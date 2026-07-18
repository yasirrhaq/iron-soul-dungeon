-- ====================================================================
-- IRON SOUL SCRIPT V6 BY BUGON
-- ====================================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

print("[Bugon V6] bootstrap started")

local FolderNama = "IronSoulConfig"
local FileNama = FolderNama .. "/YasirConfigV3.json"

local function CopyMap(Source)
    local Result = {}
    for Key, Value in pairs(Source or {}) do
        Result[Key] = Value
    end
    return Result
end

local DefaultAutoBuyWantedItemIds = {
    LuckPotion_1 = true,
    DropPotion_1 = true
}
local DefaultAutoSeasonBuyWantedItemIds = {
    SeasonTicket = true
}
local DefaultOreSellModes = {
    Corundum = "SELL",
    Heatshell = "SELL",
    Gwindel = "SELL",
    Blackhole = "KEEP",
    BloodHeart = "KEEP",
    Apocalypse = "KEEP",
    DarkBlossom = "KEEP"
}
local AutoForgeRarityFilter = 0
local AutoSellRarityFilter = 0
local AutoForge = {
    Recipes = {
        WeaponSword = {Label = "Sword", Category = "Weapon", OreCount = 3, Chance = 100},
        WeaponStaff = {Label = "Staff", Category = "Weapon", OreCount = 10, Chance = 80},
        WeaponAxeHammer = {Label = "Axe/Hammer", Category = "Weapon", OreCount = 16, Chance = 100},
        WeaponFist = {Label = "Fist", Category = "Weapon", OreCount = 18, Chance = 5},
        WeaponFistCommon = {Label = "Fist + Common Relic", Category = "Weapon", OreCount = 18, Chance = 20, RelicId = "FistRelic_1"},
        WeaponFistLuxury = {Label = "Fist + Luxury Relic", Category = "Weapon", OreCount = 18, Chance = 58, RelicId = "FistRelic_2"},
        ArmorLightHelmet = {Label = "Light Helmet", Category = "Armor", OreCount = 3, Chance = 100},
        ArmorLightArmor = {Label = "Light Armor", Category = "Armor", OreCount = 10, Chance = 80},
        ArmorHeavyHelmet = {Label = "Heavy Helmet", Category = "Armor", OreCount = 15, Chance = 80},
        ArmorHeavyArmor = {Label = "Heavy Armor", Category = "Armor", OreCount = 22, Chance = 100}
    },
    RecipeOrder = {
        "WeaponSword", "WeaponStaff", "WeaponAxeHammer", "WeaponFist", "WeaponFistCommon",
        "WeaponFistLuxury", "ArmorLightHelmet", "ArmorLightArmor", "ArmorHeavyHelmet", "ArmorHeavyArmor"
    },
    RecipeId = nil,
    Composition = nil,
    RequestedCrafts = nil,
    TargetMode = false,
    AutoDeleteNonMatch = false,
    Profiles = {},
    StatCatalog = {},
    DiscoveredStats = {},
    Groups = {
        Offensive = {
            AtkBonus = true,
            CHDmgBonus = true,
            CHIRate = true,
            SkillDmgBonus = true
        }
    },
    TargetFoundData = nil,
    TargetRefresh = nil,
    KeyString = nil,
    State = {
        Running = false,
        Status = "IDLE",
        Completed = 0,
        Planned = 0,
        Refresh = nil,
        Token = {Alive = true}
    }
}
local AutoPotion = {
    ScanInterval = 15,
    QueueSpacing = 0.65,
    ConfirmTimeout = 5,
    DungeonGraceSeconds = 10,
    Selected = nil,
    Catalog = {},
    Order = {},
    ByBuffId = {},
    Pending = {},
    ActivationPending = {},
    RetryOnScan = {},
    Queue = {},
    Queued = {},
    Connections = {},
    LifecycleConnections = {},
    WorkerRunning = false,
    ScanGeneration = 0,
    GraceGeneration = 0,
    GraceStartedAt = nil,
    GraceCharacter = nil,
    GraceAttrEntry = nil,
    LastRequestAt = -math.huge,
    Status = "OFF",
    Refresh = nil,
    Token = {Alive = true}
}
local AutoBuyWantedItemIds = nil
local AutoSeasonBuyWantedItemIds = nil
local SellMaxRarity = nil
local OreSellModes = nil

local Config = {
    TinggiMelayang = 5,
    UndergroundMode = true,
    AutoReplay = true,
    AutoGiveup = true,
    PerfectForge = true,
    AutoBuy = false,
    AutoSell = false,
    AutoSeasonBuy = false,
    AutoForge = false,
    AutoPotion = false,
    AutoPotionSelected = {},
    AutoBuyWantedItemIds = CopyMap(DefaultAutoBuyWantedItemIds),
    AutoSeasonBuyWantedItemIds = CopyMap(DefaultAutoSeasonBuyWantedItemIds),
    AutoForgeRecipeId = "WeaponSword",
    AutoForgeOreComposition = {},
    AutoForgeRequestedCrafts = 1,
    AutoForgeTargetMode = false,
    AutoForgeAutoDeleteNonMatch = false,
    AutoForgeProfiles = {},
    SellMaxRarity = 5,
    AutoStartWorldId = "World3",
    AutoStartDifficulty = 10,
    AutoRejoin = true,
    LobbyPlaceId = 0,
    RecoveryPending = false,
    RejoinAttemptTimestamps = {},
    OreSellModes = CopyMap(DefaultOreSellModes)
}

local AutoStartWorldId = Config.AutoStartWorldId
local AutoStartDifficulty = Config.AutoStartDifficulty

local function ClampNumber(value, minimum, maximum, fallback)
    value = tonumber(value)
    if not value then
        return fallback
    end
    return math.clamp(value, minimum, maximum)
end

local function NormalizeEnabledMap(Value, Fallback)
    if type(Value) ~= "table" then
        return CopyMap(Fallback)
    end

    local Result = {}
    for Key, Enabled in pairs(Value) do
        if type(Key) == "string" and Enabled == true then
            Result[Key] = true
        end
    end
    return Result
end

local function NormalizeOreSellModes(Value)
    if type(Value) ~= "table" then
        return CopyMap(DefaultOreSellModes)
    end

    local Result = {}
    for OreId, Mode in pairs(Value) do
        if type(OreId) == "string" and (Mode == "AUTO" or Mode == "SELL" or Mode == "KEEP") then
            if Mode ~= "AUTO" then
                Result[OreId] = Mode
            end
        end
    end
    return Result
end

function AutoForge.NormalizeComposition(Value)
    local Result = {}
    if type(Value) ~= "table" then
        return Result
    end
    for ItemId, Count in pairs(Value) do
        Count = math.floor(tonumber(Count) or 0)
        if type(ItemId) == "string" and Count > 0 then
            Result[ItemId] = Count
        end
    end
    return Result
end

function AutoForge.NormalizeStatId(AttributeKey)
    if type(AttributeKey) ~= "string" or AttributeKey == "" then
        return nil
    end
    return string.split(AttributeKey, "_")[1]
end

function AutoForge.GetDefaultPoolStats()
    return {"AtkBonus", "CHDmgBonus", "CHIRate", "SkillDmgBonus"}
end

function AutoForge.CreateDefaultProfile(Index)
    return {
        Id = HttpService:GenerateGUID(false),
        Name = "Profile " .. tostring(Index or 1),
        Enabled = false,
        SlotMode = "Any",
        SlotCount = 1,
        PoolPreset = "Offensive",
        PoolStats = AutoForge.GetDefaultPoolStats(),
        Rules = {{Kind = "PoolAtLeast", MinCount = 3}}
    }
end

function AutoForge.BuildPoolLookup(PoolStats)
    local Lookup = {}
    for _, StatId in ipairs(type(PoolStats) == "table" and PoolStats or {}) do
        if type(StatId) == "string" and StatId ~= "" then
            Lookup[AutoForge.NormalizeStatId(StatId) or StatId] = true
        end
    end
    return Lookup
end

function AutoForge.NormalizeProfile(Profile, Index)
    local Source = type(Profile) == "table" and Profile or {}
    local Result = AutoForge.CreateDefaultProfile(Index)
    Result.Id = type(Source.Id) == "string" and Source.Id or Result.Id
    Result.Name = type(Source.Name) == "string" and Source.Name or Result.Name
    Result.Enabled = Source.Enabled == true
    Result.SlotMode = Source.SlotMode == "Exact" and "Exact" or (Source.SlotMode == "AtLeast" and "AtLeast" or "Any")
    Result.SlotCount = math.floor(ClampNumber(Source.SlotCount, 1, 10, 1))
    Result.PoolPreset = type(Source.PoolPreset) == "string" and Source.PoolPreset or "Offensive"
    Result.PoolStats = {}
    local PoolSeen = {}
    local function PushPoolStat(StatId)
        StatId = AutoForge.NormalizeStatId(StatId)
        if StatId and not PoolSeen[StatId] then
            PoolSeen[StatId] = true
            table.insert(Result.PoolStats, StatId)
        end
    end
    for _, StatId in ipairs(type(Source.PoolStats) == "table" and Source.PoolStats or {}) do
        PushPoolStat(StatId)
    end
    local HasLegacyRules = false
    for _, SourceRule in ipairs(type(Source.Rules) == "table" and Source.Rules or {}) do
        if type(SourceRule) == "table" and (SourceRule.Kind == "Specific" or SourceRule.Kind == "TotalGroup" or SourceRule.Kind == "AdditionalGroup" or SourceRule.Kind == "AllSlotsGroup") then
            HasLegacyRules = true
            break
        end
    end
    if #Result.PoolStats <= 0 and (Result.PoolPreset == "Offensive" or HasLegacyRules) then
        for _, StatId in ipairs(AutoForge.GetDefaultPoolStats()) do
            PushPoolStat(StatId)
        end
    end
    Result.Rules = {}
    local RequireByStat = {}
    local PoolRuleAdded = false
    for _, SourceRule in ipairs(type(Source.Rules) == "table" and Source.Rules or {}) do
        if type(SourceRule) == "table" then
            local Kind = SourceRule.Kind
            local MinCount = math.floor(ClampNumber(SourceRule.MinCount, 1, 10, 1))
            if Kind == "RequireStat" or Kind == "Specific" then
                local StatId = AutoForge.NormalizeStatId(SourceRule.StatId)
                if StatId then
                    local Existing = RequireByStat[StatId]
                    if Existing then
                        Existing.MinCount = math.max(Existing.MinCount, MinCount)
                    else
                        local Rule = {Kind = "RequireStat", StatId = StatId, MinCount = MinCount}
                        RequireByStat[StatId] = Rule
                        table.insert(Result.Rules, Rule)
                    end
                end
            elseif Kind == "PoolAtLeast" or Kind == "TotalGroup" or Kind == "AdditionalGroup" then
                if not PoolRuleAdded then
                    PoolRuleAdded = true
                    table.insert(Result.Rules, {Kind = "PoolAtLeast", MinCount = MinCount})
                end
            elseif Kind == "PoolOnly" or Kind == "AllSlotsGroup" then
                if not PoolRuleAdded then
                    PoolRuleAdded = true
                    table.insert(Result.Rules, {Kind = "PoolOnly"})
                end
            end
        end
    end
    if #Result.Rules <= 0 then
        Result.Rules = {{Kind = "PoolAtLeast", MinCount = 3}}
    end
    return Result
end

function AutoForge.ValidateProfile(Profile)
    if type(Profile) ~= "table" then
        return false, "Invalid profile"
    end
    if Profile.SlotMode ~= "Any" and Profile.SlotMode ~= "Exact" and Profile.SlotMode ~= "AtLeast" then
        return false, "Invalid slot mode"
    end
    if Profile.SlotMode ~= "Any" and (tonumber(Profile.SlotCount) or 0) < 1 then
        return false, "Slot count must be positive"
    end
    if type(Profile.Rules) ~= "table" or #Profile.Rules <= 0 then
        return false, "Add at least one rule"
    end
    local HasPoolRule = false
    local PoolLookup = AutoForge.BuildPoolLookup(Profile.PoolStats)
    for _, Rule in ipairs(Profile.Rules) do
        if Rule.Kind == "RequireStat" then
            if type(Rule.StatId) ~= "string" or Rule.StatId == "" then
                return false, "Require Stat needs a stat"
            end
            if (tonumber(Rule.MinCount) or 0) < 1 or (tonumber(Rule.MinCount) or 0) > 10 then
                return false, "Minimum must be 1-10"
            end
        elseif Rule.Kind == "PoolAtLeast" then
            HasPoolRule = true
            if (tonumber(Rule.MinCount) or 0) < 1 or (tonumber(Rule.MinCount) or 0) > 10 then
                return false, "Minimum must be 1-10"
            end
        elseif Rule.Kind == "PoolOnly" then
            HasPoolRule = true
        else
            return false, "Invalid rule type"
        end
    end
    if HasPoolRule and next(PoolLookup) == nil then
        return false, "Pool needs at least one stat"
    end
    return true
end

function AutoForge.NormalizeProfiles(Value)
    local Profiles = {}
    if type(Value) ~= "table" then
        return Profiles
    end
    for Index, Source in ipairs(Value) do
        local Profile = AutoForge.NormalizeProfile(Source, Index)
        local Valid, ErrorMessage = AutoForge.ValidateProfile(Profile)
        Profile.ValidationError = Valid and nil or ErrorMessage
        Profile.Enabled = Profile.Enabled and Valid
        table.insert(Profiles, Profile)
    end
    return Profiles
end

local function LoadConfig()
    if readfile and isfile and isfile(FileNama) then
        local BerhasilBaca, IsiFile = pcall(function()
            return readfile(FileNama)
        end)
        if BerhasilBaca then
            local BerhasilDecode, Data = pcall(function()
                return HttpService:JSONDecode(IsiFile)
            end)
            if BerhasilDecode and type(Data) == "table" then
                for Key, Value in pairs(Data) do
                    if Config[Key] ~= nil then
                        Config[Key] = Value
                    end
                end
            end
        end
    end

    Config.TinggiMelayang = ClampNumber(Config.TinggiMelayang, 5, 100, 5)
    Config.UndergroundMode = Config.UndergroundMode ~= false
    Config.AutoReplay = Config.AutoReplay ~= false
    Config.AutoGiveup = Config.AutoGiveup ~= false
    Config.PerfectForge = Config.PerfectForge ~= false
    Config.AutoBuy = Config.AutoBuy == true
    Config.AutoSell = Config.AutoSell == true
    Config.AutoSeasonBuy = Config.AutoSeasonBuy == true
    Config.AutoForge = Config.AutoForge == true
    Config.AutoPotion = Config.AutoPotion == true
    Config.AutoPotionSelected = NormalizeEnabledMap(Config.AutoPotionSelected, {})
    Config.AutoBuyWantedItemIds = NormalizeEnabledMap(Config.AutoBuyWantedItemIds, DefaultAutoBuyWantedItemIds)
    Config.AutoSeasonBuyWantedItemIds = NormalizeEnabledMap(Config.AutoSeasonBuyWantedItemIds,
        DefaultAutoSeasonBuyWantedItemIds)
    Config.AutoForgeRecipeId = AutoForge.Recipes[Config.AutoForgeRecipeId] and Config.AutoForgeRecipeId or "WeaponSword"
    Config.AutoForgeOreComposition = AutoForge.NormalizeComposition(Config.AutoForgeOreComposition)
    Config.AutoForgeRequestedCrafts = math.floor(ClampNumber(Config.AutoForgeRequestedCrafts, 1, 999, 1))
    Config.AutoForgeTargetMode = Config.AutoForgeTargetMode == true
    Config.AutoForgeAutoDeleteNonMatch = Config.AutoForgeAutoDeleteNonMatch == true
    Config.AutoForgeProfiles = AutoForge.NormalizeProfiles(Config.AutoForgeProfiles)
    Config.SellMaxRarity = math.floor(ClampNumber(Config.SellMaxRarity, 0, 10, 5))
    Config.AutoStartWorldId = type(Config.AutoStartWorldId) == "string" and Config.AutoStartWorldId or "World3"
    Config.AutoStartDifficulty = math.max(1, math.floor(tonumber(Config.AutoStartDifficulty) or 10))
    Config.AutoRejoin = Config.AutoRejoin ~= false
    Config.LobbyPlaceId = math.max(0, math.floor(tonumber(Config.LobbyPlaceId) or 0))
    Config.RecoveryPending = Config.RecoveryPending == true
    if type(Config.RejoinAttemptTimestamps) ~= "table" then
        Config.RejoinAttemptTimestamps = {}
    else
        local ValidTimestamps = {}
        for _, Timestamp in ipairs(Config.RejoinAttemptTimestamps) do
            Timestamp = tonumber(Timestamp)
            if Timestamp and Timestamp > 0 then
                table.insert(ValidTimestamps, math.floor(Timestamp))
            end
        end
        Config.RejoinAttemptTimestamps = ValidTimestamps
    end
    Config.OreSellModes = NormalizeOreSellModes(Config.OreSellModes)
end

local function SaveConfig()
    Config.TinggiMelayang = _G.TinggiMelayang
    Config.UndergroundMode = _G.UndergroundMode
    Config.AutoReplay = _G.AutoReplay
    Config.AutoGiveup = _G.AutoGiveup
    Config.PerfectForge = _G.PerfectForge
    Config.AutoBuy = _G.AutoBuy
    Config.AutoSell = _G.AutoSell
    Config.AutoSeasonBuy = _G.AutoSeasonBuy
    Config.AutoForge = _G.AutoForge
    Config.AutoPotion = _G.AutoPotion
    Config.AutoPotionSelected = AutoPotion.Selected
    Config.AutoBuyWantedItemIds = AutoBuyWantedItemIds or Config.AutoBuyWantedItemIds
    Config.AutoSeasonBuyWantedItemIds = AutoSeasonBuyWantedItemIds or Config.AutoSeasonBuyWantedItemIds
    Config.AutoForgeRecipeId = AutoForge.RecipeId or Config.AutoForgeRecipeId
    Config.AutoForgeOreComposition = AutoForge.Composition or Config.AutoForgeOreComposition
    Config.AutoForgeRequestedCrafts = AutoForge.RequestedCrafts or Config.AutoForgeRequestedCrafts
    Config.AutoForgeTargetMode = AutoForge.TargetMode
    Config.AutoForgeAutoDeleteNonMatch = AutoForge.AutoDeleteNonMatch
    Config.AutoForgeProfiles = AutoForge.Profiles
    Config.SellMaxRarity = SellMaxRarity or Config.SellMaxRarity
    Config.AutoStartWorldId = AutoStartWorldId or Config.AutoStartWorldId
    Config.AutoStartDifficulty = AutoStartDifficulty or Config.AutoStartDifficulty
    Config.AutoRejoin = _G.AutoRejoin
    Config.OreSellModes = OreSellModes or Config.OreSellModes
    local Berhasil, HasilJSON = pcall(function()
        return HttpService:JSONEncode(Config)
    end)
    if Berhasil and writefile then
        pcall(function()
            if makefolder then
                makefolder(FolderNama)
            end
            writefile(FileNama, HasilJSON)
        end)
    end
end

LoadConfig()
AutoStartWorldId = Config.AutoStartWorldId
AutoStartDifficulty = Config.AutoStartDifficulty
AutoForge.RecipeId = Config.AutoForgeRecipeId
AutoForge.Composition = Config.AutoForgeOreComposition
AutoForge.RequestedCrafts = Config.AutoForgeRequestedCrafts
AutoForge.TargetMode = Config.AutoForgeTargetMode
AutoForge.AutoDeleteNonMatch = Config.AutoForgeAutoDeleteNonMatch
AutoForge.Profiles = Config.AutoForgeProfiles
AutoPotion.Selected = Config.AutoPotionSelected

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
_G.AutoGiveup = Config.AutoGiveup
_G.SemiGodMode = true
_G.PerfectForge = Config.PerfectForge
_G.AutoBuy = Config.AutoBuy
_G.AutoSell = Config.AutoSell
_G.AutoSeasonBuy = Config.AutoSeasonBuy
_G.AutoForge = Config.AutoForge
_G.AutoPotion = Config.AutoPotion
_G.AutoRejoin = Config.AutoRejoin

if _G.BugonAutoPotionRuntime and _G.BugonAutoPotionRuntime.Shutdown then
    pcall(_G.BugonAutoPotionRuntime.Shutdown)
end
_G.BugonAutoPotionRuntime = AutoPotion

local SudutPutar = 0
local Target = nil
local TargetKind = nil
local IsEgg = false
local IsExtractingEgg = false
local LastTriggeredEgg = nil
local EggLockEnd = 0
local ChestDestroyedCount = 0
local EggTriggeredCount = 0
local OreStats = {
    Current = 0,
    Max = 0,
    RejoinStatus = ""
}
local CountedBreakables = {}
local CountedEggTriggers = {}
local StatsLabel = nil

local LastJumpTime = 0
local JumpInterval = 0.1
local LastPortalCheck = 0
local IsEnteringPortal = false
local PortalCooldown = false
local LastEnemySeen = os.clock()

local MaxPortalDistance = 600
local RaycastParamsInstance = RaycastParams.new()
RaycastParamsInstance.FilterType = Enum.RaycastFilterType.Exclude
AutoBuyWantedItemIds = Config.AutoBuyWantedItemIds
AutoSeasonBuyWantedItemIds = Config.AutoSeasonBuyWantedItemIds
local AutoBuyDelay = 0.55
local AutoSeasonBuyDelay = 1.0
SellMaxRarity = Config.SellMaxRarity
OreSellModes = Config.OreSellModes
local AutoSellDelay = 5.0
local AutoSellContextDelay = 0.25
local AutoSellBusy = false
local ConsumableShopUtilModule = nil
local ConsumableShopRemoteEvent = nil
local SeasonShopRemoteEvent = nil
local SeasonShopConfig = nil
local SeasonUtilModule = nil
local TaskRemoteEvent = nil
local LastSeasonShopOpenRequest = 0
local LastSeasonShopStateLogAt = 0
local LastAutoSellContextRequest = 0
local FrameworkModule = nil
local ForgeRemoteFunction = nil
local WorldRemoteEvent = nil
local GameMatchRemoteEvent = nil
local GameEnumModule = nil
local SellPending = false
local SellPendingReason = nil
local LastOreBackpackFullLogAt = 0
local LastAutoStartDungeonAt = 0
local LastAutoStartRetryAt = 0
local AutoStartDungeonDelay = 10.0
local AutoStartRetryDelay = 3.0
local AutoStartMaxPlayers = 1
local AutoStartPending = false
local IsInLobby = nil

if _G.BugonAutoForgeToken then
    _G.BugonAutoForgeToken.Alive = false
end
_G.BugonAutoForgeToken = AutoForge.State.Token
local RejoinWatchdog = {
    LoadingTimeout = 60,
    RetryDelays = {15, 30, 60},
    AttemptWindow = 600,
    MaxAttempts = 3,
    FallbackScanInterval = 30,
    Status = Config.RecoveryPending and "WAIT LOBBY" or "IDLE",
    LoadingSince = nil,
    RecoveryActive = false,
    RecoverySource = nil,
    NextAttemptAt = nil,
    Finalizing = false,
    HardStuck = false,
    ReconnectClicked = false,
    TeleportText = nil,
    ReconnectButton = nil,
    LastFallbackScanAt = -math.huge,
    SignalsBound = false,
    PromptGuiBound = nil,
    PendingSince = Config.RecoveryPending and os.clock() or nil,
    LogFile = "Bugon-teleport-log.txt",
    Token = {
        Alive = true
    }
}

if _G.BugonRejoinWatchdogToken then
    _G.BugonRejoinWatchdogToken.Alive = false
end
_G.BugonRejoinWatchdogToken = RejoinWatchdog.Token

function RejoinWatchdog.Log(EventName, Detail)
    local Line = string.format("[%s] %s place=%s job=%s%s\n", os.date("!%Y-%m-%dT%H:%M:%SZ"),
        tostring(EventName), tostring(game.PlaceId), tostring(game.JobId),
        Detail and (" " .. tostring(Detail)) or "")
    print("[AutoRejoin] " .. tostring(EventName) .. (Detail and (" " .. tostring(Detail)) or ""))
    pcall(function()
        if appendfile then
            appendfile(RejoinWatchdog.LogFile, Line)
        elseif writefile then
            local Existing = ""
            if readfile and isfile and isfile(RejoinWatchdog.LogFile) then
                Existing = readfile(RejoinWatchdog.LogFile)
            end
            writefile(RejoinWatchdog.LogFile, Existing .. Line)
        end
    end)
end

function RejoinWatchdog.IsGuiVisible(Object)
    if not Object or not Object.Parent then
        return false
    end
    local Current = Object
    while Current and Current ~= game do
        if Current:IsA("GuiObject") and not Current.Visible then
            return false
        end
        if Current:IsA("LayerCollector") and not Current.Enabled then
            return false
        end
        Current = Current.Parent
    end
    return true
end

