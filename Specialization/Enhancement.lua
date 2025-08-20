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
local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID

local Enhancement = {}

local trinket1_is_weird = false
local trinket2_is_weird = false
local min_talented_cd_remains = 0
local target_nature_mod = false
local expected_lb_funnel = 0
local expected_cl_funnel = 0
local flame_shock_saturation = false


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


function Enhancement:precombat()
    if (MaxDps:CheckSpellUsable(classtable.WindfuryWeapon, 'WindfuryWeapon')) and mainHandEnchantID ~= 5401 and cooldown[classtable.WindfuryWeapon].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.WindfuryWeapon end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlametongueWeapon, 'FlametongueWeapon')) and offHandEnchantID ~= 5400 and cooldown[classtable.FlametongueWeapon].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.FlametongueWeapon end
    end
    if (MaxDps:CheckSpellUsable(classtable.Skyfury, 'Skyfury')) and (not buff[classtable.SkyfuryBuff].up) and cooldown[classtable.Skyfury].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Skyfury end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningShield, 'LightningShield')) and (not buff[classtable.LightningShield].up) and cooldown[classtable.LightningShield].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.LightningShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShield, 'EarthShield')) and (talents[classtable.ElementalOrbit] and not buff[classtable.EarthShieldBuff].up) and cooldown[classtable.EarthShield].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.EarthShield end
    end
    trinket1_is_weird = MaxDps:CheckTrinketNames('AlgetharPuzzleBox') or MaxDps:CheckTrinketNames('ManicGrieftorch') or MaxDps:CheckTrinketNames('ElementiumPocketAnvil') or MaxDps:CheckTrinketNames('BeaconTotheBeyond')
    trinket2_is_weird = MaxDps:CheckTrinketNames('AlgetharPuzzleBox') or MaxDps:CheckTrinketNames('ManicGrieftorch') or MaxDps:CheckTrinketNames('ElementiumPocketAnvil') or MaxDps:CheckTrinketNames('BeaconTotheBeyond')
    min_talented_cd_remains = ((cooldown[classtable.FeralSpirit].remains%(4 * (talents[classtable.WitchDoctorsAncestry] and talents[classtable.WitchDoctorsAncestry] or 0)))+1000 * (talents[classtable.FeralSpirit] and 0 or 1))>max(cooldown[classtable.DoomWinds].remains + 1000*(talents[classtable.DoomWinds] and 0 or 1)) and 1 or 0>max(cooldown[classtable.Ascendance].remains + 1000*(talents[classtable.Ascendance] and 0 or 1))
    target_nature_mod = (1 + debuff[classtable.ChaosBrandDeBuff].upMath*debuff[classtable.ChaosBrandDeBuff].value)*(1+((debuff[classtable.HuntersMarkDeBuff].upMath * targethealthPerc>=80) and 1 or 0)*debuff[classtable.HuntersMarkDeBuff].value)
    expected_lb_funnel = 450000*(1 + debuff[classtable.LightningRodDeBuff].upMath*target_nature_mod*(1 + buff[classtable.PrimordialWaveBuff].upMath*MaxDps:DebuffCounter(classtable.FlameShockDeBuff) * buff[classtable.PrimordialWaveBuff].value)*debuff[classtable.LightningRodDeBuff].value)
    expected_cl_funnel = 250000*(1 + debuff[classtable.LightningRodDeBuff].upMath*target_nature_mod*(targets >max(3 + 2*(talents[classtable.CrashingStorms] and talents[classtable.CrashingStorms] or 0)) and 1 or 0)*debuff[classtable.LightningRodDeBuff].value)
    if MaxDps:DebuffCounter(classtable.FlameShockDeBuff) >= targets or MaxDps:DebuffCounter(classtable.FlameShockDeBuff) == 6 then
        flame_shock_saturation = true
    end
end
function Enhancement:aoe()
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit') and talents[classtable.FeralSpirit]) and ((talents[classtable.ElementalSpirits] and true or false) or (talents[classtable.AlphaWolf] and true or false)) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (timeInCombat <15) then
        Enhancement:aoe_open()
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and ((talents[classtable.MoltenAssault] and true or false) and not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance') and talents[classtable.Ascendance]) and ((debuff[classtable.FlameShockDeBuff].up or not (talents[classtable.MoltenAssault] and true or false)) and talents[classtable.ThorimsInvocation] or MaxDps:boss() and ttd <1) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (not buff[classtable.ArcDischargeBuff].count >= 1 and ((buff[classtable.MaelstromWeaponBuff].count == 10 and not (talents[classtable.RagingMaelstrom] and true or false)) or (buff[classtable.MaelstromWeaponBuff].count >= 9)) or (buff[classtable.MaelstromWeaponBuff].count >= 5 and (C_Spell.GetSpellCastCount(classtable.Tempest) >30))) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit') and talents[classtable.FeralSpirit]) and ((cooldown[classtable.DoomWinds].remains >30 or cooldown[classtable.DoomWinds].remains <7) or MaxDps:boss() and ttd <16) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds') and talents[classtable.DoomWinds]) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave') and talents[classtable.PrimordialWave]) and (debuff[classtable.FlameShockDeBuff].up and flame_shock_saturation) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialStorm, 'PrimordialStorm') and talents[classtable.PrimordialStorm]) and ((buff[classtable.MaelstromWeaponBuff].count >= 10) and (buff[classtable.DoomWindsBuff].up or not (talents[classtable.DoomWinds] and true or false) or (cooldown[classtable.DoomWinds].remains >buff[classtable.PrimordialStormBuff].remains) or (buff[classtable.PrimordialStormBuff].remains <2*gcd))) and cooldown[classtable.PrimordialStorm].ready then
        if not setSpell then setSpell = classtable.PrimordialStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((talents[classtable.ConvergingStorms] and true or false) and buff[classtable.ElectrostaticWagerBuff].count >6 or not buff[classtable.CrashLightningBuff].up) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and ((talents[classtable.ThorimsInvocation] and true or false) and buff[classtable.MaelstromWeaponBuff].count >0 and talents[classtable.ThorimsInvocation]) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((talents[classtable.ConvergingStorms] and true or false) and (talents[classtable.AlphaWolf] and true or false)) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.ConvergingStormsBuff].count == 6 and buff[classtable.StormblastBuff].count >0 and buff[classtable.LegacyoftheFrostWitchBuff].up and buff[classtable.MaelstromWeaponBuff].count <= 8) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (buff[classtable.MaelstromWeaponBuff].count <= 8) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoltaicBlaze, 'VoltaicBlaze') and talents[classtable.VoltaicBlaze]) and (buff[classtable.MaelstromWeaponBuff].count <= 8) and cooldown[classtable.VoltaicBlaze].ready then
        if not setSpell then setSpell = classtable.VoltaicBlaze end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and not buff[classtable.PrimordialStormBuff].up and (cooldown[classtable.CrashLightning].remains >= 1 or not (talents[classtable.AlphaWolf] and true or false))) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova') and talents[classtable.FireNova]) and (flame_shock_saturation and targets >= 4) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and ((talents[classtable.Stormblast] and true or false) and (talents[classtable.Stormflurry] and true or false)) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoltaicBlaze, 'VoltaicBlaze') and talents[classtable.VoltaicBlaze]) and cooldown[classtable.VoltaicBlaze].ready then
        if not setSpell then setSpell = classtable.VoltaicBlaze end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and ((talents[classtable.LashingFlames] and true or false) or (talents[classtable.MoltenAssault] and true or false) and debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and ((talents[classtable.Hailstorm] and true or false) and not buff[classtable.IceStrikeBuff].up) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and ((talents[classtable.Hailstorm] and true or false) and buff[classtable.HailstormBuff].up) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and ((talents[classtable.MoltenAssault] and true or false) and not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (((talents[classtable.FireNova] and true or false) or (talents[classtable.PrimordialWave] and true or false)) and not flame_shock_saturation) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova') and talents[classtable.FireNova]) and (MaxDps:DebuffCounter(classtable.FlameShockDeBuff) >= 3) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.CrashLightningBuff].up and ((talents[classtable.DeeplyRootedElements] and true or false) or buff[classtable.ConvergingStormsBuff].count == 6)) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((talents[classtable.CrashingStorms] and true or false) and buff[classtable.ClCrashLightningBuff].up) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova') and talents[classtable.FireNova]) and (MaxDps:DebuffCounter(classtable.FlameShockDeBuff) >= 2) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and not buff[classtable.PrimordialStormBuff].up) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (not (talents[classtable.Hailstorm] and true or false)) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
