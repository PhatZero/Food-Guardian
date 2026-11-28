local addonName, FG = ...
FG.name = addonName
FG.version = "1.1b6"
FG.targetInterface = 16001
FG.items = { sleepingBag = 211527 }
FG.spells = { sleepingBag = 429959, camp = 1229741, tent = 1229451 }
FG.icons = {
  food = "Interface\\AddOns\\FoodGuardian\\Textures\\FoodRoast.tga",
  bag = "Interface\\AddOns\\FoodGuardian\\Textures\\Bedroll.tga",
  camp = "Interface\\AddOns\\FoodGuardian\\Textures\\Campfire.tga",
  tent = "Interface\\Icons\\INV_Misc_LeatherScrap_01",
  guardian = "Interface\\AddOns\\FoodGuardian\\Textures\\GuardianShield.tga",
}
FG.colors = {
  gold = { 0.94, 0.74, 0.39 }, bright = { 1, 0.89, 0.63 },
  muted = { 0.65, 0.67, 0.65 }, ivory = { 0.95, 0.93, 0.87 },
  green = { 0.37, 0.87, 0.64 }, amber = { 1, 0.65, 0.25 },
  red = { 1, 0.37, 0.34 }, cyan = { 0.30, 0.79, 0.85 },
}
local defaults = {
  visible = true, mode = "full", locked = false, minimap = true, hideInCombat = false,
  flash = true, sound = false, showTent = true,
  foodWarning = 180, bagWarning = 600, campWarning = 600,
  scale = 1, x = 0, y = 85, minimapAngle = 220,
}
FG.defaults = defaults
FG.state = { food = {}, bag = {}, camp = {}, tent = {} }
FG.demo = false
FG.demoVariant = "warning"
FG.ready = false
FG.lastStatuses = {}
FG.elapsed = 0
FG.scanElapsed = 0
FG.protectionEvents = {}
FG.protectionPending = false

function FG:Print(message)
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffce75Food Guardian|r  " .. tostring(message))
  end
end

function FG:SafeNumber(value)
  local ok, n = pcall(function()
    if type(value) == "number" then return value end
    return tonumber(value)
  end)
  if ok and type(n) == "number" and n == n then return n end
  return nil
end

function FG:SafeString(value)
  local ok, result = pcall(function() return tostring(value) end)
  if ok and type(result) == "string" then return result end
  return nil
end

function FG:Now()
  if type(GetTime) == "function" then
    local ok, result = pcall(GetTime)
    if ok then return self:SafeNumber(result) or 0 end
  end
  return 0
end

function FG:Remain(effect)
  if not effect or not effect.active then return nil end
  local endTime = self:SafeNumber(effect.expirationTime)
  if endTime and endTime > 0 then return math.max(0, endTime - self:Now()) end
  return nil
end

