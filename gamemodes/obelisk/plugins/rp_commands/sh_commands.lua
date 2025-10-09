-- Команда /do - отправляет сообщение от третьего лица с именем игрока в квадратных скобках
ix.command.Add("do", {
	description = "Отправить сообщение от третьего лица",
	arguments = ix.type.text,
	OnRun = function(self, client, text)
		local character = client:GetCharacter()
		if (not character) then
			return "У вас нет активного персонажа!"
		end
		
		local playerName = character:GetName()
		local message = text .. " [" .. playerName .. "]"
		
		ix.chat.Send(client, "do", message)
	end
})

-- Команда /rpname - позволяет сменить имя персонажа
ix.command.Add("rpname", {
	description = "Сменить имя персонажа",
	arguments = ix.type.text,
	OnRun = function(self, client, newName)
		local character = client:GetCharacter()
		if (not character) then
			return "У вас нет активного персонажа!"
		end
		
		-- Проверяем длину имени
		if (newName:utf8len() < 2) then
			return "Имя должно содержать минимум 2 символа!"
		end
		
		if (newName:utf8len() > 32) then
			return "Имя не может быть длиннее 32 символов!"
		end
		
		-- Устанавливаем новое имя
		character:SetName(newName)
		
		return "Ваше имя изменено на: " .. newName
	end
})

-- Команда /try - отправляет сообщение с случайным результатом
ix.command.Add("try", {
	description = "Попытка действия с случайным результатом",
	arguments = ix.type.text,
	OnRun = function(self, client, text)
		local character = client:GetCharacter()
		if (not character) then
			return "У вас нет активного персонажа!"
		end
		
		local playerName = character:GetName()
		local success = math.random(1, 2) == 1
		local result = success and "Удачно" or "Неудачно"
		
		local message = text .. " [" .. result .. "]"
		
		ix.chat.Send(client, "try", message)
	end
})

-- Команда /scale - изменяет размер персонажа
ix.command.Add("scale", {
	description = "Изменить размер персонажа (от 0.5 до 1.5)",
	arguments = ix.type.number,
	OnRun = function(self, client, scale)
		local character = client:GetCharacter()
		if (not character) then
			return "У вас нет активного персонажа!"
		end
		
		-- Проверяем ограничения размера
		if (scale < 0.5) then
			return "Минимальный размер персонажа: 0.5!"
		end
		
		if (scale > 1.5) then
			return "Максимальный размер персонажа: 1.5!"
		end
		
		-- Сохраняем размер в данных персонажа
		character:SetData("playerScale", scale)
		
		-- Применяем размер к игроку
		client:SetModelScale(scale)
		
		return "Размер персонажа изменен на: " .. scale
	end
})
