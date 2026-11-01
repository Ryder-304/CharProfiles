local _, ns = ...
local Util, Schema = ns.Util, ns.Schema

ns.Codec = ns.Codec or {}
local Codec = ns.Codec

Codec.PREFIX = "CP1"
Codec.MAX_CODE_SIZE = 500000
Codec.DEFAULT_PART_SIZE = 12000

local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local lookup = {}
for index = 1, #alphabet do lookup[alphabet:sub(index, index)] = index - 1 end

local function base64Encode(input)
  local result, index = {}, 1
  while index <= #input do
    local a, b, c = input:byte(index, index + 2)
    local value = (a or 0) * 65536 + (b or 0) * 256 + (c or 0)
    table.insert(result, alphabet:sub(math.floor(value / 262144) % 64 + 1, math.floor(value / 262144) % 64 + 1))
    table.insert(result, alphabet:sub(math.floor(value / 4096) % 64 + 1, math.floor(value / 4096) % 64 + 1))
    table.insert(result, b and alphabet:sub(math.floor(value / 64) % 64 + 1, math.floor(value / 64) % 64 + 1) or "=")
    table.insert(result, c and alphabet:sub(value % 64 + 1, value % 64 + 1) or "=")
    index = index + 3
  end
  return table.concat(result)
end

