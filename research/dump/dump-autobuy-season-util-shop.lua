local v_u_1 = require(game.ReplicatedStorage:WaitForChild("Framework"))
local v_u_2 = game.Players.LocalPlayer
local v_u_3 = script.Parent
v_u_3.Visible = false
local v_u_4 = v_u_3:WaitForChild("Special")
local v_u_5 = {
	v_u_3:WaitForChild("1"),
	v_u_3:WaitForChild("2"),
	v_u_3:WaitForChild("3"),
	v_u_3:WaitForChild("4"),
	v_u_3:WaitForChild("5"),
	v_u_3:WaitForChild("6")
}
local v_u_6 = v_u_3:WaitForChild("Info")
local v_u_7 = v_u_3:WaitForChild("Time"):WaitForChild("TXT")
local v8 = v_u_3:WaitForChild("Time"):WaitForChild("Details")
local v_u_9 = v_u_3.Parent:WaitForChild("StoreStatistics")
local v10 = require(game.ReplicatedStorage:WaitForChild("Utility"):WaitForChild("Timer"))
local v_u_11 = require(game.ReplicatedStorage:WaitForChild("Utility"):WaitForChild("Format"))
local v_u_12 = require(game.ReplicatedStorage:WaitForChild("Configs"):WaitForChild("ResSeasonShop"))
local v_u_13 = require(game.ReplicatedStorage:WaitForChild("Configs"):WaitForChild("ResUnForge"))
local v_u_14 = require(game.ReplicatedStorage:WaitForChild("Enum"):WaitForChild("GameEnum"))
local v_u_15 = v_u_1.Modules.SeasonUtil
local v_u_16 = v_u_1.Modules.TranslationUtil
local v_u_17 = v_u_1.Modules.EquipmentUtil
local v_u_18 = v_u_1.Modules.ForgeUtil
local v_u_19 = v_u_1.Modules.CurrencyUtil
local v_u_20 = v_u_1.Modules.RarityTiers
local v_u_21 = v_u_1.Modules.MaterialUtil
local v_u_22 = v_u_1.Modules.DebuffUtil
local v_u_23 = v_u_1.Modules.PetsUtil
local v_u_24 = v_u_1.Modules.AchievementUtil
local v_u_25 = v_u_1.Modules.PotionUtil
local v_u_26 = v_u_1.Modules.ScrollUtil
local v_u_27 = nil
v_u_27 = v10:new(1, function()
	-- upvalues: (copy) v_u_15, (copy) v_u_2, (copy) v_u_7, (copy) v_u_16, (copy) v_u_11, (ref) v_u_27
	local v28 = v_u_15:GetNowTime()
	local v29 = v_u_15:GetSeasonEndTime()
	local v30 = v_u_15:GetSeasonCloseTime()
	local v31 = v_u_15:GetShopRefreshTime(v_u_2)
	local v32 = v30 < v28
	local _ = v29 < v28
	if v32 then
		v_u_7.Visible = false
		if v_u_27 then
			v_u_27:Stop()
			v_u_27 = nil
		end
	else
		local v33 = v31 - v28
		v_u_7.Text = v_u_16:TranslateByKey("K_SEASON_RENEW_COUNTDOWN") .. " " .. v_u_11:Sec2HHMMSS(v33)
		v_u_7.Visible = true
	end
end)
v_u_27:Start()
v8.MouseButton1Down:Connect(function()
	-- upvalues: (copy) v_u_9
	v_u_9.Visible = not v_u_9.Visible
end)
local v_u_34 = nil
local v_u_35 = {}
local v_u_36 = {}
local v_u_37 = {}
local v_u_38 = nil
local v_u_39 = 0
local function v_u_71(p40, p41) -- name: UpdateInfo
	-- upvalues: (ref) v_u_34, (copy) v_u_35, (copy) v_u_6, (copy) v_u_19, (ref) v_u_38, (copy) v_u_12, (ref) v_u_39, (copy) v_u_14, (copy) v_u_17, (copy) v_u_13, (copy) v_u_16, (copy) v_u_21, (copy) v_u_22, (copy) v_u_18, (copy) v_u_23, (copy) v_u_24, (copy) v_u_25, (copy) v_u_26, (copy) v_u_20, (copy) v_u_15, (copy) v_u_2
	if p40 ~= v_u_34 or p41 then
		v_u_34 = p40
		if v_u_35 then
			for _, v42 in pairs(v_u_35) do
				v42:Disconnect()
			end
		end
		table.clear(v_u_35)
		local v_u_43 = v_u_6:WaitForChild("ItemImg")
		local v_u_44 = v_u_6:WaitForChild("VPF")
		local v_u_45 = v_u_6:WaitForChild("BuyBtn")
		local v_u_46 = v_u_45:WaitForChild("Price"):WaitForChild("Count")
		local v_u_47 = v_u_6:WaitForChild("Purchased")
		local v_u_48 = v_u_6:WaitForChild("Rarity")
		local v_u_49 = v_u_6:WaitForChild("Stock")
		local v_u_50 = v_u_6:WaitForChild("Title")
		local v_u_51 = v_u_6:WaitForChild("Desc"):WaitForChild("Desc")
		v_u_45:WaitForChild("Price"):WaitForChild("Icon").Image = v_u_19.CurrencyIcons.SeasonCurrency
		local function v_u_68() -- name: Update
			-- upvalues: (ref) v_u_38, (ref) v_u_34, (ref) v_u_12, (copy) v_u_44, (copy) v_u_43, (copy) v_u_46, (ref) v_u_39, (copy) v_u_51, (ref) v_u_14, (ref) v_u_17, (ref) v_u_13, (copy) v_u_50, (ref) v_u_16, (ref) v_u_21, (ref) v_u_22, (ref) v_u_18, (ref) v_u_19, (ref) v_u_23, (ref) v_u_24, (ref) v_u_25, (ref) v_u_26, (ref) v_u_20, (copy) v_u_48, (ref) v_u_35, (copy) v_u_45, (ref) v_u_15, (ref) v_u_2, (copy) v_u_49, (copy) v_u_47
			if v_u_38 then
				local v_u_52 = v_u_34:GetAttribute("ShopId")
				if v_u_52 then
					local v53 = v_u_12[v_u_52]
					if v53 then
						v_u_44.Visible = false
						v_u_43.Visible = false
						v_u_46.Text = string.format("%d", v53.Price)
						v_u_46.TextColor3 = v_u_39 >= v53.Price and Color3.new(1, 1, 1) or Color3.new(0.87451, 0.00784314, 0.00784314)
						local v54 = 1
						v_u_51.Text = ""
						if v53.ItemType == v_u_14.ThingType.DataEquipment then
							v_u_43.Visible = true
							local v55 = string.split(v53.ItemId, ":")
							v_u_43.Image = v_u_17:GetDef(v55[1]).Icon
							v54 = v_u_17:GetOreRarity(v_u_13[v55[2]].Ore)
							v_u_50.Text = v_u_16:TranslateByKey("K_" .. string.upper(v55[1]))
							v_u_51.Text = v_u_16:TranslateByKey("K_" .. string.upper(v55[1]) .. "_DESC")
						elseif v53.ItemType == v_u_14.ThingType.EnchantedStone then
							v_u_43.Visible = true
							local v56 = v_u_21:GetDef(v53.ItemId)
							v_u_43.Image = v_u_22:GetDebuffIcon(v56.DebuffType)
							v54 = v56.Rarity
							v_u_50.Text = v_u_16:TranslateByKey("K_" .. string.upper(v53.ItemId))
						elseif v53.ItemType == v_u_14.ThingType.Crystals then
							v_u_43.Visible = true
							local v57 = v_u_21:GetDef(v53.ItemId)
							v_u_43.Image = v57.Icon
							v54 = v57.Rarity
							v_u_50.Text = v_u_16:TranslateByKey("K_" .. string.upper(v53.ItemId))
							v_u_51.Text = v_u_16:TranslateByKey("K_" .. string.upper(v53.ItemId) .. "_DESC")
						elseif v53.ItemType == v_u_14.ThingType.Ore then
							v_u_44.Visible = true
							local v58 = v_u_18:GetDef(v53.ItemId)
							v_u_18:SetOreViewport(v_u_44, v53.ItemId)
							v54 = v58.Rarity
							v_u_50.Text = v_u_16:TranslateByKey("K_" .. string.upper(v53.ItemId))
							v_u_51.Text = v_u_16:TranslateByKey("K_" .. string.upper(v53.ItemId) .. "_DESC")
						elseif v53.ItemType == v_u_14.ThingType.Currency then
							v_u_43.Visible = true
							v_u_43.Image = v_u_19.CurrencyIcons[v53.ItemId]
							v54 = v_u_19.CurrencyRarity[v53.ItemId]
							v_u_50.Text = v_u_16:TranslateByKey(v_u_19.CurrencyDisplayNames[v53.ItemId])
						elseif v53.ItemType == v_u_14.ThingType.RaceSpins then
							v_u_43.Visible = true
							v_u_43.Image = "rbxassetid://111055180609520"
							v_u_50.Text = v_u_16:TranslateByKey("K_NAME_RACESPINS_1")
							v54 = 5
						elseif v53.ItemType == v_u_14.ThingType.Pet then
							v_u_43.Visible = true
							local v59 = v_u_23:GetPetInfo(v53.ItemId)
							v_u_43.Image = v_u_23:GetPetIcon(v53.ItemId, 1)
							v54 = v59.Rarity
							v_u_50.Text = v_u_16:TranslateByKey(v59.Name)
							v_u_51.Text = v_u_16:TranslateByKey(v59.Desc)
						elseif v53.ItemType == v_u_14.ThingType.Achievement then
							v_u_43.Visible = true
							local v60 = v_u_24:GetAchievementInfo(v53.ItemId)
							v_u_43.Image = v60.Icon
							v54 = v60.Rarity
							v_u_50.Text = v_u_16:TranslateByKey(v60.TitleDesc)
							v_u_51.Text = v_u_16:TranslateByKey(v60.DetailDesc)
						elseif v53.ItemType == v_u_14.ThingType.Potion then
							v_u_43.Visible = true
							local v61 = v_u_25:GetPotionInfo(v53.ItemId)
							v_u_43.Image = v61.Icon
							v54 = v61.Rarity
							v_u_50.Text = v_u_16:TranslateByKey(v61.Name)
							v_u_51.Text = v_u_16:TranslateByKey(v61.Desc)
						elseif v53.ItemType == v_u_14.ThingType.Scroll then
							v_u_43.Visible = true
							local v62 = v_u_26:GetDef(v53.ItemId)
							if v62 then
								v_u_43.Image = v62.Icon or ""
								v54 = v62.Rarity or 1
								v_u_50.Text = v_u_16:TranslateByKey(v62.Name)
								v_u_51.Text = v_u_16:TranslateByKey(v62.Desc)
							end
						elseif v53.ItemType == v_u_14.ThingType.DataScroll then
							v_u_43.Visible = true
							local v63 = v_u_26:GetDef(string.split(v53.ItemId, ":")[1])
							if v63 then
								v_u_43.Image = v63.Icon or ""
								v54 = v63.Rarity or 1
								v_u_50.Text = v_u_16:TranslateByKey(v63.Name)
								v_u_51.Text = v_u_16:TranslateByKey(v63.Desc)
							end
						end
						v_u_20:SetTextLabelToTier(v_u_48, v54)
						local v64 = v_u_35
						local v65 = v_u_45.MouseButton1Down
						local function v66()
							-- upvalues: (ref) v_u_15, (ref) v_u_2, (copy) v_u_52
							v_u_15:BuySeasonShopItem(v_u_2, v_u_52)
						end
						table.insert(v64, v65:Connect(v66))
						v_u_49.Visible = v53.IsSpecial
						if v_u_49.Visible then
							v_u_49.Text = v_u_16:TranslateByKey("K_SEASON_SHOP_STOCK") .. " " .. string.format("%d", v53.LimitTimes - (v_u_38.BuyCount[v_u_52] or 0))
						end
						local v67 = v_u_38.BuyCount[v_u_52]
						if v67 then
							v67 = v_u_38.BuyCount[v_u_52] >= (v53.IsSpecial and v53.LimitTimes or 1)
						end
						v_u_45.Visible = not v67
						v_u_47.Visible = v67
					end
				else
					return
				end
			else
				return
			end
		end
		local v69 = v_u_35
		local v70 = p40:GetAttributeChangedSignal("ShopId")
		table.insert(v69, v70:Connect(function()
			-- upvalues: (copy) v_u_68
			v_u_68()
		end))
		v_u_68()
	end
