local _, addonTable = ...
local Shaman = addonTable.Shaman
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Restoration = {}

function Shaman:Restoration()
    if MaxDps:SmartAoe() <= 1 then
        if not MaxDps.IsSpellOnCooldown(403, true) then return 403 end --  Lightning Bolt
    end

    if MaxDps:SmartAoe() >= 2 then
        if not MaxDps.IsSpellOnCooldown(408341, true) then return 408341 end --  Fire Nova
        if not MaxDps.IsSpellOnCooldown(403, true) then return 403 end --  Lightning Bolt
    end
end
