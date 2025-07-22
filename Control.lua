-- ====================================================================================
-- УПРАВЛЕНИЕ: СКРИПТ (ИСПРАВЛЕНО ДЛЯ СОХРАНЕНИЯ ПОСЛЕ РЕСПАУНА И СИСТЕМОЙ БИНДОВ)
-- Type: LocalScript
-- Parent: StarterPlayer.StarterPlayerScripts
-- ====================================================================================

print("Управление: Скрипт запущен.")

-- Глобальные переменные для доступа извне (сохраняют состояние между респаунами)
-- Инициализируем значения, если они еще не установлены, иначе используем текущие.
_G.HitboxSize = _G.HitboxSize or 0 -- Оставлено 0, как запрошено. Помните: хитбоксы будут невидимы, если размер 0.
_G.Disabled = _G.Disabled or true -- Состояние хитбоксов
_G.HitboxColor = _G.HitboxColor or Color3.fromRGB(117, 7, 181) -- Установлен запрошенный цвет хитбоксов
_G.GUIVisible = _G.GUIVisible or true -- Изначально GUI видим

-- НОВЫЕ ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ДЛЯ СКОРОСТИ
_G.PlayerSpeed = _G.PlayerSpeed or 16 -- Начальная скорость игрока (по умолчанию стандартная скорость Roblox)
_G.SpeedEnabled = _G.SpeedEnabled or false -- Флаг включения/выключения изменения скорости
_G.OriginalWalkSpeed = nil -- Для сохранения оригинальной скорости игрока

-- Добавлены глобальные переменные для хранения биндов
_G.ToggleGUIKeyCode = _G.ToggleGUIKeyCode or Enum.KeyCode.Insert -- Бинд для видимости GUI
_G.ToggleScriptKeyCode = _G.ToggleScriptKeyCode or Enum.KeyCode.Backspace -- Бинд для включения/выключения скрипта (хитбоксов)
_G.ToggleSpeedKeyCode = _G.ToggleSpeedKeyCode or Enum.KeyCode.V -- Бинд для переключения режима скорости (по умолчанию V)

-- Сервисы
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Ждем загрузки локального игрока и его PlayerGui
print("Управление: Ожидание LocalPlayer и PlayerGui...")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
print("Управление: LocalPlayer и PlayerGui найдены.")

-- Названия элементов GUI для поиска или создания
local GUI_NAME = "ControlGUI" -- Обновленное название для ScreenGui
local MAIN_FRAME_NAME = "MainFrame"
local TITLE_LABEL_NAME = "TitleLabel"
local SLIDER_FRAME_NAME = "HitboxSliderFrame" -- Переименовал для ясности
local HITBOX_SIZE_LABEL_NAME = "HitboxSizeLabel"
local TOGGLE_BUTTON_NAME = "ToggleHitboxButton" -- Переименовал для ясности
local CLOSE_BUTTON_NAME = "CloseButton"
local TOGGLE_VISIBILITY_BUTTON_NAME = "ToggleVisibilityButton"
local BIND_HITBOX_BUTTON_NAME = "BindHitboxButton"

-- НОВЫЕ НАЗВАНИЯ ДЛЯ ЭЛЕМЕНТОВ СКОРОСТИ
local SPEED_SLIDER_FRAME_NAME = "SpeedSliderFrame"
local PLAYER_SPEED_LABEL_NAME = "PlayerSpeedLabel"
local TOGGLE_SPEED_BUTTON_NAME = "ToggleSpeedButton"
local BIND_SPEED_BUTTON_NAME = "BindSpeedButton"

local ScreenGui, MainFrame, TitleLabel, HitboxSliderFrame, HitboxSliderKnob, HitboxSizeLabel, ToggleHitboxButton, CloseButton, ToggleVisibilityButton, BindHitboxButton
local SpeedSliderFrame, SpeedSliderKnob, PlayerSpeedLabel, ToggleSpeedButton, BindSpeedButton

-- Флаг для режима назначения бинда (общий для всех биндов)
local isAwaitingBindInput = false
local currentBindTarget = nil -- Отслеживает, для какой кнопки сейчас назначается бинд

-- Функция для создания и настройки нового элемента GUI
local function createGuiElement(instanceType, properties, parent)
    local element = Instance.new(instanceType)
    for prop, value in pairs(properties) do
        element[prop] = value
    end
    element.Parent = parent
    return element
