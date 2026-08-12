# Calling code after picking weapon

local Event = game:GetService("ReplicatedStorage").Framework.Gameplay.EquipmentSystem.EquipmentRE
Event:FireServer(
    "RequestSetExtraWeapon",
    "m1fZzEmbCYqvMzebp0qRiaZ8"
)

# Decompiled Script
local v1 = require(game.ReplicatedStorage:WaitForChild("Framework"))
local v_u_2 = game.Players.LocalPlayer
local v_u_3 = script.Parent
local v_u_4 = require(game.ReplicatedStorage:WaitForChild("Enum"):WaitForChild("KeyString"))
local v_u_5 = v_u_3:WaitForChild("ScrollingFrame")
local v_u_6 = v_u_5:WaitForChild("ItemTemplate")
v_u_6.Parent = script
local v_u_7 = v_u_3.Parent:WaitForChild("ControlFrame")
local v8 = v_u_7:WaitForChild("BtnFrame"):WaitForChild("Confirm")
local v_u_9 = v_u_7:WaitForChild("BtnFrame"):WaitForChild("FilterBtn")
v_u_7:WaitForChild("Selected")
local v_u_10 = v_u_3.Parent:WaitForChild("Info"):WaitForChild("InfoBE")
local v_u_11 = v1.Modules.TranslationUtil
local v_u_12 = v1.Modules.RarityTiers
local v_u_13 = v1.Modules.DataUtil
local v_u_14 = v1.Modules.EquipmentUtil
local v_u_15 = v1.Modules.TimeLimitUtil
local v_u_16 = v1.Modules.WindowUtil
local v_u_17 = v1.Modules.DebuffUtil
local v_u_18 = require(game.ReplicatedStorage:WaitForChild("Utility"):WaitForChild("UniqueTypeUtil"))
local v19 = v_u_3.Parent.Parent:WaitForChild("BE")
local v_u_20 = {}
local v_u_21 = nil
local v_u_22 = nil
local function v_u_26(p23) -- name: UpdateSelected
	-- upvalues: (copy) v_u_20, (ref) v_u_21, (copy) v_u_10
	for v24, v25 in pairs(v_u_20) do
		v25:SetSelected(v24 == p23)
	end
	v_u_21 = p23
	v_u_10:Fire("Equipment", p23)
