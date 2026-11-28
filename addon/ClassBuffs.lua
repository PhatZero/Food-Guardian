local _, FG = ...
-- Names match all ranks; aliases represent interchangeable buffs. No guessed spell IDs.
local catalog = {
  HUNTER = {
    {"aspect", "Hunter Aspect", "Aspect of the Hawk", "Aspect of the Monkey", "Aspect of the Cheetah", "Aspect of the Pack", "Aspect of the Wild", "Aspect of the Beast", "Aspect of the Viper"},
    {"trueshot", "Trueshot Aura", "Trueshot Aura"},
  },
  MAGE = {
    {"intellect", "Arcane Intellect", "Arcane Intellect", "Arcane Brilliance"},
    {"armor", "Mage Armor / Frost Armor", "Frost Armor", "Ice Armor", "Mage Armor", "Molten Armor"},
    {"barrier", "Ice Barrier", "Ice Barrier"},
  },
  WARRIOR = {
    {"battle", "Battle Shout", "Battle Shout"},
    {"command", "Commanding Shout", "Commanding Shout"},
  },
  PALADIN = {
    {"blessing", "Paladin Blessing", "Blessing of Might", "Greater Blessing of Might", "Blessing of Wisdom", "Greater Blessing of Wisdom", "Blessing of Kings", "Greater Blessing of Kings", "Blessing of Sanctuary", "Greater Blessing of Sanctuary", "Blessing of Light", "Greater Blessing of Light", "Blessing of Salvation", "Greater Blessing of Salvation"},
    {"aura", "Paladin Aura", "Devotion Aura", "Retribution Aura", "Concentration Aura", "Shadow Resistance Aura", "Frost Resistance Aura", "Fire Resistance Aura", "Sanctity Aura", "Crusader Aura"},
    {"seal", "Paladin Seal", "Seal of Righteousness", "Seal of Command", "Seal of the Crusader", "Seal of Light", "Seal of Wisdom", "Seal of Justice", "Seal of Vengeance", "Seal of Blood"},
    {"fury", "Righteous Fury", "Righteous Fury"},
  },
  PRIEST = {
    {"fortitude", "Power Word: Fortitude", "Power Word: Fortitude", "Prayer of Fortitude"},
    {"spirit", "Divine Spirit", "Divine Spirit", "Prayer of Spirit"},
    {"shadow", "Shadow Protection", "Shadow Protection", "Prayer of Shadow Protection"},
    {"fire", "Inner Fire", "Inner Fire"},
    {"form", "Shadowform", "Shadowform"},
    {"shield", "Power Word: Shield", "Power Word: Shield"},
  },
  DRUID = {
    {"mark", "Mark of the Wild", "Mark of the Wild", "Gift of the Wild"},
    {"thorns", "Thorns", "Thorns"},
    {"omen", "Omen of Clarity", "Clearcasting"},
  },
  SHAMAN = {
    {"shield", "Shaman Shield", "Lightning Shield", "Water Shield", "Earth Shield"},
    {"windfury", "Windfury Totem", "Windfury Totem"},
    {"strength", "Strength of Earth", "Strength of Earth", "Strength of Earth Totem"},
    {"grace", "Grace of Air", "Grace of Air", "Grace of Air Totem"},
    {"mana", "Mana Spring", "Mana Spring", "Mana Spring Totem"},
  },
  ROGUE = {
    {"slice", "Slice and Dice", "Slice and Dice"},
    {"blade", "Blade Flurry", "Blade Flurry"},
    {"stealth", "Stealth", "Stealth"},
  },
  WARLOCK = {
    {"armor", "Demon Armor / Skin", "Demon Armor", "Demon Skin", "Fel Armor"},
    {"link", "Soul Link", "Soul Link"},
    {"pact", "Blood Pact", "Blood Pact"},
    {"breath", "Unending Breath", "Unending Breath"},
    {"detect", "Detect Invisibility", "Detect Invisibility", "Detect Greater Invisibility", "Detect Lesser Invisibility"},
  },
}
local external = {
  {"ext_int", "Arcane Intellect", "Arcane Intellect", "Arcane Brilliance"},
  {"ext_fort", "Fortitude", "Power Word: Fortitude", "Prayer of Fortitude"},
  {"ext_mark", "Mark of the Wild", "Mark of the Wild", "Gift of the Wild"},
  {"ext_shout", "Battle Shout", "Battle Shout"},
  {"ext_spirit", "Divine Spirit", "Divine Spirit", "Prayer of Spirit"},
  {"ext_thorns", "Thorns", "Thorns"},
  {"ext_kings", "Blessing of Kings", "Blessing of Kings", "Greater Blessing of Kings"},
  {"ext_might", "Blessing of Might", "Blessing of Might", "Greater Blessing of Might"},
  {"ext_wisdom", "Blessing of Wisdom", "Blessing of Wisdom", "Greater Blessing of Wisdom"},
}
local fallbackIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
local function norm(s)
  if type(s) ~= "string" then return "" end
  return s:lower():gsub("^%s+", ""):gsub("%s+$", "")
