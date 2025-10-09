local PLUGIN = PLUGIN

PLUGIN.name = "Get Position"
PLUGIN.author = "kido"
PLUGIN.description = "Выводит позицию и углы объектов, на которые смотрит игрок"

if SERVER then
	-- Консольная команда для получения позиции объекта
	concommand.Add("getposentity", function(ply, cmd, args)
		if not IsValid(ply) then return end
		
		-- Проверяем права администратора
		if not ply:IsAdmin() then
			ply:ChatPrint("У вас нет доступа к этой команде!")
			return
		end
		
		-- Получаем объект, на который смотрит игрок
		local trace = ply:GetEyeTrace()
		local entity = trace.Entity
		
		if not IsValid(entity) then
			ply:ChatPrint("Вы не смотрите ни на какой объект!")
			return
		end
		
		-- Получаем данные об объекте
		local pos = entity:GetPos()
		local ang = entity:GetAngles()
		local class = entity:GetClass()
		local model = entity:GetModel() or "N/A"
		
		-- Форматируем вывод
		print("========================================")
		print("Информация об объекте:")
		print("Class: " .. class)
		print("Model: " .. model)
		print("Position: Vector(" .. math.Round(pos.x, 2) .. ", " .. math.Round(pos.y, 2) .. ", " .. math.Round(pos.z, 2) .. ")")
		print("Angles: Angle(" .. math.Round(ang.p, 2) .. ", " .. math.Round(ang.y, 2) .. ", " .. math.Round(ang.r, 2) .. ")")
		print("========================================")
		
		-- Отправляем информацию в чат игроку
		ply:ChatPrint("========================================")
		ply:ChatPrint("Информация об объекте:")
		ply:ChatPrint("Class: " .. class)
		ply:ChatPrint("Model: " .. model)
		ply:ChatPrint("Position: Vector(" .. math.Round(pos.x, 2) .. ", " .. math.Round(pos.y, 2) .. ", " .. math.Round(pos.z, 2) .. ")")
		ply:ChatPrint("Angles: Angle(" .. math.Round(ang.p, 2) .. ", " .. math.Round(ang.y, 2) .. ", " .. math.Round(ang.r, 2) .. ")")
		ply:ChatPrint("========================================")
	end)
	
	-- Альтернативная команда для копирования в буфер обмена (через сеть)
	concommand.Add("copyposentity", function(ply, cmd, args)
		if not IsValid(ply) then return end
		
		if not ply:IsAdmin() then
			ply:ChatPrint("У вас нет доступа к этой команде!")
			return
		end
		
		local trace = ply:GetEyeTrace()
		local entity = trace.Entity
		
		if not IsValid(entity) then
			ply:ChatPrint("Вы не смотрите ни на какой объект!")
			return
		end
		
		local pos = entity:GetPos()
		local ang = entity:GetAngles()
		local class = entity:GetClass()
		
		-- Формируем строку для копирования
		local copyString = string.format(
			"Vector(%.2f, %.2f, %.2f), Angle(%.2f, %.2f, %.2f) -- %s",
			pos.x, pos.y, pos.z,
			ang.p, ang.y, ang.r,
			class
		)
		
		-- Отправляем клиенту для копирования
		net.Start("ixGetPosCopy")
		net.WriteString(copyString)
		net.Send(ply)
		
		ply:ChatPrint("Позиция скопирована!")
	end)
else
	-- Клиентская часть для копирования в буфер обмена
	net.Receive("ixGetPosCopy", function()
		local text = net.ReadString()
		SetClipboardText(text)
		chat.AddText(Color(100, 255, 100), "[GetPos] ", Color(255, 255, 255), "Скопировано в буфер обмена: " .. text)
	end)
end

if SERVER then
	util.AddNetworkString("ixGetPosCopy")
end