end
local function v_u_72(p_u_27) -- name: AddItem
	-- upvalues: (copy) v_u_14, (copy) v_u_6, (copy) v_u_5, (copy) v_u_18, (copy) v_u_11, (copy) v_u_2, (copy) v_u_12, (copy) v_u_26, (copy) v_u_13, (copy) v_u_17, (copy) v_u_4, (copy) v_u_20, (copy) v_u_3, (copy) v_u_9
	local v_u_28 = v_u_14:GetDef(p_u_27.ID)
	if v_u_28 then
		local v_u_29 = v_u_6:Clone()
		v_u_29.Parent = v_u_5
		v_u_29.Name = p_u_27.UUID
		local v30 = v_u_29:WaitForChild("BTN")
		local v31 = v30:WaitForChild("Icon")
		local v_u_32 = v30:WaitForChild("Name")
		local v33 = v30:WaitForChild("Stat")
		local v_u_34 = v33:WaitForChild("Price")
		local v_u_35 = v33:WaitForChild("Attr")
		local v36 = v30:WaitForChild("Bg")
		local v_u_37 = v30:WaitForChild("Selected")
		local v_u_38 = v30:WaitForChild("Equipped")
		local v39 = v30:WaitForChild("Level")
		v30:WaitForChild("IsHell").Visible = v_u_28.IsHell
		local v_u_40 = v30:WaitForChild("EnchantmentSlot")
		local v_u_41 = v_u_40:WaitForChild("Item")
		v_u_41.Visible = false
		v31.Image = v_u_28.Icon
		v_u_18:Apply(v30, v_u_28.UniqueType)
		v_u_34.Text = string.format("%d $", v_u_14:GetPriceByInfo(p_u_27, v_u_28))
		v_u_35.Text = v_u_11:TranslateByKey(v_u_28.Type == "Weapon" and "K_DMG" or "K_HP") .. ":" .. v_u_14:GetDmgOrHpByInfo(v_u_2, p_u_27, v_u_28)
		v_u_12:ApplyColor(v36, v_u_14:GetOreRarity(p_u_27.MaxOre))
		v_u_12:ApplySelectColor(v_u_37, v_u_14:GetOreRarity(p_u_27.MaxOre))
		v_u_12:ApplyTextColor(v_u_32, v_u_14:GetOreRarity(p_u_27.MaxOre))
		v39.Text = string.format("Lv.%d", v_u_14:GetLvByInfo(p_u_27, v_u_28)) .. (v_u_28.WJB and " (" .. v_u_11:TranslateByKey("K_REQUIRE_WJB") .. ")" or "")
		local v_u_51 = {
			["ID"] = p_u_27.ID,
			["UUID"] = p_u_27.UUID,
			["Def"] = v_u_28,
			["Rarity"] = v_u_14:GetOreRarity(p_u_27.MaxOre),
			["Conns"] = {},
			["GUI"] = v_u_29,
			["Data"] = p_u_27,
			["CheckVisible"] = p_u_27.Type == "Weapon" and p_u_27.Type or p_u_27.Class,
			["SetOrder"] = function(p42, p43) -- name: SetOrder
				-- upvalues: (copy) v_u_29
				v_u_29.LayoutOrder = p43
				p42.Order = p43
			end,
			["SetVisible"] = function(p44, p45) -- name: SetVisible
				-- upvalues: (copy) v_u_29
				v_u_29.Visible = p45
				p44.IsVisible = p45
			end,
			["SetSelected"] = function(p46, p47) -- name: SetSelected
				-- upvalues: (copy) v_u_37
				v_u_37.Visible = p47
				p46.Selected = p47
			end,
			["SetEquiped"] = function(p48, p49) -- name: SetEquiped
				-- upvalues: (copy) v_u_38
				v_u_38.Visible = p49
				p48.Equiped = p49
			end,
			["OnTrigger"] = function(p50) -- name: OnTrigger
				-- upvalues: (ref) v_u_26
				v_u_26(p50.UUID)
			end
		}
		local v52 = v_u_51.Conns
		local v53 = v30.MouseButton1Down
		table.insert(v52, v53:Connect(function()
			-- upvalues: (copy) v_u_51
			v_u_51:OnTrigger()
		end))
		function v_u_51.Refresh(_) -- name: Refresh
			-- upvalues: (copy) v_u_34, (ref) v_u_14, (copy) p_u_27, (copy) v_u_28, (copy) v_u_35, (ref) v_u_11, (ref) v_u_2, (copy) v_u_32
			v_u_34.Text = string.format("%d $", v_u_14:GetPriceByInfo(p_u_27, v_u_28))
			v_u_35.Text = v_u_11:TranslateByKey(v_u_28.Type == "Weapon" and "K_DMG" or "K_HP") .. ":" .. v_u_14:GetDmgOrHpByInfo(v_u_2, p_u_27, v_u_28)
			local v54 = p_u_27.Fortify and p_u_27.Fortify - 1 or 0
			v_u_32.Text = v_u_11:TranslateByKey("K_" .. string.upper(v_u_28.ID)) .. (v54 > 0 and string.format("(+%d)", v54) or "")
		end
		local v55 = v_u_51.Conns
		local v56 = v_u_13
		local v57 = v_u_2
		table.insert(v55, v56:ListenFor(v57, { "Equipment", "Owned" }, function(_, _, ...)
			-- upvalues: (copy) v_u_51
			v_u_51:Refresh()
		end))
		function v_u_51.UpdateEnchantmentSlot(p58) -- name: UpdateEnchantmentSlot
			-- upvalues: (copy) v_u_40, (copy) v_u_41, (ref) v_u_17
			for _, v59 in pairs(v_u_40:GetChildren()) do
				if v59:IsA("Frame") and v59.Visible == true then
					v59:Destroy()
				end
			end
			local v60 = p58.Data.Enchantments
			for v61, v62 in pairs(v60) do
				local v63 = v_u_41:Clone()
				v63.Parent = v_u_40
				v63.Visible = true
				v63.Name = v61
				local v64 = v63:WaitForChild("BTN"):WaitForChild("Icon")
				if v62.Type then
					v64.Image = v_u_17:GetDebuffIcon(v62.Type)
				else
					v64.Image = ""
				end
			end
		end
		local v65 = v_u_51.Conns
		local v66 = v_u_13
		local v67 = v_u_2
		local v68 = { v_u_4.EquipmentUtil.Equipment, v_u_4.EquipmentUtil.Owned, p_u_27.UUID }
		table.insert(v65, v66:ListenFor(v67, v68, function()
			-- upvalues: (copy) v_u_51
			v_u_51:UpdateEnchantmentSlot()
		end))
		function v_u_51.Destroy(p69) -- name: Destroy
			-- upvalues: (ref) v_u_20
			p69.GUI:Destroy()
			for _, v70 in pairs(p69.Conns) do
				v70:Disconnect()
			end
			table.clear(p69.Conns)
			v_u_20[p69.UUID] = nil
		end
		v_u_51:SetEquiped(v_u_13:GetValue(v_u_2, { "Equipment", "Equipped", v_u_51.UUID }) or false)
		local v71
		if v_u_3:GetAttribute("Cur") == v_u_51.CheckVisible then
			v71 = v_u_9:GetAttribute("Cur") == 0 and true or v_u_9:GetAttribute("Cur") == v_u_51.Rarity
		else
			v71 = false
		end
		v_u_51:SetVisible(v71)
		v_u_51:UpdateEnchantmentSlot()
		v_u_51:Refresh()
		v_u_20[v_u_51.UUID] = v_u_51
	end
