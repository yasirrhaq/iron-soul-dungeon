# Consumable Shop Auto-Buy Notes

Source:
- `dump/dump-autobuy-util-shop.lua`
- Runtime console shop snapshot from `ShopUtil:GetShopSnapshot(LocalPlayer, shopKey)`
- Runtime pool dump from `getupvalues(ShopUtil.BuyItem)[2]`

## Buy Remote

Remote path:

```lua
game:GetService("ReplicatedStorage")
    :WaitForChild("Framework")
    :WaitForChild("Features")
    :WaitForChild("ConsumableShopSystem")
    :WaitForChild("ConsumableShopUtil")
    :WaitForChild("RemoteEvent")
```

Buy call:

```lua
RemoteEvent:FireServer("BuyShopItem", shopKey, itemKey)
```

Example:

```lua
RemoteEvent:FireServer("BuyShopItem", "Gold", "GoldShop_25")
```

Server-side behavior from dump:
- Rejects repeat buy faster than `0.3s` with `K_SHOP_TOO_FAST`.
- Rejects when `StockLimit[itemKey] <= BuyCount[itemKey]`.
- Rejects when player cannot afford `v76.Price` in shop currency.
- On success: spends currency, gives `ItemId`, increments `BuyCount`.

Recommended delay: `0.5s` between buy attempts.

## Current Stock Probe

Use this to discover current rotating item keys and item ids:

```lua
local Players = game:GetService("Players")
local ShopUtil = require(game:GetService("ReplicatedStorage")
    :WaitForChild("Framework")
    :WaitForChild("Features")
    :WaitForChild("ConsumableShopSystem")
    :WaitForChild("ConsumableShopUtil"))

local function DumpShop(shopKey)
    local Snapshot = ShopUtil:GetShopSnapshot(Players.LocalPlayer, shopKey)
    print("SHOP", shopKey, Snapshot and Snapshot.Currency)
    if not Snapshot then return end

    for ItemKey, Item in pairs(Snapshot.Items) do
        print(ItemKey, Item.ItemId, Item.ItemType, "price", Item.Price, "stock", Item.Stock, "state", Item.State)
    end
end

DumpShop("Gold")
DumpShop("Bond")
```

## Full Pool Probe

Use this to discover all possible shop items, not only current stock:

```lua
local ShopUtil = require(game:GetService("ReplicatedStorage")
    :WaitForChild("Framework")
    :WaitForChild("Features")
    :WaitForChild("ConsumableShopSystem")
    :WaitForChild("ConsumableShopUtil"))

local up = getupvalues(ShopUtil.BuyItem)
local ShopItems = up[2]

for shopKey, items in pairs(ShopItems) do
    print("POOL", shopKey)
    for _, itemKey in ipairs(items.__index or {}) do
        local item = items[itemKey]
        print(itemKey, item.ItemId, item.ItemType, "price", item.Price, "stock", item.StockMin, item.StockMax)
    end
end
```

## Full Gold Pool

Captured from pool dump. Stock columns are `StockMin` and `StockMax`.

