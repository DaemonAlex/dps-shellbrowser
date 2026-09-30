-- CLIENT. /shells [number or name]
-- Spawns one shell at a time high above the sea south of LSIA, so open shells
-- (no walls or roof) can be seen from every side against the sky.
-- Overview: camera circles the shell. Walk: you stand on its floor.
-- Nothing is networked: other players never see the shell.

local BASE = vec3(-2200.0, -4200.0, 1100.0)
local KEY = { left = 174, right = 175, up = 172, down = 173, q = 44, e = 38,
              wheelUp = 241, wheelDown = 242, enter = 191, back = 194, back2 = 177, copy = 26 }

local active, walking = false, false
local list, idx = {}, 1
local obj, hash, cam, back, wasGod
local center, minZ, radius, heading, tilt = BASE, BASE.z, 20.0, 45.0, 0.35

local function label()
    local m = list[idx] or '?'
    if walking then
        lib.showTextUI(('**%d / %d**  \n%s  \n  \n[Enter] back to the view  \n[C] copy name  \n[Backspace] leave'):format(idx, #list, m), { position = 'left-center' })
    else
        lib.showTextUI(('**%d / %d**  \n%s  \n  \n[Left Right] previous / next  \n[Up Down] jump 10  \n[Mouse or Q E] turn  \n[Wheel] zoom  \n[Enter] walk inside  \n[C] copy name  \n[Backspace] leave'):format(idx, #list, m), { position = 'left-center' })
    end
end

local function placeCam()
    local r = math.rad(heading)
    local pos = center + vec3(math.cos(r) * radius, math.sin(r) * radius, radius * tilt)
    SetCamCoord(cam, pos.x, pos.y, pos.z)
    PointCamAtCoord(cam, center.x, center.y, center.z)
end

local function hidePed()
    local ped = cache.ped
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)
    SetEntityCoords(ped, center.x, center.y, center.z, false, false, false, false)
end

local function clearShell()
    if obj and DoesEntityExist(obj) then DeleteEntity(obj) end
    obj = nil
    if hash then SetModelAsNoLongerNeeded(hash) end
    hash = nil
end

local function loadShell(i)
    clearShell()
    idx = ((i - 1) % #list) + 1
    local model = list[idx]
    local h = joaat(model)
    center, minZ = BASE, BASE.z
    if not IsModelInCdimage(h) then
        label()
        return lib.notify({ type = 'error', description = model .. ' is in the housing list but its file is not streamed' })
    end
    if not pcall(lib.requestModel, h, 15000) then
        label()
        return lib.notify({ type = 'error', description = model .. ' did not load in time, press Right to skip' })
    end
    hash = h
    obj = CreateObjectNoOffset(h, BASE.x, BASE.y, BASE.z, false, false, false)
    FreezeEntityPosition(obj, true)
    local mn, mx = GetModelDimensions(h)
    center = BASE + (mn + mx) / 2
    minZ = BASE.z + mn.z
    radius = math.min(400.0, math.max(8.0, #(mx - mn) * 0.9))
    if not walking then hidePed() end
    RequestCollisionAtCoord(center.x, center.y, center.z)
    placeCam()
    label()
end

local function floorPoint()
    local ray = StartExpensiveSynchronousShapeTestLosProbe(center.x, center.y, center.z, center.x, center.y, minZ - 5.0, 1 | 16, cache.ped, 7)
    local _, hit, pos = GetShapeTestResult(ray)
    if hit == 1 then return pos + vec3(0.0, 0.0, 1.0) end
    return vec3(center.x, center.y, minZ + 1.0)
end

local function walk(on)
    walking = on
    local ped = cache.ped
    if on then
        RenderScriptCams(false, false, 0, true, true)
        local p = floorPoint()
        SetEntityCollision(ped, true, true)
        SetEntityCoords(ped, p.x, p.y, p.z, false, false, false, false)
        SetEntityVisible(ped, true, false)
        FreezeEntityPosition(ped, false)
    else
        hidePed()
        RenderScriptCams(true, false, 0, true, true)
        placeCam()
    end
    label()
end

local function stop()
    if not active then return end
    active, walking = false, false
    lib.hideTextUI()
    clearShell()
    RenderScriptCams(false, false, 0, true, true)
    if cam then DestroyCam(cam, false) end
    cam = nil
    local ped = cache.ped
    SetEntityCollision(ped, true, true)
    SetEntityCoords(ped, back.x, back.y, back.z, false, false, false, false)
    SetEntityHeading(ped, back.w)
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    if not wasGod then SetEntityInvincible(ped, false) end
end

local function copyName()
    local m = list[idx]
    if not m then return end
    lib.setClipboard(m)
    print(('[shells] %d / %d  %s'):format(idx, #list, m))
    lib.notify({ type = 'success', description = 'Copied: ' .. m })
end

local function loop()
    local nextFallCheck = 0
    while active do
        if walking then
            DisableControlAction(0, KEY.enter, true)
            DisableControlAction(0, KEY.back, true)
            DisableControlAction(0, KEY.back2, true)
            DisableControlAction(0, KEY.copy, true)
            if IsDisabledControlJustPressed(0, KEY.enter) then walk(false)
            elseif IsDisabledControlJustPressed(0, KEY.back) or IsDisabledControlJustPressed(0, KEY.back2) then stop()
            elseif IsDisabledControlJustPressed(0, KEY.copy) then copyName() end
            local now = GetGameTimer()
            if active and walking and now > nextFallCheck then
                nextFallCheck = now + 500
                if GetEntityCoords(cache.ped).z < minZ - 20.0 then
                    local p = floorPoint()
                    SetEntityCoords(cache.ped, p.x, p.y, p.z, false, false, false, false)
                end
            end
        else
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true) -- push to talk stays live
            heading = heading - GetDisabledControlNormal(0, 1) * 6.0
            tilt = math.max(-0.4, math.min(1.6, tilt + GetDisabledControlNormal(0, 2) * 0.04))
            if IsDisabledControlPressed(0, KEY.q) then heading = heading + 1.5 end
            if IsDisabledControlPressed(0, KEY.e) then heading = heading - 1.5 end
            if IsDisabledControlJustPressed(0, KEY.wheelUp) then radius = math.max(3.0, radius * 0.9) end
            if IsDisabledControlJustPressed(0, KEY.wheelDown) then radius = math.min(400.0, radius * 1.1) end
            placeCam()
            if IsDisabledControlJustPressed(0, KEY.right) then loadShell(idx + 1)
            elseif IsDisabledControlJustPressed(0, KEY.left) then loadShell(idx - 1)
            elseif IsDisabledControlJustPressed(0, KEY.up) then loadShell(idx + 10)
            elseif IsDisabledControlJustPressed(0, KEY.down) then loadShell(idx - 10)
            elseif IsDisabledControlJustPressed(0, KEY.enter) then if obj then walk(true) end
            elseif IsDisabledControlJustPressed(0, KEY.back) or IsDisabledControlJustPressed(0, KEY.back2) then stop()
            elseif IsDisabledControlJustPressed(0, KEY.copy) then copyName() end
        end
        Wait(0)
    end
end

RegisterCommand('shells', function(_, args)
    if active then return stop() end
    if cache.vehicle then return lib.notify({ type = 'error', description = 'Get out of the vehicle first' }) end
    local allowed, shells = lib.callback.await('dps-shellbrowser:open', false)
    if not allowed then return lib.notify({ type = 'error', description = 'Shell browser is for admins' }) end
    if not shells or #shells == 0 then return lib.notify({ type = 'error', description = 'No shells found in qs-housing config' }) end
    list = shells

    local start, want = 1, args[1]
    if want then
        local n = tonumber(want)
        if n then start = math.max(1, math.min(#list, math.floor(n)))
        else
            want = want:lower()
            for i, m in ipairs(list) do
                if m:lower():find(want, 1, true) then start = i break end
            end
        end
    end

    local ped = cache.ped
    local p = GetEntityCoords(ped)
    back = vec4(p.x, p.y, p.z, GetEntityHeading(ped))
    wasGod = GetPlayerInvincible(cache.playerId)
    SetEntityInvincible(ped, true)
    active, walking = true, false
    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', BASE.x, BASE.y, BASE.z + 20.0, 0.0, 0.0, 0.0, 60.0, false, 0)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)
    loadShell(start)
    CreateThread(loop)
end, false)

TriggerEvent('chat:addSuggestion', '/shells', 'Browse every housing shell (admin)', {
    { name = 'start', help = 'optional: a number or part of a shell name' },
})

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then stop() end
end)
