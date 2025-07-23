-- ====================================================================================
-- УПРАВЛЕНИЕ: СКРИПТ (ИСПРАВЛЕНО ДЛЯ MM2, ХИТБОКСОВ ПРИ 0, РОЛЕЙ, ESP С ТОЛСТЫМ ОТОБРАЖЕНИЕМ)
-- Type: LocalScript
-- Parent: StarterPlayer.StarterPlayerScripts
-- ====================================================================================

-- Глобальные переменные
_G.HitboxSize = _G.HitboxSize or 0
_G.Disabled = _G.Disabled or true
_G.HitboxColor = _G.HitboxColor or Color3.fromRGB(117, 7, 181)
_G.GUIVisible = _G.GUIVisible or true
_G.EspEnabled = _G.EspEnabled or false
_G.PlayerSpeed = _G.PlayerSpeed or 16
_G.SpeedEnabled = _G.SpeedEnabled or false
_G.JumpPower = _G.JumpPower or 50
_G.JumpEnabled = _G.JumpEnabled or false
_G.OriginalWalkSpeed = nil
_G.OriginalJumpPower = nil
_G.ToggleGUIKeyCode = _G.ToggleGUIKeyCode or Enum.KeyCode.Insert
_G.ToggleScriptKeyCode = _G.ToggleScriptKeyCode or Enum.KeyCode.Backspace
_G.ToggleSpeedKeyCode = _G.ToggleSpeedKeyCode or Enum.KeyCode.V
_G.ToggleJumpKeyCode = _G.ToggleJumpKeyCode or Enum.KeyCode.B

-- Сервисы
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ждем загрузки локального игрока и его PlayerGui
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    LocalPlayer = Players.PlayerAdded:Wait()
end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Названия элементов GUI
local GUI_NAME = "ControlGUI"
local MAIN_FRAME_NAME = "MainFrame"
local TITLE_LABEL_NAME = "TitleLabel"
local SLIDER_FRAME_NAME = "HitboxSliderFrame"
local HITBOX_SIZE_LABEL_NAME = "HitboxSizeLabel"
local TOGGLE_BUTTON_NAME = "ToggleHitboxButton"
local CLOSE_BUTTON_NAME = "CloseButton"
local TOGGLE_VISIBILITY_BUTTON_NAME = "ToggleVisibilityButton"
local BIND_HITBOX_BUTTON_NAME = "BindHitboxButton"
local SPEED_SLIDER_FRAME_NAME = "SpeedSliderFrame"
local PLAYER_SPEED_LABEL_NAME = "PlayerSpeedLabel"
local TOGGLE_SPEED_BUTTON_NAME = "ToggleSpeedButton"
local BIND_SPEED_BUTTON_NAME = "BindSpeedButton"
local JUMP_SLIDER_FRAME_NAME = "JumpSliderFrame"
local JUMP_POWER_LABEL_NAME = "JumpPowerLabel"
local TOGGLE_JUMP_BUTTON_NAME = "ToggleJumpButton"
local BIND_JUMP_BUTTON_NAME = "BindJumpButton"
local TOGGLE_ESP_BUTTON_NAME = "ToggleESPButton"

local ScreenGui, MainFrame, TitleLabel, HitboxSliderFrame, HitboxSliderKnob, HitboxSizeLabel, ToggleHitboxButton, CloseButton, ToggleVisibilityButton, BindHitboxButton
local SpeedSliderFrame, SpeedSliderKnob, PlayerSpeedLabel, ToggleSpeedButton, BindSpeedButton, JumpSliderFrame, JumpSliderKnob, JumpPowerLabel, ToggleJumpButton, BindJumpButton, ToggleESPButton

-- Флаг для режима назначения бинда
local isAwaitingBindInput = false
local currentBindTarget = nil

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

-- ====================================================================================
-- ИНИЦИАЛИЗАЦИЯ GUI
-- ====================================================================================

ScreenGui = PlayerGui:FindFirstChild(GUI_NAME)
if not ScreenGui then
    ScreenGui = createGuiElement("ScreenGui", {
        Name = GUI_NAME,
        ResetOnSpawn = false,
        Enabled = _G.GUIVisible,
        DisplayOrder = 999
    }, PlayerGui)
else
    ScreenGui.Enabled = _G.GUIVisible
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 999
end

MainFrame = ScreenGui:FindFirstChild(MAIN_FRAME_NAME)
if not MainFrame then
    MainFrame = createGuiElement("Frame", {
        Name = MAIN_FRAME_NAME,
        Size = UDim2.new(0, 300, 0, 500), -- Увеличен размер для всех функций
        Position = UDim2.new(0.5, -150, 0.5, -250),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0,
        Visible = true,
        ZIndex = 1
    }, ScreenGui)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 8) }, MainFrame)
else
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0, 300, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -250)
end

TitleLabel = MainFrame:FindFirstChild(TITLE_LABEL_NAME)
if not TitleLabel then
    TitleLabel = createGuiElement("TextLabel", {
        Name = TITLE_LABEL_NAME,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Управление",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 18,
        BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 8) }, TitleLabel)
else
    TitleLabel.Text = "Управление"
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
        ZIndex = 2
    }, TitleLabel)
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
        ZIndex = 2
    }, TitleLabel)
end

local originalFrameSize = MainFrame.Size
local isCollapsed = false

local function toggleGUICollapse()
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
        for _, element in ipairs(controllableElements) do
            element.Visible = false
        end
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
end

ToggleVisibilityButton.MouseButton1Click:Connect(toggleGUICollapse)

local isDragging = false
local dragStartPos
local frameStartPos

TitleLabel.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
        isDragging = true
        dragStartPos = UserInputService:GetMouseLocation()
        frameStartPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
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

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
    end
end)

