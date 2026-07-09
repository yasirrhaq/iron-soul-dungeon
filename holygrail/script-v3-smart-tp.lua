-- ====================================================================
-- IRON SOUL - ULTIMATE REWRITTEN FARM (V20 MASTER + REPLAY TOGGLE BUTTON)
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
local FileNama = FolderNama .. "/YasirConfigV3.json"

local Config = {
    TinggiMelayang = 5,
    UndergroundMode = true,
    AutoReplay = true,
    PerfectForge = true
}

local function ClampNumber(value, minimum, maximum, fallback)
    value = tonumber(value)
    if not value then return fallback end
    return math.clamp(value, minimum, maximum)
end

local function LoadConfig()
    if readfile and isfile and isfile(FileNama) then
        local BerhasilBaca, IsiFile = pcall(function() return readfile(FileNama) end)
        if BerhasilBaca then
            local BerhasilDecode, Data = pcall(function() return HttpService:JSONDecode(IsiFile) end)
            if BerhasilDecode and type(Data) == "table" then
                for Key, Value in pairs(Data) do
                    if Config[Key] ~= nil then Config[Key] = Value end
                end
            end
        end
    end

    Config.TinggiMelayang = ClampNumber(Config.TinggiMelayang, 5, 100, 5)
    Config.UndergroundMode = Config.UndergroundMode ~= false
    Config.AutoReplay = Config.AutoReplay ~= false
    Config.PerfectForge = Config.PerfectForge ~= false
end

local function SaveConfig()
    Config.TinggiMelayang = _G.TinggiMelayang
    Config.UndergroundMode = _G.UndergroundMode
    Config.AutoReplay = _G.AutoReplay
    Config.PerfectForge = _G.PerfectForge
    local Berhasil, HasilJSON = pcall(function() return HttpService:JSONEncode(Config) end)
    if Berhasil and writefile then
        pcall(function()
            if makefolder then makefolder(FolderNama) end
            writefile(FileNama, HasilJSON)
        end)
    end
end

LoadConfig()

-- KONTROL SCRIPT MASTER
_G.AutoFarm = true          
_G.AutoSkill = true
_G.RadiusPutar = 6          
_G.TinggiMelayang = Config.TinggiMelayang
_G.KecepatanPutar = 4.0     
_G.UndergroundMode = Config.UndergroundMode
_G.KillAuraRadius = _G.TinggiMelayang + 40
_G.AutoProgressStage = true  
_G.AutoReplay = Config.AutoReplay -- Mengontrol status replay otomatis secara global
_G.SemiGodMode = true        
_G.PerfectForge = Config.PerfectForge

local SudutPutar = 0
local Target = nil
local TargetKind = nil
local IsEgg = false
local IsExtractingEgg = false
local LastTriggeredEgg = nil
local EggLockEnd = 0
local ChestDestroyedCount = 0
local EggTriggeredCount = 0
local CountedBreakables = {}
local CountedEggTriggers = {}
local StatsLabel = nil

local LastJumpTime = 0
local JumpInterval = 0.1 
local LastPortalCheck = 0
local IsEnteringPortal = false 
local PortalCooldown = false 
local LastEnemySeen = os.clock()

local MaxPortalDistance = 250 
local RaycastParamsInstance = RaycastParams.new()
RaycastParamsInstance.FilterType = Enum.RaycastFilterType.Exclude

-- =========================================================================
-- SYSTEM UTILITY: [BARU] PERFECT FORGE MODULE VIA METAMETHOD INJECTION
-- =========================================================================
local envRegistry = getfenv()
local setBypass = envRegistry["hookmetamethod"]
local getMethod = envRegistry["getnamecallmethod"]

local oldCallback
oldCallback = setBypass(game, "__namecall", function(self, ...)
    local method = getMethod()
    local args = {...}
    
    -- Hanya berjalan jika fitur di UI bernilai TRUE dan memanggil Remote ForgeRF
    if _G.PerfectForge and self.Name == "ForgeRF" then
        for i, arg in pairs(args) do
            if type(arg) == "table" and arg.Rating ~= nil then
                arg.Rating = 15 -- Memaksa rating perfect otomatis
            end
        end
    end
    
    return oldCallback(self, unpack(args))
end)

