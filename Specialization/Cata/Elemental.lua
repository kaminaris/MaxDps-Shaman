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
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Maelstrom
local MaelstromMax
local MaelstromDeficit
local Mana
local ManaMax
local ManaDeficit

local Elemental = {}



local function ClearCDs()
    MaxDps:GlowCooldown(classtable.WindShear, false)
    MaxDps:GlowCooldown(classtable.Bloodlust, false)
    MaxDps:GlowCooldown(classtable.SpiritwalkersGrace, false)
end

function Elemental:callaction()
    if (MaxDps:CheckSpellUsable(classtable.FlametongueWeapon, 'FlametongueWeapon')) and cooldown[classtable.FlametongueWeapon].ready then
        if not setSpell then setSpell = classtable.FlametongueWeapon end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningShield, 'LightningShield')) and cooldown[classtable.LightningShield].ready then
        if not setSpell then setSpell = classtable.LightningShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.ManaSpringTotem, 'ManaSpringTotem')) and cooldown[classtable.ManaSpringTotem].ready then
        if not setSpell then setSpell = classtable.ManaSpringTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.WrathofAirTotem, 'WrathofAirTotem')) and cooldown[classtable.WrathofAirTotem].ready then
        if not setSpell then setSpell = classtable.WrathofAirTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.WindShear, 'WindShear')) and cooldown[classtable.WindShear].ready then
        MaxDps:GlowCooldown(classtable.WindShear, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodlust, 'Bloodlust')) and cooldown[classtable.Bloodlust].ready then
        MaxDps:GlowCooldown(classtable.Bloodlust, cooldown[classtable.Bloodlust].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodlust, 'Bloodlust')) and (ttd <= 60) and cooldown[classtable.Bloodlust].ready then
        MaxDps:GlowCooldown(classtable.Bloodlust, cooldown[classtable.Bloodlust].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalMastery, 'ElementalMastery')) and cooldown[classtable.ElementalMastery].ready then
        if not setSpell then setSpell = classtable.ElementalMastery end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnleashElements, 'UnleashElements')) and cooldown[classtable.UnleashElements].ready then
        if not setSpell then setSpell = classtable.UnleashElements end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up or ticks_remain <2 or ( ( MaxDps:Bloodlust() or buff[classtable.ElementalMasteryBuff].up ) and ticks_remain <3 )) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >( classtable and classtable.LavaBurst and GetSpellInfo(classtable.LavaBurst).castTime /1000 )) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (buff[classtable.LightningShieldBuff].up == 9) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (buff[classtable.LightningShieldBuff].count >6 and debuff[classtable.FlameShockDeBuff].remains >cooldown and debuff[classtable.FlameShockDeBuff].remains <cooldown + action.flame_shock.tick_time) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireElementalTotem, 'FireElementalTotem')) and (not debuff[classtable.FireElementalTotemDeBuff].up and buff[classtable.VolcanicPotionBuff].up and temporary_bonus.spell_power >= 2400) and cooldown[classtable.FireElementalTotem].ready then
        if not setSpell then setSpell = classtable.FireElementalTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireElementalTotem, 'FireElementalTotem')) and (not debuff[classtable.FireElementalTotemDeBuff].up and not buff[classtable.VolcanicPotionBuff].up and temporary_bonus.spell_power >= 1200) and cooldown[classtable.FireElementalTotem].ready then
        if not setSpell then setSpell = classtable.FireElementalTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthElementalTotem, 'EarthElementalTotem')) and (not debuff[classtable.EarthElementalTotemDeBuff].up) and cooldown[classtable.EarthElementalTotem].ready then
        if not setSpell then setSpell = classtable.EarthElementalTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.SearingTotem, 'SearingTotem')) and cooldown[classtable.SearingTotem].ready then
        if not setSpell then setSpell = classtable.SearingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.SpiritwalkersGrace, 'SpiritwalkersGrace')) and cooldown[classtable.SpiritwalkersGrace].ready then
        MaxDps:GlowCooldown(classtable.SpiritwalkersGrace, cooldown[classtable.SpiritwalkersGrace].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (target.adds >2) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Thunderstorm, 'Thunderstorm')) and cooldown[classtable.Thunderstorm].ready then
        if not setSpell then setSpell = classtable.Thunderstorm end
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
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.bloodlust = 0
    classtable.FlameShockDeBuff = 188389
    classtable.ElementalMasteryBuff = 0
    classtable.LightningShieldBuff = 192106
    classtable.FireElementalTotemDeBuff = 0
    classtable.VolcanicPotionBuff = 0
    classtable.EarthElementalTotemDeBuff = 0
    setSpell = nil
    ClearCDs()

    Elemental:callaction()
    if setSpell then return setSpell end
end
