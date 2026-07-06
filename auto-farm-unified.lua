-- IRON SOUL - UNIFIED FARM (DUNGEON / ENDLESS + EGG / CHEST)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

_G.AutoFarm = true
_G.AutoSkill = true
_G.AutoReplay = true
_G.AutoProgressStage = true
_G.UndergroundMode = false
_G.FarmMode = _G.FarmMode or "Dungeon"
_G.RadiusPutar = 6
_G.TinggiMelayang = 12
_G.KecepatanPutar = 4.0
_G.KillAuraRadius = _G.TinggiMelayang + 25

local Target = nil
local TargetKind = nil
local SudutPutar = 0
local LastJumpTime = 0
local LastPortalCheck = 0
local LastEggInteract = 0
local IsEnteringPortal = false
local PortalCooldown = false
local ServerLoadingLock = false
local MaxPortalDistance = 250

if not _G.AntiAFK_Loaded then
    _G.AntiAFK_Loaded = true
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end

local PlatformPart = Instance.new("Part")
PlatformPart.Name = "IronSoulAntiFallPlatform"
PlatformPart.Size = Vector3.new(10, 1, 10)
PlatformPart.Transparency = 1
PlatformPart.Anchored = true
PlatformPart.CanCollide = true
PlatformPart.Parent = workspace

local function IsInLobby()
    local subject = workspace.CurrentCamera and workspace.CurrentCamera.CameraSubject
    local subjectName = string.lower(subject and subject.Parent and subject.Parent.Name or "")
    if string.find(subjectName, "lobby") or string.find(subjectName, "town") then return true end

    for _, obj in pairs(workspace:GetChildren()) do
        local name = string.lower(obj.Name)
        if string.find(name, "dungeon") or string.find(name, "stage") or string.find(name, "monster") or string.find(name, "enemy") or string.find(name, "match") then
            return false
        end
    end
    return true
end

local function PressKey(key)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end)
end

local function HoldKey(key, duration)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(duration)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end)
end

local function ClickReplayButton(button)
    if not button then return end
    pcall(function()
        if getconnections then
            for _, conn in pairs(getconnections(button.MouseButton1Click)) do conn:Fire() end
            for _, conn in pairs(getconnections(button.Activated)) do conn:Fire() end
        end
    end)
    pcall(function()
        local center = button.AbsolutePosition + (button.AbsoluteSize / 2)
        GuiService.SelectedObject = button
        PressKey("Return")
        GuiService.SelectedObject = nil
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(center.X, center.Y + 36))
    end)
end

local function NameHasAny(text, words)
    for _, word in ipairs(words) do
        if string.find(text, word) then return true end
    end
    return false
end

local function ClassifyTarget(model)
    local name = string.lower(model.Name)
    if NameHasAny(name, {"egg"}) then return "egg" end
    if NameHasAny(name, {"chest", "box", "crate", "treasure"}) then return "chest" end
    return "enemy"
end

local function IsDungeonContainer(obj)
    local name = string.lower(obj.Name)
    return obj:IsA("Folder") and NameHasAny(name, {"monster", "enemy", "stage", "dungeon"})
end

local function CandidateAllowedByMode(model)
    if _G.FarmMode == "Endless" then return true end
    local parent = model.Parent
    while parent and parent ~= workspace do
        if IsDungeonContainer(parent) then return true end
        parent = parent.Parent
    end
    return IsDungeonContainer(model.Parent)
end

local function FindTargetRoot(model)
    return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

local function GetClosestTarget()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or ServerLoadingLock then return nil, nil end
    if _G.FarmMode == "Dungeon" and IsInLobby() then return nil, nil end

    local bestRoot = nil
    local bestKind = nil
    local bestDistance = math.huge

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= character and not Players:GetPlayerFromCharacter(obj) and CandidateAllowedByMode(obj) then
            local kind = ClassifyTarget(obj)
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            local candidateRoot = FindTargetRoot(obj)
            local alive = kind == "egg" or kind == "chest" or (humanoid and humanoid.Health > 0)
            if alive and candidateRoot then
                local distance = (root.Position - candidateRoot.Position).Magnitude
                if distance < bestDistance then
                    bestDistance = distance
                    bestRoot = candidateRoot
                    bestKind = kind
                end
            end
        end
    end

    return bestRoot, bestKind
end

