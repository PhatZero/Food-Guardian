local _, FG = ...

local function color(font, c)
  if font and c then font:SetTextColor(c[1], c[2], c[3], 1) end
end

local function font(parent, size, c, text, justify)
  local f = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  f:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size, "OUTLINE")
  f:SetJustifyH(justify or "LEFT")
  f:SetText(text or "")
  color(f, c)
  return f
end
FG.Font = font

function FG:SkinPanel(panel, dark)
  if panel.SetBackdrop then
    panel:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Buttons\\WHITE8X8",
      tile = false, edgeSize = 1,
      insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    panel:SetBackdropColor(dark and 0.035 or 0.07, dark and 0.045 or 0.085,
      dark and 0.060 or 0.10, 0.96)
    panel:SetBackdropBorderColor(0.37, 0.29, 0.17, 1)
  end
end

local function solid(parent, w, h, c, alpha)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetTexture("Interface\\Buttons\\WHITE8X8")
  t:SetSize(w, h)
  t:SetVertexColor(c[1], c[2], c[3], alpha or 1)
  return t
end

local function smallButton(parent, iconIndex, tooltip, x, onClick)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(24, 24)
  b:SetPoint("TOPRIGHT", parent, "TOPRIGHT", x, -11)
  FG:SkinPanel(b, true)
  local t = b:CreateTexture(nil, "ARTWORK")
  t:SetTexture("Interface\\AddOns\\FoodGuardian\\Textures\\Controls.tga")
  t:SetTexCoord(iconIndex / 8, (iconIndex + 1) / 8, 0, 1)
  t:SetPoint("TOPLEFT", 3, -3)
  t:SetPoint("BOTTOMRIGHT", -3, 3)
  b.icon = t
  b:SetScript("OnEnter", function(self)
    if not FG.inCombat and GameTooltip then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(tooltip or "Control", 1, 0.83, 0.49)
      GameTooltip:Show()
    end
    if self.SetBackdropBorderColor then self:SetBackdropBorderColor(0.97, 0.73, 0.35, 1) end
  end)
  b:SetScript("OnLeave", function(self)
    if not FG.inCombat and GameTooltip then GameTooltip:Hide() end
    if self.SetBackdropBorderColor then self:SetBackdropBorderColor(0.37, 0.29, 0.17, 1) end
  end)
  b:SetScript("OnClick", function(...)
    if not FG.inCombat then onClick(...) end
  end)
  return b
end

local rowInfo = {
  food = { title = "Well Fed", icon = FG.icons.food,
    help = "Tracks the real Well Fed food aura. Re-eat before the meal buff expires." },
  bag = { title = "Well-Rested", icon = FG.icons.bag,
    help = "Tracks Well-Rested (Cozy Sleeping Bag), up to three stacks, plus item cooldown." },
  camp = { title = "Camp Benefits", icon = FG.icons.camp,
    help = "Tracks the actual Camp Benefits aura gained by resting near a campfire." },
}

