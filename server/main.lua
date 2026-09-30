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
