local Framework = require(game.ReplicatedStorage:WaitForChild("Framework"))
local DataUtil = Framework.Modules.DataUtil
local ForgeUtil = Framework.Modules.ForgeUtil
local RarityTiers = Framework.Modules.RarityTiers
local Ores = DataUtil:GetValue(game.Players.LocalPlayer, {"Ores"}) or {}

local TeksLog = "--- DATA ORES & RARITY TIERS ---\n"

for OreId, Count in pairs(Ores) do
    local Def = ForgeUtil:GetDef(OreId)
    local Rarity = Def and Def.Rarity or "nil"
    
    local ok, RarityName = pcall(function()
        return RarityTiers:GetTierName(Rarity)
    end)
    local FinalRarityName = (ok and RarityName) or "unknown"
    
    -- Tetap print di F9 console sebagai pantauan
    print(OreId, Count, Rarity, FinalRarityName)
    
    -- Menyusun teks untuk clipboard
    TeksLog = TeksLog .. string.format("Ore: %s | Count: %s | Rarity Level: %s | Tier: %s\n", tostring(OreId), tostring(Count), tostring(Rarity), tostring(FinalRarityName))
end

-- Eksekusi salin ke clipboard PC
if setclipboard then
    setclipboard(TeksLog)
    print("📋 [Clipboard]: Data Ores & Rarity Tiers berhasil disalin!")
elseif toclipboard then
    toclipboard(TeksLog)
    print("📋 [Clipboard]: Data Ores & Rarity Tiers berhasil disalin!")
else
    warn("❌ Executor kamu tidak mendukung fungsi setclipboard / toclipboard.")
end