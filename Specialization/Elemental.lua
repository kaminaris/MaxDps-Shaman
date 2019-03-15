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
	TotemMastery        = 210643,
	FireElemental       = 198067,
	ElementalBlast      = 117014,
	Bloodlust           = 2825,
	WindShear           = 57994,
	StormElemental      = 192249,
	EarthElemental      = 198103,
	Stormkeeper         = 191634,
	Ascendance          = 114050,
	LiquidMagmaTotem    = 192222,
	FlameShock          = 188389,
	Earthquake          = 61882,
	LavaBurst           = 51505,
	LavaSurge           = 77756,
	LavaSurge2          = 77762,
	ChainLightning      = 188443,
	FrostShock          = 196840,
	MasterOfTheElements = 16166,
	ExposedElements     = 260694,
	LightningBolt       = 188196,
	EarthShock          = 8042,
	Icefury             = 210714,

	ResonanceTotem      = 202192,
	LavaBeam            = 114074,
	WindGust            = 263806,
};

setmetatable(EL, Shaman.spellMeta);


function Shaman:Elemental()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell = fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell;

	local spellHistory = fd.spellHistory;
	local pet = UnitExists('pet');
	local maelstrom = UnitPower('player', Maelstrom);
	local targets = MaxDps:SmartAoe();
	local moving = GetUnitSpeed('player') > 0;

	if currentSpell == EL.LavaBurst then
		maelstrom = maelstrom + 10;
	elseif currentSpell == EL.LightningBolt then
		maelstrom = maelstrom + 8;
	elseif currentSpell == EL.Icefury then
		maelstrom = maelstrom + 15;
	elseif currentSpell == EL.ChainLightning or currentSpell == EL.LavaBeam then
		maelstrom = maelstrom + 4 * (targets - 1);
	end

	local canLavaBurst = buff[EL.LavaSurge].up or (currentSpell~= EL.LavaBurst and cooldown[EL.LavaBurst].ready)
		or (currentSpell == EL.LavaBurst and cooldown[EL.LavaBurst].charges >= 2);

	fd.targets, fd.maelstrom, fd.moving, fd.canLavaBurst = targets, maelstrom, moving, canLavaBurst;

	MaxDps:GlowCooldown(EL.Ascendance, talents[EL.Ascendance] and cooldown[EL.Ascendance].ready);

	if talents[EL.StormElemental] then
		MaxDps:GlowCooldown(EL.StormElemental, not pet and cooldown[EL.StormElemental].ready);
	else
		MaxDps:GlowCooldown(EL.FireElemental, not pet and cooldown[EL.FireElemental].ready);
	end

	MaxDps:GlowCooldown(EL.EarthElemental, not pet and cooldown[EL.EarthElemental].ready);

	-- totem_mastery,if=talent.totem_mastery.enabled&buff.resonance_totem.remains<2;
	local tmRemains = Shaman:TotemMastery(EL.TotemMastery);
	if talents[EL.TotemMastery] and tmRemains < 5 and spellHistory[1] ~= EL.TotemMastery then
		return EL.TotemMastery;
	end

	-- earth_elemental,if=cooldown.fire_elemental.remains<120&!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<120&talent.storm_elemental.enabled;
	--if cooldown[EL.FireElemental].remains < 120 and not talents[EL.StormElemental] or cooldown[EL.StormElemental].remains < 120 and talents[EL.StormElemental] then
	--	return EL.EarthElemental;
	--end

	if targets > 2 then
		return Shaman:ElementalAoe();
	end

	return Shaman:ElementalSingleTarget();
end

