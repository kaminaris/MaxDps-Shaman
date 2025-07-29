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

local Elemental = {}



local function GetTotemInfoById(sSpellID)
    local info = {
        duration = 0,
        remains = 0,
        up = false,
    }
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon, modRate, spellID = GetTotemInfo(index)
        local sName = sSpellID and GetSpellInfo(sSpellID).name or ""
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


function Elemental:precombat()
    if (MaxDps:CheckSpellUsable(classtable.FlametongueWeapon, 'FlametongueWeapon')) and (mainHandEnchantID ~= 5) and cooldown[classtable.FlametongueWeapon].ready then
        if not setSpell then setSpell = classtable.FlametongueWeapon end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningShield, 'LightningShield')) and (ManaPerc < 15 and not buff[classtable.LightningShieldBuff].up) and cooldown[classtable.LightningShield].ready and not UnitAffectingCombat('player') then
        --if not setSpell then setSpell = classtable.LightningShield end
        MaxDps:GlowCooldown(classtable.LightningShield, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.WaterShield, 'WaterShield')) and (ManaPerc < 15 and not buff[classtable.WaterShieldBuff].up) and cooldown[classtable.WaterShield].ready and not UnitAffectingCombat('player') then
        --if not setSpell then setSpell = classtable.WaterShield end
        MaxDps:GlowCooldown(classtable.WaterShield, true)
    end
    --if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and cooldown[classtable.VolcanicPotion].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.VolcanicPotion end
    --end
end
function Elemental:single()
    if (MaxDps:CheckSpellUsable(classtable.ElementalMastery, 'ElementalMastery') and talents[classtable.ElementalMastery]) and ((talents[classtable.ElementalMastery] and true or false) and timeInCombat >15 and ( ( not MaxDps:Bloodlust(1) and timeInCombat <120 ) or ( not buff[classtable.BerserkingBuff].up and not MaxDps:Bloodlust(1) and buff[classtable.AscendanceBuff].up ) or ( timeInCombat >= 200 and ( cooldown[classtable.Ascendance].remains >30 or UnitLevel('player') <87 ) ) )) and cooldown[classtable.ElementalMastery].ready then
        --if not setSpell then setSpell = classtable.ElementalMastery end
        MaxDps:GlowCooldown(classtable.ElementalMastery, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.FireElementalTotem, 'FireElementalTotem')) and (not GetTotemInfoById(classtable.SearingTotem).up and not GetTotemInfoById(classtable.MagmaTotem).up) and cooldown[classtable.FireElementalTotem].ready then
        --if not setSpell then setSpell = classtable.FireElementalTotem end
        MaxDps:GlowCooldown(classtable.FireElementalTotem, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.AncestralSwiftness, 'AncestralSwiftness') and talents[classtable.AncestralSwiftness]) and ((talents[classtable.AncestralSwiftness] and true or false) and not buff[classtable.AscendanceBuff].up) and cooldown[classtable.AncestralSwiftness].ready then
        MaxDps:GlowCooldown(classtable.AncestralSwiftness, cooldown[classtable.AncestralSwiftness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.UnleashElements, 'UnleashElements')) and ((talents[classtable.UnleashedFury] and true or false) and not buff[classtable.AscendanceBuff].up) and cooldown[classtable.UnleashElements].ready then
        if not setSpell then setSpell = classtable.UnleashElements end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not buff[classtable.AscendanceBuff].up and ( not debuff[classtable.FlameShockDeBuff].up or debuff[classtable.FlameShockDeBuff].remains <2 or ( ( MaxDps:Bloodlust(1) or buff[classtable.ElementalMasteryBuff].up ) and debuff[classtable.FlameShockDeBuff].remains <3 ) )) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (debuff[classtable.FlameShockDeBuff].remains >( classtable and classtable.LavaBurst and GetSpellInfo(classtable.LavaBurst).castTime /1000 or 0) and ( buff[classtable.AscendanceBuff].up or cooldown[classtable.LavaBurst].ready )) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.ElementalBlast, 'ElementalBlast') and talents[classtable.ElementalBlast]) and ((talents[classtable.ElementalBlast] and true or false) and not buff[classtable.AscendanceBuff].up) and cooldown[classtable.ElementalBlast].ready then
        if not setSpell then setSpell = classtable.ElementalBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (buff[classtable.LightningShieldBuff].count >= 6) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and (buff[classtable.LightningShieldBuff].count >3 and debuff[classtable.FlameShockDeBuff].remains >cooldown[classtable.EarthShock].remains and debuff[classtable.FlameShockDeBuff].remains <cooldown[classtable.EarthShock].remains + 1) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthElementalTotem, 'EarthElementalTotem')) and (not GetTotemInfoById(classtable.EarthElementalTotem).up) and cooldown[classtable.EarthElementalTotem].ready then
        --if not setSpell then setSpell = classtable.EarthElementalTotem end
        MaxDps:GlowCooldown(classtable.EarthElementalTotem, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.SearingTotem, 'SearingTotem')) and (not GetTotemInfoById(classtable.SearingTotem).up and not GetTotemInfoById(classtable.MagmaTotem).up and not GetTotemInfoById(classtable.FireElementalTotem).up) and cooldown[classtable.SearingTotem].ready then
        if not setSpell then setSpell = classtable.SearingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.SpiritwalkersGrace, 'SpiritwalkersGrace')) and cooldown[classtable.SpiritwalkersGrace].ready then
        MaxDps:GlowCooldown(classtable.SpiritwalkersGrace, cooldown[classtable.SpiritwalkersGrace].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.UnleashElements, 'UnleashElements')) and cooldown[classtable.UnleashElements].ready then
        if not setSpell then setSpell = classtable.UnleashElements end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
