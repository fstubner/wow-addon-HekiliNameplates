--[[
  HekiliNameplates — WoW Addon
  Anchors Hekili recommendation frames to the target's nameplate,
  keeping the suggested spell rotation exactly where your eyes already are.

  Author: fstubner
  Version: 1.0.0
  Interface: 120001 (The War Within / Midnight)
--]]

local ADDON_NAME = "HekiliNameplates"
local VERSION    = "1.0.0"

local DEFAULTS = {
  enabled      = true,
  offsetX      = 0,
  offsetY      = -5,
  castBarAware = true,
  frames = {
    HekiliDisplayPrimary    = true,
    HekiliDisplayAOE        = false,
    HekiliDisplayDefensives = false,
    HekiliDisplayInterrupts = false,
    HekiliDisplayCooldowns  = false,
  },
}

local ALL_FRAMES = {
  { key = "HekiliDisplayPrimary",    label = "Primary"    },
  { key = "HekiliDisplayAOE",        label = "AOE"        },
  { key = "HekiliDisplayDefensives", label = "Defensives" },
  { key = "HekiliDisplayInterrupts", label = "Interrupts" },
  { key = "HekiliDisplayCooldowns",  label = "Cooldowns"  },
}

HekiliNameplatesDB = nil

local function deepCopy(src)
  local out = {}
  for k, v in pairs(src) do
    out[k] = (type(v) == "table") and deepCopy(v) or v
  end
  return out
end

local function initDB()
  if not HekiliNameplatesDB then
    HekiliNameplatesDB = deepCopy(DEFAULTS)
    return
  end
  for k, v in pairs(DEFAULTS) do
    if HekiliNameplatesDB[k] == nil then
      HekiliNameplatesDB[k] = (type(v) == "table") and deepCopy(v) or v
    end
  end
  if not HekiliNameplatesDB.frames then
    HekiliNameplatesDB.frames = deepCopy(DEFAULTS.frames)
  else
    for k, v in pairs(DEFAULTS.frames) do
      if HekiliNameplatesDB.frames[k] == nil then
        HekiliNameplatesDB.frames[k] = v
      end
    end
  end
end

local function db() return HekiliNameplatesDB end

local savedPositions = {}

local function savePosition(frameName, hekiliFrame)
  if savedPositions[frameName] then return end
  local point, relativeTo, relativePoint, x, y = hekiliFrame:GetPoint()
  if point then
    savedPositions[frameName] = { point, relativeTo, relativePoint, x, y }
  end
end

local function restorePosition(frameName, hekiliFrame)
  local pos = savedPositions[frameName]
  if not pos then return end
  hekiliFrame:ClearAllPoints()
  hekiliFrame:SetPoint(unpack(pos))
end

local function getAnchor(nameplate)
  if db().castBarAware then
    local uf = nameplate.UnitFrame
    if uf then
      local cb = uf.castBar
      if cb and cb:IsShown() then return cb, "BOTTOM" end
      local hb = uf.healthBar
      if hb then return hb, "BOTTOM" end
    end
  end
  return nameplate, "BOTTOM"
end

local function updatePositions()
  if not db().enabled then return end
  local nameplate = C_NamePlate.GetNamePlateForUnit("target")
  local hasTarget  = nameplate and UnitExists("target") and not UnitIsDead("target")
  for _, info in ipairs(ALL_FRAMES) do
    if db().frames[info.key] then
      local hekiliFrame = _G[info.key]
      if hekiliFrame then
        savePosition(info.key, hekiliFrame)
        if hasTarget then
          local anchor, anchorPoint = getAnchor(nameplate)
          local npWidth = nameplate:GetWidth()
          local hkWidth = hekiliFrame:GetWidth()
          local centreOffX = (npWidth > 0 and hkWidth > 0) and ((npWidth - hkWidth) / 2) or 0
          hekiliFrame:ClearAllPoints()
          hekiliFrame:SetPoint("TOP", anchor, anchorPoint, centreOffX + db().offsetX, db().offsetY)
        else
          restorePosition(info.key, hekiliFrame)
        end
      end
    end
  end
end

local optionsFrame

local function syncOptionsFrame()
  if not optionsFrame then return end
  optionsFrame._enableCB:SetChecked(db().enabled)
  optionsFrame._castBarCB:SetChecked(db().castBarAware)
  optionsFrame._xSlider:SetValue(db().offsetX)
  optionsFrame._ySlider:SetValue(db().offsetY)
  for _, info in ipairs(ALL_FRAMES) do
    if optionsFrame._frameCBs[info.key] then
      optionsFrame._frameCBs[info.key]:SetChecked(db().frames[info.key])
    end
  end
end