function RejoinWatchdog.FindVisibleText(Root, Pattern)
    if not Root then
        return nil
    end
    local HiddenMatch = nil
    for _, Object in ipairs(Root:GetDescendants()) do
        if (Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox")) and
            string.find(string.lower(tostring(Object.Text)), Pattern, 1, true) then
            if RejoinWatchdog.IsGuiVisible(Object) then
                return Object
            end
            HiddenMatch = HiddenMatch or Object
        end
    end
    return HiddenMatch
end

function RejoinWatchdog.FindReconnectButton()
    local function Scan(Root)
        if not Root then
            return nil
        end
        for _, Object in ipairs(Root:GetDescendants()) do
            if Object:IsA("GuiButton") and RejoinWatchdog.IsGuiVisible(Object) then
                local Text = Object:IsA("TextButton") and Object.Text or ""
                local SearchText = string.lower(Object.Name .. " " .. tostring(Text))
                if string.find(SearchText, "reconnect", 1, true) then
                    return Object
                end
            elseif (Object:IsA("TextLabel") or Object:IsA("TextButton")) and
                RejoinWatchdog.IsGuiVisible(Object) and
                string.find(string.lower(tostring(Object.Text)), "reconnect", 1, true) then
                local Button = Object:FindFirstAncestorWhichIsA("GuiButton")
                if Button then
                    return Button
                end
            end
        end
        return nil
    end

    local Success, CoreGui = pcall(game.GetService, game, "CoreGui")
    if not Success then
        return nil
    end
    local RobloxPromptGui = CoreGui:FindFirstChild("RobloxPromptGui")
    local PromptOverlay = RobloxPromptGui and RobloxPromptGui:FindFirstChild("promptOverlay")
    return Scan(PromptOverlay)
end

function RejoinWatchdog.TrackGuiObject(Object)
    if not _G.AutoRejoin or not Object then
        return
    end
    if (Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox")) and
        string.find(string.lower(tostring(Object.Text)), "teleporting", 1, true) then
        RejoinWatchdog.TeleportText = Object
    end
    local ReconnectButton = nil
    if Object:IsA("GuiButton") then
        local Text = Object:IsA("TextButton") and Object.Text or ""
        local SearchText = string.lower(Object.Name .. " " .. tostring(Text))
        if string.find(SearchText, "reconnect", 1, true) then
            ReconnectButton = Object
        end
    elseif Object:IsA("TextLabel") or Object:IsA("TextButton") then
        if string.find(string.lower(tostring(Object.Text)), "reconnect", 1, true) then
            ReconnectButton = Object:FindFirstAncestorWhichIsA("GuiButton")
        end
    end
    if ReconnectButton then
        RejoinWatchdog.ReconnectButton = ReconnectButton
    end
end

function RejoinWatchdog.RefreshCachedTargets(Force)
    if not _G.AutoRejoin then
        return
    end
    local CurrentTime = os.clock()
    if not Force and CurrentTime - RejoinWatchdog.LastFallbackScanAt < RejoinWatchdog.FallbackScanInterval then
        return
    end
    RejoinWatchdog.LastFallbackScanAt = CurrentTime
    if not RejoinWatchdog.TeleportText or not RejoinWatchdog.TeleportText.Parent or
        not RejoinWatchdog.IsGuiVisible(RejoinWatchdog.TeleportText) then
        RejoinWatchdog.TeleportText = RejoinWatchdog.FindVisibleText(LocalPlayer:FindFirstChild("PlayerGui"), "teleporting")
    end
    if not RejoinWatchdog.ReconnectButton or not RejoinWatchdog.ReconnectButton.Parent or
        not RejoinWatchdog.IsGuiVisible(RejoinWatchdog.ReconnectButton) then
        RejoinWatchdog.ReconnectButton = RejoinWatchdog.FindReconnectButton()
    end
end

function RejoinWatchdog.BindPromptGui(RobloxPromptGui)
    if not RobloxPromptGui or RejoinWatchdog.PromptGuiBound == RobloxPromptGui then
        return
    end
    RejoinWatchdog.PromptGuiBound = RobloxPromptGui
    for _, Object in ipairs(RobloxPromptGui:GetDescendants()) do
        RejoinWatchdog.TrackGuiObject(Object)
    end
    RobloxPromptGui.DescendantAdded:Connect(function(Object)
        if RejoinWatchdog.Token.Alive then
            RejoinWatchdog.TrackGuiObject(Object)
        end
    end)
end

function RejoinWatchdog.BindGuiSignals()
    if RejoinWatchdog.SignalsBound then
        return
    end
    RejoinWatchdog.SignalsBound = true
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    PlayerGui.DescendantAdded:Connect(function(Object)
        if RejoinWatchdog.Token.Alive then
            RejoinWatchdog.TrackGuiObject(Object)
        end
    end)
    local Success, CoreGui = pcall(game.GetService, game, "CoreGui")
    if Success then
        RejoinWatchdog.BindPromptGui(CoreGui:FindFirstChild("RobloxPromptGui"))
        CoreGui.ChildAdded:Connect(function(Child)
            if RejoinWatchdog.Token.Alive and Child.Name == "RobloxPromptGui" then
                RejoinWatchdog.BindPromptGui(Child)
            end
        end)
    end
    RejoinWatchdog.RefreshCachedTargets(true)
end

function RejoinWatchdog.ClickButton(Button)
    if not Button or not RejoinWatchdog.IsGuiVisible(Button) then
        return false
    end
    local Position = Button.AbsolutePosition + (Button.AbsoluteSize / 2)
    VirtualInputManager:SendMouseButtonEvent(Position.X, Position.Y, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(Position.X, Position.Y, 0, false, game, 0)
    if firesignal then
        pcall(firesignal, Button.Activated)
    end
    return true
end

function RejoinWatchdog.PruneAttempts()
    local Now = os.time()
    local Valid = {}
    for _, Timestamp in ipairs(Config.RejoinAttemptTimestamps or {}) do
        if Now - Timestamp < RejoinWatchdog.AttemptWindow then
            table.insert(Valid, Timestamp)
        end
    end
    Config.RejoinAttemptTimestamps = Valid
    return #Valid
end

function RejoinWatchdog.MarkHardStuck(Reason)
    RejoinWatchdog.HardStuck = true
    RejoinWatchdog.RecoveryActive = false
    RejoinWatchdog.NextAttemptAt = nil
    RejoinWatchdog.Finalizing = false
    RejoinWatchdog.Status = "HARD STUCK"
    RejoinWatchdog.Log("HARD_STUCK", Reason)
end

function RejoinWatchdog.ScheduleNextAttempt()
    local AttemptCount = RejoinWatchdog.PruneAttempts()
    if AttemptCount >= RejoinWatchdog.MaxAttempts then
        RejoinWatchdog.Finalizing = true
        RejoinWatchdog.NextAttemptAt = os.clock() + RejoinWatchdog.RetryDelays[#RejoinWatchdog.RetryDelays]
        RejoinWatchdog.Status = "WAIT FINAL"
        return
    end
    local Delay = RejoinWatchdog.RetryDelays[AttemptCount + 1]
    RejoinWatchdog.NextAttemptAt = os.clock() + Delay
    RejoinWatchdog.Status = "WAIT " .. tostring(Delay) .. "S"
end

function RejoinWatchdog.BeginRecovery(Source, ReconnectButton)
    if not _G.AutoRejoin then
        if RejoinWatchdog.Status ~= "DETECTED (OFF)" then
            RejoinWatchdog.Log("RECOVERY_DETECTED_OFF", Source)
        end
        RejoinWatchdog.Status = "DETECTED (OFF)"
        return
    end
    if not RejoinWatchdog.RecoveryActive then
        RejoinWatchdog.Log("RECOVERY_DETECTED", Source)
        RejoinWatchdog.RecoveryActive = true
        RejoinWatchdog.RecoverySource = Source
        RejoinWatchdog.HardStuck = false
        Config.RecoveryPending = true
        RejoinWatchdog.PendingSince = RejoinWatchdog.PendingSince or os.clock()
        SaveConfig()
    end
    if ReconnectButton and not RejoinWatchdog.ReconnectClicked then
        RejoinWatchdog.ReconnectClicked = RejoinWatchdog.ClickButton(ReconnectButton)
        if RejoinWatchdog.ReconnectClicked then
            RejoinWatchdog.Status = "RECONNECT"
            RejoinWatchdog.Log("RECONNECT_CLICKED", Source)
        end
    end
    if not RejoinWatchdog.NextAttemptAt then
        RejoinWatchdog.ScheduleNextAttempt()
    end
end

function RejoinWatchdog.AttemptLobbyTeleport()
    if not RejoinWatchdog.RecoveryActive or RejoinWatchdog.HardStuck then
        return
    end
    if Config.LobbyPlaceId <= 0 then
        RejoinWatchdog.RecoveryActive = false
        RejoinWatchdog.Status = "NO LOBBY ID"
        RejoinWatchdog.Log("LOBBY_ID_MISSING")
        return
    end
    local AttemptCount = RejoinWatchdog.PruneAttempts()
    if AttemptCount >= RejoinWatchdog.MaxAttempts then
        RejoinWatchdog.MarkHardStuck("attempt limit")
        return
    end
    local AttemptNumber = AttemptCount + 1
    table.insert(Config.RejoinAttemptTimestamps, os.time())
    SaveConfig()
    RejoinWatchdog.NextAttemptAt = nil
    RejoinWatchdog.Status = "RETRY " .. tostring(AttemptNumber) .. "/" .. tostring(RejoinWatchdog.MaxAttempts)
    RejoinWatchdog.Log("LOBBY_TELEPORT", "attempt=" .. tostring(AttemptNumber))
    local Success, ErrorMessage = pcall(function()
        TeleportService:Teleport(Config.LobbyPlaceId, LocalPlayer)
    end)
    if not Success then
        RejoinWatchdog.Log("TELEPORT_CALL_FAILED", ErrorMessage)
    end
    RejoinWatchdog.ScheduleNextAttempt()
end

function RejoinWatchdog.BlocksAutomation()
    return _G.AutoRejoin and (RejoinWatchdog.RecoveryActive or RejoinWatchdog.HardStuck)
end

function RejoinWatchdog.Tick()
    local CurrentTime = os.clock()
    if not _G.AutoRejoin then
        RejoinWatchdog.LoadingSince = nil
        RejoinWatchdog.Status = "OFF"
        return
    end
    RejoinWatchdog.RefreshCachedTargets(false)
    local TeleportText = RejoinWatchdog.TeleportText
    if TeleportText and (not TeleportText.Parent or not RejoinWatchdog.IsGuiVisible(TeleportText) or
        not string.find(string.lower(tostring(TeleportText.Text)), "teleporting", 1, true)) then
        TeleportText = nil
        RejoinWatchdog.TeleportText = nil
    end
    local ReconnectButton = RejoinWatchdog.ReconnectButton
    if ReconnectButton and (not ReconnectButton.Parent or not RejoinWatchdog.IsGuiVisible(ReconnectButton)) then
        ReconnectButton = nil
        RejoinWatchdog.ReconnectButton = nil
    end

    if ReconnectButton then
        RejoinWatchdog.BeginRecovery("DISCONNECT", ReconnectButton)
    end

    if TeleportText then
        RejoinWatchdog.LoadingSince = RejoinWatchdog.LoadingSince or CurrentTime
        local Elapsed = CurrentTime - RejoinWatchdog.LoadingSince
        if not RejoinWatchdog.RecoveryActive then
            RejoinWatchdog.Status = "LOADING " .. tostring(math.floor(Elapsed)) .. "/60"
        end
        if Elapsed >= RejoinWatchdog.LoadingTimeout then
            RejoinWatchdog.BeginRecovery("TELEPORT_TIMEOUT")
        end
    elseif not RejoinWatchdog.RecoveryActive then
        RejoinWatchdog.LoadingSince = nil
        RejoinWatchdog.ReconnectClicked = false
        if not Config.RecoveryPending and not RejoinWatchdog.HardStuck then
            RejoinWatchdog.Status = _G.AutoRejoin and "IDLE" or "OFF"
        end
    end

    if Config.RecoveryPending and not IsInLobby() and not RejoinWatchdog.RecoveryActive and
        CurrentTime - (RejoinWatchdog.PendingSince or CurrentTime) >= 10 then
        RejoinWatchdog.BeginRecovery("PENDING_NOT_LOBBY")
    end

    if RejoinWatchdog.RecoveryActive and RejoinWatchdog.NextAttemptAt and CurrentTime >= RejoinWatchdog.NextAttemptAt then
        if RejoinWatchdog.Finalizing then
            RejoinWatchdog.MarkHardStuck("final grace expired")
        else
            RejoinWatchdog.AttemptLobbyTeleport()
        end
    end
end

TeleportService.TeleportInitFailed:Connect(function(Player, TeleportResult, ErrorMessage, PlaceId)
    if not RejoinWatchdog.Token.Alive or Player ~= LocalPlayer then
        return
    end
    RejoinWatchdog.Log("TELEPORT_INIT_FAILED",
        "result=" .. tostring(TeleportResult) .. " place=" .. tostring(PlaceId) .. " error=" .. tostring(ErrorMessage))
    if RejoinWatchdog.RecoveryActive then
        RejoinWatchdog.ScheduleNextAttempt()
    end
end)

RejoinWatchdog.Log("SESSION_START", "recoveryPending=" .. tostring(Config.RecoveryPending))

local function GetConsumableShopUtilModule()
    if not ConsumableShopUtilModule then
        ConsumableShopUtilModule = ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild(
            "ConsumableShopSystem"):WaitForChild("ConsumableShopUtil")
    end
    return ConsumableShopUtilModule
end

local function GetConsumableShopRemoteEvent()
    if not ConsumableShopRemoteEvent then
        ConsumableShopRemoteEvent = GetConsumableShopUtilModule():WaitForChild("RemoteEvent")
    end
    return ConsumableShopRemoteEvent
end

local function GetConsumableShopUtil()
    return require(GetConsumableShopUtilModule())
end

local function TryAutoBuyGoldShopOnce()
    local Snapshot = GetConsumableShopUtil():GetShopSnapshot(LocalPlayer, "Gold")
    local Items = Snapshot and Snapshot.Items
    if type(Items) ~= "table" then
        return
    end

    local RemoteEvent = GetConsumableShopRemoteEvent()
    for ItemKey, Item in pairs(Items) do
        if type(Item) == "table" and Item.State == "normal" and AutoBuyWantedItemIds[Item.ItemId] then
            print("[AutoBuy] Buying " .. tostring(Item.ItemId) .. " via " .. tostring(ItemKey))
            RemoteEvent:FireServer("BuyShopItem", "Gold", ItemKey)
            task.wait(AutoBuyDelay)
        end
    end
end

task.spawn(function()
    while true do
        task.wait(AutoBuyDelay)
        if _G.AutoBuy and not RejoinWatchdog.BlocksAutomation() then
            pcall(TryAutoBuyGoldShopOnce)
        end
    end
end)

local function GetSeasonShopRemoteEvent()
    if not SeasonShopRemoteEvent then
        SeasonShopRemoteEvent = ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild(
            "SeasonSystem"):WaitForChild("SeasonUtil"):WaitForChild("RemoteEvent")
    end
    return SeasonShopRemoteEvent
end

local function GetSeasonShopConfig()
    if not SeasonShopConfig then
        SeasonShopConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("ResSeasonShop"))
    end
    return SeasonShopConfig
end

local function GetSeasonUtil()
    if not SeasonUtilModule then
        SeasonUtilModule = require(ReplicatedStorage:WaitForChild("Framework")).Modules.SeasonUtil
    end
    return SeasonUtilModule
end

local function GetSeasonShopData()
    return GetSeasonUtil():GetShopData(LocalPlayer)
end

local function RequestSeasonShopOpen()
    local CurrentTime = os.clock()
    if (CurrentTime - LastSeasonShopOpenRequest) < 10.0 then
        return
    end

    LastSeasonShopOpenRequest = CurrentTime
    print("[AutoSeasonBuy] Direct shop state unavailable; requesting ScreenSeasonPass data")
    ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("TaskSystem"):WaitForChild(
        "TaskRE"):FireServer("UpdateTaskProgress", "OpenGUIWindow", "ScreenSeasonPass")
end

local function IsSeasonShopSlotBought(slot)
    local Purchased = slot:FindFirstChild("Purchased")
    if Purchased and Purchased:IsA("GuiObject") and Purchased.Visible then
        return true
    end

    local BuyButton = slot:FindFirstChild("BuyBtn")
    return BuyButton and BuyButton:IsA("GuiObject") and not BuyButton.Visible
end

local function IsSeasonShopIdBought(shopData, shopConfig, shopId)
    local BuyCount = shopData and shopData.BuyCount
    local Count = type(BuyCount) == "table" and tonumber(BuyCount[shopId]) or 0
    local Limit = shopConfig.IsSpecial and tonumber(shopConfig.LimitTimes) or 1
    return Count and Limit and Count >= Limit
end

local function TryBuySeasonShopId(shopData, shopId, source, shouldLogState)
    local ShopConfig = GetSeasonShopConfig()[shopId]
    if not ShopConfig then
        return false
    end

    local IsWanted = AutoSeasonBuyWantedItemIds[ShopConfig.ItemId]
    if shouldLogState or IsWanted then
        print("[AutoSeasonBuy] Loaded season " .. tostring(source) .. " " .. tostring(shopId) .. " item " ..
                  tostring(ShopConfig.ItemId) .. " price " .. tostring(ShopConfig.Price))
    end
    if not IsWanted then
        return false
    end
    if IsSeasonShopIdBought(shopData, ShopConfig, shopId) then
        print("[AutoSeasonBuy] Skip bought " .. tostring(ShopConfig.ItemId) .. " via " .. tostring(shopId))
        return false
    end

    print("[AutoSeasonBuy] Buying " .. tostring(ShopConfig.ItemId) .. " via " .. tostring(shopId))
    GetSeasonShopRemoteEvent():FireServer("BuySeasonShopItem", shopId)
    task.wait(AutoSeasonBuyDelay)
    return true
end

local function TryAutoBuySeasonShopByData()
    local ShopData = GetSeasonShopData()
    if type(ShopData) ~= "table" then
        return false
    end

    local CurrentTime = os.clock()
    local ShouldLogState = (CurrentTime - LastSeasonShopStateLogAt) >= 5.0
    if ShouldLogState then
        LastSeasonShopStateLogAt = CurrentTime
    end

    local FoundTarget = false
    local NormalIds = ShopData.NormalIds
    if type(NormalIds) == "table" then
        for Slot, ShopId in pairs(NormalIds) do
            FoundTarget = TryBuySeasonShopId(ShopData, ShopId, "slot " .. tostring(Slot), ShouldLogState) or FoundTarget
        end
    end
    if ShopData.SpecialId then
        FoundTarget = TryBuySeasonShopId(ShopData, ShopData.SpecialId, "special", ShouldLogState) or FoundTarget
    end
    if not FoundTarget and ShouldLogState then
        print("[AutoSeasonBuy] No target item in season state; wanted RaceSpins or SeasonTicket")
    end
    return true
end

local function TryAutoBuySeasonShopByGui()
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not PlayerGui then
        return false
    end

    local Configs = GetSeasonShopConfig()
    local SeenShopIds = {}
    local HasSeasonShopSlot = false
    local FoundTarget = false
    for _, Obj in pairs(PlayerGui:GetDescendants()) do
        local ShopId = Obj:GetAttribute("ShopId")
        local ShopConfig = type(ShopId) == "string" and Configs[ShopId]
        if ShopConfig and not SeenShopIds[ShopId] then
            HasSeasonShopSlot = true
            SeenShopIds[ShopId] = true
            print("[AutoSeasonBuy] Loaded GUI slot " .. tostring(ShopId) .. " item " .. tostring(ShopConfig.ItemId) ..
                      " price " .. tostring(ShopConfig.Price))
            if AutoSeasonBuyWantedItemIds[ShopConfig.ItemId] and not IsSeasonShopSlotBought(Obj) then
                FoundTarget = true
                print("[AutoSeasonBuy] Buying " .. tostring(ShopConfig.ItemId) .. " via " .. tostring(ShopId))
                GetSeasonShopRemoteEvent():FireServer("BuySeasonShopItem", ShopId)
                task.wait(AutoSeasonBuyDelay)
            end
        end
    end

    if not HasSeasonShopSlot then
        RequestSeasonShopOpen()
    elseif not FoundTarget then
        print("[AutoSeasonBuy] No target item in current GUI shop; wanted RaceSpins or SeasonTicket")
    end
    return HasSeasonShopSlot
end

local function TryAutoBuySeasonShopOnce()
    if TryAutoBuySeasonShopByData() then
        return
    end

    TryAutoBuySeasonShopByGui()
end

task.spawn(function()
    while true do
        task.wait(AutoSeasonBuyDelay)
        if _G.AutoSeasonBuy and not RejoinWatchdog.BlocksAutomation() then
            pcall(TryAutoBuySeasonShopOnce)
        end
    end
end)

local function GetFrameworkModule()
    if not FrameworkModule then
        FrameworkModule = require(ReplicatedStorage:WaitForChild("Framework"))
    end
    return FrameworkModule
end

local function GetForgeRemoteFunction()
    if not ForgeRemoteFunction then
        ForgeRemoteFunction = ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild(
            "ForgeSystem"):WaitForChild("ForgeRF")
    end
    return ForgeRemoteFunction
end

local function GetTaskRemoteEvent()
    if not TaskRemoteEvent then
        TaskRemoteEvent = ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("TaskSystem"):WaitForChild(
            "TaskRE")
    end
    return TaskRemoteEvent
end

local function GetWorldRemoteEvent()
    if not WorldRemoteEvent then
        WorldRemoteEvent = ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Gameplay"):WaitForChild(
            "WorldPlace"):WaitForChild("WorldUtil"):WaitForChild("RemoteEvent")
    end
    return WorldRemoteEvent
end

local function GetGameMatchRemoteEvent()
    if not GameMatchRemoteEvent then
        GameMatchRemoteEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GameMatchRE")
    end
    return GameMatchRemoteEvent
end

local function GetGameEnum()
    if not GameEnumModule then
        GameEnumModule = require(ReplicatedStorage:WaitForChild("Enum"):WaitForChild("GameEnum"))
    end
    return GameEnumModule
end

function AutoForge.GetKeyString()
    if not AutoForge.KeyString then
        AutoForge.KeyString = require(ReplicatedStorage:WaitForChild("Enum"):WaitForChild("KeyString"))
    end
    return AutoForge.KeyString
end

local CachedGoldShopCatalog = nil
local CachedSeasonShopCatalog = nil
local CachedOreCatalog = nil
local DungeonCatalog = (function()
    local Catalog = {}
    local CachedDungeons = nil
    local CachedDifficulties = {}

    local function GetWorldConfig()
        return require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("World"):WaitForChild("ResWorld"))
    end

    local function TranslateConfigName(NameKey, Fallback)
        local DisplayName = nil
        pcall(function()
            DisplayName = GetFrameworkModule().Modules.TranslationUtil:TranslateByKey(NameKey)
        end)
        if type(DisplayName) == "string" and DisplayName ~= "" and DisplayName ~= NameKey then
            return DisplayName
        end
        return tostring(Fallback or NameKey or "Unknown")
    end

    function Catalog.GetDungeonCatalog(ForceRefresh)
        if CachedDungeons and not ForceRefresh then
            return CachedDungeons
        end

        local ResWorld = GetWorldConfig()
        local WorldUtil = GetFrameworkModule().Modules.WorldUtil
        local Result = {}
        for _, WorldKey in ipairs(ResWorld.__index or {}) do
            local Info = ResWorld[WorldKey]
            if type(Info) == "table" and Info.Mode ~= "Lobby" then
                local WorldId = tostring(Info.Id or WorldKey)
                local Unlocked = false
                pcall(function()
                    Unlocked = WorldUtil:IsUnlockWorld(LocalPlayer, WorldId, 1) == true
                end)
                table.insert(Result, {
                    WorldId = WorldId,
                    DisplayName = TranslateConfigName(Info.Name, WorldId),
                    Sort = tonumber(Info.Sort) or math.huge,
                    Unlocked = Unlocked,
                    Info = Info
                })
            end
        end
        table.sort(Result, function(A, B)
            if A.Sort == B.Sort then
                return A.WorldId < B.WorldId
            end
            return A.Sort < B.Sort
        end)
        CachedDungeons = Result
        return Result
    end

    function Catalog.GetDifficultyCatalog(WorldId, ForceRefresh)
        if CachedDifficulties[WorldId] and not ForceRefresh then
            return CachedDifficulties[WorldId]
        end

        local Framework = GetFrameworkModule()
        local WorldUtil = Framework.Modules.WorldUtil
        local RarityTiers = Framework.Modules.RarityTiers
        local Result = {}
        local Seen = {}

        local function AddDifficulty(DiffLevel)
            DiffLevel = tonumber(DiffLevel)
            if not DiffLevel or Seen[DiffLevel] then
                return
            end
            local Success, DiffInfo = pcall(function()
                return WorldUtil:GetWorldDiffInfo(WorldId, DiffLevel)
            end)
            if not Success or type(DiffInfo) ~= "table" then
                return
            end
            Seen[DiffLevel] = true
            local NameSuccess, DifficultyName = pcall(function()
                return RarityTiers:GetDifficultyName(DiffInfo.Difficulty)
            end)
            if not NameSuccess or type(DifficultyName) ~= "string" or not string.find(DifficultyName, "%S") or
                tonumber(DifficultyName) then
                return
            end
            if DiffInfo.Style == "Hell" then
                DifficultyName = "Hell (" .. DifficultyName .. ")"
            end
            DifficultyName = "[" .. tostring(DiffLevel) .. "] " .. DifficultyName
            local Unlocked = false
            pcall(function()
                Unlocked = WorldUtil:IsUnlockWorld(LocalPlayer, WorldId, DiffLevel) == true
            end)
            table.insert(Result, {
                Level = DiffLevel,
                DisplayName = DifficultyName,
                Unlocked = Unlocked,
                Info = DiffInfo
            })
        end

        for DiffLevel = 1, 10 do
            AddDifficulty(DiffLevel)
        end
        local Success, HellList = pcall(function()
            return WorldUtil:GetWorldStyleList(WorldId, "Hell")
        end)
        if Success then
            for _, HellInfo in ipairs(HellList or {}) do
                AddDifficulty(HellInfo.DiffLevel)
            end
        end
        table.sort(Result, function(A, B)
            return A.Level < B.Level
        end)
        CachedDifficulties[WorldId] = Result
        return Result
    end

    function Catalog.FindDungeonEntry(WorldId, ForceRefresh)
        for _, Entry in ipairs(Catalog.GetDungeonCatalog(ForceRefresh)) do
            if Entry.WorldId == WorldId then
                return Entry
            end
        end
    end

    function Catalog.FindHighestUnlockedDifficulty(WorldId, ForceRefresh)
        local Selected = nil
        for _, Entry in ipairs(Catalog.GetDifficultyCatalog(WorldId, ForceRefresh)) do
            if Entry.Unlocked and (not Selected or Entry.Level > Selected.Level) then
                Selected = Entry
            end
        end
        return Selected
    end

    function Catalog.ValidateAutoStartSelection(PreferHighest)
        local Dungeon = Catalog.FindDungeonEntry(AutoStartWorldId, true)
        if not Dungeon or not Dungeon.Unlocked then
            Dungeon = nil
            for _, Entry in ipairs(Catalog.GetDungeonCatalog()) do
                if Entry.Unlocked then
                    Dungeon = Entry
                    break
                end
            end
        end
        if not Dungeon then
            return false
        end

        local CandidateWorldId = Dungeon.WorldId
        local CandidateDifficulty = nil
        if not PreferHighest then
            for _, Entry in ipairs(Catalog.GetDifficultyCatalog(CandidateWorldId, true)) do
                if Entry.Level == AutoStartDifficulty and Entry.Unlocked then
                    CandidateDifficulty = Entry
                    break
                end
            end
        end
        CandidateDifficulty = CandidateDifficulty or Catalog.FindHighestUnlockedDifficulty(CandidateWorldId)
        if not CandidateDifficulty then
            return false
        end

        local Changed = AutoStartWorldId ~= CandidateWorldId or AutoStartDifficulty ~= CandidateDifficulty.Level
        AutoStartWorldId, AutoStartDifficulty = CandidateWorldId, CandidateDifficulty.Level
        if Changed then
            SaveConfig()
        end
        return true
    end

    function Catalog.SelectAutoStartWorld(WorldId)
        local Entry = Catalog.FindDungeonEntry(WorldId, true)
        if not Entry or not Entry.Unlocked then
            return false
        end
        local CandidateDifficulty = Catalog.FindHighestUnlockedDifficulty(Entry.WorldId, true)
        if not CandidateDifficulty then
            return false
        end
        AutoStartWorldId, AutoStartDifficulty = Entry.WorldId, CandidateDifficulty.Level
        SaveConfig()
        return true
    end

    function Catalog.SelectAutoStartDifficulty(DiffLevel)
        for _, Entry in ipairs(Catalog.GetDifficultyCatalog(AutoStartWorldId, true)) do
            if Entry.Level == DiffLevel and Entry.Unlocked then
                AutoStartWorldId, AutoStartDifficulty = AutoStartWorldId, Entry.Level
                SaveConfig()
                return true
            end
        end
        return false
    end

    return Catalog
end)()

local function CatalogValues(ById)
    local Result = {}
    for _, Entry in pairs(ById) do
        table.insert(Result, Entry)
    end
    table.sort(Result, function(A, B)
        local TypeA = tostring(A.ItemType or "")
        local TypeB = tostring(B.ItemType or "")
        if TypeA == TypeB then
            return tostring(A.ItemId) < tostring(B.ItemId)
        end
        return TypeA < TypeB
    end)
    return Result
end

local function GetGoldShopCatalog(ForceRefresh)
    if CachedGoldShopCatalog and not ForceRefresh then
        return CachedGoldShopCatalog
    end

    local ShopUtil = GetConsumableShopUtil()
    local ById = {}
    local function AddItem(ItemKey, Item)
        if type(Item) ~= "table" or type(Item.ItemId) ~= "string" then
            return
        end
        local Existing = ById[Item.ItemId]
        if not Existing then
            ById[Item.ItemId] = {
                ItemId = Item.ItemId,
                ItemType = Item.ItemType,
                Price = Item.Price,
                StockMin = Item.StockMin or Item.Stock,
                StockMax = Item.StockMax or Item.Stock,
                ItemKey = ItemKey
            }
        end
    end

    local FullPool = nil
    if getupvalues and type(ShopUtil.BuyItem) == "function" then
        pcall(function()
            local Upvalues = getupvalues(ShopUtil.BuyItem)
            local ShopItems = type(Upvalues) == "table" and Upvalues[2]
            FullPool = type(ShopItems) == "table" and ShopItems.Gold or nil
        end)
    end

    if type(FullPool) == "table" then
        for _, ItemKey in ipairs(FullPool.__index or {}) do
            AddItem(ItemKey, FullPool[ItemKey])
        end
        for ItemKey, Item in pairs(FullPool) do
            if ItemKey ~= "__index" then
                AddItem(ItemKey, Item)
            end
        end
    else
        local Snapshot = ShopUtil:GetShopSnapshot(LocalPlayer, "Gold")
        for ItemKey, Item in pairs(Snapshot and Snapshot.Items or {}) do
            AddItem(ItemKey, Item)
        end
    end

    CachedGoldShopCatalog = CatalogValues(ById)
    return CachedGoldShopCatalog
end

local function GetSeasonShopCatalog(ForceRefresh)
    if CachedSeasonShopCatalog and not ForceRefresh then
        return CachedSeasonShopCatalog
    end

    local ResSeasonShop = GetSeasonShopConfig()
    local ById = {}
    for ShopId, Item in pairs(ResSeasonShop) do
        if ShopId ~= "__index" and type(Item) == "table" and type(Item.ItemId) == "string" then
            local Existing = ById[Item.ItemId]
            if not Existing then
                ById[Item.ItemId] = {
                    ItemId = Item.ItemId,
                    ItemType = Item.ItemType,
                    Price = Item.Price,
                    ItemCount = Item.ItemCount,
                    LimitTimes = Item.LimitTimes,
                    IsSpecial = Item.IsSpecial == true,
                    ShopId = ShopId
                }
            end
        end
    end

    CachedSeasonShopCatalog = CatalogValues(ById)
    return CachedSeasonShopCatalog
end

local function GetOreCatalog(ForceRefresh)
    if CachedOreCatalog and not ForceRefresh then
        return CachedOreCatalog
    end

    local Framework = GetFrameworkModule()
    local DataUtil = Framework.Modules.DataUtil
    local ForgeUtil = Framework.Modules.ForgeUtil
    local RarityTiers = Framework.Modules.RarityTiers
    local Ores = DataUtil:GetValue(LocalPlayer, {"Ores"}) or {}
    local ResOres = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("ResOres"))
    local Result = {}
    local Seen = {}

    local function AddOre(OreId)
        if type(OreId) ~= "string" or OreId == "" or Seen[OreId] then
            return
        end
        Seen[OreId] = true
        local Def = ForgeUtil:GetDef(OreId) or ResOres[OreId]
        if Def then
            local Rarity = tonumber(Def.Rarity) or 0
            local RarityName = tostring(Rarity)
            pcall(function()
                RarityName = RarityTiers:GetTierName(Rarity)
            end)
            table.insert(Result, {
                ItemId = OreId,
                ItemType = "Ore",
                Count = tonumber(Ores[OreId]) or 0,
                Level = tonumber(Def.Level or Def[6]) or 0,
                Sort = tonumber(Def.Sort or Def[5]) or 0,
                Rarity = Rarity,
                RarityName = RarityName,
                Def = Def
            })
        end
    end

    if type(ResOres.__index) == "table" then
        for _, OreId in ipairs(ResOres.__index) do
            AddOre(OreId)
        end
    end
    for OreId in pairs(ResOres) do
        if OreId ~= "__index" then
            AddOre(OreId)
        end
    end
    for OreId in pairs(Ores) do
        AddOre(OreId)
    end

    table.sort(Result, function(A, B)
        if A.Level ~= B.Level then
            return A.Level > B.Level
        end
        if A.Rarity ~= B.Rarity then
            return A.Rarity > B.Rarity
        end
        if A.Sort ~= B.Sort then
            return A.Sort < B.Sort
        end
        return tostring(A.ItemId) < tostring(B.ItemId)
    end)
    CachedOreCatalog = Result
    return CachedOreCatalog
end

local function GetOreRarityLevels(Catalog)
    local Levels = {0}
    local Seen = {[0] = true}
    for _, Entry in ipairs(Catalog or {}) do
        if not Seen[Entry.Rarity] then
            Seen[Entry.Rarity] = true
            table.insert(Levels, Entry.Rarity)
        end
    end
    table.sort(Levels, function(A, B)
        if A == B then
            return false
        end
        if A == 0 then
            return true
        end
        if B == 0 then
            return false
        end
        return A > B
    end)
    return Levels
end

local function ShouldSellOre(OreId, Def)
    local Mode = OreSellModes[OreId] or "AUTO"
    if Mode == "KEEP" then
        return false
    end
    if Mode == "SELL" then
        return true
    end
    local Rarity = Def and tonumber(Def.Rarity)
    return SellMaxRarity > 0 and Rarity and Rarity <= SellMaxRarity
end

local function GetItemDisplayName(ItemId)
    local RawId = tostring(ItemId or "Unknown")
    local BaseId = string.split(RawId, ":")[1]
    local Key = "K_" .. string.upper(BaseId)
    local DisplayName = nil

    pcall(function()
        DisplayName = GetFrameworkModule().Modules.TranslationUtil:TranslateByKey(Key)
    end)
    if type(DisplayName) == "string" and DisplayName ~= "" and DisplayName ~= Key then
        return DisplayName
    end
    return string.gsub(BaseId, "_", " ")
end

function AutoPotion.ShouldCatalog(Definition)
    return type(Definition) == "table" and Definition.PotionType == "Buff"
end

function AutoPotion.GetBuffFields(Definition)
    local BuffIds = {}
    local Durations = {}
    local Index = 1
    while true do
        local BuffIdKey = "BuffId" .. Index
        local DurationKey = "Duration" .. Index
        local BuffId = Definition[BuffIdKey]
        local Duration = Definition[DurationKey]
        if BuffId == nil or Duration == nil then
            break
        end
        if BuffId ~= "" and Duration ~= "" then
            table.insert(BuffIds, tostring(BuffId))
            table.insert(Durations, tonumber(Duration) or 0)
        end
        Index = Index + 1
    end
    return BuffIds, Durations
end

function AutoPotion.GetBuffAttributeIds(BuffId)
    local AttributeIds = {BuffId}
    local NativeAttributeId = string.match(BuffId, "^Buff_(.+)_%d+$")
    if NativeAttributeId and NativeAttributeId ~= BuffId then
        table.insert(AttributeIds, NativeAttributeId)
    end
    return AttributeIds
end

function AutoPotion.AreBuffsActive(BuffIds, GetValue)
    if type(BuffIds) ~= "table" or #BuffIds <= 0 then
        return false
    end
    for _, BuffId in ipairs(BuffIds) do
        if (tonumber(GetValue(BuffId)) or 0) <= 0 then
            return false
        end
    end
    return true
end

function AutoPotion.ShouldQueueState(Selected, Owned, Active, Queued, Pending, ActivationPending)
    return Selected == true and (tonumber(Owned) or 0) > 0 and not Active and not Queued and not Pending and
               not ActivationPending
