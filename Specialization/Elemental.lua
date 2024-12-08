local _, addonTable = ...
local Shaman = addonTable.Shaman
local MaxDps = _G.MaxDps
if not MaxDps then return end
local setSpell

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
local spymaster_in_onest
local spymaster_in_twond


local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end


function Elemental:precombat()
    if (MaxDps:CheckSpellUsable(classtable.FlametongueWeapon, 'FlametongueWeapon')) and (talents[classtable.ImprovedFlametongueWeapon]) and cooldown[classtable.FlametongueWeapon].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.FlametongueWeapon end
    end
    if (MaxDps:CheckSpellUsable(classtable.Skyfury, 'Skyfury')) and not buff[classtable.Skyfury].up and cooldown[classtable.Skyfury].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Skyfury end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningShield, 'LightningShield')) and not buff[classtable.LightningShield].up and cooldown[classtable.LightningShield].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.LightningShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderstrikeWard, 'ThunderstrikeWard')) and cooldown[classtable.ThunderstrikeWard].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.ThunderstrikeWard end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShield, 'EarthShield')) and (not buff[classtable.EarthShieldBufff].up and not buff[classtable.EarthShieldBuff].up and talents[classtable.ElementalOrbit]) and cooldown[classtable.EarthShield].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.EarthShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormkeeper, 'Stormkeeper')) and cooldown[classtable.Stormkeeper].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.Stormkeeper, cooldown[classtable.Stormkeeper].ready)
    end
    mael_cap = 100 + 50 * (talents[classtable.SwellingMaelstrom] and talents[classtable.SwellingMaelstrom] or 0) + 25 * (talents[classtable.PrimordialCapacity] and talents[classtable.PrimordialCapacity] or 0)
    spymaster_in_onest = MaxDps:CheckTrinketNames('SpymastersWeb')
    spymaster_in_twond = MaxDps:CheckTrinketNames('SpymastersWeb')
