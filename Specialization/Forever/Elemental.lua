local _, addonTable = ...
local Shaman = addonTable.Shaman
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Elemental = {}

function Shaman:Elemental()
    local isTotemSecret = C_Secrets.ShouldTotemSlotBeSecret
    if MaxDps:SmartAoe() <= 1 then
        if ((not IsInInstance() and not isTotemSecret(1) and not GetTotemInfo(1)) or not MaxDps.IsTrackedAuraActive(3599)) and not MaxDps.IsSpellOnCooldown(3599, true) then return 3599 end --  Searing Totem
        if ((not IsInInstance() and not isTotemSecret(1) and not GetTotemInfo(1)) or not MaxDps.IsTrackedAuraActive(8050)) and not MaxDps.IsSpellOnCooldown(8050, true) then return 8050 end --  Flame Shock
        if not MaxDps.IsSpellOnCooldown(408490, true) then return 408490 end --  Lava Burst
        if not MaxDps.IsSpellOnCooldown(421, true) then return 421 end --  Chain Lightning
        if not MaxDps.IsSpellOnCooldown(403, true) then return 403 end --  Lightning Bolt
    end

    if MaxDps:SmartAoe() >= 2 then
        if ((not IsInInstance() and not isTotemSecret(1) and not GetTotemInfo(1)) or not MaxDps.IsTrackedAuraActive(8190)) and not MaxDps.IsSpellOnCooldown(8190, true) then return 8190 end --  Magma Totem
        if ((not IsInInstance() and not isTotemSecret(1) and not GetTotemInfo(1)) or not MaxDps.IsTrackedAuraActive(8050)) and not MaxDps.IsSpellOnCooldown(8050, true) then return 8050 end --  Flame Shock
        if not MaxDps.IsSpellOnCooldown(408490, true) then return 408490 end --  Lava Burst
        if not MaxDps.IsSpellOnCooldown(421, true) then return 421 end --  Chain Lightning
        if not MaxDps.IsSpellOnCooldown(403, true) then return 403 end --  Lightning Bolt
    end
end
