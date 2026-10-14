-- Kwibus Overload Watcher (KOW)
-- Simple on-screen reminder that screams at you while Sorcerer Overload is toggled on so you don't drain all your ultimate into the void.
KwibusRandomThings = KwibusRandomThings or {}
local KRT = KwibusRandomThings
local EM = EVENT_MANAGER
local WM = WINDOW_MANAGER
local ADDON_NAME = KRT.name

local IsNonEmptyString = KRT.IsNonEmptyString
local DebounceNextFrame = KRT.DebounceNextFrame

local DEFAULTS = { kow = {
    enabled = true,
    text = "overload",
    fontScale = 1.0,
    offsetX = 0,
    offsetY = 0,
    enableReposition = false,
    textSide = "center", -- "left", "center", "right"
    color = { r = 1, g = 0.85, b = 0.2 },
} }

KRT.KOW = {
    id = "kow",
    defaults = DEFAULTS.kow,
    TARGET_BUFF_ID = 24806, -- Overload buff ID

    ui = nil,
    lbl = nil,
}

function KRT.KOW:SV()
    return KRT.GetModuleSV(self.id, self.defaults)
end

-- Checks if your player currently has the Overload toggle buff active
function KRT.KOW:HasOverloadBuff()
    local numBuffs = GetNumBuffs("player")
    for i = 1, numBuffs do
        local _, _, _, _, _, _, _, _, _, _, abilityId = GetUnitBuffInfo("player", i)
        if abilityId == self.TARGET_BUFF_ID then
            return true
        end
    end
    return false
end

-- Builds the top-level overlay on demand
function KRT.KOW:EnsureOverlay()
    if self.ui then return end
    local sv = self:SV()
    if not sv then return end

    local win = WM:CreateTopLevelWindow("KwibusOverloadWatcher_UI")
    win:SetDimensions(220, 60)
    win:SetHidden(true)
    win:SetMouseEnabled(false)
    win:SetMovable(false)
    win:SetClampedToScreen(true)
    win:SetDrawLayer(DL_OVERLAY)
    win:SetDrawTier(DT_HIGH)
    win:SetDrawLevel(9999)

    local label = WM:CreateControl("KwibusOverloadWatcher_Lbl", win, CT_LABEL)
    label:SetAnchor(CENTER, win, CENTER, 0, 0)
    label:SetFont("ZoFontWinH1")
    label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    label:SetVerticalAlignment(TEXT_ALIGN_CENTER)

    self.ui = win
    self.lbl = label

    self:ApplyAnchor()
    self:UpdateTextStyle()
end

-- Refreshes label font scaling, colors, and horizontal alignment
function KRT.KOW:UpdateTextStyle()
    local ui, lbl = self.ui, self.lbl
    if not (ui and lbl) then return end
    local sv = self:SV()
    if not sv then return end

    local text = IsNonEmptyString(sv.text) and sv.text or DEFAULTS.kow.text
    local scale = sv.fontScale or DEFAULTS.kow.fontScale
    local c = sv.color or DEFAULTS.kow.color
    local side = sv.textSide or "center"

    lbl:SetText(text)
    lbl:SetScale(scale)
    lbl:SetColor(c.r or 1, c.g or 0.85, c.b or 0.2, 1)

    if side == "left" then
        lbl:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    elseif side == "right" then
        lbl:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    else
        lbl:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    end

    KRT.ResizeTextHitbox("KOW_Resize", ui, lbl, scale, 80, 30)
end

-- Applies center anchor based on user offset coordinates
function KRT.KOW:ApplyAnchor()
    KRT.ApplyCenterAnchor(self.ui, self:SV(), DEFAULTS.kow.offsetY)
end

-- Toggles drag/move handles for window repositioning
function KRT.KOW:EnableDragging(enable)
    local sv = self:SV()
    KRT.EnableDragging(self.ui, self.lbl, sv, enable, function() self:ApplyAnchor() end, function() self:UpdateDisplay() end)
end

-- Updates overlay visibility depending on whether Overload is on (or preview mode is active)
function KRT.KOW:UpdateDisplay(hasBuff)
    local sv = self:SV()
    if not sv then return end
    if not self.ui then return end

    if not sv.enabled then
        self.ui:SetHidden(true)
        return
    end

    if sv.enableReposition then
        self.ui:SetHidden(false)
        return
    end

    if hasBuff == nil then
        hasBuff = self:HasOverloadBuff()
    end

    self.ui:SetHidden(not hasBuff)
end

