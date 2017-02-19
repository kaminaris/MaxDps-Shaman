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

-- totems
local _SearingTotem = 3599;
local _StormElementalTotem = 152256;
local _FireElementalTotem = 2894;

-- auras
local _LavaSurge = 77762;

-- talents
local _isAscendance = false;
local _isHailstorm = false;
local _isCrashingStorm = false;
local _isElementalMastery = false;
local _isTotemMastery = false;
local _isElementalBlast = false;
local _isIcefury = false;
local _isBoulderfist = false;
local talents = {};

MaxDps.Shaman = {};

function MaxDps.Shaman.CheckTalents()
	MaxDps:CheckTalents();
	talents = MaxDps.PlayerTalents;
	_isAscendance = MaxDps:HasTalent(_Ascendance);
	_isHailstorm = MaxDps:HasTalent(_Hailstorm);
	_isCrashingStorm = MaxDps:HasTalent(_CrashingStorm);
	_isElementalMastery = MaxDps:HasTalent(_ElementalMastery);
	_isElementalBlast = MaxDps:HasTalent(_ElementalBlast);
	_isIcefury = MaxDps:HasTalent(_Icefury);
	_isTotemMastery = MaxDps:HasTalent(_TotemMastery);
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

function MaxDps.Shaman.Elemental()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();

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

	MaxDps:GlowCooldown(_Ascendance, _isAscendance and ascendanceCD);
	MaxDps:GlowCooldown(_ElementalMastery, _isElementalMastery and emCD);
	MaxDps:GlowCooldown(_FireElemental, fetCD);

	if not fs or (not fs9 and mael >= 20 and ef) then
		return _FlameShock;
	end

	if _isElementalBlast and MaxDps:SpellAvailable(_ElementalBlast, timeShift) and
			not MaxDps:SameSpell(currentSpell, _ElementalBlast) then
		return _ElementalBlast;
	end

	if mael >= 92 then
		return _EarthShock;
	end

	if _isIcefury and MaxDps:SpellAvailable(_Icefury, timeShift) and mael < 76 then
		return _Icefury;
	end

	if lavaCharges >= 1.5 or ascendance then
		return _LavaBurst;
	end

	if _isIcefury and MaxDps:Aura(_Icefury, timeShift) and mael >= 20 then
		return _FrostShock;
	end

	if MaxDps:Aura(_PoweroftheMaelstrom, timeShift) and lavaCharges < 2 then
		return _LightningBolt;
	end

	if not ascendance and stormk and not MaxDps:SameSpell(currentSpell, _Stormkeeper) then
		return _Stormkeeper;
	end

	local totemMastery, tmExp = MaxDps.Shaman.TotemMastery();
	if _isTotemMastery and tmExp < 10 then
		return _TotemMastery;
	end

	return _LightningBolt;
end

function MaxDps.Shaman.Enhancement()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();

	local mael = UnitPower('player', SPELL_POWER_MAELSTORM);

	local rockbiter = _Rockbiter;
	if talents[_Boulderfist] then
		rockbiter = _Boulderfist;
	end

	local rockbCd, rockbCharges = MaxDps:SpellCharges(rockbiter, timeShift);



	local rockb = MaxDps:Aura(_Boulderfist, timeShift + 2);

	MaxDps:GlowCooldown(_FeralSpirit, MaxDps:SpellAvailable(_FeralSpirit, timeShift));
	MaxDps:GlowCooldown(_DoomWinds, MaxDps:SpellAvailable(_DoomWinds, timeShift));

	-- 1. Cast Rockbiter to generate Maelstrom and maintain Landslide
	if not MaxDps:Aura(_Landslide, timeShift + 2) and rockbCd then
		return rockbiter;
	end

	-- 2. Cast Fury of Air if it is not present.
	if talents[_FuryofAir] and not MaxDps:PersistentAura(_FuryofAir) then
		return _FuryofAir;
	end

	if _isHailstorm and not MaxDps:Aura(_Frostbrand, timeShift + 4) then
		return _Frostbrand;
	end

	-- 3. Maintain the Flametongue buff.
	local ftCd = MaxDps:SpellAvailable(_Flametongue, timeShift);
	if not MaxDps:Aura(_Flametongue, timeShift + 4) and ftCd then
		return _Flametongue;
	end

	-- 4. Cast Lightning Bolt if above 50 Maelstrom with Overcharge.
	if talents[_Overcharge] and MaxDps:SpellAvailable(_LightningBoltEnh, timeShift) and mael > 50 then
		return _LightningBoltEnh;
	end

	-- 5. Cast Stormstrike with Stormbringer active.
	if MaxDps:Aura(_Stormbringer, timeShift) and mael >= 20 then
		return _Stormstrike;
	end

	-- 6. Cast Windsong
	if talents[_Windsong] and MaxDps:SpellAvailable(_Windsong, timeShift) then
		return _Windsong;
	end

	-- 7. Cast Lava Lash with Hot Hand procs.
	if talents[_HotHand] and MaxDps:Aura(_HotHand, timeShift) then
		return _LavaLash;
	end

	-- 8. Cast Stormstrike on cooldown.
	if MaxDps:SpellAvailable(_Stormstrike, timeShift) and mael >= 40 then
		return _Stormstrike;
	end

	if talents[_CrashingStorm] and MaxDps:SpellAvailable(_CrashLightning, timeShift) then
		return _CrashLightning;
	end

	if mael < 120 and rockbCharges >= 1 then
		return rockbiter;
	end

	if mael > 120 then
		return _LavaLash;
	end

	if rockbCharges >= 1 then
		return rockbiter;
	end

	if ftCd then
		return _Flametongue;
	end

	return _LightningBoltEnh;
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
