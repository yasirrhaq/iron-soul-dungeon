local v1 = require(game.ReplicatedStorage:WaitForChild("Framework"))
local v_u_2 = game.Players.LocalPlayer
local v_u_3 = script.Parent
local v_u_4 = v_u_3:WaitForChild("ScrollingFrame")
local v_u_5 = v_u_4:WaitForChild("ItemTemplate")
v_u_5.Parent = script
local v_u_6 = v_u_3.Parent:WaitForChild("ControlFrame")
local v_u_7 = v_u_6:WaitForChild("BtnFrame"):WaitForChild("EquipBest")
local v_u_8 = v_u_6:WaitForChild("BtnFrame"):WaitForChild("FilterBtn")
local v_u_9 = v_u_6:WaitForChild("Capacity")
local v_u_10 = v_u_3.Parent:WaitForChild("Info"):WaitForChild("InfoBE")
local v11 = v_u_3.Parent.Parent:WaitForChild("BackpackBE")
local v_u_12 = v1.Modules.TranslationUtil
local v_u_13 = v1.Modules.RarityTiers
local v_u_14 = v1.Modules.DataUtil
local v_u_15 = v1.Modules.ForgeUtil
local v_u_16 = v1.Modules.RedPointUtil
local v_u_17 = v1.Modules.PurchasablesUtil
local v_u_18 = {}
local v_u_19 = nil
local function v_u_23(p20) -- name: UpdateSelected
	-- upvalues: (copy) v_u_18, (ref) v_u_19, (copy) v_u_10
	for v21, v22 in pairs(v_u_18) do
		v22:SetSelected(v21 == p20)
	end
	v_u_19 = p20
	v_u_10:Fire("Ores", p20)
end
local function v_u_53(p24, p25) -- name: AddItem
	-- upvalues: (copy) v_u_15, (copy) v_u_5, (copy) v_u_4, (copy) v_u_12, (copy) v_u_13, (copy) v_u_23, (copy) v_u_16, (copy) v_u_2, (copy) v_u_14, (copy) v_u_18, (copy) v_u_8
	local v26 = v_u_15:GetDef(p24)
	if v26 then
		local v_u_27 = v_u_5:Clone()
		v_u_27.Parent = v_u_4
		v_u_27.Name = p24
		local v28 = v_u_27:WaitForChild("BTN")
		local v29 = v28:WaitForChild("Name")
		local v_u_30 = v28:WaitForChild("Count")
		local v31 = v28:WaitForChild("Bg")
		local v_u_32 = v28:WaitForChild("Selected")
		local v33 = v28:WaitForChild("VPF")
		local v_u_34 = v28:WaitForChild("Notify")
		local v35 = v28:WaitForChild("IsHell")
		v29.Text = v_u_12:TranslateByKey("K_" .. string.upper(v26.ID))
		v35.Visible = v26.Hellweight > 0
		v_u_15:SetOreViewport(v33, p24)
		v_u_13:ApplyColor(v31, v26.Rarity)
		v_u_13:ApplySelectColor(v_u_32, v26.Rarity)
		local v_u_43 = {
			["ID"] = p24,
			["Count"] = p25,
			["Def"] = v26,
			["Conns"] = {},
			["GUI"] = v_u_27,
			["SetOrder"] = function(p36, p37) -- name: SetOrder
				-- upvalues: (copy) v_u_27
				v_u_27.LayoutOrder = p37
				p36.Order = p37
			end,
			["SetVisible"] = function(p38, p39) -- name: SetVisible
				-- upvalues: (copy) v_u_27
				v_u_27.Visible = p39
				p38.IsVisible = p39
			end,
			["SetSelected"] = function(p40, p41) -- name: SetSelected
				-- upvalues: (copy) v_u_32
				v_u_32.Visible = p41
				p40.Selected = p41
			end,
			["OnTrigger"] = function(p42) -- name: OnTrigger
				-- upvalues: (ref) v_u_23, (ref) v_u_16, (ref) v_u_2
				v_u_23(p42.ID)
				v_u_16:Clear(v_u_2, "Ores", p42.ID)
			end
		}
		local v44 = v_u_43.Conns
		local v45 = v28.MouseButton1Down
		table.insert(v44, v45:Connect(function()
			-- upvalues: (copy) v_u_43
			v_u_43:OnTrigger()
		end))
		function v_u_43.Refresh(p46) -- name: Refresh
			-- upvalues: (copy) v_u_30
			v_u_30.Text = string.format("x%d", p46.Count)
		end
		function v_u_43.UpdateNotify(p47) -- name: UpdateNotify
			-- upvalues: (ref) v_u_16, (ref) v_u_2, (copy) v_u_34
			v_u_34.Visible = v_u_16:Has(v_u_2, "Ores", p47.ID)
		end
		local v48 = v_u_43.Conns
		local v49 = v_u_14
		local v50 = v_u_2
		table.insert(v48, v49:ListenFor(v50, { "RedPoints", "Ores" }, function()
			-- upvalues: (copy) v_u_43
			v_u_43:UpdateNotify()
		end))
		function v_u_43.Destroy(p51) -- name: Destroy
			-- upvalues: (ref) v_u_16, (ref) v_u_2, (ref) v_u_18
			p51.GUI:Destroy()
			for _, v52 in pairs(p51.Conns) do
				v52:Disconnect()
			end
			table.clear(p51.Conns)
			v_u_16:Clear(v_u_2, "Ores", p51.ID)
			v_u_18[p51.ID] = nil
		end
		v_u_43:Refresh()
		v_u_43:SetVisible(v_u_8:GetAttribute("Cur") == 0 and true or v_u_43.Def.Rarity == v_u_8:GetAttribute("Cur"))
		v_u_43:UpdateNotify()
		v_u_18[v_u_43.ID] = v_u_43
	end
