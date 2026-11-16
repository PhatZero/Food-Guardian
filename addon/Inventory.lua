local _, FG = ...

local function callCount()
  local itemID = FG.items.sleepingBag
  if C_Item and type(C_Item.GetItemCount) == "function" then
    local ok, count = pcall(C_Item.GetItemCount, itemID, false, false)
    if ok then return FG:SafeNumber(count) or 0 end
  end
  if type(GetItemCount) == "function" then
    local ok, count = pcall(GetItemCount, itemID, false, false)
    if ok then return FG:SafeNumber(count) or 0 end
  end
  return 0
end

local function itemCooldown()
  local itemID = FG.items.sleepingBag
  if C_Item and type(C_Item.GetItemCooldown) == "function" then
    local ok, start, duration, enabled = pcall(C_Item.GetItemCooldown, itemID)
    if ok then return start, duration, enabled end
  end
  if type(GetItemCooldown) == "function" then
    local ok, start, duration, enabled = pcall(GetItemCooldown, itemID)
    if ok then return start, duration, enabled end
  end
  return nil, nil, nil
end

local function bagSlotItem(bag, slot)
  if C_Container and type(C_Container.GetContainerItemID) == "function" then
    local ok, id = pcall(C_Container.GetContainerItemID, bag, slot)
    if ok then return FG:SafeNumber(id) end
  end
  if C_Container and type(C_Container.GetContainerItemInfo) == "function" then
    local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
    if ok and info then return FG:SafeNumber(info.itemID) end
  end
  return nil
end

local function scanBags()
  if not (C_Container and type(C_Container.GetContainerNumSlots) == "function") then
    return false, nil, nil, nil
  end
  local found = false
  local start, duration, enabled
  local maxBag = NUM_BAG_SLOTS or 4
  for bag = 0, maxBag do
    local ok, slots = pcall(C_Container.GetContainerNumSlots, bag)
    if ok then
      slots = FG:SafeNumber(slots) or 0
      for slot = 1, slots do
        if bagSlotItem(bag, slot) == FG.items.sleepingBag then
          found = true
          if C_Container.GetContainerItemCooldown then
            local success, a, b, c = pcall(C_Container.GetContainerItemCooldown, bag, slot)
            if success then start, duration, enabled = a, b, c end
          end
          return found, start, duration, enabled
        end
      end
    end
  end
  return found, nil, nil, nil
end

function FG:ScanInventory()
  local found, start, duration, enabled = scanBags()
  if not found then found = callCount() > 0 end
  if not start or not duration then start, duration, enabled = itemCooldown() end
  local startN = self:SafeNumber(start) or 0
  local durationN = self:SafeNumber(duration) or 0
  local remaining = math.max(0, startN + durationN - self:Now())
  self.state.bagOwned = found
  self.state.bagCooldown = remaining
  self.state.bagCooldownKnown = start ~= nil and duration ~= nil
end
