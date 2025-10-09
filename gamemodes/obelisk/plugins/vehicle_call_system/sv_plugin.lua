-- Серверная часть плагина Vehicle Call System
local PLUGIN = PLUGIN
util.AddNetworkString("VCS_OpenTerminal")
util.AddNetworkString("VCS_SpawnVehicle") 
util.AddNetworkString("VCS_GetActiveVehicles")
util.AddNetworkString("VCS_SendActiveVehicles")
util.AddNetworkString("VCS_OpenLogTerminal")
util.AddNetworkString("VCS_GetLogs")
util.AddNetworkString("VCS_SendLogs")
util.AddNetworkString("VCS_OpenSpawnManager")
util.AddNetworkString("VCS_GetSpawnPositions") 
util.AddNetworkString("VCS_SendSpawnPositions")
util.AddNetworkString("VCS_AddSpawnPosition")
util.AddNetworkString("VCS_RemoveSpawnPosition")
util.AddNetworkString("VCS_RemoveVehicle") -- Добавляем новый сетевой канал
util.AddNetworkString("VCS_EditSpawnPosition") -- Добавляем редактирование позиций

-- Инициализация плагина
function PLUGIN:OnLoaded()
    -- Загружаем позиции спавна из файлов
    self:LoadSpawnPositions()
    
    -- Инициализируем пустой массив логов если его нет
    if not ix.data.Get("vcs_vehicle_logs", nil) then
        ix.data.Set("vcs_vehicle_logs", {})
    end
end

-- Загрузка позиций спавна из файлов
function PLUGIN:LoadSpawnPositions()
    self.spawnPositions.air = {}
    self.spawnPositions.ground = {}
    
    -- Загружаем воздушные позиции
    local airData = ix.data.Get("vcs_air_positions", {})
    for i, posData in ipairs(airData) do
        table.insert(self.spawnPositions.air, {
            id = i,
            pos = Vector(posData.x, posData.y, posData.z),
            ang = Angle(posData.ang_p or 0, posData.ang_y or 0, posData.ang_r or 0),
            description = posData.description or "Позиция спавна " .. i
        })
    end
    
    -- Загружаем наземные позиции
    local groundData = ix.data.Get("vcs_ground_positions", {})
    for i, posData in ipairs(groundData) do
        table.insert(self.spawnPositions.ground, {
            id = i,
            pos = Vector(posData.x, posData.y, posData.z),
            ang = Angle(posData.ang_p or 0, posData.ang_y or 0, posData.ang_r or 0),
            description = posData.description or "Позиция спавна " .. i
        })
    end
    
    -- Если нет позиций, создаем тестовые
    if #self.spawnPositions.air == 0 then
        print("[VCS] Создаем тестовую позицию воздушной техники")
        self:AddSpawnPosition("air", Vector(0, 0, 100), Angle(0, 0, 0), "Тестовая воздушная позиция")
    end
    
    if #self.spawnPositions.ground == 0 then
        print("[VCS] Создаем тестовую позицию наземной техники")
        self:AddSpawnPosition("ground", Vector(0, 0, 0), Angle(0, 0, 0), "Тестовая наземная позиция")
    end
end

-- Добавление позиции спавна
function PLUGIN:AddSpawnPosition(type, pos, ang, description)
    ang = ang or Angle(0, 0, 0)
    description = description or "Позиция спавна"
    
    -- Загружаем существующие данные
    local dataKey = type == "air" and "vcs_air_positions" or "vcs_ground_positions"
    local existingData = ix.data.Get(dataKey, {})
    
    -- Добавляем новую позицию
    local newPosition = {
        x = pos.x,
        y = pos.y,
        z = pos.z,
        ang_p = ang.p,
        ang_y = ang.y,
        ang_r = ang.r,
        description = description
    }
    
    table.insert(existingData, newPosition)
    
    -- Сохраняем обратно в файл
    ix.data.Set(dataKey, existingData)
    
    -- Добавляем в память
    local newId = #self.spawnPositions[type] + 1
    table.insert(self.spawnPositions[type], {
        id = newId,
        pos = pos,
        ang = ang,
        description = description
    })
