-- Kwibus In Combat (KIC)
-- Massive, impossible-to-miss on-screen text alerting you that you just got into combat (or that the enemy finally died).
KwibusRandomThings = KwibusRandomThings or {}
local KRT = KwibusRandomThings
local EM = EVENT_MANAGER
local WM = WINDOW_MANAGER
local ADDON_NAME = KRT.name

local EnsureTable = KRT.EnsureTable
local IsNonEmptyString = KRT.IsNonEmptyString
local DebounceNextFrame = KRT.DebounceNextFrame
local RGBToHex = KRT.RGBToHex

local DEFAULTS = { kic = {
    enabled = true,
    offsetX = 0,
    offsetY = -100,
    fontScale = 1.0,
    enableReposition = false,
    enterText = "IN COMBAT",
    exitText = "WOW ENEMY DIED",
    durationMs = 3000,
    enterColor = { r = 1, g = 0, b = 0 },
    exitColor = { r = 0, g = 1, b = 0 },
} }

KRT.KIC = {
    id = "kic",
    defaults = DEFAULTS.kic,
    hideTimerId = nil,
}

local FALLBACK_COLOR = { r = 1, g = 1, b = 1 } -- Safe white color in case user settings give us nil

function KRT.KIC:SV()
    return KRT.GetModuleSV(self.id, self.defaults)
end
local function SV() return KRT.KIC:SV() end

-- Cancels any pending hide timer so rapid combat transitions don't blink out early
local function KIC_CancelHide()
    if KRT.KIC.hideTimerId ~= nil then
        zo_removeCallLater(KRT.KIC.hideTimerId)
        KRT.KIC.hideTimerId = nil
    end
end

-- Anchors the overlay window using stored offsets
function KRT.KIC:ApplyAnchor()
    KRT.ApplyCenterAnchor(KwibusInCombat_UI, self:SV(), DEFAULTS.kic.offsetY)
end

-- Applies user's custom font scaling factor
function KRT.KIC:ApplyFontScale()
    local sv = self:SV()
    if not (KwibusInCombat_UIText and sv) then return end
    KwibusInCombat_UIText:SetScale(sv.fontScale or 1.0)
end

-- Enables dragging the frame around the screen in reposition mode
function KRT.KIC:EnableDragging(enable)
    local sv = self:SV()
    local ui = KwibusInCombat_UI
    local bg = KwibusInCombat_UIDragBG
    local label = KwibusInCombat_UIText
    if bg then
        bg:SetHidden(not enable)
        bg:SetMouseEnabled(false)
    end
    KRT.EnableDragging(ui, label, sv, enable, function() self:ApplyAnchor() end)
end

-- Displays the combat alert text with a given color and self-destruct timer
function KRT.KIC:ShowMessage(text, color, durationMs)
    local sv = self:SV()
    if not (sv and sv.enabled) then return end
    if not (KwibusInCombat_UI and KwibusInCombat_UIText) then return end

    KIC_CancelHide()

    KwibusInCombat_UIText:SetText(text or "")
    local c = color or FALLBACK_COLOR
    KwibusInCombat_UIText:SetColor(c.r or 1, c.g or 1, c.b or 1, 1)

    KwibusInCombat_UI:SetHidden(false)

    -- Auto-hide after the specified duration (unless reposition mode is on)
    self.hideTimerId = zo_callLater(function()
        local sv2 = self:SV()
        if not (sv2 and sv2.enableReposition) then
            KwibusInCombat_UI:SetHidden(true)
        end
        self.hideTimerId = nil
    end, durationMs or 3000)
end

-- Triggers enter/exit combat messages
function KRT.KIC:OnCombatStateChanged(inCombat)
    local sv = self:SV()
    if not (sv and sv.enabled) then return end
    if sv.enableReposition then return end -- Don't interrupt preview/move mode
    if inCombat then
        self:ShowMessage(sv.enterText, sv.enterColor, sv.durationMs)
    else
        self:ShowMessage(sv.exitText, sv.exitColor, sv.durationMs)
    end
end

-- Helpful test command so you don't have to go aggro a mudcrab just to test your text
function KRT.KIC:RegisterSlashCommands()
    SLASH_COMMANDS["/kic"] = function(arg)
        arg = (arg or ""):lower()
        if arg == "test" then
            local sv = self:SV()
            if not sv then return end
            local prevMove = sv.enableReposition
            sv.enableReposition = false
            self:EnableDragging(false)
            self:ShowMessage(sv.enterText, sv.enterColor, sv.durationMs)
            zo_callLater(function()
                self:ShowMessage(sv.exitText, sv.exitColor, sv.durationMs)
                sv.enableReposition = prevMove
                self:EnableDragging(prevMove)
            end, (sv.durationMs or 3000) + 500)
        else
            d("[KRT] Type '/kic test' to preview combat alert messages.")
        end
    end
