-- Клиентская часть плагина Airdrop System
local PLUGIN = PLUGIN

-- Глобальные переменные для контроля уникальности меню
local ADS_OpenFrames = {
    terminal = {}
}

-- Функция безопасного закрытия окна
local function SafeCloseFrame(frame)
    if IsValid(frame) then
        frame:SetVisible(false)
        frame:Remove()
        return true
    end
    return false
end

-- Функция проверки и закрытия существующего меню
local function EnsureUniqueFrame(faction)
    local existing = ADS_OpenFrames.terminal[faction]
    if SafeCloseFrame(existing) then
        print("[ADS] Закрыт существующий терминал: " .. faction)
    end
    ADS_OpenFrames.terminal[faction] = nil
end

-- Функция регистрации нового окна
local function RegisterFrame(frame, faction)
    ADS_OpenFrames.terminal[faction] = frame
    
    -- Добавляем обработчик закрытия для очистки ссылки
    local oldRemove = frame.Remove
    frame.Remove = function(self)
        ADS_OpenFrames.terminal[faction] = nil
        oldRemove(self)
    end
end

-- Создание кастомных шрифтов
surface.CreateFont("ADS_RobotoLarge", {
    font = "Roboto",
    size = 24,
    weight = 600,
    antialias = true,
    shadow = false
})

surface.CreateFont("ADS_RobotoMedium", {
    font = "Roboto",
    size = 18,
    weight = 500,
    antialias = true,
    shadow = false
})

surface.CreateFont("ADS_RobotoDefault", {
    font = "Roboto",
    size = 16,
    weight = 400,
    antialias = true,
    shadow = false
})

surface.CreateFont("ADS_RobotoSmall", {
    font = "Roboto",
    size = 14,
    weight = 400,
    antialias = true,
    shadow = false
})

surface.CreateFont("ADS_RobotoBold", {
    font = "Roboto",
    size = 16,
    weight = 700,
    antialias = true,
    shadow = false
})

-- Цветовая схема
local colors = {
    background = Color(25, 25, 35),
    surface = Color(35, 35, 50),
    primary = Color(66, 165, 245),
    secondary = Color(156, 39, 176),
    success = Color(76, 175, 80),
    warning = Color(255, 193, 7),
    error = Color(244, 67, 54),
    text = Color(255, 255, 255),
    textSecondary = Color(200, 200, 220),
    textMuted = Color(120, 120, 140),
    accent = Color(0, 188, 212),
    hover = Color(50, 50, 70),
    inputBg = Color(45, 45, 60),
    inputBorder = Color(80, 80, 100)
}

-- Современная кнопка
local PANEL = {}

function PANEL:Init()
    self.hovered = false
    self.pressed = false
    self.enabled = true
    self.backgroundColor = colors.primary
    self.textColor = colors.text
    
    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(false)
end

function PANEL:Paint(w, h)
    local bg = self.backgroundColor
    
    if not self.enabled then
        bg = Color(bg.r * 0.5, bg.g * 0.5, bg.b * 0.5, bg.a)
    elseif self.pressed then
        bg = Color(bg.r * 0.8, bg.g * 0.8, bg.b * 0.8, bg.a)
    elseif self.hovered then
        bg = Color(bg.r * 1.1, bg.g * 1.1, bg.b * 1.1, bg.a)
    end
    
    draw.RoundedBox(8, 0, 0, w, h, bg)
    
    if self.enabled and (self.hovered or self.pressed) then
        draw.RoundedBox(8, 2, 2, w, h, Color(0, 0, 0, 50))
    end
    
    surface.SetFont("ADS_RobotoBold")
    local text = self:GetText() or ""
    local tw, th = surface.GetTextSize(text)
    surface.SetTextColor(self.textColor)
    surface.SetTextPos((w - tw) / 2, (h - th) / 2)
    surface.DrawText(text)
end

function PANEL:OnCursorEntered()
    self.hovered = true
    self:InvalidateParent()
end

function PANEL:OnCursorExited()
    self.hovered = false
    self.pressed = false
    self:InvalidateParent()
end

function PANEL:OnMousePressed(keyCode)
    if keyCode == MOUSE_LEFT and self.enabled then
        self.pressed = true
        self:InvalidateParent()
        self:MouseCapture(true)
    end
end

function PANEL:OnMouseReleased(keyCode)
    if keyCode == MOUSE_LEFT then
        self:MouseCapture(false)
        if self.pressed and self.hovered and self.enabled then
            self.pressed = false
            self:InvalidateParent()
            if self.DoClick then
                self:DoClick()
            end
        else
            self.pressed = false
            self:InvalidateParent()
        end
    end
end

function PANEL:SetBackgroundColor(color)
    self.backgroundColor = color
end

function PANEL:SetEnabled(enabled)
    self.enabled = enabled
end

function PANEL:SetText(text)
    self.customText = text or ""
end

function PANEL:GetText()
    return self.customText or ""