end
local function v_u_86() -- name: UpdateLayoutOrder
	-- upvalues: (copy) v_u_3, (copy) v_u_20, (copy) v_u_14, (copy) v_u_2
	local v73 = v_u_3:GetAttribute("Cur")
	if v73 then
		local v74 = {}
		for _, v75 in pairs(v_u_20) do
			if v75.IsVisible then
				table.insert(v74, v75)
			end
		end
		if v73 == "Weapon" then
			table.sort(v74, function(p76, p77)
				-- upvalues: (ref) v_u_14, (ref) v_u_2
				local v78 = v_u_14:GetDmgOrHpByInfo(v_u_2, p76.Data, p76.Def)
				local v79 = v_u_14:GetDmgOrHpByInfo(v_u_2, p77.Data, p77.Def)
				if v78 == v79 then
					if p76.Rarity == p77.Rarity then
						return p76.Def.Sort < p77.Def.Sort
					else
						return p76.Rarity > p77.Rarity
					end
				else
					return v79 < v78
				end
			end)
		else
			table.sort(v74, function(p80, p81)
				-- upvalues: (ref) v_u_14, (ref) v_u_2
				local v82 = v_u_14:GetDmgOrHpByInfo(v_u_2, p80.Data, p80.Def)
				local v83 = v_u_14:GetDmgOrHpByInfo(v_u_2, p81.Data, p81.Def)
				if v82 == v83 then
					if p80.Rarity == p81.Rarity then
						return p80.Def.Sort < p81.Def.Sort
					else
						return p80.Rarity > p81.Rarity
					end
				else
					return v83 < v82
				end
			end)
		end
		for v84, v85 in ipairs(v74) do
			v85:SetOrder(v84)
		end
	end
end
local function v_u_93() -- name: UpdateList
	-- upvalues: (copy) v_u_13, (copy) v_u_2, (copy) v_u_15, (copy) v_u_20, (copy) v_u_72, (copy) v_u_86
	local v87 = v_u_13:GetValue(v_u_2, { "Equipment", "Owned" }) or {}
	local v88 = v_u_13:GetValue(v_u_2, { "Equipment", "EquipSlots" }) or {}
	local v89 = {}
	for v90, v91 in pairs(v87) do
		v89[v90] = 1
		if not v_u_15:IsTimeLimited(v91) and (v91.Type == "Weapon" and (v90 ~= v88.Weapon and (v90 ~= v88.Weapon2 and not v_u_20[v90]))) then
			v_u_72(v91)
		end
	end
	for _, v92 in pairs(v_u_20) do
		if v89[v92.UUID] then
			if v92.UUID == v88.Weapon or v92.UUID == v88.Weapon2 then
				v92:Destroy()
			end
		else
			v92:Destroy()
		end
	end
	v_u_86()
