local arr = {}
table.insert(arr, "str");
table.insert(arr, "str222");

require "tprint"


tprint{
	arr
}

local msg = table.remove(arr, 1)

tprint{
	arr, msg
}

-- -- to remove from that end we use table.remove(a, 1).
-- table.insert(arr, "str");
-- local msg = table.remove(arr, 1)