end

-- Список элементов, которые нужно скрывать/показывать при сворачивании
local controllableElements = {}

-- ====================================================================================
-- ИНИЦИАЛИЗАЦИЯ GUI (СОЗДАНИЕ ИЛИ ПОИСК СУЩЕСТВУЮЩЕГО)
-- ====================================================================================

-- 1. ScreenGui: Проверяем, существует ли уже GUI.
ScreenGui = PlayerGui:FindFirstChild(GUI_NAME)
if not ScreenGui then
    print("Управление: ScreenGui не найден, создаю новый.")
    ScreenGui = createGuiElement("ScreenGui", {
        Name = GUI_NAME,
        ResetOnSpawn = false,
        Enabled = _G.GUIVisible,
        DisplayOrder = 999
    }, PlayerGui)
else
    print("Управление: Найден существующий ScreenGui:", GUI_NAME)
    ScreenGui.Enabled = _G.GUIVisible
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 999
end

-- 2. MainFrame
MainFrame = ScreenGui:FindFirstChild(MAIN_FRAME_NAME)
if not MainFrame then
    print("Управление: MainFrame не найден, создаю новый.")
    MainFrame = createGuiElement("Frame", {
        Name = MAIN_FRAME_NAME,
        Size = UDim2.new(0, 250, 0, 300), -- Увеличен размер для новых элементов
        Position = UDim2.new(0.5, -125, 0.5, -150), -- Скорректирована позиция
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0,
        BorderColor3 = Color3.fromRGB(20, 20, 20),
        Visible = true,
        ZIndex = 1
    }, ScreenGui) -- Parent is ScreenGui
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 8) }, MainFrame)
else
    print("Управление: Найден существующий MainFrame.")
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0, 250, 0, 300) -- Обновить размер, если уже существует
    MainFrame.Position = UDim2.new(0.5, -125, 0.5, -150)
end

-- 3. TitleLabel
TitleLabel = MainFrame:FindFirstChild(TITLE_LABEL_NAME)
if not TitleLabel then
    print("Управление: TitleLabel не найден, создаю новый.")
    TitleLabel = createGuiElement("TextLabel", {
        Name = TITLE_LABEL_NAME,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Управление", -- Обновлен текст заголовка
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 18,
        BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 8) }, TitleLabel)
else
    print("Управление: Найден существующий TitleLabel.")
    TitleLabel.Text = "Управление"
end

-- 4. CloseButton
CloseButton = TitleLabel:FindFirstChild(CLOSE_BUTTON_NAME)
if not CloseButton then
    print("Управление: CloseButton не найден, создаю новый.")
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
else
    print("Управление: Найден существующий CloseButton.")
end

-- 5. ToggleVisibilityButton (сворачивание/разворачивание)
ToggleVisibilityButton = TitleLabel:FindFirstChild(TOGGLE_VISIBILITY_BUTTON_NAME)
if not ToggleVisibilityButton then
    print("Управление: ToggleVisibilityButton не найден, создаю новый.")
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
else
    print("Управление: Найден существующий ToggleVisibilityButton.")
end

local originalFrameSize = MainFrame.Size -- Обновить originalFrameSize после изменения MainFrame.Size
local isCollapsed = false

-- Функция для сворачивания/разворачивания GUI
local function toggleGUICollapse()
    isCollapsed = not isCollapsed
    local tweenDuration = 0.5 -- Увеличена продолжительность анимации для плавности
    local tweenEasingStyle = Enum.EasingStyle.Quad
    local tweenEasingDirection = Enum.EasingDirection.Out

    if isCollapsed then
        -- При сворачивании: сразу скрываем элементы
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
        -- При разворачивании: скрываем элементы, запускаем анимацию, затем показываем по завершении
        for _, element in ipairs(controllableElements) do
            element.Visible = false
        end
        local tween = TweenService:Create(MainFrame, TweenInfo.new(tweenDuration, tweenEasingStyle, tweenEasingDirection), {
            Size = originalFrameSize
        })
        tween:Play()
        tween.Completed:Wait() -- Ждем завершения анимации
        for _, element in ipairs(controllableElements) do
            element.Visible = true
        end
        ToggleVisibilityButton.Text = "-"
        if TitleLabel:FindFirstChildOfClass("UICorner") then
            TitleLabel:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 8)
        end
    end
