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

local Maelstrom
local MaelstromMax
local MaelstromDeficit
local Mana
local ManaMax
local ManaDeficit
local ManaPerc
local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID

local Enhancement = {}



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


local function GetTotemTypeActive(i)
   local arg1, totemName, startTime, duration, icon = GetTotemInfo(i)
   return duration > 0
end


function Enhancement:precombat()
    if (MaxDps:CheckSpellUsable(classtable.WindfuryWeapon, 'WindfuryWeapon')) and (mainHandEnchantID ~= 283 and offHandEnchantID ~= 283) and cooldown[classtable.WindfuryWeapon].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.WindfuryWeapon end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlametongueWeapon, 'FlametongueWeapon')) and (mainHandEnchantID ~= 5 and offHandEnchantID ~= 5) and cooldown[classtable.FlametongueWeapon].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.FlametongueWeapon end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningShield, 'LightningShield')) and (not buff[classtable.LightningShieldBuff].up) and cooldown[classtable.LightningShield].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.LightningShield end
    end
    --if (MaxDps:CheckSpellUsable(classtable.TolvirPotion, 'TolvirPotion')) and cooldown[classtable.TolvirPotion].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.TolvirPotion end
    --end
end
function Enhancement:single()
    if (MaxDps:CheckSpellUsable(classtable.ElementalMastery, 'ElementalMastery') and talents[classtable.ElementalMastery]) and ((talents[classtable.ElementalMastery] and true or false)) and cooldown[classtable.ElementalMastery].ready then
        if not setSpell then setSpell = classtable.ElementalMastery end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireElementalTotem, 'FireElementalTotem')) and ((not GetTotemInfoByName('Searing Totem').up and not GetTotemInfoByName('Magma Totem').up) and ( MaxDps:Bloodlust(1) or buff[classtable.ElementalMasteryBuff].up or ttd <= 60 + 10 or ( (talents[classtable.ElementalMastery] and true or false) and ( cooldown[classtable.ElementalMastery].remains == 0 or cooldown[classtable.ElementalMastery].remains >80 ) or timeInCombat >= 60 ) )) and cooldown[classtable.FireElementalTotem].ready then
        if not setSpell then setSpell = classtable.FireElementalTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.SearingTotem, 'SearingTotem')) and (not GetTotemInfoByName('Searing Totem').up and not GetTotemInfoByName('Magma Totem').up and not GetTotemInfoByName("Fire Elemental Totem").up) and cooldown[classtable.SearingTotem].ready then
        if not setSpell then setSpell = classtable.SearingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnleashElements, 'UnleashElements')) and ((talents[classtable.UnleashedFury] and true or false)) and cooldown[classtable.UnleashElements].ready then
        if not setSpell then setSpell = classtable.UnleashElements end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].up == 5 or ( (MaxDps.tier and MaxDps.tier[13].count >= 4 and 1 or 0) == 1 and buff[classtable.MaelstromWeaponBuff].count >= 4 and ( UnitExists('pet') and UnitName('pet')  == 'SpiritWolf' ) )) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (buff[classtable.UnleashFlameBuff].up and not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnleashElements, 'UnleashElements')) and cooldown[classtable.UnleashElements].ready then
        if not setSpell then setSpell = classtable.UnleashElements end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >= 3 and debuff[classtable.UnleashedFuryFtDeBuff].up and not buff[classtable.AscendanceBuff].up) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.AncestralSwiftness, 'AncestralSwiftness') and talents[classtable.AncestralSwiftness]) and ((talents[classtable.AncestralSwiftness] and true or false) and buff[classtable.MaelstromWeaponBuff].count <2) and cooldown[classtable.AncestralSwiftness].ready then
        MaxDps:GlowCooldown(classtable.AncestralSwiftness, cooldown[classtable.AncestralSwiftness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.AncestralSwiftnessBuff].up) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (buff[classtable.UnleashFlameBuff].up and debuff[classtable.FlameShockDeBuff].remains <= 3) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit')) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthElementalTotem, 'EarthElementalTotem')) and (not GetTotemInfoByName("Earth Elemental Totem").up) and cooldown[classtable.EarthElementalTotem].ready then
        if not setSpell then setSpell = classtable.EarthElementalTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.SpiritwalkersGrace, 'SpiritwalkersGrace')) and cooldown[classtable.SpiritwalkersGrace].ready then
        MaxDps:GlowCooldown(classtable.SpiritwalkersGrace, cooldown[classtable.SpiritwalkersGrace].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >1 and not buff[classtable.AscendanceBuff].up) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
