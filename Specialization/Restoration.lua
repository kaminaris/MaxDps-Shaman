
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

function Shaman:Restoration()
    fd = MaxDps.FrameData
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    classtable = MaxDps.SpellTable
	classtable.LavaSurgeBuff = 77762
	setmetatable(classtable, Shaman.spellMeta)
    if targets >= 3  then
        return Shaman:RestorationMultiTarget()
    end
    return Shaman:RestorationSingleTarget()
end

--optional abilities list


--Single-Target Rotation
function Shaman:RestorationSingleTarget()
	if not debuff[classtable.FlameShock].up or debuff[classtable.FlameShock].refreshable and cooldown[classtable.FlameShock].ready then
		return classtable.FlameShock
	end
	if talents[classtable.Stormkeeper] and cooldown[classtable.Stormkeeper].ready then
		return classtable.Stormkeeper
	end
	if cooldown[classtable.LavaBurst].ready then
		return classtable.LavaBurst
	end
	if cooldown[classtable.LightningBolt].ready then
		return classtable.LightningBolt
	end
end

--Multiple-Target Rotation
function Shaman:RestorationMultiTarget()
	if not debuff[classtable.FlameShock].up or debuff[classtable.FlameShock].refreshable and cooldown[classtable.FlameShock].ready then
		return classtable.FlameShock
	end
	if talents[classtable.AcidRain] and cooldown[classtable.HealingRain].ready then
		return classtable.HealingRain
	end
	if talents[classtable.LavaSurge] and buff[classtable.LavaSurgeBuff].up and cooldown[classtable.LavaBurst].ready then
		return classtable.LavaBurst
	end
	if talents[classtable.Stormkeeper] and cooldown[classtable.Stormkeeper].ready then
		return classtable.Stormkeeper
	end
	if cooldown[classtable.ChainLightning].ready then
		return classtable.ChainLightning
	end
	if cooldown[classtable.LavaBurst].ready then
		return classtable.LavaBurst
	end
	if cooldown[classtable.LightningBolt].ready then
		return classtable.LightningBolt
	end
end
