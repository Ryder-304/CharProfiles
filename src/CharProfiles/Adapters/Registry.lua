local _, ns = ...

ns.AdapterRegistry = ns.AdapterRegistry or { adapters = {} }
local Registry = ns.AdapterRegistry

function Registry.register(adapter)
  assert(type(adapter) == "table" and type(adapter.id) == "string", "Ungültiger Client-Adapter")
  Registry.adapters[adapter.id] = adapter
end

function Registry.get(id)
  return Registry.adapters[id]
end
