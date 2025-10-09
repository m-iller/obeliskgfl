ix.configs = ix.configs or {}

-- Список доступных конечностей
ix.configs.implantLimbs = {
    "голова",
    "глаза", 
    "грудь",
    "руки",
    "ноги"
}

-- Команда для открытия меню имплантов
ix.configs.implantCommand = "implants"

ix.configs.implants = {
    ["Пружинные суставы"] = {
        description = "Увеличивает скорость бега и прыжков",
        bonuses = {"spring_joints"}, -- Массив бонусов для поддержки множественных эффектов
        limb = "ноги"
    },
    ["Улучшенные конечности"] = {
        description = "Комплексное улучшение конечностей с множественными бонусами",
        bonuses = {"spring_joints", "enhanced_strength"}, -- Пример с несколькими бонусами
        limb = "ноги"
    },
    ["Скоростной имплант"] = {
        description = "Значительно увеличивает скорость передвижения",
        bonuses = {"speed_boost"},
        limb = "ноги"
    },
    ["Прыжковый имплант"] = {
        description = "Увеличивает высоту и дальность прыжков",
        bonuses = {"jump_boost"},
        limb = "ноги"
    },
    ["Имплант здоровья"] = {
        description = "Увеличивает максимальное здоровье персонажа",
        bonuses = {"health_boost"},
        limb = "грудь"
    },
    ["Защитный имплант"] = {
        description = "Уменьшает получаемый урон",
        bonuses = {"damage_resistance"},
        limb = "грудь"
    },
    ["Боевой имплант"] = {
        description = "Увеличивает наносимый урон",
        bonuses = {"damage_boost"},
        limb = "руки"
    },
    ["Амортизационный имплант"] = {
        description = "Уменьшает урон от падений",
        bonuses = {"fall_damage_reduction"},
        limb = "ноги"
    },
    ["Комплексный имплант ног"] = {
        description = "Комбинированное улучшение ног: скорость, прыжки и защита от падений",
        bonuses = {"speed_boost", "jump_boost", "fall_damage_reduction"},
        limb = "ноги"
    },
    ["Комплексный имплант груди"] = {
        description = "Комбинированное улучшение груди: здоровье и защита",
        bonuses = {"health_boost", "damage_resistance"},
        limb = "грудь"
    },
}

