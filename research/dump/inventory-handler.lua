local v_u_1 = {
	["ToolItems"] = {},
	["ToolInventory"] = {}
}
local v_u_2 = game:GetService("Players").LocalPlayer
local v_u_3 = v_u_2:WaitForChild("Backpack")
local v_u_4 = game:GetService("ContextActionService")
local v_u_5 = game:GetService("TextService")
local v_u_6 = game:GetService("UserInputService")
game:GetService("RunService")
local v_u_7 = v_u_2:WaitForChild("PlayerGui")
local v_u_8 = v_u_2:GetMouse()
local v_u_9 = script.Parent.Parent
local v_u_10 = v_u_9:WaitForChild("Root"):WaitForChild("ItemsBar"):WaitForChild("ItemSlot")
v_u_10.Visible = false
local v11 = v_u_9:WaitForChild("Root")
local v_u_12 = v11:WaitForChild("ItemsBar")
local v_u_13 = v11:WaitForChild("Inventory")
local v_u_14 = v_u_13:WaitForChild("SearchBox")
local v_u_15 = v_u_13:WaitForChild("Frame")
local v_u_16 = v_u_13:WaitForChild("LimitCount")
local v_u_17 = v_u_15:WaitForChild("UIGridLayout")
local v_u_18 = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
	Enum.KeyCode.Zero
}
if v_u_6.TouchEnabled then
	v_u_1.SlotAmount = 6
else
	v_u_1.SlotAmount = 10
end
local v_u_19 = 0
function v_u_1.UpdateInventoryCapacity(_) -- name: UpdateInventoryCapacity
	-- upvalues: (copy) v_u_14, (copy) v_u_2, (copy) v_u_1, (copy) v_u_16
	local v20 = v_u_14:GetAttribute("SearchKey")
	if not v20 or v20 == "All" then
		local v21 = v_u_2:GetAttribute("InventoryMaxCount")
		if v21 then
			local v22 = 0
			for _, _ in pairs(v_u_1.ToolItems) do
				v22 = v22 + 1
			end
			for _, _ in pairs(v_u_1.ToolInventory) do
				v22 = v22 + 1
			end
			v_u_16.Text = string.format("All Items (%s/%s)", v22, v21)
			return
		end
		v_u_16.Text = "All Items"
	end
end
local v_u_23 = {}
v_u_23.__index = v_u_23
function v_u_23.IsEquipped(p24, p25) -- name: IsEquipped
	-- upvalues: (copy) v_u_2
	local v26 = v_u_2.Character
	local v27 = p25 or p24.Tool
	if v26 then
		return v27.Parent == v_u_2.Character
	else
		return false
	end
end
function v_u_23.DisconnectAll(p28) -- name: DisconnectAll
	-- upvalues: (copy) v_u_12, (copy) v_u_4, (copy) v_u_1, (copy) v_u_15
	for _, v29 in pairs(p28.Connections) do
		v29:Disconnect()
	end
	p28.Frame:Destroy()
	if p28.Parent == v_u_12 and p28.Index then
		v_u_4:UnbindAction(p28.Index .. "ItemsBar")
		v_u_1.ToolItems[p28.Index] = nil
	elseif p28.Parent == v_u_15 then
		v_u_1.ToolInventory[p28.Serial] = nil
	end
end
function v_u_23.ShowDescription(p30) -- name: ShowDescription
	-- upvalues: (copy) v_u_9, (copy) v_u_5
	local v31 = p30.Tool.ToolTip
	local v32 = p30.Frame
	if v31 ~= "" then
		local v33 = Instance.new("TextLabel")
		v33.Name = "descriptionFrame"
		v33.AnchorPoint = Vector2.new(0.5, 0)
		v33.Font = Enum.Font.SourceSansSemibold
		v33.TextColor3 = Color3.new(1, 1, 1)
		v33.TextSize = 14
		v33.BorderSizePixel = 0
		v33.BackgroundColor3 = Color3.new(0, 0, 0)
		v33.BackgroundTransparency = 0.4
		v33.ZIndex = 99
		v33.TextWrapped = true
		v33.Parent = v_u_9
		local v34 = Instance.new("UICorner")
		v34.Parent = v33
		v34.CornerRadius = UDim.new(0.25, 0)
		local v35 = v_u_5:GetTextSize(v31, v33.TextSize, v33.Font, Vector2.new(400, 1000)) + Vector2.new(10, 4)
		v33.Size = UDim2.new(0, v35.X, 0, v35.Y)
		v33.Position = UDim2.new(0, v32.AbsolutePosition.X + v32.AbsoluteSize.X / 2, 0, v32.AbsolutePosition.Y - v35.Y - 2 + 57)
		v33.Text = v31
		p30.DescriptionFrame = v33
	end
