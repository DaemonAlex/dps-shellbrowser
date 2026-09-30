-- CLIENT. Runs every saved portal for every player.
-- Each shell sits 60 m under its door, spawned with its furniture only while a
-- player is within 250 m and deleted when they leave (client-only objects,
-- ox_lib points, no loops). Door and way out are 2 m points: [E] fades and moves you.

local DEPTH = 60.0
local points, shells, pieces = {}, {}, {}

-- Read by decorate.lua: name -> { data, shellPos }, and entity -> { name, id }
DpsPortals, DpsPieceByEntity = {}, {}

local function spawn(model, pos, h)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not pcall(lib.requestModel, hash, 15000) then return end
    local o = CreateObjectNoOffset(hash, pos.x, pos.y, pos.z, false, false, false)
    SetEntityHeading(o, h or 0.0)
    FreezeEntityPosition(o, true)
    SetModelAsNoLongerNeeded(hash)
    return o
end

local function despawn(name)
    if shells[name] and DoesEntityExist(shells[name]) then DeleteEntity(shells[name]) end
    shells[name] = nil
    for _, o in ipairs(pieces[name] or {}) do
        DpsPieceByEntity[o] = nil
        if DoesEntityExist(o) then DeleteEntity(o) end
    end
    pieces[name] = nil
end

local function spawnRoom(name)
    local p = DpsPortals[name]
    if not p or (shells[name] and DoesEntityExist(shells[name])) then return end
    shells[name] = spawn(p.data.shell, p.shellPos)
    pieces[name] = {}
    for _, q in ipairs(p.data.props or {}) do
        local o = spawn(q.model, p.shellPos + vec3(q.x, q.y, q.z), q.h)
        if o then
            pieces[name][#pieces[name] + 1] = o
            DpsPieceByEntity[o] = { name = name, id = q.id, model = q.model }
        end
    end
end

local function clear()
    for _, p in ipairs(points) do p:remove() end
    for name in pairs(shells) do despawn(name) end
    points, shells, pieces, DpsPortals, DpsPieceByEntity = {}, {}, {}, {}, {}
end

local function move(to, heading, name)
    if cache.vehicle then return lib.notify({ type = 'error', description = 'Get out of the vehicle first' }) end
    DoScreenFadeOut(300)
    Wait(350)
    if name then spawnRoom(name) end
    local ped = cache.ped
    FreezeEntityPosition(ped, true)
    RequestCollisionAtCoord(to.x, to.y, to.z)
    SetEntityCoords(ped, to.x, to.y, to.z - 1.0, false, false, false, false)
    SetEntityHeading(ped, heading)
    Wait(500)
    FreezeEntityPosition(ped, false)
    DoScreenFadeIn(300)
end

local function door(coords, text, onUse)
    return lib.points.new({
        coords = coords,
        distance = 2.0,
        onEnter = function() lib.showTextUI('[E] ' .. text) end,
        onExit = function() lib.hideTextUI() end,
        nearby = function() if IsControlJustPressed(0, 38) then lib.hideTextUI(); onUse() end end,
    })
end

local function build(portals)
    local wasInside = {}
    for name in pairs(shells) do wasInside[name] = true end
    clear()
    for name, p in pairs(portals or {}) do
        local ent = vec3(p.entrance.x, p.entrance.y, p.entrance.z)
        local shellPos = ent - vec3(0.0, 0.0, DEPTH)
        local out = shellPos + vec3(p.exit.x, p.exit.y, p.exit.z)
        DpsPortals[name] = { data = p, shellPos = shellPos }
        if wasInside[name] then spawnRoom(name) end -- redraw at once after an edit

        points[#points + 1] = lib.points.new({
            coords = shellPos,
            distance = 250.0,
            onEnter = function() spawnRoom(name) end,
            onExit = function() despawn(name) end,
        })
        points[#points + 1] = door(ent, 'Enter ' .. p.label, function() move(out, p.exit.h, name) end)
        points[#points + 1] = door(out, 'Leave ' .. p.label, function() move(ent, (p.entrance.h + 180.0) % 360.0) end)
    end
end

RegisterNetEvent('dps-shellbrowser:portals', build)

CreateThread(function()
    build(lib.callback.await('dps-shellbrowser:getPortals', false))
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then clear() end
end)
