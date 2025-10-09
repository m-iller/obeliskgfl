-- Клиентская часть меню имплантов
if CLIENT then
    local PANEL = {}
    
    -- Обработчик получения данных об имплантах
    net.Receive("ixImplantsGetData", function()
        local targetPlayer = net.ReadEntity()
        local implants = net.ReadTable()
        
        -- Обновляем панель имплантов если она открыта
        if IsValid(ix.gui.implants) then
            ix.gui.implants:UpdateImplantsList(targetPlayer, implants)
        end
    end)
    
    function PANEL:Init()
        self:SetTitle("Система имплантов")
        self:SetSize(600, 500)
        self:Center()
        self:MakePopup()
        
        -- Выбор игрока
        self.playerPanel = self:Add("DPanel")
        self.playerPanel:Dock(TOP)
        self.playerPanel:SetTall(60)
        self.playerPanel:DockMargin(5, 5, 5, 5)
        
        local playerLabel = self.playerPanel:Add("DLabel")
        playerLabel:SetText("Выберите игрока:")
        playerLabel:Dock(TOP)
        playerLabel:SetContentAlignment(5)
        
        self.playerCombo = self.playerPanel:Add("DComboBox")
        self.playerCombo:Dock(TOP)
        self.playerCombo:DockMargin(0, 5, 0, 0)
        self.playerCombo:SetValue("Выберите игрока...")
        
        -- Заполняем список игроков
        for _, ply in pairs(player.GetAll()) do
            if ply:GetCharacter() then
                self.playerCombo:AddChoice(ply:GetCharacter():GetName(), ply)
            end
        end
        
        -- Выбор конечности
        self.limbPanel = self:Add("DPanel")
        self.limbPanel:Dock(TOP)
        self.limbPanel:SetTall(60)
        self.limbPanel:DockMargin(5, 5, 5, 5)
        
        local limbLabel = self.limbPanel:Add("DLabel")
        limbLabel:SetText("Выберите конечность:")
        limbLabel:Dock(TOP)
        limbLabel:SetContentAlignment(5)
        
        self.limbCombo = self.limbPanel:Add("DComboBox")
        self.limbCombo:Dock(TOP)
        self.limbCombo:DockMargin(0, 5, 0, 0)
        self.limbCombo:SetValue("Выберите конечность...")
        
        -- Заполняем список конечностей из конфига
        local limbs = ix.configs.implantLimbs or {"голова", "глаза", "грудь", "руки", "ноги"}
        for _, limb in ipairs(limbs) do
            self.limbCombo:AddChoice(limb, limb)
        end
        
        -- Выбор импланта
        self.implantPanel = self:Add("DPanel")
        self.implantPanel:Dock(TOP)
        self.implantPanel:SetTall(60)
        self.implantPanel:DockMargin(5, 5, 5, 5)
        
        local implantLabel = self.implantPanel:Add("DLabel")
        implantLabel:SetText("Выберите имплант:")
        implantLabel:Dock(TOP)
        implantLabel:SetContentAlignment(5)
        
        self.implantCombo = self.implantPanel:Add("DComboBox")
        self.implantCombo:Dock(TOP)
        self.implantCombo:DockMargin(0, 5, 0, 0)
        self.implantCombo:SetValue("Выберите имплант...")
        
        -- Кнопки
        self.buttonPanel = self:Add("DPanel")
        self.buttonPanel:Dock(BOTTOM)
        self.buttonPanel:SetTall(40)
        self.buttonPanel:DockMargin(5, 5, 5, 5)
        
        self.applyButton = self.buttonPanel:Add("DButton")
        self.applyButton:SetText("Применить имплант")
        self.applyButton:Dock(LEFT)
        self.applyButton:DockMargin(0, 0, 5, 0)
        self.applyButton:SetWide(150)
        self.applyButton.DoClick = function()
            self:ApplyImplant()
        end
        
        self.removeButton = self.buttonPanel:Add("DButton")
        self.removeButton:SetText("Удалить имплант")
        self.removeButton:Dock(LEFT)
        self.removeButton:DockMargin(0, 0, 5, 0)
        self.removeButton:SetWide(150)
        self.removeButton.DoClick = function()
            self:RemoveImplant()
        end
        
        self.refreshButton = self.buttonPanel:Add("DButton")
        self.refreshButton:SetText("Обновить")
        self.refreshButton:Dock(RIGHT)
        self.refreshButton:DockMargin(0, 0, 5, 0)
        self.refreshButton:SetWide(100)
        self.refreshButton.DoClick = function()
            self:RefreshImplants()
        end
        
        self.closeButton = self.buttonPanel:Add("DButton")
        self.closeButton:SetText("Закрыть")
        self.closeButton:Dock(RIGHT)
        self.closeButton:SetWide(100)
        self.closeButton.DoClick = function()
            self:Close()
        end
        
        -- Панель для отображения установленных имплантов
        self.installedImplantsPanel = self:Add("DPanel")
        self.installedImplantsPanel:Dock(FILL)
        self.installedImplantsPanel:DockMargin(5, 5, 5, 5)
        
        local installedLabel = self.installedImplantsPanel:Add("DLabel")
        installedLabel:SetText("Установленные импланты:")
        installedLabel:Dock(TOP)
        installedLabel:SetContentAlignment(5)
        installedLabel:SetTall(20)
        
        self.installedImplantsList = self.installedImplantsPanel:Add("DScrollPanel")
        self.installedImplantsList:Dock(FILL)
        self.installedImplantsList:DockMargin(0, 5, 0, 0)
        
        -- Информационная панель
        self.infoPanel = self:Add("DPanel")
        self.infoPanel:Dock(BOTTOM)
        self.infoPanel:SetTall(60)
        self.infoPanel:DockMargin(5, 5, 5, 5)
        
        self.infoLabel = self.infoPanel:Add("DLabel")
        self.infoLabel:Dock(FILL)
        self.infoLabel:SetText("Выберите игрока, конечность и имплант для применения.")
        self.infoLabel:SetContentAlignment(5)
        self.infoLabel:SetWrap(true)
        
        -- Панель для отображения информации об импланте
        self.implantInfoPanel = self:Add("DPanel")
        self.implantInfoPanel:Dock(BOTTOM)
        self.implantInfoPanel:SetTall(100)
        self.implantInfoPanel:DockMargin(5, 5, 5, 5)
        self.implantInfoPanel:SetVisible(false)
        
        self.implantInfoLabel = self.implantInfoPanel:Add("DLabel")
        self.implantInfoLabel:Dock(FILL)
        self.implantInfoLabel:SetText("")
        self.implantInfoLabel:SetContentAlignment(7)
        self.implantInfoLabel:SetWrap(true)
        
        -- Обновляем список имплантов при выборе конечности
        self.limbCombo.OnSelect = function(panel, index, value, data)
            self:UpdateImplantList(data)
        end
        
        -- Обновляем информацию об импланте при его выборе
        self.implantCombo.OnSelect = function(panel, index, value, data)
            self:UpdateImplantInfo(data)
        end
    end
    
    function PANEL:UpdateImplantList(limb)
        self.implantCombo:Clear()
        self.implantCombo:SetValue("Выберите имплант...")
        
        -- Добавляем опцию "НЕТ"
        self.implantCombo:AddChoice("НЕТ", "НЕТ")
        
        -- Добавляем импланты для выбранной конечности
        local implants = ix.configs.implants or {}
        for implantName, implantData in pairs(implants) do
            if implantData.limb == limb then
                self.implantCombo:AddChoice(implantName, implantName)
            end
        end
    end
    
    function PANEL:UpdateImplantInfo(implantName)
        if implantName == "НЕТ" then
            self.implantInfoPanel:SetVisible(false)
            return
        end
        
        local implantData = ix.configs.implants[implantName]
        if not implantData then
            self.implantInfoPanel:SetVisible(false)
            return
        end
        
        self.implantInfoPanel:SetVisible(true)
        
        local infoText = "Описание: " .. (implantData.description or "Нет описания") .. "\n\n"
        
        -- Показываем бонусы
        local bonuses = implantData.bonuses or (implantData.bonus and {implantData.bonus}) or {}
        if #bonuses > 0 then
            infoText = infoText .. "Бонусы:\n"
            for i, bonus in ipairs(bonuses) do
                infoText = infoText .. "• " .. bonus .. "\n"
            end
        else
            infoText = infoText .. "Бонусы: Нет"
        end
        
        self.implantInfoLabel:SetText(infoText)
    end
    
    function PANEL:ApplyImplant()
        local selectedPlayer = self.playerCombo:GetOptionData(self.playerCombo:GetSelectedID())
        local selectedLimb = self.limbCombo:GetOptionData(self.limbCombo:GetSelectedID())
        local selectedImplant = self.implantCombo:GetOptionData(self.implantCombo:GetSelectedID())
        
        if not selectedPlayer or not selectedLimb or not selectedImplant then
            self.infoLabel:SetText("Пожалуйста, выберите игрока, конечность и имплант!")
            return
        end
        
        -- Отправляем команду на сервер
        net.Start("ixImplantsApply")
        net.WriteEntity(selectedPlayer)
        net.WriteString(selectedLimb)
        net.WriteString(selectedImplant)
        net.SendToServer()
        
        self.infoLabel:SetText("Имплант применен: " .. selectedImplant .. " для " .. selectedPlayer:GetCharacter():GetName())
    end
    
    function PANEL:RemoveImplant()
        local selectedPlayer = self.playerCombo:GetOptionData(self.playerCombo:GetSelectedID())
        local selectedLimb = self.limbCombo:GetOptionData(self.limbCombo:GetSelectedID())
        
        if not selectedPlayer or not selectedLimb then
            self.infoLabel:SetText("Пожалуйста, выберите игрока и конечность!")
            return
        end
        
        -- Отправляем команду на сервер для удаления импланта
        net.Start("ixImplantsApply")
        net.WriteEntity(selectedPlayer)
        net.WriteString(selectedLimb)
        net.WriteString("НЕТ")
        net.SendToServer()
        
        self.infoLabel:SetText("Имплант удален с " .. selectedLimb .. " у " .. selectedPlayer:GetCharacter():GetName())
    end
    
    function PANEL:RefreshImplants()
        local selectedPlayer = self.playerCombo:GetOptionData(self.playerCombo:GetSelectedID())
        
        if not selectedPlayer then
            self.infoLabel:SetText("Пожалуйста, выберите игрока!")
            return
        end
        
        -- Запрашиваем данные об имплантах с сервера
        net.Start("ixImplantsGetData")
        net.WriteEntity(selectedPlayer)
        net.SendToServer()
        
        self.infoLabel:SetText("Загружаем импланты...")
    end
    
    function PANEL:UpdateImplantsList(targetPlayer, implants)
        -- Очищаем список
        self.installedImplantsList:Clear()
        
        if not implants or table.IsEmpty(implants) then
            local noImplantsLabel = self.installedImplantsList:Add("DLabel")
            noImplantsLabel:SetText("У игрока нет установленных имплантов")
            noImplantsLabel:Dock(TOP)
            noImplantsLabel:SetContentAlignment(5)
            noImplantsLabel:SetTall(30)
            return
        end
        
        -- Добавляем каждый имплант в список
        for limb, implant in pairs(implants) do
            if implant and implant ~= "НЕТ" then
                local implantPanel = self.installedImplantsList:Add("DPanel")
                implantPanel:Dock(TOP)
                implantPanel:SetTall(40)
                implantPanel:DockMargin(0, 2, 0, 2)
                implantPanel.Paint = function(self, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 200))
                    draw.RoundedBox(4, 1, 1, w-2, h-2, Color(70, 70, 70, 150))
                end
                
                local implantLabel = implantPanel:Add("DLabel")
                implantLabel:SetText(limb .. ": " .. implant)
                implantLabel:Dock(FILL)
                implantLabel:SetContentAlignment(4)
                implantLabel:DockMargin(10, 0, 0, 0)
                
                -- Кнопка для удаления импланта
                local removeBtn = implantPanel:Add("DButton")
                removeBtn:SetText("Удалить")
                removeBtn:Dock(RIGHT)
                removeBtn:SetWide(80)
                removeBtn:DockMargin(0, 5, 5, 5)
                removeBtn.DoClick = function()
                    -- Устанавливаем выбранного игрока и конечность
                    self.playerCombo:ChooseOption(targetPlayer:GetCharacter():GetName(), targetPlayer)
                    self.limbCombo:ChooseOption(limb, limb)
                    self.implantCombo:ChooseOption("НЕТ", "НЕТ")
                    
                    -- Удаляем имплант
                    self:RemoveImplant()
                end
            end
        end
        
        self.infoLabel:SetText("Импланты загружены для " .. targetPlayer:GetCharacter():GetName())
    end
    
    function PANEL:OnClose()
        -- Очищаем ссылку на панель при закрытии
        if ix.gui.implants == self then
            ix.gui.implants = nil
        end
    end
    
    vgui.Register("ixImplantsMenu", PANEL, "DFrame")
end
