PLUGIN.name = 'Admin Item Menu'
PLUGIN.description = 'Adds an item menu for admins.'
PLUGIN.author = 'TomSL / ZeMysticalTaco, Wolffe and Akiran7219'
PLUGIN.version = '1.0.0'

ix.util.Include( 'cl_plugin.lua' )
ix.util.Include( 'sv_plugin.lua' )
ix.util.Include( 'cl_panels.lua' )

if ( not CAMI.GetPrivilege( "Helix - Item Menu" ) ) then
    CAMI.RegisterPrivilege( {
        Name = 'Helix - Item Menu',
        MinAccess = "superadmin",
        Description = 'Whether or not this user has access to the Context Menu Item Spawner.'
    } )
end

function PLUGIN:CanPlayerUseItemMenu( client )
    return CAMI.PlayerHasAccess( client, "Helix - Item Menu", nil ) or client:IsSuperAdmin( )
end

if SERVER then
    MsgC(Color(0, 180, 255), "[OBL_Plugins] ", Color(255,255,255), "Плагин ", Color(0,180,255), PLUGIN.name, Color(255,255,255), " успешно загружен! ", Color(0,255,0), "Версия " .. PLUGIN.version .. "\n")
else
    MsgC(Color(0, 180, 255), "[OBL_Plugins] ", Color(255,255,255), "Плагин ", Color(0,180,255), PLUGIN.name, Color(255,255,255), " успешно загружен на клиенте! ", Color(0,255,0), "Версия " .. PLUGIN.version .. "\n")
end
