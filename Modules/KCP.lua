-- Kwibus Colorless Pool (KCP)
-- Nag screen that screams at you when you are fighting an enemy and forgot to apply Minor Brittle.
KwibusRandomThings = KwibusRandomThings or {}
local KRT = KwibusRandomThings
local EM = EVENT_MANAGER
local WM = WINDOW_MANAGER
local ADDON_NAME = KRT.name

local EnsureTable = KRT.EnsureTable
local IsNonEmptyString = KRT.IsNonEmptyString
local DebounceNextFrame = KRT.DebounceNextFrame
local RGBToHex = KRT.RGBToHex

local DEFAULTS = { kcp = {
    enabled = true,
    text = "BRITTLE MISSING!",
    offsetX = 0,
    offsetY = 100,
    fontScale = 1.0,
    enableReposition = false,
} }

KRT.KCP = {
    id = "kcp",
    defaults = DEFAULTS.kcp,
    SKILL_ID = 183267,   -- Colorless Pool skill ability ID
    DEBUFF_ID = 145975,  -- Minor Brittle debuff ID

    ui = nil,
    lbl = nil,

    _slotted = false,
    _slottedAtMs = 0,
    _hasDebuff = false,
    _hasDebuffAtMs = 0,
}

local BARS_TO_CHECK = { 0, 1 } -- Check both Front bar (0) and Back bar (1)

function KRT.KCP:SV() return KRT.GetModuleSV(self.id, self.defaults) end

-- Constructs the top-level overlay window on demand
function KRT.KCP:EnsureOverlay()
    if self.ui then return end
    local sv = self:SV()
    if not sv then return end

    local win = WM:CreateTopLevelWindow("KwibusColorlessPool_UI")
    win:SetDimensions(120, 40)
    win:SetHidden(true)
    win:SetMouseEnabled(false)
    win:SetMovable(false)
    win:SetClampedToScreen(true)
    win:SetDrawLayer(DL_OVERLAY)
    win:SetDrawTier(DT_HIGH)
    win:SetDrawLevel(9999)

    local label = WM:CreateControl("KwibusColorlessPool_Lbl", win, CT_LABEL)
    label:SetAnchor(CENTER, win, CENTER, 0, 0)
    label:SetFont("ZoFontCallout")
    label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    label:SetColor(1, 0, 0, 1)

    self.ui = win
    self.lbl = label

    self:ApplyAnchor()
    self:UpdateTextAndScale()
end

-- Refreshes label text, font scaling, and adjusts the hit box
function KRT.KCP:UpdateTextAndScale()
    local win, label = self.ui, self.lbl
    if not (win and label) then return end
    local sv = self:SV()
    if not sv then return end

    local scale = sv.fontScale or 1.0
    local text = sv.text or DEFAULTS.kcp.text
    label:SetText(text)
    label:SetScale(scale)

    KRT.ResizeTextHitbox("KCP_Resize", win, label, scale, 60, 30)
end

-- Positions the overlay based on user saved coordinates
function KRT.KCP:ApplyAnchor()
    KRT.ApplyCenterAnchor(self.ui, self:SV(), DEFAULTS.kcp.offsetY)
end

-- Enables dragging the overlay during settings setup
function KRT.KCP:EnableDragging(enable)
    local sv = self:SV()
    KRT.EnableDragging(self.ui, self.lbl, sv, enable, function() self:ApplyAnchor() end, function() self:OnCombatUpdate() end)
end

-- Scans skill bars to verify if Colorless Pool is currently slotted
function KRT.KCP:_ComputeIsSkillSlotted()
    for _, bar in ipairs(BARS_TO_CHECK) do
        for slot = 3, 8 do
            if GetSlotBoundId(slot, bar) == self.SKILL_ID then return true end
        end
    end
    return false
end

-- Caches the slotted status for 1 second so we aren't querying skill slots every millisecond
function KRT.KCP:IsSkillSlottedCached(maxAgeMs)
    local nowMs = GetFrameTimeMilliseconds()
    if (nowMs - (self._slottedAtMs or 0)) > (maxAgeMs or 1000) then
        self._slotted = self:_ComputeIsSkillSlotted()
        self._slottedAtMs = nowMs
    end
    return self._slotted
end

-- Checks if your active reticle target currently suffers from Minor Brittle
function KRT.KCP:_ComputeHasDebuff()
    for i = 1, GetNumBuffs("reticleover") do
        local _, _, _, _, _, _, _, _, _, _, id = GetUnitBuffInfo("reticleover", i)
        if id == self.DEBUFF_ID then return true end
    end
    return false
end

-- Caches the debuff check (120ms) to stay responsive during rapid target changes
function KRT.KCP:HasDebuffCached(maxAgeMs)
    local nowMs = GetFrameTimeMilliseconds()
    if (nowMs - (self._hasDebuffAtMs or 0)) > (maxAgeMs or 120) then
        self._hasDebuff = self:_ComputeHasDebuff()
        self._hasDebuffAtMs = nowMs
    end
    return self._hasDebuff
end