local function FindPortalPart()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local bestPart = nil
    local bestScore = 0

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            local distance = (root.Position - obj.Position).Magnitude
            if distance <= MaxPortalDistance then
                local score = 0
                local lowerName = string.lower(obj.Name)
                local parentName = string.lower(obj.Parent and obj.Parent.Name or "")
                local fullName = lowerName .. " " .. parentName

                if _G.FarmMode == "Dungeon" and NameHasAny(fullName, {"replay", "restart", "return", "lobby", "leave", "reload", "menu"}) then
                    score = 0
                else
                    if _G.FarmMode == "Dungeon" and NameHasAny(lowerName, {"checkpoint", "stage", "next"}) then score = score + 8 end
                    if NameHasAny(lowerName, {"portal", "gate", "door", "pintu"}) then score = score + 6 end
                    if NameHasAny(lowerName, {"next", "exit", "finish", "teleport", "spawn"}) then score = score + 4 end
                    if obj:FindFirstChildOfClass("TouchTransmitter") or obj:FindFirstChildOfClass("ProximityPrompt") then score = score + 3 end
                    if obj.Material == Enum.Material.Neon then score = score + 2 end
                    if _G.FarmMode == "Endless" and obj.Size.Y > 4 and obj.Size.X > 4 then score = score + 1 end
                end

                if score > bestScore then
                    bestScore = score
                    bestPart = obj
                end
            end
        end
    end

    return bestPart
end

local function TeleportToNextStagePortal()
    if PortalCooldown or not _G.AutoProgressStage then return end
    if _G.FarmMode == "Dungeon" and IsInLobby() then return end
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or IsEnteringPortal then return end

    local portal = FindPortalPart()
    if not portal then return end

    IsEnteringPortal = true
    PortalCooldown = true
    task.wait(_G.FarmMode == "Dungeon" and 1.0 or 0)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local currentRoot = LocalPlayer.Character.HumanoidRootPart
        currentRoot.CFrame = CFrame.new(portal.Position)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        task.wait(0.2)
        currentRoot.Velocity = Vector3.new(0, 0, 0)
    end
    IsEnteringPortal = false
    task.spawn(function()
        task.wait(_G.FarmMode == "Dungeon" and 5.0 or 3.0)
        PortalCooldown = false
    end)
end

local function ScanAndExecuteReplay()
    if not _G.AutoReplay then return end
    if _G.FarmMode == "Dungeon" and (ServerLoadingLock or IsInLobby()) then return end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local replayButton = nil
    for _, obj in pairs(playerGui:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local text = string.lower(obj.Text)
            if string.find(text, "play") and string.find(text, "again") then
                replayButton = obj:FindFirstAncestorWhichIsA("TextButton") or obj:FindFirstAncestorWhichIsA("ImageButton") or obj.Parent
                break
            end
        elseif obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local name = string.lower(obj.Name)
            if (_G.FarmMode == "Dungeon" and (name == "playagain" or name == "replaybutton" or name == "againbutton")) or (_G.FarmMode == "Endless" and NameHasAny(name, {"replay", "again", "restart"})) then
                replayButton = obj
                break
            end
        end
    end

    if replayButton and replayButton.Visible and replayButton.AbsolutePosition.Y > 0 then
        if _G.FarmMode == "Dungeon" then ServerLoadingLock = true end
        Target = nil
        task.wait(_G.FarmMode == "Dungeon" and 0.5 or 1.0)
        ClickReplayButton(replayButton)
        if _G.FarmMode == "Dungeon" then
            task.spawn(function()
                task.wait(5.0)
                ServerLoadingLock = false
            end)
        else
            task.wait(4.0)
        end
    end
end

local LastUsed = {Q = 0, E = 0, R = 0}
local Cooldowns = {Q = 1, E = 3, R = 5}

task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoFarm and _G.AutoSkill and Target and TargetKind ~= "egg" and LocalPlayer.Character and not IsEnteringPortal then
            if _G.FarmMode ~= "Dungeon" or not IsInLobby() then
                local now = os.clock()
                if now - LastUsed.Q >= Cooldowns.Q then PressKey("Q") LastUsed.Q = now end
                if now - LastUsed.E >= Cooldowns.E then PressKey("E") LastUsed.E = now end
                if now - LastUsed.R >= Cooldowns.R then PressKey("R") LastUsed.R = now end
            end
        end
    end
end)

task.spawn(function()
    while true do
        if _G.AutoFarm then
            local ok, newTarget, kind = pcall(GetClosestTarget)
            if ok and newTarget then
                Target = newTarget
                TargetKind = kind
                task.wait(0.5)
            else
                Target = nil
                TargetKind = nil
                if _G.AutoReplay then pcall(ScanAndExecuteReplay) end
                if _G.AutoProgressStage and not IsEnteringPortal and not PortalCooldown then
                    local now = os.clock()
                    local interval = _G.FarmMode == "Dungeon" and 2.0 or 1.5
                    if now - LastPortalCheck >= interval then
                        LastPortalCheck = now
                        pcall(TeleportToNextStagePortal)
                    end
                end
                task.wait(0.2)
            end
        else
            Target = nil
            TargetKind = nil
            task.wait(0.5)
        end
    end
end)

