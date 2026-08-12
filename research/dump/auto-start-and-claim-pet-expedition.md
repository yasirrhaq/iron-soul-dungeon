# Calling code For Claiming Pet Rewards

local Event = game:GetService("ReplicatedStorage").Framework.Gameplay.PetsSystem.PetsExpeditionUtil.RemoteEvent
Event:FireServer(
    "Claim",
    2
)

# Script Dump Pets
local v1 = require(game.ReplicatedStorage:WaitForChild("Framework"))
local v2 = game:GetService("RunService")
local v_u_3 = game.Players.LocalPlayer
local v_u_4 = script.Parent
local v_u_5 = v1.Modules.TranslationUtil
local v_u_6 = v1.Modules.RarityTiers
local v_u_7 = v1.Modules.DataUtil
local v_u_8 = v1.Modules.PetsUtil
local v_u_9 = v1.Modules.PetsAffinityUtil
local v_u_10 = v1.Modules.PetsExpeditionUtil
local v_u_11 = v1.Modules.WindowUtil
local v_u_12 = v1.Modules.TimeUtil
local v_u_13 = v1.Modules.TimeLimitUtil
local v_u_14 = v1.Modules.MaterialUtil
local v_u_15 = v1.Modules.DebuffUtil
local v_u_16 = v1.Modules.CurrencyUtil
local v_u_17 = v1.Modules.ForgeUtil
local v_u_18 = v1.Modules.PetsHatchUtil
local v_u_19 = v1.Modules.PotionUtil
local v_u_20 = require(game.ReplicatedStorage:WaitForChild("Utility"):WaitForChild("Format"))
local v_u_21 = require(game.ReplicatedStorage:WaitForChild("Enum"):WaitForChild("GameEnum"))
local v_u_22 = require(game.ReplicatedStorage:WaitForChild("Utility"):WaitForChild("UniqueTypeUtil"))
local v_u_23 = require(game.ReplicatedStorage:WaitForChild("Configs"):WaitForChild("ResPetsExpeditionSlot"))
local v24 = v_u_4:WaitForChild("Content")
local v_u_25 = v24:WaitForChild("List"):WaitForChild("ScrollingFrame")
local v_u_26 = v_u_25:WaitForChild("ItemTemplate")
v_u_26.Parent = script
local v27 = v24:WaitForChild("Center")
local v_u_28 = {
	v27:WaitForChild("Slot" .. 1),
	v27:WaitForChild("Slot" .. 2),
	v27:WaitForChild("Slot" .. 3),
	v27:WaitForChild("Slot" .. 4)
}
local v29 = v24:WaitForChild("Right")
local v_u_30 = v29:WaitForChild("TitleFrame"):WaitForChild("TXT")
local v_u_31 = v29:WaitForChild("List")
local v_u_32 = v_u_31:WaitForChild("Item")
v_u_32.Parent = script
local v33 = v29:WaitForChild("StatFrame")
local v_u_34 = v33:WaitForChild("Daily"):WaitForChild("Count")
local v_u_35 = v33:WaitForChild("Exploring"):WaitForChild("Count")
local v_u_36 = v29:WaitForChild("Start")
local v_u_37 = v29:WaitForChild("Recall")
local v_u_38 = v29:WaitForChild("ClaimBtn")
local v_u_39 = v_u_10.Config.SlotCount
local v_u_40 = v_u_10.Config.Duration
local v_u_41 = v_u_10.Config.DailyLimit
local v_u_42 = nil
local v_u_43 = nil
local v_u_44 = {}
local v_u_45 = {}
local v_u_46 = false
local function v_u_59(p47, p48) -- name: GetItemDisplayInfo
	-- upvalues: (copy) v_u_21, (copy) v_u_16, (copy) v_u_5, (copy) v_u_14, (copy) v_u_15, (copy) v_u_17, (copy) v_u_19, (copy) v_u_18
	local v49 = ""
	local v50 = 1
	if p47 ~= v_u_21.ThingType.Currency then
		if p47 == v_u_21.ThingType.Crystals then
			local v51 = v_u_14:GetDef(p48)
			if v51 then
				return v51.Icon or "", v_u_5:TranslateByKey("K_" .. string.upper(p48)), v51.Rarity or 1
			end
		elseif p47 == v_u_21.ThingType.EnchantedStone then
			local v52 = v_u_14:GetDef(p48)
			if v52 then
				return v_u_15:GetDebuffIcon(v52.DebuffType), v_u_5:TranslateByKey("K_" .. string.upper(p48)), v52.Rarity or 1
			end
		elseif p47 == v_u_21.ThingType.Ore then
			local v53 = v_u_17:GetDef(p48)
			if v53 then
				return v53.Icon or "", v_u_5:TranslateByKey("K_" .. string.upper(p48)), v53.Rarity or 1
			end
		elseif p47 == v_u_21.ThingType.Potion then
			local v54 = v_u_19:GetPotionInfo(p48)
			if v54 then
				return v54.Icon or "", v_u_5:TranslateByKey(v54.Name), v54.Rarity or 1
			end
		elseif p47 == v_u_21.ThingType.Egg then
			local v55 = v_u_18:GetEggCfg(p48)
			if v55 then
				v49 = v55.Icon or ""
				p48 = v_u_5:TranslateByKey(v55.Name)
				v50 = v55.Rarity or 1
			end
		end
		return v49, p48, v50
	end
	local v56 = v_u_16.CurrencyIcons[p48] or ""
	local v57 = v_u_16.CurrencyDisplayNames[p48]
	local v58
	if v57 then
		v58 = v_u_5:TranslateByKey(v57) or p48
	else
		v58 = p48
	end
	return v56, v58, v_u_16.CurrencyRarity[p48] or 1
