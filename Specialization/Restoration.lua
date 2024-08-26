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

local Restoration = {}

function Restoration:precombat()
    --if (MaxDps:CheckSpellUsable(classtable.EarthlivingWeapon, 'EarthlivingWeapon')) and cooldown[classtable.EarthlivingWeapon].ready then
    --    return classtable.EarthlivingWeapon
    --end
    --if (MaxDps:CheckSpellUsable(classtable.WaterShield, 'WaterShield')) and (buff[classtable.WaterShieldBuff].up + buff[classtable.EarthShieldBuff].duration + buff[classtable.LightningShieldBuff].duration <1 + talents[classtable.ElementalOrbit]) and cooldown[classtable.WaterShield].ready then
    --    return classtable.WaterShield
    --end
    --if (MaxDps:CheckSpellUsable(classtable.LightningShield, 'LightningShield')) and (buff[classtable.WaterShieldBuff].up + buff[classtable.EarthShieldBuff].duration + buff[classtable.LightningShieldBuff].duration <1 + talents[classtable.ElementalOrbit]) and cooldown[classtable.LightningShield].ready then
    --    return classtable.LightningShield
    --end
    --if (MaxDps:CheckSpellUsable(classtable.EarthShield, 'EarthShield')) and (buff[classtable.WaterShieldBuff].up + buff[classtable.EarthShieldBuff].duration + buff[classtable.LightningShieldBuff].duration <1 + talents[classtable.ElementalOrbit]) and cooldown[classtable.EarthShield].ready then
    --    return classtable.EarthShield
    --end
    --if (MaxDps:CheckSpellUsable(classtable.EarthElemental, 'EarthElemental')) and cooldown[classtable.EarthElemental].ready then
    --    MaxDps:GlowCooldown(classtable.EarthElemental, cooldown[classtable.EarthElemental].ready)
    --end
end

function Restoration:callaction()
    if (MaxDps:CheckSpellUsable(classtable.SpiritwalkersGrace, 'SpiritwalkersGrace')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >6) and cooldown[classtable.SpiritwalkersGrace].ready then
        MaxDps:GlowCooldown(classtable.SpiritwalkersGrace, cooldown[classtable.SpiritwalkersGrace].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.WindShear, 'WindShear')) and cooldown[classtable.WindShear].ready then
        MaxDps:GlowCooldown(classtable.WindShear, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.HealingRain, 'HealingRain')) and (talents[classtable.AcidRain]) and cooldown[classtable.HealingRain].ready then
        return classtable.HealingRain
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (targets <3 and debuff[classtable.FlameShockDeBuff].refreshable) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (( targets == 1 or targets == 2 and buff[classtable.LavaSurgeBuff].up ) and debuff[classtable.FlameShockDeBuff].remains >( classtable and classtable.LavaBurst and GetSpellInfo(classtable.LavaBurst).castTime /1000 ) and cooldown[classtable.LavaBurst].ready) and cooldown[classtable.LavaBurst].ready then
        return classtable.LavaBurst
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthElemental, 'EarthElemental')) and cooldown[classtable.EarthElemental].ready then
        MaxDps:GlowCooldown(classtable.EarthElemental, cooldown[classtable.EarthElemental].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (targets <2 or not talents[classtable.ChainLightning]) and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (targets >1) and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostShock, 'FrostShock')) and cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
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
    classtable.WaterShieldBuff = 52127
    classtable.EarthShieldBuff = 383648
    classtable.LightningShieldBuff = 192106
    classtable.FlameShockDeBuff = 188389
    classtable.LavaSurgeBuff = 77762

    local precombatCheck = Restoration:precombat()
    if precombatCheck then
        return Restoration:precombat()
    end

    local callactionCheck = Restoration:callaction()
    if callactionCheck then
        return Restoration:callaction()
    end
end
