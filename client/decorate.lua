-- CLIENT. /decorate inside a portal shell (admin).
-- Menu: add furniture from the qs-housing catalogue (with pictures), or edit
-- pieces already placed. Placing: the piece follows where you look.
-- The loop runs only while placing or editing.

local busy = false
local catalogue

local K = { place = 24, place2 = 191, cancel = 194, cancel2 = 177, rotL = 174, rotR = 175,
            up = 172, down = 173, wheelUp = 241, wheelDown = 242, edit = 38, remove = 178 }

local function hereName()
    local me = GetEntityCoords(cache.ped)
    local best, bestD
    for name, p in pairs(DpsPortals) do
        local d = #(me - p.shellPos)
        if d < 120.0 and (not bestD or d < bestD) then best, bestD = name, d end
    end
    return best
end

local function camForward()
    local r = GetGameplayCamRot(2)
    local x, z = math.rad(r.x), math.rad(r.z)
    return vec3(-math.sin(z) * math.abs(math.cos(x)), math.cos(z) * math.abs(math.cos(x)), math.sin(x))
end

local function aim(ignore)
    local from = GetGameplayCamCoord()
    local to = from + camForward() * 12.0
    local ray = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, 1 | 16, ignore or cache.ped, 7)
    local _, hit, pos, _, ent = GetShapeTestResult(ray)
    return hit == 1, pos, ent
end

local function blockKeys()
    DisableControlAction(0, 24, true); DisableControlAction(0, 25, true)
    DisableControlAction(0, 140, true); DisableControlAction(0, 141, true); DisableControlAction(0, 142, true)
    DisableControlAction(0, 14, true); DisableControlAction(0, 15, true); DisableControlAction(0, 16, true); DisableControlAction(0, 17, true)
    DisableControlAction(0, 37, true)
    for _, c in pairs(K) do DisableControlAction(0, c, true) end
end

local function pressed(a, b)
    return IsDisabledControlJustPressed(0, a) or (b and IsDisabledControlJustPressed(0, b))
end

-- Place a new piece (id nil) or move an existing one (id + start heading).
local function place(name, model, id, heading, hideEnt)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not pcall(lib.requestModel, hash, 15000) then
        return lib.notify({ type = 'error', description = model .. ' did not load' })
    end
    busy = true
    if hideEnt then SetEntityVisible(hideEnt, false, false); SetEntityCollision(hideEnt, false, false) end
    local ghost = CreateObjectNoOffset(hash, 0.0, 0.0, 0.0, false, false, false)
    SetEntityCollision(ghost, false, false)
    SetEntityAlpha(ghost, 190, false)
    FreezeEntityPosition(ghost, true)
    SetModelAsNoLongerNeeded(hash)
    local mn = GetModelDimensions(hash)
    local h, lift = heading or GetEntityHeading(cache.ped), 0.0
    -- fine = the piece stays put and keys nudge it; starts on when moving a placed piece
    local fine, at = false, nil
    if hideEnt and DoesEntityExist(hideEnt) then fine, at = true, GetEntityCoords(hideEnt) end

    local function help()
        if fine then
            lib.showTextUI('**Fine tune ' .. model .. '**  \n[Arrows] slide  \n[Page Up / Down] up / down  \n[Q E or Wheel] turn  \nHold [Shift] for big steps  \n[Tab] follow my look again  \n[Left click or Enter] save  \n[Backspace] cancel', { position = 'left-center' })
        else
            lib.showTextUI('**Placing ' .. model .. '**  \n[Left click or Enter] put it here  \n[Wheel or Left Right] turn  \n[Up Down] raise / lower  \n[Tab] fine tune  \n[Backspace] cancel', { position = 'left-center' })
        end
    end
    help()

    -- tap = one step, hold = repeat after a short pause
    local held = {}
    local function tap(c)
        if not IsDisabledControlPressed(0, c) then held[c] = nil return false end
        local now = GetGameTimer()
        if not held[c] then held[c] = now + 300 return true end
        if now >= held[c] then held[c] = now + 40 return true end
        return false
    end

    while busy do
        blockKeys()
        DisableControlAction(0, 21, true); DisableControlAction(0, 10, true); DisableControlAction(0, 11, true); DisableControlAction(0, 44, true)
        local hit
        if pressed(37) then
            fine = not fine
            if fine then at = GetEntityCoords(ghost) end
            help()
        end
        if fine then
            hit = true
            local big = IsDisabledControlPressed(0, 21)
            local step, turn = big and 0.10 or 0.01, big and 15.0 or 1.0
            local r = math.rad(GetGameplayCamRot(2).z)
            local fwd, right = vec3(-math.sin(r), math.cos(r), 0.0), vec3(math.cos(r), math.sin(r), 0.0)
            if tap(K.up) then at = at + fwd * step end
            if tap(K.down) then at = at - fwd * step end
            if tap(K.rotR) then at = at + right * step end
            if tap(K.rotL) then at = at - right * step end
            if tap(10) then at = at + vec3(0.0, 0.0, step) end
            if tap(11) then at = at - vec3(0.0, 0.0, step) end
            if tap(44) or pressed(K.wheelUp) then h = h + turn end
            if tap(38) or pressed(K.wheelDown) then h = h - turn end
            SetEntityCoordsNoOffset(ghost, at.x, at.y, at.z, false, false, false)
        else
            local pos
            hit, pos = aim(ghost)
            if hit then
                SetEntityCoordsNoOffset(ghost, pos.x, pos.y, pos.z - mn.z + lift, false, false, false)
            end
            if IsDisabledControlPressed(0, K.rotL) then h = h + 2.0 end
            if IsDisabledControlPressed(0, K.rotR) then h = h - 2.0 end
            if pressed(K.wheelUp) then h = h + 15.0 end
            if pressed(K.wheelDown) then h = h - 15.0 end
            if IsDisabledControlPressed(0, K.up) then lift = lift + 0.01 end
            if IsDisabledControlPressed(0, K.down) then lift = lift - 0.01 end
        end
        h = h % 360.0
        SetEntityHeading(ghost, h)

        if pressed(K.place, K.place2) and hit then
            local base = DpsPortals[name] and DpsPortals[name].shellPos
            local at = GetEntityCoords(ghost)
            if base then
                local off = at - base
                local ok, err = lib.callback.await('dps-shellbrowser:placeProp', false, name,
                    { model = model, x = off.x, y = off.y, z = off.z, h = h }, id)
                lib.notify({ type = ok and 'success' or 'error', description = ok and 'Placed' or err })
                if not ok and hideEnt and DoesEntityExist(hideEnt) then SetEntityVisible(hideEnt, true, false); SetEntityCollision(hideEnt, true, true) end
            end
            busy = false
        elseif pressed(K.cancel, K.cancel2) then
            busy = false
            if hideEnt and DoesEntityExist(hideEnt) then SetEntityVisible(hideEnt, true, false); SetEntityCollision(hideEnt, true, true) end
        end
        Wait(0)
    end
    DeleteEntity(ghost)
    lib.hideTextUI()
