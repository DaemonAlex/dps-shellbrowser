-- CLIENT. Runs every saved portal for every player.
-- Each shell sits 60 m under its door, spawned only while a player is within
-- 250 m and deleted when they leave (client-only object, ox_lib points, no loops).
-- Door and way out are 2 m points: [E] fades, moves you, fades back.

local DEPTH = 60.0
local points, objects = {}, {}

local function clear()
    for _, p in ipairs(points) do p:remove() end
    for _, o in pairs(objects) do if DoesEntityExist(o) then DeleteEntity(o) end end
    points, objects = {}, {}
end

local function spawnShell(name, model, pos)
    if objects[name] and DoesEntityExist(objects[name]) then return objects[name] end
    local h = joaat(model)
    if not IsModelInCdimage(h) or not pcall(lib.requestModel, h, 15000) then return end
    local o = CreateObjectNoOffset(h, pos.x, pos.y, pos.z, false, false, false)
    FreezeEntityPosition(o, true)
    SetModelAsNoLongerNeeded(h)
    objects[name] = o
    return o
end

local function move(to, heading, name, model, shellPos)
    if cache.vehicle then return lib.notify({ type = 'error', description = 'Get out of the vehicle first' }) end
    DoScreenFadeOut(300)
    Wait(350)
    if shellPos then spawnShell(name, model, shellPos) end
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
    clear()
    for name, p in pairs(portals or {}) do
        local ent = vec3(p.entrance.x, p.entrance.y, p.entrance.z)
        local shellPos = ent - vec3(0.0, 0.0, DEPTH)
        local out = shellPos + vec3(p.exit.x, p.exit.y, p.exit.z)

        points[#points + 1] = lib.points.new({
            coords = shellPos,
            distance = 250.0,
            onEnter = function() spawnShell(name, p.shell, shellPos) end,
            onExit = function()
                local o = objects[name]
                if o and DoesEntityExist(o) then DeleteEntity(o) end
                objects[name] = nil
            end,
        })
        points[#points + 1] = door(ent, 'Enter ' .. p.label, function()
            move(out, p.exit.h, name, p.shell, shellPos)
        end)
        points[#points + 1] = door(out, 'Leave ' .. p.label, function()
            move(ent, (p.entrance.h + 180.0) % 360.0)
        end)
    end
end

RegisterNetEvent('dps-shellbrowser:portals', build)

CreateThread(function()
    build(lib.callback.await('dps-shellbrowser:getPortals', false))
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then clear() end
end)
