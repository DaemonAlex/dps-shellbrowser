-- SERVER. Reads the shell model names out of qs-housing's Config.Shells block.
-- qs-housing is the single source of truth, so the browser never drifts from
-- what housing can actually place. Commented-out entries are skipped.

---@param src string contents of qs-housing/config/main.lua
---@return string[] models in config order, no duplicates
function ParseShells(src)
    local out, seen = {}, {}
    if type(src) ~= 'string' then return out end
    local s = src:find('Config%.Shells%s*=')
    if not s then return out end
    local first = true
    for line in src:sub(s):gmatch('[^\n]*') do
        if not first and line:match('^Config%.') then break end
        first = false
        if not line:match('^%s*%-%-') then
            local m = line:match("model%s*=%s*'([^']+)'") or line:match('model%s*=%s*"([^"]+)"')
            if m and not seen[m] then
                seen[m] = true
                out[#out + 1] = m
            end
        end
    end
    return out
end

-- Checks a portal sent by a client before it is saved.
---@return boolean ok, string? err
function ValidatePortal(d)
    if type(d) ~= 'table' then return false, 'Bad data' end
    if type(d.name) ~= 'string' or not d.name:match('^[%w_%-]+$') or #d.name > 32 then return false, 'Bad name' end
    if type(d.label) ~= 'string' or #d.label == 0 or #d.label > 40 then return false, 'Label must be 1 to 40 letters' end
    if type(d.shell) ~= 'string' then return false, 'No shell picked' end
    local function num(v, lim) return type(v) == 'number' and v == v and math.abs(v) <= lim end
    local e, x = d.entrance, d.exit
    if type(e) ~= 'table' or not (num(e.x, 20000) and num(e.y, 20000) and num(e.z, 3000) and num(e.h, 720)) then return false, 'Bad door spot' end
    if type(x) ~= 'table' or not (num(x.x, 300) and num(x.y, 300) and num(x.z, 300) and num(x.h, 720)) then return false, 'The way out must be inside the shell' end
    return true
end

-- Reads qs-housing's furniture catalogue (config/furniture.lua) in a sandbox:
-- the file only sees a Config table, so it cannot touch anything else.
---@return table[] categories { key, label, items = { { object, label, img } } } sorted by label
---@return table<string, boolean> models every allowed model name
function ParseFurniture(src, imagePath)
    local cats, models = {}, {}
    if type(src) ~= 'string' then return cats, models end
    local lib_ = { math = math, string = string, table = table, pairs = pairs, ipairs = ipairs,
                   vector3 = vector3, vec3 = vec3, vector4 = vector4, vec4 = vec4 }
    local env = setmetatable({ Config = { ImagePath = imagePath or '' } }, { __index = lib_ })
    local chunk = load(src, 'furniture', 't', env)
    if not chunk or not pcall(chunk) then return cats, models end
    for key, c in pairs(env.Config.Furniture or {}) do
        local items = {}
        for _, it in ipairs(type(c.items) == 'table' and c.items or {}) do
            local obj = type(it) == 'table' and it.object or nil
            if type(obj) == 'string' and not models[obj] then
                models[obj] = true
                items[#items + 1] = { object = obj, label = tostring(it.label or obj), img = type(it.img) == 'string' and it.img or nil }
            end
        end
        if #items > 0 then
            table.sort(items, function(a, b) return a.label < b.label end)
            cats[#cats + 1] = { key = key, label = tostring(c.label or key), items = items }
        end
    end
    table.sort(cats, function(a, b) return a.label < b.label end)
    return cats, models
end

-- Checks one placed piece. Offsets are measured from the shell's spawn point.
function ValidateProp(p, models)
    if type(p) ~= 'table' or type(p.model) ~= 'string' or not models[p.model] then return false, 'Not a furniture item' end
    local function num(v, lim) return type(v) == 'number' and v == v and math.abs(v) <= lim end
    if not (num(p.x, 300) and num(p.y, 300) and num(p.z, 300) and num(p.h, 720)) then return false, 'Piece must be inside the shell' end
    return true
end
