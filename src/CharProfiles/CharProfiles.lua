local addonName, ns = ...
local Store, ProfileService = ns.Store, ns.ProfileService

local addon = CreateFrame("Frame")
ns.Addon = addon

local function printMessage(message)
  local prefix = "|cff4fc3f7CharProfiles|r: "
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(prefix .. tostring(message)) end
end

local function report(kind, message, details)
  local suffix = ""
  if details and details.failures and #details.failures > 0 then
    local shown, rest = {}, math.max(0, #details.failures - 4)
    for index = 1, math.min(4, #details.failures) do table.insert(shown, details.failures[index]) end
    suffix = " (" .. table.concat(shown, "; ") .. (rest > 0 and "; +" .. rest .. " weitere" or "") .. ")"
  end
  printMessage(message .. suffix)
  if ns.UI then ns.UI:setStatus(message .. suffix) end
end

local function selectedByName(name)
  local identity = ns.Service:identity()
  if not identity then return nil end
  name = name:lower()
  for _, profile in ipairs(ns.Service.store:listForCharacter(identity.key)) do
    if profile.name:lower() == name or profile.id == name then return profile end
  end
end

local function slash(message)
  local command, argument = message:match("^(%S*)%s*(.-)$")
  command = (command or ""):lower()
  if command == "" or command == "show" then return ns.UI:toggle() end
  if command == "help" then
    return printMessage("/cp, /cp save <Name>, /cp load <Name>, /cp list, /cp export, /cp import, /cp backup")
  end
  if command == "save" then
    if argument == "" then return printMessage("Bitte einen Profilnamen angeben.") end
    local profile, createError = ns.Service:create(argument)
    if not profile then return printMessage(createError) end
    local saved, captureError = ns.Service:capture(profile.id)
    return printMessage(saved and "Profil gespeichert." or captureError)
  end
  if command == "load" then
    local profile = selectedByName(argument)
    if not profile then return printMessage("Profil nicht gefunden.") end
    local result, errorMessage = ns.Service:load(profile.id, true)
    return printMessage(result and result.message or errorMessage)
  end
  if command == "list" then
    local identity = ns.Service:identity()
    if not identity then return printMessage("Charakterdaten sind noch nicht verfügbar.") end
    local profiles = ns.Service.store:listForCharacter(identity.key)
    if #profiles == 0 then return printMessage("Keine Profile für diesen Charakter.") end
    for _, profile in ipairs(profiles) do printMessage(profile.name .. " [" .. profile.id .. "]") end
    return
  end
  if command == "export" then return ns.UI:openExport(argument == "all") end
  if command == "import" then return ns.UI:openImport() end
  if command == "backup" then
    local backup, errorMessage = ns.Service:backupCurrent("Manuelle Sicherung")
    return printMessage(backup and "Manuelle Sicherung erstellt." or errorMessage)
  end
  printMessage("Unbekannter Befehl. /cp help zeigt die verfügbaren Befehle.")
end

function addon:initialize()
  CharProfilesDB = CharProfilesDB or {}
  CharProfilesBackupDB = CharProfilesBackupDB or { snapshots = {} }
  local adapter = ns.AdapterRegistry.get("tbc-classic")
  if not adapter then return printMessage("TBC-Adapter konnte nicht geladen werden.") end
  local store = Store.open(CharProfilesDB)
  CharProfilesDB = store.db
  store.onChange = function(database) CharProfilesDB = database end
  ns.Service = ProfileService.new(store, adapter, CharProfilesBackupDB, report)
  ns.Adapter = adapter
  ns.UI:initialize()
  for _, warning in ipairs(store.warnings or {}) do printMessage(warning) end
  printMessage("geladen. Öffnen mit /cp")
end

addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("PLAYER_REGEN_ENABLED")
addon:SetScript("OnEvent", function(_, event, name)
  if event == "ADDON_LOADED" and name == addonName then
    addon:initialize()
  elseif event == "PLAYER_LOGIN" and ns.Service then
    ns.Service:autoLoadDefault()
  elseif event == "PLAYER_REGEN_ENABLED" and ns.Service then
    ns.Service:retryPending()
  end
end)

SLASH_CHARPROFILES1 = "/charprofiles"
SLASH_CHARPROFILES2 = "/cp"
SlashCmdList.CHARPROFILES = slash
