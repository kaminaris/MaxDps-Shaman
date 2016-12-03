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

MaxDps.Shaman = {};

function MaxDps.Shaman.CheckTalents()
	_isAscendance = MaxDps:TalentEnabled('Ascendance');
	_isHailstorm = MaxDps:TalentEnabled('Hailstorm');
	_isCrashingStorm = MaxDps:TalentEnabled('Crashing Storm');
	_isElementalMastery = MaxDps:TalentEnabled('Elemental Mastery');
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
end

function MaxDps.Shaman.Elemental()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();

	local mael = UnitPower('player', SPELL_POWER_MAELSTORM);

	local lavaCd, lavaCharges = MaxDps:SpellCharges(_LavaBurst, timeShift);
	local eqCd, eqCharges = MaxDps:SpellCharges(_Earthquake, timeShift);

	local ascendance = MaxDps:Aura(_Ascendance);
	local ascendanceCD = MaxDps:SpellAvailable(_Ascendance, timeShift);
	local emCD = MaxDps:SpellAvailable(_ElementalMastery, timeShift);

	local fetCD = MaxDps:SpellAvailable(_FireElemental, timeShift);
	local stormk = MaxDps:SpellAvailable(_Stormkeeper, timeShift);

	local fs = MaxDps:TargetAura(_FlameShock, 4 + timeShift);

	if currentSpell == 'Lava Burst' and lavaCharges > 0 then
		lavaCharges = lavaCharges - 1;
	end

	MaxDps:GlowCooldown(_Ascendance, _isAscendance and ascendanceCD);
	MaxDps:GlowCooldown(_ElementalMastery, _isElementalMastery and emCD);
	MaxDps:GlowCooldown(_FireElemental, fetCD);

	if not fs then
		return _FlameShock;
	end

	if mael > 90 then
		return _EarthShock;
	end

	if lavaCharges > 0 then
		return _LavaBurst;
	end

	if not ascendance and stormk and currentSpell ~= 'Stormkeeper' then
		return _Stormkeeper;
	end

	return _LightningBolt;
end

function MaxDps.Shaman.Enhancement()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();

	local mael = UnitPower('player', SPELL_POWER_MAELSTORM);

	local bfCd, bfCharges = MaxDps:SpellCharges(_Boulderfist, timeShift);
	local ssCd = MaxDps:SpellAvailable(_Stormstrike, timeShift);
	local fs = MaxDps:SpellAvailable(_FeralSpirit, timeShift);
	local dw = MaxDps:SpellAvailable(_DoomWinds, timeShift);
	local cl = MaxDps:SpellAvailable(_CrashLightning, timeShift);
	local ftCd = MaxDps:SpellAvailable(_Flametongue, timeShift);

	local bf = MaxDps:Aura(_Boulderfist, timeShift + 2);
	local ls = MaxDps:Aura(_Landslide, timeShift + 2);
	local fb = MaxDps:Aura(_Frostbrand, timeShift + 4);
	local ft = MaxDps:Aura(_Flametongue, timeShift + 4);

	MaxDps:GlowCooldown(_FeralSpirit, fs);
	MaxDps:GlowCooldown(_DoomWinds, dw);

	if (not bf or not ls) and bfCd then
		return _Boulderfist;
	end

	if _isHailstorm and not fb then
		return _Frostbrand;
	end

	if not ft and ftCd then
		return _Flametongue;
	end

	if ssCd then
		return _Stormstrike;
	end

	if mael < 130 and bfCharges > 1 then
		return _Boulderfist;
	end

	if _isCrashingStorm and cl then
		return _CrashLightning;
	end

	if mael > 110 then
		return _LavaLash;
	end

	if bfCharges > 0 then
		return _Boulderfist;
	end

	if ftCd then
		return _Flametongue;
	end

	return _LightningBoltEnh;
end

function MaxDps.Shaman.FireTotem()
	local have, totemName, startTime, duration = GetTotemInfo(1);
	if not have then
		return '', 0;
	end;
	local expiration = startTime + duration - GetTime();
	return totemName, expiration;
end

