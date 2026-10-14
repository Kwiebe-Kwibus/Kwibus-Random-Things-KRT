-- Kwibus Group User ID (GUID)
-- Standardizes display names across groups, leaderboards, and rosters so you know who is actually who.
KwibusRandomThings = KwibusRandomThings or {}
local KRT = KwibusRandomThings

local DEFAULTS = { guid = {
    enabled = true,
    stripAtSymbol = true,
} }

KRT.GUID = {
    id = "guid",
    defaults = DEFAULTS.guid,
}
local function SV()
    return KRT.GetModuleSV("guid", DEFAULTS.guid)
end

-- Helper to decapitate the "@" from an account name (e.g., "@PlayerOne" -> "PlayerOne")
local function StripAt(name)
    if type(name) == "string" and SV().stripAtSymbol then
        if name:byte(1) == 64 then
            return name:sub(2)
        end
    end
    return name
end

-- =========================================================
-- UI Post-Hooks (Each returns false so ESO doesn't swallow original logic)
-- =========================================================

-- Replaces character names in the group window with the player's account name
local function groupEntryPostHook(selfControl, control, data)
    if not SV().enabled then return false end
    if not ZO_ShouldPreferUserId() then return false end
    
    control.characterNameLabel:SetText(zo_strformat(SI_GROUP_LIST_PANEL_CHARACTER_NAME, data.index, StripAt(data.displayName)))
    return false
end

-- Overrides leaderboard entries to display cleaner account names
local function leaderboardEntryPostHook(selfControl, control, data)
    if not SV().enabled then return false end
    if not ZO_ShouldPreferUserId() then return false end
    
    control.nameLabel:SetText(StripAt(data.displayName))
    return false
end

-- Makes the current Cyrodiil Emperor's name show up as their account name (and adds a tooltip for their character)
local function refreshEmperorPostHook(selfControl, control, data)
    if not SV().enabled then return false end
    if not ZO_ShouldPreferUserId() then return false end
    
    if DoesCampaignHaveEmperor(selfControl.campaignId) then
        local alliance, characterName, displayName = GetCampaignEmperorInfo(selfControl.campaignId)
        local emperorName = selfControl.emperorName
        if not emperorName then return false end
        
        emperorName:SetText(StripAt(displayName))
        emperorName:SetMouseEnabled(true)
        emperorName:SetHandler("OnMouseEnter", function(empControl)
            ZO_Tooltips_ShowTextTooltip(empControl, TOP, characterName)
        end)
        emperorName:SetHandler("OnMouseExit", function(empControl)
            ZO_Tooltips_HideTextTooltip()
        end)
    end
    return false
end

-- Enhances the hover tooltip on social list rows to show clean account names
local function socialListOnMouseEnterPostHook(selfControl, control)
    if not SV().enabled then return false end
    if not ZO_ShouldPreferUserId() then return false end
    
    local row = control:GetParent()
    local data = ZO_ScrollList_GetData(row)
    InitializeTooltip(InformationTooltip)
    local textwidth = control:GetTextDimensions()
    InformationTooltip:ClearAnchors()
    InformationTooltip:SetAnchor(BOTTOM, control, TOPLEFT, textwidth * 0.5, 0)
    
    local tooltipText = data.characterName or data.name
    SetTooltipText(InformationTooltip, StripAt(tooltipText))
    
    return false
end

-- Ensures your friends list respects account names without the '@' prefix
local function friendsListEntryPostHook(selfControl, control, data)
    if not SV().enabled then return false end
    
    local nameLabel = control:GetNamedChild("Name")
    if nameLabel and ZO_ShouldPreferUserId() then
        nameLabel:SetText(StripAt(data.displayName))
    end
    return false
end

-- Keeps the guild roster cleanly formatted
local function guildRosterEntryPostHook(selfControl, control, data)
    if not SV().enabled then return false end
    
    local nameLabel = control:GetNamedChild("DisplayName")
    if nameLabel and ZO_ShouldPreferUserId() then
        nameLabel:SetText(StripAt(data.displayName))
    end
    return false
end

-- =========================================================
-- Initialization & Registration
-- =========================================================
function KRT.GUID:Initialize()
    if GROUP_LIST then
        ZO_PostHook(GROUP_LIST, "SetupGroupEntry", groupEntryPostHook)
    end
    if ZO_LeaderboardsManager_Shared then
        ZO_PostHook(ZO_LeaderboardsManager_Shared, "SetupLeaderboardPlayerEntry", leaderboardEntryPostHook)
    end
    if CampaignEmperor_Shared then
        ZO_PostHook(CampaignEmperor_Shared, "SetupLeaderboardEntry", leaderboardEntryPostHook)
        ZO_PostHook(CampaignEmperor_Shared, "RefreshEmperor", refreshEmperorPostHook)
    end
    if ZO_SocialListKeyboard then
        ZO_PostHook(ZO_SocialListKeyboard, "CharacterName_OnMouseEnter", socialListOnMouseEnterPostHook)
    end
    
    if ZO_KeyboardFriendsList then
        ZO_PostHook(ZO_KeyboardFriendsList, "SetupFriendRow", friendsListEntryPostHook)
    end
    if ZO_GuildRosterManager then
        ZO_PostHook(ZO_GuildRosterManager, "SetupGuildRosterRow", guildRosterEntryPostHook)
    end
end

function KRT.GUID:GetLAMSubmenu()
    return {
        type = "submenu",
        name = "Group User ID",
        controls = {
            {
                type = "checkbox",
                name = "Enable Module",
                tooltip = "When ESO's 'Prefer User IDs' setting is enabled, this ensures account names are shown consistently in the group list, leaderboards, Emperor display, and social panels.",
                getFunc = function() return SV().enabled end,
                setFunc = function(v) SV().enabled = v end,
                default = DEFAULTS.guid.enabled,
                width = "full",
            },
        }
    }
end

KRT:RegisterModule(KRT.GUID)