HitboxSliderFrame = MainFrame:FindFirstChild(SLIDER_FRAME_NAME)
if not HitboxSliderFrame then
    HitboxSliderFrame = createGuiElement("Frame", {
        Name = SLIDER_FRAME_NAME,
        Size = UDim2.new(0.8, 0, 0, 10),
        Position = UDim2.new(0.1, 0, 0, 45),
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        BorderSizePixel = 0
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
        Text = ""
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
        BackgroundTransparency = 1
    }, MainFrame)
end
table.insert(controllableElements, HitboxSizeLabel)

local isHitboxSliderDragging = false
local hitboxSliderMin = 0
local hitboxSliderMax = 20

local function updateHitboxSliderKnobPosition()
    local sliderMovableWidth = HitboxSliderFrame.AbsoluteSize.X - HitboxSliderKnob.AbsoluteSize.X
    if sliderMovableWidth <= 0 or hitboxSliderMax == hitboxSliderMin then return end
    local ratio = (_G.HitboxSize - hitboxSliderMin) / (hitboxSliderMax - hitboxSliderMin)
    local clampedRelativeX = math.clamp(ratio * sliderMovableWidth, 0, sliderMovableWidth)
    HitboxSliderKnob.Position = UDim2.new(0, clampedRelativeX, 0, 0)
    HitboxSizeLabel.Text = "Размер хитбокса: " .. _G.HitboxSize
end

task.defer(updateHitboxSliderKnobPosition)

HitboxSliderKnob.MouseButton1Down:Connect(function()
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
        BackgroundColor3 = Color3.fromRGB(60, 60, 60)
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
        BackgroundColor3 = Color3.fromRGB(192, 57, 43)
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, ToggleHitboxButton)
end
table.insert(controllableElements, ToggleHitboxButton)

SpeedSliderFrame = MainFrame:FindFirstChild(SPEED_SLIDER_FRAME_NAME)
if not SpeedSliderFrame then
    SpeedSliderFrame = createGuiElement("Frame", {
        Name = SPEED_SLIDER_FRAME_NAME,
        Size = UDim2.new(0.8, 0, 0, 10),
        Position = UDim2.new(0.1, 0, 0, 185),
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        BorderSizePixel = 0
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
        Text = ""
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
        BackgroundTransparency = 1
    }, MainFrame)
end
table.insert(controllableElements, PlayerSpeedLabel)

local isSpeedSliderDragging = false
local speedSliderMin = 16
local speedSliderMax = 100

local function updateSpeedSliderKnobPosition()
    local sliderMovableWidth = SpeedSliderFrame.AbsoluteSize.X - SpeedSliderKnob.AbsoluteSize.X
    if sliderMovableWidth <= 0 or speedSliderMax == speedSliderMin then return end
    local ratio = (_G.PlayerSpeed - speedSliderMin) / (speedSliderMax - speedSliderMin)
    local clampedRelativeX = math.clamp(ratio * sliderMovableWidth, 0, sliderMovableWidth)
    SpeedSliderKnob.Position = UDim2.new(0, clampedRelativeX, 0, 0)
    PlayerSpeedLabel.Text = "Скорость: " .. _G.PlayerSpeed
end

task.defer(updateSpeedSliderKnobPosition)

SpeedSliderKnob.MouseButton1Down:Connect(function()
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
        BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, BindSpeedButton)
end
table.insert(controllableElements, BindSpeedButton)

ToggleSpeedButton = MainFrame:FindFirstChild(TOGGLE_SPEED_BUTTON_NAME)
if not ToggleSpeedButton then
    ToggleSpeedButton = createGuiElement("TextButton", {
        Name = TOGGLE_SPEED_BUTTON_NAME,
        Size = UDim2.new(0.8, 0, 0, 30),
        Position = UDim2.new(0.1, 0, 0, 265),
        Text = "Скорость: Отключена",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        BackgroundColor3 = Color3.fromRGB(192, 57, 43)
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, ToggleSpeedButton)
end
table.insert(controllableElements, ToggleSpeedButton)

JumpSliderFrame = MainFrame:FindFirstChild(JUMP_SLIDER_FRAME_NAME)
if not JumpSliderFrame then
    JumpSliderFrame = createGuiElement("Frame", {
        Name = JUMP_SLIDER_FRAME_NAME,
        Size = UDim2.new(0.8, 0, 0, 10),
        Position = UDim2.new(0.1, 0, 0, 315),
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        BorderSizePixel = 0
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, JumpSliderFrame)
end
table.insert(controllableElements, JumpSliderFrame)

JumpSliderKnob = JumpSliderFrame:FindFirstChild("JumpSliderKnob")
if not JumpSliderKnob then
    JumpSliderKnob = createGuiElement("TextButton", {
        Name = "JumpSliderKnob",
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(100, 100, 100),
        BorderSizePixel = 0,
        Text = ""
    }, JumpSliderFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }, JumpSliderKnob)
end

JumpPowerLabel = MainFrame:FindFirstChild(JUMP_POWER_LABEL_NAME)
if not JumpPowerLabel then
    JumpPowerLabel = createGuiElement("TextLabel", {
        Name = JUMP_POWER_LABEL_NAME,
        Size = UDim2.new(0.8, 0, 0, 20),
        Position = UDim2.new(0.1, 0, 0, 330),
        Text = "Сила прыжка: " .. _G.JumpPower,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BackgroundTransparency = 1
    }, MainFrame)
end
table.insert(controllableElements, JumpPowerLabel)

local isJumpSliderDragging = false
local jumpSliderMin = 50
local jumpSliderMax = 200

local function updateJumpSliderKnobPosition()
    local sliderMovableWidth = JumpSliderFrame.AbsoluteSize.X - JumpSliderKnob.AbsoluteSize.X
    if sliderMovableWidth <= 0 or jumpSliderMax == jumpSliderMin then return end
    local ratio = (_G.JumpPower - jumpSliderMin) / (jumpSliderMax - jumpSliderMin)
    local clampedRelativeX = math.clamp(ratio * sliderMovableWidth, 0, sliderMovableWidth)
    JumpSliderKnob.Position = UDim2.new(0, clampedRelativeX, 0, 0)
    JumpPowerLabel.Text = "Сила прыжка: " .. _G.JumpPower
end

task.defer(updateJumpSliderKnobPosition)

JumpSliderKnob.MouseButton1Down:Connect(function()
    isJumpSliderDragging = true
    local sliderMovedConnection = UserInputService.InputChanged:Connect(function(input)
        if isJumpSliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local currentMouseX = UserInputService:GetMouseLocation().X
            local newRelativeX = currentMouseX - JumpSliderFrame.AbsolutePosition.X
            local sliderMovableWidth = JumpSliderFrame.AbsoluteSize.X - JumpSliderKnob.AbsoluteSize.X
            local clampedRelativeX = math.clamp(newRelativeX, 0, sliderMovableWidth)
            JumpSliderKnob.Position = UDim2.new(0, clampedRelativeX, 0, 0)
            local ratio = clampedRelativeX / sliderMovableWidth
            _G.JumpPower = math.floor(jumpSliderMin + (jumpSliderMax - jumpSliderMin) * ratio)
            _G.JumpPower = math.clamp(_G.JumpPower, jumpSliderMin, jumpSliderMax)
            JumpPowerLabel.Text = "Сила прыжка: " .. _G.JumpPower
            if _G.JumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character.Humanoid.JumpPower = _G.JumpPower
            end
        end
    end)
    local sliderEndedConnection = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isJumpSliderDragging = false
            sliderMovedConnection:Disconnect()
            sliderEndedConnection:Disconnect()
        end
    end)
end)

