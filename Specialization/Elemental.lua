
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
local timetodie
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

function Shaman:Elemental()
    fd = MaxDps.FrameData
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    timetodie = fd.timetodie or 0
    targets = MaxDps:SmartAoe()
    maelstrom = UnitPower('player', PowerTypeMaelstrom)
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    classtable = MaxDps.SpellTable
    classtable.LavaBeam = 114074
    classtable.LavaSurgeBuff = 77762
    classtable.MasteroftheElementsBuff = 260734
    classtable.PowerofTheMaelstromBuff = 191877
    --setmetatable(classtable, Shaman.spellMeta)
    if targets > 1  then
        return Shaman:ElementalMultiTarget()
    end
    return Shaman:ElementalSingleTarget()
end

--optional abilities list


--Single-Target Rotation
function Shaman:ElementalSingleTarget()
    if MaxDps.tier and MaxDps.tier[31].count >= 4 then
        --Cast Fire Elemental.
        if talents[classtable.FireElemental] and cooldown[classtable.FireElemental].ready then
            return classtable.FireElemental
        end
        --Cast Primordial Wave if Splintered Elements is not up.
        if talents[classtable.PrimordialWave] and not buff[classtable.SplinteredElements].up and cooldown[classtable.PrimordialWave].ready then
            return classtable.PrimordialWave
        end
        --Cast Flame Shock during the pandemic window if Primordial Wave will not be available in time.
        if talents[classtable.PrimordialWave] and cooldown[classtable.PrimordialWave].duration >= 6 and cooldown[classtable.FlameShock].ready then
            return classtable.FlameShock
        end
        --Cast Stormkeeper when you have at least 116 Maelstrom (so you can always boost both bolts with Surge of Power)
        if talents[classtable.Stormkeeper] and maelstrom >= 116 and cooldown[classtable.Stormkeeper].ready then
            return classtable.Stormkeeper
        end
        --Cast Lava Burst if either Lava Surge or Ascendance is up.
        if talents[classtable.LavaBurst] and (talents[classtable.LavaSurge] and buff[classtable.LavaSurgeBuff].up) or (talents[classtable.Ascendance] and buff[classtable.Ascendance].up) and cooldown[classtable.LavaBurst].ready then
            return classtable.LavaBurst
        end
        --Cast Elemental Blast if Master of the Elements is up.
        if talents[classtable.ElementalBlast] and maelstrom >= 90 and (talents[classtable.MasteroftheElements] and buff[classtable.MasteroftheElementsBuff].up) and cooldown[classtable.ElementalBlast].ready then
            return classtable.ElementalBlast
        end
        --Cast Lava Burst.
        if talents[classtable.LavaBurst] and cooldown[classtable.LavaBurst].ready then
            return classtable.LavaBurst
        end
        --Cast Frost Shock if Icefury buffs are available and Master of the Elements is up.
        if talents[classtable.FrostShock] and (talents[classtable.Icefury] and buff[classtable.Icefury].up) and (talents[classtable.MasteroftheElements] and buff[classtable.MasteroftheElementsBuff].up) and cooldown[classtable.FrostShock].ready then
            return classtable.FrostShock
        end
        --Cast Lightning Bolt if Surge of Power is available.
        if (talents[classtable.SurgeofPower] and buff[classtable.SurgeofPower].up) and cooldown[classtable.LightningBolt].ready then
            return classtable.LightningBolt
        end
        --Cast Icefury.
        if talents[classtable.Icefury] and cooldown[classtable.Icefury].ready then
            return classtable.Icefury
        end
        --Cast Elemental Blast.
        if talents[classtable.ElementalBlast] and maelstrom >= 90 and cooldown[classtable.ElementalBlast].ready then
            return classtable.ElementalBlast
        end
        --Cast Frost Shock if Icefury buffs are available.
        if talents[classtable.FrostShock] and (talents[classtable.Icefury] and buff[classtable.Icefury].up) and cooldown[classtable.FrostShock].ready then
            return classtable.FrostShock
        end
        --Cast Lightning Bolt.
        if cooldown[classtable.LightningBolt].ready then
            return classtable.LightningBolt
        end
        --Cast Flame Shock and if really needed Frost Shock while moving.
        if cooldown[classtable.FlameShock].ready then
            return classtable.FlameShock
        end
        if talents[classtable.FrostShock] and cooldown[classtable.FrostShock].ready then
            return classtable.FrostShock
        end
    end
    if not MaxDps.tier or (MaxDps.tier and MaxDps.tier[31].count < 4) then
        --Cast Primordial Wave whenever available.
        if talents[classtable.PrimordialWave] and cooldown[classtable.PrimordialWave].ready then
            return classtable.PrimordialWave
        end
        --Apply or Refresh Flame Shock if it will expire in under 6 seconds, unless
        --Primordial Wave will be available before or immediately after Flame Shock expires.
        --a Surge of Power proc is available
        if (not debuff[classtable.FlameShock] or debuff[classtable.FlameShock].duration <= 5 and cooldown[classtable.FlameShock].ready) or (talents[classtable.PrimordialWave] and cooldown[classtable.PrimordialWave].duration >= debuff[classtable.FlameShock].duration ) or buff[classtable.SurgeofPower].up then
            return classtable.FlameShock
        end
        --Cast Fire Elemental if it is off cooldown. Always pair your Elemental with Haste buffs (e.g. Bloodlust/Heroism) if possible, but do not sacrifice an extra usage by delaying your elemental.
        if talents[classtable.FireElemental] and cooldown[classtable.FireElemental].ready then
            return classtable.FireElemental
        end
        --Cast Storm Elemental if it is off cooldown. Always pair your Elemental with Haste buffs (e.g. Bloodlust/Heroism) if possible, but do not sacrifice an extra usage by delaying your elemental.
        if talents[classtable.StormElemental] and cooldown[classtable.StormElemental].ready then
            return classtable.StormElemental
        end
        --Make your Fire Elemental cast Meteor.
        --if talents[classtable.FireElemental] and cooldown[classtable.Meteor].ready then
        --    return classtable.Meteor
        --end
        --Make your Storm Elemental cast Tempest once your Elemental has used Call Lightning (not before).
        --if talents[classtable.StormElemental] and not cooldown[classtable.CallLightning].ready and cooldown[classtable.Tempest].ready then
        --    return classtable.Tempest
        --end
        --Cast Lightning Bolt if Surge of Power is active.
        if talents[classtable.SurgeofPower] and buff[classtable.SurgeofPower].up and cooldown[classtable.LightningBolt].ready then
            return classtable.LightningBolt
        end
        --Cast Lava Burst whenever you gain a Lava Surge proc, even if doing so will make you overcap Maelstrom.
        if talents[classtable.LavaBurst] and talents[classtable.LavaSurge] and buff[classtable.LavaSurgeBuff].up and cooldown[classtable.LavaBurst].ready then
            return classtable.LavaBurst
        end
        --Cast Ascendance.
        if talents[classtable.Ascendance] and cooldown[classtable.Ascendance].ready then
            return classtable.Ascendance
        end
        --When in Ascendance form cast Elemental Blast whenever available, but always alternate it with Lava Burst.
        --When in Ascendance form, cast Lava Burst.
        if talents[classtable.Ascendance] and buff[classtable.Ascendance].up and cooldown[classtable.LavaBurst].ready then
            return classtable.Ascendance
        end
        --When in Ascendance form, cast Lava Burst.
        if talents[classtable.Ascendance] and buff[classtable.Ascendance].up and cooldown[classtable.LavaBurst].ready then
            return classtable.Ascendance
        end
        --Cast Stormkeeper whenever you have 81 or more Maelstrom. You must then cast the following spells in that order:
        if talents[classtable.Stormkeeper] and maelstrom >= 81 and cooldown[classtable.Stormkeeper].ready then
            return classtable.Stormkeeper
        end
            --Cast an Icefury-empowered Frost Shock
            if talents[classtable.Stormkeeper] and buff[classtable.Icefury].up and cooldown[classtable.FrostShock].ready then
                return classtable.FrostShock
            end
            --Cast Lava Burst
            if talents[classtable.LavaBurst] and cooldown[classtable.LavaBurst].ready then
                return classtable.LavaBurst
            end
            --Cast Elemental Blast
            if talents[classtable.ElementalBlast] and maelstrom >= 90 and cooldown[classtable.ElementalBlast].ready then
                return classtable.ElementalBlast
            end
            --Cast Lightning Bolt
            if cooldown[classtable.LightningBolt].ready then
                return classtable.LightningBolt
            end
            --Cast an Icefury-empowered Frost Shock
            if talents[classtable.Stormkeeper] and buff[classtable.Icefury].up and cooldown[classtable.FrostShock].ready then
                return classtable.FrostShock
            end
            --Cast Lava Burst
            if talents[classtable.LavaBurst] and cooldown[classtable.LavaBurst].ready then
                return classtable.LavaBurst
            end
            --Cast Elemental Blast
            if talents[classtable.ElementalBlast] and maelstrom >= 90 and cooldown[classtable.ElementalBlast].ready then
                return classtable.ElementalBlast
            end
            --Cast Lightning Bolt
            if cooldown[classtable.LightningBolt].ready then
                return classtable.LightningBolt
            end
        --Cast Lava Burst whenever you gain a Lava Surge proc.
        if talents[classtable.LavaBurst] and talents[classtable.LavaSurge] and buff[classtable.LavaSurgeBuff].up and cooldown[classtable.LavaBurst].ready then
            return classtable.LavaBurst
        end
        --Cast Elemental Blast whenever you have the Maelstrom for it, but never cast it twice in a row. Use Nature's Swiftness when available to make it an instant cast.
        if cooldown[classtable.ElementalBlast].ready and maelstrom >= 90 and cooldown[classtable.NaturesSwiftness].ready then
            return classtable.NaturesSwiftness
        end
        if talents[classtable.ElementalBlast] and maelstrom >= 90 and cooldown[classtable.ElementalBlast].ready then
            return classtable.ElementalBlast
        end
        --Cast Liquid Magma Totem whenever available. Delay the usage if multiple stacked targets will be present within the span of its cooldown.
        if talents[classtable.LiquidMagmaTotem] and cooldown[classtable.LiquidMagmaTotem].ready then
            return classtable.LiquidMagmaTotem
        end
        --Cast Elemental Blast if you have enough Maelstrom and the Master of the Elements buff is active.
        if talents[classtable.ElementalBlast] and maelstrom >= 90 and buff[classtable.MasteroftheElementsBuff].up and cooldown[classtable.ElementalBlast].ready then
            return classtable.ElementalBlast
        end
        --Cast Frost Shock if any Icefury buff is active and Electrified Shocks is absent or about to expire.
        if talents[classtable.FrostShock] and buff[classtable.Icefury].up and (not buff[classtable.ElectrifiedShocks].up or buff[classtable.ElectrifiedShocks].duration <= 2) and cooldown[classtable.FrostShock].ready then
            return classtable.FrostShock
        end
        --Cast Lava Burst whenever available.
        if talents[classtable.LavaBurst] and cooldown[classtable.LavaBurst].ready then
            return classtable.LavaBurst
        end
        --Cast Icefury.
        if talents[classtable.Icefury] and cooldown[classtable.Icefury].ready then
            return classtable.Icefury
        end
        --Cast Lightning Bolt if Storm Elemental is active.
        if buff[classtable.StormElemental].up and cooldown[classtable.LightningBolt].ready then
            return classtable.LightningBolt
        end
        --Cast Lightning Lasso
        if talents[classtable.LightningLasso] and cooldown[classtable.LightningLasso].ready then
            return classtable.LightningLasso
        end
        --Cast Lightning Bolt as a filler on a single target.
        if cooldown[classtable.LightningBolt].ready then
            return classtable.LightningBolt
        end
        --Cast Flame Shock as a filler while moving, unless Primordial Wave will become available
        if cooldown[classtable.PrimordialWave].duration >=2 and cooldown[classtable.FlameShock].ready then
            return classtable.FlameShock
        end
        --Cast Frost Shock as a filler while moving.
        if cooldown[classtable.FrostShock].ready then
            return classtable.FrostShock
        end
    end