end

-- Look at a placed piece: E moves it, Delete removes it.
local function edit(name)
    busy = true
    local last
    lib.showTextUI('**Edit furniture**  \nLook at a piece  \n[E] move it  \n[Delete] remove it  \n[Backspace] done', { position = 'left-center' })
    while busy do
        blockKeys()
        local _, _, ent = aim()
        local info = ent and ent ~= 0 and DpsPieceByEntity[ent]
        if info and info.name ~= name then info = nil end
        local target = info and ent or nil
        if last ~= target then
            if last and DoesEntityExist(last) then SetEntityDrawOutline(last, false) end
            if target then SetEntityDrawOutline(target, true) end
            last = target
        end
        if target and pressed(K.edit) then
            SetEntityDrawOutline(target, false); last = nil
            busy = false
            lib.hideTextUI()
            return place(name, info.model, info.id, GetEntityHeading(target), target)
        elseif target and pressed(K.remove) then
            local ok, err = lib.callback.await('dps-shellbrowser:removeProp', false, name, info.id)
            lib.notify({ type = ok and 'success' or 'error', description = ok and 'Removed' or err })
            last = nil
        elseif pressed(K.cancel, K.cancel2) then
            busy = false
        end
        Wait(0)
    end
    if last and DoesEntityExist(last) then SetEntityDrawOutline(last, false) end
    lib.hideTextUI()
end

local function itemsMenu(name, cat)
    local opts = {}
    for _, it in ipairs(cat.items) do
        opts[#opts + 1] = { title = it.label, description = it.object, image = it.img,
            onSelect = function() CreateThread(function() place(name, it.object) end) end }
    end
    lib.registerContext({ id = 'dps_decor_items', title = cat.label, menu = 'dps_decor_cats', options = opts })
    lib.showContext('dps_decor_items')
end

local function catsMenu(name)
    local opts = {}
    for _, c in ipairs(catalogue) do
        opts[#opts + 1] = { title = c.label, description = #c.items .. ' items', arrow = true,
            onSelect = function() itemsMenu(name, c) end }
    end
    lib.registerContext({ id = 'dps_decor_cats', title = 'Add furniture', menu = 'dps_decor', options = opts })
    lib.showContext('dps_decor_cats')
end

RegisterCommand('decorate', function()
    if busy then return end
    local name = hereName()
    if not name then return lib.notify({ type = 'error', description = 'Go inside a portal room first' }) end
    catalogue = catalogue or lib.callback.await('dps-shellbrowser:furniture', false)
    if not catalogue then return lib.notify({ type = 'error', description = 'Decorating is for admins' }) end
    if #catalogue == 0 then return lib.notify({ type = 'error', description = 'Could not read the housing furniture list' }) end
    local count = #(DpsPortals[name].data.props or {})
    lib.registerContext({
        id = 'dps_decor',
        title = 'Decorate: ' .. DpsPortals[name].data.label,
        options = {
            { title = 'Add furniture', description = 'Pick from the housing furniture list', arrow = true, onSelect = function() catsMenu(name) end },
            { title = 'Move or remove furniture', description = count .. ' pieces placed', onSelect = function() CreateThread(function() edit(name) end) end },
        },
    })
    lib.showContext('dps_decor')
end, false)

TriggerEvent('chat:addSuggestion', '/decorate', 'Decorate the portal room you are in (admin)')
