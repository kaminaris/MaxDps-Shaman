-- Author      : Kaminari
-- Create Date : 13:03 2015-04-20

local _LightningBolt = 403;
local _LavaBurst = 51505;
local _FlameShock = 8050;
local _EarthShock = 8042;
local _Earthquake = 61882;
local _UnleashFlame = 165462;
local _LightningShield = 324;
local _Ascendance = 114050;
local _ElementalBlast = 117014;

-- totems
local _SearingTotem = 3599;
local _StormElementalTotem = 152256;
local _FireElementalTotem = 2894;

-- auras
local _LavaSurge = 77762;
local _ElementalFusion = 157174;
local _EnhancedChainLightning = 157766;

-- talents
local _isStormElementalTotem = false;
local _isLiquidMagma = false;
local _isElementalFusion = false;
local _isUnleashedFury = false;
local _isPrimalElementalist = false;
local _isElementalBlast = false;

-- Flags

local _FlagAscendance = false;
local _FlagLS = false;

----------------------------------------------
-- Pre enable, checking talents
----------------------------------------------
TDDps_Shaman_CheckTalents = function()
	_isStormElementalTotem = TD_TalentEnabled('Storm Elemental Totem');
	_isLiquidMagma = TD_TalentEnabled('Liquid Magma');
	_isElementalFusion = TD_TalentEnabled('Elemental Fusion');

	_isUnleashedFury = TD_TalentEnabled('Unleashed Fury');
	_isPrimalElementalist = TD_TalentEnabled('Primal Elementalist');
	_isElementalBlast = TD_TalentEnabled('Elemental Blast');
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

	local lavaCd, lavaCharges = TD_SpellCharges(_LavaBurst, timeShift);
	local eqCd, eqCharges = TD_SpellCharges(_Earthquake, timeShift);
--	local lavaSurge = TD_Aura(_LavaSurge);
--	local ascendance = TD_Aura(_Ascendance);
	local ascendanceCD = TD_SpellAvailable(_Ascendance, timeShift);
	local elBlast = TD_SpellAvailable(_ElementalBlast, timeShift);
	local ulFlame = TD_SpellAvailable(_UnleashFlame, timeShift);
	local fsCD = TD_SpellAvailable(_FlameShock, timeShift);
	local esCD = TD_SpellAvailable(_EarthShock, timeShift);
	local fetCD = TD_SpellAvailable(_FireElementalTotem, timeShift);
	local ls, lsCharges = TD_Aura(_LightningShield, timeShift);
	local ecl = TD_Aura(_EnhancedChainLightning, timeShift);
--	local ef, efCharges = TD_Aura(_ElementalFusion, timeShift);
	local fs = TD_TargetAura(_FlameShock, timeShift);
	local fs9 = TD_TargetAura(_FlameShock, 15 + timeShift);
	local ftName, ftExp = TDDps_Shaman_FireTotem();

	if currentSpell == 'Lava Burst' and lavaCharges > 0 then
		lavaCharges = lavaCharges - 1;
	end

	TDButton_GlowCooldown(_LightningShield, not ls);
	TDButton_GlowCooldown(_Ascendance, ascendanceCD);
	TDButton_GlowCooldown(_FireElementalTotem, fetCD);

	if eqCd and ecl then
		return _Earthquake;
	end

	if not fs and fsCD then
		return _FlameShock;
	end

	if lsCharges == 20 and esCD then
		return _EarthShock;
	end

	if lavaCharges > 0 or lavaCd < 0.1 then
		return _LavaBurst;
	end

	if lsCharges >= 15 and esCD then
		return _EarthShock;
	end

	if not fs9 then
		return _FlameShock;
	end

	if _isElementalBlast and elBlast then
		return _ElementalBlast;
	end

	if ftExp < 2 then
		return _SearingTotem;
	end

	if _isUnleashedFury and ulFlame then
		return _UnleashFlame;
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

