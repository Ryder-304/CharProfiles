local _, ns = ...
local Util, Schema, Codec = ns.Util, ns.Schema, ns.Codec

ns.ProfileService = ns.ProfileService or {}
local ProfileService = ns.ProfileService

function ProfileService.new(store, adapter, backups, reporter)
  return setmetatable({
    store = store,
    adapter = adapter,
    backups = backups or { snapshots = {} },
    reporter = reporter or function() end,
    loadedThisSession = {},
    pendingLoad = nil,
  }, { __index = ProfileService })
end

function ProfileService:identity()
  local identity, errorMessage = self.adapter:characterIdentity()
  if not identity then return nil, errorMessage end
  identity.key = Schema.characterKey(identity)
  return identity
end

function ProfileService:report(kind, message, details)
  self.reporter(kind, message, details)
  return { kind = kind, message = message, details = details or {} }
end

function ProfileService:create(name)
  name = Util.trim(name)
  if name == "" or #name > Schema.MAX_NAME_LENGTH then return nil, "Bitte einen Profilnamen mit maximal 60 Zeichen angeben" end
  local identity, identityError = self:identity()
  if not identity then return nil, identityError end
  local profile = Schema.newProfile(identity, name, self.adapter:metadata())
  local saved, saveError = self.store:saveProfile(profile)
  if not saved then return nil, saveError end
  return profile
end

function ProfileService:capture(profileId)
  local profile = self.store:getProfile(profileId)
  if not profile then return nil, "Profil nicht gefunden" end
  local identity, identityError = self:identity()
  if not identity then return nil, identityError end
  if profile.character.key ~= identity.key then return nil, "Profil gehört zu einem anderen Charakter" end
  local captured, captureResult = self.adapter:capture()
  if not captured then return nil, captureResult end
  local candidate = Util.copy(profile)
  candidate.bindings = captured.bindings
  candidate.actionBars = captured.actionBars
  candidate.clientData = captured.clientData or {}
  candidate.source = self.adapter:metadata()
  local saved, saveError = self.store:saveProfile(candidate)
  if not saved then return nil, saveError end
  return candidate, captureResult
end

function ProfileService:rename(profileId, name)
  name = Util.trim(name)
  if name == "" or #name > Schema.MAX_NAME_LENGTH then return nil, "Ungültiger Profilname" end
  local profile = self.store:getProfile(profileId)
  if not profile then return nil, "Profil nicht gefunden" end
  local candidate = Util.copy(profile)
  candidate.name = name
  return self.store:saveProfile(candidate)
end

function ProfileService:duplicate(profileId, name)
  local profile = self.store:getProfile(profileId)
  if not profile then return nil, "Profil nicht gefunden" end
  name = Util.trim(name)
  if name == "" then name = profile.name .. " (Kopie)" end
  if #name > Schema.MAX_NAME_LENGTH then return nil, "Ungültiger Profilname" end
  local candidate = Util.copy(profile)
  candidate.id = Util.uuid()
  candidate.name = name
  candidate.createdAt, candidate.updatedAt = Util.now(), Util.now()
  return self.store:saveProfile(candidate)
end

function ProfileService:backup(label, profile)
  self.backups.snapshots = self.backups.snapshots or {}
  local entry = {
    id = Util.uuid(), label = label, profile = Util.copy(profile), createdAt = Util.now(),
  }
  table.insert(self.backups.snapshots, 1, entry)
  while #self.backups.snapshots > 20 do table.remove(self.backups.snapshots) end
  return entry
end

function ProfileService:backupCurrent(label)
  local identity, identityError = self:identity()
  if not identity then return nil, identityError end
  local captured, captureError = self.adapter:capture()
  if not captured then return nil, captureError end
  local profile = Schema.newProfile(identity, label or "Manuelle Sicherung", self.adapter:metadata())
  profile.bindings, profile.actionBars, profile.clientData = captured.bindings, captured.actionBars, captured.clientData or {}
  return self:backup(label or "Manuelle Sicherung", profile)
