local v_u_1 = require(script.ShopRegistry)
local v_u_2 = require(game.ReplicatedStorage:WaitForChild("Utility"):WaitForChild("Timer"))
local v_u_3 = {}
local v_u_4 = {}
local v_u_5 = {}
local v_u_6 = {}
local v_u_7 = nil
local v_u_8 = nil
local v_u_9 = nil
local v_u_10 = nil
local v_u_11 = {}
function v_u_6.GetShopConfig(_, p12) -- name: GetShopConfig
	-- upvalues: (copy) v_u_1
	return v_u_1[p12]
end
function v_u_6.GetAllShopConfigs(_) -- name: GetAllShopConfigs
	-- upvalues: (copy) v_u_1
	return v_u_1
end
function v_u_6.GetNowTime(_) -- name: GetNowTime
	-- upvalues: (ref) v_u_8
	if not v_u_8 then
		v_u_8 = game.ReplicatedStorage:WaitForChild("Time")
	end
	while v_u_8.Value <= 0 do
		task.wait()
	end
	local v13 = v_u_8.Value
	return math.floor(v13)
end
function v_u_6.GetShopData(_, p14, p15) -- name: GetShopData
	-- upvalues: (copy) v_u_1, (ref) v_u_7
	local v16 = v_u_1[p15]
	if v16 then
		local v17 = v_u_7:GetPlayerData(p14)
		if v17 then
			return v17[v16.ProfileKey]
		else
			return nil
		end
	else
		return nil
	end
end
function v_u_6.RefreshStock(p18, _, p19, p20) -- name: RefreshStock
	-- upvalues: (copy) v_u_1, (copy) v_u_11
	if not p18.IS_SERVER then
		return
	end
	if not p20 then
		return
	end
	local v21 = v_u_1[p19]
	local v22 = v_u_11[p19]
	if not (v21 and v22) then
		return
	end
	p20.BuyCount = {}
	p20.StockLimit = {}
	local v23 = {}
	local v24 = {}
	for _, v25 in ipairs(v22.__index) do
		table.insert(v23, v25)
		v24[v25] = v22[v25].Weight or 1
	end
	local v26 = v21.Config.ItemsPerRefresh
	local v27 = #v23
	for _ = 1, math.min(v26, v27) do
		local v28 = 0
		for _, v29 in ipairs(v23) do
			v28 = v28 + v24[v29]
		end
		local v30 = math.random() * v28
		local v31 = 0
		local v32 = 0
		for v33, v34 in ipairs(v23) do
			v31 = v31 + v24[v34]
			if v30 <= v31 then
				v32 = v33
				break
			end
		end
		if v32 == 0 then
			break
		end
		local v35 = v23[v32]
		local v36 = v22[v35]
		p20.StockLimit[v35] = math.random(v36.StockMin, v36.StockMax)
		table.remove(v23, v32)
	end
end
function v_u_6.UpdateRefreshTimer(p37, p38, p39) -- name: UpdateRefreshTimer
	-- upvalues: (copy) v_u_1, (copy) v_u_6
	if p37.IS_SERVER then
		local v40 = v_u_1[p38]
		if v40 then
			p39.RefreshTime = v_u_6:GetNowTime() + v40.Config.RefreshIntervalMin * 60
		end
	else
		return
	end
end
function v_u_6.CheckAutoRefresh(p41, p42, p43) -- name: CheckAutoRefresh
	-- upvalues: (copy) v_u_1, (copy) v_u_6, (ref) v_u_7
	if not p41.IS_SERVER then
		return false
	end
	local v44 = v_u_1[p43]
	local v45 = v_u_6:GetShopData(p42, p43)
	if not (v44 and v45) then
		return false
	end
	local v46 = v_u_6:GetNowTime()
	if v45.RefreshTime and v45.RefreshTime > v46 then
		return false
	end
	v_u_6:UpdateRefreshTimer(p43, v45)
	v_u_6:RefreshStock(p42, p43, v45)
	v_u_7:SetValue(p42, { v44.ProfileKey, "RefreshTime" }, v45.RefreshTime)
	v_u_7:SetValue(p42, { v44.ProfileKey, "BuyCount" }, v45.BuyCount)
	v_u_7:SetValue(p42, { v44.ProfileKey, "StockLimit" }, v45.StockLimit)
	return true
