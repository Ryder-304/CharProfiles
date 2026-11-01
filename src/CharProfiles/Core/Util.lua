local addonName, ns = ...
ns = ns or {}
_G[addonName] = ns

ns.Util = ns.Util or {}
local Util = ns.Util

function Util.copy(value, seen)
  if type(value) ~= "table" then return value end
  seen = seen or {}
  if seen[value] then return seen[value] end
  local result = {}
  seen[value] = result
  for key, child in pairs(value) do
    result[Util.copy(key, seen)] = Util.copy(child, seen)
  end
  return result
end

function Util.trim(value)
  if type(value) ~= "string" then return "" end
  return value:match("^%s*(.-)%s*$")
end

function Util.now()
  return time and time() or 0
end

function Util.uuid()
  local seed = tostring(Util.now()) .. ":" .. tostring(math.random(100000, 999999))
  local hash = 5381
  for index = 1, #seed do
    hash = (hash * 33 + seed:byte(index)) % 4294967296
  end
  return string.format("cp-%08x-%06x", hash, math.random(0, 0xffffff))
end

-- Deliberately small checksum: this detects clipboard damage, not hostile input.
function Util.checksum(value)
  local a, b = 1, 0
  for index = 1, #value do
    a = (a + value:byte(index)) % 65521
    b = (b + a) % 65521
  end
  return string.format("%04x%04x", b, a)
end

function Util.count(value)
  local total = 0
  for _ in pairs(value or {}) do total = total + 1 end
  return total
end

function Util.arrayContains(items, value)
  for _, item in ipairs(items or {}) do
    if item == value then return true end
  end
  return false
end

function Util.formatIssues(issues)
  if not issues or #issues == 0 then return "" end
  return table.concat(issues, "; ")
end
