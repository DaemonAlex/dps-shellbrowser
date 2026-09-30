-- Run from the resource folder: lua5.4 tests/run.lua [path to qs-housing main.lua]
-- FiveM vector helpers do not exist in plain Lua; stand-ins so vendor configs load.
local function vec(...) return { ... } end
vec3, vec4, vector3, vector4 = vec3 or vec, vec4 or vec, vector3 or vec, vector4 or vec
dofile('server/parse.lua')
local fails = 0
local function check(name, ok) print((ok and 'PASS ' or 'FAIL ') .. name); if not ok then fails = fails + 1 end end

local sample = [[
Config.Other = { model = 'not_a_shell' }
Config.Shells = {
    { model = 'shell_a', stash = {} },
    -- { model = 'shell_off' },
    { model = "shell_b" },
    { model = 'shell_a' },
}
Config.After = { model = 'also_not' }
]]
local r = ParseShells(sample)
check('reads only the Config.Shells block', #r == 2 and r[1] == 'shell_a' and r[2] == 'shell_b')
check('nil input gives empty list', #ParseShells(nil) == 0)
check('no Config.Shells gives empty list', #ParseShells('Config.X = {}') == 0)

local good = { name = 'greenroom', label = 'Green Room', shell = 'k4_warehouse3_shell',
    entrance = { x = 690.36, y = 588.38, z = 131.06, h = 343.8 }, exit = { x = 3.2, y = -7.5, z = 1.1, h = 10.0 } }
check('valid portal passes', ValidatePortal(good))
local function with(k, v) local c = {}; for a, b in pairs(good) do c[a] = b end; c[k] = v; return c end
check('bad name rejected', not ValidatePortal(with('name', 'green room!')))
check('empty label rejected', not ValidatePortal(with('label', '')))
check('exit far outside shell rejected', not ValidatePortal(with('exit', { x = 900, y = 0, z = 0, h = 0 })))
check('NaN coord rejected', not ValidatePortal(with('entrance', { x = 0/0, y = 0, z = 0, h = 0 })))
check('non-table rejected', not ValidatePortal('x'))

local fsrc = [[
Config.Furniture = {
    ['toilet'] = { label = 'Toilet', items = {
        [1] = { ['object'] = 'prop_ld_toilet_01', ['label'] = 'Old toilet', ['img'] = Config.ImagePath .. 'a.png' },
        [2] = { ['object'] = 'prop_toilet_01', ['label'] = 'Toilet' },
    } },
    ['empty'] = { label = 'Empty', items = {} },
}
]]
local cats, models = ParseFurniture(fsrc, 'nui://x/')
check('furniture: one category with items', #cats == 1 and #cats[1].items == 2)
check('furniture: image path joined', cats[1].items[1].img == 'nui://x/a.png')
check('furniture: models set', models.prop_ld_toilet_01 and models.prop_toilet_01)
check('furniture: bad file gives empty list', #ParseFurniture('this is not lua', '') == 0)
check('furniture: file cannot reach os', #ParseFurniture('os.exit(1)', '') == 0)
check('prop valid', ValidateProp({ model = 'prop_toilet_01', x = 1, y = 2, z = 0.5, h = 90 }, models))
check('prop unknown model rejected', not ValidateProp({ model = 'nope', x = 1, y = 2, z = 0, h = 0 }, models))
check('prop far away rejected', not ValidateProp({ model = 'prop_toilet_01', x = 5000, y = 2, z = 0, h = 0 }, models))

local path = arg[1]
local fpath = arg[2]
if fpath then
    local f = assert(io.open(fpath, 'r'))
    local lc, lm = ParseFurniture(f:read('a'), 'nui://qs-housing/web/images/'); f:close()
    local n = 0; for _ in pairs(lm) do n = n + 1 end
    print(('live furniture: %d categories, %d items'):format(#lc, n))
    check('live furniture has items', n > 0)
end
if path then
    local f = assert(io.open(path, 'r'))
    local live = ParseShells(f:read('a')); f:close()
    local seen, dup = {}, false
    for _, m in ipairs(live) do if seen[m] then dup = true end; seen[m] = true end
    print(('live config: %d shells, first %s, last %s'):format(#live, live[1], live[#live]))
    check('live config has shells', #live > 0)
    check('live config has no duplicates', not dup)
end

print(fails == 0 and 'ALL PASS' or (fails .. ' FAILED'))
os.exit(fails == 0 and 0 or 1)
