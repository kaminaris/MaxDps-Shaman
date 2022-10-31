local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then
	return
end
local MaxDps = MaxDps;
local UnitPower = UnitPower;
local GetTotemInfo = GetTotemInfo;
local GetTime = GetTime;

local Necrolord = Enum.CovenantType.Necrolord;
local Venthyr = Enum.CovenantType.Venthyr;
local NightFae = Enum.CovenantType.NightFae;
local Kyrian = Enum.CovenantType.Kyrian;

local Shaman = addonTable.Shaman;

local EH = {
	Ascendance = 114051,
	AshenCatalyst = 390371,
	ChainHarvest = 320674,
	ChainLightning = 188443,
	ChainLightningBuff = 333964,
	CrashLightning = 187874,
	DeeplyRootedElements = 378270,
	DoomWinds = 384352,
	EarthElemental = 198103,
	ElementalBlast = 117014,
	FaeTransfusion = 328928,
	FeralSpirit = 51533,
	FeralSpiritBuff = 333957,
	FireNova = 333974,
	FlameShock = 188389,
	FlametongueWeapon = 318038,
	FlametongueWeaponEnchantID = 5400,
	FrostShock = 196840,
	GatheringStorms = 384363,
	HailstormBuff = 334196,
	HotHand = 201900,
	IceStrike = 342240,
	LashingFlamesDebuff = 334168,
	LavaBurst = 51505,
	LavaLash = 60103,
	LegacyOfTheFrostWitchBuff = 384451,
	LightningBolt = 188196,
	LightningShield = 192106,
	MaelstromWeapon = 344179,
	MoltenWeapon = 224125,
	NecrolordPrimordialWave = 326059,
	PrimordialWave = 375982,
	PrimordialWaveBuff = 375986,
	Stormbringer = 201845,
	Stormstrike = 17364,
	Sundering = 197214,
	SwirlingMaelstrom = 384359,
	ThorimsInvocation = 384444,
	VesperTotem = 324386,
	WindfuryTotem = 8512,
	WindfuryWeapon = 33757,
	WindfuryWeaponEnchantID = 5401,
	Windstrike = 115356
};

setmetatable(EH, Shaman.spellMeta);

local TotemIcons = {
	[136114] = 'Windfury'
}

function Shaman:Enhancement()
	local fd = MaxDps.FrameData;
	local targets = MaxDps:SmartAoe();
	fd.totems = Shaman:Totems();

	Shaman:EnhancementCooldowns()

	if targets <= 1 then
		return Shaman:EnhancementSingle();
	else
		return Shaman:EnhancementAoe();
	end
end

