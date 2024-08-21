local _, addonTable = ...
local Shaman = addonTable.Shaman
local MaxDps = _G.MaxDps
if not MaxDps then return end

local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = C_UnitAuras.GetAuraDataByIndex
local UnitAuraByName = C_UnitAuras.GetAuraDataBySpellName
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCount = C_Spell.GetSpellCastCount

local ManaPT = Enum.PowerType.Mana
local RagePT = Enum.PowerType.Rage
local FocusPT = Enum.PowerType.Focus
local EnergyPT = Enum.PowerType.Energy
local ComboPointsPT = Enum.PowerType.ComboPoints
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower
local SoulShardsPT = Enum.PowerType.SoulShards
local LunarPowerPT = Enum.PowerType.LunarPower
local HolyPowerPT = Enum.PowerType.HolyPower
local MaelstromPT = Enum.PowerType.Maelstrom
local ChiPT = Enum.PowerType.Chi
local InsanityPT = Enum.PowerType.Insanity
local ArcaneChargesPT = Enum.PowerType.ArcaneCharges
local FuryPT = Enum.PowerType.Fury
local PainPT = Enum.PowerType.Pain
local EssencePT = Enum.PowerType.Essence
local RuneBloodPT = Enum.PowerType.RuneBlood
local RuneFrostPT = Enum.PowerType.RuneFrost
local RuneUnholyPT = Enum.PowerType.RuneUnholy

local fd
local ttd
local timeShift
local gcd
local cooldown
local buff
local debuff
local talents
local targets
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc
local timeInCombat
local className, classFilename, classId = UnitClass('player')
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None'
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Maelstrom
local MaelstromMax
local MaelstromDeficit
local Mana
local ManaMax
local ManaDeficit

local Enhancement = {}

local trinketone_is_weird
local trinkettwo_is_weird
local min_talented_cd_remains

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if not C_Spell.IsSpellUsable(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'KillShot' then
        if (classtable.SicEmBuff and not buff[classtable.SicEmBuff].up) or (classtable.HuntersPreyBuff and not buff[classtable.HuntersPreyBuff].up) and targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'HammerofWrath' then
        if ( (classtable.AvengingWrathBuff and not buff[classtable.AvengingWrathBuff].up) or (classtable.FinalVerdictBuff and not buff[classtable.FinalVerdictBuff].up) ) and targethealthPerc > 20 then
            return false
        end
    end
    if spellstring == 'Execute' then
        if (classtable.SuddenDeathBuff and not buff[classtable.SuddenDeathBuff].up) and targethealthPerc > 35 then
            return false
        end
    end
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end
local function MaxGetSpellCost(spell,power)
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' then return 0 end
    for i,costtable in pairs(costs) do
        if costtable.name == power then
            return costtable.cost
        end
    end
    return 0
end



local function CheckTrinketNames(checkName)
    --if slot == 1 then
    --    slot = 13
    --end
    --if slot == 2 then
    --    slot = 14
    --end
    for i=13,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = C_Item.GetItemInfo(itemID)
        if checkName == itemName then
            return true
        end
    end
    return false
end


local function CheckTrinketCooldown(slot)
    if slot == 1 then
        slot = 13
    end
    if slot == 2 then
        slot = 14
    end
    if slot == 13 or slot == 14 then
        local itemID = GetInventoryItemID('player', slot)
        local _, duration, _ = C_Item.GetItemCooldown(itemID)
        if duration == 0 then return true else return false end
    else
        local tOneitemID = GetInventoryItemID('player', 13)
        local tTwoitemID = GetInventoryItemID('player', 14)
        local tOneitemName = C_Item.GetItemInfo(tOneitemID)
        local tTwoitemName = C_Item.GetItemInfo(tTwoitemID)
        if tOneitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tOneitemID)
            if duration == 0 then return true else return false end
        end
        if tTwoitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tTwoitemID)
            if duration == 0 then return true else return false end
        end
    end
end




local function CheckPrevSpell(spell)
    if MaxDps and MaxDps.spellHistory then
        if MaxDps.spellHistory[1] then
            if MaxDps.spellHistory[1] == spell then
                return true
            end
            if MaxDps.spellHistory[1] ~= spell then
                return false
            end
        end
    end
    return true