end
function Elemental:ae()
    if (MaxDps:CheckSpellUsable(classtable.MagmaTotem, 'MagmaTotem')) and (targets >2 and not GetTotemInfoById(classtable.MagmaTotem).up and not GetTotemInfoById(classtable.SearingTotem).up and not GetTotemInfoById(classtable.FireElementalTotem).up) and cooldown[classtable.MagmaTotem].ready then
        if not setSpell then setSpell = classtable.MagmaTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.SearingTotem, 'SearingTotem')) and (targets <= 2 and not GetTotemInfoById(classtable.SearingTotem).up and not GetTotemInfoById(classtable.MagmaTotem).up and not GetTotemInfoById(classtable.FireElementalTotem).up) and cooldown[classtable.SearingTotem].ready then
        if not setSpell then setSpell = classtable.SearingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up and targets <3) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaBurst, 'LavaBurst')) and (targets <3 and debuff[classtable.FlameShockDeBuff].remains >( classtable and classtable.LavaBurst and GetSpellInfo(classtable.LavaBurst).castTime /1000 or 0) and cooldown[classtable.LavaBurst].ready) and cooldown[classtable.LavaBurst].ready then
        if not setSpell then setSpell = classtable.LavaBurst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Earthquake, 'Earthquake')) and (targets >4) and cooldown[classtable.Earthquake].ready then
        if not setSpell then setSpell = classtable.Earthquake end
    end
    if (MaxDps:CheckSpellUsable(classtable.Thunderstorm, 'Thunderstorm')) and (ManaPerc <80) and cooldown[classtable.Thunderstorm].ready then
        if not setSpell then setSpell = classtable.Thunderstorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainLightning, 'ChainLightning')) and (ManaPerc >10) and cooldown[classtable.ChainLightning].ready then
        if not setSpell then setSpell = classtable.ChainLightning end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.WindShear, false)
    MaxDps:GlowCooldown(classtable.Bloodlust, false)
    MaxDps:GlowCooldown(classtable.AncestralSwiftness, false)
    MaxDps:GlowCooldown(classtable.SpiritwalkersGrace, false)
    MaxDps:GlowCooldown(classtable.ElementalMastery, false)
    MaxDps:GlowCooldown(classtable.FireElementalTotem, false)
    MaxDps:GlowCooldown(classtable.EarthElementalTotem, false)
    MaxDps:GlowCooldown(classtable.LightningShield, false)
    MaxDps:GlowCooldown(classtable.WaterShield, false)
end

function Elemental:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Bloodlust, 'Bloodlust')) and (targethealthPerc <25 or timeInCombat >5) and cooldown[classtable.Bloodlust].ready then
        MaxDps:GlowCooldown(classtable.Bloodlust, cooldown[classtable.Bloodlust].ready)
    end
    --if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and (timeInCombat >60 and ( ( UnitExists('pet') and UnitName('pet')  == 'PrimalFireElemental' ) or ( UnitExists('pet') and UnitName('pet')  == 'GreaterFireElemental' ) or ttd <= 60 )) and cooldown[classtable.VolcanicPotion].ready then
    --    if not setSpell then setSpell = classtable.VolcanicPotion end
    --end
    if (targets <= 1) then
        Elemental:single()
    end
    if (targets >1) then
        Elemental:ae()
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
    ManaPerc = (Mana / ManaMax) * 100
    hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID = GetWeaponEnchantInfo()
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    local function debugg()
        talents[classtable.ElementalMastery] = 1
        talents[classtable.AncestralSwiftness] = 1
        talents[classtable.UnleashedFury] = 1
        talents[classtable.ElementalBlast] = 1
    end

    classtable.FlametongueWeapon = 8024
    classtable.FireElementalTotem = 2894
    classtable.MagmaTotem = 8190
    classtable.EarthElementalTotem = 2062
    classtable.SearingTotem = 3599
    classtable.WaterShield = 52127

    --classtable.FlametongueWeaponBuff
    classtable.LightningShieldBuff = 324
    classtable.WaterShieldBuff = 52127
    classtable.BerserkingBuff = 20554
    classtable.AscendanceBuff = 114050
    classtable.ElementalMasteryBuff = 16166
    classtable.FlameShockDeBuff = 8050

    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Elemental:precombat()

    Elemental:callaction()
    if setSpell then return setSpell end
end
