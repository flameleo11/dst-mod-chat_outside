function starts_with(str, prefix)
   return string.sub(str,1,string.len(prefix))==prefix
end
function starts_with2(str, prefix)
   return string.sub(str,string.len(prefix)+1,-1)
end

str = "x/ap"
prefix = "/xx"
print(starts_with(str, '-') or starts_with(str, '/'))
print(starts_with2(str, prefix))