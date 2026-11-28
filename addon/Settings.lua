local _, FG = ...

local function setTextColor(label, c)
  label:SetTextColor(c[1], c[2], c[3], 1)
end

local function button(parent, label, w, h, action)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(w, h)
  FG:SkinPanel(b, true)
  b.text = FG.Font(b, 12, FG.colors.gold, label, "CENTER")
  b.text:SetAllPoints()
  b:SetScript("OnClick", function(...)
    if not FG.inCombat then action(...) end
  end)
  b:SetScript("OnEnter", function(self)
    if self.SetBackdropBorderColor then self:SetBackdropBorderColor(.98, .78, .41, 1) end
  end)
  b:SetScript("OnLeave", function(self)
    if self.SetBackdropBorderColor then self:SetBackdropBorderColor(.37, .29, .17, 1) end
  end)
  return b
end

function FG:CreateSettings()
  local frame = CreateFrame("Frame", "FoodGuardianSettingsFrame", UIParent, "BackdropTemplate")
  frame:SetSize(440, 648)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 5)
  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:Hide()
  self:SkinPanel(frame, true)
  if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(.8, .61, .30, 1) end
  self.settings = frame

  local header = CreateFrame("Frame", nil, frame)
  header:SetPoint("TOPLEFT")
  header:SetPoint("TOPRIGHT")
  header:SetHeight(51)
  header:EnableMouse(true)
  header:SetScript("OnMouseDown", function(_, mouse)
    if mouse == "LeftButton" and not FG.inCombat then frame:StartMoving() end
  end)
  header:SetScript("OnMouseUp", function(_, mouse)
    if mouse == "LeftButton" and not FG.inCombat then frame:StopMovingOrSizing() end
  end)
  local title = self.Font(header, 17, self.colors.bright, "FOOD GUARDIAN  ·  SETTINGS")
  title:SetPoint("TOPLEFT", 17, -11)
  local caption = self.Font(header, 10, self.colors.cyan, "FOREVER  /  V"..self.version.."  /  PLAYER PREFERENCES")
  caption:SetPoint("TOPLEFT", 17, -33)
  local close = button(header, "X", 28, 26, function() frame:Hide() end)
  close:SetPoint("TOPRIGHT", -10, -10)
  local line = frame:CreateTexture(nil, "ARTWORK")
  line:SetTexture("Interface\\Buttons\\WHITE8X8")
  line:SetPoint("TOPLEFT", 10, -56)
  line:SetPoint("TOPRIGHT", -10, -56)
  line:SetHeight(1)
  line:SetVertexColor(.72, .54, .24, .9)

  local thresholdTitle = self.Font(frame, 12, self.colors.gold, "ALERT THRESHOLDS")
  thresholdTitle:SetPoint("TOPLEFT", 19, -71)
  local sub = self.Font(frame, 10, self.colors.muted, "Warn when a live buff reaches this remaining time")
  sub:SetPoint("TOPLEFT", 19, -91)

  frame.thresholds = {}
  local thresholds = {
    { key = "foodWarning", name = "Well Fed", seconds = 60 },
    { key = "bagWarning", name = "Sleeping Bag", seconds = 60 },
    { key = "campWarning", name = "Camp Benefits", seconds = 60 },
  }
  for i, data in ipairs(thresholds) do
    local y = -115 - (i - 1) * 42
    local text = self.Font(frame, 12, self.colors.ivory, data.name)
    text:SetPoint("TOPLEFT", 23, y - 3)
    local minus = button(frame, "-", 28, 26, function()
      FG.db[data.key] = math.max(30, FG.db[data.key] - data.seconds)
      FG:UpdateSettings()
      FG:Refresh(false)
    end)
    minus:SetPoint("TOPLEFT", 250, y - 3)
    local count = self.Font(frame, 12, self.colors.gold, "", "CENTER")
    count:SetPoint("TOPLEFT", 282, y - 3)
    count:SetSize(64, 26)
    local plus = button(frame, "+", 28, 26, function()
      FG.db[data.key] = math.min(1800, FG.db[data.key] + data.seconds)
      FG:UpdateSettings()
      FG:Refresh(false)
    end)
    plus:SetPoint("TOPLEFT", 352, y - 3)
    frame.thresholds[data.key] = count
  end

  local divider = frame:CreateTexture(nil, "ARTWORK")
  divider:SetTexture("Interface\\Buttons\\WHITE8X8")
  divider:SetPoint("TOPLEFT", 18, -247)
  divider:SetPoint("TOPRIGHT", -18, -247)
  divider:SetHeight(1)
  divider:SetVertexColor(.4, .32, .19, .7)
  local modeHeading = self.Font(frame, 12, self.colors.gold, "DISPLAY MODE")
  modeHeading:SetPoint("TOPLEFT", 19, -260)
  frame.modeButtons = {}
  local modes = {
    { key = "full", label = "FULL WINDOW" },
    { key = "compact", label = "COMPACT BAR" },
    { key = "icons", label = "ICON MODE" },
  }
  for i, entry in ipairs(modes) do
    local selectedMode = entry.key
    local toggle = button(frame, entry.label, 123, 30, function()
      FG:SetMode(selectedMode)
    end)
    toggle:SetPoint("TOPLEFT", 18 + (i - 1) * 136, -285)
    frame.modeButtons[entry.key] = toggle
  end
  local modeHint = self.Font(frame, 10, self.colors.muted,
    "In minimal modes: left-click for Full, right-click to cycle, drag to move.")
  modeHint:SetPoint("TOPLEFT", 19, -326)
  local appearance = self.Font(frame, 12, self.colors.gold, "APPEARANCE & NOTIFICATIONS")
  appearance:SetPoint("TOPLEFT", 19, -354)

  frame.toggles = {}
  local opts = {
    { "flash", "Pulse low / missing buffs" },
    { "sound", "Sound when active buff reaches low duration" },
    { "showTent", "Show Camp Tent / Boosted Rest strip" },
    { "minimap", "Show minimap shield launcher" },
    { "locked", "Lock tracker position and scale" },
    { "hideInCombat", "Hide tracker in combat (OFF = cached timers)" },
  }
  for i, option in ipairs(opts) do
    local key = option[1]
    local y = -379 - (i - 1) * 26
    local label = self.Font(frame, 11, self.colors.ivory, option[2])
    label:SetPoint("TOPLEFT", 24, y - 4)
    local switch = button(frame, "OFF", 52, 24, function()
      FG.db[key] = not FG.db[key]
      if key == "showTent" or key == "locked" then FG:ApplyLayout() end
      if key == "hideInCombat" or key == "minimap" then FG:ApplyCombatVisibility() end
      FG:UpdateSettings()
      FG:Refresh(false)
    end)
    switch:SetPoint("TOPRIGHT", -23, y)
    frame.toggles[key] = switch
  end

  local sText = self.Font(frame, 11, self.colors.ivory, "Window scale")
  sText:SetPoint("TOPLEFT", 23, -541)
  frame.scaleText = self.Font(frame, 11, self.colors.gold, "100%", "CENTER")
  frame.scaleText:SetPoint("TOPLEFT", 293, -541)
  frame.scaleText:SetSize(52, 22)
  local less = button(frame, "-", 25, 23, function() FG:SetScale(FG.db.scale - .05) end)
  less:SetPoint("TOPLEFT", 260, -538)
  local more = button(frame, "+", 25, 23, function() FG:SetScale(FG.db.scale + .05) end)
  more:SetPoint("TOPLEFT", 350, -538)

  frame.demoButtons = {}
  local previewModes = {
    { key = "healthy", label = "DEMO: HEALTHY" },
    { key = "warning", label = "DEMO: WARNING" },
    { key = "off", label = "LIVE BUFFS" },
  }
  for i, item in ipairs(previewModes) do
    local variant = item.key
    local demo = button(frame, item.label, 123, 28, function()
      FG:ToggleDemo(variant)
    end)
    demo:SetPoint("TOPLEFT", 18 + (i - 1) * 136, -574)
    frame.demoButtons[item.key] = demo
  end
  local reset = button(frame, "RESET POSITION", 142, 25, function()
    FG:ResetPosition()
  end)
  reset:SetPoint("BOTTOMRIGHT", -16, 12)
  local classButton = button(frame, "CLASS BUFFS", 142, 25, function() FG:OpenClassSettings() end)
  classButton:SetPoint("BOTTOMLEFT", 16, 12)
  frame.classButton=classButton
  self:CreateClassSettings()

  if type(UISpecialFrames) == "table" then
    table.insert(UISpecialFrames, "FoodGuardianSettingsFrame")
  end
  frame:SetScript("OnShow", function() FG:UpdateSettings() end)
