-- Author      : Kaminaris, PreZ, Pawel, Laag
-- Create Date : 2018-08-03

if not MaxDps then
	return;
end

local Shaman = MaxDps:NewModule('Shaman');

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
local _EarthElemental = 198103;
local _StormElemental = 192249;
local _Stormkeeper = 191634;
local _TotemMastery = 210643;
local _PoweroftheMaelstrom = 191861;
local _Icefury = 210714;
local _FrostShock = 196840;
local _EchoOfTheElements = 108283;

-- enh
local _LightningShield = 192106;
local _Boulderfist = 246035;
local _Landslide = 197992;
local _Hailstorm = 210853;
local _Frostbrand = 196834;
local _CrashLightning = 187874;
local _Flametongue = 193796;
local _Stormstrike = 17364;
local _Stormbringer = 201845;
local _FeralSpirit = 51533;
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
local _EarthenSpike = 188089;
local _Windstrike = 115356;
local _GatheringStorms = 198300;
local _SearingAssault = 192087;
local _Sundering = 197214;
local _AscendanceEnh = 114051;

-- resto
local _FlameShockResto = 188838;
local _LightningBoltResto = 403;

-- totems
local _SearingTotem = 3599;
local _StormTotem = 210652;
local _StormElementalTotem = 152256;
local _FireElementalTotem = 2894;
local _EarthElementalTotem = 73903;
local _LiquidMagmaTotem = 192222;

-- auras
local _LavaSurge = 77762;
local _ExposedElements = 260694;

-- talents


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

function Shaman:Elemental(timeShift, currentSpell, gcd, talents)

	local mael = UnitPower('player', Enum.PowerType.Maelstrom);
	local lavaCd, lavaCharges = MaxDps:SpellCharges(_LavaBurst, timeShift);
	local ascendance = MaxDps:Aura(_Ascendance, timeShift);
	local ascendanceCD = MaxDps:SpellAvailable(_Ascendance, timeShift);

	local fs = MaxDps:TargetAura(_FlameShock, 4 + timeShift);
	-- local fs9 = MaxDps:TargetAura(_FlameShock, 9 + timeShift);
	local pet = UnitExists('pet');

	if currentSpell == _LavaBurst then
		mael = mael + 10;
		lavaCharges = lavaCharges - 1;
	end

	if currentSpell == _LightningBolt then
		mael = mael + 8;
	end

	MaxDps:GlowCooldown(_Ascendance, talents[_Ascendance] and ascendanceCD);

	if talents[_StormElemental] then
		MaxDps:GlowCooldown(_StormElemental, not pet and MaxDps:SpellAvailable(_StormElemental, timeShift));
	else
		MaxDps:GlowCooldown(_FireElemental, not pet and MaxDps:SpellAvailable(_FireElemental, timeShift));
	end

	MaxDps:GlowCooldown(_EarthElemental, not pet and MaxDps:SpellAvailable(_EarthElemental, timeShift));

	local totemMastery, tmExp = Shaman:TotemMastery();
	if talents[_TotemMastery] and (tmExp < 10 or not MaxDps:Aura(_StormTotem, timeShift)) then
		return _TotemMastery;
	end

	if not fs and MaxDps:SpellAvailable(_FlameShock, timeShift) then
		return _FlameShock;
	end

	if ascendance then
		if mael >= 92 then
			return _EarthShock;
		end

		if lavaCd <= 0 then
			return _LavaBurst;
		end
	end

	if talents[_ElementalBlast] and MaxDps:SpellAvailable(_ElementalBlast, timeShift) and
		currentSpell ~= _ElementalBlast then
		return _ElementalBlast;
	end

	if talents[_LiquidMagmaTotem] and MaxDps:SpellAvailable(_LiquidMagmaTotem, timeShift) then
		return _LiquidMagmaTotem;
	end

	if talents[_Stormkeeper] and not ascendance and
		MaxDps:SpellAvailable(_Stormkeeper, timeShift) and currentSpell ~= _Stormkeeper then
		return _Stormkeeper;
	end

	if MaxDps:Aura(_PoweroftheMaelstrom, timeShift) and lavaCharges < 2 then
		return _LightningBolt;
	end

	if talents[_Icefury] and MaxDps:Aura(_Icefury, timeShift) and mael >= 20 then
		return _FrostShock;
	end

	if mael >= 92 and not MaxDps:TargetAura(_ExposedElements, timeShift) then
		return _EarthShock;
	end

	if (lavaCharges >= 1.3 or (not talents[_EchoOfTheElements] and lavaCharges >= 1)) and currentSpell ~= _LavaBurst
	then
		return _LavaBurst;
	end

	if mael >= 60 and not MaxDps:TargetAura(_LavaSurge, timeShift) then
		return _EarthShock;
	end

	return _LightningBolt;