end


local function boss()
    if UnitExists('boss1')
    or UnitExists('boss2')
    or UnitExists('boss3')
    or UnitExists('boss4')
    or UnitExists('boss5')
    or UnitExists('boss6')
    or UnitExists('boss7')
    or UnitExists('boss8')
    or UnitExists('boss9')
    or UnitExists('boss10') then
        return true
    end
    return false
end


function Enhancement:precombat()
    --if (MaxDps:FindSpell(classtable.WindfuryWeapon) and CheckSpellCosts(classtable.WindfuryWeapon, 'WindfuryWeapon')) and cooldown[classtable.WindfuryWeapon].ready then
    --    return classtable.WindfuryWeapon
    --end
    --if (MaxDps:FindSpell(classtable.FlametongueWeapon) and CheckSpellCosts(classtable.FlametongueWeapon, 'FlametongueWeapon')) and cooldown[classtable.FlametongueWeapon].ready then
    --    return classtable.FlametongueWeapon
    --end
    --if (MaxDps:FindSpell(classtable.Skyfury) and CheckSpellCosts(classtable.Skyfury, 'Skyfury')) and cooldown[classtable.Skyfury].ready then
    --    return classtable.Skyfury
    --end
    --if (MaxDps:FindSpell(classtable.LightningShield) and CheckSpellCosts(classtable.LightningShield, 'LightningShield')) and cooldown[classtable.LightningShield].ready then
    --    return classtable.LightningShield
    --end
    --min_talented_cd_remains = ( ( cooldown[classtable.FeralSpirit].remains % ( 1 + 1.5 * (talents[classtable.WitchDoctorsAncestry] and talents[classtable.WitchDoctorsAncestry] or 0) ) ) + 1000 * not talents[classtable.FeralSpirit] ) <( cooldown[classtable.DoomWinds].remains + 1000 * not talents[classtable.DoomWinds] ) <( cooldown[classtable.Ascendance].remains + 1000 * not talents[classtable.Ascendance] )
