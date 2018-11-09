-- Author      : Kaminaris, PreZ, Pawel, Laag
-- Create Date : 2018-08-03

if not MaxDps then
	return ;
end

local MaxDps = MaxDps;

local Shaman = MaxDps:NewModule('Shaman');

--local EL = {
--	LightningBolt       = 188196,
--	LavaBurst           = 51505,
--	FlameShock          = 188389,
--	EarthShock          = 8042,
--	Earthquake          = 61882,
--	UnleashFlame        = 165462,
--	LightningShield     = 324,
--	Ascendance          = 114050,
--	ElementalBlast      = 117014,
--	FireElemental       = 198067,
--	EarthElemental      = 198103,
--	StormElemental      = 192249,
--	Stormkeeper         = 191634,
--	TotemMastery        = 210643,
--	PoweroftheMaelstrom = 191861,
--	Icefury             = 210714,
--	FrostShock          = 196840,
--	EchoOfTheElements   = 108283,
--};

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


-- enh
local EN = {
	LightningShield  = 192106,
	Boulderfist      = 246035,
	Landslide        = 197992,
	Hailstorm        = 210853,
	Frostbrand       = 196834,
	CrashLightning   = 187874,
	Flametongue      = 193796,
	Stormstrike      = 17364,
	Stormbringer     = 201845,
	FeralSpirit      = 51533,
	CrashingStorm    = 192246,
	LavaLash         = 60103,
	LightningBoltEnh = 187837,
	Rockbiter        = 193786,
	FuryOfAir        = 197211,
	Overcharge       = 210727,
	Windsong         = 201898,
	HotHand          = 201900,
	Windfury         = 33757,
	FeralLunge       = 196884,
	WindRushTotem    = 192077,
	EarthenSpike     = 188089,
	Windstrike       = 115356,
	GatheringStorms  = 198300,
	SearingAssault   = 192087,
	Sundering        = 197214,
	Ascendance       = 114051,

	TotemMastery     = 262395,
	ResonanceTotem   = 262417,
};

local RT = {
	FlameShock    = 188838,
	LightningBolt = 403,
};

local spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
};

setmetatable(EL, spellMeta);
setmetatable(EN, spellMeta);
setmetatable(RT, spellMeta);


-- resto

function Shaman:Enable()
	MaxDps:Print(MaxDps.Colors.Info .. 'Shaman [Elemental, Enhancement, Restoration]')

	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Shaman.Elemental;
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Shaman.Enhancement;
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Shaman.Restoration;
	end

	return true;
end

function Shaman:Elemental()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell = fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell;

	local pet = UnitExists('pet');
	local maelstrom = UnitPower('player', Enum.PowerType.Maelstrom);
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
	if talents[EL.TotemMastery] and Shaman:TotemMastery(EL.TotemMastery) < 5 then
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
	if talents[EL.TotemMastery] and
		(buff[EL.ResonanceTotem].remains < 6 or (buff[EL.ResonanceTotem].remains < (buff[EL.Ascendance].duration + cooldown[EL.Ascendance].remains) and cooldown[EL.Ascendance].remains < 15))
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