end
local function v_u_78(p60) -- name: RefreshRewardList
	-- upvalues: (copy) v_u_45, (copy) v_u_23, (copy) v_u_32, (copy) v_u_31, (copy) v_u_59, (copy) v_u_6
	for _, v61 in pairs(v_u_45) do
		for _, v62 in pairs(v61) do
			v62.Visible = false
		end
	end
	local v63 = v_u_23["Slot" .. p60]
	if v63 then
		local v64, v65
		if v_u_45[p60] then
			v64 = 0
			v65 = 0
		else
			v_u_45[p60] = {}
			v64 = 0
			v65 = 0
		end
		while true do
			v64 = v64 + 1
			local v66 = v63["DisItemId" .. v64]
			if v66 == nil then
				break
			end
			if v66 ~= "" then
				local v67 = v63["DisItemType" .. v64]
				local v68 = v63["DisItemCount" .. v64]
				v65 = v65 + 1
				local v69 = v_u_45[p60][v66]
				if not v69 then
					v69 = v_u_32:Clone()
					v69.Name = v66
					v69.Parent = v_u_31
					local v70 = v69:WaitForChild("BTN")
					local v71 = v70:WaitForChild("BG")
					local v72 = v70:WaitForChild("Icon")
					local v73 = v70:WaitForChild("Name")
					local v74 = v70:WaitForChild("Stat"):WaitForChild("Num")
					local v75, v76, v77 = v_u_59(v67, v66)
					v72.Image = v75
					v73.Text = v76
					v_u_6:ApplyColor(v71, v77)
					if v68 and (v68 ~= "" and tonumber(v68)) then
						v74.Text = tostring(v68)
						v74.Visible = true
					else
						v74.Visible = false
					end
					v_u_45[p60][v66] = v69
				end
				v69.LayoutOrder = v65
				v69.Visible = true
			end
		end
	end
end
local function v_u_97(p79) -- name: RefreshSlot
	-- upvalues: (copy) v_u_28, (copy) v_u_10, (copy) v_u_3, (copy) v_u_8, (copy) v_u_20, (copy) v_u_40, (copy) v_u_12, (copy) v_u_6, (ref) v_u_43
	local v80 = v_u_28[p79]
	if v80 then
		local v81 = v80:WaitForChild("BTN")
		local v82 = v81:WaitForChild("Icon")
		local v83 = v81:WaitForChild("Time")
		local v84 = v81:WaitForChild("CompletedTXT")
		local v85 = v81:FindFirstChild("BG")
		local v86 = v81:FindFirstChild("Select")
		local v87 = v_u_10:GetSlotData(v_u_3, p79)
		local v88
		if v87 then
			v88 = v87.UID
		else
			v88 = v87
		end
		if v88 then
			if v_u_10:IsCompleted(v87) then
				local v89 = v_u_8:GetOwnedPetData(v_u_3, v87.UID)
				v82.Image = v89 and v_u_8:GetPetIcon(v89.Id, v89.Star) or ""
				v82.Visible = true
				v83.Visible = false
				v84.Visible = true
			else
				local v90 = v_u_8:GetOwnedPetData(v_u_3, v87.UID)
				v82.Image = v90 and v_u_8:GetPetIcon(v90.Id, v90.Star) or ""
				v82.Visible = true
				local v91 = v_u_20
				local v92
				if v87 and v87.UID then
					local v93 = v_u_40 - (v_u_12:GetNow() - (v87.StartTime or 0))
					v92 = math.max(0, v93)
				else
					v92 = v_u_40
				end
				v83.Text = v91:Sec2HMS(v92)
				v83.Visible = true
				v84.Visible = false
			end
		else
			v82.Visible = false
			v83.Visible = false
			v84.Visible = false
		end
		if v85 or v86 then
			local v94 = 1
			if v88 then
				local v95 = v_u_8:GetOwnedPetData(v_u_3, v87.UID)
				if v95 then
					v95 = v_u_8:GetPetInfo(v95.Id)
				end
				if v95 then
					v94 = v95.Rarity
				end
			end
			if v85 then
				v_u_6:ApplyColor(v85, v94)
			end
			if v86 then
				v_u_6:ApplySelectColor(v86, v94)
			end
		end
		local v96 = v81:FindFirstChild("Select")
		if v96 then
			v96.Visible = p79 == v_u_43
		end
	end