end

function Shaman:Enhancement(timeShift, currentSpell, gcd, talents)
	local healthPct = UnitHealth('player') / UnitHealthMax('player') * 100;
	local mael = UnitPower('player', Enum.PowerType.Maelstrom);

	local rockbCd, rockbCharges = MaxDps:SpellCharges(_Rockbiter, timeShift);

	local stormstrike = _Stormstrike;
	if MaxDps:Aura(_AscendanceEnh, timeShift) and not MaxDps:FindSpell(_Stormstrike) then
		stormstrike = _Windstrike;
	end

	local fs, fsCd = MaxDps:SpellAvailable(_FeralSpirit, timeShift);
	local ft, ftCd = MaxDps:SpellAvailable(_Flametongue, timeShift);

	MaxDps:GlowCooldown(_FeralSpirit, fs);
	MaxDps:GlowCooldown(_AscendanceEnh, talents[_AscendanceEnh] and MaxDps:SpellAvailable(_AscendanceEnh, timeShift));
	MaxDps:GlowCooldown(_LightningShield, talents[_LightningShield] and not MaxDps:Aura(_LightningShield, timeShift + 4));

	-- 1. Cast Rockbiter with Landslide if the buff is not currently active and you are about to reach 2 charges.
	if talents[_Landslide] and not MaxDps:Aura(_Landslide, timeShift) and rockbCharges >= 1.7 then
		return _Rockbiter;
	end

	-- 2. Cast Fury of Air if it is not present.
	if talents[_FuryofAir] and not MaxDps:Aura(_FuryofAir) then
		return _FuryofAir;
	end

	-- 3. Cast Totem Mastery if not active.
	if talents[_TotemMastery] then
		local totemMastery, tmExp = Shaman:TotemMastery();
		if tmExp < 10 or not MaxDps:Aura(_StormTotem, timeShift) then
			return _TotemMastery;
		end
	end

	-- 4. Cast Windstrike during Ascendence with Stormbringer active.
	if talents[_AscendanceEnh] and MaxDps:Aura(_AscendanceEnh) and (
		MaxDps:Aura(_Stormbringer, timeShift) or
		(MaxDps:SpellAvailable(_Windstrike, timeShift) and mael >= 30)
	) then
		return _Windstrike;
	end

	-- 5. Cast Flametongue if the buff is not active.
	if not MaxDps:Aura(_Flametongue, timeShift) and ft then
		return _Flametongue;
	end

	-- 6. Cast Earthen Spike.
	if talents[_EarthenSpike] and MaxDps:SpellAvailable(_EarthenSpike, timeShift) and mael >= 20 then
		return _EarthenSpike;
	end

	-- 7. Cast Frostbrand with Hailstorm to maintain the Hailstorm buff.
	if talents[_Hailstorm] and not MaxDps:Aura(_Frostbrand, timeShift) and mael >= 20 then
		return _Frostbrand;
	end

	-- 8. Cast Stormstrike with Stormbringer active.
	if MaxDps:Aura(_Stormbringer, timeShift) then
		return stormstrike;
	end

	-- 10. Cast Lava Lash with Hot Hand procs.
	if talents[_HotHand] and MaxDps:Aura(_HotHand, timeShift) then
		return _LavaLash;
	end

	-- 11. Cast Stormstrike.
	if MaxDps:SpellAvailable(_Stormstrike, timeShift) and mael >= 30  then
		return stormstrike;
	end

	-- 12. Cast Lightning Bolt with Fury of Air and Overcharge if above 50 Maelstrom.
	if talents[_Overcharge] and MaxDps:SpellAvailable(_LightningBoltEnh, timeShift) and (
		(mael >= 50 and talents[_FuryofAir]) or
		(mael >= 40 and not talents[_FuryofAir])
	) then
		return _LightningBoltEnh;
	end

	-- 13. Cast Flametongue to trigger Searing Assault.
	if talents[_SearingAssault] and not MaxDps:TargetAura(_SearingAssault, timeShift) and ft then
		return _Flametongue;
	end

	-- 14. Cast Sundering
	if talents[_Sundering] and MaxDps:SpellAvailable(_Sundering, timeShift) and mael >= 20 then
		return _Sundering;
	end

	-- 15. Cast Rockbiter if below 70 Maelstrom and about to reach 2 charges.
	if rockbCharges >= 1.7 and mael < 70 then
		return _Rockbiter;
	end

	-- 16. Cast Flametongue if the buff is about to expire. -- @todo: not sure about that
	if not MaxDps:Aura(_Flametongue, timeShift + 4) and ft then
		return _Flametongue;
	end

	-- 17. Cast Frostbrand with Hailstorm if buff is about to expire.
	if talents[_Hailstorm] and not MaxDps:Aura(_Frostbrand, timeShift + 4) then
		return _Frostbrand;
	end

	-- 18. Cast Lava Lash with Fury of Air if above 50 Maelstrom.
	if talents[_FuryofAir] then
		if mael > 50 then
			return _LavaLash;
		end
	else
		if mael > 40 then
			return _LavaLash;
		end
	end

	-- 19. Cast Rockbiter
	if rockbCharges >= 1 then
		return _Rockbiter;
	end

	-- 20. Cast Flametongue if nothing else
	if ftCd < rockbCd then
		return _Flametongue;
	else
		return _Rockbiter;
	end
