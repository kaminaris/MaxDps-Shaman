local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end
local MaxDps = MaxDps;
local UnitExists = UnitExists;
local UnitPower = UnitPower;
local GetUnitSpeed = GetUnitSpeed;
local Maelstrom = Enum.PowerType.Maelstrom;

local Shaman = addonTable.Shaman;

local EL = {
	Ascendance = 114050,
	ChainLightning = 188443,
	EarthElemental = 198103,
	EarthShock = 8042,
	Earthquake = 61882,
	EchoesOfGreatSundering = 384087,
	ElectrifiedShocks = 382086,
	ElectrifiedShocksDebuff = 382089,
	ElementalBlast = 117014,
	FireElemental = 198067,
	FlameShock = 188389,
	FrostShock = 196840,
	Icefury = 210714,
	LavaBurst = 51505,
	LightningBolt = 188196,
	LiquidMagmaTotem = 192222,
	MasterOfTheElementsAura = 260734,
	PrimalElementalist = 117013,
	PrimordialWave = 375982,
	StormElemental = 192249,
	Stormkeeper = 191634,
	SurgeOfPower = 262303,
	FlowOfPower = 385923
};

setmetatable(EL, Shaman.spellMeta);

local function getSpellCost(spellId, defaultCost)
	local cost = GetSpellPowerCost(spellId);
	if cost ~= nil then
		return cost[1].cost;
	end

	return defaultCost
end

function Shaman:Elemental()
	local fd = MaxDps.FrameData;
	fd.moving = GetUnitSpeed('player') > 0;
	fd.earthShockCost = 999999; -- if not talented, it should never be casted
	fd.elementalBlastCost = 999999; -- if not talented, it should never be casted
	local targets = MaxDps:SmartAoe();
	local talents = fd.talents;

	local maelstrom = UnitPower('player', Maelstrom);

	if talents[EL.EarthShock] then
		fd.earthShockCost = getSpellCost(EL.EarthShock, 60)
	end

	if talents[EL.ElementalBlast] then
		fd.elementalBlastCost = getSpellCost(EL.ElementalBlast, 90)
	end

	if talents[EL.Earthquake] then
		fd.earthQuakeCost = getSpellCost(EL.Earthquake, 60)
	end

	local currentSpell = fd.currentSpell
	if currentSpell == EL.ElementalBlast then
		maelstrom = maelstrom - fd.elementalBlastCost
	elseif currentSpell == EL.Earthquake then
		maelstrom = maelstrom - fd.earthQuakeCost
	elseif currentSpell == EL.Icefury then
		maelstrom = maelstrom + 25
	elseif currentSpell == EL.LightningBolt then
		maelstrom = maelstrom + 8 + (talents[EL.FlowOfPower] and 2 or 0)
	elseif currentSpell == EL.LavaBurst then
		maelstrom = maelstrom + 10 + (talents[EL.FlowOfPower] and 2 or 0)
	end

	if maelstrom < 0 then maelstrom = 0 end
	fd.maelstrom = maelstrom

	Shaman:ElementalCooldowns();

	if targets <= 1 then
		return Shaman:ElementalSingleTarget()
	else
		return Shaman:ElementalAoe();
	end
	-- Test-PR
end

function Shaman:ElementalCooldowns()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local talents = fd.talents;

	local petActive = UnitExists('pet');

	if talents[EL.FireElemental] then
		MaxDps:GlowCooldown(EL.FireElemental, (not petActive or not talents[EL.PrimalElementalist]) and cooldown[EL.FireElemental].ready);
	end

	if talents[EL.StormElemental] then
		MaxDps:GlowCooldown(EL.StormElemental, (not petActive or not talents[EL.PrimalElementalist]) and cooldown[EL.StormElemental].ready);
	end

	if talents[EL.EarthElemental] then
		MaxDps:GlowCooldown(EL.EarthElemental, (not petActive or not talents[EL.PrimalElementalist]) and cooldown[EL.EarthElemental].ready);
	end

	if talents[EL.Ascendance] then
		MaxDps:GlowCooldown(EL.Ascendance, cooldown[EL.Ascendance].ready);
	end
end

function Shaman:ElementalAoe()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local currentSpell = fd.currentSpell;
	local maelstrom = fd.maelstrom;
	local elementalBlastCost = fd.elementalBlastCost;

	if talents[EL.Stormkeeper] and cooldown[EL.Stormkeeper].ready and currentSpell ~= EL.Stormkeeper then
		return EL.Stormkeeper;
	end

	if talents[EL.LiquidMagmaTotem] and cooldown[EL.LiquidMagmaTotem].ready then
		return EL.LiquidMagmaTotem;
	end

	if talents[EL.Icefury] and cooldown[EL.Icefury].ready and currentSpell ~= EL.Icefury then
		return EL.Icefury;
	end

	if buff[EL.Icefury].up and not debuff[EL.ElectrifiedShocksDebuff].up then
		return EL.FrostShock;
	end

	if talents[EL.ElementalBlast] and cooldown[EL.ElementalBlast].ready and currentSpell ~= EL.ElementalBlast and maelstrom >= elementalBlastCost then
		return EL.ElementalBlast;
	end

	if talents[EL.Earthquake] and cooldown[EL.Earthquake].ready and maelstrom >= fd.earthQuakeCost then
		return EL.Earthquake;
	end

	return EL.ChainLightning;
