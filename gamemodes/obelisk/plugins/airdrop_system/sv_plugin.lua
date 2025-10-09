-- Серверная часть плагина Airdrop System
local PLUGIN = PLUGIN

-- Сетевые строки
util.AddNetworkString("ADS_OpenTerminal")
util.AddNetworkString("ADS_RequestAirdrop")
util.AddNetworkString("ADS_GetPlayerList")
util.AddNetworkString("ADS_PlayerListResponse")

-- Функция для создания аирдропа
function PLUGIN:CreateAirdrop(airdropType, position, faction, spawner)
    -- Получаем данные аирдропа
    local airdropData = self:GetAirdropDataByType(faction, airdropType)
    if not airdropData then
        print("[ADS] Ошибка: тип аирдропа не найден - " .. tostring(airdropType))
        return false
    end
    
    -- Проверяем лимит
    if not self:CheckAirdropLimit(airdropType, faction) then
        print("[ADS] Достигнут лимит аирдропов типа " .. airdropType)
        return false
    end
    
    -- Создаем энтити аирдропа
    local airdrop = ents.Create(airdropData.entityClass)
    if not IsValid(airdrop) then
        print("[ADS] Ошибка: не удалось создать энтити " .. airdropData.entityClass)
        return false
    end
    
    -- Устанавливаем позицию высоко в воздухе
    local spawnPos = Vector(position.x, position.y, position.z + (airdropData.spawnHeight or 1000))
    airdrop:SetPos(spawnPos)
    airdrop:SetAngles(Angle(0, 0, 0))
    airdrop:Spawn()
    airdrop:Activate()
    
    -- Устанавливаем владельца
    if IsValid(spawner) then
        airdrop.Owner = spawner
    end
    
    -- Добавляем в активные аирдропы
    self:AddActiveAirdrop(airdrop, airdropType, spawner, position, faction)
    
    -- Удаляем аирдроп через указанное время (если установлено)
    local lifetime = airdropData.lifetime or ix.configs.airbrop.defaultLifetime or 0
    if lifetime > 0 then
        timer.Simple(lifetime, function()
            if IsValid(airdrop) then
                airdrop:Remove()
            end
        end)
    end
    
    -- Обработчик удаления
    airdrop:CallOnRemove("ADS_RemoveFromActive", function(ent)
        self:RemoveActiveAirdrop(ent)
    end)
    
    print("[ADS] Создан аирдроп типа " .. airdropType .. " на позиции " .. tostring(position))
    return true, airdrop
end

-- Получение списка игроков для вызова
net.Receive("ADS_GetPlayerList", function(len, client)
    if not IsValid(client) then return end
    
    local factionKey = net.ReadString()
    
    -- Проверяем доступ
    local plugin = ix.plugin.Get("airdrop_system")
    if not plugin or not plugin:CanPlayerAccessFaction(client, factionKey) then
        return
    end
    
    -- Получаем конфигурацию фракции
    local factionConfig = ix.configs.airbrop.factions[factionKey]
    if not factionConfig then return end
    
    -- Собираем список игроков из разрешенных фракций
    local playerList = {}
    
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local char = ply:GetCharacter()
            if char then
                local playerFaction = char:GetFaction()
                local hasAccess = false
                
                -- Проверяем, принадлежит ли игрок к одной из разрешенных фракций
                if factionConfig.allowedTargetFactions then
                    for _, allowedFactionID in ipairs(factionConfig.allowedTargetFactions) do
                        if playerFaction == allowedFactionID then
                            hasAccess = true
                            break
                        end
                    end
                end
                
                if hasAccess then
                    -- Получаем название фракции игрока
                    local factionTable = ix.faction.Get(playerFaction)
                    local factionName = factionTable and factionTable.name or "Неизвестная фракция"
                    
                    table.insert(playerList, {
                        name = ply:GetName(),
                        steamID = ply:SteamID(),
                        factionID = playerFaction,
                        factionName = factionName
                    })
                end
            end
        end
    end
    
    -- Отправляем список клиенту
    net.Start("ADS_PlayerListResponse")
    net.WriteTable(playerList)
    net.Send(client)
end)

-- Обработчик запроса на вызов аирдропа
net.Receive("ADS_RequestAirdrop", function(len, client)
    if not IsValid(client) then return end
    
    local plugin = ix.plugin.Get("airdrop_system")
    if not plugin then return end
    
    local airdropType = net.ReadString()
    local faction = net.ReadString()
    local targetType = net.ReadString() -- "position" или "player"
    local targetData = net.ReadTable()
    
    -- Проверяем доступ игрока
    if not plugin:CanPlayerAccessFaction(client, faction) then
        client:Notify("Доступ запрещён: недостаточно прав")
        return
    end
    
    -- Проверяем кулдаун
    if not plugin:CheckCooldown(client, faction) then
        local remaining = plugin:GetCooldownRemaining(client, faction)
        client:Notify("Перезарядка! Осталось: " .. math.ceil(remaining) .. " сек.")
        return
    end
    
    -- Определяем позицию вызова
    local spawnPosition
    if targetType == "position" then
        spawnPosition = Vector(targetData.x, targetData.y, targetData.z)
    elseif targetType == "player" then
        local targetPlayer = player.GetBySteamID(targetData.steamID)
        if IsValid(targetPlayer) then
            spawnPosition = targetPlayer:GetPos()
        else
            client:Notify("Целевой игрок не найден")
            return
        end
    else
        client:Notify("Неверный тип цели")
        return
    end
    
    -- Проверяем валидность позиции
    if not spawnPosition then
        client:Notify("Не удалось определить позицию вызова")
        return
    end
    
    -- Создаем аирдроп
    local success, airdrop = plugin:CreateAirdrop(airdropType, spawnPosition, faction, client)
    
    if success then
        -- Устанавливаем кулдаун
        plugin:SetCooldown(client, faction)
        
        -- Уведомляем игрока
        client:Notify("Аирдроп вызван! Прибытие через несколько секунд...")
        
        -- Уведомляем окружающих игроков
        local factionConfig = ix.configs.airbrop.factions[faction]
        local factionName = factionConfig.name or faction
        local message = client:GetName() .. " вызвал аирдроп (" .. factionName .. ")"
        
        for k, v in pairs(player.GetAll()) do
            if v:GetPos():Distance(client:GetPos()) <= 500 then
                v:Notify(message)
            end
        end
    else
        client:Notify("Не удалось вызвать аирдроп (возможно достигнут лимит)")
    end
end)

-- Очистка старых аирдропов
hook.Add("Think", "ADS_CleanupOldAirdrops", function()
    if not PLUGIN then return end
    
    for entIndex, airdropData in pairs(PLUGIN.activeAirdrops) do
        if not IsValid(airdropData.entity) then
            PLUGIN.activeAirdrops[entIndex] = nil
        end
    end
end)