end
function Elemental:aoe()
    if (MaxDps:CheckSpellUsable(classtable.FireElemental, 'FireElemental')) and cooldown[classtable.FireElemental].ready then
        MaxDps:GlowCooldown(classtable.FireElemental, cooldown[classtable.FireElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.StormElemental, 'StormElemental')) and cooldown[classtable.StormElemental].ready then
        MaxDps:GlowCooldown(classtable.StormElemental, cooldown[classtable.StormElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormkeeper, 'Stormkeeper')) and cooldown[classtable.Stormkeeper].ready then
        MaxDps:GlowCooldown(classtable.Stormkeeper, cooldown[classtable.Stormkeeper].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.TotemicRecall, 'TotemicRecall')) and (cooldown[classtable.LiquidMagmaTotem].remains >15 and ( debuff[classtable.FlameShockDeBuff].count  <( targets >6 ) - 2 or talents[classtable.FireElemental] )) and cooldown[classtable.TotemicRecall].ready then
        if not setSpell then setSpell = classtable.TotemicRecall end
    end
    if (MaxDps:CheckSpellUsable(classtable.LiquidMagmaTotem, 'LiquidMagmaTotem')) and ((GetTotemDuration('liquid_magma_totem') == 0)) and cooldown[classtable.LiquidMagmaTotem].ready then
        if not setSpell then setSpell = classtable.LiquidMagmaTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave')) and (buff[classtable.SurgeofPowerBuff].up or not talents[classtable.SurgeofPower] or Maelstrom <60 - 5 * talents[classtable.EyeoftheStorm]) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AncestralSwiftness, 'AncestralSwiftness')) and cooldown[classtable.AncestralSwiftness].ready then
        MaxDps:GlowCooldown(classtable.AncestralSwiftness, cooldown[classtable.AncestralSwiftness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and buff[classtable.SurgeofPowerBuff].up and debuff[classtable.FlameShockDeBuff].remains <ttd - 16 and debuff[classtable.FlameShockDeBuff].count  <( targets >6 ) and not talents[classtable.LiquidMagmaTotem]) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and talents[classtable.FireElemental] and ( buff[classtable.SurgeofPowerBuff].up or not talents[classtable.SurgeofPower] ) and debuff[classtable.FlameShockDeBuff].remains <ttd - 5 and ( debuff[classtable.FlameShockDeBuff].count  <6 or debuff[classtable.FlameShockDeBuff].remains >0 )) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance')) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (not buff[classtable.ArcDischargeBuff].up and ( buff[classtable.SurgeofPowerBuff].up or not talents[classtable.SurgeofPower] )) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.StormkeeperBuff].up and buff[classtable.SurgeofPowerBuff].up and targets == 2) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and buff[classtable.PrimordialWaveBuff].up and ( buff[classtable.StormkeeperBuff].up and targets >= 6 or buff[classtable.TempestBuff].up ) and Maelstrom <60 - 5 * (talents[classtable.EyeoftheStorm] and talents[classtable.EyeoftheStorm] or 0) and talents[classtable.SurgeofPower]) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and buff[classtable.PrimordialWaveBuff].up) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains and cooldown[classtable.LavaBurst].ready and buff[classtable.LavaSurgeBuff].up and not buff[classtable.MasteroftheElementsBuff].up and talents[classtable.MasteroftheElements] and talents[classtable.FireElemental]) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (targets == 2 and ( Maelstrom >mael_cap - 30 or cooldown[classtable.PrimordialWave].remains <gcd and talents[classtable.SurgeofPower] or ( buff[classtable.StormkeeperBuff].up and targets >= 6 or buff[classtable.TempestBuff].up ) and talents[classtable.SurgeofPower] )) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (cooldown[classtable.PrimordialWave].remains <gcd and talents[classtable.SurgeofPower] and ( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up or not talents[classtable.EchoesofGreatSundering] )) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (( MaxDps:DebuffCounter(classtable.LightningRod) == 0 and talents[classtable.LightningRod] or Maelstrom >mael_cap - 30 ) and ( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up or not talents[classtable.EchoesofGreatSundering] )) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (( buff[classtable.StormkeeperBuff].up and targets >= 6 or buff[classtable.TempestBuff].up ) and talents[classtable.SurgeofPower] and ( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up or not talents[classtable.EchoesofGreatSundering] )) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (talents[classtable.EchoesofGreatSundering] and not buff[classtable.EchoesofGreatSunderingEbBuff].up and ( MaxDps:DebuffCounter(classtable.LightningRod) == 0 or Maelstrom >mael_cap - 30 or ( buff[classtable.StormkeeperBuff].up and targets >= 6 or buff[classtable.TempestBuff].up ) and talents[classtable.SurgeofPower] )) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (talents[classtable.EchoesofGreatSundering] and not buff[classtable.EchoesofGreatSunderingEsBuff].up and ( MaxDps:DebuffCounter(classtable.LightningRod) == 0 or Maelstrom >mael_cap - 30 or ( buff[classtable.StormkeeperBuff].up and targets >= 6 or buff[classtable.TempestBuff].up ) and talents[classtable.SurgeofPower] )) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Icefury, 'Icefury')) and (talents[classtable.FusionofElements] and not ( buff[classtable.FusionofElementsNatureBuff].up or buff[classtable.FusionofElementsFireBuff].up )) and cooldown[classtable.Icefury].ready then
        if not setSpell then setSpell = classtable.Icefury end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and talents[classtable.MasteroftheElements] and not buff[classtable.MasteroftheElementsBuff].up and not buff[classtable.AscendanceBuff].up and talents[classtable.FireElemental]) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