end

function Shaman:ElementalSingleTarget()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local talents = fd.talents;
	local debuff = fd.debuff;
	local buff = fd.buff;
	local maelstrom = fd.maelstrom;
	local gcd = fd.gcd;
	local earthShockCost = fd.earthShockCost;
	local elementalBlastCost = fd.elementalBlastCost;
	local moving = fd.moving;
	local currentSpell = fd.currentSpell;

	if buff[EL.Ascendance].up then
		if buff[EL.EchoesOfGreatSundering].up and talents[EL.Earthquake] and cooldown[EL.Earthquake].ready and maelstrom >= fd.earthQuakeCost then
			return EL.Earthquake;
		end

		if talents[EL.ElementalBlast] then
			if currentSpell ~= EL.ElementalBlast and cooldown[EL.ElementalBlast].ready and maelstrom >= elementalBlastCost then
				return EL.ElementalBlast
			end
		elseif talents[EL.EarthShock] and maelstrom >= 90 then
			return EL.EarthShock;
		end

		if buff[EL.Ascendance].remains > gcd then
			return EL.LavaBurst;
		end
	end

	if not debuff[EL.FlameShock].up then
		if talents[EL.PrimordialWave] and cooldown[EL.PrimordialWave].ready then
			return EL.PrimordialWave;
		end

		return EL.FlameShock;
	end

	if talents[EL.EarthShock] and not talents[EL.ElementalBlast] and maelstrom >= 90 then
		return EL.EarthShock;
	end

	if talents[EL.ElementalBlast] and cooldown[EL.ElementalBlast].ready and currentSpell ~= EL.ElementalBlast and maelstrom >= elementalBlastCost then
		return EL.ElementalBlast;
	end

	if talents[EL.EarthShock] and not talents[EL.ElementalBlast] and maelstrom >= 83 then
		return EL.EarthShock;
	end

	if talents[EL.Stormkeeper] and cooldown[EL.Stormkeeper].ready and currentSpell ~= EL.Stormkeeper then
		return EL.Stormkeeper;
	end

	if buff[EL.Stormkeeper].up then
		return Shaman:ElementalStormkeeper();
	end

	if buff[EL.SurgeOfPower].up or buff[EL.MasterOfTheElementsAura].up then
		return EL.LightningBolt;
	end

	if talents[EL.LiquidMagmaTotem] and cooldown[EL.LiquidMagmaTotem].ready then
		return EL.LiquidMagmaTotem;
	end

	if talents[EL.EarthShock] and not talents[EL.ElementalBlast] and maelstrom >= earthShockCost and buff[EL.MasterOfTheElementsAura].up then
		return EL.EarthShock;
	end

	if debuff[EL.FlameShock].refreshable then
		if talents[EL.PrimordialWave] and cooldown[EL.PrimordialWave].ready then
			return EL.PrimordialWave;
		end

		return EL.FlameShock;
	end

	if talents[EL.Icefury] and cooldown[EL.Icefury].ready and currentSpell ~= EL.Icefury then
		return EL.Icefury;
	end

	if buff[EL.Icefury].up and not debuff[EL.ElectrifiedShocksDebuff].up then
		return EL.FrostShock;
	end

	if talents[EL.LavaBurst] and cooldown[EL.LavaBurst].ready and currentSpell ~= EL.LavaBurst then
		return EL.LavaBurst;
	end

	if moving then
		if cooldown[EL.FlameShock].refreshable then
			return EL.FlameShock;
		end

		return EL.FrostShock;
	end

	return EL.LightningBolt;
end

function Shaman:ElementalStormkeeper()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local talents = fd.talents;
	local debuff = fd.debuff;
	local buff = fd.buff;
	local maelstrom = fd.maelstrom;
	local gcd = fd.gcd;
	local elementalBlastCost = fd.elementalBlastCost;
	local currentSpell = fd.currentSpell;

	if not debuff[EL.ElectrifiedShocksDebuff].up and talents[EL.Icefury] and currentSpell ~= EL.Icefury and cooldown[EL.Icefury].ready then
		return EL.Icefury
	end

	if buff[EL.Icefury].up and (not debuff[EL.ElectrifiedShocksDebuff].up or debuff[EL.ElectrifiedShocksDebuff].remains < 2 * gcd) then
		return EL.FrostShock
	end

	if talents[EL.LavaBurst] and cooldown[EL.LavaBurst].ready and currentSpell ~= EL.LavaBurst then
		return EL.LavaBurst;
	end

	if talents[EL.ElementalBlast] and cooldown[EL.ElementalBlast].ready and currentSpell ~= EL.ElementalBlast and maelstrom >= elementalBlastCost then
		return EL.ElementalBlast;
	end

	return EL.LightningBolt
end