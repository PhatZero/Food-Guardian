-- Lightweight mock for all three layout modes, buff state, controls and production release behavior.
local root = arg[1] or "/mnt/data/FoodGuardian-PreAlpha-v0.0.2-LOCAL/FoodGuardian"
local methods={}
local mockMT={__index=function(t,k)
  if methods[k] then return methods[k] end
  return function() return nil end
end}
function methods:SetScript(k,f) self.scripts=rawget(self,"scripts") or {};self.scripts[k]=f end
function methods:CreateTexture() return setmetatable({},mockMT) end
function methods:CreateFontString() return setmetatable({},mockMT) end
function methods:SetText(v) self.__text=v end
function methods:GetText() return self.__text end
function methods:SetFont(face,size,flags) self.fontSize=size end
function methods:GetStringWidth()
  local label=rawget(self,"__text")
  assert(type(label)=="string","font measurement requires a string")
  return #label*(rawget(self,"fontSize") or 10)*.61
end
function methods:SetWordWrap(wrap) self.wrap=wrap end
function methods:GetFrameLevel() return 1 end
function methods:GetCenter() return 400,400 end
function methods:GetParent() return self.parent end
function methods:SetParent(p) self.parent=p end
function methods:GetEffectiveScale() return 1 end
function methods:GetPoint() return "CENTER",UIParent,"CENTER",0,85 end
function methods:SetPoint(...) self.__point={...} end
function methods:SetShown(v) self.shown=v end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown ~= false end
function methods:SetScale(v) self.__scale=v end
function methods:GetScale() return self.__scale or 1 end
function methods:SetSize(w,h) self.width,self.height=w,h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetStatusBarColor(r,g,b,a) self.colors={r,g,b,a} end
function methods:SetValue(v) self.value=v end
function methods:SetVertexColor(r,g,b,a) self.colors={r,g,b,a} end
function methods:RegisterEvent(e) self.events=rawget(self,"events") or {}; self.events[e]=true end
function methods:StartMoving() self.moving=true end
function methods:StopMovingOrSizing() self.moving=false end