function Shaman:EnhancementCooldowns()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local talents = fd.talents;
	local buff = fd.buff;
	local inCombat = UnitAffectingCombat("player");

	-- feral_spirit;
	if talents[EH.FeralSpirit] then
		MaxDps:GlowCooldown(EH.FeralSpirit, cooldown[EH.FeralSpirit].ready);
	end

	local hasMainHandEnchant, mainHandExpiration, _, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, _, offHandEnchantID = GetWeaponEnchantInfo();
	local windfuryEnchantRemaining = false;
	local flametongueEnchantRemaining = false;

	if hasMainHandEnchant then
		if mainHandEnchantID == EH.WindfuryWeaponEnchantID then
			windfuryEnchantRemaining = mainHandExpiration / 1000;
		elseif mainHandEnchantID == EH.FlametongueWeaponEnchantID then
			flametongueEnchantRemaining = mainHandExpiration / 1000;
		end
	end

	if hasOffHandEnchant then
		if offHandEnchantID == EH.WindfuryWeaponEnchantID then
			windfuryEnchantRemaining = offHandExpiration / 1000;
		elseif offHandEnchantID == EH.FlametongueWeaponEnchantID then
			flametongueEnchantRemaining = offHandExpiration / 1000;
		end
	end

	if talents[EH.EarthElemental] then
		MaxDps:GlowCooldown(EH.EarthElemental, cooldown[EH.EarthElemental].ready);
	end

	if talents[EH.WindfuryWeapon] then
		MaxDps:GlowCooldown(EH.WindfuryWeapon, not windfuryEnchantRemaining or (not inCombat and windfuryEnchantRemaining <= 300));
	end
	MaxDps:GlowCooldown(EH.FlametongueWeapon, not flametongueEnchantRemaining or (not inCombat and flametongueEnchantRemaining <= 300));
	MaxDps:GlowCooldown(EH.LightningShield, not buff[EH.LightningShield].up or (not inCombat and buff[EH.LightningShield].remains <= 300));

	if talents[EH.Ascendance] then
		MaxDps:GlowCooldown(EH.Ascendance, cooldown[EH.Ascendance].ready);
	end

	if talents[EH.DoomWinds] then
		MaxDps:GlowCooldown(EH.DoomWinds, cooldown[EH.DoomWinds].ready);
	end

	local covenantId = fd.covenant.covenantId;

	if covenantId == NightFae then
		MaxDps:GlowCooldown(EH.FaeTransfusion, cooldown[EH.FaeTransfusion].ready);
	end

	if covenantId == Necrolord then
		MaxDps:GlowCooldown(EH.NecrolordPrimordialWave, cooldown[EH.NecrolordPrimordialWave].ready);
	end

	if covenantId == Kyrian then
		MaxDps:GlowCooldown(EH.VesperTotem, cooldown[EH.VesperTotem].ready);
	end

	if covenantId == Venthyr then
		MaxDps:GlowCooldown(EH.ChainHarvest, cooldown[EH.ChainHarvest].ready and buff[EH.MaelstromWeapon].count >= 5);
	end
end