end
local function v_u_99() -- name: UpdateEquiped
	-- upvalues: (copy) v_u_13, (copy) v_u_2, (copy) v_u_20
	local v94 = v_u_13:GetValue(v_u_2, { "Equipment", "Equipped" }) or {}
	for v95, v96 in pairs(v_u_20) do
		local v97 = false
		for v98, _ in pairs(v94) do
			if v98 == v95 then
				v97 = true
			end
		end
		v96:SetEquiped(v97)
	end
end
local function v_u_104() -- name: GetFirst
	-- upvalues: (ref) v_u_21, (copy) v_u_20
	if not (v_u_21 and (v_u_20[v_u_21] and v_u_20[v_u_21].IsVisible)) then
		local v100 = (1 / 0)
		local v101 = nil
		for v102, v103 in pairs(v_u_20) do
			if v103.IsVisible and v103.Order < v100 then
				v100 = v103.Order
				v101 = v102
			end
		end
		v_u_21 = v101
	end
end
local function v_u_109() -- name: UpdateVisible
	-- upvalues: (copy) v_u_3, (copy) v_u_9, (copy) v_u_20, (copy) v_u_86, (copy) v_u_104, (copy) v_u_26, (ref) v_u_21, (ref) v_u_22, (copy) v_u_5
	if v_u_3.Visible then
		local v105 = v_u_3:GetAttribute("Cur")
		if v105 then
			local v106 = v_u_9:GetAttribute("Cur")
			for _, v107 in pairs(v_u_20) do
				if v106 == 0 then
					v107:SetVisible(v107.CheckVisible == v105)
				else
					local v108
					if v107.CheckVisible == v105 then
						v108 = v107.Rarity == v106
					else
						v108 = false
					end
					v107:SetVisible(v108)
				end
			end
			v_u_86()
			v_u_104()
			v_u_26(v_u_21)
			v_u_22 = v105
		end
		v_u_5:SetAttribute("ForceUpdate", true)
	end
end
(function() -- name: Init
	-- upvalues: (copy) v_u_13, (copy) v_u_2, (copy) v_u_93, (copy) v_u_99, (copy) v_u_4, (copy) v_u_86, (copy) v_u_3, (copy) v_u_109, (copy) v_u_9
	v_u_13:GetPlayerData(v_u_2)
	local v_u_110 = nil
	v_u_13:ListenFor(v_u_2, { "Equipment", "Owned" }, function(_, _, ...)
		-- upvalues: (ref) v_u_110, (ref) v_u_93
		if v_u_110 then
			task.cancel(v_u_110)
		end
		v_u_110 = task.spawn(function()
			-- upvalues: (ref) v_u_110, (ref) v_u_93
			task.wait(0.1)
			v_u_110 = nil
			v_u_93()
		end)
	end)
	if v_u_110 then
		task.cancel(v_u_110)
	end
	v_u_110 = task.spawn(function()
		-- upvalues: (ref) v_u_110, (ref) v_u_93
		task.wait(0.1)
		v_u_110 = nil
		v_u_93()
	end)
	v_u_13:ListenFor(v_u_2, { "Equipment", "Equipped" }, function(_, _, ...)
		-- upvalues: (ref) v_u_99
		v_u_99()
	end)
	v_u_99()
	v_u_13:ListenFor(v_u_2, { v_u_4.EquipmentUtil.Equipment, v_u_4.EquipmentUtil.Owned }, v_u_86)
	v_u_3:GetAttributeChangedSignal("Cur"):Connect(v_u_109)
	v_u_9:GetAttributeChangedSignal("Cur"):Connect(v_u_109)
	v_u_109()
end)()
v8.MouseButton1Down:Connect(function()
	-- upvalues: (ref) v_u_21, (copy) v_u_14, (copy) v_u_2, (copy) v_u_16
	if v_u_21 then
		v_u_14:RequestSetExtraWeapon(v_u_2, v_u_21)
		v_u_16:Close("ScreenExtraWeaponSelect")
	end
end)
v_u_3:GetPropertyChangedSignal("Visible"):Connect(function()
	-- upvalues: (copy) v_u_3, (copy) v_u_109, (copy) v_u_7, (copy) v_u_20, (ref) v_u_21, (copy) v_u_26
	if v_u_3.Visible then
		v_u_109()
		v_u_7.Visible = true
		local v111 = (1 / 0)
		local v112 = nil
		for v113, v114 in pairs(v_u_20) do
			if v114.IsVisible and v114.Order < v111 then
				v111 = v114.Order
				v112 = v113
			end
		end
		v_u_21 = v112
		v_u_26(v_u_21)
	else
		v_u_21 = nil
	end
end)
v19.Event:Connect(function(p115)
	-- upvalues: (copy) v_u_109, (copy) v_u_3, (copy) v_u_104, (copy) v_u_26, (ref) v_u_21
	if p115 == "Open" then
		v_u_109()
		if v_u_3.Visible then
			v_u_104()
			v_u_26(v_u_21)
		end
	end
end)

