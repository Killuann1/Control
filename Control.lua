-- ====================================================================================
-- УПРАВЛЕНИЕ: СКРИПТ ДЛЯ MM2 (ХИТБОКСЫ, СКОРОСТЬ, ESP, GUN CHAM)
-- Type: LocalScript
-- Parent: StarterPlayer.StarterPlayerScripts
-- Credits to Kiriot22 for the Role getter <3
-- Poorly coded by FeIix <3
-- Improved by Grok 3
-- ====================================================================================

-- Глобальные переменные
_G.HitboxSize = _G.HitboxSize or 0
_G.Disabled = _G.Disabled or true
_G.HitboxColor = _G.HitboxColor or Color3.fromRGB(117, 7, 181)
_G.EspEnabled = _G.EspEnabled or false
_G.PlayerSpeed = _G.PlayerSpeed or 16
_G.SpeedEnabled = _G.SpeedEnabled or false
_G.OriginalWalkSpeed = nil
_G.ToggleScriptKeyCode = _G.ToggleScriptKeyCode or Enum.KeyCode.Backspace
_G.ToggleSpeedKeyCode = _G.ToggleSpeedKeyCode or Enum.KeyCode.V
_G.GunChamEnabled = _G.GunChamEnabled or false -- Новая переменная для Gun Cham

-- Сервисы
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Локальный игрок и PlayerGui
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    LocalPlayer = Players.PlayerAdded:Wait()
end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

-- Названия элементов GUI
local GUI_NAME = "ControlGUI"
local MAIN_FRAME_NAME = "MainFrame"
local TITLE_LABEL_NAME = "TitleLabel"
local SLIDER_FRAME_NAME = "HitboxSliderFrame"
local HITBOX_SIZE_LABEL_NAME = "HitboxSizeLabel"
local TOGGLE_BUTTON_NAME = "ToggleHitboxButton"
local TOGGLE_VISIBILITY_BUTTON_NAME = "ToggleVisibilityButton"
local CLOSE_BUTTON_NAME = "CloseButton"
local BIND_HITBOX_BUTTON_NAME = "BindHitboxButton"
local SPEED_SLIDER_FRAME_NAME = "SpeedSliderFrame"
local PLAYER_SPEED_LABEL_NAME = "PlayerSpeedLabel"
local TOGGLE_SPEED_BUTTON_NAME = "ToggleSpeedButton"
local BIND_SPEED_BUTTON_NAME = "BindSpeedButton"
local TOGGLE_ESP_BUTTON_NAME = "ToggleESPButton"
local TOGGLE_GUN_CHAM_BUTTON_NAME = "ToggleGunChamButton" -- Новая кнопка для Gun Cham

-- Переменные GUI
local ScreenGui, MainFrame, TitleLabel, HitboxSliderFrame, HitboxSliderKnob, HitboxSizeLabel, ToggleHitboxButton, ToggleVisibilityButton, CloseButton, BindHitboxButton
local SpeedSliderFrame, SpeedSliderKnob, PlayerSpeedLabel, ToggleSpeedButton, BindSpeedButton, ToggleESPButton, ToggleGunChamButton

-- Флаг для режима назначения бинда
local isAwaitingBindInput = false
local currentBindTarget = nil

-- Переменные для ESP
local roles = {}
local lastKnownRoles = {}
local Murder, Sheriff, Hero
local playerHighlights = {}
local playerBeams = {}
local pistolHighlights = {}
local lastKnownPositions = {}
local gunChamConnections = {} -- Для хранения соединений Gun Cham

-- Хранилище соединений
local connections = {}
local playerCharacterConnections = {} -- Для отслеживания CharacterAdded

-- Функция для создания GUI элемента
local function createGuiElement(instanceType, properties, parent)
    local element = Instance.new(instanceType)
    for prop, value in pairs(properties) do
        element[prop] = value
    end
    element.Parent = parent
    return element
end

-- Список элементов для сворачивания
local controllableElements = {}

-- Инициализация GUI
ScreenGui = PlayerGui:FindFirstChild(GUI_NAME)
if not ScreenGui then
    ScreenGui = createGuiElement("ScreenGui", {
        Name = GUI_NAME,
        ResetOnSpawn = false,
        Enabled = true,
        DisplayOrder = 999,
        ZIndexBehavior = Enum.ZIndexBehavior.Global
    }, PlayerGui)
else
    ScreenGui.Enabled = true
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 999
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
end

MainFrame = ScreenGui:FindFirstChild(MAIN_FRAME_NAME)
if not MainFrame then
    MainFrame = createGuiElement("Frame", {
        Name = MAIN_FRAME_NAME,
        Size = UDim2.new(0, 250, 0, 420), -- Увеличен размер для размещения GunCham
        Position = UDim2.new(0.5, -125, 0.5, -210),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0,
        Visible = true,
        ZIndex = 1,
        Active = true
    }, ScreenGui)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 8) }, MainFrame)
else
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0, 250, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -125, 0.5, -210)
    MainFrame.Active = true
end

TitleLabel = MainFrame:FindFirstChild(TITLE_LABEL_NAME)
if not TitleLabel then
    TitleLabel = createGuiElement("TextLabel", {
        Name = TITLE_LABEL_NAME,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Управление MM2",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 18,
        BackgroundColor3 = Color3.fromRGB(45, 45, 45),
        ZIndex = 2
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 8) }, TitleLabel)
else
    TitleLabel.Text = "Управление MM2"
