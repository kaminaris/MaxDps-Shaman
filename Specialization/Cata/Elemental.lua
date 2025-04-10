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
local ManaPerc

local Elemental = {}



local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end


local function GetTotemTypeActive(i)
   local arg1, totemName, startTime, duration, icon = GetTotemInfo(i)
   return duration > 0
end


function Elemental:precombat()
    if (MaxDps:CheckSpellUsable(classtable.LightningShield, 'LightningShield')) and (not buff[classtable.LightningShieldBuff].up) and cooldown[classtable.LightningShield].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.LightningShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.CalloftheElements, 'CalloftheElements')) and ((GetTotemTypeActive('1') == false) and (GetTotemTypeActive('2') == false) and (GetTotemTypeActive('3') == false) and (GetTotemTypeActive('4') == false)) and cooldown[classtable.CalloftheElements].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.CalloftheElements end
    end
end
function Elemental:single()
    if (MaxDps:CheckSpellUsable(classtable.FireElementalTotem, 'FireElementalTotem')) and (buff[classtable.PotionBuff].up or ttd <= 120) and cooldown[classtable.FireElementalTotem].ready then
        if not setSpell then setSpell = classtable.FireElementalTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.CalloftheElements, 'CalloftheElements')) and ((GetTotemTypeActive('1') == false) and (GetTotemTypeActive('2') == false) and (GetTotemTypeActive('3') == false) and (GetTotemTypeActive('4') == false)) and cooldown[classtable.CalloftheElements].ready then
        if not setSpell then setSpell = classtable.CalloftheElements end
    end
    if (MaxDps:CheckSpellUsable(classtable.SearingTotem, 'SearingTotem')) and ((GetTotemTypeActive('1') == false)) and cooldown[classtable.SearingTotem].ready then
        if not setSpell then setSpell = classtable.SearingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalMastery, 'ElementalMastery')) and cooldown[classtable.ElementalMastery].ready then
        if not setSpell then setSpell = classtable.ElementalMastery end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (debuff[classtable.FlameShockDeBuff].remains <= 2) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >2) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (buff[classtable.LightningShieldBuff].count >= 7) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Thunderstorm, 'Thunderstorm')) and (ManaPerc <60) and cooldown[classtable.Thunderstorm].ready then
        if not setSpell then setSpell = classtable.Thunderstorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningShield, 'LightningShield')) and (not buff[classtable.LightningShieldBuff].up) and cooldown[classtable.LightningShield].ready then
        if not setSpell then setSpell = classtable.LightningShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (targets >1 and not (GetUnitSpeed('player') >0)) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnleashElements, 'UnleashElements')) and ((GetUnitSpeed('player') >0) and not MaxDps:HasGlyphEnabled(classtable.UnleashedLightningGlyph)) and cooldown[classtable.UnleashElements].ready then
        if not setSpell then setSpell = classtable.UnleashElements end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
end
function Elemental:aoe()
    if (MaxDps:CheckSpellUsable(classtable.CalloftheAncestors, 'CalloftheAncestors')) and ((GetTotemTypeActive('1') == false) and (GetTotemTypeActive('2') == false) and (GetTotemTypeActive('3') == false) and (GetTotemTypeActive('4') == false)) and cooldown[classtable.CalloftheAncestors].ready then
        if not setSpell then setSpell = classtable.CalloftheAncestors end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireElementalTotem, 'FireElementalTotem')) and cooldown[classtable.FireElementalTotem].ready then
        if not setSpell then setSpell = classtable.FireElementalTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalMastery, 'ElementalMastery')) and cooldown[classtable.ElementalMastery].ready then
        if not setSpell then setSpell = classtable.ElementalMastery end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (buff[classtable.LightningShieldBuff].count >= 9 and targets <= 4) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.MagmaTotem, 'MagmaTotem')) and ((GetTotemTypeActive('1') == false)) and cooldown[classtable.MagmaTotem].ready then
        if not setSpell then setSpell = classtable.MagmaTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.Thunderstorm, 'Thunderstorm')) and (ManaPerc <60) and cooldown[classtable.Thunderstorm].ready then
        if not setSpell then setSpell = classtable.Thunderstorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningShield, 'LightningShield')) and (not buff[classtable.LightningShieldBuff].up) and cooldown[classtable.LightningShield].ready then
        if not setSpell then setSpell = classtable.LightningShield end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and ((GetUnitSpeed('player') >0) and MaxDps:HasGlyphEnabled(classtable.UnleashedLightningGlyph)) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
end


local function ClearCDs()
end

function Elemental:callaction()
    if (targets >2) then
        Elemental:aoe()
    end
    Elemental:single()
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
    ManaPerc = (Mana / ManaMax) * 100
    classtable.Icefury = 210714
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.LightningShieldBuff = 324
    classtable.FlameShockDeBuff = 8050
    classtable.LightningShield = 324
    classtable.CalloftheElements = 66842
    classtable.FireElementalTotem = 2894
    classtable.SearingTotem = 3599
    classtable.ElementalMastery = 16166
    classtable.FlameShock = 8050
    classtable.LavaBurst = 51505
    classtable.EarthShock = 8042
    classtable.Thunderstorm = 51490
    classtable.ChainLightning = 421
    classtable.UnleashElements = 73680
    classtable.LightningBolt = 403
    classtable.CalloftheAncestors = 66843
    classtable.MagmaTotem = 8190
    classtable.UnleashedLightningGlyph = 101052
    classtable.UnleashedLightningGlyph = 101052

    local function debugg()
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
