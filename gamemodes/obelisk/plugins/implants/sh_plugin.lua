PLUGIN.name = "Implants System"
PLUGIN.description = "Система имплантов с админским меню"
PLUGIN.author = "ObeliskStdDev"

-- Конфиг теперь находится в схеме

-- Консольная команда для открытия меню имплантов
concommand.Add(ix.configs.implantCommand or "implants", function(client, cmd, args)
    if CLIENT then
        ix.gui.implants = ix.gui.implants or vgui.Create("ixImplantsMenu")
        ix.gui.implants:SetVisible(true)
        ix.gui.implants:MakePopup()
    end
end)

ix.util.Include("cl_menu.lua")
ix.util.Include("sv_network.lua")

ix.util.IncludeDir("bonuses", "shared")

-- Глобальная таблица имплантов игроков
ix.implants = ix.implants or {}

-- Функция для получения имплантов игрока
function ix.GetPlayerImplants(client)
    return ix.implants[client:SteamID64()] or {}
end

-- Функция для установки импланта игроку
function ix.SetPlayerImplant(client, limb, implant)
    if not ix.implants[client:SteamID64()] then
        ix.implants[client:SteamID64()] = {}
    end
    
    if implant == "НЕТ" then
        ix.implants[client:SteamID64()][limb] = nil
    else
        ix.implants[client:SteamID64()][limb] = implant
    end
    
    -- Сохраняем в базу данных
    if SERVER then
        ix.SavePlayerImplants(client)
    end
end

-- Функция для сохранения имплантов в БД
function ix.SavePlayerImplants(client)
    if not SERVER then return end
    
    local steamID64 = client:SteamID64()
    local implants = ix.implants[steamID64] or {}
    
    -- Сохраняем в данные игрока
    client:SetData("implants", implants)
end

-- Функция для загрузки имплантов из БД
function ix.LoadPlayerImplants(client)
    if not SERVER then return end
    
    local steamID64 = client:SteamID64()
    local implants = client:GetData("implants", {})
    
    ix.implants[steamID64] = implants
end

-- Применяем бонусы имплантов при спавне персонажа
if SERVER then
    hook.Add("PlayerSpawn", "ixImplantsApplyBonuses", function(client)
        if not client:GetCharacter() then return end
        
        local implants = ix.GetPlayerImplants(client)
        
        for limb, implant in pairs(implants) do
            if implant and implant ~= "НЕТ" then
                local implantData = ix.configs.implants[implant]
                if implantData and implantData.bonus then
                    -- Применяем бонус импланта
                    hook.Run("ImplantBonusApplied", client, limb, implant, implantData.bonus)
                end
            end
        end
    end)
    
    -- Загружаем импланты при подключении игрока
    hook.Add("PlayerLoaded", "ixImplantsLoad", function(client)
        ix.LoadPlayerImplants(client)
    end)
end