end
local function v_u_90() -- name: UpdateSpecial
	-- upvalues: (copy) v_u_36, (ref) v_u_38, (copy) v_u_12, (copy) v_u_4, (copy) v_u_19, (ref) v_u_39, (copy) v_u_14, (copy) v_u_17, (copy) v_u_21, (copy) v_u_22, (copy) v_u_18, (copy) v_u_23, (copy) v_u_24, (copy) v_u_25, (copy) v_u_26, (copy) v_u_71, (copy) v_u_15, (copy) v_u_2
	if v_u_36 then
		for _, v72 in pairs(v_u_36) do
			v72:Disconnect()
		end
	end
	table.clear(v_u_36)
	if v_u_38 then
		local v_u_73 = v_u_38.SpecialId
		if v_u_73 then
			local v74 = v_u_12[v_u_73]
			if v74 then
				v_u_4:SetAttribute("ShopId", v_u_73)
				local v75 = v_u_4:WaitForChild("ItemImg")
				local v76 = v_u_4:WaitForChild("VPF")
				local v77 = v_u_4:WaitForChild("Count")
				local v78 = v_u_4:WaitForChild("BuyBtn")
				local v79 = v78:WaitForChild("Price"):WaitForChild("Count")
				local v80 = v_u_4:WaitForChild("Purchased")
				v78:WaitForChild("Price"):WaitForChild("Icon").Image = v_u_19.CurrencyIcons.SeasonCurrency
				v76.Visible = false
				v75.Visible = false
				v77.Text = "x" .. v74.ItemCount
				v79.Text = string.format("%d", v74.Price)
				v79.TextColor3 = v_u_39 >= v74.Price and Color3.new(1, 1, 1) or Color3.new(0.87451, 0.00784314, 0.00784314)
				if v74.ItemType == v_u_14.ThingType.DataEquipment then
					v75.Visible = true
					v75.Image = v_u_17:GetDef(string.split(v74.ItemId, ":")[1]).Icon
				elseif v74.ItemType == v_u_14.ThingType.EnchantedStone then
					v75.Visible = true
					v75.Image = v_u_22:GetDebuffIcon(v_u_21:GetDef(v74.ItemId).DebuffType)
				elseif v74.ItemType == v_u_14.ThingType.Crystals then
					v75.Visible = true
					v75.Image = v_u_21:GetDef(v74.ItemId).Icon
				elseif v74.ItemType == v_u_14.ThingType.Ore then
					v76.Visible = true
					v_u_18:GetDef(v74.ItemId)
					v_u_18:SetOreViewport(v76, v74.ItemId)
				elseif v74.ItemType == v_u_14.ThingType.Currency then
					v75.Visible = true
					v75.Image = v_u_19.CurrencyIcons[v74.ItemId]
				elseif v74.ItemType == v_u_14.ThingType.RaceSpins then
					v75.Visible = true
					v75.Image = "rbxassetid://111055180609520"
				elseif v74.ItemType == v_u_14.ThingType.Pet then
					v75.Visible = true
					v_u_23:GetPetInfo(v74.ItemId)
					v75.Image = v_u_23:GetPetIcon(v74.ItemId, 1)
				elseif v74.ItemType == v_u_14.ThingType.Achievement then
					v75.Visible = true
					v75.Image = v_u_24:GetAchievementInfo(v74.ItemId).Icon
				elseif v74.ItemType == v_u_14.ThingType.Potion then
					v75.Visible = true
					v75.Image = v_u_25:GetPotionInfo(v74.ItemId).Icon
				elseif v74.ItemType == v_u_14.ThingType.Scroll then
					v75.Visible = true
					local v81 = v_u_26:GetDef(v74.ItemId)
					if v81 then
						v75.Image = v81.Icon or ""
					end
				elseif v74.ItemType == v_u_14.ThingType.DataScroll then
					v75.Visible = true
					local v82 = v_u_26:GetDef(string.split(v74.ItemId, ":")[1])
					if v82 then
						v75.Image = v82.Icon or ""
					end
				end
				local v83 = v_u_36
				local v84 = v_u_4.MouseButton1Down
				local function v85()
					-- upvalues: (ref) v_u_71, (ref) v_u_4
					v_u_71(v_u_4)
				end
				table.insert(v83, v84:Connect(v85))
				local v86 = v_u_36
				local v87 = v78.MouseButton1Down
				local function v88()
					-- upvalues: (ref) v_u_71, (ref) v_u_4, (ref) v_u_15, (ref) v_u_2, (copy) v_u_73
					v_u_71(v_u_4)
					v_u_15:BuySeasonShopItem(v_u_2, v_u_73)
				end
				table.insert(v86, v87:Connect(v88))
				local v89 = v_u_38.BuyCount[v_u_73]
				if v89 then
					v89 = v_u_38.BuyCount[v_u_73] >= v74.LimitTimes
				end
				v78.Visible = not v89
				v80.Visible = v89
			end
		else
			return
		end
	else
		return
	end