end

function FG:UpdateSettings()
  if not self.settings then return end
  for key, label in pairs(self.settings.thresholds) do
    local value = self.db[key]
    local result = (value % 60 == 0) and (value / 60 .. "m") or
      (string.format("%.1fm", value / 60))
    label:SetText(result)
  end
  for key, buttonFrame in pairs(self.settings.toggles) do
    local yes = not not self.db[key]
    buttonFrame.text:SetText(yes and "ON" or "OFF")
    setTextColor(buttonFrame.text, yes and self.colors.green or self.colors.muted)
    if buttonFrame.SetBackdropBorderColor then
      local c = yes and self.colors.green or self.colors.muted
      buttonFrame:SetBackdropBorderColor(c[1] * .55, c[2] * .55, c[3] * .55, 1)
    end
  end
  for key, b in pairs(self.settings.modeButtons) do
    local selected = self.db.mode == key
    local tint = selected and self.colors.bright or self.colors.muted
    setTextColor(b.text, tint)
    if b.SetBackdropBorderColor then
      b:SetBackdropBorderColor(selected and .98 or .36,
        selected and .72 or .29, selected and .31 or .17, 1)
    end
  end
  for key, b in pairs(self.settings.demoButtons) do
    local selected = (key == "off" and not self.demo) or
      (self.demo and key == self.demoVariant)
    local tint = selected and self.colors.green or self.colors.muted
    setTextColor(b.text, tint)
  end
  self.settings.scaleText:SetText(math.floor(self.db.scale * 100 + 0.5) .. "%")
