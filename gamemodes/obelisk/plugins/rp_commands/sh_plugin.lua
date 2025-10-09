PLUGIN.name = "RP Commands"
PLUGIN.description = "Commands for roleplay"
PLUGIN.author = "ObeliskStdDev"
PLUGIN.version = "1.0.0"

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

if SERVER then
    MsgC(Color(0, 180, 255), "[OBL_Plugins] ", Color(255,255,255), "Плагин ", Color(0,180,255), PLUGIN.name, Color(255,255,255), " успешно загружен! ", Color(0,255,0), "Версия " .. PLUGIN.version .. "\n")
else
    MsgC(Color(0, 180, 255), "[OBL_Plugins] ", Color(255,255,255), "Плагин ", Color(0,180,255), PLUGIN.name, Color(255,255,255), " успешно загружен на клиенте! ", Color(0,255,0), "Версия " .. PLUGIN.version .. "\n")
end