end
function v_u_23.RemoveDescription(p36) -- name: RemoveDescription
	if p36.DescriptionFrame then
		p36.DescriptionFrame:Destroy()
	end
end
function v_u_1.RemoveCurrentDescription(_) -- name: RemoveCurrentDescription
	-- upvalues: (copy) v_u_9
	local v37 = v_u_9:FindFirstChild("descriptionFrame")
	if v37 then
		v37:Destroy()
	end
end
function v_u_1.SearchTool(p38) -- name: SearchTool
	-- upvalues: (copy) v_u_14
	local v39 = v_u_14.Text
	local v40 = v_u_14:GetAttribute("SearchKey")
	if v39 == "" then
		for _, v41 in pairs(p38.ToolInventory) do
			if v40 and v40 ~= "All" then
				v41.Frame.Visible = v40 == v41.ToolType
			else
				v41.Frame.Visible = true
			end
		end
	elseif v39 then
		for _, v42 in pairs(p38.ToolInventory) do
			if string.find(v42.Name:lower(), v39:lower()) then
				if v40 and v40 ~= "All" then
					v42.Frame.Visible = v40 == v42.ToolType
				else
					v42.Frame.Visible = true
				end
			else
				v42.Frame.Visible = false
			end
		end
	end
end
function v_u_1.HasTool(_, p43) -- name: HasTool
	-- upvalues: (copy) v_u_1
	if p43:IsA("Tool") then
		for _, v44 in pairs(v_u_1.ToolItems) do
			if v44.Tool == p43 then
				return true
			end
		end
		for _, v45 in pairs(v_u_1.ToolInventory) do
			if v45.Tool == p43 then
				return true
			end
		end
	end
end
function v_u_1.NewTool(_, p46) -- name: NewTool
	-- upvalues: (copy) v_u_1, (copy) v_u_15, (copy) v_u_12
	if not v_u_1:HasTool(p46) then
		local v47 = 0
		for _, _ in pairs(v_u_1.ToolItems) do
			v47 = v47 + 1
		end
		local v48
		if v_u_1.SlotAmount <= v47 then
			v48 = v_u_15
		else
			v48 = v_u_12
		end
		v_u_1:AddTool(p46, v48)
		v_u_1:UpdateInventoryCapacity()
	end
end
function v_u_1.GetIndexToNumber(_, p49) -- name: GetIndexToNumber
	if p49 then
		return p49 >= 10 and 0 or p49
	end
end
function v_u_1.CreatEmptyItem(_, p50, p51) -- name: CreatEmptyItem
	-- upvalues: (copy) v_u_10, (copy) v_u_1, (copy) v_u_12
	if p51 then
		local v52 = v_u_10:Clone()
		v52:WaitForChild("Name").Text = ""
		v52:WaitForChild("Number").Text = v_u_1:GetIndexToNumber(p50) or ""
		v52:WaitForChild("Quantity").Text = ""
		v52:WaitForChild("Icon").Image = ""
		v52:WaitForChild("Selected").Visible = false
		v52.Name = not p50 and "item" or tostring(p50)
		v52.LayoutOrder = p50 or 0
		v52.Parent = v_u_12
		v52.Visible = true
	end
