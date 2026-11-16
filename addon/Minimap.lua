local _, FG = ...

local function atan2(y, x)
  if math.atan2 then return math.atan2(y, x) end
  if x > 0 then return math.atan(y / x) end
  if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
  if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
  if y > 0 then return math.pi / 2 end
  return -math.pi / 2
end

function FG:RepositionMinimap()
  local icon = self.minimap
  if not icon then return end
  local a = math.rad(self.db.minimapAngle or 220)
  icon:ClearAllPoints()
  icon:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * 78, math.sin(a) * 78)
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
  badge:SetPoint("TOPLEFT", 0, 0)
  local shield = icon:CreateTexture(nil, "ARTWORK")
  shield:SetSize(23, 23)
  shield:SetPoint("CENTER", -1, 1)
  shield:SetTexture(self.icons.guardian)
  icon.shield = shield
  local dot = icon:CreateTexture(nil, "OVERLAY")
  dot:SetSize(8, 8)
  dot:SetPoint("BOTTOMRIGHT", -1, 2)
  dot:SetTexture("Interface\\Buttons\\WHITE8X8")
  icon.dot = dot
  icon:SetScript("OnClick", function(_, mouse)
    if mouse == "RightButton" then FG:ToggleSettings() else FG:ToggleWindow() end
  end)
  icon:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local scale = UIParent:GetEffectiveScale()
      local cursorX, cursorY = GetCursorPosition()
      local midX, midY = Minimap:GetCenter()
      if cursorX and midX then
        local a = atan2(cursorY / scale - midY, cursorX / scale - midX)
        FG.db.minimapAngle = (math.deg(a) + 360) % 360
        FG:RepositionMinimap()
      end
    end)
  end)
  icon:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  icon:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Food Guardian |cffc2a46b[v1.0.0]|r", 1, .82, .46)
    GameTooltip:AddLine("Left-click: Toggle tracker", .85, .9, .82)
    GameTooltip:AddLine("Right-click: Settings", .85, .9, .82)
    GameTooltip:AddLine("Drag: Move minimap icon", .85, .9, .82)
    GameTooltip:AddLine("/fg demo: Preview all states", .4, .85, .88)
    GameTooltip:Show()
  end)
  icon:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  self.minimap = icon
  self:RepositionMinimap()
  self:UpdateMinimap()
end

function FG:UpdateMinimap()
  if not self.minimap then return end
  self.minimap:SetShown(self.db.minimap)
  if not self.db.minimap then return end
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
