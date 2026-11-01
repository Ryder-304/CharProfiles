local _, ns = ...
local Util = ns.Util

ns.Schema = ns.Schema or {}
local Schema = ns.Schema

Schema.VERSION = 1
Schema.CODE_VERSION = 1
Schema.MAX_PROFILES = 250
Schema.MAX_NAME_LENGTH = 60

local function validString(value, limit)
  return type(value) == "string" and #value > 0 and #value <= limit
end

function Schema.newDatabase()
  return { schemaVersion = Schema.VERSION, profiles = {}, characters = {}, quarantined = {} }
end

function Schema.characterKey(identity)
  assert(identity and validString(identity.name, 80), "character name is required")
  assert(validString(identity.realm, 80), "realm is required")
  return identity.region and (identity.region .. ":" .. identity.realm .. ":" .. identity.name)
    or (identity.realm .. ":" .. identity.name)
end

function Schema.newProfile(identity, name, client)
  local timestamp = Util.now()
  return {
    formatVersion = Schema.VERSION,
    id = Util.uuid(),
    name = name,
    character = { key = Schema.characterKey(identity), name = identity.name, realm = identity.realm, region = identity.region },
    source = { client = client.id, build = client.build },
    bindings = {},
    actionBars = {},
    clientData = {},
    createdAt = timestamp,
    updatedAt = timestamp,
  }
end

function Schema.validateProfile(profile)
  local issues = {}
  if type(profile) ~= "table" then return false, { "Profil ist keine Tabelle" } end
  if profile.formatVersion ~= Schema.VERSION then
    table.insert(issues, "Unbekannte Profilformat-Version")
  end
  if not validString(profile.id, 120) then table.insert(issues, "Profil-ID fehlt") end
  if not validString(profile.name, Schema.MAX_NAME_LENGTH) then table.insert(issues, "Profilname ist ungültig") end
  if type(profile.character) ~= "table" or not validString(profile.character.key, 200) then
    table.insert(issues, "Charakterzuordnung fehlt")
  end
  if type(profile.source) ~= "table" or not validString(profile.source.client, 80) then
    table.insert(issues, "Herkunftsclient fehlt")
  end
  if type(profile.bindings) ~= "table" then table.insert(issues, "Belegungen sind ungültig") end
  if type(profile.actionBars) ~= "table" then table.insert(issues, "Aktionsleisten sind ungültig") end
  if type(profile.clientData) ~= "table" then table.insert(issues, "Clientdaten sind ungültig") end
  return #issues == 0, issues
end

function Schema.normalizeDatabase(database)
  if type(database) ~= "table" then return Schema.newDatabase(), { "Datenbank neu angelegt" } end
  database.schemaVersion = database.schemaVersion or Schema.VERSION
  database.profiles = type(database.profiles) == "table" and database.profiles or {}
  database.characters = type(database.characters) == "table" and database.characters or {}
  database.quarantined = type(database.quarantined) == "table" and database.quarantined or {}

  local issues = {}
  for id, profile in pairs(database.profiles) do
    local valid, profileIssues = Schema.validateProfile(profile)
    if not valid or id ~= profile.id then
      database.quarantined[id] = { profile = profile, issues = profileIssues, quarantinedAt = Util.now() }
      database.profiles[id] = nil
      table.insert(issues, "Defektes Profil isoliert: " .. tostring(id))
    end
  end
  return database, issues
end