end
function v_u_1.AddTool(p_u_53, p_u_54, p_u_55, p_u_56) -- name: AddTool
	-- upvalues: (copy) v_u_12, (copy) v_u_1, (copy) v_u_10, (copy) v_u_23, (ref) v_u_19, (copy) v_u_9, (copy) v_u_2, (copy) v_u_3, (copy) v_u_13, (copy) v_u_7, (copy) v_u_8, (copy) v_u_15, (copy) v_u_6, (copy) v_u_17, (copy) v_u_4, (copy) v_u_18
	local v57 = p_u_55 == v_u_12
	if v57 then
		if not p_u_56 then
			for v58 = 1, v_u_1.SlotAmount do
				if v_u_1.ToolItems[v58] == nil then
					p_u_56 = v58
					break
				end
			end
		end
		if not p_u_56 then
			return
		end
		local v59 = v_u_12:FindFirstChild(p_u_56)
		if v59 then
			v59:Destroy()
		end
	end
	local v_u_60 = v_u_10:Clone()
	local v61
	if v57 then
		v61 = p_u_56
	else
		v61 = p_u_54.Name
	end
	v_u_60.Name = v61
	v_u_60.Parent = p_u_55
	v_u_60.Visible = true
	local v_u_62 = v_u_60:WaitForChild("Selected")
	v_u_62.Visible = false
	local v_u_63 = v_u_60:WaitForChild("Icon")
	local v_u_64 = v_u_60:WaitForChild("Name")
	local function v65() -- name: updateToolInfo
		-- upvalues: (copy) v_u_64, (copy) p_u_54, (copy) v_u_63
		v_u_64.Text = p_u_54.Name
		v_u_64.Visible = p_u_54.TextureId == ""
		v_u_63.Image = p_u_54.TextureId
		v_u_63.Visible = p_u_54.TextureId ~= ""
	end
	v_u_64.Text = p_u_54.Name
	v_u_64.Visible = p_u_54.TextureId == ""
	v_u_63.Image = p_u_54.TextureId
	v_u_63.Visible = p_u_54.TextureId ~= ""
	local v_u_66 = {}
	local v67 = v_u_23
	setmetatable(v_u_66, v67)
	v_u_66.Tool = p_u_54
	v_u_66.Frame = v_u_60
	v_u_66.Parent = p_u_55
	v_u_66.Index = p_u_56
	v_u_66.Name = p_u_54.Name
	if p_u_54:GetAttribute("StumpId") then
		v_u_66.ToolType = "Stump"
	elseif p_u_54:GetAttribute("FruitId") then
		v_u_66.ToolType = "Fruit"
	end
	if v57 then
		v_u_60.LayoutOrder = p_u_56
		v_u_60:WaitForChild("Number").Text = v_u_1:GetIndexToNumber(p_u_56)
		v_u_1.ToolItems[p_u_56] = v_u_66
	else
		v_u_19 = v_u_19 + 1
		v_u_60.LayoutOrder = v_u_19
		v_u_60:WaitForChild("Number").Text = ""
		v_u_66.Serial = p_u_54.Name .. v_u_19
		v_u_1.ToolInventory[v_u_66.Serial] = v_u_66
	end
	local function v71(_, p68, p69) -- name: manageTool
		-- upvalues: (ref) v_u_9, (ref) v_u_2, (copy) p_u_54, (copy) v_u_66, (copy) v_u_62, (ref) v_u_1, (copy) v_u_60
		if v_u_9.Enabled then
			if p69 and (p69.UserInputType ~= Enum.UserInputType.Keyboard and p69.UserInputType ~= Enum.UserInputType.Touch) then
				return
			else
				local v70 = v_u_2.Character
				if v70 then
					v70 = v70:FindFirstChildOfClass("Humanoid")
				end
				if v70 and (v70.Health > 0 and (p_u_54.Parent and p68 ~= Enum.UserInputState.End)) then
					if v_u_66:IsEquipped() then
						v70:UnequipTools()
						v_u_62.Visible = false
						v_u_1.CurrSelectedFrame = nil
					elseif p_u_54.Enabled then
						v70:EquipTool(p_u_54)
						if v_u_1.CurrSelectedFrame and v_u_1.CurrSelectedFrame.Parent then
							v_u_1.CurrSelectedFrame:WaitForChild("Selected").Visible = false
						end
						v_u_1.CurrSelectedFrame = v_u_60
						v_u_62.Visible = true
					end
				else
					return
				end
			end
		else
			return
		end
	end
	if v_u_66:IsEquipped() and p_u_54.Enabled then
		if v_u_1.CurrSelectedFrame and v_u_1.CurrSelectedFrame.Parent then
			v_u_1.CurrSelectedFrame:WaitForChild("Selected").Visible = false
		end
		v_u_1.CurrSelectedFrame = v_u_60
		v_u_62.Visible = true
	else
		v_u_62.Visible = false
		v_u_1.CurrSelectedFrame = nil
	end
	local v_u_72 = v_u_60:WaitForChild("Quantity")
	local function v74() -- name: updateQuantity
		-- upvalues: (copy) p_u_54, (copy) v_u_72
		local v73 = p_u_54:GetAttribute("Count") or 1
		if v73 > 0 then
			v_u_72.Text = "x" .. v73
		else
			v_u_72.Text = ""
		end
	end
	local v75 = p_u_54:GetAttribute("Count") or 1
	if v75 > 0 then
		v_u_72.Text = "x" .. v75
	else
		v_u_72.Text = ""
	end
	v_u_66.Connections = {}
	v_u_66.Connections.ToolInfoChanged = p_u_54.Changed:Connect(v65)
	v_u_66.Connections.ToolRemoved = p_u_54.AncestryChanged:Connect(function(_, p76)
		-- upvalues: (ref) v_u_2, (ref) v_u_3, (copy) v_u_66, (ref) v_u_13, (copy) p_u_55, (ref) v_u_12, (ref) v_u_1, (ref) p_u_56, (copy) p_u_54, (copy) v_u_60, (copy) v_u_62
		if v_u_2 and (p76 == nil or p76 ~= v_u_3 and p76 ~= v_u_2.Character) then
			v_u_66:DisconnectAll()
			if v_u_13.Visible and p_u_55 == v_u_12 then
				v_u_1:CreatEmptyItem(p_u_56, v_u_12)
			end
		end
		if v_u_66:IsEquipped() and p_u_54.Enabled then
			if v_u_1.CurrSelectedFrame and v_u_1.CurrSelectedFrame.Parent then
				v_u_1.CurrSelectedFrame:WaitForChild("Selected").Visible = false
			end
			v_u_1.CurrSelectedFrame = v_u_60
			v_u_62.Visible = true
		else
			v_u_62.Visible = false
			v_u_1.CurrSelectedFrame = nil
		end
		v_u_1:UpdateInventoryCapacity()
	end)
	v_u_66.Connections.QuantityChanged = p_u_54:GetAttributeChangedSignal("Count"):Connect(v74)
	v_u_66.Connections.MouseEnter = v_u_60.MouseEnter:Connect(function()
		-- upvalues: (copy) v_u_66
		if not v_u_66.IsGrabbed then
			v_u_66:ShowDescription()
		end
	end)
	v_u_66.Connections.MouseLeave = v_u_60.MouseLeave:Connect(function()
		-- upvalues: (copy) v_u_66
		v_u_66:RemoveDescription()
	end)
	v_u_66.Connections.GrabConn = v_u_60.MouseButton1Down:Connect(function()
		-- upvalues: (copy) v_u_60, (copy) v_u_66, (ref) v_u_13, (ref) v_u_7, (ref) v_u_8, (ref) v_u_12, (ref) v_u_1, (copy) p_u_53, (copy) p_u_55, (ref) p_u_56, (copy) p_u_54, (ref) v_u_15, (ref) v_u_2, (ref) v_u_6, (ref) v_u_17, (ref) v_u_9
		local v_u_77 = nil
		local v_u_78 = nil
		local v_u_79 = nil
		local _ = v_u_60.AbsolutePosition
		v_u_66:RemoveDescription()
		local v_u_80 = v_u_13.Visible
		local function v_u_92() -- name: endGrab
			-- upvalues: (ref) v_u_77, (ref) v_u_78, (ref) v_u_66, (copy) v_u_80, (ref) v_u_7, (ref) v_u_8, (ref) v_u_12, (ref) v_u_1, (ref) v_u_79, (ref) p_u_53, (ref) p_u_55, (ref) p_u_56, (ref) p_u_54, (ref) v_u_15, (ref) v_u_13, (ref) v_u_60, (ref) v_u_2
			v_u_77:Disconnect()
			if v_u_78 then
				v_u_78:Disconnect()
			end
			v_u_66.IsGrabbed = false
			local v81 = false
			local v82 = true
			if v_u_80 then
				local v83 = v_u_7:GetGuiObjectsAtPosition(v_u_8.X, v_u_8.Y)
				for _, v84 in pairs(v83) do
					if v84:IsA("ImageButton") and v84.Parent == v_u_12 then
						local v85 = v_u_1.ToolItems
						local v86 = v84.Name
						local v87 = v85[tonumber(v86)]
						if v87 == v_u_66 then
							v82 = false
							if v_u_79 then
								v_u_79:Destroy()
							end
						else
							if v87 then
								v81 = true
								v_u_66:DisconnectAll()
								v87:DisconnectAll()
								p_u_53:AddTool(v87.Tool, p_u_55, p_u_56)
								p_u_53:AddTool(p_u_54, v87.Parent, v87.Index)
								if v_u_79 then
									v_u_79:Destroy()
								end
							else
								v81 = true
								v_u_66:DisconnectAll()
								local v88 = p_u_53
								local v89 = p_u_54
								local v90 = v_u_12
								local v91 = v84.Name
								v88:AddTool(v89, v90, (tonumber(v91)))
								if p_u_55 == v_u_12 then
									v_u_1:CreatEmptyItem(p_u_56, v_u_12)
								end
								if v_u_79 then
									v_u_79:Destroy()
								end
								v84:Destroy()
							end
							if v87 then
								v87:RemoveDescription()
							end
							if v_u_66 then
								v_u_66:RemoveDescription()
							end
						end
					elseif (v84:IsA("ImageButton") and v84.Parent == v_u_15 or v84:IsA("Frame") and v84 == v_u_13) and not v81 then
						if v_u_66.Parent ~= v_u_15 then
							v81 = true
							v_u_66:DisconnectAll()
							p_u_53:AddTool(p_u_54, v_u_15)
							p_u_53:SearchTool()
							if p_u_55 == v_u_12 then
								v_u_1:CreatEmptyItem(p_u_56, v_u_12)
							end
							if v_u_79 then
								v_u_79:Destroy()
							end
							break
						end
						v82 = false
						if v_u_79 then
							v_u_79:Destroy()
						end
					end
				end
			else
				v82 = false
			end
			if not v81 then
				if v_u_79 then
					v_u_79:Destroy()
				end
				v_u_60.Parent = p_u_55
				local _ = v_u_12:WaitForChild("UIGridLayout").CellSize
				local _ = v_u_60.AbsolutePosition + v_u_60.AbsoluteSize * 0.5
				if v82 and (v_u_2.Character and (p_u_54.CanBeDropped and v_u_66:IsEquipped(p_u_54))) then
					p_u_54:PivotTo(v_u_2.Character:GetPivot() * CFrame.new(0, 0, -5))
					p_u_54.Parent = workspace
					if p_u_55 == v_u_12 then
						v_u_1:CreatEmptyItem(p_u_56, v_u_12)
					end
				end
			end
		end
		v_u_77 = v_u_6.InputEnded:Connect(function(p93)
			-- upvalues: (copy) v_u_92
			if p93.UserInputType == Enum.UserInputType.MouseButton1 or p93.UserInputType == Enum.UserInputType.Touch then
				v_u_92()
			end
		end)
		if v_u_80 then
			local function v96() -- name: updateFramePos
				-- upvalues: (ref) v_u_66, (ref) v_u_79, (ref) v_u_60, (ref) p_u_55, (ref) v_u_17, (ref) v_u_9, (ref) v_u_8
				if not v_u_66.IsGrabbed then
					v_u_66.IsGrabbed = true
					v_u_79 = Instance.new("Frame")
					v_u_79.BackgroundColor3 = Color3.new(0, 0, 0)
					v_u_79.BackgroundTransparency = 0.8
					v_u_79.Name = v_u_60.Name
					v_u_79.Size = v_u_60.Size
					v_u_79.Parent = p_u_55
					v_u_79.LayoutOrder = v_u_60.LayoutOrder
					local v94 = v_u_60:FindFirstChild("UICorner")
					if v94 then
						v94:Clone().Parent = v_u_79
					end
					v_u_60.Size = v_u_17.CellSize
					v_u_60.Parent = v_u_9
				end
				local v95 = Vector2.new(v_u_8.X, v_u_8.Y)
				v_u_60.Position = UDim2.new(0, v95.X, 0, v95.Y)
			end
			v_u_78 = v_u_8.Move:Connect(v96)
		end
	end)
	if v57 and p_u_56 then
		v_u_4:BindAction(p_u_56 .. "ItemsBar", v71, false, v_u_18[p_u_56])
	end
end
return v_u_1

-- // Function Dumper made by King.Kevin
-- // Script Path: Players.bxgon24.PlayerGui.InventoryGui.InventoryGui.InventoryHandler

--[[
Function Dump: Unknown Name

Function Upvalues: Unknown Name
		1 [table]:
		1 [table] table: 0x9f0002af27501fd9
				1 [table]:
				Connections [table] table: 0x978ae52935fcd289
						1 [RBXScriptConnection] = Connection
						2 [RBXScriptConnection] = Connection
						3 [RBXScriptConnection] = Connection
						4 [RBXScriptConnection] = Connection
						5 [RBXScriptConnection] = Connection
						6 [RBXScriptConnection] = Connection
				2 [number] = 1
				3 [Instance] = ItemsBar
				4 [string] = Weapon
				5 [Instance] = 1
				6 [Instance] = Weapon

Function Constants: Unknown Name
		1 [string] = RemoveDescription

====================================================================================================

Function Dump: Unknown Name

Function Upvalues: Unknown Name
		1 [table] (Recursive table detected)

Function Constants: Unknown Name
		1 [string] = IsGrabbed
		2 [string] = ShowDescription

====================================================================================================

Function Dump: GetIndexToNumber

Function Upvalues: GetIndexToN