local function createRow(parent, key, y)
  local info = rowInfo[key]
  local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
  row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, y)
  row:SetHeight(82)
  FG:SkinPanel(row, false)

  row.accent = solid(row, 3, 80, FG.colors.green, 1)
  row.accent:SetPoint("LEFT", 0, 0)

  local iconBorder = CreateFrame("Frame", nil, row, "BackdropTemplate")
  iconBorder:SetPoint("TOPLEFT", 8, -9)
  iconBorder:SetSize(64, 64)
  FG:SkinPanel(iconBorder, true)
  row.icon = iconBorder:CreateTexture(nil, "ARTWORK")
  row.icon:SetPoint("TOPLEFT", 3, -3)
  row.icon:SetPoint("BOTTOMRIGHT", -3, 3)
  row.icon:SetTexture(info.icon)

  row.title = font(row, 15, FG.colors.ivory, info.title)
  row.title:SetPoint("TOPLEFT", 82, -10)
  row.title:SetPoint("RIGHT", -115, 0)
  row.title:SetHeight(20)

  row.detail = font(row, 11, FG.colors.muted, "Checking active effects...")
  row.detail:SetPoint("TOPLEFT", 82, -34)
  row.detail:SetPoint("RIGHT", -12, 0)
  row.detail:SetHeight(16)

  row.time = font(row, 17, FG.colors.green, "--:--", "RIGHT")
  row.time:SetPoint("TOPRIGHT", -12, -10)
  row.time:SetWidth(108)
  row.time:SetHeight(16)

  row.barBg = solid(row, 1, 7, {0.13,0.16,0.18}, 1)
  row.barBg:SetPoint("BOTTOMLEFT", 82, 10)
  row.barBg:SetPoint("BOTTOMRIGHT", -12, 10)
  row.barBg:SetHeight(10)
  row.bar = CreateFrame("StatusBar", nil, row)
  row.bar:SetPoint("BOTTOMLEFT", 82, 10)
  row.bar:SetPoint("BOTTOMRIGHT", -12, 10)
  row.bar:SetHeight(10)
  row.bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
  row.bar:SetMinMaxValues(0, 1)
  row.bar:SetValue(0)

  row.glow = solid(row, 1, 1, {1,0.35,0.10}, 0.22)
  row.glow:SetAllPoints()
  row.glow:Hide()

  row:EnableMouse(true)
  row:SetScript("OnEnter", function(self)
    if FG.inCombat or not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(info.title, 1, 0.83, 0.49)
    GameTooltip:AddLine(info.help, 0.87, 0.87, 0.83, true)
    if key == "bag" then
      local state = FG:GetDisplayState()
      local owned = state.bagOwned
      GameTooltip:AddLine(owned and "Cozy Sleeping Bag found in bags" or "Cozy Sleeping Bag not found in bags",
        0.58, 0.82, 0.82, true)
      if state.bagCooldown and state.bagCooldown > 0 then
        GameTooltip:AddLine("Item cooldown: " .. FG:FormatTime(state.bagCooldown), 1, 0.68, 0.37)
      end
    end
    GameTooltip:Show()
  end)
  row:SetScript("OnLeave", function() if not FG.inCombat and GameTooltip then GameTooltip:Hide() end end)
  return row
end

-- A truly different layout for each concept view. No header or labels in the two minimal views.
local function modeTile(parent, key, i, style)
  local bar = style == "compact"
  local item = CreateFrame("Button", nil, parent, "BackdropTemplate")
  local tileWidth = bar and 128 or 51
  local tileHeight = bar and 50 or 51
  item:SetSize(tileWidth, tileHeight)
  item:SetPoint("TOPLEFT", bar and (5 + (i - 1) * 132) or (5 + (i - 1) * 56), -5)
  FG:SkinPanel(item, true)
  if item.SetBackdropBorderColor then item:SetBackdropBorderColor(.73, .54, .30, 1) end
  item:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
  item:RegisterForDrag("LeftButton")
  item:EnableMouse(true)

  item.icon = item:CreateTexture(nil, "ARTWORK")
  item.icon:SetSize(bar and 42 or 45, bar and 42 or 45)
  item.icon:SetPoint("LEFT", bar and 4 or 3, 0)
  item.icon:SetTexture(rowInfo[key].icon)
  if bar then
    item.time = font(item, 15, FG.colors.green, "--:--", "RIGHT")
    item.time:SetPoint("LEFT", 50, 0)
    item.time:SetPoint("RIGHT", -6, 0)
    item.time:SetHeight(22)
  end

  item:SetScript("OnClick", function(_, mouse)
    if FG.inCombat then return end
    if mouse == "RightButton" then FG:CycleMode()
    elseif mouse == "MiddleButton" then FG:ToggleSettings()
    else FG:SetMode("full") end
  end)
  item:SetScript("OnDragStart", function()
    if not FG.db.locked and not FG.inCombat then FG.window:StartMoving() end
  end)
  item:SetScript("OnDragStop", function()
    if FG.inCombat then return end
    FG.window:StopMovingOrSizing()
    if not FG.db.locked then FG:SavePosition() end
  end)
  item:SetScript("OnEnter", function(self)
    if FG.inCombat or not GameTooltip then return end
    local data = FG:GetDisplayState()
    local aura = data[key] or {}
    local status = FG:Status(key)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(rowInfo[key].title, 1, .80, .43)
    GameTooltip:AddLine(rowInfo[key].help, .87, .87, .83, true)
    GameTooltip:AddLine("Status: " .. status, 1, .90, .70)
    local rem = FG:Remain(aura)
    if rem then GameTooltip:AddLine("Remaining: " .. FG:FormatTime(rem), .50, .91, .58) end
    if key == "bag" then
      local stacks = math.max(0, math.min(3, FG:SafeNumber(aura.stacks) or 0))
      GameTooltip:AddLine("Sleeping Bag stacks: " .. stacks .. "/3", .58, .88, .93)
    end
    GameTooltip:AddLine("Left click: Full  |  Right click: Next mode", 1, .77, .49)
    GameTooltip:AddLine("Drag: Move  |  Middle click: Settings", .72, .75, .77)
    GameTooltip:Show()
  end)
  item:SetScript("OnLeave", function() if not FG.inCombat and GameTooltip then GameTooltip:Hide() end end)
  return item
