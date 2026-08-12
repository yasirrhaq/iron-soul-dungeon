# Calling Code Hatching
local Event = game:GetService("ReplicatedStorage").Framework.Gameplay.PetsSystem.PetsHatchUtil.RemoteEvent
Event:FireServer(
    "StartHatch",
    1,
    "6HOqgQpcWnJd4itmo0qRiaZ8"
)

# Decompiled Script

local v1 = require(game.ReplicatedStorage:WaitForChild("Framework"))
local v2 = game:GetService("RunService")
local v_u_3 = game.Players.LocalPlayer
local v_u_4 = script.Parent
local v_u_5 = v1.Modules.TranslationUtil
local v_u_6 = v1.Modules.RarityTiers
local v_u_7 = v1.Modules.DataUtil
local v_u_8 = v1.Modules.PetsHatchUtil
local v_u_9 = v1.Modules.PurchasablesUtil
local v_u_10 = v1.Modules.WarningUtil
local v_u_11 = v1.Modules.TimeUtil
local v_u_12 = require(game.ReplicatedStorage:WaitForChild("Utility"):WaitForChild("Format"))
local v_u_13 = v1.Modules.Items
local v14 = v_u_4:WaitForChild("Content")
local v15 = v14:WaitForChild("Left")
local v_u_16 = v15:WaitForChild("List"):WaitForChild("ScrollingFrame")
local v_u_17 = v_u_16:WaitForChild("ItemTemplate")
v_u_17.Parent = script
local v_u_18 = v15:WaitForChild("Hatch")
local v_u_19 = v_u_18:WaitForChild("Normal")
local v_u_20 = v_u_18:WaitForChild("Not")
local v21 = v14:WaitForChild("Right")
local v_u_22 = { v21:WaitForChild("Slot" .. 1), v21:WaitForChild("Slot" .. 2), v21:WaitForChild("Slot" .. 3) }
local v_u_23 = nil
local v_u_24 = {}
local v_u_25 = {}
local function v_u_29() -- name: GetFirstEmptySlot
	-- upvalues: (copy) v_u_8, (copy) v_u_3
	local v26 = v_u_8:GetSlotData(v_u_3, 1)
	if not (v26 and v26.EggId) then
		return 1
	end
	local v27 = v_u_8:GetSlotData(v_u_3, 2)
	if not (v27 and v27.EggId) then
		return 2
	end
	local v28 = v_u_8:GetSlotData(v_u_3, 3)
	return not (v28 and v28.EggId) and 3 or nil
end
local function v_u_53(p30) -- name: RefreshSlot
	-- upvalues: (copy) v_u_22, (copy) v_u_8, (copy) v_u_3, (copy) v_u_6, (copy) v_u_5, (copy) v_u_12, (copy) v_u_11
	local v31 = v_u_22[p30]
	if v31 then
		local v32 = v31:WaitForChild("BTN")
		local v33 = v32:WaitForChild("Normal")
		local v34 = v32:WaitForChild("Empty")
		local v35 = v31:WaitForChild("Name")
		local v36 = v31:WaitForChild("Attribute")
		local v37 = v31:WaitForChild("Countdown")
		local v38 = v37:WaitForChild("Count")
		local v39 = v31:WaitForChild("Completed")
		local v40 = v31:WaitForChild("No")
		local v41 = v31:WaitForChild("Claim")
		local v42 = v31:WaitForChild("Skip")
		local v43 = v33:WaitForChild("Bg")
		local v44 = v_u_8:GetSlotData(v_u_3, p30)
		local v45
		if v44 then
			v45 = v44.EggId
		else
			v45 = v44
		end
		if v45 then
			if v_u_8:IsCompleted(v44) then
				local v46 = v_u_8:GetEggCfg(v44.EggId)
				if v46 then
					v33:WaitForChild("Icon").Image = v46.Icon or ""
					v35.Text = v_u_5:TranslateByKey(v46.Name)
					v_u_6:SetTextLabelToTier(v36, v46.Rarity)
					v_u_6:ApplyColorByName(v43, v46.Rarity, "TierGradients")
				end
				v33.Visible = true
				v34.Visible = false
				v35.Visible = true
				v36.Visible = true
				v37.Visible = false
				v39.Visible = true
				v40.Visible = false
				v41.Visible = true
				v42.Visible = false
			else
				local v47 = v_u_8:GetEggCfg(v44.EggId)
				if v47 then
					v33:WaitForChild("Icon").Image = v47.Icon or ""
					v35.Text = v_u_5:TranslateByKey(v47.Name)
					v_u_6:SetTextLabelToTier(v36, v47.Rarity)
					local v48 = v_u_12
					local v49
					if v44 and v44.EggId then
						local v50 = v_u_8:GetEggCfg(v44.EggId)
						if v50 then
							local v51 = v_u_11:GetNow()
							local v52 = v50.HatchDuration - (v51 - (v44.StartTime or 0))
							v49 = math.max(0, v52)
						else
							v49 = 0
						end
					else
						v49 = 0
					end
					v38.Text = v48:Sec2HMS(v49)
					v_u_6:ApplyColorByName(v43, v47.Rarity, "TierGradients")
				end
				v33.Visible = true
				v34.Visible = false
				v35.Visible = true
				v36.Visible = true
				v37.Visible = true
				v39.Visible = false
				v40.Visible = false
				v41.Visible = false
				v42.Visible = true
			end
		else
			v33.Visible = false
			v34.Visible = true
			v35.Visible = false
			v36.Visible = false
			v37.Visible = false
			v39.Visible = false
			v40.Visible = true
			v41.Visible = false
			v42.Visible = false
			v_u_6:ApplyColorByName(v43, 1, "TierGradients")
			return
		end
	else
		return
	end
