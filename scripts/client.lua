local cfg_folder = "/drive_d/SteamLibrary/steamapps/common/Don't Starve Together/data/"

local cfg_filename = "my_chat_outside.txt"


local path = cfg_folder..cfg_filename

print(path)
print("[dst] game ready to chat:")

local f = io.open(cfg_filename, "a+")

local line = ""
for i = 1, 9999 do
	print(" > ")
	line = io.read()
	f:write(line)
end

f:close();