end
function Enhancement:single()
    if (MaxDps:FindSpell(classtable.PrimordialWave) and CheckSpellCosts(classtable.PrimordialWave, 'PrimordialWave')) and (not debuff[classtable.FlameShockDeBuff].up and talents[classtable.LashingFlames] and ( math.huge >( cooldown[classtable.PrimordialWave].remains % ( 1 + (MaxDps.tier and MaxDps.tier[31].count >= 4 and 1 or 0) ) ) or math.huge <6 )) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up and talents[classtable.LashingFlames]) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.ElementalBlast) and CheckSpellCosts(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and talents[classtable.ElementalSpirits] and buff[classtable.FeralSpiritBuff].up >= 4) and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    if (MaxDps:FindSpell(classtable.Sundering) and CheckSpellCosts(classtable.Sundering, 'Sundering')) and ((MaxDps.tier and MaxDps.tier[30].count >= 2) and math.huge >= cooldown[classtable.Sundering].remains) and cooldown[classtable.Sundering].ready then
        return classtable.Sundering
    end
    if (MaxDps:FindSpell(classtable.Tempest) and CheckSpellCosts(classtable.Tempest, 'Tempest')) and cooldown[classtable.Tempest].ready then
        return classtable.Tempest
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and not buff[classtable.CracklingThunderBuff].up and buff[classtable.AscendanceBuff].up and talents[classtable.ThorimsInvocation] and ( buff[classtable.AscendanceBuff].remains >( cooldown[classtable.Strike].remains + gcd ) )) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.Stormstrike) and CheckSpellCosts(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.DoomWindsBuff].up or talents[classtable.DeeplyRootedElements] or ( talents[classtable.Stormblast] and buff[classtable.StormbringerBuff].up )) and cooldown[classtable.Stormstrike].ready then
        return classtable.Stormstrike
    end
    if (MaxDps:FindSpell(classtable.LavaLash) and CheckSpellCosts(classtable.LavaLash, 'LavaLash')) and (buff[classtable.HotHandBuff].up) and cooldown[classtable.LavaLash].ready then
        return classtable.LavaLash
    end
    if (MaxDps:FindSpell(classtable.ElementalBlast) and CheckSpellCosts(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and cooldown[classtable.ElementalBlast].charges == cooldown[classtable.ElementalBlast].maxCharges) and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >= 8 and buff[classtable.PrimordialWaveBuff].up and math.huge >buff[classtable.PrimordialWaveBuff].remains and ( not buff[classtable.SplinteredElementsBuff].up or boss and ttd <= 12 )) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 8 and buff[classtable.CracklingThunderBuff].up and talents[classtable.ElementalSpirits]) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.ElementalBlast) and CheckSpellCosts(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 8 and ( buff[classtable.FeralSpiritBuff].up >= 2 or not talents[classtable.ElementalSpirits] )) and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (not talents[classtable.ThorimsInvocation] and buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (( ( buff[classtable.MaelstromWeaponBuff].count >= 8 ) or ( talents[classtable.StaticAccumulation] and buff[classtable.MaelstromWeaponBuff].count >= 5 ) ) and not buff[classtable.PrimordialWaveBuff].up) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.CrashLightning) and CheckSpellCosts(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.AlphaWolf] and buff[classtable.FeralSpiritBuff].up and buff[classtable.FeralSpiritBuff].up == 0) and cooldown[classtable.CrashLightning].ready then
        return classtable.CrashLightning
    end
    if (MaxDps:FindSpell(classtable.PrimordialWave) and CheckSpellCosts(classtable.PrimordialWave, 'PrimordialWave')) and (math.huge >( cooldown[classtable.PrimordialWave].remains % ( 1 + (MaxDps.tier and MaxDps.tier[31].count >= 4 and 1 or 0) ) ) or math.huge <6) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.IceStrike) and CheckSpellCosts(classtable.IceStrike, 'IceStrike')) and (talents[classtable.ElementalAssault] and talents[classtable.SwirlingMaelstrom]) and cooldown[classtable.IceStrike].ready then
        return classtable.IceStrike
    end
    if (MaxDps:FindSpell(classtable.LavaLash) and CheckSpellCosts(classtable.LavaLash, 'LavaLash')) and (talents[classtable.LashingFlames]) and cooldown[classtable.LavaLash].ready then
        return classtable.LavaLash
    end
    if (MaxDps:FindSpell(classtable.IceStrike) and CheckSpellCosts(classtable.IceStrike, 'IceStrike')) and (not buff[classtable.IceStrikeBuff].up) and cooldown[classtable.IceStrike].ready then
        return classtable.IceStrike
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (buff[classtable.HailstormBuff].up) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.LavaLash) and CheckSpellCosts(classtable.LavaLash, 'LavaLash')) and cooldown[classtable.LavaLash].ready then
        return classtable.LavaLash
    end
    if (MaxDps:FindSpell(classtable.IceStrike) and CheckSpellCosts(classtable.IceStrike, 'IceStrike')) and cooldown[classtable.IceStrike].ready then
        return classtable.IceStrike
    end
    if (MaxDps:FindSpell(classtable.Windstrike) and CheckSpellCosts(classtable.Windstrike, 'Windstrike')) and cooldown[classtable.Windstrike].ready then
        return classtable.Windstrike
    end
    if (MaxDps:FindSpell(classtable.Stormstrike) and CheckSpellCosts(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        return classtable.Stormstrike
    end
    if (MaxDps:FindSpell(classtable.Sundering) and CheckSpellCosts(classtable.Sundering, 'Sundering')) and (math.huge >= cooldown[classtable.Sundering].remains) and cooldown[classtable.Sundering].ready then
        return classtable.Sundering
    end
    if (MaxDps:FindSpell(classtable.FireNova) and CheckSpellCosts(classtable.FireNova, 'FireNova')) and (talents[classtable.SwirlingMaelstrom] and debuff[classtable.FlameShockDeBuff].count  and buff[classtable.MaelstromWeaponBuff].count <MaelstromWeaponBuffmaxStacks) and cooldown[classtable.FireNova].ready then
        return classtable.FireNova
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (talents[classtable.Hailstorm] and buff[classtable.MaelstromWeaponBuff].count >= 5 and not buff[classtable.PrimordialWaveBuff].up) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.CrashLightning) and CheckSpellCosts(classtable.CrashLightning, 'CrashLightning')) and cooldown[classtable.CrashLightning].ready then
        return classtable.CrashLightning
    end
    if (MaxDps:FindSpell(classtable.FireNova) and CheckSpellCosts(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count ) and cooldown[classtable.FireNova].ready then
        return classtable.FireNova
    end
    if (MaxDps:FindSpell(classtable.EarthElemental) and CheckSpellCosts(classtable.EarthElemental, 'EarthElemental')) and cooldown[classtable.EarthElemental].ready then
        MaxDps:GlowCooldown(classtable.EarthElemental, cooldown[classtable.EarthElemental].ready)
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and buff[classtable.CracklingThunderBuff].up and talents[classtable.ElementalSpirits]) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and not buff[classtable.PrimordialWaveBuff].up) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
end
function Enhancement:aoe()
    if (MaxDps:FindSpell(classtable.CrashLightning) and CheckSpellCosts(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.CrashingStorms] and ( ( talents[classtable.UnrulyWinds] and targets >= 10 ) or targets >= 15 )) and cooldown[classtable.CrashLightning].ready then
        return classtable.CrashLightning
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (( debuff[classtable.FlameShockDeBuff].count  == targets or debuff[classtable.FlameShockDeBuff].count  == 6 ) and buff[classtable.PrimordialWaveBuff].up and buff[classtable.MaelstromWeaponBuff].count == MaelstromWeaponBuffmaxStacks and ( not buff[classtable.SplinteredElementsBuff].up or boss and ttd <= 12 or targets <= gcd )) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.LavaLash) and CheckSpellCosts(classtable.LavaLash, 'LavaLash')) and (talents[classtable.MoltenAssault] and ( talents[classtable.PrimordialWave] or talents[classtable.FireNova] ) and debuff[classtable.FlameShockDeBuff].up and ( debuff[classtable.FlameShockDeBuff].count  <targets ) and debuff[classtable.FlameShockDeBuff].count  <6) and cooldown[classtable.LavaLash].ready then
        return classtable.LavaLash
    end
    if (MaxDps:FindSpell(classtable.PrimordialWave) and CheckSpellCosts(classtable.PrimordialWave, 'PrimordialWave')) and (not buff[classtable.PrimordialWaveBuff].up) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:FindSpell(classtable.ElementalBlast) and CheckSpellCosts(classtable.ElementalBlast, 'ElementalBlast')) and (( not talents[classtable.ElementalSpirits] or ( talents[classtable.ElementalSpirits] and ( cooldown[classtable.ElementalBlast].charges == cooldown[classtable.ElementalBlast].maxCharges or buff[classtable.FeralSpiritBuff].up >= 2 ) ) ) and buff[classtable.MaelstromWeaponBuff].count == MaelstromWeaponBuffmaxStacks and ( not talents[classtable.CrashingStorms] or targets <= 3 )) and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    if (MaxDps:FindSpell(classtable.Tempest) and CheckSpellCosts(classtable.Tempest, 'Tempest')) and cooldown[classtable.Tempest].ready then
        return classtable.Tempest
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count == MaelstromWeaponBuffmaxStacks) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.CrashLightning) and CheckSpellCosts(classtable.CrashLightning, 'CrashLightning')) and (buff[classtable.DoomWindsBuff].up or not buff[classtable.CrashLightningBuff].up or ( talents[classtable.AlphaWolf] and buff[classtable.FeralSpiritBuff].up and buff[classtable.FeralSpiritBuff].up == 0 )) and cooldown[classtable.CrashLightning].ready then
        return classtable.CrashLightning
    end
    if (MaxDps:FindSpell(classtable.Sundering) and CheckSpellCosts(classtable.Sundering, 'Sundering')) and (buff[classtable.DoomWindsBuff].up or (MaxDps.tier and MaxDps.tier[30].count >= 2)) and cooldown[classtable.Sundering].ready then
        return classtable.Sundering
    end
    if (MaxDps:FindSpell(classtable.FireNova) and CheckSpellCosts(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count  == 6 or ( debuff[classtable.FlameShockDeBuff].count  >= 4 and debuff[classtable.FlameShockDeBuff].count  == targets )) and cooldown[classtable.FireNova].ready then
        return classtable.FireNova
    end
    if (MaxDps:FindSpell(classtable.LavaLash) and CheckSpellCosts(classtable.LavaLash, 'LavaLash')) and (talents[classtable.LashingFlames]) and cooldown[classtable.LavaLash].ready then
        return classtable.LavaLash
    end
    if (MaxDps:FindSpell(classtable.LavaLash) and CheckSpellCosts(classtable.LavaLash, 'LavaLash')) and (( talents[classtable.MoltenAssault] and debuff[classtable.FlameShockDeBuff].up and ( debuff[classtable.FlameShockDeBuff].count  <targets ) and debuff[classtable.FlameShockDeBuff].count  <6 ) or ( talents[classtable.AshenCatalyst] and buff[classtable.AshenCatalystBuff].count == AshenCatalystBuffmaxStacks )) and cooldown[classtable.LavaLash].ready then
        return classtable.LavaLash
    end
    if (MaxDps:FindSpell(classtable.IceStrike) and CheckSpellCosts(classtable.IceStrike, 'IceStrike')) and (talents[classtable.Hailstorm] and not buff[classtable.IceStrikeBuff].up) and cooldown[classtable.IceStrike].ready then
        return classtable.IceStrike
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (talents[classtable.Hailstorm] and buff[classtable.HailstormBuff].up) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.Sundering) and CheckSpellCosts(classtable.Sundering, 'Sundering')) and cooldown[classtable.Sundering].ready then
        return classtable.Sundering
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (talents[classtable.MoltenAssault] and not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (( talents[classtable.FireNova] or talents[classtable.PrimordialWave] ) and ( debuff[classtable.FlameShockDeBuff].count  <targets ) and debuff[classtable.FlameShockDeBuff].count  <6) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FireNova) and CheckSpellCosts(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count  >= 3) and cooldown[classtable.FireNova].ready then
        return classtable.FireNova
    end
    if (MaxDps:FindSpell(classtable.Stormstrike) and CheckSpellCosts(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.CrashLightningBuff].up and ( talents[classtable.DeeplyRootedElements] or buff[classtable.ConvergingStormsBuff].count == 6 )) and cooldown[classtable.Stormstrike].ready then
        return classtable.Stormstrike
    end
    if (MaxDps:FindSpell(classtable.CrashLightning) and CheckSpellCosts(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.CrashingStorms] and buff[classtable.ClCrashLightningBuff].up and targets >= 4) and cooldown[classtable.CrashLightning].ready then
        return classtable.CrashLightning
    end
    if (MaxDps:FindSpell(classtable.Windstrike) and CheckSpellCosts(classtable.Windstrike, 'Windstrike')) and cooldown[classtable.Windstrike].ready then
        return classtable.Windstrike
    end
    if (MaxDps:FindSpell(classtable.Stormstrike) and CheckSpellCosts(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        return classtable.Stormstrike
    end
    if (MaxDps:FindSpell(classtable.IceStrike) and CheckSpellCosts(classtable.IceStrike, 'IceStrike')) and cooldown[classtable.IceStrike].ready then
        return classtable.IceStrike
    end
    if (MaxDps:FindSpell(classtable.LavaLash) and CheckSpellCosts(classtable.LavaLash, 'LavaLash')) and cooldown[classtable.LavaLash].ready then
        return classtable.LavaLash
    end
    if (MaxDps:FindSpell(classtable.CrashLightning) and CheckSpellCosts(classtable.CrashLightning, 'CrashLightning')) and cooldown[classtable.CrashLightning].ready then
        return classtable.CrashLightning
    end
    if (MaxDps:FindSpell(classtable.FireNova) and CheckSpellCosts(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count  >= 2) and cooldown[classtable.FireNova].ready then
        return classtable.FireNova
    end
    if (MaxDps:FindSpell(classtable.ElementalBlast) and CheckSpellCosts(classtable.ElementalBlast, 'ElementalBlast')) and (( not talents[classtable.ElementalSpirits] or ( talents[classtable.ElementalSpirits] and ( cooldown[classtable.ElementalBlast].charges == cooldown[classtable.ElementalBlast].maxCharges or buff[classtable.FeralSpiritBuff].up >= 2 ) ) ) and buff[classtable.MaelstromWeaponBuff].count >= 5 and ( not talents[classtable.CrashingStorms] or targets <= 3 )) and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (not talents[classtable.Hailstorm]) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
end
function Enhancement:funnel()
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (( debuff[classtable.FlameShockDeBuff].count  == targets or debuff[classtable.FlameShockDeBuff].count  == 6 ) and buff[classtable.PrimordialWaveBuff].up and buff[classtable.MaelstromWeaponBuff].count == MaelstromWeaponBuffmaxStacks and ( not buff[classtable.SplinteredElementsBuff].up or boss and ttd <= 12 or targets <= gcd )) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.LavaLash) and CheckSpellCosts(classtable.LavaLash, 'LavaLash')) and (( talents[classtable.MoltenAssault] and debuff[classtable.FlameShockDeBuff].up and ( debuff[classtable.FlameShockDeBuff].count  <targets ) and debuff[classtable.FlameShockDeBuff].count  <6 ) or ( talents[classtable.AshenCatalyst] and buff[classtable.AshenCatalystBuff].count == AshenCatalystBuffmaxStacks )) and cooldown[classtable.LavaLash].ready then
        return classtable.LavaLash
    end
    if (MaxDps:FindSpell(classtable.PrimordialWave) and CheckSpellCosts(classtable.PrimordialWave, 'PrimordialWave')) and (not buff[classtable.PrimordialWaveBuff].up) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:FindSpell(classtable.ElementalBlast) and CheckSpellCosts(classtable.ElementalBlast, 'ElementalBlast')) and (( not talents[classtable.ElementalSpirits] or ( talents[classtable.ElementalSpirits] and ( cooldown[classtable.ElementalBlast].charges == cooldown[classtable.ElementalBlast].maxCharges or buff[classtable.FeralSpiritBuff].up ) ) ) and buff[classtable.MaelstromWeaponBuff].count == MaelstromWeaponBuffmaxStacks) and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    if (MaxDps:FindSpell(classtable.Windstrike) and CheckSpellCosts(classtable.Windstrike, 'Windstrike')) and (( talents[classtable.ThorimsInvocation] and buff[classtable.MaelstromWeaponBuff].count >1 ) or buff[classtable.ConvergingStormsBuff].count == ConvergingStormsBuffmaxStacks) and cooldown[classtable.Windstrike].ready then
        return classtable.Windstrike
    end
    if (MaxDps:FindSpell(classtable.Stormstrike) and CheckSpellCosts(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.ConvergingStormsBuff].count == ConvergingStormsBuffmaxStacks) and cooldown[classtable.Stormstrike].ready then
        return classtable.Stormstrike
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count == MaelstromWeaponBuffmaxStacks and buff[classtable.CracklingThunderBuff].up) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (( buff[classtable.MoltenWeaponBuff].count + buff[classtable.VolcanicStrengthBuff].duration >buff[classtable.CracklingSurgeBuff].count ) and buff[classtable.MaelstromWeaponBuff].count == MaelstromWeaponBuffmaxStacks) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count == MaelstromWeaponBuffmaxStacks) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.CrashLightning) and CheckSpellCosts(classtable.CrashLightning, 'CrashLightning')) and (buff[classtable.DoomWindsBuff].up or not buff[classtable.CrashLightningBuff].up or ( talents[classtable.AlphaWolf] and buff[classtable.FeralSpiritBuff].up and buff[classtable.FeralSpiritBuff].up == 0 ) or ( talents[classtable.ConvergingStorms] and buff[classtable.ConvergingStormsBuff].count <ConvergingStormsBuffmaxStacks )) and cooldown[classtable.CrashLightning].ready then
        return classtable.CrashLightning
    end
    if (MaxDps:FindSpell(classtable.Sundering) and CheckSpellCosts(classtable.Sundering, 'Sundering')) and (buff[classtable.DoomWindsBuff].up or (MaxDps.tier and MaxDps.tier[30].count >= 2)) and cooldown[classtable.Sundering].ready then
        return classtable.Sundering
    end
    if (MaxDps:FindSpell(classtable.FireNova) and CheckSpellCosts(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count  == 6 or ( debuff[classtable.FlameShockDeBuff].count  >= 4 and debuff[classtable.FlameShockDeBuff].count  == targets )) and cooldown[classtable.FireNova].ready then
        return classtable.FireNova
    end
    if (MaxDps:FindSpell(classtable.IceStrike) and CheckSpellCosts(classtable.IceStrike, 'IceStrike')) and (talents[classtable.Hailstorm] and not buff[classtable.IceStrikeBuff].up) and cooldown[classtable.IceStrike].ready then
        return classtable.IceStrike
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (talents[classtable.Hailstorm] and buff[classtable.HailstormBuff].up) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.Sundering) and CheckSpellCosts(classtable.Sundering, 'Sundering')) and cooldown[classtable.Sundering].ready then
        return classtable.Sundering
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (talents[classtable.MoltenAssault] and not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (( talents[classtable.FireNova] or talents[classtable.PrimordialWave] ) and ( debuff[classtable.FlameShockDeBuff].count  <targets ) and debuff[classtable.FlameShockDeBuff].count  <6) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FireNova) and CheckSpellCosts(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count  >= 3) and cooldown[classtable.FireNova].ready then
        return classtable.FireNova
    end
    if (MaxDps:FindSpell(classtable.Stormstrike) and CheckSpellCosts(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.CrashLightningBuff].up and talents[classtable.DeeplyRootedElements]) and cooldown[classtable.Stormstrike].ready then
        return classtable.Stormstrike
    end
    if (MaxDps:FindSpell(classtable.CrashLightning) and CheckSpellCosts(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.CrashingStorms] and buff[classtable.ClCrashLightningBuff].up and targets >= 4) and cooldown[classtable.CrashLightning].ready then
        return classtable.CrashLightning
    end
    if (MaxDps:FindSpell(classtable.Windstrike) and CheckSpellCosts(classtable.Windstrike, 'Windstrike')) and cooldown[classtable.Windstrike].ready then
        return classtable.Windstrike
    end
    if (MaxDps:FindSpell(classtable.Stormstrike) and CheckSpellCosts(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        return classtable.Stormstrike
    end
    if (MaxDps:FindSpell(classtable.IceStrike) and CheckSpellCosts(classtable.IceStrike, 'IceStrike')) and cooldown[classtable.IceStrike].ready then
        return classtable.IceStrike
    end
    if (MaxDps:FindSpell(classtable.LavaLash) and CheckSpellCosts(classtable.LavaLash, 'LavaLash')) and cooldown[classtable.LavaLash].ready then
        return classtable.LavaLash
    end
    if (MaxDps:FindSpell(classtable.CrashLightning) and CheckSpellCosts(classtable.CrashLightning, 'CrashLightning')) and cooldown[classtable.CrashLightning].ready then
        return classtable.CrashLightning
    end
    if (MaxDps:FindSpell(classtable.FireNova) and CheckSpellCosts(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count  >= 2) and cooldown[classtable.FireNova].ready then
        return classtable.FireNova
    end
    if (MaxDps:FindSpell(classtable.ElementalBlast) and CheckSpellCosts(classtable.ElementalBlast, 'ElementalBlast')) and (( not talents[classtable.ElementalSpirits] or ( talents[classtable.ElementalSpirits] and ( cooldown[classtable.ElementalBlast].charges == cooldown[classtable.ElementalBlast].maxCharges or buff[classtable.FeralSpiritBuff].up ) ) ) and buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (( buff[classtable.MoltenWeaponBuff].count + buff[classtable.VolcanicStrengthBuff].duration >buff[classtable.CracklingSurgeBuff].count ) and buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (not talents[classtable.Hailstorm]) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
end

function Enhancement:callaction()
    if (MaxDps:FindSpell(classtable.Bloodlust) and CheckSpellCosts(classtable.Bloodlust, 'Bloodlust')) and cooldown[classtable.Bloodlust].ready then
        MaxDps:GlowCooldown(classtable.Bloodlust, cooldown[classtable.Bloodlust].ready)
    end
    if (MaxDps:FindSpell(classtable.WindShear) and CheckSpellCosts(classtable.WindShear, 'WindShear')) and cooldown[classtable.WindShear].ready then
        MaxDps:GlowCooldown(classtable.WindShear, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    --if (MaxDps:FindSpell(classtable.Purge) and CheckSpellCosts(classtable.Purge, 'Purge')) and cooldown[classtable.Purge].ready then
    --    return classtable.Purge
    --end
    if (MaxDps:FindSpell(classtable.Windstrike) and CheckSpellCosts(classtable.Windstrike, 'Windstrike')) and (talents[classtable.ThorimsInvocation] and buff[classtable.MaelstromWeaponBuff].count >1 and ( targets == 1 and talents[classtable.ThorimsInvocation] ) or ( targets >1 and talents[classtable.ThorimsInvocation] )) and cooldown[classtable.Windstrike].ready then
        return classtable.Windstrike
    end
    if (MaxDps:FindSpell(classtable.PrimordialWave) and CheckSpellCosts(classtable.PrimordialWave, 'PrimordialWave')) and ((MaxDps.tier and MaxDps.tier[31].count >= 2) and ( math.huge >( cooldown[classtable.PrimordialWave].remains % ( 1 + (MaxDps.tier and MaxDps.tier[31].count >= 4 and 1 or 0) ) ) or math.huge <6 )) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:FindSpell(classtable.FeralSpirit) and CheckSpellCosts(classtable.FeralSpirit, 'FeralSpirit')) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:FindSpell(classtable.Ascendance) and CheckSpellCosts(classtable.Ascendance, 'Ascendance')) and (debuff[classtable.FlameShockDeBuff].up and ( ( talents[classtable.ThorimsInvocation] and targets == 1 and math.huge >= cooldown[classtable.Ascendance].remains % 2 ) or ( talents[classtable.ThorimsInvocation] and targets >1 ) )) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:FindSpell(classtable.DoomWinds) and CheckSpellCosts(classtable.DoomWinds, 'DoomWinds')) and (math.huge >= cooldown[classtable.DoomWinds].remains or targets >1) and cooldown[classtable.DoomWinds].ready then
        return classtable.DoomWinds
    end
    if (targets == 1) then
        local singleCheck = Enhancement:single()
        if singleCheck then
            return Enhancement:single()
        end
    end
    if (targets >1) then
        local aoeCheck = Enhancement:aoe()
        if aoeCheck then
            return Enhancement:aoe()
        end
    end
end
function Shaman:Enhancement()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    timeShift = fd.timeShift
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    Maelstrom = UnitPower('player', MaelstromPT)
    MaelstromMax = UnitPowerMax('player', MaelstromPT)
    MaelstromDeficit = MaelstromMax - Maelstrom
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.FlameShockDeBuff = 188389
    classtable.MaelstromWeaponBuff = 344179
    classtable.CracklingThunderBuff = 0
    classtable.AscendanceBuff = 114051
    classtable.DoomWindsBuff = 384352
    classtable.StormbringerBuff = 201846
    classtable.HotHandBuff = 215785
    classtable.PrimordialWaveBuff = 375986
    classtable.SplinteredElementsBuff = 382043
    classtable.IceStrikeBuff = 384357
    classtable.HailstormBuff = 334196
    classtable.CrashLightningBuff = 0
    classtable.AshenCatalystBuff = 0
    classtable.ConvergingStormsBuff = 198300
    classtable.ClCrashLightningBuff = 0
    classtable.FeralSpiritBuff = 333957
    classtable.MoltenWeaponBuff = 0
    classtable.VolcanicStrengthBuff = 0
    classtable.CracklingSurgeBuff = 0
    MaelstromWeaponBuffmaxStacks = 5
    AshenCatalystBuffmaxStacks = 8
    ConvergingStormsBuffmaxStacks = 6

    local precombatCheck = Enhancement:precombat()
    if precombatCheck then
        return Enhancement:precombat()
    end

    local callactionCheck = Enhancement:callaction()
    if callactionCheck then
        return Enhancement:callaction()
    end
end