end

function AutoPotion.RunSelfCheck()
    local Cases = {
        {Name = "one selected potion", Actual = AutoPotion.ShouldQueueState(true, 1, false, false, false, false), Expected = true},
        {Name = "multiple independent potions", Actual = AutoPotion.ShouldQueueState(true, 2, true, false, false, false), Expected = false},
        {Name = "multi-buff potion", Actual = AutoPotion.AreBuffsActive({"A", "B"}, function(Id) return Id == "A" and 1 or 0 end), Expected = false},
        {Name = "out-of-stock potion", Actual = AutoPotion.ShouldQueueState(true, 0, false, false, false, false), Expected = false},
        {Name = "missed-signal recovery", Actual = AutoPotion.ShouldQueueState(true, 1, false, false, false, false), Expected = true},
        {Name = "owned decrease waits for buff activation", Actual = AutoPotion.ShouldQueueState(true, 1, false, false, false, true), Expected = false},
        {Name = "Buff_DropRateBoost_1 maps to DropRateBoost", Actual = AutoPotion.GetBuffAttributeIds("Buff_DropRateBoost_1")[2], Expected = "DropRateBoost"},
        {Name = "Bond exclusion", Actual = AutoPotion.ShouldCatalog({PotionType = "BondIntimacy"}), Expected = false}
    }
    for _, Case in ipairs(Cases) do
        assert(Case.Actual == Case.Expected, "Auto Potion self-check failed: " .. Case.Name)
    end
    return true
end

function AutoPotion.RefreshState()
    if AutoPotion.Refresh then
        pcall(AutoPotion.Refresh)
    end
end

function AutoPotion.SetStatus(Status)
    if AutoPotion.Status == Status then
        return
    end
    AutoPotion.Status = Status
    print("[AutoPotion] " .. tostring(Status))
    AutoPotion.RefreshState()
end

function AutoPotion.BuildCatalog(ForceRefresh)
    local Framework = GetFrameworkModule()
    local PotionUtil = Framework.Modules.PotionUtil
    if not ForceRefresh and #AutoPotion.Order > 0 then
        for _, PotionId in ipairs(AutoPotion.Order) do
            local Entry = AutoPotion.Catalog[PotionId]
            Entry.Owned = tonumber(PotionUtil:GetOwnedAmount(LocalPlayer, PotionId)) or 0
        end
        return AutoPotion.Catalog, AutoPotion.Order
    end

    local ResPotion = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("ResPotion"))
    local Catalog = {}
    local Order = {}
    local ByBuffId = {}
    local Seen = {}
    local function AddPotion(PotionId)
        if type(PotionId) ~= "string" or Seen[PotionId] then
            return
        end
        Seen[PotionId] = true
        local Definition = ResPotion[PotionId]
        if not AutoPotion.ShouldCatalog(Definition) then
            return
        end
        local BuffIds, Durations = AutoPotion.GetBuffFields(Definition)
        local Entry = {
            PotionId = PotionId,
            DisplayName = GetItemDisplayName(PotionId),
            Icon = Definition.Icon,
            BuffIds = BuffIds,
            Durations = Durations,
            Definition = Definition,
            Owned = tonumber(PotionUtil:GetOwnedAmount(LocalPlayer, PotionId)) or 0
        }
        Catalog[PotionId] = Entry
        table.insert(Order, PotionId)
        for _, BuffId in ipairs(BuffIds) do
            for _, AttributeId in ipairs(AutoPotion.GetBuffAttributeIds(BuffId)) do
                ByBuffId[AttributeId] = ByBuffId[AttributeId] or {}
                table.insert(ByBuffId[AttributeId], PotionId)
            end
        end
    end

    for _, PotionId in ipairs(ResPotion.__index or {}) do
        AddPotion(PotionId)
    end
    for PotionId in pairs(ResPotion) do
        AddPotion(PotionId)
    end
    table.sort(Order, function(LeftId, RightId)
        local Left = Catalog[LeftId]
        local Right = Catalog[RightId]
        local LeftName = string.lower(Left and Left.DisplayName or LeftId)
        local RightName = string.lower(Right and Right.DisplayName or RightId)
        if LeftName == RightName then
            return LeftId < RightId
        end
        return LeftName < RightName
    end)

    local SelectionChanged = false
    for PotionId in pairs(AutoPotion.Selected) do
        if not Catalog[PotionId] then
            AutoPotion.Selected[PotionId] = nil
            SelectionChanged = true
        end
    end
    AutoPotion.Catalog = Catalog
    AutoPotion.Order = Order
    AutoPotion.ByBuffId = ByBuffId
    if SelectionChanged then
        SaveConfig()
    end
    return Catalog, Order
end

function AutoPotion.GetPlayerAttrEntry()
    return LocalPlayer:FindFirstChild("PlayerAttrEntry")
end

function AutoPotion.ResetDungeonGrace()
    if AutoPotion.GraceStartedAt or AutoPotion.GraceCharacter or AutoPotion.GraceAttrEntry then
        AutoPotion.GraceGeneration = AutoPotion.GraceGeneration + 1
    end
    AutoPotion.GraceStartedAt = nil
    AutoPotion.GraceCharacter = nil
    AutoPotion.GraceAttrEntry = nil
end

function AutoPotion.CheckDungeonGrace(Character, PlayerAttrEntry)
    if AutoPotion.GraceCharacter ~= Character or AutoPotion.GraceAttrEntry ~= PlayerAttrEntry or
        not AutoPotion.GraceStartedAt then
        AutoPotion.GraceGeneration = AutoPotion.GraceGeneration + 1
        local Generation = AutoPotion.GraceGeneration
        AutoPotion.GraceStartedAt = os.clock()
        AutoPotion.GraceCharacter = Character
        AutoPotion.GraceAttrEntry = PlayerAttrEntry
        task.delay(AutoPotion.DungeonGraceSeconds, function()
            if AutoPotion.Token.Alive and _G.AutoPotion and Generation == AutoPotion.GraceGeneration and
                AutoPotion.GraceCharacter == Character and AutoPotion.GraceAttrEntry == PlayerAttrEntry then
                pcall(AutoPotion.Scan, false)
            end
        end)
    end
    local Remaining = AutoPotion.DungeonGraceSeconds - (os.clock() - AutoPotion.GraceStartedAt)
    if Remaining > 0 then
        return false, "BLOCKED - POTION GRACE " .. tostring(math.ceil(Remaining)) .. "S"
    end
    return true
end

function AutoPotion.IsSettlementVisible()
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local ResultGui = PlayerGui and PlayerGui:FindFirstChild("ResultGui")
    local ScreenSettlement = ResultGui and ResultGui:FindFirstChild("ScreenSettlement")
    local Current = ScreenSettlement
    if not Current then
        return false
    end
    while Current and Current ~= game do
        if Current:IsA("GuiObject") and not Current.Visible then
            return false
        end
        if Current:IsA("LayerCollector") and not Current.Enabled then
            return false
        end
        Current = Current.Parent
    end
    return true
end

function AutoPotion.IsEndlessTower()
    local CurrentWorld = workspace:FindFirstChild("World")
    return CurrentWorld ~= nil and CurrentWorld:FindFirstChild("Start") ~= nil
end

function AutoPotion.IsDungeonEligible()
    if IsInLobby and IsInLobby() then
        AutoPotion.ResetDungeonGrace()
        return false, "BLOCKED - LOBBY"
    end
    if workspace:GetAttribute("LoadingEnd") ~= true then
        AutoPotion.ResetDungeonGrace()
        return false, "BLOCKED - LOADING"
    end
    if AutoPotion.IsEndlessTower() then
        AutoPotion.ResetDungeonGrace()
        return false, "BLOCKED - ENDLESS TOWER"
    end
    if AutoPotion.IsSettlementVisible() then
        AutoPotion.ResetDungeonGrace()
        return false, "BLOCKED - SETTLEMENT"
    end
    if RejoinWatchdog.BlocksAutomation() then
        AutoPotion.ResetDungeonGrace()
        return false, "BLOCKED - REJOIN"
    end
    local Character = LocalPlayer.Character
    local PlayerAttrEntry = AutoPotion.GetPlayerAttrEntry()
    if not Character or not PlayerAttrEntry then
        AutoPotion.ResetDungeonGrace()
        return false, "BLOCKED - LOADING"
    end
    return AutoPotion.CheckDungeonGrace(Character, PlayerAttrEntry)
end

function AutoPotion.IsEntryActive(Entry)
    local PlayerAttrEntry = AutoPotion.GetPlayerAttrEntry()
    if not Entry or not PlayerAttrEntry then
        return false
    end
    return AutoPotion.AreBuffsActive(Entry.BuffIds, function(BuffId)
        for _, AttributeId in ipairs(AutoPotion.GetBuffAttributeIds(BuffId)) do
            local Value = tonumber(PlayerAttrEntry:GetAttribute(AttributeId)) or 0
            if Value > 0 then
                return Value
            end
        end
        return 0
    end)
end

function AutoPotion.GetEntryState(Entry)
    if not Entry or #Entry.BuffIds <= 0 or not AutoPotion.GetPlayerAttrEntry() then
        return "Unavailable"
    end
    if AutoPotion.Pending[Entry.PotionId] or AutoPotion.ActivationPending[Entry.PotionId] then
        return "Pending"
    end
    if AutoPotion.IsEntryActive(Entry) then
        return "Active"
    end
    if (tonumber(Entry.Owned) or 0) <= 0 then
        return "Out of Stock"
    end
    return "Inactive"
end

function AutoPotion.DisconnectSignals()
    for _, Connection in pairs(AutoPotion.Connections) do
        pcall(function() Connection:Disconnect() end)
    end
    for _, Connection in ipairs(AutoPotion.LifecycleConnections) do
        pcall(function() Connection:Disconnect() end)
    end
    table.clear(AutoPotion.Connections)
    table.clear(AutoPotion.LifecycleConnections)
end

function AutoPotion.Enqueue(PotionId)
    if AutoPotion.Queued[PotionId] or AutoPotion.Pending[PotionId] then
        return false
    end
    AutoPotion.Queued[PotionId] = true
    table.insert(AutoPotion.Queue, PotionId)
    if not AutoPotion.WorkerRunning then
        AutoPotion.WorkerRunning = true
        task.spawn(AutoPotion.RunQueue)
    end
    AutoPotion.RefreshState()
    return true
end

function AutoPotion.EvaluatePotion(PotionId, AllowRetry)
    local Entry = AutoPotion.Catalog[PotionId]
    if not Entry or not AutoPotion.Selected[PotionId] then
        return false
    end
    if AutoPotion.RetryOnScan[PotionId] then
        if not AllowRetry then
            return false
        end
        AutoPotion.RetryOnScan[PotionId] = nil
    end
    local PotionUtil = GetFrameworkModule().Modules.PotionUtil
    Entry.Owned = tonumber(PotionUtil:GetOwnedAmount(LocalPlayer, PotionId)) or 0
    local Active = AutoPotion.IsEntryActive(Entry)
    if Active then
        AutoPotion.ActivationPending[PotionId] = nil
    end
    if AutoPotion.ShouldQueueState(true, Entry.Owned, Active, AutoPotion.Queued[PotionId],
        AutoPotion.Pending[PotionId], AutoPotion.ActivationPending[PotionId]) then
        return AutoPotion.Enqueue(PotionId)
    end
    return false
end

function AutoPotion.Scan(ForceRefresh, AllowRetry)
    if not _G.AutoPotion or not AutoPotion.Token.Alive then
        return
    end
    AutoPotion.BuildCatalog(ForceRefresh == true)
    local Eligible, Reason = AutoPotion.IsDungeonEligible()
    if not Eligible then
        AutoPotion.SetStatus(Reason)
        return
    end
    local QueuedAny = false
    for _, PotionId in ipairs(AutoPotion.Order) do
        if AutoPotion.Selected[PotionId] and AutoPotion.EvaluatePotion(PotionId, AllowRetry) then
            QueuedAny = true
        end
    end
    if not QueuedAny and not AutoPotion.WorkerRunning then
        AutoPotion.SetStatus("AUTO POTION READY")
    end
    AutoPotion.RefreshState()
end

function AutoPotion.UseOne(PotionId)
    local Entry = AutoPotion.Catalog[PotionId]
    local Eligible = AutoPotion.IsDungeonEligible()
    if not _G.AutoPotion or not AutoPotion.Selected[PotionId] or not Eligible or not Entry or
        not AutoPotion.ShouldCatalog(Entry.Definition) then
        return
    end
    local PotionUtil = GetFrameworkModule().Modules.PotionUtil
    local BeforeOwned = tonumber(PotionUtil:GetOwnedAmount(LocalPlayer, PotionId)) or 0
    Entry.Owned = BeforeOwned
    if BeforeOwned <= 0 or AutoPotion.IsEntryActive(Entry) then
        return
    end

    AutoPotion.Pending[PotionId] = true
    AutoPotion.SetStatus("PENDING " .. PotionId)
    local Success, ErrorMessage = pcall(function()
        PotionUtil:UsePotion(LocalPlayer, PotionId, 1, nil)
    end)
    AutoPotion.LastRequestAt = os.clock()
    if not Success then
        warn("[AutoPotion] USE ERROR " .. PotionId .. ": " .. tostring(ErrorMessage))
    else
        local RequestAccepted = false
        local Deadline = os.clock() + AutoPotion.ConfirmTimeout
        repeat
            Entry.Owned = tonumber(PotionUtil:GetOwnedAmount(LocalPlayer, PotionId)) or 0
            RequestAccepted = RequestAccepted or Entry.Owned < BeforeOwned
            if AutoPotion.IsEntryActive(Entry) then
                print("[AutoPotion] USED " .. PotionId .. " x1")
                AutoPotion.ActivationPending[PotionId] = nil
                AutoPotion.RetryOnScan[PotionId] = nil
                AutoPotion.SetStatus("ACTIVE " .. PotionId)
                AutoPotion.Pending[PotionId] = nil
                AutoPotion.RefreshState()
                return
            end
            task.wait(0.1)
        until os.clock() >= Deadline
        if RequestAccepted then
            AutoPotion.ActivationPending[PotionId] = true
            AutoPotion.RetryOnScan[PotionId] = nil
            AutoPotion.SetStatus("WAITING BUFF " .. PotionId)
        else
            warn("[AutoPotion] USE TIMEOUT " .. PotionId)
            AutoPotion.RetryOnScan[PotionId] = true
            AutoPotion.SetStatus("USE TIMEOUT " .. PotionId)
        end
    end
    AutoPotion.Pending[PotionId] = nil
    AutoPotion.RefreshState()
end

function AutoPotion.RunQueue()
    while AutoPotion.Token.Alive and _G.AutoPotion and #AutoPotion.Queue > 0 do
        local PotionId = table.remove(AutoPotion.Queue, 1)
        AutoPotion.Queued[PotionId] = nil
        local WaitTime = AutoPotion.QueueSpacing - (os.clock() - AutoPotion.LastRequestAt)
        if WaitTime > 0 then
            task.wait(WaitTime)
        end
        AutoPotion.UseOne(PotionId)
    end
    AutoPotion.WorkerRunning = false
    AutoPotion.RefreshState()
end

function AutoPotion.RebuildSignals()
    AutoPotion.DisconnectSignals()
    if not _G.AutoPotion or not AutoPotion.Token.Alive then
        return
    end
    AutoPotion.BuildCatalog(false)
    local PlayerAttrEntry = AutoPotion.GetPlayerAttrEntry()
    if PlayerAttrEntry then
        for PotionId in pairs(AutoPotion.Selected) do
            local Entry = AutoPotion.Catalog[PotionId]
            if Entry then
                for _, BuffId in ipairs(Entry.BuffIds) do
                    for _, AttributeId in ipairs(AutoPotion.GetBuffAttributeIds(BuffId)) do
                        if not AutoPotion.Connections[AttributeId] then
                            local ObservedAttributeId = AttributeId
                            AutoPotion.Connections[ObservedAttributeId] = PlayerAttrEntry:GetAttributeChangedSignal(AttributeId):Connect(function()
                                for _, RelatedPotionId in ipairs(AutoPotion.ByBuffId[ObservedAttributeId] or {}) do
                                    AutoPotion.EvaluatePotion(RelatedPotionId)
                                end
                                AutoPotion.RefreshState()
                            end)
                        end
                    end
                end
            end
        end
    end

    local function RefreshContext(Child)
        local Name = Child and Child.Name or ""
        if Name == "MatchRoom" or Name == "WorldEnemys" or Name == "DragonEgg" or Name == "PlayerAttrEntry" then
            if Name == "MatchRoom" or Name == "PlayerAttrEntry" then
                AutoPotion.ResetDungeonGrace()
            end
            task.defer(function()
                AutoPotion.RebuildSignals()
                AutoPotion.Scan(false)
            end)
        end
    end
    table.insert(AutoPotion.LifecycleConnections, workspace.ChildAdded:Connect(RefreshContext))
    table.insert(AutoPotion.LifecycleConnections, workspace.ChildRemoved:Connect(RefreshContext))
    table.insert(AutoPotion.LifecycleConnections, workspace:GetAttributeChangedSignal("LoadingEnd"):Connect(function()
        AutoPotion.ResetDungeonGrace()
        task.defer(function() AutoPotion.Scan(false) end)
    end))
    table.insert(AutoPotion.LifecycleConnections, LocalPlayer.ChildAdded:Connect(RefreshContext))
    table.insert(AutoPotion.LifecycleConnections, LocalPlayer.ChildRemoved:Connect(RefreshContext))
    table.insert(AutoPotion.LifecycleConnections, LocalPlayer.CharacterAdded:Connect(function()
        AutoPotion.ResetDungeonGrace()
        task.defer(function() AutoPotion.Scan(false) end)
    end))
    table.insert(AutoPotion.LifecycleConnections, LocalPlayer.CharacterRemoving:Connect(AutoPotion.ResetDungeonGrace))
end

function AutoPotion.StartScanner()
    AutoPotion.ScanGeneration = AutoPotion.ScanGeneration + 1
    local Generation = AutoPotion.ScanGeneration
    task.spawn(function()
        while AutoPotion.Token.Alive and _G.AutoPotion and Generation == AutoPotion.ScanGeneration do
            task.wait(AutoPotion.ScanInterval)
            if AutoPotion.Token.Alive and _G.AutoPotion and Generation == AutoPotion.ScanGeneration then
                pcall(AutoPotion.Scan, false, true)
            end
        end
    end)
end

function AutoPotion.SetEnabled(Enabled)
    _G.AutoPotion = Enabled == true
    AutoPotion.ScanGeneration = AutoPotion.ScanGeneration + 1
    if not _G.AutoPotion then
        AutoPotion.DisconnectSignals()
        AutoPotion.ResetDungeonGrace()
        table.clear(AutoPotion.Queue)
        table.clear(AutoPotion.Queued)
        table.clear(AutoPotion.ActivationPending)
        AutoPotion.SetStatus("OFF")
        return
    end
    AutoPotion.BuildCatalog(true)
    AutoPotion.RebuildSignals()
    AutoPotion.SetStatus("AUTO POTION READY")
    AutoPotion.Scan(false)
    AutoPotion.StartScanner()
end

function AutoPotion.Shutdown()
    AutoPotion.Token.Alive = false
    AutoPotion.ScanGeneration = AutoPotion.ScanGeneration + 1
    AutoPotion.DisconnectSignals()
    AutoPotion.ResetDungeonGrace()
    table.clear(AutoPotion.Queue)
    table.clear(AutoPotion.Queued)
    table.clear(AutoPotion.ActivationPending)
end

AutoPotion.RunSelfCheck()

function AutoForge.GetInventory()
    local Framework = GetFrameworkModule()
    local DataUtil = Framework.Modules.DataUtil
    local KeyString = AutoForge.GetKeyString()
    local Ores = DataUtil:GetValue(LocalPlayer, {"Ores"}) or {}
    local Crystals = DataUtil:GetValue(LocalPlayer, {KeyString.EquipmentUtil.Crystals}) or {}
    return Ores, Crystals
end

function AutoForge.GetCompositionTotal(Composition)
    local Total = 0
    for _, Count in pairs(Composition or {}) do
        Total = Total + math.max(0, math.floor(tonumber(Count) or 0))
    end
    return Total
end

function AutoForge.CalculateLimit(Recipe, Composition, Ores, Crystals)
    if not Recipe or AutoForge.GetCompositionTotal(Composition) ~= Recipe.OreCount then
        return 0, nil, "Composition must equal " .. tostring(Recipe and Recipe.OreCount or 0)
    end

    local MaxCrafts = math.huge
    local LimitingItemId = nil
    for OreId, PerCraft in pairs(Composition) do
        PerCraft = math.floor(tonumber(PerCraft) or 0)
        if PerCraft > 0 then
            local OwnedCount = tonumber(Ores[OreId]) or 0
            local OreCrafts = math.floor(OwnedCount / PerCraft)
            if OreCrafts < MaxCrafts then
                MaxCrafts = OreCrafts
                LimitingItemId = OreId
            end
        end
    end

    if Recipe.RelicId then
        local ForgeUtil = GetFrameworkModule().Modules.ForgeUtil
        local RelicUsable = false
        pcall(function()
            RelicUsable = ForgeUtil:IsRelicUsable(LocalPlayer, Recipe.RelicId)
        end)
        local RelicCount = RelicUsable and (tonumber(Crystals[Recipe.RelicId]) or 0) or 0
        if RelicCount < MaxCrafts then
            MaxCrafts = RelicCount
            LimitingItemId = Recipe.RelicId
        end
    end

    if MaxCrafts == math.huge then
        MaxCrafts = 0
    end
    MaxCrafts = math.max(0, math.floor(MaxCrafts))
    local Reason = MaxCrafts > 0 and nil or "Insufficient materials"
    return MaxCrafts, LimitingItemId, Reason
end

function AutoForge.BuildStatCatalog(ResultData)
    local Seen = {}
    local function AddStat(Value)
        local StatId = AutoForge.NormalizeStatId(Value)
        if StatId and StatId ~= "SpecialEntry" then
            Seen[StatId] = true
        end
    end
    local AttrEntry = GetGameEnum().AttrEntry or {}
    for Key, Value in pairs(AttrEntry) do
        AddStat(Key)
        AddStat(Value)
    end
    for StatId in pairs(AutoForge.Groups.Offensive) do
        AddStat(StatId)
    end
    for StatId in pairs(AutoForge.DiscoveredStats) do
        AddStat(StatId)
    end
    for AttributeKey in pairs(type(ResultData) == "table" and type(ResultData.Attr) == "table" and ResultData.Attr or {}) do
        AddStat(AttributeKey)
    end

    local TranslationUtil = GetFrameworkModule().Modules.TranslationUtil
    local Catalog = {}
    for StatId in pairs(Seen) do
        local TranslationKey = "K_" .. string.upper(StatId)
        local DisplayName = StatId
        pcall(function()
            local Translated = TranslationUtil:TranslateByKey(TranslationKey)
            if type(Translated) == "string" and Translated ~= "" and Translated ~= TranslationKey then
                DisplayName = Translated
            end
        end)
        table.insert(Catalog, {StatId = StatId, DisplayName = DisplayName})
    end
    table.sort(Catalog, function(Left, Right)
        return string.lower(Left.DisplayName) < string.lower(Right.DisplayName)
    end)
    AutoForge.StatCatalog = Catalog
    return Catalog
end

function AutoForge.BuildResultSummary(ResultData)
    local Summary = {Slots = {}, Counts = {}, GroupCounts = {Offensive = 0}, TotalSlots = 0}
    for AttributeKey in pairs(type(ResultData) == "table" and type(ResultData.Attr) == "table" and ResultData.Attr or {}) do
        local StatId = AutoForge.NormalizeStatId(AttributeKey)
        if StatId then
            table.insert(Summary.Slots, StatId)
            Summary.Counts[StatId] = (Summary.Counts[StatId] or 0) + 1
            Summary.TotalSlots = Summary.TotalSlots + 1
            AutoForge.DiscoveredStats[StatId] = true
            if AutoForge.Groups.Offensive[StatId] then
                Summary.GroupCounts.Offensive = Summary.GroupCounts.Offensive + 1
            end
        end
    end
    table.sort(Summary.Slots)
    AutoForge.BuildStatCatalog(ResultData)
    return Summary
end

function AutoForge.BuildProfileSummary(Profile)
    Profile = AutoForge.NormalizeProfile(Profile)
    local Parts = {Profile.SlotMode == "Any" and "Any Total Slots" or (Profile.SlotMode == "Exact" and ("Exact " .. tostring(Profile.SlotCount) .. " Slots") or ("At Least " .. tostring(Profile.SlotCount) .. " Slots"))}
    for _, Rule in ipairs(Profile.Rules or {}) do
        if Rule.Kind == "PoolAtLeast" then
            table.insert(Parts, "At Least " .. tostring(Rule.MinCount) .. " From Pool")
        elseif Rule.Kind == "PoolOnly" then
            table.insert(Parts, "Only From Pool")
        elseif Rule.Kind == "RequireStat" then
            table.insert(Parts, "Require " .. GetItemDisplayName(Rule.StatId) .. " >= " .. tostring(Rule.MinCount))
        end
    end
    return table.concat(Parts, " · ")
end

function AutoForge.MatchProfile(Profile, Summary)
    local Valid = AutoForge.ValidateProfile(Profile)
    if not Valid or type(Summary) ~= "table" then
        return false
    end
    if Profile.SlotMode == "Exact" and Summary.TotalSlots ~= Profile.SlotCount then
        return false
    end
    if Profile.SlotMode == "AtLeast" and Summary.TotalSlots < Profile.SlotCount then
        return false
    end
    local PoolLookup = AutoForge.BuildPoolLookup(Profile.PoolStats)
    local PoolCount = 0
    for _, StatId in ipairs(Summary.Slots or {}) do
        if PoolLookup[StatId] then
            PoolCount = PoolCount + 1
        end
    end
    for _, Rule in ipairs(Profile.Rules or {}) do
        if Rule.Kind == "RequireStat" then
            if (Summary.Counts[Rule.StatId] or 0) < Rule.MinCount then
                return false
            end
        elseif Rule.Kind == "PoolAtLeast" then
            if PoolCount < Rule.MinCount then
                return false
            end
        elseif Rule.Kind == "PoolOnly" then
            if Summary.TotalSlots <= 0 or PoolCount ~= Summary.TotalSlots then
                return false
            end
        end
    end
    return true
end

function AutoForge.FindMatchingProfile(ResultData)
    local Summary = AutoForge.BuildResultSummary(ResultData)
    for _, Profile in ipairs(AutoForge.Profiles) do
        local Normalized = AutoForge.NormalizeProfile(Profile)
        if Normalized.Enabled and AutoForge.MatchProfile(Normalized, Summary) then
            return Normalized, Summary
        end
    end
    return nil, Summary
end

function AutoForge.CopyResultData(ResultData)
    local Copy = {}
    for Key, Value in pairs(ResultData or {}) do
        Copy[Key] = Key == "Attr" and CopyMap(Value) or Value
    end
    return Copy
end

function AutoForge.CheckEquipmentStorage()
    local EquipmentUtil = GetFrameworkModule().Modules.EquipmentUtil
    local Success, CanAdd = pcall(EquipmentUtil.CheckCanAdd, EquipmentUtil, LocalPlayer)
    return Success and CanAdd == true
end

function AutoForge.NotifyTargetFound(Profile, ResultData)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "TARGET FOUND",
            Text = tostring(Profile.Name) .. " - " .. GetItemDisplayName(ResultData.ID),
            Duration = 10
        })
    end)
end

function AutoForge.RunTargetProfileSelfChecks()
    local function Result(Keys)
        local Attr = {}
        for Index, Key in ipairs(Keys) do
            Attr[Key .. "_" .. tostring(Index)] = 1
        end
        return AutoForge.BuildResultSummary({Attr = Attr})
    end
    local Cases = {
        {Name = "pool only allows duplicate crit damage", Profile = AutoForge.NormalizeProfile({SlotMode = "Exact", SlotCount = 4, PoolPreset = "Offensive", PoolStats = {"AtkBonus", "CHDmgBonus", "CHIRate", "SkillDmgBonus"}, Rules = {{Kind = "PoolOnly"}}}), Summary = Result({"CHIRate", "CHDmgBonus", "CHDmgBonus", "AtkBonus"}), Expected = true},
        {Name = "pool at least allows non-pool remainder", Profile = AutoForge.NormalizeProfile({SlotMode = "Any", SlotCount = 1, PoolPreset = "Offensive", PoolStats = {"AtkBonus", "CHDmgBonus", "CHIRate", "SkillDmgBonus"}, Rules = {{Kind = "PoolAtLeast", MinCount = 2}}}), Summary = Result({"SkillDmgBonus", "SkillDmgBonus", "HpBonus"}), Expected = true},
        {Name = "require stat stacks with pool only", Profile = AutoForge.NormalizeProfile({SlotMode = "Exact", SlotCount = 4, PoolPreset = "Offensive", PoolStats = {"AtkBonus", "CHDmgBonus", "CHIRate", "SkillDmgBonus"}, Rules = {{Kind = "PoolOnly"}, {Kind = "RequireStat", StatId = "CHDmgBonus", MinCount = 2}}}), Summary = Result({"CHDmgBonus", "CHDmgBonus", "CHIRate", "AtkBonus"}), Expected = true},
        {Name = "pool only rejects non-pool slot", Profile = AutoForge.NormalizeProfile({SlotMode = "Exact", SlotCount = 4, PoolPreset = "Offensive", PoolStats = {"AtkBonus", "CHDmgBonus", "CHIRate", "SkillDmgBonus"}, Rules = {{Kind = "PoolOnly"}}}), Summary = Result({"CHDmgBonus", "CHIRate", "HpBonus", "AtkBonus"}), Expected = false},
        {Name = "duplicate normalized stats", Profile = AutoForge.NormalizeProfile({SlotMode = "Any", SlotCount = 1, PoolPreset = "Offensive", PoolStats = {"AtkBonus", "CHDmgBonus", "CHIRate", "SkillDmgBonus"}, Rules = {{Kind = "RequireStat", StatId = "CHDmgBonus", MinCount = 2}}}), Summary = AutoForge.BuildResultSummary({Attr = {CHDmgBonus_1 = 1, CHDmgBonus_Hell = 1}}), Expected = true}
    }
    for _, Case in ipairs(Cases) do
        assert(AutoForge.MatchProfile(Case.Profile, Case.Summary) == Case.Expected, "Auto Forge target self-check failed: " .. Case.Name)
    end
    local PreviousProfiles = AutoForge.Profiles
    AutoForge.Profiles = {
        AutoForge.NormalizeProfile({Name = "first", Enabled = true, SlotMode = "Exact", SlotCount = 4, PoolPreset = "Offensive", PoolStats = {"AtkBonus", "CHDmgBonus", "CHIRate", "SkillDmgBonus"}, Rules = {{Kind = "PoolOnly"}, {Kind = "RequireStat", StatId = "CHDmgBonus", MinCount = 2}}}),
        AutoForge.NormalizeProfile({Name = "second", Enabled = true, SlotMode = "Any", SlotCount = 1, PoolPreset = "Offensive", PoolStats = {"AtkBonus", "CHDmgBonus", "CHIRate", "SkillDmgBonus"}, Rules = {{Kind = "PoolAtLeast", MinCount = 2}}})
    }
    local Match = AutoForge.FindMatchingProfile({Attr = {CHDmgBonus_1 = 1, CHDmgBonus_2 = 1, CHIRate_3 = 1, AtkBonus_4 = 1}})
    assert(Match and Match.Name == "first", "Auto Forge target self-check failed: first profile wins")
    AutoForge.Profiles = PreviousProfiles
