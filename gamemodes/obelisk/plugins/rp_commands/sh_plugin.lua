PLUGIN.name = "RP Commands"
PLUGIN.description = "Commands for roleplay"
PLUGIN.author = "ObeliskStdDev"

-- Регистрируем типы чата для RP команд

function PLUGIN:InitializedConfig()
	-- Тип чата для команды /do
	ix.chat.Register("do", {
		OnChatAdd = function(self, speaker, text)
			chat.AddText(ix.config.Get("chatColor"), text)
		end,
		CanHear = ix.config.Get("chatRange", 280) * 2,
		deadCanChat = true
	})
	
	-- Тип чата для команды /try
	ix.chat.Register("try", {
		OnChatAdd = function(self, speaker, text)
			chat.AddText(ix.config.Get("chatColor"), text)
		end,
		CanHear = ix.config.Get("chatRange", 280) * 2,
		deadCanChat = true
	})
end

ix.util.Include("sh_commands.lua")
ix.util.Include("sv_hooks.lua")