# Inventory for extra wepaon
local Event = game:GetService("ReplicatedStorage").Framework.Features.TaskSystem.TaskRE
Event:FireServer(
    "UpdateTaskProgress",
    "OpenGUIWindow",
    "ScreenExtraWeaponSelect",
    nil
)

# Decompiled Script for it
local v1 = require(game.ReplicatedStorage:WaitForChild("Framework"))
local v_u_2 = game.Players.LocalPlayer
local v_u_3 = script.Parent
local v_u_4 = v_u_3:WaitForChild("Frame")
local v_u_5 = v_u_4:WaitForChild("ItemTemplate")
v_u_5.Parent = script
local v6 = v_u_3:WaitForChild("StartButton")
local v_u_7 = v1.Modules.DataUtil
local v_u_8 = v1.Modules.EquipmentUtil
local v_u_9 = v1.Modules.WindowUtil
local v_u_10 = v1.Modules.TranslationUtil
local v_u_11 = v1.Modules.RarityTiers
local v_u_12 = v1.Modules.DebuffUtil
local v_u_13 = require(game.ReplicatedStorage:WaitForChild("Utility"):WaitForChild("UniqueTypeUtil"))
local v_u_14 = require(game.ReplicatedStorage:WaitForChild("Enum"):WaitForChild("KeyString"))
local v_u_15 = {}
local function v_u_52(p16, p17, p18) -- name: buildSlot
	-- upvalues: (copy) v_u_5, (copy) v_u_4, (copy) v_u_7, (copy) v_u_2, (copy) v_u_8, (copy) v_u_13, (copy) v_u_11, (copy) v_u_10, (copy) v_u_12, (copy) v_u_14, (copy) v_u_9, (copy) v_u_15
	local v19 = v_u_5:Clone()
	v19.Parent = v_u_4
	v19.LayoutOrder = p16
	v19.Name = "Slot" .. tostring(p16)
	v19.Visible = true
	local v20 = v19:WaitForChild("BTN")
	local v21 = v19:WaitForChild("Empty")
	local v22 = {}
	if p17 then
		local v_u_23 = v_u_7:GetValue(v_u_2, { "Equipment", "Owned", p17 })
		local v_u_24 = v_u_23 and v_u_8:GetDef(v_u_23.ID)
		if v_u_24 then
			v20.Visible = true
			v21.Visible = false
			local v25 = v20:WaitForChild("Icon")
			local v_u_26 = v20:WaitForChild("Name")
			local v27 = v20:WaitForChild("Stat")
			local v_u_28 = v27:WaitForChild("Price")
			local v_u_29 = v27:WaitForChild("Attr")
			local v30 = v20:WaitForChild("Bg")
			local v31 = v20:WaitForChild("Selected")
			local v32 = v20:WaitForChild("Equipped")
			local v_u_33 = v20:WaitForChild("Level")
			local v34 = v20:WaitForChild("IsHell")
			local v_u_35 = v20:WaitForChild("EnchantmentSlot")
			local v_u_36 = v_u_35:WaitForChild("Item")
			v_u_36.Visible = false
			v25.Image = v_u_24.Icon
			v_u_13:Apply(v20, v_u_24.UniqueType)
			v34.Visible = v_u_24.IsHell
			v32.Visible = false
			local v37 = v_u_8:GetOreRarity(v_u_23.MaxOre)
			v_u_11:ApplyColor(v30, v37)
			v_u_11:ApplySelectColor(v31, v37)
			v_u_11:ApplyTextColor(v_u_26, v37)
			local function v39() -- name: refreshDisplay
				-- upvalues: (copy) v_u_28, (ref) v_u_8, (copy) v_u_23, (copy) v_u_24, (copy) v_u_29, (ref) v_u_10, (ref) v_u_2, (copy) v_u_26, (copy) v_u_33
				v_u_28.Text = string.format("%d $", v_u_8:GetPriceByInfo(v_u_23, v_u_24))
				v_u_29.Text = v_u_10:TranslateByKey(v_u_24.Type == "Weapon" and "K_DMG" or "K_HP") .. ":" .. v_u_8:GetDmgOrHpByInfo(v_u_2, v_u_23, v_u_24)
				local v38 = v_u_23.Fortify and v_u_23.Fortify - 1 or 0
				v_u_26.Text = v_u_10:TranslateByKey("K_" .. string.upper(v_u_24.ID)) .. (v38 > 0 and string.format("(+%d)", v38) or "")
				v_u_33.Text = string.format("Lv.%d", v_u_8:GetLvByInfo(v_u_23, v_u_24)) .. (v_u_24.WJB and " (" .. v_u_10:TranslateByKey("K_REQUIRE_WJB") .. ")" or "")
			end
			local function v46() -- name: updateEnchantmentSlot
				-- upvalues: (copy) v_u_35, (copy) v_u_23, (copy) v_u_36, (ref) v_u_12
				for _, v40 in pairs(v_u_35:GetChildren()) do
					if v40:IsA("Frame") and v40.Visible == true then
						v40:Destroy()
					end
				end
				local v41 = v_u_23.Enchantments
				for v42, v43 in pairs(v41) do
					local v44 = v_u_36:Clone()
					v44.Parent = v_u_35
					v44.Visible = true
					v44.Name = v42
					local v45 = v44:WaitForChild("BTN"):WaitForChild("Icon")
					if v43.Type then
						v45.Image = v_u_12:GetDebuffIcon(v43.Type)
					else
						v45.Image = ""
					end
				end
			end
			v39()
			v46()
			local v47 = v_u_7
			local v48 = v_u_2
			table.insert(v22, v47:ListenFor(v48, { "Equipment", "Owned" }, v39))
			local v49 = v_u_7
			local v50 = v_u_2
			local v51 = { v_u_14.EquipmentUtil.Equipment, v_u_14.EquipmentUtil.Owned, v_u_23.UUID }
			table.insert(v22, v49:ListenFor(v50, v51, v46))
		end
	elseif p18 then
		v20.Visible = false
		v21.Visible = true
		v21.MouseButton1Down:Connect(function()
			-- upvalues: (ref) v_u_9
			v_u_9:Open("ScreenExtraWeaponSelect", nil, true)
		end)
	else
		v19.Visible = false
	end
	v_u_15[p16] = {
		["item"] = v19,
		["conns"] = v22
	}
