require("tprint")

local G = GLOBAL
local push = table.insert
local tjoin = table.concat
local trace = print
local trace = function () end
local easing = require("easing")
local Text = require "widgets/text"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"

lib_chat_outside = lib_chat_outside or {}
lib_chat_outside.player_inited = lib_chat_outside.player_inited or {}
lib_chat_outside.key_inited  = lib_chat_outside.key_inited or {}

lib_chat_outside.queue_msg = lib_chat_outside.queue_msg or {}

local cfg_filename = "my_chat_outside.txt"
local cfg_default_keys = {
  ["BACKSPACE"] = {};
  ["DELETE"] = {};
}
local cfg_rightnow = 0;
local cfg_count_down = 5;
local CFG_SCAN_RANGE = 45;
local b_debug = true;


------------------------------------------------------------
-- tools
------------------------------------------------------------

-- local GetTime = _G.GetTime
-- local TheNet = _G.TheNet
is_PvP = TheNet:GetDefaultPvpSetting()
SERVER_SIDE = TheNet:GetIsServer()

-- also user when host
CLIENT_SIDE =	TheNet:GetIsClient() or (SERVER_SIDE and not TheNet:IsDedicated())

function IsInGameplay()
  if not ThePlayer then
    return
  end
  trace("IsInGameplay.....", TheFrontEnd:GetActiveScreen().name)
  if not (TheFrontEnd:GetActiveScreen().name == "HUD") then
    return
  end
  return true
end

function IsDST()
  return TheSim:GetGameID() == "DST"
end

function add_ThePlayer_init(fn)
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

function show_msg_api(msg, onlyClear)
  -- debug hot reload
  if (b_debug and TheFrontEnd.showmsg) then
    TheFrontEnd.overlayroot:RemoveChild(TheFrontEnd.showmsg)
    TheFrontEnd.showmsg:Hide()
    TheFrontEnd.showmsg:Kill()
    TheFrontEnd.showmsg = nil
  end

  if (lib_chat_outside.update_msg_task) then
    lib_chat_outside.update_msg_task:Cancel()
    lib_chat_outside.update_msg_task = nil
  end

  if (onlyClear) then
    return
  end
   -- 39
   -- 40
   -- 41: ANCHOR_MIDDLE = 0
   -- 42: ANCHOR_LEFT = 1
   -- 43: ANCHOR_RIGHT = 2
   -- 44: ANCHOR_TOP = 1
   -- 45: ANCHOR_BOTTOM = 2

  local text = TheFrontEnd.showmsg
  if not (text) then
-- print(222, 555, text)
-- tprint{text.SetVAlign}
    text = Text(TALKINGFONT, 32)
    text:Hide()
    text:SetPosition(300, 120, 0)
    if (b_debug) then
      text:SetPosition(300, 240, 0)
    end
    text:SetVAlign(ANCHOR_BOTTOM)

    text:SetHAlign(ANCHOR_LEFT)
    text:SetHAnchor(ANCHOR_LEFT)
    text:SetVAnchor(ANCHOR_BOTTOM)
    TheFrontEnd.showmsg = text
    TheFrontEnd.overlayroot:AddChild(text)
  end

  text:Hide()
  text:SetString(msg)

  local fade_time = 0
  local fade_total = 5
  local dt = 1/10

  on_text_timeover = _f(function (text, dt)
    text:Hide()
    lib_chat_outside.update_msg_task:Cancel()
    lib_chat_outside.update_msg_task = nil
  end)

  text:Show()
  lib_chat_outside.update_msg_task = ThePlayer:DoTaskInTime(
    cfg_count_down,
    function()
      on_text_timeover(text, dt)
    end, 0)
end


function show_msg(...)
  local arr = {}
  for i,v in ipairs({...}) do
    arr[i] = tostring(v)
  end
  local msg = tjoin(arr, "\n")
  if (TheFrontEnd and TheFrontEnd.ShowTitle) then
    -- TheFrontEnd:ShowTitle("", msg)
    show_msg_api(msg)
  else
    if (ThePlayer and ThePlayer.components and ThePlayer.components.talker) then
      ThePlayer.components.talker:Say(msg)
    end
  end
  trace(msg)
  -- ThePlayer.components.talker:Say(msg)
end

function touch_file(filename)
  local f0 = io.open(filename, "w")
  f0:close();
  local f = io.open(filename, "r")
  return f
end

------------------------------------------------------------
-- game
------------------------------------------------------------