function FG:FormatTime(seconds)
  seconds = self:SafeNumber(seconds)
  if not seconds then return "ACTIVE" end
  seconds = math.max(0, math.floor(seconds + 0.5))
  if seconds >= 3600 then
    return string.format("%dh %02dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
  end
  return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

function FG:Threshold(key)
  local db = self.db or self.defaults
  return db[key .. "Warning"] or 300
end

function FG:Status(key)
  local aura
  if self.demo then
    aura = self:GetDisplayState()[key]
  else
    aura = self.state[key]
    if (self.auraReadFailed or not self.scannedOnce) and not (aura and aura.active) then return "unknown" end
  end
  if not aura or not aura.active then return "missing" end
  local remaining = self:Remain(aura)
  if remaining and remaining <= 0 then return "missing" end
  if remaining and remaining <= self:Threshold(key) then return "warning" end
  return "active"
end

function FG:DemoState()
  local now = self:Now()
  local warning = self.demoVariant ~= "healthy"
  return {
    food = { active = true, name = "Well Fed", duration = 900,
      expirationTime = now + (warning and 88 or 867) },
    bag = { active = true, name = "Well-Rested", duration = 3600,
      expirationTime = now + 3581, stacks = 3 },
    camp = { active = true, name = "Camp Benefits", duration = 3600,
      expirationTime = now + (warning and 434 or 3128) },
    tent = { active = true, name = "Boosted Rest", duration = 3600,
      expirationTime = now + 1800 },
    bagOwned = true, bagCooldown = 0,
  }
end

function FG:GetDisplayState()
  if self.demo then
    if not self.demoData then self.demoData = self:DemoState() end
    return self.demoData
  end
  return self.state
end

function FG:NotifyTransitions()
  if not self.scannedOnce or self.demo then return end
  local playWarning = false
  for _, key in ipairs({ "food", "bag", "camp" }) do
    local status = self:Status(key)
    local previous = self.lastStatuses[key]
    if self.db and self.db.sound and previous == "active" and status ~= "active" and status ~= "unknown" then
      playWarning = true
    end
    self.lastStatuses[key] = status
  end
  for _, d in ipairs(self:ClassSelected()) do
    local status=self:ClassStatus(d.key)
    if self.db.sound and self.lastStatuses[d.key]=="active" and (status=="warning" or status=="missing") then playWarning=true end
    self.lastStatuses[d.key]=status
  end
  -- One chime even if multiple buffs expire simultaneously.
  if playWarning and PlaySound then
    pcall(function()
      if SOUNDKIT and SOUNDKIT.RAID_WARNING then PlaySound(SOUNDKIT.RAID_WARNING, "Master")
      else PlaySound(8959, "Master") end
    end)
  end
end

-- Observe Blizzard's own blocked/forbidden event. We intentionally never
-- suppress it or guess which addon caused it; the blame field can be indirect.
function FG:RecordProtectedAction(eventName, blamedAddon, functionName)
  local entry = {
    event = self:SafeString(eventName) or "unknown",
    blamed = self:SafeString(blamedAddon) or "unknown",
    action = self:SafeString(functionName) or "UNKNOWN()",
    time = self:Now(),
  }
  if type(debugstack) == "function" then
    local ok, result = pcall(debugstack, 2, 10, 10)
    if ok and type(result) == "string" then entry.stack = string.sub(result, 1, 4000) end
  end
  table.insert(self.protectionEvents, 1, entry)
  if #self.protectionEvents > 8 then table.remove(self.protectionEvents) end
  if self.charDB then self.charDB.lastProtection = entry end
  self.protectionPending = true
end

function FG:PrintProtectionInfo()
  local entries = self.protectionEvents
  local last = entries and entries[1] or (self.charDB and self.charDB.lastProtection)
  if not last then
    self:Print("No blocked-action event captured yet. For full details: /console taintLog 2, restart WoW, reproduce, then inspect Logs/taint.log.")
    return
  end
  self:Print("Protected action: " .. tostring(last.event) ..
    " | addon=" .. tostring(last.blamed) .. " | function=" .. tostring(last.action))
  if last.stack then self:Print("Captured stack: " .. tostring(last.stack)) end
  self:Print("For the complete cause, enable /console taintLog 2 and send Logs/taint.log.")
end

function FG:Refresh(rescan)
  -- During combat, only render our own cached, ordinary Lua values.
  -- Never query aura/inventory APIs or manipulate a minimap manager here.
  if self.inCombat then
    if not self:ShouldHideInCombat() then
      self:NotifyTransitions()
      if self.UpdateUI then self:UpdateUI() end
    end
    return
  end
  if rescan then
    if self.ScanAuras then self:ScanAuras() end
    if self.ScanInventory then self:ScanInventory() end
    self.scannedOnce = true
  end
  self:NotifyTransitions()
  if self.UpdateUI then self:UpdateUI() end
  if self.UpdateMinimap then self:UpdateMinimap() end
end

function FG:SavePosition()
  if not (self.window and self.db) then return end
  local _, _, _, x, y = self.window:GetPoint(1)
  x = self:SafeNumber(x)
  y = self:SafeNumber(y)
  if x and y then self.db.x, self.db.y = x, y end
end

function FG:ResetPosition()
  if self.inCombat then return end
  self.db.x, self.db.y = 0, 85
  if self.window then
    self.window:ClearAllPoints()
    self.window:SetPoint("CENTER", UIParent, "CENTER", 0, 85)
  end
  self:Print("Window position reset.")
end

function FG:SetScale(value)
  if self.inCombat then return end
  value = self:SafeNumber(value) or 1
  value = math.floor(math.max(0.70, math.min(1.45, value)) * 20 + 0.5) / 20
  self.db.scale = value
  if self.window then self.window:SetScale(value) end
  if self.UpdateSettings then self:UpdateSettings() end
end

function FG:ToggleDemo(variant)
  if self.inCombat then return end
  if variant == "off" then
    self.demo = false
  elseif variant == "healthy" or variant == "warning" then
    self.demo = true
    self.demoVariant = variant
  else
    self.demo = not self.demo
    if self.demo then self.demoVariant = "warning" end
  end
  self.demoData = self.demo and self:DemoState() or nil
  self:Refresh(false)
  if self.UpdateSettings then self:UpdateSettings() end
  self:Print(self.demo and ("Demo " .. self.demoVariant .. " ON (example timers only).")
    or "Demo OFF. Live tracking restored.")
end

function FG:ShouldHideInCombat()
  return self.db and self.db.hideInCombat and self.inCombat
end

function FG:ApplyCombatVisibility()
  if not self.db then return end
  local hidden = self:ShouldHideInCombat()
  if self.settings and self.inCombat and self.settings:IsShown() then
    self.restoreSettingsAfterCombat = true
  end
  local wanted = self.db.visible and not hidden
  if self.window and self.window:IsShown() ~= wanted then self.window:SetShown(wanted) end
  -- Visible combat mode leaves externally managed minimap buttons alone.
  if self.minimap and (not self.inCombat or hidden) then self:ApplyMinimapVisibility() end
  if self.settings then
    if self.inCombat then
      self.settings:Hide()
    elseif self.restoreSettingsAfterCombat then
      self.restoreSettingsAfterCombat = nil
      self.settings:Show()
    end
  end
end

function FG:ToggleWindow()
  if self.inCombat then return end
  self.db.visible = not self.db.visible
  self:ApplyCombatVisibility()
end

function FG:SetMode(mode)
  if self.inCombat then return false end
  if mode == "compact" or mode == "bar" then mode = "compact" end
  if mode == "icon" then mode = "icons" end
  if mode ~= "full" and mode ~= "compact" and mode ~= "icons" then return false end
  self.db.mode = mode
  self.db.compact = nil -- migrate and discard the v0.0.1 legacy toggle
  if self.ApplyLayout then self:ApplyLayout() end
  self:Refresh(false)
  if self.UpdateSettings then self:UpdateSettings() end
  return true
end

function FG:CycleMode()
  local order = { full = "compact", compact = "icons", icons = "full" }
  self:SetMode(order[self.db.mode] or "full")
end

function FG:ToggleCompact()
  self:SetMode(self.db.mode == "compact" and "full" or "compact")
end

function FG:Debug()
  self:Print("Version "..self.version.." | layout: "..tostring(self.db.mode).." | class layout: centered 128px tiles")
  self:Refresh(true)
  self:Print("Combat visibility: " .. (self.db.hideInCombat and "hide" or "cached timers") ..
    "; in combat: " .. tostring(self.inCombat) .. "; tracker enabled: " .. tostring(self.db.visible) ..
    "; frame shown: " .. tostring(self.window and self.window:IsShown()))
  for _, key in ipairs({ "food", "bag", "camp", "tent" }) do
    local aura = self.state[key] or {}
    self:Print(key .. ": " .. (aura.active and (self:SafeString(aura.name) or "active") or "not detected") ..
      " / spell " .. tostring(aura.spellId or "?") .. " / " .. self:FormatTime(self:Remain(aura)))
  end
  self:Print("Bag in bags: " .. tostring(self.state.bagOwned) .. "; cooldown: " .. self:FormatTime(self.state.bagCooldown) ..
    "; aura readable: " .. tostring(not self.auraReadFailed))
end

function FG:Slash(message)
  local rawCmd, rawValue = string.match(message or "", "^%s*(%S*)%s*(.-)%s*$")
  local cmd, value = rawCmd:lower(), rawValue:lower()
  if self.inCombat and cmd ~= "debug" and cmd ~= "protected" and cmd ~= "taint" then
    self:Print("Tracker controls are locked until combat ends.")
    return
  end
  if cmd == "" or cmd == "toggle" then
    self:ToggleWindow()
  elseif cmd == "buffadd" then
    self:Print(self:AddClassBuff(rawValue) and "Custom buff added." or "Unable to add buff (duplicate, invalid, or limit of 8).")
  elseif cmd == "buffremove" then
    self:Print(self:RemoveClassBuff(rawValue) and "Custom buff removed." or "Custom buff not found.")
  elseif cmd == "settings" or cmd == "options" then
    self:ToggleSettings()
  elseif cmd == "show" then
    self.db.visible = true
    self:ApplyCombatVisibility()
  elseif cmd == "hide" then
    self.db.visible = false
    self:ApplyCombatVisibility()
  elseif cmd == "combat" then
    if value == "on" then self.db.hideInCombat = true
    elseif value == "off" then self.db.hideInCombat = false
    else self.db.hideInCombat = not self.db.hideInCombat end
    self:ApplyCombatVisibility()
    if self.UpdateSettings then self:UpdateSettings() end
    self:Print("Hide in combat " .. (self.db.hideInCombat and "enabled." or "disabled."))
  elseif cmd == "mode" then
    if not self:SetMode(value) then
      self:Print("Choose /fg mode full, /fg mode compact, or /fg mode icons.")
    end
  elseif cmd == "full" or cmd == "compact" or cmd == "bar" or cmd == "icons" or cmd == "icon" then
    self:SetMode(cmd)
  elseif cmd == "cycle" then
    self:CycleMode()
  elseif cmd == "demo" or cmd == "preview" then
    self:ToggleDemo(value ~= "" and value or nil)
  elseif cmd == "lock" then
    self.db.locked = not self.db.locked
    self:ApplyLayout()
    self:Refresh(false)
    self:Print(self.db.locked and "Window locked." or "Window unlocked.")
  elseif cmd == "reset" then
    self:ResetPosition()
  elseif cmd == "scale" then
    self:SetScale(tonumber(value) or 1)
  elseif cmd == "debug" then
    self:Debug()
  elseif cmd == "protected" or cmd == "taint" then
    self:PrintProtectionInfo()
  else
    self:Print("/fg mode full|compact|icons | cycle | settings | demo healthy|warning|off | combat on|off | lock | reset | scale 1.1 | debug | protected")
  end
end

function FG:Init()
  FoodGuardianDB = type(FoodGuardianDB) == "table" and FoodGuardianDB or {}
  FoodGuardianCharDB = type(FoodGuardianCharDB) == "table" and FoodGuardianCharDB or {}
  local previousCompact = FoodGuardianDB.compact
  local hadMode = FoodGuardianDB.mode ~= nil
  for key, val in pairs(self.defaults) do
    if FoodGuardianDB[key] == nil then FoodGuardianDB[key] = val end
  end
  self.db = FoodGuardianDB
  -- Older builds recommended concealment to avoid protected-action errors.
  -- Reset the inherited flag once now that combat uses cached timers.
  -- Explicit choices made after this migration remain persistent.
  if self.db.combatVisibilityVersion ~= 1 then
    self.db.hideInCombat = false
    self.db.combatVisibilityVersion = 1
  end
  self.inCombat = type(InCombatLockdown) == "function" and InCombatLockdown() or false
  if not hadMode and previousCompact then self.db.mode = "compact" end
  if self.db.mode ~= "full" and self.db.mode ~= "compact" and self.db.mode ~= "icons" then
    self.db.mode = self.db.compact and "compact" or "full"
  end
  self.db.compact = nil
  self.charDB = FoodGuardianCharDB
  self:InitClassBuffs()
  self.db.foodWarning = math.max(30, math.min(1800, self:SafeNumber(self.db.foodWarning) or 180))
  self.db.bagWarning = math.max(30, math.min(1800, self:SafeNumber(self.db.bagWarning) or 600))
  self.db.campWarning = math.max(30, math.min(1800, self:SafeNumber(self.db.campWarning) or 600))
  self.db.scale = math.max(0.70, math.min(1.45, self:SafeNumber(self.db.scale) or 1))
  self:CreateUI()
  self:CreateSettings()
  if not self.inCombat then self:CreateMinimap() end
  self:Refresh(true)
  self.ready = true
  -- Blizzard owns SlashCmdList. Do not ever replace its global registry.
  SLASH_FOODGUARDIAN1 = "/fg"
  SLASH_FOODGUARDIAN2 = "/foodguardian"
  if type(SlashCmdList) == "table" then
    SlashCmdList.FOODGUARDIAN = function(text) FG:Slash(text) end
  end
  self:Print("v1.1b6 ready. /fg mode full|compact|icons; /fg settings for options.")
  self:ApplyCombatVisibility()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
-- Some Forever client builds omit diagnostic events. Never make startup fail.
pcall(events.RegisterEvent, events, "ADDON_ACTION_BLOCKED")
pcall(events.RegisterEvent, events, "ADDON_ACTION_FORBIDDEN")
events:SetScript("OnEvent", function(_, event, arg1, arg2)
  if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
    FG:RecordProtectedAction(event, arg1, arg2)
  elseif event == "ADDON_LOADED" then
    if arg1 == addonName then FG:Init() end
  elseif event == "PLAYER_REGEN_DISABLED" then
    FG.inCombat = true
    if FG.ready then
      FG:ApplyCombatVisibility()
      FG:Refresh(false)
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    FG.inCombat = false
    if FG.ready then
      if not FG.minimap then FG:CreateMinimap() end
      FG:ApplyCombatVisibility()
      FG.scanElapsed = 0
      FG:Refresh(true)
    end
  elseif FG.ready and FG.inCombat then
    -- Aura/inventory events can contain restricted values; wait for regen.
    return
  elseif FG.ready and event == "UNIT_AURA" then
    if arg1 == "player" then FG:Refresh(true) end
  elseif FG.ready then
    FG:Refresh(true)
  end
end)
events:SetScript("OnUpdate", function(_, elapsed)
  if not FG.ready or FG:ShouldHideInCombat() then return end
  if FG.protectionPending then
    FG.protectionPending = false
    local issue = FG.protectionEvents[1]
    if issue then
      FG:Print("Blizzard blocked " .. tostring(issue.action) .. " (blamed: " ..
        tostring(issue.blamed) .. "). Run /fg protected for details.")
    end
  end
  FG.elapsed = FG.elapsed + elapsed
  if not FG.inCombat then FG.scanElapsed = FG.scanElapsed + elapsed end
  if FG.elapsed >= 0.15 then
    FG.elapsed = 0
    FG:Refresh(FG.scanElapsed >= 2)
    if FG.scanElapsed >= 2 then FG.scanElapsed = 0 end
  end
end)