end

-- Подключаем обработчик только один раз
if not ToggleVisibilityButton:GetAttribute("Connected") then
    ToggleVisibilityButton:SetAttribute("Connected", true)
    ToggleVisibilityButton.MouseButton1Click:Connect(toggleGUICollapse)
end

-- Логика перетаскивания (TitleLabel)
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

-- 6. HitboxSliderFrame для размера хитбокса
HitboxSliderFrame = MainFrame:FindFirstChild(SLIDER_FRAME_NAME)
if not HitboxSliderFrame then
    print("Управление: HitboxSliderFrame не найден, создаю новый.")
    HitboxSliderFrame = createGuiElement("Frame", {
        Name = SLIDER_FRAME_NAME,
        Size = UDim2.new(0.8, 0, 0, 10),
        Position = UDim2.new(0.1, 0, 0, 45),
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        BorderSizePixel = 0,
        BorderColor3 = Color3.fromRGB(30, 30, 30)
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, HitboxSliderFrame)
else
    print("Управление: Найден существующий HitboxSliderFrame.")
end
table.clear(controllableElements) -- Очистка перед заполнением, чтобы избежать дублирования
table.insert(controllableElements, HitboxSliderFrame)

HitboxSliderKnob = HitboxSliderFrame:FindFirstChild("SliderKnob")
if not HitboxSliderKnob then
    print("Управление: HitboxSliderKnob не найден, создаю новый.")
    HitboxSliderKnob = createGuiElement("TextButton", {
        Name = "SliderKnob",
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(100, 100, 100),
        BorderSizePixel = 0,
        BorderColor3 = Color3.fromRGB(50, 50, 50),
        Text = ""
    }, HitboxSliderFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }, HitboxSliderKnob)
else
    print("Управление: Найден существующий HitboxSliderKnob.")
end

-- 7. HitboxSizeLabel
HitboxSizeLabel = MainFrame:FindFirstChild(HITBOX_SIZE_LABEL_NAME)
if not HitboxSizeLabel then
    print("Управление: HitboxSizeLabel не найден, создаю новый.")
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
else
    print("Управление: Найден существующий HitboxSizeLabel.")
end
table.insert(controllableElements, HitboxSizeLabel)

local isHitboxSliderDragging = false
local hitboxSliderMin = 0
local hitboxSliderMax = 20

-- Функция для обновления позиции ползунка на основе _G.HitboxSize
local function updateHitboxSliderKnobPosition()
    local sliderMovableWidth = HitboxSliderFrame.AbsoluteSize.X - HitboxSliderKnob.AbsoluteSize.X
    if sliderMovableWidth <= 0 or hitboxSliderMax == hitboxSliderMin then return end
    local ratio = (_G.HitboxSize - hitboxSliderMin) / (hitboxSliderMax - hitboxSliderMin)
    local clampedRelativeX = math.clamp(ratio * sliderMovableWidth, 0, sliderMovableWidth)
    HitboxSliderKnob.Position = UDim2.new(0, clampedRelativeX, 0, 0)
    HitboxSizeLabel.Text = "Размер хитбокса: " .. _G.HitboxSize
end

-- Изначальное позиционирование ползунка
task.defer(function()
    updateHitboxSliderKnobPosition()
end)

-- Подключаем обработчик только один раз
if not HitboxSliderKnob:GetAttribute("Connected") then
    HitboxSliderKnob:SetAttribute("Connected", true)
    HitboxSliderKnob.MouseButton1Down:Connect(function()
        isHitboxSliderDragging = true

        local sliderMovedConnection
        local sliderEndedConnection

        sliderMovedConnection = UserInputService.InputChanged:Connect(function(input)
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

        sliderEndedConnection = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isHitboxSliderDragging = false
                sliderMovedConnection:Disconnect()
                sliderEndedConnection:Disconnect()
            end
        end)
    end)
end

-- 8. Bind Hitbox Button (для бинда хитбоксов)
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
else
    print("Управление: Найден существующий BindHitboxButton.")
    BindHitboxButton.Text = "Бинд хитбокса: " .. _G.ToggleScriptKeyCode.Name
end
table.insert(controllableElements, BindHitboxButton)

