-- ====================================================================
-- IRON SOUL - ULTIMATE REWRITTEN FARM (V20 MASTER + REPLAY TOGGLE BUTTON)
-- ====================================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

-- KONTROL SCRIPT MASTER
_G.AutoFarm = true          
_G.AutoSkill = true
_G.RadiusPutar = 6          
_G.TinggiMelayang = 5        
_G.KecepatanPutar = 4.0     
_G.UndergroundMode = true   
_G.KillAuraRadius = 45      
_G.AutoProgressStage = true  
_G.AutoReplay = true         -- Mengontrol status replay otomatis secara global
_G.SemiGodMode = true        

local SudutPutar = 0
local Target = nil
local TargetKind = nil
local IsEgg = false
local IsExtractingEgg = false
local LastTriggeredEgg = nil
local EggLockEnd = 0

local LastJumpTime = 0
local JumpInterval = 0.1 
local LastPortalCheck = 0
local IsEnteringPortal = false 
local PortalCooldown = false 
local LastEnemySeen = os.clock()

local MaxPortalDistance = 250 

-- 1. FUNGSI ANTI-AFK
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

local function HoldKey(key, seconds)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    end)
    task.wait(seconds)
    pcall(function()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end)
end

-- FUNGSI HIT TOMBOL REPLAY VIA GUI SELECTION
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

-- AUTO SKILL DENGAN COOLDOWN
local LastUsed = {Q = 0, E = 0, R = 0}
local Cooldowns = {Q = 1, E = 3, R = 5} 

task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoFarm and _G.AutoSkill and LocalPlayer.Character and Target and not IsExtractingEgg then
            local CurrentTime = os.clock()
            if (CurrentTime - LastUsed.Q) >= Cooldowns.Q then PressKey("Q") LastUsed.Q = CurrentTime end
            if (CurrentTime - LastUsed.E) >= Cooldowns.E then PressKey("E") LastUsed.E = CurrentTime end
            if (CurrentTime - LastUsed.R) >= Cooldowns.R then PressKey("R") LastUsed.R = CurrentTime end
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

-- STATE-GLITCH IMMUNITY LOOP
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

-- 3. SCANNING TARGET INTERNAL
local function GetClosestTargetZeroSpike()
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return nil, false end

    local NewTarget = nil
    local ClosestDistance = math.huge
    local BreakableTarget = nil
    local BreakableKind = nil
    local ClosestBreakableDistance = math.huge
    local SemuaObjek = workspace:GetDescendants()

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
            else
                local nameLower = string.lower(obj.Name)
                local kind = nil
                if string.find(nameLower, "egg") then
                    kind = "egg"
                elseif string.find(nameLower, "chest") or string.find(nameLower, "box") or string.find(nameLower, "crate") or string.find(nameLower, "barrel") then
                    kind = "breakable"
                end
                if kind then
                    local BreakableRoot = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                    if BreakableRoot then
                        local Distance = (MyRoot.Position - BreakableRoot.Position).Magnitude
                        if Distance < ClosestBreakableDistance then
                            ClosestBreakableDistance = Distance
                            BreakableTarget = BreakableRoot
                            BreakableKind = kind
                        end
                    end
                end
            end
        elseif obj:IsA("BasePart") and not obj:IsDescendantOf(Character) then
            local nameLower = string.lower(obj.Name)
            if obj.Parent then nameLower = nameLower .. " " .. string.lower(obj.Parent.Name) end
            local kind = nil
            if string.find(nameLower, "egg") then
                kind = "egg"
            elseif string.find(nameLower, "chest") or string.find(nameLower, "box") or string.find(nameLower, "crate") or string.find(nameLower, "barrel") then
                kind = "breakable"
            end
            if kind then
                local ParentModel = obj:FindFirstAncestorWhichIsA("Model")
                if not ParentModel or not ParentModel:FindFirstChildOfClass("Humanoid") then
                    local Distance = (MyRoot.Position - obj.Position).Magnitude
                    if Distance < ClosestBreakableDistance then
                        ClosestBreakableDistance = Distance
                        BreakableTarget = obj
                        BreakableKind = kind
                    end
                end
            end
        end
    end
    if NewTarget then return NewTarget, "enemy" end
    return BreakableTarget, BreakableKind
end

local function TriggerEggIfNeeded(target, kind)
    if kind ~= "egg" or IsExtractingEgg then return end
    if LastTriggeredEgg == target and os.clock() < EggLockEnd then return end

    LastTriggeredEgg = target
    IsExtractingEgg = true
    print("[Egg] Holding F 3s to trigger damage absorb...")
    HoldKey("F", 3.0)
    IsExtractingEgg = false
    EggLockEnd = os.clock() + 12.0
end

