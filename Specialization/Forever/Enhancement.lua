local _, addonTable = ...
local Shaman = addonTable.Shaman
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Enhancement = {}

function Shaman:Enhancement()
    if not MaxDps.IsTrackedAuraActive(8075) then return 8075 end --  Strength of Earth Totem
    if not MaxDps.IsTrackedAuraActive(8835) then return 8835 end --  Grace of Air Totem
    if not MaxDps.IsTrackedAuraActive(3599) then return 3599 end --  Searing Totem
    if not MaxDps.IsSpellOnCooldown(17364, true) then return 17364 end --  Stormstrike
    if (MaxDps.Stacks("player", 408505, "HELPFUL") >= 5) then return 403 end --  Lightning Bolt
    if not MaxDps.IsSpellOnCooldown(8042, true) then return 8042 end --  Earth Shock
end
