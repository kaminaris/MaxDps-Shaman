local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end

local MaxDps = MaxDps;
local Shaman = addonTable.Shaman;

local RT = {
	ChainLightning = 188443,
	EarthlivingWeapon = 382021,
	EarthlivingEnchantId = 6498,
	FlameShock = 188389,
	LightningBolt = 188196,
	LavaBurst = 51505,
	WaterShield = 52127
};

function Shaman:Restoration()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local debuff = fd.debuff;
	local buff = fd.buff;

	MaxDps:GlowCooldown(RT.WaterShield, not buff[RT.WaterShield].up);

	local hasMainHandEnchant, mainHandExpiration, _, mainHandEnchantID, _, _, _, _ = GetWeaponEnchantInfo();
	local earthLivingEnchantRemaining = false;

	if hasMainHandEnchant then
		if mainHandEnchantID == RT.EarthlivingEnchantId then
			earthLivingEnchantRemaining = mainHandExpiration / 1000;
		end
	end

	local inCombat = UnitAffectingCombat("player");
	MaxDps:GlowCooldown(RT.EarthlivingWeapon, not earthLivingEnchantRemaining or (not inCombat and earthLivingEnchantRemaining <= 300));

	if not debuff[RT.FlameShock].up or debuff[RT.FlameShock].refreshable then
		return RT.FlameShock;
	end

	local targets = MaxDps:SmartAoe();
	if targets >= 3 then
		return RT.ChainLightning;
	end

	if cooldown[RT.LavaBurst].ready then
		return RT.LavaBurst;
	end

	if targets >= 2 then
		return RT.ChainLightning;
	end

	return RT.LightningBolt;
end