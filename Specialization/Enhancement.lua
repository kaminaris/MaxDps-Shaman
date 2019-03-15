local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end
local MaxDps = MaxDps;
local UnitPower = UnitPower;
local Maelstrom = Enum.PowerType.Maelstrom;

local Shaman = addonTable.Shaman;


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

setmetatable(EN, Shaman.spellMeta);


function Shaman:Enhancement()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, talents, azerite, currentSpell =
	fd.cooldown, fd.buff, fd.debuff, fd.talents, fd.azerite, fd.currentSpell;

	--local healthPct = UnitHealth('player') / UnitHealthMax('player') * 100;
	local maelstrom = UnitPower('player', Maelstrom);

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