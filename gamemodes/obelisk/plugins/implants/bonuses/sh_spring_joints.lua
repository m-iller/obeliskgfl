-- Бонус: Пружинные суставы
-- Увеличивает скорость бега и прыжков

hook.Add("ImplantBonusApplied", "spring_joints", function(client, limb, implant, bonus)
    if bonus == "spring_joints" then
        -- Увеличиваем скорость бега
        client:SetWalkSpeed(client:GetWalkSpeed() * 1.3)
        client:SetRunSpeed(client:GetRunSpeed() * 1.3)
        
        -- Увеличиваем высоту прыжка
        client:SetJumpPower(client:GetJumpPower() * 1.5)
        
        -- Уменьшаем урон от падений
        client:SetNWFloat("ixFallDamageReduction", 0.7)
        
        client:Notify("Пружинные суставы активированы! Увеличена скорость и высота прыжков.")
    end
end)

-- Убираем бонус при удалении импланта
hook.Add("ImplantBonusRemoved", "spring_joints", function(client, limb, implant)
    if implant == "Пружинные суставы" then
        client:SetWalkSpeed(client:GetWalkSpeed() / 1.3)
        client:SetRunSpeed(client:GetRunSpeed() / 1.3)
        client:SetJumpPower(client:GetJumpPower() / 1.5)
        client:SetNWFloat("ixFallDamageReduction", 1.0)
        client:Notify("Пружинные суставы деактивированы.")
    end
end)
