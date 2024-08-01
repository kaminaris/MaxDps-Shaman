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


local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'KillShot' then
        if (classtable.SicEmBuff and not buff[classtable.SicEmBuff].up) and targethealthPerc > 15 then
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


function Elemental:precombat()
    if (MaxDps:FindSpell(classtable.FlametongueWeapon) and CheckSpellCosts(classtable.FlametongueWeapon, 'FlametongueWeapon')) and (talents[classtable.ImprovedFlametongueWeapon]) and cooldown[classtable.FlametongueWeapon].ready then
        return classtable.FlametongueWeapon
    end
    if (MaxDps:FindSpell(classtable.Stormkeeper) and CheckSpellCosts(classtable.Stormkeeper, 'Stormkeeper')) and cooldown[classtable.Stormkeeper].ready then
        return classtable.Stormkeeper
    end
    if (MaxDps:FindSpell(classtable.Icefury) and CheckSpellCosts(classtable.Icefury, 'Icefury')) and cooldown[classtable.Icefury].ready then
        return classtable.Icefury
    end
end
function Elemental:aoe()
    if (MaxDps:FindSpell(classtable.FireElemental) and CheckSpellCosts(classtable.FireElemental, 'FireElemental')) and cooldown[classtable.FireElemental].ready then
        return classtable.FireElemental
    end
    if (MaxDps:FindSpell(classtable.StormElemental) and CheckSpellCosts(classtable.StormElemental, 'StormElemental')) and cooldown[classtable.StormElemental].ready then
        return classtable.StormElemental
    end
    if (MaxDps:FindSpell(classtable.Stormkeeper) and CheckSpellCosts(classtable.Stormkeeper, 'Stormkeeper')) and (not buff[classtable.StormkeeperBuff].up) and cooldown[classtable.Stormkeeper].ready then
        return classtable.Stormkeeper
    end
    if (MaxDps:FindSpell(classtable.TotemicRecall) and CheckSpellCosts(classtable.TotemicRecall, 'TotemicRecall')) and (cooldown[classtable.LiquidMagmaTotem].remains >45) and cooldown[classtable.TotemicRecall].ready then
        return classtable.TotemicRecall
    end
    if (MaxDps:FindSpell(classtable.LiquidMagmaTotem) and CheckSpellCosts(classtable.LiquidMagmaTotem, 'LiquidMagmaTotem')) and cooldown[classtable.LiquidMagmaTotem].ready then
        return classtable.LiquidMagmaTotem
    end
    if (MaxDps:FindSpell(classtable.PrimordialWave) and CheckSpellCosts(classtable.PrimordialWave, 'PrimordialWave')) and (not buff[classtable.PrimordialWaveBuff].up and buff[classtable.SurgeofPowerBuff].up and not buff[classtable.SplinteredElementsBuff].up) and cooldown[classtable.PrimordialWave].ready then
        return classtable.PrimordialWave
    end
    if (MaxDps:FindSpell(classtable.PrimordialWave) and CheckSpellCosts(classtable.PrimordialWave, 'PrimordialWave')) and (not buff[classtable.PrimordialWaveBuff].up and talents[classtable.DeeplyRootedElements] and not talents[classtable.SurgeofPower] and not buff[classtable.SplinteredElementsBuff].up) and cooldown[classtable.PrimordialWave].ready then
        return classtable.PrimordialWave
    end
    if (MaxDps:FindSpell(classtable.PrimordialWave) and CheckSpellCosts(classtable.PrimordialWave, 'PrimordialWave')) and (not buff[classtable.PrimordialWaveBuff].up and talents[classtable.MasteroftheElements] and not talents[classtable.LightningRod]) and cooldown[classtable.PrimordialWave].ready then
        return classtable.PrimordialWave
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (buff[classtable.SurgeofPowerBuff].up and talents[classtable.LightningRod] and talents[classtable.WindspeakersLavaResurgence] and debuff[classtable.FlameShockDeBuff].remains <ttd - 16 and targets <5) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    --if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (buff[classtable.SurgeofPowerBuff].up and ( not talents[classtable.LightningRod] or talents[classtable.SkybreakersFieryDemise] ) and debuff[classtable.FlameShockDeBuff].remains <ttd - 5 and debuff[classtable.FlameShock].count  <6) and cooldown[classtable.FlameShock].ready then
    --    return classtable.FlameShock
    --end
    --if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (talents[classtable.MasteroftheElements] and not talents[classtable.LightningRod] and not talents[classtable.SurgeofPower] and debuff[classtable.FlameShockDeBuff].remains <ttd - 5 and debuff[classtable.FlameShock].count  <6) and cooldown[classtable.FlameShock].ready then
    --    return classtable.FlameShock
    --end
    --if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (talents[classtable.DeeplyRootedElements] and not talents[classtable.SurgeofPower] and debuff[classtable.FlameShockDeBuff].remains <ttd - 5 and debuff[classtable.FlameShock].count  <6) and cooldown[classtable.FlameShock].ready then
    --    return classtable.FlameShock
    --end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (buff[classtable.SurgeofPowerBuff].up and ( not talents[classtable.LightningRod] or talents[classtable.SkybreakersFieryDemise] ) and debuff[classtable.FlameShockDeBuff].remains <ttd - 5 and debuff[classtable.FlameShockDeBuff].remains >0) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (talents[classtable.MasteroftheElements] and not talents[classtable.LightningRod] and not talents[classtable.SurgeofPower] and debuff[classtable.FlameShockDeBuff].remains <ttd - 5 and debuff[classtable.FlameShockDeBuff].remains >0) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (talents[classtable.DeeplyRootedElements] and not talents[classtable.SurgeofPower] and debuff[classtable.FlameShockDeBuff].remains <ttd - 5 and debuff[classtable.FlameShockDeBuff].remains >0) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.Ascendance) and CheckSpellCosts(classtable.Ascendance, 'Ascendance')) and cooldown[classtable.Ascendance].ready then
        return classtable.Ascendance
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (targets ==3 and ( not talents[classtable.LightningRod] and (MaxDps.tier and MaxDps.tier[31].count >= 4) )) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.Earthquake) and CheckSpellCosts(classtable.Earthquake, 'Earthquake')) and (buff[classtable.MasteroftheElementsBuff].up and ( buff[classtable.MagmaChamberBuff].count >15 and targets >= ( 7 - talents[classtable.UnrelentingCalamity] ) or talents[classtable.SplinteredElements] and targets >= ( 10 - talents[classtable.UnrelentingCalamity] ) or talents[classtable.MountainsWillFall] and targets >= 9 ) and ( not talents[classtable.LightningRod] and (MaxDps.tier and MaxDps.tier[31].count >= 4) )) and cooldown[classtable.Earthquake].ready then
        return classtable.Earthquake
    end
    if (MaxDps:FindSpell(classtable.LavaBeam) and CheckSpellCosts(classtable.LavaBeam, 'LavaBeam')) and (buff[classtable.StormkeeperBuff].up and ( buff[classtable.SurgeofPowerBuff].up and targets >= 6 or buff[classtable.MasteroftheElementsBuff].up and ( targets <6 or not talents[classtable.SurgeofPower] ) ) and ( not talents[classtable.LightningRod] and (MaxDps.tier and MaxDps.tier[31].count >= 4) )) and cooldown[classtable.LavaBeam].ready then
        return classtable.LavaBeam
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.StormkeeperBuff].up and ( buff[classtable.SurgeofPowerBuff].up and targets >= 6 or buff[classtable.MasteroftheElementsBuff].up and ( targets <6 or not talents[classtable.SurgeofPower] ) ) and ( not talents[classtable.LightningRod] and (MaxDps.tier and MaxDps.tier[31].count >= 4) )) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (cooldown[classtable.LavaBurst].ready and buff[classtable.LavaSurgeBuff].up and ( not talents[classtable.LightningRod] and (MaxDps.tier and MaxDps.tier[31].count >= 4) )) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (cooldown[classtable.LavaBurst].ready and buff[classtable.LavaSurgeBuff].up and talents[classtable.MasteroftheElements] and not buff[classtable.MasteroftheElementsBuff].up and ( Maelstrom >= 60 - 5 * talents[classtable.EyeoftheStorm] - 2 * talents[classtable.FlowofPower] ) and ( not talents[classtable.EchoesofGreatSundering] and not talents[classtable.LightningRod] or buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up ) and ( not buff[classtable.AscendanceBuff].up and targets >3 and talents[classtable.UnrelentingCalamity] or targets >3 and not talents[classtable.UnrelentingCalamity] or targets ==3 )) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.Earthquake) and CheckSpellCosts(classtable.Earthquake, 'Earthquake')) and (not talents[classtable.EchoesofGreatSundering] and targets >3 and ( targets >3 or targets >3 )) and cooldown[classtable.Earthquake].ready then
        return classtable.Earthquake
    end
    if (MaxDps:FindSpell(classtable.Earthquake) and CheckSpellCosts(classtable.Earthquake, 'Earthquake')) and (not talents[classtable.EchoesofGreatSundering] and not talents[classtable.ElementalBlast] and targets ==3 and ( targets or targets )) and cooldown[classtable.Earthquake].ready then
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
    if (MaxDps:FindSpell(classtable.ElementalBlast) and CheckSpellCosts(classtable.ElementalBlast, 'ElementalBlast')) and (targets ==3 and not talents[classtable.EchoesofGreatSundering]) and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    if (MaxDps:FindSpell(classtable.EarthShock) and CheckSpellCosts(classtable.EarthShock, 'EarthShock')) and (talents[classtable.EchoesofGreatSundering]) and cooldown[classtable.EarthShock].ready then
        return classtable.EarthShock
    end
    if (MaxDps:FindSpell(classtable.EarthShock) and CheckSpellCosts(classtable.EarthShock, 'EarthShock')) and (talents[classtable.EchoesofGreatSundering]) and cooldown[classtable.EarthShock].ready then
        return classtable.EarthShock
    end
    if (MaxDps:FindSpell(classtable.Icefury) and CheckSpellCosts(classtable.Icefury, 'Icefury')) and (not buff[classtable.AscendanceBuff].up and talents[classtable.ElectrifiedShocks] and ( talents[classtable.LightningRod] and targets <5 and not buff[classtable.MasteroftheElementsBuff].up or talents[classtable.DeeplyRootedElements] and targets ==3 )) and cooldown[classtable.Icefury].ready then
        return classtable.Icefury
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (not buff[classtable.AscendanceBuff].up and buff[classtable.IcefuryBuff].up and talents[classtable.ElectrifiedShocks] and ( not debuff[classtable.ElectrifiedShocksDeBuff].up or buff[classtable.IcefuryBuff].remains <gcd ) and ( talents[classtable.LightningRod] and targets <5 and not buff[classtable.MasteroftheElementsBuff].up or talents[classtable.DeeplyRootedElements] and targets ==3 )) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (talents[classtable.MasteroftheElements] and not buff[classtable.MasteroftheElementsBuff].up and ( buff[classtable.StormkeeperBuff].up ) and ( Maelstrom <60 - 5 * talents[classtable.EyeoftheStorm] - 2 * talents[classtable.FlowofPower] - 10 ) and targets <5) and cooldown[classtable.LavaBurst].ready then
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
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (buff[classtable.LavaSurgeBuff].up and talents[classtable.DeeplyRootedElements] and buff[classtable.WindspeakersLavaResurgenceBuff].up) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LavaBeam) and CheckSpellCosts(classtable.LavaBeam, 'LavaBeam')) and (buff[classtable.MasteroftheElementsBuff].up and buff[classtable.AscendanceBuff].remains >( classtable and classtable.LavaBeam and GetSpellInfo(classtable.LavaBeam).castTime /1000 )) and cooldown[classtable.LavaBeam].ready then
        return classtable.LavaBeam
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (targets ==3 and talents[classtable.MasteroftheElements]) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (buff[classtable.LavaSurgeBuff].up and talents[classtable.DeeplyRootedElements]) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.Icefury) and CheckSpellCosts(classtable.Icefury, 'Icefury')) and (talents[classtable.ElectrifiedShocks] and targets <5) and cooldown[classtable.Icefury].ready then
        return classtable.Icefury
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (buff[classtable.IcefuryBuff].up and talents[classtable.ElectrifiedShocks] and not debuff[classtable.ElectrifiedShocksDeBuff].up and targets <5) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.LavaBeam) and CheckSpellCosts(classtable.LavaBeam, 'LavaBeam')) and (buff[classtable.AscendanceBuff].remains >( classtable and classtable.LavaBeam and GetSpellInfo(classtable.LavaBeam).castTime /1000 )) and cooldown[classtable.LavaBeam].ready then
        return classtable.LavaBeam
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShock].refreshable) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
end
function Elemental:single_target()
    if (MaxDps:FindSpell(classtable.FireElemental) and CheckSpellCosts(classtable.FireElemental, 'FireElemental')) and cooldown[classtable.FireElemental].ready then
        return classtable.FireElemental
    end
    if (MaxDps:FindSpell(classtable.StormElemental) and CheckSpellCosts(classtable.StormElemental, 'StormElemental')) and cooldown[classtable.StormElemental].ready then
        return classtable.StormElemental
    end
    if (MaxDps:FindSpell(classtable.TotemicRecall) and CheckSpellCosts(classtable.TotemicRecall, 'TotemicRecall')) and (cooldown[classtable.LiquidMagmaTotem].remains >45 and ( talents[classtable.LavaSurge] and talents[classtable.SplinteredElements] or targets >1 and ( targets >1 or targets >1 ) )) and cooldown[classtable.TotemicRecall].ready then
        return classtable.TotemicRecall
    end
    if (MaxDps:FindSpell(classtable.LiquidMagmaTotem) and CheckSpellCosts(classtable.LiquidMagmaTotem, 'LiquidMagmaTotem')) and (talents[classtable.LavaSurge] and talents[classtable.SplinteredElements] or debuff[classtable.FlameShock].count == 0 or debuff[classtable.FlameShockDeBuff].remains <6 or targets >1 and ( targets >1 or targets >1 )) and cooldown[classtable.LiquidMagmaTotem].ready then
        return classtable.LiquidMagmaTotem
    end
    if (MaxDps:FindSpell(classtable.PrimordialWave) and CheckSpellCosts(classtable.PrimordialWave, 'PrimordialWave')) and (not buff[classtable.PrimordialWaveBuff].up and not buff[classtable.SplinteredElementsBuff].up) and cooldown[classtable.PrimordialWave].ready then
        return classtable.PrimordialWave
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (targets ==1 and debuff[classtable.FlameShock].refreshable and ( debuff[classtable.FlameShockDeBuff].remains <cooldown[classtable.PrimordialWave].remains or not talents[classtable.PrimordialWave] ) and not buff[classtable.SurgeofPowerBuff].up and ( not buff[classtable.MasteroftheElementsBuff].up or ( not buff[classtable.StormkeeperBuff].up and ( talents[classtable.ElementalBlast] and Maelstrom <90 - 8 * talents[classtable.EyeoftheStorm] or Maelstrom <60 - 5 * talents[classtable.EyeoftheStorm] ) ) )) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShock].count == 0 and targets >1 and ( targets >1 or targets >1 ) and ( talents[classtable.DeeplyRootedElements] or talents[classtable.Ascendance] or talents[classtable.PrimordialWave] or talents[classtable.SearingFlames] or talents[classtable.MagmaChamber] ) and ( not buff[classtable.MasteroftheElementsBuff].up and ( buff[classtable.StormkeeperBuff].up or cooldown[classtable.Stormkeeper].remains==0 ) or not talents[classtable.SurgeofPower] )) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (targets >1 and ( targets >1 or targets >1 ) and debuff[classtable.FlameShock].refreshable and ( talents[classtable.DeeplyRootedElements] or talents[classtable.Ascendance] or talents[classtable.PrimordialWave] or talents[classtable.SearingFlames] or talents[classtable.MagmaChamber] ) and ( buff[classtable.SurgeofPowerBuff].up and not buff[classtable.StormkeeperBuff].up and not cooldown[classtable.Stormkeeper].remains==0 or not talents[classtable.SurgeofPower] )) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.Stormkeeper) and CheckSpellCosts(classtable.Stormkeeper, 'Stormkeeper')) and (not buff[classtable.AscendanceBuff].up and not buff[classtable.StormkeeperBuff].up and Maelstrom >= 116 and talents[classtable.ElementalBlast] and talents[classtable.SurgeofPower] and talents[classtable.SwellingMaelstrom] and not talents[classtable.LavaSurge] and not talents[classtable.EchooftheElements] and not talents[classtable.PrimordialSurge]) and cooldown[classtable.Stormkeeper].ready then
        return classtable.Stormkeeper
    end
    if (MaxDps:FindSpell(classtable.Stormkeeper) and CheckSpellCosts(classtable.Stormkeeper, 'Stormkeeper')) and (not buff[classtable.AscendanceBuff].up and not buff[classtable.StormkeeperBuff].up and buff[classtable.SurgeofPowerBuff].up and not talents[classtable.LavaSurge] and not talents[classtable.EchooftheElements] and not talents[classtable.PrimordialSurge]) and cooldown[classtable.Stormkeeper].ready then
        return classtable.Stormkeeper
    end
    if (MaxDps:FindSpell(classtable.Stormkeeper) and CheckSpellCosts(classtable.Stormkeeper, 'Stormkeeper')) and (not buff[classtable.AscendanceBuff].up and not buff[classtable.StormkeeperBuff].up and ( not talents[classtable.SurgeofPower] or not talents[classtable.ElementalBlast] or talents[classtable.LavaSurge] or talents[classtable.EchooftheElements] or talents[classtable.PrimordialSurge] )) and cooldown[classtable.Stormkeeper].ready then
        return classtable.Stormkeeper
    end
    if (MaxDps:FindSpell(classtable.Ascendance) and CheckSpellCosts(classtable.Ascendance, 'Ascendance')) and (not buff[classtable.StormkeeperBuff].up) and cooldown[classtable.Ascendance].ready then
        return classtable.Ascendance
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.StormkeeperBuff].up and buff[classtable.SurgeofPowerBuff].up) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.LavaBeam) and CheckSpellCosts(classtable.LavaBeam, 'LavaBeam')) and (targets >1 and ( targets >1 or targets >1 ) and buff[classtable.StormkeeperBuff].up and not talents[classtable.SurgeofPower]) and cooldown[classtable.LavaBeam].ready then
        return classtable.LavaBeam
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (targets >1 and ( targets >1 or targets >1 ) and buff[classtable.StormkeeperBuff].up and not talents[classtable.SurgeofPower]) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (buff[classtable.StormkeeperBuff].up and not buff[classtable.MasteroftheElementsBuff].up and not talents[classtable.SurgeofPower] and talents[classtable.MasteroftheElements]) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.StormkeeperBuff].up and not talents[classtable.SurgeofPower] and buff[classtable.MasteroftheElementsBuff].up) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.StormkeeperBuff].up and not talents[classtable.SurgeofPower] and not talents[classtable.MasteroftheElements]) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.SurgeofPowerBuff].up and talents[classtable.LightningRod]) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.Icefury) and CheckSpellCosts(classtable.Icefury, 'Icefury')) and (talents[classtable.ElectrifiedShocks] and talents[classtable.LightningRod]) and cooldown[classtable.Icefury].ready then
        return classtable.Icefury
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (buff[classtable.IcefuryBuff].up and talents[classtable.ElectrifiedShocks] and ( debuff[classtable.ElectrifiedShocksDeBuff].remains <2 or buff[classtable.IcefuryBuff].remains <= gcd ) and talents[classtable.LightningRod]) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (buff[classtable.IcefuryBuff].up and talents[classtable.ElectrifiedShocks] and Maelstrom >= 50 and debuff[classtable.ElectrifiedShocksDeBuff].remains <2 * gcd and buff[classtable.StormkeeperBuff].up and talents[classtable.LightningRod]) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.LavaBeam) and CheckSpellCosts(classtable.LavaBeam, 'LavaBeam')) and (targets >1 and ( targets >1 or targets >1 ) and buff[classtable.PoweroftheMaelstromBuff].up and buff[classtable.AscendanceBuff].remains >( classtable and classtable.LavaBeam and GetSpellInfo(classtable.LavaBeam).castTime /1000 ) and not (MaxDps.tier and MaxDps.tier[31].count >= 4)) and cooldown[classtable.LavaBeam].ready then
        return classtable.LavaBeam
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (buff[classtable.IcefuryBuff].up and buff[classtable.StormkeeperBuff].up and not talents[classtable.LavaSurge] and not talents[classtable.EchooftheElements] and not talents[classtable.PrimordialSurge] and talents[classtable.ElementalBlast] and ( Maelstrom >= 61 and Maelstrom <75 and cooldown[classtable.LavaBurst].remains >gcd or Maelstrom >= 49 and Maelstrom <63 and cooldown[classtable.LavaBurst].ready )) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (buff[classtable.IcefuryBuff].up and buff[classtable.StormkeeperBuff].up and not talents[classtable.LavaSurge] and not talents[classtable.EchooftheElements] and not talents[classtable.ElementalBlast] and ( Maelstrom >= 36 and Maelstrom <50 and cooldown[classtable.LavaBurst].remains >gcd or Maelstrom >= 24 and Maelstrom <38 and cooldown[classtable.LavaBurst].ready )) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (buff[classtable.WindspeakersLavaResurgenceBuff].up and ( talents[classtable.EchooftheElements] or talents[classtable.LavaSurge] or talents[classtable.PrimordialSurge] or Maelstrom >= 63 and talents[classtable.MasteroftheElements] or Maelstrom >= 38 and ( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up ) and targets >1 and ( targets >1 or targets >1 ) or not talents[classtable.ElementalBlast] )) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (cooldown[classtable.LavaBurst].ready and buff[classtable.LavaSurgeBuff].up and ( talents[classtable.EchooftheElements] or talents[classtable.LavaSurge] or talents[classtable.PrimordialSurge] or not talents[classtable.MasteroftheElements] or not talents[classtable.ElementalBlast] )) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (buff[classtable.AscendanceBuff].up and ( (MaxDps.tier and MaxDps.tier[31].count >= 4) or not talents[classtable.ElementalBlast] ) and ( not talents[classtable.FurtherBeyond] or buff[classtable.FurtherBeyond].remains <2 )) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (not buff[classtable.AscendanceBuff].up and ( not talents[classtable.ElementalBlast] or not talents[classtable.MountainsWillFall] ) and not talents[classtable.LightningRod] and (MaxDps.tier and MaxDps.tier[31].count >= 4)) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (talents[classtable.MasteroftheElements] and not buff[classtable.MasteroftheElementsBuff].up and not talents[classtable.LightningRod]) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (talents[classtable.MasteroftheElements] and not buff[classtable.MasteroftheElementsBuff].up and ( Maelstrom >= 75 or Maelstrom >= 50 and not talents[classtable.ElementalBlast] ) and talents[classtable.SwellingMaelstrom] and Maelstrom <= 130) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.Earthquake) and CheckSpellCosts(classtable.Earthquake, 'Earthquake')) and (( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up ) and ( not talents[classtable.ElementalBlast] and targets <2 or targets >1 )) and cooldown[classtable.Earthquake].ready then
        return classtable.Earthquake
    end
    if (MaxDps:FindSpell(classtable.Earthquake) and CheckSpellCosts(classtable.Earthquake, 'Earthquake')) and (targets >1 and ( targets >1 or targets >1 ) and not talents[classtable.EchoesofGreatSundering] and not talents[classtable.ElementalBlast]) and cooldown[classtable.Earthquake].ready then
        return classtable.Earthquake
    end
    if (MaxDps:FindSpell(classtable.ElementalBlast) and CheckSpellCosts(classtable.ElementalBlast, 'ElementalBlast')) and (( not talents[classtable.MasteroftheElements] or buff[classtable.MasteroftheElementsBuff].up ) and debuff[classtable.ElectrifiedShocksDeBuff].up) and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (buff[classtable.IcefuryBuff].up and buff[classtable.MasteroftheElementsBuff].up and Maelstrom <110 and cooldown[classtable.LavaBurst].charges <1.0 and talents[classtable.ElectrifiedShocks] and talents[classtable.ElementalBlast] and not talents[classtable.LightningRod]) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.ElementalBlast) and CheckSpellCosts(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MasteroftheElementsBuff].up or talents[classtable.LightningRod]) and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    if (MaxDps:FindSpell(classtable.EarthShock) and CheckSpellCosts(classtable.EarthShock, 'EarthShock')) and cooldown[classtable.EarthShock].ready then
        return classtable.EarthShock
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (buff[classtable.IcefuryBuff].up and talents[classtable.ElectrifiedShocks] and buff[classtable.MasteroftheElementsBuff].up and not talents[classtable.LightningRod] and targets >1 and ( targets >1 or targets >1 )) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (talents[classtable.DeeplyRootedElements]) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (buff[classtable.IcefuryBuff].up and talents[classtable.FluxMelting] and not buff[classtable.FluxMeltingBuff].up) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (buff[classtable.IcefuryBuff].up and ( talents[classtable.ElectrifiedShocks] and debuff[classtable.ElectrifiedShocksDeBuff].remains <2 or buff[classtable.IcefuryBuff].remains <6 )) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.LavaBurst) and CheckSpellCosts(classtable.LavaBurst, 'LavaBurst')) and (talents[classtable.EchooftheElements] or talents[classtable.LavaSurge] or talents[classtable.PrimordialSurge] or not talents[classtable.ElementalBlast] or not talents[classtable.MasteroftheElements] or buff[classtable.StormkeeperBuff].up) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:FindSpell(classtable.ElementalBlast) and CheckSpellCosts(classtable.ElementalBlast, 'ElementalBlast')) and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.PoweroftheMaelstromBuff].up and talents[classtable.UnrelentingCalamity] and targets >1 and ( targets >1 or targets >1 )) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.PoweroftheMaelstromBuff].up and talents[classtable.UnrelentingCalamity]) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.Icefury) and CheckSpellCosts(classtable.Icefury, 'Icefury')) and cooldown[classtable.Icefury].ready then
        return classtable.Icefury
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (( UnitExists('pet') and UnitName('pet')  == 'storm_elemental' ) and debuff[classtable.LightningRodDeBuff].up and ( debuff[classtable.ElectrifiedShocksDeBuff].up or buff[classtable.PoweroftheMaelstromBuff].up ) and targets >1 and ( targets >1 or targets >1 )) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (( UnitExists('pet') and UnitName('pet')  == 'storm_elemental' ) and debuff[classtable.LightningRodDeBuff].up and ( debuff[classtable.ElectrifiedShocksDeBuff].up or buff[classtable.PoweroftheMaelstromBuff].up )) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (buff[classtable.IcefuryBuff].up and buff[classtable.MasteroftheElementsBuff].up and not buff[classtable.LavaSurgeBuff].up and not talents[classtable.ElectrifiedShocks] and not talents[classtable.FluxMelting] and cooldown[classtable.LavaBurst].charges <1.0 and talents[classtable.EchooftheElements]) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (buff[classtable.IcefuryBuff].up and ( talents[classtable.FluxMelting] or talents[classtable.ElectrifiedShocks] and not talents[classtable.LightningRod] )) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MasteroftheElementsBuff].up and not buff[classtable.LavaSurgeBuff].up and ( cooldown[classtable.LavaBurst].charges <1.0 and talents[classtable.EchooftheElements] ) and targets >1 and ( targets >1 or targets >1 )) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MasteroftheElementsBuff].up and not buff[classtable.LavaSurgeBuff].up and ( cooldown[classtable.LavaBurst].charges <1.0 and talents[classtable.EchooftheElements] )) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and (buff[classtable.IcefuryBuff].up and not talents[classtable.ElectrifiedShocks] and not talents[classtable.FluxMelting]) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
    if (MaxDps:FindSpell(classtable.ChainLightning) and CheckSpellCosts(classtable.ChainLightning, 'ChainLightning')) and (targets >1 and ( targets >1 or targets >1 )) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:FindSpell(classtable.LightningBolt) and CheckSpellCosts(classtable.LightningBolt, 'LightningBolt')) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShock].refreshable) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FlameShock) and CheckSpellCosts(classtable.FlameShock, 'FlameShock')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >6) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:FindSpell(classtable.FrostShock) and CheckSpellCosts(classtable.FrostShock, 'FrostShock')) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
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
    targets = 3--MaxDps:SmartAoe()
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
    classtable.StormkeeperBuff = 191634
    classtable.PrimordialWaveBuff = 375986
    classtable.SurgeofPowerBuff = 285514
    classtable.SplinteredElementsBuff = 382043
    classtable.FlameShockDeBuff = 188389
    classtable.MasteroftheElementsBuff = 260734
    classtable.MagmaChamberBuff = 381933
    classtable.LavaSurgeBuff = 77762
    classtable.EchoesofGreatSunderingEsBuff = 336217
    classtable.EchoesofGreatSunderingEbBuff = 336217
    classtable.AscendanceBuff = 114050
    classtable.IcefuryBuff = 462818
    classtable.ElectrifiedShocksDeBuff = 382089
    classtable.PoweroftheMaelstromBuff = 191877
    classtable.WindspeakersLavaResurgenceBuff = 378269
    classtable.FluxMeltingBuff = 381777
    classtable.LightningRodDeBuff = 197209

    if (MaxDps:FindSpell(classtable.SpiritwalkersGrace) and CheckSpellCosts(classtable.SpiritwalkersGrace, 'SpiritwalkersGrace')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >6) and cooldown[classtable.SpiritwalkersGrace].ready then
        MaxDps:GlowCooldown(classtable.SpiritwalkersGrace, cooldown[classtable.SpiritwalkersGrace].ready)
    end
    if (MaxDps:FindSpell(classtable.WindShear) and CheckSpellCosts(classtable.WindShear, 'WindShear')) and cooldown[classtable.WindShear].ready then
        MaxDps:GlowCooldown(classtable.WindShear, select(8,UnitCastingInfo('target') == false) and cooldown[classtable.WindShear].ready)
    end
    if (MaxDps:FindSpell(classtable.NaturesSwiftness) and CheckSpellCosts(classtable.NaturesSwiftness, 'NaturesSwiftness')) and cooldown[classtable.NaturesSwiftness].ready then
        return classtable.NaturesSwiftness
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