end
local function v_u_111(p98) -- name: SelectSlot
	-- upvalues: (ref) v_u_43, (copy) v_u_39, (copy) v_u_28, (copy) v_u_23, (copy) v_u_30, (copy) v_u_5, (copy) v_u_78, (copy) v_u_10, (copy) v_u_3, (copy) v_u_34, (copy) v_u_41, (copy) v_u_35, (copy) v_u_20, (copy) v_u_40, (copy) v_u_12, (copy) v_u_36, (ref) v_u_42, (copy) v_u_37, (copy) v_u_38
	v_u_43 = p98
	for v99 = 1, v_u_39 do
		local v100 = v_u_28[v99]
		if v100 then
			local v101 = v100:FindFirstChild("BTN")
			if v101 then
				local v102 = v101:FindFirstChild("Select")
				if v102 then
					v102.Visible = v99 == p98
				end
			end
		end
	end
	local v103 = v_u_23["Slot" .. p98]
	v_u_30.Text = v103 and (v103.Name and v103.Name ~= "") and v_u_5:TranslateByKey(v103.Name) or "Slot" .. p98
	v_u_78(p98)
	v_u_34.Text = v_u_41 - v_u_10:_GetEffectiveDailyCount(v_u_3) .. "/" .. v_u_41
	local v104 = v_u_10:GetSlotData(v_u_3, p98)
	if v104 and v104.UID then
		if v_u_10:IsCompleted(v104) then
			v_u_35.Text = v_u_20:Sec2HMS(0)
		else
			local v105 = v_u_35
			local v106 = v_u_20
			local v107
			if v104 and v104.UID then
				local v108 = v_u_40 - (v_u_12:GetNow() - (v104.StartTime or 0))
				v107 = math.max(0, v108)
			else
				v107 = v_u_40
			end
			v105.Text = v106:Sec2HMS(v107)
		end
	else
		v_u_35.Text = v_u_20:Sec2HMS(v_u_40)
	end
	local v109 = v_u_10:GetSlotData(v_u_3, p98)
	local v110
	if v109 then
		v110 = v109.UID
	else
		v110 = v109
	end
	if v110 then
		if v_u_10:IsCompleted(v109) then
			v_u_36.Visible = false
			v_u_37.Visible = false
			v_u_38.Visible = true
		else
			v_u_36.Visible = false
			v_u_37.Visible = true
			v_u_38.Visible = false
		end
	else
		v_u_36.Visible = true
		v_u_36.Active = v_u_42 ~= nil
		v_u_37.Visible = false
		v_u_38.Visible = false
		return
	end
end
local function v_u_117(p112) -- name: SetCurrentSelectedPet
	-- upvalues: (copy) v_u_44, (ref) v_u_42, (ref) v_u_43, (copy) v_u_10, (copy) v_u_3, (copy) v_u_36, (copy) v_u_37, (copy) v_u_38
	for v113, v114 in pairs(v_u_44) do
		v114:SetSelected(v113 == p112)
	end
	v_u_42 = p112
	if v_u_43 then
		local v115 = v_u_10:GetSlotData(v_u_3, v_u_43)
		local v116
		if v115 then
			v116 = v115.UID
		else
			v116 = v115
		end
		if not v116 then
			v_u_36.Visible = true
			v_u_36.Active = v_u_42 ~= nil
			v_u_37.Visible = false
			v_u_38.Visible = false
			return
		end
		if v_u_10:IsCompleted(v115) then
			v_u_36.Visible = false
			v_u_37.Visible = false
			v_u_38.Visible = true
			return
		end
		v_u_36.Visible = false
		v_u_37.Visible = true
		v_u_38.Visible = false
	end