end

-- =========================================================
-- Initialization
-- =========================================================
function KRT.KIC:Initialize()
    local sv = self:SV()
    if not sv then return end

    self:ApplyAnchor()
    self:ApplyFontScale()
    self:EnableDragging(sv.enableReposition)

    if sv.enableReposition then
        KIC_CancelHide()
        self:ShowMessage("move me", { r = 1, g = 1, b = 1 }, 9999999)
    end

    EM:RegisterForEvent(ADDON_NAME .. "_KIC_Activated", EVENT_PLAYER_ACTIVATED, function()
        local sv2 = self:SV()
        if not (sv2 and sv2.enabled) then return end
        self:ApplyAnchor()
        self:ApplyFontScale()
    end)

    EM:RegisterForEvent(ADDON_NAME .. "_KIC_Combat", EVENT_PLAYER_COMBAT_STATE, function(_, inCombat)
        self:OnCombatStateChanged(inCombat)
    end)

    self:RegisterSlashCommands()
end

-- =========================================================
-- Settings Menu
-- =========================================================
function KRT.KIC:GetLAMSubmenu()
    return {
        type = "submenu",
        name = "Kwibus In Combat",
        controls = {
            {
                type = "checkbox",
                name = "Enable Module",
                getFunc = function() return SV().enabled end,
                setFunc = function(v)
                    SV().enabled = v
                    if not v then
                        KIC_CancelHide()
                        self:EnableDragging(false)
                        if KwibusInCombat_UI then KwibusInCombat_UI:SetHidden(true) end
                    end
                end,
                width = "full",
            },
            {
                type = "checkbox",
                name = "Enable Repositioning (Drag)",
                tooltip = "Shows a drag box and a 'move me' label so you can park the alert wherever you like.",
                getFunc = function() return SV().enableReposition end,
                setFunc = function(v)
                    SV().enableReposition = v
                    KRT.KIC:EnableDragging(v)
                    KRT.KIC:ApplyAnchor()
                    if v then
                        KRT.KIC.hideTimerId = nil
                        KRT.KIC:ShowMessage("move me", { r = 1, g = 1, b = 1 }, 9999999)
                    else
                        if KwibusInCombat_UI then KwibusInCombat_UI:SetHidden(true) end
                    end
                end,
                width = "full",
                disabled = function() return not SV().enabled end,
            },
            {
                type = "button",
                name = "Reset Horizontal Position",
                func = function() SV().offsetX = 0; KRT.KIC:ApplyAnchor() end,
                disabled = function() return not SV().enabled or not SV().enableReposition end,
                width = "half",
            },
            {
                type = "button",
                name = "Reset Vertical Position",
                func = function() SV().offsetY = DEFAULTS.kic.offsetY; KRT.KIC:ApplyAnchor() end,
                disabled = function() return not SV().enabled or not SV().enableReposition end,
                width = "half",
            },
            {
                type = "editbox",
                name = "Enter Combat Text",
                isMultiline = false,
                getFunc = function() return SV().enterText end,
                setFunc = function(v) SV().enterText = v end,
                width = "full",
                disabled = function() return not SV().enabled end,
            },
            {
                type = "editbox",
                name = "Exit Combat Text",
                isMultiline = false,
                getFunc = function() return SV().exitText end,
                setFunc = function(v) SV().exitText = v end,
                width = "full",
                disabled = function() return not SV().enabled end,
            },
            {
                type = "slider",
                name = "Text Scale",
                min = 0.5,
                max = 2.0,
                step = 0.05,
                getFunc = function() return SV().fontScale end,
                setFunc = function(v) SV().fontScale = v; KRT.KIC:ApplyFontScale() end,
                width = "full",
                disabled = function() return not SV().enabled end,
            },
            {
                type = "slider",
                name = "Duration (ms)",
                min = 500,
                max = 8000,
                step = 100,
                getFunc = function() return SV().durationMs end,
                setFunc = function(v) SV().durationMs = v end,
                width = "full",
                disabled = function() return not SV().enabled end,
            },
        }
    }
end

KRT:RegisterModule(KRT.KIC)
