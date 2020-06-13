------------------------------------------------------------
-- header
------------------------------------------------------------

local require = GLOBAL.require
local modinit = require("modinit")
local mod = modinit("chat_outside")

------------------------------------------------------------
-- main
------------------------------------------------------------

require("tprint")
mod.import("main")
mod.import("cmd")

--[[
modget("chat_outside").import("main")
modget("chat_outside").import("cmd")

]]

