

function split_by_space(s)
	local arr = {}
	for w in s:gmatch("%S+") do
		arr[#arr+1] = w
	end
	return arr
end

local s = "11 22 3sdfa 55st"
require "tprint"
tprint(split_by_space(s))