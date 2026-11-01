local _, ns = ...
local Util, Schema = ns.Util, ns.Schema

ns.Store = ns.Store or {}
local Store = ns.Store

function Store.open(rawDatabase)
  local database, warnings = Schema.normalizeDatabase(rawDatabase)
  return setmetatable({ db = database, warnings = warnings or {} }, { __index = Store })
end

function Store:commit(mutator)
  local draft = Util.copy(self.db)
  local ok, result, extra = pcall(mutator, draft)
  if not ok then return nil, result end
  if result == false then return nil, extra or "Änderung abgebrochen" end
  self.db = draft
  if self.onChange then self.onChange(self.db) end
  return result, extra
end

function Store:getProfile(id)
  return self.db.profiles[id]
end

function Store:listForCharacter(characterKey)
  local result = {}
  for _, profile in pairs(self.db.profiles) do
    if profile.character.key == characterKey then table.insert(result, profile) end
  end
  table.sort(result, function(left, right)
    if left.name == right.name then return left.createdAt < right.createdAt end
    return left.name:lower() < right.name:lower()
  end)
  return result
end

function Store:defaultForCharacter(characterKey)
  local state = self.db.characters[characterKey]
  return state and state.defaultProfileId and self.db.profiles[state.defaultProfileId] or nil
end

function Store:saveProfile(profile)
  local valid, issues = Schema.validateProfile(profile)
  if not valid then return nil, Util.formatIssues(issues) end
  return self:commit(function(draft)
    if not draft.profiles[profile.id] and Util.count(draft.profiles) >= Schema.MAX_PROFILES then
      return false, "Maximale Profilanzahl erreicht"
    end
    profile.updatedAt = Util.now()
    draft.profiles[profile.id] = Util.copy(profile)
    draft.characters[profile.character.key] = draft.characters[profile.character.key] or {}
    return profile.id
  end)
end

function Store:deleteProfile(id)
  return self:commit(function(draft)
    local profile = draft.profiles[id]
    if not profile then return false, "Profil nicht gefunden" end
    local owner = draft.characters[profile.character.key]
    if owner and owner.defaultProfileId == id then owner.defaultProfileId = nil end
    draft.profiles[id] = nil
    return true
  end)
end

function Store:setDefault(characterKey, profileId)
  return self:commit(function(draft)
    local profile = draft.profiles[profileId]
    if not profile or profile.character.key ~= characterKey then
      return false, "Profil gehört nicht zu diesem Charakter"
    end
    draft.characters[characterKey] = draft.characters[characterKey] or {}
    draft.characters[characterKey].defaultProfileId = profileId
    return true
  end)
end

function Store:importProfiles(profiles, conflictPolicy)
  return self:commit(function(draft)
    local imported, conflicts = {}, {}
    for _, profile in ipairs(profiles) do
      local valid, issues = Schema.validateProfile(profile)
      if not valid then return false, "Ungültiges Importprofil: " .. Util.formatIssues(issues) end
      local existing = draft.profiles[profile.id]
      if existing and conflictPolicy == "keep" then
        table.insert(conflicts, profile.id)
      else
        local candidate = Util.copy(profile)
        if existing and conflictPolicy == "copy" then
          candidate.id = Util.uuid()
          candidate.name = candidate.name .. " (Import)"
        elseif existing and conflictPolicy ~= "replace" then
          return false, "Ungültige Konfliktoption"
        end
        draft.profiles[candidate.id] = candidate
        draft.characters[candidate.character.key] = draft.characters[candidate.character.key] or {}
        table.insert(imported, candidate.id)
      end
    end
    return { imported = imported, conflicts = conflicts }
  end)
end
