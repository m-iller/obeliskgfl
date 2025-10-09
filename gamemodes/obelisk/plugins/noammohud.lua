
PLUGIN.name = "No Ammo Hud"
PLUGIN.description = "Disables the base Helix ammo HUD."
PLUGIN.author = "bruck"
PLUGIN.version = "1.0.0"

if CLIENT then
    function PLUGIN:CanDrawAmmoHUD(weapon)
        return false
    end
end

if SERVER then
    MsgC(Color(0, 180, 255), "[OBL_Plugins] ", Color(255,255,255), "Плагин ", Color(0,180,255), PLUGIN.name, Color(255,255,255), " успешно загружен! ", Color(0,255,0), "Версия " .. PLUGIN.version .. "\n")
else
    MsgC(Color(0, 180, 255), "[OBL_Plugins] ", Color(255,255,255), "Плагин ", Color(0,180,255), PLUGIN.name, Color(255,255,255), " успешно загружен на клиенте! ", Color(0,255,0), "Версия " .. PLUGIN.version .. "\n")
end