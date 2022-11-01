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
	SurgeOfPower = 262303
};

setmetatable(EL, Shaman.spellMeta);

function Shaman:Elemental()
	local fd = MaxDps.FrameData;
	fd.moving = GetUnitSpeed('player') > 0;
	fd.maelstrom = UnitPower('player', Maelstrom);
	fd.earthShockCost = 999999; -- if not talented, it should never be casted
	fd.elementalBlastCost = 999999; -- if not talented, it should never be casted
	local targets = MaxDps:SmartAoe();
	local talents = fd.talents;

	if talents[EL.EarthShock] then
		local earthShockCost = GetSpellPowerCost(EL.EarthShock);
		if earthShockCost ~= nil then
			fd.earthShockCost = earthShockCost[1].cost;
		end
	end

	if talents[EL.ElementalBlast] then
		local elementalBlastCost = GetSpellPowerCost(EL.ElementalBlast);
		if elementalBlastCost ~= nil then
			fd.elementalBlastCost = elementalBlastCost[1].cost;
		end
	end

	Shaman:ElementalCooldowns();

	if targets <= 1 then
		return Shaman:ElementalSingleTarget();
	else
		return Shaman:ElementalAoe();
	end
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
	local talents = fd.talents;

	if talents[EL.Stormkeeper] and cooldown[EL.Stormkeeper].ready then
		return EL.Stormkeeper;
	end

	if talents[EL.LiquidMagmaTotem] and cooldown[EL.LiquidMagmaTotem].ready then
		return EL.LiquidMagmaTotem;
	end

	if cooldown[EL.Earthquake] then
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
		if buff[EL.EchoesOfGreatSundering].up and cooldown[EL.Earthquake].ready then
			return EL.Earthquake;
		end

		if talents[EL.EarthShock] and maelstrom >= 90 then
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

	if talents[EL.EarthShock] and maelstrom >= 90 then
		return EL.EarthShock;
	end

	if talents[EL.ElementalBlast] and cooldown[EL.ElementalBlast].ready and currentSpell ~= EL.ElementalBlast and maelstrom >= elementalBlastCost then
		return EL.ElementalBlast;
	end

	if talents[EL.EarthShock] and maelstrom >= 83 then
		return EL.EarthShock;
	end

	if talents[EL.Stormkeeper] and cooldown[EL.Stormkeeper].ready and currentSpell ~= EL.Stormkeeper then
		return EL.Stormkeeper;
	end

	if buff[EL.Stormkeeper].up then
		return EL.LightningBolt;
	end

	if buff[EL.SurgeOfPower].up or buff[EL.MasterOfTheElementsAura].up then
		return EL.LightningBolt;
	end

	if talents[EL.LiquidMagmaTotem] and cooldown[EL.LiquidMagmaTotem].ready then
		return EL.LiquidMagmaTotem;
	end

	if talents[EL.EarthShock] and maelstrom >= earthShockCost and buff[EL.MasterOfTheElementsAura].up then
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

	if buff[EL.Icefury].up and buff[EL.ElectrifiedShocks].up and buff[EL.ElectrifiedShocks].remains < 1.1 * gcd then
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