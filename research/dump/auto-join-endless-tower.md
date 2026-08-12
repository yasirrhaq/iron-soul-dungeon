# Calling Code=
local Event = game:GetService("ReplicatedStorage").Remotes.GameMatchRE
Event:FireServer(
    "CreatRoom",
    "Endless1",
    1,
    2,
    141
)

# Decompiled Script

local v_u_1 = require(game.ReplicatedStorage:WaitForChild("Framework"))
local v_u_2 = require(game.ReplicatedStorage:WaitForChild("Utility"):WaitForChild("CountDownUtility"))
local v_u_3 = require(game.ReplicatedStorage:WaitForChild("Enum"):WaitForChild("GameEnum"))
local v_u_4 = require(game.ReplicatedStorage:WaitForChild("Enum"):WaitForChild("KeyString"))
local v_u_5 = require(game.ReplicatedStorage:WaitForChild("Configs"):WaitForChild("GameConfigs"))
local v_u_6 = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GameMatchRE")
local v_u_7 = game.Players.LocalPlayer
local v_u_8 = script.Parent
local v9 = v_u_8:WaitForChild("Control")
local v_u_10 = v9:WaitForChild("CreatBtn")
local v11 = v9:WaitForChild("Match")
local v_u_12 = v11:WaitForChild("AddButton")
local v_u_13 = v11:WaitForChild("MinusButton")
local v_u_14 = v11:WaitForChild("MatchCount")
local v_u_15 = v9:WaitForChild("FriendOnly")
local v_u_16 = v_u_15:WaitForChild("Check")
local v_u_17 = v9:WaitForChild("Time"):WaitForChild("Bar"):WaitForChild("Tag")
local v18 = v_u_8:WaitForChild("WorldFrame")
local v_u_19 = v18:WaitForChild("DiffTabs")
local v_u_20 = v_u_19:WaitForChild("Round")
local v_u_21 = v_u_19:WaitForChild("UIListLayout")
local v_u_22 = v18:WaitForChild("Details")
local v_u_23 = v_u_22:WaitForChild("Title"):WaitForChild("Text")
local v_u_24 = v_u_22:WaitForChild("Icon")
local v_u_25 = v_u_22:WaitForChild("Reward")
local v_u_26 = v_u_25:WaitForChild("Item")
v_u_26.Visible = false
local v_u_27 = v_u_22:WaitForChild("BestTime")
local v_u_28 = v_u_22:WaitForChild("HellMode")
local v_u_29 = v_u_22:WaitForChild("Power")
local v_u_30 = v_u_22:WaitForChild("TotalCleared")
local v_u_31 = v_u_8:WaitForChild("SeasonInfo")
local v_u_32 = v_u_22:WaitForChild("SeasonInfoButton")
local v_u_33 = v_u_22:WaitForChild("SeasonDungeonSpeedUp")
local v_u_34 = v_u_8:WaitForChild("Close")
local v_u_35 = v_u_1.Modules.WorldUtil
local v_u_36 = v_u_1.Modules.SeasonUtil
local v_u_37 = v_u_1.Modules.TranslationUtil
local v_u_38 = v_u_1.Modules.DebuffUtil
local v_u_39 = v_u_1.Modules.ForgeUtil
local v_u_40 = v_u_1.Modules.RarityTiers
local v_u_41 = v_u_1.Modules.MaterialUtil
local v_u_42 = v_u_1.Modules.EquipmentUtil
local v_u_43 = v_u_1.Modules.PetsHatchUtil
local v_u_44 = v_u_1.Modules.ScrollUtil
local v_u_45 = v_u_5.GameMatchConfig.DefaultMatchCount
local v_u_46 = v_u_5.GameMatchConfig.MaxMatchCount
local v_u_47 = nil
local v_u_48 = v_u_45
local v_u_49 = nil
local v_u_50 = true
local v_u_51 = {}
local v_u_52 = {}
local function v_u_58() -- name: DisplayRoomCD
	-- upvalues: (ref) v_u_47, (copy) v_u_5, (copy) v_u_2, (copy) v_u_17
	if v_u_47 then
		v_u_47:Stop()
		v_u_47 = nil
	end
	local v_u_53 = v_u_5.GameMatchConfig.WaitCreatTime
	v_u_47 = v_u_2:new(v_u_53, 0.02, function(p54)
		-- upvalues: (ref) v_u_17, (copy) v_u_53
		local v55 = v_u_17
		local v56 = UDim2.fromScale
		local v57 = p54 / v_u_53
		v55.Size = v56(math.clamp(v57, 0, 1), 1)
	end, function()
		-- upvalues: (ref) v_u_17
		v_u_17.Size = UDim2.fromScale(0, 1)
	end)
	v_u_47:Start()