local function buildOptionsFrame()
  if optionsFrame then return optionsFrame end
  local f = CreateFrame("Frame", "HekiliNameplatesOptions", UIParent, "BasicFrameTemplateWithInset")
  f:SetSize(320, 380)
  f:SetPoint("CENTER")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop",  f.StopMovingOrSizing)
  f:SetFrameStrata("DIALOG")
  f:Hide()
  f:SetFrameLevel(100)
  f.TitleText:SetText("Hekili Nameplates  v" .. VERSION)
  f._frameCBs = {}
  local yOff = -36
  local enableCB = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  enableCB:SetPoint("TOPLEFT", 14, yOff)
  enableCB.text:SetText("Enable nameplate anchoring")
  enableCB:SetChecked(db().enabled)
  enableCB:SetScript("OnClick", function(self) db().enabled = self:GetChecked(); updatePositions() end)
  f._enableCB = enableCB
  yOff = yOff - 28
  local castBarCB = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  castBarCB:SetPoint("TOPLEFT", 14, yOff)
  castBarCB.text:SetText("Anchor below cast bar when active")
  castBarCB:SetChecked(db().castBarAware)
  castBarCB:SetScript("OnClick", function(self) db().castBarAware = self:GetChecked(); updatePositions() end)
  f._castBarCB = castBarCB
  yOff = yOff - 36
  local offsetLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  offsetLabel:SetPoint("TOPLEFT", 14, yOff)
  offsetLabel:SetText("Position offset:")
  yOff = yOff - 20
  local xSlider = CreateFrame("Slider", "HNSliderX", f, "OptionsSliderTemplate")
  xSlider:SetPoint("TOPLEFT", 20, yOff)
  xSlider:SetWidth(260)
  xSlider:SetMinMaxValues(-100, 100)
  xSlider:SetValueStep(1)
  xSlider:SetValue(db().offsetX)
  HNSliderXLow:SetText("-100"); HNSliderXHigh:SetText("+100"); HNSliderXText:SetText("X offset: " .. db().offsetX)
  xSlider:SetScript("OnValueChanged", function(self, val) local v = math.floor(val+0.5); db().offsetX = v; HNSliderXText:SetText("X offset: "..v); updatePositions() end)
  f._xSlider = xSlider
  yOff = yOff - 42
  local ySlider = CreateFrame("Slider", "HNSliderY", f, "OptionsSliderTemplate")
  ySlider:SetPoint("TOPLEFT", 20, yOff)
  ySlider:SetWidth(260)
  ySlider:SetMinMaxValues(-60, 0)
  ySlider:SetValueStep(1)
  ySlider:SetValue(db().offsetY)
  HNSliderYLow:SetText("-60"); HNSliderYHigh:SetText("0"); HNSliderYText:SetText("Y offset: " .. db().offsetY)
  ySlider:SetScript("OnValueChanged", function(self, val) local v = math.floor(val+0.5); db().offsetY = v; HNSliderYText:SetText("Y offset: "..v); updatePositions() end)
  f._ySlider = ySlider
  yOff = yOff - 44
  local framesLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  framesLabel:SetPoint("TOPLEFT", 14, yOff)
  framesLabel:SetText("Hekili displays to reposition:")
  yOff = yOff - 20
  for _, info in ipairs(ALL_FRAMES) do
    local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 20, yOff)
    cb.text:SetText(info.label)
    cb:SetChecked(db().frames[info.key])
    local key = info.key
    cb:SetScript("OnClick", function(self) db().frames[key] = self:GetChecked(); updatePositions() end)
    f._frameCBs[info.key] = cb
    yOff = yOff - 24
  end
  local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  resetBtn:SetPoint("BOTTOMLEFT", 14, 10)
  resetBtn:SetSize(120, 22)
  resetBtn:SetText("Reset Defaults")
  resetBtn:SetScript("OnClick", function() HekiliNameplatesDB = deepCopy(DEFAULTS); ReloadUI() end)
  local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  closeBtn:SetPoint("BOTTOMRIGHT", -14, 10)
  closeBtn:SetSize(80, 22)
  closeBtn:SetText("Close")
  closeBtn:SetScript("OnClick", function() f:Hide() end)
  optionsFrame = f
  return f
end

local function toggleOptions()
  local f = buildOptionsFrame()
  if f:IsShown() then f:Hide() else syncOptionsFrame(); f:Show() end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 == ADDON_NAME then initDB() end
    return
  end
  updatePositions()
end)

SLASH_HEKILINAMEPLATES1 = "/hekilinameplates"
SLASH_HEKILINAMEPLATES2 = "/hn"

SlashCmdList["HEKILINAMEPLATES"] = function(msg)
  local cmd = strtrim(msg):lower()
  if cmd == "" or cmd == "config" or cmd == "options" then
    toggleOptions()
  elseif cmd == "enable" then
    db().enabled = true; updatePositions()
    print("|cffCC6600HekiliNameplates:|r Enabled.")
  elseif cmd == "disable" then
    db().enabled = false; updatePositions()
    print("|cffCC6600HekiliNameplates:|r Disabled.")
  elseif cmd:match("^x%s+%-?%d+$") then
    local v = tonumber(cmd:match("%-?%d+"))
    if cmd:find("x%s+%-") then v = -v end
    db().offsetX = v; updatePositions()
    print("|cffCC6600HekiliNameplates:|r X offset → " .. v)
  elseif cmd:match("^y%s+%-?%d+$") then
    local v = tonumber(cmd:match("%-?%d+"))
    if cmd:find("y%s+%-") then v = -v end
    db().offsetY = v; updatePositions()
    print("|cffCC6600HekiliNameplates:|r Y offset → " .. v)
  elseif cmd == "about" then
    print("|cffCC6600HekiliNameplates|r v" .. VERSION)
    print("Anchors Hekili frames to the target's nameplate.")
  else
    print("|cffCC6600HekiliNameplates|r — commands:")
    print("  |cffFFD700/hn|r               — open options panel")
    print("  |cffFFD700/hn enable|r         — enable repositioning")
    print("  |cffFFD700/hn disable|r        — disable repositioning")
    print("  |cffFFD700/hn x <value>|r      — horizontal offset  (e.g. /hn x -10)")
    print("  |cffFFD700/hn y <value>|r      — vertical offset    (e.g. /hn y -8)")
    print("  |cffFFD700/hn about|r          — version info")
  end
end