end
function v_u_6.DoRefresh(p47, p_u_48, p_u_49) -- name: DoRefresh
	-- upvalues: (copy) v_u_1, (copy) v_u_4, (copy) v_u_6, (ref) v_u_7
	if p47.IS_SERVER then
		if p_u_48 and p_u_49 then
			local v_u_50 = v_u_1[p_u_49]
			if v_u_50 then
				local v51 = v_u_4
				local v52 = v51[p_u_48]
				if not v52 then
					v52 = {}
					v51[p_u_48] = v52
				end
				if not v52[p_u_49] then
					v52[p_u_49] = true
					local v54, v55 = pcall(function()
						-- upvalues: (ref) v_u_6, (copy) p_u_48, (copy) p_u_49, (ref) v_u_7, (copy) v_u_50
						local v53 = v_u_6:GetShopData(p_u_48, p_u_49)
						if v53 then
							v_u_6:RefreshStock(p_u_48, p_u_49, v53)
							v_u_7:SetValue(p_u_48, { v_u_50.ProfileKey, "BuyCount" }, v53.BuyCount)
							v_u_7:SetValue(p_u_48, { v_u_50.ProfileKey, "StockLimit" }, v53.StockLimit)
						end
					end)
					v52[p_u_49] = nil
					if not v54 then
						warn("[ConsumableShopUtil] DoRefresh error for " .. p_u_48.Name .. " (" .. p_u_49 .. "): " .. tostring(v55))
					end
				end
			else
				return
			end
		else
			return
		end
	else
		return
	end
end
function v_u_6.CheckDailyPurchaseReset(p56, p57, p58) -- name: CheckDailyPurchaseReset
	-- upvalues: (copy) v_u_1, (copy) v_u_6, (ref) v_u_9, (ref) v_u_7
	if p56.IS_SERVER then
		local v59 = v_u_1[p58]
		local v60 = v_u_6:GetShopData(p57, p58)
		if v59 and v60 then
			local v61 = v_u_9:GetDate()
			if v60.LastPurchaseDate ~= v61 then
				v60.DailyPurchaseCount = 0
				v60.LastPurchaseDate = v61
				v_u_7:SetValue(p57, { v59.ProfileKey, "DailyPurchaseCount" }, 0)
				v_u_7:SetValue(p57, { v59.ProfileKey, "LastPurchaseDate" }, v61)
			end
		end
	else
		return
	end
end
function v_u_6.BuyItem(p_u_62, p_u_63, p_u_64, p_u_65) -- name: BuyItem
	-- upvalues: (copy) v_u_1, (copy) v_u_11, (copy) v_u_3, (copy) v_u_5, (copy) v_u_6, (ref) v_u_7
	if p_u_63 and (p_u_64 and p_u_65) then
		if p_u_62.IS_SERVER then
			local v_u_66 = v_u_1[p_u_64]
			local v_u_67 = v_u_11[p_u_64]
			if v_u_66 and v_u_67 then
				local v68 = p_u_62.Modules.WarningUtil
				local v69 = v_u_3
				local v70 = v69[p_u_63]
				if not v70 then
					v70 = {}
					v69[p_u_63] = v70
				end
				if v70[p_u_64] then
					v68:Warn(p_u_63, "K_SHOP_BUSY", {
						["IsPositive"] = false
					})
					return
				else
					local v71 = os.clock()
					local v72 = v_u_5[p_u_63]
					if v71 - (v72 and (v72[p_u_64] or 0) or 0) < 0.3 then
						v68:Warn(p_u_63, "K_SHOP_TOO_FAST", {
							["IsPositive"] = false
						})
					else
						v70[p_u_64] = true
						local v73 = v_u_5[p_u_63]
						if not v73 then
							v73 = {}
							v_u_5[p_u_63] = v73
						end
						v73[p_u_64] = v71
						local v_u_74 = nil
						local v79, v80 = pcall(function()
							-- upvalues: (ref) v_u_6, (copy) p_u_63, (copy) p_u_64, (copy) v_u_67, (copy) p_u_65, (ref) v_u_74, (copy) p_u_62, (copy) v_u_66, (ref) v_u_7
							local v75 = v_u_6:GetShopData(p_u_63, p_u_64)
							if v75 then
								local v76 = v_u_67[p_u_65]
								if v76 then
									local v77 = v75.StockLimit[p_u_65] or 0
									local v78 = v75.BuyCount[p_u_65] or 0
									if v77 <= v78 then
										v_u_74 = "K_SHOP_OUT_OF_STOCK"
										return
									elseif p_u_62.Modules.CurrencyUtil:Has(p_u_63, v_u_66.Currency, v76.Price) then
										v_u_6:CheckDailyPurchaseReset(p_u_63, p_u_64)
										if (v75.DailyPurchaseCount or 0) >= v_u_66.Config.MaxDailyPurchases then
											v_u_74 = "K_SHOP_DAILY_LIMIT"
										else
											p_u_62.Modules.CurrencyService:Spend(p_u_63, v_u_66.Currency, v76.Price, {
												["TransactionType"] = p_u_64 .. "ShopBuy"
											})
											p_u_62.Modules.GiveThingsUtil:Give(p_u_63, v76.ItemId, v76.ItemType, v76.ItemCount, true, p_u_64 .. "Shop", true)
											v_u_7:SetValue(p_u_63, { v_u_66.ProfileKey, "BuyCount", p_u_65 }, v78 + 1)
											v75.DailyPurchaseCount = (v75.DailyPurchaseCount or 0) + 1
											v_u_7:SetValue(p_u_63, { v_u_66.ProfileKey, "DailyPurchaseCount" }, v75.DailyPurchaseCount)
										end
									else
										v_u_74 = "K_SHOP_NOT_ENOUGH"
										return
									end
								else
									return
								end
							else
								return
							end
						end)
						v70[p_u_64] = nil
						if v79 then
							if v_u_74 then
								v68:Warn(p_u_63, v_u_74, {
									["IsPositive"] = false
								})
							end
						else
							warn("[ConsumableShopUtil] BuyItem error for " .. p_u_63.Name .. " (" .. p_u_64 .. "): " .. tostring(v80))
						end
					end
				end
			else
				return
			end
		else
			p_u_62.RemoteEvent:FireServer("BuyShopItem", p_u_64, p_u_65)
			return
		end
	else
		return
	end