end

function FG:CreateUI()
  local frame = CreateFrame("Frame", "FoodGuardianTrackerFrame", UIParent, "BackdropTemplate")
  frame:SetSize(414, 390)
  frame:SetScale(self.db.scale)
  frame:SetPoint("CENTER", UIParent, "CENTER", self.db.x, self.db.y)
  frame:SetFrameStrata("MEDIUM")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  self:SkinPanel(frame, true)
  if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(0.75, 0.55, 0.26, 1) end
  self.window = frame
  self.classOuterOutline = nil
  self.classLayoutSignature = nil

  frame.topRule = solid(frame, 1, 2, self.colors.gold, .65)
  frame.topRule:SetPoint("TOPLEFT", 1, -49)
  frame.topRule:SetPoint("TOPRIGHT", -1, -49)

  local header = CreateFrame("Frame", nil, frame)
  header:SetPoint("TOPLEFT", 0, 0)
  header:SetPoint("TOPRIGHT", 0, 0)
  header:SetHeight(49)
  frame.header = header
  header:EnableMouse(true)
  header:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" and not FG.db.locked and not FG.inCombat then frame:StartMoving() end
  end)
  header:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" and not FG.db.locked and not FG.inCombat then
      frame:StopMovingOrSizing()
      FG:SavePosition()
    end
  end)
  header:SetScript("OnHide", function()
    -- OnHide also runs when combat concealment starts. Never move a frame then.
    if not FG.inCombat then frame:StopMovingOrSizing() end
  end)

  local crest = header:CreateTexture(nil, "ARTWORK")
  crest:SetSize(40, 40)
  crest:SetPoint("TOPLEFT", 7, -4)
  crest:SetTexture(self.icons.guardian)
  frame.crest = crest
  frame.heading = font(header, 19, self.colors.bright, "Food Guardian")
  frame.heading:SetPoint("TOPLEFT", 50, -8)
  frame.subtitle = font(header, 9, self.colors.cyan, "FOREVER  ·  V1.1b7")
  frame.subtitle:SetPoint("TOPLEFT", 51, -30)

  frame.closeButton = smallButton(header, 0, "Close tracker (reopen with /fg)", -10, function() FG:ToggleWindow() end)
  frame.settingsButton = smallButton(header, 1, "Settings", -39, function() FG:ToggleSettings() end)
  frame.compactButton = smallButton(header, 2, "Cycle layouts: Full → Compact Bar → Icons", -68, function() FG:CycleMode() end)
  -- Demo toggle is in settings, leaving the concept header clean.

  local summary = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  summary:SetPoint("TOPLEFT", 12, -61)
  summary:SetPoint("TOPRIGHT", -12, -61)
  summary:SetHeight(31)
  self:SkinPanel(summary, true)
  frame.summary = summary
  frame.summaryText = font(summary, 11, self.colors.gold, "WAITING FOR BUFFS")
  frame.summaryText:SetPoint("LEFT", 9, 0)
  frame.summaryRight = font(summary, 10, self.colors.muted, "LIVE TRACKING", "RIGHT")
  frame.summaryRight:SetPoint("RIGHT", -8, 0)

  frame.rows = {}
  frame.rows.food = createRow(frame, "food", -57)
  frame.rows.bag = createRow(frame, "bag", -145)
  frame.rows.camp = createRow(frame, "camp", -233)

  local tent = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  tent:SetPoint("TOPLEFT", 12, -326)
  tent:SetPoint("TOPRIGHT", -12, -326)
  tent:SetHeight(34)
  self:SkinPanel(tent, true)
  frame.tent = tent
  local tentIcon = tent:CreateTexture(nil, "ARTWORK")
  tentIcon:SetSize(22, 22)
  tentIcon:SetPoint("LEFT", 7, 0)
  tentIcon:SetTexture(self.icons.tent)
  frame.tentIcon = tentIcon
  frame.tentLabel = font(tent, 10, self.colors.muted, "CAMP TENT")
  frame.tentLabel:SetPoint("LEFT", 36, 0)
  frame.tentTime = font(tent, 11, self.colors.gold, "Checking lockout...", "RIGHT")
  frame.tentTime:SetPoint("RIGHT", -9, 0)
  frame.tentTime:SetWidth(225)
  tent:EnableMouse(true)
  tent:SetScript("OnEnter", function(self)
    if not FG.inCombat and GameTooltip then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText("Camp Tent · Boosted Rest", 1, 0.84, 0.49)
      GameTooltip:AddLine("The Boosted Rest debuff marks your Camp Tent rested-XP lockout. It is not the Camp Benefits buff.", .88, .88, .85, true)
      GameTooltip:Show()
    end
  end)
  tent:SetScript("OnLeave", function() if not FG.inCombat and GameTooltip then GameTooltip:Hide() end end)

  frame.footer = font(frame, 10, self.colors.muted, "Drag title to move  •  Drag corner to resize")
  frame.footer:SetPoint("BOTTOMLEFT", 13, 12)
  frame.footer:SetWidth(346)
  frame.footer:SetHeight(13)

  local grip = CreateFrame("Button", nil, frame)
  grip:SetSize(25, 25)
  grip:SetPoint("BOTTOMRIGHT", -2, 2)
  grip:EnableMouse(true)
  frame.grip = grip
  local gripLabel = font(grip, 16, self.colors.gold, "//", "CENTER")
  gripLabel:SetAllPoints()
  grip:SetScript("OnMouseDown", function(self, button)
    if button ~= "LeftButton" or FG.db.locked or FG.inCombat or type(GetCursorPosition) ~= "function" then return end
    local x = GetCursorPosition()
    self.dragStart = x
    self.scaleStart = FG.db.scale
    self:SetScript("OnUpdate", function(b)
      if FG.inCombat then
        b:SetScript("OnUpdate", nil)
        b.dragStart = nil
        return
      end
      local cursorX = GetCursorPosition()
      local unitScale = UIParent:GetEffectiveScale()
      local delta = (cursorX - b.dragStart) / (unitScale * 414)
      FG:SetScale(b.scaleStart + delta)
    end)
  end)
  grip:SetScript("OnMouseUp", function(self)
    self:SetScript("OnUpdate", nil)
    self.dragStart = nil
  end)
  grip:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)

  -- Compact Bar: one thin horizontal strip of three icon+timer cells.
  local compact = CreateFrame("Frame", nil, frame)
  compact:SetPoint("TOPLEFT", 0, 0)
  compact:SetSize(402, 60)
  frame.compactRow = compact
  frame.compactTiles = {
    food = modeTile(compact, "food", 1, "compact"),
    bag = modeTile(compact, "bag", 2, "compact"),
    camp = modeTile(compact, "camp", 3, "compact"),
  }

  -- Icon Mode: three square icons; time and stacks are visible on hover.
  local icons = CreateFrame("Frame", nil, frame)
  icons:SetPoint("TOPLEFT", 0, 0)
  icons:SetSize(174, 60)
  frame.iconsRow = icons
  frame.iconTiles = {
    food = modeTile(icons, "food", 1, "icons"),
    bag = modeTile(icons, "bag", 2, "icons"),
    camp = modeTile(icons, "camp", 3, "icons"),
  }

  self:ApplyLayout()
