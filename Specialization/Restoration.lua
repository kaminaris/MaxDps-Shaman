local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end
local MaxDps = MaxDps;

local Shaman = addonTable.Shaman;

local RT = {
    FlameShock    = 188389,
    LightningBolt = 188196,
    ChainLightning = 188443,
	LavaBurst = 51505,

    --CD
    EarthElemental = 198103,

    --Covenant Abilities
    --Kyrian
    VesperTotem = 324386,
    --Venthyr
    ChainHarvest = 320674,
    --NightFae
    FaeTransfusion = 328923,
    --Necrolord
    PrimordialWave = 326059,
};

local CN = {
    None      = 0,
    Kyrian    = 1,
    Venthyr   = 2,
    NightFae  = 3,
    Necrolord = 4
};

setmetatable(RT, Shaman.spellMeta);

function Shaman:Restoration()
    local fd = MaxDps.FrameData;
    local covenantId = fd.covenant.covenantId;
    fd.targets = MaxDps:SmartAoe();
    local cooldown = fd.cooldown;
    local buff = fd.buff;
    local debuff = fd.debuff;
	local targets = fd.targets;
    local gcd = fd.gcd;
    local targetHp = MaxDps:TargetPercentHealth() * 100;
    local health = UnitHealth('player');
    local healthMax = UnitHealthMax('player');
    local healthPercent = ( health / healthMax ) * 100;
    local currentSpell = fd.currentSpell;

    -- Update Talents
    MaxDps:CheckTalents();

    -- Essences
    MaxDps:GlowEssences();

    MaxDps:GlowCooldown(RT.EarthElemental, cooldown[RT.EarthElemental].ready);

    --Covenant
    --Kyrian
    if covenantId == CN.Kyrian and cooldown[RT.VesperTotem].ready then
        MaxDps:GlowCooldown(RT.VesperTotem, cooldown[RT.VesperTotem].ready);
    end

    --Venthyr
    if covenantId == CN.Venthyr and cooldown[RT.ChainHarvest].ready then
        MaxDps:GlowCooldown(RT.ChainHarvest, cooldown[RT.ChainHarvest].ready);
    end

    --NightFae
    if covenantId == CN.NightFae and cooldown[RT.FaeTransfusion].ready then
        MaxDps:GlowCooldown(RT.FaeTransfusion, cooldown[RT.FaeTransfusion].ready);
    end

    --Necrolord
    if covenantId == CN.Necrolord and cooldown[RT.PrimordialWave].ready then
        MaxDps:GlowCooldown(RT.PrimordialWave, cooldown[RT.PrimordialWave].ready);
    end

    if debuff[RT.FlameShock].remains < 1 and cooldown[RT.FlameShock].ready then
        return RT.FlameShock;
    end

	if cooldown[RT.LavaBurst].ready then
        return RT.LavaBurst;
    end

    if targets > 1 then
        return RT.ChainLightning;
    else
        return RT.LightningBolt;
    end

end