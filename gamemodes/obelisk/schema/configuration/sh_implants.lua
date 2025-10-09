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
        bonus = "spring_joints", -- Эффекты прописываются разрабом :P
        limb = "ноги"
    },
}

