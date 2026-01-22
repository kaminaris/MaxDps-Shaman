local addonName, addonTable = ...
_G[addonName] = addonTable

--- @type MaxDps
if not MaxDps then return end
local MaxDps = MaxDps
local GetSpellInfo = C_Spell and C_Spell.GetSpellInfo or _G.GetSpellInfo
local GetTotemInfo = GetTotemInfo
local GetTime = GetTime

local Shaman = MaxDps:NewModule('Shaman')
addonTable.Shaman = Shaman

Shaman.spellMeta = {
    __index = function(t, k)
        print('Spell Key ' .. k .. ' not found!')
    end
}

function Shaman:Enable()
    if MaxDps.Spec == 1 then
        MaxDps.NextSpell = Shaman.Elemental
        MaxDps:Print(MaxDps.Colors.Info .. 'Shaman Elemental', "info")
    elseif MaxDps.Spec == 2 then
        MaxDps.NextSpell = Shaman.Enhancement
        MaxDps:Print(MaxDps.Colors.Info .. 'Shaman Enhancement', "info")
    elseif MaxDps.Spec == 3 then
        MaxDps.NextSpell = Shaman.Restoration
        MaxDps:Print(MaxDps.Colors.Info .. 'Shaman Restoration', "info")
    end

    return true
end

function Shaman:TotemMastery(totem)
    local tmName = C_Spell and GetSpellInfo(totem).name or GetSpellInfo(totem)

    for i = 1, 4 do
        local haveTotem, totemName, startTime, duration = GetTotemInfo(i)

        if haveTotem and totemName == tmName then
            return startTime + duration - GetTime()
        end
    end

    return 0
end

if not MaxDps:IsRetailWow() then
    local spellTracker = CreateFrame("Frame")
    spellTracker:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    spellTracker:RegisterEvent("CHALLENGE_MODE_START")
    spellTracker:RegisterEvent("ENCOUNTER_START")
    spellTracker:RegisterEvent("PLAYER_DEAD")
    spellTracker:RegisterEvent("TRAIT_CONFIG_UPDATED")
    
    MaxDps.TWW3ProcsToAsc = 8
    MaxDps.tww3_procs_to_asc = function ()
        return MaxDps.TWW3ProcsToAsc
    end
    
    spellTracker:SetScript("OnEvent", function(self, event)
        if event == "CHALLENGE_MODE_START" or event == "ENCOUNTER_START" or event == "PLAYER_DEAD" or event == "TRAIT_CONFIG_UPDATED" then
            MaxDps.TWW3ProcsToAsc = 8
        end
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            if not MaxDps.tier or not MaxDps.tier[34].count then return end
            local subtype = select(2, CombatLogGetCurrentEventInfo())
            --timestamp, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId
            local _, _, _, sourceGUID, _, _, _, _, _, _, _, spellId = CombatLogGetCurrentEventInfo()
            if sourceGUID ~= UnitGUID("player") then return end
            if spellId == 462131 and MaxDps.tier[34].count >= 2 then
                if subtype == "SPELL_AURA_APPLIED" or subtype == "SPELL_AURA_APPLIED_DOSE" then
                    MaxDps.TWW3ProcsToAsc = MaxDps.TWW3ProcsToAsc - 1
                    if MaxDps.TWW3ProcsToAsc <= 0 then
                        MaxDps.TWW3ProcsToAsc = 8
                    end
                end
            end
        end
    end)
end