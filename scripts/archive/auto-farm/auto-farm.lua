-- ====================================================================
-- IRON SOUL - V34 HYBRID MASTER (STRICT LOBBY DETECTOR & GROUNDED FIX)
-- ====================================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local FolderNama = "IronSoulConfig"
local FileNama = FolderNama .. "/YasirConfig.json"

-- CONFIG STRUCTURE WITH AUTO-SAVE
local Config = {
    AutoFarm = true,
    AutoSkill = true,
    RadiusPutar = 6,          
    TinggiMelayang = 15,      
    KecepatanPutar = 4.0,     
    UndergroundMode = false, 
    AutoProgressStage = true,
    AutoReplay = true,
    SemiGodMode = true
}

local function SinkronisasiConfig(Aksi)
    if Aksi == "SAVE" then
        local Berhasil, HasilJSON = pcall(function() return HttpService:JSONEncode(Config) end)
        if Berhasil and writefile then
            pcall(function()
                if makefolder then makefolder(FolderNama) end
                writefile(FileNama, HasilJSON)
            end)
        end
    elseif Aksi == "LOAD" then
        if readfile and isfile and isfile(FileNama) then
            local Berhasilbaca, IsiFile = pcall(function() return readfile(FileNama) end)
            if Berhasilbaca then
                local BerhasilDecode, TabelData = pcall(function() return HttpService:JSONDecode(IsiFile) end)
                if BerhasilDecode and type(TabelData) == "table" then
                    for Key, Value in pairs(TabelData) do Config[Key] = Value end
                end
            end
        else
            SinkronisasiConfig("SAVE")
        end
    end
end

SinkronisasiConfig("LOAD")

_G.AutoFarm = Config.AutoFarm
_G.AutoSkill = Config.AutoSkill
_G.RadiusPutar = Config.RadiusPutar
_G.TinggiMelayang = Config.TinggiMelayang
_G.KecepatanPutar = Config.KecepatanPutar
_G.UndergroundMode = Config.UndergroundMode
_G.KillAuraRadius = _G.TinggiMelayang + 25 
_G.AutoProgressStage = Config.AutoProgressStage
_G.AutoReplay = Config.AutoReplay
_G.SemiGodMode = Config.SemiGodMode

local SudutPutar = 0
local Target = nil
local IsEgg = false
local IsExtractingEgg = false

local LastJumpTime = 0
local JumpInterval = 0.1 
local LastPortalCheck = 0
local IsEnteringPortal = false 
local PortalCooldown = false 
local MaxPortalDistance = 250 
local ServerLoadingLock = false

if not _G.AntiAFK_Loaded then
    _G.AntiAFK_Loaded = true
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0,0))
    end)
end

-- PLATFORM ANTI-JATUH
local PlatformPart = Instance.new("Part")
PlatformPart.Name = "AntiFallPlatform"
PlatformPart.Size = Vector3.new(10, 1, 10)
PlatformPart.Transparency = 1 
PlatformPart.Anchored = true
PlatformPart.CanCollide = true
PlatformPart.Parent = workspace

-- [FIXED V34] DETEKSI LOBBY AKURAT (Berdasarkan Struktur Folder Unik Dungeon)
local function IsInLobby()
    -- Cek nama Map bawaan game jika menggunakan sistem Place tunggal
    local CurrentMapName = string.lower(workspace.CurrentCamera.CameraSubject and workspace.CurrentCamera.CameraSubject.Parent and workspace.CurrentCamera.CameraSubject.Parent.Name or "")
    if string.find(CurrentMapName, "lobby") or string.find(CurrentMapName, "town") then
        return true
    end

    -- Scan tanda-tanda folder Dungeon aktif
    local IsDungeonActive = false
    local ObjekWorkspace = workspace:GetChildren()
    for i = 1, #ObjekWorkspace do
        local nameLower = string.lower(ObjekWorkspace[i].Name)
        -- Folder khas yang membedakan dungeon dari lobby utama
        if string.find(nameLower, "dungeon") or string.find(nameLower, "stage") or string.find(nameLower, "monster") or string.find(nameLower, "enemy") or string.find(nameLower, "match") then
            IsDungeonActive = true
            break
        end
    end
    
    return not IsDungeonActive
end