end
local function v_u_120() -- name: UpdateNormals
	-- upvalues: (copy) v_u_37, (ref) v_u_38, (copy) v_u_5, (copy) v_u_12, (copy) v_u_19, (ref) v_u_39, (copy) v_u_14, (copy) v_u_17, (copy) v_u_13, (copy) v_u_21, (copy) v_u_22, (copy) v_u_18, (copy) v_u_23, (copy) v_u_24, (copy) v_u_25, (copy) v_u_26, (copy) v_u_20, (copy) v_u_71, (copy) v_u_15, (copy) v_u_2
	if v_u_37 then
		for _, v91 in pairs(v_u_37) do
			v91:Disconnect()
		end
	end
	table.clear(v_u_37)
	if v_u_38 then
		local v92 = v_u_38.NormalIds
		if v92 then
			for _, v_u_93 in pairs(v_u_5) do
				local v_u_94 = v92[v_u_93.Name]
				if v_u_94 then
					local v95 = v_u_12[v_u_94]
					if v95 then
						v_u_93:SetAttribute("ShopId", v_u_94)
						local v96 = v_u_93:WaitForChild("ItemImg")
						local v97 = v_u_93:WaitForChild("VPF")
						local v98 = v_u_93:WaitForChild("Count")
						local v99 = v_u_93:WaitForChild("BuyBtn")
						local v100 = v99:WaitForChild("Price"):WaitForChild("Count")
						local v101 = v_u_93:WaitForChild("Purchased")
						local v102 = v_u_93:WaitForChild("Bg")
						v99:WaitForChild("Price"):WaitForChild("Icon").Image = v_u_19.CurrencyIcons.SeasonCurrency
						v97.Visible = false
						v96.Visible = false
						v98.Text = "x" .. v95.ItemCount
						v100.Text = string.format("%d", v95.Price)
						v100.TextColor3 = v_u_39 >= v95.Price and Color3.new(1, 1, 1) or Color3.new(0.87451, 0.00784314, 0.00784314)
						local v103 = 1
						if v95.ItemType == v_u_14.ThingType.DataEquipment then
							v96.Visible = true
							local v104 = string.split(v95.ItemId, ":")
							v96.Image = v_u_17:GetDef(v104[1]).Icon
							v103 = v_u_17:GetOreRarity(v_u_13[v104[2]].Ore)
						elseif v95.ItemType == v_u_14.ThingType.EnchantedStone then
							v96.Visible = true
							local v105 = v_u_21:GetDef(v95.ItemId)
							v96.Image = v_u_22:GetDebuffIcon(v105.DebuffType)
							v103 = v105.Rarity
						elseif v95.ItemType == v_u_14.ThingType.Crystals then
							v96.Visible = true
							local v106 = v_u_21:GetDef(v95.ItemId)
							v96.Image = v106.Icon
							v103 = v106.Rarity
						elseif v95.ItemType == v_u_14.ThingType.Ore then
							v97.Visible = true
							local v107 = v_u_18:GetDef(v95.ItemId)
							v_u_18:SetOreViewport(v97, v95.ItemId)
							v103 = v107.Rarity
						elseif v95.ItemType == v_u_14.ThingType.Currency then
							v96.Visible = true
							v96.Image = v_u_19.CurrencyIcons[v95.ItemId]
							v103 = v_u_19.CurrencyRarity[v95.ItemId]
						elseif v95.ItemType == v_u_14.ThingType.RaceSpins then
							v96.Visible = true
							v96.Image = "rbxassetid://111055180609520"
							v103 = 5
						elseif v95.ItemType == v_u_14.ThingType.Pet then
							v96.Visible = true
							local v108 = v_u_23:GetPetInfo(v95.ItemId)
							v96.Image = v_u_23:GetPetIcon(v95.ItemId, 1)
							v103 = v108.Rarity
						elseif v95.ItemType == v_u_14.ThingType.Achievement then
							v96.Visible = true
							local v109 = v_u_24:GetAchievementInfo(v95.ItemId)
							v96.Image = v109.Icon
							v103 = v109.Rarity
						elseif v95.ItemType == v_u_14.ThingType.Potion then
							v96.Visible = true
							local v110 = v_u_25:GetPotionInfo(v95.ItemId)
							v96.Image = v110.Icon
							v103 = v110.Rarity
						elseif v95.ItemType == v_u_14.ThingType.Scroll then
							v96.Visible = true
							local v111 = v_u_26:GetDef(v95.ItemId)
							if v111 then
								v96.Image = v111.Icon or ""
								v103 = v111.Rarity or 1
							end
						elseif v95.ItemType == v_u_14.ThingType.DataScroll then
							v96.Visible = true
							local v112 = v_u_26:GetDef(string.split(v95.ItemId, ":")[1])
							if v112 then
								v96.Image = v112.Icon or ""
								v103 = v112.Rarity or 1
							end
						end
						v_u_20:ApplyColorByName(v102, v103, v_u_20.GradientFolderName.TierGradients)
						local v113 = v_u_37
						local v114 = v_u_93.MouseButton1Down
                        local function v115()
                            -- upvalues: (ref) v_u_71, (ref) v_u_93
                            v_u_71(v_u_93)
                        end
                        table.insert(v113, v114:Connect(v115))
                        local v116 = v_u_37
                        local v117 = v99.MouseButton1Down
                        local function v118()
                            -- upvalues: (ref) v_u_71, (ref) v_u_93, (ref) v_u_15, (ref) v_u_2, (copy) v_u_94
                            v_u_71(v_u_93)
                            v_u_15:BuySeasonShopItem(v_u_2, v_u_94)
                        end
                        table.insert(v116, v117:Connect(v118))
                        local v119 = v_u_38.BuyCount[v_u_94]
                        if v119 then
                            v119 = v_u_38.BuyCount[v_u_94] >= (v95.IsSpecial and v95.LimitTimes or 1)
                        end
                        v99.Visible = not v119
                        v101.Visible = v119
                    end
                end
            end
        end
    else
        return
    end
end

