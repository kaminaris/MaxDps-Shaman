-- Author      : Kaminari
-- Create Date : 13:03 2015-04-20

local _LightningBolt = 188196;
local _LavaBurst = 51505;
local _FlameShock = 188389;
local _EarthShock = 8042;
local _Earthquake = 61882;
local _UnleashFlame = 165462;
local _LightningShield = 324;
local _Ascendance = 114050;
local _ElementalBlast = 117014;
local _FireElemental = 198067;
local _Stormkeeper = 205495;
local _ElementalMastery = 16166;
local _TotemMastery = 210643;
local _ElementalFocus = 16164;
local _PoweroftheMaelstrom = 191861;
local _Icefury = 210714;
local _FrostShock = 196840;

-- enh
local _Boulderfist = 201897;
local _Landslide = 197992;
local _Hailstorm = 210853;
local _Frostbrand = 196834;
local _CrashLightning = 187874;
local _Flametongue = 193796;
local _Stormstrike = 17364;
local _Stormbringer = 201845;
local _FeralSpirit = 51533;
local _AlphaWolf = 198434;
local _DoomWinds = 204945;
local _CrashingStorm = 192246;
local _LavaLash = 60103;
local _LightningBoltEnh = 187837;
local _Rockbiter = 193786;
local _FuryofAir = 197211;
local _Overcharge = 210727;
local _Windsong = 201898;
local _HotHand = 201900;
local _Windfury = 33757;
local _FeralLunge = 196884;
local _WindRushTotem = 192077;
local _Rainfall = 215864;
local _Tempest = 192234;
local _EarthenSpike = 188089;
local _Windstrike = 115356;
local _GatheringStorms = 198300;

-- totems
local _SearingTotem = 3599;
local _StormElementalTotem = 152256;
local _FireElementalTotem = 2894;

-- auras
local _LavaSurge = 77762;

-- talents

MaxDps.Shaman = {};

function MaxDps.Shaman.CheckTalents()
	MaxDps:CheckTalents();
end

function MaxDps:EnableRotationModule(mode)
	mode = mode or 1;
	MaxDps.Description = 'Shaman Module [Elemental, Enhancement]';
	MaxDps.ModuleOnEnable = MaxDps.Shaman.CheckTalents;
	if mode == 1 then
		MaxDps.NextSpell = MaxDps.Shaman.Elemental;
	end;
	if mode == 2 then
		MaxDps.NextSpell = MaxDps.Shaman.Enhancement;
	end;
	if mode == 3 then
		MaxDps.NextSpell = MaxDps.Shaman.Restoration;
	end;
end

function MaxDps.Shaman.Elemental(_, timeShift, currentSpell, gcd, talents)

	local mael = UnitPower('player', SPELL_POWER_MAELSTORM);
	local lavaCd, lavaCharges = MaxDps:SpellCharges(_LavaBurst, timeShift);
	local eqCd, eqCharges = MaxDps:SpellCharges(_Earthquake, timeShift);
	local ascendance = MaxDps:Aura(_Ascendance, timeShift);
	local ef = MaxDps:Aura(_ElementalFocus, timeShift);
	local ascendanceCD = MaxDps:SpellAvailable(_Ascendance, timeShift);
	local emCD = MaxDps:SpellAvailable(_ElementalMastery, timeShift);
	local fetCD = MaxDps:SpellAvailable(_FireElemental, timeShift);
	local stormk = MaxDps:SpellAvailable(_Stormkeeper, timeShift);
	local fs = MaxDps:TargetAura(_FlameShock, 4 + timeShift);
	local fs9 = MaxDps:TargetAura(_FlameShock, 9 + timeShift);

	if MaxDps:SameSpell(currentSpell, _LavaBurst) then
		mael = mael + 12;
		if lavaCharges > 0 then
			lavaCharges = lavaCharges - 1;
		end
	end

	if MaxDps:SameSpell(currentSpell, _LightningBolt) then
		mael = mael + 8;
	end

	MaxDps:GlowCooldown(_Ascendance, talents[_Ascendance] and ascendanceCD);
	MaxDps:GlowCooldown(_ElementalMastery, talents[_ElementalMastery] and emCD);
	MaxDps:GlowCooldown(_FireElemental, fetCD);

	if not fs or (not fs9 and mael >= 20 and ef) then
		return _FlameShock;
	end

	local totemMastery, tmExp = MaxDps.Shaman.TotemMastery();
	if talents[_TotemMastery] and tmExp < 10 then
		return _TotemMastery;
	end

	if talents[_ElementalBlast] and MaxDps:SpellAvailable(_ElementalBlast, timeShift) and
			not MaxDps:SameSpell(currentSpell, _ElementalBlast) then
		return _ElementalBlast;
	end

	if mael >= 117 then
		return _EarthShock;
	end

	if talents[_Icefury] and MaxDps:SpellAvailable(_Icefury, timeShift) and mael < 101 then
		return _Icefury;
	end

	if lavaCharges >= 1.5 or ascendance then
		return _LavaBurst;
	end

	if talents[_Icefury] and MaxDps:Aura(_Icefury, timeShift) and mael >= 20 then
		return _FrostShock;
	end

	if MaxDps:Aura(_PoweroftheMaelstrom, timeShift) and lavaCharges < 2 then
		return _LightningBolt;
	end

	if not ascendance and stormk and not MaxDps:SameSpell(currentSpell, _Stormkeeper) then
		return _Stormkeeper;
	end

	return _LightningBolt;
