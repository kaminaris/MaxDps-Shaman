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

local Restoration = {}

function Restoration:precombat()
    if (MaxDps:CheckSpellUsable(classtable.EarthlivingWeapon, 'EarthlivingWeapon')) and talents[classtable.EarthlivingWeapon] and select(4,GetWeaponEnchantInfo()) ~= 6498 and cooldown[classtable.EarthlivingWeapon].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.EarthlivingWeapon end
    end
    if (MaxDps:CheckSpellUsable(classtable.TidecallersGuard, 'TidecallersGuard')) and select(8,GetWeaponEnchantInfo()) ~= 7528 and cooldown[classtable.TidecallersGuard].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.TidecallersGuard end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthElemental, 'EarthElemental')) and cooldown[classtable.EarthElemental].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.EarthElemental, cooldown[classtable.EarthElemental].ready)
    end
end

local function ClearCDs()
    MaxDps:GlowCooldown(classtable.EarthElemental, false)
    MaxDps:GlowCooldown(classtable.SpiritwalkersGrace, false)
    MaxDps:GlowCooldown(classtable.WindShear, false)
end

function Restoration:callaction()
    if (MaxDps:CheckSpellUsable(classtable.SpiritwalkersGrace, 'SpiritwalkersGrace')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >6) and cooldown[classtable.SpiritwalkersGrace].ready then
        MaxDps:GlowCooldown(classtable.SpiritwalkersGrace, cooldown[classtable.SpiritwalkersGrace].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.WindShear, 'WindShear')) and cooldown[classtable.WindShear].ready then
        MaxDps:GlowCooldown(classtable.WindShear, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.SurgingTotem, 'SurgingTotem')) and (talents[classtable.SurgingTotem] and talents[classtable.AcidRain]) and cooldown[classtable.SurgingTotem].ready then
        if not setSpell then setSpell = classtable.SurgingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.HealingRain, 'HealingRain')) and (not talents[classtable.SurgingTotem] and GetUnitSpeed("player") == 0 and talents[classtable.AcidRain]) and cooldown[classtable.HealingRain].ready then
        if not setSpell then setSpell = classtable.HealingRain end
    end
    --print(MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock'))
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (targets <3 and debuff[classtable.FlameShockDeBuff].refreshable) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (( targets == 1 or targets == 2 and buff[classtable.LavaSurgeBuff].up ) and debuff[classtable.FlameShockDeBuff].remains >( classtable and classtable.LavaBurst and GetSpellInfo(classtable.LavaBurst).castTime /1000 or 0 ) and cooldown[classtable.LavaBurst].ready) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthElemental, 'EarthElemental')) and cooldown[classtable.EarthElemental].ready then
        MaxDps:GlowCooldown(classtable.EarthElemental, cooldown[classtable.EarthElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (targets <2 or not talents[classtable.ChainLightning]) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (targets >1) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and cooldown[classtable.FrostShock].ready then
        if not setSpell then setSpell = classtable.FrostShock end
    end
end
function Shaman:Restoration()
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
    classtable.FlameShock = MaxDps:FindSpell(118389) and 118389 or MaxDps:FindSpell(470411) and 470411 or 118389
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.WaterShieldBuff = 52127
    classtable.EarthShieldBuff = 383648
    classtable.LightningShieldBuff = 192106
    classtable.UnleashLifeBuff = 0
    classtable.DownpourBuff = 462488
    classtable.HighTideBuff = 288675
    classtable.EarthShieldDeBuff = 0
    classtable.FlameShockDeBuff = 188389
    classtable.LavaSurgeBuff = 77762
    classtable.EarthlivingWeaponBuff = 6498
    classtable.TidecallersGuard = 457481
    setSpell = nil
    ClearCDs()

    Restoration:precombat()

    Restoration:callaction()
    if setSpell then return setSpell end
end
