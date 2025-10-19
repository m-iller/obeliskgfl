-- Серверная часть для обработки команд имплантов
if SERVER then
    util.AddNetworkString("ixImplantsApply")
    util.AddNetworkString("ixImplantsOpenMenu")
    util.AddNetworkString("ixImplantsGetData")
    
    net.Receive("ixImplantsApply", function(len, client)        
        local targetPlayer = net.ReadEntity()
        local limb = net.ReadString()
        local implant = net.ReadString()
        
        if not IsValid(targetPlayer) or not targetPlayer:GetCharacter() then
            client:Notify("Неверный игрок!")
            return
        end
        
        -- Устанавливаем имплант
        ix.SetCharacterImplant(targetPlayer:GetCharacter(), limb, implant)
        targetPlayer:Notify("Вам " .. (implant == "НЕТ" and "удален имплант с" or "установлен имплант в") .. " " .. limb)
    end)
    
    -- Обработчик для получения данных об имплантах
    net.Receive("ixImplantsGetData", function(len, client)
        if not client:IsAdmin() then return end
        
        local targetPlayer = net.ReadEntity()
        
        if not IsValid(targetPlayer) or not targetPlayer:GetCharacter() then
            return
        end
        
        local character = targetPlayer:GetCharacter()
        local implants = ix.GetCharacterImplants(character)
        
        -- Отправляем данные обратно клиенту
        net.Start("ixImplantsGetData")
        net.WriteEntity(targetPlayer)
        net.WriteTable(implants)
        net.Send(client)
    end)
end