-- 9. ToggleButton (для включения/выключения скрипта хитбоксов)
ToggleHitboxButton = MainFrame:FindFirstChild(TOGGLE_BUTTON_NAME)
if not ToggleHitboxButton then
    print("Управление: ToggleHitboxButton не найден, создаю новый.")
    ToggleHitboxButton = createGuiElement("TextButton", {
        Name = TOGGLE_BUTTON_NAME,
        Size = UDim2.new(0.8, 0, 0, 30),
        Position = UDim2.new(0.1, 0, 0, 135),
        Text = "Хитбоксы: Отключены",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 16
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, ToggleHitboxButton)
else
    print("Управление: Найден существующий ToggleHitboxButton.")
end
table.insert(controllableElements, ToggleHitboxButton)

-- ====================================================================================
-- НОВЫЕ ЭЛЕМЕНТЫ GUI ДЛЯ СКОРОСТИ
-- ====================================================================================

-- 10. SpeedSliderFrame
SpeedSliderFrame = MainFrame:FindFirstChild(SPEED_SLIDER_FRAME_NAME)
if not SpeedSliderFrame then
    print("Управление: SpeedSliderFrame не найден, создаю новый.")
    SpeedSliderFrame = createGuiElement("Frame", {
        Name = SPEED_SLIDER_FRAME_NAME,
        Size = UDim2.new(0.8, 0, 0, 10),
        Position = UDim2.new(0.1, 0, 0, 185), -- Позиция ниже хитбоксов
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        BorderSizePixel = 0,
        BorderColor3 = Color3.fromRGB(30, 30, 30)
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, SpeedSliderFrame)
else
    print("Управление: Найден существующий SpeedSliderFrame.")
end
table.insert(controllableElements, SpeedSliderFrame)

SpeedSliderKnob = SpeedSliderFrame:FindFirstChild("SpeedSliderKnob")
if not SpeedSliderKnob then
    print("Управление: SpeedSliderKnob не найден, создаю новый.")
    SpeedSliderKnob = createGuiElement("TextButton", {
        Name = "SpeedSliderKnob",
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(100, 100, 100),
        BorderSizePixel = 0,
        BorderColor3 = Color3.fromRGB(50, 50, 50),
        Text = ""
    }, SpeedSliderFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }, SpeedSliderKnob)
else
    print("Управление: Найден существующий SpeedSliderKnob.")
end

-- 11. PlayerSpeedLabel
PlayerSpeedLabel = MainFrame:FindFirstChild(PLAYER_SPEED_LABEL_NAME)
if not PlayerSpeedLabel then
    print("Управление: PlayerSpeedLabel не найден, создаю новый.")
    PlayerSpeedLabel = createGuiElement("TextLabel", {
        Name = PLAYER_SPEED_LABEL_NAME,
        Size = UDim2.new(0.8, 0, 0, 20),
        Position = UDim2.new(0.1, 0, 0, 200), -- Позиция ниже слайдера скорости
        Text = "Скорость: " .. _G.PlayerSpeed, -- Изменено на "Скорость"
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSans,
        TextSize = 14,
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BackgroundTransparency = 1
    }, MainFrame)
else
    print("Управление: Найден существующий PlayerSpeedLabel.")
    PlayerSpeedLabel.Text = "Скорость: " .. _G.PlayerSpeed
end
table.insert(controllableElements, PlayerSpeedLabel)

local isSpeedSliderDragging = false
local speedSliderMin = 16 -- Стандартная скорость Roblox
local speedSliderMax = 100 -- Максимальная скорость

-- Функция для обновления позиции ползунка скорости на основе _G.PlayerSpeed
local function updateSpeedSliderKnobPosition()
    local sliderMovableWidth = SpeedSliderFrame.AbsoluteSize.X - SpeedSliderKnob.AbsoluteSize.X
    if sliderMovableWidth <= 0 or speedSliderMax == speedSliderMin then return end
    local ratio = (_G.PlayerSpeed - speedSliderMin) / (speedSliderMax - speedSliderMin)
    local clampedRelativeX = math.clamp(ratio * sliderMovableWidth, 0, sliderMovableWidth)
    SpeedSliderKnob.Position = UDim2.new(0, clampedRelativeX, 0, 0)
    PlayerSpeedLabel.Text = "Скорость: " .. _G.PlayerSpeed
end

-- Изначальное позиционирование ползунка скорости
task.defer(function()
    updateSpeedSliderKnobPosition()
end)

-- Подключаем обработчик ползунка скорости
if not SpeedSliderKnob:GetAttribute("Connected") then
    SpeedSliderKnob:SetAttribute("Connected", true)
    SpeedSliderKnob.MouseButton1Down:Connect(function()
        isSpeedSliderDragging = true

        local sliderMovedConnection
        local sliderEndedConnection

        sliderMovedConnection = UserInputService.InputChanged:Connect(function(input)
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
                -- Обновляем скорость игрока сразу при перетаскивании ползунка, если режим скорости включен
                if _G.SpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    LocalPlayer.Character.Humanoid.WalkSpeed = _G.PlayerSpeed
                end
            end
        end)

        sliderEndedConnection = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isSpeedSliderDragging = false
                sliderMovedConnection:Disconnect()
                sliderEndedConnection:Disconnect()
            end
        end)
    end)