end
local function v_u_85() -- name: UpdateWorldReward
	-- upvalues: (copy) v_u_35, (copy) v_u_52, (copy) v_u_26, (copy) v_u_25, (copy) v_u_39, (copy) v_u_37, (copy) v_u_40, (copy) v_u_41, (copy) v_u_38, (copy) v_u_3, (copy) v_u_42, (copy) v_u_43, (copy) v_u_44, (copy) v_u_7
	local v59 = v_u_35:GetWorldDisplayRewards("Endless1", 1) or {}
	for _, v60 in v_u_52 do
		v60.Visible = false
	end
	for v61, v62 in ipairs(v59) do
		local v63 = v62.ItemId
		local v64 = v62.IsFirst
		local v65
		if v64 then
			v65 = "First" .. v63
		else
			v65 = v63
		end
		local v66 = v_u_52[v65]
		if not v66 then
			v66 = v_u_26:Clone()
			v66.Name = v65
			v66.Parent = v_u_25
			local v67 = v66:WaitForChild("BTN")
			local v68 = v67:WaitForChild("BG")
			local v69 = v67:WaitForChild("Name")
			v67:WaitForChild("FirstClear").Visible = v64
			local v70 = v67:WaitForChild("Mark")
			v70.Image = ""
			local v71 = v67:WaitForChild("IsHell")
			if v62.ItemType == "Ore" then
				local v72 = v67:WaitForChild("VPF")
				v72.Visible = true
				local v73 = v_u_39:GetDef(v63)
				v69.Text = v_u_37:TranslateByKey("K_" .. string.upper(v63))
				v_u_39:SetOreViewport(v72, v63)
				v_u_40:ApplyColor(v68, v73.Rarity)
				v71.Visible = v73.Hellweight > 0
			elseif v62.ItemType == "EnchantedStone" then
				local v74 = v67:WaitForChild("Image")
				v74.Visible = true
				local v75 = v_u_41:GetDef(v63)
				v74.Image = v_u_38:GetDebuffIcon(v75.DebuffType)
				v69.Text = v_u_37:TranslateByKey("K_" .. string.upper(v63))
				v_u_40:ApplyColor(v68, v75.Rarity)
			elseif v62.ItemType == "Crystals" then
				local v76 = v67:WaitForChild("Image")
				v76.Visible = true
				local v77 = v_u_41:GetDef(v63)
				v76.Image = v77.Icon
				v69.Text = v_u_37:TranslateByKey("K_" .. string.upper(v63))
				v_u_40:ApplyColor(v68, v77.Rarity)
			elseif v62.ItemType == v_u_3.ThingType.Blueprint then
				local v78 = v67:WaitForChild("Image")
				v78.Visible = true
				v78.Image = v_u_42:GetDef(v63).Icon
				v70.Image = "rbxassetid://129469119728475"
				v69.Text = v_u_37:TranslateByKey("K_BLUEPRINT")
				v_u_40:ApplyColor(v68, 5)
			elseif v62.ItemType == v_u_3.ThingType.Egg then
				local v79 = v67:WaitForChild("Image")
				v79.Visible = true
				local v80 = v_u_43:GetEggCfg(v63)
				v79.Image = v80.Icon
				v69.Text = v_u_37:TranslateByKey(v80.Name)
				v_u_40:ApplyColor(v68, v80.Rarity)
			elseif v62.ItemType == v_u_3.ThingType.Scroll then
				local v81 = v67:WaitForChild("Image")
				v81.Visible = true
				local v82 = v_u_44:GetDef(v63)
				if v82 then
					v81.Image = v82.Icon or ""
					v69.Text = v_u_37:TranslateByKey(v82.Name)
					v_u_40:ApplyColor(v68, v82.Rarity or 1)
				end
			elseif v62.ItemType == v_u_3.ThingType.DataScroll then
				local v83 = v67:WaitForChild("Image")
				v83.Visible = true
				local v84 = v_u_44:GetDef(string.split(v63, ":")[1])
				if v84 then
					v83.Image = v84.Icon or ""
					v69.Text = v_u_37:TranslateByKey(v84.Name)
					v_u_40:ApplyColor(v68, v84.Rarity or 1)
				end
			end
			v_u_52[v65] = v66
		end
		v66.LayoutOrder = v61
		if v64 then
			v66.Visible = v_u_35:IsWolrdFirstClear(v_u_7, "Endless1", 1)
		else
			v66.Visible = true
		end
	end