RunService.Heartbeat:Connect(function()
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    if _G.AutoFarm and _G.UndergroundMode and MyRoot and not IsInLobby() then
        PlatformPart.Position = Vector3.new(MyRoot.Position.X, MyRoot.Position.Y - 3.5, MyRoot.Position.Z)
        PlatformPart.CanCollide = true
    else
        PlatformPart.Position = Vector3.new(0, -5000, 0)
        PlatformPart.CanCollide = false
    end
end)

local function PressKey(key)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end)
end

local function EksekusiKlikReplay(tombol)
    if not tombol then return end
    pcall(function()
        if getconnections then
            for _, conn in pairs(getconnections(tombol.MouseButton1Click)) do conn:Fire() end
            for _, conn in pairs(getconnections(tombol.Activated)) do conn:Fire() end
        end
    end)
    pcall(function()
        local cx = tombol.AbsolutePosition.X + (tombol.AbsoluteSize.X / 2)
        local cy = tombol.AbsolutePosition.Y + (tombol.AbsoluteSize.Y / 2) + 36
        GuiService.SelectedObject = tombol
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        GuiService.SelectedObject = nil
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(cx, cy))
    end)
end

-- AUTO SKILL THREAD
local LastUsed = {Q = 0, E = 0, R = 0}
local Cooldowns = {Q = 1, E = 3, R = 5} 
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoFarm and _G.AutoSkill and LocalPlayer.Character and Target and not IsInLobby() then
            local CurrentTime = os.clock()
            if (CurrentTime - LastUsed.Q) >= Cooldowns.Q then PressKey("Q") LastUsed.Q = CurrentTime end
            if (CurrentTime - LastUsed.E) >= Cooldowns.E then PressKey("E") LastUsed.E = CurrentTime end
            if (CurrentTime - LastUsed.R) >= Cooldowns.R then PressKey("R") LastUsed.R = CurrentTime end
        end
    end
end)

