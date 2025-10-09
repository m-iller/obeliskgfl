ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Лог терминал наземной техники"
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
        
        -- RP отыгрывание
        caller:SetAction("Подключается к лог терминалу...", 2)
        
        -- Уведомляем окружающих
        local plyName = caller:GetName()
        local message = plyName .. " подключается к лог терминалу наземной техники."
        
        for k, v in pairs(player.GetAll()) do
            if v:GetPos():Distance(caller:GetPos()) <= 150 then
                v:Notify(message)
            end
        end
        
        timer.Simple(2, function()
            if IsValid(caller) and caller:GetPos():Distance(self:GetPos()) <= 100 then
                net.Start("VCS_OpenLogTerminal")
                net.WriteString("ground")
                net.Send(caller)
            end
        end)
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
        
        -- Отрисовка текста над терминалом
        local pos = self:GetPos() + Vector(0, 0, 80)
        local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
        local distance = LocalPlayer():GetPos():Distance(self:GetPos())
        
        -- Проверяем расстояние до игрока
        if distance < 500 then
            cam.Start3D2D(pos, ang, 0.1)
                -- Рисуем название
                draw.SimpleText("Лог терминал наземной техники", "DermaLarge", 0, 0, Color(255, 165, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                
                -- Рисуем подсказку
                draw.SimpleText("Нажмите [E] для просмотра логов", "DermaDefault", 0, 30, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end
end 