end

-- 12. Bind Speed Button (для бинда скорости игрока)
BindSpeedButton = MainFrame:FindFirstChild(BIND_SPEED_BUTTON_NAME)
if not BindSpeedButton then
    BindSpeedButton = createGuiElement("TextButton", {
        Name = BIND_SPEED_BUTTON_NAME,
        Size = UDim2.new(0.8, 0, 0, 30),
        Position = UDim2.new(0.1, 0, 0, 235), -- Позиция ниже лейбла скорости
        Text = "Бинд скорости: " .. _G.ToggleSpeedKeyCode.Name,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 16,
        BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, BindSpeedButton)
else
    print("Управление: Найден существующий BindSpeedButton.")
    BindSpeedButton.Text = "Бинд скорости: " .. _G.ToggleSpeedKeyCode.Name
end
table.insert(controllableElements, BindSpeedButton)

-- 13. Toggle Speed Button (для включения/выключения режима скорости)
ToggleSpeedButton = MainFrame:FindFirstChild(TOGGLE_SPEED_BUTTON_NAME)
if not ToggleSpeedButton then
    print("Управление: ToggleSpeedButton не найден, создаю новый.")
    ToggleSpeedButton = createGuiElement("TextButton", {
        Name = TOGGLE_SPEED_BUTTON_NAME,
        Size = UDim2.new(0.8, 0, 0, 30),
        Position = UDim2.new(0.1, 0, 0, 265), -- Позиция ниже Bind Speed Button
        Text = "Скорость: Отключена",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSansBold,
        TextSize = 16
    }, MainFrame)
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5) }, ToggleSpeedButton)
else
    print("Управление: Найден существующий ToggleSpeedButton.")
end
table.insert(controllableElements, ToggleSpeedButton)

-- ====================================================================================
-- ЛОГИКА СКРИПТА
-- ====================================================================================

-- Функции обновления текста и цвета кнопок
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


-- Функция для сброса хитбоксов всех игроков к их стандартному виду
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

-- Функция для применения скорости игрока
local function applyPlayerSpeed()
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if _G.OriginalWalkSpeed == nil then -- Сохраняем оригинальную скорость только один раз
            _G.OriginalWalkSpeed = humanoid.WalkSpeed
        end
        humanoid.WalkSpeed = _G.PlayerSpeed
        print("Управление: Скорость игрока установлена на: " .. _G.PlayerSpeed)
    end
end

-- Функция для сброса скорости игрока к оригинальной
local function resetPlayerSpeed()
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid and _G.OriginalWalkSpeed ~= nil then -- Сбрасываем только если оригинальная скорость была сохранена
        humanoid.WalkSpeed = _G.OriginalWalkSpeed
        print("Управление: Скорость игрока сброшена до оригинальной: " .. _G.OriginalWalkSpeed)
        _G.OriginalWalkSpeed = nil -- Сбросим, чтобы заново получить при следующем включении
    end
end