end
function Enhancement:ae()
    if (MaxDps:CheckSpellUsable(classtable.FireElementalTotem, 'FireElementalTotem')) and ((not GetTotemInfoByName('Searing Totem').up and not GetTotemInfoByName('Magma Totem').up) and ( MaxDps:Bloodlust(1) or buff[classtable.ElementalMasteryBuff].up or ttd <= 60 + 10 or ( (talents[classtable.ElementalMastery] and true or false) and ( cooldown[classtable.ElementalMastery].remains == 0 or cooldown[classtable.ElementalMastery].remains >80 ) or timeInCombat >= 60 ) )) and cooldown[classtable.FireElementalTotem].ready then
        if not setSpell then setSpell = classtable.FireElementalTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.MagmaTotem, 'MagmaTotem')) and (targets >5 and not GetTotemInfoByName('Searing Totem').up and not GetTotemInfoByName("Fire Elemental Totem").up) and cooldown[classtable.MagmaTotem].ready then
        if not setSpell then setSpell = classtable.MagmaTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.SearingTotem, 'SearingTotem')) and (targets <= 5 and not GetTotemInfoByName('Searing Totem').up and not GetTotemInfoByName('Magma Totem').up and not GetTotemInfoByName("Fire Elemental Totem").up) and cooldown[classtable.SearingTotem].ready then
        if not setSpell then setSpell = classtable.SearingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova')) and (( targets <= 5 and MaxDps:DebuffCounter(classtable.FlameShock) == targets ) or MaxDps:DebuffCounter(classtable.FlameShock) >= 5) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and (debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (targets >2 and buff[classtable.MaelstromWeaponBuff].count >= 3) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnleashElements, 'UnleashElements')) and cooldown[classtable.UnleashElements].ready then
        if not setSpell then setSpell = classtable.UnleashElements end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].up == 5 and cooldown[classtable.ChainLightning].remains >= 2) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralSpirit, 'FeralSpirit')) and cooldown[classtable.FeralSpirit].ready then
        MaxDps:GlowCooldown(classtable.FeralSpirit, cooldown[classtable.FeralSpirit].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (targets >2 and buff[classtable.MaelstromWeaponBuff].count >1) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >1) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.WindShear, false)
    MaxDps:GlowCooldown(classtable.Bloodlust, false)
    MaxDps:GlowCooldown(classtable.AncestralSwiftness, false)
    MaxDps:GlowCooldown(classtable.FeralSpirit, false)
    MaxDps:GlowCooldown(classtable.SpiritwalkersGrace, false)
end

function Enhancement:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Bloodlust, 'Bloodlust')) and (targethealthPerc <25 or timeInCombat >5) and cooldown[classtable.Bloodlust].ready then
        MaxDps:GlowCooldown(classtable.Bloodlust, cooldown[classtable.Bloodlust].ready)
    end
    --if (MaxDps:CheckSpellUsable(classtable.TolvirPotion, 'TolvirPotion')) and (timeInCombat >60 and ( ( UnitExists('pet') and UnitName('pet')  == 'PrimalFireElemental' ) or ( UnitExists('pet') and UnitName('pet')  == 'GreaterFireElemental' ) or ttd <= 60 )) and cooldown[classtable.TolvirPotion].ready then
    --    if not setSpell then setSpell = classtable.TolvirPotion end
    --end
    if (targets <= 1) then
        Enhancement:single()
    end
    if (targets >1) then
        Enhancement:ae()
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
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    local function debugg()
        talents[classtable.ElementalMastery] = 1
        talents[classtable.UnleashedFury] = 1
        talents[classtable.AncestralSwiftness] = 1
    end

    classtable.WindfuryWeapon = 8232
    classtable.FlametongueWeapon = 8024
    classtable.FireElementalTotem = 2894
    classtable.SearingTotem = 3599
    classtable.EarthElementalTotem = 2062

    classtable.LightningShieldBuff = 324
    classtable.ElementalMasteryBuff = 16166
    classtable.MaelstromWeaponBuff = 53817
    classtable.UnleashFlameBuff = 73683
    --classtable.AncestralSwiftnessBuff
    classtable.AscendanceBuff = 114051
    classtable.FlameShockDeBuff = 8050
    classtable.UnleashedFuryFtDeBuff = 118522

    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Enhancement:precombat()

    Enhancement:callaction()
    if setSpell then return setSpell end
end