end
local function v_u_58() -- name: GetFirst
	-- upvalues: (ref) v_u_19, (copy) v_u_18
	if not (v_u_19 and (v_u_18[v_u_19] and v_u_18[v_u_19].IsVisible)) then
		local v54 = (1 / 0)
		local v55 = nil
		for v56, v57 in pairs(v_u_18) do
			if v57.IsVisible and v57.Order < v54 then
				v54 = v57.Order
				v55 = v56
			end
		end
		v_u_19 = v55
	end
end
local function v_u_61() -- name: UpdateCapacity
	-- upvalues: (copy) v_u_3, (copy) v_u_18, (copy) v_u_9, (copy) v_u_12, (copy) v_u_15, (copy) v_u_2
	if v_u_3.Visible then
		local v59 = 0
		for _, v60 in pairs(v_u_18) do
			v59 = v59 + v60.Count
		end
		v_u_9.Text = v_u_12:TranslateByKey("K_CAPACITY") .. ":" .. string.format("%d/%d", v59, v_u_15:GetMax(v_u_2))
	end
end
local function v_u_68() -- name: UpdateLayoutOrder
	-- upvalues: (copy) v_u_18
	local v62 = {}
	for _, v63 in pairs(v_u_18) do
		if v63.IsVisible then
			table.insert(v62, v63)
		end
	end
	table.sort(v62, function(p64, p65)
		if p64.Def.Rarity == p65.Def.Rarity then
			return p64.Def.Sort < p65.Def.Sort
		else
			return p64.Def.Rarity > p65.Def.Rarity
		end
	end)
	for v66, v67 in ipairs(v62) do
		v67:SetOrder(v66)
	end
end
local function v_u_71() -- name: UpdateVisible
	-- upvalues: (copy) v_u_3, (copy) v_u_8, (copy) v_u_18, (copy) v_u_68, (copy) v_u_58, (copy) v_u_23, (ref) v_u_19, (copy) v_u_4
	if v_u_3.Visible then
		local v69 = v_u_8:GetAttribute("Cur")
		for _, v70 in pairs(v_u_18) do
			if v69 == 0 then
				v70:SetVisible(true)
			else
				v70:SetVisible(v69 == v70.Def.Rarity)
			end
		end
		v_u_68()
		v_u_58()
		v_u_23(v_u_19)
		v_u_4:SetAttribute("ForceUpdate", true)
	end
