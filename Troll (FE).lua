-- ===================================== -- FULL PLUGIN TAB (TROLL FE + BACKSHOTS + RC CAR + SIT) -- ===================================== 
if not odh_shared_plugins then
    warn("ODH Shared Plugins environment not found! Load the main hub first.")
    return
end

local pluginTab = odh_shared_plugins.AddSection("Troll (FE)") 

local Players = game:GetService("Players") 
local LocalPlayer = Players.LocalPlayer 
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- ===================================== -- GUI SETUP (DUAL KNIFE) -- ===================================== 
local playerGui = LocalPlayer:WaitForChild("PlayerGui") 

local function createKnifeGui(name, imageId) 
    local screenGui = Instance.new("ScreenGui") 
    screenGui.Name = name .. "GUI" 
    screenGui.ResetOnSpawn = false 
    screenGui.Parent = playerGui 
    screenGui.Enabled = false 

    local buttonSize = 100 
    local imageButton = Instance.new("ImageButton") 
    imageButton.Size = UDim2.new(0, buttonSize, 0, buttonSize) 
    imageButton.Position = UDim2.new(0.5, -buttonSize/2, 0.5, -buttonSize/2) 
    imageButton.Image = imageId 
    imageButton.BackgroundTransparency = 0.8 
    imageButton.Active = true 
    imageButton.Draggable = true 
    imageButton.Parent = screenGui 

    return screenGui, imageButton 
end 

local function playDualKnifeAnimation(char) 
    if not char then return end 
    local humanoid = char:FindFirstChildOfClass("Humanoid") 
    if humanoid then 
        local anim1 = Instance.new("Animation") 
        anim1.AnimationId = "rbxassetid://2467577524" 
        local track1 = humanoid:LoadAnimation(anim1) 
        track1:Play() 
        task.delay(1, function() 
            local anim2 = Instance.new("Animation") 
            anim2.AnimationId = "rbxassetid://2470501967" 
            local track2 = humanoid:LoadAnimation(anim2) 
            track2:Play() 
        end) 
    end 
end 

local fakeDualGui, fakeDualButton = createKnifeGui("FakeDualKnife", "rbxassetid://131282777381667") 

pluginTab:AddToggle("Fake Dual Slash", function(on) 
    fakeDualGui.Enabled = on 
end) 

pluginTab:AddLabel("Works always... even in the lobby 😈") 

pluginTab:AddSlider("Fake Dual Slash Size", 50, 200, 100, function(v) 
    fakeDualButton.Size = UDim2.new(0, v, 0, v) 
    fakeDualButton.Position = UDim2.new(0.5, -v/2, 0.5, -v/2) 
end) 

fakeDualButton.MouseButton1Click:Connect(function() 
    playDualKnifeAnimation(LocalPlayer.Character) 
end) 

fakeDualButton.TouchTap:Connect(function() 
    playDualKnifeAnimation(LocalPlayer.Character) 
end)

-- ===================================== -- BACKSHOTS FEATURE -- ===================================== 
local backshotsGui = Instance.new("ScreenGui")
backshotsGui.Name = "ToggleMovementGui"
backshotsGui.ResetOnSpawn = false
pcall(function()
    backshotsGui.Parent = CoreGui
end)
if not backshotsGui.Parent then
    backshotsGui.Parent = playerGui
