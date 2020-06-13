------------------------------------------------------------
-- header
------------------------------------------------------------

local require = GLOBAL.require
local modinit = require("modinit")
modinit("chat_outside")

------------------------------------------------------------
-- main
------------------------------------------------------------

require("tprint")

local push = table.insert
local tjoin = table.concat
local trace = print

local easing = require("easing")
local Text = require "widgets/text"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local ImageWheel = require("widgets/imagewheel")

local IMAGETEXT  = 3
local SHOWIMAGE  = IMAGETEXT > 1
local SHOWTEXT   = IMAGETEXT%2 == 1
local RIGHTSTICK = false
local SCALEFACTOR = 1
local CENTERCURSOR = true
local CENTERWHEEL = true


this = this or {}
this.key_inited = this.key_inited or {}
this.togglekey = this.togglekey or "R"
this.selected_ents = this.selected_ents or {}
this.color = {x = 1, y = 1, z = 1}

local b_debug = true

local DEFAULT_EMOTES = {
  {name = "rude",   anim = {anim="emoteXL_waving4", randomanim=true}},
  {name = "annoyed",  anim = {anim="emoteXL_annoyed"}},
  {name = "sad",    anim = {anim="emoteXL_sad", fx="tears", fxoffset={0.25,3.25,0}, fxdelay=17*GLOBAL.FRAMES}},
  {name = "joy",    anim = {anim="research", fx=false}},
  {name = "facepalm", anim = {anim="emoteXL_facepalm"}},
  {name = "wave",   anim = {anim={"emoteXL_waving1", "emoteXL_waving2", "emoteXL_waving3"}, randomanim=true}},
  {name = "dance",  anim = {anim ={ "emoteXL_pre_dance0", "emoteXL_loop_dance0" }, loop = true, fx = false, beaver = true }},
  {name = "pose",   anim = {anim = "emote_strikepose", zoom = true, soundoverride = "/pose"}},
  {name = "kiss",   anim = {anim="emoteXL_kiss"}},
  {name = "bonesaw",  anim = {anim="emoteXL_bonesaw"}},
  {name = "happy",  anim = {anim="emoteXL_happycheer"}},
  {name = "angry",  anim = {anim="emoteXL_angry"}},
  {name = "sit",    anim = {anim={{"emote_pre_sit2", "emote_loop_sit2"}, {"emote_pre_sit4", "emote_loop_sit4"}}, randomanim = true, loop = true, fx = false}},
  {name = "squat",  anim = {anim={{"emote_pre_sit1", "emote_loop_sit1"}, {"emote_pre_sit3", "emote_loop_sit3"}}, randomanim = true, loop = true, fx = false}},
  {name = "toast",  anim = {anim={ "emote_pre_toast", "emote_loop_toast" }, loop = true, fx = false }},
  -- TODO: make sure this list stays up to date
}

local def_roles = DST_CHARACTERLIST
local mod_roles = MODCHARACTERLIST

------------------------------------------------------------
-- utils
------------------------------------------------------------

function show_msg_api(msg, onlyClear)
  if not (TheFrontEnd and TheFrontEnd.overlayroot) then
    return
  end

  local inst = this.label
  -- if (inst) then
  --   inst:Hide()
  -- end
  if (this.update_msg_task) then
    this.update_msg_task:Cancel()
    this.update_msg_task = nil
  end

  if (b_debug and inst) then
    TheFrontEnd.overlayroot:RemoveChild(inst)
    inst:Hide()
    inst:Kill()
    this.label = nil
  end

  if (onlyClear) then
    return
  end


  if not (this.label) then
    inst = Text(TALKINGFONT, 32)
    inst:Hide()
    inst:SetPosition(300, 120, 0)
    if (b_debug) then
      inst:SetPosition(300, 420, 0)
    end
    inst:SetVAlign(ANCHOR_BOTTOM)
    inst:SetHAlign(ANCHOR_LEFT)
    inst:SetHAnchor(ANCHOR_LEFT)
    inst:SetVAnchor(ANCHOR_BOTTOM)

    this.label = inst
    TheFrontEnd.overlayroot:AddChild(inst)
  end

  inst:SetString(msg)
  inst:Show()

  local ontimeover = _f(function (inst)
    inst:Hide()
    this.update_msg_task:Cancel()
    this.update_msg_task = nil
  end)

  this.update_msg_task = ThePlayer:DoTaskInTime(8,
    function()
      ontimeover(inst)
    end,
    0
  )
end