end

function FG:ApplyLayout()
  if self.inCombat and self.ready then return end
  if not self.window then return end
  local frame = self.window
  local mode = self.db.mode or "full"
  local full = mode == "full"
  frame:SetSize(full and 414 or mode == "compact" and 402 or 174,
                full and 390 or 60)
  frame.topRule:SetShown(full)
  frame.header:SetShown(full)
  frame.summary:Hide() -- The concept has three direct status rows, no extra summary panel.
  for _, row in pairs(frame.rows) do row:SetShown(full) end
  frame.tent:SetShown(full and self.db.showTent)
  frame.footer:SetShown(full)
  frame.grip:SetShown(full and not self.db.locked)
  frame.compactRow:SetShown(mode == "compact")
  frame.iconsRow:SetShown(mode == "icons")
  frame:SetScale(self.db.scale)
end

local function displayStatus(fg, key, aura)
  local status = fg:Status(key)
  local remaining = fg:Remain(aura)
  local label, fill, tint
  if status == "active" then
    label = fg:FormatTime(remaining)
    tint = fg.colors.green
  elseif status == "warning" then
    label = fg:FormatTime(remaining)
    tint = fg.colors.amber
  elseif status == "unknown" then
    label = "UNKNOWN"
    tint = fg.colors.muted
  else
    label = "MISSING"
    tint = fg.colors.red
  end
  if status == "missing" or status == "unknown" then
    fill = 0
  elseif aura and aura.duration and aura.duration > 0 and remaining then
    fill = math.max(0, math.min(1, remaining / aura.duration))
  else
    fill = 1
  end
  return status, label, fill, tint