end
local function v_u_154(p118) -- name: AddPetItem
	-- upvalues: (copy) v_u_8, (copy) v_u_9, (copy) v_u_13, (copy) v_u_26, (copy) v_u_25, (copy) v_u_6, (copy) v_u_22, (copy) v_u_3, (copy) v_u_5, (copy) v_u_10, (copy) v_u_117, (copy) v_u_44, (copy) v_u_7
	local v_u_119 = v_u_8:GetPetInfo(p118.Id)
	if v_u_119 then
		if v_u_9:GetAffinityLevel(p118.Affinity or 0) < 3 then
			return
		elseif not v_u_13:IsTimeLimited(p118) then
			local v_u_120 = v_u_26:Clone()
			v_u_120.Parent = v_u_25
			v_u_120.Name = p118.UID
			local v121 = v_u_120:WaitForChild("BTN")
			local v_u_122 = v121:WaitForChild("Icon")
			local v_u_123 = v121:WaitForChild("Level")
			local v_u_124 = v121:WaitForChild("Star"):WaitForChild("Count")
			local v125 = v121:WaitForChild("Bg")
			local v_u_126 = v121:WaitForChild("Selected")
			local v_u_127 = v121:WaitForChild("Name")
			local v_u_128 = v121:WaitForChild("Exploring")
			local v129 = v121:WaitForChild("Stat")
			local v_u_130 = v129:WaitForChild("Affinity"):WaitForChild("Count")
			local v_u_131 = v129:WaitForChild("Attr")
			v_u_6:ApplyColor(v125, v_u_119.Rarity)
			v_u_6:ApplySelectColor(v_u_126, v_u_119.Rarity)
			v_u_6:ApplyTextColor(v_u_127, v_u_119.Rarity)
			v_u_22:Apply(v121, v_u_119.UniqueType)
			local v_u_148 = {
				["UID"] = p118.UID,
				["Def"] = v_u_119,
				["Data"] = p118,
				["GUI"] = v_u_120,
				["Conns"] = {},
				["IsVisible"] = true,
				["Order"] = 0,
				["SetSelected"] = function(p132, p133) -- name: SetSelected
					-- upvalues: (copy) v_u_126
					v_u_126.Visible = p133
					p132.IsSelected = p133
				end,
				["SetVisible"] = function(p134, p135) -- name: SetVisible
					-- upvalues: (copy) v_u_120
					v_u_120.Visible = p135
					p134.IsVisible = p135
				end,
				["SetOrder"] = function(p136, p137) -- name: SetOrder
					-- upvalues: (copy) v_u_120
					v_u_120.LayoutOrder = p137
					p136.Order = p137
				end,
				["UpdateInfo"] = function(p138) -- name: UpdateInfo
					-- upvalues: (ref) v_u_8, (ref) v_u_3, (copy) v_u_122, (copy) v_u_127, (ref) v_u_5, (copy) v_u_119, (copy) v_u_123, (copy) v_u_124, (copy) v_u_131, (copy) v_u_130, (ref) v_u_9, (ref) v_u_10, (copy) v_u_128
					local v139 = v_u_8:GetOwnedPetData(v_u_3, p138.UID)
					if v139 then
						v_u_122.Image = v_u_8:GetPetIcon(v139.Id, v139.Star)
						v_u_127.Text = v_u_5:TranslateByKey(v_u_119.Name)
						v_u_123.Text = string.format("Lv.%d", v139.Lv or 1)
						local v140 = v_u_124
						local v141 = v139.Star or 1
						v140.Text = tostring(v141)
						v_u_131.Text = "ATK:" .. v_u_8:GetPetAtkDmg(v_u_3, p138.UID)
						local v142 = v_u_130
						local v143 = v_u_9
						local v144 = v139.Affinity or 0
						v142.Text = tostring(v143:GetAffinityLevel(v144))
						v_u_128.Visible = v_u_10:IsDispatched(v_u_3, p138.UID)
					end
				end,
				["OnTrigger"] = function(p145) -- name: OnTrigger
					-- upvalues: (ref) v_u_10, (ref) v_u_3, (ref) v_u_117
					if not v_u_10:IsDispatched(v_u_3, p145.UID) then
						v_u_117(p145.UID)
					end
				end,
				["Destroy"] = function(p146) -- name: Destroy
					-- upvalues: (ref) v_u_44
					p146.GUI:Destroy()
					for _, v147 in pairs(p146.Conns) do
						v147:Disconnect()
					end
					table.clear(p146.Conns)
					v_u_44[p146.UID] = nil
				end
			}
			local v149 = v_u_148.Conns
			local v150 = v121.MouseButton1Down
			table.insert(v149, v150:Connect(function()
				-- upvalues: (copy) v_u_148
				v_u_148:OnTrigger()
			end))
			local v151 = v_u_148.Conns
			local v152 = v_u_7
			local v153 = v_u_3
			table.insert(v151, v152:ListenFor(v153, { "Pets", "Owned" }, function()
				-- upvalues: (copy) v_u_148
				v_u_148:UpdateInfo()
			end))
			v_u_148:SetSelected(false)
			v_u_148:UpdateInfo()
			v_u_44[v_u_148.UID] = v_u_148
		end
	else
		return
	end
end
local function v_u_165() -- name: UpdateLayoutOrder
	-- upvalues: (copy) v_u_44, (copy) v_u_8, (copy) v_u_3, (copy) v_u_9
	local v155 = {}
	for _, v156 in pairs(v_u_44) do
		if v156.IsVisible then
			table.insert(v155, v156)
		end
	end
	table.sort(v155, function(p157, p158)
		-- upvalues: (ref) v_u_8, (ref) v_u_3, (ref) v_u_9
		local v159 = v_u_8:GetOwnedPetData(v_u_3, p157.UID)
		local v160 = v_u_8:GetOwnedPetData(v_u_3, p158.UID)
		local v161 = v_u_9:GetAffinityLevel(v159 and v159.Affinity or 0)
		local v162 = v_u_9:GetAffinityLevel(v160 and v160.Affinity or 0)
		if v161 == v162 then
			if p157.Def.Rarity == p158.Def.Rarity then
				return p157.Def.Sort < p158.Def.Sort
			else
				return p157.Def.Rarity > p158.Def.Rarity
			end
		else
			return v162 < v161
		end
	end)
	for v163, v164 in ipairs(v155) do
		v164:SetOrder(v163)
	end