end
function v_u_6.GetItemStock(_, p81, p82, p83) -- name: GetItemStock
	-- upvalues: (copy) v_u_6
	local v84 = v_u_6:GetShopData(p81, p82)
	if not v84 then
		return 0
	end
	local v85 = (v84.StockLimit[p83] or 0) - (v84.BuyCount[p83] or 0)
	return math.max(v85, 0)
end
function v_u_6.GetRefreshCountdown(_, p86, p87) -- name: GetRefreshCountdown
	-- upvalues: (copy) v_u_6
	local v88 = v_u_6:GetShopData(p86, p87)
	if not v88 then
		return 0
	end
	local v89 = v_u_6:GetNowTime()
	local v90 = (v88.RefreshTime or 0) - v89
	return math.max(v90, 0)
end
function v_u_6.GetShopSnapshot(p91, p92, p93) -- name: GetShopSnapshot
	-- upvalues: (copy) v_u_1, (copy) v_u_11, (copy) v_u_6, (ref) v_u_7, (ref) v_u_10
	local v94 = v_u_1[p93]
	local v95 = v_u_11[p93]
	local v96 = v_u_6:GetShopData(p92, p93)
	if not (v94 and (v95 and v96)) then
		return nil
	end
	if p91.IS_SERVER then
		v_u_6:CheckAutoRefresh(p92, p93)
		v96 = v_u_6:GetShopData(p92, p93)
	end
	local v97 = v_u_6:GetNowTime()
	local v98 = v_u_7:GetPlayerData(p92)
	local v99 = v98 and v98.Currency and (v98.Currency[v94.Currency] or 0) or 0
	local v100 = v_u_10:GetItem("Purchasables", v94.RefreshProductId)
	local v101 = v100 and v100.Price or 0
	local v102 = v96.DailyPurchaseCount or 0
	local v103 = v94.Config.MaxDailyPurchases - v102
	local v104 = math.max(v103, 0)
	local v105 = {
		["ShopId"] = p93,
		["Currency"] = v94.Currency,
		["RefreshTime"] = v96.RefreshTime
	}
	local v106 = (v96.RefreshTime or 0) - v97
	v105.Countdown = math.max(v106, 0)
	v105.RefreshCost = v101
	v105.CanAffordRefresh = v104 > 0
	v105.RemainingPurchases = v104
	v105.MaxDailyPurchases = v94.Config.MaxDailyPurchases
	v105.Items = {}
	for v107, v108 in pairs(v96.StockLimit) do
		local v109 = v95[v107]
		if v109 then
			local v110 = v108 - (v96.BuyCount[v107] or 0)
			local v111 = math.max(v110, 0)
			local v112
			if v109.Price <= v99 then
				v112 = v104 > 0
			else
				v112 = false
			end
			local v113 = v111 <= 0 and "soldout" or (v112 and "normal" or "poor")
			v105.Items[v107] = {
				["Id"] = v109.Id,
				["ItemId"] = v109.ItemId,
				["ItemType"] = v109.ItemType,
				["ItemCount"] = v109.ItemCount,
				["Price"] = v109.Price,
				["Stock"] = v111,
				["LimitStock"] = v108,
				["Affordable"] = v112,
				["State"] = v113
			}
		end
	end
	return v105
