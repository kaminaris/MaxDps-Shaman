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

local Elemental = {}

local mael_cap

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

local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end


function Elemental:precombat()
    --if (MaxDps:FindSpell(classtable.FlametongueWeapon) and CheckSpellCosts(classtable.FlametongueWeapon, 'FlametongueWeapon')) and (talents[classtable.ImprovedFlametongueWeapon]) and cooldown[classtable.FlametongueWeapon].ready then
    --    return classtable.FlametongueWeapon
    --end
    --if (MaxDps:FindSpell(classtable.ThunderstrikeWard) and CheckSpellCosts(classtable.ThunderstrikeWard, 'ThunderstrikeWard')) and cooldown[classtable.ThunderstrikeWard].ready then
    --    return classtable.ThunderstrikeWard
    --end
    --if (MaxDps:FindSpell(classtable.Skyfury) and CheckSpellCosts(classtable.Skyfury, 'Skyfury')) and cooldown[classtable.Skyfury].ready then
    --    return classtable.Skyfury
    --end
    if (MaxDps:FindSpell(classtable.Stormkeeper) and CheckSpellCosts(classtable.Stormkeeper, 'Stormkeeper')) and cooldown[classtable.Stormkeeper].ready then
        MaxDps:GlowCooldown(classtable.Stormkeeper, cooldown[classtable.Stormkeeper].ready)
    end
    --if (MaxDps:FindSpell(classtable.LightningShield) and CheckSpellCosts(classtable.LightningShield, 'LightningShield')) and cooldown[classtable.LightningShield].ready then
    --    return classtable.LightningShield
    --end
    mael_cap = 100 + 50 * (talents[classtable.SwellingMaelstrom] and talents[classtable.SwellingMaelstrom] or 0) + 25 * (talents[classtable.PrimordialCapacity] and talents[classtable.PrimordialCapacity] or 0)