-- JUMP SYSTEM THREAD
RunService.Heartbeat:Connect(function()
    if _G.AutoFarm and LocalPlayer.Character and Target and not IsExtractingEgg and not IsEnteringPortal and not IsInLobby() then
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

-- GOD IMMUNITY
task.spawn(function()
    while true do
        task.wait(0.2)
        if _G.SemiGodMode and LocalPlayer.Character then
            local Hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if Hum then
                Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            end
        end
    end
end)

-- SUPER AGGRESSIVE TARGET SCANNER (DENGAN RE-CHECK NETRAL DI LOBBY)
local function GetClosestTargetZeroSpike()
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot or ServerLoadingLock or IsInLobby() then return nil, false end

    local NewTarget = nil
    local ClosestDistance = math.huge
    
    -- Pemindaian berbasis folder lingkungan khusus dungeon saja
    for _, obj in pairs(workspace:GetChildren()) do
        local nameLower = string.lower(obj.Name)
        if obj:IsA("Folder") and (string.find(nameLower, "monster") or string.find(nameLower, "enemy") or string.find(nameLower, "stage") or string.find(nameLower, "dungeon")) then
            local IsiFolder = obj:GetChildren()
            for j = 1, #IsiFolder do
                local subObj = IsiFolder[j]
                if subObj:IsA("Model") and subObj ~= Character then
                    local Humanoid = subObj:FindFirstChildOfClass("Humanoid")
                    if Humanoid and Humanoid.Health > 0 then
                        local EnemyRoot = subObj:FindFirstChild("HumanoidRootPart") or subObj:FindFirstChild("PrimaryPart")
                        if EnemyRoot then
                            local Distance = (MyRoot.Position - EnemyRoot.Position).Magnitude
                            if Distance < ClosestDistance then ClosestDistance = Distance NewTarget = EnemyRoot end
                        end
                    end
                end
            end
        end
    end
    return NewTarget, false
end

-- PORTAL CONTROL
local function TeleportToNextStagePortal()
    if PortalCooldown or not _G.AutoProgressStage or IsInLobby() then return end 
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot or IsEnteringPortal or ServerLoadingLock then return end

    local CekTarget, _ = GetClosestTargetZeroSpike()
    if CekTarget then return end

    local BestPortalPart = nil
    local HighestScore = 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            local DistanceToPortal = (MyRoot.Position - obj.Position).Magnitude
            if DistanceToPortal <= MaxPortalDistance then
                local CurrentScore = 0
                local LowerName = string.lower(obj.Name)
                if string.find(LowerName, "portal") or string.find(LowerName, "gate") or string.find(LowerName, "door") or string.find(LowerName, "pintu") then CurrentScore = CurrentScore + 6
                elseif string.find(LowerName, "next") or string.find(LowerName, "exit") or string.find(LowerName, "finish") or string.find(LowerName, "teleport") then CurrentScore = CurrentScore + 4 end
                if obj:FindFirstChildOfClass("TouchTransmitter") or obj:FindFirstChildOfClass("ProximityPrompt") then CurrentScore = CurrentScore + 3 end
                if obj.Material == Enum.Material.Neon then CurrentScore = CurrentScore + 2 end
                if CurrentScore > HighestScore then HighestScore = CurrentScore BestPortalPart = obj end
            end
        end
    end

    if BestPortalPart and HighestScore >= 3 then
        IsEnteringPortal = true
        PortalCooldown = true 
        task.wait(1.0)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local CurrentRoot = LocalPlayer.Character.HumanoidRootPart
            CurrentRoot.CFrame = CFrame.new(BestPortalPart.Position)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            task.wait(0.2) 
            CurrentRoot.Velocity = Vector3.new(0, 0, 0)
        end
        IsEnteringPortal = false
        task.spawn(function() task.wait(5.0) PortalCooldown = false end)
    end
end

local function ScanAndExecuteReplay()
    if not _G.AutoReplay or ServerLoadingLock or IsInLobby() then return end
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not PlayerGui then return end
    local ReplayButton = nil
    local SemuaGui = PlayerGui:GetDescendants()
    for i = 1, #SemuaGui do
        local obj = SemuaGui[i]
        if obj:IsA("TextLabel") then
            local textLower = string.lower(obj.Text)
            if string.find(textLower, "play") and string.find(textLower, "again") then
                local parentButton = obj:FindFirstAncestorWhichIsA("TextButton") or obj:FindFirstAncestorWhichIsA("ImageButton") or obj.Parent
                if parentButton and parentButton.AbsolutePosition.Y > 0 then ReplayButton = parentButton break end
            end
        elseif obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local nameLower = string.lower(obj.Name)
            if string.find(nameLower, "replay") or string.find(nameLower, "again") or string.find(nameLower, "restart") then
                if obj.Visible and obj.AbsolutePosition.Y > 0 then ReplayButton = obj break end
            end
        end
    end
    
    if ReplayButton then
        ServerLoadingLock = true 
        Target = nil
        task.wait(0.5)
        EksekusiKlikReplay(ReplayButton)
        task.spawn(function()
            task.wait(5.0)
            ServerLoadingLock = false
        end)
    end
end

-- MAIN FARM LOOP TRIGGER
task.spawn(function()
    while true do
        if _G.AutoFarm and not IsInLobby() then
            local Success, NewTarget, IsAnEgg = pcall(GetClosestTargetZeroSpike)
            if Success and NewTarget then
                Target = NewTarget
                IsEgg = IsAnEgg
                task.wait(0.5) 
            else
                Target = nil
                if _G.AutoReplay then pcall(ScanAndExecuteReplay) end
                if _G.AutoProgressStage and not IsEnteringPortal and not PortalCooldown then
                    local CurrentTime = os.clock()
                    if (CurrentTime - LastPortalCheck) >= 2.0 then LastPortalCheck = CurrentTime pcall(TeleportToNextStagePortal) end
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

-- CORE MOVEMENT LOOP (HEARTBEAT FLY/UNDERGROUND ENGINE)
RunService.Heartbeat:Connect(function(dt)
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    
    -- JIKA DI LOBBY: Putuskan paksa pergerakan terbang/orbit biar jalan normal menapak bumi
    if IsInLobby() or ServerLoadingLock or not _G.AutoFarm or not MyRoot or IsEnteringPortal then 
        return 
    end
    
    if not Target or not Target.Parent or not Target.Parent:FindFirstChildOfClass("Humanoid") or Target.Parent:FindFirstChildOfClass("Humanoid").Health <= 0 then Target = nil return end
    
    MyRoot.Velocity = Vector3.new(0, MyRoot.Velocity.Y, 0)
    
    local TargetPos = Target.Position
    local FinalY = TargetPos.Y
    
    if _G.UndergroundMode then
        RaycastParamsInstance.FilterDescendantsInstances = {Target.Parent, Character}
        local GroundRay = workspace:Raycast(TargetPos, Vector3.new(0, -150, 0), RaycastParamsInstance)
        if GroundRay then FinalY = GroundRay.Position.Y - _G.TinggiMelayang else FinalY = TargetPos.Y - _G.TinggiMelayang end
    else
        FinalY = TargetPos.Y + _G.TinggiMelayang
    end
    
    SudutPutar = SudutPutar + (dt * _G.KecepatanPutar)
    local OffsetX = math.sin(SudutPutar) * _G.RadiusPutar
    local OffsetZ = math.cos(SudutPutar) * _G.RadiusPutar
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
    if _G.AutoFarm and not IsInLobby() and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- ====================================================================
-- DASHBOARD UI CONTROL MANAGER PANEL
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
local MainPanel = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local MasterButton = Instance.new("TextButton")
local ModeButton = Instance.new("TextButton")
local ReplayButtonToggle = Instance.new("TextButton")

local LabelHeight = Instance.new("TextLabel")
local SliderHeightFrame = Instance.new("Frame")
local SliderHeightButton = Instance.new("TextButton")

local LabelRadius = Instance.new("TextLabel")
local SliderRadiusFrame = Instance.new("Frame")
local SliderRadiusButton = Instance.new("TextButton")

local LabelSpeed = Instance.new("TextLabel")
local SliderSpeedFrame = Instance.new("Frame")
local SliderSpeedButton = Instance.new("TextButton")

local ConfigHeaderLabel = Instance.new("TextLabel")
local ManualSaveButton = Instance.new("TextButton")
local ManualLoadButton = Instance.new("TextButton")
local StatusLogLabel = Instance.new("TextLabel")

local OldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("IronSoulDualMenu")
if OldGui then OldGui:Destroy() end

ScreenGui.Name = "IronSoulDualMenu"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

MainPanel.Name = "MainPanel"
MainPanel.Parent = ScreenGui
MainPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainPanel.BorderSizePixel = 2
MainPanel.BorderColor3 = Color3.fromRGB(100, 100, 110)
MainPanel.Position = UDim2.new(0.03, 0, 0.15, 0)
MainPanel.Size = UDim2.new(0, 190, 0, 440)

TitleLabel.Parent = MainPanel
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Text = "IRON SOUL V34 GROUNDED"
TitleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
TitleLabel.TextSize = 12

MasterButton.Parent = MainPanel
MasterButton.Position = UDim2.new(0.05, 0, 0.09, 0)         
MasterButton.Size = UDim2.new(0, 171, 0, 30)               
MasterButton.Font = Enum.Font.SourceSansBold
MasterButton.TextSize = 13
if _G.AutoFarm then MasterButton.Text = "SCRIPT: ON" MasterButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0) else MasterButton.Text = "SCRIPT: OFF" MasterButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0) end

ModeButton.Parent = MainPanel
ModeButton.Position = UDim2.new(0.05, 0, 0.17, 0)         
ModeButton.Size = UDim2.new(0, 171, 0, 30)               
ModeButton.Font = Enum.Font.SourceSansBold
ModeButton.TextSize = 13
if _G.UndergroundMode then ModeButton.Text = "MODE: UNDERGROUND" ModeButton.BackgroundColor3 = Color3.fromRGB(0, 85, 255) else ModeButton.Text = "MODE: SKY FLIGHT" ModeButton.BackgroundColor3 = Color3.fromRGB(135, 0, 255) end

ReplayButtonToggle.Parent = MainPanel
ReplayButtonToggle.Position = UDim2.new(0.05, 0, 0.25, 0)         
ReplayButtonToggle.Size = UDim2.new(0, 171, 0, 30)               
ReplayButtonToggle.Font = Enum.Font.SourceSansBold
ReplayButtonToggle.TextSize = 13
if _G.AutoReplay then ReplayButtonToggle.Text = "AUTO REPLAY: YES" ReplayButtonToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 75) else ReplayButtonToggle.Text = "AUTO REPLAY: NO" ReplayButtonToggle.BackgroundColor3 = Color3.fromRGB(180, 40, 40) end