local function base64Decode(input)
  if #input % 4 ~= 0 or input:find("[^%w%+/%=]") then return nil, "Ungültige Base64-Daten" end
  local result = {}
  for index = 1, #input, 4 do
    local c1, c2, c3, c4 = input:sub(index, index), input:sub(index + 1, index + 1), input:sub(index + 2, index + 2), input:sub(index + 3, index + 3)
    if not lookup[c1] or not lookup[c2] or (c3 ~= "=" and not lookup[c3]) or (c4 ~= "=" and not lookup[c4]) then
      return nil, "Ungültige Base64-Daten"
    end
    if (c3 == "=" and c4 ~= "=") or ((c3 == "=" or c4 == "=") and index + 3 ~= #input) then
      return nil, "Ungültige Base64-Polsterung"
    end
    local value = lookup[c1] * 262144 + lookup[c2] * 4096 + (lookup[c3] or 0) * 64 + (lookup[c4] or 0)
    table.insert(result, string.char(math.floor(value / 65536) % 256))
    if c3 ~= "=" then table.insert(result, string.char(math.floor(value / 256) % 256)) end
    if c4 ~= "=" then table.insert(result, string.char(value % 256)) end
  end
  return table.concat(result)
end

local function sortedKeys(value)
  local keys = {}
  for key in pairs(value) do
    if type(key) ~= "string" and type(key) ~= "number" then error("Nur Zeichenketten- und Zahlenschlüssel sind exportierbar") end
    table.insert(keys, key)
  end
  table.sort(keys, function(left, right)
    if type(left) == type(right) then return left < right end
    return type(left) == "number"
  end)
  return keys
end

-- A restricted length-prefixed format avoids evaluating clipboard data as Lua.
local function serialize(value, seen)
  local kind = type(value)
  if kind == "string" then return "s" .. #value .. ":" .. value end
  if kind == "number" then
    if value ~= value or value == math.huge or value == -math.huge then error("Ungültige Zahl") end
    return "n" .. string.format("%.17g", value) .. ";"
  end
  if kind == "boolean" then return value and "b1" or "b0" end
  if kind ~= "table" then error("Nicht exportierbarer Wert: " .. kind) end
  seen = seen or {}
  if seen[value] then error("Zyklische Profildaten sind nicht exportierbar") end
  seen[value] = true
  local keys, output = sortedKeys(value), {}
  table.insert(output, "t" .. #keys .. "{")
  for _, key in ipairs(keys) do
    table.insert(output, serialize(key, seen))
    table.insert(output, serialize(value[key], seen))
  end
  table.insert(output, "}")
  seen[value] = nil
  return table.concat(output)
end

local function deserialize(source)
  local position, nodes = 1, 0
  local function readNumber(terminator)
    local stop = source:find(terminator, position, true)
    if not stop then return nil, "Abgeschnittene Zahl" end
    local result = tonumber(source:sub(position, stop - 1))
    if not result then return nil, "Ungültige Zahl" end
    position = stop + 1
    return result
  end
  local function readValue()
    nodes = nodes + 1
    if nodes > 100000 then return nil, "Import ist zu komplex" end
    local tag = source:sub(position, position)
    position = position + 1
    if tag == "s" then
      local length, errorMessage = readNumber(":")
      if not length or length < 0 or length % 1 ~= 0 then return nil, errorMessage or "Ungültige Zeichenkette" end
      local result = source:sub(position, position + length - 1)
      if #result ~= length then return nil, "Abgeschnittene Zeichenkette" end
      position = position + length
      return result
    elseif tag == "n" then
      return readNumber(";")
    elseif tag == "b" then
      local bit = source:sub(position, position)
      position = position + 1
      if bit == "1" then return true end
      if bit == "0" then return false end
      return nil, "Ungültiger Wahrheitswert"
    elseif tag == "t" then
      local size, errorMessage = readNumber("{")
      if not size or size < 0 or size % 1 ~= 0 or size > 50000 then return nil, errorMessage or "Ungültige Tabelle" end
      local result = {}
      for _ = 1, size do
        local key, keyError = readValue()
        if key == nil then return nil, keyError end
        if type(key) ~= "string" and type(key) ~= "number" then return nil, "Ungültiger Tabellenschlüssel" end
        local value, valueError = readValue()
        if value == nil then return nil, valueError end
        result[key] = value
      end
      if source:sub(position, position) ~= "}" then return nil, "Unvollständige Tabelle" end
      position = position + 1
      return result
    end
    return nil, "Unbekannter Datentyp"
  end
  local value, errorMessage = readValue()
  if not value then return nil, errorMessage end
  if position <= #source then return nil, "Unerwartete Daten am Ende" end
  return value
end

function Codec.export(profiles, origin)
  local payload = { codeVersion = Schema.CODE_VERSION, exportedAt = Util.now(), origin = origin, profiles = profiles }
  local raw = serialize(payload)
  local encoded = base64Encode(raw)
  local code = Codec.PREFIX .. ":" .. Util.checksum(encoded) .. ":" .. encoded
  if #code > Codec.MAX_CODE_SIZE then return nil, "Exportcode ist zu groß" end
  return code
end

function Codec.split(code, partSize)
  if type(code) ~= "string" or code:sub(1, #Codec.PREFIX + 1) ~= Codec.PREFIX .. ":" then return nil, "Ungültiger Exportcode" end
  partSize = partSize or Codec.DEFAULT_PART_SIZE
  if #code <= partSize then return { code } end
  local checksum, encoded = code:match("^CP1:([0-9a-f]+):(.+)$")
  if not checksum then return nil, "Ungültiger Exportcode" end
  local total, parts = math.ceil(#encoded / partSize), {}
  for index = 1, total do
    local from = (index - 1) * partSize + 1
    parts[index] = string.format("CPP1:%d/%d:%s:%s", index, total, checksum, encoded:sub(from, from + partSize - 1))
  end
  return parts
end

function Codec.joinParts(input)
  input = Util.trim(input)
  if input:sub(1, 4) == "CP1:" then return input end
  local parts, total, checksum = {}, nil, nil
  for line in input:gmatch("[^\r\n]+") do
    local index, candidateTotal, candidateChecksum, payload = line:match("^CPP1:(%d+)/(%d+):([0-9a-f]+):(.+)$")
    index, candidateTotal = tonumber(index), tonumber(candidateTotal)
    if not index or not candidateTotal or candidateTotal < 2 or index > candidateTotal then return nil, "Ungültiges Exportteil" end
    if total and (total ~= candidateTotal or checksum ~= candidateChecksum) then return nil, "Exportteile gehören nicht zusammen" end
    if parts[index] then return nil, "Doppeltes Exportteil" end
    total, checksum, parts[index] = candidateTotal, candidateChecksum, payload
  end
  if not total then return nil, "Kein Exportcode gefunden" end
  local payload = {}
  for index = 1, total do
    if not parts[index] then return nil, "Exportteil " .. index .. " fehlt" end
    table.insert(payload, parts[index])
  end
  return Codec.PREFIX .. ":" .. checksum .. ":" .. table.concat(payload)
end

function Codec.import(input)
  local code, joinError = Codec.joinParts(input)
  if not code then return nil, joinError end
  if #code > Codec.MAX_CODE_SIZE then return nil, "Importcode ist zu groß" end
  local checksum, encoded = code:match("^CP1:([0-9a-f]+):(.+)$")
  if not checksum or not encoded or Util.checksum(encoded) ~= checksum then return nil, "Prüfsumme stimmt nicht" end
  local raw, decodeError = base64Decode(encoded)
  if not raw then return nil, decodeError end
  local payload, dataError = deserialize(raw)
  if not payload or type(payload) ~= "table" or payload.codeVersion ~= Schema.CODE_VERSION or type(payload.profiles) ~= "table" then
    return nil, dataError or "Unbekanntes oder beschädigtes Exportformat"
  end
  local issues = {}
  for _, profile in ipairs(payload.profiles) do
    local valid, profileIssues = Schema.validateProfile(profile)
    if not valid then table.insert(issues, Util.formatIssues(profileIssues)) end
  end
  if #issues > 0 then return nil, "Ungültige Profile: " .. table.concat(issues, " | ") end
  return payload
end
