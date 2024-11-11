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
    if (MaxDps:CheckSpellUsable(classtable.FlametongueWeapon, 'FlametongueWeapon')) and (talents[classtable.ImprovedFlametongueWeapon] and not buff[classtable.ImprovedFlametongueWeaponBuff].up) and cooldown[classtable.FlametongueWeapon].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.FlametongueWeapon end
    end
    --if (MaxDps:CheckSpellUsable(classtable.Skyfury, 'Skyfury')) and cooldown[classtable.Skyfury].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.Skyfury end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.LightningShield, 'LightningShield')) and cooldown[classtable.LightningShield].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.LightningShield end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.ThunderstrikeWard, 'ThunderstrikeWard')) and cooldown[classtable.ThunderstrikeWard].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.ThunderstrikeWard end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.Stormkeeper, 'Stormkeeper')) and cooldown[classtable.Stormkeeper].ready and not UnitAffectingCombat('player') then
    --    MaxDps:GlowCooldown(classtable.Stormkeeper, cooldown[classtable.Stormkeeper].ready)
    --end
    --if (MaxDps:CheckSpellUsable(classtable.EarthShield, 'EarthShield')) and (not buff[classtable.EarthShieldBuff].up and talents[classtable.ElementalOrbit]) and cooldown[classtable.EarthShield].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.EarthShield end
    --end
    mael_cap = 100 + 50 * (talents[classtable.SwellingMaelstrom] and talents[classtable.SwellingMaelstrom] or 1) + 25 * (talents[classtable.PrimordialCapacity] and talents[classtable.PrimordialCapacity] or 1)
    spymaster_in_onest = MaxDps:CheckTrinketNames('SpymastersWeb')
    spymaster_in_twond = MaxDps:CheckTrinketNames('SpymastersWeb')