end
function Enhancement:aoe_open()
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((buff[classtable.ElectrostaticWagerBuff].count >9 and buff[classtable.DoomWindsBuff].up) or not buff[classtable.CrashLightningBuff].up) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoltaicBlaze, 'VoltaicBlaze') and talents[classtable.VoltaicBlaze]) and (MaxDps:DebuffCounter(classtable.FlameShockDeBuff) <targets and MaxDps:DebuffCounter(classtable.FlameShockDeBuff) <3) and cooldown[classtable.VoltaicBlaze].ready then
        if not setSpell then setSpell = classtable.VoltaicBlaze end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and ((talents[classtable.MoltenAssault] and true or false) and ((talents[classtable.PrimordialWave] and true or false) or (talents[classtable.FireNova] and true or false)) and debuff[classtable.FlameShockDeBuff].up and (MaxDps:DebuffCounter(classtable.FlameShockDeBuff) <targets) and MaxDps:DebuffCounter(classtable.FlameShockDeBuff) <3) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave') and talents[classtable.PrimordialWave]) and ((buff[classtable.MaelstromWeaponBuff].count >= 4) and debuff[classtable.FlameShockDeBuff].up and flame_shock_saturation) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit') and talents[classtable.FeralSpirit]) and (ttd <16 or buff[classtable.MaelstromWeaponBuff].count >= 9) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds') and talents[classtable.DoomWinds]) and (buff[classtable.MaelstromWeaponBuff].count >= 9 or MaxDps:boss() and ttd <9) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance') and talents[classtable.Ascendance]) and ((debuff[classtable.FlameShockDeBuff].up or not (talents[classtable.MoltenAssault] and true or false)) and talents[classtable.ThorimsInvocation] and (buff[classtable.LegacyoftheFrostWitchBuff].up or not (talents[classtable.LegacyoftheFrostWitch] and true or false)) and not buff[classtable.DoomWindsBuff].up or MaxDps:boss() and ttd <16) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialStorm, 'PrimordialStorm') and talents[classtable.PrimordialStorm]) and ((buff[classtable.MaelstromWeaponBuff].count >= 9) and (buff[classtable.LegacyoftheFrostWitchBuff].up or not (talents[classtable.LegacyoftheFrostWitch] and true or false))) and cooldown[classtable.PrimordialStorm].ready then
        if not setSpell then setSpell = classtable.PrimordialStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (buff[classtable.MaelstromWeaponBuff].count >= 9 and not buff[classtable.ArcDischargeBuff].up) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((buff[classtable.ElectrostaticWagerBuff].count >4)) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and ((talents[classtable.ThorimsInvocation] and true or false) and talents[classtable.ThorimsInvocation]) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and (not buff[classtable.PrimordialStormBuff].up or not buff[classtable.LegacyoftheFrostWitchBuff].up) and buff[classtable.DoomWindsBuff].up) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 9 and (not buff[classtable.PrimordialStormBuff].up or not buff[classtable.LegacyoftheFrostWitchBuff].up)) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.ConvergingStormsBuff].count == 6 and buff[classtable.StormblastBuff].count >1) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoltaicBlaze, 'VoltaicBlaze') and talents[classtable.VoltaicBlaze]) and cooldown[classtable.VoltaicBlaze].ready then
        if not setSpell then setSpell = classtable.VoltaicBlaze end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
