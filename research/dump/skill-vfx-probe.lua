-- Skill/VFX runtime probe.
-- Jalankan di executor, langsung tekan Q satu kali, tunggu 15 detik, lalu paste clipboard ke chat.

if type(_G.SkillVfxProbeStop) == "function" then
    pcall(_G.SkillVfxProbeStop)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local State = {
    Active = true,
    Duration = 15,
    MaxLines = 600,
    StartedAt = os.clock(),
    Lines = {},
    Connections = {},
    Watched = {},
    MotorBaseline = {},
    MotorChanged = {},
    LastMotorScanAt = 0
}

local function GetPath(InstanceValue)
    if typeof(InstanceValue) ~= "Instance" then
        return tostring(InstanceValue)
    end
    local Parts = {}
    local Current = InstanceValue
    while Current do
        table.insert(Parts, 1, Current.Name)
        Current = Current.Parent
    end
    return table.concat(Parts, ".")
end

local function Short(Value, Depth)
    Depth = Depth or 0
    if typeof(Value) == "Instance" then
        return GetPath(Value)
    end
    if type(Value) ~= "table" then
        local Text = tostring(Value)
        return #Text > 180 and string.sub(Text, 1, 177) .. "..." or Text
    end
    if Depth >= 2 then
        return "{...}"
    end
    local Parts = {}
    local Count = 0
    for Key, Item in pairs(Value) do
        Count = Count + 1
        if Count > 12 then
            table.insert(Parts, "...")
            break
        end
        table.insert(Parts, tostring(Key) .. "=" .. Short(Item, Depth + 1))
    end
    return "{" .. table.concat(Parts, ",") .. "}"
end

local function Log(Kind, ...)
    if #State.Lines >= State.MaxLines then
        return
    end
    local Parts = {}
    for Index = 1, select("#", ...) do
        Parts[Index] = Short(select(Index, ...))
    end
    local Line = string.format("[SkillVfxProbe][%06.3f][%s] %s", os.clock() - State.StartedAt, Kind,
        table.concat(Parts, " | "))
    table.insert(State.Lines, Line)
    print(Line)
end

local function Connect(Signal, Callback)
    local Connection = Signal:Connect(Callback)
    table.insert(State.Connections, Connection)
    return Connection
end

local function HasEffectName(InstanceValue)
    local Current = InstanceValue
    for _ = 1, 7 do
        if not Current then
            break
        end
        local Name = string.lower(Current.Name or "")
        if string.find(Name, "skill") or string.find(Name, "effect") or string.find(Name, "vfx") or
            string.find(Name, "ability") or string.find(Name, "arrow") or string.find(Name, "rain") or
            string.find(Name, "skywing") or string.find(Name, "fx") then
            return true
        end
        Current = Current.Parent
    end
    return false
end

local function IsVisual(InstanceValue)
    return InstanceValue:IsA("ParticleEmitter") or InstanceValue:IsA("Trail") or InstanceValue:IsA("Beam") or
               InstanceValue:IsA("Smoke") or InstanceValue:IsA("Fire") or InstanceValue:IsA("Sparkles") or
               InstanceValue:IsA("Highlight") or InstanceValue:IsA("Light") or InstanceValue:IsA("Decal") or
               InstanceValue:IsA("Texture") or InstanceValue:IsA("BasePart") or InstanceValue:IsA("Attachment") or
               InstanceValue:IsA("Model")
end

local function ReadProperty(InstanceValue, Property)
    local Success, Value = pcall(function()
        return InstanceValue[Property]
    end)
    return Success and Short(Value) or "<unavailable>"
end

local function WatchProperty(InstanceValue, Property)
    local Success, Signal = pcall(InstanceValue.GetPropertyChangedSignal, InstanceValue, Property)
    if not Success then
        return
    end
    Connect(Signal, function()
        if State.Active then
            Log("PROP", GetPath(InstanceValue), Property .. "=" .. ReadProperty(InstanceValue, Property))
        end
    end)
end

local function WatchVisual(InstanceValue, IsNew)
    if State.Watched[InstanceValue] or not IsVisual(InstanceValue) then
        return
    end
    if (InstanceValue:IsA("BasePart") or InstanceValue:IsA("Attachment") or InstanceValue:IsA("Model")) and
        not HasEffectName(InstanceValue) then
        return
    end
    State.Watched[InstanceValue] = true

    local Details = {"class=" .. InstanceValue.ClassName, "path=" .. GetPath(InstanceValue)}
    if InstanceValue:IsA("Animation") then
        table.insert(Details, "id=" .. tostring(InstanceValue.AnimationId))
    elseif InstanceValue:IsA("BasePart") then
        table.insert(Details, "transparency=" .. ReadProperty(InstanceValue, "Transparency"))
        table.insert(Details, "localTransparency=" .. ReadProperty(InstanceValue, "LocalTransparencyModifier"))
        WatchProperty(InstanceValue, "Transparency")
        WatchProperty(InstanceValue, "LocalTransparencyModifier")
    elseif InstanceValue:IsA("Decal") or InstanceValue:IsA("Texture") then
        table.insert(Details, "transparency=" .. ReadProperty(InstanceValue, "Transparency"))
        WatchProperty(InstanceValue, "Transparency")
    elseif not InstanceValue:IsA("Attachment") and not InstanceValue:IsA("Model") then
        table.insert(Details, "enabled=" .. ReadProperty(InstanceValue, "Enabled"))
        WatchProperty(InstanceValue, "Enabled")
    end
    Log(IsNew and "VFX_NEW" or "VFX_EXISTING", table.concat(Details, " "))
