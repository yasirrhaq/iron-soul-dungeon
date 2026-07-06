-- ====================================================================
-- IRON SOUL - ULTIMATE REWRITTEN FARM (V14 GABUNGAN + AUTO DOOR & PORTAL)
-- ====================================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

-- KONTROL SCRIPT MASTER
_G.AutoFarm = true          
_G.AutoSkill = true
_G.RadiusPutar = 6          
_G.TinggiMelayang = 5        
_G.KecepatanPutar = 4.0     
_G.UndergroundMode = true   
_G.KillAuraRadius = 45      
_G.AutoProgressStage = true  

local SudutPutar = 0
local Target = nil
local IsEgg = false
local IsExtractingEgg = false

local LastJumpTime = 0
local JumpInterval = 0.1 
local LastPortalCheck = 0
local IsEnteringPortal = false 
local PortalCooldown = false 

local MaxPortalDistance = 250 -- Diperluas agar jangkauan deteksi pintu/portal lebih jauh

-- 1. FUNGSI ANTI-AFK
if not _G.AntiAFK_Loaded then
    _G.AntiAFK_Loaded = true
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0,0))
    end)
end

-- PLATFORM ANTI-JATUH (OPTIMIZED)
local PlatformPart = Instance.new("Part")
PlatformPart.Name = "AntiFallPlatform"
PlatformPart.Size = Vector3.new(10, 1, 10)
PlatformPart.Transparency = 1 
PlatformPart.Anchored = true
PlatformPart.CanCollide = true
PlatformPart.Parent = workspace

RunService.Heartbeat:Connect(function()
    if _G.AutoFarm and _G.UndergroundMode and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local MyRoot = LocalPlayer.Character.HumanoidRootPart
        PlatformPart.Position = Vector3.new(MyRoot.Position.X, MyRoot.Position.Y - 3.5, MyRoot.Position.Z)
        PlatformPart.CanCollide = true
    else
        PlatformPart.Position = Vector3.new(0, -5000, 0)
        PlatformPart.CanCollide = false
    end
end)

-- 2. FUNGSI KEYBOARD GLOBAL
local function PressKey(key)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end)
end

-- AUTO SKILL DENGAN COOLDOWN (Q=1s, E=3s, R=5s)
local LastUsed = {Q = 0, E = 0, R = 0}
local Cooldowns = {Q = 1, E = 3, R = 5} 

task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoFarm and _G.AutoSkill and LocalPlayer.Character and Target then
            local CurrentTime = os.clock()
            
            if (CurrentTime - LastUsed.Q) >= Cooldowns.Q then
                PressKey("Q")
                LastUsed.Q = CurrentTime
            end
            
            if (CurrentTime - LastUsed.E) >= Cooldowns.E then
                PressKey("E")
                LastUsed.E = CurrentTime
            end
            
            if (CurrentTime - LastUsed.R) >= Cooldowns.R then
                PressKey("R")
                LastUsed.R = CurrentTime
            end
        end
    end
end)

-- ZERO-SPIKE JUMP SYSTEM
RunService.Heartbeat:Connect(function()
    if _G.AutoFarm and LocalPlayer.Character and Target and not IsExtractingEgg and not IsEnteringPortal then
        local CurrentTime = os.clock()
        if (CurrentTime - LastJumpTime) >= JumpInterval then
            LastJumpTime = CurrentTime
            local Hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if Hum then
                Hum:ChangeState(Enum.HumanoidStateType.Jumping)
                Hum.Jump = true 
            end
        end
    end
end)

-- 3. SCANNING TARGET INTERNAL
local function GetClosestTargetZeroSpike()
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return nil, false end

    local NewTarget = nil
    local ClosestDistance = math.huge
    local SemuaObjek = workspace:GetChildren()

    for i = 1, #SemuaObjek do
        local obj = SemuaObjek[i]
        if obj:IsA("Model") and obj ~= Character then
            local Humanoid = obj:FindFirstChildOfClass("Humanoid")
            if Humanoid and Humanoid.Health > 0 then
                local EnemyRoot = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("PrimaryPart")
                if EnemyRoot then
                    local Distance = (MyRoot.Position - EnemyRoot.Position).Magnitude
                    if Distance < ClosestDistance then
                        ClosestDistance = Distance
                        NewTarget = EnemyRoot
                    end
                end
            end
        elseif obj:IsA("Folder") then
            local IsiFolder = obj:GetChildren()
            for j = 1, #IsiFolder do
                local subObj = IsiFolder[j]
                if subObj:IsA("Model") and subObj ~= Character then
                    local Humanoid = subObj:FindFirstChildOfClass("Humanoid")
                    if Humanoid and Humanoid.Health > 0 then
                        local EnemyRoot = subObj:FindFirstChild("HumanoidRootPart") or subObj:FindFirstChild("PrimaryPart")
                        if EnemyRoot then
                            local Distance = (MyRoot.Position - EnemyRoot.Position).Magnitude
                            if Distance < ClosestDistance then
                                ClosestDistance = Distance
                                NewTarget = EnemyRoot
                            end
                        end
                    end
                end
            end
        end
    end
    return NewTarget, false