end
local function v_u_77() -- name: UpdateList
	-- upvalues: (copy) v_u_14, (copy) v_u_2, (copy) v_u_18, (copy) v_u_53, (copy) v_u_71
	local v72 = v_u_14:GetValue(v_u_2, { "Ores" }) or {}
	local v73 = {}
	for v74, v75 in pairs(v72) do
		if v75 > 0 then
			v73[v74] = 1
			if v_u_18[v74] then
				if v_u_18[v74].Count ~= v75 then
					v_u_18[v74].Count = v75
					v_u_18[v74]:Refresh()
				end
			else
				v_u_53(v74, v75)
			end
		end
	end
	for _, v76 in pairs(v_u_18) do
		if not v73[v76.ID] then
			v76:Destroy()
		end
	end
	v_u_71()
end
(function() -- name: Init
	-- upvalues: (copy) v_u_14, (copy) v_u_2, (copy) v_u_77, (copy) v_u_61, (copy) v_u_8, (copy) v_u_71, (copy) v_u_17
	v_u_14:GetPlayerData(v_u_2)
	local v_u_78 = nil
	v_u_14:ListenFor(v_u_2, { "Ores" }, function(_, _, ...)
		-- upvalues: (ref) v_u_78, (ref) v_u_77, (ref) v_u_61
		if v_u_78 then
			task.cancel(v_u_78)
		end
		v_u_78 = task.spawn(function()
			-- upvalues: (ref) v_u_78, (ref) v_u_77, (ref) v_u_61
			task.wait(0.1)
			v_u_78 = nil
			v_u_77()
			v_u_61()
		end)
	end)
	if v_u_78 then
		task.cancel(v_u_78)
	end
	v_u_78 = task.spawn(function()
		-- upvalues: (ref) v_u_78, (ref) v_u_77, (ref) v_u_61
		task.wait(0.1)
		v_u_78 = nil
		v_u_77()
		v_u_61()
	end)
	v_u_8:GetAttributeChangedSignal("Cur"):Connect(v_u_71)
	v_u_71()
	v_u_17.OnPurchased:Connect(function(_, p79)
		-- upvalues: (ref) v_u_61
		if p79 and (p79.Id == "OresBackpack1" or (p79.Id == "OresAndMaterialBackpack1" or p79.Id == "SuperVIP")) then
			v_u_61()
		end
	end)
end)()
v_u_3:GetPropertyChangedSignal("Visible"):Connect(function()
	-- upvalues: (copy) v_u_3, (copy) v_u_71, (copy) v_u_7, (copy) v_u_6, (copy) v_u_61
	if v_u_3.Visible then
		v_u_71()
		v_u_7.Visible = false
		v_u_6.Visible = true
		v_u_61()
	end
end)
v11.Event:Connect(function(p80, ...)
	-- upvalues: (copy) v_u_3, (copy) v_u_71, (copy) v_u_61
	if p80 == "Open" and v_u_3.Visible then
		v_u_71()
		v_u_61()
	end
end)

-- // Function Dumper made by King.Kevin
-- // Script Path: Players.bxgon24.PlayerGui.MainGui.ScreenBackpack.InventoryFrame.OresContent.OresContent

