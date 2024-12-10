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

local Enhancement = {}

local trinketone_is_weird
local trinkettwo_is_weird
local min_talented_cd_remains
local target_nature_mod
local expected_lb_funnel
local expected_cl_funnel


local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end


function Enhancement:precombat()
    --if (MaxDps:CheckSpellUsable(classtable.WindfuryWeapon, 'WindfuryWeapon')) and cooldown[classtable.WindfuryWeapon].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.WindfuryWeapon end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.FlametongueWeapon, 'FlametongueWeapon')) and cooldown[classtable.FlametongueWeapon].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.FlametongueWeapon end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.LightningShield, 'LightningShield')) and cooldown[classtable.LightningShield].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.LightningShield end
    --end
    --min_talented_cd_remains = ( ( cooldown[classtable.FeralSpirit].remains % ( 4 * (talents[classtable.WitchDoctorsAncestry] and talents[classtable.WitchDoctorsAncestry] or 0) ) ) + 1000 * (talents[classtable.FeralSpirit] and 1 or 0) ) >( cooldown[classtable.DoomWinds].remains + 1000 * (talents[classtable.DoomWinds] and 1 or 0) ) >( cooldown[classtable.Ascendance].remains + 1000 * (talents[classtable.Ascendance] and 1 or 0) )
    target_nature_mod = ( 1 + debuff[classtable.ChaosBrandDeBuff].remains * 3 ) * ( 1 + ( debuff[classtable.HuntersMarkDeBuff].remains * (targetHP >= 80 and 1 or 0) ) * 5 )
    --action.lightning_bolt.damage
    --action.chain_lightning.damage
    expected_lb_funnel = 450000 * ( 1 + debuff[classtable.LightningRodDeBuff].remains * target_nature_mod * ( 1 + buff[classtable.PrimordialWaveBuff].duration * debuff[classtable.FlameShockDeBuff].count  * 175 ) * 10 )
    expected_cl_funnel = 250000 * ( 1 + debuff[classtable.LightningRodDeBuff].remains * target_nature_mod * ( targets >( 3 + 2 * (talents[classtable.CrashingStorms] and talents[classtable.CrashingStorms] or 0) ) and 1 or 0) * 10 )
