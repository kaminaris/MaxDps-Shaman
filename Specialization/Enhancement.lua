
local _, addonTable = ...

--- @type MaxDps
if not MaxDps then return end

local Shaman = addonTable.Shaman
local MaxDps = MaxDps
local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = UnitAura
local GetSpellDescription = GetSpellDescription
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local PowerTypeMaelstrom = Enum.PowerType.Maelstrom

local fd
local cooldown
local buff
local debuff
local talents
local targets
local maelstrom
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc

local className, classFilename, classId = UnitClass('player')
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or "None"
local classtable

function Shaman:Enhancement()
    fd = MaxDps.FrameData
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    maelstrom = UnitPower('player', PowerTypeMaelstrom)
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    classtable = MaxDps.SpellTable
    classtable.WindfuryTotemBuff = 327942
    classtable.PrimordialWaveBuff = 375986
    classtable.MaelstromWeaponBuff = 344179
    --setmetatable(classtable, Shaman.spellMeta)
    if targets > 1  then
        return Shaman:EnhancementMultiTarget()
    end
    return Shaman:EnhancementSingleTarget()
end

--optional abilities list


--Single-Target Rotation
function Shaman:EnhancementSingleTarget()
    --Cast Windstrike on cooldown during Ascendance.
    if MaxDps:FindSpell(classtable.Windstrike) and talents[classtable.DeeplyRootedElements] and buff[classtable.Ascendance].up and cooldown[classtable.Windstrike].ready then
        return classtable.Windstrike
    end
    --Cast Primordial Wave Icon Primordial Wave whenever available. With Tier 31 
    if MaxDps.Tier and MaxDps.Tier[31].count >= 2 and talents[classtable.PrimordialWave] and cooldown[classtable.PrimordialWave].ready then
        return classtable.PrimordialWave
    end
    --Cast Feral Spirit.
    if talents[classtable.FeralSpirit] and cooldown[classtable.FeralSpirit].ready then
        return classtable.FeralSpirit
    end
    --Cast Primordial Wave or Flame Shock if it is not active on your target.
    if talents[classtable.PrimordialWave] and not debuff[classtable.PrimordialWaveBuff].up and cooldown[classtable.PrimordialWave].ready then
        return classtable.PrimordialWave
    end
    if debuff[classtable.FlameShock].up and cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    --Cast Windfury Totem if not currently active.
    if talents[classtable.WindfuryTotem] and not buff[classtable.WindfuryTotemBuff].up and cooldown[classtable.WindfuryTotem].ready then
        return classtable.WindfuryTotem
    end
    --Cast Ascendance.
    if talents[classtable.Ascendance] and cooldown[classtable.Ascendance].ready then
        return classtable.Ascendance
    end
    --Cast Doom Winds.
    if talents[classtable.DoomWinds] and cooldown[classtable.DoomWinds].ready then
        return classtable.DoomWinds
    end
    --Cast Sundering to trigger the T30 bonus.
    if MaxDps.Tier and MaxDps.Tier[30].count >= 2 and talents[classtable.Sundering] and cooldown[classtable.Sundering].ready then
        return classtable.Sundering
    end
    --Cast Windstrike on cooldown with Ascendance active.
    if MaxDps:FindSpell(classtable.Windstrike) and talents[classtable.Ascendance] and buff[classtable.Ascendance].up and cooldown[classtable.Windstrike].ready then
        return classtable.Windstrike
    end
    --Cast Lava Lash if Hot Hand is active.
    if talents[classtable.LavaLash] and talents[classtable.HotHand] and buff[classtable.HotHand].up and cooldown[classtable.LavaLash].ready then
        return classtable.LavaLash
    end
    --Cast Elemental Blast with 5+ Maelstrom Weapon stacks and are at two charges.
    if maelstrom >= 90 and talents[classtable.ElementalBlast] and talents[classtable.MaelstromWeapon] and buff[classtable.MaelstromWeaponBuff].count >= 5 and cooldown[classtable.ElementalBlast].charges == 2 and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    --Cast Elemental Blast with 8+ Maelstrom Weapon stacks and Feral Spirit active.
    if maelstrom >= 90 and talents[classtable.ElementalBlast] and talents[classtable.MaelstromWeapon] and buff[classtable.MaelstromWeaponBuff].count >= 8 and buff[classtable.FeralSpirit].up and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    --Cast Lightning Bolt with 5+ Maelstrom Weapon stacks.
    if buff[classtable.MaelstromWeaponBuff].count >= 5 and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    --Cast Ice Strike with Doom Winds active.
    if talents[classtable.IceStrike] and talents[classtable.DoomWinds] and cooldown[classtable.IceStrike].ready then
        return classtable.IceStrike
    end
    --Cast Sundering with Doom Winds active.
    if talents[classtable.Sundering] and talents[classtable.DoomWinds] and buff[classtable.DoomWinds].up and cooldown[classtable.Sundering].ready then
        return classtable.Sundering
    end
    --Cast Crash Lightning with Doom Winds active.
    if talents[classtable.CrashLightning] and talents[classtable.DoomWinds] and buff[classtable.DoomWinds].up and cooldown[classtable.CrashLightning].ready then
        return classtable.CrashLightning
    end
    --Cast Primordial Wave.
    if talents[classtable.PrimordialWave] and cooldown[classtable.PrimordialWave].ready then
        return classtable.PrimordialWave
    end

    if talents[classtable.Hailstorm] then
        --Cast Ice Strike.
        if talents[classtable.IceStrike] and cooldown[classtable.IceStrike].ready then
            return classtable.IceStrike
        end
        --Cast Lava Lash.
        if talents[classtable.LavaLash] and cooldown[classtable.LavaLash].ready then
            return classtable.LavaLash
        end
        --Cast Frost Shock if you have Hailstorm stacks.
        if talents[classtable.FrostShock] and talents[classtable.Hailstorm] and buff[classtable.Hailstorm].up and cooldown[classtable.FrostShock].ready then
            return classtable.FrostShock
        end
        --Cast Stormstrike.
        if MaxDps:FindSpell(classtable.Stormstrike) and talents[classtable.Stormstrike] and cooldown[classtable.Stormstrike].ready then
            return classtable.Stormstrike
        end
        --Cast Sundering.
        if talents[classtable.Sundering] and cooldown[classtable.Sundering].ready then
            return classtable.Sundering
        end
    end

    if not talents[classtable.Hailstorm] then
        --Cast Lava Lash.
        if talents[classtable.LavaLash] and cooldown[classtable.LavaLash].ready then
            return classtable.LavaLash
        end
        --Cast Stormstrike.
        if MaxDps:FindSpell(classtable.Stormstrike) and talents[classtable.Stormstrike] and cooldown[classtable.Stormstrike].ready then
            return classtable.Stormstrike
        end
        --Cast Sundering.
        if talents[classtable.Sundering] and cooldown[classtable.Sundering].ready then
            return classtable.Sundering
        end
        --Cast Ice Strike.
        if talents[classtable.IceStrike] and cooldown[classtable.IceStrike].ready then
            return classtable.IceStrike
        end
        --Cast Fire Nova.
        if talents[classtable.FireNova] and cooldown[classtable.FireNova].ready then
            return classtable.FireNova
        end
        --Cast Frost Shock to fill.
        if talents[classtable.FrostShock] and cooldown[classtable.FrostShock].ready then
            return classtable.FrostShock
        end
    end

    --Cast Crash Lightning to fill.
    if talents[classtable.CrashLightning] and cooldown[classtable.CrashLightning].ready then
        return classtable.CrashLightning
    end
    --Refresh Flame Shock to fill.
    if cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    --Refresh Windfury Totem to fill.
    if talents[classtable.WindfuryTotem] and not buff[classtable.WindfuryTotemBuff].up and cooldown[classtable.WindfuryTotem].ready then
        return classtable.WindfuryTotem
    end