-- =========================================================
-- Initialization
-- =========================================================
function KRT.KOW:Initialize()
    local sv = self:SV()
    if not sv then return end

    self:EnsureOverlay()
    self:ApplyAnchor()
    self:UpdateTextStyle()
    self:EnableDragging(sv.enableReposition)

    -- Listen for player effect changes specifically filtered to the Overload buff
    EM:RegisterForEvent(ADDON_NAME .. "_KOW_Effect", EVENT_EFFECT_CHANGED, function(_, changeType, _, _, _, _, _, _, _, _, _, _, _, _, abilityId)
        local sv2 = self:SV()
        if not (sv2 and sv2.enabled) then return end
        if abilityId ~= self.TARGET_BUFF_ID then return end

        if changeType == EFFECT_RESULT_GAINED then
            self:UpdateDisplay(true)
        elseif changeType == EFFECT_RESULT_FADED then
            self:UpdateDisplay(false)
        else
            self:UpdateDisplay()
        end
    end)
    EM:AddFilterForEvent(ADDON_NAME .. "_KOW_Effect", EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, "player")

    -- Initial state sync on load
    EM:RegisterForEvent(ADDON_NAME .. "_KOW_Activated", EVENT_PLAYER_ACTIVATED, function()
        local sv2 = self:SV()
        if not (sv2 and sv2.enabled) then return end
        self:ApplyAnchor()
        self:UpdateTextStyle()
        self:UpdateDisplay()
    end)
end

-- =========================================================
-- Settings Menu
-- =========================================================
local function SV() return KRT.sv end

function KRT.KOW:GetLAMSubmenu()
    return {
        type = "submenu",
        name = "Kwibus Overload Watcher",
        controls = {
            {
                type = "checkbox",
                name = "Enable Module",
                getFunc = function() return SV().kow.enabled end,
                setFunc = function(v)
                    SV().kow.enabled = v
                    if not v then
                        KRT.KOW:EnableDragging(false)
                        if KRT.KOW.ui then KRT.KOW.ui:SetHidden(true) end
                    else
                        KRT.KOW:UpdateDisplay()
                    end
                end,
                width = "full",
            },
            {
                type = "checkbox",
                name = "Enable Repositioning (Drag)",
                tooltip = "Allows you to drag and reposition the reminder overlay.",
                getFunc = function() return SV().kow.enableReposition end,
                setFunc = function(v)
                    SV().kow.enableReposition = v
                    KRT.KOW:EnableDragging(v)
                    KRT.KOW:ApplyAnchor()
                end,
                width = "full",
                disabled = function() return not SV().kow.enabled end,
            },
            {
                type = "button",
                name = "Reset Horizontal Position",
                func = function()
                    SV().kow.offsetX = 0
                    KRT.KOW:ApplyAnchor()
                end,
                width = "half",
                disabled = function() return not SV().kow.enabled or not SV().kow.enableReposition end,
            },
            {
                type = "button",
                name = "Reset Vertical Position",
                func = function()
                    SV().kow.offsetY = DEFAULTS.kow.offsetY
                    KRT.KOW:ApplyAnchor()
                end,
                width = "half",
                disabled = function() return not SV().kow.enabled or not SV().kow.enableReposition end,
            },
            {
                type = "editbox",
                name = "Reminder Text",
                isMultiline = false,
                getFunc = function() return SV().kow.text end,
                setFunc = function(v)
                    SV().kow.text = IsNonEmptyString(v) and v or DEFAULTS.kow.text
                    KRT.KOW:UpdateTextStyle()
                    KRT.KOW:UpdateDisplay()
                end,
                width = "full",
                disabled = function() return not SV().kow.enabled end,
            },
            {
                type = "slider",
                name = "Text Scale",
                min = 0.5,
                max = 3.0,
                step = 0.1,
                getFunc = function() return SV().kow.fontScale end,
                setFunc = function(v)
                    SV().kow.fontScale = v
                    KRT.KOW:UpdateTextStyle()
                end,
                width = "full",
                disabled = function() return not SV().kow.enabled end,
            },
            {
                type = "dropdown",
                name = "Text Side",
                choices = { "Left", "Center", "Right" },
                choicesValues = { "left", "center", "right" },
                getFunc = function() return SV().kow.textSide end,
                setFunc = function(v)
                    SV().kow.textSide = v
                    KRT.KOW:UpdateTextStyle()
                end,
                width = "full",
                disabled = function() return not SV().kow.enabled end,
            },
        },
    }
end

KRT:RegisterModule(KRT.KOW)