end
local function v_u_90() -- name: UpdateWorldDetails
	-- upvalues: (copy) v_u_22, (copy) v_u_28, (copy) v_u_29, (copy) v_u_30, (copy) v_u_35, (copy) v_u_23, (copy) v_u_37, (copy) v_u_24, (copy) v_u_7, (copy) v_u_36, (copy) v_u_27, (copy) v_u_85
	v_u_22.Visible = true
	v_u_28.Visible = false
	v_u_29.Visible = false
	v_u_30.Visible = false
	local v86 = v_u_35:GetWorldName("Endless1")
	if v86 then
		v_u_23.Text = v_u_37:TranslateByKey(v86)
	end
	local v87 = v_u_35:GetWorldDiffInfo("Endless1", 1)
	if v87 then
		v_u_24.Image = v87.Icon or ""
	end
	local v88 = v_u_35:GetWorldRecords(v_u_7, "Endless1", 1, "MaxRound", v_u_36:GetCurrentSeason())
	local v89 = v_u_37:TranslateByKey("K_BEST_ROUND")
	if type(v88) == "number" and v88 > 0 then
		v_u_27.Text = string.format("%s %d", v89, (math.floor(v88)))
	else
		v_u_27.Text = v89 .. " --"
	end
	v_u_85()
end
local function v_u_94(p91) -- name: UpdateRoundLocks
	-- upvalues: (copy) v_u_51
	for v92, v93 in pairs(v_u_51) do
		v93.Unlocked = v92 <= p91 + 1
		v93.Lock.Visible = not v93.Unlocked
		v93.Normal.Visible = true
	end
end
local function v_u_116() -- name: RefreshRoundTabs
	-- upvalues: (copy) v_u_35, (copy) v_u_7, (copy) v_u_36, (copy) v_u_94, (ref) v_u_49, (copy) v_u_51, (copy) v_u_19, (copy) v_u_21, (copy) v_u_90
	local v95 = v_u_35:GetWorldRecords(v_u_7, "Endless1", 1, "MaxRound", v_u_36:GetCurrentSeason())
	local v96
	if type(v95) == "number" then
		local v97 = math.floor(v95)
		v96 = math.clamp(v97, 1, 200)
	else
		v96 = 1
	end
	v_u_94(v96)
	local v98 = v96 / 5
	local v99 = math.floor(v98) * 5 + 1
	local v100 = math.clamp(v99, 1, 196)
	if v_u_49 and (v_u_51[v_u_49] and v_u_51[v_u_49].Unlocked) then
		local v_u_101 = v_u_51[v_u_49].Item
		task.defer(function()
			-- upvalues: (ref) v_u_19, (copy) v_u_101, (ref) v_u_21
			task.wait()
			local v102 = v_u_19.AbsolutePosition.X + v_u_19.AbsoluteSize.X * 0.5
			local v103 = v_u_101.AbsolutePosition.X + v_u_101.AbsoluteSize.X * 0.5
			local v104 = v_u_19.CanvasPosition.X + v103 - v102
			local v105 = v_u_21.AbsoluteContentSize.X - v_u_19.AbsoluteSize.X
			local v106 = math.max(0, v105)
			v_u_19.CanvasPosition = Vector2.new(math.clamp(v104, 0, v106), 0)
		end)
	else
		local v107 = v_u_51[v100]
		if v107 and v107.Unlocked then
			v_u_49 = v100
			for v108, v109 in pairs(v_u_51) do
				v109.Select.Visible = v108 == v100
			end
			local v_u_110 = v107.Item
			task.defer(function()
				-- upvalues: (ref) v_u_19, (copy) v_u_110, (ref) v_u_21
				task.wait()
				local v111 = v_u_19.AbsolutePosition.X + v_u_19.AbsoluteSize.X * 0.5
				local v112 = v_u_110.AbsolutePosition.X + v_u_110.AbsoluteSize.X * 0.5
				local v113 = v_u_19.CanvasPosition.X + v112 - v111
				local v114 = v_u_21.AbsoluteContentSize.X - v_u_19.AbsoluteSize.X
				local v115 = math.max(0, v114)
				v_u_19.CanvasPosition = Vector2.new(math.clamp(v113, 0, v115), 0)
			end)
		end
	end
	v_u_90()