end

function FG:UpdateUI()
  if not self.window then return end
  local frame = self.window
  local data = self:GetDisplayState()
  local present = 0
  local hasWarning = false
  local pulse = 0.08 + 0.19 * (0.5 + 0.5 * math.sin(self:Now() * 8))
  local descriptions = {
    food = { active = "Food Buff", warning = "Food Buff · expiring", missing = "Food Buff · missing", unknown = "Food Buff · unknown" },
    bag = { active = "Sleeping Bag", warning = "Sleeping Bag · expiring", missing = "Sleeping Bag · missing", unknown = "Sleeping Bag · unknown" },
    camp = { active = "Campfire Buff", warning = "Campfire Buff · expiring", missing = "Campfire Buff · missing", unknown = "Campfire Buff · unknown" },
  }
  for _, key in ipairs({ "food", "bag", "camp" }) do
    local aura = data[key] or { active = false }
    local status, label, fill, tint = displayStatus(self, key, aura)
    local remaining = self:Remain(aura)
    if aura.active and status ~= "missing" then present = present + 1 end
    if status == "warning" or status == "missing" then hasWarning = true end
    if status == "warning" and remaining and remaining <= 120 then tint = self.colors.red end
    local row = frame.rows[key]
    local compact = frame.compactTiles[key]
    local iconTile = frame.iconTiles[key]
    row.time:SetText(label)
    color(row.time, tint)
    row.bar:SetValue(fill)
    row.bar:SetStatusBarColor(tint[1], tint[2], tint[3], 1)
    row.accent:SetVertexColor(tint[1], tint[2], tint[3], 1)
    if row.SetBackdropBorderColor then row:SetBackdropBorderColor(tint[1] * .43, tint[2] * .43, tint[3] * .43, 0.75) end
    local detail = descriptions[key][status]
    if key == "bag" then
      if aura.active and status ~= "missing" then
        local stacks = math.max(0, math.min(3, self:SafeNumber(aura.stacks) or 0))
        detail = string.format("Sleeping Bag (%d/3 Stacks)", stacks)
      elseif not data.bagOwned and status == "missing" then
        detail = "Cozy Sleeping Bag not in bags"
      end
      if data.bagOwned and data.bagCooldown and data.bagCooldown > 0 then
        -- Bag item cooldown is available in tooltip, not inserted into the narrow concept subtitle.
      end
    end
    row.detail:SetText(detail)
    color(row.detail, status == "warning" and self.colors.amber or self.colors.muted)
    local icon = rowInfo[key].icon -- stable concept artwork in all layouts
    pcall(function() row.icon:SetTexture(icon) end)
    compact.time:SetText(label == "MISSING" and "NONE" or label == "UNKNOWN" and "?" or label)
    color(compact.time, tint)
    if compact.SetBackdropBorderColor then
      compact:SetBackdropBorderColor(tint[1], tint[2], tint[3], 1)
    end
    if iconTile.SetBackdropBorderColor then
      iconTile:SetBackdropBorderColor(tint[1], tint[2], tint[3], 1)
    end
    pcall(function() compact.icon:SetTexture(icon) end)
    pcall(function() iconTile.icon:SetTexture(icon) end)
    if self.db.flash and (status == "warning" or status == "missing") then
      row.icon:SetAlpha(.65 + .35 * math.abs(math.sin(self:Now() * 5)))
      compact.icon:SetAlpha(.65 + .35 * math.abs(math.sin(self:Now() * 5)))
      iconTile.icon:SetAlpha(.65 + .35 * math.abs(math.sin(self:Now() * 5)))
      row.glow:Show()
      row.glow:SetAlpha(pulse)
      if compact.SetBackdropBorderColor then
        compact:SetBackdropBorderColor(tint[1], tint[2], tint[3], .55 + .45 * math.abs(math.sin(self:Now() * 5)))
      end
      if iconTile.SetBackdropBorderColor then
        iconTile:SetBackdropBorderColor(tint[1], tint[2], tint[3], .55 + .45 * math.abs(math.sin(self:Now() * 5)))
      end
    else
      row.icon:SetAlpha(1)
      compact.icon:SetAlpha(1)
      row.glow:Hide()
      iconTile.icon:SetAlpha(1)
    end
  end
  local summaryTint = present == 3 and self.colors.green or present == 0 and self.colors.red or self.colors.amber
  frame.summaryText:SetText(string.format("%d / 3 BUFFS PRESENT", present))
  color(frame.summaryText, summaryTint)
  frame.summaryRight:SetText(self.demo and "DEMO PREVIEW" or self.inCombat and "CACHED TIMERS" or self.auraReadFailed and "AURA API LIMITED" or "LIVE TRACKING")
  color(frame.summaryRight, self.demo and self.colors.cyan or self.colors.muted)
  local tent = data.tent or {}
  local tentRemaining = self:Remain(tent)
  if tent.active and (not tentRemaining or tentRemaining > 0) then
    frame.tentTime:SetText("Boosted Rest  ·  " .. self:FormatTime(tentRemaining))
    color(frame.tentTime, self.colors.amber)
  elseif (self.auraReadFailed or not self.scannedOnce) and not self.demo then
    frame.tentTime:SetText("Lockout unavailable")
    color(frame.tentTime, self.colors.muted)
  else
    frame.tentTime:SetText("No Boosted Rest lockout")
    color(frame.tentTime, self.colors.green)
  end
  if not self.inCombat then
    frame.tent:SetShown(self.db.mode == "full" and self.db.showTent)
    frame.grip:SetShown(self.db.mode == "full" and not self.db.locked)
  end
  if frame.SetBackdropBorderColor then
    if hasWarning and self.db.flash then
      frame:SetBackdropBorderColor(.9, .43 + .24 * math.abs(math.sin(self:Now() * 5)), .13, 1)
    elseif hasWarning then
      frame:SetBackdropBorderColor(.88, .48, .18, 1)
    else
      frame:SetBackdropBorderColor(.77, .57, .29, 1)
    end
  end
  if self.inCombat then
    frame.footer:SetText("Combat: cached timers  •  Resync after combat")
  elseif self.db.locked then
    frame.footer:SetText("Window locked  •  /fg lock to unlock")
  elseif hasWarning then
    frame.footer:SetText("Amber: expiring soon  •  Red: missing")
  else
    frame.footer:SetText("Drag header to move  •  Drag corner to resize")
  end