local function UpdateStatsLabel()
    if StatsLabel then
        StatsLabel.Text = "CHEST DESTROYED: " .. ChestDestroyedCount .. "\nEGG TRIGGERED: " .. EggTriggeredCount
    end
end

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

local function TriggerPrompt(prompt)
    if not prompt then return false end
    if fireproximityprompt then
        fireproximityprompt(prompt)
        return true
    end

    prompt:InputHoldBegin()
    task.wait((prompt.HoldDuration or 3) + 0.1)
    prompt:InputHoldEnd()
    return true
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
local LastUsed = {Q = 0, E = 0, R = 0, G = 0}
local Cooldowns = {Q = 1, E = 3, R = 5, G = 7} 

task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoFarm and _G.AutoSkill and LocalPlayer.Character and Target and not IsExtractingEgg then
            local CurrentTime = os.clock()
            if (CurrentTime - LastUsed.Q) >= Cooldowns.Q then PressKey("Q") LastUsed.Q = CurrentTime end
            if (CurrentTime - LastUsed.E) >= Cooldowns.E then PressKey("E") LastUsed.E = CurrentTime end
            if (CurrentTime - LastUsed.R) >= Cooldowns.R then PressKey("R") LastUsed.R = CurrentTime end
            if (CurrentTime - LastUsed.G) >= Cooldowns.G then PressKey("G") LastUsed.G = CurrentTime end
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
local function TrackBreakableTarget(target, kind)
    if kind ~= "breakable" or not target then return end
    local trackTarget = target:FindFirstAncestorWhichIsA("Model") or target
    if CountedBreakables[trackTarget] then return end
    CountedBreakables[trackTarget] = true
    local counted = false
    trackTarget.Destroying:Connect(function()
        if not counted then
            counted = true
            ChestDestroyedCount = ChestDestroyedCount + 1
            UpdateStatsLabel()
        end
    end)
end

local function TrackEggTarget(target, kind)
    if kind ~= "egg" or not target then return end
    local eggModel = target:FindFirstAncestor("DragonEgg") or target:FindFirstAncestorWhichIsA("Model")
    if not eggModel or CountedEggTriggers[eggModel] then return end
    CountedEggTriggers[eggModel] = true
    eggModel:GetAttributeChangedSignal("Active"):Connect(function()
        if eggModel:GetAttribute("Active") then
            EggTriggeredCount = EggTriggeredCount + 1
            UpdateStatsLabel()
        end
    end)
    if eggModel:GetAttribute("Active") then
        EggTriggeredCount = EggTriggeredCount + 1
        UpdateStatsLabel()
    end
end

local function GetEggModel(target)
    return target and (target:FindFirstAncestor("DragonEgg") or target:FindFirstAncestorWhichIsA("Model")) or nil
end

local function GetEggPrompt(target)
    local eggModel = GetEggModel(target)
    return eggModel and eggModel:FindFirstChildWhichIsA("ProximityPrompt", true) or nil
end

local function GetTargetPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true) end
    return obj:FindFirstChildWhichIsA("BasePart", true)
end

local function ScanWorldTarget(myRoot)
    local DragonEgg = workspace:FindFirstChild("DragonEgg")
    if DragonEgg and not DragonEgg:GetAttribute("Broken") then
        local part = GetTargetPart(DragonEgg)
        if part then return part, "egg" end
    end

    local bestTarget = nil
    local bestDistance = math.huge
    local children = workspace:GetChildren()
    for i = 1, #children do
        local obj = children[i]
        local part = string.match(obj.Name, "^Chest") and GetTargetPart(obj) or nil
        if part then
            local distance = (myRoot.Position - part.Position).Magnitude
            if distance < bestDistance then
                bestDistance = distance
                bestTarget = part
            end
        end
    end
    return bestTarget, bestTarget and "breakable" or nil
end