end
function Enhancement:single()
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit')) and (talents[classtable.ElementalSpirits]) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and (talents[classtable.ThorimsInvocation] and buff[classtable.MaelstromWeaponBuff].count >0 and talents[classtable.ThorimsInvocation] and not talents[classtable.ElementalSpirits]) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave')) and (not debuff[classtable.FlameShockDeBuff].up and talents[classtable.MoltenAssault]) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (talents[classtable.LashingFlames] and not debuff[classtable.LashingFlamesDeBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.MaelstromWeaponBuff].count <2 and cooldown[classtable.Ascendance].remains == 0) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit')) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (( classtable and classtable.Tempest and GetSpellInfo(classtable.Tempest).castTime /1000 ) == 0 and talents[classtable.Ascendance] and cooldown[classtable.Ascendance].remains <2 * gcd and talents[classtable.ThorimsInvocation] and not talents[classtable.ThorimsInvocation]) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (( classtable and classtable.LightningBolt and GetSpellInfo(classtable.LightningBolt).castTime /1000 ) == 0 and talents[classtable.Ascendance] and cooldown[classtable.Ascendance].remains <2 * gcd and talents[classtable.ThorimsInvocation] and not talents[classtable.ThorimsInvocation]) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance')) and (debuff[classtable.FlameShockDeBuff].up and talents[classtable.ThorimsInvocation] and targets == 1 and buff[classtable.MaelstromWeaponBuff].count >= 2) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (buff[classtable.MaelstromWeaponBuff].count == 10 or ( buff[classtable.TempestBuff].count == buff[classtable.TempestBuff].maxStacks and ( C_Spell.GetSpellCastCount(classtable.Tempest) >30 or buff[classtable.AwakeningStormsBuff].count == 2 ) and buff[classtable.MaelstromWeaponBuff].count >= 5 )) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count == 10 and talents[classtable.ElementalSpirits] and buff[classtable.FeralSpiritBuff].remains >= 6 and ( cooldown[classtable.ElementalBlast].charges >= 1.8 or buff[classtable.AscendanceBuff].up )) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and (talents[classtable.ThorimsInvocation] and buff[classtable.MaelstromWeaponBuff].count >0 and talents[classtable.ThorimsInvocation] and cooldown[classtable.Windstrike].charges == cooldown[classtable.Windstrike].maxCharges) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds')) and (talents[classtable.ElementalSpirits] and talents[classtable.Ascendance] and buff[classtable.MaelstromWeaponBuff].count >= 2) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and (talents[classtable.ThorimsInvocation] and buff[classtable.MaelstromWeaponBuff].up and talents[classtable.ThorimsInvocation]) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up and talents[classtable.AshenCatalyst]) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count == 10 and buff[classtable.PrimordialWaveBuff].up) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (( not talents[classtable.OverflowingMaelstrom] and buff[classtable.MaelstromWeaponBuff].count >= 5 ) or ( buff[classtable.MaelstromWeaponBuff].count >= 10 - 2 * (talents[classtable.ElementalSpirits] and talents[classtable.ElementalSpirits] or 0) )) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave')) and (not talents[classtable.DeeplyRootedElements]) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 8 and buff[classtable.FeralSpiritBuff].remains >= 4 and ( not buff[classtable.AscendanceBuff].up or cooldown[classtable.ElementalBlast].charges >= 1.8 )) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >= 8 + 2 * (talents[classtable.LegacyoftheFrostWitch] and talents[classtable.LegacyoftheFrostWitch] or 0 )) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and not talents[classtable.LegacyoftheFrostWitch] and ( talents[classtable.DeeplyRootedElements] or not talents[classtable.OverflowingMaelstrom] or not talents[classtable.WitchDoctorsAncestry] )) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (buff[classtable.VoltaicBlazeBuff].up and talents[classtable.ElementalSpirits] and not talents[classtable.WitchDoctorsAncestry]) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.ArcDischargeBuff].up and talents[classtable.DeeplyRootedElements]) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (buff[classtable.HotHandBuff].up or ( buff[classtable.AshenCatalystBuff].count == 8 )) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.DoomWindsBuff].up or ( talents[classtable.Stormblast] and buff[classtable.StormsurgeBuff].up and cooldown[classtable.Stormstrike].charges == cooldown[classtable.Stormstrike].maxCharges )) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (talents[classtable.LashingFlames] and not buff[classtable.DoomWindsBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (buff[classtable.VoltaicBlazeBuff].up and talents[classtable.ElementalSpirits] and not buff[classtable.DoomWindsBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.UnrelentingStorms] and talents[classtable.ElementalSpirits] and not talents[classtable.DeeplyRootedElements]) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and (talents[classtable.ElementalAssault] and talents[classtable.SwirlingMaelstrom] and talents[classtable.WitchDoctorsAncestry]) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and talents[classtable.Ascendance] and not talents[classtable.LegacyoftheFrostWitch]) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.UnrelentingStorms]) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (buff[classtable.VoltaicBlazeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and (not talents[classtable.ElementalSpirits]) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (buff[classtable.HailstormBuff].up and buff[classtable.IceStrikeBuff].up and talents[classtable.SwirlingMaelstrom] and talents[classtable.Ascendance]) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and buff[classtable.FeralSpiritBuff].remains >= 4 and talents[classtable.DeeplyRootedElements] and ( cooldown[classtable.ElementalBlast].charges >= 1.8 or ( buff[classtable.MoltenWeaponBuff].count + buff[classtable.IcyEdgeBuff].count >= 4 ) ) and not talents[classtable.FlowingSpirits]) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.AlphaWolf] and buff[classtable.FeralSpiritBuff].remains and buff[classtable.FeralSpiritBuff].remains == 0) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up and not talents[classtable.Tempest]) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds')) and (talents[classtable.ElementalSpirits]) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (talents[classtable.ElementalAssault] and talents[classtable.Tempest] and talents[classtable.MoltenAssault] and talents[classtable.DeeplyRootedElements] and debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and (talents[classtable.ElementalAssault] and talents[classtable.SwirlingMaelstrom]) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.ArcDischargeBuff].up) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.UnrelentingStorms]) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (talents[classtable.ElementalAssault] and talents[classtable.Tempest] and talents[classtable.MoltenAssault] and debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (buff[classtable.HailstormBuff].up and buff[classtable.IceStrikeBuff].up and talents[classtable.SwirlingMaelstrom] and talents[classtable.Tempest]) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (talents[classtable.LashingFlames]) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and (not buff[classtable.IceStrikeBuff].up) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (buff[classtable.HailstormBuff].up) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.ConvergingStorms]) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count ) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthElemental, 'EarthElemental')) and cooldown[classtable.EarthElemental].ready then
        MaxDps:GlowCooldown(classtable.EarthElemental, cooldown[classtable.EarthElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (true) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
end
function Enhancement:single_totemic()
    if (MaxDps:CheckSpellUsable(classtable.SurgingTotem, 'SurgingTotem')) and cooldown[classtable.SurgingTotem].ready then
        if not setSpell then setSpell = classtable.SurgingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (( classtable and classtable.Tempest and GetSpellInfo(classtable.Tempest).castTime /1000 ) == 0 and talents[classtable.Ascendance] and cooldown[classtable.Ascendance].remains <2 * gcd and talents[classtable.ThorimsInvocation] and not talents[classtable.ThorimsInvocation]) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (( classtable and classtable.LightningBolt and GetSpellInfo(classtable.LightningBolt).castTime /1000 ) == 0 and talents[classtable.Ascendance] and cooldown[classtable.Ascendance].remains <2 * gcd and talents[classtable.ThorimsInvocation] and not talents[classtable.ThorimsInvocation]) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance')) and (talents[classtable.ThorimsInvocation] and GetTotemDuration('surging_totem') >4 and ( buff[classtable.TotemicReboundBuff].count >= 3 or buff[classtable.MaelstromWeaponBuff].up )) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds')) and (not talents[classtable.ElementalSpirits] and buff[classtable.LegacyoftheFrostWitchBuff].up) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and (buff[classtable.AscendanceBuff].up and ( UnitExists('pet') and UnitName('pet')  == 'surging_totem' ) and talents[classtable.Earthsurge] and buff[classtable.LegacyoftheFrostWitchBuff].up and buff[classtable.TotemicReboundBuff].count >= 5 and buff[classtable.EarthenWeaponBuff].count >= 2) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.UnrelentingStorms] and talents[classtable.AlphaWolf] and buff[classtable.FeralSpiritBuff].remains == 0 and buff[classtable.EarthenWeaponBuff].count >= 8) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and (talents[classtable.ThorimsInvocation] and buff[classtable.MaelstromWeaponBuff].count >0 and talents[classtable.ThorimsInvocation] and not talents[classtable.ElementalSpirits]) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and (buff[classtable.LegacyoftheFrostWitchBuff].up and cooldown[classtable.Ascendance].remains >= 10 and ( UnitExists('pet') and UnitName('pet')  == 'surging_totem' ) and buff[classtable.TotemicReboundBuff].count >= 3 and not buff[classtable.AscendanceBuff].up) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave')) and (not debuff[classtable.FlameShockDeBuff].up and talents[classtable.MoltenAssault]) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit')) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count == 10 and talents[classtable.ElementalSpirits] and buff[classtable.FeralSpiritBuff].remains >= 6 and ( cooldown[classtable.ElementalBlast].charges >= 1.8 or buff[classtable.AscendanceBuff].up )) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (buff[classtable.VoltaicBlazeBuff].up and buff[classtable.WhirlingEarthBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.UnrelentingStorms] and talents[classtable.AlphaWolf] and buff[classtable.FeralSpiritBuff].remains == 0) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up and talents[classtable.LashingFlames]) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (buff[classtable.HotHandBuff].up and not talents[classtable.LegacyoftheFrostWitch]) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and cooldown[classtable.ElementalBlast].charges == cooldown[classtable.ElementalBlast].maxCharges) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >= 8 and buff[classtable.PrimordialWaveBuff].up and ( not buff[classtable.SplinteredElementsBuff].up or ttd <= 12 )) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 8 and ( buff[classtable.FeralSpiritBuff].remains >= 2 or not talents[classtable.ElementalSpirits] )) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (not talents[classtable.ThorimsInvocation] and buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave')) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and ( cooldown[classtable.ElementalBlast].charges >= 1.8 or ( buff[classtable.MoltenWeaponBuff].count + buff[classtable.IcyEdgeBuff].count >= 4 ) ) and talents[classtable.Ascendance] and ( buff[classtable.FeralSpiritBuff].remains >= 4 or not talents[classtable.ElementalSpirits] )) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (talents[classtable.Ascendance] and ( buff[classtable.MaelstromWeaponBuff].count >= 10 or ( buff[classtable.MaelstromWeaponBuff].count >= 5 and buff[classtable.WhirlingAirBuff].up and not buff[classtable.LegacyoftheFrostWitchBuff].up ) )) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (talents[classtable.Ascendance] and ( buff[classtable.MaelstromWeaponBuff].count >= 10 or ( buff[classtable.MaelstromWeaponBuff].count >= 5 and buff[classtable.WhirlingAirBuff].up and not buff[classtable.LegacyoftheFrostWitchBuff].up ) )) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (buff[classtable.HotHandBuff].up and talents[classtable.MoltenAssault] and ( UnitExists('pet') and UnitName('pet')  == 'searing_totem' )) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (talents[classtable.MoltenAssault]) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.UnrelentingStorms]) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and talents[classtable.Ascendance]) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and (not buff[classtable.IceStrikeBuff].up) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (buff[classtable.HailstormBuff].up and ( UnitExists('pet') and UnitName('pet')  == 'searing_totem' )) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and buff[classtable.FeralSpiritBuff].remains >= 4 and talents[classtable.DeeplyRootedElements] and ( cooldown[classtable.ElementalBlast].charges >= 1.8 or ( buff[classtable.IcyEdgeBuff].count + buff[classtable.MoltenWeaponBuff].count >= 4 ) )) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds')) and (talents[classtable.ElementalSpirits]) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up and not talents[classtable.VoltaicBlaze]) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (buff[classtable.HailstormBuff].up) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.ConvergingStorms]) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count ) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthElemental, 'EarthElemental')) and cooldown[classtable.EarthElemental].ready then
        MaxDps:GlowCooldown(classtable.EarthElemental, cooldown[classtable.EarthElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not talents[classtable.VoltaicBlaze]) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
end
function Enhancement:aoe()
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit')) and (talents[classtable.ElementalSpirits] or talents[classtable.AlphaWolf]) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (( classtable and classtable.Tempest and GetSpellInfo(classtable.Tempest).castTime /1000 ) == 0 and talents[classtable.Ascendance] and cooldown[classtable.Ascendance].remains <2 * gcd and talents[classtable.ThorimsInvocation] and not talents[classtable.ThorimsInvocation]) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (( classtable and classtable.ChainLightning and GetSpellInfo(classtable.ChainLightning).castTime /1000 ) == 0 and talents[classtable.Ascendance] and cooldown[classtable.Ascendance].remains <2 * gcd and talents[classtable.ThorimsInvocation] and not talents[classtable.ThorimsInvocation]) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance')) and (debuff[classtable.FlameShockDeBuff].up and ( cooldown[classtable.LavaLash].ready==false or debuff[classtable.FlameShockDeBuff].count  >= targets or debuff[classtable.FlameShockDeBuff].count  == 6 ) and talents[classtable.ThorimsInvocation]) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (not buff[classtable.ArcDischargeBuff].up and ( ( buff[classtable.MaelstromWeaponBuff].count == 10 and not talents[classtable.RagingMaelstrom] ) or ( buff[classtable.MaelstromWeaponBuff].count >= 8 ) ) or ( buff[classtable.MaelstromWeaponBuff].count >= 5 and ( C_Spell.GetSpellCastCount(classtable.Tempest) >30 or buff[classtable.AwakeningStormsBuff].count == 2 ) )) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and (talents[classtable.ThorimsInvocation] and buff[classtable.MaelstromWeaponBuff].count >0 and talents[classtable.ThorimsInvocation]) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.CrashingStorms] and ( ( talents[classtable.UnrulyWinds] and targets >= 10 ) or targets >= 15 )) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (( not talents[classtable.Tempest] or ( C_Spell.GetSpellCastCount(classtable.Tempest) <= 10 and buff[classtable.AwakeningStormsBuff].count <= 1 ) ) and ( ( debuff[classtable.FlameShockDeBuff].count  >= targets or debuff[classtable.FlameShockDeBuff].count  == 6 ) and buff[classtable.PrimordialWaveBuff].up and buff[classtable.MaelstromWeaponBuff].count == 10 and ( not buff[classtable.SplinteredElementsBuff].up or ttd <= 12 or targets <= gcd ) )) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (buff[classtable.VoltaicBlazeBuff].up and buff[classtable.MaelstromWeaponBuff].count <= 8) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (talents[classtable.MoltenAssault] and ( talents[classtable.PrimordialWave] or talents[classtable.FireNova] ) and debuff[classtable.FlameShockDeBuff].up and ( debuff[classtable.FlameShockDeBuff].count  <targets ) and debuff[classtable.FlameShockDeBuff].count  <6) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave')) and (not buff[classtable.PrimordialWaveBuff].up) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.ArcDischargeBuff].up and buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (( not talents[classtable.ElementalSpirits] or ( talents[classtable.ElementalSpirits] and ( cooldown[classtable.ElementalBlast].charges == cooldown[classtable.ElementalBlast].maxCharges or buff[classtable.FeralSpiritBuff].remains >= 2 ) ) ) and buff[classtable.MaelstromWeaponBuff].count == 10 and ( not talents[classtable.CrashingStorms] or targets <= 3 )) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (( buff[classtable.MaelstromWeaponBuff].count == 10 and not talents[classtable.RagingMaelstrom] ) or ( buff[classtable.MaelstromWeaponBuff].count >= 7 )) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit')) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds')) and (talents[classtable.ThorimsInvocation] and ( buff[classtable.LegacyoftheFrostWitchBuff].up or not talents[classtable.LegacyoftheFrostWitch] )) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (( buff[classtable.DoomWindsBuff].up and targets >= 4 ) or not buff[classtable.CrashLightningBuff].up or ( talents[classtable.AlphaWolf] and buff[classtable.FeralSpiritBuff].remains and buff[classtable.FeralSpiritBuff].remains == 0 )) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and (buff[classtable.DoomWindsBuff].up or talents[classtable.Earthsurge]) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count  == 6 or ( debuff[classtable.FlameShockDeBuff].count  >= 4 and debuff[classtable.FlameShockDeBuff].count  >= 1 )) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (talents[classtable.Stormblast] and talents[classtable.Stormflurry]) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (buff[classtable.VoltaicBlazeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (talents[classtable.LashingFlames]) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (talents[classtable.MoltenAssault] and debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and (talents[classtable.Hailstorm] and not buff[classtable.IceStrikeBuff].up) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (talents[classtable.Hailstorm] and buff[classtable.HailstormBuff].up) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (talents[classtable.MoltenAssault] and not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and ( talents[classtable.FireNova] or talents[classtable.PrimordialWave] ) and ( debuff[classtable.FlameShockDeBuff].count  <targets ) and debuff[classtable.FlameShockDeBuff].count  <6) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count  >= 3) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.CrashLightningBuff].up and ( talents[classtable.DeeplyRootedElements] or buff[classtable.ConvergingStormsBuff].count == 6 )) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.CrashingStorms] and buff[classtable.ClCrashLightningBuff].up and targets >= 4) and cooldown[classtable.CrashLightning].ready then
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
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count  >= 2) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (( not talents[classtable.ElementalSpirits] or ( talents[classtable.ElementalSpirits] and ( cooldown[classtable.ElementalBlast].charges == cooldown[classtable.ElementalBlast].maxCharges or buff[classtable.FeralSpiritBuff].remains >= 2 ) ) ) and buff[classtable.MaelstromWeaponBuff].count >= 5 and ( not talents[classtable.CrashingStorms] or targets <= 3 )) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (not talents[classtable.Hailstorm]) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
end
function Enhancement:aoe_totemic()
    if (MaxDps:CheckSpellUsable(classtable.SurgingTotem, 'SurgingTotem')) and cooldown[classtable.SurgingTotem].ready then
        if not setSpell then setSpell = classtable.SurgingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (( classtable and classtable.ChainLightning and GetSpellInfo(classtable.ChainLightning).castTime /1000 ) == 0 and talents[classtable.Ascendance] and cooldown[classtable.Ascendance].remains <2 * gcd and talents[classtable.ThorimsInvocation] and not talents[classtable.ThorimsInvocation]) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance')) and (talents[classtable.ThorimsInvocation]) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and (buff[classtable.AscendanceBuff].up and ( UnitExists('pet') and UnitName('pet')  == 'surging_totem' ) and talents[classtable.Earthsurge] and ( buff[classtable.LegacyoftheFrostWitchBuff].up or not talents[classtable.LegacyoftheFrostWitch] )) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.CrashingStorms] and ( targets >= 15 - 5 * (talents[classtable.UnrulyWinds] and talents[classtable.UnrulyWinds] or 0) )) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (( ( debuff[classtable.FlameShockDeBuff].count  >= targets or debuff[classtable.FlameShockDeBuff].count  == 6 ) and buff[classtable.PrimordialWaveBuff].up and buff[classtable.MaelstromWeaponBuff].count == 10 and ( not buff[classtable.SplinteredElementsBuff].up or ttd <= 12 or targets <= gcd ) )) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds')) and (not talents[classtable.ElementalSpirits] and ( buff[classtable.LegacyoftheFrostWitchBuff].up or not talents[classtable.LegacyoftheFrostWitch] )) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (talents[classtable.MoltenAssault] and ( talents[classtable.PrimordialWave] or talents[classtable.FireNova] ) and debuff[classtable.FlameShockDeBuff].up and debuff[classtable.FlameShockDeBuff].count  <targets and debuff[classtable.FlameShockDeBuff].count  <6) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave')) and (not buff[classtable.PrimordialWaveBuff].up) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (( not talents[classtable.ElementalSpirits] or ( talents[classtable.ElementalSpirits] and ( cooldown[classtable.ElementalBlast].charges == cooldown[classtable.ElementalBlast].maxCharges or buff[classtable.FeralSpiritBuff].remains >= 2 ) ) ) and buff[classtable.MaelstromWeaponBuff].count == 10 and ( not talents[classtable.CrashingStorms] or targets <= 3 )) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 10) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit')) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds')) and (buff[classtable.LegacyoftheFrostWitchBuff].up or not talents[classtable.LegacyoftheFrostWitch]) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (buff[classtable.DoomWindsBuff].up or not buff[classtable.CrashLightningBuff].up or ( talents[classtable.AlphaWolf] and buff[classtable.FeralSpiritBuff].remains and buff[classtable.FeralSpiritBuff].remains == 0 )) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and (buff[classtable.DoomWindsBuff].up or talents[classtable.Earthsurge] and ( buff[classtable.LegacyoftheFrostWitchBuff].up or not talents[classtable.LegacyoftheFrostWitch] ) and ( UnitExists('pet') and UnitName('pet')  == 'surging_totem' )) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count  == 6 or ( debuff[classtable.FlameShockDeBuff].count  >= 4 and debuff[classtable.FlameShockDeBuff].count  >= 1 )) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (buff[classtable.VoltaicBlazeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (talents[classtable.LashingFlames]) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (talents[classtable.MoltenAssault] and debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and (talents[classtable.Hailstorm] and not buff[classtable.IceStrikeBuff].up) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (talents[classtable.Hailstorm] and buff[classtable.HailstormBuff].up) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and (( buff[classtable.LegacyoftheFrostWitchBuff].up or not talents[classtable.LegacyoftheFrostWitch] ) and ( UnitExists('pet') and UnitName('pet')  == 'surging_totem' )) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (talents[classtable.MoltenAssault] and not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and ( talents[classtable.FireNova] or talents[classtable.PrimordialWave] ) and ( debuff[classtable.FlameShockDeBuff].count  <targets ) and debuff[classtable.FlameShockDeBuff].count  <6) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count  >= 3) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.CrashLightningBuff].up and ( talents[classtable.DeeplyRootedElements] or buff[classtable.ConvergingStormsBuff].count == 6 )) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.CrashingStorms] and buff[classtable.ClCrashLightningBuff].up and targets >= 4) and cooldown[classtable.CrashLightning].ready then
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
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count  >= 2) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (( not talents[classtable.ElementalSpirits] or ( talents[classtable.ElementalSpirits] and ( cooldown[classtable.ElementalBlast].charges == cooldown[classtable.ElementalBlast].maxCharges or buff[classtable.FeralSpiritBuff].remains >= 2 ) ) ) and buff[classtable.MaelstromWeaponBuff].count >= 5 and ( not talents[classtable.CrashingStorms] or targets <= 3 )) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
end
function Enhancement:funnel()
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit')) and (talents[classtable.ElementalSpirits]) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SurgingTotem, 'SurgingTotem')) and cooldown[classtable.SurgingTotem].ready then
        if not setSpell then setSpell = classtable.SurgingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ascendance, 'Ascendance')) and cooldown[classtable.Ascendance].ready then
        MaxDps:GlowCooldown(classtable.Ascendance, cooldown[classtable.Ascendance].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Windstrike, 'Windstrike')) and (( talents[classtable.ThorimsInvocation] and buff[classtable.MaelstromWeaponBuff].count >0 ) or buff[classtable.ConvergingStormsBuff].count == 6) and cooldown[classtable.Windstrike].ready then
        if not setSpell then setSpell = classtable.Windstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Tempest, 'Tempest')) and (buff[classtable.MaelstromWeaponBuff].count == 10 or ( buff[classtable.MaelstromWeaponBuff].count >= 5 and ( C_Spell.GetSpellCastCount(classtable.Tempest) >30 or buff[classtable.AwakeningStormsBuff].count == 2 ) )) and cooldown[classtable.Tempest].ready then
        if not setSpell then setSpell = classtable.Tempest end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (( debuff[classtable.FlameShockDeBuff].count  >= targets or debuff[classtable.FlameShockDeBuff].count  == 6 ) and buff[classtable.PrimordialWaveBuff].up and buff[classtable.MaelstromWeaponBuff].count == 10 and ( not buff[classtable.SplinteredElementsBuff].up or ttd <= 12 or targets <= gcd )) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and talents[classtable.ElementalSpirits] and buff[classtable.FeralSpiritBuff].remains >= 4) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (talents[classtable.Supercharge] and buff[classtable.MaelstromWeaponBuff].count == 10 and ( expected_lb_funnel >expected_cl_funnel )) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (( talents[classtable.Supercharge] and buff[classtable.MaelstromWeaponBuff].count == 10 ) or buff[classtable.ArcDischargeBuff].up and buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (( talents[classtable.MoltenAssault] and debuff[classtable.FlameShockDeBuff].up and ( debuff[classtable.FlameShockDeBuff].count  <targets ) and debuff[classtable.FlameShockDeBuff].count  <6 ) or ( talents[classtable.AshenCatalyst] and buff[classtable.AshenCatalystBuff].count == 8 )) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.PrimordialWave, 'PrimordialWave')) and (not buff[classtable.PrimordialWaveBuff].up) and cooldown[classtable.PrimordialWave].ready then
        MaxDps:GlowCooldown(classtable.PrimordialWave, cooldown[classtable.PrimordialWave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (( not talents[classtable.ElementalSpirits] or ( talents[classtable.ElementalSpirits] and ( cooldown[classtable.ElementalBlast].charges == cooldown[classtable.ElementalBlast].maxCharges or buff[classtable.FeralSpiritBuff].up ) ) ) and buff[classtable.MaelstromWeaponBuff].count == 10) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit')) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DoomWinds, 'DoomWinds')) and cooldown[classtable.DoomWinds].ready then
        if not setSpell then setSpell = classtable.DoomWinds end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.ConvergingStormsBuff].count == 6) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (( buff[classtable.MoltenWeaponBuff].count >buff[classtable.CracklingSurgeBuff].count ) and buff[classtable.MaelstromWeaponBuff].count == 10) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count == 10 and ( expected_lb_funnel >expected_cl_funnel )) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count == 10) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (buff[classtable.DoomWindsBuff].up or not buff[classtable.CrashLightningBuff].up or ( talents[classtable.AlphaWolf] and buff[classtable.FeralSpiritBuff].remains and buff[classtable.FeralSpiritBuff].remains == 0 ) or ( talents[classtable.ConvergingStorms] and buff[classtable.ConvergingStormsBuff].count <6 )) and cooldown[classtable.CrashLightning].ready then
        if not setSpell then setSpell = classtable.CrashLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and (buff[classtable.DoomWindsBuff].up or talents[classtable.Earthsurge]) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count  == 6 or ( debuff[classtable.FlameShockDeBuff].count  >= 4 and debuff[classtable.FlameShockDeBuff].count  >= targets )) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.IceStrike, 'IceStrike')) and (talents[classtable.Hailstorm] and not buff[classtable.IceStrikeBuff].up) and cooldown[classtable.IceStrike].ready then
        if not setSpell then setSpell = classtable.IceStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (talents[classtable.Hailstorm] and buff[classtable.HailstormBuff].up) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sundering, 'Sundering')) and cooldown[classtable.Sundering].ready then
        if not setSpell then setSpell = classtable.Sundering end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (talents[classtable.MoltenAssault] and not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].refreshable and ( talents[classtable.FireNova] or talents[classtable.PrimordialWave] ) and ( debuff[classtable.FlameShockDeBuff].count  <targets ) and debuff[classtable.FlameShockDeBuff].count  <6) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count  >= 3) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and (buff[classtable.CrashLightningBuff].up and talents[classtable.DeeplyRootedElements]) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrashLightning, 'CrashLightning')) and (talents[classtable.CrashingStorms] and buff[classtable.ClCrashLightningBuff].up and targets >= 4) and cooldown[classtable.CrashLightning].ready then
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
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova')) and (debuff[classtable.FlameShockDeBuff].count  >= 2) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast')) and (( not talents[classtable.ElementalSpirits] or ( talents[classtable.ElementalSpirits] and ( cooldown[classtable.ElementalBlast].charges == cooldown[classtable.ElementalBlast].maxCharges or buff[classtable.FeralSpiritBuff].up ) ) ) and buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (( buff[classtable.MoltenWeaponBuff].count >buff[classtable.CracklingSurgeBuff].count ) and buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >= 5 and ( expected_lb_funnel >expected_cl_funnel )) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (buff[classtable.MaelstromWeaponBuff].count >= 5) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and (not talents[classtable.Hailstorm]) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.WindShear, false)
    MaxDps:GlowCooldown(classtable.FeralSpirit, false)
    MaxDps:GlowCooldown(classtable.PrimordialWave, false)
    MaxDps:GlowCooldown(classtable.Ascendance, false)
    MaxDps:GlowCooldown(classtable.EarthElemental, false)
