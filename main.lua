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

-- totems
local _SearingTotem = 3599;
local _StormElementalTotem = 152256;
local _FireElementalTotem = 2894;

-- auras
local _LavaSurge = 77762;
local _ElementalFusion = 157174;
local _EnhancedChainLightning = 157766;

-- talents
local _isAscendance = false;
local _isElementalMastery = false;

-- Flags

local _FlagAscendance = false;
local _FlagLS = false;

----------------------------------------------
-- Pre enable, checking talents
----------------------------------------------
TDDps_Shaman_CheckTalents = function()
	_isAscendance = TD_TalentEnabled('Ascendance');
	_isElementalMastery = TD_TalentEnabled('Elemental Mastery');
end

----------------------------------------------
-- Enabling Addon
----------------------------------------------
function TDDps_Shaman_EnableAddon(mode)
	mode = mode or 1;
	_TD['DPS_Description'] = 'TD Shaman DPS supports: Elemental';
	_TD['DPS_OnEnable'] = TDDps_Shaman_CheckTalents;
	if mode == 1 then
		_TD['DPS_NextSpell'] = TDDps_Shaman_Elemental
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