end
function Enhancement:aoe_totemic()
    if (timeInCombat <= 16 and (cooldown[classtable.DoomWinds].remains == 0 or cooldown[classtable.Sundering].remains == 0 or not buff[classtable.HotHandBuff].up)) then
        Enhancement:aoe_totemic_open()
    end
    if (MaxDps:CheckSpellUsable(classtable.SurgingTotem, 'SurgingTotem') and talents[classtable.SurgingTotem]) and cooldown[classtable.SurgingTotem].ready then
        if not setSpell then setSpell = classtable.SurgingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance') and talents[classtable.Ascendance]) and (talents[classtable.ThorimsInvocation]) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((talents[classtable.CrashingStorms] and true or false) and (targets >= 15-5 * (talents[classtable.UnrulyWinds] and talents[classtable.UnrulyWinds] or 0))) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit') and talents[classtable.FeralSpirit]) and (ttd <16 or ((cooldown[classtable.DoomWinds].remains >15 or cooldown[classtable.DoomWinds].remains <7 or buff[classtable.WinningStreakBuff].count == 1 and buff[classtable.MaelstromWeaponBuff].count >7) and (cooldown[classtable.PrimordialWave].remains <2 or buff[classtable.PrimordialStormBuff].up or not (talents[classtable.PrimordialStorm] and true or false)))) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialStorm, 'PrimordialStorm') and talents[classtable.PrimordialStorm]) and ((buff[classtable.MaelstromWeaponBuff].count >= 10) and (cooldown[classtable.DoomWinds].remains >3) and (buff[classtable.DoomWindsBuff].remains <= 3 or not buff[classtable.DoomWindsBuff].up and cooldown[classtable.DoomWinds].remains >15 or buff[classtable.EarthenWeaponBuff].count >= 4) or buff[classtable.PrimordialStormBuff].remains <3*gcd) and cooldown[classtable.PrimordialStorm].ready then
        if not setSpell then setSpell = classtable.PrimordialStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up and ((talents[classtable.AshenCatalyst] and true or false) or (talents[classtable.PrimordialWave] and true or false)) and not flame_shock_saturation) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds') and talents[classtable.DoomWinds]) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave') and talents[classtable.PrimordialWave]) and (debuff[classtable.FlameShockDeBuff].up and flame_shock_saturation) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (buff[classtable.HotHandBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (buff[classtable.ElectrostaticWagerBuff].count >8) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and (buff[classtable.DoomWindsBuff].up or (talents[classtable.Earthsurge] and true or false) and (buff[classtable.LegacyoftheFrostWitchBuff].up or not (talents[classtable.LegacyoftheFrostWitch] and true or false)) and ( UnitExists('pet') and UnitName('pet')  == 'SurgingTotem' )) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 10 and buff[classtable.ElectrostaticWagerBuff].count >4 and not buff[classtable.ClCrashLightningBuff].up and buff[classtable.DoomWindsBuff].up) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 10) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 10 and (not buff[classtable.PrimordialStormBuff].up or buff[classtable.PrimordialStormBuff].remains >gcd*4)) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (buff[classtable.DoomWindsBuff].up or not buff[classtable.CrashLightningBuff].up or ((talents[classtable.AlphaWolf] and true or false) and buff[classtable.FeralSpiritBuff].remains and buff[classtable.FeralSpiritBuff].remains == 0)) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoltaicBlaze, 'VoltaicBlaze') and talents[classtable.VoltaicBlaze]) and cooldown[classtable.VoltaicBlaze].ready then
        if not setSpell then setSpell = classtable.VoltaicBlaze end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova') and talents[classtable.FireNova]) and (debuff[classtable.FlameShockDeBuff].up and flame_shock_saturation and ( UnitExists('pet') and UnitName('pet')  == 'SearingTotem' )) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and ((talents[classtable.MoltenAssault] and true or false) and debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and ((talents[classtable.Hailstorm] and true or false) and buff[classtable.HailstormBuff].up and ( UnitExists('pet') and UnitName('pet')  == 'SearingTotem' )) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((talents[classtable.CrashingStorms] and true or false)) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova') and talents[classtable.FireNova]) and (debuff[classtable.FlameShockDeBuff].up and flame_shock_saturation) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and ((talents[classtable.Hailstorm] and true or false) and buff[classtable.HailstormBuff].up) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and ((talents[classtable.Hailstorm] and true or false) and not buff[classtable.IceStrikeBuff].up) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and (not buff[classtable.PrimordialStormBuff].up or buff[classtable.PrimordialStormBuff].remains >gcd*4)) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and (not buff[classtable.PrimordialStormBuff].up or buff[classtable.PrimordialStormBuff].remains >gcd*4)) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and (buff[classtable.DoomWindsBuff].up or (talents[classtable.Earthsurge] and true or false) and (buff[classtable.LegacyoftheFrostWitchBuff].up or not (talents[classtable.LegacyoftheFrostWitch] and true or false)) and ( UnitExists('pet') and UnitName('pet')  == 'SurgingTotem' )) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova') and talents[classtable.FireNova]) and (flame_shock_saturation and targets >= 4) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoltaicBlaze, 'VoltaicBlaze') and talents[classtable.VoltaicBlaze]) and cooldown[classtable.VoltaicBlaze].ready then
        if not setSpell then setSpell = classtable.VoltaicBlaze end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and ((talents[classtable.Hailstorm] and true or false) and not buff[classtable.IceStrikeBuff].up) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and ((talents[classtable.Hailstorm] and true or false) and buff[classtable.HailstormBuff].up) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and ((buff[classtable.LegacyoftheFrostWitchBuff].up or not (talents[classtable.LegacyoftheFrostWitch] and true or false)) and ( UnitExists('pet') and UnitName('pet')  == 'SurgingTotem' )) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and ((talents[classtable.MoltenAssault] and true or false) and not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova') and talents[classtable.FireNova]) and (MaxDps:DebuffCounter(classtable.FlameShockDeBuff) >= 3) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
end
function Enhancement:aoe_totemic_open()
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up and not flame_shock_saturation) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (not ( UnitExists('pet') and UnitName('pet')  == 'SurgingTotem' ) and not flame_shock_saturation) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.SurgingTotem, 'SurgingTotem') and talents[classtable.SurgingTotem]) and cooldown[classtable.SurgingTotem].ready then
        if not setSpell then setSpell = classtable.SurgingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova') and talents[classtable.FireNova]) and ((talents[classtable.SwirlingMaelstrom] and true or false) and debuff[classtable.FlameShockDeBuff].up and flame_shock_saturation) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit') and talents[classtable.FeralSpirit]) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave') and talents[classtable.PrimordialWave]) and (debuff[classtable.FlameShockDeBuff].up and flame_shock_saturation) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialStorm, 'PrimordialStorm') and talents[classtable.PrimordialStorm]) and ((buff[classtable.MaelstromWeaponBuff].count >= 10) and (cooldown[classtable.DoomWinds].remains >3) and (buff[classtable.DoomWindsBuff].remains <= gcd or not buff[classtable.DoomWindsBuff].up and cooldown[classtable.DoomWinds].remains >15) or buff[classtable.PrimordialStormBuff].remains <3*gcd) and cooldown[classtable.PrimordialStorm].ready then
        if not setSpell then setSpell = classtable.PrimordialStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 10 and not buff[classtable.LegacyoftheFrostWitchBuff].up and cooldown[classtable.DoomWinds].remains == 0) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds') and talents[classtable.DoomWinds]) and (not (talents[classtable.LegacyoftheFrostWitch] and true or false) or buff[classtable.LegacyoftheFrostWitchBuff].up) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((buff[classtable.ElectrostaticWagerBuff].count >9 and buff[classtable.DoomWindsBuff].up) or not buff[classtable.CrashLightningBuff].up) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialStorm, 'PrimordialStorm') and talents[classtable.PrimordialStorm]) and ((buff[classtable.MaelstromWeaponBuff].count >= 10) and (buff[classtable.DoomWindsBuff].remains <= gcd or not buff[classtable.DoomWindsBuff].up and cooldown[classtable.DoomWinds].remains >buff[classtable.PrimordialStormBuff].remains)) and cooldown[classtable.PrimordialStorm].ready then
        if not setSpell then setSpell = classtable.PrimordialStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (buff[classtable.HotHandBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and (buff[classtable.LegacyoftheFrostWitchBuff].up or (buff[classtable.EarthenWeaponBuff].count >= 2 and buff[classtable.PrimordialStormBuff].up)) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and ((buff[classtable.LegacyoftheFrostWitchBuff].up and buff[classtable.WhirlingFireBuff].up)) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((buff[classtable.EarthenWeaponBuff].count >= 2 and buff[classtable.PrimordialStormBuff].up and buff[classtable.DoomWindsBuff].up)) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 10) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 10) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and ((talents[classtable.Hailstorm] and true or false) and buff[classtable.HailstormBuff].up and ( UnitExists('pet') and UnitName('pet')  == 'SearingTotem' )) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova') and talents[classtable.FireNova]) and (( UnitExists('pet') and UnitName('pet')  == 'SearingTotem' ) and debuff[classtable.FlameShockDeBuff].up and flame_shock_saturation) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.MaelstromWeaponBuff].count <10 and not buff[classtable.LegacyoftheFrostWitchBuff].up) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and ((talents[classtable.Hailstorm] and true or false) and buff[classtable.HailstormBuff].up and ( UnitExists('pet') and UnitName('pet')  == 'SearingTotem' )) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((talents[classtable.CrashingStorms] and true or false)) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova') and talents[classtable.FireNova]) and (debuff[classtable.FlameShockDeBuff].up and flame_shock_saturation) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and ((talents[classtable.Hailstorm] and true or false) and buff[classtable.HailstormBuff].up) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and ((talents[classtable.Hailstorm] and true or false) and not buff[classtable.IceStrikeBuff].up) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and not buff[classtable.PrimordialStormBuff].up) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and not buff[classtable.PrimordialStormBuff].up) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
