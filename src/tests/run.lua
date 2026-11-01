-- Run with a standalone Lua interpreter from src/tests:
--   lua run.lua
local root = "../CharProfiles/"
local ns = {}
local function loadAddon(relative)
  local chunk = assert(loadfile(root .. relative))
  chunk("CharProfiles", ns)
end

math.randomseed(42)
loadAddon("Core/Util.lua")
loadAddon("Core/Schema.lua")
loadAddon("Core/Store.lua")
loadAddon("Core/Codec.lua")

local function expect(condition, message)
  if not condition then error(message or "assertion failed", 2) end
end

local identity = { name = "Tester", realm = "Realm" }
local profile = ns.Schema.newProfile(identity, "PvE", { id = "test-client", build = "1" })
profile.bindings = { { action = "ACTIONBUTTON1", keys = { "1", "SHIFT-1" } } }
profile.actionBars = { [1] = { kind = "spell", id = 133, name = "Fireball" } }

local code = assert(ns.Codec.export({ profile }, { id = "test-client", build = "1" }))
local decoded = assert(ns.Codec.import(code))
expect(decoded.profiles[1].name == "PvE", "round trip loses profile name")
expect(decoded.profiles[1].actionBars[1].id == 133, "round trip loses slot")
expect(not ns.Codec.import(code:gsub("A", "B", 1)), "checksum accepts corrupted code")

local parts = assert(ns.Codec.split(code, 20))
expect(#parts > 1, "small part size did not split")
local combined = assert(ns.Codec.joinParts(table.concat(parts, "\n")))
expect(combined == code, "parts were not reassembled")

local store = ns.Store.open(ns.Schema.newDatabase())
assert(store:saveProfile(profile))
local invalid = { id = "broken" }
expect(not store:saveProfile(invalid), "invalid profile was accepted")
expect(#store:listForCharacter(profile.character.key) == 1, "transaction changed valid data")

print("CharProfiles core tests passed")
