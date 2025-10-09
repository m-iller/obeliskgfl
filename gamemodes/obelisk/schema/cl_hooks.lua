
-- Here is where all of your clientside hooks should go.

-- Disables the crosshair permanently.
function Schema:CharacterLoaded(character)
    self:ExampleFunction("@serverWelcome", character:GetName())

    local cfg = ix and ix.configs and ix.configs.disclaimer
    if (not cfg or not isstring(cfg.text) or #cfg.text == 0) then
        return
    end

    if (cookie.GetString("ix_disclaimer_ack", "0") == "1") then
        return
    end

    -- Полноэкранный фон
    local overlay = vgui.Create("DPanel")
    overlay:SetSize(ScrW(), ScrH())
    overlay:SetPos(0, 0)
    overlay:MakePopup()
    overlay:SetKeyboardInputEnabled(true)
    overlay:SetMouseInputEnabled(true)
    
    -- Темный полупрозрачный фон
    overlay.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 200))
    end

    -- Основное окно дисклеймера
    local frame = vgui.Create("DPanel", overlay)
    frame:SetSize(ScrW() * 0.8, ScrH() * 0.85)
    frame:Center()
    frame:SetKeyboardInputEnabled(false)
    frame:SetMouseInputEnabled(true)
    
    -- Стилизованное окно с градиентом
    frame.Paint = function(self, w, h)
        -- Основной фон с градиентом
        draw.RoundedBox(8, 0, 0, w, h, Color(25, 25, 35, 250))
        
        -- Верхняя полоса
        draw.RoundedBoxEx(8, 0, 0, w, 4, Color(70, 130, 180, 255), true, true, false, false)
        
        -- Тень
        draw.RoundedBox(8, 2, 2, w, h, Color(0, 0, 0, 50))
    end

    local padding = 20
    frame:DockPadding(padding, padding + 10, padding, padding)

    -- Заголовок
    local title = vgui.Create("DLabel", frame)
    title:SetText("СОГЛАШЕНИЕ ОБ ИСПОЛЬЗОВАНИИ СЕРВЕРА")
    title:SetFont("DermaLarge")
    title:SetTextColor(Color(255, 255, 255))
    title:SetContentAlignment(5)
    title:Dock(TOP)
    title:SetTall(40)

    -- Скролл-панель для текста
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(0, 10, 0, 10)
    
    -- Стилизация скроллбара
    local scrollbar = scroll:GetVBar()
    scrollbar:SetWide(8)
    scrollbar.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 60, 200))
    end
    scrollbar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(100, 100, 120, 255))
    end

    -- Текст дисклеймера
    local text = vgui.Create("DLabel", scroll)
    text:SetText(cfg.text)
    text:SetWrap(true)
    text:SetAutoStretchVertical(true)
    text:SetFont("DermaDefault")
    text:SetTextColor(Color(220, 220, 220))
    text:SetContentAlignment(7)
    text:Dock(TOP)
    text:DockMargin(15, 15, 15, 15)

    -- Нижняя панель с кнопками
    local bottom = vgui.Create("DPanel", frame)
    bottom:Dock(BOTTOM)
    bottom:SetTall(60)
    bottom:SetPaintBackground(false)

    -- Чекбокс "Больше не показывать"
    local dontShow = vgui.Create("DCheckBoxLabel", bottom)
    dontShow:SetText("Больше не показывать")
    dontShow:SetFont("DermaDefault")
    dontShow:SetTextColor(Color(200, 200, 200))
    dontShow:SizeToContents()
    dontShow:Dock(LEFT)
    dontShow:DockMargin(0, 15, 0, 0)

    -- Кнопка "Ознакомлен"
    local ok = vgui.Create("DButton", bottom)
    ok:SetText("ОЗНАКОМЛЕН")
    ok:SetFont("DermaDefault")
    ok:Dock(RIGHT)
    ok:SetWide(200)
    ok:SetTall(40)
    ok:DockMargin(0, 10, 0, 0)
    
    -- Стилизация кнопки
    ok.Paint = function(self, w, h)
        local color = self:IsHovered() and Color(60, 120, 170, 255) or Color(50, 100, 150, 255)
        draw.RoundedBox(4, 0, 0, w, h, color)
        
        if (self:IsHovered()) then
            draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 20))
        end
    end
    
    ok.SetTextColor = function(self, color)
        self.textColor = color or Color(255, 255, 255)
    end
    
    ok.PaintText = function(self, w, h)
        local textColor = self.textColor or Color(255, 255, 255)
        draw.SimpleText(self:GetText(), self:GetFont(), w/2, h/2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    ok:SetTextColor(Color(255, 255, 255))
    
    ok.DoClick = function()
        if (dontShow:GetChecked()) then
            cookie.Set("ix_disclaimer_ack", "1")
        end
        overlay:Remove()
    end
end
