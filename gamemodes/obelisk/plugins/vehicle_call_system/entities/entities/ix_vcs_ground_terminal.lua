ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Консоль вызова наземной техники"
ENT.Author = "kido"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "VCS"

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
        local plugin = ix.plugin.Get("vehicle_call_system")
        if not plugin then return end
		
		-- Проверяем доступ по флагу V
		local character = caller:GetCharacter()
		if (not character) or (not character:HasFlags("V")) then
			caller:Notify("Доступ запрещён: требуется флаг V")
			local denyMsg = caller:GetName() .. " пытается использовать терминал наземной техники, но система отказывает в доступе."
			for _, v in pairs(player.GetAll()) do
				if v:GetPos():Distance(caller:GetPos()) <= 200 then
					v:Notify(denyMsg)
				end
			end
			return
		end
        
        -- Проверяем кулдаун терминала
        if not plugin:CheckCooldown(caller, "terminal") then
            local remaining = plugin:GetCooldownRemaining(caller, "terminal")
            caller:Notify("Терминал перезаряжается! Осталось: " .. math.ceil(remaining) .. " сек.")
            return
        end
        
		-- RP уведомление о подтверждении доступа
		caller:Notify("Доступ к терминалу подтверждён")
		
        -- RP отыгрывание
        caller:SetAction("Подключается к терминалу наземной техники...", 3)
        
        -- Уведомляем окружающих
        local plyName = caller:GetName()
        local message = plyName .. " подключается к терминалу вызова наземной техники."
        
        for k, v in pairs(player.GetAll()) do
            if v:GetPos():Distance(caller:GetPos()) <= 200 then
                v:Notify(message)
            end
        end
        
        timer.Simple(3, function()
            if IsValid(caller) and caller:GetPos():Distance(self:GetPos()) <= 100 then
                net.Start("VCS_OpenTerminal")
                net.WriteString("ground")
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
            draw.SimpleText("КОНСОЛЬ ВЫЗОВА", "VCS_RobotoLarge", 0, -60, Color(255, 165, 0), TEXT_ALIGN_CENTER)
            draw.SimpleText("НАЗЕМНОЙ ТЕХНИКИ", "VCS_RobotoMedium", 0, -30, Color(255, 165, 0), TEXT_ALIGN_CENTER)
            draw.SimpleText("Нажмите E для использования", "VCS_RobotoSmall", 0, 10, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end 