LabelHeight.Parent = MainPanel
LabelHeight.Size = UDim2.new(1, 0, 0, 15)
LabelHeight.Position = UDim2.new(0, 0, 0.34, 0)
LabelHeight.BackgroundTransparency = 1
LabelHeight.Font = Enum.Font.SourceSansBold
LabelHeight.Text = "HEIGHT DISTANCE: " .. tostring(_G.TinggiMelayang) .. " STUDS"
LabelHeight.TextColor3 = Color3.fromRGB(255, 255, 255)
LabelHeight.TextSize = 11

SliderHeightFrame.Parent = MainPanel
SliderHeightFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
SliderHeightFrame.Position = UDim2.new(0.05, 0, 0.39, 0)
SliderHeightFrame.Size = UDim2.new(0, 171, 0, 6)
SliderHeightButton.Parent = SliderHeightFrame
SliderHeightButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
SliderHeightButton.Size = UDim2.new(0, 14, 0, 14)
SliderHeightButton.Position = UDim2.new((_G.TinggiMelayang / 100) - 0.04, 0, -0.6, 0)
SliderHeightButton.Text = ""

LabelRadius.Parent = MainPanel
LabelRadius.Size = UDim2.new(1, 0, 0, 15)
LabelRadius.Position = UDim2.new(0, 0, 0.44, 0)
LabelRadius.BackgroundTransparency = 1
LabelRadius.Font = Enum.Font.SourceSansBold
LabelRadius.Text = "ORBIT RADIUS: " .. tostring(_G.RadiusPutar) .. " STUDS"
LabelRadius.TextColor3 = Color3.fromRGB(255, 255, 255)
LabelRadius.TextSize = 11