local RaycastParamsInstance = RaycastParams.new()
RaycastParamsInstance.FilterType = Enum.RaycastFilterType.Exclude

RunService.Heartbeat:Connect(function(dt)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not _G.AutoFarm or not root or IsEnteringPortal then return end
    if _G.FarmMode == "Dungeon" and (ServerLoadingLock or IsInLobby()) then return end
    if not Target or not Target.Parent then Target = nil TargetKind = nil return end

    local targetPos = Target.Position
    if TargetKind == "egg" then
        if os.clock() - LastEggInteract < 4.0 then return end
        LastEggInteract = os.clock()
        local groundRay = workspace:Raycast(targetPos + Vector3.new(0, 20, 0), Vector3.new(0, -80, 0))
        local groundPos = groundRay and groundRay.Position or targetPos
        root.CFrame = CFrame.new(groundPos + Vector3.new(0, 3, 0))
        root.Velocity = Vector3.new(0, 0, 0)
        HoldKey("E", 2.5)
        return
    end

    root.Velocity = Vector3.new(0, root.Velocity.Y, 0)
    local finalY = targetPos.Y + _G.TinggiMelayang
    if _G.UndergroundMode then
        RaycastParamsInstance.FilterDescendantsInstances = {Target.Parent, character}
        local groundRay = workspace:Raycast(targetPos, Vector3.new(0, -150, 0), RaycastParamsInstance)
        finalY = (groundRay and groundRay.Position.Y or targetPos.Y) - _G.TinggiMelayang
    end

    SudutPutar = SudutPutar + (dt * _G.KecepatanPutar)
    local offsetX = math.sin(SudutPutar) * _G.RadiusPutar
    local offsetZ = math.cos(SudutPutar) * _G.RadiusPutar
    local finalPosition = Vector3.new(targetPos.X + offsetX, finalY, targetPos.Z + offsetZ)
    root.CFrame = CFrame.new(finalPosition) * CFrame.Angles(math.rad(_G.UndergroundMode and 90 or -90), 0, 0)

    if (root.Position - targetPos).Magnitude <= _G.KillAuraRadius or TargetKind == "chest" then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0, 0))
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
    end
end)

RunService.Heartbeat:Connect(function()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if _G.AutoFarm and _G.UndergroundMode and root and (_G.FarmMode ~= "Dungeon" or not IsInLobby()) then
        PlatformPart.Position = Vector3.new(root.Position.X, root.Position.Y - 3.5, root.Position.Z)
        PlatformPart.CanCollide = true
    else
        PlatformPart.Position = Vector3.new(0, -5000, 0)
        PlatformPart.CanCollide = false
    end
end)

RunService.Stepped:Connect(function()
    if _G.AutoFarm and LocalPlayer.Character and (_G.FarmMode ~= "Dungeon" or not IsInLobby()) then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("IronSoulUnifiedMenu")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "IronSoulUnifiedMenu"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local function makeButton(text, y, color)
    local button = Instance.new("TextButton")
    button.Parent = screenGui
    button.Position = UDim2.new(0.05, 0, y, 0)
    button.Size = UDim2.new(0, 190, 0, 38)
    button.BackgroundColor3 = color
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 14
    button.Text = text
    return button
end

local masterButton = makeButton("SCRIPT: ON", 0.20, Color3.fromRGB(0, 170, 0))
local farmModeButton = makeButton("FARM MODE: " .. string.upper(_G.FarmMode), 0.27, Color3.fromRGB(180, 100, 0))
local heightModeButton = makeButton("HEIGHT MODE: ABOVE", 0.34, Color3.fromRGB(135, 0, 255))
local replayButton = makeButton("AUTO REPLAY: YES", 0.41, Color3.fromRGB(0, 150, 75))

local function makeLabel(text, y)
    local label = Instance.new("TextLabel")
    label.Parent = screenGui
    label.Position = UDim2.new(0.05, 0, y, 0)
    label.Size = UDim2.new(0, 190, 0, 18)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 12
    label.Text = text
    return label
end

local function makeSlider(y, color, percent)
    local frame = Instance.new("Frame")
    frame.Parent = screenGui
    frame.Position = UDim2.new(0.05, 0, y, 0)
    frame.Size = UDim2.new(0, 190, 0, 6)
    frame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)

    local knob = Instance.new("TextButton")
    knob.Parent = frame
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(percent - 0.04, 0, -0.6, 0)
    knob.BackgroundColor3 = color
    knob.Text = ""
    return frame, knob
end