-- DETEKSI OTOMATIS DAN PEMBUKA PINTU / STAGE PORTAL
local function TeleportToNextStagePortal()
    if PortalCooldown or not _G.AutoProgressStage then return end 
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    local MyHumanoid = Character and Character:FindFirstChild("Humanoid")
    if not MyRoot or not MyHumanoid or IsEnteringPortal then return end

    local BestPortalPart = nil
    local HighestScore = 0
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            local DistanceToPortal = (MyRoot.Position - obj.Position).Magnitude
            if DistanceToPortal <= MaxPortalDistance then
                local CurrentScore = 0
                local LowerName = string.lower(obj.Name)
                
                if string.find(LowerName, "portal") or string.find(LowerName, "gate") or string.find(LowerName, "door") or string.find(LowerName, "pintu") then
                    CurrentScore = CurrentScore + 6
                elseif string.find(LowerName, "next") or string.find(LowerName, "exit") or string.find(LowerName, "finish") or string.find(LowerName, "teleport") then
                    CurrentScore = CurrentScore + 4
                end
                
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

    if BestPortalPart and HighestScore >= 3 then
        IsEnteringPortal = true
        PortalCooldown = true 
        MyRoot.CFrame = CFrame.new(BestPortalPart.Position)
        
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        
        task.wait(0.2) 
        MyRoot.Velocity = Vector3.new(0, 0, 0)
        IsEnteringPortal = false
        
        task.spawn(function()
            task.wait(3.0) 
            PortalCooldown = false
        end)
    end
end

-- INTERCEPTOR SCAN REPLAY DEEP AREA
local function IsGuiVisible(obj)
    if not obj or not obj.Parent then return false end
    if obj:IsA("GuiObject") and (not obj.Visible or obj.AbsolutePosition.Y <= 0) then return false end
    local parent = obj.Parent
    while parent and parent ~= game do
        if parent:IsA("GuiObject") and not parent.Visible then return false end
        parent = parent.Parent
    end
    return true
end

local function HasVictoryUi(guiObjects)
    for i = 1, #guiObjects do
        local obj = guiObjects[i]
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            if IsGuiVisible(obj) and string.find(string.lower(obj.Text), "victory") then
                return true
            end
        end
    end
    return false
end

local function FindVisibleButtonByText(guiObjects, textPattern)
    for i = 1, #guiObjects do
        local obj = guiObjects[i]
        if obj:IsA("TextButton") then
            local nameLower = string.lower(obj.Name)
            local textLower = string.lower(obj.Text)
            if IsGuiVisible(obj) and (string.find(nameLower, textPattern) or string.find(textLower, textPattern)) then
                return obj
            end
        elseif obj:IsA("ImageButton") then
            local nameLower = string.lower(obj.Name)
            if IsGuiVisible(obj) and string.find(nameLower, textPattern) then
                return obj
            end
        elseif obj:IsA("TextLabel") then
            local textLower = string.lower(obj.Text)
            if IsGuiVisible(obj) and string.find(textLower, textPattern) then
                local parentButton = obj:FindFirstAncestorWhichIsA("TextButton") or obj:FindFirstAncestorWhichIsA("ImageButton") or obj.Parent
                if IsGuiVisible(parentButton) then return parentButton end
            end
        end
    end
    return nil
end

local function HasVisibleText(guiObjects, textPattern)
    for i = 1, #guiObjects do
        local obj = guiObjects[i]
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            if IsGuiVisible(obj) and string.find(string.lower(obj.Text), textPattern) then
                return true
            end
        end
    end
    return false
end

local function ScanAndHandleDeath()
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not PlayerGui then return end
    local SemuaGui = PlayerGui:GetDescendants()
    if not HasVisibleText(SemuaGui, "you died") then return end

    local GiveUpButton = FindVisibleButtonByText(SemuaGui, "give up")
    if GiveUpButton then
        print("[Auto Death] You died detected. Clicking Give up...")
        Target = nil
        EksekusiKlikReplay(GiveUpButton)
        task.wait(5.0)
    end
end

local function ScanAndExecuteReplay()
    if not _G.AutoReplay then return end
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not PlayerGui then return end
    
    local ReplayButton = nil
    local SemuaGui = PlayerGui:GetDescendants()
    if not HasVictoryUi(SemuaGui) then return end
    
    for i = 1, #SemuaGui do
        local obj = SemuaGui[i]
        
        if obj:IsA("TextLabel") then
            local textLower = string.lower(obj.Text)
            if string.find(textLower, "play") and string.find(textLower, "again") then
                local parentButton = obj:FindFirstAncestorWhichIsA("TextButton") or obj:FindFirstAncestorWhichIsA("ImageButton") or obj.Parent
                if IsGuiVisible(parentButton) then
                    ReplayButton = parentButton
                    break
                end
            end
        elseif obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local nameLower = string.lower(obj.Name)
            if string.find(nameLower, "replay") or string.find(nameLower, "again") or string.find(nameLower, "restart") then
                if IsGuiVisible(obj) then
                    ReplayButton = obj
                    break
                end
            end
        end
    end
    
    if ReplayButton then
        print("[Auto Replay] Reward settle delay sebelum re-run...")
        Target = nil
        task.wait(5.0)

        if HasVictoryUi(PlayerGui:GetDescendants()) and IsGuiVisible(ReplayButton) then
            print("[Auto Replay] Target Tombol Terkunci. Mengeksekusi Re-Run...")
            EksekusiKlikReplay(ReplayButton)
            task.wait(8.0)
        end
    end