end

function FG:InitClassBuffs()
  local db = self.charDB
  if type(db.classBuffs) ~= "table" then db.classBuffs = {} end
  local c = db.classBuffs
  if type(c.selected) ~= "table" then c.selected = {} end
  if type(c.custom) ~= "table" then c.custom = {} end
  if c.enabled == nil then c.enabled = false end
  if c.missing == nil then c.missing = true end
  c.warning = math.max(15, math.min(1800, self:SafeNumber(c.warning) or 60))
  self.classDB = c
  self.classState = {}
  self.classRows = {}
  self.classToken = ""
  if not self.inCombat and type(UnitClass) == "function" then
    local ok, _, token = pcall(UnitClass, "player")
    if ok then self.classToken = self:SafeString(token) or "" end
  end
end

function FG:ClassDefinitions()
  local out = {}
  local function add(row, category)
    local d = {key="class_"..row[1], label=row[2], names={}, category=category}
    for i=3,#row do d.names[norm(row[i])] = true end
    d.spellName = row[3]
    out[#out+1] = d
  end
  for _, row in ipairs(catalog[self.classToken] or {}) do add(row, "class") end
  for _, row in ipairs(external) do
    local duplicate = false
    for _, d in ipairs(out) do
      if d.names[norm(row[3])] then duplicate = true; break end
    end
    if not duplicate then add(row, "external") end
  end
  out[#out+1] = {key="class_weapon_main", label="Main-hand enhancement", slot=16, category="weapon"}
  out[#out+1] = {key="class_weapon_off", label="Off-hand enhancement", slot=17, category="weapon"}
  for i, value in ipairs(self.classDB.custom) do
    if i > 8 then break end
    local id = tonumber(value)
    local d = {key="class_custom_"..value, label=value, category="custom", names={}}
    if id then d.id = id else d.names[norm(value)] = true; d.spellName=value end
    out[#out+1] = d
  end
  return out
end

function FG:ClassSelected()
  local selected = {}
  if not self.classDB or not self.classDB.enabled then return selected end
  for _, d in ipairs(self:ClassDefinitions()) do
    if self.classDB.selected[d.key] then selected[#selected+1] = d end
  end
  return selected
end

function FG:AddClassBuff(value)
  if self.inCombat then return false end
  value = (value or ""):match("^%s*(.-)%s*$")
  if value == "" or #value > 80 or #self.classDB.custom >= 8 then return false end
  local id = tonumber(value)
  if id then
    if id < 1 or id ~= math.floor(id) then return false end
    value = tostring(id)
  end
  for _, existing in ipairs(self.classDB.custom) do
    if norm(existing) == norm(value) then return false end
  end
  table.insert(self.classDB.custom,value)
  self.classDB.selected["class_custom_"..value] = true
  self:ClassChanged()
  return true
end

function FG:RemoveClassBuff(value)
  if self.inCombat then return false end
  for i, existing in ipairs(self.classDB.custom) do
    if norm(existing)==norm(value) then
      self.classDB.selected["class_custom_"..existing] = nil
      self.classState["class_custom_"..existing] = nil
      table.remove(self.classDB.custom,i)
      self:ClassChanged()
      return true
    end
  end
  return false
end

function FG:ClassChanged()
  if self.inCombat then return end
  self:Refresh(true)
  if self.UpdateClassSettings then self:UpdateClassSettings() end
end

-- Only use the spellbook when its legacy API is available and readable.
-- Missing self-buffs are suppressed if none of the alternative spells are learned.
local function knownNames(fg)
  if type(GetNumSpellTabs) ~= "function" or type(GetSpellTabInfo) ~= "function" or
      type(GetSpellBookItemName) ~= "function" then return nil end
  local ok, result = pcall(function()
    local names, count = {}, 0
    for tab=1,GetNumSpellTabs() do
      local _, _, offset, n = GetSpellTabInfo(tab)
      for i=offset+1,offset+n do
        local name = fg:SafeString(GetSpellBookItemName(i, BOOKTYPE_SPELL or "spell"))
        if name then names[norm(name)]=true; count=count+1 end
      end
    end
    return count > 0 and names or nil
  end)
  return ok and result or nil
end

local function spellIcon(fg, d)
  local arg = d.id or d.spellName
  if arg and type(C_Spell)=="table" and type(C_Spell.GetSpellInfo)=="function" then
    local ok, info = pcall(C_Spell.GetSpellInfo,arg)
    if ok and type(info)=="table" then
      return fg:SafeNumber(info.iconID) or (type(info.iconID)=="string" and fg:SafeString(info.iconID)) or fallbackIcon
    end
  end
  if arg and type(GetSpellInfo)=="function" then
    local ok, _, _, icon = pcall(GetSpellInfo,arg)
    if ok then return fg:SafeNumber(icon) or (type(icon)=="string" and fg:SafeString(icon)) or fallbackIcon end
  end
  return fallbackIcon
end

function FG:ScanClassBuffs(auras, failed)
  if self.inCombat or not self.classDB then return end
  if self.classToken=="" and type(UnitClass)=="function" then
    local ok, _, token = pcall(UnitClass,"player")
    if ok then self.classToken=self:SafeString(token) or "" end
  end
  local nextState = {}
  local selected = self:ClassSelected()
  if #selected==0 then self.classState=nextState; return end
  local known = knownNames(self)
  local weaponOK, main, mainMS, _, _, off, offMS
  if type(GetWeaponEnchantInfo)=="function" then
    weaponOK, main, mainMS, _, _, off, offMS = pcall(GetWeaponEnchantInfo)
  end
  for _, d in ipairs(selected) do
    local entry = {active=false, name=d.label, icon=spellIcon(self,d), unknown=failed}
    if d.slot then
      entry.unknown = not weaponOK
      local equipped
      if type(GetInventoryItemID)=="function" then
        local ok, id=pcall(GetInventoryItemID,"player",d.slot)
        if ok then equipped=id~=nil end
      end
      local has, ms
      if d.slot==16 then has,ms=main,mainMS else has,ms=off,offMS end
      if weaponOK and has then
        local seconds = (self:SafeNumber(ms) or 0)/1000
        entry.active=true; entry.unknown=false
        if seconds>0 then entry.expirationTime=self:Now()+seconds end
        local old=self.classState[d.key]
        entry.duration=math.max(seconds,old and old.duration or 0)
      elseif equipped==false then entry.unlearned=true end
      if type(GetInventoryItemTexture)=="function" then
        local ok, icon=pcall(GetInventoryItemTexture,"player",d.slot)
        if ok then entry.icon=self:SafeNumber(icon) or (type(icon)=="string" and self:SafeString(icon)) or entry.icon end
      end
    else
      local best
      for _, aura in ipairs(auras) do
        if (d.id and aura.spellId==d.id) or d.names[norm(aura.name)] then
          if not best or (aura.expirationTime or 0)>(best.expirationTime or 0) then best=aura end
        end
      end
      if best then
        entry.active=true; entry.unknown=false; entry.name=best.name
        entry.expirationTime=best.expirationTime; entry.duration=best.duration
        entry.icon=self:SafeNumber(best.icon) or (type(best.icon)=="string" and self:SafeString(best.icon)) or entry.icon
      elseif known and d.category=="class" and d.key~="class_pact" and d.key~="class_omen" then
        local learned=false
        for n in pairs(d.names) do if known[n] then learned=true; break end end
        entry.unlearned=not learned
      end
    end
    nextState[d.key]=entry
  end
  self.classState=nextState
end

function FG:ClassStatus(key)
  local a=self.classState[key]
  if not a or a.unknown then return "unknown" end
  if a.unlearned then return "unlearned" end
  if not a.active then return "missing" end
  local rem=self:Remain(a)
  if rem and rem<=0 then return "missing" end
  if rem and rem<=self.classDB.warning then return "warning" end
  return "active"
end

function FG:ClassVisible()
  local out={}
  for _, d in ipairs(self:ClassSelected()) do
    local status=self:ClassStatus(d.key)
    if status~="unlearned" and (self.classDB.missing or status~="missing") then
      out[#out+1]=d
    end
  end
  return out
end