end

AutoForge.RunTargetProfileSelfChecks()

local function GetOreBackpackUsage()
    local Framework = GetFrameworkModule()
    local DataUtil = Framework.Modules.DataUtil
    local ForgeUtil = Framework.Modules.ForgeUtil
    local Ores = DataUtil:GetValue(LocalPlayer, {"Ores"}) or {}
    local Current = 0

    for _, Count in pairs(Ores) do
        Current = Current + (tonumber(Count) or 0)
    end

    local Max = tonumber(ForgeUtil:GetMax(LocalPlayer)) or 0
    return Current, Max
end

local function UpdateSellPendingFromBackpack()
    local Current, Max = GetOreBackpackUsage()

    if Max > 0 and Current >= Max then
        SellPending = true
        SellPendingReason = "ore backpack full"
        local CurrentTime = os.clock()
        if (CurrentTime - LastOreBackpackFullLogAt) >= 5.0 then
            LastOreBackpackFullLogAt = CurrentTime
            print("[AutoSell] Ore backpack full " .. tostring(Current) .. "/" .. tostring(Max) .. "; pending lobby sell")
        end
    elseif SellPending and (SellPendingReason == "ore backpack full" or SellPendingReason == "sell blocked") then
        SellPending = false
        SellPendingReason = nil
    end
    return Current, Max
end

local function GetScreenMatch()
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local MainGui = PlayerGui and PlayerGui:FindFirstChild("MainGui")
    return MainGui and MainGui:FindFirstChild("ScreenMatch")
end

local function IsAutoStartFreeMatchRoom(Room)
    local PlayersCount = tonumber(Room:GetAttribute("PlayersCount")) or 0
    local RoomState = Room:GetAttribute("RoomState")
    local EmptyState = GetGameEnum().RoomState.Empty
    return PlayersCount == 0 and (RoomState == nil or RoomState == EmptyState or tostring(RoomState) == tostring(EmptyState))
end

local function FindAutoStartPortalPart(Room)
    local Touch = Room and Room:FindFirstChild("Touch")
    if not Touch then
        return nil
    end
    if Touch:IsA("BasePart") then
        return Touch
    end
    for _, Obj in ipairs(Touch:GetDescendants()) do
        if Obj:IsA("BasePart") then
            return Obj
        end
    end
end

local function FindAutoStartFreePortal()
    local MatchRoom = workspace:FindFirstChild("MatchRoom")
    if not MatchRoom then
        return nil, nil
    end
    for Index = 1, 4 do
        local Room = MatchRoom:FindFirstChild("Room" .. tostring(Index))
        if Room and IsAutoStartFreeMatchRoom(Room) then
            local PortalPart = FindAutoStartPortalPart(Room)
            if PortalPart then
                return Room, PortalPart
            end
        end
    end
end

local function TouchAutoStartPortal()
    if not firetouchinterest then
        print("[AutoStart] firetouchinterest unavailable")
        return false
    end

    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local RootPart = Character:FindFirstChild("HumanoidRootPart") or Character:WaitForChild("HumanoidRootPart", 3)
    local Room, PortalPart = FindAutoStartFreePortal()
    if not RootPart or not PortalPart then
        print("[AutoStart] Waiting free match room")
        return false
    end

    print("[AutoStart] Touching " .. Room.Name .. " portal")
    firetouchinterest(RootPart, PortalPart, 0)
    task.wait(0.2)
    firetouchinterest(RootPart, PortalPart, 1)
    return true
end

local function WaitForScreenMatchVisible(Timeout)
    local StartedAt = os.clock()
    repeat
        local ScreenMatch = GetScreenMatch()
        if ScreenMatch and ScreenMatch.Visible then
            return ScreenMatch
        end
        task.wait(0.1)
    until (os.clock() - StartedAt) >= Timeout
    return nil
end

local function IsAutoStartGuiVisible(Obj)
    if not Obj or not Obj.Parent then
        return false
    end
    if Obj:IsA("GuiObject") and not Obj.Visible then
        return false
    end

    local Parent = Obj.Parent
    while Parent and Parent ~= game do
        if Parent:IsA("GuiObject") and not Parent.Visible then
            return false
        end
        Parent = Parent.Parent
    end
    return true
end

local function ClickGuiButton(Button)
    if not Button or not Button:IsA("GuiObject") or not IsAutoStartGuiVisible(Button) then
        return false
    end

    local Position = Button.AbsolutePosition + (Button.AbsoluteSize / 2)
    VirtualInputManager:SendMouseButtonEvent(Position.X, Position.Y, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(Position.X, Position.Y, 0, false, game, 0)
    if firesignal and Button:IsA("GuiButton") then
        pcall(firesignal, Button.MouseButton1Down)
        pcall(firesignal, Button.MouseButton1Click)
        pcall(firesignal, Button.Activated)
    end
    return true
end

local function FindAutoStartWorldButton(ScreenMatch)
    local WorldFrame = ScreenMatch and ScreenMatch:FindFirstChild("WorldFrame")
    local ChapterFrame = WorldFrame and WorldFrame:FindFirstChild("ChapterFrame")
    local Tab = ChapterFrame and ChapterFrame:FindFirstChild("Tab")
    local ScrollingFrame = Tab and Tab:FindFirstChild("ScrollingFrame")
    local WorldItem = ScrollingFrame and ScrollingFrame:FindFirstChild(AutoStartWorldId)
    return WorldItem and WorldItem:FindFirstChild("Btn")
end

local function FindAutoStartDiffButton(ScreenMatch)
    local WorldFrame = ScreenMatch and ScreenMatch:FindFirstChild("WorldFrame")
    local DiffTabs = WorldFrame and WorldFrame:FindFirstChild("DiffTabs")
    local VisualDifficulty = AutoStartDifficulty > 5 and (AutoStartDifficulty - 5) or AutoStartDifficulty
    return DiffTabs and (DiffTabs:FindFirstChild(tostring(AutoStartDifficulty)) or
                             DiffTabs:FindFirstChild(tostring(VisualDifficulty)))
end

local function SetAutoStartMatchCount(ScreenMatch)
    local Control = ScreenMatch and ScreenMatch:FindFirstChild("Control")
    local Match = Control and Control:FindFirstChild("Match")
    local MatchCount = Match and Match:FindFirstChild("MatchCount")
    local MinusButton = Match and Match:FindFirstChild("MinusButton")
    if not MatchCount or not MinusButton then
        return false
    end

    for _ = 1, 6 do
        if tonumber(MatchCount.Text) == AutoStartMaxPlayers then
            return true
        end
        if not ClickGuiButton(MinusButton) then
            return false
        end
        task.wait(0.15)
    end

    return tonumber(MatchCount.Text) == AutoStartMaxPlayers
end

local function PrepareScreenMatchForAutoStart(ScreenMatch)
    local WorldButton = FindAutoStartWorldButton(ScreenMatch)
    if not ClickGuiButton(WorldButton) then
        print("[AutoStart] Waiting world tab " .. AutoStartWorldId)
        return false
    end
    task.wait(0.35)

    local WorldFrame = ScreenMatch:FindFirstChild("WorldFrame")
    local Details = WorldFrame and WorldFrame:FindFirstChild("Details")
    local HellMode = Details and Details:FindFirstChild("HellMode")
    local HellButton = HellMode and HellMode:FindFirstChild("BTN")
    if AutoStartDifficulty > 5 and HellButton and not HellButton:GetAttribute("Open") then
        ClickGuiButton(HellButton)
        task.wait(0.35)
    end

    local DiffButton = FindAutoStartDiffButton(ScreenMatch)
    if not ClickGuiButton(DiffButton) then
        print("[AutoStart] Waiting diff tab " .. tostring(AutoStartDifficulty))
        return false
    end
    task.wait(0.35)

    if not SetAutoStartMatchCount(ScreenMatch) then
        print("[AutoStart] Waiting match count " .. tostring(AutoStartMaxPlayers))
        return false
    end

    return true
end

local function TryAutoStartSoloDungeon()
    if RejoinWatchdog.BlocksAutomation() or SellPending or not _G.AutoFarm or not _G.AutoReplay then
        return false
    end

    if not IsInLobby or not IsInLobby() then
        return false
    end

    local CurrentTime = os.clock()
    if (CurrentTime - LastAutoStartDungeonAt) < AutoStartDungeonDelay then
        return false
    end

    local ScreenMatch = GetScreenMatch()
    if not ScreenMatch or not ScreenMatch.Visible then
        if not TouchAutoStartPortal() then
            return false
        end
        ScreenMatch = WaitForScreenMatchVisible(2.5)
        if not ScreenMatch then
            print("[AutoStart] Waiting ScreenMatch after portal")
            return false
        end
    end

    if not IsInLobby() then
        return false
    end

    if not DungeonCatalog.ValidateAutoStartSelection(false) then
        print("[AutoStart] No unlocked dungeon target")
        return false
    end

    print("[AutoStart] Creating solo " .. AutoStartWorldId .. " diff " ..
              tostring(AutoStartDifficulty))
    GetWorldRemoteEvent():FireServer("SelectWorld", AutoStartWorldId, AutoStartDifficulty)
    task.wait(0.35)
    GetGameMatchRemoteEvent():FireServer("CreatRoom", AutoStartWorldId, AutoStartDifficulty, AutoStartMaxPlayers)
    LastAutoStartDungeonAt = os.clock()
    AutoStartPending = false
    print("[AutoStart] Create room fired")
    return true
end

local function QueueAutoStartSoloDungeon()
    AutoStartPending = true
    LastAutoStartRetryAt = 0
    if Config.RecoveryPending then
        Config.RecoveryPending = false
        Config.RejoinAttemptTimestamps = {}
        RejoinWatchdog.RecoveryActive = false
        RejoinWatchdog.HardStuck = false
        RejoinWatchdog.NextAttemptAt = nil
        RejoinWatchdog.Finalizing = false
        RejoinWatchdog.Status = "IDLE"
        RejoinWatchdog.Log("AUTO_START_QUEUED")
        SaveConfig()
    end
    print("[AutoStart] Queued solo dungeon restart")
    TryAutoStartSoloDungeon()
end

local function RequestAutoSellContext()
    local CurrentTime = os.clock()
    if (CurrentTime - LastAutoSellContextRequest) < 10.0 then
        return
    end

    LastAutoSellContextRequest = CurrentTime
    print("[AutoSell] Requesting ScreenEquipSell context")
    local TaskRemote = GetTaskRemoteEvent()
    TaskRemote:FireServer("UpdateTaskProgress", "DialogNpc", "EquipmentSellNpc1|1")
    TaskRemote:FireServer("UpdateTaskProgress", "DialogNpc", "EquipmentSellNpc1|0")
    TaskRemote:FireServer("UpdateTaskProgress", "OpenGUIWindow", "ScreenEquipSell")
    TaskRemote:FireServer("UpdateTaskProgress", "OpenGUIWindow", "ScreenTips")
    task.wait(AutoSellContextDelay)
end

local function TryAutoSellOresOnce()
    local Framework = GetFrameworkModule()
    local DataUtil = Framework.Modules.DataUtil
    local ForgeUtil = Framework.Modules.ForgeUtil
    local Ores = DataUtil:GetValue(LocalPlayer, {"Ores"}) or {}
    local SellList = {}
    local BeforeCounts = {}
    local AnySold = false

    UpdateSellPendingFromBackpack()

    for OreId, Count in pairs(Ores) do
        Count = tonumber(Count) or 0
        local Def = ForgeUtil:GetDef(OreId)
        local ShouldSell = ShouldSellOre(OreId, Def)
        if Count > 0 and ShouldSell then
            BeforeCounts[OreId] = Count
            print("[AutoSell] Attempt " .. tostring(OreId) .. " x" .. tostring(Count) .. " rarity " ..
                      tostring(Def and Def.Rarity or "?"))
            table.insert(SellList, OreId)
        end
    end

    if #SellList <= 0 then
        return
    end

    RequestAutoSellContext()

    local SellCall = "ForgeRF.Sell"
    local Success, Result = pcall(function()
        return GetForgeRemoteFunction():InvokeServer("Sell", SellList)
    end)
    if Success then
        print("[AutoSell] " .. SellCall .. " result " .. tostring(Result))
    else
        print("[AutoSell] " .. SellCall .. " error " .. tostring(Result))
        return
    end

    task.wait(0.35)
    local AfterOres = DataUtil:GetValue(LocalPlayer, {"Ores"}) or {}
    for _, OreId in pairs(SellList) do
        local BeforeCount = BeforeCounts[OreId] or 0
        local AfterCount = tonumber(AfterOres[OreId]) or 0
        if AfterCount <= 0 then
            AnySold = true
            print("[AutoSell] Confirmed sold " .. tostring(OreId))
        elseif AfterCount < BeforeCount then
            AnySold = true
            print("[AutoSell] Partially sold " .. tostring(OreId) .. " before " .. tostring(BeforeCount) ..
                      " after " .. tostring(AfterCount))
        else
            local Current, Max = GetOreBackpackUsage()
            if Max > 0 and Current >= Max then
                SellPending = true
                SellPendingReason = "sell blocked"
            end
            print("[AutoSell] Still owned " .. tostring(OreId) .. " x" .. tostring(AfterCount) ..
                      " after sell attempt")
        end
    end

    if AnySold then
        local Current, Max = GetOreBackpackUsage()
        if Max <= 0 or Current < Max then
            SellPending = false
            SellPendingReason = nil
            print("[AutoSell] Pending sell cleared; ore backpack " .. tostring(Current) .. "/" .. tostring(Max))
            QueueAutoStartSoloDungeon()
        end
    end
end

function AutoForge.RefreshState()
    if AutoForge.State.Refresh then
        pcall(AutoForge.State.Refresh)
    end
end

function AutoForge.SetStatus(Status)
    AutoForge.State.Status = Status
    AutoForge.RefreshState()
end

function AutoForge.WaitForData(ForgeUtil, ExpectedOreCount, PreviousUUID, Timeout)
    local Deadline = os.clock() + Timeout
    repeat
        local Success, ForgeData = pcall(ForgeUtil.GetForgeData, ForgeUtil, LocalPlayer)
        if Success and type(ForgeData) == "table" and ForgeData.ForgeState == "QTE" and
            ForgeData.OresNum == ExpectedOreCount and type(ForgeData.QTE) == "table" and
            ForgeData.QTE.UUID and ForgeData.QTE.UUID ~= PreviousUUID then
            return ForgeData
        end
        task.wait(0.1)
    until os.clock() >= Deadline
    return nil
end

function AutoForge.WaitForQTEProgress(ForgeUtil, ExpectedTimes, PreviousUUID, Timeout)
    local Deadline = os.clock() + Timeout
    repeat
        local Success, QTEData = pcall(ForgeUtil.GetQTE, ForgeUtil, LocalPlayer)
        if Success and type(QTEData) == "table" and (tonumber(QTEData.Times) or 0) >= ExpectedTimes and
            QTEData.UUID ~= PreviousUUID then
            return QTEData
        end
        task.wait(0.05)
    until os.clock() >= Deadline
    return nil
end

function AutoForge.RunCraft(Recipe, Composition, AttemptIndex)
    local Framework = GetFrameworkModule()
    local ForgeUtil = Framework.Modules.ForgeUtil
    local ForgeRemote = GetForgeRemoteFunction()
    if not AutoForge.CheckEquipmentStorage() then
        AutoForge.SetStatus("STOPPED - EQUIPMENT BAG FULL")
        return {Stop = true, Status = "STOPPED - EQUIPMENT BAG FULL"}
    end
    local ExistingData = ForgeUtil:GetForgeData(LocalPlayer)
    local ForgeData = nil
    if AttemptIndex == 1 and type(ExistingData) == "table" and ExistingData.ForgeState == "QTE" and
        type(ExistingData.QTE) == "table" and ExistingData.QTE.UUID then
        ForgeData = ExistingData
        AutoForge.SetStatus("RESUMING PENDING QTE")
    else
        local PreviousUUID = type(ExistingData) == "table" and type(ExistingData.QTE) == "table" and
            ExistingData.QTE.UUID or nil
        local Accepted = ForgeRemote:InvokeServer("DropOres", Composition, Recipe.Category, Recipe.RelicId)
        if Accepted ~= true then
            error("DropOres rejected")
        end
        AutoForge.SetStatus("WAITING FOR QTE DATA")
        ForgeData = AutoForge.WaitForData(ForgeUtil, Recipe.OreCount, PreviousUUID, 10.0)
        if not ForgeData then
            error("fresh QTE data timeout")
        end
    end

    local QTEConfig = ForgeUtil:GetForgeQTE(ForgeData.OresNum)
    local CompletedQTE = tonumber(ForgeData.QTE.Times) or 0
    local TotalQTE = tonumber(QTEConfig and QTEConfig.QT) or 0
    for QTEIndex = CompletedQTE + 1, TotalQTE do
        AutoForge.SetStatus("QTE " .. tostring(QTEIndex) .. "/" .. tostring(TotalQTE))
        local QTEData = ForgeUtil:GetQTE(LocalPlayer)
        if type(QTEData) ~= "table" or not QTEData.UUID then
            error("missing QTE UUID")
        end
        local PreviousUUID = QTEData.UUID
        ForgeRemote:InvokeServer("QTE", {
            UUID = QTEData.UUID,
            Rating = 15
        })
        if not AutoForge.WaitForQTEProgress(ForgeUtil, QTEIndex, PreviousUUID, 10.0) then
            error("QTE progress timeout " .. tostring(QTEIndex) .. "/" .. tostring(TotalQTE))
        end
    end

    local Finished, ResultData = ForgeRemote:InvokeServer("ForgeFinish")
    if Finished ~= true or type(ResultData) ~= "table" or not ResultData.ID then
        error("ForgeFinish rejected")
    end
    local ResultCopy = AutoForge.CopyResultData(ResultData)
    local MatchedProfile = nil
    local Summary = nil
    local AcceptResult = true
    local Stop = false

    if AutoForge.TargetMode then
        AutoForge.SetStatus("CHECKING TARGETS")
        MatchedProfile, Summary = AutoForge.FindMatchingProfile(ResultCopy)
        if MatchedProfile then
            AutoForge.SetStatus("TARGET FOUND - " .. tostring(MatchedProfile.Name))
            Stop = true
        elseif AutoForge.AutoDeleteNonMatch then
            AcceptResult = false
            AutoForge.SetStatus("NON-MATCH - DELETED")
        else
            AutoForge.SetStatus("NON-MATCH - ACCEPTED")
        end
    else
        Summary = AutoForge.BuildResultSummary(ResultCopy)
        AutoForge.SetStatus("ACCEPTED - " .. GetItemDisplayName(ResultCopy.ID))
    end

    if AcceptResult then
        ForgeRemote:InvokeServer("ForgeResult", true)
    else
        ForgeRemote:InvokeServer("ForgeResult", false)
    end

    if MatchedProfile then
        AutoForge.TargetFoundData = {
            ProfileName = MatchedProfile.Name,
            ItemId = ResultCopy.ID,
            Attempt = AttemptIndex,
            Summary = Summary,
            Result = ResultCopy
        }
        AutoForge.NotifyTargetFound(MatchedProfile, ResultCopy)
        if AutoForge.TargetRefresh then
            pcall(AutoForge.TargetRefresh)
        end
    end
    return {Stop = Stop, MatchedProfile = MatchedProfile, Summary = Summary, Result = ResultCopy}
end

function AutoForge.StartBatch()
    if AutoForge.State.Running then
        _G.AutoForge = false
        SaveConfig()
        AutoForge.SetStatus("STOP AFTER CURRENT CRAFT")
        return false
    end
    if not _G.AutoForge then
        AutoForge.SetStatus("ENABLE AUTO FORGE FIRST")
        return false
    end
    if not IsInLobby or not IsInLobby() then
        AutoForge.SetStatus("LOBBY ONLY")
        return false
    end
    if RejoinWatchdog.BlocksAutomation() then
        AutoForge.SetStatus("REJOIN BLOCKED")
        return false
    end
    if AutoSellBusy or SellPending then
        AutoForge.SetStatus("WAIT AUTO SELL")
        return false
    end
    if AutoForge.TargetMode then
        local HasEnabledProfile = false
        for _, Profile in ipairs(AutoForge.Profiles) do
            local Valid = AutoForge.ValidateProfile(Profile)
            if Profile.Enabled and Valid then
                HasEnabledProfile = true
                break
            end
        end
        if not HasEnabledProfile then
            AutoForge.SetStatus("ENABLE A VALID TARGET PROFILE")
            return false
        end
    end

    local Recipe = AutoForge.Recipes[AutoForge.RecipeId]
    local Composition = CopyMap(AutoForge.Composition)
    local Ores, Crystals = AutoForge.GetInventory()
    local MaxCrafts, LimitingItemId, Reason = AutoForge.CalculateLimit(Recipe, Composition, Ores, Crystals)
    if MaxCrafts <= 0 then
        AutoForge.SetStatus(Reason or "INSUFFICIENT MATERIALS")
        return false
    end

    local Planned = math.min(AutoForge.RequestedCrafts, MaxCrafts)
    AutoForge.State.Running = true
    AutoForge.State.Completed = 0
    AutoForge.State.Planned = Planned
    if Planned < AutoForge.RequestedCrafts then
        AutoForge.SetStatus("ADJUSTED TO " .. tostring(Planned) .. " - " .. GetItemDisplayName(LimitingItemId))
    else
        AutoForge.SetStatus("STARTING 0/" .. tostring(Planned))
    end

    task.spawn(function()
        local FinalStatus = nil
        local Success, ErrorMessage = pcall(function()
            for CraftIndex = 1, Planned do
                if not AutoForge.State.Token.Alive or not _G.AutoForge then
                    break
                end
                if not IsInLobby() or RejoinWatchdog.BlocksAutomation() or AutoSellBusy or SellPending then
                    error("automation state changed")
                end

                local CurrentOres, CurrentCrystals = AutoForge.GetInventory()
                local CurrentMax = AutoForge.CalculateLimit(Recipe, Composition, CurrentOres, CurrentCrystals)
                if CurrentMax <= 0 then
                    FinalStatus = "STOPPED - MATERIALS EXHAUSTED"
                    break
                end

                AutoForge.SetStatus("FORGING " .. tostring(CraftIndex) .. "/" .. tostring(Planned))
                local Decision = AutoForge.RunCraft(Recipe, Composition, CraftIndex)
                if Decision and Decision.Status == "STOPPED - EQUIPMENT BAG FULL" then
                    FinalStatus = Decision.Status
                    break
                end
                AutoForge.State.Completed = CraftIndex
                AutoForge.RefreshState()
                if Decision and Decision.Stop then
                    FinalStatus = "TARGET FOUND - " .. tostring(Decision.MatchedProfile.Name)
                    break
                end
            end
        end)

        AutoForge.State.Running = false
        if not Success then
            AutoForge.SetStatus("ERROR: " .. tostring(ErrorMessage))
            warn("[AutoForge] " .. tostring(ErrorMessage))
        elseif FinalStatus then
            AutoForge.SetStatus(FinalStatus)
        elseif AutoForge.State.Completed >= Planned then
            AutoForge.SetStatus("DONE " .. tostring(AutoForge.State.Completed) .. "/" .. tostring(Planned))
        else
            AutoForge.SetStatus("STOPPED " .. tostring(AutoForge.State.Completed) .. "/" .. tostring(Planned))
        end
    end)
    return true
end

function RejoinWatchdog.ProcessPostRejoin()
    if not Config.RecoveryPending or not _G.AutoRejoin or RejoinWatchdog.BlocksAutomation() or not IsInLobby() then
        return
    end
    local Success, Current, Max = pcall(GetOreBackpackUsage)
    if not Success then
        RejoinWatchdog.Status = "WAIT BACKPACK"
        return
    end
    if Max > 0 and Current >= Max then
        SellPending = true
        SellPendingReason = "rejoin backpack full"
        RejoinWatchdog.Status = "WAIT AUTO SELL"
        return
    end
    RejoinWatchdog.Status = "QUEUE DUNGEON"
    QueueAutoStartSoloDungeon()
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if AutoStartPending and _G.AutoFarm and _G.AutoReplay and not SellPending and
            not RejoinWatchdog.BlocksAutomation() then
            local CurrentTime = os.clock()
            if (CurrentTime - LastAutoStartRetryAt) >= AutoStartRetryDelay then
                LastAutoStartRetryAt = CurrentTime
                pcall(TryAutoStartSoloDungeon)
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(AutoSellDelay)
        if (_G.AutoSell or Config.RecoveryPending) and IsInLobby and IsInLobby() and
            not RejoinWatchdog.BlocksAutomation() and not AutoForge.State.Running then
            AutoSellBusy = true
            pcall(TryAutoSellOresOnce)
            AutoSellBusy = false
        end
    end
end)

-- =========================================================================
-- SYSTEM UTILITY: [BARU] PERFECT FORGE MODULE VIA METAMETHOD INJECTION
-- =========================================================================
local envRegistry = getfenv()
local setBypass = envRegistry["hookmetamethod"]
local getMethod = envRegistry["getnamecallmethod"]

local oldCallback
if type(setBypass) == "function" and type(getMethod) == "function" then
    oldCallback = setBypass(game, "__namecall", function(self, ...)
        local method = getMethod()
        local args = {...}

        -- Hanya berjalan jika fitur di UI bernilai TRUE dan memanggil Remote ForgeRF
        if _G.PerfectForge and self.Name == "ForgeRF" then
            for _, arg in pairs(args) do
                if type(arg) == "table" and arg.Rating ~= nil then
                    arg.Rating = 15 -- Memaksa rating perfect otomatis
                end
            end
        end

        return oldCallback(self, unpack(args))
    end)
else
    warn("[Bugon V6] Perfect Forge hook unavailable; continuing without hook")
end

local function UpdateStatsLabel()
    if StatsLabel then
        StatsLabel.Text = "CHEST DESTROYED: " .. tostring(ChestDestroyedCount) ..
                              "\nEGG TRIGGERED: " .. tostring(EggTriggeredCount) ..
                              "\nORE: " .. tostring(OreStats.Current) .. "/" .. tostring(OreStats.Max) ..
                              "\nREJOIN: " .. tostring(RejoinWatchdog.Status)
    end
end

task.spawn(function()
    while true do
        local Success, Current, Max = pcall(GetOreBackpackUsage)
        local Changed = OreStats.RejoinStatus ~= RejoinWatchdog.Status
        if Success and (Current ~= OreStats.Current or Max ~= OreStats.Max) then
            OreStats.Current = Current
            OreStats.Max = Max
            Changed = true
        end
        if Changed then
            OreStats.RejoinStatus = RejoinWatchdog.Status
            UpdateStatsLabel()
        end
        task.wait(1.0)
    end
end)

IsInLobby = function()
    return workspace:FindFirstChild("MatchRoom") ~= nil and workspace:FindFirstChild("WorldEnemys") == nil and
               workspace:FindFirstChild("DragonEgg") == nil
end

AutoPotion.SetEnabled(_G.AutoPotion)

RejoinWatchdog.BindGuiSignals()

task.spawn(function()
    while RejoinWatchdog.Token.Alive do
        task.wait(1.0)
        if IsInLobby() and Config.LobbyPlaceId ~= game.PlaceId then
            Config.LobbyPlaceId = game.PlaceId
            RejoinWatchdog.Log("LOBBY_PLACE_CAPTURED", tostring(game.PlaceId))
            SaveConfig()
        end
        local Success, ErrorMessage = pcall(RejoinWatchdog.Tick)
        if not Success then
            RejoinWatchdog.Log("WATCHDOG_ERROR", ErrorMessage)
        end
        pcall(RejoinWatchdog.ProcessPostRejoin)
    end
end)