SliderRadiusFrame.Parent = MainPanel
SliderRadiusFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
SliderRadiusFrame.Position = UDim2.new(0.05, 0, 0.49, 0)
SliderRadiusFrame.Size = UDim2.new(0, 171, 0, 6)
SliderRadiusButton.Parent = SliderRadiusFrame
SliderRadiusButton.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
SliderRadiusButton.Size = UDim2.new(0, 14, 0, 14)
SliderRadiusButton.Position = UDim2.new((_G.RadiusPutar / 30) - 0.04, 0, -0.6, 0)
SliderRadiusButton.Text = ""

LabelSpeed.Parent = MainPanel
LabelSpeed.Size = UDim2.new(1, 0, 0, 15)
LabelSpeed.Position = UDim2.new(0, 0, 0.54, 0)
LabelSpeed.BackgroundTransparency = 1
LabelSpeed.Font = Enum.Font.SourceSansBold
LabelSpeed.Text = "ORBIT SPEED: " .. string.format("%.1f", _G.KecepatanPutar) .. " X"
LabelSpeed.TextColor3 = Color3.fromRGB(255, 255, 255)
LabelSpeed.TextSize = 11

SliderSpeedFrame.Parent = MainPanel
SliderSpeedFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
SliderSpeedFrame.Position = UDim2.new(0.05, 0, 0.59, 0)
SliderSpeedFrame.Size = UDim2.new(0, 171, 0, 6)
SliderSpeedButton.Parent = SliderSpeedFrame
SliderSpeedButton.BackgroundColor3 = Color3.fromRGB(255, 100, 255)
SliderSpeedButton.Size = UDim2.new(0, 14, 0, 14)
SliderSpeedButton.Position = UDim2.new((_G.KecepatanPutar / 10) - 0.04, 0, -0.6, 0)
SliderSpeedButton.Text = ""

ConfigHeaderLabel.Parent = MainPanel
ConfigHeaderLabel.Size = UDim2.new(1, 0, 0, 20)
ConfigHeaderLabel.Position = UDim2.new(0, 0, 0.66, 0)
ConfigHeaderLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
ConfigHeaderLabel.Font = Enum.Font.SourceSansBold
ConfigHeaderLabel.Text = "⚙️ CONFIG MANAGER"
ConfigHeaderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ConfigHeaderLabel.TextSize = 11

ManualSaveButton.Parent = MainPanel
ManualSaveButton.BackgroundColor3 = Color3.fromRGB(45, 125, 45)
ManualSaveButton.Position = UDim2.new(0.05, 0, 0.73, 0)
ManualSaveButton.Size = UDim2.new(0, 80, 0, 28)
ManualSaveButton.Font = Enum.Font.SourceSansBold
ManualSaveButton.Text = "SAVE FILE"
ManualSaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ManualSaveButton.TextSize = 11