--[[
Function Dump: Unknown Name

Function Upvalues: Unknown Name
		1 [table]:
		1 [table] table: 0x0cefa768b8e23ed9
				1 [function] = Destroy
				2 [boolean] = true
				3 [function] = UpdateNotify
				4 [table]:
				Def [table] table: 0xa829d123c31f3739
						1 [number] = 1
						2 [number] = 6
						3 [number] = 220
						4 [number] = 0
						5 [number] = 1
						6 [number] = 76
						7 [string] = Apocalypse
						8 [string] = Plastic
						9 [boolean] = true
						10 [number] = 6
				5 [table]:
				Conns [table] table: 0x33a13a14c46ead89
						1 [RBXScriptConnection] = Connection
						2 [table]:
						2 [table] table: 0x7db31fd6a28c9319
								1 [function] = Unknown Name
								2 [boolean] = true
								3 [table]:
								_signal [table] table: 0x1b58683594ec4d29
										1 [table]:
										_connections [table] table: 0x04a28cbbe79739d9
												1 [table]:
												1 [table] table: 0x0ded16bdc9ba0489
														1 [function] = Unknown Name
														2 [boolean] = true
														3 [table] (Recursive table detected)
												2 [table]:
												2 [table] table: 0x2be87a82d1ae0be9
														1 [function] = Unknown Name
														2 [boolean] = true
														3 [table] (Recursive table detected)
												3 [table]:
												3 [table] table: 0xd452d24382f47ce9
														1 [function] = Unknown Name
														2 [boolean] = true
														3 [table] (Recursive table detected)
												4 [table]:
												4 [table] table: 0x838303cc1d08dc99
														1 [function] = Unknown Name
														2 [boolean] = true
														3 [table] (Recursive table detected)
												5 [table]:
												5 [table] table: 0xfed04d497f2da4c9
														1 [function] = Unknown Name
														2 [boolean] = true
														3 [table] (Recursive table detected)
												6 [table]:
												6 [table] table: 0xede0a4bb5ccf9539
														1 [function] = Unknown Name
														2 [boolean] = true
														3 [table] (Recursive table detected)
												7 [table]:
												7 [table] table: 0x0131fcdc3168f2a9
														1 [function] = Unknown Name
														2 [boolean] = true
														3 [table] (Recursive table detected)
												8 [table]:
												8 [table] table: 0x29b7a07fe2a93da9
														1 [function] = Unknown Name
														2 [boolean] = true
														3 [table] (Recursive table detected)
												9 [table]:
												9 [table] table: 0xb4e81192fd42dd59
														1 [function] = Unknown Name
														2 [boolean] = true
														3 [table] (Recursive table detected)
												10 [table]:
												10 [table] table: 0x8028c331dfef7509
														1 [function] = Unknown Name
														2 [boolean] = true
														3 [table] (Recursive table detected)
												11 [table]:
												11 [table] table: 0xab59b2aebd081579
														1 [function] = Unknown Name
														2 [boolean] = true
														3 [table] (Recursive table detected)
												12 [table]:
												12 [table] table: 0xde9a66eb10d32c69
														1 [function] = Unknown Name
														2 [boolean] = true
														3 [table] (Recursive table detected)
												13 [table]:
												13 [table] table: 0x00e3966c4263ff69
														1 [function] = Unknown Name
														2 [boolean] = true
														3 [table] (Recursive table detected)
												14 [table] (Recursive table detected)
												15 [table]:
												15 [table] table: 0xb5e36c980449d449
														1 [function] = updateRedPoint
														2 [boolean] = true
														3 [table] (Recursive table detected)
												16 [table]:
												16 [table] table: 0x0bfcf89c807d4ed9
														1 [function] = updateRedPoint
														2 [boolean] = true
														3 [table] (Recursive table detected)
												17 [table]:
												17 [table] table: 0xf12bb40e2f61e0d9
														1 [function] = updateRedPoint
														2 [boolean] = true
														3 [table] (Recursive table detected)
				6 [function] = Refresh
				7 [function] = SetVisible
				8 [number] = 1
				9 [Instance] = Apocalypse
				10 [number] = 27
				11 [function] = SetOrder
				12 [string] = Apocalypse
				13 [boolean] = true
				14 [function] = SetSelected
				15 [function] = OnTrigger

Function Constants: Unknown Name
		1 [string] = UpdateNotify

====================================================================================================

Function Dump: Refresh

Function Upvalues: Refresh
		1 [Instance] = Count

Function Constants: Refresh
		1 [string] = string
		2 [string] = format
		4 [string] = x%d
		5 [string] = Count
		6 [string] = Text

====================================================================================================

Function Dump: Unknown Name

Function Upvalues: Unknown Name
		1 [table] (Recursive table detected)

Function Constants: Unknown Name
		1 [string] = OnTrigger

====================================================================================================

Function Dump: SetSelected

Function Upvalues: SetSelected
		1 [Instance] = Selected

Function Constants: SetSelected
		1 [string] = Visible
		2 [string] = Selected

====================================================================================================

Function Dump: SetVisible

Function Upvalues: SetVisible
		1 [Instance] = Apocalypse

Function Constants: SetVisible
		1 [string] = Visible
		2 [string] = IsVisible

====================================================================================================

Function Dump: SetOrder

Function Upvalues: SetOrder
		1 [Instance] = Apocalypse

Function Constants: SetOrder
		1 [string] = LayoutOrder
		2 [string] = Order

====================================================================================================

Function Dump: Unknown Name

Function Upvalues: Unknown Name
		1 [table]:
		1 [table] table: 0x21a4cd2bc5795129
				1 [function] = Destroy
				2 [boolean] = true
				3 [function] = UpdateNotify
				4 [table]:
				Def [table] table: 0x7718368640a388d9
						1 [number] = 1
						2 [number] = 6
						3 [number] = 124
						4 [number] = 0
						5 [number] = 6
						6 [number] = 63
						7 [string] = Gwindel
						8 [string] = Plastic
						9 [boolean] = true
						10 [number] = 6
				5 [table]:
				Conns [table] table: 0x3f71e6a9d82dedd9
						1 [RBXScriptConnection] = Connection
						2 [table] (Recursive table detected)
				6 [function] = Refresh
				7 [function] = SetVisible
				8 [number] = 4
				9 [Instance] = Gwindel
				10 [number] = 100
				11 [function] = SetOrder
				12 [string] = Gwindel
				13 [boolean] = false
				14 [function] = SetSelected
				15 [function] = OnTrigger

Function Constants: Unknown Name
		1 [string] = UpdateNotify

====================================================================================================

Function Dump: Refresh

Function Upvalues: Refresh
		1 [Instance] = Count

Function Constants: Refresh
		1 [string] = string
		2 [string] = format
		4 [string] = x%d
		5 [string] = Count
		6 [string] = Text

====================================================================================================

Function Dump: Unknown Name

Function Upvalues: Unknown Name
		1 [table] (Recursive table detected)

Function Constants: Unknown Name
		1 [string] = OnTrigger

====================================================================================================

Function Dump: SetSelected

Function Upvalues: SetSelected
		1 [Instance] = Selected

Function Constants: SetSelected
		1 [string] = Visible
		2 [string] = Selected

====================================================================================================

Function Dump: SetVisible

Function Upvalues: SetVisible
		1 [Instance] = Gwindel

Function Constants: SetVisible
		1 [string] = Visible
		2 [string] = IsVisible

====================================================================================================

Function Dump: SetOrder

Function Upvalues: SetOrder
		1 [Instance] = Gwindel

Function Constants: SetOrder
		1 [string] = LayoutOrder
		2 [string] = Order

====================================================================================================

Function Dump: Unknown Name

Function Upvalues: Unknown Name
		1 [table]:
		1 [table] table: 0xc802af2af4c88429
				1 [function] = Destroy
				2 [boolean] = true
				3 [function] = UpdateNotify
				4 [table]:
				Def [table] table: 0x5e7a9a12c2d05d79
						1 [number] = 1
						2 [number] = 4
						3 [number] = 80
						4 [number] = 0
						5 [number] = 12
						6 [number] = 42
						7 [string] = Romanstone
						8 [string] = Plastic
				