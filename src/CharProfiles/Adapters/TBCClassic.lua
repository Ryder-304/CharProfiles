local _, ns = ...
local Registry = ns.AdapterRegistry

local Adapter = { id = "tbc-classic", MAX_ACTION_SLOTS = 120 }

local function buildMetadata()
  local build = "unbestätigt"
  if GetBuildInfo then
    local _, clientBuild = GetBuildInfo()
    build = tostring(clientBuild or build)
  end
  return { id = Adapter.id, build = build }
end

function Adapter:metadata()
  return buildMetadata()
end

function Adapter:characterIdentity()
  if not UnitName or not GetRealmName then return nil, "Spielclient ist noch nicht bereit" end
  local name, realm = UnitName("player"), GetRealmName()
  if not name or not realm or realm == "" then return nil, "Charakterdaten sind noch nicht verfügbar" end
  return { name = name, realm = realm }
end

function Adapter:canApply()
  if InCombatLockdown and InCombatLockdown() then
    return false, "Wiederherstellung erst nach Verlassen des Kampfes möglich"
  end
  return true
end

local function captureBindings()
  local bindings = {}
  local count = GetNumBindings and GetNumBindings() or 0
  for index = 1, count do
    local command, firstKey, secondKey = GetBinding(index)
    if command then
      table.insert(bindings, { action = command, keys = { firstKey, secondKey } })
    end
  end
  return bindings
end

local function spellReference(id)
  local name, _, icon = GetSpellInfo(id)
  return { kind = "spell", id = id, name = name, icon = icon }
end

local function itemReference(id)
  local itemName, itemLink, _, _, _, _, _, _, _, icon = GetItemInfo(id)
  return { kind = "item", id = id, name = itemName, link = itemLink, icon = icon }
end

local function macroReference(index)
  local name, icon, body = GetMacroInfo(index)
  return { kind = "macro", name = name, body = body, icon = icon }
end

local function captureActions()
  local slots, unsupported = {}, {}
  for slot = 1, Adapter.MAX_ACTION_SLOTS do
    local actionType, actionId, subType = GetActionInfo(slot)
    if actionType == "spell" and actionId then
      slots[slot] = spellReference(actionId)
    elseif actionType == "item" and actionId then
      slots[slot] = itemReference(actionId)
    elseif actionType == "macro" and actionId then
      slots[slot] = macroReference(actionId)
    elseif actionType then
      slots[slot] = { kind = "client-specific", actionType = actionType, id = actionId, subType = subType }
      table.insert(unsupported, "Aktionsplatz " .. slot .. " (" .. actionType .. ")")
    end
  end
  return slots, unsupported
end

function Adapter:capture()
  local bindings = captureBindings()
  local actionBars, unsupported = captureActions()
  return { bindings = bindings, actionBars = actionBars, clientData = { unsupportedAtCapture = unsupported } }, { unsupported = unsupported }
end

local function clearAllBindings()
  local count = GetNumBindings and GetNumBindings() or 0
  for index = 1, count do
    local _, firstKey, secondKey = GetBinding(index)
    if firstKey then SetBinding(firstKey) end
    if secondKey then SetBinding(secondKey) end
  end
end

local function applyBindings(bindings, failures)
  clearAllBindings()
  for _, binding in ipairs(bindings or {}) do
    for _, key in ipairs(binding.keys or {}) do
      if key and not SetBinding(key, binding.action) then
        table.insert(failures, "Belegung " .. key .. " → " .. tostring(binding.action))
      end
    end
  end
  if SaveBindings and GetCurrentBindingSet then SaveBindings(GetCurrentBindingSet()) end
end

local function findMacro(reference)
  if not GetNumMacros or not GetMacroInfo then return nil end
  local account, character = GetNumMacros()
  for index = 1, (account or 0) + (character or 0) do
    local name, _, body = GetMacroInfo(index)
    if name == reference.name and body == reference.body then return index end
  end
end

local function pickUp(reference)
  if reference.kind == "spell" and reference.id and PickupSpell then
    PickupSpell(reference.id)
    return true
  elseif reference.kind == "item" and reference.id and PickupItem then
    PickupItem("item:" .. tostring(reference.id))
    return true
  elseif reference.kind == "macro" and PickupMacro then
    local macro = findMacro(reference)
    if macro then PickupMacro(macro) return true end
  end
  return false
end

local function applyActions(actions, failures)
  for slot = 1, Adapter.MAX_ACTION_SLOTS do
    local reference = actions and actions[slot]
    if reference then
      if ClearAction then ClearAction(slot) end
      if pickUp(reference) and PlaceAction then
        PlaceAction(slot)
      else
        if ClearCursor then ClearCursor() end
        table.insert(failures, "Aktionsplatz " .. slot .. " (" .. tostring(reference.kind) .. ")")
      end
    elseif ClearAction then
      ClearAction(slot)
    end
  end
end

function Adapter:apply(profile)
  local allowed, reason = self:canApply()
  if not allowed then return nil, reason end
  local failures = {}
  applyBindings(profile.bindings, failures)
  applyActions(profile.actionBars, failures)
  return { status = #failures == 0 and "complete" or "partial", failures = failures }
end

function Adapter:checkProfile(profile)
  local unsupported = {}
  if not profile.source or profile.source.client ~= self.id then
    table.insert(unsupported, "Profil stammt von einem anderen Client; vor dem Laden prüfen")
  end
  for slot, reference in pairs(profile.actionBars or {}) do
    if reference.kind ~= "spell" and reference.kind ~= "item" and reference.kind ~= "macro" then
      table.insert(unsupported, "Aktionsplatz " .. tostring(slot) .. " (" .. tostring(reference.kind) .. ")")
    end
  end
  return { unsupported = unsupported }
end

Registry.register(Adapter)
