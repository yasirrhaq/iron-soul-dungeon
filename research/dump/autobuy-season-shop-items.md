# Season Shop Auto-Buy Notes

Source:
- `dump/dump-autobuy-season-util-shop.lua`
- `dump/autobuy-season-shop.md`

## Buy Remote

Remote path:

```lua
game:GetService("ReplicatedStorage")
    :WaitForChild("Framework")
    :WaitForChild("Features")
    :WaitForChild("SeasonSystem")
    :WaitForChild("SeasonUtil")
    :WaitForChild("RemoteEvent")
```

Buy call:

```lua
RemoteEvent:FireServer("BuySeasonShopItem", shopId)
```

Example from dump:

```lua
RemoteEvent:FireServer("BuySeasonShopItem", "SeasonShop_05")
```

UI buy path from `dump/dump-autobuy-season-util-shop.lua`:

```lua
local Framework = require(game.ReplicatedStorage:WaitForChild("Framework"))
local SeasonUtil = Framework.Modules.SeasonUtil
SeasonUtil:BuySeasonShopItem(game.Players.LocalPlayer, shopId)
```

## Runtime Item Probe

Use this to print all possible `ResSeasonShop` entries and current visible store slots.
Open/run in executor, then copy F9 output lines starting with `[SeasonShopDump]`.

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local ResSeasonShop = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("ResSeasonShop"))
local GameEnum = require(ReplicatedStorage:WaitForChild("Enum"):WaitForChild("GameEnum"))

local ThingTypeName = {}
for Name, Value in pairs(GameEnum.ThingType or {}) do
    ThingTypeName[Value] = Name
end

local function TypeName(Value)
    return tostring(ThingTypeName[Value] or Value)
end

local function DumpConfig(Label, ShopId)
    local Config = ResSeasonShop[ShopId]
    if type(Config) ~= "table" then
        print("[SeasonShopDump] MISSING", Label, tostring(ShopId))
        return
    end

    print(string.format(
        "[SeasonShopDump] %s ShopId=%s ItemId=%s ItemType=%s ItemCount=%s Price=%s LimitTimes=%s IsSpecial=%s",
        tostring(Label),
        tostring(ShopId),
        tostring(Config.ItemId),
        TypeName(Config.ItemType),
        tostring(Config.ItemCount),
        tostring(Config.Price),
        tostring(Config.LimitTimes),
        tostring(Config.IsSpecial)
    ))
end

pcall(function()
    ReplicatedStorage:WaitForChild("Framework")
        :WaitForChild("Features")
        :WaitForChild("TaskSystem")
        :WaitForChild("TaskRE")
        :FireServer("UpdateTaskProgress", "OpenGUIWindow", "ScreenSeasonPass")
end)

task.wait(1)

local FoundCurrent = {}
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
for _, Obj in ipairs(PlayerGui:GetDescendants()) do
    local ShopId = Obj:GetAttribute("ShopId")
    if type(ShopId) == "string" and ResSeasonShop[ShopId] and not FoundCurrent[ShopId] then
        FoundCurrent[ShopId] = true
        DumpConfig("CURRENT " .. Obj:GetFullName(), ShopId)
    end
end

if not next(FoundCurrent) then
    print("[SeasonShopDump] CURRENT none; open Season Pass > Store once, then rerun")
end

local AllIds = {}
for ShopId in pairs(ResSeasonShop) do
    table.insert(AllIds, ShopId)
end

table.sort(AllIds, function(A, B)
    return tostring(A) < tostring(B)
end)