end

function Shaman:ElementalMultiTarget()
    if not MaxDps.tier or (MaxDps.tier and MaxDps.tier[31].count < 4) then
        --Cast Fire Elemental.
        if talents[classtable.FireElemental] and cooldown[classtable.FireElemental].ready then
            return classtable.FireElemental
        end
        --Cast Storm Elemental.
        if talents[classtable.StormElemental] and cooldown[classtable.StormElemental].ready then
            return classtable.StormElemental
        end
        --Cast Meteor.
        --if talents[classtable.FireElemental] and cooldown[classtable.Meteor].ready then
        --    return classtable.Meteor
        --end
        --Cast Tempest once your Elemental has used Call Lightning (not before).
        --if talents[classtable.StormElemental] and not cooldown[classtable.CallLightning].ready and cooldown[classtable.Tempest].ready then
        --    return classtable.Tempest
        --end
        --When your Fire Elemental is out, cast Flame Shock on targets unafflicted by it on cooldown as long as they will live for most of the duration.
        if buff[classtable.FireElemental].up and not debuff[classtable.FireElemental].up and cooldown[classtable.FlameShock].ready then
            return classtable.FlameShock
        end
        --Cast Liquid Magma Totem then cast Primordial Wave and Flame Shock on targets not afflicted by the Flame Shock DoT. If there is no such 5th target for your Flame Shock, skip that last cast. Follow this with a Lava Burst. Use Totemic Recall before using another totem to have Liquid Magma Totem back faster.
        if talents[classtable.LiquidMagmaTotem] and cooldown[classtable.LiquidMagmaTotem].ready then
            return classtable.LiquidMagmaTotem
        end
        if talents[classtable.PrimordialWave] and cooldown[classtable.PrimordialWave].ready then
            return classtable.PrimordialWave
        end
        if buff[classtable.FireElemental].up and not debuff[classtable.FlameShock].up and cooldown[classtable.FlameShock].ready then
            return classtable.FlameShock
        end
        --Cast Stormkeeper on cooldown unless there are 6+ targets, in which case, you want to have enough Maelstrom to immediately cast the next appropriate spender.
        if talents[classtable.Stormkeeper] and maelstrom >= 81 and targets <= 6 and cooldown[classtable.Stormkeeper].ready then
            return classtable.Stormkeeper
        end
        --If all targets are split, keep Flame Shock up on as many of them as you can as long as they will live for the whole duration.
        if not debuff[classtable.FlameShock].up and timetodie >= 6 and cooldown[classtable.FlameShock].ready then
            return classtable.FlameShock
        end
        --If no more than 3 targets are cleavable and they will not die soon, try using your Surge of Power procs with Flame Shock.
        if targets <= 3 and timetodie >= 6 and buff[classtable.SurgeofPower].up and cooldown[classtable.FlameShock].ready then
            return classtable.FlameShock
        end
        --If no more than 2 targets are cleavable and will either die soon or have a long duration Flame Shocks on them, try using your Surge of Power procs with Lightning Bolt. This is also valid if there is a priority target in a 3-target cleave situation.
        if targets <= 2 and (timetodie <= 6 or debuff[classtable.FlameShock].duration >= 10) and buff[classtable.SurgeofPower].up and cooldown[classtable.FlameShock].ready then
            return classtable.FlameShock
        end
        --Cast Lava Burst if Lava Surge is up.
        if talents[classtable.LavaBurst] and talents[classtable.LavaSurge] and buff[classtable.LavaSurgeBuff].up and cooldown[classtable.LavaBurst].ready then
            return classtable.LavaBurst
        end
        --Cast Elemental Blast to empower your next Earthquake with Echoes of Great Sundering.
        if talents[classtable.ElementalBlast] and maelstrom >= 90 and cooldown[classtable.ElementalBlast].ready then
            return classtable.ElementalBlast
        end
        --Cast Earthquake.
        if talents[classtable.Earthquake] and maelstrom >= 60 and cooldown[classtable.Earthquake].ready then
            return classtable.Earthquake
        end
        --Cast Lava Beam when in Ascendance form if Power of the Maelstrom is available.
        --Cast Lava Beam when in Ascendance form if Power of the Maelstrom is available.
        if MaxDps:FindSpell(classtable.LavaBeam) and (talents[classtable.Ascendance] and buff[classtable.Ascendance].up and talents[classtable.PowerofTheMaelstrom] and buff[classtable.PowerofTheMaelstromBuff].up and cooldown[classtable.LavaBeam].ready) then
            return classtable.LavaBeam
        end
        --Cast Lava Beam when in Ascendance form if Master of the Elements is available.
        --Cast Lava Beam when in Ascendance form if Master of the Elements is available.
        if MaxDps:FindSpell(classtable.LavaBeam) and (talents[classtable.Ascendance] and buff[classtable.Ascendance].up and talents[classtable.MasteroftheElements] and buff[classtable.MasteroftheElementsBuff].up and cooldown[classtable.LavaBeam].ready) then
            return classtable.LavaBeam
        end
        --Cast Chain Lightning if Power of the Maelstrom is available.
        if MaxDps:FindSpell(classtable.ChainLightning) and (talents[classtable.PowerofTheMaelstrom] and buff[classtable.PowerofTheMaelstromBuff].up and cooldown[classtable.ChainLightning].ready) then
            return classtable.ChainLightning
        end
        --Cast Lava Burst if there are 3 or fewer targets, and if a Flame Shock is up, ideally right before using Stormkeeper-boosted abilities, or an Echoes of Great Sundering Earthquake.
        if talents[classtable.LavaBurst] and targets <= 3 and cooldown[classtable.LavaBurst].ready then
            return classtable.LavaBurst
        end
        --Cast Lava Beam when in Ascendance form.
        --Cast Lava Beam when in Ascendance form.
        if MaxDps:FindSpell(classtable.LavaBeam) and (talents[classtable.Ascendance] and buff[classtable.Ascendance].up and cooldown[classtable.LavaBeam].ready) then
            return classtable.LavaBeam
        end
        --Cast Icefury on cooldown. If there are more than 4 targets and you will not need to move, you can skip this.
        if talents[classtable.Icefury] and targets < 4 and cooldown[classtable.Icefury].ready then
            return classtable.Icefury
        end
        --Use an Icefury-empowered Frost Shock if the Electrified Shocks debuff is not present or will expire before the next cast. If there are many targets, you will not need to move, and Stormkeeper will not be used; you can skip this.
        if talents[classtable.Icefury] and (not debuff[classtable.ElectrifiedShocks].up or debuff[classtable.ElectrifiedShocks].duration <= 2) and cooldown[classtable.Icefury].ready then
            return classtable.Icefury
        end
        --Cast Chain Lightning.
        if MaxDps:FindSpell(classtable.ChainLightning) and cooldown[classtable.ChainLightning].ready then
            return classtable.ChainLightning
        end
        --Cast Flame Shock when moving
        if cooldown[classtable.FlameShock].ready then
            return classtable.FlameShock
        end
    end
    if MaxDps.tier and MaxDps.tier[31].count >= 4 then
        --Cast Fire Elemental if Ascendance is not up.
        if talents[classtable.FireElemental] and talents[classtable.Ascendance] and not buff[classtable.Ascendance].up and cooldown[classtable.FireElemental].ready then
            return classtable.FireElemental
        end
        --Cast Stormkeeper if Ascendance is up and a previous Stormkeeper buff is not available (for people still using Shaman Elemental 10.1 Class Set 2pc Shaman Elemental 10.1 Class Set 2pc).
        if talents[classtable.FireElemental] and talents[classtable.Ascendance] and buff[classtable.Ascendance].up and not buff[classtable.Stormkeeper].up and cooldown[classtable.Stormkeeper].ready then
            return classtable.Stormkeeper
        end
        --Cast Totemic Recall if Ascendance is not up and Liquid Magma Totem is on cooldown for a long time, depending on how long adds will live.
        --Cast Liquid Magma Totem if Ascendance is not up.
        if talents[classtable.LiquidMagmaTotem] and talents[classtable.Ascendance] and not buff[classtable.Ascendance].up and cooldown[classtable.LiquidMagmaTotem].ready then
            return classtable.LiquidMagmaTotem
        end
        --Cast Primordial Wave on whichever target is closest to losing the Flame Shock effect, unless it is close to dying.
        if talents[classtable.PrimordialWave] and timetodie >= 6 and cooldown[classtable.PrimordialWave].ready then
            return classtable.PrimordialWave
        end
        --If specced into Surge of Power, cast Flame Shock when it is up on whichever target has the lowest duration Flame Shock effect, unless it is close to dying.
        if talents[classtable.SurgeofPower] and timetodie >= 6 and cooldown[classtable.FlameShock].ready then
            return classtable.FlameShock
        end
        --Cast Lava Beam if Ascendance and Master of the Elements are up.
        if MaxDps:FindSpell(classtable.LavaBeam) and (talents[classtable.Ascendance] and buff[classtable.Ascendance].up and talents[classtable.MasteroftheElements] and buff[classtable.MasteroftheElementsBuff].up and cooldown[classtable.LavaBeam].ready) then
            return classtable.LavaBeam
        end
        --Cast Lava Burst if Ascendance is up.
        if talents[classtable.LavaBurst] and talents[classtable.Ascendance] and buff[classtable.Ascendance].up and cooldown[classtable.LavaBurst].ready then
            return classtable.LavaBurst
        end
        --Cast Earthquake if Master of the Elements is up, you have 15 or more stacks of Magma Chamber and Lava Surge is not up
        if talents[classtable.Earthquake] and talents[classtable.MasteroftheElements] and buff[classtable.MasteroftheElementsBuff].up and buff[classtable.MagmaChamber].count >= 15 and not buff[classtable.LavaSurgeBuff].up and maelstrom >= 60 and cooldown[classtable.Earthquake].ready then
            return classtable.Earthquake
        end
        --Cast Chain Lightning if Master of the Elements is up but neither Ascendance or Lava Surge are up
        if MaxDps:FindSpell(classtable.ChainLightning) and (talents[classtable.MasteroftheElements] and buff[classtable.MasteroftheElementsBuff].up and ((talents[classtable.Ascendance] and not buff[classtable.Ascendance].up) and not buff[classtable.LavaSurgeBuff].up) and cooldown[classtable.ChainLightning].ready) then
            return classtable.ChainLightning
        end
        --Cast Lava Burst.
        if talents[classtable.LavaBurst] and cooldown[classtable.LavaBurst].ready then
            return classtable.LavaBurst
        end
        --Cast Earthquake.
        if talents[classtable.Earthquake] and maelstrom >= 60 and cooldown[classtable.Earthquake].ready then
            return classtable.Earthquake
        end
        --Cast Chain Lightning.
        if MaxDps:FindSpell(classtable.ChainLightning) and cooldown[classtable.ChainLightning].ready then
            return classtable.ChainLightning
        end
        --Cast Flame Shock on whichever target is closest to losing its DoT effect.
        if cooldown[classtable.FlameShock].ready then
            return classtable.FlameShock
        end
    end
end