end

task.spawn(function()
    while true do
        if _G.AutoFarm then
            if IsEgg and Target and Target.Parent and os.clock() < EggLockEnd then
                LastEnemySeen = os.clock()
                task.wait(0.5)
            else
                local Success, NewTarget, NewTargetKind = pcall(GetClosestTargetZeroSpike)
                if Success and NewTarget then
                    LastEnemySeen = os.clock()
                    Target = NewTarget
                    TargetKind = NewTargetKind
                    IsEgg = NewTargetKind == "egg"
                    TriggerEggIfNeeded(NewTarget, NewTargetKind)
                    task.wait(0.5) 
                else
                    Target = nil
                    TargetKind = nil
                    IsEgg = false
                    pcall(ScanAndHandleDeath)
                    
                    if _G.AutoReplay then
                        pcall(ScanAndExecuteReplay)
                    end
                    
                    if _G.AutoProgressStage and not IsEnteringPortal and not PortalCooldown then
                        local CurrentTime = os.clock()
                        if (CurrentTime - LastEnemySeen) >= 4.0 and (CurrentTime - LastPortalCheck) >= 1.5 then 
                            LastPortalCheck = CurrentTime
                            pcall(TeleportToNextStagePortal)
                        end
                    end
                    task.wait(0.2)
                end
            end
        else
            Target = nil
            TargetKind = nil
            IsEgg = false
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
    if not Target or not Target.Parent then
        Target = nil
        TargetKind = nil
        IsEgg = false
        return
    end
    if TargetKind == "enemy" then
        local TargetHumanoid = Target.Parent:FindFirstChildOfClass("Humanoid")
        if not TargetHumanoid or TargetHumanoid.Health <= 0 then
            Target = nil
            TargetKind = nil
            IsEgg = false
            return
        end
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
            if part:IsA("BasePart") then 
                part.CanCollide = false 
                if _G.SemiGodMode then
                    local transmitter = part:FindFirstChildOfClass("TouchTransmitter")
                    if transmitter then transmitter:Destroy() end
                end
            end
        end
    end
end)

-- ====================================================================
-- PERBAIKAN & PENAMBAHAN MENU DUAL BUTTON + TOGGLE REPLAY BUTTON
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
local MasterButton = Instance.new("TextButton")
local ModeButton = Instance.new("TextButton")
local ReplayButtonToggle = Instance.new("TextButton") -- [BARU] Tombol Replay Toggle

local OldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("IronSoulDualMenu")
if OldGui then OldGui:Destroy() end

ScreenGui.Name = "IronSoulDualMenu"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- 1. Tombol Utama (SCRIPT ON/OFF)
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

-- 2. Tombol Mode (UNDERGROUND / ABOVE)
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

-- 3. [BARU] Tombol Kontrol Replay (AUTO REPLAY: YES / NO)
ReplayButtonToggle.Name = "ReplayButtonToggle"
ReplayButtonToggle.Parent = ScreenGui
ReplayButtonToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 75) -- Hijau gelap bawaan aktif
ReplayButtonToggle.Position = UDim2.new(0.05, 0, 0.34, 0) -- Berada tepat di bawah tombol mode        
ReplayButtonToggle.Size = UDim2.new(0, 160, 0, 40)               
ReplayButtonToggle.Font = Enum.Font.SourceSansBold
ReplayButtonToggle.Text = "AUTO REPLAY: YES"
ReplayButtonToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
ReplayButtonToggle.TextSize = 14
ReplayButtonToggle.BorderSizePixel = 2

-- KONEKSI EVENT INTERAKSI KLIK UI
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

ReplayButtonToggle.MouseButton1Click:Connect(function()
    _G.AutoReplay = not _G.AutoReplay
    if _G.AutoReplay then
        ReplayButtonToggle.Text = "AUTO REPLAY: YES"
        ReplayButtonToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 75) -- Ganti hijau
    else
        ReplayButtonToggle.Text = "AUTO REPLAY: NO"
        ReplayButtonToggle.BackgroundColor3 = Color3.fromRGB(180, 40, 40) -- Ganti merah
    end
end)
