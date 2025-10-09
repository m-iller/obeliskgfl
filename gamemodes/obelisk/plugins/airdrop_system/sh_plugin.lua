PLUGIN.name = "Airdrop System"
PLUGIN.uniqueID = "airdrop_system"
PLUGIN.author = "kido" 
PLUGIN.description = "Система вызова аирдропов для фракций с терминалами"
PLUGIN.version = "1.0.0"

-- Регистрируем флаг A для доступа к системе аирдропов
ix.flag.Add("A", "Доступ к системе аирдропов", nil, true)

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")

-- Конфигурация плагина находится в ix.configs.airbrop
-- Все параметры доступны через ix.configs.airbrop.*

-- Таблицы для хранения данных
PLUGIN.activeAirdrops = {}
PLUGIN.playerCooldowns = {}

-- Функция для проверки лимитов конкретного типа аирдропа
function PLUGIN:CheckAirdropLimit(airdropType, faction)
    local count = 0
    for _, airdrop in pairs(self.activeAirdrops) do
        if airdrop.type == airdropType and airdrop.faction == faction and IsValid(airdrop.entity) then
            count = count + 1
        end
    end
    
    -- Находим максимальный лимит для этого типа аирдропа
    local factionConfig = ix.configs.airbrop.factions[faction]
    if factionConfig then
        for _, airdropData in ipairs(factionConfig.airdrops or {}) do
            if airdropData.type == airdropType then
                return count < airdropData.maxActive
            end
        end
    end
    
    return false -- Если тип не найден, запрещаем
end

-- Функция для получения информации об аирдропе по типу
function PLUGIN:GetAirdropDataByType(faction, airdropType)
    local factionConfig = ix.configs.airbrop.factions[faction]
    if factionConfig then
        for _, airdropData in ipairs(factionConfig.airdrops or {}) do
            if airdropData.type == airdropType then
                return airdropData
            end
        end
    end
    return nil
end

-- Функция для добавления аирдропа в активные
function PLUGIN:AddActiveAirdrop(entity, type, spawner, position, faction)
    local airdropData = {
        entity = entity,
        type = type,
        faction = faction,
        spawner = spawner,
        position = position,
        spawnTime = CurTime()
    }
    
    self.activeAirdrops[entity:EntIndex()] = airdropData
    
    return airdropData
end

-- Функция для удаления аирдропа из активных
function PLUGIN:RemoveActiveAirdrop(entity)
    local index = entity:EntIndex()
    local airdropData = self.activeAirdrops[index]
    
    if airdropData then
        self.activeAirdrops[index] = nil
    end
end

-- Функция для проверки кулдауна
function PLUGIN:CheckCooldown(player, faction)
    local steamID = player:SteamID()
    local cooldownKey = steamID .. "_" .. faction
    local lastUse = self.playerCooldowns[cooldownKey] or 0
    local cooldownTime = ix.configs.airbrop.cooldown or 0
    
    return CurTime() - lastUse >= cooldownTime
end

-- Функция для установки кулдауна
function PLUGIN:SetCooldown(player, faction)
    local steamID = player:SteamID()
    local cooldownKey = steamID .. "_" .. faction
    self.playerCooldowns[cooldownKey] = CurTime()
end

-- Функция для получения оставшегося времени кулдауна
function PLUGIN:GetCooldownRemaining(player, faction)
    local steamID = player:SteamID()
    local cooldownKey = steamID .. "_" .. faction
    local lastUse = self.playerCooldowns[cooldownKey] or 0
    local cooldownTime = ix.configs.airbrop.cooldown or 0
    
    return math.max(0, cooldownTime - (CurTime() - lastUse))
end

-- Функция для проверки доступа игрока к аирдропам фракции
function PLUGIN:CanPlayerAccessFaction(player, factionKey)
    local character = player:GetCharacter()
    if (not character) or (not character:HasFlags("A")) then
        return false
    end
    
    -- Проверяем фракцию персонажа
    local factionConfig = ix.configs.airbrop.factions[factionKey]
    if not factionConfig or not factionConfig.factionID then
        return false
    end
    
    -- Проверяем, принадлежит ли персонаж к нужной фракции
    local playerFaction = character:GetFaction()
    
    -- Поддерживаем как одну фракцию, так и список фракций
    if type(factionConfig.factionID) == "table" then
        for _, factionID in ipairs(factionConfig.factionID) do
            if playerFaction == factionID then
                return true
            end
        end
        return false
    else
        return playerFaction == factionConfig.factionID
    end
end

-- Функция для получения доступных аирдропов для игрока
function PLUGIN:GetAvailableAirdropsForPlayer(player, factionKey)
    local character = player:GetCharacter()
    if not character then
        return {}
    end
    
    -- Проверяем доступ к фракции
    if not self:CanPlayerAccessFaction(player, factionKey) then
        return {}
    end
    
    local factionConfig = ix.configs.airbrop.factions[factionKey]
    if not factionConfig then
        return {}
    end
    
    -- Возвращаем все доступные аирдропы фракции
    return factionConfig.airdrops or {}
end 

if SERVER then
    MsgC(Color(0, 180, 255), "[OBL_Plugins] ", Color(255,255,255), "Плагин ", Color(0,180,255), PLUGIN.name, Color(255,255,255), " успешно загружен! ", Color(0,255,0), "Версия " .. PLUGIN.version .. "\n")
else
    MsgC(Color(0, 180, 255), "[OBL_Plugins] ", Color(255,255,255), "Плагин ", Color(0,180,255), PLUGIN.name, Color(255,255,255), " успешно загружен на клиенте! ", Color(0,255,0), "Версия " .. PLUGIN.version .. "\n")
end