end

-- Удаление позиции спавна
function PLUGIN:RemoveSpawnPosition(type, id)
    -- Удаляем из памяти
    for i, position in ipairs(self.spawnPositions[type]) do
        if position.id == id then
            table.remove(self.spawnPositions[type], i)
            break
        end
    end
    
    -- Пересохраняем весь массив в файл
    local dataKey = type == "air" and "vcs_air_positions" or "vcs_ground_positions"
    local saveData = {}
    
    for _, position in ipairs(self.spawnPositions[type]) do
        table.insert(saveData, {
            x = position.pos.x,
            y = position.pos.y,
            z = position.pos.z,
            ang_p = position.ang.p,
            ang_y = position.ang.y,
            ang_r = position.ang.r,
            description = position.description
        })
    end
    
    ix.data.Set(dataKey, saveData)
    
    -- Обновляем ID в памяти
    for i, position in ipairs(self.spawnPositions[type]) do
        position.id = i
    end
end

-- Логирование в файлы данных
function PLUGIN:LogVehicleAction(player, vehicleType, vehicleName, position, action)
    if not IsValid(player) then return end
    
    local positionString = "Неизвестно"
    if position and position.x then
        positionString = string.format("%.0f, %.0f, %.0f", position.x, position.y, position.z)
    elseif type(position) == "string" then
        positionString = position
    end
    
    -- Загружаем существующие логи
    local logs = ix.data.Get("vcs_vehicle_logs", {})
    
    -- Добавляем новый лог
    local newLog = {
        id = #logs + 1,
        player_steamid = player:SteamID(),
        player_name = player:GetName(),
        vehicle_type = vehicleType,
        vehicle_name = vehicleName,
        spawn_position = positionString,
        action = action,
        timestamp = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    table.insert(logs, newLog)
    
    -- Ограничиваем количество логов (оставляем только последние 1000)
    if #logs > 1000 then
        table.remove(logs, 1)
    end
    
    -- Сохраняем логи обратно в файл
    ix.data.Set("vcs_vehicle_logs", logs)
    
    print("[VCS] Лог записан: " .. player:GetName() .. " " .. action .. " " .. vehicleName)
end





-- Спавн техники
function PLUGIN:SpawnVehicle(ply, vehicleType, vehicleName, spawnIndex)
    print("[VCS] SpawnVehicle вызван: " .. vehicleName .. " индекс " .. spawnIndex)
    
    -- Получаем данные о технике
    local vehicleData = self:GetVehicleDataByName(vehicleType, vehicleName)
    if not vehicleData then
        ply:Notify("Неизвестная техника!")
        print("[VCS] Ошибка: техника " .. vehicleName .. " не найдена")
        return false
    end
    
    -- Проверяем доступ игрока к технике
    if not self:CanPlayerAccessVehicle(ply, vehicleData) then
        ply:Notify("У вас нет доступа к этой технике!")
        print("[VCS] Ошибка: игрок " .. ply:GetName() .. " не имеет доступа к технике " .. vehicleName)
        return false
    end
    
    print("[VCS] Данные техники найдены: " .. vehicleData.class)
    
    -- Проверяем лимиты конкретной техники
    if not self:CheckVehicleLimit(vehicleData.class) then
        local currentCount = 0
        for _, vehicle in pairs(self.activeVehicles) do
            if vehicle.class == vehicleData.class and IsValid(vehicle.entity) then
                currentCount = currentCount + 1
            end
        end
        ply:Notify(string.format("Достигнут лимит техники %s! (%d/%d)", vehicleName, currentCount, vehicleData.maxActive))
        return false
    end
    
    -- Проверяем кулдаун
    if not self:CheckCooldown(ply, "terminal") then
        local remaining = self:GetCooldownRemaining(ply, "terminal")
        ply:Notify("Кулдаун еще активен! Осталось: " .. math.ceil(remaining) .. " сек.")
        return false
    end
    
    -- Получаем позицию спавна
    local positions = self:GetSpawnPositions(vehicleType)
    print("[VCS] Доступно позиций: " .. #positions .. ", запрашиваемый индекс: " .. spawnIndex)
    
    if not positions[spawnIndex] then
        ply:Notify("Неверная позиция спавна!")
        print("[VCS] Ошибка: позиция с индексом " .. spawnIndex .. " не найдена")
        return false
    end
    
    local spawnData = positions[spawnIndex]
    print("[VCS] Позиция спавна найдена: " .. spawnData.description)
    
    -- RP отыгрывание процесса вызова
    ply:SetAction("Передает запрос на вызов техники...", 5)
    
    -- Уведомляем окружающих
    local plyName = ply:GetName()
    local typeText = vehicleType == "air" and "воздушную" or "наземную"
    local rpMessage = plyName .. " запрашивает " .. typeText .. " технику: " .. vehicleName
    
    for k, v in pairs(player.GetAll()) do
        if v:GetPos():Distance(ply:GetPos()) <= 300 then
            v:Notify(rpMessage)
        end
    end
    
    timer.Simple(5, function()
        if not IsValid(ply) then 
            print("[VCS] Игрок больше не валиден")
            return 
        end
        
        print("[VCS] Создаем технику класса: " .. vehicleData.class)
        
        -- Создаем технику по указанному классу
        local vehicle = ents.Create(vehicleData.class)
        if not IsValid(vehicle) then
            -- Если класс не найден, создаем обычный автомобиль как резервный вариант
            print("[VCS] Класс " .. vehicleData.class .. " не найден, создаем резервный")
            vehicle = ents.Create("prop_vehicle_jeep")
            ply:Notify("Внимание: Использован резервный класс техники!")
            print("[VCS] Класс техники '" .. vehicleData.class .. "' не найден, создан prop_vehicle_jeep")
        end
        
        vehicle:SetModel(vehicleData.model)
        vehicle:SetPos(spawnData.pos)
        vehicle:SetAngles(spawnData.ang)
        vehicle:Spawn()
        vehicle:Activate()
        
        -- Проверяем, что техника успешно создалась
        if not IsValid(vehicle) then
            ply:Notify("Ошибка создания техники!")
            print("[VCS] Ошибка: техника не создалась")
            return false
        end
        
        print("[VCS] Техника создана успешно, ID: " .. vehicle:EntIndex())
        
        -- Добавляем в активные
        self:AddActiveVehicle(vehicle, vehicleType, ply, spawnData.pos, vehicleData.class, vehicleName)
        
        -- Устанавливаем кулдаун
        self:SetCooldown(ply, "terminal")
        
        -- Логируем
        self:LogVehicleAction(ply, vehicleType, vehicleName, spawnData.description, "spawned")
        
        -- Удаляем через время жизни
        if ix.configs.vcs.vehicleLifetime > 0 then
            timer.Simple(ix.configs.vcs.vehicleLifetime, function()
                if IsValid(vehicle) then
                    self:RemoveActiveVehicle(vehicle)
                    vehicle:Remove()
                    
                    -- Уведомляем игрока
                    if IsValid(ply) then
                        ply:Notify("Техника " .. vehicleName .. " была автоматически убрана (истек срок службы)")
                    end
                end
            end)
        end
        
        -- Финальное уведомление об успешном вызове
        ply:Notify("✓ Техника " .. vehicleName .. " успешно вызвана на позицию: " .. spawnData.description)
        
        -- RP сообщение о прибытии техники
        local arrivalMessage = "Техника " .. vehicleName .. " прибыла на позицию: " .. spawnData.description
        for k, v in pairs(player.GetAll()) do
            if v:GetPos():Distance(spawnData.pos) <= 500 then
                v:Notify(arrivalMessage)
            end
        end
    end)
    
    return true
end

-- Проверка близости к позиции спавна
function PLUGIN:IsPlayerNearSpawnPosition(player, vehicleType)
    local playerPos = player:GetPos()
    local positions = self:GetSpawnPositions(vehicleType)
    
    for i, spawnData in ipairs(positions) do
        if playerPos:Distance(spawnData.pos) <= ix.configs.vcs.maxDatapadDistance then
            return true, i
        end
    end
    
    return false, nil
end

-- ИСПРАВЛЕНО: Получение всех позиций для датападов (без ограничения расстояния)
function PLUGIN:GetNearbySpawnPositions(player, vehicleType)
    local playerPos = player:GetPos()
    local positions = self:GetSpawnPositions(vehicleType)
    local nearbyPositions = {}
    
    -- НОВОЕ: Возвращаем ВСЕ позиции для обычных датападов (без проверки расстояния)
    for i, spawnData in ipairs(positions) do
        local distance = playerPos:Distance(spawnData.pos)
        table.insert(nearbyPositions, {
            index = i,
            data = spawnData,
            distance = distance
        })
    end
    
    -- Сортируем по расстоянию (ближайшие первыми)
    table.sort(nearbyPositions, function(a, b)
        return a.distance < b.distance
    end)
    
    return nearbyPositions
end

-- Команды
ix.command.Add("vcs_spawnadd", {
    description = "Добавить позицию спавна техники",
    superAdminOnly = true,
    arguments = {
        ix.type.string -- air или ground
    },
    OnRun = function(self, client, vehicleType)
        if vehicleType ~= "air" and vehicleType ~= "ground" then
            client:Notify("Используйте 'air' или 'ground'")
            return
        end
        
        local pos = client:GetPos()
        local ang = client:GetAngles()
        ang.p = 0 -- Убираем наклон
        ang.r = 0
        
        local plugin = ix.plugin.Get("vehicle_call_system")
        if plugin then
            plugin:AddSpawnPosition(vehicleType, pos, ang, "Позиция спавна")
        end
        
        local typeText = vehicleType == "air" and "воздушной" or "наземной"
        client:Notify("Позиция спавна для " .. typeText .. " техники добавлена!")
    end
})

ix.command.Add("vcs_spawnremove", {
    description = "Удалить позицию спавна техники",
    superAdminOnly = true,
    arguments = {
        ix.type.string, -- air или ground
        ix.type.number  -- id позиции
    },
    OnRun = function(self, client, vehicleType, id)
        if vehicleType ~= "air" and vehicleType ~= "ground" then
            client:Notify("Используйте 'air' или 'ground'")
            return
        end
        
        local plugin = ix.plugin.Get("vehicle_call_system")
        if plugin then
            plugin:RemoveSpawnPosition(vehicleType, id)
        end
        
        local typeText = vehicleType == "air" and "воздушной" or "наземной"
        client:Notify("Позиция спавна для " .. typeText .. " техники удалена!")
    end
})

ix.command.Add("vcs_spawnlist", {
    description = "Показать все позиции спавна",
    adminOnly = true,
    OnRun = function(self, client)
        local plugin = ix.plugin.Get("vehicle_call_system")
        if not plugin then
            client:Notify("Плагин не найден!")
            return
        end
        
        local message = "Позиции спавна:\n\nВоздушная техника:\n"
        
        for i, spawnData in ipairs(plugin.spawnPositions.air) do
            message = message .. string.format("ID %d: %s (%.0f, %.0f, %.0f)\n", 
                spawnData.id, spawnData.description, spawnData.pos.x, spawnData.pos.y, spawnData.pos.z)
        end
        
        message = message .. "\nНаземная техника:\n"
        
        for i, spawnData in ipairs(plugin.spawnPositions.ground) do
            message = message .. string.format("ID %d: %s (%.0f, %.0f, %.0f)\n", 
                spawnData.id, spawnData.description, spawnData.pos.x, spawnData.pos.y, spawnData.pos.z)
        end
        
        client:Notify(message)
    end
})


-- Альтернативная команда с более коротким именем
ix.command.Add("vcsm", {
    description = "Открыть менеджер позиций VCS",
    superAdminOnly = true,
    OnRun = function(self, client)
        net.Start("VCS_OpenSpawnManager")
        net.Send(client)
    end
})

-- Полная команда для поиска
ix.command.Add("vcs_manager", {
    description = "Открыть полный интерфейс управления VCS",
    superAdminOnly = true,
    OnRun = function(self, client)
        net.Start("VCS_OpenSpawnManager")
        net.Send(client)
    end
})


-- Команда для просмотра текущих настроек VCS
ix.command.Add("vcs_info", {
    description = "Показать информацию о настройках VCS",
    adminOnly = true,
    OnRun = function(self, client)
        local plugin = ix.plugin.Get("vehicle_call_system")
        if not plugin then
            client:Notify("Плагин не найден!")
            return
        end
        
        local info = string.format([[
╔═══════════════════════════════════════╗
║          VEHICLE CALL SYSTEM          ║
╠═══════════════════════════════════════╣
║                                       ║
║ Время жизни техники: %4d сек          ║
║                                       ║
║ Кулдауны:                             ║
║                                       ║
║ • Терминалы: %3d сек                  ║
║                                       ║
║ Позиции спавна:                       ║
║ • Воздушная техника: %2d              ║
║ • Наземная техника: %2d               ║
║                                       ║
║ Активная техника: %2d                 ║
╚═══════════════════════════════════════╝]], 
            ix.configs.vcs.vehicleLifetime,
            ix.configs.vcs.cooldowns.terminal,
            #plugin.spawnPositions.air,
            #plugin.spawnPositions.ground,
            table.Count(plugin.activeVehicles)
        )
        
                 client:Notify(info)
     end
})



-- Сетевые функции
net.Receive("VCS_SpawnVehicle", function(len, player)
    local vehicleType = net.ReadString()
    local vehicleName = net.ReadString()
    local spawnIndex = net.ReadUInt(8)
    local deviceType = net.ReadString() -- "terminal"
    
    local plugin = ix.plugin.Get("vehicle_call_system")
    if not plugin then
        player:Notify("Плагин не найден!")
        return
    end
    
    print("[VCS] Запрос спавна: " .. vehicleName .. " типа " .. vehicleType .. " устройством " .. deviceType)
    
    if false then
        -- Проверяем близость к позиции спавна для датападов
        local isNear, nearestIndex = plugin:IsPlayerNearSpawnPosition(player, vehicleType)
        if not isNear then
            player:Notify("Вы слишком далеко от позиции спавна!")
            return
        end
        -- Если spawnIndex = 0, используем ближайшую позицию автоматически
        if spawnIndex == 0 then
            spawnIndex = nearestIndex
            print("[VCS] Автоматически выбрана ближайшая позиция: " .. spawnIndex)
        else
            -- Проверяем, что выбранная позиция в пределах досягаемости
            local positions = plugin:GetSpawnPositions(vehicleType)
            if positions[spawnIndex] then
                local distance = player:GetPos():Distance(positions[spawnIndex].pos)
                if distance > 10000 then
                    player:Notify("Выбранная позиция слишком далеко!")
                    return
                end
                print("[VCS] Использована выбранная позиция: " .. spawnIndex .. " (расстояние: " .. math.floor(distance) .. " м)")
            else
                player:Notify("Неверная позиция спавна!")
                return
            end
        end
        
    end
    
    -- Проверяем, что позиция существует
    local positions = plugin:GetSpawnPositions(vehicleType)
    if not positions[spawnIndex] then
        player:Notify("Неверная позиция спавна! Доступно позиций: " .. #positions)
        print("[VCS] Ошибка: позиция " .. spawnIndex .. " не найдена, всего позиций: " .. #positions)
        return
    end
    
    plugin:SpawnVehicle(player, vehicleType, vehicleName, spawnIndex)
end)

-- УБИРАЕМ АВТОМАТИЧЕСКИЕ ОТПРАВКИ И ДЕЛАЕМ ТОЛЬКО ПО ЗАПРОСУ
net.Receive("VCS_GetActiveVehicles", function(len, player)
    local plugin = ix.plugin.Get("vehicle_call_system")
    if not plugin then return end
    
    local activeVehicles = {}
    
    for index, vehicle in pairs(plugin.activeVehicles) do
        if IsValid(vehicle.entity) then
            table.insert(activeVehicles, {
                type = vehicle.type,
                name = vehicle.name,
                class = vehicle.class,
                spawner = IsValid(vehicle.spawner) and vehicle.spawner:GetName() or "Неизвестно",
                position = vehicle.position,
                spawnTime = vehicle.spawnTime
            })
        else
            plugin.activeVehicles[index] = nil
        end
    end
    
    -- Отправляем ТОЛЬКО запросившему игроку
    net.Start("VCS_SendActiveVehicles")
    net.WriteTable(activeVehicles)
    net.Send(player)
    
    print("[VCS] Отправлены данные о " .. #activeVehicles .. " активных ТС игроку " .. player:GetName())
end)

-- Новая функция для удаления техники по имени и типу
net.Receive("VCS_RemoveVehicle", function(len, player)
    local vehicleName = net.ReadString()
    local vehicleType = net.ReadString()
    
    local plugin = ix.plugin.Get("vehicle_call_system")
    if not plugin then return end
    
    print("[VCS] Запрос на удаление техники: " .. vehicleName .. " типа " .. vehicleType .. " от игрока " .. player:GetName())
    
    -- Ищем технику в активных
    local removedCount = 0
    for index, vehicle in pairs(plugin.activeVehicles) do
        if vehicle.name == vehicleName and vehicle.type == vehicleType and IsValid(vehicle.entity) then
            -- Логируем удаление
            plugin:LogVehicleAction(player, vehicleType, vehicleName, vehicle.position, "removed")
            
            -- Удаляем из активных
            plugin.activeVehicles[index] = nil
            
            -- Удаляем сущность
            vehicle.entity:Remove()
            removedCount = removedCount + 1
            
            print("[VCS] Удалена техника: " .. vehicleName .. " (ID: " .. index .. ")")
        end
    end
    
    if removedCount > 0 then
        player:Notify("✓ Удалено техники: " .. removedCount .. " ед. (" .. vehicleName .. ")")
        
        -- RP сообщение о принудительном отзыве техники
        local plyName = player:GetName()
        local typeText = vehicleType == "air" and "воздушную" or "наземную"
        local rpMessage = plyName .. " принудительно отозвал " .. typeText .. " технику: " .. vehicleName
        
        for k, v in pairs(player.GetAll()) do
            if v:GetPos():Distance(player:GetPos()) <= 300 then
                v:Notify(rpMessage)
            end
        end
    else        player:Notify("✗ Техника " .. vehicleName .. " не найдена среди активной техники!")
    end
end)

net.Receive("VCS_GetLogs", function(len, player)
    local vehicleType = net.ReadString()
    
    print("[VCS] Запрос логов для типа: " .. vehicleType)
    
    -- Загружаем логи из файла
    local allLogs = ix.data.Get("vcs_vehicle_logs", {})
    local filteredLogs = {}
    
    -- Фильтруем логи по типу техники
    for _, log in ipairs(allLogs) do
        if log.vehicle_type == vehicleType then
            table.insert(filteredLogs, log)
        end
    end
    
    -- Сортируем по времени (новые первыми) и ограничиваем до 50
    table.sort(filteredLogs, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    if #filteredLogs > 50 then
        local limitedLogs = {}
        for i = 1, 50 do
            table.insert(limitedLogs, filteredLogs[i])
        end
        filteredLogs = limitedLogs
    end
    
    print("[VCS] Получено логов: " .. #filteredLogs)
    print("[VCS] Отправляем " .. #filteredLogs .. " логов игроку " .. player:GetName())
    
    net.Start("VCS_SendLogs")
    net.WriteTable(filteredLogs)
    net.Send(player)
end)

-- Получение позиций спавна для меню
net.Receive("VCS_GetSpawnPositions", function(len, player)
    local plugin = ix.plugin.Get("vehicle_call_system")
    if not plugin then 
        print("[VCS] Ошибка: плагин не найден при запросе позиций")
        return 
    end
    
    print("[VCS] Отправляем позиции спавна игроку " .. player:GetName())
    print("[VCS] Воздушных позиций: " .. #plugin.spawnPositions.air)
    print("[VCS] Наземных позиций: " .. #plugin.spawnPositions.ground)
    
    net.Start("VCS_SendSpawnPositions")
    net.WriteTable(plugin.spawnPositions)
    net.Send(player)
end)

-- Добавление позиции спавна через меню
net.Receive("VCS_AddSpawnPosition", function(len, player)
    if not player:IsSuperAdmin() then return end
    
    local vehicleType = net.ReadString()
    local x = net.ReadFloat()
    local y = net.ReadFloat()
    local z = net.ReadFloat()
    local ang_p = net.ReadFloat()
    local ang_y = net.ReadFloat()
    local ang_r = net.ReadFloat()
    local description = net.ReadString()
    
    local plugin = ix.plugin.Get("vehicle_call_system")
    if not plugin then return end
    
    local pos = Vector(x, y, z)
    local ang = Angle(ang_p, ang_y, ang_r)
    
    plugin:AddSpawnPosition(vehicleType, pos, ang, description)
    
    -- Отправляем обновленные позиции обратно
    timer.Simple(0.1, function()
        if IsValid(player) then
            net.Start("VCS_SendSpawnPositions")
            net.WriteTable(plugin.spawnPositions)
            net.Send(player)
        end
    end)
    
    player:Notify("Позиция спавна добавлена: " .. description)
end)

-- Удаление позиции спавна через меню
net.Receive("VCS_RemoveSpawnPosition", function(len, player)
    if not player:IsSuperAdmin() then return end
    
    local vehicleType = net.ReadString()
    local id = net.ReadUInt(16)
    
    local plugin = ix.plugin.Get("vehicle_call_system")
    if not plugin then return end
    
    plugin:RemoveSpawnPosition(vehicleType, id)
    
    -- Отправляем обновленные позиции обратно
    timer.Simple(0.1, function()
        if IsValid(player) then
            net.Start("VCS_SendSpawnPositions")
            net.WriteTable(plugin.spawnPositions)
            net.Send(player)
        end
    end)
    
    player:Notify("Позиция спавна удалена!")
end)

-- Редактирование позиции спавна через меню
net.Receive("VCS_EditSpawnPosition", function(len, player)
    if not player:IsSuperAdmin() then return end
    
    local vehicleType = net.ReadString()
    local id = net.ReadUInt(16)
    local x = net.ReadFloat()
    local y = net.ReadFloat()
    local z = net.ReadFloat()
    local ang_p = net.ReadFloat()
    local ang_y = net.ReadFloat()
    local ang_r = net.ReadFloat()
    local description = net.ReadString()
    
    local plugin = ix.plugin.Get("vehicle_call_system")
    if not plugin then return end
    
    -- Находим позицию по ID и обновляем её
    for i, position in ipairs(plugin.spawnPositions[vehicleType]) do
        if position.id == id then
            -- Обновляем данные в памяти
            position.pos = Vector(x, y, z)
            position.ang = Angle(ang_p, ang_y, ang_r)
            position.description = description
            
            -- Пересохраняем весь массив в файл
            local dataKey = vehicleType == "air" and "vcs_air_positions" or "vcs_ground_positions"
            local saveData = {}
            
            for _, pos in ipairs(plugin.spawnPositions[vehicleType]) do
                table.insert(saveData, {
                    x = pos.pos.x,
                    y = pos.pos.y,
                    z = pos.pos.z,
                    ang_p = pos.ang.p,
                    ang_y = pos.ang.y,
                    ang_r = pos.ang.r,
                    description = pos.description
                })
            end
            
            ix.data.Set(dataKey, saveData)
            break
        end
    end
    
    -- Отправляем обновленные позиции обратно
    timer.Simple(0.1, function()
        if IsValid(player) then
            net.Start("VCS_SendSpawnPositions")
            net.WriteTable(plugin.spawnPositions)
            net.Send(player)
        end
    end)
    
    player:Notify("Позиция спавна обновлена!")
end)

-- ИСПРАВЛЕНО: Получение всех позиций для датапада (без ограничения расстояния)
net.Receive("VCS_GetNearbyPositions", function(len, player)
    local vehicleType = net.ReadString()
    
    local plugin = ix.plugin.Get("vehicle_call_system")
    if not plugin then 
        print("[VCS] Ошибка: плагин не найден!")
        return 
    end
    
    -- ИСПРАВЛЕНО: Получаем ВСЕ позиции для обычных датападов
    local nearbyPositions = plugin:GetNearbySpawnPositions(player, vehicleType)
    
    print("[VCS] Отправляем позиций для " .. player:GetName() .. " (" .. vehicleType .. "): " .. #nearbyPositions)
    
    -- Отправляем данные клиенту
    net.Start("VCS_SendNearbyPositions")
    net.WriteString(vehicleType)
    net.WriteTable(nearbyPositions)
    net.Send(player)
    
    -- Отладочная информация
    for i, pos in ipairs(nearbyPositions) do
        print("[VCS] Позиция " .. i .. ": " .. pos.data.description .. " (расстояние: " .. math.floor(pos.distance) .. "м)")
    end
end)

-- Функция очистки старых логов (старше 7 дней)
function PLUGIN:CleanupOldLogs()
    local logFile = "helix/starwarsrp/vcs_vehicle_logs.txt"
    
    if not file.Exists(logFile, "DATA") then
        print("[VCS] Файл логов не найден для очистки")
        return
    end
    
    local content = file.Read(logFile, "DATA")
    if not content then
        print("[VCS] Ошибка чтения файла логов")
        return
    end
    
    local lines = string.Split(content, "\n")
    local newLines = {}
    local currentTime = os.time()
    local sevenDaysAgo = currentTime - (7 * 24 * 60 * 60) -- 7 дней в секундах
    local removedCount = 0
    
    for _, line in ipairs(lines) do
        if line ~= "" then
            -- Парсим дату из строки лога формата "2025-01-27 15:30:45"
            local dateStr = string.match(line, "(%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d)")
            if dateStr then
                local year, month, day, hour, min, sec = dateStr:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
                if year and month and day and hour and min and sec then
                    local logTime = os.time({
                        year = tonumber(year),
                        month = tonumber(month),
                        day = tonumber(day),
                        hour = tonumber(hour),
                        min = tonumber(min),
                        sec = tonumber(sec)
                    })
                    
                    -- Оставляем только логи новее 7 дней
                    if logTime >= sevenDaysAgo then
                        table.insert(newLines, line)
                    else
                        removedCount = removedCount + 1
                    end
                else
                    -- Если не можем парсить дату, оставляем строку
                    table.insert(newLines, line)
                end
            else
                -- Если в строке нет даты, оставляем её
                table.insert(newLines, line)
            end
        end
    end
    
    -- Записываем очищенные логи обратно в файл
    local newContent = table.concat(newLines, "\n")
    file.Write(logFile, newContent)
    
    if removedCount > 0 then
        print("[VCS] Очищено " .. removedCount .. " старых записей логов (старше 7 дней)")
        
        -- Записываем лог об очистке
        self:WriteLog("SYSTEM", "cleanup", "system", "log_cleanup", "server", "Очищено " .. removedCount .. " старых записей логов")
    else
        print("[VCS] Записей логов старше 7 дней не найдено")
    end
end

-- Очистка неактивной техники БЕЗ автоматических отправок всем
timer.Create("VCS_CleanupVehicles", 30, 0, function()
    local plugin = ix.plugin.Get("vehicle_call_system")
    if not plugin then return end
    
    local cleaned = false
    for index, vehicle in pairs(plugin.activeVehicles) do
        if not IsValid(vehicle.entity) then
            plugin.activeVehicles[index] = nil
            cleaned = true
        end
    end
    
    if cleaned then
        print("[VCS] Очищена неактивная техника из списка")
    end
end)

-- Таймер очистки старых логов (каждые 24 часа)
timer.Create("VCS_LogCleanup", 86400, 0, function()
    local plugin = ix.plugin.Get("vehicle_call_system")
    if not plugin then return end
    
    plugin:CleanupOldLogs()
end)