end
local function v_u_134() -- name: InitRoundTabs
	-- upvalues: (copy) v_u_20, (copy) v_u_51, (copy) v_u_19, (copy) v_u_1, (ref) v_u_49, (copy) v_u_21
	v_u_20.Visible = false
	for v117 = 0, 39 do
		local v_u_118 = v117 * 5 + 1
		local v119 = v_u_20:Clone()
		v119.Name = "Round_" .. v_u_118
		v119.LayoutOrder = v117 + 1
		v119.Visible = true
		local v120 = v119:WaitForChild("Normal"):WaitForChild("TXT")
		local v121 = string.format
		local v122 = v_u_118 + 5 - 1
		v120.Text = v121("%d-%d", v_u_118, (math.min(v122, 200)))
		local v_u_123 = {
			["Item"] = nil,
			["Normal"] = nil,
			["Lock"] = nil,
			["Select"] = nil,
			["Unlocked"] = false,
			["Item"] = v119,
			["Normal"] = v119:WaitForChild("Normal"),
			["Lock"] = v119:WaitForChild("Lock"),
			["Select"] = v119:WaitForChild("Select")
		}
		v_u_51[v_u_118] = v_u_123
		v119.Parent = v_u_19
		v119.MouseButton1Down:Connect(function()
			-- upvalues: (copy) v_u_123, (ref) v_u_1, (copy) v_u_118, (ref) v_u_51, (ref) v_u_49, (ref) v_u_19, (ref) v_u_21
			if v_u_123.Unlocked then
				local v124 = v_u_118
				local v125 = v_u_51[v124]
				if v125 then
					if not v125.Unlocked then
						return
					end
					v_u_49 = v124
					for v126, v127 in pairs(v_u_51) do
						v127.Select.Visible = v126 == v124
					end
					local v_u_128 = v125.Item
					task.defer(function()
						-- upvalues: (ref) v_u_19, (copy) v_u_128, (ref) v_u_21
						task.wait()
						local v129 = v_u_19.AbsolutePosition.X + v_u_19.AbsoluteSize.X * 0.5
						local v130 = v_u_128.AbsolutePosition.X + v_u_128.AbsoluteSize.X * 0.5
						local v131 = v_u_19.CanvasPosition.X + v130 - v129
						local v132 = v_u_21.AbsoluteContentSize.X - v_u_19.AbsoluteSize.X
						local v133 = math.max(0, v132)
						v_u_19.CanvasPosition = Vector2.new(math.clamp(v131, 0, v133), 0)
					end)
				end
			else
				v_u_1.Modules.WarningUtil:Warn("K_WORLD_DIFF_LOCK")
			end
		end)
	end
end
local function v_u_135() -- name: OnMatchFriendOnly
	-- upvalues: (copy) v_u_16, (copy) v_u_7
	v_u_16.Visible = v_u_7:GetAttribute("MatchFriendOnly") == true