end

function MaxDps.Shaman.Enhancement(_, timeShift, currentSpell, gcd, talents)

	local mael = UnitPower('player', SPELL_POWER_MAELSTORM);
	local rockbiter = _Rockbiter;
	if talents[_Boulderfist] then
		rockbiter = _Boulderfist;
	end

	local rockbCd, rockbCharges = MaxDps:SpellCharges(rockbiter, timeShift);
	local rockb = MaxDps:Aura(_Boulderfist, timeShift + 2);
	local asc = MaxDps:Aura(_Ascendance, timeShift);

	local stormstrike = _Stormstrike;
	if asc then
		stormstrike = _Windstrike;
	end

	local fs, fsCd = MaxDps:SpellAvailable(_FeralSpirit, timeShift);

	MaxDps:GlowCooldown(_FeralSpirit, fs);
	MaxDps:GlowCooldown(_CrashLightning, fsCd > 110 and not MaxDps:Aura(_GatheringStorms, timeShift));
	MaxDps:GlowCooldown(_DoomWinds, MaxDps:SpellAvailable(_DoomWinds, timeShift));
	MaxDps:GlowCooldown(_Ascendance, talents[_Ascendance] and MaxDps:SpellAvailable(_Ascendance, timeShift));
	MaxDps:GlowCooldown(_Windsong, talents[_Windsong] and MaxDps:SpellAvailable(_Windsong, timeShift));

	-- 1. Cast Rockbiter to generate Maelstrom and maintain Landslide
	if not MaxDps:Aura(_Landslide, timeShift + 2) and rockbCd then
		return rockbiter;
	end

	-- 2. Cast Fury of Air if it is not present.
	if talents[_FuryofAir] and not MaxDps:PersistentAura(_FuryofAir) then
		return _FuryofAir;
	end

	-- 3. Cast Flametongue if the buff is not active.
	local ftCd = MaxDps:SpellAvailable(_Flametongue, timeShift);
	if not MaxDps:Aura(_Flametongue, timeShift + 4) and ftCd then
		return _Flametongue;
	end

	-- 4. Cast Earthen Spike.
	if talents[_EarthenSpike] and MaxDps:SpellAvailable(_EarthenSpike, timeShift) then
		return _EarthenSpike;
	end

	-- 5. Cast Windstrike with or without Stormbringer active.
	if talents[_Ascendance] and asc and MaxDps:SpellAvailable(_Windstrike, timeShift) then
		return _Windstrike;
	end

	-- 6. Cast Frostbrand to maintain the Hailstorm buff.
	if talents[_Hailstorm] and not MaxDps:Aura(_Frostbrand, timeShift + 4) then
		return _Frostbrand;
	end

	-- 7. Cast Windsong.
	if talents[_Windsong] and MaxDps:SpellAvailable(_Windsong, timeShift) then
		return _Windsong;
	end

	-- 8. Cast Stormstrike with Stormbringer active.
	if MaxDps:Aura(_Stormbringer, timeShift) and mael >= 20 then
		return stormstrike;
	end

	-- 9. Cast Lightning Bolt if above 50 Maelstrom with Overcharge.
	if talents[_Overcharge] and MaxDps:SpellAvailable(_LightningBoltEnh, timeShift) and mael > 50 then
		return _LightningBoltEnh;
	end

	-- 10. Cast Lava Lash with Hot Hand procs.
	if talents[_HotHand] and MaxDps:Aura(_HotHand, timeShift) then
		return _LavaLash;
	end

	-- 11. Cast Stormstrike.
	if MaxDps:SpellAvailable(_Stormstrike, timeShift) and mael >= 40  then
		return stormstrike;
	end

	-- 12. Cast Rockbiter.
	if rockbCharges >= 1 then
		return rockbiter;
	end

	-- 13.
	if talents[_CrashingStorm] and MaxDps:SpellAvailable(_CrashLightning, timeShift) then
		return _CrashLightning;
	end

	-- 14. Cast Lava Lash if you have more than 80 Maelstrom.
	if mael > 80 then
		return _LavaLash;
	end

	return nil;
end

function MaxDps.Shaman.Restoration()
	return nil;
end

function MaxDps.Shaman.Totem()
	local have, totemName, startTime, duration = GetTotemInfo(1);
	if not have then
		return '', 0;
	end;
	local expiration = startTime + duration - GetTime();
	return totemName, expiration;
end

function MaxDps.Shaman.TotemMastery()
	local tmName = GetSpellInfo(_TotemMastery);

	for i = 1, 4 do
		local haveTotem, totemName, startTime, duration = GetTotemInfo(i);
		if haveTotem and totemName == tmName then
			return true, startTime + duration - GetTime();
		end
	end
	return false, 0;
end