local created={}
CreateFrame=function(kind,name,parent,template)
  local f=setmetatable({name=name,kind=kind,parent=parent},mockMT)
  created[#created+1]=f
  if name then _G[name]=f end
  return f
end
UIParent=setmetatable({},mockMT)
Minimap=setmetatable({},mockMT)
Minimap:SetSize(220,220)
GetMinimapShape=function() return "ROUND" end
GameTooltip=setmetatable({},mockMT)
DEFAULT_CHAT_FRAME={AddMessage=function() end}
STANDARD_TEXT_FONT="Fonts\\FRIZQT__.TTF"
UISpecialFrames={}
SlashCmdList={}
NUM_BAG_SLOTS=4
local now=1000
GetTime=function() return now end
GetCursorPosition=function() return 500,500 end
GetBuildInfo=function() return "1.60.1","70000","Nov 2026",16001 end
SOUNDKIT={RAID_WARNING=1}
PlaySound=function() end
local aura={
  HELPFUL={
    {name="Well Fed",spellId=1225780,icon=1,duration=900,expirationTime=1600,applications=1},
    {name="Well-Rested",spellId=429959,icon=2,duration=7200,expirationTime=7800,applications=3},
    {name="Camp Benefits",spellId=1229741,icon=3,duration=3600,expirationTime=4000,applications=1},
  },
  HARMFUL={{name="Boosted Rest",spellId=1229451,icon=4,duration=3600,expirationTime=3000,applications=1}},
}
C_UnitAuras={GetAuraDataByIndex=function(unit,i,filter)
 assert(unit=="player");return aura[filter][i]
end}
C_Item={GetItemCount=function(id) return id==211527 and 1 or 0 end,
 GetItemCooldown=function() return 800,1200,true end}
C_Container={GetContainerNumSlots=function(bag) return bag==0 and 1 or 0 end,
 GetContainerItemID=function() return 211527 end,
 GetContainerItemCooldown=function() return 800,1200,1 end}

UnitClass=function() return "Mage","MAGE" end
-- Simulate a saved preference from the pre-cached-timer releases.
FoodGuardianDB={hideInCombat=true}
local fg={}
for _, path in ipairs({"Core.lua","ClassBuffs.lua","Auras.lua","Inventory.lua","UI.lua","Settings.lua","Minimap.lua"}) do
  local f,err=loadfile(root.."/"..path);assert(f,err);f("FoodGuardian",fg)
end
local bootstrap=created[1]
bootstrap.scripts.OnEvent(bootstrap,"ADDON_LOADED","FoodGuardian")
assert(fg.ready,"addon did not initialize")
assert(fg.db.hideInCombat==false and fg.db.combatVisibilityVersion==1,"legacy hide flag not migrated")
bootstrap.scripts.OnEvent(bootstrap,"PLAYER_REGEN_DISABLED")
assert(fg.window:IsShown(),"migrated tracker still hides in combat")
bootstrap.scripts.OnEvent(bootstrap,"PLAYER_REGEN_ENABLED")
assert(fg.version=="1.1b8","incorrect version")
assert(fg.window and fg.settings and fg.minimap,"UI components not initialized")
assert(fg.state.food.active and fg.state.bag.active and fg.state.camp.active and fg.state.tent.active,"auras not found")
assert(fg.state.bag.stacks==3,"sleeping bag stacks not read")
assert(fg.state.bagOwned and fg.state.bagCooldown==1000,"bag item cooldown not read")
assert(fg.window.rows.food.time.__text=="10:00","food countdown wrong")
assert(not fg.auraReadFailed,"aura unexpectedly unreadable")

-- Protected-action diagnostics must never suppress the Blizzard event.
assert(bootstrap.events.ADDON_ACTION_BLOCKED and bootstrap.events.ADDON_ACTION_FORBIDDEN,
  "protection diagnostic events not registered")
bootstrap.scripts.OnEvent(bootstrap,"ADDON_ACTION_BLOCKED","FoodGuardian","SomeProtectedFunction()")
assert(fg.protectionPending and fg.protectionEvents[1].action=="SomeProtectedFunction()",
  "protected function not captured")
assert(fg.charDB.lastProtection.blamed=="FoodGuardian","protected action not saved")
bootstrap.scripts.OnUpdate(bootstrap,.2)
assert(not fg.protectionPending,"protected action notice never flushed")
fg:Slash("protected")
bootstrap.scripts.OnEvent(bootstrap,"ADDON_ACTION_FORBIDDEN","SomeOtherAddon","OtherFunction()")
assert(fg.protectionEvents[1].blamed=="SomeOtherAddon",
  "blamed addon should not be overwritten with Food Guardian")
for i=1,12 do
  bootstrap.scripts.OnEvent(bootstrap,"ADDON_ACTION_BLOCKED","FoodGuardian","Synthetic()"..i)
end
assert(#fg.protectionEvents==8,"diagnostic history must be bounded")
fg.protectionPending=false

-- Minimap shield follows the true minimap rim, even when resized.
local function shieldDistance()
  local p=fg.minimap.__point
  return math.sqrt(p[4]*p[4]+p[5]*p[5])
end
assert(math.abs(shieldDistance()-118)<.01,"minimap shield not positioned on 220px rim")
Minimap:SetSize(300,300)
fg:UpdateMinimap()
assert(math.abs(shieldDistance()-158)<.01,"minimap resize did not reposition shield")
GetMinimapShape=function() return "SQUARE" end
fg:UpdateMinimap()
local squareX,squareY=fg.minimap.__point[4],fg.minimap.__point[5]
assert(math.abs(math.max(math.abs(squareX),math.abs(squareY))-157)<.01,
  "square minimap shield not docked to edge")
GetMinimapShape=function() return "ROUND" end
Minimap:SetSize(220,220)
fg:UpdateMinimap()

-- EllesmereUI owns the placement and shown state of collected minimap buttons.
-- Food Guardian must not undo a grouped button's flyout anchor or force-show it
-- during ordinary status refreshes. It still controls its own on/off preference.
local euiFlyout=CreateFrame("Frame","MockEllesmereFlyout",UIParent)
_G._EMM_DB={profile={minimap={enabled=true}}}
fg.minimap:SetParent(euiFlyout)
fg.minimap:SetPoint("TOPLEFT",euiFlyout,"TOPLEFT",12,-8)
local externalPoint=fg.minimap.__point
fg.minimap:SetShown(false) -- the external manager grouped/hidden the button
Minimap:SetSize(320,320)
fg:UpdateMinimap()
fg:UpdateMinimap()
assert(fg.minimap.__point==externalPoint and fg.minimap:GetParent()==euiFlyout,
  "Food Guardian overwrote EllesmereUI's button layout")
assert(fg.minimap.shown==false,"status refresh force-showed EllesmereUI's grouped button")
fg.db.minimap=false
fg:UpdateMinimap()
assert(fg.minimap.shown==false,"minimap preference did not hide EllesmereUI button")
fg.db.minimap=true
fg:UpdateMinimap()
assert(fg.minimap.shown==true,"minimap preference did not restore EllesmereUI button")
fg.db.hideInCombat=true
fg.inCombat=true
fg:ApplyCombatVisibility()
assert(fg.minimap.shown==false,"combat hiding did not apply to EllesmereUI button")
fg.inCombat=false
fg:ApplyCombatVisibility()
assert(fg.minimap.shown==true,"EllesmereUI button not restored after combat")
-- When the external minimap is disabled, return to Food Guardian's native rim.
fg.minimap:SetScript("OnDragStart",nil) -- Ellesmere disables native dragging
_G._EMM_DB.profile.minimap.enabled=false
fg:UpdateMinimap()
assert(fg.minimap:GetParent()==Minimap,"native minimap parent was not restored")
assert(math.abs(shieldDistance()-168)<.01,"native minimap edge position was not restored")
assert(fg.minimap.scripts.OnDragStart,"native minimap drag handler was not restored")
assert(fg.minimap.shown==true,"icon remained hidden after external manager disabled")
Minimap:SetSize(220,220)
_G._EMM_DB=nil
fg:UpdateMinimap()

-- All addon UI hides in combat without changing the saved user preference.
assert(fg.defaults.hideInCombat==false,"visible combat timers should default on")
fg.db.hideInCombat=true
fg.settings:Show()
bootstrap.scripts.OnEvent(bootstrap,"PLAYER_REGEN_DISABLED")
assert(fg.inCombat and fg.window.shown==false and fg.minimap.shown==false and fg.settings.shown==false,
  "tracker, minimap and settings must hide in combat")
fg:Slash("show")
assert(fg.window.shown==false and fg.db.visible==true,"slash show must not override combat hiding")
bootstrap.scripts.OnEvent(bootstrap,"PLAYER_REGEN_ENABLED")
assert(not fg.inCombat and fg.window.shown and fg.minimap.shown and fg.settings.shown,
  "user's active windows must return after combat")
fg.settings:Hide()
fg.db.visible=false
fg:ApplyCombatVisibility()
bootstrap.scripts.OnEvent(bootstrap,"PLAYER_REGEN_DISABLED")
bootstrap.scripts.OnEvent(bootstrap,"PLAYER_REGEN_ENABLED")
assert(fg.window.shown==false and fg.db.visible==false,"previously hidden window reopened")
fg.db.visible=true
fg:ApplyCombatVisibility()
fg:Slash("combat off")
bootstrap.scripts.OnEvent(bootstrap,"PLAYER_REGEN_DISABLED")
assert(fg.window.shown and fg.minimap.shown,"combat hide opt-out ignored")
-- No restricted scans or minimap updates while visible, even on aura events.
local scanAuras,scanInventory,updateMinimap=fg.ScanAuras,fg.ScanInventory,fg.UpdateMinimap
fg.ScanAuras=function() assert(not fg.inCombat,"aura scan in combat"); scanAuras(fg) end
fg.ScanInventory=function() assert(not fg.inCombat,"inventory scan in combat"); scanInventory(fg) end
fg.UpdateMinimap=function() assert(not fg.inCombat,"minimap update in combat"); updateMinimap(fg) end
local savedPoint=fg.minimap.__point
now=1100
bootstrap.scripts.OnEvent(bootstrap,"UNIT_AURA","player")
bootstrap.scripts.OnEvent(bootstrap,"BAG_UPDATE_DELAYED")
bootstrap.scripts.OnUpdate(bootstrap,2.1)
assert(fg.window.rows.food.time.__text=="08:20","cached timer failed")
assert(fg.window.compactTiles.food.time.__text=="08:20","compact cache failed")
assert(fg.minimap.__point==savedPoint,"minimap repositioned")
assert(fg.window.rows.food.bar.value>0,"cached progress bar missing")
fg:Slash("mode icons")
assert(fg.db.mode=="full","combat mode change was allowed")
now=1530
bootstrap.scripts.OnUpdate(bootstrap,.2)
assert(fg:Status("food")=="warning","combat warning missing")
now=1601
bootstrap.scripts.OnUpdate(bootstrap,.2)
assert(fg:Status("food")=="missing","cached expiration not recognized")
assert(fg.window.rows.food.time.__text=="MISSING","expired display stale")
aura.HELPFUL[1].expirationTime=2500
bootstrap.scripts.OnEvent(bootstrap,"UNIT_AURA","player")
assert(fg:Status("food")=="missing","combat aura unexpectedly rescanned")
bootstrap.scripts.OnEvent(bootstrap,"PLAYER_REGEN_ENABLED")
assert(fg:Status("food")=="active","post-combat refresh failed")
now=1000
aura.HELPFUL[1].expirationTime=1600
fg:Refresh(true)
fg:Slash("combat on")
assert(fg.window.shown and fg.minimap.shown and fg.db.hideInCombat,
  "combat state or preference not restored")
assert(fg.settings.toggles.hideInCombat,"combat visibility setting missing")

-- FULL WINDOW as pictured: header, names, bar, 3 buff rows + optional camp tent.
assert(fg.db.mode=="full","full should be default")
assert(fg.window.width==414 and fg.window.height==390,"full dimensions wrong")
assert(fg.window.header.shown and fg.window.rows.food.shown,"full elements hidden")
assert(fg.window.tent.shown,"tent strip missing")
assert(fg.window.rows.food.title.__text=="Well Fed","full food label wrong")
assert(fg.window.rows.bag.title.__text=="Well-Rested","full bag label wrong")
assert(fg.window.rows.camp.title.__text=="Camp Benefits","full camp label wrong")
assert(fg.window.rows.bag.detail.__text=="Sleeping Bag (3/3 Stacks)","stack caption wrong")
assert(fg.window.rows.food.bar.value>0,"full progress bar not filled")

-- COMPACT BAR: one narrow horizontal row, icon plus time per category, no header or summary.
fg:Slash("mode compact")
assert(fg.db.mode=="compact", "mode was not saved")
assert(fg.window.width==402 and fg.window.height==60,"compact dimensions wrong")
assert(fg.window.compactRow.shown==true,"compact bar not visible")
assert(fg.window.header.shown==false and fg.window.rows.food.shown==false,"full chrome visible in compact")
assert(fg.window.compactTiles.food.time.__text=="10:00","compact timer wrong")
assert(fg.window.compactTiles.bag.time.__text=="1h 53m","compact bag time wrong")

-- ICON MODE: only three icons, with state outlines and hover details, no text.
fg:Slash("mode icons")
assert(fg.db.mode=="icons","icons mode was not saved")
assert(fg.window.width==174 and fg.window.height==60,"icon dimensions wrong")
assert(fg.window.iconsRow.shown==true and not fg.window.compactRow.shown,"icon panel wrong")
for _,key in ipairs({"food","bag","camp"}) do
  assert(fg.window.iconTiles[key] and fg.window.iconTiles[key].icon,"missing icon mode tile: "..key)
  assert(rawget(fg.window.iconTiles[key], "time") == nil,"icon mode should have no timers on the panel")
end
assert(fg.window.header.shown==false and fg.window.footer.shown==false,"chrome in icon mode")
-- Simulate a UI right-click to cycle back to Full Window.
fg.window.iconTiles.food.scripts.OnClick(fg.window.iconTiles.food,"RightButton")
assert(fg.db.mode=="full", "right-click cycling from icon view failed")
-- Simulate dragging the compact bar.
fg:SetMode("compact")
fg.window.compactTiles.food.scripts.OnDragStart(fg.window.compactTiles.food)
assert(fg.window.moving,"compact bar drag failed")
fg.window.compactTiles.food.scripts.OnDragStop(fg.window.compactTiles.food)
assert(not fg.window.moving,"compact bar drag stop failed")
fg:SetMode("icons")
fg.window.iconTiles.food.scripts.OnClick(fg.window.iconTiles.food,"LeftButton")
assert(fg.db.mode=="full","icon left-click did not expand to Full Window")
fg:CycleMode(); assert(fg.db.mode=="compact")
fg:CycleMode(); assert(fg.db.mode=="icons")
fg:CycleMode(); assert(fg.db.mode=="full")
assert(fg:SetMode("nonsense")==false and fg.db.mode=="full", "invalid mode accepted")

-- Settings has all three visible choices and updates the live mode.
fg:ToggleSettings()
assert(fg.settings:IsShown(),"settings unavailable")
assert(fg.settings.modeButtons.full and fg.settings.modeButtons.compact and fg.settings.modeButtons.icons,
 "not all mode settings exist")
fg.settings.modeButtons.compact.scripts.OnClick()
assert(fg.db.mode=="compact","compact choice did not work")
fg.settings.modeButtons.icons.scripts.OnClick()
assert(fg.db.mode=="icons","icon choice did not work")
fg.settings.modeButtons.full.scripts.OnClick()
assert(fg.db.mode=="full","full choice did not work")
fg.db.flash=false;fg:UpdateSettings()
assert(fg.settings.toggles.flash.text.__text=="OFF","warning toggle not applied")
fg.db.flash=true
fg:Slash("scale 1.25"); assert(fg.db.scale==1.25,"scale not saved")
fg:Slash("lock"); assert(fg.db.locked and fg.window.grip.shown==false,"lock failed")
fg:Slash("lock"); assert(not fg.db.locked and fg.window.grip.shown==true,"unlock failed")

-- Healthy/Warning previews use real per-row status behavior.
fg:Slash("demo healthy")
assert(fg.demo and fg.demoVariant=="healthy","healthy demo not enabled")
assert(fg:Status("food")=="active" and fg:Status("camp")=="active","healthy demo statuses wrong")
assert(fg.window.rows.bag.detail.__text=="Sleeping Bag (3/3 Stacks)","demo stacks wrong")
fg:Slash("demo warning")
assert(fg:Status("food")=="warning" and fg:Status("camp")=="warning","warning demo statuses wrong")
assert(fg.window.rows.food.time.__text=="01:28","warning countdown wrong")
assert(fg.window.compactTiles.food.time.__text=="01:28","compact warning mismatch")
assert(fg.window.iconTiles.food.outline.edges.BOTTOM.colors,"icon border was not tinted")
fg:Slash("demo off");assert(not fg.demo,"failed to resume live tracking")

-- Live update and missing/unknown cases propagate to all three views.
now=1530; fg:Refresh(false)
assert(fg:Status("food")=="warning","live food warning not detected")
assert(fg.window.rows.food.time.__text=="01:10","live food timer did not tick")
fg:SetMode("compact")
assert(fg.window.compactTiles.food.time.__text=="01:10","compact did not tick")
fg:SetMode("icons")
assert(fg.window.iconTiles.food,"icons missing after live update")
for _,tableForFilter in pairs(aura) do
 for k in pairs(tableForFilter) do tableForFilter[k]=nil end
end
fg:Refresh(true)
assert(fg:Status("food")=="missing" and fg.window.rows.food.time.__text=="MISSING","missing status wrong")
assert(fg.window.compactTiles.food.time.__text=="NONE","missing compact status wrong")
C_UnitAuras.GetAuraDataByIndex=function() error("aura access denied") end
fg:Refresh(true)
assert(fg:Status("camp")=="unknown" and fg.window.rows.camp.time.__text=="UNKNOWN",
 "unreadable aura must not become missing")
assert(fg.window.compactTiles.food.time.__text=="?","unknown compact status wrong")
print("Food Guardian mock runtime: PASS (three modes, buffs, combat concealment, minimap rim, settings)")


-- Optional class tracking stays off by default and preserves existing dimensions.
assert(not fg.classDB.enabled,"class buffs must default off")
C_UnitAuras.GetAuraDataByIndex=function(unit,i,filter) assert(not fg.inCombat); return aura[filter][i] end
now=2000
aura.HELPFUL={{name="Arcane Brilliance",spellId=23028,icon=2,duration=3600,expirationTime=2300},
  {name="Ice Armor",spellId=7302,icon=3,duration=1800,expirationTime=0},
  {name="Custom Test",spellId=90001,icon=4,duration=120,expirationTime=2120}}
fg.classDB.enabled=true
fg.classDB.selected.class_intellect=true
fg.classDB.selected.class_armor=true
fg:Refresh(true)
assert(fg:ClassStatus("class_intellect")=="active","intellect alias not recognized")
assert(fg:ClassStatus("class_armor")=="active","permanent armor not recognized")
assert(#fg:ClassVisible()==2,"class selections not respected")
fg:SetMode("full")
assert(fg.window.height>390 and fg.classRows[1].time.__text=="05:00","class full rows absent")
fg:SetMode("compact")
assert(fg.window.height>60,"class compact rows absent")
assert(fg.classRows[1].width==128 and fg.classRows[2].width==128,"class tiles must match core compact tile width")
assert(fg.classRows[1].__point[4]==71 and fg.classRows[2].__point[4]==203,"two compact tiles must be centered, not stretched")
assert(fg.classRows[1].height==46 and fg.classRows[1].icon.width==28,"class tile geometry differs from reference")
assert(fg.classRows[1].__point[5]==-60 and fg.window.height==114,"compact row gaps or window height wrong")
for _,side in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
  assert(fg.classRows[1].outline.edges[side] and fg.classOuterOutline.edges[side],"missing explicit border: "..side)
  assert(fg.classRows[1].outline.edges[side].colors,"untinted class border")
  for _,key in ipairs({"food","bag","camp"}) do
    assert(type(fg.window.compactTiles[key].outline.edges[side].colors)=="table","untinted core compact border: "..key.."/"..side)
    assert(type(fg.window.iconTiles[key].outline.edges[side].colors)=="table","untinted core icon border: "..key.."/"..side)
  end
end
aura.HELPFUL[1].name="Arcane Brilliance"
fg:Refresh(true)
assert(fg.classRows[1].title.__text=="Arcane Brilliance","full buff name not retained")
assert(fg.classRows[1].title.fontSize<10,"long name should fit by reducing font size")
assert(fg.classRows[1].__point[5]==fg.classRows[2].__point[5],"two tiles should share a row")
fg:SetMode("icons")
assert(fg.classRows[1].icon and not fg.classRows[1].time.shown,"class icon row incorrect")
assert(fg:AddClassBuff("90001"),"custom ID not accepted")
assert(fg:ClassStatus("class_custom_90001")=="active","custom ID not matched")
assert(not fg:AddClassBuff("90001"),"duplicate custom allowed")
assert(fg:RemoveClassBuff("90001"),"custom removal failed")
fg.db.hideInCombat=false
bootstrap.scripts.OnEvent(bootstrap,"PLAYER_REGEN_DISABLED")
now=2250
fg:Refresh(true)
assert(fg:ClassStatus("class_intellect")=="warning","cached class countdown failed")
assert(fg.window:IsShown() and fg.classRows[1]:IsShown(),"class tracker hidden in cached combat mode")
aura.HELPFUL[1].expirationTime=5000
now=2301
fg:Refresh(true)
assert(fg:ClassStatus("class_intellect")=="missing","cached expiration failed")
bootstrap.scripts.OnEvent(bootstrap,"PLAYER_REGEN_ENABLED")
assert(fg:ClassStatus("class_intellect")=="active","post-combat class resync failed")
fg.classDB.selected.class_weapon_main=true
GetWeaponEnchantInfo=function() return true,90000,0,123,false,0,0,nil end
fg:Refresh(true)
assert(fg:ClassStatus("class_weapon_main")=="active","weapon timer missing")
assert(fg:Remain(fg.classState.class_weapon_main)==90,"weapon milliseconds conversion failed")
fg.classDB.enabled=false
fg:Refresh(true)
assert(fg.window.height==60,"disabled class buffs changed original layout")
assert(fg.window.outline:IsShown(),"outer outline disappeared when class tracking disabled")
for _,key in ipairs({"food","bag","camp"}) do
  assert(type(fg.window.compactTiles[key].outline.edges.BOTTOM.colors)=="table","core bottom outline lost when class tracking disabled")
end
print("Food Guardian class buff mock: PASS")

-- A later deliberate hide preference is retained rather than reset on every login.
fg.db.hideInCombat=true
fg:Init()
assert(fg.db.hideInCombat==true,"explicit combat preference lost on reload")
print("Food Guardian combat preference migration: PASS")


-- Test centered wrapping independently of class-specific availability.
fg.db.hideInCombat=false
fg.inCombat=false
local originalVisible=fg.ClassVisible
for _,mode in ipairs({"full","compact","icons"}) do
  fg.db.mode=mode
  local width=mode=="full" and 414 or mode=="compact" and 402 or 174
  local columns=3
  local gap=mode=="icons" and 5 or 4
  local tile=mode=="icons" and 51 or 128
  for n=0,8 do
    fg.ClassVisible=function()
      local d={}
      for i=1,n do d[i]={key="layout_test_"..i} end
      return d
    end
    fg:ApplyLayout()
    for i=1,n do
      local row=fg.classRows[i]
      local line=math.floor((i-1)/columns)
      local count=math.min(columns,n-line*columns)
      local x=math.floor((width-count*tile-(count-1)*gap)/2)+((i-1)%columns)*(tile+gap)
      assert(row.width==tile and row.__point[4]==x,"inconsistent class tile spacing")
      assert(row.height==(mode=="icons" and 51 or 46),"inconsistent tile height")
      assert(row.icon.width==(mode=="icons" and 43 or 28),"inconsistent icon size")
      assert(row.__point[4]>=0 and row.__point[4]+row.width<=width,"class tile outside frame")
      assert(-row.__point[5]+row.height<=fg.window.height,"class tile below frame")
      if i>columns then assert(row.__point[5]<fg.classRows[i-columns].__point[5],"class tile did not wrap") end
    end
    if n==0 then assert(fg.window.height==(mode=="full" and 390 or 60),"original layout height changed") end
  end
end
fg.ClassVisible=originalVisible
fg:ApplyLayout()
print("Food Guardian uniform class tile layout: PASS")