-- Основная логика управления хитбоксами через RenderStepped
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
                                -- Если _G.HitboxSize равно 0, используем минимальный видимый размер
                                local currentHitboxSize = (_G.HitboxSize == 0) and 0.1 or _G.HitboxSize
                                rootPart.Size = Vector3.new(currentHitboxSize, currentHitboxSize, currentHitboxSize)
                                rootPart.Material = Enum.Material.Plastic
                                rootPart.BrickColor = BrickColor.new(_G.HitboxColor)
                                rootPart.Transparency = 0.7
                                rootPart.CanCollide = false
                            end
                        end
                    end
                end
            end)
            print("Управление: RenderStepped подключен (хитбоксы).")
        end
    else
        if renderSteppedConnection then
            renderSteppedConnection:Disconnect()
            renderSteppedConnection = nil
            resetHitboxes()
            print("Управление: RenderStepped отключен, хитбоксы сброшены.")
        end
    end
end

-- Функция для переключения видимости GUI
local function toggleGUIVisibility()
    local wasVisible = _G.GUIVisible
    _G.GUIVisible = not _G.GUIVisible
    ScreenGui.Enabled = _G.GUIVisible
    
    if _G.GUIVisible then
        -- GUI стал видимым
        -- В этом блоке происходит автоматическое включение функций, которые вам не нужны
        -- *** ЭТИ СТРОКИ НУЖНО ЗАКОММЕНТИРОВАТЬ ИЛИ УДАЛИТЬ ***
        if not wasVisible then
            -- _G.Disabled = false -- Включаем хитбоксы по умолчанию
            -- _G.SpeedEnabled = true -- Включаем скорость по умолчанию
            -- _G.EspEnabled = false -- Оставляем ESP выключенным по умолчанию
        end
    else
        -- GUI стал невидимым, отключаем скрипты и сбрасываем состояние
        _G.Disabled = true
        _G.SpeedEnabled = false
        resetPlayerSpeed() -- Сбрасываем скорость, когда GUI скрыт
    end
    updateScriptConnection() -- Обновляем соединение скрипта хитбоксов
    updateToggleHitboxButton() -- Обновляем текст кнопки состояния хитбоксов
    updateToggleSpeedButton() -- Обновляем текст кнопки состояния скорости
    
    print("Управление: GUI переключен. Новое состояние: " .. tostring(_G.GUIVisible))
end

-- Функция для переключения состояния скрипта хитбоксов
local function toggleHitboxState()
    _G.Disabled = not _G.Disabled
    updateToggleHitboxButton()
    updateScriptConnection()
    print("Управление: Скрипт хитбоксов переключен. Новое состояние: " .. tostring(not _G.Disabled))
end

-- Функция для переключения состояния скорости
local function toggleSpeedState()
    _G.SpeedEnabled = not _G.SpeedEnabled
    updateToggleSpeedButton()
    if _G.SpeedEnabled then
        applyPlayerSpeed()
    else
        resetPlayerSpeed()
    end
    print("Управление: Режим скорости переключен. Новое состояние: " .. tostring(_G.SpeedEnabled))
end

-- Инициализация GUI и соединений при запуске
updateToggleHitboxButton()
updateToggleSpeedButton()
updateScriptConnection() -- Инициализируем соединение для хитбоксов
updateHitboxSliderKnobPosition()
updateSpeedSliderKnobPosition()
-- Здесь также можно добавить вызов updateESPConnection() и updateToggleESPButton(), если ESP уже добавлен в скрипт и вам нужно его инициализировать при запуске.

-- Соединение для события "CharacterAdded" для LocalPlayer
LocalPlayer.CharacterAdded:Connect(function(character)
    print("Управление: Персонаж добавлен.")
    -- Если скорость включена, применяем её при появлении персонажа
    if _G.SpeedEnabled then
        -- Небольшая задержка, чтобы Humanoid успел загрузиться
        task.wait(0.1)
        applyPlayerSpeed()
    else
        -- Если скорость выключена, убедимся, что она сброшена до оригинала
        resetPlayerSpeed()
    end
end)

-- Подключение кнопок управления (убедимся, что они привязаны только один раз)
if not ToggleHitboxButton:GetAttribute("Connected") then
    ToggleHitboxButton:SetAttribute("Connected", true)
    ToggleHitboxButton.MouseButton1Click:Connect(toggleHitboxState)
end

if not CloseButton:GetAttribute("Connected") then
    CloseButton:SetAttribute("Connected", true)
    CloseButton.MouseButton1Click:Connect(function()
        toggleGUIVisibility()
        print("Управление: Кнопка закрытия нажата, GUI отключен.")
    end)
end

