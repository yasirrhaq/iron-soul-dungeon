# Focused Season Shop State Probe

Use this after `dump/season-shop-state-api-probe-dump.md` showed `SeasonUtil.GetShopData` exists, but the broad probe stopped before safe getter calls.

Run in dungeon first. Copy F9 lines starting with `[SeasonShopState]`.

Safety:
- Does not call `BuySeasonShopItem`.
- Does not fire any remote.
- Only calls read methods: `GetShopData`, `GetSeasonPass`, `GetShopRefreshTime`, `GetCurrentSeason`.

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local SeasonUtil = Framework.Modules.SeasonUtil
local ResSeasonShop = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("ResSeasonShop"))

local Prefix = "[SeasonShopState]"

-- [PERBAIKAN] Mengamankan fungsi print asli Roblox agar tidak memicu blocked thread
local oldPrint = print
local TeksLog = "--- SEASON SHOP STATE LOG ---\n"

local function print(...)
    local Parts = {}
    local Args = {...}
    for i = 1, #Args do
        table.insert(Parts, tostring(Args[i]))
    end
    local Line = table.concat(Parts, " ")
    
    -- Menggunakan print asli bawaan Roblox (Aman & Anti-Blocked)
    oldPrint(Line) 
    TeksLog = TeksLog .. Line .. "\n"
end

local function Short(Value, Depth, Seen)
    Depth = Depth or 2
    Seen = Seen or {}
    local ValueType = typeof and typeof(Value) or type(Value)

    if ValueType == "Instance" then
        return Value:GetFullName() .. " <" .. Value.ClassName .. ">"
    end

    if type(Value) ~= "table" then
        return tostring(Value)
    end

    if Seen[Value] then
        return "{cycle}"
    end
    if Depth <= 0 then
        return "{...}"
    end

    Seen[Value] = true
    local Parts = {}
    local Count = 0
    for Key, ChildValue in pairs(Value) do
        Count = Count + 1
        if Count <= 24 then
            table.insert(Parts, tostring(Key) .. "=" .. Short(ChildValue, Depth - 1, Seen))
        end
    end
    if Count > 24 then
        table.insert(Parts, "...+" .. tostring(Count - 24))
    end
    Seen[Value] = nil
    return "{" .. table.concat(Parts, ", ") .. "}"
end

local function LogCall(Label, Fn)
    local Ok, A, B, C = pcall(Fn)
    if Ok then
        print(Prefix, Label, "OK", Short(A, 3), Short(B, 2), Short(C, 2))
    else
        print(Prefix, Label, "FAIL", tostring(A))
    end
    return Ok, A, B, C
end

local function DumpShopData(Label, Data)
    print(Prefix, Label, "RAW", Short(Data, 3))
    if type(Data) ~= "table" then
        return
    end

    local NormalIds = Data.NormalIds or (Data.ShopData and Data.ShopData.NormalIds)
    local SpecialId = Data.SpecialId or (Data.ShopData and Data.ShopData.SpecialId)
    local BuyCount = Data.BuyCount or (Data.ShopData and Data.ShopData.BuyCount) or {}

    print(Prefix, Label, "SpecialId", tostring(SpecialId), "BuyCount", Short(BuyCount, 2))
    if SpecialId and ResSeasonShop[SpecialId] then
        local Config = ResSeasonShop[SpecialId]
        print(Prefix, Label, "SPECIAL", SpecialId, Config.ItemId, Config.Price, "bought", tostring(BuyCount[SpecialId]))
    end

    if type(NormalIds) == "table" then
        for Slot, ShopId in pairs(NormalIds) do
            local Config = ResSeasonShop[ShopId]
            print(Prefix, Label, "NORMAL", tostring(Slot), tostring(ShopId), Config and tostring(Config.ItemId) or "?", Config and tostring(Config.Price) or "?", "bought", tostring(BuyCount[ShopId]))
        end
    else
        print(Prefix, Label, "NormalIds missing", Short(NormalIds, 2))
    end
end

print(Prefix, "START", "place", game.PlaceId, "job", game.JobId)
print(Prefix, "SeasonUtil has GetShopData", tostring(type(SeasonUtil.GetShopData)))

LogCall("GetCurrentSeason colon", function()
    return SeasonUtil:GetCurrentSeason(LocalPlayer)
end)

LogCall("GetShopRefreshTime colon", function()
    return SeasonUtil:GetShopRefreshTime(LocalPlayer)
end)

local OkPass, SeasonPass = LogCall("GetSeasonPass colon", function()
    return SeasonUtil:GetSeasonPass(LocalPlayer)
end)
if OkPass then
    DumpShopData("GetSeasonPass", SeasonPass)
end

local Calls = {
    {"GetShopData colon player", function() return SeasonUtil:GetShopData(LocalPlayer) end},
    {"GetShopData colon noarg", function() return SeasonUtil:GetShopData() end},
    {"GetShopData dot player", function() return SeasonUtil.GetShopData(LocalPlayer) end},
    {"GetShopData dot util player", function() return SeasonUtil.GetShopData(SeasonUtil, LocalPlayer) end}
}

for _, Entry in ipairs(Calls) do
    local Ok, Result = LogCall(Entry[1], Entry[2])
    if Ok then
        DumpShopData(Entry[1], Result)
    end
end

print(Prefix, "END")

-- Eksekusi salin data ke clipboard
if setclipboard then
    setclipboard(TeksLog)
    oldPrint("📋 [Clipboard]: Log SeasonShopState berhasil disalin tanpa error!")
elseif toclipboard then
    toclipboard(TeksLog)
    oldPrint("📋 [Clipboard]: Log SeasonShopState berhasil disalin tanpa error!")
else
    oldPrint("❌ Executor kamu tidak mendukung fungsi setclipboard / toclipboard.")
end
```
