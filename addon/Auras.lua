local _, FG = ...

local function field(aura, name)
  local ok, result = pcall(function() return aura[name] end)
  if ok then return result end
  return nil
end

local function extractAura(aura)
  if not aura then return nil end
  local name = FG:SafeString(field(aura, "name"))
  local spellId = FG:SafeNumber(field(aura, "spellId"))
  local icon = field(aura, "icon")
  local duration = FG:SafeNumber(field(aura, "duration"))
  local expirationTime = FG:SafeNumber(field(aura, "expirationTime"))
  local applications = FG:SafeNumber(field(aura, "applications"))
    or FG:SafeNumber(field(aura, "count")) or 0
  return {
    active = true, name = name or "Active aura", spellId = spellId,
    icon = icon, duration = duration, expirationTime = expirationTime,
    stacks = applications, opaque = name == nil and spellId == nil,
  }
end

local function oldAura(unit, index, filter)
  local get = filter == "HARMFUL" and UnitDebuff or UnitBuff
  if type(get) ~= "function" then return nil, false end
  local ok, name, icon, count, _, duration, expirationTime, _, _, _, spellId = pcall(get, unit, index)
  if not ok then return nil, false end
  if not name then return nil, true end
  return {
    name = name, icon = icon, applications = count, duration = duration,
    expirationTime = expirationTime, spellId = spellId,
  }, true
end

local function matchEffect(aura, filter)
  if not aura then return nil end
  local id = aura.spellId
  local name = (aura.name or ""):lower()
  if filter == "HARMFUL" then
    if id == FG.spells.tent or name == "boosted rest" then return "tent" end
    return nil
  end
  if id == FG.spells.sleepingBag or name == "well-rested" or name == "well rested" then
    return "bag"
  end
  if id == FG.spells.camp or name == "camp benefits" then
    return "camp"
  end
  -- Food spell IDs differ by cooked meal; the Well Fed aura is the visible source.
  -- Hidden "Well Fed XP Boost" is not a timer and must not masquerade as a food aura.
  if name == "well fed" or name:match("^well fed %(") then
    return "food"
  end
  return nil
end

local function preferNew(a, b)
  if not a then return true end
  local aEnd = FG:SafeNumber(a.expirationTime) or 0
  local bEnd = FG:SafeNumber(b.expirationTime) or 0
  return bEnd > aEnd
end

function FG:ScanAuras()
  local results = { food = { active = false }, bag = { active = false },
    camp = { active = false }, tent = { active = false } }
  local failed = false
  local helpful = {}
  for _, filter in ipairs({ "HELPFUL", "HARMFUL" }) do
    local modern = type(C_UnitAuras) == "table" and type(C_UnitAuras.GetAuraDataByIndex) == "function"
    local legacy = (filter == "HELPFUL" and type(UnitBuff) == "function") or
      (filter == "HARMFUL" and type(UnitDebuff) == "function")
    if not modern and not legacy then
      failed = true
    else
      for index = 1, 120 do
        local raw, ok
        if modern then
          ok, raw = pcall(C_UnitAuras.GetAuraDataByIndex, "player", index, filter)
          if not ok and legacy then raw, ok = oldAura("player", index, filter) end
        else
          raw, ok = oldAura("player", index, filter)
        end
        if not ok then
          failed = true
          break
        end
        if not raw then break end
        local entry = extractAura(raw)
        if entry.opaque then failed = true end
        if filter == "HELPFUL" then helpful[#helpful+1] = entry end
        local key = matchEffect(entry, filter)
        if key and preferNew(results[key].active and results[key] or nil, entry) then
          results[key] = entry
        end
      end
    end
  end
  for _, key in ipairs({ "food", "bag", "camp", "tent" }) do
    self.state[key] = results[key]
  end
  self.auraReadFailed = failed
  self:ScanClassBuffs(helpful, failed)
end