end
local function v_u_173() -- name: RefreshPetList
	-- upvalues: (copy) v_u_7, (copy) v_u_3, (copy) v_u_8, (copy) v_u_44, (copy) v_u_9, (copy) v_u_13, (copy) v_u_154, (ref) v_u_42, (copy) v_u_117, (ref) v_u_46, (copy) v_u_165
	local v166 = v_u_7:GetValue(v_u_3, { "Pets", "Owned" }) or {}
	local v167 = {}
	local v168 = false
	for _, v169 in ipairs(v166) do
		local v170 = v169.UID
		v167[v170] = true
		if v_u_8:GetEquippedPetIndex(v_u_3, v170) then
			if v_u_44[v170] then
				v_u_44[v170]:Destroy()
				v168 = true
			end
		elseif v_u_9:GetAffinityLevel(v169.Affinity or 0) < 3 then
			if v_u_44[v170] then
				v_u_44[v170]:Destroy()
				v168 = true
			end
		elseif v_u_13:IsTimeLimited(v169) then
			if v_u_44[v170] then
				v_u_44[v170]:Destroy()
				v168 = true
			end
		elseif not v_u_44[v170] then
			v_u_154(v169)
			v168 = true
		end
	end
	for v171, v172 in pairs(v_u_44) do
		if not v167[v171] then
			v172:Destroy()
			v168 = true
		end
	end
	if v_u_42 and not v_u_44[v_u_42] then
		v_u_117(nil)
	end
	if v168 or not v_u_46 then
		v_u_46 = true
		v_u_165()
	end
