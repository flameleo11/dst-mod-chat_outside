
function shuffle2(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

function shuffle(arr)
  local len = #arr
  for i=1, len-1 do
    local x = math.random(i, len)
    arr[i], arr[x] = arr[x], arr[i]
  end
  return arr
end

-- todo shuffle part of ele to pop out

require "tprint"

local arr = {}
for i=1,10 do
	arr[i] = i
end

shuffle(arr)
  -- for i=1, #arr do
tprint(arr)
