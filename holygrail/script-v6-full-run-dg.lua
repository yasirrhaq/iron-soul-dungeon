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
local AutoBuyWantedItemIds = nil
local AutoSeasonBuyWantedItemIds = nil
local SellMaxRarity = nil
local OreSellModes = nil

local Config = {
    TinggiMelayang = 5,
    UndergroundMode = true,
    AutoReplay = true,
    PerfectForge = true,
    AutoBuy = false,
    AutoSell = false,
    AutoSeasonBuy = false,
    AutoBuyWantedItemIds = CopyMap(DefaultAutoBuyWantedItemIds),
    AutoSeasonBuyWantedItemIds = CopyMap(DefaultAutoSeasonBuyWantedItemIds),
    SellMaxRarity = 5,
    AutoStartWorldId = "World3",
    AutoStartDifficulty = 10,
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
    Config.PerfectForge = Config.PerfectForge ~= false
    Config.AutoBuy = Config.AutoBuy == true
    Config.AutoSell = Config.AutoSell == true
    Config.AutoSeasonBuy = Config.AutoSeasonBuy == true
    Config.AutoBuyWantedItemIds = NormalizeEnabledMap(Config.AutoBuyWantedItemIds, DefaultAutoBuyWantedItemIds)
    Config.AutoSeasonBuyWantedItemIds = NormalizeEnabledMap(Config.AutoSeasonBuyWantedItemIds,
        DefaultAutoSeasonBuyWantedItemIds)
    Config.SellMaxRarity = math.floor(ClampNumber(Config.SellMaxRarity, 0, 10, 5))
    Config.AutoStartWorldId = type(Config.AutoStartWorldId) == "string" and Config.AutoStartWorldId or "World3"
    Config.AutoStartDifficulty = math.max(1, math.floor(tonumber(Config.AutoStartDifficulty) or 10))
    Config.OreSellModes = NormalizeOreSellModes(Config.OreSellModes)
end

local function SaveConfig()
    Config.TinggiMelayang = _G.TinggiMelayang
    Config.UndergroundMode = _G.UndergroundMode
    Config.AutoReplay = _G.AutoReplay
    Config.PerfectForge = _G.PerfectForge
    Config.AutoBuy = _G.AutoBuy
    Config.AutoSell = _G.AutoSell
    Config.AutoSeasonBuy = _G.AutoSeasonBuy
    Config.AutoBuyWantedItemIds = AutoBuyWantedItemIds or Config.AutoBuyWantedItemIds
    Config.AutoSeasonBuyWantedItemIds = AutoSeasonBuyWantedItemIds or Config.AutoSeasonBuyWantedItemIds
    Config.SellMaxRarity = SellMaxRarity or Config.SellMaxRarity
    Config.AutoStartWorldId = AutoStartWorldId or Config.AutoStartWorldId
    Config.AutoStartDifficulty = AutoStartDifficulty or Config.AutoStartDifficulty
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
_G.AutoBuy = Config.AutoBuy
_G.AutoSell = Config.AutoSell
_G.AutoSeasonBuy = Config.AutoSeasonBuy

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
AutoBuyWantedItemIds = Config.AutoBuyWantedItemIds
AutoSeasonBuyWantedItemIds = Config.AutoSeasonBuyWantedItemIds
local AutoBuyDelay = 0.55
local AutoSeasonBuyDelay = 1.0
SellMaxRarity = Config.SellMaxRarity
OreSellModes = Config.OreSellModes
local AutoSellDelay = 5.0
local AutoSellContextDelay = 0.25
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
        if _G.AutoBuy then
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
        if _G.AutoSeasonBuy then
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

local CachedGoldShopCatalog = nil
local CachedSeasonShopCatalog = nil
local CachedOreCatalog = nil
local CachedDungeonCatalog = nil
local CachedDifficultyCatalogs = {}

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

local function GetDungeonCatalog(ForceRefresh)
    if CachedDungeonCatalog and not ForceRefresh then
        return CachedDungeonCatalog
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
    CachedDungeonCatalog = Result
    return Result
end

local function GetDifficultyCatalog(WorldId, ForceRefresh)
    if CachedDifficultyCatalogs[WorldId] and not ForceRefresh then
        return CachedDifficultyCatalogs[WorldId]
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

    for DiffLevel = 1, 5 do
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
    CachedDifficultyCatalogs[WorldId] = Result
    return Result
end

local function FindDungeonEntry(WorldId, ForceRefresh)
    for _, Entry in ipairs(GetDungeonCatalog(ForceRefresh)) do
        if Entry.WorldId == WorldId then
            return Entry
        end
    end
end

local function FindHighestUnlockedDifficulty(WorldId, ForceRefresh)
    local Selected = nil
    for _, Entry in ipairs(GetDifficultyCatalog(WorldId, ForceRefresh)) do
        if Entry.Unlocked and (not Selected or Entry.Level > Selected.Level) then
            Selected = Entry
        end
    end
    return Selected
end

local function ValidateAutoStartSelection(PreferHighest)
    local Changed = false
    local Dungeon = FindDungeonEntry(AutoStartWorldId, true)
    if not Dungeon or not Dungeon.Unlocked then
        Dungeon = nil
        for _, Entry in ipairs(GetDungeonCatalog()) do
            if Entry.Unlocked then
                Dungeon = Entry
                break
            end
        end
        if not Dungeon then
            return false
        end
        AutoStartWorldId = Dungeon.WorldId
        Changed = true
    end

    local Difficulty = nil
    if not PreferHighest then
        for _, Entry in ipairs(GetDifficultyCatalog(AutoStartWorldId, true)) do
            if Entry.Level == AutoStartDifficulty and Entry.Unlocked then
                Difficulty = Entry
                break
            end
        end
    end
    Difficulty = Difficulty or FindHighestUnlockedDifficulty(AutoStartWorldId)
    if not Difficulty then
        return false
    end
    if AutoStartDifficulty ~= Difficulty.Level then
        AutoStartDifficulty = Difficulty.Level
        Changed = true
    end
    if Changed then
        SaveConfig()
    end
    return true
end

local function SelectAutoStartWorld(WorldId)
    local Entry = FindDungeonEntry(WorldId, true)
    if not Entry or not Entry.Unlocked then
        return false
    end
    AutoStartWorldId = Entry.WorldId
    if not ValidateAutoStartSelection(true) then
        return false
    end
    SaveConfig()
    return true
end

local function SelectAutoStartDifficulty(DiffLevel)
    for _, Entry in ipairs(GetDifficultyCatalog(AutoStartWorldId, true)) do
        if Entry.Level == DiffLevel and Entry.Unlocked then
            AutoStartDifficulty = Entry.Level
            SaveConfig()
            return true
        end
    end
    return false
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
    local Result = {}

    for OreId, Count in pairs(Ores) do
        local Def = ForgeUtil:GetDef(OreId)
        if Def then
            local Rarity = tonumber(Def.Rarity) or 0
            local RarityName = tostring(Rarity)
            pcall(function()
                RarityName = RarityTiers:GetTierName(Rarity)
            end)
            table.insert(Result, {
                ItemId = OreId,
                ItemType = "Ore",
                Count = tonumber(Count) or 0,
                Rarity = Rarity,
                RarityName = RarityName,
                Def = Def
            })
        end
    end

    table.sort(Result, function(A, B)
        if A.Rarity == B.Rarity then
            return A.ItemId < B.ItemId
        end
        return A.Rarity > B.Rarity
    end)
    CachedOreCatalog = Result
    return CachedOreCatalog
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
    if SellPending or not _G.AutoFarm or not _G.AutoReplay then
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

    if not ValidateAutoStartSelection(false) then
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

task.spawn(function()
    while true do
        task.wait(0.5)
        if AutoStartPending and _G.AutoFarm and _G.AutoReplay and not SellPending then
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
        if _G.AutoSell and IsInLobby and IsInLobby() then
            pcall(TryAutoSellOresOnce)
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
        StatsLabel.Text = "CHEST DESTROYED: " .. ChestDestroyedCount .. "\nEGG TRIGGERED: " .. EggTriggeredCount
    end
end

IsInLobby = function()
    return workspace:FindFirstChild("MatchRoom") ~= nil and workspace:FindFirstChild("WorldEnemys") == nil and
               workspace:FindFirstChild("DragonEgg") == nil
end

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
    if _G.AutoFarm and _G.UndergroundMode and not IsInLobby() and LocalPlayer.Character and
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

local function IsSkillReady(key)
    local Button = GetSkillButton(key)
    if Button then
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
        if _G.AutoFarm and _G.AutoSkill and not IsInLobby() and LocalPlayer.Character and Target and not IsExtractingEgg and
            not IsEnteringPortal then
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
    if _G.AutoFarm and not IsInLobby() and LocalPlayer.Character and Target and not IsExtractingEgg and not IsEnteringPortal then
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
        if _G.AutoFarm then
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
    if not MyRoot or not MyHumanoid or IsEnteringPortal or not _G.AutoFarm or IsInLobby() then
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
    if _G.AutoFarm and not IsInLobby() and LocalPlayer.Character then
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

local function BuildV6Menu()
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
D3DPanel.ClipsDescendants = true
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
FarmTabButton.Size = UDim2.new(0.5, -3, 1, 0)

local UtilityTabButton = CreateButton(Navigation, "UTILITY")
UtilityTabButton.Name = "UtilityTabButton"
UtilityTabButton.Position = UDim2.new(0.5, 3, 0, 0)
UtilityTabButton.Size = UDim2.new(0.5, -3, 1, 0)

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

local function SetMainTab(Name)
    local IsFarm = Name == "Farm"
    FarmTab.Visible = IsFarm
    UtilityTab.Visible = not IsFarm
    FarmTabButton.BackgroundColor3 = IsFarm and Theme.Accent or Theme.Surface
    UtilityTabButton.BackgroundColor3 = IsFarm and Theme.Surface or Theme.Accent
end
FarmTabButton.Activated:Connect(function()
    SetMainTab("Farm")
end)
UtilityTabButton.Activated:Connect(function()
    SetMainTab("Utility")
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
StatsLabel.Size = UDim2.new(1, 0, 0, 62)
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

local function CreateSelectorDropdown(Parent, Name, PositionY)
    local Button = CreateButton(Parent, "")
    Button.Name = Name .. "Dropdown"
    Button.Position = UDim2.fromOffset(0, PositionY)
    Button.Size = UDim2.new(1, 0, 0, 34)
    Button.TextXAlignment = Enum.TextXAlignment.Left

    local Options = Instance.new("ScrollingFrame")
    Options.Name = Name .. "Options"
    Options.Position = UDim2.fromOffset(0, PositionY + 38)
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

    Button.Activated:Connect(function()
        Options.Visible = not Options.Visible
    end)
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
local DifficultyDropdown, DifficultyOptions = CreateSelectorDropdown(DungeonPage, "Difficulty", 126)

local PartyStatus = CreateText(DungeonPage, "Party Size   SOLO 1/1", 12)
PartyStatus.Position = UDim2.fromOffset(10, 210)
PartyStatus.Size = UDim2.new(1, -20, 0, 30)
local TriggerStatus = CreateText(DungeonPage, "Trigger      AFTER AUTO-SELL", 12)
TriggerStatus.Position = UDim2.fromOffset(10, 246)
TriggerStatus.Size = UDim2.new(1, -20, 0, 30)

local GroceryPage = CreateCatalogPage("GroceryPage")
local SeasonPage = CreateCatalogPage("SeasonPage")
local AutoSellPage = CreateCatalogPage("AutoSellPage")

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
    for _, Entry in ipairs(GetDifficultyCatalog(AutoStartWorldId)) do
        if Entry.Level == AutoStartDifficulty then
            return Entry.DisplayName
        end
    end
    return "Unavailable"
end

local function BuildDifficultyOptions(ForceRefresh)
    ClearSelectorOptions(DifficultyOptions)
    for _, Entry in ipairs(GetDifficultyCatalog(AutoStartWorldId, ForceRefresh)) do
        AddSelectorOption(DifficultyOptions, Entry.DisplayName, Entry.Unlocked, function()
            if SelectAutoStartDifficulty(Entry.Level) then
                DifficultyDropdown.Text = "  " .. Entry.DisplayName .. "  \226\150\188"
            end
        end)
    end
    DifficultyOptions.Size = UDim2.new(1, 0, 0, math.min(180, #GetDifficultyCatalog(AutoStartWorldId) * 32 + 10))
    DifficultyDropdown.Text = "  " .. FindSelectedDifficultyName() .. "  \226\150\188"
end

local function BuildDungeonPage(ForceRefresh)
    ValidateAutoStartSelection(false)
    ClearSelectorOptions(DungeonOptions)
    local SelectedName = AutoStartWorldId
    local Catalog = GetDungeonCatalog(ForceRefresh)
    for _, Entry in ipairs(Catalog) do
        if Entry.WorldId == AutoStartWorldId then
            SelectedName = Entry.DisplayName
        end
        AddSelectorOption(DungeonOptions, Entry.DisplayName, Entry.Unlocked, function()
            if SelectAutoStartWorld(Entry.WorldId) then
                BuildDungeonPage(true)
            end
        end)
    end
    DungeonOptions.Size = UDim2.new(1, 0, 0, math.min(180, #Catalog * 32 + 10))
    DungeonDropdown.Text = "  " .. SelectedName .. "  \226\150\188"
    BuildDifficultyOptions(ForceRefresh)
end

local function SetUtilityPage(Name)
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
    local Success, ErrorMessage = pcall(BuildV6Menu)
    if not Success then
        warn("[Bugon V6] menu error: " .. tostring(ErrorMessage))
    end
end)