end

-- DETEKSI OTOMATIS DAN PEMBUKA PINTU / STAGE PORTAL (OPTIMIZED RADAR)
local function TeleportToNextStagePortal()
    if PortalCooldown or not _G.AutoProgressStage then return end 
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    local MyHumanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if not MyRoot or not MyHumanoid or IsEnteringPortal then return end

    local BestPortalPart = nil
    local HighestScore = 0
    
    -- Menyisir objek di workspace untuk mencari target pintu/portal secara agresif
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            local DistanceToPortal = (MyRoot.Position - obj.Position).Magnitude
            if DistanceToPortal <= MaxPortalDistance then
                local CurrentScore = 0
                local LowerName = string.lower(obj.Name)
                
                -- Sistem pembobotan deteksi kata kunci pintu/portal/gate/exit
                if string.find(LowerName, "portal") or string.find(LowerName, "gate") or string.find(LowerName, "door") or string.find(LowerName, "pintu") then
                    CurrentScore = CurrentScore + 6
                elseif string.find(LowerName, "next") or string.find(LowerName, "exit") or string.find(LowerName, "finish") or string.find(LowerName, "teleport") then
                    CurrentScore = CurrentScore + 4
                end
                
                -- Cek trigger mekanis Roblox (TouchTransmitter / ProximityPrompt)
                if obj:FindFirstChildOfClass("TouchTransmitter") or obj:FindFirstChildOfClass("ProximityPrompt") then 
                    CurrentScore = CurrentScore + 3 
                end
                if obj.Material == Enum.Material.Neon then CurrentScore = CurrentScore + 2 end
                if obj.Size.Y > 4 and obj.Size.X > 4 then CurrentScore = CurrentScore + 1 end
                
                if CurrentScore > HighestScore then
                    HighestScore = CurrentScore
                    BestPortalPart = obj
                end
            end
        end
    end

    -- Eksekusi Teleportasi Masuk Portal / Buka Pintu jika kecocokan tinggi
    if BestPortalPart and HighestScore >= 3 then
        IsEnteringPortal = true
        PortalCooldown = true 
        
        -- Berpindah tepat di depan koordinat pintu/portal
        MyRoot.CFrame = CFrame.new(BestPortalPart.Position)
        
        -- Simulasi eksekusi aksi (Menekan Shift & E untuk memicu pembukaan Proximity/Prompt pintu game)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        
        task.wait(0.2) 
        MyRoot.Velocity = Vector3.new(0, 0, 0)
        IsEnteringPortal = false
        
        task.spawn(function()
            task.wait(3.0) -- Cooldown aman sebelum scan portal berikutnya
            PortalCooldown = false
        end)
    end
end

task.spawn(function()
    while true do
        if _G.AutoFarm then
            local Success, NewTarget, IsAnEgg = pcall(GetClosestTargetZeroSpike)
            if Success and NewTarget then
                Target = NewTarget
                IsEgg = IsAnEgg
                task.wait(0.5) -- Jeda scan lebih responsif
            else
                Target = nil
                -- Jika monster habis, langsung pacu fungsi pencari pintu/portal otomatis
                if _G.AutoProgressStage and not IsEnteringPortal and not PortalCooldown then
                    local CurrentTime = os.clock()
                    if (CurrentTime - LastPortalCheck) >= 1.5 then 
                        LastPortalCheck = CurrentTime
                        pcall(TeleportToNextStagePortal)
                    end
                end
                task.wait(0.2)
            end
        else
            Target = nil
            task.wait(0.5)
        end
    end
end)

local RaycastParamsInstance = RaycastParams.new()
RaycastParamsInstance.FilterType = Enum.RaycastFilterType.Exclude

