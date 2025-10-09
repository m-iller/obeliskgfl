ix.configs = ix.configs or {}

-- Конфигурация системы вызова аирдропов
ix.configs.airbrop = {
    -- Кулдаун между вызовами (в секундах)
    cooldown = 60,  -- 1 минута
    
    -- Время жизни аирдропа по умолчанию (в секундах, 0 = бесконечно)
    defaultLifetime = 1800,  -- 30 минут
    
    -- Конфигурация фракций
    factions = {
        -- Фракция 1 (например, Повстанцы)
        faction1 = {
            name = "Повстанцы",
            factionID = FACTION_CITIZEN,  -- ID фракции для доступа к терминалу (можно указать одну или массив {FACTION_CITIZEN, FACTION_OTA})
            allowedTargetFactions = {FACTION_CITIZEN, FACTION_OTA},  -- ID фракций игроков, которых можно выбирать как цель
            
            -- Заготовленные позиции для вызова аирдропов
            -- Используйте команду "ix_getpos" в консоли чтобы узнать текущие координаты
            positions = {
                {
                    name = "Площадь центра города",
                    pos = Vector(0, 0, 0)  -- Замените на реальные координаты
                },
                {
                    name = "Склады",
                    pos = Vector(100, 200, 50)  -- Замените на реальные координаты
                },
                {
                    name = "Окраины",
                    pos = Vector(-500, 300, 0)  -- Замените на реальные координаты
                }
            },
            
            -- Доступные типы аирдропов
            airdrops = {
                {
                    type = "small_supply",
                    name = "Малый грузовой аирдроп",
                    description = "Небольшой ящик с боеприпасами",
                    entityClass = "sw_airdrop_v3",  -- Класс энтити из папки airdrope
                    maxActive = 3,  -- Максимум активных одновременно
                    spawnHeight = 1000,  -- Высота спавна над целью
                    lifetime = 1800  -- Время жизни в секундах (0 = бесконечно)
                },
                {
                    type = "large_supply",
                    name = "Большой грузовой аирдроп",
                    description = "Крупный контейнер с припасами",
                    entityClass = "sw_airdrop_large_v3",
                    maxActive = 2,
                    spawnHeight = 1200,
                    lifetime = 2400
                }
            }
        },
        
        -- Фракция 2 (например, Альянс)
        faction2 = {
            name = "Альянс",
            factionID = FACTION_MPF,  -- ID фракции для доступа к терминалу
            allowedTargetFactions = {FACTION_MPF, FACTION_OTA},  -- ID фракций игроков, которых можно выбирать как цель
            
            -- Заготовленные позиции для вызова аирдропов
            positions = {
                {
                    name = "Штаб-квартира",
                    pos = Vector(1000, 500, 100)  -- Замените на реальные координаты
                },
                {
                    name = "Периметр",
                    pos = Vector(800, -200, 50)  -- Замените на реальные координаты
                }
            },
            
            -- Доступные типы аирдропов
            airdrops = {
                {
                    type = "small_supply",
                    name = "Малый грузовой аирдроп",
                    description = "Небольшой ящик с боеприпасами",
                    entityClass = "sw_airdrop_v3",
                    maxActive = 3,
                    spawnHeight = 1000,
                    lifetime = 1800
                },
                {
                    type = "large_supply",
                    name = "Большой грузовой аирдроп",
                    description = "Крупный контейнер с припасами",
                    entityClass = "sw_airdrop_large_v3",
                    maxActive = 2,
                    spawnHeight = 1200,
                    lifetime = 2400
                }
            }
        }
    }
}

--[[
    ИНСТРУКЦИЯ ПО НАСТРОЙКЕ ФРАКЦИЙ:
    
    1. Узнайте ID ваших фракций. Они обычно определены в schema/factions/*.lua как константы:
       FACTION_CITIZEN = 1
       FACTION_MPF = 2
       FACTION_OTA = 3
       и т.д.
    
    2. Для factionID можно указать:
       - Одну фракцию: factionID = FACTION_CITIZEN
       - Несколько фракций: factionID = {FACTION_CITIZEN, FACTION_OTA}
    
    3. Для allowedTargetFactions укажите массив ID фракций, чьих игроков можно выбирать как цель.
    
    4. Если не знаете ID фракций, зайдите в игру и введите в консоль: lua_run PrintTable(ix.faction.teams)
    
    Пример настройки:
    
    faction1 = {
        name = "Сопротивление",
        factionID = {1, 3, 5},  -- Несколько фракций имеют доступ
        allowedTargetFactions = {1, 3, 5, 7},  -- Можно вызывать на эти фракции
        airdrops = { ... }
    }
]]