end


-- Class tiles extend the existing window without moving the three original tiles.
-- Layout is changed only outside combat; countdowns use cached plain values.
local baseLayout=FG.ApplyLayout
function FG:ApplyLayout()
  baseLayout(self)
  if self.window and not self.inCombat then
    self.classLayoutSignature=nil
    self:LayoutClassRows()
  end
end

-- Explicit four-sided borders: the resized BackdropTemplate can lose edges
-- on fractional UI scales. Anchor ordinary textures to the actual frame.
local function makeOutline(parent, thickness)
  local outline=CreateFrame("Frame",nil,parent)
  outline:SetAllPoints(parent)
  outline:SetFrameLevel(parent:GetFrameLevel()+8)
  outline:EnableMouse(false)
  outline.edges={}
  for _,side in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
    local edge=outline:CreateTexture(nil,"OVERLAY")
    edge:SetTexture("Interface\\Buttons\\WHITE8X8")
    if side=="TOP" or side=="BOTTOM" then
      edge:SetPoint(side.."LEFT",outline,side.."LEFT",0,0)
      edge:SetPoint(side.."RIGHT",outline,side.."RIGHT",0,0)
      edge:SetHeight(thickness)
    else
      edge:SetPoint("TOP"..side,outline,"TOP"..side,0,0)
      edge:SetPoint("BOTTOM"..side,outline,"BOTTOM"..side,0,0)
      edge:SetWidth(thickness)
    end
    if edge.SetSnapToPixelGrid then edge:SetSnapToPixelGrid(false) end
    if edge.SetTexelSnappingBias then edge:SetTexelSnappingBias(0) end
    outline.edges[side]=edge
  end
  return outline
