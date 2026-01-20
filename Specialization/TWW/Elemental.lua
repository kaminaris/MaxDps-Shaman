local _, addonTable = ...
local Shaman = addonTable.Shaman
local MaxDps = _G.MaxDps
if not MaxDps then return end
local LibStub = LibStub
local setSpell

local ceil = ceil
local floor = floor
local fmod = fmod
local format = format
local max = max
local min = min
local pairs = pairs
local select = select
local strsplit = strsplit
local GetTime = GetTime

local UnitAffectingCombat = UnitAffectingCombat
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitSpellHaste = UnitSpellHaste
local UnitThreatSituation = UnitThreatSituation
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
local GetSpellCastCount = C_Spell.GetSpellCastCount
local GetUnitSpeed = GetUnitSpeed
local GetCritChance = GetCritChance
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = C_Item.GetItemInfo
local GetItemSpell = C_Item.GetItemSpell
local GetNamePlates = C_NamePlate.GetNamePlates and C_NamePlate.GetNamePlates or GetNamePlates
local GetPowerRegenForPowerType = GetPowerRegenForPowerType
local GetSpellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName or GetSpellInfo
local GetTotemInfo = GetTotemInfo
local IsStealthed = IsStealthed
local IsCurrentSpell = C_Spell and C_Spell.IsCurrentSpell
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

local ManaPT = Enum.PowerType.Mana
local RagePT = Enum.PowerType.Rage
local FocusPT = Enum.PowerType.Focus
local EnergyPT = Enum.PowerType.Energy
local ComboPointsPT = Enum.PowerType.ComboPoints
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower
local SoulShardsPT = Enum.PowerType.SoulShards
local DemonicFuryPT = Enum.PowerType.DemonicFury
local BurningEmbersPT = Enum.PowerType.BurningEmbers
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
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Mana
local ManaMax
local ManaDeficit
local ManaPerc
local ManaRegen
local ManaRegenCombined
local ManaTimeToMax
local Maelstrom
local MaelstromMax
local MaelstromDeficit
local MaelstromPerc
local MaelstromRegen
local MaelstromRegenCombined
local MaelstromTimeToMax

local Elemental = {}

local mael_cap = 0
local trinket_1_buffs = false
local trinket_2_buffs = false
local ascendance_trinket = false
local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID


local function GetTotemInfoByName(name)
    local info = {
        duration = 0,
        remains = 0,
        up = false,
    }
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local remains = math.floor(startTime+duration-GetTime())
        if (totemName == name ) then
            info.duration = duration
            info.up = true
            info.remains = remains
            break
        end
    end
    return info
end

local function GetTotemInfoById(sSpellID)
    local info = {
        duration = 0,
        remains = 0,
        up = false,
    }
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon, modRate, spellID = GetTotemInfo(index)
        local sName = sSpellID and GetSpellInfo(sSpellID).name or ''
        local remains = math.floor(startTime+duration-GetTime())
        if (spellID == sSpellID) or (totemName == sName ) then
            info.duration = duration
            info.up = true
            info.remains = remains
            break
        end
    end
    return info
end

local function GetTotemTypeActive(i)
   local arg1, totemName, startTime, duration, icon = GetTotemInfo(i)
   return duration > 0
end