end
function Enhancement:funnel()
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit') and talents[classtable.FeralSpirit]) and ((talents[classtable.ElementalSpirits] and true or false)) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SurgingTotem, 'SurgingTotem') and talents[classtable.SurgingTotem]) and cooldown[classtable.SurgingTotem].ready then
        if not setSpell then setSpell = classtable.SurgingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance') and talents[classtable.Ascendance]) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and (((talents[classtable.ThorimsInvocation] and true or false) and buff[classtable.MaelstromWeaponBuff].count >0) or buff[classtable.ConvergingStormsBuff].count == 6) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (buff[classtable.MaelstromWeaponBuff].count == 10 or (buff[classtable.MaelstromWeaponBuff].count >= 5 and (C_Spell.GetSpellCastCount(classtable.Tempest) >30 or buff[classtable.AwakeningStormsBuff].count == 2))) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (flame_shock_saturation and buff[classtable.PrimordialWaveBuff].up and buff[classtable.MaelstromWeaponBuff].count == 10 and (not buff[classtable.SplinteredElementsBuff].up or MaxDps:boss() and ttd <= 12 or targets <= gcd)) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and (talents[classtable.ElementalSpirits] and true or false) and buff[classtable.FeralSpiritBuff].remains >= 4) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and ((talents[classtable.Supercharge] and true or false) and buff[classtable.MaelstromWeaponBuff].count == 10 and (expected_lb_funnel >expected_cl_funnel)) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (((talents[classtable.Supercharge] and true or false) and buff[classtable.MaelstromWeaponBuff].count == 10) or buff[classtable.ArcDischargeBuff].up and buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (((talents[classtable.MoltenAssault] and true or false) and debuff[classtable.FlameShockDeBuff].up and not flame_shock_saturation) or ((talents[classtable.AshenCatalyst] and true or false) and buff[classtable.AshenCatalystBuff].count == 8)) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave') and talents[classtable.PrimordialWave]) and (not buff[classtable.PrimordialWaveBuff].up) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and ((not (talents[classtable.ElementalSpirits] and true or false) or ((talents[classtable.ElementalSpirits] and true or false) and (cooldown[classtable.ElementalBlast].charges == cooldown[classtable.ElementalBlast].maxCharges or buff[classtable.FeralSpiritBuff].up))) and buff[classtable.MaelstromWeaponBuff].count == 10) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit') and talents[classtable.FeralSpirit]) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds') and talents[classtable.DoomWinds]) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.ConvergingStormsBuff].count == 6) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and ((buff[classtable.MoltenWeaponBuff].count >buff[classtable.CracklingSurgeBuff].count) and buff[classtable.MaelstromWeaponBuff].count == 10) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count == 10 and (expected_lb_funnel >expected_cl_funnel)) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count == 10) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (buff[classtable.DoomWindsBuff].up or not buff[classtable.CrashLightningBuff].up or ((talents[classtable.AlphaWolf] and true or false) and buff[classtable.FeralSpiritBuff].remains and buff[classtable.FeralSpiritBuff].remains == 0) or ((talents[classtable.ConvergingStorms] and true or false) and buff[classtable.ConvergingStormsBuff].count <6)) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and (buff[classtable.DoomWindsBuff].up or (talents[classtable.Earthsurge] and true or false)) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova') and talents[classtable.FireNova]) and (flame_shock_saturation and targets >= 4) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and ((talents[classtable.Hailstorm] and true or false) and not buff[classtable.IceStrikeBuff].up) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and ((talents[classtable.Hailstorm] and true or false) and buff[classtable.HailstormBuff].up) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and ((talents[classtable.MoltenAssault] and true or false) and not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and ((talents[classtable.FireNova] and true or false) or (talents[classtable.PrimordialWave] and true or false)) and not flame_shock_saturation) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova') and talents[classtable.FireNova]) and (MaxDps:DebuffCounter(classtable.FlameShockDeBuff) >= 3) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.CrashLightningBuff].up and (talents[classtable.DeeplyRootedElements] and true or false)) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((talents[classtable.CrashingStorms] and true or false) and buff[classtable.ClCrashLightningBuff].up and targets >= 4) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova') and talents[classtable.FireNova]) and (MaxDps:DebuffCounter(classtable.FlameShockDeBuff) >= 2) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and ((not (talents[classtable.ElementalSpirits] and true or false) or ((talents[classtable.ElementalSpirits] and true or false) and (cooldown[classtable.ElementalBlast].charges == cooldown[classtable.ElementalBlast].maxCharges or buff[classtable.FeralSpiritBuff].up))) and buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and ((buff[classtable.MoltenWeaponBuff].count >buff[classtable.CracklingSurgeBuff].count) and buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and (expected_lb_funnel >expected_cl_funnel)) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (not (talents[classtable.Hailstorm] and true or false)) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