function Shaman:ElementalAoe()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, targets, maelstrom, moving, canLavaBurst =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.targets, fd.maelstrom, fd.moving, fd.canLavaBurst;

	-- its the same condition anyways
	local chainLightning = MaxDps:FindSpell(EL.ChainLightning) and EL.ChainLightning or EL.LavaBeam;

	local lavaSurge = buff[EL.LavaSurge].up or buff[EL.LavaSurge2].up;

	-- stormkeeper,if=talent.stormkeeper.enabled;
	if talents[EL.Stormkeeper] and cooldown[EL.Stormkeeper].ready then
		return EL.Stormkeeper;
	end

	-- liquid_magma_totem,if=talent.liquid_magma_totem.enabled;
	if talents[EL.LiquidMagmaTotem] and cooldown[EL.LiquidMagmaTotem].ready then
		return EL.LiquidMagmaTotem;
	end

	-- flame_shock,if=spell_targets.chain_lightning<4,target_if=refreshable;
	if targets < 4 and debuff[EL.FlameShock].refreshable and cooldown[EL.FlameShock].ready then
		return EL.FlameShock;
	end

	-- earthquake;
	if maelstrom >= 60 then
		return EL.Earthquake;
	end

	-- lava_burst,if=(buff.lava_surge.up|buff.ascendance.up)&spell_targets.chain_lightning<4;
	if canLavaBurst and ((lavaSurge or buff[EL.Ascendance].up) and targets < 4) then
		return EL.LavaBurst;
	end

	-- elemental_blast,if=talent.elemental_blast.enabled&spell_targets.chain_lightning<4;
	if talents[EL.ElementalBlast] and
		currentSpell~= EL.ElementalBlast and
		cooldown[EL.ElementalBlast].ready and
		targets < 4
	then
		return EL.ElementalBlast;
	end

	-- lava_burst,moving=1,if=talent.ascendance.enabled;
	if moving and canLavaBurst and talents[EL.Ascendance] then
		return EL.LavaBurst;
	end

	-- flame_shock,moving=1,target_if=refreshable;
	if moving and debuff[EL.FlameShock].refreshable and cooldown[EL.FlameShock].ready then
		return EL.FlameShock;
	end

	-- frost_shock,moving=1;
	if moving then
		return EL.FrostShock;
	end

	-- chain_lightning;
	-- Chain Lightning or Lava Beam
	return chainLightning;
end