local function MoveToEggGround(target)
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    local MyHumanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if not MyRoot or not MyHumanoid then return false end

    RaycastParamsInstance.FilterDescendantsInstances = {target.Parent, Character}
    local GroundRay = workspace:Raycast(target.Position + Vector3.new(0, 8, 0), Vector3.new(0, -35, 0), RaycastParamsInstance)
    local GroundPos = GroundRay and GroundRay.Position or target.Position
    MyRoot.CFrame = CFrame.new(GroundPos + Vector3.new(0, 3, 0), target.Position)
    MyRoot.Velocity = Vector3.new(0, 0, 0)
    MyHumanoid:ChangeState(Enum.HumanoidStateType.Running)
    task.wait(0.35)
    return true
end

local function GetClosestTargetZeroSpike()
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return nil, false end

    local NewTarget = nil
    local ClosestDistance = math.huge
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
            end
        end
    end
    if NewTarget then return NewTarget, "enemy" end

    return ScanWorldTarget(MyRoot)
end

local function TriggerEggIfNeeded(target, kind)
    if kind ~= "egg" or IsExtractingEgg then return end
    if LastTriggeredEgg == target and os.clock() < EggLockEnd then return end
    IsExtractingEgg = true
    if not MoveToEggGround(target) then
        IsExtractingEgg = false
        return
    end
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot or (MyRoot.Position - target.Position).Magnitude > 24 then
        IsExtractingEgg = false
        return
    end

    LastTriggeredEgg = target
    local Prompt = GetEggPrompt(target)
    if Prompt then
        print("[Egg] Triggering ProximityPrompt...")
        TriggerPrompt(Prompt)
    else
        print("[Egg] Prompt not found. Holding F 3s fallback...")
        HoldKey("F", 3.0)
    end
    IsExtractingEgg = false
    EggLockEnd = os.clock() + 12.0
end

-- =========================================================================
-- [FINAL PERFECT VERSION] AUTO WAVE TRIGGER & STAGE PORTAL PROGRESSION
-- =========================================================================
local LastWaveTriggerAttempt = 0
local LastMapPath = "" -- Menyimpan nama map terakhir untuk deteksi Play Again