end
backshotsGui.Enabled = false

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "backshots"
toggleBtn.Size = UDim2.new(0, 120, 0, 50)
toggleBtn.Position = UDim2.new(0.1, 0, 0.1, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.Text = "backshots: OFF"
toggleBtn.Parent = backshotsGui

-- Draggable Logic
local dragging, dragInput, dragStart, startPos
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = toggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

toggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        toggleBtn.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

local function setNoPlayerCollision(enabled)
    local character = LocalPlayer.Character
    if not character then return end
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= LocalPlayer and otherPlayer.Character then
            for _, part in ipairs(otherPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = not enabled
                end
            end
        end
    end
end

local active = false
local connection = nil
local centerPos = nil
local walkDir = 1
local landDelayTick = 0
local wasInAir = false

local movementSpeed = 0.25
local maxDistance = 0.1

local function toggleBackshots(state)
    active = state
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if active then
        toggleBtn.Text = "backshots: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)

        if rootPart and humanoid then
            centerPos = rootPart.Position
            walkDir = 1
            humanoid.AutoRotate = false
            landDelayTick = 0
            wasInAir = false

            connection = RunService.RenderStepped:Connect(function()
                if not character or not character.Parent or humanoid.Health <= 0 then
                    return
                end

                setNoPlayerCollision(true)

                local lookVector = Camera.CFrame.LookVector
                local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
                if flatLook.Magnitude > 0 then
                    flatLook = flatLook.Unit
                else
                    flatLook = rootPart.CFrame.LookVector
                    flatLook = Vector3.new(flatLook.X, 0, flatLook.Z).Unit
                end

                local state = humanoid:GetState()
                local inAir = (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.FallingDown)

                if inAir then
                    wasInAir = true
                    centerPos = rootPart.Position
                    walkDir = 1
                    landDelayTick = tick() + 0.1
                elseif wasInAir and not inAir then
                    wasInAir = false
                end

                if humanoid.MoveDirection.Magnitude > 0 then
                    centerPos = rootPart.Position
                    walkDir = 1
                end

                if tick() < landDelayTick then
                    centerPos = rootPart.Position
                    return
                end

                local lockedLookCFrame = CFrame.lookAt(centerPos, centerPos + flatLook)
                local currentPos = rootPart.Position
                local displacement = (currentPos - centerPos):Dot(flatLook)

                if displacement >= maxDistance then
                    walkDir = -1
                elseif displacement <= -maxDistance then
                    walkDir = 1
                end

                local targetPosition = lockedLookCFrame.Position + (centerPos - lockedLookCFrame.Position) + (flatLook * displacement)

                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.FilterDescendantsInstances = {character}
                
                local raycastResult = workspace:Raycast(centerPos + Vector3.new(0, 2, 0), (targetPosition - centerPos), raycastParams)
                if raycastResult then
                    targetPosition = raycastResult.Position - (flatLook * 0.2)
                end

                local goalCFrame = lockedLookCFrame + (targetPosition - centerPos)
                rootPart.CFrame = rootPart.CFrame:Lerp(goalCFrame, movementSpeed)
                
                humanoid:Move(flatLook * walkDir, false)
            end)
        end
    else
        toggleBtn.Text = "backshots: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

        if connection then
            connection:Disconnect()
            connection = nil
        end

        setNoPlayerCollision(false)

        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.AutoRotate = true
                humanoid:Move(Vector3.zero, true)
            end
        end
        centerPos = nil
    end
end

toggleBtn.MouseButton1Click:Connect(function()
    toggleBackshots(not active)
end)

pluginTab:AddToggle("Show Backshots Button", function(on)
    backshotsGui.Enabled = on
    if not on and active then
        toggleBackshots(false)
    end
end)

pluginTab:AddKeybind("Backshots Keybind", "B", function()
    if backshotsGui.Enabled then
        toggleBackshots(not active)
    end
end)

pluginTab:AddSlider("Backshots Speed", 1, 100, 25, function(v)
    movementSpeed = v / 100
end)

pluginTab:AddSlider("Backshots Distance", 1, 50, 10, function(v)
    maxDistance = v / 100
end)

pluginTab:AddSlider("Backshots GUI Size", 50, 250, 120, function(v)
    toggleBtn.Size = UDim2.new(0, v, 0, math.floor(v * (50/120)))
    toggleBtn.TextSize = math.clamp(math.floor(v / 8), 10, 24)
end)

-- ===================================== -- DELTA RC CAR INTEGRATION -- ===================================== --
local rcEnabled = false
local dashcamEnabled = false
local customSpeedEnabled = false
local customSoundsEnabled = false
local speedometerEnabled = false
local sitOnCarEnabled = false
local maxSpeedVal = 80
local horsePowerVal = 500

local rcConnection = nil
local lastPosition = nil
local lastVelCalcTime = tick()
local wasTrackingCar = false
local trackedCarInstance = nil
local toolActivationConn = nil

-- Compact Draggable Minimal Speedometer ("0 km/h")
local speedGui = Instance.new("ScreenGui")
speedGui.Name = "RCCarSpeedometerCompact"
speedGui.ResetOnSpawn = false
pcall(function() speedGui.Parent = CoreGui end)
if not speedGui.Parent then speedGui.Parent = playerGui end
speedGui.Enabled = false

local speedValueLabel = Instance.new("TextLabel")
speedValueLabel.Size = UDim2.new(0, 110, 0, 36)
speedValueLabel.Position = UDim2.new(0.5, -55, 0.75, 0)
speedValueLabel.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
speedValueLabel.BackgroundTransparency = 0.25
speedValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedValueLabel.TextSize = 16
speedValueLabel.Font = Enum.Font.GothamBold
speedValueLabel.Text = "0 km/h"
speedValueLabel.Active = true
speedValueLabel.Draggable = true
speedValueLabel.Parent = speedGui

local labelCorner = Instance.new("UICorner")
labelCorner.CornerRadius = UDim.new(0, 10)
labelCorner.Parent = speedValueLabel

local labelStroke = Instance.new("UIStroke")
labelStroke.Color = Color3.fromRGB(0, 242, 254)
labelStroke.Transparency = 0.4
labelStroke.Thickness = 1.2
labelStroke.Parent = speedValueLabel

local idleSound = Instance.new("Sound")
idleSound.SoundId = "rbxassetid://98076378627817"
idleSound.Looped = true
idleSound.Volume = 0

local drivingSound = Instance.new("Sound")
drivingSound.SoundId = "rbxassetid://140713709172971"
drivingSound.Looped = true
drivingSound.Volume = 0

pcall(function()
    idleSound.Parent = CoreGui
    drivingSound.Parent = CoreGui
end)
if not idleSound.Parent then
    idleSound.Parent = playerGui
    drivingSound.Parent = playerGui
end

pcall(function()
    idleSound:Play()
    drivingSound:Play()
end)

local function resetCameraToPlayer()
    Camera.CameraType = Enum.CameraType.Custom
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        Camera.CameraSubject = hum
    end
end

local function setCharacterFrozen(isFrozen)
    if sitOnCarEnabled then
        local char = LocalPlayer.Character
        if char then
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            if rootPart and rootPart:IsA("BasePart") then rootPart.Anchored = false end
        end
        return
    end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = isFrozen end
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if rootPart and rootPart:IsA("BasePart") then rootPart.Anchored = isFrozen end
    end
end

local function getSpawnTool()
    local char = LocalPlayer.Character
    if char then
        local t = char:FindFirstChild("RCCar26")
        if t and t:IsA("Tool") then return t end
    end
    local userFolder = workspace:FindFirstChild(LocalPlayer.Name)
    if userFolder then
        local fTool = userFolder:FindFirstChild("RCCar26")
        if fTool and fTool:IsA("Tool") then return fTool end
    end
    return nil
end

local function isOwnedCar(carModel)
    if not carModel or not carModel:IsA("Model") or not carModel.Parent then return false end
    return carModel.Name == LocalPlayer.Name 
        or (carModel:FindFirstChild("Owner") and carModel.Owner.Value == LocalPlayer)
        or (carModel:GetAttribute("Owner") == LocalPlayer.UserId)
        or (carModel.Name == "RCCar" and getSpawnTool() ~= nil)
end

local function findMatchingCarInstance()
    local carsFolder = workspace:FindFirstChild("RCCars")
    if carsFolder then
        for _, car in ipairs(carsFolder:GetChildren()) do
            if car:IsA("Model") and isOwnedCar(car) then
                return car
            end
        end
    end
    return nil
end

local function setupToolTracking()
    if toolActivationConn then toolActivationConn:Disconnect() end
    local tool = getSpawnTool()
    if tool then
        toolActivationConn = tool.Activated:Connect(function()
            task.wait(0.05)
            local target = findMatchingCarInstance()
            if target then
                trackedCarInstance = target
            end
        end)
    end
end

local function updateRCState()
    if rcEnabled then
        lastPosition = nil
        wasTrackingCar = false
        trackedCarInstance = nil
        setupToolTracking()

        if rcConnection then rcConnection:Disconnect() end
        rcConnection = RunService.RenderStepped:Connect(function()
            if not rcEnabled then return end
            
            if trackedCarInstance and (not trackedCarInstance.Parent or not isOwnedCar(trackedCarInstance)) then
                trackedCarInstance = nil
            end

            if not trackedCarInstance and getSpawnTool() then
                trackedCarInstance = findMatchingCarInstance()
            end

            local targetCar = trackedCarInstance

            if targetCar and targetCar.Parent and isOwnedCar(targetCar) then
                wasTrackingCar = true
                setCharacterFrozen(true)
                local targetPart = targetCar.PrimaryPart or targetCar:FindFirstChildWhichIsA("BasePart")
                local currentSpeedStuds = 0

                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local rootPart = char and char:FindFirstChild("HumanoidRootPart")

                if sitOnCarEnabled and hum and rootPart and targetPart then
                    hum.PlatformStand = false
                    rootPart.Anchored = false
                    hum.Sit = true
                    -- Tighter low sit hover offset (0.85 studs above car part)
                    rootPart.CFrame = targetPart.CFrame * CFrame.new(0, 2, 0)
                end

                if targetPart and not targetPart.Anchored then
                    local currentPos = targetPart.Position
                    local measuredVelMag = targetPart.AssemblyLinearVelocity.Magnitude

                    if lastPosition then
                        local deltaT = math.clamp(tick() - lastVelCalcTime, 0.001, 0.1)
                        local dist = (currentPos - lastPosition).Magnitude
                        local rawVelMag = dist / deltaT

                        if dist > 0.02 then
                            local moveDir = (currentPos - lastPosition).Unit
                            local filterList = {targetCar, LocalPlayer.Character}
                            local result
                            while true do
                                local rayParams = RaycastParams.new()
                                rayParams.FilterDescendantsInstances = filterList
                                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                local tempRes = workspace:Raycast(currentPos, moveDir * 3, rayParams)
                                if tempRes and tempRes.Instance and not tempRes.Instance.CanCollide then
                                    table.insert(filterList, tempRes.Instance)
                                else
                                    result = tempRes
                                    break
                                end
                            end

                            if not result then
                                if customSpeedEnabled then
                                    local hpMultiplier = math.clamp(horsePowerVal / 500, 0.2, 2.0)
                                    local targetVelMag = math.min(rawVelMag * hpMultiplier, maxSpeedVal)
                                    targetPart.AssemblyLinearVelocity = moveDir * targetVelMag
                                    currentSpeedStuds = math.floor(targetVelMag + 0.5)
                                else
                                    currentSpeedStuds = math.floor(math.max(measuredVelMag, rawVelMag) + 0.5)
                                end
                            else
                                currentSpeedStuds = math.floor(math.max(measuredVelMag, math.min(rawVelMag, targetPart.AssemblyLinearVelocity.Magnitude)) + 0.5)
                            end
                        else
                            currentSpeedStuds = math.floor(measuredVelMag + 0.5)
                        end
                    else
                        currentSpeedStuds = math.floor(measuredVelMag + 0.5)
                    end
                    lastPosition = currentPos
                    lastVelCalcTime = tick()

                    speedGui.Enabled = speedometerEnabled
                    local kmhVal = math.floor(currentSpeedStuds * 1.60934 + 0.5)
                    speedValueLabel.Text = string.format("%d km/h", kmhVal)

                    local alpha = math.clamp(currentSpeedStuds / math.max(maxSpeedVal, 10), 0, 1)
                    if alpha > 0.88 then
                        labelStroke.Color = Color3.fromRGB(255, 45, 85)
                    else
                        labelStroke.Color = Color3.fromRGB(0, 242, 254)
                    end

                    if customSoundsEnabled then
                        if currentSpeedStuds > 0.8 then
                            idleSound.Volume = 0
                            drivingSound.Volume = math.clamp(currentSpeedStuds / 25, 0.25, 1.0)
                            local drivingSpeedVal = math.clamp(0.6 + (currentSpeedStuds / math.max(maxSpeedVal, 10)) * 1.4, 0.6, 2.2)
                            pcall(function() drivingSound.PlaybackSpeed = drivingSpeedVal end)
                        else
                            idleSound.Volume = 0.5
                            drivingSound.Volume = 0
                        end
                    else
                        idleSound.Volume = 0
                        drivingSound.Volume = 0
                    end

                    if dashcamEnabled then
                        Camera.CameraType = Enum.CameraType.Scriptable
                        Camera.CFrame = targetPart.CFrame * CFrame.new(0, 0.9, -0.4)
                    else
                        Camera.CameraType = Enum.CameraType.Custom
                        local humObj = targetCar:FindFirstChildOfClass("Humanoid")
                        Camera.CameraSubject = humObj or targetCar
                    end
                end
            else
                if wasTrackingCar then
                    wasTrackingCar = false
                    resetCameraToPlayer()
                end
                speedGui.Enabled = false
                idleSound.Volume = 0
                drivingSound.Volume = 0
                lastPosition = nil
                setCharacterFrozen(false)
            end
        end)
    else
        speedGui.Enabled = false
        idleSound.Volume = 0
        drivingSound.Volume = 0
        if rcConnection then
            rcConnection:Disconnect()
            rcConnection = nil
        end
        if toolActivationConn then
            toolActivationConn:Disconnect()
            toolActivationConn = nil
        end
        lastPosition = nil
        wasTrackingCar = false
        trackedCarInstance = nil
        setCharacterFrozen(false)
        resetCameraToPlayer()
    end
end

pluginTab:AddToggle("Spectate RCCar", function(on)
    rcEnabled = on
    updateRCState()
end)

pluginTab:AddToggle("Sit on RCCar", function(on)
    sitOnCarEnabled = on
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if not on then
        if hum then hum.Sit = false end
    else
        if hum then hum.PlatformStand = false end
        if rootPart and rootPart:IsA("BasePart") then rootPart.Anchored = false end
    end
end)

pluginTab:AddToggle("Dashcam Mode", function(on)
    dashcamEnabled = on
end)

pluginTab:AddToggle("Custom RCCar sound", function(on)
    customSoundsEnabled = on
end)

pluginTab:AddToggle("Custom RCCar Speed", function(on)
    customSpeedEnabled = on
end)

pluginTab:AddToggle("RCCar Speedometer", function(on)
    speedometerEnabled = on
    if rcEnabled then
        speedGui.Enabled = on
    else
        speedGui.Enabled = false
    end
end)

pluginTab:AddSlider("Max Speed", 1, 200, 80, function(v)
    maxSpeedVal = v
end)

pluginTab:AddSlider("Horse Power ( HP )", 10, 1000, 500, function(v)
    horsePowerVal = v
end)