| Item Key | ItemId | Type | Price | StockMin | StockMax |
| --- | --- | --- | ---: | ---: | ---: |
| `GoldShop_01` | `Hellstone4` | `Ore` | 30000 | 1 | 1 |
| `GoldShop_02` | `Starfall` | `Ore` | 25000 | 1 | 1 |
| `GoldShop_03` | `Redsunder` | `Ore` | 20000 | 1 | 1 |
| `GoldShop_04` | `Glacium` | `Ore` | 18000 | 1 | 1 |
| `GoldShop_05` | `Hellstone3` | `Ore` | 16000 | 1 | 1 |
| `GoldShop_06` | `Earthmaw` | `Ore` | 16000 | 1 | 1 |
| `GoldShop_07` | `Voidstar` | `Ore` | 15000 | 1 | 1 |
| `GoldShop_08` | `Sunflare` | `Ore` | 14000 | 1 | 1 |
| `GoldShop_09` | `VoidcubeCrystal` | `Ore` | 12000 | 1 | 2 |
| `GoldShop_10` | `RoseTourmaline` | `Ore` | 8000 | 1 | 2 |
| `GoldShop_11` | `BerylFragment` | `Ore` | 6000 | 1 | 2 |
| `GoldShop_12` | `IceCrystalOre` | `Ore` | 4000 | 1 | 3 |
| `GoldShop_13` | `Sunstone` | `Ore` | 2000 | 1 | 3 |
| `GoldShop_14` | `CrystalGem` | `Crystals` | 10000 | 1 | 5 |
| `GoldShop_15` | `CrystalPrism` | `Crystals` | 5000 | 1 | 5 |
| `GoldShop_16` | `CrystalFlake` | `Crystals` | 3000 | 1 | 5 |
| `GoldShop_17` | `CrystalShards` | `Crystals` | 1000 | 1 | 5 |
| `GoldShop_18` | `Burn_3` | `EnchantedStone` | 3000 | 1 | 3 |
| `GoldShop_19` | `Methysis_3` | `EnchantedStone` | 3000 | 1 | 3 |
| `GoldShop_20` | `Frost_3` | `EnchantedStone` | 3000 | 1 | 3 |
| `GoldShop_21` | `Corrode_3` | `EnchantedStone` | 3000 | 1 | 3 |
| `GoldShop_22` | `GoldPotion_1` | `Potion` | 2000 | 1 | 1 |
| `GoldShop_23` | `EXPPotion_1` | `Potion` | 2000 | 1 | 3 |
| `GoldShop_24` | `LuckPotion_1` | `Potion` | 15000 | 1 | 1 |
| `GoldShop_25` | `DropPotion_1` | `Potion` | 12000 | 1 | 1 |
| `GoldShop_26` | `AtkPotion_1` | `Potion` | 3000 | 1 | 2 |
| `GoldShop_27` | `HPPotion_1` | `Potion` | 3000 | 1 | 2 |
| `GoldShop_28` | `CHPotion_1` | `Potion` | 4000 | 1 | 2 |
| `GoldShop_29` | `BrokenDragonScale` | `Crystals` | 1000 | 1 | 3 |
| `GoldShop_30` | `WholeDragonScale` | `Crystals` | 2000 | 1 | 3 |
| `GoldShop_31` | `DragonClaw` | `Crystals` | 3500 | 1 | 3 |
| `GoldShop_32` | `DragonHorn` | `Crystals` | 5000 | 1 | 3 |
| `GoldShop_33` | `DragonTear` | `Crystals` | 7500 | 1 | 3 |
| `GoldShop_34` | `BondPotion_1` | `Potion` | 8000 | 1 | 2 |

## Full Bond Pool

Captured from pool dump. Stock columns are `StockMin` and `StockMax`.

| Item Key | ItemId | Type | Price | StockMin | StockMax |
| --- | --- | --- | ---: | ---: | ---: |
| `BondShop_1` | `RaceSpins` | `RaceSpins` | 1500 | 1 | 1 |
| `BondShop_2` | `Gem` | `Currency` | 700 | 1 | 1 |
| `BondShop_3` | `GoldPotion_1` | `Potion` | 80 | 1 | 1 |
| `BondShop_4` | `EXPPotion_1` | `Potion` | 80 | 1 | 1 |
| `BondShop_5` | `LuckPotion_1` | `Potion` | 600 | 1 | 1 |
| `BondShop_6` | `DropPotion_1` | `Potion` | 480 | 1 | 1 |
| `BondShop_7` | `AtkPotion_1` | `Potion` | 120 | 1 | 1 |
| `BondShop_8` | `HPPotion_1` | `Potion` | 120 | 1 | 1 |
| `BondShop_9` | `CHPotion_1` | `Potion` | 160 | 1 | 1 |
| `BondShop_10` | `BondPotion_1` | `Potion` | 450 | 1 | 1 |

## Current Stock Notes

`ShopUtil:GetShopSnapshot(LocalPlayer, shopKey)` only returns current rolled stock from `StockLimit`. It does not list the full pool.

Current stock fields:
- `Item.State == "normal"`: affordable and in stock.
- `Item.State == "poor"`: in stock but not enough currency.
- `Item.State == "soldout"`: no remaining stock.

## Auto-Buy Targeting Design

Prefer matching by `ItemId`, not fixed `GoldShop_XX`, because current stock rotates but pool keys stay useful for buying.

Example wanted list:

```lua
local AutoBuyWantedItemIds = {
    Hellstone4 = true,
    Starfall = true,
    Redsunder = true,
    Glacium = true,
    VoidcubeCrystal = true,
    CrystalGem = true,
    DragonClaw = true,
    WholeDragonScale = true,
    DragonTear = true,
    DragonHorn = true,
}
```

Runtime loop should:
- Read `ShopUtil:GetShopSnapshot(LocalPlayer, "Gold")`.
- Iterate `Snapshot.Items`.
- Buy only when `Item.State == "normal"` and `AutoBuyWantedItemIds[Item.ItemId]`.
- Fire `RemoteEvent:FireServer("BuyShopItem", "Gold", ItemKey)`.
- Wait at least `0.5s` between attempts.

Optional UI toggle:
- Add `_G.AutoBuy = false` by default.
- Add `AUTO BUY: YES/NO` button.
- Keep disabled by default because it spends currency.
