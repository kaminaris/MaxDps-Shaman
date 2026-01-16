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
local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID

local Enhancement = {}

local function ClearCDs()
    MaxDps:GlowCooldown(classtable.FireNovaTotem, false)
    MaxDps:GlowCooldown(classtable.MagmaTotem, false)
    MaxDps:GlowCooldown(classtable.StrengthofEarthTotem, false)
    MaxDps:GlowCooldown(classtable.WindfuryWeapon, false)
end

function Enhancement:AoE()
    if (MaxDps:CheckSpellUsable(classtable.FireNovaTotem, 'FireNovaTotem')) and (not MaxDps:FindBuffAuraData(classtable.FireNovaTotem).up) and cooldown[classtable.FireNovaTotem].ready then
        --if not setSpell then setSpell = classtable.FireNovaTotem end
        MaxDps:GlowCooldown(classtable.FireNovaTotem, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.MagmaTotem, 'MagmaTotem')) and not cooldown[classtable.FireNovaTotem].ready and cooldown[classtable.MagmaTotem].ready then
        --if not setSpell then setSpell = classtable.MagmaTotem end
        MaxDps:GlowCooldown(classtable.MagmaTotem, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not MaxDps:FindBuffAuraData(classtable.FlameShock).up) and speed >= 0 and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
end

function Enhancement:Single()
    if (MaxDps:CheckSpellUsable(classtable.StrengthofEarthTotem, 'StrengthofEarthTotem')) and (not MaxDps:FindBuffAuraData(classtable.StrengthofEarthTotem).up) and cooldown[classtable.StrengthofEarthTotem].ready then
        --if not setSpell then setSpell = classtable.StrengthofEarthTotem end
        MaxDps:GlowCooldown(classtable.StrengthofEarthTotem, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (debuff[classtable.EarthShock].up) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShock].refreshable) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
end

function Enhancement:CallAction()
    if (MaxDps:CheckSpellUsable(classtable.WindfuryWeapon, 'WindfuryWeapon')) and (mainHandEnchantID ~= 283 and offHandEnchantID ~= 283) and cooldown[classtable.WindfuryWeapon].ready then
        --if not setSpell then setSpell = classtable.WindfuryWeapon end
        MaxDps:GlowCooldown(classtable.WindfuryWeapon, true)
    end
    if targets >= 2 then
        Enhancement:AoE()
    end
    Enhancement:Single()
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
    ManaPerc = (Mana / ManaMax) * 100
    hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID = GetWeaponEnchantInfo()

    classtable.FireNovaTotem = 29077
    classtable.MagmaTotem = 25549
    classtable.StrengthofEarthTotem = 25528
    classtable.FlameShock = 25457
    classtable.Stormstrike = 17364
    classtable.EarthShock = 25454

    setSpell = nil
    ClearCDs()

    Enhancement:CallAction()
    if setSpell then return setSpell end
end
