-- Run from the resource folder: lua5.4 tests/run.lua [path to qs-housing main.lua]
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

local path = arg[1]
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
