-- Клиентская часть меню имплантов
if CLIENT then
    local PANEL = {}
    
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
        
        self.closeButton = self.buttonPanel:Add("DButton")
        self.closeButton:SetText("Закрыть")
        self.closeButton:Dock(RIGHT)
        self.closeButton:SetWide(100)
        self.closeButton.DoClick = function()
            self:Close()
        end
        
        -- Информационная панель
        self.infoPanel = self:Add("DPanel")
        self.infoPanel:Dock(FILL)
        self.infoPanel:DockMargin(5, 5, 5, 5)
        
        self.infoLabel = self.infoPanel:Add("DLabel")
        self.infoLabel:Dock(FILL)
        self.infoLabel:SetText("Выберите игрока, конечность и имплант для применения.")
        self.infoLabel:SetContentAlignment(5)
        self.infoLabel:SetWrap(true)
        
        -- Обновляем список имплантов при выборе конечности
        self.limbCombo.OnSelect = function(panel, index, value, data)
            self:UpdateImplantList(data)
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
    
    vgui.Register("ixImplantsMenu", PANEL, "DFrame")
end