end
function Elemental:aoe()
    if (MaxDps:CheckSpellUsable(classtable.FireElemental, 'FireElemental')) and (not buff[classtable.FireElementalBuff].up) and cooldown[classtable.FireElemental].ready then
        MaxDps:GlowCooldown(classtable.FireElemental, cooldown[classtable.FireElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.StormElemental, 'StormElemental')) and (not buff[classtable.StormElementalBuff].up) and cooldown[classtable.StormElemental].ready then
        MaxDps:GlowCooldown(classtable.StormElemental, cooldown[classtable.StormElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormkeeper, 'Stormkeeper')) and (not buff[classtable.StormkeeperBuff].up) and cooldown[classtable.Stormkeeper].ready then
        MaxDps:GlowCooldown(classtable.Stormkeeper, cooldown[classtable.Stormkeeper].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.TotemicRecall, 'TotemicRecall')) and (cooldown[classtable.LiquidMagmaTotem].remains >15 and ( debuff[classtable.FlameShockDeBuff].count  <4 or talents[classtable.FireElemental] )) and cooldown[classtable.TotemicRecall].ready then
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
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and buff[classtable.SurgeofPowerBuff].up and talents[classtable.LightningRod] and debuff[classtable.FlameShockDeBuff].remains <ttd - 16 and not talents[classtable.LiquidMagmaTotem]) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and buff[classtable.PrimordialWaveBuff].up and buff[classtable.StormkeeperBuff].up and Maelstrom <60 - 5 * (talents[classtable.EyeoftheStorm] and talents[classtable.EyeoftheStorm] or 0) - ( 8 + 2 * (talents[classtable.FlowofPower] and talents[classtable.FlowofPower] or 0) ) * debuff[classtable.FlameShockDeBuff].count  and targets >= 6 and debuff[classtable.FlameShockDeBuff].count  <6) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and talents[classtable.FireElemental] and ( buff[classtable.SurgeofPowerBuff].up or not talents[classtable.SurgeofPower] ) and debuff[classtable.FlameShockDeBuff].remains <ttd - 5 and ( debuff[classtable.FlameShockDeBuff].count  <6 or debuff[classtable.FlameShockDeBuff].remains >0 )) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (not buff[classtable.ArcDischargeBuff].up) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance')) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBeam, 'LavaBeam')) and (targets >= 6 and buff[classtable.SurgeofPowerBuff].up and buff[classtable.AscendanceBuff].remains >( classtable and classtable.LavaBeam and GetSpellInfo(classtable.LavaBeam).castTime /1000 )) and cooldown[classtable.LavaBeam].ready then
        if not setSpell then setSpell = classtable.LavaBeam end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (targets >= 6 and buff[classtable.SurgeofPowerBuff].up) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and buff[classtable.PrimordialWaveBuff].up and buff[classtable.StormkeeperBuff].up and Maelstrom <60 - 5 * (talents[classtable.EyeoftheStorm] and talents[classtable.EyeoftheStorm] or 0) and targets >= 6 and talents[classtable.SurgeofPower]) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and buff[classtable.PrimordialWaveBuff].up and ( buff[classtable.PrimordialWaveBuff].remains <4 or buff[classtable.LavaSurgeBuff].up )) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains and cooldown[classtable.LavaBurst].ready and buff[classtable.LavaSurgeBuff].up and not buff[classtable.MasteroftheElementsBuff].up and talents[classtable.MasteroftheElements] and talents[classtable.FireElemental]) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (cooldown[classtable.PrimordialWave].remains <gcd and talents[classtable.SurgeofPower] and ( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up or not talents[classtable.EchoesofGreatSundering] )) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (( not buff[classtable.LightningRod].up and talents[classtable.LightningRod] or Maelstrom >mael_cap - 30 ) and ( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up or not talents[classtable.EchoesofGreatSundering] )) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (buff[classtable.StormkeeperBuff].up and targets >= 6 and talents[classtable.SurgeofPower] and ( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up or not talents[classtable.EchoesofGreatSundering] )) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (( buff[classtable.MasteroftheElementsBuff].up or targets >= 5 ) and ( buff[classtable.FusionofElementsNatureBuff].up or buff[classtable.AscendanceBuff].remains >9 or not buff[classtable.AscendanceBuff].up ) and ( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up or not talents[classtable.EchoesofGreatSundering] ) and talents[classtable.FireElemental]) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (talents[classtable.EchoesofGreatSundering] and not buff[classtable.EchoesofGreatSunderingEbBuff].up and ( not buff[classtable.LightningRod].up or Maelstrom >mael_cap - 30 )) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (talents[classtable.EchoesofGreatSundering] and not buff[classtable.EchoesofGreatSunderingEsBuff].up and ( not buff[classtable.LightningRod].up or Maelstrom >mael_cap - 30 )) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Icefury, 'Icefury')) and (talents[classtable.FusionofElements] and not ( buff[classtable.FusionofElementsNatureBuff].up or buff[classtable.FusionofElementsFireBuff].up )) and cooldown[classtable.Icefury].ready then
        if not setSpell then setSpell = classtable.Icefury end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and talents[classtable.MasteroftheElements] and not buff[classtable.MasteroftheElementsBuff].up and not buff[classtable.AscendanceBuff].up and talents[classtable.FireElemental]) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBeam, 'LavaBeam')) and (buff[classtable.StormkeeperBuff].up and ( buff[classtable.SurgeofPowerBuff].up or targets <6 )) and cooldown[classtable.LavaBeam].ready then
        if not setSpell then setSpell = classtable.LavaBeam end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.StormkeeperBuff].up and ( buff[classtable.SurgeofPowerBuff].up or targets <6 )) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBeam, 'LavaBeam')) and (buff[classtable.PoweroftheMaelstromBuff].up and buff[classtable.AscendanceBuff].remains >( classtable and classtable.LavaBeam and GetSpellInfo(classtable.LavaBeam).castTime /1000 ) and not buff[classtable.StormkeeperBuff].up) and cooldown[classtable.LavaBeam].ready then
        if not setSpell then setSpell = classtable.LavaBeam end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.PoweroftheMaelstromBuff].up and not buff[classtable.StormkeeperBuff].up) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBeam, 'LavaBeam')) and (( buff[classtable.MasteroftheElementsBuff].up and targets >= 4 or targets >= 5 ) and buff[classtable.AscendanceBuff].remains >( classtable and classtable.LavaBeam and GetSpellInfo(classtable.LavaBeam).castTime /1000 ) and not buff[classtable.StormkeeperBuff].up) and cooldown[classtable.LavaBeam].ready then
        if not setSpell then setSpell = classtable.LavaBeam end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and talents[classtable.DeeplyRootedElements]) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBeam, 'LavaBeam')) and (buff[classtable.AscendanceBuff].remains >( classtable and classtable.LavaBeam and GetSpellInfo(classtable.LavaBeam).castTime /1000 )) and cooldown[classtable.LavaBeam].ready then
        if not setSpell then setSpell = classtable.LavaBeam end
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
    if (MaxDps:CheckSpellUsable(classtable.FireElemental, 'FireElemental')) and (not buff[classtable.FireElementalBuff].up) and cooldown[classtable.FireElemental].ready then
        MaxDps:GlowCooldown(classtable.FireElemental, cooldown[classtable.FireElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.StormElemental, 'StormElemental')) and (not buff[classtable.StormElementalBuff].up) and cooldown[classtable.StormElemental].ready then
        MaxDps:GlowCooldown(classtable.StormElemental, cooldown[classtable.StormElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormkeeper, 'Stormkeeper')) and (not buff[classtable.AscendanceBuff].up and not buff[classtable.StormkeeperBuff].up) and cooldown[classtable.Stormkeeper].ready then
        MaxDps:GlowCooldown(classtable.Stormkeeper, cooldown[classtable.Stormkeeper].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.TotemicRecall, 'TotemicRecall')) and (cooldown[classtable.LiquidMagmaTotem].remains >15 and targets >1 and talents[classtable.FireElemental]) and cooldown[classtable.TotemicRecall].ready then
        if not setSpell then setSpell = classtable.TotemicRecall end
    end
    if (MaxDps:CheckSpellUsable(classtable.LiquidMagmaTotem, 'LiquidMagmaTotem')) and (not (GetTotemDuration("Liquid Magma Totem") > 0) and not buff[classtable.AscendanceBuff].up and ( talents[classtable.FireElemental] or targets >1 )) and cooldown[classtable.LiquidMagmaTotem].ready then
        if not setSpell then setSpell = classtable.LiquidMagmaTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave')) and (targets == 1 or buff[classtable.SurgeofPowerBuff].up or not talents[classtable.SurgeofPower] or Maelstrom <60 - 5 * (talents[classtable.EyeoftheStorm] and talents[classtable.EyeoftheStorm] or 0) or talents[classtable.LiquidMagmaTotem]) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AncestralSwiftness, 'AncestralSwiftness')) and (not buff[classtable.PrimordialWaveBuff].up or not buff[classtable.StormkeeperBuff].up or not talents[classtable.ElementalBlast]) and cooldown[classtable.AncestralSwiftness].ready then
        MaxDps:GlowCooldown(classtable.AncestralSwiftness, cooldown[classtable.AncestralSwiftness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and targets == 1 and ( debuff[classtable.FlameShockDeBuff].remains <2 or debuff[classtable.FlameShockDeBuff].count  == 0 ) and ( debuff[classtable.FlameShockDeBuff].remains <cooldown[classtable.PrimordialWave].remains or not talents[classtable.PrimordialWave] ) and ( debuff[classtable.FlameShockDeBuff].remains <cooldown[classtable.LiquidMagmaTotem].remains or not talents[classtable.LiquidMagmaTotem] ) and not buff[classtable.SurgeofPowerBuff].up and talents[classtable.FireElemental]) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].count  <targets and targets >1 and ( talents[classtable.DeeplyRootedElements] or talents[classtable.Ascendance] or talents[classtable.PrimordialWave] or talents[classtable.SearingFlames] or talents[classtable.MagmaChamber] ) and ( not buff[classtable.SurgeofPowerBuff].up and buff[classtable.StormkeeperBuff].up or not talents[classtable.SurgeofPower] or cooldown[classtable.Ascendance].remains == 0 and talents[classtable.Ascendance] ) and not talents[classtable.LiquidMagmaTotem]) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (targets >1 and ( talents[classtable.DeeplyRootedElements] or talents[classtable.Ascendance] or talents[classtable.PrimordialWave] or talents[classtable.SearingFlames] or talents[classtable.MagmaChamber] ) and ( buff[classtable.SurgeofPowerBuff].up and not buff[classtable.StormkeeperBuff].up or not talents[classtable.SurgeofPower] ) and debuff[classtable.FlameShockDeBuff].remains <6 and talents[classtable.FireElemental]) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (not buff[classtable.ArcDischargeBuff].up) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.StormkeeperBuff].up and buff[classtable.SurgeofPowerBuff].up) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and buff[classtable.StormkeeperBuff].up and not buff[classtable.MasteroftheElementsBuff].up and not talents[classtable.SurgeofPower] and talents[classtable.MasteroftheElements]) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.StormkeeperBuff].up and not talents[classtable.SurgeofPower] and ( buff[classtable.MasteroftheElementsBuff].up or not talents[classtable.MasteroftheElements] )) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.SurgeofPowerBuff].up and not buff[classtable.AscendanceBuff].up and talents[classtable.EchoChamber]) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance')) and (cooldown[classtable.LavaBurst].charges <1.0) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains and cooldown[classtable.LavaBurst].ready and buff[classtable.LavaSurgeBuff].up and talents[classtable.FireElemental]) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and buff[classtable.PrimordialWaveBuff].up) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (buff[classtable.MasteroftheElementsBuff].up and ( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up or targets >1 and not talents[classtable.EchoesofGreatSundering] and not talents[classtable.ElementalBlast] ) and ( buff[classtable.FusionofElementsNatureBuff].up or Maelstrom >mael_cap - 15 or buff[classtable.AscendanceBuff].remains >9 or not buff[classtable.AscendanceBuff].up ) and talents[classtable.FireElemental]) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MasteroftheElementsBuff].up and ( buff[classtable.FusionofElementsNatureBuff].up or buff[classtable.FusionofElementsFireBuff].up or Maelstrom >mael_cap - 15 or buff[classtable.AscendanceBuff].remains >6 or not buff[classtable.AscendanceBuff].up ) and talents[classtable.FireElemental]) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (buff[classtable.MasteroftheElementsBuff].up and ( buff[classtable.FusionofElementsNatureBuff].up or Maelstrom >mael_cap - 15 or buff[classtable.AscendanceBuff].remains >9 or not buff[classtable.AscendanceBuff].up ) and talents[classtable.FireElemental]) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up or targets >1 and not talents[classtable.EchoesofGreatSundering] and not talents[classtable.ElementalBlast] ) and ( buff[classtable.StormkeeperBuff].up or cooldown[classtable.PrimordialWave].remains <gcd and talents[classtable.SurgeofPower] and not talents[classtable.LiquidMagmaTotem] ) and talents[classtable.StormElemental]) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.StormkeeperBuff].up and talents[classtable.StormElemental]) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (( ( buff[classtable.MasteroftheElementsBuff].up or not buff[classtable.LightningRod].up ) and cooldown[classtable.Stormkeeper].remains >10 or buff[classtable.StormkeeperBuff].up ) and talents[classtable.StormElemental] and targets == 1) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (( cooldown[classtable.PrimordialWave].remains <gcd and talents[classtable.SurgeofPower] and not talents[classtable.LiquidMagmaTotem] or buff[classtable.StormkeeperBuff].up ) and talents[classtable.StormElemental] and targets >1 and talents[classtable.EchoesofGreatSundering] and not buff[classtable.EchoesofGreatSunderingEsBuff].up) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Icefury, 'Icefury')) and (not ( buff[classtable.FusionofElementsNatureBuff].up or buff[classtable.FusionofElementsFireBuff].up ) and buff[classtable.IcefuryBuff].count == 2 and ( talents[classtable.FusionofElements] or not buff[classtable.AscendanceBuff].up )) and cooldown[classtable.Icefury].ready then
        if not setSpell then setSpell = classtable.Icefury end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and buff[classtable.AscendanceBuff].up) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and talents[classtable.MasteroftheElements] and not buff[classtable.MasteroftheElementsBuff].up and talents[classtable.FireElemental]) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and buff[classtable.StormkeeperBuff].up and talents[classtable.ElementalReverb] and talents[classtable.EarthShock] and timeInCombat <10) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (( buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up or targets >1 and not talents[classtable.EchoesofGreatSundering] and not talents[classtable.ElementalBlast] ) and ( Maelstrom >mael_cap - 35 or ttd <5 )) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (Maelstrom >mael_cap - 15 or ttd <5) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (Maelstrom >mael_cap - 15 or ttd <5) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.SurgeofPowerBuff].up) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Icefury, 'Icefury')) and (not ( buff[classtable.FusionofElementsNatureBuff].up or buff[classtable.FusionofElementsFireBuff].up )) and cooldown[classtable.Icefury].ready then
        if not setSpell then setSpell = classtable.Icefury end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (buff[classtable.IcefuryDmgBuff].up and ( targets == 1 or buff[classtable.StormkeeperBuff].up and talents[classtable.SurgeofPower] )) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.PoweroftheMaelstromBuff].up and targets >1 and not buff[classtable.StormkeeperBuff].up) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.PoweroftheMaelstromBuff].up and not buff[classtable.StormkeeperBuff].up) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2 and talents[classtable.DeeplyRootedElements]) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (targets >1 and not buff[classtable.StormkeeperBuff].up) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    --if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and cooldown[classtable.LightningBolt].ready then
    --    if not setSpell then setSpell = classtable.LightningBolt end
    --end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >6) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
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
    if (MaxDps:CheckSpellUsable(classtable.SpiritwalkersGrace, 'SpiritwalkersGrace')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >6) and cooldown[classtable.SpiritwalkersGrace].ready then
        MaxDps:GlowCooldown(classtable.SpiritwalkersGrace, cooldown[classtable.SpiritwalkersGrace].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningShield, 'LightningShield')) and (not buff[classtable.LightningShieldBuff].up) and cooldown[classtable.LightningShield].ready then
        if not setSpell then setSpell = classtable.LightningShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.NaturesSwiftness, 'NaturesSwiftness')) and cooldown[classtable.NaturesSwiftness].ready then
        MaxDps:GlowCooldown(classtable.NaturesSwiftness, cooldown[classtable.NaturesSwiftness].ready)
    end
    if (targets >2) then
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
    classtable.LavaBeam = 114074
    classtable.ImprovedFlametongueWeaponBuff = 382028
    classtable.FlameShock = 470411
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.EarthShieldBuff = 0
    classtable.FireElementalBuff = 0
    classtable.StormElementalBuff = 0
    classtable.StormkeeperBuff = 191634
    classtable.FlameShockDeBuff = 188389
    classtable.SurgeofPowerBuff = 285514
    classtable.PrimordialWaveBuff = 375986
    classtable.ArcDischargeBuff = 0
    classtable.AscendanceBuff = 114050
    classtable.LavaSurgeBuff = 77762
    classtable.MasteroftheElementsBuff = 260734
    classtable.EchoesofGreatSunderingEsBuff = 336217
    classtable.EchoesofGreatSunderingEbBuff = 336217
    classtable.FusionofElementsNatureBuff = 0
    classtable.FusionofElementsFireBuff = 0
    classtable.PoweroftheMaelstromBuff = 191877
    classtable.IcefuryBuff = 462818
    classtable.IcefuryDmgBuff = 0
    classtable.LightningShieldBuff = 192106
    setSpell = nil
    ClearCDs()

    Elemental:precombat()

    Elemental:callaction()
    if setSpell then return setSpell end
end