BindJumpButton = MainFrame:FindFirstChild(BIND_JUMP_BUTTON_NAME)
if not BindJumpButton then
    BindJumpButton = createGuiElement("TextButton", {
        Name = BIND_JUMP_BUTTON_NAME,
        Size = UDim2.new(0.8, 0, 0, 30),
        Position = UDim2.new(0.1, 0, 0, 365),
        Text = "Бинд прыжка: " .. _G.ToggleJumpKeyCode.Name,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, BindJumpButton)
end
table.insert(controllableElements, BindJumpButton)

ToggleJumpButton = MainFrame:FindFirstChild(TOGGLE_JUMP_BUTTON_NAME)
if not ToggleJumpButton then
    ToggleJumpButton = createGuiElement("TextButton", {
        Name = TOGGLE_JUMP_BUTTON_NAME,
        Size = UDim2.new(0.8, 0, 0, 30),
        Position = UDim2.new(0.1, 0, 0, 395),
        Text = "Прыжок: Отключен",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        BackgroundColor3 = Color3.fromRGB(192, 57, 43)
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, ToggleJumpButton)
end
table.insert(controllableElements, ToggleJumpButton)

ToggleESPButton = MainFrame:FindFirstChild(TOGGLE_ESP_BUTTON_NAME)
if not ToggleESPButton then
    ToggleESPButton = createGuiElement("TextButton", {
        Name = TOGGLE_ESP_BUTTON_NAME,
        Size = UDim2.new(0.8, 0, 0, 30),
        Position = UDim2.new(0.1, 0, 0, 435),
        Text = "ESP: Отключено",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        BackgroundColor3 = Color3.fromRGB(192, 57, 43)
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, ToggleESPButton)
end
table.insert(controllableElements, ToggleESPButton)

-- ====================================================================================
-- ЛОГИКА ESP
-- ====================================================================================

local Camera = Workspace.CurrentCamera
local playerESPConnections = {}
local playerESPLines = {}
local playerPistolLines = {}
local playerBillboards = {}

-- Настройки ESP
local Box_Color = Color3.fromRGB(63, 49, 214)
local Box_Thickness = 3
local Box_Transparency = 1
local Tracers = true
local Tracer_Color = Color3.fromRGB(63, 49, 214)
local Tracer_Thickness = 3
local Tracer_Transparency = 1
local Autothickness = false
local Team_Check = true
local teamColors = {
    Innocent = Color3.fromRGB(88, 217, 24),
    Civilian = Color3.fromRGB(88, 217, 24),
    Survivor = Color3.fromRGB(88, 217, 24),
    InnocentPlayer = Color3.fromRGB(88, 217, 24),
    Sheriff = Color3.fromRGB(0, 162, 255),
    Murderer = Color3.fromRGB(227, 52, 52),
    Hero = Color3.fromRGB(0, 162, 255),
    Terrorist = Color3.fromRGB(255, 147, 0),
    SWAT = Color3.fromRGB(0, 255, 255),
    RegularPlayer = Color3.fromRGB(255, 255, 255)
}
local Pistol_Color = Color3.fromRGB(255, 165, 0)
local Pistol_Thickness = 4
local Pistol_Transparency = 0.7

-- Отслеживание смерти шерифа
local sheriffAlive = true
local currentSheriff = nil

local function NewLine()
    local line = Drawing.new("Line")
    line.Visible = false
    line.From = Vector2.new(0, 0)
    line.To = Vector2.new(1, 1)
    line.Color = Box_Color
    line.Thickness = Box_Thickness
    line.Transparency = Box_Transparency
    return line
end

local function NewRectangle()
    local rect = Drawing.new("Rectangle")
    rect.Visible = false
    rect.Color = Pistol_Color
    rect.Thickness = Pistol_Thickness
    rect.Transparency = Pistol_Transparency
    return rect
end

local function createESPLines()
    local lines = {
        line1 = NewLine(),
        line2 = NewLine(),
        line3 = NewLine(),
        line4 = NewLine(),
        line5 = NewLine(),
        line6 = NewLine(),
        line7 = NewLine(),
        line8 = NewLine(),
        line9 = NewLine(),
        line10 = NewLine(),
        line11 = NewLine(),
        line12 = NewLine(),
        Tracer = NewLine()
    }
    lines.Tracer.Color = Tracer_Color
    lines.Tracer.Thickness = Tracer_Thickness
    lines.Tracer.Transparency = Tracer_Transparency
    return lines
end

local function createPistolLines()
    local lines = {
        rect1 = NewRectangle(),
        rect2 = NewRectangle(),
        rect3 = NewRectangle(),
        rect4 = NewRectangle()
    }
    return lines
end

local function createBillboardESP(targetPlayer)
    local billboard = Instance.new("BillboardGui")
    billboard.Parent = targetPlayer.Character:WaitForChild("Head")
    billboard.Size = UDim2.new(0, 350, 0, 200)
    billboard.Adornee = targetPlayer.Character:WaitForChild("Head")
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    local borderFrame = Instance.new("Frame")
    borderFrame.Parent = billboard
    borderFrame.Size = UDim2.new(1, 30, 1, 30)
    borderFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    borderFrame.BorderSizePixel = 0
    local innerFrame = Instance.new("Frame")
    innerFrame.Parent = billboard
    innerFrame.Size = UDim2.new(1, -60, 1, -60)
    innerFrame.Position = UDim2.new(0, 30, 0, 30)
    innerFrame.BackgroundColor3 = teamColors[getPlayerRole(targetPlayer)] or teamColors.RegularPlayer
    innerFrame.BackgroundTransparency = 0.3
    local nicknameText = Instance.new("TextLabel")
    nicknameText.Parent = billboard
    nicknameText.Size = UDim2.new(0, 200, 0, 40)
    nicknameText.Position = UDim2.new(0.5, -100, 0, -150)
    nicknameText.Text = targetPlayer.Name
    nicknameText.TextColor3 = teamColors[getPlayerRole(targetPlayer)] or Color3.fromRGB(255, 255, 255)
    nicknameText.Font = Enum.Font.SourceSansBold
    nicknameText.TextSize = 20
    nicknameText.BackgroundTransparency = 1
    nicknameText.Visible = true
    local pistolText = Instance.new("TextLabel")
    pistolText.Parent = billboard
    pistolText.Size = UDim2.new(0, 100, 0, 50)
    pistolText.Position = UDim2.new(0.5, -50, 0, -60)
    pistolText.Text = "GUN"
    pistolText.TextColor3 = Pistol_Color
    pistolText.Font = Enum.Font.SourceSansBold
    pistolText.TextSize = 24
    pistolText.BackgroundTransparency = 1
    pistolText.Visible = false
    playerBillboards[targetPlayer.UserId] = billboard
end

local function getPlayerRole(targetPlayer)
    local character = targetPlayer.Character
    if not character then
        character = targetPlayer.CharacterAdded:Wait()
        task.wait(2)
    end
    local role = "RegularPlayer"
    
    local roleValue = character:FindFirstChild("Role")
    if roleValue and roleValue:IsA("StringValue") and teamColors[roleValue.Value] then
        role = roleValue.Value
    end
    
    local dataFolder = character:FindFirstChild("Data")
    if dataFolder then
        local dataRole = dataFolder:FindFirstChild("Role")
        if dataRole and dataRole:IsA("StringValue") and teamColors[dataRole.Value] then
            role = dataRole.Value
        end
    end
    
    local playerData = targetPlayer:FindFirstChild("Data")
    if playerData then
        local playerRole = playerData:FindFirstChild("Role")
        if playerRole and playerRole:IsA("StringValue") and teamColors[playerRole.Value] then
            role = playerRole.Value
        end
    end
    
    local gameData = ReplicatedStorage:FindFirstChild("GameData")
    if gameData then
        local playerRoleValue = gameData:FindFirstChild(targetPlayer.Name)
        if playerRoleValue and playerRoleValue:IsA("StringValue") and teamColors[playerRoleValue.Value] then
            role = playerRoleValue.Value
        end
    end
    
    local backpack = targetPlayer:FindFirstChild("Backpack")
    if backpack then
        local tools = backpack:GetChildren()
        for _, tool in pairs(tools) do
            if tool.Name:lower():find("knife") or tool.Name:lower():find("murder") or tool.Name:lower():find("murderer") or tool.Name:lower():find("blade") then
                role = "Murderer"
            elseif tool.Name:lower():find("gun") or tool.Name:lower():find("pistol") or tool.Name:lower():find("sheriff") or tool.Name:lower():find("herogun") or tool.Name:lower():find("hero") then
                if not sheriffAlive and currentSheriff and currentSheriff ~= targetPlayer then
                    role = "Hero"
                else
                    role = "Sheriff"
                end
            end
        end
        local characterTools = character and character:FindFirstChildOfClass("Tool")
        if characterTools then
            if characterTools.Name:lower():find("knife") or characterTools.Name:lower():find("murder") or characterTools.Name:lower():find("murderer") or characterTools.Name:lower():find("blade") then
                role = "Murderer"
            elseif characterTools.Name:lower():find("gun") or characterTools.Name:lower():find("pistol") or characterTools.Name:lower():find("sheriff") or characterTools.Name:lower():find("herogun") or characterTools.Name:lower():find("hero") then
                if not sheriffAlive and currentSheriff and currentSheriff ~= targetPlayer then
                    role = "Hero"
                else
                    role = "Sheriff"
                end
            end
        end
    end

    if role == "RegularPlayer" and character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            local tools = character:GetChildren()
            for _, tool in pairs(tools) do
                if tool:IsA("Tool") and (tool.Name:lower():find("sheriff") or tool.Name:lower():find("gun")) then
                    role = "Sheriff"
                    break
                end
            end
        end
    end

    if role == "RegularPlayer" and (roleValue and (roleValue.Value == "Innocent" or roleValue.Value == "Civilian" or roleValue.Value == "Survivor" or roleValue.Value == "InnocentPlayer")) then
        role = roleValue.Value
    end

    return role
end

local function findPistolOrTexture(targetPlayer)
    local character = targetPlayer.Character
    local pistol = nil

    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Handle") then
            if tool.Name:lower():find("pistol") or tool.Name:lower():find("gun") or tool.Name:lower():find("sheriff") or tool.Name:lower():find("herogun") or tool.Name:lower():find("hero") then
                pistol = tool
            end
        end

        local backpack = targetPlayer:FindFirstChild("Backpack")
        if backpack and not pistol then
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:FindFirstChild("Handle") then
                    if tool.Name:lower():find("pistol") or tool.Name:lower():find("gun") or tool.Name:lower():find("sheriff") or tool.Name:lower():find("herogun") or tool.Name:lower():find("hero") then
                        pistol = tool
                        break
                    end
                end
            end
        end

        if not pistol then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") and (part.Name:lower():find("arm") or part.Name:lower():find("hand")) then
                        local texture = part:FindFirstChildOfClass("Decal")
                        if texture and (texture.Texture:lower():find("pistol") or texture.Texture:lower():find("gun")) then
                            pistol = part
                            break
                        end
                    end
                end
            end
        end
    end

    return pistol
end

local function updateESP(targetPlayer, lines, pistolLines)
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Humanoid") or
       not targetPlayer.Character:FindFirstChild("HumanoidRootPart") or targetPlayer.Name == LocalPlayer.Name or
       targetPlayer.Character.Humanoid.Health <= 0 or not targetPlayer.Character:FindFirstChild("Head") then
        for _, x in pairs(lines) do
            if x then x.Visible = false end
        end
        for _, x in pairs(pistolLines) do
            if x then x.Visible = false end
        end
        if playerBillboards[targetPlayer.UserId] then
            playerBillboards[targetPlayer.UserId].Enabled = false
            local nicknameText = playerBillboards[targetPlayer.UserId]:FindFirstChild("NicknameText")
            if nicknameText then nicknameText.Visible = false end
            local pistolText = playerBillboards[targetPlayer.UserId]:FindFirstChild("PistolText")
            if pistolText then pistolText.Visible = false end
        end
        return
    end

    local pos, vis = Camera:WorldToViewportPoint(targetPlayer.Character.HumanoidRootPart.Position)
    if vis and _G.EspEnabled then
        local Scale = targetPlayer.Character.Head.Size.Y / 2
        local Size = Vector3.new(2, 3, 1.5) * (Scale * 2)

        local Top1 = Camera:WorldToViewportPoint((targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(-Size.X, Size.Y, -Size.Z)).p)
        local Top2 = Camera:WorldToViewportPoint((targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(-Size.X, Size.Y, Size.Z)).p)
        local Top3 = Camera:WorldToViewportPoint((targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(Size.X, Size.Y, Size.Z)).p)
        local Top4 = Camera:WorldToViewportPoint((targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(Size.X, Size.Y, -Size.Z)).p)

        local Bottom1 = Camera:WorldToViewportPoint((targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(-Size.X, -Size.Y, -Size.Z)).p)
        local Bottom2 = Camera:WorldToViewportPoint((targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(-Size.X, -Size.Y, Size.Z)).p)
        local Bottom3 = Camera:WorldToViewportPoint((targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(Size.X, -Size.Y, Size.Z)).p)
        local Bottom4 = Camera:WorldToViewportPoint((targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(Size.X, -Size.Y, -Size.Z)).p)

        lines.line1.From = Vector2.new(Top1.X, Top1.Y)
        lines.line1.To = Vector2.new(Top2.X, Top2.Y)
        lines.line2.From = Vector2.new(Top2.X, Top2.Y)
        lines.line2.To = Vector2.new(Top3.X, Top3.Y)
        lines.line3.From = Vector2.new(Top3.X, Top3.Y)
        lines.line3.To = Vector2.new(Top4.X, Top4.Y)
        lines.line4.From = Vector2.new(Top4.X, Top4.Y)
        lines.line4.To = Vector2.new(Top1.X, Top1.Y)

        lines.line5.From = Vector2.new(Bottom1.X, Bottom1.Y)
        lines.line5.To = Vector2.new(Bottom2.X, Bottom2.Y)
        lines.line6.From = Vector2.new(Bottom2.X, Bottom2.Y)
        lines.line6.To = Vector2.new(Bottom3.X, Bottom3.Y)
        lines.line7.From = Vector2.new(Bottom3.X, Bottom3.Y)
        lines.line7.To = Vector2.new(Bottom4.X, Bottom4.Y)
        lines.line8.From = Vector2.new(Bottom4.X, Bottom4.Y)
        lines.line8.To = Vector2.new(Bottom1.X, Bottom1.Y)

        lines.line9.From = Vector2.new(Bottom1.X, Bottom1.Y)
        lines.line9.To = Vector2.new(Top1.X, Top1.Y)
        lines.line10.From = Vector2.new(Bottom2.X, Bottom2.Y)
        lines.line10.To = Vector2.new(Top2.X, Top2.Y)
        lines.line11.From = Vector2.new(Bottom3.X, Bottom3.Y)
        lines.line11.To = Vector2.new(Top3.X, Top3.Y)
        lines.line12.From = Vector2.new(Bottom4.X, Bottom4.Y)
        lines.line12.To = Vector2.new(Top4.X, Top4.Y)

        if Tracers then
            local trace = Camera:WorldToViewportPoint((targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, -Size.Y, 0)).p)
            lines.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            lines.Tracer.To = Vector2.new(trace.X, trace.Y)
        end

        if Team_Check then
            local teamName = getPlayerRole(targetPlayer)
            local color = teamColors[teamName] or teamColors.RegularPlayer
            for _, x in pairs(lines) do
                if x then x.Color = color end
            end
            if playerBillboards[targetPlayer.UserId] then
                playerBillboards[targetPlayer.UserId].innerFrame.BackgroundColor3 = color
                local nicknameText = playerBillboards[targetPlayer.UserId]:FindFirstChild("NicknameText")
                if nicknameText then nicknameText.TextColor3 = color end
            end
        else
            for _, x in pairs(lines) do
                if x then x.Color = Box_Color end
            end
        end

        if Autothickness then
            local distance = (LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart and 
                            (LocalPlayer.Character.HumanoidRootPart.Position - targetPlayer.Character.HumanoidRootPart.Position).magnitude) or 100
            local value = math.clamp(1 / distance * 100, 0.1, 4)
            for _, x in pairs(lines) do
                if x then x.Thickness = value end
            end
        else
            for _, x in pairs(lines) do
                if x then x.Thickness = Box_Thickness end
            end
        end

        for _, x in pairs(lines) do
            if x and x ~= lines.Tracer then x.Visible = true end
        end
        if Tracers and lines.Tracer then lines.Tracer.Visible = true end

        local pistolPart = findPistolOrTexture(targetPlayer)
        if pistolPart then
            local pistolPos, pistolVis = Camera:WorldToViewportPoint(pistolPart.Position)
            if pistolVis then
                local pistolSize = Vector2.new(20, 20)
                pistolLines.rect1.Position = Vector2.new(pistolPos.X - pistolSize.X / 2, pistolPos.Y - pistolSize.Y / 2)
                pistolLines.rect1.Size = Vector2.new(pistolSize.X, 1)
                pistolLines.rect2.Position = Vector2.new(pistolPos.X - pistolSize.X / 2, pistolPos.Y + pistolSize.Y / 2 - 1)
                pistolLines.rect2.Size = Vector2.new(pistolSize.X, 1)
                pistolLines.rect3.Position = Vector2.new(pistolPos.X - pistolSize.X / 2, pistolPos.Y - pistolSize.Y / 2)
                pistolLines.rect3.Size = Vector2.new(1, pistolSize.Y)
                pistolLines.rect4.Position = Vector2.new(pistolPos.X + pistolSize.X / 2 - 1, pistolPos.Y - pistolSize.Y / 2)
                pistolLines.rect4.Size = Vector2.new(1, pistolSize.Y)
                for _, x in pairs(pistolLines) do x.Visible = true end
                local billboard = playerBillboards[targetPlayer.UserId]
                if billboard then
                    local pistolText = billboard:FindFirstChild("PistolText")
                    if pistolText then
                        pistolText.Position = UDim2.new(0, pistolPos.X - Camera.ViewportSize.X / 2, 0, pistolPos.Y - Camera.ViewportSize.Y - 50)
                        pistolText.Visible = true
                    end
                end
            else
                for _, x in pairs(pistolLines) do x.Visible = false end
                local billboard = playerBillboards[targetPlayer.UserId]
                if billboard then
                    local pistolText = billboard:FindFirstChild("PistolText")
                    if pistolText then pistolText.Visible = false end
                end
            end
        else
            for _, x in pairs(pistolLines) do x.Visible = false end
            local billboard = playerBillboards[targetPlayer.UserId]
            if billboard then
                local pistolText = billboard:FindFirstChild("PistolText")
                if pistolText then pistolText.Visible = false end
            end
        end

        if not next(lines) and not playerBillboards[targetPlayer.UserId] then
            createBillboardESP(targetPlayer)
        elseif playerBillboards[targetPlayer.UserId] then
            playerBillboards[targetPlayer.UserId].Enabled = true
            local teamName = getPlayerRole(targetPlayer)
            playerBillboards[targetPlayer.UserId].innerFrame.BackgroundColor3 = teamColors[teamName] or teamColors.RegularPlayer
            local nicknameText = playerBillboards[targetPlayer.UserId]:FindFirstChild("NicknameText")
            if nicknameText then
                nicknameText.Text = targetPlayer.Name
                nicknameText.Position = UDim2.new(0, pos.X - Camera.ViewportSize.X / 2 - 100, 0, pos.Y - Camera.ViewportSize.Y - 150)
                nicknameText.TextColor3 = teamColors[teamName] or Color3.fromRGB(255, 255, 255)
                nicknameText.Visible = true
            end
        end
    else
        for _, x in pairs(lines) do
            if x then x.Visible = false end
        end
        for _, x in pairs(pistolLines) do
            if x then x.Visible = false end
        end
        if playerBillboards[targetPlayer.UserId] then
            playerBillboards[targetPlayer.UserId].Enabled = false
            local nicknameText = playerBillboards[targetPlayer.UserId]:FindFirstChild("NicknameText")
            if nicknameText then nicknameText.Visible = false end
            local pistolText = playerBillboards[targetPlayer.UserId]:FindFirstChild("PistolText")
            if pistolText then pistolText.Visible = false end
        end
    end
end

local function setupESPForPlayer(targetPlayer)
    if playerESPLines[targetPlayer.UserId] then
        for _, line in pairs(playerESPLines[targetPlayer.UserId]) do
            if line then line.Visible = false end
        end
        if playerESPConnections[targetPlayer.UserId] then
            playerESPConnections[targetPlayer.UserId]:Disconnect()
        end
    end
    if playerPistolLines[targetPlayer.UserId] then
        for _, line in pairs(playerPistolLines[targetPlayer.UserId]) do
            if line then line.Visible = false end
        end
    end

    local lines = createESPLines()
    local pistolLines = createPistolLines()
    playerESPLines[targetPlayer.UserId] = lines
    playerPistolLines[targetPlayer.UserId] = pistolLines

    if not next(lines) and not playerBillboards[targetPlayer.UserId] then
        createBillboardESP(targetPlayer)
    end

    local connection = RunService.RenderStepped:Connect(function()
        updateESP(targetPlayer, lines, pistolLines)
    end)
    playerESPConnections[targetPlayer.UserId] = connection
end

local function removeESPForPlayer(targetPlayer)
    if playerESPConnections[targetPlayer.UserId] then
        playerESPConnections[targetPlayer.UserId]:Disconnect()
        playerESPConnections[targetPlayer.UserId] = nil
    end
    if playerESPLines[targetPlayer.UserId] then
        for _, line in pairs(playerESPLines[targetPlayer.UserId]) do
            if line then line:Remove() end
        end
        playerESPLines[targetPlayer.UserId] = nil
    end
    if playerPistolLines[targetPlayer.UserId] then
        for _, line in pairs(playerPistolLines[targetPlayer.UserId]) do
            if line then line:Remove() end
        end
        playerPistolLines[targetPlayer.UserId] = nil
    end
    if playerBillboards[targetPlayer.UserId] then
        playerBillboards[targetPlayer.UserId]:Destroy()
        playerBillboards[targetPlayer.UserId] = nil
    end
end

for _, v in pairs(Players:GetPlayers()) do
    if v ~= LocalPlayer then
        setupESPForPlayer(v)
    end
end

Players.PlayerAdded:Connect(function(newPlayer)
    if newPlayer ~= LocalPlayer then
        setupESPForPlayer(newPlayer)
    end
end)

Players.PlayerRemoving:Connect(function(removedPlayer)
    removeESPForPlayer(removedPlayer)
end)

local function updateESPConnection()
    if _G.EspEnabled then
        for userId, lines in pairs(playerESPLines) do
            local targetPlayer = Players:GetPlayerByUserId(userId)
            if targetPlayer then
                updateESP(targetPlayer, lines, playerPistolLines[userId] or {})
            end
        end
    else
        for userId, lines in pairs(playerESPLines) do
            for _, line in pairs(lines) do
                if line then line.Visible = false end
            end
            for _, line in pairs(playerPistolLines[userId] or {}) do
                if line then line.Visible = false end
            end
            if playerBillboards[userId] then
                playerBillboards[userId].Enabled = false
                local nicknameText = playerBillboards[userId]:FindFirstChild("NicknameText")
                if nicknameText then nicknameText.Visible = false end
                local pistolText = playerBillboards[userId]:FindFirstChild("PistolText")
                if pistolText then pistolText.Visible = false end
            end
        end
    end
    if not _G.EspEnabled and sheriffAlive == false then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local characterTools = player.Character:FindFirstChildOfClass("Tool")
                if characterTools and (characterTools.Name:lower():find("gun") or characterTools.Name:lower():find("herogun") or characterTools.Name:lower():find("hero")) then
                    local billboard = playerBillboards[player.UserId]
                    if billboard then
                        billboard.innerFrame.BackgroundColor3 = teamColors["Sheriff"]
                        local nicknameText = billboard:FindFirstChild("NicknameText")
                        if nicknameText then nicknameText.TextColor3 = teamColors["Sheriff"] end
                    end
                end
            end
        end
    end
end

-- ====================================================================================
-- ЛОГИКА СКРИПТА
-- ====================================================================================

local function updateToggleHitboxButton()
    if _G.Disabled then
        ToggleHitboxButton.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
        ToggleHitboxButton.Text = "Хитбоксы: Отключены"
    else
        ToggleHitboxButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        ToggleHitboxButton.Text = "Хитбоксы: Включены"
    end
end

local function updateToggleSpeedButton()
    if _G.SpeedEnabled then
        ToggleSpeedButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        ToggleSpeedButton.Text = "Скорость: Включена"
    else
        ToggleSpeedButton.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
        ToggleSpeedButton.Text = "Скорость: Отключена"
    end
end

local function updateToggleJumpButton()
    if _G.JumpEnabled then
        ToggleJumpButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        ToggleJumpButton.Text = "Прыжок: Включен"
    else
        ToggleJumpButton.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
        ToggleJumpButton.Text = "Прыжок: Отключен"
    end
end

local function updateToggleESPButton()
    if _G.EspEnabled then
        ToggleESPButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        ToggleESPButton.Text = "ESP: Включено"
    else
        ToggleESPButton.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
        ToggleESPButton.Text = "ESP: Отключено"
    end
end

local function resetHitboxes()
    for _, player in Players:GetPlayers() do
        if player and player ~= LocalPlayer then
            local character = player.Character
            if character then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.Transparency = 1
                    rootPart.Material = Enum.Material.Plastic
                    rootPart.BrickColor = BrickColor.new("Medium stone grey")
                    rootPart.CanCollide = true
                    rootPart.Size = Vector3.new(2, 2, 1)
                end
            end
        end
    end
end

local function applyPlayerSpeed()
    local character = LocalPlayer.Character
    if character and character:FindFirstChildOfClass("Humanoid") then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if _G.OriginalWalkSpeed == nil then
            _G.OriginalWalkSpeed = humanoid.WalkSpeed
        end
        humanoid.WalkSpeed = _G.PlayerSpeed
    end
end

local function resetPlayerSpeed()
    local character = LocalPlayer.Character
    if character and character:FindFirstChildOfClass("Humanoid") and _G.OriginalWalkSpeed ~= nil then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        humanoid.WalkSpeed = _G.OriginalWalkSpeed
        _G.OriginalWalkSpeed = nil
    end
end

local function applyJumpPower()
    local character = LocalPlayer.Character
    if character and character:FindFirstChildOfClass("Humanoid") then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if _G.OriginalJumpPower == nil then
            _G.OriginalJumpPower = humanoid.JumpPower
        end
        humanoid.JumpPower = _G.JumpPower
    end
end

local function resetJumpPower()
    local character = LocalPlayer.Character
    if character and character:FindFirstChildOfClass("Humanoid") and _G.OriginalJumpPower ~= nil then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        humanoid.JumpPower = _G.OriginalJumpPower
        _G.OriginalJumpPower = nil
    end
end

local renderSteppedConnection = nil

local function updateScriptConnection()
    if not _G.Disabled then
        if not renderSteppedConnection then
            renderSteppedConnection = RunService.RenderStepped:Connect(function()
                for _, player in Players:GetPlayers() do
                    if player and player ~= LocalPlayer then
                        local character = player.Character
                        if character and character.Parent then
                            local rootPart = character:FindFirstChild("HumanoidRootPart")
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
                end
            end)
        end
    else
        if renderSteppedConnection then
            renderSteppedConnection:Disconnect()
            renderSteppedConnection = nil
            resetHitboxes()
        end
    end
end

local function toggleGUIVisibility()
    _G.GUIVisible = not _G.GUIVisible
    ScreenGui.Enabled = _G.GUIVisible
end

local function toggleHitboxState()
    _G.Disabled = not _G.Disabled
    updateToggleHitboxButton()
    updateScriptConnection()
end

local function toggleSpeedState()
    _G.SpeedEnabled = not _G.SpeedEnabled
    updateToggleSpeedButton()
    if _G.SpeedEnabled then
        applyPlayerSpeed()
    else
        resetPlayerSpeed()
    end
end

local function toggleJumpState()
    _G.JumpEnabled = not _G.JumpEnabled
    updateToggleJumpButton()
    if _G.JumpEnabled then
        applyJumpPower()
    else
        resetJumpPower()
    end
end

local function toggleESPState()
    _G.EspEnabled = not _G.EspEnabled
    updateToggleESPButton()
    updateESPConnection()
end

updateToggleHitboxButton()
updateToggleSpeedButton()
updateToggleJumpButton()
updateToggleESPButton()
updateScriptConnection()
updateESPConnection()
updateHitboxSliderKnobPosition()
updateSpeedSliderKnobPosition()
updateJumpSliderKnobPosition()

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.1)
    if _G.SpeedEnabled then applyPlayerSpeed() end
    if _G.JumpEnabled then applyJumpPower() end
end)