end
function Elemental:single_target()
    if (MaxDps:CheckSpellUsable(classtable.FireElemental, 'FireElemental')) and cooldown[classtable.FireElemental].ready then
        MaxDps:GlowCooldown(classtable.FireElemental, cooldown[classtable.FireElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.StormElemental, 'StormElemental')) and cooldown[classtable.StormElemental].ready then
        MaxDps:GlowCooldown(classtable.StormElemental, cooldown[classtable.StormElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormkeeper, 'Stormkeeper')) and cooldown[classtable.Stormkeeper].ready then
        MaxDps:GlowCooldown(classtable.Stormkeeper, cooldown[classtable.Stormkeeper].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave')) and (not buff[classtable.SurgeofPowerBuff].up) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AncestralSwiftness, 'AncestralSwiftness')) and cooldown[classtable.AncestralSwiftness].ready then
        MaxDps:GlowCooldown(classtable.AncestralSwiftness, cooldown[classtable.AncestralSwiftness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance')) and (ttd >cooldown[classtable.Ascendance].remains or buff[classtable.SpymastersWebBuff].up or not ( spymaster_in_onest or spymaster_in_twond )) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (buff[classtable.SurgeofPowerBuff].up) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.SurgeofPowerBuff].up) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (buff[classtable.StormFrenzyBuff].count == 2 and not talents[classtable.SurgeofPower]) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.StormFrenzyBuff].count == 2 and not talents[classtable.SurgeofPower]) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.LiquidMagmaTotem, 'LiquidMagmaTotem')) and (debuff[classtable.FlameShockDeBuff].refreshable and not buff[classtable.MasteroftheElementsBuff].up) and cooldown[classtable.LiquidMagmaTotem].ready then
        if not setSpell then setSpell = classtable.LiquidMagmaTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and not buff[classtable.SurgeofPowerBuff].up and not buff[classtable.MasteroftheElementsBuff].up and not talents[classtable.PrimordialWave] and not talents[classtable.LiquidMagmaTotem]) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up ) and ( Maelstrom >mael_cap - 15 or ttd <5 )) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (Maelstrom >mael_cap - 15 or ttd <5) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (Maelstrom >mael_cap - 15 or ttd <5) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up ) and not talents[classtable.SurgeofPower]) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (not talents[classtable.SurgeofPower]) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (not talents[classtable.SurgeofPower]) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Icefury, 'Icefury')) and (not ( buff[classtable.FusionofElementsNatureBuff].up or buff[classtable.FusionofElementsFireBuff].up )) and cooldown[classtable.Icefury].ready then
        if not setSpell then setSpell = classtable.Icefury end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and not buff[classtable.MasteroftheElementsBuff].up) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (not buff[classtable.MasteroftheElementsBuff].up and buff[classtable.LavaSurgeBuff].up) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up ) and ( buff[classtable.TempestBuff].up or buff[classtable.StormkeeperBuff].up ) and talents[classtable.SurgeofPower]) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (( buff[classtable.TempestBuff].up or buff[classtable.StormkeeperBuff].up ) and talents[classtable.SurgeofPower]) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (( buff[classtable.TempestBuff].up or buff[classtable.StormkeeperBuff].up ) and talents[classtable.SurgeofPower]) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Stormkeeper, false)
    MaxDps:GlowCooldown(classtable.WindShear, false)
    MaxDps:GlowCooldown(classtable.SpiritwalkersGrace, false)
    MaxDps:GlowCooldown(classtable.NaturesSwiftness, false)
    MaxDps:GlowCooldown(classtable.FireElemental, false)
    MaxDps:GlowCooldown(classtable.StormElemental, false)
    MaxDps:GlowCooldown(classtable.PrimordialWave, false)
    MaxDps:GlowCooldown(classtable.AncestralSwiftness, false)
    MaxDps:GlowCooldown(classtable.Ascendance, false)
end

function Elemental:callaction()
    if (MaxDps:CheckSpellUsable(classtable.WindShear, 'WindShear')) and cooldown[classtable.WindShear].ready then
        MaxDps:GlowCooldown(classtable.WindShear, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.SpiritwalkersGrace, 'SpiritwalkersGrace')) and cooldown[classtable.SpiritwalkersGrace].ready then
        MaxDps:GlowCooldown(classtable.SpiritwalkersGrace, cooldown[classtable.SpiritwalkersGrace].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningShield, 'LightningShield')) and (not buff[classtable.LightningShieldBuff].up) and cooldown[classtable.LightningShield].ready then
        if not setSpell then setSpell = classtable.LightningShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.NaturesSwiftness, 'NaturesSwiftness')) and cooldown[classtable.NaturesSwiftness].ready then
        MaxDps:GlowCooldown(classtable.NaturesSwiftness, cooldown[classtable.NaturesSwiftness].ready)
    end
    if (targets >1) then
        Elemental:aoe()
    end
    Elemental:single_target()
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
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
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
    classtable.Icefury = 210714
    classtable.FlameShock = MaxDps:FindSpell(188389) and 188389 or MaxDps:FindSpell(470411) and 470411 or 188389
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.EarthShieldBuff = 974
    classtable.EarthShieldBufff = 383648
    classtable.FlameShockDeBuff = 188389
    classtable.SurgeofPowerBuff = 285514
    classtable.ArcDischargeBuff = 0
    classtable.StormkeeperBuff = 191634
    classtable.PrimordialWaveBuff = 375986
    classtable.TempestBuff = 0
    classtable.LavaSurgeBuff = 77762
    classtable.MasteroftheElementsBuff = 260734
    classtable.EchoesofGreatSunderingEsBuff = 336217
    classtable.EchoesofGreatSunderingEbBuff = 336217
    classtable.FusionofElementsNatureBuff = 0
    classtable.FusionofElementsFireBuff = 0
    classtable.AscendanceBuff = 114050
    classtable.SpymastersWebBuff = 0
    classtable.StormFrenzyBuff = 462695
    classtable.LightningShieldBuff = 192106
    setSpell = nil
    ClearCDs()

    Elemental:precombat()

    Elemental:callaction()
    if setSpell then return setSpell end
end