ManualLoadButton.Parent = MainPanel
ManualLoadButton.BackgroundColor3 = Color3.fromRGB(45, 85, 150)
ManualLoadButton.Position = UDim2.new(0.53, 0, 0.73, 0)
ManualLoadButton.Size = UDim2.new(0, 80, 0, 28)
ManualLoadButton.Font = Enum.Font.SourceSansBold
ManualLoadButton.Text = "LOAD FILE"
ManualLoadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ManualLoadButton.TextSize = 11

StatusLogLabel.Parent = MainPanel
StatusLogLabel.Size = UDim2.new(1, 0, 0, 45)
StatusLogLabel.Position = UDim2.new(0, 0, 0.82, 0)
StatusLogLabel.BackgroundTransparency = 1
StatusLogLabel.Font = Enum.Font.SourceSansItalic
StatusLogLabel.Text = "Status: Autoloaded Active\nFile: YasirConfig.json"
StatusLogLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
StatusLogLabel.TextSize = 11
StatusLogLabel.TextWrapped = true

local function RefreshTampilanUI()
    if _G.AutoFarm then MasterButton.Text = "SCRIPT: ON" MasterButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0) else MasterButton.Text = "SCRIPT: OFF" MasterButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0) end
    if _G.UndergroundMode then ModeButton.Text = "MODE: UNDERGROUND" ModeButton.BackgroundColor3 = Color3.fromRGB(0, 85, 255) else ModeButton.Text = "MODE: SKY FLIGHT" ModeButton.BackgroundColor3 = Color3.fromRGB(135, 0, 255) end
    if _G.AutoReplay then ReplayButtonToggle.Text = "AUTO REPLAY: YES" ReplayButtonToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 75) else ReplayButtonToggle.Text = "AUTO REPLAY: NO" ReplayButtonToggle.BackgroundColor3 = Color3.fromRGB(180, 40, 40) end
    LabelHeight.Text = "HEIGHT DISTANCE: " .. tostring(_G.TinggiMelayang) .. " STUDS"
    SliderHeightButton.Position = UDim2.new((_G.TinggiMelayang / 100) - 0.04, 0, -0.6, 0)
    LabelRadius.Text = "ORBIT RADIUS: " .. tostring(_G.RadiusPutar) .. " STUDS"
    SliderRadiusButton.Position = UDim2.new((_G.RadiusPutar / 30) - 0.04, 0, -0.6, 0)
    LabelSpeed.Text = "ORBIT SPEED: " .. string.format("%.1f", _G.KecepatanPutar) .. " X"
    SliderSpeedButton.Position = UDim2.new((_G.KecepatanPutar / 10) - 0.04, 0, -0.6, 0)
end

-- TRIPLE SLIDERS TOUCH SYSTEM
local ActiveSlider = nil
SliderHeightButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then ActiveSlider = "HEIGHT" end end)
SliderRadiusButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then ActiveSlider = "RADIUS" end end)
SliderSpeedButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then ActiveSlider = "SPEED" end end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        if ActiveSlider then ActiveSlider = nil SinkronisasiConfig("SAVE") end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if ActiveSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        if ActiveSlider == "HEIGHT" then
            local RelX = input.Position.X - SliderHeightFrame.AbsolutePosition.X
            local Persen = math.clamp(RelX / SliderHeightFrame.AbsoluteSize.X, 0, 1)
            local Val = math.floor(Persen * 100) if Val < 5 then Val = 5 end
            _G.TinggiMelayang = Val Config.TinggiMelayang = Val _G.KillAuraRadius = Val + 25
            LabelHeight.Text = "HEIGHT DISTANCE: " .. tostring(Val) .. " STUDS"
            SliderHeightButton.Position = UDim2.new(Persen - 0.04, 0, -0.6, 0)
        elseif ActiveSlider == "RADIUS" then
            local RelX = input.Position.X - SliderRadiusFrame.AbsolutePosition.X
            local Persen = math.clamp(RelX / SliderRadiusFrame.AbsoluteSize.X, 0, 1)
            local Val = math.floor(Persen * 30) if Val < 2 then Val = 2 end
            _G.RadiusPutar = Val Config.RadiusPutar = Val
            LabelRadius.Text = "ORBIT RADIUS: " .. tostring(Val) .. " STUDS"
            SliderRadiusButton.Position = UDim2.new(Persen - 0.04, 0, -0.6, 0)
        elseif ActiveSlider == "SPEED" then
            local RelX = input.Position.X - SliderSpeedFrame.AbsolutePosition.X
            local Persen = math.clamp(RelX / SliderSpeedFrame.AbsoluteSize.X, 0, 1)
            local Val = tonumber(string.format("%.1f", Persen * 10)) if Val < 0.5 then Val = 0.5 end
            _G.KecepatanPutar = Val Config.KecepatanPutar = Val
            LabelSpeed.Text = "ORBIT SPEED: " .. string.format("%.1f", Val) .. " X"
            SliderSpeedButton.Position = UDim2.new(Persen - 0.04, 0, -0.6, 0)
        end
    end