end

function Enhancement:callaction()
    if (MaxDps:CheckSpellUsable(classtable.WindShear, 'WindShear')) and cooldown[classtable.WindShear].ready then
        MaxDps:GlowCooldown(classtable.WindShear, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    --if (MaxDps:CheckSpellUsable(classtable.Purge, 'Purge')) and (buff[classtable.DispellableMagicBuff].up) and cooldown[classtable.Purge].ready then
    --    if not setSpell then setSpell = classtable.Purge end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.GreaterPurge, 'GreaterPurge')) and (buff[classtable.DispellableMagicBuff].up) and cooldown[classtable.GreaterPurge].ready then
    --    if not setSpell then setSpell = classtable.GreaterPurge end
    --end
    if (targets == 1 and not talents[classtable.SurgingTotem]) then
        Enhancement:single()
    end
    if (targets == 1 and talents[classtable.SurgingTotem]) then
        Enhancement:single_totemic()
    end
    if (targets >1 and not talents[classtable.SurgingTotem]) then
        Enhancement:aoe()
    end
    if (targets >1 and talents[classtable.SurgingTotem]) then
        Enhancement:aoe_totemic()
    end
    --if (targets >1 and toggle.funnel) then
    --    Enhancement:funnel()
    --end
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
    classtable.Windstrike = 115356
    classtable.FlameShock = MaxDps:FindSpell(470057) and 470057 or MaxDps:FindSpell(188389) and 188389 or MaxDps:FindSpell(470411) and 470411 or 188389
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.ChaosBrandDeBuff = 0
    classtable.HuntersMarkDeBuff = 0
    classtable.LightningRodDeBuff = 197209
    classtable.PrimordialWaveBuff = 375986
    classtable.FlameShockDeBuff = 188389
    classtable.MaelstromWeaponBuff = 344179
    classtable.LashingFlamesDeBuff = 334046
    classtable.TempestBuff = 454009
    classtable.AwakeningStormsBuff = 455129
    classtable.AscendanceBuff = 114051
    classtable.VoltaicBlazeBuff = 470058
    classtable.ArcDischargeBuff = 455096
    classtable.HotHandBuff = 215785
    classtable.AshenCatalystBuff = 0
    classtable.DoomWindsBuff = 384352
    classtable.StormsurgeBuff = 201846
    classtable.HailstormBuff = 334196
    classtable.IceStrikeBuff = 384357
    classtable.MoltenWeaponBuff = 0
    classtable.IcyEdgeBuff = 0
    classtable.TotemicReboundBuff = 445025
    classtable.LegacyoftheFrostWitchBuff = 384451
    classtable.EarthenWeaponBuff = 0
    classtable.WhirlingEarthBuff = 0
    classtable.SplinteredElementsBuff = 382043
    classtable.WhirlingAirBuff = 0
    classtable.CrashLightningBuff = 0
    classtable.ConvergingStormsBuff = 198300
    classtable.ClCrashLightningBuff = 0
    classtable.FeralSpiritBuff = 333957
    classtable.CracklingSurgeBuff = 0
    classtable.DispellableMagicBuff = 0
    setSpell = nil
    ClearCDs()

    Enhancement:precombat()

    Enhancement:callaction()
    if setSpell then return setSpell end
end