end

local function paintOutline(outline,tint)
  for _,edge in pairs(outline.edges) do
    edge:SetVertexColor(tint[1],tint[2],tint[3],1)
  end
end

local function fitClassTitle(row,label)
  if row.fittedName==label then return end
  row.fittedName=label
  local face=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
  local size=10
  local available=91
  row.measure:SetText(label)
  row.measure:SetFont(face,size,"OUTLINE")
  local width=row.measure:GetStringWidth()
  if type(width)=="number" and width>available then
    size=math.max(8,math.floor(size*available/width*2)/2)
    row.measure:SetFont(face,size,"OUTLINE")
    width=row.measure:GetStringWidth()
  end
  local wraps=type(width)=="number" and width>available
  row.title:SetFont(face,size,"OUTLINE")
  if row.title.SetWordWrap then row.title:SetWordWrap(wraps) end
  row.title:SetHeight(wraps and 22 or 14)
  row.title:SetText(label)
end

local function newClassTile(fg)
  local row=CreateFrame("Button",nil,fg.window)
  row:SetFrameLevel(fg.window:GetFrameLevel()+3)
  local bg=row:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(row)
  bg:SetColorTexture(.035,.045,.060,.96)
  row.outline=makeOutline(row,1.5)
  row.icon=row:CreateTexture(nil,"ARTWORK")
  row.icon:SetSize(28,28)
  row.icon:SetPoint("LEFT",4,0)
  row.title=fg.Font(row,10,fg.colors.ivory,"","LEFT")
  row.title:SetPoint("TOPLEFT",row,"TOPLEFT",35,-5)
  row.title:SetPoint("TOPRIGHT",row,"TOPRIGHT",-2,-5)
  row.title:SetHeight(14)
  if row.title.SetWordWrap then row.title:SetWordWrap(false) end
  row.measure=fg.Font(row,10,fg.colors.ivory,"")
  row.measure:Hide()
  -- Match reference: name top-left, countdown bottom-right.
  row.time=fg.Font(row,12,fg.colors.green,"","RIGHT")
  row.time:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",35,5)
  row.time:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",-7,5)
  row.time:SetHeight(16)
  row:RegisterForClicks("LeftButtonUp","RightButtonUp","MiddleButtonUp")
  row:RegisterForDrag("LeftButton")
  row:SetScript("OnClick",function(_,mouse)
    if fg.inCombat then return end
    if mouse=="RightButton" then fg:CycleMode()
    elseif mouse=="MiddleButton" then fg:ToggleSettings()
    elseif fg.db.mode~="full" then fg:SetMode("full") end
  end)
  row:SetScript("OnDragStart",function() if not fg.inCombat and not fg.db.locked then fg.window:StartMoving() end end)
  row:SetScript("OnDragStop",function() if not fg.inCombat then fg.window:StopMovingOrSizing(); fg:SavePosition() end end)
  row:SetScript("OnEnter",function(b)
    if fg.inCombat or not GameTooltip then return end
    local a=fg.classState[b.buffKey] or {}
    GameTooltip:SetOwner(b,"ANCHOR_TOP")
    GameTooltip:SetText(a.name or b.buffKey,1,.8,.43)
    GameTooltip:AddLine(fg:ClassStatus(b.buffKey).." / "..fg:FormatTime(fg:Remain(a)),.87,.87,.83,true)
    GameTooltip:Show()
  end)
  row:SetScript("OnLeave",function() if not fg.inCombat and GameTooltip then GameTooltip:Hide() end end)
  return row