function init_buffer_txt(filename)
  local f = touch_file(filename)
  if (f == nil) then
    show_msg("[error] can not open file", filename)
    return
  end
  lib_chat_outside.file = f
  return f
end

function push_sending_msg(msg)
  local arr = lib_chat_outside.queue_msg
  table.insert(arr, msg)
end

function get_sending_msg()
  local arr = lib_chat_outside.queue_msg
  local msg = table.remove(arr, 1)
  return msg
end

function cancel_sending_msg()
  local msg = get_sending_msg()
  if (msg) then
    -- show_msg("undo say: "..msg)
    local msg = ("say: %s ( undo )"):format(msg)
    show_msg(msg)
  end
  trace("1111..........cancel_sending_msg.......", msg)
end

function send_current_msg()
  local msg = get_sending_msg()
  if not (msg) then
    return
  end
  if (TheNet and TheNet.Say) then
    TheNet:Say(msg);print(msg)
  end
end

function parseMsg(str)
  -- todo by format
  return str
end

function starts_with(str, prefix)
   return string.sub(str,1,string.len(prefix))==prefix
end

function after_prefix(str, prefix)
   return string.sub(str,string.len(prefix)+1,-1)
end


------------------------------------------------------------
-- on event
------------------------------------------------------------


local CFG_PLAYER_PREFAB = {
  ["wilson"]       = 1;
  ["willow"]       = 1;
  ["wolfgang"]     = 1;
  ["wendy"]        = 1;
  ["wx78"]         = 1;
  ["wickerbottom"] = 1;
  ["woodie"]       = 1;
  ["wes"]          = 1;
  ["waxwell"]      = 1;
  ["wathgrithr"]   = 1;
  ["webber"]       = 1;
  ["winona"]       = 1;
  ["warly"]        = 1;
  ["wortox"]       = 1;
  ["wormwood"]     = 1;
  ["wurt"]         = 1;
}


onChatCommand = _f(function (msg)
  local cmd = after_prefix(msg, "-")
  if (cmd == "scan_beefalo") then
    ScanNearByBeefalo()
  end
  if (cmd == "1") then
    ScanNearByBeefalo()
  end

  local name = cmd
  if (CFG_PLAYER_PREFAB[name]) then
    ThePlayer.prefab = name
    show_msg(name)
  end

end)

onPressKey = _f(function ()
  trace("[chat_outside] onPressKey ..... 111")
  if not ThePlayer then
    return
  end

  if (lib_chat_outside.count_down_task) then
    lib_chat_outside.count_down_task:Cancel()
    lib_chat_outside.count_down_task = nil
  end
  cancel_sending_msg()
  -- lib_chat_outside.on_count_down(cfg_count_down)

  trace("IsInGameplay.....", TheFrontEnd:GetActiveScreen().name)
  if (TheFrontEnd:GetActiveScreen().name == "ConsoleScreen") then
    reset()
  end
end)

onTimeoutSendingMsg = _f(function ()
  send_current_msg()
end)


