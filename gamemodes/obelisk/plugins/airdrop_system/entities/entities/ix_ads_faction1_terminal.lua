ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Консоль вызова аирдропов (Фракция 1)"
ENT.Author = "kido"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Airdrop System"

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/props_combine/combine_interface001.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        
        local phys = self:GetPhysicsObject()
        if phys:IsValid() then
            phys:Wake()
            phys:EnableMotion(false)
        end
        
        self:SetUseType(SIMPLE_USE)
    end
    
    function ENT:Use(activator, caller)
        if not IsValid(caller) or not caller:IsPlayer() then return end
        
        -- Получаем плагин
        local plugin = ix.plugin.Get("airdrop_system")
        if not plugin then return end
        
        -- Получаем фракцию из конфига
        local factionKey = "faction1"
        local factionConfig = ix.configs.airbrop.factions[factionKey]
        if not factionConfig then
            caller:Notify("Ошибка: конфигурация фракции не найдена")
            return
        end
        
        -- Проверяем доступ по фракции персонажа
        if not plugin:CanPlayerAccessFaction(caller, factionKey) then
            local character = caller:GetCharacter()
            local playerFactionID = character and character:GetFaction()
            local playerFactionTable = playerFactionID and ix.faction.Get(playerFactionID)
            local playerFactionName = playerFactionTable and playerFactionTable.name or "Неизвестная"
            
            caller:Notify("Доступ запрещён: требуется фракция " .. (factionConfig.name or factionKey))
            local denyMsg = caller:GetName() .. " (" .. playerFactionName .. ") пытается использовать терминал аирдропов, но система отказывает в доступе."
            for _, v in pairs(player.GetAll()) do
                if v:GetPos():Distance(caller:GetPos()) <= 200 then
                    v:Notify(denyMsg)
                end
            end
            return
        end
        
        -- Проверяем кулдаун терминала
        if not plugin:CheckCooldown(caller, factionKey) then
            local remaining = plugin:GetCooldownRemaining(caller, factionKey)
            caller:Notify("Терминал перезаряжается! Осталось: " .. math.ceil(remaining) .. " сек.")
            return
        end
        
        -- RP уведомление о подтверждении доступа
        caller:Notify("Доступ к терминалу подтверждён")
        
        -- RP отыгрывание
        caller:SetAction("Подключается к терминалу вызова аирдропов...", 3)
        
        -- Уведомляем окружающих
        local plyName = caller:GetName()
        local message = plyName .. " подключается к терминалу вызова аирдропов (" .. (factionConfig.name or factionKey) .. ")."
        
        for k, v in pairs(player.GetAll()) do
            if v:GetPos():Distance(caller:GetPos()) <= 200 then
                v:Notify(message)
            end
        end
        
        timer.Simple(3, function()
            if IsValid(caller) and caller:GetPos():Distance(self:GetPos()) <= 100 then
                net.Start("ADS_OpenTerminal")
                net.WriteString(factionKey)
                net.Send(caller)
            end
        end)
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
        
        local pos = self:GetPos() + self:GetUp() * 30
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        
        cam.Start3D2D(pos, ang, 0.1)
            -- Получаем название фракции из конфига
            local factionConfig = ix.configs.airbrop.factions["faction1"]
            local factionName = factionConfig and factionConfig.name or "ФРАКЦИЯ 1"
            
            draw.SimpleText("КОНСОЛЬ ВЫЗОВА", "ADS_RobotoLarge", 0, -60, Color(66, 165, 245), TEXT_ALIGN_CENTER)
            draw.SimpleText("АИРДРОПОВ", "ADS_RobotoMedium", 0, -30, Color(66, 165, 245), TEXT_ALIGN_CENTER)
            draw.SimpleText(factionName, "ADS_RobotoMedium", 0, 0, Color(76, 175, 80), TEXT_ALIGN_CENTER)
            draw.SimpleText("Нажмите E для использования", "ADS_RobotoSmall", 0, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end 

