PLUGIN.name = "Vehicle Call System"
PLUGIN.uniqueID = "vehicle_call_system"
PLUGIN.author = "kido" 
PLUGIN.description = "Система вызова воздушной и наземной техники с терминалами"

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")

-- Добавляем флаг для доступа к системе вызова техники
ix.flag.Add("V", "Доступ к системе вызова техники", function(client, bGiven)
    if bGiven then
        print("[VCS] Игрок " .. (client:GetName() or "Unknown") .. " получил доступ к системе вызова техники")
        if IsValid(client) and client.Notify then
            client:Notify("Вы получили доступ к системе вызова техники (флаг V)")
        end
    else
        print("[VCS] Игрок " .. (client:GetName() or "Unknown") .. " потерял доступ к системе вызова техники")
        if IsValid(client) and client.Notify then
            client:Notify("Вы потеряли доступ к системе вызова техники (флаг V)")
        end
    end
end)

-- Конфигурация плагина теперь находится в ix.configs.vcs
-- Все параметры доступны через ix.configs.vcs.*

-- Таблицы для хранения данных
PLUGIN.spawnPositions = {
    air = {},
    ground = {}
}

PLUGIN.activeVehicles = {}
PLUGIN.playerCooldowns = {}

-- Функция для получения позиций спавна
function PLUGIN:GetSpawnPositions(type)
    return self.spawnPositions[type] or {}
end

-- Функция для проверки лимитов конкретной техники
function PLUGIN:CheckVehicleLimit(vehicleClass)
    local count = 0
    for _, vehicle in pairs(self.activeVehicles) do
        if vehicle.class == vehicleClass and IsValid(vehicle.entity) then
            count = count + 1
        end
    end
    
    -- Находим максимальный лимит для этого класса техники
    for vehicleType, vehicles in pairs(ix.configs.vcs.vehicles) do
        for _, vehicleData in ipairs(vehicles) do
            if vehicleData.class == vehicleClass then
                return count < vehicleData.maxActive
            end
        end
    end
    
    return false -- Если класс не найден, запрещаем
end

-- Функция для получения информации о технике по классу
function PLUGIN:GetVehicleDataByClass(vehicleClass)
    for vehicleType, vehicles in pairs(ix.configs.vcs.vehicles) do
        for _, vehicleData in ipairs(vehicles) do
            if vehicleData.class == vehicleClass then
                return vehicleData, vehicleType
            end
        end
    end
    return nil, nil
end

-- Функция для получения информации о технике по имени и типу
function PLUGIN:GetVehicleDataByName(vehicleType, vehicleName)
    for _, vehicleData in ipairs(ix.configs.vcs.vehicles[vehicleType] or {}) do
        if vehicleData.name == vehicleName then
            return vehicleData
        end
    end
    return nil
end

-- Функция для добавления техники в активные
function PLUGIN:AddActiveVehicle(entity, type, spawner, position, vehicleClass, vehicleName)
    local vehicleData = {
        entity = entity,
        type = type,
        class = vehicleClass,
        name = vehicleName,
        spawner = spawner,
        position = position,
        spawnTime = CurTime()
    }
    
    self.activeVehicles[entity:EntIndex()] = vehicleData
    
    return vehicleData
end

-- Функция для удаления техники из активных
function PLUGIN:RemoveActiveVehicle(entity)
    local index = entity:EntIndex()
    local vehicleData = self.activeVehicles[index]
    
    if vehicleData then
        self.activeVehicles[index] = nil
    end
end

-- Функция для проверки кулдауна
function PLUGIN:CheckCooldown(player, type)
    local steamID = player:SteamID()
    local cooldownKey = steamID .. "_" .. type
    local lastUse = self.playerCooldowns[cooldownKey] or 0
    local cooldownTime = ix.configs.vcs.cooldowns[type] or 0
    
    return CurTime() - lastUse >= cooldownTime
end

-- Функция для установки кулдауна
function PLUGIN:SetCooldown(player, type)
    local steamID = player:SteamID()
    local cooldownKey = steamID .. "_" .. type
    self.playerCooldowns[cooldownKey] = CurTime()
end

-- Функция для получения оставшегося времени кулдауна
function PLUGIN:GetCooldownRemaining(player, type)
    local steamID = player:SteamID()
    local cooldownKey = steamID .. "_" .. type
    local lastUse = self.playerCooldowns[cooldownKey] or 0
    local cooldownTime = ix.configs.vcs.cooldowns[type] or 0
    
    return math.max(0, cooldownTime - (CurTime() - lastUse))
end

-- Функция для проверки доступа игрока к технике
function PLUGIN:CanPlayerAccessVehicle(player, vehicleData)
    -- Проверяем, есть ли у игрока флаг доступа к системе вызова техники
    local character = player:GetCharacter()
    if not character then
        return false
    end
    
    return character:HasFlags("V")
end

-- Функция для получения доступной техники для игрока
function PLUGIN:GetAvailableVehiclesForPlayer(player, vehicleType)
    -- Проверяем, есть ли у игрока флаг доступа к системе вызова техники
    local character = player:GetCharacter()
    if not character or not character:HasFlags("V") then
        return {} -- Возвращаем пустой список, если нет доступа
    end
    
    -- Возвращаем всю технику указанного типа, если есть доступ
    return ix.configs.vcs.vehicles[vehicleType] or {}
end 