-- Подключение Toggle Speed Button
if not ToggleSpeedButton:GetAttribute("Connected") then
    ToggleSpeedButton:SetAttribute("Connected", true)
    ToggleSpeedButton.MouseButton1Click:Connect(toggleSpeedState)
end

-- Логика для кнопки Bind Hitbox (назначение бинда для хитбоксов)
if not BindHitboxButton:GetAttribute("Connected") then
    BindHitboxButton:SetAttribute("Connected", true)
    BindHitboxButton.MouseButton1Click:Connect(function()
        if not isAwaitingBindInput then
            isAwaitingBindInput = true
            currentBindTarget = "Hitbox" -- Устанавливаем цель бинда
            BindHitboxButton.Text = "Нажмите кнопку..."
            -- Сбрасываем текст других кнопок, чтобы было понятно, какая кнопка ожидает ввода
            BindSpeedButton.Text = "Бинд скорости: " .. _G.ToggleSpeedKeyCode.Name
            print("Управление: Ожидание нажатия клавиши для бинда хитбоксов.")
        end
    end)
end

-- Подключение Bind Speed Button
if not BindSpeedButton:GetAttribute("Connected") then
    BindSpeedButton:SetAttribute("Connected", true)
    BindSpeedButton.MouseButton1Click:Connect(function()
        if not isAwaitingBindInput then
            isAwaitingBindInput = true
            currentBindTarget = "Speed" -- Устанавливаем цель бинда
            BindSpeedButton.Text = "Нажмите кнопку..."
            -- Сбрасываем текст других кнопок, чтобы было понятно, какая кнопка ожидает ввода
            BindHitboxButton.Text = "Бинд хитбокса: " .. _G.ToggleScriptKeyCode.Name
            print("Управление: Ожидание нажатия клавиши для бинда скорости.")
        end
    end)
end

-- Обработчик AncestryChanged для ScreenGui.
-- Поскольку ResetOnSpawn = false, скрипт не будет перезапускаться.
if not ScreenGui:GetAttribute("AncestryChangedConnected") then
    ScreenGui:SetAttribute("Connected", true)
    ScreenGui.AncestryChanged:Connect(function()
        if not ScreenGui.Parent then
            _G.Disabled = true
            _G.SpeedEnabled = false -- Отключаем скорость тоже
            updateScriptConnection()
            resetPlayerSpeed() -- Сбрасываем скорость при удалении GUI
            print("Управление: ScreenGui был удален из PlayerGui (внешне). Скрипт отключен.")
        end
    end)
end

-- ====================================================================================
-- СИСТЕМА БИНДОВ (ОБНОВЛЕННАЯ)
-- ====================================================================================

local function handleKeyBinds(input, gameProcessed)
    -- Если игра обработала ввод (например, игрок вводит текст в чате), игнорируем
    if gameProcessed then return end 

    if isAwaitingBindInput then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if currentBindTarget == "Hitbox" then
                _G.ToggleScriptKeyCode = input.KeyCode
                BindHitboxButton.Text = "Бинд хитбокса: " .. _G.ToggleScriptKeyCode.Name
            elseif currentBindTarget == "Speed" then
                _G.ToggleSpeedKeyCode = input.KeyCode
                BindSpeedButton.Text = "Бинд скорости: " .. _G.ToggleSpeedKeyCode.Name
            end
            isAwaitingBindInput = false
            currentBindTarget = nil -- Сбрасываем цель бинда после назначения
            print("Управление: Бинд успешно установлен.")
        end
        return -- Прекращаем обработку, пока ждем ввода для бинда
    end

    -- Обработка обычных биндов
    if input.UserInputType == Enum.UserInputType.Keyboard then
        -- Бинд для переключения видимости GUI
        if input.KeyCode == _G.ToggleGUIKeyCode then
            toggleGUIVisibility()
        end

        -- Бинд для переключения состояния скрипта (хитбоксов)
        if input.KeyCode == _G.ToggleScriptKeyCode then
            toggleHitboxState()
        end

        -- Бинд для переключения состояния скорости
        if input.KeyCode == _G.ToggleSpeedKeyCode then
            toggleSpeedState()
        end
    end
end

UserInputService.InputBegan:Connect(handleKeyBinds)

print("Управление: Все соединения и GUI элементы инициализированы.")