end
function Elemental:aoe()
    if (MaxDps:FindSpell(classtable.FireElemental) and CheckSpellCosts(classtable.FireElemental, 'FireElemental')) and (not buff[classtable.FireElementalBuff].up) and cooldown[classtable.FireElemental].ready then
        MaxDps:GlowCooldown(classtable.FireElemental, cooldown[classtable.FireElemental].ready)
    end
    if (MaxDps:FindSpell(classtable.StormElemental) and CheckSpellCosts(classtable.StormElemental, 'StormElemental')) and (not buff[classtable.StormElementalBuff].up) and cooldown[classtable.StormElemental].ready then
        MaxDps:GlowCooldown(classtable.StormElemental, cooldown[classtable.StormElemental].ready)
    end
    if (MaxDps:FindSpell(classtable.Stormkeeper) and CheckSpellCosts(classtable.Stormkeeper, 'Stormkeeper')) and (not buff[classtable.StormkeeperBuff].up) and cooldown[classtable.Stormkeeper].ready then
        MaxDps:GlowCooldown(classtable.Stormkeeper, cooldown[classtable.Stormkeeper].ready)
    end
    if (MaxDps:FindSpell(classtable.TotemicRecall) and CheckSpellCosts(classtable.TotemicRecall, 'TotemicRecall')) and (cooldown[classtable.LiquidMagmaTotem].remains >25) and cooldown[classtable.TotemicRecall].ready then
        return classtable.TotemicRecall
    end
    if (MaxDps:FindSpell(classtable.LiquidMagmaTotem) and CheckSpellCosts(classtable.LiquidMagmaTotem, 'LiquidMagmaTotem')) and (GetTotemDuration('Liquid Magma Totem') == 0) and cooldown[classtable.LiquidMagmaTotem].ready then
        return classtable.LiquidMagmaTotem
    end
    if (MaxDps:FindSpell(classtable.PrimordialWave) and CheckSpellCosts(classtable.PrimordialWave, 'PrimordialWave')) and (buff[classtable.SurgeofPowerBuff].up) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:FindSpell(classtable.PrimordialWave) and CheckSpellCosts(classtable.PrimordialWave, 'PrimordialWave')) and (talents[classtable.DeeplyRootedElements] and not talents[classtable.SurgeofPower]) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:FindSpell(classtable.PrimordialWave) and CheckSpellCosts(classtable.PrimordialWave, 'PrimordialWave')) and (talents[classtable.MasteroftheElements] and not talents[classtable.LightningRod]) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and buff[classtable.SurgeofPowerBuff].up and talents[classtable.LightningRod] and debuff[classtable.FlameShockDeBuff].remains <ttd - 16 and targets <5) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and buff[classtable.SurgeofPowerBuff].up and ( not talents[classtable.LightningRod] or talents[classtable.SkybreakersFieryDemise] ) and debuff[classtable.FlameShockDeBuff].remains <ttd - 5 and debuff[classtable.FlameShockDeBuff].count  <6) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and talents[classtable.MasteroftheElements] and not talents[classtable.LightningRod] and not talents[classtable.SurgeofPower] and debuff[classtable.FlameShockDeBuff].remains <ttd - 5 and debuff[classtable.FlameShockDeBuff].count  <6) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and talents[classtable.DeeplyRootedElements] and not talents[classtable.SurgeofPower] and debuff[classtable.FlameShockDeBuff].remains <ttd - 5 and debuff[classtable.FlameShockDeBuff].count  <6) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and buff[classtable.SurgeofPowerBuff].up and ( not talents[classtable.LightningRod] or talents[classtable.SkybreakersFieryDemise] ) and debuff[classtable.FlameShockDeBuff].remains <ttd - 5 and debuff[classtable.FlameShockDeBuff].remains >0) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and talents[classtable.MasteroftheElements] and not talents[classtable.LightningRod] and not talents[classtable.SurgeofPower] and debuff[classtable.FlameShockDeBuff].remains <ttd - 5 and debuff[classtable.FlameShockDeBuff].remains >0) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and talents[classtable.DeeplyRootedElements] and not talents[classtable.SurgeofPower] and debuff[classtable.FlameShockDeBuff].remains <ttd - 5 and debuff[classtable.FlameShockDeBuff].remains >0) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.Ascendance) and CheckSpellCosts(classtable.Ascendance, 'Ascendance')) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains and targets == 3 and ( not talents[classtable.LightningRod] and (MaxDps.tier and MaxDps.tier[31].count >= 4) )) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.Earthquake) and CheckSpellCosts(classtable.Earthquake, 'Earthquake')) and (buff[classtable.MasteroftheElementsBuff].up and ( buff[classtable.MagmaChamberBuff].count == 10 and targets >= 6 or talents[classtable.SplinteredElements] and targets >= 9 or talents[classtable.MountainsWillFall] and targets >= 9 ) and ( not talents[classtable.LightningRod] and (MaxDps.tier and MaxDps.tier[31].count >= 4) )) and cooldown[classtable.Earthquake].ready then
        return classtable.Earthquake
    end
    if (MaxDps:FindSpell(classtable.LavaBeam) and CheckSpellCosts(classtable.LavaBeam, 'LavaBeam')) and (buff[classtable.StormkeeperBuff].up and ( buff[classtable.SurgeofPowerBuff].up and targets >= 6 or buff[classtable.MasteroftheElementsBuff].up and ( targets <6 or not talents[classtable.SurgeofPower] ) ) and ( not talents[classtable.LightningRod] and (MaxDps.tier and MaxDps.tier[31].count >= 4) )) and cooldown[classtable.LavaBeam].ready then
        return classtable.LavaBeam
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.StormkeeperBuff].up and ( buff[classtable.SurgeofPowerBuff].up and targets >= 6 or buff[classtable.MasteroftheElementsBuff].up and ( targets <6 or not talents[classtable.SurgeofPower] ) ) and ( not talents[classtable.LightningRod] and (MaxDps.tier and MaxDps.tier[31].count >= 4) )) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains and cooldown[classtable.LavaBurst].ready and buff[classtable.LavaSurgeBuff].up and ( not talents[classtable.LightningRod] and (MaxDps.tier and MaxDps.tier[31].count >= 4) )) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains and cooldown[classtable.LavaBurst].ready and buff[classtable.LavaSurgeBuff].up and talents[classtable.MasteroftheElements] and not buff[classtable.MasteroftheElementsBuff].up and ( Maelstrom >= 52 - 5 * (talents[classtable.EyeoftheStorm] and talents[classtable.EyeoftheStorm] or 0) - 2 * (talents[classtable.FlowofPower] and talents[classtable.FlowofPower] or 0) ) and ( not talents[classtable.EchoesofGreatSundering] and not talents[classtable.LightningRod] or buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up ) and ( not buff[classtable.AscendanceBuff].up and targets >3 or targets == 3 )) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.Earthquake) and CheckSpellCosts(classtable.Earthquake, 'Earthquake')) and (not talents[classtable.EchoesofGreatSundering] and targets >3 and ( targets >3 or targets >3 )) and cooldown[classtable.Earthquake].ready then
        return classtable.Earthquake
    end
    if (MaxDps:FindSpell(classtable.Earthquake) and CheckSpellCosts(classtable.Earthquake, 'Earthquake')) and (not talents[classtable.EchoesofGreatSundering] and not talents[classtable.ElementalBlast] and targets == 3 and ( targets == 3 or targets == 3 )) and cooldown[classtable.Earthquake].ready then
        return classtable.Earthquake
    end
    if (MaxDps:FindSpell(classtable.Earthquake) and CheckSpellCosts(classtable.Earthquake, 'Earthquake')) and (buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up) and cooldown[classtable.Earthquake].ready then
        return classtable.Earthquake
    end
    if (MaxDps:FindSpell(classtable.ElementalBlast) and CheckSpellCosts(classtable.ElementalBlast, 'ElementalBlast')) and (talents[classtable.EchoesofGreatSundering]) and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    if (MaxDps:FindSpell(classtable.ElementalBlast) and CheckSpellCosts(classtable.ElementalBlast, 'ElementalBlast')) and (talents[classtable.EchoesofGreatSundering]) and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    if (MaxDps:FindSpell(classtable.ElementalBlast) and CheckSpellCosts(classtable.ElementalBlast, 'ElementalBlast')) and (targets == 3 and not talents[classtable.EchoesofGreatSundering]) and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    if (MaxDps:FindSpell(classtable.EarthShock) and CheckSpellCosts(classtable.EarthShock, 'EarthShock')) and (talents[classtable.EchoesofGreatSundering]) and cooldown[classtable.EarthShock].ready then
        return classtable.EarthShock
    end
    if (MaxDps:FindSpell(classtable.EarthShock) and CheckSpellCosts(classtable.EarthShock, 'EarthShock')) and (talents[classtable.EchoesofGreatSundering]) and cooldown[classtable.EarthShock].ready then
        return classtable.EarthShock
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains and talents[classtable.MasteroftheElements] and not buff[classtable.MasteroftheElementsBuff].up and ( buff[classtable.StormkeeperBuff].up ) and ( Maelstrom <60 - 5 * (talents[classtable.EyeoftheStorm] and talents[classtable.EyeoftheStorm] or 0) - 2 * (talents[classtable.FlowofPower] and talents[classtable.FlowofPower] or 0) - 10 ) and targets <5) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LavaBeam) and CheckSpellCosts(classtable.LavaBeam, 'LavaBeam')) and (buff[classtable.StormkeeperBuff].up) and cooldown[classtable.LavaBeam].ready then
        return classtable.LavaBeam
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.StormkeeperBuff].up) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.LavaBeam) and CheckSpellCosts(classtable.LavaBeam, 'LavaBeam')) and (buff[classtable.PoweroftheMaelstromBuff].up and buff[classtable.AscendanceBuff].remains >( classtable and classtable.LavaBeam and GetSpellInfo(classtable.LavaBeam).castTime /1000 )) and cooldown[classtable.LavaBeam].ready then
        return classtable.LavaBeam
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.PoweroftheMaelstromBuff].up) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.LavaBeam) and CheckSpellCosts(classtable.LavaBeam, 'LavaBeam')) and (targets >= 6 and buff[classtable.SurgeofPowerBuff].up and buff[classtable.AscendanceBuff].remains >( classtable and classtable.LavaBeam and GetSpellInfo(classtable.LavaBeam).castTime /1000 )) and cooldown[classtable.LavaBeam].ready then
        return classtable.LavaBeam
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (targets >= 6 and buff[classtable.SurgeofPowerBuff].up) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.LavaBeam) and CheckSpellCosts(classtable.LavaBeam, 'LavaBeam')) and (buff[classtable.MasteroftheElementsBuff].up and buff[classtable.AscendanceBuff].remains >( classtable and classtable.LavaBeam and GetSpellInfo(classtable.LavaBeam).castTime /1000 )) and cooldown[classtable.LavaBeam].ready then
        return classtable.LavaBeam
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains and targets == 3 and talents[classtable.MasteroftheElements]) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains and buff[classtable.LavaSurgeBuff].up and talents[classtable.DeeplyRootedElements]) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.Icefury) and CheckSpellCosts(classtable.Icefury, 'Icefury')) and (talents[classtable.FusionofElements] and talents[classtable.EchoesofGreatSundering]) and cooldown[classtable.Icefury].ready then
        return classtable.Icefury
    end
    if (MaxDps:FindSpell(classtable.LavaBeam) and CheckSpellCosts(classtable.LavaBeam, 'LavaBeam')) and (buff[classtable.AscendanceBuff].remains >( classtable and classtable.LavaBeam and GetSpellInfo(classtable.LavaBeam).castTime /1000 )) and cooldown[classtable.LavaBeam].ready then
        return classtable.LavaBeam
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
end
function Elemental:single_target()
    if (MaxDps:FindSpell(classtable.FireElemental) and CheckSpellCosts(classtable.FireElemental, 'FireElemental')) and (not buff[classtable.FireElementalBuff].up) and cooldown[classtable.FireElemental].ready then
        MaxDps:GlowCooldown(classtable.FireElemental, cooldown[classtable.FireElemental].ready)
    end
    if (MaxDps:FindSpell(classtable.StormElemental) and CheckSpellCosts(classtable.StormElemental, 'StormElemental')) and (not buff[classtable.StormElementalBuff].up) and cooldown[classtable.StormElemental].ready then
        MaxDps:GlowCooldown(classtable.StormElemental, cooldown[classtable.StormElemental].ready)
    end
    if (MaxDps:FindSpell(classtable.LiquidMagmaTotem) and CheckSpellCosts(classtable.LiquidMagmaTotem, 'LiquidMagmaTotem')) and (not buff[classtable.AscendanceBuff].up and talents[classtable.FireElemental]) and cooldown[classtable.LiquidMagmaTotem].ready then
        return classtable.LiquidMagmaTotem
    end
    if (MaxDps:FindSpell(classtable.PrimordialWave) and CheckSpellCosts(classtable.PrimordialWave, 'PrimordialWave')) and (( not buff[classtable.SurgeofPowerBuff].up and targets == 1 ) or debuff[classtable.FlameShockDeBuff].count  == 0 or talents[classtable.FireElemental] and ( talents[classtable.SkybreakersFieryDemise] or talents[classtable.DeeplyRootedElements] ) or ( buff[classtable.SurgeofPowerBuff].up or not talents[classtable.SurgeofPower] ) and targets >1) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (targets == 1 and ( debuff[classtable.FlameShockDeBuff].remains <2 or debuff[classtable.FlameShockDeBuff].count  == 0 ) and ( debuff[classtable.FlameShockDeBuff].remains <cooldown[classtable.PrimordialWave].remains or not talents[classtable.PrimordialWave] ) and ( debuff[classtable.FlameShockDeBuff].remains <cooldown[classtable.LiquidMagmaTotem].remains or not talents[classtable.LiquidMagmaTotem] ) and not buff[classtable.SurgeofPowerBuff].up and talents[classtable.FireElemental]) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].count  == 0 and targets >1 and ( targets >1 or targets >1 ) and ( talents[classtable.DeeplyRootedElements] or talents[classtable.Ascendance] or talents[classtable.PrimordialWave] or talents[classtable.SearingFlames] or talents[classtable.MagmaChamber] ) and ( not buff[classtable.MasteroftheElementsBuff].up and ( buff[classtable.StormkeeperBuff].up or cooldown[classtable.Stormkeeper].remains == 0 ) or not talents[classtable.SurgeofPower] )) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (targets >1 and debuff[classtable.FlameShockDeBuff].refreshable and ( talents[classtable.DeeplyRootedElements] or talents[classtable.Ascendance] or talents[classtable.PrimordialWave] or talents[classtable.SearingFlames] or talents[classtable.MagmaChamber] ) and ( buff[classtable.SurgeofPowerBuff].up and not buff[classtable.StormkeeperBuff].up and not cooldown[classtable.Stormkeeper].remains == 0 or not talents[classtable.SurgeofPower] )) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.Stormkeeper) and CheckSpellCosts(classtable.Stormkeeper, 'Stormkeeper')) and (not buff[classtable.AscendanceBuff].up and not buff[classtable.StormkeeperBuff].up) and cooldown[classtable.Stormkeeper].ready then
        MaxDps:GlowCooldown(classtable.Stormkeeper, cooldown[classtable.Stormkeeper].ready)
    end
    if (MaxDps:FindSpell(classtable.Tempest) and CheckSpellCosts(classtable.Tempest, 'Tempest')) and cooldown[classtable.Tempest].ready then
        return classtable.Tempest
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.StormkeeperBuff].up and buff[classtable.SurgeofPowerBuff].up) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and buff[classtable.StormkeeperBuff].up and not buff[classtable.MasteroftheElementsBuff].up and not talents[classtable.SurgeofPower] and talents[classtable.MasteroftheElements]) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LavaBeam) and CheckSpellCosts(classtable.LavaBeam, 'LavaBeam')) and (targets >1 and buff[classtable.StormkeeperBuff].up and not talents[classtable.SurgeofPower]) and cooldown[classtable.LavaBeam].ready then
        return classtable.LavaBeam
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (targets >1 and buff[classtable.StormkeeperBuff].up and not talents[classtable.SurgeofPower]) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.StormkeeperBuff].up and not talents[classtable.SurgeofPower] and ( buff[classtable.MasteroftheElementsBuff].up or not talents[classtable.MasteroftheElements] )) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.SurgeofPowerBuff].up and not buff[classtable.AscendanceBuff].up and talents[classtable.EchoChamber]) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.Ascendance) and CheckSpellCosts(classtable.Ascendance, 'Ascendance')) and (cooldown[classtable.LavaBurst].charges <1.0) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:FindSpell(classtable.LavaBeam) and CheckSpellCosts(classtable.LavaBeam, 'LavaBeam')) and (targets >1 and buff[classtable.PoweroftheMaelstromBuff].up and buff[classtable.AscendanceBuff].remains >( classtable and classtable.LavaBeam and GetSpellInfo(classtable.LavaBeam).castTime /1000 ) and not (MaxDps.tier and MaxDps.tier[31].count >= 4)) and cooldown[classtable.LavaBeam].ready then
        return classtable.LavaBeam
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (cooldown[classtable.LavaBurst].ready and buff[classtable.LavaSurgeBuff].up and ( talents[classtable.DeeplyRootedElements] or not talents[classtable.MasteroftheElements] )) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.Earthquake) and CheckSpellCosts(classtable.Earthquake, 'Earthquake')) and (buff[classtable.MasteroftheElementsBuff].up and ( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up ) and ( buff[classtable.FusionofElementsNatureBuff].up or Maelstrom >mael_cap - 15 or buff[classtable.AscendanceBuff].remains >9 or not buff[classtable.AscendanceBuff].up )) and cooldown[classtable.Earthquake].ready then
        return classtable.Earthquake
    end
    if (MaxDps:FindSpell(classtable.ElementalBlast) and CheckSpellCosts(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MasteroftheElementsBuff].up and ( buff[classtable.FusionofElementsNatureBuff].up or buff[classtable.FusionofElementsFireBuff].up or Maelstrom >mael_cap - 15 or buff[classtable.AscendanceBuff].remains >6 or not buff[classtable.AscendanceBuff].up )) and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    if (MaxDps:FindSpell(classtable.EarthShock) and CheckSpellCosts(classtable.EarthShock, 'EarthShock')) and (buff[classtable.MasteroftheElementsBuff].up and ( buff[classtable.FusionofElementsNatureBuff].up or Maelstrom >mael_cap - 15 or buff[classtable.AscendanceBuff].remains >9 or not buff[classtable.AscendanceBuff].up )) and cooldown[classtable.EarthShock].ready then
        return classtable.EarthShock
    end
    if (MaxDps:FindSpell(classtable.Icefury) and CheckSpellCosts(classtable.Icefury, 'Icefury')) and (buff[classtable.IcefuryBuff].up and ( talents[classtable.FusionofElements] or not buff[classtable.AscendanceBuff].up )) and cooldown[classtable.Icefury].ready then
        return classtable.Icefury
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and buff[classtable.AscendanceBuff].up) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and talents[classtable.MasteroftheElements] and not buff[classtable.MasteroftheElementsBuff].up and talents[classtable.FireElemental]) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (talents[classtable.MasteroftheElements] and not buff[classtable.MasteroftheElementsBuff].up and ( Maelstrom >= 82 - 10 * (talents[classtable.EyeoftheStorm] and talents[classtable.EyeoftheStorm] or 0) or Maelstrom >= 52 - 5 * (talents[classtable.EyeoftheStorm] and talents[classtable.EyeoftheStorm] or 0) and ( not talents[classtable.ElementalBlast] or buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up or targets >1 and not talents[classtable.EchoesofGreatSundering] ) ) and ( debuff[classtable.LightningRodDeBuff].remains <2 or not debuff[classtable.LightningRodDeBuff].up )) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.Earthquake) and CheckSpellCosts(classtable.Earthquake, 'Earthquake')) and (( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up ) and ( Maelstrom >mael_cap - 20 or not talents[classtable.MasteroftheElements] and not talents[classtable.LightningRod] or buff[classtable.StormkeeperBuff].up and talents[classtable.LightningRod] )) and cooldown[classtable.Earthquake].ready then
        return classtable.Earthquake
    end
    if (MaxDps:FindSpell(classtable.Earthquake) and CheckSpellCosts(classtable.Earthquake, 'Earthquake')) and (targets >1 and not talents[classtable.EchoesofGreatSundering] and not talents[classtable.ElementalBlast] and ( Maelstrom >mael_cap - 20 or not talents[classtable.MasteroftheElements] and not talents[classtable.LightningRod] or buff[classtable.StormkeeperBuff].up and talents[classtable.LightningRod] )) and cooldown[classtable.Earthquake].ready then
        return classtable.Earthquake
    end
    if (MaxDps:FindSpell(classtable.ElementalBlast) and CheckSpellCosts(classtable.ElementalBlast, 'ElementalBlast')) and (Maelstrom >mael_cap - 20 or not talents[classtable.MasteroftheElements] and not talents[classtable.LightningRod]) and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    if (MaxDps:FindSpell(classtable.EarthShock) and CheckSpellCosts(classtable.EarthShock, 'EarthShock')) and (Maelstrom >mael_cap - 20 or not talents[classtable.MasteroftheElements] and not talents[classtable.LightningRod] or ( buff[classtable.StormkeeperBuff].up and talents[classtable.LightningRod] )) and cooldown[classtable.EarthShock].ready then
        return classtable.EarthShock
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.SurgeofPowerBuff].up) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.Icefury) and CheckSpellCosts(classtable.Icefury, 'Icefury')) and (not ( buff[classtable.FusionofElementsNatureBuff].up or buff[classtable.FusionofElementsFireBuff].up )) and cooldown[classtable.Icefury].ready then
        return classtable.Icefury
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (buff[classtable.IcefuryDmgBuff].up) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.PoweroftheMaelstromBuff].up and targets >1) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.PoweroftheMaelstromBuff].up) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and talents[classtable.DeeplyRootedElements]) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (targets >1) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >6) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
end

