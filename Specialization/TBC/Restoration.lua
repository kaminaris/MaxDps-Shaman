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
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Maelstrom
local MaelstromMax
local MaelstromDeficit
local Mana
local ManaMax
local ManaDeficit
local ManaPerc
local speed, runSpeed, flightSpeed = 0, 0, 0

local Restoration = {}

local function ClearCDs()
    MaxDps:GlowCooldown(classtable.FireNovaTotem, false)
    MaxDps:GlowCooldown(classtable.MagmaTotem, false)
    MaxDps:GlowCooldown(classtable.TotemofWrath, false)
end

function Restoration:AoE()
    if (MaxDps:CheckSpellUsable(classtable.FireNovaTotem, 'FireNovaTotem')) and (not MaxDps:FindBuffAuraData(classtable.FireNovaTotem).up) and cooldown[classtable.FireNovaTotem].ready then
        --if not setSpell then setSpell = classtable.FireNovaTotem end
        MaxDps:GlowCooldown(classtable.FireNovaTotem, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (cooldown[classtable.ElementalMastery].ready) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.MagmaTotem, 'MagmaTotem')) and not cooldown[classtable.FireNovaTotem].ready and cooldown[classtable.MagmaTotem].ready then
        --if not setSpell then setSpell = classtable.MagmaTotem end
        MaxDps:GlowCooldown(classtable.MagmaTotem, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not MaxDps:FindBuffAuraData(classtable.FlameShock).up) and speed >= 0 and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
end

function Restoration:Single()
    if (MaxDps:CheckSpellUsable(classtable.TotemofWrath, 'TotemofWrath')) and (not MaxDps:FindBuffAuraData(classtable.TotemofWrath).up) and cooldown[classtable.TotemofWrath].ready then
        --if not setSpell then setSpell = classtable.TotemofWrath end
        MaxDps:GlowCooldown(classtable.TotemofWrath, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (cooldown[classtable.ElementalMastery].ready) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not MaxDps:FindBuffAuraData(classtable.FlameShock).up) and speed >= 0 and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
end

function Restoration:CallAction()
    if targets >= 2 then
        Restoration:AoE()
    end
    Restoration:Single()
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
    ManaPerc = (Mana / ManaMax) * 100

    speed, runSpeed, flightSpeed = GetUnitSpeed("player")

    classtable.FireNovaTotem = 29077
    classtable.ChainLightning = 25383
    classtable.MagmaTotem = 25549
    classtable.FlameShock = 25457
    classtable.LightningBolt = 25448
    classtable.ElementalMastery = 16166
    classtable.TotemofWrath = 30706

    setSpell = nil
    ClearCDs()

    Restoration:CallAction()
    if setSpell then return setSpell end
end