function Shaman:EnhancementAoe()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;

	local talents = fd.talents;
	local totems = fd.totems;
	local activeFlameShock = MaxDps:DebuffCounter(EH.FlameShock, fd.timeShift);

	if talents[EH.WindfuryTotem] and totems.Windfury <= 10 then
		return EH.WindfuryTotem;
	end

	if cooldown[EH.FlameShock].ready and not debuff[EH.FlameShock].up and activeFlameShock < 6 then
		return EH.FlameShock;
	end

	if buff[EH.MaelstromWeapon].count >= 5 and buff[EH.PrimordialWaveBuff].up then
		return EH.LightningBolt;
	end

	if buff[EH.MaelstromWeapon].count == 10 and talents[EH.ChainLightning] then
		return EH.ChainLightning;
	end

	if talents[EH.DoomWinds] and cooldown[EH.DoomWinds].ready then
		return EH.DoomWinds;
	end

	if buff[EH.DoomWinds].up then
		if talents[EH.CrashLightning] and cooldown[EH.CrashLightning].ready then
			return EH.CrashLightning;
		end

		if talents[EH.Sundering] and cooldown[EH.Sundering].ready then
			return EH.Sundering;
		end
	end

	if talents[EH.FireNova] and cooldown[EH.FireNova].ready and activeFlameShock == 6 then
		return EH.FireNova;
	end

	if talents[EH.IceStrike] and cooldown[EH.IceStrike].ready then
		return EH.IceStrike;
	end

	if talents[EH.FrostShock] and cooldown[EH.FrostShock].ready and buff[EH.HailstormBuff].up then
		return EH.FrostShock;
	end

	if talents[EH.Sundering] and cooldown[EH.Sundering].ready and (buff[EH.LegacyOfTheFrostWitchBuff].up or buff[EH.MoltenWeapon].up) then
		return EH.Sundering;
	end

	if talents[EH.CrashLightning] and cooldown[EH.CrashLightning].ready and not buff[EH.CrashLightning].up then
		return EH.CrashLightning;
	end

	local Windstrike = MaxDps:FindSpell(EH.Windstrike) and EH.Windstrike or nil;
	if Windstrike and buff[EH.Ascendance].up and cooldown[Windstrike].ready and talents[EH.ThorimsInvocation] then
		return Windstrike;
	end

	if talents[EH.PrimordialWave] and cooldown[EH.PrimordialWave].ready then
		return EH.PrimordialWave;
	end

	if cooldown[EH.FlameShock].ready and not debuff[EH.FlameShock].up then
		return EH.FlameShock;
	end

	if talents[EH.DeeplyRootedElements] then
		if Windstrike and buff[EH.Ascendance].up and cooldown[EH.Windstrike].ready then
			return Windstrike;
		end

		if talents[EH.Stormstrike] and cooldown[EH.Stormstrike].ready then
			return EH.Stormstrike;
		end
	end

	if talents[EH.LavaLash] and cooldown[EH.LavaLash].ready and not debuff[EH.LashingFlamesDebuff].up then
		return EH.LavaLash;
	end

	if buff[EH.ChainLightningBuff].up and talents[EH.CrashLightning] and cooldown[EH.CrashLightning].ready then
		return EH.CrashLightning;
	end

	if talents[EH.Sundering] and cooldown[EH.Sundering].ready then
		return EH.Sundering;
	end

	if talents[EH.FireNova] and cooldown[EH.FireNova].ready and activeFlameShock >= 4 then
		return EH.FireNova;
	end

	if talents[EH.LavaLash] and cooldown[EH.LavaLash].ready then
		return EH.LavaLash;
	end

	if talents[EH.ElementalBlast] and cooldown[EH.ElementalBlast].ready
			and buff[EH.MaelstromWeapon].count >= 5
			and buff[EH.FeralSpiritBuff].up then
		return EH.ElementalBlast;
	end

	if Windstrike and buff[EH.Ascendance].up and cooldown[EH.Windstrike].ready then
		return Windstrike;
	end

	if talents[EH.Stormstrike] and cooldown[EH.Stormstrike].ready then
		return EH.Stormstrike;
	end

	if talents[EH.CrashLightning] and cooldown[EH.CrashLightning].ready then
		return EH.CrashLightning;
	end

	if talents[EH.FireNova] and cooldown[EH.FireNova].ready and activeFlameShock >= 2 then
		return EH.FireNova;
	end

	if talents[EH.ChainLightning] and buff[EH.MaelstromWeapon].count >= 5 then
		return EH.ChainLightning;
	end

	if talents[EH.FrostShock] and cooldown[EH.FrostShock].ready then
		return EH.FrostShock;
	end

	if talents[EH.WindfuryTotem] then
		return EH.WindfuryTotem;
	end
end