end
local function v_u_58(p54) -- name: SetCurrentSelectedEgg
	-- upvalues: (copy) v_u_24, (ref) v_u_23, (copy) v_u_29, (copy) v_u_19, (copy) v_u_20
	for v55, v56 in pairs(v_u_24) do
		v56:SetSelected(v55 == p54)
	end
	if p54 and v_u_24[p54] then
		v_u_23 = v_u_24[p54].EggData
	else
		v_u_23 = nil
	end
	local v57
	if v_u_23 == nil then
		v57 = false
	else
		v57 = v_u_29() ~= nil
	end
	v_u_19.Visible = v57
	v_u_20.Visible = not v57
end
local function v_u_83(p_u_59, p60) -- name: AddEggItem
	-- upvalues: (copy) v_u_8, (copy) v_u_17, (copy) v_u_16, (copy) v_u_5, (copy) v_u_12, (copy) v_u_6, (ref) v_u_23, (copy) v_u_24, (copy) v_u_29, (copy) v_u_19, (copy) v_u_20, (copy) v_u_58
	local v61 = v_u_8:GetEggCfg(p60.EggId)
	if v61 then
		local v_u_62 = v_u_17:Clone()
		v_u_62.Parent = v_u_16
		v_u_62.Name = p_u_59
		local v63 = v_u_62:WaitForChild("BTN")
		local v64 = v63:WaitForChild("Icon")
		local v65 = v63:WaitForChild("Bg")
		local v_u_66 = v63:WaitForChild("Selected")
		local v67 = v63:WaitForChild("Name")
		local v68 = v63:WaitForChild("Stat"):WaitForChild("Countdown"):WaitForChild("Count")
		v64.Image = v61.Icon or ""
		v67.Text = v_u_5:TranslateByKey(v61.Name)
		v68.Text = v_u_12:Sec2HMS(v61.HatchDuration)
		v_u_6:ApplyColor(v65, v61.Rarity)
		v_u_6:ApplySelectColor(v_u_66, v61.Rarity)
		v_u_6:ApplyTextColor(v67, v61.Rarity)
		local v79 = {
			["UUID"] = p_u_59,
			["EggData"] = {
				["UUID"] = p_u_59,
				["EggId"] = p60.EggId,
				["cfg"] = v61
			},
			["Cfg"] = v61,
			["GUI"] = v_u_62,
			["Conns"] = {},
			["Order"] = 0,
			["SetSelected"] = function(p69, p70) -- name: SetSelected
				-- upvalues: (copy) v_u_66
				v_u_66.Visible = p70
				p69.IsSelected = p70
			end,
			["SetOrder"] = function(p71, p72) -- name: SetOrder
				-- upvalues: (copy) v_u_62
				v_u_62.LayoutOrder = p72
				p71.Order = p72
			end,
			["Destroy"] = function(p73) -- name: Destroy
				-- upvalues: (ref) v_u_23, (ref) v_u_24, (ref) v_u_29, (ref) v_u_19, (ref) v_u_20
				p73.GUI:Destroy()
				for _, v74 in pairs(p73.Conns) do
					v74:Disconnect()
				end
				table.clear(p73.Conns)
				local v75 = v_u_23
				if v75 then
					v75 = v_u_23.UUID == p73.UUID
				end
				v_u_24[p73.UUID] = nil
				if v75 then
					for v76, v77 in pairs(v_u_24) do
						v77:SetSelected(v76 == nil)
					end
					v_u_23 = nil
					local v78
					if v_u_23 == nil then
						v78 = false
					else
						v78 = v_u_29() ~= nil
					end
					v_u_19.Visible = v78
					v_u_20.Visible = not v78
				end
			end
		}
		local v80 = v79.Conns
		local v81 = v63.MouseButton1Down
		local function v82()
			-- upvalues: (ref) v_u_58, (copy) p_u_59
			v_u_58(p_u_59)
		end
		table.insert(v80, v81:Connect(v82))
		v79:SetSelected(false)
		v_u_24[p_u_59] = v79
	end
