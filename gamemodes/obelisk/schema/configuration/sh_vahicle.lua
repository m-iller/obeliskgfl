ix.configs = ix.configs or {}

-- Конфигурация системы вызова техники (VCS)
ix.configs.vcs = {
    -- Кулдауны (в секундах)
    cooldowns = {
        terminal = 30          -- 30 секунд для терминалов
    },
    
    -- Время жизни техники (в секундах, 0 = бесконечно)
    vehicleLifetime = 1800,  -- 30 минут
    
    -- Доступная техника с индивидуальными лимитами
    vehicles = {
        air = {
            {
                name = "Rebel Helicopter",
                model = "models/hunter/blocks/cube075x075x075.mdl", 
                class = "lvs_helicopter_rebel",
                description = "Вертолет повстанцев",
                maxActive = 4
            },
            {
                name = "Combine Helicopter",
                model = "models/hunter/blocks/cube075x075x075.mdl", 
                class = "lvs_helicopter_combine",
                description = "Вертолет Альянса",
                maxActive = 4
            }
        },
        ground = {
            {
                name = "BMW R75",
                model = "models/hunter/blocks/cube075x075x075.mdl", 
                class = "lvs_wheeldrive_bmw_r75",
                description = "Мотоцикл с коляской",
                maxActive = 4
            }
        }
    }
}   