onTimedReadingMsg = _f(function ()
  -- todo high level check file open
  local f = lib_chat_outside.file
  if not f then
    f = init_buffer_txt(cfg_filename)
  end

  -- local len = f:seek("end")
  -- f:seek("set", len - 1024)

  local str = f:read("*a")
  if not (str and #str > 0) then
    return
  end

  local msg = parseMsg(str)
  if (starts_with(msg, '-') or starts_with(msg, '/')) then
    onChatCommand(msg)
    return
  end


  push_sending_msg(msg)
  trace("ready to say: ", msg, lib_chat_outside.queue_msg)

  -- ThePlayer:DoTaskInTime(cfg_rightnow, _f(function()
  --   show_msg("say: "..msg)
  -- end))
  if (lib_chat_outside.count_down_task) then

    -- lib_chat_outside.count_down_task:Cancel()
    -- lib_chat_outside.count_down_task = nil
    -- local onlyClear = true
    -- show_msg_api("", onlyClear)
    lib_chat_outside.on_count_down(cfg_count_down)
  end

  lib_chat_outside.on_count_down = _f(function(second)
    local remain_sec = cfg_count_down - second
    local msg = ("say: %s (%ss)"):format(msg, remain_sec)
    show_msg(msg)

    if (remain_sec <= 0) then
      lib_chat_outside.count_down_task:Cancel()
      lib_chat_outside.count_down_task = nil
      local onlyClear = true
      show_msg_api("", onlyClear)
      onTimeoutSendingMsg(msg)
    end
  end)

  local second = 0

  lib_chat_outside.count_down_task = ThePlayer:DoPeriodicTask(1, function ()
    lib_chat_outside.on_count_down(second)
    second = second + 1
  end)

end)

function addHotKey(key)
  local keybind = _G["KEY_"..key]
  TheInput:AddKeyDownHandler(keybind, function ()
    onPressKey()
  end)
end

------------------------------------------------------------
-- main
------------------------------------------------------------

function init_hotkey(key)
  if (key == "None") then
    return
  end

  if not (cfg_default_keys[key]) then
    addHotKey(key)
  end

  for k, v in pairs(cfg_default_keys) do
    addHotKey(k)
  end
end

function init_player()
  ThePlayer:DoPeriodicTask(1, function()
    onTimedReadingMsg()
  end, 0)
end

function reset()
  if (lib_chat_outside.file) then
    lib_chat_outside.file:close()
  end
  lib_chat_outside.file = nil
  lib_chat_outside.sending_msg = nil

  init_buffer_txt(cfg_filename)

  lib_chat_outside.ver = 123
  trace("ver.....", lib_chat_outside.ver)
end

function init()
  reset()

  local GUID = ThePlayer.GUID
  if not (lib_chat_outside.player_inited[GUID]) then
    lib_chat_outside.player_inited[GUID] = true;
    init_player()
  end

  local key = GetModConfigData("CANCLE_CHAT_KEY")
  trace(111, key, 22222222222)
  if not (lib_chat_outside.key_inited[key]) then
    lib_chat_outside.key_inited[key] = true
    init_hotkey(key)
  end

  on_minimap()

  print("[mod] lib_chat_outside ........init ok..")
end

------------------------------------------------------------
-- init
------------------------------------------------------------



add_ThePlayer_init(function ()
  trace("lib_chat_outside.init()", 111)
  init()
end)

if (TheInput and ThePlayer) then
  trace("lib_chat_outside.init()", 222)
  init()
end


------------------------------------------------------------
-- test
------------------------------------------------------------

this = this or {}
this.selected_ents = this.selected_ents or {}
this.color = {x = 1, y = 1, z = 1}


function SetSelectionColor(r, g, b, a)
  this.color.x = r * 0.5
  this.color.y = g * 0.5
  this.color.z = b * 0.5
  return this.color
end

function SetColorPreset(name)
  local r, g, b = unpack(PLAYERCOLOURS[name])
  local a = 0.2
  return SetSelectionColor(r, g, b, a)
end

print(SetColorPreset("GREEN"))


function IsSelectedEntity(ent)
  return this.selected_ents[ent]
end

function SelectEntity(ent, color)
  if IsSelectedEntity(ent) then return end
  if not ent.components.highlight then
    ent:AddComponent("highlight")
  end
  local highlight = ent.components.highlight
  highlight.highlight_add_colour_red = nil
  highlight.highlight_add_colour_green = nil
  highlight.highlight_add_colour_blue = nil
  highlight:SetAddColour(color)
  highlight.highlit = true
end

function DeselectEntity(ent)
  if IsSelectedEntity(ent) then
    this.selected_ents[ent] = nil
    if ent:IsValid() and ent.components.highlight then
      ent.components.highlight:UnHighlight()
    end
  end
end

function GetBeefaloHerd(ent)
  return ent.components.herdmember and ent.components.herdmember:GetHerd();
end

function EnumNearByBeefalo(inst, range, callback)
  local x, y, z = inst.Transform:GetWorldPosition()
  local ents = TheSim:FindEntities(x, y, z, range, { "herdmember", "beefalo" })
  for i, v in ipairs(ents) do
    callback(v, i)
  end
end


function ScanNearByBeefalo()
  local arr = {}
  onEnumBeefalo = _f(function (ent, i)
    if (GetBeefaloHerd(ent) == nil) then
      SelectEntity(ent, this.color)
      local x, y, z = ent.Transform:GetWorldPosition()
      local msg = ("find %s at (%s, %s, %s)"):format(
        tostring(ent), x, y, z );
      push(arr, ent)
      show_msg(msg);
    end
  end)

  EnumNearByBeefalo(ThePlayer, CFG_SCAN_RANGE, function (ent, i)
    onEnumBeefalo(ent, i)
  end);
  show_msg(("scan over find %s"):format(#arr));
end


------------------------------------------------------------
-- reload
------------------------------------------------------------


on_reload = _f(function (params, caller)
  _M2.import("chat_outside");
  local elapse = GetTime()
  show_msg("reload ...... ok..."..elapse)
end)

AddUserCommand("r", {
  prettyname = nil, --default to STRINGS.UI.BUILTINCOMMANDS.BUG.PRETTYNAME
  desc = nil, --default to STRINGS.UI.BUILTINCOMMANDS.BUG.DESC
  permission = COMMAND_PERMISSION.USER,
  slash = false,
  usermenu = false,
  servermenu = false,
  params = {},
  vote = false,
  localfn = function(params, caller)
    on_reload(params, caller)
  end,
})


------------------------------------------------------------
-- test 2
------------------------------------------------------------


function split_by_space(s)
  local arr = {}
  for w in s:gmatch("%S+") do
    arr[#arr+1] = w
  end
  return arr
end

function set_mapscale(minimap_small, mapscale)
  mapscale = mapscale or 1
  local bg = Image("images/hud.xml", "map.tex")
  local map_w, map_h = bg:GetSize()
  bg:Kill()
  bg = nil
  print(111, map_w, map_h)
  local map_w, map_h = map_w*mapscale, map_h*mapscale
  minimap_small.mapsize = {w=map_w, h=map_h}
  minimap_small.img:SetSize(map_w,map_h,0)
  minimap_small.bg:SetSize(0,0,0)
  print(222, map_w, map_h)
end

on_minimap = _f(function (params, caller)
  -- show_msg("test ...... ok...111")
  local args = {}
  if (params and params.rest and #params.rest > 0) then
    args = split_by_space(params.rest)
  end

  local controls = this.controls
  local pos = controls.minimap_small:GetPosition()
  x = args[3] and tonumber(args[3]) or -320
  y = args[4] and tonumber(args[4]) or -600
  local mapscale = args[1] and tonumber(args[1]) or 0.5
  local ups = args[2] and tonumber(args[2]) or 0.1


  controls.minimap_small:SetUPS(ups)
  -- controls.minimap_small:ToggleOpen()
  -- controls.minimap_small:ToggleOpen()
  controls.minimap_small:SetOpen(true)

  set_mapscale(controls.minimap_small, mapscale)

  controls.minimap_small:SetPosition(x, y)
  print(777, x, y, mapscale, ups)
  show_msg(999, x, y, mapscale, ups)
end)

AddUserCommand("minimap", {
  prettyname = nil, --default to STRINGS.UI.BUILTINCOMMANDS.BUG.PRETTYNAME
  desc = nil, --default to STRINGS.UI.BUILTINCOMMANDS.BUG.DESC
  permission = COMMAND_PERMISSION.USER,
  slash = false,
  usermenu = false,
  servermenu = false,
  params = {},
  vote = false,
  localfn = function(params, caller)
    on_minimap(params, caller)
  end,
})


on_test = _f(function (params, caller)
  -- show_msg("test ...... ok...111")
  local mc = this.mapcontrols

end)

AddUserCommand("t", {
  prettyname = nil, --default to STRINGS.UI.BUILTINCOMMANDS.BUG.PRETTYNAME
  desc = nil, --default to STRINGS.UI.BUILTINCOMMANDS.BUG.DESC
  permission = COMMAND_PERMISSION.USER,
  slash = false,
  usermenu = false,
  servermenu = false,
  params = {},
  vote = false,
  localfn = function(params, caller)
    on_test(params, caller)
  end,
})



--[[
_M2.import("chat_outside");_M2.show_msg_api("ok")
print(_M2.GetBeefaloHerd(t_inst))

_M2.EnumNearByBeefalo(ThePlayer, 40, function (ent, i) print(i, ent) end);
_M2.ScanNearByBeefalo()

t_inst = TheInput:GetWorldEntityUnderMouse();print(t_inst);_M2.show_msg_api(tostring(_M2.GetBeefaloHerd(t_inst)));
t_herd = t_inst.components.herdmember and t_inst.components.herdmember:GetHerd(); print(t_herd:GetDebugString())

EnumNearByBeefalo(ThePlayer, 40, fun)

print(_M2.SetColorPreset("GREEN"))
print(_M2.IsSelectedEntity(t_inst))
print(_M2.SelectEntity(t_inst, _M2.this.color))

function SelectEntity(ent, color)


PLAYERCOLOURS[GetModConfigData("turf_grid_color")]

--]]
trace(".....import.......lib_chat_outside.....111...ok", CLIENT_SIDE)
