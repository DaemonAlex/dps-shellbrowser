-- SERVER. Access check + shell list for the browser.
-- Uses the same ace as dps-whatobject (group.admin already has it), so no
-- permissions.cfg change is needed.

local ACE = 'dps.entityselector'

lib.callback.register('dps-shellbrowser:open', function(source)
    if not IsPlayerAceAllowed(source, ACE) then return false end
    local shells = ParseShells(LoadResourceFile('qs-housing', 'config/main.lua'))
    lib.print.info(('%s opened the shell browser (%d shells)'):format(GetPlayerName(source) or source, #shells))
    return true, shells
end)

-- Portals: a door in the world that leads into a shell 60 m under it.
-- Saved in this resource's portals.json (the resource owns that file).
local FILE = 'portals.json'
local portals = json.decode(LoadResourceFile(GetCurrentResourceName(), FILE) or '{}') or {}

local function save()
    SaveResourceFile(GetCurrentResourceName(), FILE, json.encode(portals, { indent = true }), -1)
    TriggerClientEvent('dps-shellbrowser:portals', -1, portals)
end

lib.callback.register('dps-shellbrowser:getPortals', function() return portals end)

lib.callback.register('dps-shellbrowser:listPortals', function(source)
    if not IsPlayerAceAllowed(source, ACE) then return nil end
    local names = {}
    for n, p in pairs(portals) do names[#names + 1] = ('%s (%s)'):format(n, p.shell) end
    table.sort(names)
    return names
end)


lib.callback.register('dps-shellbrowser:savePortal', function(source, d)
    if not IsPlayerAceAllowed(source, ACE) then return false, 'Portals are for admins' end
    local ok, err = ValidatePortal(d)
    if not ok then return false, err end
    local known = false
    for _, m in ipairs(ParseShells(LoadResourceFile('qs-housing', 'config/main.lua'))) do
        if m == d.shell then known = true break end
    end
    if not known then return false, 'That shell is not in the housing list' end
    portals[d.name] = { label = d.label, shell = d.shell, entrance = d.entrance, exit = d.exit }
    save()
    lib.print.info(('%s saved portal %s -> %s'):format(GetPlayerName(source) or source, d.name, d.shell))
    return true
end)

lib.callback.register('dps-shellbrowser:deletePortal', function(source, name)
    if not IsPlayerAceAllowed(source, ACE) then return false, 'Portals are for admins' end
    if type(name) ~= 'string' or not portals[name] then return false, 'No portal with that name' end
    portals[name] = nil
    save()
    lib.print.info(('%s removed portal %s'):format(GetPlayerName(source) or source, name))
    return true
end)
