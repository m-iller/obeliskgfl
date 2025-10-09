
PLUGIN.name = "Disable Business Menu"
PLUGIN.description = "Disables the business menu in all cases."
PLUGIN.author = "bruck"
PLUGIN.version = "1.0.0"

function PLUGIN:BuildBusinessMenu()
    return false
end

if SERVER then
    MsgC(Color(0, 180, 255), "[OBL_Plugins] ", Color(255,255,255), "Плагин ", Color(0,180,255), PLUGIN.name, Color(255,255,255), " успешно загружен! ", Color(0,255,0), "Версия " .. PLUGIN.version .. "\n")
else
    MsgC(Color(0, 180, 255), "[OBL_Plugins] ", Color(255,255,255), "Плагин ", Color(0,180,255), PLUGIN.name, Color(255,255,255), " успешно загружен на клиенте! ", Color(0,255,0), "Версия " .. PLUGIN.version .. "\n")
end