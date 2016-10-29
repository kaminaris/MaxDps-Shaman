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

----------------------------------------------
-- Pre enable, checking talents
----------------------------------------------
TDDps_Shaman_CheckTalents = function()
	_isAscendance = TD_TalentEnabled('Ascendance');
	_isHailstorm = TD_TalentEnabled('Hailstorm');
	_isCrashingStorm = TD_TalentEnabled('Crashing Storm');
	_isElementalMastery = TD_TalentEnabled('Elemental Mastery');
end

----------------------------------------------
-- Enabling Addon
----------------------------------------------
function TDDps_Shaman_EnableAddon(mode)
	mode = mode or 1;
	_TD['DPS_Description'] = 'TD Shaman DPS supports: Elemental, Enhancement';
	_TD['DPS_OnEnable'] = TDDps_Shaman_CheckTalents;
	if mode == 1 then
		_TD['DPS_NextSpell'] = TDDps_Shaman_Elemental;
	end;
	if mode == 2 then
		_TD['DPS_NextSpell'] = TDDps_Shaman_Enhancement;
	end;
	TDDps_EnableAddon();
end

----------------------------------------------
-- Main rotation: Elemental
----------------------------------------------
TDDps_Shaman_Elemental = function()
	local timeShift, currentSpell, gcd = TD_EndCast();

	local mael = UnitPower('player', SPELL_POWER_MAELSTORM);

	local lavaCd, lavaCharges = TD_SpellCharges(_LavaBurst, timeShift);
	local eqCd, eqCharges = TD_SpellCharges(_Earthquake, timeShift);

	local ascendance = TD_Aura(_Ascendance);
	local ascendanceCD = TD_SpellAvailable(_Ascendance, timeShift);
	local emCD = TD_SpellAvailable(_ElementalMastery, timeShift);

	local fetCD = TD_SpellAvailable(_FireElemental, timeShift);
	local stormk = TD_SpellAvailable(_Stormkeeper, timeShift);

	local fs = TD_TargetAura(_FlameShock, 4 + timeShift);

	if currentSpell == 'Lava Burst' and lavaCharges > 0 then
		lavaCharges = lavaCharges - 1;
	end

	TDButton_GlowCooldown(_Ascendance, _isAscendance and ascendanceCD);
	TDButton_GlowCooldown(_ElementalMastery, _isElementalMastery and emCD);
	TDButton_GlowCooldown(_FireElemental, fetCD);

	if not fs then
		return _FlameShock;
	end

	if mael > 90 then
		return _EarthShock;
	end

	if lavaCharges > 0 then
		return _LavaBurst;
	end

	if not ascendance and stormk then
		return _Stormkeeper;
	end

	return _LightningBolt;
end

----------------------------------------------
-- Main rotation: Enhancement
----------------------------------------------
TDDps_Shaman_Enhancement = function()
	local timeShift, currentSpell, gcd = TD_EndCast();

	local mael = UnitPower('player', SPELL_POWER_MAELSTORM);

	local bfCd, bfCharges = TD_SpellCharges(_Boulderfist, timeShift);
	local ssCd = TD_SpellAvailable(_Stormstrike, timeShift);
	local fs = TD_SpellAvailable(_FeralSpirit, timeShift);
	local dw = TD_SpellAvailable(_DoomWinds, timeShift);
	local cl = TD_SpellAvailable(_CrashLightning, timeShift);
	local ftCd = TD_SpellAvailable(_Flametongue, timeShift);

	local bf = TD_Aura(_Boulderfist, timeShift + 2);
	local ls = TD_Aura(_Landslide, timeShift + 2);
	local fb = TD_Aura(_Frostbrand, timeShift + 4);
	local ft = TD_Aura(_Flametongue, timeShift + 4);

	TDButton_GlowCooldown(_FeralSpirit, fs);
	TDButton_GlowCooldown(_DoomWinds, dw);

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
----------------------------------------------
-- Fire totem name and expiration
----------------------------------------------
function TDDps_Shaman_FireTotem()
	local have, totemName, startTime, duration = GetTotemInfo(1);
	if not have then
		return '', 0;
	end;
	local expiration = startTime + duration - GetTime();
	return totemName, expiration;
end

