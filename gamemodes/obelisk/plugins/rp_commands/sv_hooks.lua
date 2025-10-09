local PLUGIN = PLUGIN

function PLUGIN:CharacterLoaded(client, character)
	if (not IsValid(client)) then return end
	if (not character) then return end
	
	-- Получаем сохраненный размер персонажа
	local savedScale = character:GetData("playerScale", 1.0)
	
	-- Применяем размер к игроку
	client:SetModelScale(savedScale)
end