end
function v_u_6.Init(p114) -- name: Init
	-- upvalues: (ref) v_u_7, (ref) v_u_9, (ref) v_u_10, (copy) v_u_1, (copy) v_u_11
	v_u_7 = p114.Modules.DataUtil
	v_u_9 = p114.Modules.TimeUtil
	v_u_10 = p114.Modules.Items
	p114.RemoteEvent = script:WaitForChild("RemoteEvent")
	for v115, v116 in pairs(v_u_1) do
		local v117, v118 = pcall(require, game.ReplicatedStorage.Configs:WaitForChild(v116.ResModule))
		if v117 and v118 then
			v_u_11[v115] = v118
		else
			local v119 = warn
			local v120 = v116.ResModule
			v119("[ConsumableShopUtil] Failed to load ResModule " .. tostring(v120) .. " for shop " .. v115 .. ": " .. tostring(v118))
		end
	end
	if p114.IS_SERVER then
		for _, v121 in pairs(v_u_1) do
			p114.Modules.DataService:AddProfileSection(v121.ProfileKey, {
				["RefreshTime"] = 0,
				["BuyCount"] = nil,
				["StockLimit"] = nil,
				["DailyPurchaseCount"] = 0,
				["LastPurchaseDate"] = "",
				["BuyCount"] = {},
				["StockLimit"] = {}
			}, "Owner")
		end
	end
end
function v_u_6.Start(p122) -- name: Start
	-- upvalues: (ref) v_u_8, (copy) v_u_2, (ref) v_u_7, (copy) v_u_1, (copy) v_u_6, (copy) v_u_3, (copy) v_u_4, (copy) v_u_5
	v_u_8 = game.ReplicatedStorage:WaitForChild("Time")
	if p122.IS_SERVER then
		v_u_2:new(1, function()
			-- upvalues: (ref) v_u_7, (ref) v_u_1, (ref) v_u_6
			for v123, _ in pairs(v_u_7.Data) do
				for v124 in pairs(v_u_1) do
					task.spawn(v_u_6.CheckAutoRefresh, v_u_6, v123, v124)
					task.spawn(v_u_6.CheckDailyPurchaseReset, v_u_6, v123, v124)
				end
			end
		end):Start()
		local function v127(p125) -- name: onNewPlayer
			-- upvalues: (ref) v_u_1, (ref) v_u_6
			for v126 in pairs(v_u_1) do
				v_u_6:CheckAutoRefresh(p125, v126)
				v_u_6:CheckDailyPurchaseReset(p125, v126)
			end
		end
		local function v129(p128) -- name: onPlayerRemoving
			-- upvalues: (ref) v_u_3, (ref) v_u_4, (ref) v_u_5
			v_u_3[p128] = nil
			v_u_4[p128] = nil
			v_u_5[p128] = nil
		end
		v_u_7.OnDataAdded:Connect(v127)
		game.Players.PlayerRemoving:Connect(v129)
		for v130, _ in pairs(v_u_7.Data) do
			task.spawn(v127, v130)
		end
		p122.RemoteEvent.OnServerEvent:Connect(function(p131, p132, ...)
			-- upvalues: (ref) v_u_1, (ref) v_u_6
			if p132 == "BuyShopItem" then
				local v133, v134 = ...
				if not v_u_1[v133] then
					return
				end
				v_u_6:BuyItem(p131, v133, v134)
			end
		end)
	end
end
return v_u_6

-- // Function Dumper made by King.Kevin
-- // Script Path: ReplicatedStorage.Framework.Features.ConsumableShopSystem.ConsumableShopUtil