end
function Enhancement:single()
    if (timeInCombat <= 18 and (cooldown[classtable.DoomWinds].remains == 0 or cooldown[classtable.Sundering].remains == 0 or not buff[classtable.HotHandBuff].up)) then
        Enhancement:single_open()
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialStorm, 'PrimordialStorm') and talents[classtable.PrimordialStorm]) and ((buff[classtable.MaelstromWeaponBuff].count >= 10 or buff[classtable.PrimordialStormBuff].remains <= 4 and buff[classtable.MaelstromWeaponBuff].count >= 5)) and cooldown[classtable.PrimordialStorm].ready then
        if not setSpell then setSpell = classtable.PrimordialStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up and ((talents[classtable.AshenCatalyst] and true or false) or (talents[classtable.PrimordialWave] and true or false) or (talents[classtable.LashingFlames] and true or false))) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit') and talents[classtable.FeralSpirit]) and (ttd <16 or cooldown[classtable.DoomWinds].remains >15 or cooldown[classtable.DoomWinds].remains <7 or buff[classtable.WinningStreakBuff].count == 1 and buff[classtable.MaelstromWeaponBuff].count >7) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and ((talents[classtable.ThorimsInvocation] and true or false) and buff[classtable.MaelstromWeaponBuff].count >0 and talents[classtable.ThorimsInvocation]) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds') and talents[classtable.DoomWinds]) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave') and talents[classtable.PrimordialWave]) and (debuff[classtable.FlameShockDeBuff].up and (math.huge >cooldown[classtable.PrimordialWave].remains or math.huge <6)) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance') and talents[classtable.Ascendance]) and ((debuff[classtable.FlameShockDeBuff].up or not (talents[classtable.PrimordialWave] and true or false) or not (talents[classtable.AshenCatalyst] and true or false))) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (buff[classtable.MaelstromWeaponBuff].count >= 9 and (buff[classtable.TempestBuff].count == buff[classtable.TempestBuff].maxStacks and (C_Spell.GetSpellCastCount(classtable.Tempest) >30 or buff[classtable.AwakeningStormsBuff].count == 3))) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (((not (talents[classtable.OverflowingMaelstrom] and true or false) and buff[classtable.MaelstromWeaponBuff].count >= 5) or (buff[classtable.MaelstromWeaponBuff].count >= 9))) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (buff[classtable.MaelstromWeaponBuff].count >= 9 and (cooldown[classtable.Ascendance].remains >= buff[classtable.TempestBuff].remains or cooldown[classtable.Ascendance].remains <= 3*gcd or not (talents[classtable.TempestStrikes] and true or false))) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >= 9) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 9 and not buff[classtable.PrimordialStormBuff].up and cooldown[classtable.Ascendance].remains <23 and buff[classtable.TempestBuff].up and (talents[classtable.TempestStrikes] and true or false)) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and ((buff[classtable.HotHandBuff].up and (buff[classtable.AshenCatalystBuff].count == 8)) or (debuff[classtable.FlameShockDeBuff].remains <= 2 and not (talents[classtable.VoltaicBlaze] and true or false) and (talents[classtable.MoltenAssault] and true or false)) or ((talents[classtable.LashingFlames] and true or false) and (not debuff[classtable.LashingFlamesDeBuff].up))) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((buff[classtable.DoomWindsBuff].up and buff[classtable.ElectrostaticWagerBuff].count >1) or buff[classtable.ElectrostaticWagerBuff].count >8) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.DoomWindsBuff].up or buff[classtable.StormblastBuff].count >0) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((talents[classtable.UnrelentingStorms] and true or false) and (talents[classtable.AlphaWolf] and true or false) and buff[classtable.FeralSpiritBuff].remains == 0) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (buff[classtable.HotHandBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((MaxDps.tier and MaxDps.tier[33].count >= 4)) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoltaicBlaze, 'VoltaicBlaze') and talents[classtable.VoltaicBlaze]) and cooldown[classtable.VoltaicBlaze].ready then
        if not setSpell then setSpell = classtable.VoltaicBlaze end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and ((talents[classtable.ElementalAssault] and true or false) and (talents[classtable.MoltenAssault] and true or false) and debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (buff[classtable.HailstormBuff].count == 10 and buff[classtable.IceStrikeBuff].up) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and not buff[classtable.PrimordialStormBuff].up) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and not buff[classtable.PrimordialStormBuff].up) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (buff[classtable.HailstormBuff].up) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and (math.huge >= cooldown[classtable.Sundering].remains) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova') and talents[classtable.FireNova]) and (MaxDps:DebuffCounter(classtable.FlameShockDeBuff)) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthElemental, 'EarthElemental')) and cooldown[classtable.EarthElemental].ready then
        MaxDps:GlowCooldown(classtable.EarthElemental, cooldown[classtable.EarthElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (false) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
end
function Enhancement:single_open()
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoltaicBlaze, 'VoltaicBlaze') and talents[classtable.VoltaicBlaze]) and (MaxDps:DebuffCounter(classtable.FlameShockDeBuff) <3 and not buff[classtable.AscendanceBuff].up) and cooldown[classtable.VoltaicBlaze].ready then
        if not setSpell then setSpell = classtable.VoltaicBlaze end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave') and talents[classtable.PrimordialWave]) and ((buff[classtable.MaelstromWeaponBuff].count >= 4) and debuff[classtable.FlameShockDeBuff].up and flame_shock_saturation) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit') and talents[classtable.FeralSpirit]) and (not (talents[classtable.LegacyoftheFrostWitch] and true or false) or buff[classtable.LegacyoftheFrostWitchBuff].up or ttd <16) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds') and talents[classtable.DoomWinds]) and (not (talents[classtable.LegacyoftheFrostWitch] and true or false) or buff[classtable.LegacyoftheFrostWitchBuff].up or MaxDps:boss() and ttd <9) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance') and talents[classtable.Ascendance]) and (not (talents[classtable.LegacyoftheFrostWitch] and true or false) or buff[classtable.LegacyoftheFrostWitchBuff].up or MaxDps:boss() and ttd <16) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialStorm, 'PrimordialStorm') and talents[classtable.PrimordialStorm]) and ((buff[classtable.MaelstromWeaponBuff].count >= 10) and (buff[classtable.LegacyoftheFrostWitchBuff].up or not (talents[classtable.LegacyoftheFrostWitch] and true or false))) and cooldown[classtable.PrimordialStorm].ready then
        if not setSpell then setSpell = classtable.PrimordialStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((MaxDps.tier and MaxDps.tier[33].count >= 4)) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoltaicBlaze, 'VoltaicBlaze') and talents[classtable.VoltaicBlaze]) and cooldown[classtable.VoltaicBlaze].ready then
        if not setSpell then setSpell = classtable.VoltaicBlaze end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and ((talents[classtable.ElementalAssault] and true or false) and (talents[classtable.MoltenAssault] and true or false) and debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
end
function Enhancement:single_totemic()
    if (timeInCombat <20 and (cooldown[classtable.DoomWinds].remains == 0 or cooldown[classtable.Sundering].remains == 0 or not buff[classtable.HotHandBuff].up)) then
        Enhancement:single_totemic_open()
    end
    if (MaxDps:CheckSpellUsable(classtable.SurgingTotem, 'SurgingTotem') and talents[classtable.SurgingTotem]) and cooldown[classtable.SurgingTotem].ready then
        if not setSpell then setSpell = classtable.SurgingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance') and talents[classtable.Ascendance]) and (talents[classtable.ThorimsInvocation] and GetTotemInfoById(classtable.SurgingTotem).remains >4 and (buff[classtable.TotemicReboundBuff].count >= 3 or buff[classtable.MaelstromWeaponBuff].count >0)) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up and ((talents[classtable.AshenCatalyst] and true or false) or (talents[classtable.PrimordialWave] and true or false))) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (buff[classtable.HotHandBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit') and talents[classtable.FeralSpirit]) and (ttd <16 or ((cooldown[classtable.DoomWinds].remains >23 or cooldown[classtable.DoomWinds].remains <7 or buff[classtable.WinningStreakBuff].count == 1 and buff[classtable.MaelstromWeaponBuff].count >7) and (cooldown[classtable.PrimordialWave].remains <20 or buff[classtable.PrimordialStormBuff].up or not (talents[classtable.PrimordialStorm] and true or false)))) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave') and talents[classtable.PrimordialWave]) and (debuff[classtable.FlameShockDeBuff].up and (math.huge >cooldown[classtable.PrimordialWave].remains) or math.huge <6) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds') and talents[classtable.DoomWinds]) and (not (talents[classtable.LegacyoftheFrostWitch] and true or false) or buff[classtable.LegacyoftheFrostWitchBuff].up) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialStorm, 'PrimordialStorm') and talents[classtable.PrimordialStorm]) and ((buff[classtable.MaelstromWeaponBuff].count >= 10) and ((cooldown[classtable.DoomWinds].remains >= buff[classtable.PrimordialStormBuff].remains) or buff[classtable.DoomWindsBuff].up or not (talents[classtable.DoomWinds] and true or false) or (buff[classtable.PrimordialStormBuff].remains <2*gcd))) and cooldown[classtable.PrimordialStorm].ready then
        if not setSpell then setSpell = classtable.PrimordialStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and (buff[classtable.AscendanceBuff].up and ( UnitExists('pet') and UnitName('pet')  == 'SurgingTotem' ) and (talents[classtable.Earthsurge] and true or false) and buff[classtable.LegacyoftheFrostWitchBuff].up and buff[classtable.TotemicReboundBuff].count >= 5 and buff[classtable.EarthenWeaponBuff].count >= 2) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and ((talents[classtable.ThorimsInvocation] and true or false) and buff[classtable.MaelstromWeaponBuff].count >0 and talents[classtable.ThorimsInvocation]) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and (buff[classtable.LegacyoftheFrostWitchBuff].up and ((cooldown[classtable.Ascendance].remains >= 10 and (talents[classtable.Ascendance] and true or false)) or not (talents[classtable.Ascendance] and true or false)) and ( UnitExists('pet') and UnitName('pet')  == 'SurgingTotem' ) and buff[classtable.TotemicReboundBuff].count >= 3 and not buff[classtable.AscendanceBuff].up) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((talents[classtable.UnrelentingStorms] and true or false) and (talents[classtable.AlphaWolf] and true or false) and buff[classtable.FeralSpiritBuff].remains == 0) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (not (talents[classtable.ThorimsInvocation] and true or false) and buff[classtable.MaelstromWeaponBuff].count >= 10 and not buff[classtable.WhirlingAirBuff].up) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and ((buff[classtable.MaelstromWeaponBuff].count >= 10) and (not buff[classtable.PrimordialStormBuff].up or buff[classtable.PrimordialStormBuff].remains >4)) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.DoomWindsBuff].up and buff[classtable.LegacyoftheFrostWitchBuff].up) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and ((buff[classtable.MaelstromWeaponBuff].count >= 10) and (not buff[classtable.PrimordialStormBuff].up or buff[classtable.PrimordialStormBuff].remains >4)) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (buff[classtable.ElectrostaticWagerBuff].count >4) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.DoomWindsBuff].up or buff[classtable.StormblastBuff].count >1) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (buff[classtable.WhirlingFireBuff].up or buff[classtable.AshenCatalystBuff].count >= 8) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((MaxDps.tier and MaxDps.tier[33].count >= 4)) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoltaicBlaze, 'VoltaicBlaze') and talents[classtable.VoltaicBlaze]) and cooldown[classtable.VoltaicBlaze].ready then
        if not setSpell then setSpell = classtable.VoltaicBlaze end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and ((talents[classtable.UnrelentingStorms] and true or false)) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and (not buff[classtable.IceStrikeBuff].up) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova') and talents[classtable.FireNova]) and (MaxDps:DebuffCounter(classtable.FlameShockDeBuff)) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthElemental, 'EarthElemental')) and cooldown[classtable.EarthElemental].ready then
        MaxDps:GlowCooldown(classtable.EarthElemental, cooldown[classtable.EarthElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not (talents[classtable.VoltaicBlaze] and true or false)) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
end
function Enhancement:single_totemic_open()
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (not ( UnitExists('pet') and UnitName('pet')  == 'SurgingTotem' ) and (talents[classtable.LashingFlames] and true or false) and not debuff[classtable.LashingFlamesDeBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.SurgingTotem, 'SurgingTotem') and talents[classtable.SurgingTotem]) and cooldown[classtable.SurgingTotem].ready then
        if not setSpell then setSpell = classtable.SurgingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave') and talents[classtable.PrimordialWave]) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit') and talents[classtable.FeralSpirit]) and (not (talents[classtable.LegacyoftheFrostWitch] and true or false) or buff[classtable.LegacyoftheFrostWitchBuff].up or ttd <16) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds') and talents[classtable.DoomWinds]) and (not (talents[classtable.LegacyoftheFrostWitch] and true or false) or buff[classtable.LegacyoftheFrostWitchBuff].up or MaxDps:boss() and ttd <9) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialStorm, 'PrimordialStorm') and talents[classtable.PrimordialStorm]) and ((buff[classtable.MaelstromWeaponBuff].count >= 10) and (buff[classtable.LegacyoftheFrostWitchBuff].up or not (talents[classtable.LegacyoftheFrostWitch] and true or false))) and cooldown[classtable.PrimordialStorm].ready then
        if not setSpell then setSpell = classtable.PrimordialStorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (buff[classtable.HotHandBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.DoomWindsBuff].up and buff[classtable.LegacyoftheFrostWitchBuff].up) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and (buff[classtable.LegacyoftheFrostWitchBuff].up) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count == 10) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count == 10) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.WindShear, false)
    MaxDps:GlowCooldown(classtable.elementium_pocket_anvil, false)
    MaxDps:GlowCooldown(classtable.algethar_puzzle_box, false)
    MaxDps:GlowCooldown(classtable.trinket1, false)
    MaxDps:GlowCooldown(classtable.trinket2, false)
    MaxDps:GlowCooldown(classtable.beacon_to_the_beyond, false)
    MaxDps:GlowCooldown(classtable.manic_grieftorch, false)
    MaxDps:GlowCooldown(classtable.FeralSpirit, false)
    MaxDps:GlowCooldown(classtable.Ascendance, false)
    MaxDps:GlowCooldown(classtable.PrimordialWave, false)
    MaxDps:GlowCooldown(classtable.EarthElemental, false)