function Elemental:precombat()
    if (MaxDps:CheckSpellUsable(classtable.FlametongueWeapon, 'FlametongueWeapon')) and mainHandEnchantID ~= 5400 and ((talents[classtable.ImprovedFlametongueWeapon] and true or false)) and cooldown[classtable.FlametongueWeapon].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.FlametongueWeapon end
    end
    if (MaxDps:CheckSpellUsable(classtable.Skyfury, 'Skyfury')) and not buff[classtable.Skyfury].up and cooldown[classtable.Skyfury].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Skyfury end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningShield, 'LightningShield')) and not buff[classtable.LightningShield].up and cooldown[classtable.LightningShield].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.LightningShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderstrikeWard, 'ThunderstrikeWard')) and offHandEnchantID ~= 7587 and not buff[classtable.ThunderstrikeWard].up and cooldown[classtable.ThunderstrikeWard].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.ThunderstrikeWard end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShield, 'EarthShield')) and (not buff[classtable.EarthShieldBuff].up and talents[classtable.ElementalOrbit]) and cooldown[classtable.EarthShield].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.EarthShield end
    end
    mael_cap = 100 + 50*(talents[classtable.SwellingMaelstrom] and talents[classtable.SwellingMaelstrom] or 0) + 25*(talents[classtable.PrimordialCapacity] and talents[classtable.PrimordialCapacity] or 0)
    trinket_1_buffs = (MaxDps:HasOnUseEffect('13') or MaxDps:CheckTrinketNames('FunhouseLens'))
    trinket_2_buffs = (MaxDps:HasOnUseEffect('14') or MaxDps:CheckTrinketNames('FunhouseLens'))
    if (MaxDps:CheckSpellUsable(classtable.Stormkeeper, 'Stormkeeper')) and cooldown[classtable.Stormkeeper].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.Stormkeeper, cooldown[classtable.Stormkeeper].ready)
    end