function Shaman:Enhancement()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell;

	--local healthPct = UnitHealth('player') / UnitHealthMax('player') * 100;
	local maelstrom = UnitPower('player', Enum.PowerType.Maelstrom);

	local stormstrike = (buff[EN.Ascendance].up and not MaxDps:FindSpell(EN.Stormstrike)) and EN.Windstrike or EN.Stormstrike;

	local fs, fsCd = cooldown[EN.FeralSpirit].ready;
	local ft, ftCd = cooldown[EN.Flametongue].ready;

	MaxDps:GlowCooldown(EN.FeralSpirit, fs);
	MaxDps:GlowCooldown(EN.Ascendance, talents[EN.Ascendance] and cooldown[EN.Ascendance].ready);
	MaxDps:GlowCooldown(EN.LightningShield, talents[EN.LightningShield] and buff[EN.LightningShield].remains < 4);

	-- 1. Cast Rockbiter with Landslide if the buff is not currently active and you are about to reach 2 charges.
	if talents[EN.Landslide] and not buff[EN.Landslide].up and cooldown[EN.Rockbiter].charges >= 1.7 then
		return EN.Rockbiter;
	end

	-- 2. Cast Fury of Air if it is not present.
	if talents[EN.FuryOfAir] and not MaxDps:Aura(EN.FuryOfAir) then
		return EN.FuryOfAir;
	end

	-- 3. Cast Totem Mastery if not active.
	if talents[EN.TotemMastery] then
		if Shaman:TotemMastery(EN.TotemMastery) < 10 then
			return EN.TotemMastery;
		end
	end

	-- 4. Cast Windstrike during Ascendence with Stormbringer active.
	if talents[EN.Ascendance] and MaxDps:Aura(EN.Ascendance) and (
		buff[EN.Stormbringer].up or
			(cooldown[EN.Windstrike].ready and maelstrom >= 30)
	) then
		return EN.Windstrike;
	end

	-- 5. Cast Flametongue if the buff is not active.
	if not buff[EN.Flametongue].up and ft then
		return EN.Flametongue;
	end

	-- 6. Cast Earthen Spike.
	if talents[EN.EarthenSpike] and cooldown[EN.EarthenSpike].ready and maelstrom >= 20 then
		return EN.EarthenSpike;
	end

	-- 7. Cast Frostbrand with Hailstorm to maintain the Hailstorm buff.
	if talents[EN.Hailstorm] and not buff[EN.Frostbrand].up and maelstrom >= 20 then
		return EN.Frostbrand;
	end

	-- 8. Cast Stormstrike with Stormbringer active.
	if buff[EN.Stormbringer].up then
		return stormstrike;
	end

	-- 10. Cast Lava Lash with Hot Hand procs.
	if talents[EN.HotHand] and buff[EN.HotHand].up then
		return EN.LavaLash;
	end

	-- 11. Cast Stormstrike.
	if cooldown[EN.Stormstrike].ready and maelstrom >= 30 then
		return stormstrike;
	end

	-- 12. Cast Lightning Bolt with Fury of Air and Overcharge if above 50 Maelstrom.
	if talents[EN.Overcharge] and cooldown[EN.LightningBoltEnh].ready and (
		(maelstrom >= 50 and talents[EN.FuryOfAir]) or
		(maelstrom >= 40 and not talents[EN.FuryOfAir])
	) then
		return EN.LightningBoltEnh;
	end

	-- 13. Cast Flametongue to trigger Searing Assault.
	if talents[EN.SearingAssault] and not debuff[EN.SearingAssault].up and ft then
		return EN.Flametongue;
	end

	-- 14. Cast Sundering
	if talents[EN.Sundering] and cooldown[EN.Sundering].ready and maelstrom >= 20 then
		return EN.Sundering;
	end

	-- 15. Cast Rockbiter if below 70 Maelstrom and about to reach 2 charges.
	if cooldown[EN.Rockbiter].charges >= 1.7 and maelstrom < 70 then
		return EN.Rockbiter;
	end

	-- 16. Cast Flametongue if the buff is about to expire. -- @todo: not sure about that
	if buff[EN.Flametongue].remains < 4 and ft then
		return EN.Flametongue;
	end

	-- 17. Cast Frostbrand with Hailstorm if buff is about to expire.
	if talents[EN.Hailstorm] and buff[EN.Frostbrand].remains < 4 then
		return EN.Frostbrand;
	end

	-- 18. Cast Lava Lash with Fury of Air if above 50 Maelstrom.
	if talents[EN.FuryOfAir] then
		if maelstrom > 50 then
			return EN.LavaLash;
		end
	else
		if maelstrom > 40 then
			return EN.LavaLash;
		end
	end

	-- 19. Cast Rockbiter
	if cooldown[EN.Rockbiter].charges >= 1 then
		return EN.Rockbiter;
	end

	-- 20. Cast Flametongue if nothing else
	if cooldown[EN.Flametongue].remains < cooldown[EN.Rockbiter].remains then
		return EN.Flametongue;
	else
		return EN.Rockbiter;
	end
end

function Shaman:Restoration(timeShift, currentSpell, gcd, talents)
	--local healthPct = UnitHealth('player') / UnitHealthMax('player') * 100;
	--local lavaCd, lavaCharges = MaxDps:SpellCharges(RT.LavaBurst, timeShift);
	--local ashift = cooldown[RT.AstralShift].ready;
	--local eet = cooldown[RT.EarthElemental].ready;
	--local fs = MaxDps:TargetAura(RT.FlameShock, 4 + timeShift);
	--
	--if currentSpell == RT.LavaBurst then
	--	if lavaCharges > 0 then
	--		lavaCharges = lavaCharges - 1;
	--	end
	--end
	--
	--MaxDps:GlowCooldown(RT.EarthElemental, eet);
	--
	---- May as well get a shot off before they run towards you!
	--if not UnitAffectingCombat('player') then
	--	return RT.LightningBolt;
	--end
	--
	--if not fs and cooldown[RT.FlameShock].ready then
	--	return RT.FlameShock;
	--end
	--
	--if buff[RT.PoweroftheMaelstrom].up and lavaCharges < 2 then
	--	return RT.LightningBolt;
	--end
	--
	--if lavaCd <= 0 then
	--	return RT.LavaBurst;
	--end
	--
	--return RT.LightningBolt;
end

function Shaman:TotemMastery(totem)
	local tmName = GetSpellInfo(totem);

	local i = 1;
	while true do
		local haveTotem, totemName, startTime, duration = GetTotemInfo(i);
		if not haveTotem then
			return 0;
		end

		if haveTotem and totemName == tmName then
			return startTime + duration - GetTime();
		end

		i = i + 1;
	end
	return 0;
end