end
local v_u_174 = 0
local v_u_175 = {}
v2.Heartbeat:Connect(function(p176)
	-- upvalues: (copy) v_u_4, (ref) v_u_174, (copy) v_u_39, (copy) v_u_10, (copy) v_u_3, (copy) v_u_175, (copy) v_u_28, (ref) v_u_43, (copy) v_u_40, (copy) v_u_12, (copy) v_u_20, (copy) v_u_35, (copy) v_u_36, (ref) v_u_42, (copy) v_u_37, (copy) v_u_38
	if v_u_4.Visible then
		v_u_174 = v_u_174 + p176
		if v_u_174 >= 1 then
			v_u_174 = 0
			local v177 = false
			for v178 = 1, v_u_39 do
				local v179 = v_u_10:GetSlotData(v_u_3, v178)
				if v179 and v179.UID then
					local v180 = v_u_28[v178]
					if v180 then
						v180 = v180:FindFirstChild("BTN")
					end
					if v180 then
						local v181 = v180:FindFirstChild("Time")
						local v182 = v180:FindFirstChild("CompletedTXT")
						if v_u_10:IsCompleted(v179) then
							if v181 then
								v181.Visible = false
							end
							if v182 then
								v182.Visible = true
							end
							v177 = v178 == v_u_43 and not v_u_175[v178] and true or v177
							v_u_175[v178] = true
						else
							local v183
							if v179 and v179.UID then
								local v184 = v_u_40 - (v_u_12:GetNow() - (v179.StartTime or 0))
								v183 = math.max(0, v184)
							else
								v183 = v_u_40
							en


# Pet Script Util
-- Script Path: game:GetService("ReplicatedStorage").Framework.Gameplay.PetsSystem.PetsExpeditionUtil
-- Took 0.13s to decompile.
-- Executor: Delta (1.1.731.944)

local v_u_1 = {
    ["Config"] = {
        ["Duration"] = nil,
        ["SlotCount"] = 4,
        ["DailyLimit"] = 3,
        ["Duration"] = require(game.ReplicatedStorage:WaitForChild("Utility"):WaitForChild("GamePlaceUtil")):IsDev() and 120 or 21600
    }
}
local v_u_2 = nil
local v_u_3 = nil
local v_u_4 = nil
local v_u_5 = nil
local v_u_6 = nil
local v_u_7 = nil
local v_u_8 = nil
local v_u_9 = nil
local v_u_10 = nil
local v_u_11 = require(game.ReplicatedStorage:WaitForChild("Configs"):WaitForChild("ResPetsExpeditionSlot"))
local v_u_12 = {}
local v_u_13 = {}
local v_u_14 = v_u_1.Config.SlotCount
local v_u_15 = v_u_1.Config.Duration
local v_u_16 = v_u_1.Config.DailyLimit
function v_u_1._GetSlotCfg(_, p17) -- name: _GetSlotCfg
    -- upvalues: (copy) v_u_11
    return v_u_11["Slot" .. p17]
end
function v_u_1.GetSlotData(_, p18, p19) -- name: GetSlotData
    -- upvalues: (ref) v_u_2
    return v_u_2:GetValue(p18, { "Pets", "Expedition", (tostring(p19)) })
end
function v_u_1._GetEffectiveDailyCount(_, p20) -- name: _GetEffectiveDailyCount
    -- upvalues: (ref) v_u_3, (ref) v_u_2
    local v21 = v_u_3:GetCurrentDate()
    local v22 = v_u_2:GetValue(p20, { "Pets", "DailyDispatchDay" }) or 0
    local v23 = v_u_2:GetValue(p20, { "Pets", "DailyDispatchCount" }) or 0
    return v22 ~= v21 and 0 or v23
end
function v_u_1._GetFilteredLootTable(_, p24) -- name: _GetFilteredLootTable
    -- upvalues: (copy) v_u_12
    local v25 = v_u_12[p24] or {}
    local v26 = {}
    for _, v27 in ipairs(v25) do
        if v27.ItemType ~= "Egg" then
            table.insert(v26, v27)
        end
    end
    return v26
end
function v_u_1._GetFilteredEggTable(_, p28, p29) -- name: _GetFilteredEggTable
    -- upvalues: (copy) v_u_12, (ref) v_u_7, (ref) v_u_8
    local v30 = v_u_12[p28] or {}
    local v31 = {}
    for _, v32 in ipairs(v30) do
        if v32.ItemType == "Egg" then
            local v33 = v_u_7:GetPetIdByEggId(v32.ItemId)
            if v33 and v_u_8:IsPetUnlocked(p29, v33) then
                table.insert(v31, v32)
            end
        end
    end
    return v31
end
function v_u_1.CanDispatch(p34, p35, p36, p37) -- name: CanDispatch
    -- upvalues: (copy) v_u_14, (copy) v_u_16, (ref) v_u_5, (ref) v_u_4, (ref) v_u_6, (ref) v_u_2
    if type(p36) ~= "number" or (p36 < 1 or v_u_14 < p36) then
        return false, "K_PET_EXPEDITION_INVALID_SLOT"
    end
    if type(p37) ~= "number" or math.isnan(p37) then
        return false, "K_PET_EXPEDITION_INVALID_UID"
    end
    if v_u_16 <= p34:_GetEffectiveDailyCount(p35) then
        return false, "K_PET_EXPEDITION_DAILY_LIMIT_REACHED"
    end
    local v38 = p34:GetSlotData(p35, p36)
    if v38 and v38.UID then
        return false, "K_PET_EXPEDITION_SLOT_OCCUPIED"
    end
    local v39 = v_u_5:GetOwnedPetData(p35, p37)
    if not v39 then
        return false, "K_PET_NOT_FOUND"
    end
    if v_u_4:IsTimeLimited(v39) then
        return false, "K_TIME_LIMIT_CANNOT_EXPEDITION"
    end
    if v_u_5:GetEquippedPetIndex(p35, p37) then
        return false, "K_PET_EQUIPPED"
    end
    if v_u_6:GetAffinityLevel(v39.Affinity or 0) < 3 then
        return false, "K_PET_AFFINITY_TOO_LOW"
    end
    local v40 = v_u_2:GetValue(p35, { "Pets", "Expedition" }) or {}
    for _, v41 in pairs(v40) do
        if v41 and v41.UID == p37 then
            return false, "K_PET_ALREADY_DISPATCHED"
        end
    end
    return true
end
function v_u_1.IsDispatched(_, p42, p43) -- name: IsDispatched
    -- upvalues: (ref) v_u_2
    local v44 = v_u_2:GetValue(p42, { "Pets", "Expedition" }) or {}
    for _, v45 in pairs(v44) do
        if v45 and v45.UID == p43 then
            return true
        end
    end
    return false
end
function v_u_1.IsCompleted(_, p46) -- name: IsCompleted
    -- upvalues: (ref) v_u_3, (copy) v_u_15
    if p46 and p46.UID then
        return v_u_15 <= v_u_3:GetNow() - p46.StartTime
    else
        return false
    end
end
function v_u_1.HasDispatchablePet(_, p47) -- name: HasDispatchablePet
    -- upvalues: (ref) v_u_5, (ref) v_u_4, (ref) v_u_6
    if not (v_u_5 and p47) then
        return false
    end
    local v48 = v_u_5:GetOwnedPets(p47)
    if not v48 then
        return false
    end
    for _, v49 in ipairs(v48) do
        if v49.UID and (not v_u_4:IsTimeLimited(v49) and (not v_u_5:GetEquippedPetIndex(p47, v49.UID) and (not v_u_6 or v_u_6:GetAffinityLevel(v49.Affinity or 0) >= 3))) then
            return true
        end
    end
    return false
end
function v_u_1.Dispatch(p_u_50, p_u_51, p_u_52, p_u_53) -- name: Dispatch
    -- upvalues: (ref) v_u_9, (copy) v_u_13, (ref) v_u_3, (ref) v_u_2, (copy) v_u_16
    local v54, v55 = p_u_50:CanDispatch(p_u_51, p_u_52, p_u_53)
    if not v54 then
        if p_u_50.IS_SERVER then
            v_u_9:Warn(p_u_51, v55, {
                ["IsPositive"] = false
            })
        else
            v_u_9:Warn(v55, {
                ["IsPositive"] = false
            })
        end
        return false
    end
    if not p_u_50.IS_SERVER then
        p_u_50.RemoteEvent:FireServer("Dispatch", p_u_52, p_u_53)
        return true
    end
    if v_u_13[p_u_51] then
        return false
    end
    v_u_13[p_u_51] = true
    local v64, v65 = pcall(function()
        -- upvalues: (copy) p_u_50, (copy) p_u_51, (copy) p_u_52, (copy) p_u_53, (ref) v_u_3, (ref) v_u_2, (ref) v_u_16
        if not p_u_50:CanDispatch(p_u_51, p_u_52, p_u_53) then
            return false
        end
        local v56 = v_u_3:GetCurrentDate()
        local v57 = v_u_2:GetValue(p_u_51, { "Pets", "DailyDispatchDay" }) or 0
        local v58 = v_u_2:GetValue(p_u_51, { "Pets", "DailyDispatchCount" }) or 0
        local v59 = v57 == v56 and v58 and v58 or 0
        if v_u_16 <= v59 then
            return false
        end
        local v60 = v_u_2
        local v61 = p_u_51
        local v62 = {}
        local v63 = p_u_52
        __set_list(v62, 1, {"Pets", "Expedition", (tostring(v63))})
        v60:SetValue(v61, v62, {
            ["UID"] = p_u_53,
            ["StartTime"] = v_u_3:GetNow()
        })
        v_u_2:SetValue(p_u_51, { "Pets", "DailyDispatchCount" }, v59 + 1)
        if v57 ~= v56 then
            v_u_2:SetValue(p_u_51, { "Pets", "DailyDispatchDay" }, v56)
        end
        return true
    end)
    v_u_13[p_u_51] = nil
    if v64 then
        return v65
    end
    warn("[PetsExpeditionUtil] Dispatch error: " .. tostring(v65))
    return false
end
function v_u_1.Recall(p66, p67, p68) -- name: Recall
    -- upvalues: (ref) v_u_2
    if not p66.IS_SERVER then
        p66.RemoteEvent:FireServer("Recall", p68)
        return true
    end
    local v69 = p66:GetSlotData(p67, p68)
    if not (v69 and v69.UID) then
        return false
    end
    if p66:IsCompleted(v69) then
        return false
    end
    v_u_2:SetValue(p67, { "Pets", "Expedition", (tostring(p68)) }, nil)
    return true
end
function v_u_1.ResetDailyDispatch(p70, p71) -- name: ResetDailyDispatch
    -- upvalues: (ref) v_u_2
    if not p70.IS_SERVER then
        return false
    end
    if not p71 then
        return false
    end
    v_u_2:SetValue(p71, { "Pets", "DailyDispatchCount" }, 0)
    v_u_2:SetValue(p71, { "Pets", "DailyDispatchDay" }, 0)
    return true
end
function v_u_1.CompleteAllDispatch(p72, p73) -- name: CompleteAllDispatch
    -- upvalues: (ref) v_u_3, (copy) v_u_14, (copy) v_u_15, (ref) v_u_2
    if not p72.IS_SERVER then
        return false
    end
    if not p73 then
        return false
    end
    local v74 = v_u_3:GetNow()
    local v75 = 0
    for v76 = 1, v_u_14 do
        local v77 = p72:GetSlotData(p73, v76)
        if v77 and (v77.UID and v74 - (v77.StartTime or v74) < v_u_15) then
            v_u_2:SetValue(p73, { "Pets", "Expedition", (tostring(v76)) }, {
                ["UID"] = v77.UID,
                ["StartTime"] = v74 - v_u_15
            })
            v75 = v75 + 1
        end
    end
    return true, v75
end
function v_u_1.Claim(p_u_78, p_u_79, p_u_80) -- name: Claim
    -- upvalues: (copy) v_u_13, (ref) v_u_5, (ref) v_u_2, (ref) v_u_6, (ref) v_u_10
    if not p_u_78.IS_SERVER then
        p_u_78.RemoteEvent:FireServer("Claim", p_u_80)
        return true
    end
    if v_u_13[p_u_79] then
        return false
    end
    v_u_13[p_u_79] = true
    local v96, v97 = pcall(function()
        -- upvalues: (copy) p_u_78, (copy) p_u_79, (copy) p_u_80, (ref) v_u_5, (ref) v_u_2, (ref) v_u_6, (ref) v_u_10
        local v81 = p_u_78:GetSlotData(p_u_79, p_u_80)
        if not (v81 and v81.UID) then
            return false
        end
        if not p_u_78:IsCompleted(v81) then
            return false
        end
        local v82 = v_u_5:GetOwnedPetData(p_u_79, v81.UID)
        if not v82 then
            local v83 = v_u_2
            local v84 = p_u_79
            local v85 = {}
            local v86 = p_u_80
            __set_list(v85, 1, {"Pets", "Expedition", (tostring(v86))})
            v83:SetValue(v84, v85, nil)
            return false
        end
        local v87 = v_u_6:GetAffinityLevel(v82.Affinity or 0)
        local v88 = v_u_2
        local v89 = p_u_79
        local v90 = {}
        local v91 = p_u_80
        __set_list(v90, 1, {"Pets", "Expedition", (tostring(v91))})
        v88:SetValue(v89, v90, nil)
        local v92 = p_u_78:_GetSlotCfg(p_u_80)
        if v92 then
            for _, v93 in ipairs({ v92.LootTableId1, v92.LootTableId2, v92.LootTableId3 }) do
                local v94 = p_u_78:_GetFilteredLootTable(v93)
                if v94 and #v94 > 0 then
                    v_u_10:GiveLootItemByCustomTable(p_u_79, v94, 1, v87, true, nil, true)
                end
            end
            if v87 >= 8 and (v87 - 7) * 0.04 > math.random() then
                local v95 = p_u_78:_GetFilteredEggTable(v92.EggLootTableId, p_u_79)
                if v95 and #v95 > 0 then
                    v_u_10:GiveLootItemByCustomTable(p_u_79, v95, 1, v87, true, nil, true)
                end
            end
        end
        return true
    end)
    v_u_13[p_u_79] = nil
    if v96 then
        return v97
    end
    warn("[PetsExpeditionUtil] Claim error: " .. tostring(v97))
    return false
end
function v_u_1.Init(p98) -- name: Init
    -- upvalues: (ref) v_u_2, (ref) v_u_3, (ref) v_u_4, (ref) v_u_5, (ref) v_u_6, (ref) v_u_7, (ref) v_u_8, (ref) v_u_9, (ref) v_u_10, (copy) v_u_12
    p98.RemoteEvent = script:WaitForChild("RemoteEvent")
    v_u_2 = p98.Modules.DataUtil
    v_u_3 = p98.Modules.TimeUtil
    v_u_4 = p98.Modules.TimeLimitUtil
    v_u_5 = p98.Modules.PetsUtil
    v_u_6 = p98.Modules.PetsAffinityUtil
    v_u_7 = p98.Modules.PetsHatchUtil
    v_u_8 = p98.Modules.ItemsIndexUtil
    v_u_9 = p98.Modules.WarningUtil
    v_u_10 = p98.Modules.LootServiceUtil
    if p98.IS_SERVER then
        local v99 = require(game.ServerStorage:WaitForChild("Configs"):WaitForChild("ResPetsExpeditionLoot"))
        for _, v100 in ipairs(v99.__index) do
            local v101 = v99[v100]
            if not v_u_12[v101.Table] then
                v_u_12[v101.Table] = {}
            end
            local v102 = v_u_12[v101.Table]
            table.insert(v102, v101)
        end
    end
end
function v_u_1._MigrateSlotKeys(_, p103) -- name: _MigrateSlotKeys
    -- upvalues: (ref) v_u_2, (copy) v_u_1
    local v104 = v_u_2:GetValue(p103, { "Pets", "Expedition" })
    if v104 then
        for v105 = 1, v_u_1.Config.SlotCount do
            local v106 = v104[v105]
            if v106 ~= nil then
                if v104[tostring(v105)] == nil then
                    v_u_2:SetValue(p103, { "Pets", "Expedition", (tostring(v105)) }, v106)
                end
                v_u_2:SetValue(p103, { "Pets", "Expedition", v105 }, nil)
            end
        end
    end
end
function v_u_1.Start(p_u_107) -- name: Start
    -- upvalues: (ref) v_u_2, (copy) v_u_13
    if p_u_107.IS_SERVER then
        v_u_2.OnDataAdded:Connect(function(p_u_108)
            -- upvalues: (copy) p_u_107
            task.spawn(function()
                -- upvalues: (ref) p_u_107, (copy) p_u_108
                p_u_107:_MigrateSlotKeys(p_u_108)
            end)
        end)
        for v_u_109, _ in pairs(v_u_2.Data) do
            task.spawn(function()
                -- upvalues: (copy) p_u_107, (copy) v_u_109
                p_u_107:_MigrateSlotKeys(v_u_109)
            end)
        end
        game.Players.PlayerRemoving:Connect(function(p110)
            -- upvalues: (ref) v_u_13
            v_u_13[p110] = nil
        end)
        p_u_107.RemoteEvent.OnServerEvent:Connect(function(p111, p112, ...)
            -- upvalues: (copy) p_u_107
            local v113 = { ... }
            if p112 == "Dispatch" then
                local v114 = v113[1]
                local v115 = v113[2]
                local v116
                if type(v114) == "number" and (v114 == math.floor(v114) and v114 >= 1) then
                    v116 = v114 ~= (1 / 0)
                else
                    v116 = false
                end
                if v116 then
                    if type(v115) == "number" and (not math.isnan(v115) and v115 ~= (1 / 0)) then
                        p_u_107:Dispatch(p111, v114, v115)
                    end
                else
                    return
                end
            elseif p112 == "Recall" then
                local v117 = v113[1]
                local v118
                if type(v117) == "number" and (v117 == math.floor(v117) and v117 >= 1) then
                    v118 = v117 ~= (1 / 0)
                else
                    v118 = false
                end
                if v118 then
                    p_u_107:Recall(p111, v117)
                end
            else
                if p112 == "Claim" then
                    local v119 = v113[1]
                    local v120
                    if type(v119) == "number" and (v119 == math.floor(v119) and v119 >= 1) then
                        v120 = v119 ~= (1 / 0)
                    else
                        v120 = false
                    end
                    if not v120 then
                        return
                    end
                    p_u_107:Claim(p111, v119)
                end
                return
            end
        end)
    end
end
return v_u_1

# Starting Pet Expedition Calling Code

local Event = game:GetService("ReplicatedStorage").Framework.Gameplay.PetsSystem.PetsExpeditionUtil.RemoteEvent
Event:FireServer(
    "Dispatch",
    4,
    1
)