end

local function ScanRoot(Root)
    if not Root then
        return
    end
    WatchVisual(Root, false)
    for _, InstanceValue in ipairs(Root:GetDescendants()) do
        WatchVisual(InstanceValue, false)
        if InstanceValue:IsA("Motor6D") then
            State.MotorBaseline[InstanceValue] = {
                Transform = InstanceValue.Transform,
                C0 = InstanceValue.C0,
                C1 = InstanceValue.C1
            }
        end
    end
end

local function BindAnimator(Character)
    local Humanoid = Character and (Character:FindFirstChildOfClass("Humanoid") or Character:WaitForChild("Humanoid", 5))
    if not Humanoid then
        Log("ERROR", "Humanoid missing")
        return
    end

    for _, Child in ipairs(Humanoid:GetChildren()) do
        if Child:IsA("Animation") and string.find(string.lower(Child.Name), "skill") then
            Log("ANIM_ASSET", GetPath(Child), Child.AnimationId)
        end
    end

    local Animator = Humanoid:FindFirstChildOfClass("Animator") or Humanoid:WaitForChild("Animator", 5)
    if not Animator then
        Log("ERROR", "Animator missing")
        return
    end
    Connect(Animator.AnimationPlayed, function(Track)
        local AnimationId = "<nil>"
        pcall(function()
            AnimationId = Track.Animation.AnimationId
        end)
        Log("ANIM_PLAY", "name=" .. tostring(Track.Name), "id=" .. tostring(AnimationId),
            "priority=" .. tostring(Track.Priority), "length=" .. tostring(Track.Length),
            "weight=" .. tostring(Track.WeightCurrent), "speed=" .. tostring(Track.Speed))
        Connect(Track.KeyframeReached, function(KeyframeName)
            if State.Active then
                Log("KEYFRAME", Track.Name, KeyframeName, "time=" .. tostring(Track.TimePosition))
            end
        end)
        Connect(Track.Stopped, function()
            Log("ANIM_STOP", Track.Name, "time=" .. tostring(Track.TimePosition))
        end)
    end)
end

local function InstallRemoteHook()
    if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then
        Log("REMOTE_HOOK", "unavailable")
        return
    end
    local OldNamecall
    local Callback = function(Self, ...)
        local Method = getnamecallmethod()
        if State.Active and (Method == "FireServer" or Method == "InvokeServer") then
            Log("REMOTE", Method, GetPath(Self), Short({...}))
        end
        return OldNamecall(Self, ...)
    end
    if type(newcclosure) == "function" then
        Callback = newcclosure(Callback)
    end
    local Success, Result = pcall(function()
        OldNamecall = hookmetamethod(game, "__namecall", Callback)
    end)
    Log("REMOTE_HOOK", Success and "installed" or ("failed=" .. tostring(Result)))
end

local function Export(Reason)
    if not State.Active then
        return
    end
    Log("END", Reason, "lines=" .. tostring(#State.Lines))
    State.Active = false
    for _, Connection in ipairs(State.Connections) do
        pcall(Connection.Disconnect, Connection)
    end
    table.clear(State.Connections)
    local Output = table.concat(State.Lines, "\n")
    if type(setclipboard) == "function" then
        setclipboard(Output)
        print("[SkillVfxProbe] copied with setclipboard")
    elseif type(toclipboard) == "function" then
        toclipboard(Output)
        print("[SkillVfxProbe] copied with toclipboard")
    else
        print("[SkillVfxProbe] clipboard unavailable; copy F9 lines manually")
    end
end

_G.SkillVfxProbeStop = function()
    Export("manual stop")
end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
ScanRoot(Character)
ScanRoot(workspace.CurrentCamera)
for _, Root in ipairs(workspace:GetChildren()) do
    if HasEffectName(Root) then
        ScanRoot(Root)
    end
end

Connect(workspace.DescendantAdded, function(InstanceValue)
    if State.Active then
        task.defer(function()
            if State.Active then
                WatchVisual(InstanceValue, true)
            end
        end)
    end
end)

Connect(LocalPlayer.CharacterAdded, function(NewCharacter)
    Log("CHARACTER", "replaced", GetPath(NewCharacter))
    ScanRoot(NewCharacter)
    BindAnimator(NewCharacter)
end)

Connect(RunService.RenderStepped, function()
    if not State.Active or os.clock() - State.LastMotorScanAt < 0.1 then
        return
    end
    State.LastMotorScanAt = os.clock()
    for Motor, Baseline in pairs(State.MotorBaseline) do
        if Motor.Parent and not State.MotorChanged[Motor] and
            (Motor.Transform ~= Baseline.Transform or Motor.C0 ~= Baseline.C0 or Motor.C1 ~= Baseline.C1) then
            State.MotorChanged[Motor] = true
            Log("MOTOR_CHANGED", GetPath(Motor))
        end
    end
end)

BindAnimator(Character)
InstallRemoteHook()
Log("READY", "Tekan Q satu kali sekarang", "capture=" .. tostring(State.Duration) .. "s",
    "animation=rbxassetid://109180965508862")
task.delay(State.Duration, function()
    Export("timeout")
end)