end

function FG:ToggleSettings()
  if not self.settings then return end
  if self.inCombat then
    self:Print("Settings are hidden until combat ends.")
    return
  end
  if self.settings:IsShown() then self.settings:Hide()
  else self.settings:Show() end
end


function FG:CreateClassSettings()
  local parent=self.settings
  local p=CreateFrame("Frame",nil,parent,"BackdropTemplate")
  p:SetAllPoints(parent)
  p:SetFrameLevel(parent:GetFrameLevel()+10)
  p:EnableMouse(true)
  self:SkinPanel(p,true)
  p:Hide()
  parent.classPage=p
  p.heading=self.Font(p,17,self.colors.bright,"CLASS BUFFS")
  p.heading:SetPoint("TOPLEFT",17,-15)
  p.caption=self.Font(p,10,self.colors.cyan,"")
  p.caption:SetPoint("TOPLEFT",17,-40)
  local back=button(p,"BACK",70,26,function() p:Hide() end)
  back:SetPoint("TOPRIGHT",-12,-12)
  local function toggle(label,key,y)
    local f=self.Font(p,12,self.colors.ivory,label); f:SetPoint("TOPLEFT",19,y-5)
    local b=button(p,"OFF",60,25,function()
      FG.classDB[key]=not FG.classDB[key]; FG:ClassChanged()
    end)
    b:SetPoint("TOPRIGHT",-19,y)
    return b
  end
  p.enabled=toggle("Enable optional buff tracking","enabled",-65)
  p.missing=toggle("Show missing buffs","missing",-97)
  local warning=self.Font(p,12,self.colors.ivory,"Expiration warning")
  warning:SetPoint("TOPLEFT",19,-135)
  p.warning=self.Font(p,12,self.colors.gold,"","CENTER")
  p.warning:SetPoint("TOPRIGHT",-55,-135)
  p.warning:SetSize(70,22)
  local less=button(p,"-",25,23,function() FG.classDB.warning=math.max(15,FG.classDB.warning-15); FG:ClassChanged() end)
  less:SetPoint("TOPRIGHT",-130,-130)
  local more=button(p,"+",25,23,function() FG.classDB.warning=math.min(1800,FG.classDB.warning+15); FG:ClassChanged() end)
  more:SetPoint("TOPRIGHT",-19,-130)
  p.entries={}
  p.pageIndex=1
  for i=1,10 do
    local y=-176-(i-1)*34
    local label=self.Font(p,11,self.colors.ivory,"")
    label:SetPoint("TOPLEFT",19,y-5)
    label:SetWidth(290)
    local b=button(p,"OFF",52,25,function()
      local d=p.entries[i].definition
      if d then FG.classDB.selected[d.key]=not FG.classDB.selected[d.key]; FG:ClassChanged() end
    end)
    b:SetPoint("TOPRIGHT",-50,y)
    local remove=button(p,"X",25,25,function()
      local d=p.entries[i].definition
      if d and d.category=="custom" then FG:RemoveClassBuff(d.label) end
    end)
    remove:SetPoint("TOPRIGHT",-19,y)
    p.entries[i]={label=label,toggle=b,remove=remove}
  end
  local prev=button(p,"PREV",70,24,function() p.pageIndex=math.max(1,p.pageIndex-1); FG:UpdateClassSettings() end)
  prev:SetPoint("TOPLEFT",19,-524)
  local nextButton=button(p,"NEXT",70,24,function() p.pageIndex=p.pageIndex+1; FG:UpdateClassSettings() end)
  nextButton:SetPoint("TOPRIGHT",-19,-524)
  p.pageLabel=self.Font(p,11,self.colors.gold,"","CENTER")
  p.pageLabel:SetPoint("TOP",0,-529)
  local hint=self.Font(p,10,self.colors.muted,"Add any helpful aura by exact name or spell ID (up to 8).")
  hint:SetPoint("TOPLEFT",19,-560)
  local edit=CreateFrame("EditBox",nil,p,"InputBoxTemplate")
  edit:SetSize(280,26)
  edit:SetPoint("TOPLEFT",24,-578)
  edit:SetAutoFocus(false)
  p.input=edit
  local function add()
    if FG.inCombat then return end
    if FG:AddClassBuff(edit:GetText()) then
      edit:SetText(""); edit:ClearFocus()
      p.pageIndex=math.ceil(#FG:ClassDefinitions()/10)
      FG:UpdateClassSettings()
    else FG:Print("Invalid or duplicate buff, or custom buff limit reached.") end
  end
  edit:SetScript("OnEnterPressed",add)
  local addButton=button(p,"ADD",82,26,add)
  addButton:SetPoint("TOPRIGHT",-19,-578)
  local note=self.Font(p,10,self.colors.muted,"Weapon options track temporary enhancements by hand, not poison type.")
  note:SetPoint("BOTTOMLEFT",19,17)
end

function FG:OpenClassSettings()
  if self.inCombat then return end
  self.settings.classPage:Show()
  self:UpdateClassSettings()
end

function FG:UpdateClassSettings()
  local p=self.settings and self.settings.classPage
  if not p or self.inCombat then return end
  local db=self.classDB
  p.caption:SetText((self.classToken~="" and self.classToken or "CLASS UNKNOWN").."  /  CHARACTER PREFERENCES")
  local function paint(b,on)
    b.text:SetText(on and "ON" or "OFF")
    setTextColor(b.text,on and self.colors.green or self.colors.muted)
  end
  paint(p.enabled,db.enabled); paint(p.missing,db.missing)
  p.warning:SetText(db.warning.."s")
  local definitions=self:ClassDefinitions()
  local pages=math.max(1,math.ceil(#definitions/10))
  p.pageIndex=math.min(pages,math.max(1,p.pageIndex))
  p.pageLabel:SetText(p.pageIndex.." / "..pages)
  for i,row in ipairs(p.entries) do
    local d=definitions[(p.pageIndex-1)*10+i]
    row.definition=d
    row.label:SetShown(d~=nil)
    row.toggle:SetShown(d~=nil)
    row.remove:SetShown(d~=nil and d.category=="custom")
    if d then
      local prefix=d.category=="external" and "External: " or d.category=="custom" and "Custom: " or ""
      row.label:SetText(prefix..d.label)
      paint(row.toggle,db.selected[d.key])
    end
  end
end
