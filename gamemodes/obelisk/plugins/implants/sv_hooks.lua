-- Серверные хуки для системы имплантов
if SERVER then
    -- Хук для увеличения урона на основе данных персонажа
    hook.Add("EntityTakeDamage", "ixImplantsDamageBoost", function(target, dmgInfo)
        local attacker = dmgInfo:GetAttacker()
        
        -- Проверяем, что атакующий - игрок с персонажем
        if IsValid(attacker) and attacker:IsPlayer() and attacker:GetCharacter() then
            local character = attacker:GetCharacter()
            local multiplier = character:GetData("ixDamageMultiplier", 1.0)
            
            -- Если множитель больше 1.0, значит есть активный бонус урона
            if multiplier > 1.0 then
                dmgInfo:ScaleDamage(multiplier)
            end
        end
    end)
    
    -- Хук для сопротивления урону на основе данных персонажа
    hook.Add("EntityTakeDamage", "ixImplantsDamageResistance", function(target, dmgInfo)
        -- Проверяем, что цель - игрок с персонажем
        if IsValid(target) and target:IsPlayer() and target:GetCharacter() then
            local character = target:GetCharacter()
            local resistance = character:GetData("ixDamageResistance", 1.0)
            
            -- Если сопротивление меньше 1.0, значит есть активное сопротивление урону
            if resistance < 1.0 then
                dmgInfo:ScaleDamage(resistance)
            end
        end
    end)
    
    -- Хук для уменьшения урона от падения на основе данных персонажа
    hook.Add("EntityTakeDamage", "ixImplantsFallDamageReduction", function(target, dmgInfo)
        -- Проверяем, что цель - игрок с персонажем
        if IsValid(target) and target:IsPlayer() and target:GetCharacter() then
            -- Проверяем, что урон от падения
            if dmgInfo:GetDamageType() == DMG_FALL then
                local character = target:GetCharacter()
                local reduction = character:GetData("ixFallDamageReduction", 1.0)
                
                -- Если уменьшение меньше 1.0, значит есть активное уменьшение урона от падения
                if reduction < 1.0 then
                    dmgInfo:ScaleDamage(reduction)
                end
            end
        end
    end)

     -- Хук для применения эффектов имплантов при загрузке персонажа
     hook.Add("PlayerSpawn", "ixImplantsApplyOnLoad", function(ply)
        local character = ply:GetCharacter()
        
        local implants = ix.GetCharacterImplants(character)
        
        for limb, implant in pairs(implants) do
            if implant ~= "НЕТ" then
                ix.SetCharacterImplant(character, limb, implant)
            end
        end
     end)
end