end

vgui.Register("ADS_ModernButton", PANEL, "DPanel")

-- Функция создания UI терминала
local function CreateTerminalUI(faction)
    -- Закрываем существующее окно если есть
    EnsureUniqueFrame(faction)
    
    -- Получаем конфигурацию фракции
    local factionConfig = ix.configs.airbrop.factions[faction]
    if not factionConfig then
        LocalPlayer():Notify("Ошибка: конфигурация фракции не найдена")
        return
    end
    
    local scrW, scrH = ScrW(), ScrH()
    local frameW, frameH = 800, 600
    
    -- Создаем главное окно
    local frame = vgui.Create("DFrame")
    frame:SetSize(frameW, frameH)
    frame:SetPos((scrW - frameW) / 2, (scrH - frameH) / 2)
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    
    frame.Paint = function(self, w, h)
        -- Основной фон
        draw.RoundedBox(12, 0, 0, w, h, colors.background)
        
        -- Тень
        draw.RoundedBox(12, 2, 2, w, h, Color(0, 0, 0, 30))
        
        -- Заголовок
        draw.RoundedBox(12, 0, 0, w, 60, colors.surface)
        surface.SetFont("ADS_RobotoLarge")
        surface.SetTextColor(colors.text)
        local title = "Терминал вызова аирдропов - " .. (factionConfig.name or faction)
        local tw, th = surface.GetTextSize(title)
        surface.SetTextPos((w - tw) / 2, (60 - th) / 2)
        surface.DrawText(title)
    end
    
    -- Кнопка закрытия
    local closeBtn = vgui.Create("ADS_ModernButton", frame)
    closeBtn:SetSize(100, 35)
    closeBtn:SetPos(frameW - 120, 12)
    closeBtn:SetText("Закрыть")
    closeBtn:SetBackgroundColor(colors.error)
    closeBtn.DoClick = function()
        frame:Close()
    end
    
    -- Панель выбора типа вызова
    local typePanel = vgui.Create("DPanel", frame)
    typePanel:SetPos(20, 80)
    typePanel:SetSize(frameW - 40, 60)
    typePanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, colors.surface)
        surface.SetFont("ADS_RobotoMedium")
        surface.SetTextColor(colors.textSecondary)
        surface.SetTextPos(10, 10)
        surface.DrawText("Выберите тип вызова:")
    end
    
    local targetTypeCombo = vgui.Create("DComboBox", typePanel)
    targetTypeCombo:SetPos(10, 35)
    targetTypeCombo:SetSize(300, 30)
    targetTypeCombo:SetValue("Выберите тип вызова")
    targetTypeCombo:AddChoice("На позицию")
    targetTypeCombo:AddChoice("На игрока")
    
    -- Панель выбора аирдропа
    local airdropPanel = vgui.Create("DPanel", frame)
    airdropPanel:SetPos(20, 160)
    airdropPanel:SetSize(frameW - 40, 300)
    airdropPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, colors.surface)
        surface.SetFont("ADS_RobotoMedium")
        surface.SetTextColor(colors.textSecondary)
        surface.SetTextPos(10, 10)
        surface.DrawText("Доступные аирдропы:")
    end
    
    -- Скроллируемый список аирдропов
    local airdropList = vgui.Create("DScrollPanel", airdropPanel)
    airdropList:SetPos(10, 40)
    airdropList:SetSize(airdropPanel:GetWide() - 20, airdropPanel:GetTall() - 50)
    
    -- Переменные для хранения выбора
    local selectedAirdrop = nil
    local selectedTargetType = nil
    local selectedTarget = nil
    
    -- Функция для сохранения выбранной цели
    frame.SetSelectedTarget = function(self, target)
        selectedTarget = target
    end
    
    -- Функция для получения выбранной цели
    frame.GetSelectedTarget = function(self)
        return selectedTarget
    end
    
    -- Заполняем список аирдропов
    local airdrops = factionConfig.airdrops or {}
    for i, airdropData in ipairs(airdrops) do
        local airdropBtn = vgui.Create("DButton", airdropList)
        airdropBtn:SetSize(airdropList:GetWide() - 20, 80)
        airdropBtn:Dock(TOP)
        airdropBtn:DockMargin(0, 0, 0, 10)
        airdropBtn:SetText("")
        
        airdropBtn.Paint = function(self, w, h)
            local bgColor = colors.inputBg
            if self:IsHovered() then
                bgColor = colors.hover
            end
            if selectedAirdrop == airdropData then
                bgColor = colors.primary
            end
            
            draw.RoundedBox(6, 0, 0, w, h, bgColor)
            draw.RoundedBox(6, 2, 2, w, h, Color(0, 0, 0, 20))
            
            -- Название
            surface.SetFont("ADS_RobotoBold")
            surface.SetTextColor(colors.text)
            surface.SetTextPos(10, 10)
            surface.DrawText(airdropData.name or "Неизвестный аирдроп")
            
            -- Описание
            surface.SetFont("ADS_RobotoSmall")
            surface.SetTextColor(colors.textSecondary)
            surface.SetTextPos(10, 35)
            surface.DrawText(airdropData.description or "")
            
            -- Лимит
            surface.SetFont("ADS_RobotoSmall")
            surface.SetTextColor(colors.textMuted)
            surface.SetTextPos(10, 55)
            surface.DrawText("Макс. активных: " .. (airdropData.maxActive or 1))
        end
        
        airdropBtn.DoClick = function()
            selectedAirdrop = airdropData
        end
    end
    
    -- Панель выбора цели (появляется в зависимости от типа)
    local targetPanel = vgui.Create("DPanel", frame)
    targetPanel:SetPos(20, 480)
    targetPanel:SetSize(frameW - 40, 60)
    targetPanel:SetVisible(false)
    targetPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, colors.surface)
    end
    
    local targetCombo = vgui.Create("DComboBox", targetPanel)
    targetCombo:SetPos(10, 15)
    targetCombo:SetSize(targetPanel:GetWide() - 20, 30)
    
    -- Обработчик выбора типа вызова
    targetTypeCombo.OnSelect = function(panel, index, value)
        if value == "На позицию" then
            selectedTargetType = "position"
            targetPanel:SetVisible(true)
            
            -- Очищаем и заполняем комбобокс заготовленными позициями из конфига
            targetCombo:Clear()
            targetCombo:SetValue("Выберите позицию")
            
            -- Получаем позиции из конфига
            local positions = factionConfig.positions or {}
            
            if #positions == 0 then
                targetCombo:SetValue("Нет доступных позиций")
            else
                for _, posData in ipairs(positions) do
                    targetCombo:AddChoice(posData.name, posData.pos)
                end
                
                targetCombo.OnSelect = function(panel, idx, val, data)
                    -- data содержит Vector позиции
                    selectedTarget = {
                        x = data.x,
                        y = data.y,
                        z = data.z
                    }
                end
            end
        elseif value == "На игрока" then
            selectedTargetType = "player"
            targetPanel:SetVisible(true)
            
            -- Запрашиваем список игроков
            targetCombo:Clear()
            targetCombo:SetValue("Загрузка игроков...")
            
            -- Сохраняем ссылку на комбобокс для обновления после получения ответа
            frame.targetCombo = targetCombo
            
            net.Start("ADS_GetPlayerList")
            net.WriteString(faction)
            net.SendToServer()
        end
    end
    
    -- Кнопка вызова аирдропа
    local callBtn = vgui.Create("ADS_ModernButton", frame)
    callBtn:SetSize(200, 40)
    callBtn:SetPos((frameW - 200) / 2, frameH - 60)
    callBtn:SetText("Вызвать аирдроп")
    callBtn:SetBackgroundColor(colors.success)
    callBtn.DoClick = function()
        if not selectedAirdrop then
            LocalPlayer():Notify("Выберите тип аирдропа")
            return
        end
        
        if not selectedTargetType then
            LocalPlayer():Notify("Выберите тип вызова")
            return
        end
        
        if not selectedTarget then
            LocalPlayer():Notify("Выберите цель вызова")
            return
        end
        
        -- Отправляем запрос на сервер
        net.Start("ADS_RequestAirdrop")
        net.WriteString(selectedAirdrop.type)
        net.WriteString(faction)
        net.WriteString(selectedTargetType)
        net.WriteTable(selectedTarget)
        net.SendToServer()
        
        frame:Close()
    end
    
    -- Регистрируем окно
    RegisterFrame(frame, faction)
end

-- Получение списка игроков с сервера
net.Receive("ADS_PlayerListResponse", function()
    local playerList = net.ReadTable()
    
    -- Находим открытый терминал и обновляем список игроков
    for faction, frame in pairs(ADS_OpenFrames.terminal) do
        if IsValid(frame) and frame.targetCombo and IsValid(frame.targetCombo) then
            local targetCombo = frame.targetCombo
            targetCombo:Clear()
            
            if #playerList == 0 then
                targetCombo:SetValue("Нет доступных игроков")
            else
                targetCombo:SetValue("Выберите игрока")
                for _, playerData in ipairs(playerList) do
                    local displayName = playerData.name .. " (" .. playerData.factionName .. ")"
                    targetCombo:AddChoice(displayName, playerData)
                end
                
                targetCombo.OnSelect = function(panel, index, value, data)
                    -- Сохраняем выбранного игрока
                    frame:SetSelectedTarget({
                        steamID = data.steamID
                    })
                end
            end
            
            return
        end
    end
end)

-- Получение команды на открытие терминала
net.Receive("ADS_OpenTerminal", function()
    local faction = net.ReadString()
    CreateTerminalUI(faction)
end)

print("[ADS] Клиентская часть плагина Airdrop System загружена")

