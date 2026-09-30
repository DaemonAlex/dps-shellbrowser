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
    local old = portals[d.name]
    local keep = old and old.shell == d.shell -- same shell keeps its furniture
    portals[d.name] = { label = d.label, shell = d.shell, entrance = d.entrance, exit = d.exit,
                        props = keep and old.props or nil, nextId = keep and old.nextId or nil }
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

-- Decorating: furniture pieces saved per portal, offsets from the shell spawn point.
local MAX_PROPS = 400
local furnitureCats, furnitureModels

local function furniture()
    if not furnitureCats then
        furnitureCats, furnitureModels = ParseFurniture(LoadResourceFile('qs-housing', 'config/furniture.lua'), 'nui://qs-housing/web/images/')
        local n = 0
        for _ in pairs(furnitureModels) do n = n + 1 end
        lib.print.info(('furniture catalogue: %d categories, %d items'):format(#furnitureCats, n))
    end
    return furnitureCats, furnitureModels
end

lib.callback.register('dps-shellbrowser:furniture', function(source)
    if not IsPlayerAceAllowed(source, ACE) then return nil end
    return (furniture())
end)

lib.callback.register('dps-shellbrowser:placeProp', function(source, name, prop, id)
    if not IsPlayerAceAllowed(source, ACE) then return false, 'Decorating is for admins' end
    local p = type(name) == 'string' and portals[name]
    if not p then return false, 'No portal here' end
    local _, models = furniture()
    local ok, err = ValidateProp(prop, models)
    if not ok then return false, err end
    p.props = p.props or {}
    local piece = { model = prop.model, x = prop.x, y = prop.y, z = prop.z, h = prop.h }
    if id then
        for i, q in ipairs(p.props) do
            if q.id == id then piece.id = id; p.props[i] = piece; break end
        end
        if not piece.id then return false, 'That piece is gone' end
    else
        if #p.props >= MAX_PROPS then return false, 'This room is full (' .. MAX_PROPS .. ' pieces)' end
        p.nextId = (p.nextId or 0) + 1
        piece.id = p.nextId
        p.props[#p.props + 1] = piece
    end
    save()
    return true
end)

lib.callback.register('dps-shellbrowser:removeProp', function(source, name, id)
    if not IsPlayerAceAllowed(source, ACE) then return false, 'Decorating is for admins' end
    local p = type(name) == 'string' and portals[name]
    if not p or not p.props then return false, 'No portal here' end
    for i, q in ipairs(p.props) do
        if q.id == id then
            table.remove(p.props, i)
            save()
            return true
        end
    end
    return false, 'That piece is gone'
end)