-- 1. FUNGSI ANTI-AFK
if not _G.AntiAFK_Loaded then
    _G.AntiAFK_Loaded = true
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
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
    if _G.AutoFarm and _G.UndergroundMode and not RejoinWatchdog.BlocksAutomation() and not IsInLobby() and
        LocalPlayer.Character and
        LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
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
    if not prompt then
        return false
    end
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
    if not tombol then
        return
    end
    pcall(function()
        if getconnections then
            for _, conn in pairs(getconnections(tombol.MouseButton1Click)) do
                conn:Fire()
            end
            for _, conn in pairs(getconnections(tombol.Activated)) do
                conn:Fire()
            end
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
local LastUsed = {
    Q = 0,
    E = 0,
    R = 0,
    G = 0
}
local Cooldowns = {
    Q = 1,
    E = 3,
    R = 5,
    G = 7
}
local SkillButtonNames = {
    Q = "Skill1",
    E = "Skill2",
    G = "SkillAW",
    R = "SkillU"
}
local SkillPriority = {"G", "R", "E", "Q"}
local SkillDebug = _G.SkillDebug ~= false
local SkillAnimationReleaseWindow = 0.2
local WeaponSwitchCooldown = 3.1
local WeaponSwitchAttemptInterval = 0.25
local WeaponSwitchConfirmDelay = 0.1
local NoSwitchSkillsReadyDelay = 0.4
local LastSkillDebugAt = 0
local LastWeaponSwitchAt = 0
local LastWeaponSwitchAttemptAt = 0
local NoSwitchSkillsReadySince = nil
local IsSwitchPending = false

local function DebugSkill(message)
    if not SkillDebug then
        return
    end
    local CurrentTime = os.clock()
    if CurrentTime - LastSkillDebugAt < 0.5 then
        return
    end
    LastSkillDebugAt = CurrentTime
    print("[SkillCD] " .. message)
end

local function DebugSkillNow(message)
    if SkillDebug then
        print("[SkillCD] " .. message)
    end
end

local function GetSkillsFrame()
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local ScreenInput = PlayerGui and PlayerGui:FindFirstChild("ScreenInput")
    local PCInput = ScreenInput and ScreenInput:FindFirstChild("PCInput")
    return PCInput and PCInput:FindFirstChild("Skills") or nil
end

local function GetSkillButton(key)
    local Skills = GetSkillsFrame()
    local SkillName = SkillButtonNames[key]
    local DirectButton = Skills and Skills:FindFirstChild(SkillName)
    if DirectButton then
        return DirectButton
    end
    local Buttons = Skills and Skills:FindFirstChild("LocalPCSkillButtons")
    return (Buttons and Buttons:FindFirstChild(SkillName)) or (Skills and Skills:FindFirstChild(SkillName, true)) or nil
end

local function IsWeaponSwitchReady()
    local Skills = GetSkillsFrame()
    local SwitchButton = Skills and Skills:FindFirstChild("SwitchWpn")
    local Cool = SwitchButton and SwitchButton:FindFirstChild("Cool")
    return SwitchButton ~= nil and (not Cool or Cool.Visible ~= true)
end

local function IsWeaponSwitchOnCooldown()
    local Skills = GetSkillsFrame()
    local SwitchButton = Skills and Skills:FindFirstChild("SwitchWpn")
    local Cool = SwitchButton and SwitchButton:FindFirstChild("Cool")
    return SwitchButton ~= nil and Cool ~= nil and Cool.Visible == true
end

local function GetEquippedWeaponUUID()
    local EquippedWeapon = LocalPlayer:FindFirstChild("PlayerEquippedWeapon")
    return EquippedWeapon and EquippedWeapon:GetAttribute("UUID") or nil
end

local function ConfirmWeaponSwitchSucceeded(previousSwitchTs, previousWeaponUUID)
    local CurrentSwitchTs = LocalPlayer:GetAttribute("SwitchWpnLastTs")
    if CurrentSwitchTs ~= previousSwitchTs then
        return true, "ts changed"
    end

    local CurrentWeaponUUID = GetEquippedWeaponUUID()
    if previousWeaponUUID and CurrentWeaponUUID and CurrentWeaponUUID ~= previousWeaponUUID then
        return true, "uuid changed"
    end

    if IsWeaponSwitchOnCooldown() then
        return true, "cooldown visible"
    end
    return false, "not accepted"
end

local function GetSwitchButtonDebugSummary()
    local Skills = GetSkillsFrame()
    local SwitchButton = Skills and Skills:FindFirstChild("SwitchWpn")
    local Cool = SwitchButton and SwitchButton:FindFirstChild("Cool")
    local Time = Cool and Cool:FindFirstChild("Time")
    return "switchCool=" .. tostring(Cool and Cool.Visible) .. " switchTime=" .. tostring(Time and Time.Text or "nil")
end

local function GetAnimationDebugSummary()
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local Animator = Humanoid and Humanoid:FindFirstChildOfClass("Animator")
    local StateName = Humanoid and Humanoid:GetState().Name or "no humanoid"
    if not Animator then
        return "state=" .. StateName .. " anims=no animator"
    end

    local Animations = {}
    for _, Track in ipairs(Animator:GetPlayingAnimationTracks()) do
        local Length = Track.Length or 0
        local Position = Track.TimePosition or 0
        Animations[#Animations + 1] = string.format("%s len=%.2f pos=%.2f rem=%.2f", tostring(Track.Name), Length,
            Position, Length - Position)
    end

    return "state=" .. StateName .. " anims=" .. (#Animations > 0 and table.concat(Animations, " | ") or "none")
end

local function IsSkillButtonEquipped(button)
    return button:IsA("GuiObject") and button.Visible == true
end

local function IsSkillReady(key)
    local Button = GetSkillButton(key)
    if Button then
        if key == "G" and not IsSkillButtonEquipped(Button) then return false end
        if key == "R" then
            return Button:GetAttribute("OnCD") ~= true and Button:GetAttribute("FullCharge") == true
        end
        return Button:GetAttribute("OnCD") ~= true
    end
    local CurrentTime = os.clock()
    return (CurrentTime - LastUsed[key]) >= Cooldowns[key]
end

local function HasSwitchBlockingSkillReady()
    return IsSkillReady("Q") or IsSkillReady("E")
end

local function ShouldSwitchWeapon(currentTime)
    if HasSwitchBlockingSkillReady() then
        NoSwitchSkillsReadySince = nil
        IsSwitchPending = false
        return false
    end

    NoSwitchSkillsReadySince = NoSwitchSkillsReadySince or currentTime
    IsSwitchPending = currentTime - LastWeaponSwitchAt >= WeaponSwitchCooldown and IsWeaponSwitchReady()

    if not IsSwitchPending then
        return false
    end
    if currentTime - NoSwitchSkillsReadySince < NoSwitchSkillsReadyDelay then
        return false
    end
    return currentTime - LastWeaponSwitchAttemptAt >= WeaponSwitchAttemptInterval
end

local function IsSkillAnimating()
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local Animator = Humanoid and Humanoid:FindFirstChildOfClass("Animator")
    if not Animator then
        return false
    end

    for _, Track in ipairs(Animator:GetPlayingAnimationTracks()) do
        local Name = string.lower(Track.Name or "")
        if string.find(Name, "skill") then
            local Remaining = (Track.Length or 0) - (Track.TimePosition or 0)
            if Track.Length <= 0 or Remaining > SkillAnimationReleaseWindow then
                return true, Track.Name .. " remaining=" .. string.format("%.2f", Remaining)
            end
        end
    end

    return false, nil
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoFarm and _G.AutoSkill and not RejoinWatchdog.BlocksAutomation() and not IsInLobby() and
            LocalPlayer.Character and Target and not IsExtractingEgg and not IsEnteringPortal then
            local CurrentTime = os.clock()
            local IsAnimating, AnimationName = IsSkillAnimating()
            if IsAnimating then
                NoSwitchSkillsReadySince = nil
                IsSwitchPending = false
                DebugSkill("WAIT ANIM " .. tostring(AnimationName))
            else
                local WaitReason = nil
                local PressedSkill = false
                for _, Key in ipairs(SkillPriority) do
                    local Button = GetSkillButton(Key)
                    if IsSkillReady(Key) then
                        NoSwitchSkillsReadySince = nil
                        IsSwitchPending = false
                        DebugSkill("PRESS " .. Key .. " -> " .. SkillButtonNames[Key])
                        PressKey(Key)
                        LastUsed[Key] = os.clock()
                        PressedSkill = true
                        task.wait(0.15)
                        break
                    elseif not WaitReason then
                        if Button then
                            WaitReason = Key .. " OnCD=" .. tostring(Button:GetAttribute("OnCD"))
                            if Key == "R" then
                                WaitReason = WaitReason .. " FullCharge=" .. tostring(Button:GetAttribute("FullCharge"))
                            end
                        else
                            WaitReason = Key .. " no button, timer fallback"
                        end
                    end
                end
                if not PressedSkill and ShouldSwitchWeapon(CurrentTime) then
                    local PreviousSwitchTs = LocalPlayer:GetAttribute("SwitchWpnLastTs")
                    local PreviousWeaponUUID = GetEquippedWeaponUUID()
                    DebugSkillNow("SWITCH C try " .. GetSwitchButtonDebugSummary() .. " " .. GetAnimationDebugSummary())
                    PressKey("C")
                    LastWeaponSwitchAttemptAt = os.clock()
                    task.wait(WeaponSwitchConfirmDelay)

                    local SwitchSucceeded, SwitchReason = ConfirmWeaponSwitchSucceeded(PreviousSwitchTs,
                        PreviousWeaponUUID)
                    if SwitchSucceeded then
                        NoSwitchSkillsReadySince = nil
                        IsSwitchPending = false
                        LastWeaponSwitchAt = os.clock()
                        DebugSkillNow("SWITCH C accepted " .. SwitchReason)
                    else
                        DebugSkill("SWITCH C retry " .. SwitchReason)
                    end
                    task.wait(0.15)
                elseif WaitReason and not PressedSkill then
                    DebugSkill("WAIT CD " .. WaitReason)
                end
            end
        else
            NoSwitchSkillsReadySince = nil
            IsSwitchPending = false
        end
    end
end)

-- ZERO-SPIKE JUMP SYSTEM
RunService.Heartbeat:Connect(function()
    if _G.AutoFarm and not RejoinWatchdog.BlocksAutomation() and not IsInLobby() and LocalPlayer.Character and Target and
        not IsExtractingEgg and not IsEnteringPortal then
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
    if kind ~= "breakable" or not target then
        return
    end
    local trackTarget = target:FindFirstAncestorWhichIsA("Model") or target
    if CountedBreakables[trackTarget] then
        return
    end
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
    if kind ~= "egg" or not target then
        return
    end
    local eggModel = target:FindFirstAncestor("DragonEgg") or target:FindFirstAncestorWhichIsA("Model")
    if not eggModel or CountedEggTriggers[eggModel] then
        return
    end
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
    if obj:IsA("BasePart") then
        return obj
    end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return obj:FindFirstChildWhichIsA("BasePart", true)
end

local function ScanWorldTarget(myRoot)
    local DragonEgg = workspace:FindFirstChild("DragonEgg")
    if DragonEgg and not DragonEgg:GetAttribute("Broken") then
        local part = GetTargetPart(DragonEgg)
        if part then
            return part, "egg"
        end
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
    if not MyRoot or not MyHumanoid then
        return false
    end

    RaycastParamsInstance.FilterDescendantsInstances = {target.Parent, Character}
    local GroundRay = workspace:Raycast(target.Position + Vector3.new(0, 8, 0), Vector3.new(0, -35, 0),
        RaycastParamsInstance)
    local GroundPos = GroundRay and GroundRay.Position or target.Position
    MyRoot.CFrame = CFrame.new(GroundPos + Vector3.new(0, 3, 0), target.Position)
    MyRoot.Velocity = Vector3.new(0, 0, 0)
    MyHumanoid:ChangeState(Enum.HumanoidStateType.Running)
    task.wait(0.35)
    return true
end

local function GetClosestTargetZeroSpike()
    if IsInLobby() then
        return nil, false
    end

    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then
        return nil, false
    end

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
    if NewTarget then
        return NewTarget, "enemy"
    end

    return ScanWorldTarget(MyRoot)
end

local function TriggerEggIfNeeded(target, kind)
    if kind ~= "egg" or IsExtractingEgg then
        return
    end
    if LastTriggeredEgg == target and os.clock() < EggLockEnd then
        return
    end
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
local LastMapPath = ""
local MatchLoadTimer = 0

local LastWaveTriggerAttempt = 0
local LastWorldInstance = nil
local MatchLoadTimer = 0

local LastPortal = nil
local LastPortalPosition = nil
local LastPortalAttemptTime = 0

local WAVE_TRIGGER_COOLDOWN = 2
local PORTAL_COOLDOWN_DURATION = 8
local MAP_LOAD_DELAY = 5
local SAME_PORTAL_POSITION_TOLERANCE = 3

local function ResetPortalState()
    PortalCooldown = false
    IsEnteringPortal = false

    LastPortal = nil
    LastPortalPosition = nil
    LastPortalAttemptTime = 0
    LastWaveTriggerAttempt = 0
end

local function IsPortalAlreadyUsed(PortalPart)
    if not PortalPart then
        return false
    end

    -- Portal lama sudah dihancurkan/diganti oleh game
    if LastPortal and not LastPortal.Parent then
        LastPortal = nil
        LastPortalPosition = nil
        LastPortalAttemptTime = 0
        return false
    end

    -- FIX: Jika waktu percobaan terakhir sudah lewat dari durasi cooldown (8 detik),
    -- anggap portal sudah kedaluwarsa sehingga bot diizinkan untuk mencoba interaksi ulang.
    if os.clock() - LastPortalAttemptTime > PORTAL_COOLDOWN_DURATION then
        LastPortal = nil
        LastPortalPosition = nil
        LastPortalAttemptTime = 0
        return false
    end

    -- Instance portal sama dan masih dalam masa tunggu cooldown
    if LastPortal == PortalPart then
        return true
    end

    -- Instance mungkin diganti, tetapi posisinya masih sama (Anti-spam posisi)
    if LastPortalPosition then
        local PositionDifference = (PortalPart.Position - LastPortalPosition).Magnitude
        if PositionDifference <= SAME_PORTAL_POSITION_TOLERANCE then
            return true
        end
    end

    return false
end

local function TriggerPortalInteraction(MyRoot, PortalPart, UseTouchTrigger)
    if not MyRoot or not MyRoot.Parent then
        return
    end

    if not PortalPart or not PortalPart.Parent then
        return
    end

    local function TouchPortal()
        if firetouchinterest and MyRoot and MyRoot.Parent and PortalPart and PortalPart.Parent then
            firetouchinterest(MyRoot, PortalPart, 0)
            task.wait(0.05)
            firetouchinterest(MyRoot, PortalPart, 1)
        end
    end

    -- Pindahkan karakter ke trigger portal dan fire touch event asli.
    MyRoot.CFrame = CFrame.new(PortalPart.Position + Vector3.new(0, 1, 0))

    MyRoot.AssemblyLinearVelocity = Vector3.zero
    MyRoot.AssemblyAngularVelocity = Vector3.zero

    if UseTouchTrigger then
        TouchPortal()
    end

    -- Tekan Shift + F
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)

    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)

    task.wait(0.05)

    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)

    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)

    task.wait(0.2)

    if MyRoot and MyRoot.Parent then
        MyRoot.AssemblyLinearVelocity = Vector3.zero
        MyRoot.AssemblyAngularVelocity = Vector3.zero
        if UseTouchTrigger then
            MyRoot.CFrame = CFrame.new(PortalPart.Position + Vector3.new(0, 1, 0))
            TouchPortal()
        end
    end
end

local function TeleportToNextStagePortal()
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")

    local MyHumanoid = Character and Character:FindFirstChildOfClass("Humanoid")

    if not MyRoot or not MyHumanoid then
        return
    end

    if MyHumanoid.Health <= 0 then
        return
    end

    -- =========================================================
    -- DETEKSI PERGANTIAN MAP / PLAY AGAIN
    -- =========================================================

    local CurrentWorld = workspace:FindFirstChild("World")

    if CurrentWorld ~= LastWorldInstance then
        LastWorldInstance = CurrentWorld

        ResetPortalState()

        MatchLoadTimer = os.clock() + MAP_LOAD_DELAY

        print("🔄 [System] Map baru dimuat. " .. "Radar portal dikunci selama " .. tostring(MAP_LOAD_DELAY) ..
                  " detik...")
    end

    if not _G.AutoProgressStage then
        return
    end

    if PortalCooldown or IsEnteringPortal then
        return
    end

    -- =========================================================
    -- DETEKSI MODE ENDLESS TOWER
    -- =========================================================

    local IsEndlessTower = false

    if CurrentWorld and CurrentWorld:FindFirstChild("Start") then
        IsEndlessTower = true
    end

    -- =========================================================
    -- CARI WAVE SPAWN TOUCH
    -- =========================================================

    local WorldEnemys = workspace:FindFirstChild("WorldEnemys")

    local WaveSpawnTouch = workspace:FindFirstChild("WaveSpawnTouch") or
                               (WorldEnemys and WorldEnemys:FindFirstChild("WaveSpawnTouch"))

    local HasActiveWaveInterest = false

    if WaveSpawnTouch then
        for _, Zone in ipairs(WaveSpawnTouch:GetChildren()) do
            if Zone:IsA("BasePart") then
                local TouchInterest = Zone:FindFirstChildOfClass("TouchInterest") or
                                          Zone:FindFirstChildOfClass("TouchTransmitter")

                if TouchInterest then
                    HasActiveWaveInterest = true
                    break
                end
            end
        end
    end

    -- =========================================================
    -- STEP 1: TRIGGER SENSOR WAVE
    -- =========================================================

    if WaveSpawnTouch and HasActiveWaveInterest then
        local CurrentTime = os.clock()

        if CurrentTime - LastWaveTriggerAttempt < WAVE_TRIGGER_COOLDOWN then
            return
        end

        local ActiveTouchZone = nil
        local ClosestZoneDistance = math.huge

        for _, Zone in ipairs(WaveSpawnTouch:GetChildren()) do
            if Zone:IsA("BasePart") then
                local TouchInterest = Zone:FindFirstChildOfClass("TouchInterest") or
                                          Zone:FindFirstChildOfClass("TouchTransmitter")

                if TouchInterest then
                    local Distance = (MyRoot.Position - Zone.Position).Magnitude

                    if Distance < ClosestZoneDistance and Distance <= 9999 then
                        ClosestZoneDistance = Distance
                        ActiveTouchZone = Zone
                    end
                end
            end
        end

        if ActiveTouchZone then
            LastWaveTriggerAttempt = CurrentTime

            print("🌊 [SmartTrigger] Mengunci Wave Aktif: " .. ActiveTouchZone:GetFullName())

            local TargetPosition =
                Vector3.new(ActiveTouchZone.Position.X, MyRoot.Position.Y, ActiveTouchZone.Position.Z)

            MyRoot.CFrame = CFrame.new(TargetPosition)
            MyRoot.AssemblyLinearVelocity = Vector3.zero
            MyRoot.AssemblyAngularVelocity = Vector3.zero

            if firetouchinterest then
                firetouchinterest(MyRoot, ActiveTouchZone, 0)

                task.wait(0.02)

                firetouchinterest(MyRoot, ActiveTouchZone, 1)
            end

            task.wait(0.5)
            return
        end
    end

    -- Jangan mencari portal selama wave masih aktif
    if HasActiveWaveInterest then
        return
    end

    -- Tunggu map selesai dimuat
    if os.clock() < MatchLoadTimer then
        return
    end

    -- =========================================================
    -- STEP 2: SCANNING PORTAL
    -- =========================================================

    local BestPortalPart = nil
    local HighestScore = 0
    local ClosestDistance = math.huge

    for _, Object in ipairs(workspace:GetDescendants()) do
        if Object:IsA("BasePart") then
            local HasTrigger = Object:FindFirstChildOfClass("TouchTransmitter") or
                                   Object:FindFirstChildOfClass("TouchInterest") or
                                   Object:FindFirstChildOfClass("ProximityPrompt")

            if HasTrigger then
                local DistanceToPortal = (MyRoot.Position - Object.Position).Magnitude

                if DistanceToPortal <= MaxPortalDistance then
                    local CurrentScore = 0

                    local LowerName = string.lower(Object.Name)

                    local ParentName = ""

                    if Object.Parent then
                        ParentName = string.lower(Object.Parent.Name)
                    end

                    -- Abaikan collision part umum
                    if string.find(LowerName, "collide") then
                        CurrentScore = -100
                    end

                    -- Hindari MapTeleport pada endless tower
                    if IsEndlessTower and string.find(LowerName, "mapteleport") then
                        CurrentScore = -100
                    end

                    if CurrentScore >= 0 then
                        if string.find(LowerName, "portal") or string.find(ParentName, "portal") or
                            string.find(LowerName, "door") or string.find(ParentName, "door") or
                            string.find(LowerName, "gate") or string.find(ParentName, "gate") or
                            string.find(LowerName, "pintu") or string.find(ParentName, "pintu") then

                            CurrentScore = CurrentScore + 10

                        elseif string.find(LowerName, "next") or string.find(ParentName, "next") or
                            string.find(LowerName, "exit") or string.find(ParentName, "exit") or
                            string.find(LowerName, "finish") or string.find(ParentName, "finish") or
                            string.find(LowerName, "teleport") or string.find(ParentName, "teleport") then

                            CurrentScore = CurrentScore + 4
                        end

                        -- Memiliki trigger
                        CurrentScore = CurrentScore + 3

                        if LowerName == "root" then
                            CurrentScore = CurrentScore + 2
                        end

                        if Object.Material == Enum.Material.Neon then
                            CurrentScore = CurrentScore + 2
                        end

                        if Object.Size.Y > 4 and Object.Size.X > 4 then
                            CurrentScore = CurrentScore + 1
                        end
                    end

                    if CurrentScore > HighestScore then
                        HighestScore = CurrentScore
                        BestPortalPart = Object
                        ClosestDistance = DistanceToPortal

                    elseif CurrentScore == HighestScore and CurrentScore > 0 and DistanceToPortal < ClosestDistance then

                        BestPortalPart = Object
                        ClosestDistance = DistanceToPortal
                    end
                end
            end
        end
    end

    local RequiredScore = 10

    if IsEndlessTower then
        RequiredScore = 3
    end

    -- Tidak menemukan portal valid
    if not BestPortalPart or HighestScore < RequiredScore then

        if IsEndlessTower then
            IsEnteringPortal = false
            PortalCooldown = false
        end

        return
    end

    -- Portal yang sama sudah pernah digunakan
    if IsPortalAlreadyUsed(BestPortalPart) then
        return
    end

    -- =========================================================
    -- STEP 3: MASUK PORTAL
    -- =========================================================

    IsEnteringPortal = true
    PortalCooldown = true

    LastPortal = BestPortalPart
    LastPortalPosition = BestPortalPart.Position
    LastPortalAttemptTime = os.clock()

    print("🚪 [Portal] Sukses Mengunci Portal Utama: " .. BestPortalPart:GetFullName() .. " (Skor: " ..
              tostring(HighestScore) .. ", Jarak: " .. string.format("%.1f", ClosestDistance) .. ")")

    TriggerPortalInteraction(MyRoot, BestPortalPart, not IsEndlessTower)

    IsEnteringPortal = false

    task.spawn(function()
        task.wait(PORTAL_COOLDOWN_DURATION)

        PortalCooldown = false

        -- Hanya hapus portal terakhir apabila instance lama
        -- memang sudah hilang dari workspace.
        if LastPortal and not LastPortal.Parent then
            LastPortal = nil
            LastPortalPosition = nil
            LastPortalAttemptTime = 0
        end
    end)
end

-- INTERCEPTOR SCAN REPLAY DEEP AREA
local function IsGuiVisible(obj)
    if not obj or not obj.Parent then
        return false
    end
    if obj:IsA("GuiObject") and (not obj.Visible or obj.AbsolutePosition.Y <= 0) then
        return false
    end
    local parent = obj.Parent
    while parent and parent ~= game do
        if parent:IsA("GuiObject") and not parent.Visible then
            return false
        end
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
                local parentButton = obj:FindFirstAncestorWhichIsA("TextButton") or
                                         obj:FindFirstAncestorWhichIsA("ImageButton") or obj.Parent
                if IsGuiVisible(parentButton) then
                    return parentButton
                end
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
    if not PlayerGui then
        return
    end
    local SemuaGui = PlayerGui:GetDescendants()
    if not HasVisibleText(SemuaGui, "you died") then
        return
    end

    local GiveUpButton = FindVisibleButtonByText(SemuaGui, "give up")
    if GiveUpButton then
        print("[Auto Death] You died detected. Clicking Give up...")
        Target = nil
        EksekusiKlikReplay(GiveUpButton)
        task.wait(5.0)
    end
end

local function GetReturnToLobbyButton()
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local ResultGui = PlayerGui and PlayerGui:FindFirstChild("ResultGui")
    local ScreenSettlement = ResultGui and ResultGui:FindFirstChild("ScreenSettlement")
    local BtnGroup = ScreenSettlement and ScreenSettlement:FindFirstChild("BtnGroup")
    return BtnGroup and BtnGroup:FindFirstChild("ReturnToLobbyBtn")
end

local function ScanAndExecuteReplay()
    if not _G.AutoReplay then
        return
    end
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not PlayerGui then
        return
    end

    local ReplayButton = nil
    local SemuaGui = PlayerGui:GetDescendants()
    if not HasVictoryUi(SemuaGui) then
        return
    end

    local BackpackOk, CurrentOres, MaxOres = pcall(UpdateSellPendingFromBackpack)
    local BackpackFull = BackpackOk and MaxOres > 0 and CurrentOres >= MaxOres
    if BackpackFull then
        local ReturnButton = GetReturnToLobbyButton()
        if ReturnButton and IsGuiVisible(ReturnButton) then
            print("[Auto Replay] Sell pending (" .. tostring(SellPendingReason or "unknown") ..
                      "); returning to lobby before replay")
            Target = nil
            task.wait(5.0)

            ReturnButton = GetReturnToLobbyButton()
            if HasVictoryUi(PlayerGui:GetDescendants()) and ReturnButton and IsGuiVisible(ReturnButton) then
                EksekusiKlikReplay(ReturnButton)
                task.wait(8.0)
            end
        end
        return
    end

    for i = 1, #SemuaGui do
        local obj = SemuaGui[i]

        if obj:IsA("TextLabel") then
            local textLower = string.lower(obj.Text)
            if string.find(textLower, "play") and string.find(textLower, "again") then
                local parentButton = obj:FindFirstAncestorWhichIsA("TextButton") or
                                         obj:FindFirstAncestorWhichIsA("ImageButton") or obj.Parent
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
        if _G.AutoFarm and not RejoinWatchdog.BlocksAutomation() then
            if IsInLobby() then
                Target = nil
                TargetKind = nil
                IsEgg = false
                task.wait(0.5)
            elseif IsEgg and Target and Target.Parent and os.clock() < EggLockEnd then
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
    if not MyRoot or not MyHumanoid or IsEnteringPortal or not _G.AutoFarm or RejoinWatchdog.BlocksAutomation() or
        IsInLobby() then
        return
    end
    if IsExtractingEgg then
        return
    end
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
        if GroundRay then
            FinalY = GroundRay.Position.Y + CurrentHeight
        else
            FinalY = TargetPos.Y + CurrentHeight
        end
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

    if not IsExtractingEgg and not IsSwitchPending then
        local CurrentDistance = (MyRoot.Position - Target.Position).Magnitude
        if CurrentDistance <= _G.KillAuraRadius then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0, 0))
            local ToolInChar = Character:FindFirstChildOfClass("Tool")
            if ToolInChar then
                ToolInChar:Activate()
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    if _G.AutoFarm and not RejoinWatchdog.BlocksAutomation() and not IsInLobby() and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                if _G.SemiGodMode then
                    local transmitter = part:FindFirstChildOfClass("TouchTransmitter")
                    if transmitter then
                        transmitter:Destroy()
                    end
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
local AutoBuyButtonToggle = Instance.new("TextButton")
local AutoSellButtonToggle = Instance.new("TextButton")
local AutoSeasonBuyButtonToggle = Instance.new("TextButton")
local LabelHeight = Instance.new("TextLabel")
local SliderHeightFrame = Instance.new("Frame")
local SliderHeightButton = Instance.new("TextButton")
StatsLabel = Instance.new("TextLabel")

local OldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("IronSoulDualMenu")
if OldGui then
    OldGui:Destroy()
end

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

AutoBuyButtonToggle.Name = "AutoBuyButtonToggle"
AutoBuyButtonToggle.Parent = ScreenGui
AutoBuyButtonToggle.BackgroundColor3 = _G.AutoBuy and Color3.fromRGB(0, 150, 75) or Color3.fromRGB(180, 40, 40)
AutoBuyButtonToggle.Position = UDim2.new(0.05, 0, 0.41, 88)
AutoBuyButtonToggle.Size = UDim2.new(0, 160, 0, 40)
AutoBuyButtonToggle.Font = Enum.Font.SourceSansBold
AutoBuyButtonToggle.Text = _G.AutoBuy and "AUTO BUY: YES" or "AUTO BUY: NO"
AutoBuyButtonToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoBuyButtonToggle.TextSize = 14
AutoBuyButtonToggle.BorderSizePixel = 2

AutoSellButtonToggle.Name = "AutoSellButtonToggle"
AutoSellButtonToggle.Parent = ScreenGui
AutoSellButtonToggle.BackgroundColor3 = _G.AutoSell and Color3.fromRGB(0, 150, 75) or Color3.fromRGB(180, 40, 40)
AutoSellButtonToggle.Position = UDim2.new(0.05, 0, 0.41, 136)
AutoSellButtonToggle.Size = UDim2.new(0, 160, 0, 40)
AutoSellButtonToggle.Font = Enum.Font.SourceSansBold
AutoSellButtonToggle.Text = _G.AutoSell and "AUTO SELL: YES" or "AUTO SELL: NO"
AutoSellButtonToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoSellButtonToggle.TextSize = 14
AutoSellButtonToggle.BorderSizePixel = 2

AutoSeasonBuyButtonToggle.Name = "AutoSeasonBuyButtonToggle"
AutoSeasonBuyButtonToggle.Parent = ScreenGui
AutoSeasonBuyButtonToggle.BackgroundColor3 = _G.AutoSeasonBuy and Color3.fromRGB(0, 150, 75) or
                                                 Color3.fromRGB(180, 40, 40)
AutoSeasonBuyButtonToggle.Position = UDim2.new(0.05, 0, 0.41, 184)
AutoSeasonBuyButtonToggle.Size = UDim2.new(0, 160, 0, 40)
AutoSeasonBuyButtonToggle.Font = Enum.Font.SourceSansBold
AutoSeasonBuyButtonToggle.Text = _G.AutoSeasonBuy and "SEASON BUY: YES" or "SEASON BUY: NO"
AutoSeasonBuyButtonToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoSeasonBuyButtonToggle.TextSize = 14
AutoSeasonBuyButtonToggle.BorderSizePixel = 2

StatsLabel.Name = "StatsLabel"
StatsLabel.Parent = ScreenGui
StatsLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
StatsLabel.BackgroundTransparency = 0.15
StatsLabel.Position = UDim2.new(0.05, 0, 0.41, 232)
StatsLabel.Size = UDim2.new(0, 160, 0, 64)
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
    return
        math.clamp((input.Position.X - SliderHeightFrame.AbsolutePosition.X) / SliderHeightFrame.AbsoluteSize.X, 0, 1)
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
    if ActiveSlider and
        (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
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

AutoBuyButtonToggle.MouseButton1Click:Connect(function()
    _G.AutoBuy = not _G.AutoBuy
    if _G.AutoBuy then
        AutoBuyButtonToggle.Text = "AUTO BUY: YES"
        AutoBuyButtonToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 75)
    else
        AutoBuyButtonToggle.Text = "AUTO BUY: NO"
        AutoBuyButtonToggle.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
    SaveConfig()
end)

AutoSellButtonToggle.MouseButton1Click:Connect(function()
    _G.AutoSell = not _G.AutoSell
    if _G.AutoSell then
        AutoSellButtonToggle.Text = "AUTO SELL: YES"
        AutoSellButtonToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 75)
    else
        AutoSellButtonToggle.Text = "AUTO SELL: NO"
        AutoSellButtonToggle.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
    SaveConfig()
end)

AutoSeasonBuyButtonToggle.MouseButton1Click:Connect(function()
    _G.AutoSeasonBuy = not _G.AutoSeasonBuy
    if _G.AutoSeasonBuy then
        AutoSeasonBuyButtonToggle.Text = "SEASON BUY: YES"
        AutoSeasonBuyButtonToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 75)
    else
        AutoSeasonBuyButtonToggle.Text = "SEASON BUY: NO"
        AutoSeasonBuyButtonToggle.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
    SaveConfig()
end)

