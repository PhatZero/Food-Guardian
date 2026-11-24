local _, FG = ...

local function atan2(y, x)
  if math.atan2 then return math.atan2(y, x) end
  if x > 0 then return math.atan(y / x) end
  if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
  if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
  if y > 0 then return math.pi / 2 end
  return -math.pi / 2
end

local function minimapGeometry()
  local width = FG:SafeNumber(Minimap:GetWidth()) or 140
  local height = FG:SafeNumber(Minimap:GetHeight()) or 140
  if width < 40 then width = 140 end
  if height < 40 then height = 140 end
  local shape = "ROUND"
  if type(GetMinimapShape) == "function" then
    local ok, result = pcall(GetMinimapShape)
    if ok and type(result) == "string" then shape = result end
  end
  return width, height, shape
end

-- EllesmereUI Minimap collects named addon buttons into its own row/flyout.
-- Its layout is authoritative while enabled; writing our rim anchor over it
-- makes buttons jump, disappear from the flyout, or overlap the map.
function FG:IsEllesmereMinimapActive()
  local externalDB = rawget(_G, "_EMM_DB")
  local profile = type(externalDB) == "table" and externalDB.profile
  local config = type(profile) == "table" and profile.minimap
  return type(config) == "table" and config.enabled ~= false
end

-- Do not repeatedly Show() a button that another minimap addon intentionally
-- hid for grouping. Only touch visibility when our own preference changes.
function FG:ApplyMinimapVisibility()
  if not self.minimap or not self.db then return end
  local wanted = not not (self.db.minimap and not self:ShouldHideInCombat())
  if wanted ~= self.minimapRequestedVisible then
    self.minimapRequestedVisible = wanted
    self.minimap:SetShown(wanted)
  end
end

function FG:RepositionMinimap()
  local icon = self.minimap
  if not icon or self:IsEllesmereMinimapActive() then return end
  -- A disabled external minimap may leave our button inside its flyout.
  -- Restore the native parent, art, and drag behavior if it is switched off.
  if self.nativeRestorePending or icon:GetParent() ~= Minimap then
    if self.inCombat then return end
    icon:SetParent(Minimap)
    icon:SetAlpha(1)
    icon:SetSize(33, 33)
    if icon.shield then
      icon.shield:ClearAllPoints()
      icon.shield:SetSize(23, 23)
      icon.shield:SetPoint("CENTER", icon, "CENTER", -1, 1)
    end
    icon:RegisterForDrag("LeftButton")
    if icon.nativeDragStart then icon:SetScript("OnDragStart", icon.nativeDragStart) end
    if icon.nativeDragStop then icon:SetScript("OnDragStop", icon.nativeDragStop) end
  end
  local width, height, shape = minimapGeometry()
  local a = math.rad(self.db.minimapAngle or 220)
  local dx, dy = math.cos(a), math.sin(a)
  local x, y
  if shape == "SQUARE" then
    -- For square minimaps, intersect the ray with the appropriate edge.
    local radius = math.min((width / 2 + 7) / math.max(math.abs(dx), .001),
      (height / 2 + 7) / math.max(math.abs(dy), .001))
    x, y = dx * radius, dy * radius
  else
    -- Keep the shield centered on the actual rim, including resized minimaps.
    x, y = dx * (width / 2 + 8), dy * (height / 2 + 8)
  end
  icon:ClearAllPoints()
  icon:SetPoint("CENTER", Minimap, "CENTER", x, y)
  self.minimapWidth, self.minimapHeight, self.minimapShape = width, height, shape
end

