-- Kwibus Auto Confirm (KAC)
-- Because typing out "CONFIRM" for the 500th time today is not why you play ESO.
KwibusRandomThings = KwibusRandomThings or {}
local KRT = KwibusRandomThings
local EM = EVENT_MANAGER
local WM = WINDOW_MANAGER
local ADDON_NAME = KRT.name

local EnsureTable = KRT.EnsureTable
local IsNonEmptyString = KRT.IsNonEmptyString
local DebounceNextFrame = KRT.DebounceNextFrame
local RGBToHex = KRT.RGBToHex

-- Module-local defaults wrapper 
local DEFAULTS = { kac = {
    enabled = true,
} }

KRT.KAC = {
    id = "kac",
    defaults = DEFAULTS.kac,
    autoConfirmHooked = false,
}

function KRT.KAC:SV() return KRT.GetModuleSV(self.id, self.defaults) end

function KRT.KAC:Initialize()
  local sv = self:SV()
  if not sv then return end

  if self.autoConfirmHooked then return end
  self.autoConfirmHooked = true

  local function hook()
    local sv2 = self:SV()
    if not (sv2 and sv2.enabled) then return end

    -- Give the dialog window a tiny 10ms nap so its text parameters and editbox actually exist
    zo_callLater(function()
      if not (self:SV() and self:SV().enabled) then return end

      if ZO_Dialog1 and ZO_Dialog1.textParams and ZO_Dialog1.textParams.mainTextParams then
        for _, v in pairs(ZO_Dialog1.textParams.mainTextParams) do
          -- 1. zo_strupper handles Cyrillic (unlike standard string.upper)
          -- 2. v ~= zo_strlower ensures it actually contains letters (ignores purely numeric strings like "123")
          -- 3. not string.find ensures it's a single word (prevents typing in an entire uppercase item name)
          if type(v) == "string" and v == zo_strupper(v) and v ~= zo_strlower(v) and not string.find(v, " ") then
            if ZO_Dialog1EditBox and ZO_Dialog1EditBox.SetText then
              ZO_Dialog1EditBox:SetText(v)
              -- Unfocus the box so you can immediately hit [E] or Space without typing extra gibberish
              ZO_Dialog1EditBox:LoseFocus()
            end
          end
        end
      end
    end, 10)
  end

  -- Hijack the dialog creation before it shows up to pre-fill the confirmation phrase
  ZO_PreHook("ZO_Dialogs_ShowDialog", hook)
end

-- =========================================================
-- Settings Menu
-- =========================================================

local function SV() return KRT.KAC:SV() end

function KRT.KAC:GetLAMSubmenu()
    return {
      type = "submenu",
      name = "Kwibus Confirm",
      controls = {
        {
          type = "checkbox",
          name = "Enable Module",
          tooltip = "Automatically fills in 'CONFIRM' or localized text when destructive dialogs appear. Use with care unless you enjoy accidentally destroying your gold jewelry.",
          getFunc = function() return SV().enabled end,
          setFunc = function(v) SV().enabled = v end,
          width = "full",
        },
      },
    }
end

KRT:RegisterModule(KRT.KAC)