local function TeleportToNextStagePortal()
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    local MyHumanoid = Character and Character:FindFirstChild("Humanoid")
    if not MyRoot or not MyHumanoid then return end

    -- DETEKSI PLAY AGAIN (Reset gembok jika mendeteksi perubahan/muat ulang map baru)
    local CurrentWorld = workspace:FindFirstChild("World")
    local CurrentMapPath = CurrentWorld and CurrentWorld:GetFullName() or ""
    if CurrentMapPath ~= LastMapPath then
        LastMapPath = CurrentMapPath
        PortalCooldown = false
        IsEnteringPortal = false
        print("🔄 [System] Map Baru Terdeteksi / Play Again. Reset State Cooldown!")
    end

    -- Jika script beneran sedang transisi loading screen, baru return
    if PortalCooldown or not _G.AutoProgressStage or IsEnteringPortal then return end 

    -- DETEKSI JIKA KITA SEDANG DI ENDLESS TOWER / TRIAL
    local IsEndlessTower = false
    if CurrentWorld and CurrentWorld:FindFirstChild("Start") then
        IsEndlessTower = true
    end

    -- Cek keberadaan TouchInterest aktif di folder Wave terlebih dahulu
    local WaveSpawnTouch = workspace:FindFirstChild("WaveSpawnTouch")
    local HasActiveWaveInterest = false
    
    if WaveSpawnTouch then
        for _, zone in pairs(WaveSpawnTouch:GetChildren()) do
            if zone:IsA("BasePart") and zone:FindFirstChildOfClass("TouchInterest") then
                HasActiveWaveInterest = true
                break
            end
        end
    end

    -- =====================================================================
    -- STEP 1: TRIGGER SENSOR WAVE (Agresif, Radius Luas, Kunci Tinggi Tanah)
    -- =====================================================================
    if WaveSpawnTouch and HasActiveWaveInterest then 
        local ActiveTouchZone = nil
        local ClosestZoneDist = math.huge
        
        for _, zone in pairs(WaveSpawnTouch:GetChildren()) do
            if zone:IsA("BasePart") and zone:FindFirstChildOfClass("TouchInterest") then
                local dist = (MyRoot.Position - zone.Position).Magnitude
                if dist < ClosestZoneDist and dist <= 9999 then
                    ClosestZoneDist = dist
                    ActiveTouchZone = zone
                end
            end
        end
        
        if ActiveTouchZone then
            print("🌊 [SmartTrigger] Mengunci Wave Aktif via TouchInterest: " .. ActiveTouchZone.Name)
            
            local TargetPosition = Vector3.new(ActiveTouchZone.Position.X, MyRoot.Position.Y, ActiveTouchZone.Position.Z)
            MyRoot.CFrame = CFrame.new(TargetPosition)
            MyRoot.Velocity = Vector3.new(0, 0, 0)
            
            if firetouchinterest then
                firetouchinterest(MyRoot, ActiveTouchZone, 0)
                task.wait(0.02)
                firetouchinterest(MyRoot, ActiveTouchZone, 1)
            end
            
            task.wait(0.5)
            return -- Keluar penuh agar tidak mengecek portal
        end
    end

    -- =====================================================================
    -- STEP 2: SCANNING PORTAL (HANYA BERJALAN JIKA SENSOR WAVE BENAR-BENAR KOSONG)
    -- =====================================================================
    -- KUNCI AMAN: Jika di area masih ada TouchInterest Wave, JANGAN CARI PORTAL!
    if HasActiveWaveInterest then return end

    local BestPortalPart = nil
    local HighestScore = 0
    local ClosestDistance = math.huge
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            local HasTrigger = obj:FindFirstChildOfClass("TouchTransmitter") or obj:FindFirstChildOfClass("ProximityPrompt")
            
            if HasTrigger then
                local DistanceToPortal = (MyRoot.Position - obj.Position).Magnitude
                if DistanceToPortal <= MaxPortalDistance then
                    local CurrentScore = 0
                    local LowerName = string.lower(obj.Name)
                    local ParentName = obj.Parent and string.lower(obj.Parent.Name) or ""
                    
                    if string.find(LowerName, "collide") then
                        CurrentScore = -100
                    end
                    if IsEndlessTower and string.find(LowerName, "mapteleport") then
                        CurrentScore = -100
                    end
                    
                    if CurrentScore >= 0 then
                        if string.find(LowerName, "portal") or string.find(ParentName, "portal") or 
                           string.find(LowerName, "door") or string.find(ParentName, "door") or 
                           string.find(LowerName, "gate") or string.find(LowerName, "pintu") then
                            
                            CurrentScore = CurrentScore + 10 
                        elseif string.find(LowerName, "next") or string.find(LowerName, "exit") or string.find(LowerName, "finish") or string.find(LowerName, "teleport") then
                            CurrentScore = CurrentScore + 4
                        end
                        
                        CurrentScore = CurrentScore + 3 
                        if LowerName == "root" then CurrentScore = CurrentScore + 2 end 
                        if obj.Material == Enum.Material.Neon then CurrentScore = CurrentScore + 2 end
                        if obj.Size.Y > 4 and obj.Size.X > 4 then CurrentScore = CurrentScore + 1 end
                    end
                    
                    if CurrentScore > HighestScore then
                        HighestScore = CurrentScore
                        BestPortalPart = obj
                        ClosestDistance = DistanceToPortal
                    elseif CurrentScore == HighestScore and CurrentScore > 0 then
                        if DistanceToPortal < ClosestDistance then
                            BestPortalPart = obj
                            ClosestDistance = DistanceToPortal
                        end
                    end
                end
            end
        end
    end

    local RequiredScore = 10
    if IsEndlessTower then RequiredScore = 3 end

    if BestPortalPart and HighestScore >= RequiredScore then
        IsEnteringPortal = true
        PortalCooldown = true 
        print("🚪 [Portal] Sukses Mengunci Portal Utama: " .. BestPortalPart:GetFullName() .. " (Skor: " .. HighestScore .. ")")
        
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
            task.wait(8.0) 
            PortalCooldown = false
        end)
    else
        if IsEndlessTower then
            IsEnteringPortal = false
            PortalCooldown = false
        end
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
                    TrackBreakableTarget(NewTarget, NewTargetKind)
                    TrackEggTarget(NewTarget, NewTargetKind)
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