print("[SeasonShopDump] ALL START count=" .. tostring(#AllIds))
for _, ShopId in ipairs(AllIds) do
    DumpConfig("ALL", ShopId)
end
print("[SeasonShopDump] ALL END")
```

## Captured Current Stock

Captured from F9 output. Special slot plus normal slots `1`-`6`.

| Slot | ShopId | ItemId | Type | Count | Price | Limit | Special |
| --- | --- | --- | --- | ---: | ---: | --- | --- |
| `Special` | `SeasonShop_02` | `Staff_SkyMace_S2:Staff_SkyMace_S2` | `DataEquipment` | 1 | 6000 | 1 | true |
| `1` | `SeasonShop_16` | `GoldPotion_1` | `Potion` | 1 | 500 |  | false |
| `2` | `SeasonShop_15` | `Currency1` | `Currency` | 1500 | 300 |  | false |
| `3` | `SeasonShop_13` | `Ticket1` | `Currency` | 1 | 1000 |  | false |
| `4` | `SeasonShop_09` | `CrystalPrism` | `Crystals` | 3 | 500 |  | false |
| `5` | `SeasonShop_20` | `AtkPotion_1` | `Potion` | 1 | 800 |  | false |
| `6` | `SeasonShop_10` | `DragonTear` | `Crystals` | 3 | 2000 |  | false |

## Captured Full Pool

Captured from `ResSeasonShop`. Dump count was `23` because module also exposes `__index`; skip that key.

| ShopId | ItemId | Type | Count | Price | Limit | Special |
| --- | --- | --- | ---: | ---: | --- | --- |
| `SeasonShop_01` | `Pet_Eagle` | `Pet` | 1 | 5000 | 4 | true |
| `SeasonShop_02` | `Staff_SkyMace_S2:Staff_SkyMace_S2` | `DataEquipment` | 1 | 6000 | 1 | true |
| `SeasonShop_03` | `Single_SkySword_S2:Single_SkySword_S2` | `DataEquipment` | 1 | 4000 | 1 | true |
| `SeasonShop_04` | `SkywyrmFist_T4:SkywyrmFist_T4` | `DataEquipment` | 1 | 15000 | 1 | true |
| `SeasonShop_05` | `RaceSpins` | `RaceSpins` | 1 | 2000 |  | false |
| `SeasonShop_06` | `SeasonTicket` | `Currency` | 1 | 1600 |  | false |
| `SeasonShop_07` | `Hellstone` | `Ore` | 1 | 3500 |  | false |
| `SeasonShop_08` | `CrystalGem` | `Crystals` | 3 | 1200 |  | false |
| `SeasonShop_09` | `CrystalPrism` | `Crystals` | 3 | 500 |  | false |
| `SeasonShop_10` | `DragonTear` | `Crystals` | 3 | 2000 |  | false |
| `SeasonShop_11` | `BowRelic_1` | `Crystals` | 1 | 1500 |  | false |
| `SeasonShop_12` | `FistRelic_1` | `Crystals` | 1 | 1000 |  | false |
| `SeasonShop_13` | `Ticket1` | `Currency` | 1 | 1000 |  | false |
| `SeasonShop_14` | `DetachTool` | `Currency` | 1 | 1200 |  | false |
| `SeasonShop_15` | `Currency1` | `Currency` | 1500 | 300 |  | false |
| `SeasonShop_16` | `GoldPotion_1` | `Potion` | 1 | 500 |  | false |
| `SeasonShop_17` | `EXPPotion_1` | `Potion` | 1 | 500 |  | false |
| `SeasonShop_18` | `LuckPotion_1` | `Potion` | 1 | 4000 |  | false |
| `SeasonShop_19` | `DropPotion_1` | `Potion` | 1 | 3000 |  | false |
| `SeasonShop_20` | `AtkPotion_1` | `Potion` | 1 | 800 |  | false |
| `SeasonShop_21` | `HPPotion_1` | `Potion` | 1 | 800 |  | false |
| `SeasonShop_22` | `CHPotion_1` | `Potion` | 1 | 1000 |  | false |

## Auto-Buy Plan

- Keep `_G.AutoSeasonBuy` default `false`.
- Match by `ItemId`, not fixed `SeasonShop_*` key.
- Skip bought-out items with `BuyCount`/UI purchased state when available.
- Log each buy attempt: `ShopId`, `ItemId`, `Price`, and result path.

