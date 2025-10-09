-- Серверная часть для обработки команд имплантов
if SERVER then
    util.AddNetworkString("ixImplantsApply")
    util.AddNetworkString("ixImplantsOpenMenu")
    
    net.Receive("ixImplantsApply", function(len, client)
        if not client:IsAdmin() then return end
        
        local targetPlayer = net.ReadEntity()
        local limb = net.ReadString()
        local implant = net.ReadString()
        
        if not IsValid(targetPlayer) or not targetPlayer:GetCharacter() then
            client:Notify("Неверный игрок!")
            return
        end
        
        -- Устанавливаем имплант
        ix.SetPlayerImplant(targetPlayer, limb, implant)
        
        local message = ""
        if implant == "НЕТ" then
            message = "Имплант удален с " .. limb .. " у " .. targetPlayer:GetCharacter():GetName()
        else
            message = "Имплант " .. implant .. " установлен в " .. limb .. " для " .. targetPlayer:GetCharacter():GetName()
        end
        
        client:Notify(message)
        targetPlayer:Notify("Вам " .. (implant == "НЕТ" and "удален имплант с" or "установлен имплант в") .. " " .. limb)
        
        -- Логируем действие
        ix.log.Add(client, "implant", message)
    end)
end