end

function ProfileService:restoreBackup(backupId)
  for _, backup in ipairs(self.backups.snapshots or {}) do
    if backup.id == backupId then return self:loadSnapshot(backup.profile, false) end
  end
  return nil, "Sicherung nicht gefunden"
end

function ProfileService:loadSnapshot(profile, saveBeforeLoad)
  local allowed, reason = self.adapter:canApply()
  if not allowed then
    self.pendingLoad = { profile = Util.copy(profile), saveBeforeLoad = saveBeforeLoad }
    return self:report("pending", reason or "Wiederherstellung wird verschoben")
  end
  if saveBeforeLoad then
    local backup, backupError = self:backupCurrent("Vor Wiederherstellung: " .. profile.name)
    if not backup then return nil, "Sicherung konnte nicht erstellt werden: " .. backupError end
  end
  local result, applyError = self.adapter:apply(profile)
  if not result then return nil, applyError end
  local message = result.status == "complete" and "Profil vollständig geladen"
    or result.status == "partial" and "Profil teilweise geladen"
    or "Profil konnte nicht geladen werden"
  return self:report(result.status, message, result)
end

function ProfileService:load(profileId, saveBeforeLoad)
  local profile = self.store:getProfile(profileId)
  if not profile then return nil, "Profil nicht gefunden" end
  local valid, issues = Schema.validateProfile(profile)
  if not valid then return nil, "Profil ist beschädigt: " .. Util.formatIssues(issues) end
  local result, errorMessage = self:loadSnapshot(profile, saveBeforeLoad)
  if result then self.loadedThisSession[profile.character.key .. ":" .. profile.id] = true end
  return result, errorMessage
end

function ProfileService:retryPending()
  if not self.pendingLoad then return end
  local pending = self.pendingLoad
  self.pendingLoad = nil
  return self:loadSnapshot(pending.profile, pending.saveBeforeLoad)
end

function ProfileService:autoLoadDefault()
  local identity = self:identity()
  if not identity then return end
  local profile = self.store:defaultForCharacter(identity.key)
  if not profile then return end
  local key = identity.key .. ":" .. profile.id
  if self.loadedThisSession[key] then return end
  local result, errorMessage = self:load(profile.id, false)
  if not result and errorMessage then self:report("failed", errorMessage) end
end

function ProfileService:exportOne(profileId)
  local profile = self.store:getProfile(profileId)
  if not profile then return nil, "Profil nicht gefunden" end
  return Codec.export({ profile }, self.adapter:metadata())
end

function ProfileService:exportAll()
  local profiles = {}
  for _, profile in pairs(self.store.db.profiles) do table.insert(profiles, profile) end
  table.sort(profiles, function(left, right) return left.id < right.id end)
  return Codec.export(profiles, self.adapter:metadata())
end

function ProfileService:inspectImport(code)
  local payload, importError = Codec.import(code)
  if not payload then return nil, importError end
  local unsupported, conflicts = {}, {}
  for _, profile in ipairs(payload.profiles) do
    local capability = self.adapter:checkProfile(profile)
    if capability and #capability.unsupported > 0 then
      unsupported[profile.id] = capability.unsupported
    end
    if self.store:getProfile(profile.id) then table.insert(conflicts, profile.id) end
  end
  return { payload = payload, conflicts = conflicts, unsupported = unsupported }
end

function ProfileService:import(code, conflictPolicy)
  local inspection, inspectionError = self:inspectImport(code)
  if not inspection then return nil, inspectionError end
  if conflictPolicy == "replace" then
    for _, profile in ipairs(inspection.payload.profiles) do
      local previous = self.store:getProfile(profile.id)
      if previous then self:backup("Vor Import ersetzen: " .. previous.name, previous) end
    end
  end
  return self.store:importProfiles(inspection.payload.profiles, conflictPolicy)
end