end
local function v_u_58() -- name: refresh
	-- upvalues: (copy) v_u_15, (copy) v_u_7, (copy) v_u_2, (copy) v_u_52
	for v53, v54 in pairs(v_u_15) do
		if v54 then
			for _, v55 in pairs(v54.conns) do
				v55:Disconnect()
			end
			v54.item:Destroy()
			v_u_15[v53] = nil
		end
	end
	local v56 = v_u_7:GetValue(v_u_2, { "Equipment", "EquipSlots" }) or {}
	local v57 = v_u_2:GetAttribute("ExtraWeaponUUID")
	v_u_52(1, v56.Weapon, false)
	v_u_52(2, v56.Weapon2, false)
	v_u_52(3, v57, true)
end
v_u_7:ListenFor(v_u_2, { "Equipment", "EquipSlots" }, function()
	-- upvalues: (copy) v_u_58
	v_u_58()
end)
v_u_2:GetAttributeChangedSignal("ExtraWeaponUUID"):Connect(function()
	-- upvalues: (copy) v_u_58
	v_u_58()
end)
v6.MouseButton1Down:Connect(function()
	-- upvalues: (copy) v_u_9
	v_u_9:Close("ScreenExtraWeapon")
end)
v_u_3:GetPropertyChangedSignal("Visible"):Connect(function()
	-- upvalues: (copy) v_u_3, (copy) v_u_58
	if v_u_3.Visible then
		v_u_58()
	end
end)
v_u_58()