--[[
Function Dump: BuyItem

Function Upvalues: BuyItem
		1 [table]:
		1 [table] table: 0x0f86e8f5d0ced0ab
				1 [table]:
				Bond [table] table: 0x942003d2ee76ffdb
						1 [string] = BondCoin
						2 [table]:
						Config [table] table: 0x76b7793c188118eb
								1 [number] = 1440
								2 [number] = 5
								3 [number] = 9
						3 [string] = ResShop_Bond
						4 [string] = BondShop
						5 [string] = CurrencyFrame_Bond
						6 [string] = Bond
						7 [string] = BondShopRefresh
				2 [table]:
				Gold [table] table: 0x910a4f36461c45bb
						1 [string] = Currency1
						2 [table]:
						Config [table] table: 0x339f215033e35ccb
								1 [number] = 5
								2 [number] = 15
								3 [number] = 10
						3 [string] = ResShop_Gold
						4 [string] = GoldShop
						5 [string] = CurrencyFrame_Gold
						6 [string] = Coin
						7 [string] = GoldShopRefresh
		2 [table]:
		2 [table] table: 0xd430b914f3f431ab
				1 [table]:
				Bond [table] table: 0xb39dfddc9222d25b
						1 [table]:
						BondShop_2 [table] table: 0x68814d38b64f0a7b
								1 [number] = 700
								2 [number] = 80
								3 [string] = Currency
								4 [number] = 1
								5 [string] = BondShop_2
								6 [number] = 1
								7 [number] = 1
								8 [string] = Gem
						2 [table]:
						BondShop_8 [table] table: 0xdf442f4cfd9fa3db
								1 [number] = 120
								2 [number] = 1
								3 [string] = Potion
								4 [number] = 1
								5 [string] = BondShop_8
								6 [number] = 1
								7 [number] = 1
								8 [string] = HPPotion_1
						3 [table]:
						BondShop_7 [table] table: 0xfd4f495e354a50cb
								1 [number] = 120
								2 [number] = 1
								3 [string] = Potion
								4 [number] = 1
								5 [string] = BondShop_7
								6 [number] = 1
								7 [number] = 1
								8 [string] = AtkPotion_1
						4 [table]:
						BondShop_9 [table] table: 0x39d100fa0e6894eb
								1 [number] = 160
								2 [number] = 1
								3 [string] = Potion
								4 [number] = 1
								5 [string] = BondShop_9
								6 [number] = 1
								7 [number] = 1
								8 [string] = CHPotion_1
						5 [table]:
						BondShop_1 [table] table: 0x2e36276a80102c6b
								1 [number] = 1500
								2 [number] = 1
								3 [string] = RaceSpins
								4 [number] = 1
								5 [string] = BondShop_1
								6 [number] = 1
								7 [number] = 1
								8 [string] = RaceSpins
						6 [table]:
						BondShop_4 [table] table: 0xa5e89755cf65279b
								1 [number] = 80
								2 [number] = 1
								3 [string] = Potion
								4 [number] = 1
								5 [string] = BondShop_4
								6 [number] = 1
								7 [number] = 1
								8 [string] = EXPPotion_1
						7 [table]:
						__index [table] table: 0x76fddf49d607ab0b
								1 [string] = BondShop_1
								2 [string] = BondShop_2
								3 [string] = BondShop_3
								4 [string] = BondShop_4
								5 [string] = BondShop_5
								6 [string] = BondShop_6
								7 [string] = BondShop_7
								8 [string] = BondShop_8
								9 [string] = BondShop_9
								10 [string] = BondShop_10
						8 [table]:
						BondShop_5 [table] table: 0x2067b133dbd454ab
								1 [number] = 600
								2 [number] = 1
								3 [string] = Potion
								4 [number] = 1
								5 [string] = BondShop_5
								6 [number] = 1
								7 [number] = 1
								8 [string] = LuckPotion_1
						9 [table]:
						BondShop_10 [table] table: 0x546a654860f989fb
								1 [number] = 450
								2 [number] = 1
								3 [string] = Potion
								4 [number] = 1
								5 [string] = BondShop_10
								6 [number] = 1
								7 [number] = 1
								8 [string] = BondPotion_1
						10 [table]:
						BondShop_3 [table] table: 0x6b1ce8d67cf2088b
								1 [number] = 80
								2 [number] = 1
								3 [string] = Potion
								4 [number] = 1
								5 [string] = BondShop_3
								6 [number] = 1
								7 [number] = 1
								8 [string] = GoldPotion_1
						11 [table]:
						BondShop_6 [table] table: 0xe2d3dbf0673ac1bb
								1 [number] = 48