end

function Enhancement:callaction()
    if (MaxDps:CheckSpellUsable(classtable.WindShear, 'WindShear')) and cooldown[classtable.WindShear].ready then
        MaxDps:GlowCooldown(classtable.WindShear, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningLasso, 'LightningLasso')) and (not MaxDps:boss() and debuff[classtable.CastingDeBuff].up and (not select(8,UnitCastingInfo('target')) and 1 or 0) == 0 and debuff[classtable.CastingDeBuff].remains >gcd and debuff[classtable.CastingDeBuff].remains <gcd+gcd) and cooldown[classtable.LightningLasso].ready then
        if not setSpell then setSpell = classtable.LightningLasso end
    end
    if (MaxDps:CheckSpellUsable(classtable.Thunderstorm, 'Thunderstorm')) and ((talents[classtable.Thundershock] and true or false) and not MaxDps:boss() and debuff[classtable.CastingDeBuff].up and (not select(8,UnitCastingInfo('target')) and 1 or 0) == 0 and debuff[classtable.CastingDeBuff].remains >gcd and debuff[classtable.CastingDeBuff].remains <gcd+gcd) and cooldown[classtable.Thunderstorm].ready then
        if not setSpell then setSpell = classtable.Thunderstorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.CapacitorTotem, 'CapacitorTotem')) and (not MaxDps:boss() and debuff[classtable.CastingDeBuff].up and (not select(8,UnitCastingInfo('target')) and 1 or 0) == 0 and debuff[classtable.CastingDeBuff].remains >gcd and debuff[classtable.CastingDeBuff].remains <gcd+gcd) and cooldown[classtable.CapacitorTotem].ready then
        if not setSpell then setSpell = classtable.CapacitorTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.Purge, 'Purge')) and (buff[classtable.DispellableMagicBuff].up) and cooldown[classtable.Purge].ready then
        if not setSpell then setSpell = classtable.Purge end
    end
    if (MaxDps:CheckSpellUsable(classtable.GreaterPurge, 'GreaterPurge')) and (buff[classtable.DispellableMagicBuff].up) and cooldown[classtable.GreaterPurge].ready then
        if not setSpell then setSpell = classtable.GreaterPurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.PoisonCleansingTotem, 'PoisonCleansingTotem')) and (buff[classtable.DispellablePoisonBuff].up) and cooldown[classtable.PoisonCleansingTotem].ready then
        if not setSpell then setSpell = classtable.PoisonCleansingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.elementium_pocket_anvil, 'elementium_pocket_anvil')) and cooldown[classtable.elementium_pocket_anvil].ready then
        MaxDps:GlowCooldown(classtable.elementium_pocket_anvil, cooldown[classtable.elementium_pocket_anvil].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.algethar_puzzle_box, 'algethar_puzzle_box')) and ((not buff[classtable.AscendanceBuff].up and not buff[classtable.FeralSpiritBuff].up and not buff[classtable.DoomWindsBuff].up) or ((talents[classtable.Ascendance] and true or false) and (cooldown[classtable.Ascendance].remains <2*action.stormstrike.gcd)) or (math.fmod(ttd , 180)<=30)) and cooldown[classtable.algethar_puzzle_box].ready then
        MaxDps:GlowCooldown(classtable.algethar_puzzle_box, cooldown[classtable.algethar_puzzle_box].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (not trinket1_is_weird and MaxDps:HasOnUseEffect('13') and ttd <= 20 or (buff[classtable.AscendanceBuff].up or (not (talents[classtable.Ascendance] and true or false) and (buff[classtable.SplinteredElementsBuff].up or buff[classtable.DoomWindsBuff].up or buff[classtable.FeralSpiritBuff].up or (not (talents[classtable.SplinteredElements] and true or false) and not (talents[classtable.DoomWinds] and true or false) and not (talents[classtable.FeralSpirit] and true or false))) or (math.fmod(ttd , MaxDps:CheckTrinketCooldownDuration('13'))<=MaxDps:CheckTrinketBuffDuration('13', 'any')) or (min_talented_cd_remains >= MaxDps:CheckTrinketCooldownDuration('13'))))) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (not trinket2_is_weird and MaxDps:HasOnUseEffect('14') and ttd <= 20 or (buff[classtable.AscendanceBuff].up or (not (talents[classtable.Ascendance] and true or false) and (buff[classtable.SplinteredElementsBuff].up or buff[classtable.DoomWindsBuff].up or buff[classtable.FeralSpiritBuff].up or (not (talents[classtable.SplinteredElements] and true or false) and not (talents[classtable.DoomWinds] and true or false) and not (talents[classtable.FeralSpirit] and true or false))) or (math.fmod(ttd , MaxDps:CheckTrinketCooldownDuration('14'))<=MaxDps:CheckTrinketBuffDuration('14', 'any')) or (min_talented_cd_remains >= MaxDps:CheckTrinketCooldownDuration('14'))))) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.beacon_to_the_beyond, 'beacon_to_the_beyond')) and ((not buff[classtable.AscendanceBuff].up and not buff[classtable.FeralSpiritBuff].up and not buff[classtable.DoomWindsBuff].up) or (math.fmod(ttd , 150)<=5)) and cooldown[classtable.beacon_to_the_beyond].ready then
        MaxDps:GlowCooldown(classtable.beacon_to_the_beyond, cooldown[classtable.beacon_to_the_beyond].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.manic_grieftorch, 'manic_grieftorch')) and ((not buff[classtable.AscendanceBuff].up and not buff[classtable.FeralSpiritBuff].up and not buff[classtable.DoomWindsBuff].up) or (math.fmod(ttd , 120)<=5)) and cooldown[classtable.manic_grieftorch].ready then
        MaxDps:GlowCooldown(classtable.manic_grieftorch, cooldown[classtable.manic_grieftorch].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (not trinket1_is_weird and not MaxDps:HasOnUseEffect('13')) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (not trinket2_is_weird and not MaxDps:HasOnUseEffect('14')) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (targets == 1 and not (talents[classtable.SurgingTotem] and true or false)) then
        Enhancement:single()
    end
    if (targets == 1 and (talents[classtable.SurgingTotem] and true or false)) then
        Enhancement:single_totemic()
    end
    if (targets >1 and not false and not (talents[classtable.SurgingTotem] and true or false)) then
        Enhancement:aoe()
    end
    if (targets >1 and not false and (talents[classtable.SurgingTotem] and true or false)) then
        Enhancement:aoe_totemic()
    end
    if (targets >1 and false) then
        Enhancement:funnel()
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
    classtable.Windstrike = 115356
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.SkyfuryBuff = 462854
    classtable.EarthShieldBuff = talents[classtable.ElementalOrbit] and 383648 or 974
    classtable.PrimordialWaveBuff = 375986
    classtable.AscendanceBuff = 1219480
    classtable.FeralSpiritBuff = 333957
    classtable.DoomWindsBuff = 384352
    classtable.DispellableMagicBuff = 0
    classtable.DispellablePoisonBuff = 0
    classtable.SplinteredElementsBuff = 382043
    classtable.AnyBuff = 0
    classtable.ArcDischargeBuff = 455097
    classtable.MaelstromWeaponBuff = 344179
    classtable.PrimordialStormBuff = 1218125
    classtable.ElectrostaticWagerBuff = 0
    classtable.CrashLightningBuff = 187878
    classtable.ConvergingStormsBuff = 333964
    classtable.StormblastBuff = 470466
    classtable.LegacyoftheFrostWitchBuff = 384451
    classtable.IceStrikeBuff = 384357
    classtable.HailstormBuff = 334196
    classtable.ClCrashLightningBuff = 333964
    classtable.HotHandBuff = 215785
    classtable.WinningStreakBuff = 1216813
    classtable.EarthenWeaponBuff = 392375
    classtable.WhirlingFireBuff = 453405
    classtable.AwakeningStormsBuff = 462131
    classtable.AshenCatalystBuff = 390371
    classtable.MoltenWeaponBuff = 224125
    classtable.CracklingSurgeBuff = 224127
    classtable.TempestBuff = 454015
    classtable.TotemicReboundBuff = 458269
    classtable.WhirlingAirBuff = 453409
    classtable.ChaosBrandDeBuff = 0
    classtable.HuntersMarkDeBuff = 0
    classtable.LightningRodDeBuff = 197209
    classtable.CastingDeBuff = 0
    classtable.FlameShockDeBuff = 188389
    classtable.LashingFlamesDeBuff = 334168
    classtable.Windstrike = 115356

    local function debugg()
        talents[classtable.ElementalOrbit] = 1
        talents[classtable.Ascendance] = 1
        talents[classtable.FeralSpirit] = 1
        talents[classtable.DoomWinds] = 1
        talents[classtable.Thundershock] = 1
        talents[classtable.SplinteredElements] = 1
        talents[classtable.SurgingTotem] = 1
        talents[classtable.ElementalSpirits] = 1
        talents[classtable.AlphaWolf] = 1
        talents[classtable.MoltenAssault] = 1
        talents[classtable.RagingMaelstrom] = 1
        talents[classtable.ConvergingStorms] = 1
        talents[classtable.ThorimsInvocation] = 1
        talents[classtable.Stormblast] = 1
        talents[classtable.Stormflurry] = 1
        talents[classtable.LashingFlames] = 1
        talents[classtable.Hailstorm] = 1
        talents[classtable.FireNova] = 1
        talents[classtable.PrimordialWave] = 1
        talents[classtable.DeeplyRootedElements] = 1
        talents[classtable.CrashingStorms] = 1
        talents[classtable.LegacyoftheFrostWitch] = 1
        talents[classtable.PrimordialStorm] = 1
        talents[classtable.AshenCatalyst] = 1
        talents[classtable.Earthsurge] = 1
        talents[classtable.SwirlingMaelstrom] = 1
        talents[classtable.Supercharge] = 1
        talents[classtable.OverflowingMaelstrom] = 1
        talents[classtable.TempestStrikes] = 1
        talents[classtable.VoltaicBlaze] = 1
        talents[classtable.UnrelentingStorms] = 1
        talents[classtable.ElementalAssault] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Enhancement:precombat()

    Enhancement:callaction()
    if setSpell then return setSpell end
end