ToggleHitboxButton.MouseButton1Click:Connect(toggleHitboxState)
CloseButton.MouseButton1Click:Connect(toggleGUIVisibility)
ToggleSpeedButton.MouseButton1Click:Connect(toggleSpeedState)
ToggleJumpButton.MouseButton1Click:Connect(toggleJumpState)
ToggleESPButton.MouseButton1Click:Connect(toggleESPState)

BindHitboxButton.MouseButton1Click:Connect(function()
    if not isAwaitingBindInput then
        isAwaitingBindInput = true
        currentBindTarget = "Hitbox"
        BindHitboxButton.Text = "Нажмите кнопку..."
        BindSpeedButton.Text = "Бинд скорости: " .. _G.ToggleSpeedKeyCode.Name
        BindJumpButton.Text = "Бинд прыжка: " .. _G.ToggleJumpKeyCode.Name
    end
end)

BindSpeedButton.MouseButton1Click:Connect(function()
    if not isAwaitingBindInput then
        isAwaitingBindInput = true
        currentBindTarget = "Speed"
        BindSpeedButton.Text = "Нажмите кнопку..."
        BindHitboxButton.Text = "Бинд хитбокса: " .. _G.ToggleScriptKeyCode.Name
        BindJumpButton.Text = "Бинд прыжка: " .. _G.ToggleJumpKeyCode.Name
    end
end)