end

ToggleVisibilityButton = TitleLabel:FindFirstChild(TOGGLE_VISIBILITY_BUTTON_NAME)
if not ToggleVisibilityButton then
    ToggleVisibilityButton = createGuiElement("TextButton", {
        Name = TOGGLE_VISIBILITY_BUTTON_NAME,
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -45, 0, 0),
        Text = "-",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 20,
        BackgroundColor3 = Color3.fromRGB(80, 80, 80),
        ZIndex = 3,
        Active = true,
        Selectable = true
    }, TitleLabel)
end

CloseButton = TitleLabel:FindFirstChild(CLOSE_BUTTON_NAME)
if not CloseButton then
    CloseButton = createGuiElement("TextButton", {
        Name = CLOSE_BUTTON_NAME,
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -20, 0, 0),
        Text = "X",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 20,
        BackgroundColor3 = Color3.fromRGB(180, 0, 0),
        ZIndex = 3,
        Active = true,
        Selectable = true
    }, TitleLabel)
end

local originalFrameSize = MainFrame.Size
local isCollapsed = false

local function toggleGUICollapse()
    local success, err = pcall(function()
        isCollapsed = not isCollapsed
        local tweenDuration = 0.5
        local tweenEasingStyle = Enum.EasingStyle.Quad
        local tweenEasingDirection = Enum.EasingDirection.Out

        if isCollapsed then
            for _, element in ipairs(controllableElements) do
                element.Visible = false
            end
            local tween = TweenService:Create(MainFrame, TweenInfo.new(tweenDuration, tweenEasingStyle, tweenEasingDirection), {
                Size = UDim2.new(originalFrameSize.X.Scale, originalFrameSize.X.Offset, 0, TitleLabel.Size.Y.Offset)
            })
            tween:Play()
            ToggleVisibilityButton.Text = "+"
            if TitleLabel:FindFirstChildOfClass("UICorner") then
                TitleLabel:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 0)
            end
        else
            local tween = TweenService:Create(MainFrame, TweenInfo.new(tweenDuration, tweenEasingStyle, tweenEasingDirection), {
                Size = originalFrameSize
            })
            tween:Play()
            tween.Completed:Wait()
            for _, element in ipairs(controllableElements) do
                element.Visible = true
            end
            ToggleVisibilityButton.Text = "-"
            if TitleLabel:FindFirstChildOfClass("UICorner") then
                TitleLabel:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 8)
            end
        end
    end)
    if not success then warn("Error in toggleGUICollapse: ", err) end
end

ToggleVisibilityButton.MouseButton1Click:Connect(toggleGUICollapse)

local function closeScript()
    local success, err = pcall(function()
        -- Disable all features
        _G.Disabled = true
        _G.SpeedEnabled = false
        _G.EspEnabled = false
        _G.GunChamEnabled = false

        -- Disconnect all stored connections
        for _, connection in pairs(connections) do
            if connection and typeof(connection) == "RBXScriptConnection" and connection.Connected then
                connection:Disconnect()
            end
        end
        for _, connection in pairs(gunChamConnections) do
            if connection and typeof(connection) == "RBXScriptConnection" and connection.Connected then
                connection:Disconnect()
            end
        end
        for player, conn in pairs(playerCharacterConnections) do
            if conn and typeof(conn) == "RBXScriptConnection" and conn.Connected then
                conn:Disconnect()
            end
        end
        connections = {}
        gunChamConnections = {}
        playerCharacterConnections = {}

        -- Clean up ESP highlights and beams
        for player, highlight in pairs(playerHighlights) do
            if highlight then
                highlight:Destroy()
                playerHighlights[player] = nil
            end
            if playerBeams[player] then
                playerBeams[player]:Destroy()
                playerBeams[player] = nil
            end
        end
        for _, highlight in pairs(pistolHighlights) do
            if highlight then
                highlight:Destroy()
            end
        end
        pistolHighlights = {}

        -- Destroy GUI
        if ScreenGui then
            ScreenGui:Destroy()
            ScreenGui = nil
        end
    end)
    if not success then warn("Error in closeScript: ", err) end
end

CloseButton.MouseButton1Click:Connect(function()
    closeScript()
end)

local isDragging = false
local dragStartPos
local frameStartPos

TitleLabel.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
        local mousePos = UserInputService:GetMouseLocation()
        local toggleButtonRect = {
            xMin = ToggleVisibilityButton.AbsolutePosition.X,
            xMax = ToggleVisibilityButton.AbsolutePosition.X + ToggleVisibilityButton.AbsoluteSize.X,
            yMin = ToggleVisibilityButton.AbsolutePosition.Y,
            yMax = ToggleVisibilityButton.AbsolutePosition.Y + ToggleVisibilityButton.AbsoluteSize.Y
        }
        local closeButtonRect = {
            xMin = CloseButton.AbsolutePosition.X,
            xMax = CloseButton.AbsolutePosition.X + CloseButton.AbsoluteSize.X,
            yMin = CloseButton.AbsolutePosition.Y,
            yMax = CloseButton.AbsolutePosition.Y + CloseButton.AbsoluteSize.Y
        }
        if (mousePos.X < toggleButtonRect.xMin or mousePos.X > toggleButtonRect.xMax or
            mousePos.Y < toggleButtonRect.yMin or mousePos.Y > toggleButtonRect.yMax) and
           (mousePos.X < closeButtonRect.xMin or mousePos.X > closeButtonRect.xMax or
            mousePos.Y < closeButtonRect.yMin or mousePos.Y > closeButtonRect.yMax) then
            isDragging = true
            dragStartPos = mousePos
            frameStartPos = MainFrame.Position
        end
    end