function Shaman:EnhancementSingle()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local totems = fd.totems;

	if talents[EH.WindfuryTotem] and totems.Windfury <= 10 then
		return EH.WindfuryTotem;
	end

	local Windstrike = MaxDps:FindSpell(EH.Windstrike) and EH.Windstrike or nil;
	if Windstrike and buff[EH.Ascendance].up and cooldown[Windstrike].ready then
		return Windstrike;
	end

	if talents[EH.LavaLash] and cooldown[EH.LavaLash].ready and (buff[EH.HotHand].up or buff[EH.AshenCatalyst].count > 6) then
		return EH.LavaLash
	end

	if buff[EH.DoomWinds].up then
		if talents[EH.IceStrike] and cooldown[EH.IceStrike].ready then
			return EH.IceStrike;
		end

		if talents[EH.Stormstrike] and cooldown[EH.Stormstrike].ready then
			return EH.Stormstrike;
		end

		if talents[EH.CrashLightning] and cooldown[EH.CrashLightning].ready then
			return EH.CrashLightning;
		end

		if talents[EH.Sundering] and cooldown[EH.Sundering].ready then
			return EH.Sundering;
		end
	end

	if cooldown[EH.FlameShock].ready and not debuff[EH.FlameShock].up then
		return EH.FlameShock;
	end

	if buff[EH.MaelstromWeapon].count >= 5 and buff[EH.PrimordialWaveBuff].up then
		return EH.LightningBolt;
	end

	if talents[EH.PrimordialWave] and not buff[EH.PrimordialWaveBuff].up and cooldown[EH.PrimordialWave].ready then
		return EH.PrimordialWave
	end

	if buff[EH.MaelstromWeapon].count >= 5 and buff[EH.FeralSpiritBuff].up then
		if talents[EH.ElementalBlast] then
			if cooldown[EH.ElementalBlast].ready then return EH.ElementalBlast end;
		elseif talents[EH.LavaBurst] then
			if cooldown[EH.LavaBurst].ready then return EH.LavaBurst end;
		end
	end

	if talents[EH.Sundering] and cooldown[EH.Sundering].ready and (buff[EH.LegacyOfTheFrostWitchBuff].up or buff[EH.MoltenWeapon].up) then
		return EH.Sundering;
	end

	if talents[EH.IceStrike] and cooldown[EH.IceStrike].ready then
		return EH.IceStrike;
	end

	if talents[EH.FrostShock] and cooldown[EH.FrostShock].ready and buff[EH.HailstormBuff].up then
		return EH.FrostShock;
	end

	if talents[EH.LavaLash] and cooldown[EH.LavaLash].ready and debuff[EH.FlameShock].refreshable then
		return EH.LavaLash;
	end

	if talents[EH.Stormstrike] and cooldown[EH.Stormstrike].ready and buff[EH.Stormbringer].up then
		return EH.Stormstrike;
	end

	if buff[EH.MaelstromWeapon].count >= 5 then
		if talents[EH.ElementalBlast] then
			if cooldown[EH.ElementalBlast].ready and cooldown[EH.ElementalBlast].charges == cooldown[EH.ElementalBlast].maxCharges then
				return EH.ElementalBlast
			end
		elseif talents[EH.LavaBurst] and cooldown[EH.LavaBurst].ready then
			return EH.LavaBurst;
		end
	end

	if buff[EH.MaelstromWeapon].count == 10 then
		if talents[EH.ElementalBlast] and cooldown[EH.ElementalBlast].ready then
			return EH.ElementalBlast;
		end
		return EH.LightningBolt;
	end

	if talents[EH.Stormstrike] and cooldown[EH.Stormstrike].ready then
		return EH.Stormstrike;
	end

	if talents[EH.LavaLash] and cooldown[EH.LavaLash].ready then
		return EH.LavaLash;
	end

	if buff[EH.MaelstromWeapon].count == 5 then
		return EH.LightningBolt;
	end

	if talents[EH.Sundering] and cooldown[EH.Sundering].ready and talents[EH.LavaLash] and cooldown[EH.LavaLash].ready then
		return EH.LavaLash;
	end

	if talents[EH.SwirlingMaelstrom] and talents[EH.FireNova] and cooldown[EH.FireNova].ready and debuff[EH.FlameShock].up then
		return EH.FireNova;
	end

	if talents[EH.FrostShock] and cooldown[EH.FrostShock].ready then
		return EH.FrostShock;
	end

	if talents[EH.CrashLightning] and cooldown[EH.CrashLightning].ready then
		return EH.CrashLightning;
	end

	if talents[EH.FireNova] and debuff[EH.FlameShock].up and cooldown[EH.FireNova].ready then
		return EH.FireNova;
	end

	if cooldown[EH.FlameShock].ready then
		return EH.FlameShock;
	end
end


function Shaman:Totems()
	local pets = {
		Windfury = 0,
	};

	for index = 1, MAX_TOTEMS do
		local hasTotem, _, startTime, duration, icon = GetTotemInfo(index);
		if hasTotem then
			local totemUnifiedName = TotemIcons[icon];
			if totemUnifiedName then
				local remains = startTime + duration - GetTime();
				pets[totemUnifiedName] = remains;
			end
		end
	end

	return pets;
end