end

--Multiple-Target Rotation
function Shaman:EnhancementMultiTarget()
    if MaxDps.Tier and MaxDps.Tier[31].count >= 2 then
        --Cast Primordial Wave whenever available.
        if talents[classtable.PrimordialWave] and cooldown[classtable.PrimordialWave].ready then
            return classtable.PrimordialWave
        end
        --Cast Feral Spirit.
        if talents[classtable.FeralSpirit] and cooldown[classtable.FeralSpirit].ready then
            return classtable.FeralSpirit
        end
        --Cast Lava Lash with Flame Shock active and you have less than 6 active Flame Shocks.
        if talents[classtable.LavaLash] and debuff[classtable.FlameShock].up and cooldown[classtable.LavaLash].ready then
            return classtable.LavaLash
        end
        --Cast Flame Shock on an unaffected target if you have less than 6 active.
        if not debuff[classtable.FlameShock].up and cooldown[classtable.FlameShock].ready then
            return classtable.FlameShock
        end
    end
    if not MaxDps.Tier or (MaxDps.Tier and MaxDps.Tier[31].count < 2) then
        --Cast Feral Spirit.
        if talents[classtable.FeralSpirit] and cooldown[classtable.FeralSpirit].ready then
            return classtable.FeralSpirit
        end
        --Cast Lava Lash with Flame Shock active and you have less than 6 active Flame Shocks.
        if talents[classtable.LavaLash] and debuff[classtable.FlameShock].up and cooldown[classtable.LavaLash].ready then
            return classtable.LavaLash
        end
        --Cast Flame Shock on an unaffected target if you have less than 6 active.
        if not debuff[classtable.FlameShock].up and cooldown[classtable.FlameShock].ready then
            return classtable.FlameShock
        end
        --Cast Primordial Wave, ideally on a target not affected by Flame Shock.
        if talents[classtable.PrimordialWave] and not debuff[classtable.FlameShock].up and cooldown[classtable.PrimordialWave].ready then
            return classtable.PrimordialWave
        end
    end
    --Cast Lightning Bolt with 10 Maelstrom Weapon stacks, the Primordial Wave buff and as many Flame Shocks active as possible.
    if talents[classtable.MaelstromWeapon] and buff[classtable.MaelstromWeaponBuff].count >= 10 and talents[classtable.PrimordialWave] and buff[classtable.PrimordialWaveBuff].up and debuff[classtable.FlameShock].up and cooldown[classtable.LightningBolt].ready then
        return classtable.LightningBolt
    end
    --Cast Elemental Blast with 10 Maelstrom Weapon stacks, at 2 charges and against 1-3 targets.
    if maelstrom >= 90 and buff[classtable.MaelstromWeaponBuff].count >= 10 and cooldown[classtable.ElementalBlast].charges == 2 and targets <= 3 and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    --Cast Windstrike during Ascendance.
    if MaxDps:FindSpell(classtable.Windstrike) and talents[classtable.Ascendance] and buff[classtable.Ascendance].up and cooldown[classtable.Windstrike].ready then
        return classtable.Windstrike
    end
    --Cast Chain Lightning if at 10 Maelstrom Weapon stacks.
    if talents[classtable.ChainLightning] and buff[classtable.MaelstromWeaponBuff].count >= 10 and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    --Cast Windfury Totem if not currently active.
    if talents[classtable.WindfuryTotem] and not buff[classtable.WindfuryTotemBuff].up and cooldown[classtable.WindfuryTotem].ready then
        return classtable.WindfuryTotem
    end
    --Cast Doom Winds.
    if talents[classtable.DoomWinds] and cooldown[classtable.DoomWinds].ready then
        return classtable.DoomWinds
    end
    --Cast Crash Lightning if the buff is not active, or during Doom Winds.
    if (talents[classtable.CrashLightning] and not buff[classtable.CrashLightning]) or (talents[classtable.DoomWinds] and buff[classtable.DoomWinds].up) and cooldown[classtable.CrashLightning].ready then
        return classtable.CrashLightning
    end
    --Cast Sundering, try to align with Doom Winds when possible.
    if talents[classtable.Sundering] and cooldown[classtable.Sundering].ready then
        return classtable.Sundering
    end
    --Cast Fire Nova with 6 active Flame Shocks.
    if talents[classtable.FireNova] and cooldown[classtable.FireNova].ready then
        return classtable.FireNova
    end
    --Cast Lava Lash, cycling between targets to apply Lashing Flames.
    if talents[classtable.LavaLash] and cooldown[classtable.LavaLash].ready then
        return classtable.LavaLash
    end
    --Cast Fire Nova with 3 active Flame Shocks.
    if talents[classtable.FireNova] and cooldown[classtable.FireNova].ready then
        return classtable.FireNova
    end
    --Stormstrike  / Windstrike.
    if MaxDps:FindSpell(classtable.Stormstrike) and talents[classtable.Stormstrike] and cooldown[classtable.Stormstrike].ready then
        return classtable.Stormstrike
    end
    if MaxDps:FindSpell(classtable.Windstrike) and talents[classtable.Windstrike] and cooldown[classtable.Windstrike].ready then
        return classtable.Windstrike
    end
    --Cast Crash Lightning.
    if talents[classtable.CrashLightning] and cooldown[classtable.CrashLightning].ready then
        return classtable.CrashLightning
    end
    --Cast Ice Strike.
    if talents[classtable.IceStrike] and cooldown[classtable.IceStrike].ready then
        return classtable.IceStrike
    end
    --Cast Elemental Blast with 5+ Maelstrom Weapon stacks against 1-3 targets.
    if maelstrom >= 90 and buff[classtable.MaelstromWeaponBuff].count >= 5 and targets <= 3 and cooldown[classtable.ElementalBlast].ready then
        return classtable.ElementalBlast
    end
    --Cast Chain Lightning at 5+ Maelstrom Weapon stacks.
    if buff[classtable.MaelstromWeaponBuff].count >= 5 and cooldown[classtable.ChainLightning].ready then
        return classtable.ChainLightning
    end
    --Refresh Windfury Totem.
    if talents[classtable.WindfuryTotem] and not buff[classtable.WindfuryTotemBuff].up and cooldown[classtable.WindfuryTotem].ready then
        return classtable.WindfuryTotem
    end
    --Cast Flame Shock to fill.
    if cooldown[classtable.FlameShock].ready then
        return classtable.FlameShock
    end
    --Cast Frost Shock to fill.
    if cooldown[classtable.FrostShock].ready then
        return classtable.FrostShock
    end
end