function AutoForge.BuildMenuPage(Context)
    local Theme = Context.Theme
    local Page = Instance.new("Frame")
    Page.Name = Context.Name or "AutoForgePage"
    Page.Size = UDim2.fromScale(1, 1)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.Parent = Context.Parent

    local ToggleButton = Context.CreateButton(Page, "")
    ToggleButton.Position = UDim2.fromOffset(0, 0)
    ToggleButton.Size = UDim2.new(1, 0, 0, 30)

    local RecipeButton = Context.CreateButton(Page, "")
    RecipeButton.Position = UDim2.fromOffset(0, 34)
    RecipeButton.Size = UDim2.new(1, 0, 0, 30)
    RecipeButton.TextXAlignment = Enum.TextXAlignment.Left

    local RecipeOptions = Instance.new("ScrollingFrame")
    RecipeOptions.Name = "AutoForgeRecipeOptions"
    RecipeOptions.Position = UDim2.fromOffset(0, 68)
    RecipeOptions.Size = UDim2.new(1, 0, 0, 180)
    RecipeOptions.BackgroundColor3 = Theme.Surface
    RecipeOptions.BorderSizePixel = 0
    RecipeOptions.ScrollBarThickness = 3
    RecipeOptions.ScrollBarImageColor3 = Theme.Accent
    RecipeOptions.AutomaticCanvasSize = Enum.AutomaticSize.Y
    RecipeOptions.CanvasSize = UDim2.fromOffset(0, 0)
    RecipeOptions.Visible = false
    RecipeOptions.ZIndex = 40
    RecipeOptions.Parent = Page
    Context.AddCorner(RecipeOptions, 6)
    Context.AddStroke(RecipeOptions, Theme.Accent)
    local RecipePadding = Instance.new("UIPadding")
    RecipePadding.PaddingTop = UDim.new(0, 5)
    RecipePadding.PaddingBottom = UDim.new(0, 5)
    RecipePadding.PaddingLeft = UDim.new(0, 5)
    RecipePadding.PaddingRight = UDim.new(0, 5)
    RecipePadding.Parent = RecipeOptions
    local RecipeLayout = Instance.new("UIListLayout")
    RecipeLayout.Padding = UDim.new(0, 4)
    RecipeLayout.Parent = RecipeOptions

    local CraftCountInput = Instance.new("TextBox")
    CraftCountInput.Name = "AutoForgeCraftCount"
    CraftCountInput.Position = UDim2.fromOffset(0, 68)
    CraftCountInput.Size = UDim2.new(0.46, 0, 0, 30)
    CraftCountInput.BackgroundColor3 = Theme.Surface
    CraftCountInput.BorderSizePixel = 0
    CraftCountInput.ClearTextOnFocus = false
    CraftCountInput.Font = Enum.Font.GothamMedium
    CraftCountInput.PlaceholderText = "Craft count"
    CraftCountInput.TextColor3 = Theme.Text
    CraftCountInput.TextSize = 12
    CraftCountInput.Parent = Page
    Context.AddCorner(CraftCountInput, 6)
    Context.AddStroke(CraftCountInput)

    local StartButton = Context.CreateButton(Page, "START FORGE")
    StartButton.Position = UDim2.new(0.48, 0, 0, 68)
    StartButton.Size = UDim2.new(0.52, 0, 0, 30)

    local Summary = Context.CreateText(Page, "", 10, Theme.Muted)
    Summary.Position = UDim2.fromOffset(4, 102)
    Summary.Size = UDim2.new(1, -8, 0, 32)
    Summary.TextWrapped = true
    Summary.TextYAlignment = Enum.TextYAlignment.Top

    local SearchBox = Instance.new("TextBox")
    SearchBox.Name = "AutoForgeOreSearch"
    SearchBox.Position = UDim2.fromOffset(0, 138)
    SearchBox.Size = UDim2.new(1, -166, 0, 28)
    SearchBox.BackgroundColor3 = Theme.Surface
    SearchBox.BorderSizePixel = 0
    SearchBox.ClearTextOnFocus = false
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.PlaceholderText = "Search ore..."
    SearchBox.PlaceholderColor3 = Theme.Muted
    SearchBox.Text = ""
    SearchBox.TextColor3 = Theme.Text
    SearchBox.TextSize = 11
    SearchBox.Parent = Page
    Context.AddCorner(SearchBox, 6)
    Context.AddStroke(SearchBox)

    local ForgeRarityFilterButton = Context.CreateButton(Page, "RARITY: All ▼")
    ForgeRarityFilterButton.Name = "AutoForgeRarityFilter"
    ForgeRarityFilterButton.Position = UDim2.new(1, -162, 0, 138)
    ForgeRarityFilterButton.Size = UDim2.fromOffset(96, 28)
    ForgeRarityFilterButton.TextSize = 10

    local RefreshButton = Context.CreateButton(Page, "REFRESH")
    RefreshButton.Position = UDim2.new(1, -60, 0, 138)
    RefreshButton.Size = UDim2.fromOffset(60, 28)
    RefreshButton.TextSize = 10

    local ForgeRarityOptions = Instance.new("Frame")
    ForgeRarityOptions.Name = "AutoForgeRarityOptions"
    ForgeRarityOptions.Position = UDim2.new(1, -162, 0, 170)
    ForgeRarityOptions.Size = UDim2.fromOffset(96, 10)
    ForgeRarityOptions.BackgroundColor3 = Theme.Panel
    ForgeRarityOptions.BorderSizePixel = 0
    ForgeRarityOptions.Visible = false
    ForgeRarityOptions.ZIndex = 20
    ForgeRarityOptions.Parent = Page
    Context.AddCorner(ForgeRarityOptions, 6)
    Context.AddStroke(ForgeRarityOptions, Theme.Accent)
    local ForgeRarityOptionsPadding = Instance.new("UIPadding")
    ForgeRarityOptionsPadding.PaddingTop = UDim.new(0, 5)
    ForgeRarityOptionsPadding.PaddingBottom = UDim.new(0, 5)
    ForgeRarityOptionsPadding.PaddingLeft = UDim.new(0, 5)
    ForgeRarityOptionsPadding.PaddingRight = UDim.new(0, 5)
    ForgeRarityOptionsPadding.Parent = ForgeRarityOptions
    local ForgeRarityOptionsLayout = Instance.new("UIListLayout")
    ForgeRarityOptionsLayout.Padding = UDim.new(0, 4)
    ForgeRarityOptionsLayout.Parent = ForgeRarityOptions

    local OreList = Instance.new("ScrollingFrame")
    OreList.Name = "AutoForgeOreList"
    OreList.Position = UDim2.fromOffset(0, 170)
    OreList.Size = UDim2.new(1, 0, 1, -170)
    OreList.BackgroundTransparency = 1
    OreList.BorderSizePixel = 0
    OreList.ScrollBarThickness = 3
    OreList.ScrollBarImageColor3 = Theme.Accent
    OreList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    OreList.CanvasSize = UDim2.fromOffset(0, 0)
    OreList.Parent = Page
    local OreLayout = Instance.new("UIListLayout")
    OreLayout.Padding = UDim.new(0, 4)
    OreLayout.SortOrder = Enum.SortOrder.LayoutOrder
    OreLayout.Parent = OreList

    local PageState = {
        Page = Page,
        RecipeOptions = RecipeOptions,
        Rows = {}
    }

    local FilterRows

    local function ForgeRarityFilterName(Level, Catalog)
        if Level <= 0 then
            return "All"
        end
        for _, Entry in ipairs(Catalog or GetOreCatalog()) do
            if Entry.Rarity == Level then
                return tostring(Entry.RarityName) .. " Lv." .. tostring(Level)
            end
        end
        return "Lv." .. tostring(Level)
    end

    local function RefreshForgeRarityFilterButton(Catalog)
        ForgeRarityFilterButton.Text = "RARITY: " .. ForgeRarityFilterName(AutoForgeRarityFilter, Catalog) .. " ▼"
    end

    local function BuildForgeRarityOptions(Catalog)
        for _, Child in ipairs(ForgeRarityOptions:GetChildren()) do
            if Child:IsA("GuiButton") then
                Child:Destroy()
            end
        end
        local Levels = GetOreRarityLevels(Catalog)
        for _, Level in ipairs(Levels) do
            local Option = Context.CreateButton(ForgeRarityOptions, ForgeRarityFilterName(Level, Catalog))
            Option.Size = UDim2.new(1, 0, 0, 26)
            Option.ZIndex = 21
            Option.Activated:Connect(function()
                AutoForgeRarityFilter = Level
                ForgeRarityOptions.Visible = false
                RefreshForgeRarityFilterButton(Catalog)
                FilterRows()
            end)
        end
        ForgeRarityOptions.Size = UDim2.fromOffset(96, #Levels * 30 + 10)
        RefreshForgeRarityFilterButton(Catalog)
    end

    FilterRows = function()
        local Query = string.lower(SearchBox.Text or "")
        for _, RowState in ipairs(PageState.Rows) do
            local MatchQuery = Query == "" or string.find(RowState.SearchText, Query, 1, true) ~= nil
            local MatchRarity = AutoForgeRarityFilter <= 0 or RowState.Rarity == AutoForgeRarityFilter
            RowState.Gui.Visible = MatchQuery and MatchRarity
        end
    end

    local function RefreshSummary()
        local Recipe = AutoForge.Recipes[AutoForge.RecipeId] or AutoForge.Recipes.WeaponSword
        local Ores, Crystals = AutoForge.GetInventory()
        local Total = AutoForge.GetCompositionTotal(AutoForge.Composition)
        local MaxCrafts, LimitingItemId, Reason = AutoForge.CalculateLimit(Recipe, AutoForge.Composition, Ores, Crystals)
        local RelicText = ""
        if Recipe.RelicId then
            RelicText = " | RELIC " .. tostring(tonumber(Crystals[Recipe.RelicId]) or 0)
        end

        ToggleButton.Text = _G.AutoForge and "AUTO FORGE: ON" or "AUTO FORGE: OFF"
        ToggleButton.BackgroundColor3 = _G.AutoForge and Theme.Enabled or Theme.Disabled
        RecipeButton.Text = "  " .. Recipe.Category .. " - " .. Recipe.Label .. " - " .. tostring(Recipe.OreCount) ..
                                " Ore - " .. tostring(Recipe.Chance) .. "%  \226\150\188"
        if not CraftCountInput:IsFocused() then
            CraftCountInput.Text = "CRAFT COUNT: " .. tostring(AutoForge.RequestedCrafts)
        end

        local Detail = AutoForge.State.Status
        if Reason then
            Detail = Reason
        elseif MaxCrafts < AutoForge.RequestedCrafts then
            Detail = "Adjusted " .. tostring(AutoForge.RequestedCrafts) .. " to " .. tostring(MaxCrafts) ..
                         " - Limited by " .. GetItemDisplayName(LimitingItemId)
        end
        Summary.Text = "ORE " .. tostring(Total) .. "/" .. tostring(Recipe.OreCount) .. " | MAX " ..
                           tostring(MaxCrafts) .. RelicText .. "\n" .. tostring(Detail)
        StartButton.Text = AutoForge.State.Running and "STOP AFTER CRAFT" or "START FORGE"
        StartButton.BackgroundColor3 = AutoForge.State.Running and Theme.Keep or Theme.Accent

        for _, RowState in ipairs(PageState.Rows) do
            local Owned = tonumber(Ores[RowState.ItemId]) or 0
            local Selected = tonumber(AutoForge.Composition[RowState.ItemId]) or 0
            RowState.Owned.Text = "x" .. tostring(Owned)
            RowState.Selected.Text = tostring(Selected)
            RowState.Minus.BackgroundColor3 = Selected > 0 and Theme.Sell or Theme.Disabled
            RowState.Plus.BackgroundColor3 = Owned > Selected and Total < Recipe.OreCount and Theme.Enabled or Theme.Disabled
        end
    end

    local function ClearRows()
        for _, RowState in ipairs(PageState.Rows) do
            RowState.Gui:Destroy()
        end
        PageState.Rows = {}
    end

    local function BuildRows()
        ClearRows()
        local Catalog = GetOreCatalog(true)
        for Index, Entry in ipairs(Catalog) do
            local DisplayName = GetItemDisplayName(Entry.ItemId)
            local Row = Context.CreateButton(OreList, "")
            Row.Name = "ForgeOre_" .. Entry.ItemId
            Row.LayoutOrder = Index
            Row.Size = UDim2.new(1, -2, 0, 38)

            local Name = Context.CreateText(Row, DisplayName, 11)
            Name.Position = UDim2.fromOffset(8, 0)
            Name.Size = UDim2.new(1, -150, 1, 0)

            local Owned = Context.CreateText(Row, "", 10, Theme.Muted, Enum.TextXAlignment.Right)
            Owned.Position = UDim2.new(1, -142, 0, 0)
            Owned.Size = UDim2.fromOffset(38, 38)

            local Minus = Context.CreateButton(Row, "-")
            Minus.Position = UDim2.new(1, -98, 0, 5)
            Minus.Size = UDim2.fromOffset(26, 28)

            local Selected = Context.CreateText(Row, "0", 11, Theme.Text, Enum.TextXAlignment.Center)
            Selected.Position = UDim2.new(1, -68, 0, 0)
            Selected.Size = UDim2.fromOffset(34, 38)

            local Plus = Context.CreateButton(Row, "+")
            Plus.Position = UDim2.new(1, -30, 0, 5)
            Plus.Size = UDim2.fromOffset(26, 28)

            local RowState = {
                Gui = Row,
                ItemId = Entry.ItemId,
                Owned = Owned,
                Minus = Minus,
                Selected = Selected,
                Plus = Plus,
                SearchText = string.lower(DisplayName .. " " .. Entry.ItemId .. " " .. tostring(Entry.RarityName) .. " " .. tostring(Entry.Rarity)),
                Rarity = Entry.Rarity
            }
            table.insert(PageState.Rows, RowState)

            Minus.Activated:Connect(function()
                RecipeOptions.Visible = false
                local Count = tonumber(AutoForge.Composition[Entry.ItemId]) or 0
                if Count > 1 then
                    AutoForge.Composition[Entry.ItemId] = Count - 1
                else
                    AutoForge.Composition[Entry.ItemId] = nil
                end
                SaveConfig()
                RefreshSummary()
            end)
            Plus.Activated:Connect(function()
                RecipeOptions.Visible = false
                local Recipe = AutoForge.Recipes[AutoForge.RecipeId]
                local Ores, _ = AutoForge.GetInventory()
                local OwnedCount = tonumber(Ores[Entry.ItemId]) or 0
                local SelectedCount = tonumber(AutoForge.Composition[Entry.ItemId]) or 0
                if SelectedCount < OwnedCount and AutoForge.GetCompositionTotal(AutoForge.Composition) < Recipe.OreCount then
                    AutoForge.Composition[Entry.ItemId] = SelectedCount + 1
                    SaveConfig()
                    RefreshSummary()
                end
            end)
        end
        BuildForgeRarityOptions(Catalog)
        FilterRows()
        RefreshSummary()
    end

    for _, RecipeId in ipairs(AutoForge.RecipeOrder) do
        local Recipe = AutoForge.Recipes[RecipeId]
        local Option = Context.CreateButton(RecipeOptions, Recipe.Category .. " - " .. Recipe.Label .. " - " ..
            tostring(Recipe.OreCount) .. " Ore - " .. tostring(Recipe.Chance) .. "%")
        Option.Size = UDim2.new(1, 0, 0, 28)
        Option.ZIndex = 41
        Option.Activated:Connect(function()
            RecipeOptions.Visible = false
            AutoForge.RecipeId = RecipeId
            AutoForge.Composition = {}
            AutoForge.State.Status = "SELECT ORE COMPOSITION"
            SaveConfig()
            RefreshSummary()
        end)
    end

    ToggleButton.Activated:Connect(function()
        RecipeOptions.Visible = false
        _G.AutoForge = not _G.AutoForge
        if not _G.AutoForge and AutoForge.State.Running then
            AutoForge.State.Status = "STOP AFTER CURRENT CRAFT"
        end
        SaveConfig()
        RefreshSummary()
    end)
    RecipeButton.Activated:Connect(function()
        RecipeOptions.Visible = not RecipeOptions.Visible
    end)
    CraftCountInput.Focused:Connect(function()
        RecipeOptions.Visible = false
        CraftCountInput.Text = tostring(AutoForge.RequestedCrafts)
    end)
    CraftCountInput.FocusLost:Connect(function()
        AutoForge.RequestedCrafts = math.floor(ClampNumber(CraftCountInput.Text, 1, 999, 1))
        SaveConfig()
        RefreshSummary()
    end)
    StartButton.Activated:Connect(function()
        RecipeOptions.Visible = false
        AutoForge.StartBatch()
        RefreshSummary()
    end)
    SearchBox:GetPropertyChangedSignal("Text"):Connect(FilterRows)
    ForgeRarityFilterButton.Activated:Connect(function()
        RecipeOptions.Visible = false
        ForgeRarityOptions.Visible = not ForgeRarityOptions.Visible
    end)
    RefreshButton.Activated:Connect(function()
        RecipeOptions.Visible = false
        ForgeRarityOptions.Visible = false
        BuildRows()
    end)

    function PageState.Close()
        RecipeOptions.Visible = false
        ForgeRarityOptions.Visible = false
    end
    PageState.Refresh = RefreshSummary
    AutoForge.State.Refresh = RefreshSummary
    BuildRows()
    return PageState
end

function AutoForge.BuildTargetsPage(Context)
    local Theme = Context.Theme
    local Page = Instance.new("Frame")
    Page.Name = "ForgeTargetsPage"
    Page.Size = UDim2.fromScale(1, 1)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.Parent = Context.Parent

    local TargetModeButton = Context.CreateButton(Page, "")
    TargetModeButton.Size = UDim2.new(1, 0, 0, 30)
    local AutoDeleteButton = Context.CreateButton(Page, "")
    AutoDeleteButton.Position = UDim2.fromOffset(0, 34)
    AutoDeleteButton.Size = UDim2.new(1, 0, 0, 30)
    local AddProfileButton = Context.CreateButton(Page, "ADD PROFILE")
    AddProfileButton.Position = UDim2.fromOffset(0, 68)
    AddProfileButton.Size = UDim2.new(1, 0, 0, 30)
    local OrderHint = Context.CreateText(Page, "Enabled profiles are checked top-to-bottom. First match wins.", 9, Theme.Muted)
    OrderHint.Position = UDim2.fromOffset(0, 102)
    OrderHint.Size = UDim2.new(1, 0, 0, 18)

    local ProfileList = Instance.new("ScrollingFrame")
    ProfileList.Name = "TargetProfileList"
    ProfileList.Position = UDim2.fromOffset(0, 124)
    ProfileList.Size = UDim2.new(1, 0, 1, -124)
    ProfileList.BackgroundColor3 = Theme.Background
    ProfileList.BorderSizePixel = 0
    ProfileList.ScrollBarThickness = 3
    ProfileList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ProfileList.CanvasSize = UDim2.fromOffset(0, 0)
    ProfileList.Parent = Page
    Context.AddCorner(ProfileList, 6)
    Context.AddStroke(ProfileList)
    local ProfilePadding = Instance.new("UIPadding")
    ProfilePadding.PaddingTop = UDim.new(0, 5)
    ProfilePadding.PaddingBottom = UDim.new(0, 5)
    ProfilePadding.PaddingLeft = UDim.new(0, 5)
    ProfilePadding.PaddingRight = UDim.new(0, 5)
    ProfilePadding.Parent = ProfileList
    local ProfileLayout = Instance.new("UIListLayout")
    ProfileLayout.Padding = UDim.new(0, 5)
    ProfileLayout.Parent = ProfileList

    local Editor = Instance.new("Frame")
    Editor.Name = "TargetProfileEditor"
    Editor.Size = UDim2.fromScale(1, 1)
    Editor.BackgroundColor3 = Theme.Panel
    Editor.BorderSizePixel = 0
    Editor.Visible = false
    Editor.ZIndex = 50
    Editor.Parent = Page
    Context.AddCorner(Editor, 7)
    Context.AddStroke(Editor, Theme.Accent)

    local EditorTitle = Context.CreateText(Editor, "TARGET PROFILE", 13)
    EditorTitle.Position = UDim2.fromOffset(8, 0)
    EditorTitle.Size = UDim2.new(1, -16, 0, 28)
    EditorTitle.Font = Enum.Font.GothamBold
    EditorTitle.ZIndex = 51
    local NameInput = Instance.new("TextBox")
    NameInput.Position = UDim2.fromOffset(0, 32)
    NameInput.Size = UDim2.new(1, 0, 0, 30)
    NameInput.BackgroundColor3 = Theme.Surface
    NameInput.BorderSizePixel = 0
    NameInput.ClearTextOnFocus = false
    NameInput.PlaceholderText = "Profile name"
    NameInput.TextColor3 = Theme.Text
    NameInput.Font = Enum.Font.Gotham
    NameInput.TextSize = 12
    NameInput.ZIndex = 51
    NameInput.Parent = Editor
    Context.AddCorner(NameInput, 6)
    Context.AddStroke(NameInput)
    local SlotModeButton = Context.CreateButton(Editor, "")
    SlotModeButton.Name = "SlotModeDropdown"
    SlotModeButton.Position = UDim2.fromOffset(0, 66)
    SlotModeButton.Size = UDim2.new(0.64, -3, 0, 30)
    SlotModeButton.ZIndex = 51
    local SlotCountInput = Instance.new("TextBox")
    SlotCountInput.Position = UDim2.new(0.64, 3, 0, 66)
    SlotCountInput.Size = UDim2.new(0.36, -3, 0, 30)
    SlotCountInput.BackgroundColor3 = Theme.Surface
    SlotCountInput.BorderSizePixel = 0
    SlotCountInput.ClearTextOnFocus = false
    SlotCountInput.TextColor3 = Theme.Text
    SlotCountInput.Font = Enum.Font.Gotham
    SlotCountInput.TextSize = 12
    SlotCountInput.ZIndex = 51
    SlotCountInput.Parent = Editor
    Context.AddCorner(SlotCountInput, 6)
    Context.AddStroke(SlotCountInput)
    local PoolPresetButton = Context.CreateButton(Editor, "POOL PRESET: Offensive ▼")
    PoolPresetButton.Name = "PoolPresetDropdown"
    PoolPresetButton.Position = UDim2.fromOffset(0, 100)
    PoolPresetButton.Size = UDim2.new(1, 0, 0, 30)
    PoolPresetButton.ZIndex = 51
    local PoolHint = Context.CreateText(Editor, "Preset fills defaults. You can still edit this profile.", 9, Theme.Muted)
    PoolHint.Position = UDim2.fromOffset(4, 132)
    PoolHint.Size = UDim2.new(1, -8, 0, 16)
    PoolHint.ZIndex = 51
    local PoolTitle = Context.CreateText(Editor, "POOL STATS", 10)
    PoolTitle.Position = UDim2.fromOffset(4, 148)
    PoolTitle.Size = UDim2.new(1, -8, 0, 18)
    PoolTitle.ZIndex = 51
    local PoolList = Instance.new("ScrollingFrame")
    PoolList.Name = "PoolStatsList"
    PoolList.Position = UDim2.fromOffset(0, 168)
    PoolList.Size = UDim2.new(1, 0, 0, 118)
    PoolList.BackgroundColor3 = Theme.Background
    PoolList.BorderSizePixel = 0
    PoolList.ScrollBarThickness = 3
    PoolList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    PoolList.CanvasSize = UDim2.fromOffset(0, 0)
    PoolList.ZIndex = 51
    PoolList.Parent = Editor
    Context.AddCorner(PoolList, 6)
    Context.AddStroke(PoolList)
    local PoolListLayout = Instance.new("UIListLayout")
    PoolListLayout.Padding = UDim.new(0, 4)
    PoolListLayout.Parent = PoolList

    local RulesList = Instance.new("ScrollingFrame")
    RulesList.Name = "TargetRuleList"
    RulesList.Position = UDim2.fromOffset(0, 292)
    RulesList.Size = UDim2.new(1, 0, 1, -366)
    RulesList.BackgroundColor3 = Theme.Background
    RulesList.BorderSizePixel = 0
    RulesList.ScrollBarThickness = 3
    RulesList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    RulesList.CanvasSize = UDim2.fromOffset(0, 0)
    RulesList.ZIndex = 51
    RulesList.Parent = Editor
    Context.AddCorner(RulesList, 6)
    Context.AddStroke(RulesList)
    local RulesPadding = Instance.new("UIPadding")
    RulesPadding.PaddingTop = UDim.new(0, 5)
    RulesPadding.PaddingBottom = UDim.new(0, 5)
    RulesPadding.PaddingLeft = UDim.new(0, 5)
    RulesPadding.PaddingRight = UDim.new(0, 5)
    RulesPadding.Parent = RulesList
    local RulesLayout = Instance.new("UIListLayout")
    RulesLayout.Padding = UDim.new(0, 5)
    RulesLayout.Parent = RulesList

    local ErrorLabel = Context.CreateText(Editor, "", 10, Theme.Keep)
    ErrorLabel.Position = UDim2.new(0, 4, 1, -74)
    ErrorLabel.Size = UDim2.new(1, -8, 0, 18)
    ErrorLabel.ZIndex = 51
    local AddRuleButton = Context.CreateButton(Editor, "ADD RULE")
    AddRuleButton.Position = UDim2.new(0, 0, 1, -48)
    AddRuleButton.Size = UDim2.new(0.34, -3, 0, 30)
    AddRuleButton.ZIndex = 51
    local SaveButton = Context.CreateButton(Editor, "SAVE")
    SaveButton.Position = UDim2.new(0.34, 3, 1, -48)
    SaveButton.Size = UDim2.new(0.33, -3, 0, 30)
    SaveButton.ZIndex = 51
    local CancelButton = Context.CreateButton(Editor, "CANCEL")
    CancelButton.Position = UDim2.new(0.67, 3, 1, -48)
    CancelButton.Size = UDim2.new(0.33, -3, 0, 30)
    CancelButton.ZIndex = 51

    local Picker = Instance.new("Frame")
    Picker.Name = "TargetEditorPicker"
    Picker.Size = UDim2.fromScale(1, 1)
    Picker.BackgroundColor3 = Theme.Panel
    Picker.BorderSizePixel = 0
    Picker.Visible = false
    Picker.ZIndex = 60
    Picker.Parent = Editor
    Context.AddCorner(Picker, 7)
    Context.AddStroke(Picker, Theme.Accent)
    local PickerTitle = Context.CreateText(Picker, "SELECT", 13)
    PickerTitle.Size = UDim2.new(1, -70, 0, 30)
    PickerTitle.Position = UDim2.fromOffset(8, 0)
    PickerTitle.ZIndex = 61
    local PickerClose = Context.CreateButton(Picker, "CLOSE")
    PickerClose.AnchorPoint = Vector2.new(1, 0)
    PickerClose.Position = UDim2.new(1, 0, 0, 0)
    PickerClose.Size = UDim2.fromOffset(64, 30)
    PickerClose.ZIndex = 61
    local PickerList = Instance.new("ScrollingFrame")
    PickerList.Position = UDim2.fromOffset(0, 36)
    PickerList.Size = UDim2.new(1, 0, 1, -36)
    PickerList.BackgroundColor3 = Theme.Background
    PickerList.BorderSizePixel = 0
    PickerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    PickerList.CanvasSize = UDim2.fromOffset(0, 0)
    PickerList.ScrollBarThickness = 3
    PickerList.ZIndex = 61
    PickerList.Parent = Picker
    local PickerLayout = Instance.new("UIListLayout")
    PickerLayout.Padding = UDim.new(0, 5)
    PickerLayout.Parent = PickerList

    local Draft = nil
    local EditingIndex = nil
    local RefreshProfiles
    local RefreshEditor

    local function CopyProfile(Profile)
        local Copy = {Id = Profile.Id, Name = Profile.Name, Enabled = Profile.Enabled, SlotMode = Profile.SlotMode,
            SlotCount = Profile.SlotCount, PoolPreset = Profile.PoolPreset, PoolStats = {}, Rules = {}}
        for _, StatId in ipairs(Profile.PoolStats or {}) do
            table.insert(Copy.PoolStats, StatId)
        end
        for _, Rule in ipairs(Profile.Rules or {}) do
            table.insert(Copy.Rules, CopyMap(Rule))
        end
        return Copy
    end

    local function OpenPicker(Title, Entries, OnSelect)
        for _, Child in ipairs(PickerList:GetChildren()) do
            if Child:IsA("GuiButton") then
                Child:Destroy()
            end
        end
        PickerTitle.Text = Title
        for _, Entry in ipairs(Entries) do
            local Option = Context.CreateButton(PickerList, Entry.Label)
            Option.Size = UDim2.new(1, 0, 0, 30)
            Option.ZIndex = 62
            Option.Activated:Connect(function()
                Picker.Visible = false
                OnSelect(Entry.Value)
            end)
        end
        Picker.Visible = true
    end

    local function ProfileSummary(Profile)
        return AutoForge.BuildProfileSummary(Profile)
    end

    local function OpenEditor(Profile, Index)
        Draft = CopyProfile(Profile)
        EditingIndex = Index
        Editor.Visible = true
        Picker.Visible = false
        RefreshEditor()
    end

    RefreshEditor = function()
        if not Draft then
            return
        end
        NameInput.Text = Draft.Name or ""
        SlotModeButton.Text = "TOTAL SLOTS: " .. (Draft.SlotMode == "Any" and "Any Total Slots" or (Draft.SlotMode == "Exact" and "Exact N Slots" or "At Least N Slots")) .. " ▼"
        SlotCountInput.Text = tostring(Draft.SlotCount or 1)
        SlotCountInput.Visible = Draft.SlotMode ~= "Any"
        PoolPresetButton.Text = "POOL PRESET: " .. tostring(Draft.PoolPreset or "Offensive") .. " ▼"
        for _, Child in ipairs(PoolList:GetChildren()) do
            if Child:IsA("GuiButton") then
                Child:Destroy()
            end
        end
        local PoolLookup = AutoForge.BuildPoolLookup(Draft.PoolStats)
        for _, Stat in ipairs(AutoForge.BuildStatCatalog()) do
            local Checked = PoolLookup[Stat.StatId] == true
            local PoolButton = Context.CreateButton(PoolList, (Checked and "[x] " or "[ ] ") .. Stat.DisplayName .. " (" .. Stat.StatId .. ")")
            PoolButton.Size = UDim2.new(1, 0, 0, 24)
            PoolButton.ZIndex = 52
            PoolButton.Activated:Connect(function()
                local NewPool = {}
                local Seen = {}
                local Removed = false
                for _, StatId in ipairs(Draft.PoolStats or {}) do
                    if StatId == Stat.StatId and not Removed then
                        Removed = true
                    elseif not Seen[StatId] then
                        Seen[StatId] = true
                        table.insert(NewPool, StatId)
                    end
                end
                if not Removed then
                    table.insert(NewPool, Stat.StatId)
                end
                Draft.PoolStats = NewPool
                RefreshEditor()
            end)
        end
        for _, Child in ipairs(RulesList:GetChildren()) do
            if Child:IsA("Frame") then
                Child:Destroy()
            end
        end
        for RuleIndex, Rule in ipairs(Draft.Rules or {}) do
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, -2, 0, 66)
            Row.BackgroundColor3 = Theme.Surface
            Row.BorderSizePixel = 0
            Row.ZIndex = 52
            Row.Parent = RulesList
            Context.AddCorner(Row, 5)
            local KindButton = Context.CreateButton(Row, Rule.Kind == "PoolAtLeast" and "At Least N From Pool" or (Rule.Kind == "PoolOnly" and "Only From Pool" or "Require Stat"))
            KindButton.Name = "RuleTypeDropdown"
            KindButton.Position = UDim2.fromOffset(4, 4)
            KindButton.Size = UDim2.new(0.48, -6, 0, 26)
            KindButton.ZIndex = 53
            local ValueButton = Context.CreateButton(Row, Rule.Kind == "RequireStat" and tostring(Rule.StatId or "CHDmgBonus") or "Pool")
            ValueButton.Name = Rule.Kind == "RequireStat" and "SpecificStatDropdown" or "GroupDropdown"
            ValueButton.Position = UDim2.new(0.48, 2, 0, 4)
            ValueButton.Size = UDim2.new(0.52, -36, 0, 26)
            ValueButton.ZIndex = 53
            local DeleteButton = Context.CreateButton(Row, "X")
            DeleteButton.AnchorPoint = Vector2.new(1, 0)
            DeleteButton.Position = UDim2.new(1, -4, 0, 4)
            DeleteButton.Size = UDim2.fromOffset(28, 26)
            DeleteButton.ZIndex = 53
            local MinInput = Instance.new("TextBox")
            MinInput.Position = UDim2.fromOffset(4, 35)
            MinInput.Size = UDim2.new(1, -8, 0, 26)
            MinInput.BackgroundColor3 = Theme.Background
            MinInput.BorderSizePixel = 0
            MinInput.ClearTextOnFocus = false
            MinInput.Text = Rule.Kind == "PoolOnly" and "ONLY FROM POOL" or tostring(Rule.MinCount or 1)
            MinInput.TextColor3 = Theme.Text
            MinInput.Font = Enum.Font.Gotham
            MinInput.TextSize = 11
            MinInput.TextEditable = Rule.Kind ~= "PoolOnly"
            MinInput.ZIndex = 53
            MinInput.Parent = Row
            Context.AddCorner(MinInput, 5)
            KindButton.Activated:Connect(function()
                OpenPicker("RULE TYPE", {
                    {Label = "At Least N From Pool", Value = "PoolAtLeast"}, {Label = "Only From Pool", Value = "PoolOnly"},
                    {Label = "Require Stat", Value = "RequireStat"}
                }, function(Value)
                    Rule.Kind = Value
                    Rule.StatId = Value == "RequireStat" and (Rule.StatId or "CHDmgBonus") or nil
                    Rule.MinCount = Value == "PoolOnly" and nil or (Rule.MinCount or 1)
                    RefreshEditor()
                end)
            end)
            ValueButton.Activated:Connect(function()
                if Rule.Kind ~= "RequireStat" then
                    return
                end
                local Entries = {}
                for _, Stat in ipairs(AutoForge.BuildStatCatalog()) do
                    table.insert(Entries, {Label = Stat.DisplayName .. " (" .. Stat.StatId .. ")", Value = Stat.StatId})
                end
                OpenPicker("REQUIRE STAT", Entries, function(Value)
                    Rule.StatId = Value
                    RefreshEditor()
                end)
            end)
            DeleteButton.Activated:Connect(function()
                table.remove(Draft.Rules, RuleIndex)
                RefreshEditor()
            end)
            MinInput.FocusLost:Connect(function()
                if Rule.Kind ~= "PoolOnly" then
                    Rule.MinCount = math.floor(ClampNumber(MinInput.Text, 1, 10, 1))
                    RefreshEditor()
                end
            end)
        end
        local Valid, ErrorMessage = AutoForge.ValidateProfile(Draft)
        ErrorLabel.Text = Valid and "" or tostring(ErrorMessage)
        SaveButton.BackgroundColor3 = Valid and Theme.Enabled or Theme.Disabled
    end

    RefreshProfiles = function()
        TargetModeButton.Text = "TARGET MODE: " .. (AutoForge.TargetMode and "ON" or "OFF")
        TargetModeButton.BackgroundColor3 = AutoForge.TargetMode and Theme.Enabled or Theme.Disabled
        AutoDeleteButton.Text = "AUTO DELETE NON-MATCH: " .. (AutoForge.AutoDeleteNonMatch and "ON" or "OFF")
        AutoDeleteButton.BackgroundColor3 = AutoForge.AutoDeleteNonMatch and Theme.Keep or Theme.Disabled
        for _, Child in ipairs(ProfileList:GetChildren()) do
            if Child:IsA("Frame") then
                Child:Destroy()
            end
        end
        for Index, Profile in ipairs(AutoForge.Profiles) do
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, -2, 0, 78)
            Row.BackgroundColor3 = Theme.Surface
            Row.BorderSizePixel = 0
            Row.Parent = ProfileList
            Context.AddCorner(Row, 5)
            local EnabledButton = Context.CreateButton(Row, Profile.Enabled and "✓" or "")
            EnabledButton.Position = UDim2.fromOffset(5, 5)
            EnabledButton.Size = UDim2.fromOffset(28, 28)
            EnabledButton.BackgroundColor3 = Profile.Enabled and Theme.Enabled or Theme.Disabled
            local Name = Context.CreateText(Row, Profile.Name, 11)
            Name.Position = UDim2.fromOffset(38, 3)
            Name.Size = UDim2.new(1, -42, 0, 28)
            local Summary = Context.CreateText(Row, Profile.ValidationError or ProfileSummary(Profile), 9,
                Profile.ValidationError and Theme.Keep or Theme.Muted)
            Summary.Position = UDim2.fromOffset(6, 32)
            Summary.Size = UDim2.new(1, -12, 0, 18)
            local Edit = Context.CreateButton(Row, "EDIT")
            Edit.Position = UDim2.fromOffset(5, 52)
            Edit.Size = UDim2.new(0.34, -5, 0, 22)
            local Duplicate = Context.CreateButton(Row, "COPY")
            Duplicate.Position = UDim2.new(0.34, 2, 0, 52)
            Duplicate.Size = UDim2.new(0.33, -4, 0, 22)
            local Delete = Context.CreateButton(Row, "DELETE")
            Delete.Position = UDim2.new(0.67, 2, 0, 52)
            Delete.Size = UDim2.new(0.33, -7, 0, 22)
            EnabledButton.Activated:Connect(function()
                local Valid = AutoForge.ValidateProfile(Profile)
                Profile.Enabled = Valid and not Profile.Enabled or false
                SaveConfig()
                RefreshProfiles()
            end)
            Edit.Activated:Connect(function() OpenEditor(Profile, Index) end)
            Duplicate.Activated:Connect(function()
                local Copy = CopyProfile(Profile)
                Copy.Id = nil
                Copy.Name = Copy.Name .. " Copy"
                Copy.Enabled = false
                local Normalized = AutoForge.NormalizeProfiles({Copy})[1]
                table.insert(AutoForge.Profiles, Normalized)
                SaveConfig()
                RefreshProfiles()
            end)
            Delete.Activated:Connect(function()
                table.remove(AutoForge.Profiles, Index)
                SaveConfig()
                RefreshProfiles()
            end)
        end
    end

    TargetModeButton.Activated:Connect(function()
        AutoForge.TargetMode = not AutoForge.TargetMode
        SaveConfig()
        RefreshProfiles()
    end)
    AutoDeleteButton.Activated:Connect(function()
        AutoForge.AutoDeleteNonMatch = not AutoForge.AutoDeleteNonMatch
        SaveConfig()
        RefreshProfiles()
    end)
    AddProfileButton.Activated:Connect(function()
        OpenEditor(AutoForge.CreateDefaultProfile(#AutoForge.Profiles + 1), nil)
    end)
    SlotModeButton.Activated:Connect(function()
        OpenPicker("TOTAL SLOTS", {{Label = "Any Total Slots", Value = "Any"}, {Label = "Exact N Slots", Value = "Exact"},
            {Label = "At Least N Slots", Value = "AtLeast"}}, function(Value)
            Draft.SlotMode = Value
            RefreshEditor()
        end)
    end)
    PoolPresetButton.Activated:Connect(function()
        OpenPicker("POOL PRESET", {{Label = "Offensive", Value = "Offensive"}, {Label = "Custom Empty", Value = "Custom"}}, function(Value)
            Draft.PoolPreset = Value
            Draft.PoolStats = Value == "Offensive" and AutoForge.GetDefaultPoolStats() or {}
            RefreshEditor()
        end)
    end)
    SlotCountInput.FocusLost:Connect(function()
        Draft.SlotCount = math.floor(ClampNumber(SlotCountInput.Text, 1, 10, 1))
        RefreshEditor()
    end)
    AddRuleButton.Activated:Connect(function()
        table.insert(Draft.Rules, {Kind = "PoolAtLeast", MinCount = 3})
        RefreshEditor()
    end)
    SaveButton.Activated:Connect(function()
        Draft.Name = NameInput.Text ~= "" and NameInput.Text or "Target Profile"
        local Valid, ErrorMessage = AutoForge.ValidateProfile(Draft)
        if not Valid then
            ErrorLabel.Text = tostring(ErrorMessage)
            return
        end
        local Normalized = AutoForge.NormalizeProfiles({Draft})[1]
        if EditingIndex then
            AutoForge.Profiles[EditingIndex] = Normalized
        else
            table.insert(AutoForge.Profiles, Normalized)
        end
        SaveConfig()
        Editor.Visible = false
        RefreshProfiles()
    end)
    CancelButton.Activated:Connect(function() Editor.Visible = false end)
    PickerClose.Activated:Connect(function() Picker.Visible = false end)

    local PageState = {Page = Page}
    function PageState.Close()
        Picker.Visible = false
        Editor.Visible = false
    end
    function PageState.CloseDropdowns()
        Picker.Visible = false
    end
    PageState.Refresh = RefreshProfiles
    RefreshProfiles()
    return PageState
end

function _G.BugonBuildV6Menu()
-- V6 NATIVE D3D-STYLE MENU
for _, OldControl in ipairs({MasterButton, ModeButton, ReplayButtonToggle, ForgeButtonToggle, AutoBuyButtonToggle,
                             AutoSellButtonToggle, AutoSeasonBuyButtonToggle, LabelHeight, SliderHeightFrame, StatsLabel}) do
    OldControl.Visible = false
end

local Theme = {
    Background = Color3.fromRGB(13, 16, 22),
    Panel = Color3.fromRGB(20, 24, 32),
    Surface = Color3.fromRGB(28, 33, 43),
    SurfaceHover = Color3.fromRGB(36, 43, 56),
    Border = Color3.fromRGB(58, 68, 86),
    Text = Color3.fromRGB(235, 239, 247),
    Muted = Color3.fromRGB(147, 158, 179),
    Accent = Color3.fromRGB(71, 134, 255),
    Enabled = Color3.fromRGB(40, 190, 112),
    Disabled = Color3.fromRGB(91, 101, 119),
    Sell = Color3.fromRGB(230, 157, 52),
    Keep = Color3.fromRGB(217, 75, 75)
}

local function AddCorner(Object, Radius)
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, Radius or 6)
    Corner.Parent = Object
    return Corner
end

local function AddStroke(Object, Color, Thickness)
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color or Theme.Border
    Stroke.Thickness = Thickness or 1
    Stroke.Parent = Object
    return Stroke
end

local function CreateText(Parent, Text, Size, Color, Alignment)
    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.fromScale(1, 1)
    Label.Font = Enum.Font.Gotham
    Label.Text = Text or ""
    Label.TextColor3 = Color or Theme.Text
    Label.TextSize = Size or 13
    Label.TextXAlignment = Alignment or Enum.TextXAlignment.Left
    Label.Parent = Parent
    return Label
end

local function CreateButton(Parent, Text)
    local Button = Instance.new("TextButton")
    Button.AutoButtonColor = false
    Button.BackgroundColor3 = Theme.Surface
    Button.BorderSizePixel = 0
    Button.Font = Enum.Font.GothamMedium
    Button.Text = Text or ""
    Button.TextColor3 = Theme.Text
    Button.TextSize = 12
    Button.Parent = Parent
    AddCorner(Button, 6)
    AddStroke(Button)
    return Button
end

local function MakeDraggable(Handle, Target)
    local Dragging = false
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    Handle.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = Input.Position
            StartPosition = Target.Position
            Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)
    Handle.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
            DragInput = Input
        end
    end)
    UserInputService.InputChanged:Connect(function(Input)
        if Dragging and Input == DragInput then
            local Delta = Input.Position - DragStart
            Target.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X,
                StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
        end
    end)