RunService.Heartbeat:Connect(function(dt)
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    local MyHumanoid = Character and Character:FindFirstChild("Humanoid")
    if not MyRoot or not MyHumanoid or IsEnteringPortal or not _G.AutoFarm then return end
    if IsExtractingEgg then return end
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
local ForgeButtonToggle = Instance.new("TextButton") -- [BARU] Tombol UI Perfect Forge
local LabelHeight = Instance.new("TextLabel")
local SliderHeightFrame = Instance.new("Frame")
local SliderHeightButton = Instance.new("TextButton")
StatsLabel = Instance.new("TextLabel")

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
ModeButton.BackgroundColor3 = _G.UndergroundMode and Color3.fromRGB(0, 85, 255) or Color3.fromRGB(135, 0, 255)
ModeButton.Position = UDim2.new(0.05, 0, 0.27, 0)         
ModeButton.Size = UDim2.new(0, 160, 0, 40)               
ModeButton.Font = Enum.Font.SourceSansBold
ModeButton.Text = _G.UndergroundMode and "MODE: UNDERGROUND" or "MODE: ABOVE MONSTER"
ModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeButton.TextSize = 14
ModeButton.BorderSizePixel = 2

-- 3. [BARU] Tombol Kontrol Replay (AUTO REPLAY: YES / NO)
ReplayButtonToggle.Name = "ReplayButtonToggle"
ReplayButtonToggle.Parent = ScreenGui
ReplayButtonToggle.BackgroundColor3 = _G.AutoReplay and Color3.fromRGB(0, 150, 75) or Color3.fromRGB(180, 40, 40) -- Hijau gelap bawaan aktif
ReplayButtonToggle.Position = UDim2.new(0.05, 0, 0.34, 0) -- Berada tepat di bawah tombol mode        
ReplayButtonToggle.Size = UDim2.new(0, 160, 0, 40)               
ReplayButtonToggle.Font = Enum.Font.SourceSansBold
ReplayButtonToggle.Text = _G.AutoReplay and "AUTO REPLAY: YES" or "AUTO REPLAY: NO"
ReplayButtonToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
ReplayButtonToggle.TextSize = 14
ReplayButtonToggle.BorderSizePixel = 2

LabelHeight.Name = "LabelHeight"
LabelHeight.Parent = ScreenGui
LabelHeight.Size = UDim2.new(0, 160, 0, 16)
LabelHeight.Position = UDim2.new(0.05, 0, 0.41, 0)
LabelHeight.BackgroundTransparency = 1
LabelHeight.Font = Enum.Font.SourceSansBold
LabelHeight.Text = "HEIGHT DISTANCE: " .. tostring(_G.TinggiMelayang) .. " STUDS"
LabelHeight.TextColor3 = Color3.fromRGB(255, 255, 255)
LabelHeight.TextSize = 12

SliderHeightFrame.Name = "SliderHeightFrame"
SliderHeightFrame.Parent = ScreenGui
SliderHeightFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
SliderHeightFrame.Position = UDim2.new(0.05, 0, 0.41, 20)
SliderHeightFrame.Size = UDim2.new(0, 160, 0, 6)
SliderHeightFrame.BorderSizePixel = 0

SliderHeightButton.Name = "SliderHeightButton"
SliderHeightButton.Parent = SliderHeightFrame
SliderHeightButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
SliderHeightButton.Size = UDim2.new(0, 14, 0, 14)
SliderHeightButton.Position = UDim2.new((_G.TinggiMelayang / 100) - 0.04, 0, -0.6, 0)
SliderHeightButton.Text = ""

-- 4. [BARU] Tombol Kontrol Perfect Forge (PERFECT FORGE: YES / NO)
ForgeButtonToggle.Name = "ForgeButtonToggle"
ForgeButtonToggle.Parent = ScreenGui
ForgeButtonToggle.BackgroundColor3 = _G.PerfectForge and Color3.fromRGB(150, 120, 0) or Color3.fromRGB(120, 30, 30) -- Warna Emas/Oranye gelap bawaan aktif
ForgeButtonToggle.Position = UDim2.new(0.05, 0, 0.41, 40) -- Berada tepat di bawah slider Height        
ForgeButtonToggle.Size = UDim2.new(0, 160, 0, 40)               
ForgeButtonToggle.Font = Enum.Font.SourceSansBold
ForgeButtonToggle.Text = _G.PerfectForge and "PERFECT FORGE: YES" or "PERFECT FORGE: NO"
ForgeButtonToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
ForgeButtonToggle.TextSize = 14
ForgeButtonToggle.BorderSizePixel = 2

StatsLabel.Name = "StatsLabel"
StatsLabel.Parent = ScreenGui
StatsLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
StatsLabel.BackgroundTransparency = 0.15
StatsLabel.Position = UDim2.new(0.05, 0, 0.41, 88)
StatsLabel.Size = UDim2.new(0, 160, 0, 48)
StatsLabel.Font = Enum.Font.SourceSansBold
StatsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatsLabel.TextSize = 13
StatsLabel.BorderSizePixel = 2
UpdateStatsLabel()

local function RefreshHeightSlider()
    LabelHeight.Text = "HEIGHT DISTANCE: " .. tostring(_G.TinggiMelayang) .. " STUDS"
    SliderHeightButton.Position = UDim2.new((_G.TinggiMelayang / 100) - 0.04, 0, -0.6, 0)
end

local function SetHeightPercent(percent)
    _G.TinggiMelayang = math.max(5, math.floor(percent * 100))
    _G.KillAuraRadius = _G.TinggiMelayang + 40
    RefreshHeightSlider()
end

local ActiveSlider = nil

local function IsSliderInput(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function SliderPercent(input)
    return math.clamp((input.Position.X - SliderHeightFrame.AbsolutePosition.X) / SliderHeightFrame.AbsoluteSize.X, 0, 1)
end

local function UpdateActiveSlider(input)
    if ActiveSlider == "HEIGHT" then
        SetHeightPercent(SliderPercent(input))
    end
end

SliderHeightButton.InputBegan:Connect(function(input)
    if IsSliderInput(input) then
        ActiveSlider = "HEIGHT"
        UpdateActiveSlider(input)
    end
end)

SliderHeightFrame.InputBegan:Connect(function(input)
    if IsSliderInput(input) then
        ActiveSlider = "HEIGHT"
        UpdateActiveSlider(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if IsSliderInput(input) and ActiveSlider then
        ActiveSlider = nil
        SaveConfig()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if ActiveSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateActiveSlider(input)
    end
end)

-- KONEKSI EVENT INTERAKSI KLIK UI
MasterButton.MouseButton1Click:Connect(function()
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    if _G.AutoFarm then
        _G.AutoFarm = false
        MasterButton.Text = "SCRIPT: OFF"
        MasterButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0) 
        Target = nil
        TargetKind = nil
        IsEgg = false
        if MyRoot then
            local SkyY = MyRoot.Position.Y + 150
            MyRoot.CFrame = CFrame.new(MyRoot.Position.X, SkyY, MyRoot.Position.Z)
        end
    else
        Target = nil 
        TargetKind = nil
        IsEgg = false
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
    SaveConfig()
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
    SaveConfig()
end)

-- [BARU] Event handler untuk klik tombol Perfect Forge
ForgeButtonToggle.MouseButton1Click:Connect(function()
    _G.PerfectForge = not _G.PerfectForge
    if _G.PerfectForge then
        ForgeButtonToggle.Text = "PERFECT FORGE: YES"
        ForgeButtonToggle.BackgroundColor3 = Color3.fromRGB(150, 120, 0) -- Oranye/Emas saat aktif
    else
        ForgeButtonToggle.Text = "PERFECT FORGE: NO"
        ForgeButtonToggle.BackgroundColor3 = Color3.fromRGB(120, 30, 30) -- Merah tua saat mati
    end
    SaveConfig()
end)
