-- Author      : Kaminari
-- Create Date : 13:03 2015-04-20

local _LightningBolt	= 403;
local _LavaBurst		= 51505;
local _FlameShock		= 8050;
local _EarthShock		= 8042;
local _UnleashFlame		= 165462;
local _LightningShield	= 324;
local _Ascendance		= 114050;
local _ElementalBlast	= 117014;

-- totems
local _SearingTotem			= 3599;
local _StormElementalTotem	= 152256;
local _FireElementalTotem	= 2894;

-- auras
local _LavaSurge		= 77762;

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

	_isStormElementalTotem = TD_TalentEnabled("Storm Elemental Totem");
	_isLiquidMagma = TD_TalentEnabled("Liquid Magma");
	_isElementalFusion = TD_TalentEnabled("Elemental Fusion");

	_isUnleashedFury = TD_TalentEnabled("Unleashed Fury");
	_isPrimalElementalist = TD_TalentEnabled("Primal Elementalist");
	_isElementalBlast = TD_TalentEnabled("Elemental Blast");
end

----------------------------------------------
-- Enabling Addon
----------------------------------------------
function TDDps_Shaman_EnableAddon(mode)
	mode = mode or 1;
	_TD["DPS_Description"] = "TD Shaman DPS supports: Elemental";
	_TD["DPS_OnEnable"] = TDDps_Shaman_CheckTalents;
	if mode == 1 then
		_TD["DPS_NextSpell"] = TDDps_Shaman_Elemental
	end;
	TDDps_EnableAddon();
end

----------------------------------------------
-- Main rotation: Elemental
----------------------------------------------
TDDps_Shaman_Elemental = function()

	local lcd, currentSpell, gcd = TD_EndCast();
	local timeShift = lcd + gcd;
	
	local lavaCd, lavaCharges = TD_SpellCharges("Lava Burst");
	local lavaSurge = TD_Aura(_LavaSurge);
	local ascendance = TD_Aura(_Ascendance);
	local ascendanceCD = TD_SpellAvailable(_Ascendance, timeShift);
	local elBlast = TD_SpellAvailable(_ElementalBlast, timeShift);
	local ulFlame = TD_SpellAvailable(_UnleashFlame, timeShift);
	local fsCD = TD_SpellAvailable(_FlameShock, timeShift);
	local ls, lsCharges = TD_Aura(_LightningShield);
	local fs = TD_TargetAura(_FlameShock, timeShift);
	local fs9 = TD_TargetAura(_FlameShock, 8 + timeShift);
	local ftName, ftExp = TDDps_Shaman_FireTotem();

	if currentSpell == 'Lava Burst' and lavaCharges > 0 then
		lavaCharges = lavaCharges - 1;
	end

	if ascendanceCD and not _FlagAscendance then
		_FlagAscendance = true;
		TDButton_GlowIndependent(_Ascendance, 'asc', 0, 1, 0);
	end
	if not ascendanceCD and _FlagAscendance then
		_FlagAscendance = false;
		TDButton_ClearGlowIndependent(_Ascendance, 'asc');
	end

	if not ls and not _FlagLS then
		_FlagLS = true;
		TDButton_GlowIndependent(_LightningShield, 'ls', 0, 1, 0);
	end
	if ls and _FlagLS then
		_FlagLS = false;
		TDButton_ClearGlowIndependent(_LightningShield, 'ls');
	end
	
	if not fs and fsCD then
		return _FlameShock;
	end
	
	if lsCharges == 20 then
		return _EarthShock;
	end 
	
	if lavaCharges > 0 or lavaCd < 0.1 then
		return _LavaBurst;
	end 
	
	if lsCharges >= 15 then
		return _EarthShock;
	end 
	
	if not fs9 then
		return _FlameShock;
	end
	
	if _isElementalBlast and elBlast then
		return _ElementalBlast;
	end
	
	if ftExp < 3 then
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
		return "", 0;
	end;
	local expiration = startTime + duration - GetTime();
	return totemName, expiration;  
end

