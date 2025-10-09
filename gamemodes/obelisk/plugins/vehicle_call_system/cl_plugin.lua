-- Клиентская часть плагина Vehicle Call System
local PLUGIN = PLUGIN

-- Глобальные переменные для контроля уникальности меню
local VCS_OpenFrames = {
    spawnManager = nil,
    terminal = {air = nil, ground = nil},
    logTerminal = {air = nil, ground = nil},
    logDetail = {}
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
local function EnsureUniqueFrame(frameType, subType)
    local existing = nil
    
    if frameType == "spawnManager" then
        existing = VCS_OpenFrames.spawnManager
        if SafeCloseFrame(existing) then
            print("[VCS] Закрыт существующий менеджер позиций")
        end
        VCS_OpenFrames.spawnManager = nil
    elseif frameType == "terminal" and subType then
        existing = VCS_OpenFrames.terminal[subType]
        if SafeCloseFrame(existing) then
            print("[VCS] Закрыт существующий терминал: " .. subType)
        end
        VCS_OpenFrames.terminal[subType] = nil
    elseif frameType == "logTerminal" and subType then
        existing = VCS_OpenFrames.logTerminal[subType]
        if SafeCloseFrame(existing) then
            print("[VCS] Закрыт существующий лог терминал: " .. subType)
        end
        VCS_OpenFrames.logTerminal[subType] = nil
    elseif frameType == "logDetail" then
        -- Закрываем все окна детальной информации
        for i, detailFrame in pairs(VCS_OpenFrames.logDetail) do
            if SafeCloseFrame(detailFrame) then
                print("[VCS] Закрыто окно детальной информации: " .. i)
            end
        end
        VCS_OpenFrames.logDetail = {}
    end
end

-- Функция регистрации нового окна
local function RegisterFrame(frameType, frame, subType)
    if frameType == "spawnManager" then
        VCS_OpenFrames.spawnManager = frame
    elseif frameType == "terminal" and subType then
        VCS_OpenFrames.terminal[subType] = frame
    elseif frameType == "logTerminal" and subType then
        VCS_OpenFrames.logTerminal[subType] = frame
    elseif frameType == "logDetail" then
        table.insert(VCS_OpenFrames.logDetail, frame)
    end
    
    -- Добавляем обработчик закрытия для очистки ссылки
    local oldRemove = frame.Remove
    frame.Remove = function(self)
        -- Очищаем ссылку при закрытии
        if frameType == "spawnManager" then
            VCS_OpenFrames.spawnManager = nil
        elseif frameType == "terminal" and subType then
            VCS_OpenFrames.terminal[subType] = nil
        elseif frameType == "logTerminal" and subType then
            VCS_OpenFrames.logTerminal[subType] = nil
        elseif frameType == "logDetail" then
            for i, detailFrame in pairs(VCS_OpenFrames.logDetail) do
                if detailFrame == self then
                    table.remove(VCS_OpenFrames.logDetail, i)
                    break
                end
            end
        end
        
        oldRemove(self)
    end
end

-- Создание кастомных шрифтов Roboto
surface.CreateFont("VCS_RobotoLarge", {
    font = "Roboto",
    size = 24,
    weight = 600,
    antialias = true,
    shadow = false
})

surface.CreateFont("VCS_RobotoMedium", {
    font = "Roboto",
    size = 18,
    weight = 500,
    antialias = true,
    shadow = false
})

surface.CreateFont("VCS_RobotoDefault", {
    font = "Roboto",
    size = 16,
    weight = 400,
    antialias = true,
    shadow = false
})

surface.CreateFont("VCS_RobotoSmall", {
    font = "Roboto",
    size = 14,
    weight = 400,
    antialias = true,
    shadow = false
})

surface.CreateFont("VCS_RobotoBold", {
    font = "Roboto",
    size = 16,
    weight = 700,
    antialias = true,
    shadow = false
})

-- Цветовая схема для современного дизайна
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

-- Кастомные компоненты

-- Современная кнопка
local PANEL = {}

function PANEL:Init()
    self.hovered = false
    self.pressed = false
    self.enabled = true
    self.backgroundColor = colors.primary
    self.textColor = colors.text
    self.icon = nil
    
    -- Включаем обработку мыши
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
    
    -- Рисуем фон с закругленными углами
    draw.RoundedBox(8, 0, 0, w, h, bg)
    
    -- Добавляем тень
    if self.enabled and (self.hovered or self.pressed) then
        draw.RoundedBox(8, 2, 2, w, h, Color(0, 0, 0, 50))
    end
    
    -- Рисуем текст
    surface.SetFont("VCS_RobotoBold")
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

function PANEL:SetIcon(icon)
    self.icon = icon
end

function PANEL:SetBackgroundColor(color)
    self.backgroundColor = color
end

function PANEL:SetEnabled(enabled)
    self.enabled = enabled
end

-- Переопределяем стандартные методы чтобы убрать DLabel функциональность
function PANEL:SetText(text)
    self.customText = text or ""
end

function PANEL:GetText()
    return self.customText or ""
end

vgui.Register("VCS_ModernButton", PANEL, "DPanel") -- Наследуемся от DPanel, а не DLabel

-- Современная панель с полностью кастомным рисованием
local PANEL = {}

function PANEL:Init()
    self.title = ""
    self.subtitle = ""
    
    -- Убираем попытки вызова методов DFrame, так как мы наследуемся от DPanel
    -- self:SetTitle("")
    -- self:ShowCloseButton(false)
    -- self:SetDraggable(false)
end

function PANEL:Paint(w, h)
    -- Основной фон с закругленными углами
    draw.RoundedBox(12, 0, 0, w, h, colors.surface)
    
    -- Тень
    draw.RoundedBox(12, 2, 2, w, h, Color(0, 0, 0, 30))
    
    -- Заголовок
    if self.title ~= "" then
        surface.SetFont("VCS_RobotoMedium")
        surface.SetTextColor(colors.text)
        surface.SetTextPos(20, 15)
        surface.DrawText(self.title)
        
        if self.subtitle ~= "" then
            surface.SetFont("VCS_RobotoSmall")
            surface.SetTextColor(colors.textSecondary)
            surface.SetTextPos(20, 45)
            surface.DrawText(self.subtitle)
        end
    end
    
    return true -- Возвращаем true чтобы дочерние элементы отображались
end

function PANEL:SetTitle(title, subtitle)
    self.title = title
    self.subtitle = subtitle or ""
    self:InvalidateParent()
end

vgui.Register("VCS_ModernPanel", PANEL, "DPanel")

-- ИСПРАВЛЕННЫЙ ComboBox - используем DComboBox как основу
local PANEL = {}

function PANEL:Init()
    -- Создаем стандартный DComboBox внутри
    self.comboBox = vgui.Create("DComboBox", self)
    self.comboBox:SetPos(0, 0)
    self.comboBox:SetSize(self:GetWide(), self:GetTall())
    
    -- Настраиваем стандартный комбобокс
    self.comboBox:SetFont("VCS_RobotoDefault")
    self.comboBox:SetText("Выберите опцию")
    
    -- Перенаправляем события
    self.comboBox.OnSelect = function(panel, index, value, data)
        if self.OnSelect then
            self:OnSelect(index, value, data)
        end
    end
    
    -- Хранилище для опций
    self.options = {}
end

function PANEL:PerformLayout()
    if IsValid(self.comboBox) then
        self.comboBox:SetPos(0, 0)
        self.comboBox:SetSize(self:GetWide(), self:GetTall())
    end
end

function PANEL:Paint(w, h)
    -- Кастомный фон
    draw.RoundedBox(8, 0, 0, w, h, colors.inputBg)
    
    -- Рамка
    surface.SetDrawColor(colors.inputBorder)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
    
    return true
end

function PANEL:AddChoice(text, value)
    if IsValid(self.comboBox) then
        self.comboBox:AddChoice(text, value)
        table.insert(self.options, {text = text, value = value})
    end
end

function PANEL:Clear()
    if IsValid(self.comboBox) then
        self.comboBox:Clear()
        self.options = {}
    end
end

function PANEL:SetValue(text)
    if IsValid(self.comboBox) then
        self.comboBox:SetText(text)
        -- Также ищем и выбираем опцию по тексту если она существует
        for i, option in ipairs(self.options) do
            if option.text == text then
                self.comboBox:ChooseOptionID(i)
                break
            end
        end
    end
end

function PANEL:GetSelectedID()
    if IsValid(self.comboBox) then
        local id = self.comboBox:GetSelectedID()
        return id or 1 -- Возвращаем 1 если nil
    end
    return 1
end

function PANEL:GetOptionData(id)
    if id and self.options[id] then
        return self.options[id].value
    end
    return "all" -- Возвращаем значение по умолчанию
end

function PANEL:GetSelected()
    if IsValid(self.comboBox) then
        local id = self.comboBox:GetSelectedID()
        return self:GetOptionData(id)
    end
    return nil
end

function PANEL:SelectOption(index)
    if IsValid(self.comboBox) then
        self.comboBox:ChooseOptionID(index)
    end
end

function PANEL:SetSize(w, h)
    DPanel.SetSize(self, w, h)
    if IsValid(self.comboBox) then
        self.comboBox:SetSize(w, h)
    end
end

vgui.Register("VCS_ModernComboBox", PANEL, "DPanel")

-- Современный список с иконками
local PANEL = {}

function PANEL:Init()
    self.items = {}
    self.selectedIndex = 0
    self.itemHeight = 50
    self.scrollOffset = 0
    self.maxVisible = 0
    self.scrollBarWidth = 16
    self.scrolling = false
    
    -- Включаем обработку мыши
    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(false)
end

function PANEL:Paint(w, h)
    -- Фон списка с закругленными углами
    draw.RoundedBox(8, 0, 0, w, h, colors.background)
    
    self.maxVisible = math.floor(h / self.itemHeight)
    local contentWidth = w - self.scrollBarWidth - 10
    
    -- Проверяем нужна ли прокрутка
    local needsScroll = #self.items * self.itemHeight > h
    local maxScrollOffset = math.max(0, (#self.items * self.itemHeight) - h)
    self.scrollOffset = math.Clamp(self.scrollOffset, 0, maxScrollOffset)
    
    -- Рисуем элементы
    for i, item in ipairs(self.items) do
        local y = (i - 1) * self.itemHeight - self.scrollOffset
        
        if y >= -self.itemHeight and y <= h then
            local itemColor = colors.surface
            
            if i == self.selectedIndex then
                itemColor = colors.primary
            end
            
            -- Фон элемента с закругленными углами
            local itemW = needsScroll and contentWidth or w - 10
            draw.RoundedBox(6, 5, y + 2, itemW, self.itemHeight - 4, itemColor)
            
            -- Основной текст
            surface.SetFont("VCS_RobotoBold")
            surface.SetTextColor(colors.text)
            surface.SetTextPos(20, y + 8)
            surface.DrawText(item.title or "")
            
            -- Дополнительный текст
            if item.subtitle then
                surface.SetFont("VCS_RobotoSmall")
                surface.SetTextColor(colors.textSecondary)
                surface.SetTextPos(20, y + 28)
                surface.DrawText(item.subtitle)
            end
            
            -- Статус справа
            if item.status then
                surface.SetFont("VCS_RobotoBold")
                local statusColor = item.statusColor or colors.success
                surface.SetTextColor(statusColor)
                local tw, th = surface.GetTextSize(item.status)
                surface.SetTextPos(itemW - tw + 5, y + 15)
                surface.DrawText(item.status)
            end
        end
    end
    
    -- Рисуем скроллбар если нужен
    if needsScroll then
        local scrollBarX = w - self.scrollBarWidth
        local scrollBarH = h
        
        -- Фон скроллбара
        draw.RoundedBox(4, scrollBarX, 0, self.scrollBarWidth, scrollBarH, colors.inputBg)
        
        -- Ползунок скроллбара
        local thumbHeight = math.max(20, (h / (#self.items * self.itemHeight)) * scrollBarH)
        local thumbY = (self.scrollOffset / maxScrollOffset) * (scrollBarH - thumbHeight)
        
        draw.RoundedBox(4, scrollBarX + 2, thumbY, self.scrollBarWidth - 4, thumbHeight, colors.primary)
    end
end

function PANEL:OnMousePressed(keyCode)
    if keyCode == MOUSE_LEFT then
        local x, y = self:CursorPos()
        local w, h = self:GetSize()
        
        -- Проверяем клик по скроллбару
        local needsScroll = #self.items * self.itemHeight > h
        if needsScroll and x >= w - self.scrollBarWidth then
            self.scrolling = true
            self:MouseCapture(true)
            return
        end
        
        -- Обычный клик по элементу списка
        local clickedIndex = math.floor((y + self.scrollOffset) / self.itemHeight) + 1
        
        if clickedIndex > 0 and clickedIndex <= #self.items then
            self.selectedIndex = clickedIndex
            self:InvalidateParent()
            if self.OnItemSelected then
                self:OnItemSelected(clickedIndex, self.items[clickedIndex])
            end
        end
    end
end

function PANEL:OnMouseReleased(keyCode)
    if keyCode == MOUSE_LEFT then
        self.scrolling = false
        self:MouseCapture(false)
    end
end

function PANEL:OnMouseWheeled(delta)
    local w, h = self:GetSize()
    local maxScrollOffset = math.max(0, (#self.items * self.itemHeight) - h)
    
    if maxScrollOffset > 0 then
        self.scrollOffset = math.Clamp(self.scrollOffset - delta * self.itemHeight, 0, maxScrollOffset)
        self:InvalidateParent()
    end
end

function PANEL:Think()
    if self.scrolling then
        local mx, my = self:CursorPos()
        local w, h = self:GetSize()
        local maxScrollOffset = math.max(0, (#self.items * self.itemHeight) - h)
        
        if maxScrollOffset > 0 then
            local scrollPercent = math.Clamp(my / h, 0, 1)
            self.scrollOffset = scrollPercent * maxScrollOffset
            self:InvalidateParent()
        end
    end
end

function PANEL:AddItem(title, subtitle, icon, status, statusColor, data)
    -- Проверяем, что все параметры корректны
    if not title then
        print("[VCS] Ошибка: AddItem вызван с пустым title")
        return
    end
    
    table.insert(self.items, {
        title = tostring(title),
        subtitle = subtitle and tostring(subtitle) or nil,
        icon = icon,
        status = status and tostring(status) or nil,
        statusColor = statusColor,
        data = data
    })
    self:InvalidateParent()
end

function PANEL:Clear()
    self.items = {}
    self.selectedIndex = 0
    self:InvalidateParent()
end

function PANEL:GetSelected()
    return self.selectedIndex > 0 and self.items[self.selectedIndex] or nil
end

vgui.Register("VCS_ModernList", PANEL, "DPanel")

-- Кастомный TextEntry
local PANEL = {}

function PANEL:Init()
    self.text = ""
    self.placeholder = ""
    self.focused = false
    self.cursorPos = 0
    
    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(true)
end

function PANEL:Paint(w, h)
    -- Фон с закругленными углами
    local bgColor = self.focused and Color(colors.inputBg.r + 10, colors.inputBg.g + 10, colors.inputBg.b + 10) or colors.inputBg
    draw.RoundedBox(8, 0, 0, w, h, bgColor)
    
    -- Рамка
    local borderColor = self.focused and colors.primary or colors.inputBorder
    surface.SetDrawColor(borderColor)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
    
    -- Текст или placeholder
    surface.SetFont("VCS_RobotoDefault")
    if self.text ~= "" then
        surface.SetTextColor(colors.text)
        surface.SetTextPos(15, (h - 16) / 2)
        surface.DrawText(self.text)
    elseif self.placeholder ~= "" then
        surface.SetTextColor(colors.textMuted)
        surface.SetTextPos(15, (h - 16) / 2)
        surface.DrawText(self.placeholder)
    end
    
    -- Курсор
    if self.focused and math.sin(CurTime() * 4) > 0 then -- Мигающий курсор
        local textW = 0
        if self.text ~= "" then
            surface.SetFont("VCS_RobotoDefault")
            textW, _ = surface.GetTextSize(string.sub(self.text, 1, self.cursorPos))
        end
        
        surface.SetDrawColor(colors.text)
        surface.DrawLine(15 + textW, 8, 15 + textW, h - 8)
    end
end

function PANEL:OnMousePressed(keyCode)
    if keyCode == MOUSE_LEFT then
        self.focused = true
        self:RequestFocus()
        self:MouseCapture(true)
        
        -- Вычисляем позицию курсора по клику
        local mx, my = self:CursorPos()
        if mx > 15 and self.text ~= "" then
            surface.SetFont("VCS_RobotoDefault")
            local clickPos = mx - 15
            local bestPos = 0
            local bestDistance = math.huge
            
            for i = 0, string.len(self.text) do
                local textW, _ = surface.GetTextSize(string.sub(self.text, 1, i))
                local distance = math.abs(textW - clickPos)
                if distance < bestDistance then
                    bestDistance = distance
                    bestPos = i
                end
            end
            
            self.cursorPos = bestPos
        else
            self.cursorPos = 0
        end
    end
end

function PANEL:OnMouseReleased(keyCode)
    if keyCode == MOUSE_LEFT then
        self:MouseCapture(false)
    end
end

function PANEL:OnLoseFocus()
    self.focused = false
end

function PANEL:OnTextChanged()
    -- Переопределяется в наследниках
end

function PANEL:SetPlaceholderText(text)
    self.placeholder = text
end

function PANEL:SetValue(text)
    self.text = tostring(text)
    self.cursorPos = string.len(self.text)
end

function PANEL:GetValue()
    return self.text
end

function PANEL:OnKeyCodeTyped(keyCode)
    if not self.focused then return end
    
    if keyCode == KEY_BACKSPACE and self.cursorPos > 0 then
        self.text = string.sub(self.text, 1, self.cursorPos - 1) .. string.sub(self.text, self.cursorPos + 1)
        self.cursorPos = self.cursorPos - 1
        self:OnTextChanged()
    elseif keyCode == KEY_DELETE and self.cursorPos < string.len(self.text) then
        self.text = string.sub(self.text, 1, self.cursorPos) .. string.sub(self.text, self.cursorPos + 2)
        self:OnTextChanged()
    elseif keyCode == KEY_LEFT and self.cursorPos > 0 then
        self.cursorPos = self.cursorPos - 1
    elseif keyCode == KEY_RIGHT and self.cursorPos < string.len(self.text) then
        self.cursorPos = self.cursorPos + 1
    elseif keyCode == KEY_HOME then
        self.cursorPos = 0
    elseif keyCode == KEY_END then
        self.cursorPos = string.len(self.text)
    elseif keyCode == KEY_ENTER and self.OnEnter then
        self:OnEnter()
    end
end

-- Исправленная обработка символов
function PANEL:OnTextEntered()
    -- Пустая функция для совместимости
end

function PANEL:OnChar(char)
    if not self.focused then return end
    
    local charCode = string.byte(char)
    
    -- Проверяем печатаемые символы
    if charCode >= 32 and charCode <= 126 then
        -- Проверяем, что это число, точка или минус для числовых полей
        if self.numbersOnly then
            if not string.match(char, "[0-9%.%-]") then
                return
            end
        end
        
        self.text = string.sub(self.text, 1, self.cursorPos) .. char .. string.sub(self.text, self.cursorPos + 1)
        self.cursorPos = self.cursorPos + 1
        self:OnTextChanged()
    end
end

function PANEL:SetNumbersOnly(bool)
    self.numbersOnly = bool
end

-- КРИТИЧЕСКИ ВАЖНО: эти методы должны возвращать true для правильной работы
function PANEL:ShouldAcceptInput()
    return true
end

function PANEL:AllowInput(char)
    return true
end

vgui.Register("VCS_ModernTextEntry", PANEL, "DPanel")

-- СТИЛИЗОВАННАЯ обертка для DTextEntry с кастомным дизайном
local PANEL = {}

function PANEL:Init()
    self.placeholder = ""
    
    -- Создаем DTextEntry внутри
    self.realEntry = vgui.Create("DTextEntry", self)
    self.realEntry:SetPaintBackground(false) -- Убираем стандартный фон
    self.realEntry:SetTextColor(colors.text)
    self.realEntry:SetCursorColor(colors.text)
    self.realEntry:SetFont("VCS_RobotoDefault")
    
    -- Сразу устанавливаем размеры
    self:PerformLayout()
    
    -- Перенаправляем методы к реальному полю
    self.realEntry.OnChange = function()
        if self.OnTextChanged then
            self:OnTextChanged()
        end
    end
    
    self.realEntry.OnEnter = function()
        if self.OnEnter then
            self:OnEnter()
        end
    end
end

function PANEL:PerformLayout()
    if IsValid(self.realEntry) then
        -- Устанавливаем размеры сразу без таймера
        self.realEntry:SetPos(5, 2)
        self.realEntry:SetSize(self:GetWide() - 10, self:GetTall() - 4)
    end
end

function PANEL:Paint(w, h)
    -- КАСТОМНЫЙ ДИЗАЙН В СТИЛЕ VCS - фон с закругленными углами
    local focused = IsValid(self.realEntry) and self.realEntry:HasFocus()
    local bgColor = focused and Color(colors.inputBg.r + 15, colors.inputBg.g + 15, colors.inputBg.b + 15) or colors.inputBg
    draw.RoundedBox(8, 0, 0, w, h, bgColor)
    
    -- КАСТОМНАЯ РАМКА В СТИЛЕ VCS
    local borderColor = focused and colors.primary or colors.inputBorder
    surface.SetDrawColor(borderColor)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
    
    -- КАСТОМНЫЙ PLACEHOLDER В СТИЛЕ VCS
    if IsValid(self.realEntry) and self.realEntry:GetValue() == "" and self.placeholder ~= "" and not focused then
        surface.SetFont("VCS_RobotoDefault")
        surface.SetTextColor(colors.textMuted)
        surface.SetTextPos(10, (h - 16) / 2)
        surface.DrawText(self.placeholder)
    end
    
    return true
end

function PANEL:SetPlaceholderText(text)
    self.placeholder = text or ""
end

function PANEL:SetValue(text)
    if IsValid(self.realEntry) then
        self.realEntry:SetValue(tostring(text or ""))
    end
end

function PANEL:GetValue()
    if IsValid(self.realEntry) then
        return self.realEntry:GetValue()
    end
    return ""
end

-- ПРОСТОЕ управление типом поля - используем встроенную логику GMod
function PANEL:SetNumbersOnly(bool)
    if IsValid(self.realEntry) then
        self.realEntry:SetNumeric(bool) -- Встроенная валидация GMod
    end
end

function PANEL:RequestFocus()
    if IsValid(self.realEntry) then
        self.realEntry:RequestFocus()
        return true
    end
    return false
end

-- ПРАВИЛЬНАЯ обработка клика мыши для фокуса
function PANEL:OnMousePressed(keyCode)
    if keyCode == MOUSE_LEFT and IsValid(self.realEntry) then
        self.realEntry:RequestFocus()
        self:MouseCapture(true)
        return true
    end
    return false
end

function PANEL:OnMouseReleased(keyCode)
    if keyCode == MOUSE_LEFT then
        self:MouseCapture(false)
    end
end

-- ПРАВИЛЬНАЯ установка размеров
function PANEL:SetSize(w, h)
    DPanel.SetSize(self, w, h)
    self:PerformLayout()
end

function PANEL:OnSizeChanged(w, h)
    self:PerformLayout()
end

-- Методы для полной совместимости
function PANEL:SetMouseInputEnabled(enabled)
    DPanel.SetMouseInputEnabled(self, enabled)
    if IsValid(self.realEntry) then
        self.realEntry:SetMouseInputEnabled(enabled)
    end
end

function PANEL:SetKeyboardInputEnabled(enabled)
    DPanel.SetKeyboardInputEnabled(self, enabled)
    if IsValid(self.realEntry) then
        self.realEntry:SetKeyboardInputEnabled(enabled)
    end
end

vgui.Register("VCS_StyledTextEntry", PANEL, "DPanel")

-- Получение данных о активной технике
net.Receive("VCS_SendActiveVehicles", function()
    local activeVehicles = net.ReadTable()
    local plugin = ix.plugin.Get("vehicle_call_system")
    if plugin then
        plugin.activeVehicles = activeVehicles
        print("[VCS] Получены данные о " .. #activeVehicles .. " активных ТС")
        
        -- Обновляем все открытые интерфейсы
        for _, panel in pairs(vgui.GetWorldPanel():GetChildren()) do
            if IsValid(panel) then
                -- Обновляем списки техники в терминалах и датападах
                if panel.RefreshVehicleData then
                    panel:RefreshVehicleData()
                    print("[VCS] Обновлен интерфейс техники")
                end
                
                -- Обновляем активную технику в улучшенных датападах
                if panel.UpdateActiveVehicles then
                    panel:UpdateActiveVehicles()
                    print("[VCS] Обновлен список активной техники")
                end
            end
        end
    end
end)

-- УПРОЩЕННОЕ получение позиций для датапада - теперь используем ту же логику что и терминалы
net.Receive("VCS_SendNearbyPositions", function()
    local vehicleType = net.ReadString()
    local nearbyPositions = net.ReadTable()
    print("[VCS] Получены позиции для " .. vehicleType .. ": " .. #nearbyPositions .. " (игнорируем - используем прямую загрузку)")
    
    -- Больше не используем эти данные, так как датапады теперь работают как терминалы
    -- Все позиции загружаются напрямую из plugin.spawnPositions
end)

-- Функция создания меню управления позициями спавна
function PLUGIN:CreateSpawnManagerInterface()
    -- Проверяем и закрываем существующий менеджер позиций
    EnsureUniqueFrame("spawnManager")
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(1600, 900) -- Еще больше увеличиваем размер
    frame:Center()
    frame:SetTitle("")
    frame:SetVisible(true)
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    
    -- Убираем стандартный заголовок полностью
    frame:SetDeleteOnClose(true)
    
    frame.Paint = function(self, w, h)
        -- Полностью перекрываем стандартное рисование
        draw.RoundedBox(16, 0, 0, w, h, colors.background)
        
        -- Заголовок
        surface.SetFont("VCS_RobotoLarge")
        surface.SetTextColor(colors.text)
        surface.SetTextPos(30, 20)
        surface.DrawText("Менеджер позиций спавна техники")
        
        surface.SetFont("VCS_RobotoDefault")
        surface.SetTextColor(colors.textSecondary)
        surface.SetTextPos(30, 55)
        surface.DrawText("Управление позициями для воздушной и наземной техники")
    end
    
    -- Кнопка закрытия с правильной обработкой
    local closeBtn = vgui.Create("VCS_ModernButton", frame)
    closeBtn:SetPos(frame:GetWide() - 50, 10)
    closeBtn:SetSize(40, 40)
    closeBtn:SetText("X")
    closeBtn:SetBackgroundColor(colors.error)
    closeBtn.DoClick = function()
        frame:SetVisible(false)
        frame:Remove()
    end
    
    -- Левая панель - список позиций (расширена)
    local leftPanel = vgui.Create("VCS_ModernPanel", frame)
    leftPanel:SetPos(20, 90)
    leftPanel:SetSize(780, 790) -- Еще больше увеличиваем размер
    leftPanel:SetTitle("Существующие позиции", "Выберите тип для просмотра")
    
    local typeSelector = vgui.Create("VCS_ModernComboBox", leftPanel)
    typeSelector:SetPos(20, 75)
    typeSelector:SetSize(740, 30)
    typeSelector:SetValue("Выберите тип техники")
    typeSelector:AddChoice("Воздушная техника", "air")
    typeSelector:AddChoice("Наземная техника", "ground")
    
    local positionsList = vgui.Create("VCS_ModernList", leftPanel)
    positionsList:SetPos(20, 115)
    positionsList:SetSize(740, 590) -- Еще больше увеличиваем размер
    
    local deleteButton = vgui.Create("VCS_ModernButton", leftPanel)
    deleteButton:SetPos(20, 720)
    deleteButton:SetSize(740, 50)
    deleteButton:SetText("Удалить выбранную позицию")
    deleteButton:SetBackgroundColor(colors.error)
    
    -- Правая панель - добавление новой позиции (расширена)
    local rightPanel = vgui.Create("VCS_ModernPanel", frame)
    rightPanel:SetPos(820, 90)
    rightPanel:SetSize(760, 790) -- Еще больше увеличиваем размер
    rightPanel:SetTitle("Добавить позицию", "Создание новой позиции спавна")
    
    -- Тип техники для добавления
    local addTypeSelector = vgui.Create("VCS_ModernComboBox", rightPanel)
    addTypeSelector:SetPos(20, 75)
    addTypeSelector:SetSize(720, 30)
    addTypeSelector:SetValue("Выберите тип техники")
    addTypeSelector:AddChoice("Воздушная техника", "air")
    addTypeSelector:AddChoice("Наземная техника", "ground")
    
    -- Описание с кастомным заголовком
    rightPanel.Paint = function(self, w, h)
        -- Основной фон с закругленными углами
        draw.RoundedBox(12, 0, 0, w, h, colors.surface)
        
        -- Тень
        draw.RoundedBox(12, 2, 2, w, h, Color(0, 0, 0, 30))
        
        -- Заголовок
        surface.SetFont("VCS_RobotoMedium")
        surface.SetTextColor(colors.text)
        surface.SetTextPos(20, 15)
        surface.DrawText("Добавить позицию")
        
        surface.SetFont("VCS_RobotoSmall")
        surface.SetTextColor(colors.textSecondary)
        surface.SetTextPos(20, 45)
        surface.DrawText("Создание новой позиции спавна")
        
        -- Описание позиции
        surface.SetFont("VCS_RobotoDefault")
        surface.SetTextColor(colors.text)
        surface.SetTextPos(20, 120)
        surface.DrawText("Описание позиции:")
        
        -- Координаты
        surface.SetTextPos(20, 195)
        surface.DrawText("Координаты:")
        
        -- Углы поворота
        surface.SetTextPos(20, 275)
        surface.DrawText("Углы поворота:")
        
        return true
    end
    
    local descEntry = vgui.Create("VCS_StyledTextEntry", rightPanel)
    descEntry:SetPos(20, 145)
    descEntry:SetSize(720, 35)
    descEntry:SetPlaceholderText("Например: ВПП 2, Ангар 1, Парковка А")
    descEntry:SetNumbersOnly(false) -- Любой текст
    
    -- Функция создания кастомного числового поля
    local function createCoordInput(parent, x, y, label, placeholder)
        -- Создаем отдельную панель для метки
        local labelPanel = vgui.Create("DLabel", parent)
        labelPanel:SetPos(x, y + 5)
        labelPanel:SetSize(30, 20)
        labelPanel:SetText(label)
        labelPanel:SetFont("VCS_RobotoSmall")
        labelPanel:SetTextColor(colors.textSecondary)
        
        -- ИСПОЛЬЗУЕМ СТИЛИЗОВАННЫЙ VCS_StyledTextEntry для координат
        local entry = vgui.Create("VCS_StyledTextEntry", parent)
        entry:SetPos(x + 35, y)
        entry:SetSize(160, 30) -- Увеличиваем ширину еще больше
        entry:SetPlaceholderText(placeholder)
        entry:SetNumbersOnly(true) -- Только числа
        
        return entry
    end
    
    local xEntry = createCoordInput(rightPanel, 20, 225, "X:", "0.00")
    local yEntry = createCoordInput(rightPanel, 250, 225, "Y:", "0.00")
    local zEntry = createCoordInput(rightPanel, 480, 225, "Z:", "0.00")
    
    local pitchEntry = createCoordInput(rightPanel, 20, 305, "P:", "0.00")
    local yawEntry = createCoordInput(rightPanel, 250, 305, "Y:", "0.00")
    local rollEntry = createCoordInput(rightPanel, 480, 305, "R:", "0.00")
    
    -- Кнопка получения позиции игрока
    local getPlayerPosButton = vgui.Create("VCS_ModernButton", rightPanel)
    getPlayerPosButton:SetPos(20, 355)
    getPlayerPosButton:SetSize(720, 45)
    getPlayerPosButton:SetText("Получить мою позицию")
    getPlayerPosButton:SetBackgroundColor(colors.warning)
    
    getPlayerPosButton.DoClick = function()
        local ply = LocalPlayer()
        local eyePos = ply:EyePos()
        local eyeAngles = ply:EyeAngles()
        
        -- Делаем трейс от глаз игрока вниз до земли
        local tr = util.TraceLine({
            start = eyePos,
            endpos = eyePos + Vector(0, 0, -2000), -- Трейс вниз на 2000 единиц
            filter = ply
        })
        
        local groundPos = tr.Hit and tr.HitPos or ply:GetPos()
        local angles = Angle(0, eyeAngles.y, 0) -- Используем только yaw, убираем pitch и roll
        
        xEntry:SetValue(string.format("%.2f", groundPos.x))
        yEntry:SetValue(string.format("%.2f", groundPos.y))
        zEntry:SetValue(string.format("%.2f", groundPos.z))
        pitchEntry:SetValue("0") -- Всегда 0 для техники
        yawEntry:SetValue(string.format("%.2f", angles.y))
        rollEntry:SetValue("0") -- Всегда 0 для техники
        
        notification.AddLegacy("Позиция под ногами получена!", NOTIFY_GENERIC, 3)
    end
    
    -- Кнопка добавления позиции
    local addButton = vgui.Create("VCS_ModernButton", rightPanel)
    addButton:SetPos(20, 415)
    addButton:SetSize(720, 55)
    addButton:SetText("ДОБАВИТЬ ПОЗИЦИЮ")
    addButton:SetBackgroundColor(colors.success)
    
    addButton.DoClick = function()
        local addTypeID = addTypeSelector:GetSelectedID() or 1
        local vehicleTypeData = addTypeSelector:GetOptionData(addTypeID)
        local description = descEntry:GetValue()
        
        print("[VCS] Debug: addTypeSelector selectedID = " .. tostring(addTypeID))
        print("[VCS] Debug: addTypeSelector vehicleTypeData = " .. tostring(vehicleTypeData))
        
        if not vehicleTypeData or vehicleTypeData == "" then
            notification.AddLegacy("Выберите тип техники!", NOTIFY_ERROR, 3)
            return
        end
        
        if description == "" then
            notification.AddLegacy("Введите описание позиции!", NOTIFY_ERROR, 3)
            return
        end
        
        if editMode and editingPosition then
            -- Режим редактирования
            net.Start("VCS_EditSpawnPosition")
            net.WriteString(vehicleTypeData)
            net.WriteUInt(editingPosition.id, 16)
            net.WriteFloat(tonumber(xEntry:GetValue()) or 0)
            net.WriteFloat(tonumber(yEntry:GetValue()) or 0)
            net.WriteFloat(tonumber(zEntry:GetValue()) or 0)
            net.WriteFloat(tonumber(pitchEntry:GetValue()) or 0)
            net.WriteFloat(tonumber(yawEntry:GetValue()) or 0)
            net.WriteFloat(tonumber(rollEntry:GetValue()) or 0)
            net.WriteString(description)
            net.SendToServer()
            
            notification.AddLegacy("Позиция обновлена!", NOTIFY_GENERIC, 3)
        else
            -- Режим добавления
            net.Start("VCS_AddSpawnPosition")
            net.WriteString(vehicleTypeData)
            net.WriteFloat(tonumber(xEntry:GetValue()) or 0)
            net.WriteFloat(tonumber(yEntry:GetValue()) or 0)
            net.WriteFloat(tonumber(zEntry:GetValue()) or 0)
            net.WriteFloat(tonumber(pitchEntry:GetValue()) or 0)
            net.WriteFloat(tonumber(yawEntry:GetValue()) or 0)
            net.WriteFloat(tonumber(rollEntry:GetValue()) or 0)
            net.WriteString(description)
            net.SendToServer()
            
            notification.AddLegacy("Позиция добавлена!", NOTIFY_GENERIC, 3)
        end
        
        -- Очищаем поля и выходим из режима редактирования
        descEntry:SetValue("")
        xEntry:SetValue("0")
        yEntry:SetValue("0")
        zEntry:SetValue("0")
        pitchEntry:SetValue("0")
        yawEntry:SetValue("0")
        rollEntry:SetValue("0")
        
        editMode = false
        editingPosition = nil
        addButton:SetText("ДОБАВИТЬ ПОЗИЦИЮ")
        addButton:SetBackgroundColor(colors.success)
    end
    
    -- Переменная для отслеживания режима редактирования
    local editMode = false
    local editingPosition = nil
    
    -- Функция обновления списка позиций
    local function RefreshPositionsList()
        if not IsValid(positionsList) then return end
        
        positionsList:Clear()
        
        local selectedType = typeSelector:GetSelected()
        if not selectedType then return end
        
        local plugin = ix.plugin.Get("vehicle_call_system")
        if not plugin or not plugin.spawnPositions then return end
        
        for _, spawnData in ipairs(plugin.spawnPositions[selectedType] or {}) do
            local coordsText = string.format("%.0f, %.0f, %.0f", spawnData.pos.x, spawnData.pos.y, spawnData.pos.z)
            local anglesText = string.format("%.0f°, %.0f°, %.0f°", spawnData.ang.p, spawnData.ang.y, spawnData.ang.r)
            
            positionsList:AddItem(
                spawnData.description,
                "Координаты: " .. coordsText .. " • Углы: " .. anglesText,
                "",
                "#" .. spawnData.id,
                colors.accent,
                spawnData
            )
        end
    end
    
    -- Функция загрузки позиции в поля редактирования
    local function LoadPositionToEditor(positionData)
        if not positionData then return end
        
        descEntry:SetValue(positionData.description)
        xEntry:SetValue(string.format("%.2f", positionData.pos.x))
        yEntry:SetValue(string.format("%.2f", positionData.pos.y))
        zEntry:SetValue(string.format("%.2f", positionData.pos.z))
        pitchEntry:SetValue(string.format("%.2f", positionData.ang.p))
        yawEntry:SetValue(string.format("%.2f", positionData.ang.y))
        rollEntry:SetValue(string.format("%.2f", positionData.ang.r))
        
        -- ИСПРАВЛЕНО: Устанавливаем правильный тип в комбобоксе
        local currentTypeID = typeSelector:GetSelectedID() or 1
        local currentTypeData = typeSelector:GetOptionData(currentTypeID)
        print("[VCS] Debug: currentTypeData = " .. tostring(currentTypeData))
        
        if currentTypeData == "air" then
            addTypeSelector:SelectOption(1) -- Воздушная техника
        elseif currentTypeData == "ground" then
            addTypeSelector:SelectOption(2) -- Наземная техника
        end
        
        editMode = true
        editingPosition = positionData
        
        -- Меняем текст кнопки
        addButton:SetText("СОХРАНИТЬ ИЗМЕНЕНИЯ")
        addButton:SetBackgroundColor(colors.warning)
    end
    
    -- Обработка выбора типа техники
    typeSelector.OnSelect = function(self, index, value, data)
        print("[VCS] Debug: typeSelector selected value = " .. tostring(data))
        RefreshPositionsList()
    end
    
    -- Обработка выбора позиции для редактирования
    positionsList.OnItemSelected = function(self, index, item)
        if item and item.data then
            LoadPositionToEditor(item.data)
        end
    end
    
    -- Кнопка отмены редактирования
    local cancelEditButton = vgui.Create("VCS_ModernButton", rightPanel)
    cancelEditButton:SetPos(20, 485)
    cancelEditButton:SetSize(300, 40)
    cancelEditButton:SetText("ОТМЕНИТЬ РЕДАКТИРОВАНИЕ")
    cancelEditButton:SetBackgroundColor(colors.textMuted)
    cancelEditButton:SetVisible(false)
    
    cancelEditButton.DoClick = function()
        -- Очищаем поля
        descEntry:SetValue("")
        xEntry:SetValue("0")
        yEntry:SetValue("0")
        zEntry:SetValue("0")
        pitchEntry:SetValue("0")
        yawEntry:SetValue("0")
        rollEntry:SetValue("0")
        
        editMode = false
        editingPosition = nil
        addButton:SetText("ДОБАВИТЬ ПОЗИЦИЮ")
        addButton:SetBackgroundColor(colors.success)
        cancelEditButton:SetVisible(false)
    end
    
    -- Обновляем функцию LoadPositionToEditor для показа кнопки отмены
    local oldLoadPositionToEditor = LoadPositionToEditor
    LoadPositionToEditor = function(positionData)
        oldLoadPositionToEditor(positionData)
        cancelEditButton:SetVisible(true)
    end
    
    -- Обработка удаления позиции
    deleteButton.DoClick = function()
        if not IsValid(positionsList) then return end
        
        local selected = positionsList:GetSelected()
        if not selected then
            notification.AddLegacy("Выберите позицию для удаления!", NOTIFY_ERROR, 3)
            return
        end
        
        -- ИСПРАВЛЕНО: Правильно получаем тип техники
        local selectedTypeID = typeSelector:GetSelectedID() or 1
        local selectedTypeData = typeSelector:GetOptionData(selectedTypeID)
        if not selectedTypeData then
            notification.AddLegacy("Выберите тип техники!", NOTIFY_ERROR, 3)
            return
        end
        
        net.Start("VCS_RemoveSpawnPosition")
        net.WriteString(selectedTypeData)
        net.WriteUInt(selected.data.id, 16)
        net.SendToServer()
        
        notification.AddLegacy("Позиция удалена!", NOTIFY_GENERIC, 3)
    end
    
    -- Сохраним ссылку на функцию обновления для использования в колбэке
    frame.RefreshPositionsList = RefreshPositionsList
    
    -- Регистрируем окно в системе контроля уникальности
    RegisterFrame("spawnManager", frame)
    
    -- Запрашиваем актуальные данные ТОЛЬКО при открытии
    net.Start("VCS_GetSpawnPositions")
    net.SendToServer()
    
    return frame
end

-- Получение позиций спавна
net.Receive("VCS_SendSpawnPositions", function()
    local spawnPositions = net.ReadTable()
    local plugin = ix.plugin.Get("vehicle_call_system")
    if plugin then
        plugin.spawnPositions = spawnPositions
        
        -- Обновляем список в открытом менеджере позиций, если он существует
        for _, panel in pairs(vgui.GetWorldPanel():GetChildren()) do
            if IsValid(panel) then
                if panel.RefreshPositionsList then
                    panel.RefreshPositionsList()
                end
                
                -- Обновляем позиции в датападах напрямую
                if panel.LoadPositionsDirectly then
                    panel.LoadPositionsDirectly()
                    print("[VCS] Обновлены позиции в датападе напрямую")
                end
            end
        end
    end
end)

-- Функция создания терминала вызова техники с актуальными данными
function PLUGIN:CreateTerminalInterface(vehicleType)
    -- Проверяем и закрываем существующий терминал этого типа
    EnsureUniqueFrame("terminal", vehicleType)
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(1250, 800) -- Еще больше увеличиваем размер
    frame:Center()
    frame:SetTitle("")
    frame:SetVisible(true)
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame:SetDeleteOnClose(true)
    
    local typeName = vehicleType == "air" and "воздушной" or "наземной"
    
    frame.Paint = function(self, w, h)
        draw.RoundedBox(16, 0, 0, w, h, colors.background)
        
        -- Заголовок
        surface.SetFont("VCS_RobotoLarge")
        surface.SetTextColor(colors.text)
        surface.SetTextPos(30, 20)
        surface.DrawText("Терминал вызова " .. typeName .. " техники")
        
        surface.SetFont("VCS_RobotoDefault")
        surface.SetTextColor(colors.textSecondary)
        surface.SetTextPos(30, 55)
        surface.DrawText("Выберите технику и позицию для вызова")
    end
    
    -- Кнопка закрытия
    local closeBtn = vgui.Create("VCS_ModernButton", frame)
    closeBtn:SetPos(frame:GetWide() - 50, 10)
    closeBtn:SetSize(40, 40)
    closeBtn:SetText("X")
    closeBtn:SetBackgroundColor(colors.error)
    closeBtn.DoClick = function()
        frame:SetVisible(false)
        frame:Remove()
    end
    
    -- Панель выбора техники (расширена)
    local vehiclePanel = vgui.Create("VCS_ModernPanel", frame)
    vehiclePanel:SetPos(20, 90)
    vehiclePanel:SetSize(750, 580) -- Еще больше увеличиваем размер
    vehiclePanel:SetTitle("Доступная техника", "Выберите технику для вызова")
    
    local vehicleList = vgui.Create("VCS_ModernList", vehiclePanel)
    vehicleList:SetPos(20, 75)
    vehicleList:SetSize(710, 430) -- ИСПРАВЛЕНО: уменьшаем высоту списка для кнопки
    
    -- Функция обновления списка техники БЕЗ автоматических запросов
    local function RefreshVehicleList()
        if not IsValid(vehicleList) then return end
        
        vehicleList:Clear()
        
        -- Получаем доступную технику для игрока
        local plugin = ix.plugin.Get("vehicle_call_system")
        local availableVehicles = plugin and plugin:GetAvailableVehiclesForPlayer(LocalPlayer(), vehicleType) or {}
        
        for _, vehicleData in ipairs(availableVehicles) do
            -- Подсчитываем активную технику этого класса
            local activeCount = 0
            if PLUGIN.activeVehicles then
                for _, activeVehicle in ipairs(PLUGIN.activeVehicles) do
                    if activeVehicle.type == vehicleType and activeVehicle.name == vehicleData.name then
                        activeCount = activeCount + 1
                    end
                end
            end
            
            local status = string.format("%d/%d", activeCount, vehicleData.maxActive)
            local statusColor = colors.success
            
            if activeCount >= vehicleData.maxActive then
                status = status .. " ЛИМИТ"
                statusColor = colors.error
            end
            
            vehicleList:AddItem(
                vehicleData.name,
                vehicleData.description or "Техника",
                "",
                status,
                statusColor,
                vehicleData
            )
        end
        
        print("[VCS] Обновлен список техники в терминале, элементов: " .. #availableVehicles)
    end
    
    -- Добавляем функцию обновления к фрейму
    frame.RefreshVehicleData = RefreshVehicleList
    
    -- Регистрируем окно в системе контроля уникальности
    RegisterFrame("terminal", frame, vehicleType)
    
    -- Кнопка ручного обновления
    local refreshButton = vgui.Create("VCS_ModernButton", vehiclePanel)
    refreshButton:SetPos(20, 520) -- ИСПРАВЛЕНО: перемещаем кнопку ниже списка
    refreshButton:SetSize(120, 30)
    refreshButton:SetText("Обновить")
    refreshButton:SetBackgroundColor(colors.accent)
    
    refreshButton.DoClick = function()
        -- Запрашиваем актуальные данные только по клику
        net.Start("VCS_GetActiveVehicles")
        net.SendToServer()
        print("[VCS] Запрошены актуальные данные о технике")
    end
    
    -- Первоначальная загрузка ОДИН РАЗ
    RefreshVehicleList()
    
    -- Панель выбора позиции (расширена)
    local positionPanel = vgui.Create("VCS_ModernPanel", frame)
    positionPanel:SetPos(790, 90)
    positionPanel:SetSize(440, 580) -- Еще больше увеличиваем размер
    positionPanel:SetTitle("Позиции спавна", "Выберите место")
    
    local spawnList = vgui.Create("VCS_ModernList", positionPanel)
    spawnList:SetPos(20, 75)
    spawnList:SetSize(400, 485) -- Еще больше увеличиваем размер
    
    -- Добавляем позиции спавна
    local positions = {}
    local plugin = ix.plugin.Get("vehicle_call_system")
    if plugin and plugin.spawnPositions then
        positions = plugin.spawnPositions[vehicleType] or {}
    end
    
    for i, spawnData in ipairs(positions) do
        spawnList:AddItem(
            spawnData.description or ("Позиция " .. i),
            string.format("%.0f, %.0f, %.0f", spawnData.pos.x, spawnData.pos.y, spawnData.pos.z),
            "",
            nil,
            nil,
            {spawnIndex = i}
        )
    end
    
    -- Кнопка вызова
    local spawnButton = vgui.Create("VCS_ModernButton", frame)
    spawnButton:SetPos(20, 690)
    spawnButton:SetSize(1210, 70) -- Еще больше увеличиваем размер
    spawnButton:SetText("ВЫЗВАТЬ ТЕХНИКУ")
    spawnButton:SetBackgroundColor(colors.success)
    
    spawnButton.DoClick = function()
        if not IsValid(vehicleList) or not IsValid(spawnList) then return end
        
        local selectedVehicle = vehicleList:GetSelected()
        local selectedPosition = spawnList:GetSelected()
        
        if not selectedVehicle then
            notification.AddLegacy("Выберите технику!", NOTIFY_ERROR, 3)
            return
        end
        
        if not selectedPosition then
            notification.AddLegacy("Выберите позицию спавна!", NOTIFY_ERROR, 3)
            return
        end
        
        net.Start("VCS_SpawnVehicle")
        net.WriteString(vehicleType)
        net.WriteString(selectedVehicle.data.name)
        net.WriteUInt(selectedPosition.data.spawnIndex, 8)
        net.WriteString("terminal")
        net.SendToServer()
        
        frame:SetVisible(false)
        frame:Remove()
        notification.AddLegacy("Техника вызывается...", NOTIFY_GENERIC, 5)
    end
    
    return frame
end

-- Получение логов
net.Receive("VCS_SendLogs", function()
    local logs = net.ReadTable()
    local plugin = ix.plugin.Get("vehicle_call_system")
    if plugin then
        plugin.currentLogs = logs
        print("[VCS] Получено логов: " .. #logs)
    end
end)

-- Функция создания лог терминала
function PLUGIN:CreateLogTerminalInterface(vehicleType)
    -- Проверяем и закрываем существующий лог терминал этого типа
    EnsureUniqueFrame("logTerminal", vehicleType)
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(1400, 950) -- Еще больше увеличиваем размер
    frame:Center()
    frame:SetTitle("")
    frame:SetVisible(true)
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame:SetDeleteOnClose(true)
    
    local typeName = vehicleType == "air" and "воздушной" or "наземной"
    
    frame.Paint = function(self, w, h)
        draw.RoundedBox(16, 0, 0, w, h, colors.background)
        
        -- Заголовок
        surface.SetFont("VCS_RobotoLarge")
        surface.SetTextColor(colors.text)
        surface.SetTextPos(30, 20)
        surface.DrawText("Лог терминал " .. typeName .. " техники")
        
        surface.SetFont("VCS_RobotoDefault")
        surface.SetTextColor(colors.textSecondary)
        surface.SetTextPos(30, 55)
        surface.DrawText("История вызовов и операций с техникой")
    end
    
    -- Кнопка закрытия
    local closeBtn = vgui.Create("VCS_ModernButton", frame)
    closeBtn:SetPos(frame:GetWide() - 50, 10)
    closeBtn:SetSize(40, 40)
    closeBtn:SetText("X")
    closeBtn:SetBackgroundColor(colors.error)
    closeBtn.DoClick = function()
        frame:SetVisible(false)
        frame:Remove()
    end
    
    -- Панель фильтров
    local filterPanel = vgui.Create("VCS_ModernPanel", frame)
    filterPanel:SetPos(20, 90)
    filterPanel:SetSize(1360, 120)
    filterPanel:SetTitle("Фильтры и поиск", "Настройте отображение логов")
    
    -- ПОЛЕ ПОИСКА - стилизованный VCS_StyledTextEntry
    local searchEntry = vgui.Create("VCS_StyledTextEntry", filterPanel)
    searchEntry:SetPos(20, 75)
    searchEntry:SetSize(300, 35)
    searchEntry:SetPlaceholderText("Поиск по игроку или технике...")
    searchEntry:SetNumbersOnly(false) -- Любой текст
    
    -- Фильтр по действию
    local actionFilter = vgui.Create("VCS_ModernComboBox", filterPanel)
    actionFilter:SetPos(340, 75)
    actionFilter:SetSize(200, 35)
    actionFilter:AddChoice("Все действия", "all")
    actionFilter:AddChoice("Только вызовы", "spawned")
    actionFilter:AddChoice("Только удаления", "removed")
    actionFilter:SetValue("Все действия")
    
    -- Фильтр по времени
    local timeFilter = vgui.Create("VCS_ModernComboBox", filterPanel)
    timeFilter:SetPos(560, 75)
    timeFilter:SetSize(200, 35)
    timeFilter:AddChoice("За всё время", "all")
    timeFilter:AddChoice("За последний час", "1h")
    timeFilter:AddChoice("За последние 6 часов", "6h")
    timeFilter:AddChoice("За последние 24 часа", "24h")
    timeFilter:AddChoice("За последнюю неделю", "7d")
    timeFilter:SetValue("За всё время")
    
    -- Кнопка применения фильтров
    local applyFiltersButton = vgui.Create("VCS_ModernButton", filterPanel)
    applyFiltersButton:SetPos(780, 75)
    applyFiltersButton:SetSize(120, 35)
    applyFiltersButton:SetText("Применить")
    applyFiltersButton:SetBackgroundColor(colors.primary)
    
    -- Кнопка сброса фильтров
    local resetFiltersButton = vgui.Create("VCS_ModernButton", filterPanel)
    resetFiltersButton:SetPos(920, 75)
    resetFiltersButton:SetSize(120, 35)
    resetFiltersButton:SetText("Сбросить")
    resetFiltersButton:SetBackgroundColor(colors.textMuted)
    
    -- Панель логов (расширена)
    local logPanel = vgui.Create("VCS_ModernPanel", frame)
    logPanel:SetPos(20, 220) -- Сдвигаем вниз под фильтры
    logPanel:SetSize(1360, 570) -- Увеличиваем высоту значительно
    logPanel:SetTitle("История операций", "Последние действия с техникой")
    
    local logList = vgui.Create("VCS_ModernList", logPanel)
    logList:SetPos(20, 75)
    logList:SetSize(1320, 475) -- Увеличиваем размер значительно
    logList.itemHeight = 60 -- Увеличим высоту для более детального отображения
    
    -- Кнопка обновления
    local refreshButton = vgui.Create("VCS_ModernButton", frame)
    refreshButton:SetPos(20, 900) -- Сдвигаем еще ниже
    refreshButton:SetSize(150, 40)
    refreshButton:SetText("Обновить")
    refreshButton:SetBackgroundColor(colors.accent)
    
    -- Функция загрузки логов БЕЗ автоматических запросов
    local function RefreshLogs()
        if not IsValid(logList) then return end
        
        logList:Clear()
        
        -- Запрашиваем логи с сервера ТОЛЬКО при нажатии кнопки
        net.Start("VCS_GetLogs")
        net.WriteString(vehicleType)
        net.SendToServer()
        
        print("[VCS] Запрошены логи для типа: " .. vehicleType)
    end
    
    -- Переменные для хранения всех логов и фильтров
    local allLogs = {}
    local currentFilters = {
        search = "",
        action = "all",
        time = "all"
    }
    
    -- Функция фильтрации логов
    local function FilterLogs()
        if not allLogs or #allLogs == 0 then return {} end
        
        local filtered = {}
        local searchText = string.lower(currentFilters.search)
        local now = os.time()
        
        for _, log in ipairs(allLogs) do
            -- Фильтр по действию
            if currentFilters.action ~= "all" and log.action ~= currentFilters.action then
                continue
            end
            
            -- Фильтр по времени
            if currentFilters.time ~= "all" then
                local logTime = 0
                if log.timestamp and type(log.timestamp) == "string" then
                    -- Парсим timestamp формата "2025-01-27 15:30:45"
                    local year, month, day, hour, min, sec = log.timestamp:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
                    if year and month and day and hour and min and sec then
                        logTime = os.time({
                            year = tonumber(year), 
                            month = tonumber(month), 
                            day = tonumber(day), 
                            hour = tonumber(hour), 
                            min = tonumber(min), 
                            sec = tonumber(sec)
                        })
                        print("[VCS] Парсим дату: " .. log.timestamp .. " -> " .. logTime)
                    end
                end
                
                if logTime > 0 then
                    local timeDiff = now - logTime
                    local timeLimit = 0
                    
                    if currentFilters.time == "1h" then
                        timeLimit = 3600
                    elseif currentFilters.time == "6h" then
                        timeLimit = 21600
                    elseif currentFilters.time == "24h" then
                        timeLimit = 86400
                    elseif currentFilters.time == "7d" then
                        timeLimit = 604800
                    end
                    
                    print("[VCS] Разница времени: " .. timeDiff .. " сек, лимит: " .. timeLimit .. " сек")
                    
                    if timeLimit > 0 and timeDiff > timeLimit then
                        continue
                    end
                end
            end
            
            -- Фильтр по поиску
            if searchText ~= "" then
                local playerName = string.lower(log.player_name or "")
                local vehicleName = string.lower(log.vehicle_name or "")
                local steamID = string.lower(log.player_steamid or "")
                
                if not (string.find(playerName, searchText) or 
                       string.find(vehicleName, searchText) or 
                       string.find(steamID, searchText)) then
                    continue
                end
            end
            
            table.insert(filtered, log)
        end
        
        return filtered
    end
    
    -- Обработка полученных логов
    local function DisplayLogs(logs)
        if not IsValid(logList) then return end
        
        if logs then
            allLogs = logs
        end
        
        local filteredLogs = FilterLogs()
        logList:Clear()
        
        for _, log in ipairs(filteredLogs) do
            local actionText = log.action == "spawned" and "[+] Вызвал" or "[-] Удалил"
            local timeStr = "Неизвестно"
            
            -- Безопасно извлекаем время из timestamp
            if log.timestamp and type(log.timestamp) == "string" and string.len(log.timestamp) >= 19 then
                timeStr = string.sub(log.timestamp, 12, 19) -- Извлекаем время из timestamp
            elseif log.timestamp then
                timeStr = tostring(log.timestamp)
            end
            
            local spawnPosition = log.spawn_position or "Неизвестно"
            local steamID = log.player_steamid or "Неизвестно"
            
            logList:AddItem(
                actionText .. " " .. log.vehicle_name,
                "Игрок: " .. log.player_name .. " • Позиция: " .. spawnPosition,
                "",
                timeStr,
                log.action == "spawned" and colors.success or colors.error,
                log
            )
        end
        
        print("[VCS] Отображено логов: " .. #filteredLogs .. " из " .. #allLogs)
    end
    
    -- Обработка кнопок фильтров
    applyFiltersButton.DoClick = function()
        currentFilters.search = searchEntry:GetValue()
        
        -- ИСПРАВЛЕНО: Правильно получаем значения из комбобоксов с безопасной проверкой
        local actionID = actionFilter:GetSelectedID() or 1
        local timeID = timeFilter:GetSelectedID() or 1
        
        print("[VCS] Debug: selectedID actionFilter = " .. tostring(actionID))
        print("[VCS] Debug: selectedID timeFilter = " .. tostring(timeID))
        
        local actionData = actionFilter:GetOptionData(actionID)
        currentFilters.action = actionData or "all"
        
        local timeData = timeFilter:GetOptionData(timeID)
        currentFilters.time = timeData or "all"
        
        print("[VCS] Фильтры: action=" .. currentFilters.action .. ", time=" .. currentFilters.time .. ", search='" .. currentFilters.search .. "'")
        
        DisplayLogs() -- Перефильтровываем с новыми настройками
        notification.AddLegacy("Фильтры применены!", NOTIFY_GENERIC, 2)
    end
    
    resetFiltersButton.DoClick = function()
        searchEntry:SetValue("")
        
        -- ИСПРАВЛЕНО: Правильно сбрасываем комбобоксы
        actionFilter:SelectOption(1) -- Выбираем первую опцию "Все действия"
        timeFilter:SelectOption(1) -- Выбираем первую опцию "За всё время"
        
        currentFilters.search = ""
        currentFilters.action = "all"
        currentFilters.time = "all"
        
        DisplayLogs() -- Показываем все логи
        notification.AddLegacy("Фильтры сброшены!", NOTIFY_GENERIC, 2)
    end
    
    -- Детальная информация при клике на лог
    logList.OnItemSelected = function(self, index, item)
        if not item or not item.data then return end
        
        -- Закрываем все существующие окна детальной информации
        EnsureUniqueFrame("logDetail")
        
        local log = item.data
        local detailFrame = vgui.Create("DFrame")
        detailFrame:SetSize(500, 400)
        detailFrame:Center()
        detailFrame:SetTitle("")
        detailFrame:SetVisible(true)
        detailFrame:SetDraggable(true)
        detailFrame:ShowCloseButton(false)
        detailFrame:MakePopup()
        detailFrame:SetDeleteOnClose(true)
        
        detailFrame.Paint = function(self, w, h)
            draw.RoundedBox(16, 0, 0, w, h, colors.background)
            
            -- Заголовок
            surface.SetFont("VCS_RobotoLarge")
            surface.SetTextColor(colors.text)
            surface.SetTextPos(20, 15)
            surface.DrawText("Детальная информация")
        end
        
        -- Кнопка закрытия
        local closeDetailBtn = vgui.Create("VCS_ModernButton", detailFrame)
        closeDetailBtn:SetPos(detailFrame:GetWide() - 50, 10)
        closeDetailBtn:SetSize(40, 40)
        closeDetailBtn:SetText("X")
        closeDetailBtn:SetBackgroundColor(colors.error)
        closeDetailBtn.DoClick = function()
            detailFrame:Remove()
        end
        
        -- Регистрируем окно детальной информации
        RegisterFrame("logDetail", detailFrame)
        
        -- Панель с деталями
        local detailPanel = vgui.Create("VCS_ModernPanel", detailFrame)
        detailPanel:SetPos(20, 60)
        detailPanel:SetSize(460, 320)
        detailPanel:SetTitle("Информация о записи", "Подробные данные операции")
        
        -- Создаем текстовые метки с информацией
        local yPos = 80
        local function addDetailRow(label, value, color)
            color = color or colors.text
            
            -- Метка
            surface.SetFont("VCS_RobotoBold")
            local labelPanel = vgui.Create("DPanel", detailPanel)
            labelPanel:SetPos(20, yPos)
            labelPanel:SetSize(420, 25)
            labelPanel.Paint = function(self, w, h)
                surface.SetFont("VCS_RobotoBold")
                surface.SetTextColor(colors.textSecondary)
                surface.SetTextPos(0, 5)
                surface.DrawText(label .. ":")
                
                surface.SetFont("VCS_RobotoDefault")
                surface.SetTextColor(color)
                surface.SetTextPos(150, 5)
                surface.DrawText(tostring(value))
            end
            
            yPos = yPos + 30
        end
        
        -- Добавляем информацию
        addDetailRow("ID записи", log.id or "Неизвестно")
        addDetailRow("Игрок", log.player_name or "Неизвестно")
        addDetailRow("Steam ID", log.player_steamid or "Неизвестно")
        addDetailRow("Действие", log.action == "spawned" and "Вызов техники" or "Удаление техники", 
                    log.action == "spawned" and colors.success or colors.error)
        addDetailRow("Тип техники", log.vehicle_type == "air" and "Воздушная" or "Наземная")
        addDetailRow("Название техники", log.vehicle_name or "Неизвестно")
        addDetailRow("Позиция спавна", log.spawn_position or "Неизвестно")
        addDetailRow("Время", log.timestamp or "Неизвестно")
    end
    
    -- Обновляем отображение логов когда получаем данные
    local oldReceive = PLUGIN.currentLogs
    timer.Create("VCS_LogCheck_" .. tostring(frame), 0.5, 0, function()
        if not IsValid(frame) then
            timer.Remove("VCS_LogCheck_" .. tostring(frame))
            return
        end
        
        if PLUGIN.currentLogs ~= oldReceive then
            oldReceive = PLUGIN.currentLogs
            DisplayLogs(PLUGIN.currentLogs)
        end
    end)
    
    refreshButton.DoClick = RefreshLogs
    
    -- Регистрируем окно в системе контроля уникальности
    RegisterFrame("logTerminal", frame, vehicleType)
    
    -- Загружаем логи при открытии ОДИН РАЗ
    RefreshLogs()
    
    return frame
end

-- Хуки для открытия интерфейсов
net.Receive("VCS_OpenTerminal", function()
    local vehicleType = net.ReadString()
    local plugin = ix.plugin.Get("vehicle_call_system")
    if plugin then
        -- Запрашиваем актуальные позиции спавна перед открытием терминала
        net.Start("VCS_GetSpawnPositions")
        net.SendToServer()
        
        -- Открываем терминал через небольшую задержку
        timer.Simple(0.2, function()
            if plugin.CreateTerminalInterface then
                plugin:CreateTerminalInterface(vehicleType)
            end
        end)
    end
end)


net.Receive("VCS_OpenLogTerminal", function()
    local vehicleType = net.ReadString()
    local plugin = ix.plugin.Get("vehicle_call_system")
    if plugin and plugin.CreateLogTerminalInterface then
        plugin:CreateLogTerminalInterface(vehicleType)
    end
end)

net.Receive("VCS_OpenSpawnManager", function()
    local plugin = ix.plugin.Get("vehicle_call_system")
    if plugin and plugin.CreateSpawnManagerInterface then
        plugin:CreateSpawnManagerInterface()
    end
end)

-- Команда для принудительного закрытия всех VCS меню (полезная для админов)
concommand.Add("vcs_close_all", function()
    print("[VCS] Закрываем все VCS меню...")
    
    local closed = 0
    
    -- Закрываем менеджер позиций
    if SafeCloseFrame(VCS_OpenFrames.spawnManager) then
        VCS_OpenFrames.spawnManager = nil
        closed = closed + 1
    end
    
    -- Закрываем терминалы
    for type, frame in pairs(VCS_OpenFrames.terminal) do
        if SafeCloseFrame(frame) then
            VCS_OpenFrames.terminal[type] = nil
            closed = closed + 1
        end
    end
    
    -- Закрываем лог терминалы
    for type, frame in pairs(VCS_OpenFrames.logTerminal) do
        if SafeCloseFrame(frame) then
            VCS_OpenFrames.logTerminal[type] = nil
            closed = closed + 1
        end
    end
    
    -- Закрываем окна детальной информации
    for i, frame in pairs(VCS_OpenFrames.logDetail) do
        if SafeCloseFrame(frame) then
            closed = closed + 1
        end
    end
    VCS_OpenFrames.logDetail = {}
    
    print("[VCS] ✓ Закрыто окон: " .. closed)
end)
 