end)

connections["InputChanged"] = UserInputService.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = UserInputService:GetMouseLocation() - dragStartPos
        MainFrame.Position = UDim2.new(
            frameStartPos.X.Scale,
            frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale,
            frameStartPos.Y.Offset + delta.Y
        )
    end
end)

connections["InputEnded"] = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
    end
end)

-- Слайдер для хитбоксов
HitboxSliderFrame = MainFrame:FindFirstChild(SLIDER_FRAME_NAME)
if not HitboxSliderFrame then
    HitboxSliderFrame = createGuiElement("Frame", {
        Name = SLIDER_FRAME_NAME,
        Size = UDim2.new(0.8, 0, 0, 10),
        Position = UDim2.new(0.1, 0, 0, 45),
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        BorderSizePixel = 0,
        ZIndex = 2
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, HitboxSliderFrame)
end
table.insert(controllableElements, HitboxSliderFrame)

HitboxSliderKnob = HitboxSliderFrame:FindFirstChild("SliderKnob")
if not HitboxSliderKnob then
    HitboxSliderKnob = createGuiElement("TextButton", {
        Name = "SliderKnob",
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(100, 100, 100),
        BorderSizePixel = 0,
        Text = "",
        ZIndex = 3,
        Active = true,
        Selectable = true
    }, HitboxSliderFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }, HitboxSliderKnob)
end

HitboxSizeLabel = MainFrame:FindFirstChild(HITBOX_SIZE_LABEL_NAME)
if not HitboxSizeLabel then
    HitboxSizeLabel = createGuiElement("TextLabel", {
        Name = HITBOX_SIZE_LABEL_NAME,
        Size = UDim2.new(0.8, 0, 0, 20),
        Position = UDim2.new(0.1, 0, 0, 60),
        Text = "Размер хитбокса: " .. _G.HitboxSize,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BackgroundTransparency = 1,
        ZIndex = 2
    }, MainFrame)
end
table.insert(controllableElements, HitboxSizeLabel)

local isHitboxSliderDragging = false
local hitboxSliderMin = 0
local hitboxSliderMax = 20

local function updateHitboxSliderKnobPosition()
    local success, err = pcall(function()
        local sliderMovableWidth = HitboxSliderFrame.AbsoluteSize.X - HitboxSliderKnob.AbsoluteSize.X
        if sliderMovableWidth <= 0 or hitboxSliderMax == hitboxSliderMin then return end
        local ratio = (_G.HitboxSize - hitboxSliderMin) / (hitboxSliderMax - hitboxSliderMin)
        local clampedRelativeX = math.clamp(ratio * sliderMovableWidth, 0, sliderMovableWidth)
        HitboxSliderKnob.Position = UDim2.new(0, clampedRelativeX, 0, 0)
        HitboxSizeLabel.Text = "Размер хитбокса: " .. _G.HitboxSize
    end)
    if not success then warn("Error in updateHitboxSliderKnobPosition: ", err) end
end

task.defer(updateHitboxSliderKnobPosition)

HitboxSliderKnob.MouseButton1Down:Connect(function()
    local success, err = pcall(function()
        isHitboxSliderDragging = true
        local sliderMovedConnection = UserInputService.InputChanged:Connect(function(input)
            if isHitboxSliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local currentMouseX = UserInputService:GetMouseLocation().X
                local newRelativeX = currentMouseX - HitboxSliderFrame.AbsolutePosition.X
                local sliderMovableWidth = HitboxSliderFrame.AbsoluteSize.X - HitboxSliderKnob.AbsoluteSize.X
                local clampedRelativeX = math.clamp(newRelativeX, 0, sliderMovableWidth)
                HitboxSliderKnob.Position = UDim2.new(0, clampedRelativeX, 0, 0)
                local ratio = clampedRelativeX / sliderMovableWidth
                _G.HitboxSize = math.floor(hitboxSliderMin + (hitboxSliderMax - hitboxSliderMin) * ratio)
                _G.HitboxSize = math.clamp(_G.HitboxSize, hitboxSliderMin, hitboxSliderMax)
                HitboxSizeLabel.Text = "Размер хитбокса: " .. _G.HitboxSize
            end
        end)
        local sliderEndedConnection = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isHitboxSliderDragging = false
                sliderMovedConnection:Disconnect()
                sliderEndedConnection:Disconnect()
            end
        end)
    end)
    if not success then warn("Error in HitboxSliderKnob.MouseButton1Down: ", err) end
end)

