-- Единый обработчик бонусов имплантов
-- Все бонусы обрабатываются в одном месте для удобства управления

if SERVER then
    -- Хук для применения бонусов имплантов
    hook.Add("ImplantBonusApplied", "ixImplantsBonuses", function(character, limb, implant, bonus)
        local client = character:GetPlayer()
        if not IsValid(client) then return end
        
        print("[Implants] Применяем бонус:", bonus, "для импланта:", implant, "на конечность:", limb)
        
        if bonus == "speed_boost" then
            -- Повышение скорости
            client:SetWalkSpeed(client:GetWalkSpeed() * 10)
            client:SetRunSpeed(client:GetRunSpeed() * 10)
            client:Notify("Повышение скорости активировано! Увеличена скорость передвижения.")
            
        elseif bonus == "jump_boost" then
            -- Повышение прыжка
            client:SetJumpPower(client:GetJumpPower() * 1.6)
            client:Notify("Повышение прыжка активировано! Увеличена высота прыжков.")
            
        elseif bonus == "health_boost" then
            -- Увеличение HP
            local currentHealth = client:Health()
            local maxHealth = client:GetMaxHealth()
            local newMaxHealth = maxHealth * 1.5
            
            client:SetMaxHealth(newMaxHealth)
            
            -- Восстанавливаем здоровье пропорционально
            local healthRatio = currentHealth / maxHealth
            client:SetHealth(newMaxHealth * healthRatio)
            
            -- Устанавливаем флаг для отслеживания
            character:SetData("ixHealthBoostActive", true)
            client:Notify("Увеличение HP активировано! Максимальное здоровье увеличено.")
            
        elseif bonus == "damage_boost" then
            -- Повышение урона
            character:SetData("ixDamageMultiplier", 1.5) -- Увеличиваем урон на 50%
            client:Notify("Повышение урона активировано! Наносимый урон увеличен.")
            
        elseif bonus == "damage_resistance" then
            -- Сопротивление урону
            character:SetData("ixDamageResistance", 0.6) -- Уменьшаем урон на 40%
            client:Notify("Сопротивление урону активировано! Получаемый урон уменьшен.")
            
        elseif bonus == "fall_damage_reduction" then
            -- Уменьшение урона от падения
            character:SetData("ixFallDamageReduction", 0.3) -- Уменьшаем урон от падения на 70%
            client:Notify("Уменьшение урона от падения активировано! Урон от падений уменьшен.")
            
        elseif bonus == "spring_joints" then
            -- Пружинные суставы (комбинированный бонус)
            -- Увеличиваем скорость бега
            client:SetWalkSpeed(client:GetWalkSpeed() * 10)
            client:SetRunSpeed(client:GetRunSpeed() * 10)
            
            -- Увеличиваем высоту прыжка
            client:SetJumpPower(client:GetJumpPower() * 1.5)
            
            -- Уменьшаем урон от падений
            character:SetData("ixFallDamageReduction", 0.7)
            
            client:Notify("Пружинные суставы активированы! Увеличена скорость и высота прыжков.")
            
        else
            print("[Implants] Неизвестный бонус:", bonus)
        end
    end)
    
    -- Хук для удаления бонусов имплантов
    hook.Add("ImplantBonusRemoved", "ixImplantsBonuses", function(character, limb, implant)
        local client = character:GetPlayer()
        if not IsValid(client) then return end
        
        print("[Implants] Удаляем бонус для импланта:", implant, "с конечности:", limb)
        
        -- Определяем тип бонуса по названию импланта
        local implantData = ix.configs.implants[implant]
        if not implantData then return end
        
        local bonuses = implantData.bonuses or (implantData.bonus and {implantData.bonus}) or {}
        
        for _, bonus in ipairs(bonuses) do
            if bonus == "speed_boost" then
                -- Убираем повышение скорости
                client:SetWalkSpeed(client:GetWalkSpeed() / 10)
                client:SetRunSpeed(client:GetRunSpeed() / 10)
                client:Notify("Повышение скорости деактивировано.")
                
            elseif bonus == "jump_boost" then
                -- Убираем повышение прыжка
                client:SetJumpPower(client:GetJumpPower() / 1.6)
                client:Notify("Повышение прыжка деактивировано.")
                
            elseif bonus == "health_boost" then
                -- Убираем увеличение HP
                if character:GetData("ixHealthBoostActive", false) then
                    local currentHealth = client:Health()
                    local maxHealth = client:GetMaxHealth()
                    local newMaxHealth = maxHealth / 1.5
                    
                    client:SetMaxHealth(newMaxHealth)
                    
                    -- Восстанавливаем здоровье пропорционально
                    local healthRatio = currentHealth / maxHealth
                    client:SetHealth(math.min(newMaxHealth * healthRatio, newMaxHealth))
                    
                    character:SetData("ixHealthBoostActive", false)
                    client:Notify("Увеличение HP деактивировано.")
                end
                
            elseif bonus == "damage_boost" then
                -- Убираем повышение урона
                local multiplier = character:GetData("ixDamageMultiplier", 1.0)
                if multiplier > 1.0 then
                    character:SetData("ixDamageMultiplier", 1.0)
                    client:Notify("Повышение урона деактивировано.")
                end
                
            elseif bonus == "damage_resistance" then
                -- Убираем сопротивление урону
                local resistance = character:GetData("ixDamageResistance", 1.0)
                if resistance < 1.0 then
                    character:SetData("ixDamageResistance", 1.0)
                    client:Notify("Сопротивление урону деактивировано.")
                end
                
            elseif bonus == "fall_damage_reduction" then
                -- Убираем уменьшение урона от падения
                local reduction = character:GetData("ixFallDamageReduction", 1.0)
                if reduction < 1.0 then
                    character:SetData("ixFallDamageReduction", 1.0)
                    client:Notify("Уменьшение урона от падения деактивировано.")
                end
                
            elseif bonus == "spring_joints" then
                -- Убираем пружинные суставы
                client:SetWalkSpeed(client:GetWalkSpeed() / 10)
                client:SetRunSpeed(client:GetRunSpeed() / 10)
                client:SetJumpPower(client:GetJumpPower() / 1.5)
                character:SetData("ixFallDamageReduction", 1.0)
                client:Notify("Пружинные суставы деактивированы.")
                
            else
                print("[Implants] Неизвестный бонус для удаления:", bonus)
            end
        end
    end)
end