end
local function v_u_90() -- name: UpdateLayoutOrder
	-- upvalues: (copy) v_u_24
	local v84 = {}
	for _, v85 in pairs(v_u_24) do
		table.insert(v84, v85)
	end
	table.sort(v84, function(p86, p87)
		if p86.Cfg.Rarity == p87.Cfg.Rarity then
			return (p86.Cfg.Sort or 0) < (p87.Cfg.Sort or 0)
		else
			return p86.Cfg.Rarity > p87.Cfg.Rarity
		end
	end)
	for v88, v89 in ipairs(v84) do
		v89:SetOrder(v88)
	end
end
local function v_u_97() -- name: RefreshEggList
	-- upvalues: (copy) v_u_8, (copy) v_u_3, (copy) v_u_24, (copy) v_u_83, (copy) v_u_90
	local v91 = v_u_8:GetOwnedEggs(v_u_3)
	local v92 = {}
	for v93, v94 in pairs(v91) do
		v92[v93] = true
		if not v_u_24[v93] then
			v_u_83(v93, v94)
		end
	end
	for v95, v96 in pairs(v_u_24) do
		if not v92[v95] then
			v96:Destroy()
		end
	end
	v_u_90()
end
local v_u_98 = 0
v2.Heartbeat:Connect(function(p99)
	-- upvalues: (copy) v_u_4, (ref) v_u_98, (copy) v_u_8, (copy) v_u_3, (ref) v_u_25, (copy) v_u_22, (ref) v_u_23, (copy) v_u_29, (copy) v_u_19, (copy) v_u_20, (copy) v_u_12, (copy) v_u_11
	if v_u_4.Visible then
		v_u_98 = v_u_98 + p99
		if v_u_98 >= 1 then
			v_u_98 = 0
			for v100 = 1, 3 do
				local v101 = v_u_8:GetSlotData(v_u_3, v100)
				if v101 and v101.EggId then
					local v102 = v_u_22[v100]
					local v103
					if v102 then
						v103 = v102:FindFirstChild("Countdown")
					else
						v103 = v102
					end
					local v104
					if v103 then
						v104 = v103:FindFirstChild("Count")
					else
						v104 = v103
					end
					local v105
					if v102 then
						v105 = v102:FindFirstChild("Completed")
					else
						v105 = v102
					end
					local v106
					if v102 then
						v106 = v102:FindFirstChild("Claim")
					else
						v106 = v102
					end
					if v102 then
						v102 = v102:FindFirstChild("Skip")
					end
					if v_u_8:IsCompleted(v101) then
						if v103 then
							v103.Visible = false
						end
						if v105 then
							v105.Visible = true
						end
						if v106 then
							v106.Visible = true
						end
						if v102 then
							v102.Visible = false
						end
						if not v_u_25[v100] then
							v_u_25[v100] = true
							local v107
							if v_u_23 == nil then
								v107 = false
							else
								v107 = v_u_29() ~= nil
							end
							v_u_19.Visible = v107
							v_u_20.Visible = not v107
						end
					else
						v_u_25[v100] = false
						if v104 then
							local v108 = v_u_12
							local v109
							if v101 and v101.EggId then
								local v110 = v_u_8:GetEggCfg(v101.EggId)
								if v110 then
									local v111 = v_u_11:GetNow()
									local v112 = v110.HatchDuration - (v111 - (v101.StartTime or 0))
									v109 = math.max(0, v112)
								else
									v109 = 0
								end
							else
								v109 = 0
							end
							v104.Text = v108:Sec2HMS(v109)
						end
						if v103 then
							v103.Visible = true
						end
						if v105 then
							v105.Visible = false
						end
					end
				else
					v_u_25[v100] = false
				end
			end
		end
	else
		return
	end
end);
(function() -- name: Init
	-- upvalues: (copy) v_u_18, (copy) v_u_19, (ref) v_u_23, (copy) v_u_29, (copy) v_u_8, (copy) v_u_3, (copy) v_u_24, (copy) v_u_20, (copy) v_u_22, (copy) v_u_13, (copy) v_u_10, (copy) v_u_9, (copy) v_u_7, (copy) v_u_97, (copy) v_u_53, (ref) v_u_25, (copy) v_u_4
	v_u_18.MouseButton1Down:Connect(function()
		-- upvalues: (ref) v_u_19, (ref) v_u_23, (ref) v_u_29, (ref) v_u_8, (ref) v_u_3, (ref) v_u_24, (ref) v_u_20
		if v_u_19.Visible then
			if v_u_23 then
				local v113 = v_u_29()
				if v113 then
					if v_u_8:StartHatch(v_u_3, v113, v_u_23.UUID) then
						for v114, v115 in pairs(v_u_24) do
							v115:SetSelected(v114 == nil)
						end
						v_u_23 = nil
						local v116
						if v_u_23 == nil then
							v116 = false
						else
							v116 = v_u_29() ~= nil
						end
						v_u_19.Visible = v116
						v_u_20.Visible = not v116
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
	end)
	for v_u_117 = 1, 3 do
		local v118 = v_u_22[v_u_117]
		v118:WaitForChild("Claim").MouseButton1Down:Connect(function()
			-- upvalues: (ref) v_u_8, (ref) v_u_3, (copy) v_u_117
			v_u_8:Claim(v_u_3, v_u_117)
		end)
		v118:WaitForChild("Skip").MouseButton1Down:Connect(function()
			-- upvalues: (copy) v_u_117, (ref) v_u_8, (ref) v_u_3, (ref) v_u_13, (ref) v_u_10, (ref) v_u_9
			local v119 = v_u_8:GetSlotData(v_u_3, v_u_117)
			if v119 and v119.EggId then
				if v_u_8:IsCompleted(v119) then
					return
				else
					local v120 = v_u_8:GetEggCfg(v119.EggId)
					if v120 then
						local v121 = "SkipHatch_R" .. v120.Rarity
						if v_u_13:GetItem("Purchasables", v121) then
							v_u_8:SetPendingSkip(v_u_3, v_u_117)
							v_u_9:PromptPurchaseById(v_u_3, v121)
						else
							v_u_10:Warn("K_NOT_SUPPORTED", {
								["IsPositive"] = false
							})
						end
					else
						return
					end
				end
			else
				return
			end
		end)
	end
	v_u_7:ListenFor(v_u_3, { "PetHatch", "Egg" }, function()
		-- upvalues: (ref) v_u_97
		task.defer(v_u_97)
	end)
	v_u_7:ListenFor(v_u_3, { "PetHatch", "Slots" }, function()
		-- upvalues: (ref) v_u_53, (ref) v_u_23, (ref) v_u_29, (ref) v_u_19, (ref) v_u_20, (ref) v_u_25
		v_u_53(1)
		v_u_53(2)
		v_u_53(3)
		local v122
		if v_u_23 == nil then
			v122 = false
		else
			v122 = v_u_29() ~= nil
		end
		v_u_19.Visible = v122
		v_u_20.Visible = not v122
		v_u_25 = {}
	end)
	v_u_4:GetPropertyChangedSignal("Visible"):Connect(function()
		-- upvalues: (ref) v_u_4, (ref) v_u_25, (ref) v_u_97, (ref) v_u_53, (ref) v_u_23, (ref) v_u_29, (ref) v_u_19, (ref) v_u_20, (ref) v_u_24
		if v_u_4.Visible then
			v_u_25 = {}
			task.defer(function()
				-- upvalues: (ref) v_u_97, (ref) v_u_53, (ref) v_u_23, (ref) v_u_29, (ref) v_u_19, (ref) v_u_20
				v_u_97()
				v_u_53(1)
				v_u_53(2)
				v_u_53(3)
				local v123
				if v_u_23 == nil then
					v123 = false
				else
					v123 = v_u_29() ~= nil
				end
				v_u_19.Visible = v123
				v_u_20.Visible = not v123
			end)
		else
			for v124, v125 in pairs(v_u_24) do
				v125:SetSelected(v124 == nil)
			end
			v_u_23 = nil
			local v126
			if v_u_23 == nil then
				v126 = false
			else
				v126 = v_u_29() ~= nil
			end
			v_u_19.Visible = v126
			v_u_20.Visible = not v126
		end
	end)
end)()

# Calling Code for Claiming Hatch Pet

-- This code was generated by Cobalt
-- https://gitlab.com/upio/cobalt

local Event = game:GetService("ReplicatedStorage").Framework.Gameplay.PetsSystem.PetsHatchUtil.RemoteEvent
Event:FireServer(
    "Claim",
    1
)