function FG:CreateMinimap()
  if not Minimap then
    self:Print("Minimap unavailable; /fg still opens the tracker.")
    return
  end
  local icon = CreateFrame("Button", "FoodGuardianMinimapIcon", Minimap)
  icon:SetFrameStrata("MEDIUM")
  icon:SetFrameLevel(Minimap:GetFrameLevel() + 8)
  icon:SetSize(33, 33)
  icon:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  icon:RegisterForDrag("LeftButton")
  icon:EnableMouse(true)
  local badge = icon:CreateTexture(nil, "BACKGROUND")
  badge:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  badge:SetSize(55, 55)
  badge:SetPoint("CENTER", icon, "CENTER", 0, 0)
  local shield = icon:CreateTexture(nil, "ARTWORK")
  shield:SetSize(23, 23)
  shield:SetPoint("CENTER", -1, 1)
  shield:SetTexture(self.icons.guardian)
  icon.shield = shield
  -- Expose the real icon texture for minimap collectors such as EllesmereUI.
  icon.icon = shield
  local dot = icon:CreateTexture(nil, "OVERLAY")
  dot:SetSize(8, 8)
  dot:SetPoint("BOTTOMRIGHT", -1, 2)
  dot:SetTexture("Interface\\Buttons\\WHITE8X8")
  icon.dot = dot
  icon:SetScript("OnClick", function(_, mouse)
    if mouse == "RightButton" then FG:ToggleSettings() else FG:ToggleWindow() end
  end)
  icon.nativeDragStart = function(self)
    if FG.inCombat then return end
    self:SetScript("OnUpdate", function()
      if FG.inCombat then self:SetScript("OnUpdate", nil); return end
      local scale = Minimap:GetEffectiveScale()
      if not scale or scale <= 0 then scale = UIParent:GetEffectiveScale() end
      if not scale or scale <= 0 then return end
      local cursorX, cursorY = GetCursorPosition()
      local midX, midY = Minimap:GetCenter()
      if cursorX and cursorY and midX and midY then
        local a = atan2(cursorY / scale - midY, cursorX / scale - midX)
        FG.db.minimapAngle = (math.deg(a) + 360) % 360
        FG:RepositionMinimap()
      end
    end)
  end
  icon.nativeDragStop = function(self) self:SetScript("OnUpdate", nil) end
  icon:SetScript("OnDragStart", icon.nativeDragStart)
  icon:SetScript("OnDragStop", icon.nativeDragStop)
  icon:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)
  icon:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Food Guardian |cffc2a46b[v1.0.2]|r", 1, .82, .46)
    GameTooltip:AddLine("Left-click: Toggle tracker", .85, .9, .82)
    GameTooltip:AddLine("Right-click: Settings", .85, .9, .82)
    if FG:IsEllesmereMinimapActive() then
      GameTooltip:AddLine("Position: EllesmereUI minimap settings", .85, .9, .82)
    else
      GameTooltip:AddLine("Drag: Move minimap icon", .85, .9, .82)
    end
    GameTooltip:AddLine("/fg demo: Preview all states", .4, .85, .88)
    GameTooltip:Show()
  end)
  icon:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  self.minimap = icon
  self.minimapManagedByEllesmere = self:IsEllesmereMinimapActive()
  self:RepositionMinimap()
  self:UpdateMinimap()
end

function FG:UpdateMinimap()
  if not self.minimap then return end
  local managed = self:IsEllesmereMinimapActive()
  if managed ~= self.minimapManagedByEllesmere then
    self.minimapManagedByEllesmere = managed
    if not managed then self.nativeRestorePending = true end
  end
  if not managed then
    if self.nativeRestorePending and not self.inCombat then
      self:RepositionMinimap()
      self.nativeRestorePending = nil
      -- The external manager may have hidden even an ungrouped button.
      -- Reapply Food Guardian's own visibility when native mode resumes.
      self.minimapRequestedVisible = nil
    else
      local width, height, shape = minimapGeometry()
      if width ~= self.minimapWidth or height ~= self.minimapHeight or shape ~= self.minimapShape then
        self:RepositionMinimap()
      end
    end
  end
  self:ApplyMinimapVisibility()
  if not self.minimapRequestedVisible then return end
  local statusFood = self:Status("food")
  local statusBag = self:Status("bag")
  local statusCamp = self:Status("camp")
  local color = self.colors.green
  if statusFood == "missing" or statusBag == "missing" or statusCamp == "missing" then
    color = self.colors.red
  elseif statusFood == "warning" or statusBag == "warning" or statusCamp == "warning" then
    color = self.colors.amber
  elseif statusFood == "unknown" or statusBag == "unknown" or statusCamp == "unknown" then
    color = self.colors.muted
  end
  self.minimap.dot:SetVertexColor(color[1], color[2], color[3], 1)
end
