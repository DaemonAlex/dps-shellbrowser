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