end)

-- INTERACTION CONFIG CLICKS
ManualSaveButton.MouseButton1Click:Connect(function()
    SinkronisasiConfig("SAVE")
    StatusLogLabel.Text = "Status: File Berhasil Disimpan!\nJalur: /" .. FileNama
    StatusLogLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    task.spawn(function() task.wait(3.0) StatusLogLabel.Text = "Status: Ready\nFile: YasirConfig.json" StatusLogLabel.TextColor3 = Color3.fromRGB(200, 200, 200) end)
end)

ManualLoadButton.MouseButton1Click:Connect(function()
    SinkronisasiConfig("LOAD")
    _G.AutoFarm = Config.AutoFarm
    _G.AutoSkill = Config.AutoSkill
    _G.RadiusPutar = Config.RadiusPutar
    _G.TinggiMelayang = Config.TinggiMelayang
    _G.KecepatanPutar = Config.KecepatanPutar
    _G.UndergroundMode = Config.UndergroundMode
    _G.AutoReplay = Config.AutoReplay
    _G.KillAuraRadius = _G.TinggiMelayang + 25
    RefreshTampilanUI()
    StatusLogLabel.Text = "Status: Config Dimuat!\nRadius: " .. tostring(_G.RadiusPutar) .. " | Speed: " .. tostring(_G.KecepatanPutar)
    StatusLogLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    task.spawn(function() task.wait(3.0) StatusLogLabel.Text = "Status: Ready\nFile: YasirConfig.json" StatusLogLabel.TextColor3 = Color3.fromRGB(200, 200, 200) end)
end)

MasterButton.MouseButton1Click:Connect(function()
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    if _G.AutoFarm then
        _G.AutoFarm = false Config.AutoFarm = false MasterButton.Text = "SCRIPT: OFF" MasterButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0) Target = nil
        if MyRoot then MyRoot.CFrame = MyRoot.CFrame * CFrame.new(0, 100, 0) end
    else
        Target = nil _G.AutoFarm = true Config.AutoFarm = true MasterButton.Text = "SCRIPT: ON" MasterButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0) 
    end
    SinkronisasiConfig("SAVE")
end)

ModeButton.MouseButton1Click:Connect(function()
    if _G.UndergroundMode then _G.UndergroundMode = false Config.UndergroundMode = false ModeButton.Text = "MODE: SKY FLIGHT" ModeButton.BackgroundColor3 = Color3.fromRGB(135, 0, 255) else _G.UndergroundMode = true Config.UndergroundMode = true ModeButton.Text = "MODE: UNDERGROUND" ModeButton.BackgroundColor3 = Color3.fromRGB(0, 85, 255) end
    SinkronisasiConfig("SAVE")
end)

ReplayButtonToggle.MouseButton1Click:Connect(function()
    _G.AutoReplay = not _G.AutoReplay Config.AutoReplay = _G.AutoReplay
    if _G.AutoReplay then ReplayButtonToggle.Text = "AUTO REPLAY: YES" ReplayButtonToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 75) else ReplayButtonToggle.Text = "AUTO REPLAY: NO" ReplayButtonToggle.BackgroundColor3 = Color3.fromRGB(180, 40, 40) end
    SinkronisasiConfig("SAVE")
end)