-- Main evaluation loop: decides whether to scream "BRITTLE MISSING!" on your screen
function KRT.KCP:OnCombatUpdate()
    local sv = self:SV()
    if not sv then return end

    if not sv.enabled then
        if self.ui then self.ui:SetHidden(true) end
        return
    end

    -- If in reposition mode, keep visible so the user can drag it
    if sv.enableReposition then
        if self.ui then self.ui:SetHidden(false) end
        return
    end

    if not self.ui then return end

    -- Only yell if:
    -- 1. We are in combat
    -- 2. Looking at a valid living enemy
    -- 3. We actually have Colorless Pool on our bar
    if IsUnitInCombat("player")
        and DoesUnitExist("reticleover")
        and IsUnitAttackable("reticleover")
        and not IsUnitDead("reticleover") then
        if self:IsSkillSlottedCached(1000) then
            -- Hide the warning IF debuff is present; show IF debuff is missing
            self.ui:SetHidden(self:HasDebuffCached(120))
            return
        end
    end

    self.ui:SetHidden(true)
end

-- =========================================================
-- Initialization
-- =========================================================
function KRT.KCP:Initialize()
    local sv = self:SV()
    if not sv then return end

    self:EnsureOverlay()
    self:ApplyAnchor()
    self:UpdateTextAndScale()
    self:EnableDragging(sv.enableReposition)

    -- Refresh state when entering/leaving combat
    EM:RegisterForEvent(ADDON_NAME .. "_KCP_Combat", EVENT_PLAYER_COMBAT_STATE, function()
        local sv2 = self:SV()
        if not (sv2 and sv2.enabled) then return end
        self:OnCombatUpdate()
    end)

    -- Invalidate target cache and re-evaluate when your crosshair points at someone new
    EM:RegisterForEvent(ADDON_NAME .. "_KCP_Target", EVENT_RETICLE_TARGET_CHANGED, function()
        local sv2 = self:SV()
        if not (sv2 and sv2.enabled) then return end
        if not (IsUnitInCombat("player") or sv2.enableReposition) then return end
        self._hasDebuffAtMs = 0
        self._slottedAtMs = 0
        self:OnCombatUpdate()
    end)

    -- Listen for debuff gain/loss on your reticle target
    EM:RegisterForEvent(ADDON_NAME .. "_KCP_Effect", EVENT_EFFECT_CHANGED, function()
        local sv2 = self:SV()
        if not (sv2 and sv2.enabled) then return end
        if not (IsUnitInCombat("player") or sv2.enableReposition) then return end
        self._hasDebuffAtMs = 0
        self:OnCombatUpdate()
    end)
    EM:AddFilterForEvent(ADDON_NAME .. "_KCP_Effect", EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, "reticleover")
end

-- =========================================================
-- Settings Menu
-- =========================================================
local function SV() return KRT.sv end

function KRT.KCP:GetLAMSubmenu()
    return {
        type = "submenu",
        name = "Kwibus Colorless Pool",
        controls = {
            {
                type = "checkbox",
                name = "Enable Module",
                getFunc = function() return SV().kcp.enabled end,
                setFunc = function(v)
                    SV().kcp.enabled = v
                    if not v then
                        KRT.KCP:EnableDragging(false)
                        if KRT.KCP.ui then KRT.KCP.ui:SetHidden(true) end
                    else
                        KRT.KCP:OnCombatUpdate()
                    end
                end,
                width = "full",
            },
            {
                type = "checkbox",
                name = "Enable Repositioning (Drag)",
                tooltip = "Allows you to drag and reposition the reminder overlay.",
                getFunc = function() return SV().kcp.enableReposition end,
                setFunc = function(v)
                    SV().kcp.enableReposition = v
                    KRT.KCP:EnableDragging(v)
                    KRT.KCP:ApplyAnchor()
                end,
                width = "full",
                disabled = function() return not SV().kcp.enabled end,
            },
            {
                type = "button",
                name = "Reset Horizontal Position",
                func = function() SV().kcp.offsetX = 0; KRT.KCP:ApplyAnchor() end,
                disabled = function() return not SV().kcp.enabled or not SV().kcp.enableReposition end,
                width = "half",
            },
            {
                type = "button",
                name = "Reset Vertical Position",
                func = function() SV().kcp.offsetY = DEFAULTS.kcp.offsetY; KRT.KCP:ApplyAnchor() end,
                disabled = function() return not SV().kcp.enabled or not SV().kcp.enableReposition end,
                width = "half",
            },
            {
                type = "editbox",
                name = "Reminder Text",
                isMultiline = false,
                getFunc = function() return SV().kcp.text end,
                setFunc = function(v)
                    SV().kcp.text = IsNonEmptyString(v) and v or DEFAULTS.kcp.text
                    KRT.KCP:UpdateTextAndScale()
                end,
                width = "full",
                disabled = function() return not SV().kcp.enabled end,
            },
            {
                type = "slider",
                name = "Text Scale",
                min = 0.5,
                max = 3.0,
                step = 0.1,
                getFunc = function() return SV().kcp.fontScale end,
                setFunc = function(v) SV().kcp.fontScale = v; KRT.KCP:UpdateTextAndScale() end,
                width = "full",
                disabled = function() return not SV().kcp.enabled end,
            },
        },
    }
end

KRT:RegisterModule(KRT.KCP)
