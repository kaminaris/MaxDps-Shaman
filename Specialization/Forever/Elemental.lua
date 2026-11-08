local _, addonTable = ...
local Shaman = addonTable.Shaman
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Elemental = {}

function Shaman:Elemental()
    if MaxDps:SmartAoe() <= 1 then
        if (not GetTotemInfo(1)) and not MaxDps.IsSpellOnCooldown(3599, true) then return 3599 end --  Searing Totem
        if (not GetTotemInfo(1)) and not MaxDps.IsSpellOnCooldown(8050, true) then return 8050 end --  Flame Shock
        if not MaxDps.IsSpellOnCooldown(408490, true) then return 408490 end --  Lava Burst
        if not MaxDps.IsSpellOnCooldown(421, true) then return 421 end --  Chain Lightning
        if not MaxDps.IsSpellOnCooldown(403, true) then return 403 end --  Lightning Bolt
    end

    if MaxDps:SmartAoe() >= 2 then
        if (not GetTotemInfo(1)) and not MaxDps.IsSpellOnCooldown(8190, true) then return 8190 end --  Magma Totem
        if (not GetTotemInfo(1)) and not MaxDps.IsSpellOnCooldown(8050, true) then return 8050 end --  Flame Shock
        if not MaxDps.IsSpellOnCooldown(408490, true) then return 408490 end --  Lava Burst
        if not MaxDps.IsSpellOnCooldown(421, true) then return 421 end --  Chain Lightning
        if not MaxDps.IsSpellOnCooldown(403, true) then return 403 end --  Lightning Bolt
    end
end