BindJumpButton.MouseButton1Click:Connect(function()
    if not isAwaitingBindInput then
        isAwaitingBindInput = true
        currentBindTarget = "Jump"
        BindJumpButton.Text = "Нажмите кнопку..."
        BindHitboxButton.Text = "Бинд хитбокса: " .. _G.ToggleScriptKeyCode.Name
        BindSpeedButton.Text = "Бинд скорости: " .. _G.ToggleSpeedKeyCode.Name
    end
end)

ScreenGui.AncestryChanged:Connect(function()
    if not ScreenGui.Parent then
        _G.Disabled = true
        _G.SpeedEnabled = false
        _G.JumpEnabled = false
        _G.EspEnabled = false
        updateScriptConnection()
        updateESPConnection()
        resetPlayerSpeed()
        resetJumpPower()
    end
end)

local function handleKeyBinds(input, gameProcessed)
    if gameProcessed then return end
    if isAwaitingBindInput then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if currentBindTarget == "Hitbox" then
                _G.ToggleScriptKeyCode = input.KeyCode
                BindHitboxButton.Text = "Бинд хитбокса: " .. _G.ToggleScriptKeyCode.Name
            elseif currentBindTarget == "Speed" then
                _G.ToggleSpeedKeyCode = input.KeyCode
                BindSpeedButton.Text = "Бинд скорости: " .. _G.ToggleSpeedKeyCode.Name
            elseif currentBindTarget == "Jump" then
                _G.ToggleJumpKeyCode = input.KeyCode
                BindJumpButton.Text = "Бинд прыжка: " .. _G.ToggleJumpKeyCode.Name
            end
            isAwaitingBindInput = false
            currentBindTarget = nil
        end
        return
    end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == _G.ToggleGUIKeyCode then
            toggleGUIVisibility()
        elseif input.KeyCode == _G.ToggleScriptKeyCode then
            toggleHitboxState()
        elseif input.KeyCode == _G.ToggleSpeedKeyCode then
            toggleSpeedState()
        elseif input.KeyCode == _G.ToggleJumpKeyCode then
            toggleJumpState()
        end
    end
end

UserInputService.InputBegan:Connect(handleKeyBinds)

-- Отслеживание смерти Шерифа
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                if getPlayerRole(player) == "Sheriff" then
                    sheriffAlive = false
                    currentSheriff = nil
                end
            end)
        end
        player.CharacterAdded:Connect(function(character)
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.Died:Connect(function()
                    if getPlayerRole(player) == "Sheriff" then
                        sheriffAlive = false
                        currentSheriff = nil
                    end
                end)
            end
        end)
    end
end)

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if humanoid and getPlayerRole(player) == "Sheriff" then
            currentSheriff = player
            sheriffAlive = true
            humanoid.Died:Connect(function()
                sheriffAlive = false
                currentSheriff = nil
            end)
        end
        player.CharacterAdded:Connect(function(character)
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and getPlayerRole(player) == "Sheriff" then
                currentSheriff = player
                sheriffAlive = true
                humanoid.Died:Connect(function()
                    sheriffAlive = false
                    currentSheriff = nil
                end)
            end
        end)
    end
end