function Elemental:callaction()
    if (MaxDps:FindSpell(classtable.SpiritwalkersGrace) and CheckSpellCosts(classtable.SpiritwalkersGrace, 'SpiritwalkersGrace')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >6) and cooldown[classtable.SpiritwalkersGrace].ready then
        MaxDps:GlowCooldown(classtable.SpiritwalkersGrace, cooldown[classtable.SpiritwalkersGrace].ready)
    end
    if (MaxDps:FindSpell(classtable.WindShear) and CheckSpellCosts(classtable.WindShear, 'WindShear')) and cooldown[classtable.WindShear].ready then
        MaxDps:GlowCooldown(classtable.WindShear, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:FindSpell(classtable.LightningShield) and CheckSpellCosts(classtable.LightningShield, 'LightningShield')) and (not buff[classtable.LightningShieldBuff].up) and cooldown[classtable.LightningShield].ready then
        return classtable.LightningShield
    end
    if (MaxDps:FindSpell(classtable.NaturesSwiftness) and CheckSpellCosts(classtable.NaturesSwiftness, 'NaturesSwiftness')) and cooldown[classtable.NaturesSwiftness].ready then
        MaxDps:GlowCooldown(classtable.NaturesSwiftness, cooldown[classtable.NaturesSwiftness].ready)
    end
    if (MaxDps:FindSpell(classtable.AncestralSwiftness) and CheckSpellCosts(classtable.AncestralSwiftness, 'AncestralSwiftness')) and cooldown[classtable.AncestralSwiftness].ready then
        MaxDps:GlowCooldown(classtable.AncestralSwiftness, cooldown[classtable.AncestralSwiftness].ready)
    end
    if (targets >2) then
        local aoeCheck = Elemental:aoe()
        if aoeCheck then
            return Elemental:aoe()
        end
    end
    local single_targetCheck = Elemental:single_target()
    if single_targetCheck then
        return single_targetCheck
    end
end
function Shaman:Elemental()
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
    classtable.FireElementalBuff = 0
    classtable.StormElementalBuff = 0
    classtable.StormkeeperBuff = 191634
    classtable.SurgeofPowerBuff = 285514
    classtable.FlameShockDeBuff = 188389
    classtable.MasteroftheElementsBuff = 260734
    classtable.MagmaChamberBuff = 381933
    classtable.LavaSurgeBuff = 77762
    classtable.EchoesofGreatSunderingEsBuff = 336217
    classtable.EchoesofGreatSunderingEbBuff = 336217
    classtable.AscendanceBuff = 114050
    classtable.PoweroftheMaelstromBuff = 191877
    classtable.FusionofElementsNatureBuff = 0
    classtable.FusionofElementsFireBuff = 0
    classtable.IcefuryBuff = 462818
    classtable.LightningRodDeBuff = 197209
    classtable.IcefuryDmgBuff = 210714
    classtable.LightningShieldBuff = 192106
    classtable.Icefury = 210714

    local precombatCheck = Elemental:precombat()
    if precombatCheck then
        return Elemental:precombat()
    end

    local callactionCheck = Elemental:callaction()
    if callactionCheck then
        return Elemental:callaction()
    end
end