local heightLabel = makeLabel("HEIGHT DISTANCE: " .. tostring(_G.TinggiMelayang) .. " STUDS", 0.49)
local heightFrame, heightKnob = makeSlider(0.53, Color3.fromRGB(255, 215, 0), _G.TinggiMelayang / 100)
local radiusLabel = makeLabel("ORBIT RADIUS: " .. tostring(_G.RadiusPutar) .. " STUDS", 0.57)
local radiusFrame, radiusKnob = makeSlider(0.61, Color3.fromRGB(0, 255, 255), _G.RadiusPutar / 30)
local speedLabel = makeLabel("ORBIT SPEED: " .. string.format("%.1f", _G.KecepatanPutar) .. " X", 0.65)
local speedFrame, speedKnob = makeSlider(0.69, Color3.fromRGB(255, 100, 255), _G.KecepatanPutar / 10)

local function RefreshButtons()
    masterButton.Text = _G.AutoFarm and "SCRIPT: ON" or "SCRIPT: OFF"
    masterButton.BackgroundColor3 = _G.AutoFarm and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    farmModeButton.Text = "FARM MODE: " .. string.upper(_G.FarmMode)
    farmModeButton.BackgroundColor3 = _G.FarmMode == "Dungeon" and Color3.fromRGB(180, 100, 0) or Color3.fromRGB(0, 100, 180)
    heightModeButton.Text = _G.UndergroundMode and "HEIGHT MODE: UNDERGROUND" or "HEIGHT MODE: ABOVE"
    heightModeButton.BackgroundColor3 = _G.UndergroundMode and Color3.fromRGB(0, 85, 255) or Color3.fromRGB(135, 0, 255)
    replayButton.Text = _G.AutoReplay and "AUTO REPLAY: YES" or "AUTO REPLAY: NO"
    replayButton.BackgroundColor3 = _G.AutoReplay and Color3.fromRGB(0, 150, 75) or Color3.fromRGB(180, 40, 40)
    heightLabel.Text = "HEIGHT DISTANCE: " .. tostring(_G.TinggiMelayang) .. " STUDS"
    heightKnob.Position = UDim2.new((_G.TinggiMelayang / 100) - 0.04, 0, -0.6, 0)
    radiusLabel.Text = "ORBIT RADIUS: " .. tostring(_G.RadiusPutar) .. " STUDS"
    radiusKnob.Position = UDim2.new((_G.RadiusPutar / 30) - 0.04, 0, -0.6, 0)
    speedLabel.Text = "ORBIT SPEED: " .. string.format("%.1f", _G.KecepatanPutar) .. " X"
    speedKnob.Position = UDim2.new((_G.KecepatanPutar / 10) - 0.04, 0, -0.6, 0)
end

local activeSlider = nil
heightKnob.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then activeSlider = "HEIGHT" end end)
radiusKnob.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then activeSlider = "RADIUS" end end)
speedKnob.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then activeSlider = "SPEED" end end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        activeSlider = nil
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not activeSlider or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end

    if activeSlider == "HEIGHT" then
        local percent = math.clamp((input.Position.X - heightFrame.AbsolutePosition.X) / heightFrame.AbsoluteSize.X, 0, 1)
        _G.TinggiMelayang = math.max(5, math.floor(percent * 100))
        _G.KillAuraRadius = _G.TinggiMelayang + 25
    elseif activeSlider == "RADIUS" then
        local percent = math.clamp((input.Position.X - radiusFrame.AbsolutePosition.X) / radiusFrame.AbsoluteSize.X, 0, 1)
        _G.RadiusPutar = math.max(2, math.floor(percent * 30))
    elseif activeSlider == "SPEED" then
        local percent = math.clamp((input.Position.X - speedFrame.AbsolutePosition.X) / speedFrame.AbsoluteSize.X, 0, 1)
        _G.KecepatanPutar = math.max(0.5, tonumber(string.format("%.1f", percent * 10)))
    end

    RefreshButtons()
end)

masterButton.MouseButton1Click:Connect(function()
    _G.AutoFarm = not _G.AutoFarm
    Target = nil
    TargetKind = nil
    RefreshButtons()
end)

farmModeButton.MouseButton1Click:Connect(function()
    _G.FarmMode = _G.FarmMode == "Dungeon" and "Endless" or "Dungeon"
    Target = nil
    TargetKind = nil
    PortalCooldown = false
    ServerLoadingLock = false
    RefreshButtons()
end)

heightModeButton.MouseButton1Click:Connect(function()
    _G.UndergroundMode = not _G.UndergroundMode
    RefreshButtons()
end)

replayButton.MouseButton1Click:Connect(function()
    _G.AutoReplay = not _G.AutoReplay
    RefreshButtons()
end)

RefreshButtons()