end
function Elemental:aoe()
    if (MaxDps:CheckSpellUsable(classtable.FireElemental, 'FireElemental')) and cooldown[classtable.FireElemental].ready then
        MaxDps:GlowCooldown(classtable.FireElemental, cooldown[classtable.FireElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.StormElemental, 'StormElemental')) and ((not buff[classtable.StormElementalBuff].up or not talents[classtable.EchooftheElementals]) and not buff[classtable.AncestralWisdomBuff].up) and cooldown[classtable.StormElemental].ready then
        MaxDps:GlowCooldown(classtable.StormElemental, cooldown[classtable.StormElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormkeeper, 'Stormkeeper')) and (talents[classtable.HeraldoftheStorms] or cooldown[classtable.PrimordialWave].remains <gcd or not talents[classtable.PrimordialWave]) and cooldown[classtable.Stormkeeper].ready then
        MaxDps:GlowCooldown(classtable.Stormkeeper, cooldown[classtable.Stormkeeper].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.LiquidMagmaTotem, 'LiquidMagmaTotem') and talents[classtable.LiquidMagmaTotem]) and ((cooldown[classtable.PrimordialWave].remains <5*gcd or not talents[classtable.PrimordialWave]) and (MaxDps:DebuffCounter(classtable.FlameShockDeBuff) <= targets-3 or MaxDps:DebuffCounter(classtable.FlameShockDeBuff)<(math.max(targets , 3)))) and cooldown[classtable.LiquidMagmaTotem].ready then
        if not setSpell then setSpell = classtable.LiquidMagmaTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (cooldown[classtable.PrimordialWave].remains <gcd and not debuff[classtable.FlameShockDeBuff].up and (talents[classtable.PrimordialWave] or targets <= 3) and cooldown[classtable.Ascendance].remains >10) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave') and talents[classtable.PrimordialWave]) and (MaxDps:DebuffCounter(classtable.FlameShockDeBuff) == math.max(targets , 6) or (cooldown[classtable.LiquidMagmaTotem].remains >15 or not talents[classtable.LiquidMagmaTotem]) and cooldown[classtable.Ascendance].remains >15) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AncestralSwiftness, 'AncestralSwiftness') and talents[classtable.AncestralSwiftness]) and cooldown[classtable.AncestralSwiftness].ready then
        MaxDps:GlowCooldown(classtable.AncestralSwiftness, cooldown[classtable.AncestralSwiftness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance') and talents[classtable.Ascendance]) and ((talents[classtable.FirstAscendant] or ttd >200 or ttd <80 or ascendance_trinket) and (buff[classtable.FuryofStormsBuff].up or not talents[classtable.FuryoftheStorms])) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (buff[classtable.ArcDischargeBuff].count <2 and (buff[classtable.SurgeofPowerBuff].up or not talents[classtable.SurgeofPower])) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.StormkeeperBuff].up and buff[classtable.SurgeofPowerBuff].up and targets == 2) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (targets >= 6 and buff[classtable.SurgeofPowerBuff].up) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.StormFrenzyBuff].count == 2 and not talents[classtable.SurgeofPower] and Maelstrom <mael_cap-(15 + buff[classtable.StormkeeperBuff].upMath*targets * targets) and buff[classtable.StormkeeperBuff].up and not buff[classtable.CalloftheAncestorsBuff].up and targets == 2) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.StormFrenzyBuff].count == 2 and not talents[classtable.SurgeofPower] and Maelstrom <mael_cap-(15 + buff[classtable.StormkeeperBuff].upMath*targets * targets)) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (cooldown[classtable.LavaBurst].ready and buff[classtable.LavaSurgeBuff].up and buff[classtable.FusionofElementsFireBuff].up and not buff[classtable.MasteroftheElementsBuff].up and (Maelstrom >52-5 * (talents[classtable.EyeoftheStorm] and talents[classtable.EyeoftheStorm] or 0) and (buff[classtable.EchoesofGreatSunderingEsBuff].up or not talents[classtable.EchoesofGreatSundering]))) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and ((Maelstrom >mael_cap-10*(targets + 1) or buff[classtable.MasteroftheElementsBuff].up or buff[classtable.AscendanceBuff].up and buff[classtable.AscendanceBuff].remains <3 or MaxDps:boss() and ttd <5) and (buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up or not talents[classtable.EchoesofGreatSundering] and (not talents[classtable.ElementalBlast] or targets >1+(talents[classtable.Tempest] and talents[classtable.Tempest] or 0))) and (cooldown[classtable.PrimordialWave].remains >8 or not ((MaxDps.tier and MaxDps.tier[34].count >= 4) and talents[classtable.AncestralSwiftness]) or Maelstrom >mael_cap-20)) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast') and talents[classtable.ElementalBlast]) and ((Maelstrom >mael_cap-10*(targets + 1) or buff[classtable.MasteroftheElementsBuff].up or buff[classtable.AscendanceBuff].up and buff[classtable.AscendanceBuff].remains <3 or MaxDps:boss() and ttd <5) and (cooldown[classtable.PrimordialWave].remains >8 or not ((MaxDps.tier and MaxDps.tier[34].count >= 4) and talents[classtable.AncestralSwiftness]) or Maelstrom >mael_cap-20)) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and ((Maelstrom >mael_cap-10*(targets + 1) or buff[classtable.MasteroftheElementsBuff].up or buff[classtable.AscendanceBuff].up and buff[classtable.AscendanceBuff].remains <3 or MaxDps:boss() and ttd <5) and (cooldown[classtable.PrimordialWave].remains >8 or not ((MaxDps.tier and MaxDps.tier[34].count >= 4) and talents[classtable.AncestralSwiftness]) or Maelstrom >mael_cap-20)) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (talents[classtable.LightningRod] and MaxDps:DebuffCounter(classtable.LightningRod) <targets and (buff[classtable.StormkeeperBuff].up or buff[classtable.TempestBuff].up or not talents[classtable.SurgeofPower]) and (buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up or not talents[classtable.EchoesofGreatSundering] and (not talents[classtable.ElementalBlast] or targets >1+3 * (talents[classtable.Tempest] and talents[classtable.Tempest] or 0)))) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast') and talents[classtable.ElementalBlast]) and (talents[classtable.LightningRod] and MaxDps:DebuffCounter(classtable.LightningRod) <targets and (buff[classtable.StormkeeperBuff].up or buff[classtable.TempestBuff].up or not talents[classtable.SurgeofPower])) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (talents[classtable.LightningRod] and MaxDps:DebuffCounter(classtable.LightningRod) <targets and (buff[classtable.StormkeeperBuff].up or buff[classtable.TempestBuff].up or not talents[classtable.SurgeofPower])) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Icefury, 'Icefury')) and (talents[classtable.FusionofElements] and not (buff[classtable.FusionofElementsNatureBuff].up or buff[classtable.FusionofElementsFireBuff].up) and (targets <= 4 or not talents[classtable.ElementalBlast] or not talents[classtable.EchoesofGreatSundering])) and cooldown[classtable.Icefury].ready then
        if not setSpell then setSpell = classtable.Icefury end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (cooldown[classtable.LavaBurst].ready and buff[classtable.LavaSurgeBuff].up and not buff[classtable.MasteroftheElementsBuff].up and talents[classtable.MasteroftheElements] and targets <= 3) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (not buff[classtable.MasteroftheElementsBuff].up and talents[classtable.MasteroftheElements] and (buff[classtable.StormkeeperBuff].up or buff[classtable.TempestBuff].up or Maelstrom >82-10 * (talents[classtable.EyeoftheStorm] and talents[classtable.EyeoftheStorm] or 0) or Maelstrom >52-5 * (talents[classtable.EyeoftheStorm] and talents[classtable.EyeoftheStorm] or 0) and (buff[classtable.EchoesofGreatSunderingEbBuff].up or not talents[classtable.ElementalBlast])) and targets <= 3 and not talents[classtable.LightningRod] and talents[classtable.CalloftheAncestors]) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (not buff[classtable.MasteroftheElementsBuff].up and targets == 2) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (MaxDps:DebuffCounter(classtable.FlameShockDeBuff) == 0 and buff[classtable.FusionofElementsFireBuff].up and (not talents[classtable.ElementalBlast] or not talents[classtable.EchoesofGreatSundering] and targets >1+(talents[classtable.Tempest] and talents[classtable.Tempest] or 0))) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (((buff[classtable.StormkeeperBuff].up and targets >= 6 or buff[classtable.TempestBuff].up) and talents[classtable.SurgeofPower]) and (buff[classtable.EchoesofGreatSunderingEsBuff].up or buff[classtable.EchoesofGreatSunderingEbBuff].up or not talents[classtable.EchoesofGreatSundering] and (not talents[classtable.ElementalBlast] or targets >1+(talents[classtable.Tempest] and talents[classtable.Tempest] or 0)))) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast') and talents[classtable.ElementalBlast]) and ((buff[classtable.StormkeeperBuff].up and targets >= 6 or buff[classtable.TempestBuff].up) and talents[classtable.SurgeofPower]) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and ((buff[classtable.StormkeeperBuff].up and targets >= 6 or buff[classtable.TempestBuff].up) and talents[classtable.SurgeofPower]) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (buff[classtable.IcefuryDmgBuff].up and not buff[classtable.AscendanceBuff].up and not buff[classtable.StormkeeperBuff].up and (talents[classtable.CalloftheAncestors] or targets <= 3)) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
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
    if (MaxDps:CheckSpellUsable(classtable.StormElemental, 'StormElemental')) and ((not buff[classtable.StormElementalBuff].up or not talents[classtable.EchooftheElementals]) and not buff[classtable.AncestralWisdomBuff].up) and cooldown[classtable.StormElemental].ready then
        MaxDps:GlowCooldown(classtable.StormElemental, cooldown[classtable.StormElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormkeeper, 'Stormkeeper')) and (talents[classtable.HeraldoftheStorms] or cooldown[classtable.PrimordialWave].remains <gcd or not talents[classtable.PrimordialWave]) and cooldown[classtable.Stormkeeper].ready then
        MaxDps:GlowCooldown(classtable.Stormkeeper, cooldown[classtable.Stormkeeper].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.LiquidMagmaTotem, 'LiquidMagmaTotem') and talents[classtable.LiquidMagmaTotem]) and (not debuff[classtable.FlameShockDeBuff].up and not buff[classtable.SurgeofPowerBuff].up and not buff[classtable.MasteroftheElementsBuff].up and not ((MaxDps.tier and MaxDps.tier[34].count >= 2) and talents[classtable.AncestralSwiftness])) and cooldown[classtable.LiquidMagmaTotem].ready then
        if not setSpell then setSpell = classtable.LiquidMagmaTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.LiquidMagmaTotem, 'LiquidMagmaTotem') and talents[classtable.LiquidMagmaTotem]) and (debuff[classtable.FlameShockDeBuff].refreshable and not buff[classtable.SurgeofPowerBuff].up and not buff[classtable.MasteroftheElementsBuff].up and cooldown[classtable.Ascendance].ready) and cooldown[classtable.LiquidMagmaTotem].ready then
        if not setSpell then setSpell = classtable.LiquidMagmaTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up and not buff[classtable.SurgeofPowerBuff].up and not buff[classtable.MasteroftheElementsBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave') and talents[classtable.PrimordialWave]) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AncestralSwiftness, 'AncestralSwiftness') and talents[classtable.AncestralSwiftness]) and cooldown[classtable.AncestralSwiftness].ready then
        MaxDps:GlowCooldown(classtable.AncestralSwiftness, cooldown[classtable.AncestralSwiftness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance') and talents[classtable.Ascendance]) and ((talents[classtable.FirstAscendant] or ascendance_trinket) and (buff[classtable.FuryofStormsBuff].up or cooldown[classtable.Stormkeeper].remains >12 or not talents[classtable.FuryoftheStorms]) and (cooldown[classtable.PrimordialWave].remains >25 or not talents[classtable.PrimordialWave])) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (buff[classtable.SurgeofPowerBuff].up) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.SurgeofPowerBuff].up) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (buff[classtable.StormFrenzyBuff].count == 2 and not (talents[classtable.SurgeofPower] and true or false)) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.LiquidMagmaTotem, 'LiquidMagmaTotem') and talents[classtable.LiquidMagmaTotem]) and (debuff[classtable.FlameShockDeBuff].refreshable and not buff[classtable.MasteroftheElementsBuff].up and not talents[classtable.CalloftheAncestors]) and cooldown[classtable.LiquidMagmaTotem].ready then
        if not setSpell then setSpell = classtable.LiquidMagmaTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.LiquidMagmaTotem, 'LiquidMagmaTotem') and talents[classtable.LiquidMagmaTotem]) and (cooldown[classtable.PrimordialWave].remains >24 and not buff[classtable.AscendanceBuff].up and Maelstrom <mael_cap-10 and not buff[classtable.AncestralSwiftnessBuff].up and not buff[classtable.MasteroftheElementsBuff].up) and cooldown[classtable.LiquidMagmaTotem].ready then
        if not setSpell then setSpell = classtable.LiquidMagmaTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and not buff[classtable.SurgeofPowerBuff].up and not buff[classtable.MasteroftheElementsBuff].up and talents[classtable.EruptingLava]) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast') and talents[classtable.ElementalBlast]) and (Maelstrom >mael_cap-15 or buff[classtable.MasteroftheElementsBuff].up or buff[classtable.AncestralWisdomBuff].up and buff[classtable.AncestralWisdomBuff].remains <2) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (Maelstrom >mael_cap-15 or buff[classtable.MasteroftheElementsBuff].up or buff[classtable.AncestralWisdomBuff].up and buff[classtable.AncestralWisdomBuff].remains <2) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Icefury, 'Icefury')) and (not (buff[classtable.FusionofElementsNatureBuff].up or buff[classtable.FusionofElementsFireBuff].up)) and cooldown[classtable.Icefury].ready then
        if not setSpell then setSpell = classtable.Icefury end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (not buff[classtable.MasteroftheElementsBuff].up and (buff[classtable.LavaSurgeBuff].up or buff[classtable.TempestBuff].up or buff[classtable.StormkeeperBuff].up or cooldown[classtable.LavaBurst].charges >1.8 or Maelstrom >mael_cap-30 or (Maelstrom >52-5 * (talents[classtable.EyeoftheStorm] and talents[classtable.EyeoftheStorm] or 0)*(1 + (talents[classtable.ElementalBlast] and talents[classtable.ElementalBlast] or 0))+30 * (talents[classtable.ElementalBlast] and talents[classtable.ElementalBlast] or 0)) and (cooldown[classtable.PrimordialWave].remains >8 or not ((MaxDps.tier and MaxDps.tier[34].count >= 4) and talents[classtable.AncestralSwiftness])))) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (buff[classtable.EchoesofGreatSunderingEbBuff].up and (buff[classtable.TempestBuff].up or buff[classtable.StormkeeperBuff].up) and talents[classtable.SurgeofPower] and not talents[classtable.MasteroftheElements]) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast') and talents[classtable.ElementalBlast]) and ((buff[classtable.TempestBuff].up or buff[classtable.StormkeeperBuff].up) and talents[classtable.SurgeofPower] and not talents[classtable.MasteroftheElements]) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and ((buff[classtable.TempestBuff].up or buff[classtable.StormkeeperBuff].up) and talents[classtable.SurgeofPower] and not talents[classtable.MasteroftheElements]) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.StormElementalBuff].up and buff[classtable.WindGustBuff].count <4) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (buff[classtable.IcefuryDmgBuff].up and not buff[classtable.AscendanceBuff].up and not buff[classtable.StormkeeperBuff].up and talents[classtable.CalloftheAncestors]) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >6 or debuff[classtable.FlameShockDeBuff].refreshable) and cooldown[classtable.FlameShock].ready then
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
    MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, false)
    MaxDps:GlowCooldown(classtable.trinket1, false)
    MaxDps:GlowCooldown(classtable.trinket2, false)
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
    if (MaxDps:CheckSpellUsable(classtable.neural_synapse_enhancer, 'neural_synapse_enhancer')) and (buff[classtable.AscendanceBuff].remains >12 or cooldown[classtable.Ascendance].remains >10) and cooldown[classtable.neural_synapse_enhancer].ready then
        MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, cooldown[classtable.neural_synapse_enhancer].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (((buff[classtable.FuryofStormsBuff].up or not talents[classtable.FuryoftheStorms] or cooldown[classtable.Stormkeeper].remains >10) and (cooldown[classtable.PrimordialWave].remains >25 or not talents[classtable.PrimordialWave] or targets >= 2) and cooldown[classtable.Ascendance].remains >15 or MaxDps:boss() and ttd <21 or buff[classtable.AscendanceBuff].remains >12)) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (((buff[classtable.FuryofStormsBuff].up or not talents[classtable.FuryoftheStorms] or cooldown[classtable.Stormkeeper].remains >10) and (cooldown[classtable.PrimordialWave].remains >25 or not talents[classtable.PrimordialWave] or targets >= 2) and cooldown[classtable.Ascendance].remains >15 or MaxDps:boss() and ttd <21 or buff[classtable.AscendanceBuff].remains >12)) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.main_hand, 'main_hand')) and ((buff[classtable.FuryofStormsBuff].up or not talents[classtable.FuryoftheStorms] or cooldown[classtable.Stormkeeper].remains >10) and (cooldown[classtable.PrimordialWave].remains >25 or not talents[classtable.PrimordialWave]) and cooldown[classtable.Ascendance].remains >15 or buff[classtable.AscendanceBuff].remains >12) and cooldown[classtable.main_hand].ready then
        if not setSpell then setSpell = classtable.main_hand end
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (not (MaxDps:HasOnUseEffect('13')) and (not (MaxDps:HasOnUseEffect('14') and MaxDps:CheckEquipped('NeuralSynapseEnhancer') or MaxDps:CheckEquipped('BestInSlots')) or cooldown[classtable.Ascendance].remains >20 or (MaxDps:CheckTrinketCooldown('14') >20 and cooldown[classtable.NeuralSynapseEnhancer].remains >20 and cooldown[classtable.BestInSlots].remains >20))) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (not (MaxDps:HasOnUseEffect('14')) and (not (MaxDps:HasOnUseEffect('13') and MaxDps:CheckEquipped('NeuralSynapseEnhancer') or MaxDps:CheckEquipped('BestInSlots')) or cooldown[classtable.Ascendance].remains >20 or (MaxDps:CheckTrinketCooldown('13') >20 and cooldown[classtable.NeuralSynapseEnhancer].remains >20 and cooldown[classtable.BestInSlots].remains >20))) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningShield, 'LightningShield')) and (not buff[classtable.LightningShieldBuff].up) and cooldown[classtable.LightningShield].ready then
        if not setSpell then setSpell = classtable.LightningShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.NaturesSwiftness, 'NaturesSwiftness')) and cooldown[classtable.NaturesSwiftness].ready then
        MaxDps:GlowCooldown(classtable.NaturesSwiftness, cooldown[classtable.NaturesSwiftness].ready)
    end
    ascendance_trinket = (MaxDps:HasOnUseEffect('13') and MaxDps:CheckTrinketReady('13') or MaxDps:CheckTrinketCooldown('13') >20) or (MaxDps:HasOnUseEffect('14') and MaxDps:CheckTrinketReady('14') or MaxDps:CheckTrinketCooldown('14') >20) or MaxDps:CheckEquipped('NeuralSynapseEnhancer') and (cooldown[classtable.NeuralSynapseEnhancer].remains == 0 or cooldown[classtable.NeuralSynapseEnhancer].remains >20) or MaxDps:CheckEquipped('BestInSlots') and (cooldown[classtable.BestInSlots].remains == 0 or cooldown[classtable.BestInSlots].remains >20) or not MaxDps:HasOnUseEffect('13') and not MaxDps:HasOnUseEffect('14')
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
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    local trinket1ID = GetInventoryItemID('player', 13)
    local trinket2ID = GetInventoryItemID('player', 14)
    local MHID = GetInventoryItemID('player', 16)
    classtable.trinket1 = (trinket1ID and select(2,GetItemSpell(trinket1ID)) ) or 0
    classtable.trinket2 = (trinket2ID and select(2,GetItemSpell(trinket2ID)) ) or 0
    classtable.main_hand = (MHID and select(2,GetItemSpell(MHID)) ) or 0
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    ManaPerc = (Mana / ManaMax) * 100
    ManaRegen = GetPowerRegenForPowerType(ManaPT)
    ManaTimeToMax = ManaDeficit / ManaRegen
    Maelstrom = UnitPower('player', MaelstromPT)
    MaelstromMax = UnitPowerMax('player', MaelstromPT)
    MaelstromDeficit = MaelstromMax - Maelstrom
    MaelstromPerc = (Maelstrom / MaelstromMax) * 100
    MaelstromRegen = GetPowerRegenForPowerType(MaelstromPT)
    MaelstromTimeToMax = MaelstromDeficit / MaelstromRegen
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID = GetWeaponEnchantInfo()
    classtable.Icefury = 210714
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.EarthShieldBuff = talents[classtable.ElementalOrbit] and 383648 or 974
    classtable.AscendanceBuff = 1219480
    classtable.FuryofStormsBuff = 191716
    classtable.LightningShieldBuff = 192106
    classtable.BloodlustBuff = 2825
    classtable.StormElementalBuff = 192249
    classtable.AncestralWisdomBuff = 0
    classtable.ArcDischargeBuff = 455097
    classtable.SurgeofPowerBuff = 285514
    classtable.StormkeeperBuff = 191634
    classtable.StormFrenzyBuff = 462725
    classtable.CalloftheAncestorsBuff = 447244
    classtable.LavaSurgeBuff = 77762
    classtable.FusionofElementsFireBuff = 462843
    classtable.MasteroftheElementsBuff = 260734
    classtable.EchoesofGreatSunderingEsBuff = 336217
    classtable.EchoesofGreatSunderingEbBuff = 384088
    classtable.TempestBuff = 454015
    classtable.FusionofElementsNatureBuff = 462841
    classtable.IcefuryDmgBuff = 210714
    classtable.AncestralSwiftnessBuff = 443454
    classtable.WindGustBuff = 263806
    classtable.FlameShockDeBuff = 188389

    local function debugg()
        talents[classtable.ImprovedFlametongueWeapon] = 1
        talents[classtable.ElementalOrbit] = 1
        talents[classtable.Ascendance] = 1
        talents[classtable.FuryoftheStorms] = 1
        talents[classtable.PrimordialWave] = 1
        talents[classtable.EchooftheElementals] = 1
        talents[classtable.HeraldoftheStorms] = 1
        talents[classtable.LiquidMagmaTotem] = 1
        talents[classtable.FirstAscendant] = 1
        talents[classtable.SurgeofPower] = 1
        talents[classtable.EchoesofGreatSundering] = 1
        talents[classtable.ElementalBlast] = 1
        talents[classtable.AncestralSwiftness] = 1
        talents[classtable.LightningRod] = 1
        talents[classtable.FusionofElements] = 1
        talents[classtable.MasteroftheElements] = 1
        talents[classtable.CalloftheAncestors] = 1
        talents[classtable.EruptingLava] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Elemental:precombat()

    Elemental:callaction()
    if setSpell then return setSpell end
end
