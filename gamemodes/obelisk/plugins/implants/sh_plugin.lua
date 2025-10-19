PLUGIN.name = "Implants System"
PLUGIN.description = "Система имплантов с админским меню"
PLUGIN.author = "ObeliskStdDev"
PLUGIN.version = "1.0.1"

-- Конфиг теперь находится в схеме

ix.flag.Add("I", "Доступ к системе имплантов", nil, true)

-- Чат-команда для открытия меню имплантов
    ix.command.Add("implants", {
        description = "Открыть меню имплантов",
        OnRun = function(self, client)
            if client:GetCharacter():HasFlags("I") then
                net.Start("ixImplantsOpenMenu")
                net.Send(client)
            else
                client:Notify("У вас нет доступа к этой команде")
            end
        end
    })

if CLIENT then
    -- Обработчик сетевого сообщения для открытия меню
    net.Receive("ixImplantsOpenMenu", function()
        -- Проверяем, существует ли панель и валидна ли она
        if not IsValid(ix.gui.implants) then
            ix.gui.implants = vgui.Create("ixImplantsMenu")
        end
        
        ix.gui.implants:SetVisible(true)
        ix.gui.implants:MakePopup()
    end)
end

ix.util.Include("cl_menu.lua")
ix.util.Include("sv_network.lua")
ix.util.Include("sv_hooks.lua")
ix.util.Include("sv_bonuses.lua")

-- Функция для получения имплантов персонажа
function ix.GetCharacterImplants(character)
    return character:GetData("implants", {})
end

-- Функция для установки импланта персонажу
function ix.SetCharacterImplant(character, limb, implant)
    local currentImplants = ix.GetCharacterImplants(character)
    
    -- Получаем текущий имплант для удаления его бонусов
    local currentImplant = currentImplants[limb]
    
    if implant == "НЕТ" then
        -- Удаляем бонусы текущего импланта перед снятием
        if currentImplant and currentImplant ~= "НЕТ" then
            if SERVER then
                ix.RemoveImplantBonuses(character, limb, currentImplant)
            end
        end
        currentImplants[limb] = nil
    else
        -- Удаляем бонусы текущего импланта перед установкой нового
        if currentImplant and currentImplant ~= "НЕТ" then
            if SERVER then
                ix.RemoveImplantBonuses(character, limb, currentImplant)
            end
        end
        
        currentImplants[limb] = implant
        
        -- Применяем бонусы нового импланта сразу при установке
        if SERVER then
            local implantData = ix.configs.implants[implant]
            if implantData then
                local bonuses = implantData.bonuses or (implantData.bonus and {implantData.bonus}) or {}
                for _, bonus in ipairs(bonuses) do
                    print("[Implants] Применяем бонус:", bonus, "для импланта:", implant, "на конечность:", limb)
                    hook.Run("ImplantBonusApplied", character, limb, implant, bonus)
                end
            end
            
            -- Если игрок находится в игре, применяем бонусы немедленно
            local client = character:GetPlayer()
            if IsValid(client) and client:Alive() then
                timer.Simple(0.1, function()
                    if IsValid(client) and client:GetCharacter() == character then
                        local implantData = ix.configs.implants[implant]
                        if implantData then
                            local bonuses = implantData.bonuses or (implantData.bonus and {implantData.bonus}) or {}
                            for _, bonus in ipairs(bonuses) do
                                print("[Implants] Применяем бонус (отложенно):", bonus, "для импланта:", implant, "на конечность:", limb)
                                hook.Run("ImplantBonusApplied", character, limb, implant, bonus)
                            end
                        end
                    end
                end)
            end
        end
    end
    
    -- Сохраняем в данные персонажа
    character:SetData("implants", currentImplants)
end

-- Применяем бонусы имплантов при спавне персонажа
if SERVER then  
    -- Функция для удаления всех бонусов импланта
    function ix.RemoveImplantBonuses(character, limb, implant)
        local implantData = ix.configs.implants[implant]
        if implantData then
            -- Поддерживаем как старый формат (bonus), так и новый (bonuses)
            local bonuses = implantData.bonuses or (implantData.bonus and {implantData.bonus}) or {}
            
            -- Удаляем все бонусы импланта
            for _, bonus in ipairs(bonuses) do
                print("[Implants] Удаляем бонус:", bonus, "для импланта:", implant, "с конечности:", limb)
                hook.Run("ImplantBonusRemoved", character, limb, implant)
            end
        end
    end
end

if SERVER then
    MsgC(Color(0, 180, 255), "[OBL_Plugins] ", Color(255,255,255), "Плагин ", Color(0,180,255), PLUGIN.name, Color(255,255,255), " успешно загружен! ", Color(0,255,0), "Версия " .. PLUGIN.version .. "\n")
else
    MsgC(Color(0, 180, 255), "[OBL_Plugins] ", Color(255,255,255), "Плагин ", Color(0,180,255), PLUGIN.name, Color(255,255,255), " успешно загружен на клиенте! ", Color(0,255,0), "Версия " .. PLUGIN.version .. "\n")
end

