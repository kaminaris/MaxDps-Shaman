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

local Enhancement = {}

function Enhancement:precombat()
    if (MaxDps:CheckSpellUsable(classtable.StrengthofEarthTotem, 'StrengthofEarthTotem')) and cooldown[classtable.StrengthofEarthTotem].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.StrengthofEarthTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.WindfuryTotem, 'WindfuryTotem')) and cooldown[classtable.WindfuryTotem].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.WindfuryTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.GraceofAirTotem, 'GraceofAirTotem')) and cooldown[classtable.GraceofAirTotem].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.GraceofAirTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.SearingTotem, 'SearingTotem')) and cooldown[classtable.SearingTotem].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SearingTotem end
    end
end
function Enhancement:priorityList()
    if (MaxDps:CheckSpellUsable(classtable.StrengthofEarthTotem, 'StrengthofEarthTotem')) and (not MaxDps:FindBuffAuraData ( 10442 ) .up) and cooldown[classtable.StrengthofEarthTotem].ready then
        if not setSpell then setSpell = classtable.StrengthofEarthTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.WindfuryTotem, 'WindfuryTotem')) and (MaxDps:FindBuffAuraData ( 10611 ) .remains <= 1.5) and cooldown[classtable.WindfuryTotem].ready then
        if not setSpell then setSpell = classtable.WindfuryTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.GraceofAirTotem, 'GraceofAirTotem')) and (not MaxDps:FindBuffAuraData ( 10627 ) .up) and cooldown[classtable.GraceofAirTotem].ready then
        if not setSpell then setSpell = classtable.GraceofAirTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.SearingTotem, 'SearingTotem')) and (not MaxDps:FindDeBuffAuraData ( 10438 ) .up and ttd >= 20) and cooldown[classtable.SearingTotem].ready then
        if not setSpell then setSpell = classtable.SearingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (ManaPerc >= 50) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
end


local function ClearCDs()
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
    classtable.Windstrike = 115356
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    classtable.StrengthofEarthTotem=10442
    classtable.WindfuryTotem=10614
    classtable.GraceofAirTotem=10627
    classtable.SearingTotem=10438
    classtable.Stormstrike=17364
    classtable.EarthShock=10414

    local function debugg()
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Enhancement:precombat()
    Enhancement:priorityList()
    if setSpell then return setSpell end
end