end
(function() -- name: Init
	-- upvalues: (copy) v_u_134, (copy) v_u_14, (ref) v_u_48, (copy) v_u_31, (copy) v_u_32, (copy) v_u_33, (copy) v_u_1, (copy) v_u_34, (ref) v_u_50, (copy) v_u_6, (copy) v_u_10, (ref) v_u_49, (copy) v_u_35, (copy) v_u_4, (copy) v_u_7, (copy) v_u_12, (copy) v_u_46, (copy) v_u_13, (copy) v_u_15, (copy) v_u_135, (copy) v_u_16, (copy) v_u_8, (copy) v_u_45, (copy) v_u_58, (copy) v_u_116, (ref) v_u_47
	v_u_134()
	local v136 = v_u_48
	v_u_14.Text = tostring(v136)
	v_u_31.Visible = false
	v_u_32.Visible = true
	v_u_33.Visible = false
	v_u_32.MouseButton1Down:Connect(function()
		-- upvalues: (ref) v_u_1
		v_u_1.Modules.WindowUtil:Open("ScreenTips", {
			["IgnoreCancel"] = true,
			["TitleKey"] = "K_ENDLESS_PLAY_TIPS_TITLE",
			["DescKey"] = "K_ENDLESS_PLAY_TIPS"
		}, true)
	end)
	v_u_34.MouseButton1Down:Connect(function()
		-- upvalues: (ref) v_u_50, (ref) v_u_6, (ref) v_u_1
		if v_u_50 then
			v_u_6:FireServer("LeaveRoom")
			v_u_50 = false
		end
		v_u_1.Modules.WindowUtil:Close("ScreenMatch_Endless")
	end)
	v_u_10.MouseButton1Down:Connect(function()
		-- upvalues: (ref) v_u_49, (ref) v_u_35, (ref) v_u_4, (ref) v_u_1, (ref) v_u_7, (ref) v_u_6, (ref) v_u_48, (ref) v_u_50
		if v_u_49 then
			local v137 = v_u_35:GetWorldDiffInfo("Endless1", 1)
			local v138 = true
			if v137.LootType == v_u_4.WorldLootType.Ore then
				v138 = v_u_1.Modules.ForgeUtil:CheckCanAdd(v_u_7, 1)
			elseif v137.LootType == v_u_4.WorldLootType.Material then
				v138 = v_u_1.Modules.MaterialUtil:CheckCanAdd(v_u_7, 1)
			end
			if v138 then
				v_u_6:FireServer("CreatRoom", "Endless1", 1, v_u_48, v_u_49)
				v_u_50 = false
				v_u_1.Modules.WindowUtil:Close("ScreenMatch_Endless")
			else
				v_u_1.Modules.WarningUtil:Warn("K_BAG_FULL")
			end
		else
			return
		end
	end)
	v_u_12.MouseButton1Down:Connect(function()
		-- upvalues: (ref) v_u_48, (ref) v_u_46, (ref) v_u_14
		local v139 = v_u_48 + 1
		local v140 = v_u_46
		v_u_48 = math.min(v139, v140)
		local v141 = v_u_48
		v_u_14.Text = tostring(v141)
	end)
	v_u_13.MouseButton1Down:Connect(function()
		-- upvalues: (ref) v_u_48, (ref) v_u_14
		local v142 = v_u_48 - 1
		v_u_48 = math.max(v142, 1)
		local v143 = v_u_48
		v_u_14.Text = tostring(v143)
	end)
	v_u_15.MouseButton1Down:Connect(function()
		-- upvalues: (ref) v_u_6
		v_u_6:FireServer("ChangeFriendOnly")
	end)
	v_u_7:GetAttributeChangedSignal("MatchFriendOnly"):Connect(v_u_135)
	v_u_16.Visible = v_u_7:GetAttribute("MatchFriendOnly") == true
	v_u_8:GetPropertyChangedSignal("Visible"):Connect(function()
		-- upvalues: (ref) v_u_8, (ref) v_u_50, (ref) v_u_48, (ref) v_u_45, (ref) v_u_14, (ref) v_u_58, (ref) v_u_116, (ref) v_u_47, (ref) v_u_49, (ref) v_u_6
		if v_u_8.Visible then
			v_u_50 = true
			v_u_48 = v_u_45
			local v144 = v_u_48
			v_u_14.Text = tostring(v144)
			v_u_58()
			v_u_116()
		else
			if v_u_47 then
				v_u_47:Stop()
				v_u_47 = nil
			end
			v_u_49 = nil
			if v_u_50 then
				v_u_6:FireServer("LeaveRoom")
			end
		end
	end)
	v_u_7:GetAttributeChangedSignal("EnterRoomId"):Connect(function()
		-- upvalues: (ref) v_u_7, (ref) v_u_1
		if not v_u_7:GetAttribute("EnterRoomId") then
			v_u_1.Modules.WindowUtil:Close("ScreenMatch_Endless")
		end
	end)
end)()