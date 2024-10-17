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

local Enhancement = {}



local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end




local function ClearCDs()
    MaxDps:GlowCooldown(classtable.WindShear, false)
    MaxDps:GlowCooldown(classtable.Bloodlust, false)
    MaxDps:GlowCooldown(classtable.SpiritwalkersGrace, false)
end

function Enhancement:callaction()
    --if (MaxDps:CheckSpellUsable(classtable.WindfuryWeapon, 'WindfuryWeapon')) and cooldown[classtable.WindfuryWeapon].ready then
    --    if not setSpell then setSpell = classtable.WindfuryWeapon end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.FlametongueWeapon, 'FlametongueWeapon')) and cooldown[classtable.FlametongueWeapon].ready then
    --    if not setSpell then setSpell = classtable.FlametongueWeapon end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.StrengthofEarthTotem, 'StrengthofEarthTotem')) and cooldown[classtable.StrengthofEarthTotem].ready then
    --    if not setSpell then setSpell = classtable.StrengthofEarthTotem end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.WindfuryTotem, 'WindfuryTotem')) and cooldown[classtable.WindfuryTotem].ready then
    --    if not setSpell then setSpell = classtable.WindfuryTotem end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.ManaSpringTotem, 'ManaSpringTotem')) and cooldown[classtable.ManaSpringTotem].ready then
    --    if not setSpell then setSpell = classtable.ManaSpringTotem end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.LightningShield, 'LightningShield')) and cooldown[classtable.LightningShield].ready then
    --    if not setSpell then setSpell = classtable.LightningShield end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.TolvirPotion, 'TolvirPotion')) and (not UnitAffectingCombat('player') or MaxDps:Bloodlust() or ttd <= 40) and cooldown[classtable.TolvirPotion].ready then
    --    if not setSpell then setSpell = classtable.TolvirPotion end
    --end
    if (MaxDps:CheckSpellUsable(classtable.WindShear, 'WindShear')) and cooldown[classtable.WindShear].ready then
        MaxDps:GlowCooldown(classtable.WindShear, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodlust, 'Bloodlust')) and cooldown[classtable.Bloodlust].ready then
        MaxDps:GlowCooldown(classtable.Bloodlust, cooldown[classtable.Bloodlust].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodlust, 'Bloodlust')) and (ttd <= 60) and cooldown[classtable.Bloodlust].ready then
        MaxDps:GlowCooldown(classtable.Bloodlust, cooldown[classtable.Bloodlust].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SearingTotem, 'SearingTotem')) and cooldown[classtable.SearingTotem].ready then
        if not setSpell then setSpell = classtable.SearingTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stormstrike, 'Stormstrike')) and cooldown[classtable.Stormstrike].ready then
        if not setSpell then setSpell = classtable.Stormstrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.LavaLash, 'LavaLash')) and cooldown[classtable.LavaLash].ready then
        if not setSpell then setSpell = classtable.LavaLash end
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].up == 5 or ( (MaxDps.tier and MaxDps.tier[13].count >= 4 and 1 or 0) == 1 and buff[classtable.MaelstromWeaponBuff].count >= 4 and ( UnitExists('pet') and UnitName('pet')  == 'spirit_wolf' ) )) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnleashElements, 'UnleashElements')) and cooldown[classtable.UnleashElements].ready then
        if not setSpell then setSpell = classtable.UnleashElements end
    end
    if (MaxDps:CheckSpellUsable(classtable.FlameShock, 'FlameShock')) and (not debuff[classtable.FlameShockDeBuff].up or buff[classtable.UnleashFlameBuff].up) and cooldown[classtable.FlameShock].ready then
        if not setSpell then setSpell = classtable.FlameShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthShock, 'EarthShock')) and cooldown[classtable.EarthShock].ready then
        if not setSpell then setSpell = classtable.EarthShock end
    end
    if (MaxDps:CheckSpellUsable(classtable.SpiritWolf, 'SpiritWolf')) and cooldown[classtable.SpiritWolf].ready then
        if not setSpell then setSpell = classtable.SpiritWolf end
    end
    if (MaxDps:CheckSpellUsable(classtable.EarthElementalTotem, 'EarthElementalTotem')) and cooldown[classtable.EarthElementalTotem].ready then
        if not setSpell then setSpell = classtable.EarthElementalTotem end
    end
    if (MaxDps:CheckSpellUsable(classtable.FireNova, 'FireNova')) and (targets >1) and cooldown[classtable.FireNova].ready then
        if not setSpell then setSpell = classtable.FireNova end
    end
    if (MaxDps:CheckSpellUsable(classtable.SpiritwalkersGrace, 'SpiritwalkersGrace')) and cooldown[classtable.SpiritwalkersGrace].ready then
        MaxDps:GlowCooldown(classtable.SpiritwalkersGrace, cooldown[classtable.SpiritwalkersGrace].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.LightningBolt, 'LightningBolt')) and (buff[classtable.MaelstromWeaponBuff].count >1) and cooldown[classtable.LightningBolt].ready then
        if not setSpell then setSpell = classtable.LightningBolt end
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
    classtable.Windstrike = 115356
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.bloodlust = 0
    classtable.MaelstromWeaponBuff = 344179
    classtable.FlameShockDeBuff = 188389
    classtable.UnleashFlameBuff = 0
    setSpell = nil
    ClearCDs()

    Enhancement:callaction()
    if setSpell then return setSpell end
end