RunService.Heartbeat:Connect(function(dt)
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    local MyHumanoid = Character and Character:FindFirstChild("Humanoid")
    if not MyRoot or not MyHumanoid or IsEnteringPortal or not _G.AutoFarm then return end
    if not Target or not Target.Parent or not Target.Parent:FindFirstChildOfClass("Humanoid") or Target.Parent:FindFirstChildOfClass("Humanoid").Health <= 0 then 
        Target = nil
        return 
    end
    MyRoot.Velocity = Vector3.new(0, MyRoot.Velocity.Y, 0)
    local CurrentRadius = _G.RadiusPutar
    local CurrentHeight = _G.TinggiMelayang
    local TargetPos = Target.Position
    local FinalY = TargetPos.Y
    
    if _G.UndergroundMode then
        CurrentRadius = _G.RadiusPutar
        CurrentHeight = -(_G.TinggiMelayang) 
        RaycastParamsInstance.FilterDescendantsInstances = {Target.Parent, Character}
        local GroundRay = workspace:Raycast(TargetPos, Vector3.new(0, -30, 0), RaycastParamsInstance)
        if GroundRay then FinalY = GroundRay.Position.Y + CurrentHeight else FinalY = TargetPos.Y + CurrentHeight end
    else
        CurrentRadius = _G.RadiusPutar
        CurrentHeight = _G.TinggiMelayang
        FinalY = TargetPos.Y + CurrentHeight
    end
    
    SudutPutar = SudutPutar + (dt * _G.KecepatanPutar)
    local OffsetX = math.sin(SudutPutar) * CurrentRadius
    local OffsetZ = math.cos(SudutPutar) * CurrentRadius
    local FinalPosition = Vector3.new(TargetPos.X + OffsetX, FinalY, TargetPos.Z + OffsetZ)
    
    if _G.UndergroundMode then
        MyRoot.CFrame = CFrame.new(FinalPosition) * CFrame.Angles(math.rad(90), 0, 0)
    else
        MyRoot.CFrame = CFrame.new(FinalPosition) * CFrame.Angles(math.rad(-90), 0, 0)
    end
    
    if not IsExtractingEgg then
        local CurrentDistance = (MyRoot.Position - Target.Position).Magnitude
        if CurrentDistance <= _G.KillAuraRadius then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0, 0))
            local ToolInChar = Character:FindFirstChildOfClass("Tool")
            if ToolInChar then ToolInChar:Activate() end
        end
    end
end)

RunService.Stepped:Connect(function()
    if _G.AutoFarm and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- GUI MENU DUAL BUTTON (TETAP SAMA SEPERTI ASLINYA)
local ScreenGui = Instance.new("ScreenGui")
local MasterButton = Instance.new("TextButton")
local ModeButton = Instance.new("TextButton")
local OldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("IronSoulDualMenu")
if OldGui then OldGui:Destroy() end
ScreenGui.Name = "IronSoulDualMenu"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
MasterButton.Name = "MasterButton"
MasterButton.Parent = ScreenGui
MasterButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0) 
MasterButton.Position = UDim2.new(0.05, 0, 0.2, 0)         
MasterButton.Size = UDim2.new(0, 160, 0, 40)               
MasterButton.Font = Enum.Font.SourceSansBold
MasterButton.Text = "SCRIPT: ON"
MasterButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MasterButton.TextSize = 16
MasterButton.BorderSizePixel = 2
ModeButton.Name = "ModeButton"
ModeButton.Parent = ScreenGui
ModeButton.BackgroundColor3 = Color3.fromRGB(0, 85, 255) 
ModeButton.Position = UDim2.new(0.05, 0, 0.27, 0)         
ModeButton.Size = UDim2.new(0, 160, 0, 40)               
ModeButton.Font = Enum.Font.SourceSansBold
ModeButton.Text = "MODE: UNDERGROUND"
ModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeButton.TextSize = 14
ModeButton.BorderSizePixel = 2

MasterButton.MouseButton1Click:Connect(function()
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    if _G.AutoFarm then
        _G.AutoFarm = false
        MasterButton.Text = "SCRIPT: OFF"
        MasterButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0) 
        Target = nil
        if MyRoot then
            local SkyY = MyRoot.Position.Y + 150
            MyRoot.CFrame = CFrame.new(MyRoot.Position.X, SkyY, MyRoot.Position.Z)
        end
    else
        Target = nil 
        _G.AutoFarm = true
        MasterButton.Text = "SCRIPT: ON"
        MasterButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0) 
    end
end)

ModeButton.MouseButton1Click:Connect(function()
    if _G.UndergroundMode then
        _G.UndergroundMode = false
        ModeButton.Text = "MODE: ABOVE MONSTER"
        ModeButton.BackgroundColor3 = Color3.fromRGB(135, 0, 255) 
    else
        _G.UndergroundMode = true
        ModeButton.Text = "MODE: UNDERGROUND"
        ModeButton.BackgroundColor3 = Color3.fromRGB(0, 85, 255) 
    end
end)