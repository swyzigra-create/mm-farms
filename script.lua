-- Инициализация системных сервисов
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client = Players.LocalPlayer

-- Инициализация глобальных переменных
getgenv().Autofarm = getgenv().Autofarm or false
getgenv().AutofarmMethod = getgenv().AutofarmMethod or "XP"
getgenv().SheriffAim = getgenv().SheriffAim or false
getgenv().GunAccuracy = getgenv().GunAccuracy or 25

-- Локальная переменная для отслеживания уникального ID запущенного цикла Autofarm
local currentFarmSession = 0

-- Загрузка библиотеки Rayfield UI 
local Rayfield = loadstring(game:HttpGet('https://sirius.menu'))()


-- Создание главного окна
local Window = Rayfield:CreateWindow({
   Name = "GitHub Pro Hub | MM2 Edition",
   LoadingTitle = "Инициализация модулей...",
   LoadingSubtitle = "by GitHub Pro AI",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

-- Создание вкладок (Tabs)
local FarmTab = Window:CreateTab("Autofarm", nil)
local SheriffTab = Window:CreateTab("Sheriff Aim", nil)

-- Создание секций
local AutofarmSection = FarmTab:CreateSection("Настройки Фарма")
local SheriffSection = SheriffTab:CreateSection("Модификации Оружия")

-- ==================== СЕРВИСНЫЕ ФУНКЦИИ ДЛЯ SILENT AIM ====================

-- Поиск игрока с ролью Murderer (Убийца) по наличию ножа
local function getMurderer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Client and player.Character then
            -- Проверяем инвентарь или руки персонажа на наличие ножа
            if player.Backpack:FindFirstChild("Knife") or player.Character:FindFirstChild("Knife") then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    return player.Character
                end
            end
        end
    end
    -- Если явный убийца не найден, ищем ближайшего живого противника
    local closestEnemy = nil
    local shortestDistance = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Client and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local distance = (Client.Character and Client.Character:FindFirstChild("HumanoidRootPart")) and (root.Position - Client.Character.HumanoidRootPart.Position).Magnitude or 0
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestEnemy = player.Character
                end
            end
        end
    end
    return closestEnemy
end

-- Хук метатаблицы для реализации Silent Aim
-- Перехватывает выстрелы пистолета, направляя их точно в цель
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- Проверяем, что включен Silent Aim, и идет вызов стрельбы (обычно через ShootEvent или аналогичные ремуты)
    if getgenv().SheriffAim and (method == "FireServer" or method == "InvokeServer") then
        if self.Name == "ShootEvent" or (self.Parent and self.Parent.Name == "Gun" and string.find(self.Name, "Fire")) then
            local targetChar = getMurderer()
            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                -- Расчет шанса попадания (Accuracy)
                local chance = math.random(1, 100)
                if chance <= getgenv().GunAccuracy then
                    -- Направляем выстрел в HumanoidRootPart или Head
                    local targetPart = targetChar:FindFirstChild("HumanoidRootPart")
                    if targetPart then
                        -- В MM2 аргументом выстрела обычно является Vector3 позиция клика
                        -- Модифицируем первый аргумент на координаты цели
                        args[1] = targetPart.Position
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
        end
    end
    return oldNamecall(self, ...)
end)

-- ==================== СЕКЦИЯ AUTOFARM ====================

AutofarmSection:CreateToggle({
    Name = "Autofarm",
    CurrentValue = false,
    Flag = "Toggle_Autofarm",
    Callback = function(state)
        getgenv().Autofarm = state
        if not state then return end
        if not getgenv().AutofarmMethod then return end

        currentFarmSession = currentFarmSession + 1
        local mySession = currentFarmSession

        local function getRoot()
            local char = Client.Character
            return char and char:FindFirstChild("HumanoidRootPart")
        end

        if getgenv().AutofarmMethod == "Coins" then
            while getgenv().Autofarm and currentFarmSession == mySession do
                task.wait()
                local root = getRoot()
                local coinContainer = Workspace:FindFirstChild("CoinContainer", true)
                local mainGui = Client.PlayerGui:FindFirstChild("MainGUI")
                local cashBagVisible = mainGui and mainGui.Game.CashBag.Visible

                if root and coinContainer and cashBagVisible then
                    local coin = coinContainer:FindFirstChild("Coin_Server")
                    if coin then
                        repeat
                            if not getgenv().Autofarm or currentFarmSession ~= mySession then break end
                            if coin and coin.Parent then
                                root.CFrame = CFrame.new(coin.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(180))
                            end
                            RunService.Stepped:Wait()
                        until not coin:IsDescendantOf(Workspace) or coin.Name ~= "Coin_Server"
                        task.wait(1.8)
                    end
                else
                    task.wait(1.5)
                end
            end
        else
            -- Режим XP
            while getgenv().Autofarm and currentFarmSession == mySession do
                task.wait()
                local root = getRoot()
                local mainGui = Client.PlayerGui:FindFirstChild("MainGUI")
                
                if root and mainGui and mainGui.Game.CashBag.Visible then
                    root.CFrame = CFrame.new(-121.12338256836, 138.27394104004, 38.946128845215)
                end
            end
        end
    end
})

AutofarmSection:CreateDropdown({
    Name = "Autofarm method",
    Options = {"XP", "Coins"},
    CurrentOption = {"XP"},
    MultipleOptions = false,
    Flag = "Dropdown_Method",
    Callback = function(Option)
        local val = type(Option) == "table" and Option[1] or Option
        getgenv().AutofarmMethod = val
    end,
})

-- ==================== СЕКЦИЯ SHERIFF AIM ====================

SheriffSection:CreateToggle({
    Name = "Silent aim",
    CurrentValue = false,
    Flag = "Toggle_SilentAim",
    Callback = function(state)
        getgenv().SheriffAim = state
    end
})

SheriffSection:CreateSlider({
    Name = "Accuracy",
    Min = 0,
    Max = 100,
    CurrentValue = 25,
    Increment = 1,
    ValueName = "%",
    Flag = "Slider_Accuracy",
    Callback = function(val)
        getgenv().GunAccuracy = tonumber(val) or 25
    end
})

-- Уведомление
Rayfield:Notify({
   Title = "GitHub Pro AI",
   Content = "Silent Aim успешно интегрирован в ядро Namecall!",
   Duration = 4,
   Image = 4483362458,
})