end

function FG:LayoutClassRows()
  if self.inCombat or not self.classDB then return end
  local list=self:ClassVisible()
  local mode=self.db.mode
  local keys={mode}
  for _,d in ipairs(list) do keys[#keys+1]=d.key end
  local signature=table.concat(keys,"|")
  if signature==self.classLayoutSignature then return end
  self.classLayoutSignature=signature
  local width=mode=="full" and 414 or mode=="compact" and 402 or 174
  local base=mode=="full" and 390 or 60
  -- All named class tiles have exactly the same width as a core compact tile.
  -- Center each incomplete row without stretching; wrap after three tiles.
  local columns=3
  local gap=mode=="icons" and 5 or 4
  local tileWidth=mode=="icons" and 51 or 128
  local tileHeight=mode=="icons" and 51 or 46
  local top=mode=="full" and 365 or 60
  if #list>0 and not self.classOuterOutline then
    self.classOuterOutline=makeOutline(self.window,1.5)
    paintOutline(self.classOuterOutline,self.colors.gold)
  end
  if self.classOuterOutline then self.classOuterOutline:SetShown(#list>0) end
  for i,d in ipairs(list) do
    local row=self.classRows[i]
    if not row then row=newClassTile(self); self.classRows[i]=row end
    row.buffKey=d.key
    row:ClearAllPoints()
    local line=math.floor((i-1)/columns)
    local count=math.min(columns,#list-line*columns)
    local lineWidth=count*tileWidth+(count-1)*gap
    local startX=math.floor((width-lineWidth)/2)
    row:SetPoint("TOPLEFT",self.window,"TOPLEFT",startX+((i-1)%columns)*(tileWidth+gap),
      -top-line*(tileHeight+gap))
    row:SetSize(tileWidth,tileHeight)
    local iconSize=mode=="icons" and 43 or 28
    row.icon:SetSize(iconSize,iconSize)
    row.icon:ClearAllPoints()
    row.icon:SetPoint("LEFT",row,"LEFT",mode=="icons" and 4 or 4,0)
    row.title:SetShown(mode~="icons")
    row.time:SetShown(mode~="icons")
    row:Show()
  end
  for i=#list+1,#self.classRows do self.classRows[i]:Hide(); self.classRows[i].buffKey=false end
  local lines=math.ceil(#list/columns)
  local bottom=mode=="full" and 30 or 8
  local height=lines>0 and (top+lines*tileHeight+(lines-1)*gap+bottom) or base
  self.window:SetSize(width,height)
end

local baseUpdate=FG.UpdateUI
function FG:UpdateUI()
  baseUpdate(self)
  if not self.window or not self.classDB then return end
  if not self.inCombat then self:LayoutClassRows() end
  for _,row in ipairs(self.classRows) do
    if type(row.buffKey)=="string" then
      local a=self.classState[row.buffKey] or {}
      local status=self:ClassStatus(row.buffKey)
      local tint=status=="active" and self.colors.green or status=="warning" and self.colors.amber or status=="missing" and self.colors.red or self.colors.muted
      if not self.inCombat then fitClassTitle(row,a.name or row.buffKey) end
      row.time:SetText((status=="active" or status=="warning") and self:FormatTime(self:Remain(a)) or status:upper())
      row.time:SetTextColor(tint[1],tint[2],tint[3],1)
      row.icon:SetTexture(a.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
      local flash=self.db.flash and (status=="warning" or status=="missing")
      row.icon:SetAlpha(flash and (.65+.35*math.abs(math.sin(self:Now()*5))) or 1)
      paintOutline(row.outline,tint)
    end
  end
end