function show_msg(...)
  local arr = {}
  for i,v in ipairs({...}) do
    arr[i] = tostring(v)
  end
  local msg = tjoin(arr, "\n")
  show_msg_api(msg)
  print(msg)
end

function split_by_space(s)
  local arr = {}
  for w in s:gmatch("%S+") do
    arr[#arr+1] = w
  end
  return arr
end

------------------------------------------------------------
-- common
------------------------------------------------------------

function IsInGameplay()
  if not ThePlayer then
    return
  end
  if not (TheFrontEnd:GetActiveScreen().name == "HUD") then
    return
  end
  return true
end

function IsDST()
  return TheSim:GetGameID() == "DST"
end

--Variables to control the display of the wheel
local cursorx = 0
local cursory = 0
local centerx = 0
local centery = 0
local controls = nil

local NORMSCALE = nil
local STARTSCALE = nil

local function IsDefaultScreen()
  local screen = TheFrontEnd:GetActiveScreen()
  return ((screen and type(screen.name) == "string") and screen.name or ""):find("HUD") ~= nil
    and not(ThePlayer.HUD:IsControllerCraftingOpen() or ThePlayer.HUD:IsControllerInventoryOpen())
end

local function ResetScale(wheel)
  local screenwidth, screenheight = GLOBAL.TheSim:GetScreenSize()
  centerx = math.floor(screenwidth/2 + 0.5)
  centery = math.floor(screenheight/2 + 0.5)
  local screenscalefactor = math.min(screenwidth/1920, screenheight/1080) --normalize by my testing setup, 1080p
  wheel.screenscalefactor = SCALEFACTOR*screenscalefactor
  NORMSCALE = SCALEFACTOR*screenscalefactor
  STARTSCALE = 0
  wheel:SetPosition(centerx, centery, 0)
  wheel.inst.UITransform:SetScale(STARTSCALE, STARTSCALE, 1)
end

function _AddThePlayerInit(fn)
  if IsDST() then
    env.AddPrefabPostInit("world", function(wrld)
      wrld:ListenForEvent("playeractivated", function(wlrd, player)
        if player == ThePlayer then
          fn()
        end
      end)
    end)
  else
    env.AddPlayerPostInit(function(player)
      fn()
    end)
  end
end

function regHotkey(key, b_keyup)
  local tag = b_keyup and key.."_up" or key
  if (this.key_inited[tag]) then
    return
  end
  this.key_inited[tag] = true

  local keybind = _G["KEY_"..key]
  if (b_keyup) then
    TheInput:AddKeyUpHandler(keybind, function()
      onPressKey(key, b_keyup)
    end)
  else
    TheInput:AddKeyDownHandler(keybind, function()
      onPressKey(key, b_keyup)
    end)
  end
end

------------------------------------------------------------
-- func
------------------------------------------------------------

onThePlayerInit = _f(function ()
  regHotkey(this.togglekey, true)
  regHotkey(this.togglekey, false)
end)

onPressKey = _f(function (key, b_keyup)
  if not IsInGameplay() then return end
  if not (this.togglekey == key) then
    return
  end

  local b_keydown = not (b_keyup)
  if (b_keydown) then
    -- addRoleWheel(this.controls)
    -- ThePlayer:DoTaskInTime(0.5, function()
      ShowRoleWheel()
    -- end)
  else
    HideRoleWheel()
  end
end)

function changeMyPrefab(name)
  if (table.contains(def_roles, name)
   or table.contains(mod_roles, name) )  then
    ThePlayer.prefab = name
    show_msg(name)
  else
    local arr = {}
    push(arr, "invalid:"..tostring(name))
    for i, name in pairs(def_roles) do
      push(arr, name)
    end
    for i, name in pairs(mod_roles) do
      push(arr, name)
    end
    local str = tjoin(arr, '\n')
    show_msg(str)
  end
end

onChatTest = _f(function (params, caller)
  local args = {}
  if (params and params.rest and #params.rest > 0) then
    args = split_by_space(params.rest)
  end
print("......c,,,,tttt", 111)

  -- /ct
  if not (this.skinspuppet) then
print("......c,,,,tttt", 222)
    return
  end
print("......c,,,,tttt", 333)
  if not (this.org_skinspuppet_DoEmote) then
print("......c,,,,tttt", 444)
    this.org_skinspuppet_DoEmote = this.skinspuppet.DoEmote
  end
print("......c,,,,tttt", 555)
  this.skinspuppet.DoEmote = function (self, emote, loop, force, do_push)
    print(".......DoEmote......", emote)
print("......c,,,,tttt", 666)
    if not self.sitting and (force or self.animstate:IsCurrentAnimation("idle_loop")) then
      self.animstate:SetBank("wilson")
          if type(emote) == "table" then
        self.animstate:PlayAnimation(emote[1])
        for i=2,#emote do
          self.animstate:PushAnimation(emote[i], loop)
        end
        self.looping = loop
print("......c,,,,tttt", 777)
      else
print("......c,,,,tttt", 888)
        if do_push then
          self.animstate:PushAnimation(emote)
        else
          self.animstate:PlayAnimation(emote)
        end
        self.looping = false
      end
    end
  end
print("......c,,,,tttt", 999)
  -- local str = args[1] or ""
  -- if (str == "r" or str == "reset") then

  -- end

end)

on_change_prefab = _f(function (params, caller)
  local args = {}
  if (params and params.rest and #params.rest > 0) then
    args = split_by_space(params.rest)
  end

  local str = args[1] or ""
  if (str == "r" or str == "reset") then
    modget("chat_outside").import("cmd")
    show_msg("cg reset")
    return
  end
  if (str == "shuffle") then
    this.cg_shuffle = not (this.cg_shuffle)
    local tag = this.cg_shuffle and "on" or "off"
    show_msg("cg shuffle: ".. tag)
    addRoleWheel(this.controls)
    return
  end
  changeMyPrefab(str)

end)

AddUserCommand("cg", {
  prettyname = nil, --default to STRINGS.UI.BUILTINCOMMANDS.BUG.PRETTYNAME
  desc = nil, --default to STRINGS.UI.BUILTINCOMMANDS.BUG.DESC
  permission = COMMAND_PERMISSION.USER,
  slash = false,
  usermenu = false,
  servermenu = false,
  params = {},
  vote = false,
  localfn = function(params, caller)
    on_change_prefab(params, caller)
  end,
})


AddUserCommand("ct", {
  prettyname = nil, --default to STRINGS.UI.BUILTINCOMMANDS.BUG.PRETTYNAME
  desc = nil, --default to STRINGS.UI.BUILTINCOMMANDS.BUG.DESC
  permission = COMMAND_PERMISSION.USER,
  slash = false,
  usermenu = false,
  servermenu = false,
  params = {},
  vote = false,
  localfn = function(params, caller)
    onChatTest(params, caller)
  end,
})


function ShowRoleWheel()
  if this.wheel_visable then return end
  if not (ThePlayer and ThePlayer.HUD) then return end
  if not IsDefaultScreen() then return end
  if not this.rolewheel then return end

  this.wheel_visable = true
  -- SetModHUDFocus("ImageWheel", true)

  local inst = this.rolewheel
  ResetScale(inst)
  local gesturewheel = this.rolewheel
  if SHOWIMAGE then
    for _,gesturebadge in pairs(gesturewheel.gestures) do
      gesturebadge:RefreshSkins()
    end
  end

  if CENTERCURSOR then
    GLOBAL.TheInputProxy:SetOSCursorPos(centerx, centery)
  end

  if CENTERWHEEL then
    gesturewheel:SetPosition(centerx, centery, 0)
  else
    gesturewheel:SetPosition(GLOBAL.TheInput:GetScreenPosition():Get())
  end

  local controller_mode = false
  gesturewheel:SetControllerMode(controller_mode)
  gesturewheel:Show()
  gesturewheel:ScaleTo(STARTSCALE, NORMSCALE, .25)
end

function HideRoleWheel(delay_focus_loss)
  if not this.rolewheel then return end
  if not (ThePlayer and ThePlayer.HUD) then return end
  if not (IsInGameplay() or this.wheel_visable) then
    return
  end
  this.wheel_visable = false
  local inst = this.rolewheel

  -- SetModHUDFocus("ImageWheel", false)
  inst:Hide()
  inst.inst.UITransform:SetScale(STARTSCALE, STARTSCALE, 1)
  if not IsDefaultScreen() then return end

  if inst.activegesture then
    local item = inst.activegesture
    local name = item.name
    tprint{"....active item....", item.color, item.name}
    changeMyPrefab(name)
  end
end

function shuffle(arr)
  local len = #arr
  for i=1, len-1 do
    local x = math.random(i, len)
    arr[i], arr[x] = arr[x], arr[i]
  end
  return arr
end

function random_color(x)
  local arr = this.arr_color
  if not (arr) then
    arr = {}
    for name, color in pairs(PLAYERCOLOURS) do
      push(arr, color)
    end
    this.arr_color = arr
  end

  local len = #arr
  local x = x or math.random(1, len)
  local t_color = {
    [1] = 0.5843137254902;
    [2] = 0.74901960784314;
    [3] = 0.94901960784314;
    [4] = 1;
  }
  if (t_color) then
    return t_color
  end
  return this.arr_color[x]
end


-- wilson willow wolfgang wendy
-- wx78 wickerbottom woodie wes
-- waxwell wathgrithr webber winona
-- warly wortox wormwood wurt

function randomEmoteItem(name)
  local x = math.random(1, #DEFAULT_EMOTES)
  local anim_r = DEFAULT_EMOTES[x].anim
  local item = {
    name = name,
    prefab = name,
    anim = anim_r,
    color = random_color(x),
  }

  return item
end


function BuildEmoteSets()
  local arr = {}
  for i, name in pairs(def_roles) do
    push(arr, name)
  end
  for i, name in pairs(mod_roles) do
    push(arr, name)
  end
  if (this.cg_shuffle) then
    arr = shuffle(arr)
  end

  local emotes = {}
  for i, name in ipairs(arr) do
    push(emotes, randomEmoteItem(name))
  end

  -- local emotes = {}
  -- for i=1, 4 do
  --   push(emotes, arr[i])
  -- end

  local emote_sets = {
    {
      name = "old",
      emotes = emotes,
      radius = 375,
      -- color = GLOBAL.PLAYERCOLOURS.FUSCHIA,
    }
  }
  return emote_sets
end

function BuildEmoteSetsDemo()
  local emote_sets = {
    {
      name = "old",
      emotes =
      {
        {prefab="wolfgang", name = "111", anim = {anim="emoteXL_sad", fx="tears", fxoffset={0.25,3.25,0}, fxdelay=17*GLOBAL.FRAMES}},
        {prefab="wilson", name = "222", anim = {anim="emoteXL_waving4", randomanim=true}},
        {prefab="willow", name = "333", anim = {anim="emoteXL_annoyed"}},
        {prefab="wendy", name = "joy", anim = {anim="research", fx=false}},
      },
      -- radius = 175,
      -- color = GLOBAL.DARKGREY,
      radius = 375,
      color = GLOBAL.PLAYERCOLOURS.FUSCHIA,
    }
  }
  return emote_sets
end


function InitRoleWheel()
  local emote_sets = BuildEmoteSets()
  local inst = ImageWheel(emote_sets, SHOWIMAGE, SHOWTEXT, RIGHTSTICK)
  inst:Hide()

  ResetScale(inst)
  return inst
end


addRoleWheel = _f(function (controls)
  local inst = this.rolewheel
  local controls = this.controls or controls
  if not (controls) then
    return
  end

  if inst then
    controls:RemoveChild(inst)
    inst:Hide()
    inst:Kill()
    this.rolewheel = nil
  end

  inst = InitRoleWheel()
  this.rolewheel = inst
  controls.rolewheel = inst
  controls:AddChild(inst)

  if not (this.controlsOnUpdate_origin) then
    this.controlsOnUpdate_origin = controls.OnUpdate
  end
  local OnUpdate = _f(function (self, ...)
    this.controlsOnUpdate_origin(self, ...)
    if this.wheel_visable then
      self.rolewheel:OnUpdate()
    end
  end)
  controls.OnUpdate = OnUpdate
end)

onControlsInit = _f(function (self)
  this.controls = self
  addRoleWheel(this.controls)
end)

AddClassPostConstruct("widgets/controls", onControlsInit)

onInitClassSkinsPuppet = _f(function (self)
  this.skinspuppet = self
  print("........skinspuppet..........111", this.skinspuppet)
end)

AddClassPostConstruct("widgets/skinspuppet", onInitClassSkinsPuppet)

_AddThePlayerInit(function ()
  onThePlayerInit()
end)

if (TheInput and ThePlayer) then
  onThePlayerInit()
  addRoleWheel(this.controls)
end


show_msg("cg 11111: ok", GetTime())



--[[
modget("chat_outside").import("cmd")
modget("chat_outside").import("main")
modget("chat_outside").import("widgets/imagewheel")
print(modget("chat_outside").this.controls)
print(modget("chat_outside").this.rolewheel)
print(modget("chat_outside").this.skinspuppet)


modinit("widgets/imagewheel").this.ImageWheel
this.skinspuppet
modget("widgets/imagewheel").arr
tprint(modget("chat_outside").arr)
this.


modget("chat_outside").SetModHUDFocus
tprint(ThePlayer.HUD.SetModFocus)
modget("minimap").this
  local map = this.controls.minimap_small
  map:ToggleOpen()
]]