function Shaman:ElementalSingleTarget()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell, gcd, targets, maelstrom, moving, canLavaBurst=
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell, fd.gcd, fd.targets, fd.maelstrom, fd.moving, fd.canLavaBurst;

	local lavaSurge = buff[EL.LavaSurge].up or buff[EL.LavaSurge2].up;
	local chainLightning = MaxDps:FindSpell(EL.ChainLightning) and EL.ChainLightning or EL.LavaBeam;

	-- flame_shock,if=!ticking|dot.flame_shock.remains<=gcd|talent.ascendance.enabled&dot.flame_shock.remains<(cooldown.ascendance.remains+buff.ascendance.duration)&cooldown.ascendance.remains<4&(!talent.storm_elemental.enabled|talent.storm_elemental.enabled&cooldown.storm_elemental.remains<120);
	if cooldown[EL.FlameShock].ready and (not debuff[EL.FlameShock].up or debuff[EL.FlameShock].remains <= gcd or talents[EL.Ascendance] and
		debuff[EL.FlameShock].remains < (cooldown[EL.Ascendance].remains + buff[EL.Ascendance].duration) and
		cooldown[EL.Ascendance].remains < 4 and
		(not talents[EL.StormElemental] or talents[EL.StormElemental] and cooldown[EL.StormElemental].remains < 120))
	then
		return EL.FlameShock;
	end

	-- elemental_blast,if=talent.elemental_blast.enabled&(talent.master_of_the_elements.enabled&buff.master_of_the_elements.up&maelstrom<60|!talent.master_of_the_elements.enabled);
	if talents[EL.ElementalBlast] and currentSpell ~= EL.ElementalBlast and (
		talents[EL.MasterOfTheElements] and
			buff[EL.MasterOfTheElements].up and
			maelstrom < 60 or not talents[EL.MasterOfTheElements]
	) then
		return EL.ElementalBlast;
	end

	-- stormkeeper,if=talent.stormkeeper.enabled&(raid_event.adds.count<3|raid_event.adds.in>50);
	if talents[EL.Stormkeeper] and cooldown[EL.Stormkeeper].ready then
		return EL.Stormkeeper;
	end

	-- liquid_magma_totem,if=talent.liquid_magma_totem.enabled&(raid_event.adds.count<3|raid_event.adds.in>50);
	if talents[EL.LiquidMagmaTotem] and cooldown[EL.LiquidMagmaTotem].ready then
		return EL.LiquidMagmaTotem;
	end

	-- earthquake,if=active_enemies>1&spell_targets.chain_lightning>1&!talent.exposed_elements.enabled;
	if targets > 1 and not talents[EL.ExposedElements] and maelstrom >= 60 then
		return EL.Earthquake;
	end

	-- lightning_bolt,if=talent.exposed_elements.enabled&debuff.exposed_elements.up&maelstrom>=60&!buff.ascendance.up;
	if talents[EL.ExposedElements] and debuff[EL.ExposedElements].up and maelstrom >= 60 and not buff[EL.Ascendance].up then
		return EL.LightningBolt;
	end

	-- earth_shock,if=talent.master_of_the_elements.enabled&(buff.master_of_the_elements.up|maelstrom>=92)|!talent.master_of_the_elements.enabled;
	if maelstrom >= 60 and (talents[EL.MasterOfTheElements] and
		(buff[EL.MasterOfTheElements].up or maelstrom >= 92) or not talents[EL.MasterOfTheElements])
	then
		return EL.EarthShock;
	end

	-- lightning_bolt,if=buff.wind_gust.stack>=14&!buff.lava_surge.up;
	if buff[EL.WindGust].count >= 14 and not lavaSurge then
		return EL.LightningBolt;
	end

	-- lava_burst,if=cooldown_react|buff.ascendance.up;
	if canLavaBurst then
		return EL.LavaBurst;
	end

	-- flame_shock,target_if=refreshable;
	if debuff[EL.FlameShock].refreshable then
		return EL.FlameShock;
	end

	-- totem_mastery,if=talent.totem_mastery.enabled&(buff.resonance_totem.remains<6|(buff.resonance_totem.remains<(buff.ascendance.duration+cooldown.ascendance.remains)&cooldown.ascendance.remains<15));
	local tmRemains = Shaman:TotemMastery(EL.TotemMastery);
	if talents[EL.TotemMastery] and
		(tmRemains < 6 or (tmRemains < (buff[EL.Ascendance].duration + cooldown[EL.Ascendance].remains) and cooldown[EL.Ascendance].remains < 15))
	then
		return EL.TotemMastery;
	end

	-- frost_shock,if=talent.icefury.enabled&buff.icefury.up;
	if talents[EL.Icefury] and (buff[EL.Icefury].up or currentSpell == EL.Icefury) then
		return EL.FrostShock;
	end

	-- icefury,if=talent.icefury.enabled;
	if talents[EL.Icefury] and currentSpell ~= EL.Icefury and cooldown[EL.Icefury].ready then
		return EL.Icefury;
	end

	-- lava_beam,if=talent.ascendance.enabled&active_enemies>1&spell_targets.lava_beam>1;
	-- chain_lightning,if=active_enemies>1&spell_targets.chain_lightning>1;
	if targets > 1 then
		return chainLightning;
	end

	-- lava_burst,moving=1,if=talent.ascendance.enabled;
	if moving and talents[EL.Ascendance] and canLavaBurst and buff[EL.Ascendance].up then
		return EL.LavaBurst;
	end

	-- flame_shock,moving=1,target_if=refreshable;
	if moving and debuff[EL.FlameShock].refreshable and cooldown[EL.FlameShock].ready then
		return EL.FlameShock;
	end

	-- frost_shock,moving=1;
	if moving then
		return EL.FrostShock;
	end

	return EL.LightningBolt;
end