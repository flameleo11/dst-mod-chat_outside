name = 'Chat Outside'
description = 'Say chat msg by outside html input box'
author = 'Flameleo'
version = '20200413'
forumthread = ''
api_version = 10
dst_compatible = true
client_only_mod = true
dont_starve_compatible = false
reign_of_giants_compatible = false
all_clients_require_mod = false
icon_atlas = 'modicon.xml'
icon = 'modicon.tex'
server_filter_tags = {}


local keys = {
	"None",
	"BACKSPACE","DELETE","ESC",
	"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
};

configuration_options = {
	{
		name = "CANCLE_CHAT_KEY",
		label = "cancel sending chat msg",
		hover = "cancel sending chat msg",
		options = {
			--fill later
		},
		default = "DELETE",
	},
}

local function filltable(tbl)
	for i=1, #keys do
		tbl[i] = {description = keys[i], data = keys[i]}
	end
end
filltable(configuration_options[1].options)