end

local function CreateToggleRow(Parent, LabelText, GetValue, OnToggle)
    local Row = CreateButton(Parent, "")
    Row.Size = UDim2.new(1, 0, 0, 34)
    local Label = CreateText(Row, LabelText, 12)
    Label.Position = UDim2.fromOffset(10, 0)
    Label.Size = UDim2.new(1, -62, 1, 0)

    local Switch = Instance.new("Frame")
    Switch.AnchorPoint = Vector2.new(1, 0.5)
    Switch.Position = UDim2.new(1, -8, 0.5, 0)
    Switch.Size = UDim2.fromOffset(38, 20)
    Switch.BorderSizePixel = 0
    Switch.Parent = Row
    AddCorner(Switch, 10)

    local Knob = Instance.new("Frame")
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.Size = UDim2.fromOffset(14, 14)
    Knob.BorderSizePixel = 0
    Knob.BackgroundColor3 = Color3.new(1, 1, 1)
    Knob.Parent = Switch
    AddCorner(Knob, 7)

    local function Refresh()
        local Enabled = GetValue()
        Switch.BackgroundColor3 = Enabled and Theme.Enabled or Theme.Disabled
        Knob.Position = Enabled and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0)
    end
    local LastToggleAt = 0
    Row.Activated:Connect(function()
        local CurrentTime = os.clock()
        if (CurrentTime - LastToggleAt) < 0.25 then
            return
        end
        LastToggleAt = CurrentTime
        OnToggle(not GetValue())
        Refresh()
    end)
    Refresh()
    return Row, Refresh
end

ScreenGui.DisplayOrder = 50
ScreenGui.IgnoreGuiInset = false

local D3DPanel = Instance.new("Frame")
D3DPanel.Name = "D3DPanel"
D3DPanel.AnchorPoint = Vector2.new(0.5, 0.5)
D3DPanel.Position = UDim2.fromScale(0.5, 0.5)
D3DPanel.Size = UDim2.fromOffset(360, 520)
D3DPanel.BackgroundColor3 = Theme.Panel
D3DPanel.BorderSizePixel = 0
D3DPanel.ClipsDescendants = false
D3DPanel.Parent = ScreenGui
AddCorner(D3DPanel, 10)
AddStroke(D3DPanel, Theme.Border, 1.25)

local MenuScale = Instance.new("UIScale")
MenuScale.Parent = D3DPanel
local function RefreshMenuScale()
    local Camera = workspace.CurrentCamera
    local Viewport = Camera and Camera.ViewportSize or Vector2.new(1280, 720)
    MenuScale.Scale = math.clamp(math.min((Viewport.X - 24) / 360, (Viewport.Y - 24) / 520), 0.62, 1)
end
RefreshMenuScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(RefreshMenuScale)
end

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = Theme.Background
Header.BorderSizePixel = 0
Header.Parent = D3DPanel

local HeaderTitle = CreateText(Header, "Iron Soul Script by Bugon", 14, Theme.Text)
HeaderTitle.Position = UDim2.fromOffset(14, 0)
HeaderTitle.Size = UDim2.new(1, -62, 1, 0)
HeaderTitle.Font = Enum.Font.GothamBold

local MinimizeButton = CreateButton(Header, "—")
MinimizeButton.AnchorPoint = Vector2.new(1, 0.5)
MinimizeButton.Position = UDim2.new(1, -8, 0.5, 0)
MinimizeButton.Size = UDim2.fromOffset(34, 26)

local Navigation = Instance.new("Frame")
Navigation.Position = UDim2.fromOffset(10, 50)
Navigation.Size = UDim2.new(1, -20, 0, 34)
Navigation.BackgroundTransparency = 1
Navigation.Parent = D3DPanel

local FarmTabButton = CreateButton(Navigation, "FARM")
FarmTabButton.Name = "FarmTabButton"
FarmTabButton.Size = UDim2.new(1 / 3, -4, 1, 0)

local UtilityTabButton = CreateButton(Navigation, "UTILITY")
UtilityTabButton.Name = "UtilityTabButton"
UtilityTabButton.Position = UDim2.new(1 / 3, 2, 0, 0)
UtilityTabButton.Size = UDim2.new(1 / 3, -4, 1, 0)

local ForgeTabButton = CreateButton(Navigation, "FORGE")
ForgeTabButton.Name = "ForgeTabButton"
ForgeTabButton.Position = UDim2.new(2 / 3, 4, 0, 0)
ForgeTabButton.Size = UDim2.new(1 / 3, -4, 1, 0)

local Content = Instance.new("Frame")
Content.Position = UDim2.fromOffset(10, 92)
Content.Size = UDim2.new(1, -20, 1, -122)
Content.BackgroundTransparency = 1
Content.Parent = D3DPanel

local FarmTab = Instance.new("Frame")
FarmTab.Name = "FarmTab"
FarmTab.Size = UDim2.fromScale(1, 1)
FarmTab.BackgroundTransparency = 1
FarmTab.Parent = Content

local UtilityTab = Instance.new("Frame")
UtilityTab.Name = "UtilityTab"
UtilityTab.Size = UDim2.fromScale(1, 1)
UtilityTab.BackgroundTransparency = 1
UtilityTab.Visible = false
UtilityTab.Parent = Content

local ForgeTab = Instance.new("Frame")
ForgeTab.Name = "ForgeTab"
ForgeTab.Size = UDim2.fromScale(1, 1)
ForgeTab.BackgroundTransparency = 1
ForgeTab.Visible = false
ForgeTab.Parent = Content

local Footer = CreateText(D3DPanel, "© 2026 Bugon. All rights reserved.", 10, Theme.Muted, Enum.TextXAlignment.Center)
Footer.AnchorPoint = Vector2.new(0.5, 1)
Footer.Position = UDim2.new(0.5, 0, 1, -4)
Footer.Size = UDim2.new(1, -20, 0, 20)

local FloatingIcon = CreateButton(ScreenGui, "B")
FloatingIcon.Name = "FloatingIcon"
FloatingIcon.Position = UDim2.fromOffset(18, 180)
FloatingIcon.Size = UDim2.fromOffset(48, 48)
FloatingIcon.Font = Enum.Font.GothamBold
FloatingIcon.TextSize = 19
FloatingIcon.BackgroundColor3 = Theme.Accent
FloatingIcon.Visible = false
MakeDraggable(Header, D3DPanel)
MakeDraggable(FloatingIcon, FloatingIcon)

local CloseMenuDropdowns = function() end
local function SetMainTab(Name)
    local IsFarm = Name == "Farm"
    local IsUtility = Name == "Utility"
    local IsForge = Name == "Forge"
    FarmTab.Visible = IsFarm
    UtilityTab.Visible = IsUtility
    ForgeTab.Visible = IsForge
    FarmTabButton.BackgroundColor3 = IsFarm and Theme.Accent or Theme.Surface
    UtilityTabButton.BackgroundColor3 = IsUtility and Theme.Accent or Theme.Surface
    ForgeTabButton.BackgroundColor3 = IsForge and Theme.Accent or Theme.Surface
    CloseMenuDropdowns()
end
FarmTabButton.Activated:Connect(function()
    SetMainTab("Farm")
end)
UtilityTabButton.Activated:Connect(function()
    SetMainTab("Utility")
end)
ForgeTabButton.Activated:Connect(function()
    SetMainTab("Forge")
end)
MinimizeButton.Activated:Connect(function()
    D3DPanel.Visible = false
    FloatingIcon.Visible = true
end)
FloatingIcon.Activated:Connect(function()
    FloatingIcon.Visible = false
    D3DPanel.Visible = true
end)
SetMainTab("Farm")

local FarmLayout = Instance.new("UIListLayout")
FarmLayout.Padding = UDim.new(0, 7)
FarmLayout.SortOrder = Enum.SortOrder.LayoutOrder
FarmLayout.Parent = FarmTab

CreateToggleRow(FarmTab, "Script", function()
    return _G.AutoFarm
end, function(Value)
    local Character = LocalPlayer.Character
    local MyRoot = Character and Character:FindFirstChild("HumanoidRootPart")
    Target = nil
    TargetKind = nil
    IsEgg = false
    _G.AutoFarm = Value
    if not Value and MyRoot then
        MyRoot.CFrame = CFrame.new(MyRoot.Position.X, MyRoot.Position.Y + 150, MyRoot.Position.Z)
    end
end)

CreateToggleRow(FarmTab, "Underground Mode", function()
    return _G.UndergroundMode
end, function(Value)
    _G.UndergroundMode = Value
    SaveConfig()
end)

CreateToggleRow(FarmTab, "Auto Replay", function()
    return _G.AutoReplay
end, function(Value)
    _G.AutoReplay = Value
    SaveConfig()
end)

CreateToggleRow(FarmTab, "Auto Giveup", function()
    return _G.AutoGiveup
end, function(Value)
    _G.AutoGiveup = Value
    SaveConfig()
end)

CreateToggleRow(FarmTab, "Auto Rejoin", function()
    return _G.AutoRejoin
end, function(Value)
    _G.AutoRejoin = Value
    if not Value then
        RejoinWatchdog.RecoveryActive = false
        RejoinWatchdog.HardStuck = false
        RejoinWatchdog.NextAttemptAt = nil
        RejoinWatchdog.Status = "OFF"
    else
        RejoinWatchdog.LastFallbackScanAt = -math.huge
        RejoinWatchdog.RefreshCachedTargets(true)
    end
    SaveConfig()
end)

local HeightCard = Instance.new("Frame")
HeightCard.Size = UDim2.new(1, 0, 0, 62)
HeightCard.BackgroundColor3 = Theme.Surface
HeightCard.BorderSizePixel = 0
HeightCard.Parent = FarmTab
AddCorner(HeightCard, 6)
AddStroke(HeightCard)

local HeightTitle = CreateText(HeightCard, "Height Distance", 12)
HeightTitle.Position = UDim2.fromOffset(10, 4)
HeightTitle.Size = UDim2.new(1, -70, 0, 24)

local HeightValue = CreateText(HeightCard, "", 12, Theme.Accent, Enum.TextXAlignment.Right)
HeightValue.Position = UDim2.new(1, -60, 0, 4)
HeightValue.Size = UDim2.fromOffset(50, 24)
HeightValue.Font = Enum.Font.GothamBold

local HeightTrack = Instance.new("TextButton")
HeightTrack.AutoButtonColor = false
HeightTrack.Text = ""
HeightTrack.Position = UDim2.fromOffset(12, 39)
HeightTrack.Size = UDim2.new(1, -24, 0, 6)
HeightTrack.BackgroundColor3 = Theme.Disabled
HeightTrack.BorderSizePixel = 0
HeightTrack.Parent = HeightCard
AddCorner(HeightTrack, 3)

local HeightFill = Instance.new("Frame")
HeightFill.BackgroundColor3 = Theme.Accent
HeightFill.BorderSizePixel = 0
HeightFill.Size = UDim2.fromScale(0, 1)
HeightFill.Parent = HeightTrack
AddCorner(HeightFill, 3)

local HeightKnob = Instance.new("Frame")
HeightKnob.AnchorPoint = Vector2.new(0.5, 0.5)
HeightKnob.Position = UDim2.fromScale(0, 0.5)
HeightKnob.Size = UDim2.fromOffset(14, 14)
HeightKnob.BackgroundColor3 = Color3.new(1, 1, 1)
HeightKnob.BorderSizePixel = 0
HeightKnob.Parent = HeightTrack
AddCorner(HeightKnob, 7)

local function RefreshV6Height()
    local Percent = math.clamp((_G.TinggiMelayang - 5) / 95, 0, 1)
    HeightValue.Text = tostring(_G.TinggiMelayang) .. " studs"
    HeightFill.Size = UDim2.fromScale(Percent, 1)
    HeightKnob.Position = UDim2.fromScale(Percent, 0.5)
end

local HeightDragging = false
local function UpdateV6Height(Input)
    local Percent = math.clamp((Input.Position.X - HeightTrack.AbsolutePosition.X) / HeightTrack.AbsoluteSize.X, 0, 1)
    _G.TinggiMelayang = math.floor(5 + Percent * 95 + 0.5)
    _G.KillAuraRadius = _G.TinggiMelayang + 40
    RefreshHeightSlider()
    RefreshV6Height()
end
HeightTrack.InputBegan:Connect(function(Input)
    if IsSliderInput(Input) then
        HeightDragging = true
        UpdateV6Height(Input)
    end
end)
UserInputService.InputChanged:Connect(function(Input)
    if HeightDragging and
        (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
        UpdateV6Height(Input)
    end
end)
UserInputService.InputEnded:Connect(function(Input)
    if HeightDragging and IsSliderInput(Input) then
        HeightDragging = false
        SaveConfig()
    end
end)
RefreshV6Height()

StatsLabel = Instance.new("TextLabel")
StatsLabel.Name = "V6StatsLabel"
StatsLabel.Size = UDim2.new(1, 0, 0, 96)
StatsLabel.BackgroundColor3 = Theme.Surface
StatsLabel.BorderSizePixel = 0
StatsLabel.Font = Enum.Font.GothamMedium
StatsLabel.TextColor3 = Theme.Text
StatsLabel.TextSize = 12
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.TextYAlignment = Enum.TextYAlignment.Center
StatsLabel.Parent = FarmTab
AddCorner(StatsLabel, 6)
AddStroke(StatsLabel)
local StatsPadding = Instance.new("UIPadding")
StatsPadding.PaddingLeft = UDim.new(0, 10)
StatsPadding.Parent = StatsLabel
UpdateStatsLabel()

local UtilityToggleGrid = Instance.new("Frame")
UtilityToggleGrid.Size = UDim2.new(1, 0, 0, 75)
UtilityToggleGrid.BackgroundTransparency = 1
UtilityToggleGrid.Parent = UtilityTab

local UtilityToggles = {
    {"Perfect Forge", function() return _G.PerfectForge end, function(Value) _G.PerfectForge = Value end},
    {"Auto Buy", function() return _G.AutoBuy end, function(Value) _G.AutoBuy = Value end},
    {"Auto Sell", function() return _G.AutoSell end, function(Value) _G.AutoSell = Value end},
    {"Season Buy", function() return _G.AutoSeasonBuy end, function(Value) _G.AutoSeasonBuy = Value end}
}
for Index, Definition in ipairs(UtilityToggles) do
    local LabelText = Definition[1]
    local GetValue = Definition[2]
    local SetValue = Definition[3]
    local Row = CreateToggleRow(UtilityToggleGrid, LabelText, GetValue, function(Value)
        SetValue(Value)
        SaveConfig()
    end)
    local Column = (Index - 1) % 2
    local Line = math.floor((Index - 1) / 2)
    Row.Position = UDim2.new(Column * 0.5, Column == 0 and 0 or 4, 0, Line * 41)
    Row.Size = UDim2.new(0.5, -4, 0, 34)
end

local UtilityNavigation = Instance.new("Frame")
UtilityNavigation.Position = UDim2.fromOffset(0, 84)
UtilityNavigation.Size = UDim2.new(1, 0, 0, 32)
UtilityNavigation.BackgroundTransparency = 1
UtilityNavigation.Parent = UtilityTab

local DungeonTabButton = CreateButton(UtilityNavigation, "DUNGEON")
DungeonTabButton.Size = UDim2.new(0.25, -4, 1, 0)
local GroceryTabButton = CreateButton(UtilityNavigation, "GROCERY")
GroceryTabButton.Position = UDim2.new(0.25, 2, 0, 0)
GroceryTabButton.Size = UDim2.new(0.25, -4, 1, 0)
local SeasonTabButton = CreateButton(UtilityNavigation, "SEASON")
SeasonTabButton.Position = UDim2.new(0.5, 4, 0, 0)
SeasonTabButton.Size = UDim2.new(0.25, -4, 1, 0)
local AutoSellTabButton = CreateButton(UtilityNavigation, "AUTO SELL")
AutoSellTabButton.Position = UDim2.new(0.75, 6, 0, 0)
AutoSellTabButton.Size = UDim2.new(0.25, -6, 1, 0)

local UtilityPages = Instance.new("Frame")
UtilityPages.Position = UDim2.fromOffset(0, 124)
UtilityPages.Size = UDim2.new(1, 0, 1, -124)
UtilityPages.BackgroundTransparency = 1
UtilityPages.Parent = UtilityTab

local ForgeNavigation = Instance.new("Frame")
ForgeNavigation.Size = UDim2.new(1, 0, 0, 32)
ForgeNavigation.BackgroundTransparency = 1
ForgeNavigation.Parent = ForgeTab
local ForgeCraftButton = CreateButton(ForgeNavigation, "CRAFT")
ForgeCraftButton.Size = UDim2.new(0.5, -3, 1, 0)
local ForgeTargetsButton = CreateButton(ForgeNavigation, "TARGETS")
ForgeTargetsButton.Position = UDim2.new(0.5, 3, 0, 0)
ForgeTargetsButton.Size = UDim2.new(0.5, -3, 1, 0)
local ForgePages = Instance.new("Frame")
ForgePages.Position = UDim2.fromOffset(0, 40)
ForgePages.Size = UDim2.new(1, 0, 1, -40)
ForgePages.BackgroundTransparency = 1
ForgePages.Parent = ForgeTab

local function CreateSelectorDropdown(Parent, Name, PositionY, OpenUpwards)
    local Button = CreateButton(Parent, "")
    Button.Name = Name .. "Dropdown"
    Button.Position = UDim2.fromOffset(0, PositionY)
    Button.Size = UDim2.new(1, 0, 0, 34)
    Button.TextXAlignment = Enum.TextXAlignment.Left

    local Options = Instance.new("ScrollingFrame")
    Options.Name = Name .. "Options"
    Options.AnchorPoint = OpenUpwards and Vector2.new(0, 1) or Vector2.new(0, 0)
    Options.Position = UDim2.fromOffset(0, OpenUpwards and (PositionY - 4) or (PositionY + 38))
    Options.Size = UDim2.new(1, 0, 0, 0)
    Options.BackgroundColor3 = Theme.Surface
    Options.BorderSizePixel = 0
    Options.ScrollBarThickness = 3
    Options.ScrollBarImageColor3 = Theme.Accent
    Options.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Options.CanvasSize = UDim2.fromOffset(0, 0)
    Options.Visible = false
    Options.ZIndex = 30
    Options.Parent = Parent
    AddCorner(Options, 6)
    AddStroke(Options, Theme.Accent)
    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 5)
    Padding.PaddingBottom = UDim.new(0, 5)
    Padding.PaddingLeft = UDim.new(0, 5)
    Padding.PaddingRight = UDim.new(0, 5)
    Padding.Parent = Options
    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 4)
    Layout.Parent = Options

    return Button, Options
end

local function CreateCatalogPage(Name)
    local Page = Instance.new("Frame")
    Page.Name = Name
    Page.Size = UDim2.fromScale(1, 1)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.Parent = UtilityPages

    local SearchBox = Instance.new("TextBox")
    SearchBox.Name = "SearchBox"
    SearchBox.Size = UDim2.new(1, -80, 0, 30)
    SearchBox.BackgroundColor3 = Theme.Surface
    SearchBox.BorderSizePixel = 0
    SearchBox.ClearTextOnFocus = false
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.PlaceholderText = "Search item..."
    SearchBox.PlaceholderColor3 = Theme.Muted
    SearchBox.Text = ""
    SearchBox.TextColor3 = Theme.Text
    SearchBox.TextSize = 12
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.Parent = Page
    AddCorner(SearchBox, 6)
    AddStroke(SearchBox)
    local SearchPadding = Instance.new("UIPadding")
    SearchPadding.PaddingLeft = UDim.new(0, 10)
    SearchPadding.Parent = SearchBox

    local RefreshButton = CreateButton(Page, "REFRESH")
    RefreshButton.AnchorPoint = Vector2.new(1, 0)
    RefreshButton.Position = UDim2.new(1, 0, 0, 0)
    RefreshButton.Size = UDim2.fromOffset(72, 30)

    local List = Instance.new("ScrollingFrame")
    List.Name = "List"
    List.Position = UDim2.fromOffset(0, 38)
    List.Size = UDim2.new(1, 0, 1, -38)
    List.BackgroundColor3 = Theme.Background
    List.BorderSizePixel = 0
    List.ScrollBarThickness = 3
    List.ScrollBarImageColor3 = Theme.Accent
    List.CanvasSize = UDim2.fromOffset(0, 0)
    List.AutomaticCanvasSize = Enum.AutomaticSize.Y
    List.Parent = Page
    AddCorner(List, 6)
    AddStroke(List)
    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 5)
    Padding.PaddingBottom = UDim.new(0, 5)
    Padding.PaddingLeft = UDim.new(0, 5)
    Padding.PaddingRight = UDim.new(0, 5)
    Padding.Parent = List
    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 5)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = List

    return {
        Page = Page,
        SearchBox = SearchBox,
        RefreshButton = RefreshButton,
        List = List,
        Rows = {}
    }