BindHitboxButton = MainFrame:FindFirstChild(BIND_HITBOX_BUTTON_NAME)
if not BindHitboxButton then
    BindHitboxButton = createGuiElement("TextButton", {
        Name = BIND_HITBOX_BUTTON_NAME,
        Size = UDim2.new(0.8, 0, 0, 30),
        Position = UDim2.new(0.1, 0, 0, 95),
        Text = "Бинд хитбокса: " .. _G.ToggleScriptKeyCode.Name,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        ZIndex = 2,
        Active = true,
        Selectable = true
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, BindHitboxButton)
end
table.insert(controllableElements, BindHitboxButton)

ToggleHitboxButton = MainFrame:FindFirstChild(TOGGLE_BUTTON_NAME)
if not ToggleHitboxButton then
    ToggleHitboxButton = createGuiElement("TextButton", {
        Name = TOGGLE_BUTTON_NAME,
        Size = UDim2.new(0.8, 0, 0, 30),
        Position = UDim2.new(0.1, 0, 0, 135),
        Text = "Хитбоксы: Отключены",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        BackgroundColor3 = Color3.fromRGB(192, 57, 43),
        ZIndex = 2,
        Active = true,
        Selectable = true
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, ToggleHitboxButton)
end
table.insert(controllableElements, ToggleHitboxButton)

-- Слайдер для скорости
SpeedSliderFrame = MainFrame:FindFirstChild(SPEED_SLIDER_FRAME_NAME)
if not SpeedSliderFrame then
    SpeedSliderFrame = createGuiElement("Frame", {
        Name = SPEED_SLIDER_FRAME_NAME,
        Size = UDim2.new(0.8, 0, 0, 10),
        Position = UDim2.new(0.1, 0, 0, 185),
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        BorderSizePixel = 0,
        ZIndex = 2
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, SpeedSliderFrame)
end
table.insert(controllableElements, SpeedSliderFrame)

SpeedSliderKnob = SpeedSliderFrame:FindFirstChild("SpeedSliderKnob")
if not SpeedSliderKnob then
    SpeedSliderKnob = createGuiElement("TextButton", {
        Name = "SpeedSliderKnob",
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(100, 100, 100),
        BorderSizePixel = 0,
        Text = "",
        ZIndex = 3,
        Active = true,
        Selectable = true
    }, SpeedSliderFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }, SpeedSliderKnob)
end

PlayerSpeedLabel = MainFrame:FindFirstChild(PLAYER_SPEED_LABEL_NAME)
if not PlayerSpeedLabel then
    PlayerSpeedLabel = createGuiElement("TextLabel", {
        Name = PLAYER_SPEED_LABEL_NAME,
        Size = UDim2.new(0.8, 0, 0, 20),
        Position = UDim2.new(0.1, 0, 0, 200),
        Text = "Скорость: " .. _G.PlayerSpeed,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BackgroundTransparency = 1,
        ZIndex = 2
    }, MainFrame)
end
table.insert(controllableElements, PlayerSpeedLabel)

local isSpeedSliderDragging = false
local speedSliderMin = 16
local speedSliderMax = 100

local function updateSpeedSliderKnobPosition()
    local success, err = pcall(function()
        local sliderMovableWidth = SpeedSliderFrame.AbsoluteSize.X - SpeedSliderKnob.AbsoluteSize.X
        if sliderMovableWidth <= 0 or speedSliderMax == speedSliderMin then return end
        local ratio = (_G.PlayerSpeed - speedSliderMin) / (speedSliderMax - speedSliderMin)
        local clampedRelativeX = math.clamp(ratio * sliderMovableWidth, 0, sliderMovableWidth)
        SpeedSliderKnob.Position = UDim2.new(0, clampedRelativeX, 0, 0)
        PlayerSpeedLabel.Text = "Скорость: " .. _G.PlayerSpeed
    end)
    if not success then warn("Error in updateSpeedSliderKnobPosition: ", err) end
end

task.defer(updateSpeedSliderKnobPosition)

SpeedSliderKnob.MouseButton1Down:Connect(function()
    local success, err = pcall(function()
        isSpeedSliderDragging = true
        local sliderMovedConnection = UserInputService.InputChanged:Connect(function(input)
            if isSpeedSliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local currentMouseX = UserInputService:GetMouseLocation().X
                local newRelativeX = currentMouseX - SpeedSliderFrame.AbsolutePosition.X
                local sliderMovableWidth = SpeedSliderFrame.AbsoluteSize.X - SpeedSliderKnob.AbsoluteSize.X
                local clampedRelativeX = math.clamp(newRelativeX, 0, sliderMovableWidth)
                SpeedSliderKnob.Position = UDim2.new(0, clampedRelativeX, 0, 0)
                local ratio = clampedRelativeX / sliderMovableWidth
                _G.PlayerSpeed = math.floor(speedSliderMin + (speedSliderMax - speedSliderMin) * ratio)
                _G.PlayerSpeed = math.clamp(_G.PlayerSpeed, speedSliderMin, speedSliderMax)
                PlayerSpeedLabel.Text = "Скорость: " .. _G.PlayerSpeed
                if _G.SpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    LocalPlayer.Character.Humanoid.WalkSpeed = _G.PlayerSpeed
                end
            end
        end)
        local sliderEndedConnection = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isSpeedSliderDragging = false
                sliderMovedConnection:Disconnect()
                sliderEndedConnection:Disconnect()
            end
        end)
    end)
    if not success then warn("Error in SpeedSliderKnob.MouseButton1Down: ", err) end
end)

BindSpeedButton = MainFrame:FindFirstChild(BIND_SPEED_BUTTON_NAME)
if not BindSpeedButton then
    BindSpeedButton = createGuiElement("TextButton", {
        Name = BIND_SPEED_BUTTON_NAME,
        Size = UDim2.new(0.8, 0, 0, 30),
        Position = UDim2.new(0.1, 0, 0, 235),
        Text = "Бинд скорости: " .. _G.ToggleSpeedKeyCode.Name,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        ZIndex = 2,
        Active = true,
        Selectable = true
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, BindSpeedButton)
end
table.insert(controllableElements, BindSpeedButton)

ToggleSpeedButton = MainFrame:FindFirstChild(TOGGLE_SPEED_BUTTON_NAME)
if not ToggleSpeedButton then
    ToggleSpeedButton = createGuiElement("TextButton", {
        Name = TOGGLE_SPEED_BUTTON_NAME,
        Size = UDim2.new(0.8, 0, 0, 30),
        Position = UDim2.new(0.1, 0, 0, 275),
        Text = "Скорость: Отключена",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        BackgroundColor3 = Color3.fromRGB(192, 57, 43),
        ZIndex = 2,
        Active = true,
        Selectable = true
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, ToggleSpeedButton)
end
table.insert(controllableElements, ToggleSpeedButton)

ToggleESPButton = MainFrame:FindFirstChild(TOGGLE_ESP_BUTTON_NAME)
if not ToggleESPButton then
    ToggleESPButton = createGuiElement("TextButton", {
        Name = TOGGLE_ESP_BUTTON_NAME,
        Size = UDim2.new(0.8, 0, 0, 30),
        Position = UDim2.new(0.1, 0, 0, 315),
        Text = "ESP: Отключено",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        BackgroundColor3 = Color3.fromRGB(192, 57, 43),
        ZIndex = 2,
        Active = true,
        Selectable = true
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, ToggleESPButton)
end
table.insert(controllableElements, ToggleESPButton)

ToggleGunChamButton = MainFrame:FindFirstChild(TOGGLE_GUN_CHAM_BUTTON_NAME)
if not ToggleGunChamButton then
    ToggleGunChamButton = createGuiElement("TextButton", {
        Name = TOGGLE_GUN_CHAM_BUTTON_NAME,
        Size = UDim2.new(0.8, 0, 0, 30),
        Position = UDim2.new(0.1, 0, 0, 355),
        Text = "Gun Cham: Отключено",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 14,
        BackgroundColor3 = Color3.fromRGB(192, 57, 43),
        ZIndex = 2,
        Active = true,
        Selectable = true
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, ToggleGunChamButton)
end
table.insert(controllableElements, ToggleGunChamButton)

-- Логика ESP
local espConnection = nil

local function esp(player)
    if player ~= LocalPlayer and not playerHighlights[player] then
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            lastKnownPositions[player] = lastKnownPositions[player] or Vector3.new(0, 0, 0)
            return
        end

        -- Создание Highlight с обводкой
        local highlight = Instance.new("Highlight")
        highlight.FillTransparency = 0.55
        highlight.OutlineTransparency = 0.3
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.Enabled = _G.EspEnabled
        highlight.Parent = character
        playerHighlights[player] = highlight

        -- Создание Attachment для локального игрока с проверкой
        local attachment0 = Instance.new("Attachment")
        local localCharacter = LocalPlayer.Character
        if localCharacter and localCharacter:FindFirstChild("HumanoidRootPart") then
            attachment0.Parent = localCharacter.HumanoidRootPart
        else
            task.wait(0.1) -- Краткая задержка для загрузки
            localCharacter = LocalPlayer.Character
            if localCharacter and localCharacter:FindFirstChild("HumanoidRootPart") then
                attachment0.Parent = localCharacter.HumanoidRootPart
            else
                warn("LocalPlayer HumanoidRootPart still not found after delay")
                return
            end
        end

        -- Создание Attachment для целевого игрока
        local attachment1 = Instance.new("Attachment")
        attachment1.Parent = character:FindFirstChild("HumanoidRootPart")

        -- Создание 3D Beam
        local beam = Instance.new("Beam")
        beam.Name = "ESPBeam"
        beam.Attachment0 = attachment0
        beam.Attachment1 = attachment1
        beam.Width0 = 0.3
        beam.Width1 = 0.3
        beam.CurveSize0 = 1.5
        beam.CurveSize1 = 1.5
        beam.Transparency = NumberSequence.new(0)
        beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
        beam.Enabled = _G.EspEnabled
        beam.Parent = Workspace
        playerBeams[player] = beam

        -- Отслеживание CharacterAdded
        if not playerCharacterConnections[player] then
            playerCharacterConnections[player] = player.CharacterAdded:Connect(function(newCharacter)
                task.wait(0.1)
                if playerHighlights[player] then
                    playerHighlights[player].Parent = newCharacter
                    playerHighlights[player].Adornee = newCharacter
                end
                if playerBeams[player] and newCharacter:FindFirstChild("HumanoidRootPart") then
                    playerBeams[player].Attachment1.Parent = newCharacter.HumanoidRootPart
                end
            end)
        end
    end
end

local function removeHighlightForPlayer(player)
    local success, err = pcall(function()
        if playerHighlights[player] then
            playerHighlights[player].Parent = nil
            playerHighlights[player] = nil
        end
        if playerBeams[player] then
            playerBeams[player]:Destroy()
            playerBeams[player] = nil
        end
        if playerCharacterConnections[player] then
            playerCharacterConnections[player]:Disconnect()
            playerCharacterConnections[player] = nil
        end
    end)
    if not success then warn("Error in removeHighlightForPlayer: ", err) end
end

local function updateHighlights()
    local success, err = pcall(function()
        for player, highlight in pairs(playerHighlights) do
            local character = player.Character
            local isAlive = character and character:FindFirstChildOfClass("Humanoid") and character.Humanoid.Health > 0
            if character and character:FindFirstChild("HumanoidRootPart") then
                if not highlight.Parent then
                    highlight.Parent = character
                    highlight.Adornee = character
                end
            elseif not isAlive and highlight then
                if not highlight.Parent then
                    highlight.Parent = Workspace
                    highlight.Adornee = nil
                    highlight.FillTransparency = 1
                    highlight.OutlineTransparency = 0.3
                end
            end

            local color = Color3.fromRGB(0, 225, 0) -- По умолчанию зелёный для обычных игроков
            if lastKnownRoles[player.Name] then
                if lastKnownRoles[player.Name].Role == "Sheriff" then
                    color = Color3.fromRGB(0, 0, 225)
                elseif lastKnownRoles[player.Name].Role == "Murderer" then
                    color = Color3.fromRGB(225, 0, 0)
                elseif lastKnownRoles[player.Name].Role == "Hero" then
                    color = Color3.fromRGB(255, 250, 0) -- Жёлтый для героев
                end
            end
            highlight.FillColor = color
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = isAlive and 0.55 or 1
            highlight.Enabled = _G.EspEnabled

            local beam = playerBeams[player]
            if beam then
                beam.Color = ColorSequence.new(color)
                beam.Enabled = _G.EspEnabled
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    beam.Attachment0 = LocalPlayer.Character:FindFirstChild("HumanoidRootPart"):FindFirstChildOfClass("Attachment") or Instance.new("Attachment", LocalPlayer.Character.HumanoidRootPart)
                else
                    beam.Enabled = false
                end

                if character and character:FindFirstChild("HumanoidRootPart") then
                    lastKnownPositions[player] = character.HumanoidRootPart.Position
                    beam.Attachment1.Parent = character.HumanoidRootPart
                elseif lastKnownPositions[player] then
                    local part = beam.Attachment1.Parent
                    if part and part:IsA("Part") and part.Parent == Workspace then
                        part.Position = lastKnownPositions[player]
                        beam.Attachment1.Parent = part
                    end
                end
            end
        end
    end)
    if not success then warn("Error in updateHighlights: ", err) end
end

local function fetchRoles()
    local success, roleData = pcall(function()
        local getPlayerData = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
        if getPlayerData then
            return getPlayerData:InvokeServer()
        else
            return nil
        end
    end)
    if success and roleData then
        roles = roleData
        lastKnownRoles = table.clone(roles)
        Murder, Sheriff, Hero = nil, nil, nil
        for i, v in pairs(roles) do
            if v.Role == "Murderer" then
                Murder = i
            elseif v.Role == "Sheriff" then
                Sheriff = i
            elseif v.Role == "Hero" then
                Hero = i
            end
        end
        updateHighlights() -- Обновляем подсветку после получения ролей
    elseif not success then
        warn("Error fetching player data: ", roleData)
    end
end

local function updateESPConnection()
    local success, err = pcall(function()
        if _G.EspEnabled then
            if not espConnection then
                for _, player in pairs(Players:GetPlayers()) do
                    esp(player)
                end
                espConnection = RunService.Heartbeat:Connect(function()
                    fetchRoles()
                    updateHighlights()
                end)
                connections["PlayerAdded"] = Players.PlayerAdded:Connect(esp)
                connections["PlayerRemoving"] = Players.PlayerRemoving:Connect(removeHighlightForPlayer)
            end
        else
            if espConnection then
                espConnection:Disconnect()
                espConnection = nil
            end
            for _, player in pairs(Players:GetPlayers()) do
                if playerHighlights[player] then
                    playerHighlights[player].Enabled = false
                end
                if playerBeams[player] then
                    playerBeams[player].Enabled = false
                end
            end
        end
    end)
    if not success then warn("Error in updateESPConnection: ", err) end
end

local function PlayerHasTool(Target, ToolName)
    if Target:WaitForChild("Backpack"):FindFirstChild(ToolName) or (Target.Character and Target.Character:FindFirstChild(ToolName)) then
        return true
    else
        return false
    end
end

local function HighlightPlayer(Target, BrickColorName)
    if Target == LocalPlayer then
        return nil
    end
    local TargetPart
    
    if Target:IsA("Player") then
        local TargetCharacter = Target.Character or Target.CharacterAdded:Wait()
        TargetPart = TargetCharacter.PrimaryPart
    elseif Target:IsA("BasePart") then
        TargetPart = Target
    end
    if not TargetPart then
        return nil
    end
    
    local Old = PlayerGui:FindFirstChild("ESP:" .. Target.Name)
    
    local Billboard = Old or Instance.new("BillboardGui")
    Billboard.Name = "ESP:" .. Target.Name
    Billboard.Adornee = TargetPart
    Billboard.Size = UDim2.new(1, 0, 1, 0)
    Billboard.AlwaysOnTop = true
    Billboard.Parent = PlayerGui
    
    local Frame = Billboard:FindFirstChild("Frame") or Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 1, 0)
    Frame.BackgroundColor3 = BrickColor.new(BrickColorName).Color
    Frame.BorderPixelSize = 0
    Frame.BackgroundTransparency = 0.5
    Frame.Parent = Billboard
end

local function CheckTools(Target)
    if _G.GunChamEnabled and _G.EspEnabled then
        local character = Target.Character
        if character then
            local gun = character:FindFirstChild("Gun")
            if gun then
                HighlightPlayer(gun, "Bright green")
                pistolHighlights[gun] = PlayerGui:FindFirstChild("ESP:" .. gun.Name)
            end
        end
    end
end

local function updateGunCham()
    local success, err = pcall(function()
        if _G.GunChamEnabled and _G.EspEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                CheckTools(player)
            end
            for _, part in pairs(Workspace:GetChildren()) do
                if part:IsA("BasePart") and part.Name == "GunDrop" then
                    HighlightPlayer(part, "Bright blue")
                end
            end
        else
            for _, player in pairs(Players:GetPlayers()) do
                local character = player.Character
                if character then
                    local gun = character:FindFirstChild("Gun")
                    if gun and pistolHighlights[gun] then
                        local esp = PlayerGui:FindFirstChild("ESP:" .. gun.Name)
                        if esp then
                            esp:Destroy()
                        end
                        pistolHighlights[gun] = nil
                    end
                end
            end
            for _, part in pairs(Workspace:GetChildren()) do
                local esp = PlayerGui:FindFirstChild("ESP:" .. part.Name)
                if esp then
                    esp:Destroy()
                end
            end
        end
    end)
    if not success then
        warn("Error in updateGunCham: ", err)
    end
end

-- Логика скрипта
local renderSteppedConnection = nil

local function updateToggleHitboxButton()
    local success, err = pcall(function()
        if _G.Disabled then
            ToggleHitboxButton.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
            ToggleHitboxButton.Text = "Хитбоксы: Отключены"
        else
            ToggleHitboxButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            ToggleHitboxButton.Text = "Хитбоксы: Включены"
        end
    end)
    if not success then warn("Error in updateToggleHitboxButton: ", err) end
end

local function updateToggleSpeedButton()
    local success, err = pcall(function()
        if _G.SpeedEnabled then
            ToggleSpeedButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            ToggleSpeedButton.Text = "Скорость: Включена"
        else
            ToggleSpeedButton.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
            ToggleSpeedButton.Text = "Скорость: Отключена"
        end
    end)
    if not success then warn("Error in updateToggleSpeedButton: ", err) end
end

local function updateToggleESPButton()
    local success, err = pcall(function()
        if _G.EspEnabled then
            ToggleESPButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            ToggleESPButton.Text = "ESP: Включено"
        else
            ToggleESPButton.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
            ToggleESPButton.Text = "ESP: Отключено"
        end
    end)
    if not success then warn("Error in updateToggleESPButton: ", err) end
end

local function updateToggleGunChamButton()
    local success, err = pcall(function()
        if _G.GunChamEnabled then
            ToggleGunChamButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            ToggleGunChamButton.Text = "Gun Cham: Включено"
        else
            ToggleGunChamButton.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
            ToggleGunChamButton.Text = "Gun Cham: Отключено"
        end
    end)
    if not success then warn("Error in updateToggleGunChamButton: ", err) end
end

local function resetHitboxes()
    local success, err = pcall(function()
        for _, player in pairs(Players:GetPlayers()) do
            if player and player ~= LocalPlayer and player.Character then
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.Size = Vector3.new(2, 2, 1)
                    rootPart.Transparency = 1
                    rootPart.Material = Enum.Material.Plastic
                    rootPart.BrickColor = BrickColor.new("Medium stone grey")
                    rootPart.CanCollide = true
                end
            end
        end
    end)
    if not success then warn("Error in resetHitboxes: ", err) end
end

local function applyPlayerSpeed()
    local success, err = pcall(function()
        local character = LocalPlayer.Character
        if character and character:FindFirstChildOfClass("Humanoid") then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if _G.OriginalWalkSpeed == nil then
                _G.OriginalWalkSpeed = humanoid.WalkSpeed
            end
            humanoid.WalkSpeed = _G.PlayerSpeed
        end
    end)
    if not success then warn("Error in applyPlayerSpeed: ", err) end
end

local function resetPlayerSpeed()
    local success, err = pcall(function()
        local character = LocalPlayer.Character
        if character and character:FindFirstChildOfClass("Humanoid") and _G.OriginalWalkSpeed ~= nil then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            humanoid.WalkSpeed = _G.OriginalWalkSpeed
            _G.OriginalWalkSpeed = nil
        end
    end)
    if not success then warn("Error in resetPlayerSpeed: ", err) end
end

local function updateScriptConnection()
    local success, err = pcall(function()
        if not _G.Disabled then
            if not renderSteppedConnection then
                renderSteppedConnection = RunService.RenderStepped:Connect(function()
                    for _, player in pairs(Players:GetPlayers()) do
                        if player and player ~= LocalPlayer and player.Character then
                            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                            if rootPart then
                                if _G.HitboxSize > 0 then
                                    rootPart.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                                    rootPart.Material = Enum.Material.Plastic
                                    rootPart.BrickColor = BrickColor.new(_G.HitboxColor)
                                    rootPart.Transparency = 0.7
                                    rootPart.CanCollide = false
                                else
                                    rootPart.Size = Vector3.new(2, 2, 1)
                                    rootPart.Transparency = 1
                                    rootPart.Material = Enum.Material.Plastic
                                    rootPart.BrickColor = BrickColor.new("Medium stone grey")
                                    rootPart.CanCollide = true
                                end
                            end
                        end
                    end
                end)
                table.insert(connections, renderSteppedConnection)
            end
        else
            if renderSteppedConnection then
                renderSteppedConnection:Disconnect()
                renderSteppedConnection = nil
                resetHitboxes()
            end
        end
    end)
    if not success then warn("Error in updateScriptConnection: ", err) end
end

local function toggleHitboxState()
    local success, err = pcall(function()
        _G.Disabled = not _G.Disabled
        updateToggleHitboxButton()
        updateScriptConnection()
    end)
    if not success then warn("Error in toggleHitboxState: ", err) end
end

local function toggleSpeedState()
    local success, err = pcall(function()
        _G.SpeedEnabled = not _G.SpeedEnabled
        updateToggleSpeedButton()
        if _G.SpeedEnabled then
            applyPlayerSpeed()
        else
            resetPlayerSpeed()
        end
    end)
    if not success then warn("Error in toggleSpeedState: ", err) end
end

local function toggleESPState()
    local success, err = pcall(function()
        _G.EspEnabled = not _G.EspEnabled
        updateToggleESPButton()
        updateESPConnection()
    end)
    if not success then warn("Error in toggleESPState: ", err) end
end

local function toggleGunChamState()
    local success, err = pcall(function()
        _G.GunChamEnabled = not _G.GunChamEnabled
        updateToggleGunChamButton()
        updateGunCham()
    end)
    if not success then warn("Error in toggleGunChamState: ", err) end
end

updateToggleHitboxButton()
updateToggleSpeedButton()
updateToggleESPButton()
updateToggleGunChamButton()
updateScriptConnection()
updateESPConnection()
updateGunCham()

LocalPlayer.CharacterAdded:Connect(function(character)
    local success, err = pcall(function()
        task.wait(0.1)
        if _G.SpeedEnabled then applyPlayerSpeed() end
        if _G.EspEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and playerBeams[player] then
                    local beam = playerBeams[player]
                    beam.Attachment0 = character:FindFirstChild("HumanoidRootPart") and Instance.new("Attachment", character.HumanoidRootPart) or nil
                end
                if playerHighlights[player] and not playerHighlights[player].Parent then
                    playerHighlights[player].Parent = player.Character or Workspace
                    playerHighlights[player].Adornee = player.Character
                end
            end
        end
        if _G.GunChamEnabled then
            updateGunCham()
        end
    end)
    if not success then warn("Error in CharacterAdded: ", err) end
end)

connections["InputBegan"] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    local success, err = pcall(function()
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if isAwaitingBindInput then
                if currentBindTarget == "Hitbox" then
                    _G.ToggleScriptKeyCode = input.KeyCode
                    BindHitboxButton.Text = "Бинд хитбокса: " .. _G.ToggleScriptKeyCode.Name
                elseif currentBindTarget == "Speed" then
                    _G.ToggleSpeedKeyCode = input.KeyCode
                    BindSpeedButton.Text = "Бинд скорости: " .. _G.ToggleSpeedKeyCode.Name
                end
                isAwaitingBindInput = false
                currentBindTarget = nil
            elseif input.KeyCode == _G.ToggleScriptKeyCode then
                toggleHitboxState()
            elseif input.KeyCode == _G.ToggleSpeedKeyCode then
                toggleSpeedState()
            end
        end
    end)
    if not success then warn("Error in handleKeyBinds: ", err) end
end)

ToggleHitboxButton.MouseButton1Click:Connect(function()
    toggleHitboxState()
end)

ToggleSpeedButton.MouseButton1Click:Connect(function()
    toggleSpeedState()
end)

ToggleESPButton.MouseButton1Click:Connect(function()
    toggleESPState()
end)

ToggleGunChamButton.MouseButton1Click:Connect(function()
    toggleGunChamState()
end)

BindHitboxButton.MouseButton1Click:Connect(function()
    if not isAwaitingBindInput then
        isAwaitingBindInput = true
        currentBindTarget = "Hitbox"
        BindHitboxButton.Text = "Нажмите кнопку..."
        BindSpeedButton.Text = "Бинд скорости: " .. _G.ToggleSpeedKeyCode.Name
    end
end)

BindSpeedButton.MouseButton1Click:Connect(function()
    if not isAwaitingBindInput then
        isAwaitingBindInput = true
        currentBindTarget = "Speed"
        BindSpeedButton.Text = "Нажмите кнопку..."
        BindHitboxButton.Text = "Бинд хитбокса: " .. _G.ToggleScriptKeyCode.Name
    end
end)

-- Инициализация ESP для существующих игроков
for _, player in pairs(Players:GetPlayers()) do
    esp(player)
end

-- Подсветка выпавших пистолетов при добавлении в Workspace
Workspace.ChildAdded:Connect(function(part)
    if _G.GunChamEnabled and part:IsA("BasePart") and part.Name == "GunDrop" then
        HighlightPlayer(part, "Bright blue")
    end
end)