end

function Shaman:Restoration(timeShift, currentSpell, gcd, talents)
	local healthPct = UnitHealth('player') / UnitHealthMax('player') * 100;
	local lavaCd, lavaCharges = MaxDps:SpellCharges(_LavaBurst, timeShift);
	local ashift = MaxDps:SpellAvailable(_AstralShift, timeShift);
	local eet = MaxDps:SpellAvailable(_EarthElemental, timeShift);
	local fs = MaxDps:TargetAura(_FlameShockResto, 4 + timeShift);

	if currentSpell == _LavaBurst then
		if lavaCharges > 0 then
			lavaCharges = lavaCharges - 1;
		end
	end

	MaxDps:GlowCooldown(_EarthElemental, eet);

	-- May as well get a shot off before they run towards you!
	if not UnitAffectingCombat('player') then
		return _LightningBoltResto;
	end

	if not fs and MaxDps:SpellAvailable(_FlameShockResto, timeShift) then
		return _FlameShockResto;
	end

	if MaxDps:Aura(_PoweroftheMaelstrom, timeShift) and lavaCharges < 2 then
		return _LightningBoltResto;
	end

	if lavaCd <= 0 then
		return _LavaBurst;
	end

	return _LightningBoltResto;
end

function Shaman:Totem()
	local have, totemName, startTime, duration = GetTotemInfo(1);
	if not have then
		return '', 0;
	end;
	local expiration = startTime + duration - GetTime();
	return totemName, expiration;
end

function Shaman:TotemMastery()
	local tmName = GetSpellInfo(_TotemMastery);

	for i = 1, 4 do
		local haveTotem, totemName, startTime, duration = GetTotemInfo(i);
		if haveTotem and totemName == tmName then
			return true, startTime + duration - GetTime();
		end
	end
	return false, 0;
end