end

local DungeonPage = Instance.new("Frame")
DungeonPage.Name = "DungeonPage"
DungeonPage.Size = UDim2.fromScale(1, 1)
DungeonPage.BackgroundTransparency = 1
DungeonPage.Parent = UtilityPages

local DungeonLabel = CreateText(DungeonPage, "Dungeon", 11, Theme.Muted)
DungeonLabel.Size = UDim2.new(1, 0, 0, 20)
local DungeonDropdown, DungeonOptions = CreateSelectorDropdown(DungeonPage, "Dungeon", 22)

local DifficultyLabel = CreateText(DungeonPage, "Difficulty", 11, Theme.Muted)
DifficultyLabel.Position = UDim2.fromOffset(0, 104)
DifficultyLabel.Size = UDim2.new(1, 0, 0, 20)
local DifficultyDropdown, DifficultyOptions = CreateSelectorDropdown(DungeonPage, "Difficulty", 126, true)
DungeonDropdown.Activated:Connect(function()
    DifficultyOptions.Visible = false
    DungeonOptions.Visible = not DungeonOptions.Visible
end)
DifficultyDropdown.Activated:Connect(function()
    DungeonOptions.Visible = false
    DifficultyOptions.Visible = not DifficultyOptions.Visible
end)

local PartyStatus = CreateText(DungeonPage, "SOLO 1/1 · AFTER AUTO-SELL", 11, Theme.Muted)
PartyStatus.Position = UDim2.fromOffset(8, 170)
PartyStatus.Size = UDim2.new(1, -16, 0, 20)

local AutoPotionToggle = CreateButton(DungeonPage, "")
AutoPotionToggle.Name = "AutoPotionToggle"
AutoPotionToggle.Position = UDim2.fromOffset(0, 196)
AutoPotionToggle.Size = UDim2.new(1, 0, 0, 32)

local AutoPotionOpen = CreateButton(DungeonPage, "POTIONS")
AutoPotionOpen.Name = "AutoPotionOpen"
AutoPotionOpen.Position = UDim2.fromOffset(0, 234)
AutoPotionOpen.Size = UDim2.new(1, 0, 0, 32)

local AutoPotionOverlay = Instance.new("Frame")
AutoPotionOverlay.Name = "AutoPotionOverlay"
AutoPotionOverlay.Size = UDim2.fromScale(1, 1)
AutoPotionOverlay.BackgroundColor3 = Theme.Panel
AutoPotionOverlay.BorderSizePixel = 0
AutoPotionOverlay.Visible = false
AutoPotionOverlay.ZIndex = 40
AutoPotionOverlay.Parent = DungeonPage
AddCorner(AutoPotionOverlay, 7)
AddStroke(AutoPotionOverlay, Theme.Accent)

local AutoPotionTitle = CreateText(AutoPotionOverlay, "AUTO POTION", 13)
AutoPotionTitle.Position = UDim2.fromOffset(8, 0)
AutoPotionTitle.Size = UDim2.new(1, -148, 0, 30)
AutoPotionTitle.Font = Enum.Font.GothamBold
AutoPotionTitle.ZIndex = 41

local AutoPotionRefresh = CreateButton(AutoPotionOverlay, "REFRESH")
AutoPotionRefresh.AnchorPoint = Vector2.new(1, 0)
AutoPotionRefresh.Position = UDim2.new(1, -66, 0, 0)
AutoPotionRefresh.Size = UDim2.fromOffset(64, 30)
AutoPotionRefresh.ZIndex = 41

local AutoPotionClose = CreateButton(AutoPotionOverlay, "CLOSE")
AutoPotionClose.AnchorPoint = Vector2.new(1, 0)
AutoPotionClose.Position = UDim2.new(1, 0, 0, 0)
AutoPotionClose.Size = UDim2.fromOffset(60, 30)
AutoPotionClose.ZIndex = 41

local AutoPotionSearch = Instance.new("TextBox")
AutoPotionSearch.Name = "AutoPotionSearch"
AutoPotionSearch.Position = UDim2.fromOffset(0, 36)
AutoPotionSearch.Size = UDim2.new(1, 0, 0, 30)
AutoPotionSearch.BackgroundColor3 = Theme.Surface
AutoPotionSearch.BorderSizePixel = 0
AutoPotionSearch.ClearTextOnFocus = false
AutoPotionSearch.Font = Enum.Font.Gotham
AutoPotionSearch.PlaceholderText = "Search potion name or ID..."
AutoPotionSearch.PlaceholderColor3 = Theme.Muted
AutoPotionSearch.Text = ""
AutoPotionSearch.TextColor3 = Theme.Text
AutoPotionSearch.TextSize = 12
AutoPotionSearch.TextXAlignment = Enum.TextXAlignment.Left
AutoPotionSearch.ZIndex = 41
AutoPotionSearch.Parent = AutoPotionOverlay
AddCorner(AutoPotionSearch, 6)
AddStroke(AutoPotionSearch)
local AutoPotionSearchPadding = Instance.new("UIPadding")
AutoPotionSearchPadding.PaddingLeft = UDim.new(0, 10)
AutoPotionSearchPadding.Parent = AutoPotionSearch

local AutoPotionList = Instance.new("ScrollingFrame")
AutoPotionList.Name = "AutoPotionList"
AutoPotionList.Position = UDim2.fromOffset(0, 72)
AutoPotionList.Size = UDim2.new(1, 0, 1, -72)
AutoPotionList.BackgroundColor3 = Theme.Background
AutoPotionList.BorderSizePixel = 0
AutoPotionList.ScrollBarThickness = 3
AutoPotionList.ScrollBarImageColor3 = Theme.Accent
AutoPotionList.AutomaticCanvasSize = Enum.AutomaticSize.Y
AutoPotionList.CanvasSize = UDim2.fromOffset(0, 0)
AutoPotionList.ZIndex = 41
AutoPotionList.Parent = AutoPotionOverlay
AddCorner(AutoPotionList, 6)
AddStroke(AutoPotionList)
local AutoPotionListPadding = Instance.new("UIPadding")
AutoPotionListPadding.PaddingTop = UDim.new(0, 5)
AutoPotionListPadding.PaddingBottom = UDim.new(0, 5)
AutoPotionListPadding.PaddingLeft = UDim.new(0, 5)
AutoPotionListPadding.PaddingRight = UDim.new(0, 5)
AutoPotionListPadding.Parent = AutoPotionList
local AutoPotionListLayout = Instance.new("UIListLayout")
AutoPotionListLayout.Padding = UDim.new(0, 5)
AutoPotionListLayout.SortOrder = Enum.SortOrder.LayoutOrder
AutoPotionListLayout.Parent = AutoPotionList

local function BuildAutoPotionRows()
    for _, Child in ipairs(AutoPotionList:GetChildren()) do
        if Child:IsA("GuiButton") then
            Child:Destroy()
        end
    end
    AutoPotion.BuildCatalog(false)
    local Query = string.lower(AutoPotionSearch.Text or "")
    for LayoutOrder, PotionId in ipairs(AutoPotion.Order) do
        local Entry = AutoPotion.Catalog[PotionId]
        local SearchText = string.lower(Entry.DisplayName .. " " .. PotionId)
        if Query == "" or string.find(SearchText, Query, 1, true) then
            local Row = CreateButton(AutoPotionList, "")
            Row.Name = "Potion_" .. PotionId
            Row.Size = UDim2.new(1, -2, 0, 48)
            Row.LayoutOrder = LayoutOrder
            Row.ZIndex = 42

            local Title = CreateText(Row, Entry.DisplayName, 12)
            Title.Position = UDim2.fromOffset(10, 3)
            Title.Size = UDim2.new(1, -48, 0, 22)
            Title.Font = Enum.Font.GothamMedium
            Title.ZIndex = 43

            local State = AutoPotion.GetEntryState(Entry)
            local Detail = CreateText(Row, PotionId .. " · " .. State .. " · owned " .. tostring(Entry.Owned), 10,
                Theme.Muted)
            Detail.Position = UDim2.fromOffset(10, 25)
            Detail.Size = UDim2.new(1, -48, 0, 18)
            Detail.ZIndex = 43

            local Check = CreateText(Row, AutoPotion.Selected[PotionId] and "✓" or "", 14)
            Check.AnchorPoint = Vector2.new(1, 0.5)
            Check.Position = UDim2.new(1, -8, 0.5, 0)
            Check.Size = UDim2.fromOffset(26, 26)
            Check.BackgroundColor3 = AutoPotion.Selected[PotionId] and Theme.Enabled or Theme.SurfaceHover
            Check.BackgroundTransparency = 0
            Check.TextXAlignment = Enum.TextXAlignment.Center
            Check.ZIndex = 43
            AddCorner(Check, 5)

            Row.Activated:Connect(function()
                if AutoPotion.Selected[PotionId] then
                    AutoPotion.Selected[PotionId] = nil
                else
                    AutoPotion.Selected[PotionId] = true
                end
                SaveConfig()
                AutoPotion.RebuildSignals()
                AutoPotion.Scan(false)
                BuildAutoPotionRows()
            end)
        end
    end
end

local function RefreshAutoPotionUI()
    local SelectedCount = 0
    for PotionId in pairs(AutoPotion.Selected) do
        if AutoPotion.Catalog[PotionId] then
            SelectedCount = SelectedCount + 1
        end
    end
    AutoPotionToggle.Text = _G.AutoPotion and "AUTO POTION: ON" or "AUTO POTION: OFF"
    AutoPotionToggle.BackgroundColor3 = _G.AutoPotion and Theme.Enabled or Theme.Disabled
    AutoPotionOpen.Text = "POTIONS " .. tostring(SelectedCount) .. " · " .. tostring(AutoPotion.Status)
    if AutoPotionOverlay.Visible then
        BuildAutoPotionRows()
    end
end

AutoPotion.Refresh = RefreshAutoPotionUI
AutoPotionToggle.Activated:Connect(function()
    AutoPotion.SetEnabled(not _G.AutoPotion)
    SaveConfig()
    RefreshAutoPotionUI()
end)
AutoPotionOpen.Activated:Connect(function()
    DungeonOptions.Visible = false
    DifficultyOptions.Visible = false
    AutoPotionOverlay.Visible = true
    BuildAutoPotionRows()
end)
AutoPotionClose.Activated:Connect(function() AutoPotionOverlay.Visible = false end)
AutoPotionRefresh.Activated:Connect(function()
    AutoPotion.BuildCatalog(true)
    AutoPotion.RebuildSignals()
    AutoPotion.Scan(false)
    RefreshAutoPotionUI()
end)
AutoPotionSearch:GetPropertyChangedSignal("Text"):Connect(BuildAutoPotionRows)
RefreshAutoPotionUI()

local GroceryPage = CreateCatalogPage("GroceryPage")
local SeasonPage = CreateCatalogPage("SeasonPage")
local AutoSellPage = CreateCatalogPage("AutoSellPage")
local AutoForgePage = AutoForge.BuildMenuPage({
    Parent = ForgePages,
    Name = "ForgeCraftPage",
    Theme = Theme,
    CreateButton = CreateButton,
    CreateText = CreateText,
    AddCorner = AddCorner,
    AddStroke = AddStroke
})
local ForgeTargetsPage = AutoForge.BuildTargetsPage({
    Parent = ForgePages,
    Theme = Theme,
    CreateButton = CreateButton,
    CreateText = CreateText,
    AddCorner = AddCorner,
    AddStroke = AddStroke
})

local function SetForgePage(Name)
    AutoForgePage.Close()
    ForgeTargetsPage.Close()
    AutoForgePage.Page.Visible = Name == "Craft"
    ForgeTargetsPage.Page.Visible = Name == "Targets"
    ForgeCraftButton.BackgroundColor3 = Name == "Craft" and Theme.Accent or Theme.Surface
    ForgeTargetsButton.BackgroundColor3 = Name == "Targets" and Theme.Accent or Theme.Surface
    if Name == "Targets" then
        ForgeTargetsPage.Refresh()
    end
end
ForgeCraftButton.Activated:Connect(function() SetForgePage("Craft") end)
ForgeTargetsButton.Activated:Connect(function() SetForgePage("Targets") end)
SetForgePage("Craft")

local TargetFoundModal = Instance.new("Frame")
TargetFoundModal.Name = "TargetFoundModal"
TargetFoundModal.Size = UDim2.fromScale(1, 1)
TargetFoundModal.BackgroundColor3 = Theme.Panel
TargetFoundModal.BorderSizePixel = 0
TargetFoundModal.Visible = false
TargetFoundModal.ZIndex = 80
TargetFoundModal.Parent = Content
AddCorner(TargetFoundModal, 8)
AddStroke(TargetFoundModal, Theme.Enabled, 2)
local TargetFoundTitle = CreateText(TargetFoundModal, "TARGET FOUND", 18, Theme.Enabled, Enum.TextXAlignment.Center)
TargetFoundTitle.Position = UDim2.fromOffset(10, 14)
TargetFoundTitle.Size = UDim2.new(1, -20, 0, 32)
TargetFoundTitle.Font = Enum.Font.GothamBold
TargetFoundTitle.ZIndex = 81
local TargetFoundText = CreateText(TargetFoundModal, "", 12, Theme.Text, Enum.TextXAlignment.Center)
TargetFoundText.Position = UDim2.fromOffset(14, 58)
TargetFoundText.Size = UDim2.new(1, -28, 1, -116)
TargetFoundText.TextWrapped = true
TargetFoundText.TextYAlignment = Enum.TextYAlignment.Top
TargetFoundText.ZIndex = 81
local TargetFoundClose = CreateButton(TargetFoundModal, "CLOSE")
TargetFoundClose.AnchorPoint = Vector2.new(0.5, 1)
TargetFoundClose.Position = UDim2.new(0.5, 0, 1, -14)
TargetFoundClose.Size = UDim2.new(0.6, 0, 0, 34)
TargetFoundClose.ZIndex = 81
local function RefreshTargetFoundModal()
    local Data = AutoForge.TargetFoundData
    TargetFoundModal.Visible = Data ~= nil
    if not Data then
        return
    end
    local CountParts = {}
    for StatId, Count in pairs(Data.Summary and Data.Summary.Counts or {}) do
        table.insert(CountParts, tostring(StatId) .. " x" .. tostring(Count))
    end
    table.sort(CountParts)
    TargetFoundText.Text = "PROFILE\n" .. tostring(Data.ProfileName) .. "\n\nITEM\n" ..
        GetItemDisplayName(Data.ItemId) .. "\n\nATTEMPT " .. tostring(Data.Attempt) .. " · SLOTS " ..
        tostring(Data.Summary and Data.Summary.TotalSlots or 0) .. "\n" .. table.concat(CountParts, "\n") ..
        "\n\nAUTOMATICALLY ACCEPTED"
end
TargetFoundClose.Activated:Connect(function()
    AutoForge.TargetFoundData = nil
    RefreshTargetFoundModal()
end)
AutoForge.TargetRefresh = RefreshTargetFoundModal
RefreshTargetFoundModal()

local function ClearSelectorOptions(Options)
    for _, Child in ipairs(Options:GetChildren()) do
        if Child:IsA("GuiButton") then
            Child:Destroy()
        end
    end
end

local function AddSelectorOption(Options, Text, Unlocked, OnSelect)
    local Option = CreateButton(Options, Unlocked and Text or (Text .. "  LOCKED"))
    Option.Size = UDim2.new(1, 0, 0, 28)
    Option.ZIndex = 31
    Option.TextColor3 = Unlocked and Theme.Text or Theme.Muted
    Option.Activated:Connect(function()
        if Unlocked then
            Options.Visible = false
            OnSelect()
        end
    end)
end

local function FindSelectedDifficultyName()
    for _, Entry in ipairs(DungeonCatalog.GetDifficultyCatalog(AutoStartWorldId)) do
        if Entry.Level == AutoStartDifficulty then
            return Entry.DisplayName
        end
    end
    return "Unavailable"
end

local function BuildDifficultyOptions(ForceRefresh)
    ClearSelectorOptions(DifficultyOptions)
    for _, Entry in ipairs(DungeonCatalog.GetDifficultyCatalog(AutoStartWorldId, ForceRefresh)) do
        AddSelectorOption(DifficultyOptions, Entry.DisplayName, Entry.Unlocked, function()
            if DungeonCatalog.SelectAutoStartDifficulty(Entry.Level) then
                DifficultyDropdown.Text = "  " .. Entry.DisplayName .. "  \226\150\188"
            end
        end)
    end
    DifficultyOptions.Size = UDim2.new(1, 0, 0,
        math.min(180, #DungeonCatalog.GetDifficultyCatalog(AutoStartWorldId) * 32 + 10))
    DifficultyDropdown.Text = "  " .. FindSelectedDifficultyName() .. "  \226\150\188"
end

local function BuildDungeonPage(ForceRefresh)
    DungeonOptions.Visible = false
    DifficultyOptions.Visible = false
    DungeonCatalog.ValidateAutoStartSelection(false)
    ClearSelectorOptions(DungeonOptions)
    local SelectedName = AutoStartWorldId
    local Catalog = DungeonCatalog.GetDungeonCatalog(ForceRefresh)
    for _, Entry in ipairs(Catalog) do
        if Entry.WorldId == AutoStartWorldId then
            SelectedName = Entry.DisplayName
        end
        AddSelectorOption(DungeonOptions, Entry.DisplayName, Entry.Unlocked, function()
            if DungeonCatalog.SelectAutoStartWorld(Entry.WorldId) then
                BuildDungeonPage(true)
            end
        end)
    end
    DungeonOptions.Size = UDim2.new(1, 0, 0, math.min(180, #Catalog * 32 + 10))
    DungeonDropdown.Text = "  " .. SelectedName .. "  \226\150\188"
    BuildDifficultyOptions(ForceRefresh)
end

local function SetUtilityPage(Name)
    DungeonOptions.Visible = false
    DifficultyOptions.Visible = false
    AutoPotionOverlay.Visible = false
    DungeonPage.Visible = Name == "Dungeon"
    GroceryPage.Page.Visible = Name == "Grocery"
    SeasonPage.Page.Visible = Name == "Season"
    AutoSellPage.Page.Visible = Name == "AutoSell"
    DungeonTabButton.BackgroundColor3 = Name == "Dungeon" and Theme.Accent or Theme.Surface
    GroceryTabButton.BackgroundColor3 = Name == "Grocery" and Theme.Accent or Theme.Surface
    SeasonTabButton.BackgroundColor3 = Name == "Season" and Theme.Accent or Theme.Surface
    AutoSellTabButton.BackgroundColor3 = Name == "AutoSell" and Theme.Accent or Theme.Surface
    if Name == "Dungeon" then
        pcall(BuildDungeonPage, true)
    end
end
DungeonTabButton.Activated:Connect(function() SetUtilityPage("Dungeon") end)
GroceryTabButton.Activated:Connect(function() SetUtilityPage("Grocery") end)
SeasonTabButton.Activated:Connect(function() SetUtilityPage("Season") end)
AutoSellTabButton.Activated:Connect(function() SetUtilityPage("AutoSell") end)
CloseMenuDropdowns = function()
    DungeonOptions.Visible = false
    DifficultyOptions.Visible = false
    AutoPotionOverlay.Visible = false
    AutoForgePage.Close()
    ForgeTargetsPage.CloseDropdowns()
end
SetUtilityPage("Dungeon")

local function ClearCatalogRows(PageState)
    for _, RowState in ipairs(PageState.Rows) do
        if RowState.Gui then
            RowState.Gui:Destroy()
        end
    end
    PageState.Rows = {}
end

local function FilterCatalogRows(PageState)
    local Query = string.lower(PageState.SearchBox.Text or "")
    for _, RowState in ipairs(PageState.Rows) do
        RowState.Gui.Visible = Query == "" or string.find(RowState.SearchText, Query, 1, true) ~= nil
    end
end

local function CreateSelectionRow(PageState, Entry, SelectionMap, DetailText)
    local Row = CreateButton(PageState.List, "")
    Row.Name = "Item_" .. Entry.ItemId
    Row.Size = UDim2.new(1, -2, 0, 46)

    local DisplayName = GetItemDisplayName(Entry.ItemId)

    local Title = CreateText(Row, DisplayName, 12)
    Title.Position = UDim2.fromOffset(10, 3)
    Title.Size = UDim2.new(1, -55, 0, 22)
    Title.Font = Enum.Font.GothamMedium

    local Detail = CreateText(Row, Entry.ItemId .. " · " .. DetailText, 10, Theme.Muted)
    Detail.Position = UDim2.fromOffset(10, 23)
    Detail.Size = UDim2.new(1, -55, 0, 18)

    local Check = Instance.new("TextLabel")
    Check.AnchorPoint = Vector2.new(1, 0.5)
    Check.Position = UDim2.new(1, -10, 0.5, 0)
    Check.Size = UDim2.fromOffset(25, 25)
    Check.BackgroundColor3 = Theme.SurfaceHover
    Check.BorderSizePixel = 0
    Check.Font = Enum.Font.GothamBold
    Check.TextColor3 = Theme.Text
    Check.TextSize = 14
    Check.Parent = Row
    AddCorner(Check, 5)

    local function Refresh()
        local Selected = SelectionMap[Entry.ItemId] == true
        Check.Text = Selected and "✓" or ""
        Check.BackgroundColor3 = Selected and Theme.Enabled or Theme.SurfaceHover
    end
    Row.Activated:Connect(function()
        if SelectionMap[Entry.ItemId] then
            SelectionMap[Entry.ItemId] = nil
        else
            SelectionMap[Entry.ItemId] = true
        end
        Refresh()
        SaveConfig()
    end)
    Refresh()

    table.insert(PageState.Rows, {
        Gui = Row,
        SearchText = string.lower(DisplayName .. " " .. Entry.ItemId .. " " .. tostring(Entry.ItemType or ""))
    })
end

local function BuildGroceryPage(ForceRefresh)
    ClearCatalogRows(GroceryPage)
    for _, Entry in ipairs(GetGoldShopCatalog(ForceRefresh)) do
        local Stock = ""
        if Entry.StockMin then
            Stock = " · stock " .. tostring(Entry.StockMin) .. "-" .. tostring(Entry.StockMax or Entry.StockMin)
        end
        CreateSelectionRow(GroceryPage, Entry, AutoBuyWantedItemIds,
            tostring(Entry.ItemType or "Item") .. " · " .. tostring(Entry.Price or "?") .. " Gold" .. Stock)
    end
    FilterCatalogRows(GroceryPage)
end

local function BuildSeasonPage(ForceRefresh)
    ClearCatalogRows(SeasonPage)
    for _, Entry in ipairs(GetSeasonShopCatalog(ForceRefresh)) do
        local Limit = Entry.LimitTimes and (" · limit " .. tostring(Entry.LimitTimes)) or ""
        local Special = Entry.IsSpecial and " · special" or ""
        CreateSelectionRow(SeasonPage, Entry, AutoSeasonBuyWantedItemIds,
            tostring(Entry.ItemType or "Item") .. " · " .. tostring(Entry.Price or "?") .. " Season" .. Limit .. Special)
    end
    FilterCatalogRows(SeasonPage)
end

GroceryPage.SearchBox:GetPropertyChangedSignal("Text"):Connect(function() FilterCatalogRows(GroceryPage) end)
SeasonPage.SearchBox:GetPropertyChangedSignal("Text"):Connect(function() FilterCatalogRows(SeasonPage) end)
GroceryPage.RefreshButton.Activated:Connect(function() pcall(BuildGroceryPage, true) end)
SeasonPage.RefreshButton.Activated:Connect(function() pcall(BuildSeasonPage, true) end)

AutoSellPage.SearchBox.Position = UDim2.fromOffset(0, 40)
AutoSellPage.RefreshButton.Position = UDim2.new(1, 0, 0, 40)
AutoSellPage.List.Position = UDim2.fromOffset(0, 78)
AutoSellPage.List.Size = UDim2.new(1, 0, 1, -78)

local RarityButton = CreateButton(AutoSellPage.Page, "")
RarityButton.Name = "SellMaxRarityDropdown"
RarityButton.Size = UDim2.new(1, 0, 0, 32)
RarityButton.TextXAlignment = Enum.TextXAlignment.Left

local RarityOptions = Instance.new("Frame")
RarityOptions.Position = UDim2.fromOffset(0, 35)
RarityOptions.Size = UDim2.new(1, 0, 0, 10)
RarityOptions.BackgroundColor3 = Theme.Panel
RarityOptions.BorderSizePixel = 0
RarityOptions.Visible = false
RarityOptions.ZIndex = 20
RarityOptions.Parent = AutoSellPage.Page
AddCorner(RarityOptions, 6)
AddStroke(RarityOptions, Theme.Accent)
local RarityOptionsPadding = Instance.new("UIPadding")
RarityOptionsPadding.PaddingTop = UDim.new(0, 5)
RarityOptionsPadding.PaddingBottom = UDim.new(0, 5)
RarityOptionsPadding.PaddingLeft = UDim.new(0, 5)
RarityOptionsPadding.PaddingRight = UDim.new(0, 5)
RarityOptionsPadding.Parent = RarityOptions
local RarityOptionsLayout = Instance.new("UIListLayout")
RarityOptionsLayout.Padding = UDim.new(0, 4)
RarityOptionsLayout.Parent = RarityOptions

local function RarityDisplayName(Level, Catalog)
    if Level <= 0 then
        return "OFF"
    end
    for _, Entry in ipairs(Catalog or GetOreCatalog()) do
        if Entry.Rarity == Level then
            return tostring(Entry.RarityName) .. " · Level " .. tostring(Level)
        end
    end
    return "Level " .. tostring(Level)
end

local function RefreshRarityButton(Catalog)
    RarityButton.Text = "  Sell Max Rarity: " .. RarityDisplayName(SellMaxRarity, Catalog) .. "  ▼"
end

local function BuildRarityOptions(Catalog)
    for _, Child in ipairs(RarityOptions:GetChildren()) do
        if Child:IsA("GuiButton") then
            Child:Destroy()
        end
    end

    local Levels = {0}
    local Seen = {[0] = true}
    for _, Entry in ipairs(Catalog) do
        if not Seen[Entry.Rarity] then
            Seen[Entry.Rarity] = true
            table.insert(Levels, Entry.Rarity)
        end
    end
    table.sort(Levels)

    for _, Level in ipairs(Levels) do
        local Option = CreateButton(RarityOptions, RarityDisplayName(Level, Catalog))
        Option.Size = UDim2.new(1, 0, 0, 26)
        Option.ZIndex = 21
        Option.Activated:Connect(function()
            SellMaxRarity = Level
            Config.SellMaxRarity = Level
            RarityOptions.Visible = false
            RefreshRarityButton(Catalog)
            SaveConfig()
        end)
    end
    RarityOptions.Size = UDim2.new(1, 0, 0, #Levels * 30 + 10)
    RefreshRarityButton(Catalog)
end

local function CreateOreModeRow(Entry)
    local Row = CreateButton(AutoSellPage.List, "")
    Row.Name = "Ore_" .. Entry.ItemId
    Row.Size = UDim2.new(1, -2, 0, 46)

    local DisplayName = GetItemDisplayName(Entry.ItemId)
    local Title = CreateText(Row, DisplayName, 12)
    Title.Position = UDim2.fromOffset(10, 3)
    Title.Size = UDim2.new(1, -78, 0, 22)
    Title.Font = Enum.Font.GothamMedium

    local Detail = CreateText(Row,
        Entry.ItemId .. " · " .. tostring(Entry.RarityName) .. " · Level " .. tostring(Entry.Rarity) .. " · owned " ..
            tostring(Entry.Count),
        10, Theme.Muted)
    Detail.Position = UDim2.fromOffset(10, 23)
    Detail.Size = UDim2.new(1, -78, 0, 18)

    local ModeLabel = Instance.new("TextLabel")
    ModeLabel.AnchorPoint = Vector2.new(1, 0.5)
    ModeLabel.Position = UDim2.new(1, -8, 0.5, 0)
    ModeLabel.Size = UDim2.fromOffset(58, 25)
    ModeLabel.BorderSizePixel = 0
    ModeLabel.Font = Enum.Font.GothamBold
    ModeLabel.TextColor3 = Theme.Text
    ModeLabel.TextSize = 10
    ModeLabel.Parent = Row
    AddCorner(ModeLabel, 5)

    local function Refresh()
        local Mode = OreSellModes[Entry.ItemId] or "AUTO"
        ModeLabel.Text = Mode
        ModeLabel.BackgroundColor3 = Mode == "SELL" and Theme.Sell or Mode == "KEEP" and Theme.Keep or Theme.Accent
    end
    -- AUTO -> SELL -> KEEP -> AUTO
    Row.Activated:Connect(function()
        local Mode = OreSellModes[Entry.ItemId] or "AUTO"
        if Mode == "AUTO" then
            OreSellModes[Entry.ItemId] = "SELL"
        elseif Mode == "SELL" then
            OreSellModes[Entry.ItemId] = "KEEP"
        else
            OreSellModes[Entry.ItemId] = nil
        end
        Refresh()
        SaveConfig()
    end)
    Refresh()
    table.insert(AutoSellPage.Rows, {
        Gui = Row,
        SearchText = string.lower(DisplayName .. " " .. Entry.ItemId .. " " .. tostring(Entry.RarityName))
    })
end

local function BuildAutoSellPage(ForceRefresh)
    ClearCatalogRows(AutoSellPage)
    local Catalog = GetOreCatalog(ForceRefresh)
    for _, Entry in ipairs(Catalog) do
        CreateOreModeRow(Entry)
    end
    BuildRarityOptions(Catalog)
    FilterCatalogRows(AutoSellPage)
end

AutoSellPage.SearchBox:GetPropertyChangedSignal("Text"):Connect(function() FilterCatalogRows(AutoSellPage) end)
AutoSellPage.RefreshButton.Activated:Connect(function() pcall(BuildAutoSellPage, true) end)
RarityButton.Activated:Connect(function()
    RarityOptions.Visible = not RarityOptions.Visible
end)

pcall(BuildGroceryPage, false)
pcall(BuildSeasonPage, false)
pcall(BuildAutoSellPage, false)
print("[Bugon V6] menu ready")
end

task.spawn(function()
    local Success, ErrorMessage = pcall(_G.BugonBuildV6Menu)
    if not Success then
        warn("[Bugon V6] menu error: " .. tostring(ErrorMessage))
    end
end)

