# Calling Code

local Event = game:GetService("ReplicatedStorage").Framework.Gameplay.WorldPlace.WorldBonusCardUtil.RemoteEvent
Event:FireServer(
    "Select",
    2
)

local v1 = game:GetService("Players")
local v2 = game:GetService("ReplicatedStorage")
local v_u_3 = game:GetService("TweenService")
local v_u_4 = require(v2:WaitForChild("Utility"):WaitForChild("CountDownUtility"))
local v_u_5 = v1.LocalPlayer
local v6 = require(v2:WaitForChild("Framework"))
local v_u_7 = v6.Modules.TranslationUtil
local v_u_8 = v6.Modules.WorldBonusCardUtil
local v_u_9 = v6.Modules.WindowUtil
local v_u_10 = v6.Modules.WarningUtil
local v_u_11 = v6.Modules.CurrencyUtil
local v_u_12 = v6.Modules.RarityTiers
local v_u_13 = v6.Modules.DataUtil
local v_u_14 = v_u_8.RemoteEvent
local v_u_15 = Color3.fromRGB(255, 255, 255)
local v_u_16 = Color3.fromRGB(255, 60, 60)
local v_u_17 = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local v_u_18 = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local v_u_19 = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local v_u_20 = script.Parent
local v_u_21 = v_u_20:WaitForChild("Cards")
local v_u_22 = v_u_20:WaitForChild("Time"):WaitForChild("Time")
local v_u_23 = v_u_21:WaitForChild("Item")
v_u_23.Parent = script
v_u_23.Visible = false
local v_u_24 = v_u_23.BTN.Position
local v_u_25 = UDim2.new(v_u_24.X.Scale, v_u_24.X.Offset, -1.6, 0)
local v_u_26 = UDim2.new(v_u_24.X.Scale, v_u_24.X.Offset, 2.2, 0)
local v_u_27 = v_u_20.Name
local v_u_28 = v_u_11.CurrencyIds.Currency1
local v_u_29 = {}
local v_u_30 = nil
local v_u_31 = false
local function v_u_33() -- name: ClearCards
	-- upvalues: (ref) v_u_29
	for _, v32 in ipairs(v_u_29) do
		if v32.item then
			v32.item:Destroy()
		end
	end
	v_u_29 = {}
end
local function v_u_36() -- name: RefreshAffordColors
	-- upvalues: (ref) v_u_29, (copy) v_u_11, (copy) v_u_5, (copy) v_u_28, (copy) v_u_15, (copy) v_u_16
	for _, v34 in ipairs(v_u_29) do
		if v34.paid and v34.goldText then
			local v35 = v_u_11:Has(v_u_5, v_u_28, v34.price)
			v34.goldText.TextColor3 = v35 and v_u_15 or v_u_16
		end
	end
end
local function v_u_40(p37) -- name: SetSelectHighlight
	-- upvalues: (ref) v_u_29
	for _, v38 in ipairs(v_u_29) do
		local v39 = v38.btn:FindFirstChild("Select")
		if v39 then
			v39.Visible = v38.index == p37
		end
	end
end
local function v_u_61(p_u_41, p_u_42) -- name: CreateCard
	-- upvalues: (copy) v_u_8, (copy) v_u_23, (copy) v_u_21, (copy) v_u_12, (copy) v_u_7, (ref) v_u_31, (copy) v_u_14, (copy) v_u_10, (copy) v_u_40, (copy) v_u_25, (copy) v_u_3, (copy) v_u_17, (copy) v_u_24, (ref) v_u_29
	local v43 = v_u_8:GetCardInfo(p_u_41.ID)
	if v43 then
		local v44 = v_u_23:Clone()
		v44.Name = "Item" .. p_u_42
		v44.LayoutOrder = p_u_42
		v44.Visible = true
		v44.Parent = v_u_21
		local v45 = v44.BTN
		local v46 = v_u_8:GetCardRarity(v43) or 1
		local v47 = math.clamp(v46, 1, 7)
		local v48 = v45:FindFirstChild("Icon")
		if v48 then
			v48.Image = v_u_8:GetCardIcon(v43) or ""
		end
		local v49 = v45:FindFirstChild("RarityText")
		if v49 then
			v_u_12:SetTextLabelToTier(v49, v47)
		end
		local v50 = v45:FindFirstChild("Stat")
		if v50 then
			v50:WaitForChild("Name").Text = v_u_7:TranslateByKey(v43.Name)
			v50:WaitForChild("Info"):WaitForChild("Desc").Text = v_u_7:TranslateByKey(v43.Desc)
		end
		local v51 = v45:FindFirstChild("Bg")
		if v51 then
			for v52 = 1, 7 do
				local v53 = v51:FindFirstChild("Bg" .. v52)
				if v53 then
					v53.Visible = v52 == v47
				end
			end
		end
		local v54 = v45:FindFirstChild("Select")
		if v54 then
			v54.Visible = false
		end
		local v55 = v45:FindFirstChild("Lock")
		local v56 = nil
		if p_u_41.Paid then
			if v55 then
				v55.Visible = true
			end
			if v55 then
				v55 = v55:FindFirstChild("Unlock")
			end
			if v55 then
				v56 = v55:FindFirstChild("Gold")
			else
				v56 = v55
			end
			if v56 then
				v56 = v56:FindFirstChild("Text")
			end
			if v56 then
				local v57 = p_u_41.Price
				v56.Text = tostring(v57)
			end
			if v55 then
				v55.MouseButton1Click:Connect(function()
					-- upvalues: (ref) v_u_31, (ref) v_u_14, (copy) p_u_42
					if not v_u_31 then
						v_u_14:FireServer("Unlock", p_u_42)
					end
				end)
			end
		elseif v55 then
			v55.Visible = false
		end
		v45.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_31, (copy) p_u_41, (ref) v_u_10, (ref) v_u_40, (copy) p_u_42, (ref) v_u_14
			if v_u_31 then
				return
			elseif p_u_41.Paid then
				v_u_10:Warn("K_CARD_LOCK", {
					["IsPositive"] = false
				})
			else
				v_u_40(p_u_42)
				v_u_14:FireServer("Select", p_u_42)
			end
		end)
		v45.Position = v_u_25
		local v58 = {
			["Position"] = v_u_24
		}
		v_u_3:Create(v45, TweenInfo.new(v_u_17.Time, v_u_17.EasingStyle, v_u_17.EasingDirection, 0, false, 0.06 * (p_u_42 - 1)), v58):Play()
		local v59 = v_u_29
		local v60 = {
			["item"] = v44,
			["btn"] = v45,
			["index"] = p_u_42,
			["paid"] = p_u_41.Paid,
			["price"] = p_u_41.Price,
			["goldText"] = v56
		}
		table.insert(v59, v60)
	end
end
local function v_u_68(p62) -- name: OnSelectAndClose
	-- upvalues: (ref) v_u_31, (ref) v_u_30, (copy) v_u_40, (ref) v_u_29, (copy) v_u_3, (copy) v_u_19, (copy) v_u_18, (copy) v_u_25, (copy) v_u_26, (copy) v_u_9, (copy) v_u_27
	v_u_31 = true
	if v_u_30 then
		v_u_30:Stop()
		v_u_30 = nil
	end
	v_u_40(p62)
	for _, v_u_63 in ipairs(v_u_29) do
		if v_u_63.index == p62 then
			local v64 = v_u_63.paid and v_u_63.btn:FindFirstChild("Lock")
			if v64 then
				v64.Visible = false
			end
			local v65 = v_u_63.btn.Size
			v_u_3:Create(v_u_63.btn, v_u_19, {
				["Size"] = UDim2.new(1.2 * v65.X.Scale, 0, 1.2 * v65.Y.Scale, 0)
			}):Play()
			task.delay(v_u_19.Time + 0.5, function()
				-- upvalues: (ref) v_u_3, (copy) v_u_63, (ref) v_u_18, (ref) v_u_25
				local v66 = {
					["Position"] = v_u_25
				}
				v_u_3:Create(v_u_63.btn, v_u_18, v66):Play()
			end)
		else
			local v67 = {
				["Position"] = v_u_26
			}
			v_u_3:Create(v_u_63.btn, v_u_18, v67):Play()
		end
	end
	task.delay(1, function()
		-- upvalues: (ref) v_u_9, (ref) v_u_27
		v_u_9:Close(v_u_27)
	end)
end
local function v_u_80(p69, p70) -- name: OnShowCards
	-- upvalues: (ref) v_u_30, (copy) v_u_33, (ref) v_u_31, (copy) v_u_61, (ref) v_u_29, (copy) v_u_36, (copy) v_u_40, (copy) v_u_9, (copy) v_u_27, (copy) v_u_8, (copy) v_u_22, (copy) v_u_4
	if type(p69) == "table" then
		if v_u_30 then
			v_u_30:Stop()
			v_u_30 = nil
		end
		v_u_33()
		v_u_31 = false
		for v71, v72 in ipairs(p69) do
			v_u_61(v72, v71)
		end
		if #v_u_29 ~= 0 then
			v_u_36()
			v_u_40(1)
			v_u_9:Open(v_u_27, nil, true)
			local v73 = tonumber(p70) or v_u_8:GetSelectCardTime()
			local v74 = v_u_22
			local v75 = math.ceil(v73)
			v74.Text = tostring(v75)
			v_u_30 = v_u_4:new(v73, 1, function(p76)
				-- upvalues: (ref) v_u_22
				local v77 = v_u_22
				local v78 = math.ceil(p76)
				local v79 = math.max(0, v78)
				v77.Text = tostring(v79)
			end, function()
				-- upvalues: (ref) v_u_22, (ref) v_u_31, (ref) v_u_9, (ref) v_u_27
				v_u_22.Text = "0"
				task.delay(1.5, function()
					-- upvalues: (ref) v_u_31, (ref) v_u_9, (ref) v_u_27
					if not v_u_31 then
						v_u_9:Close(v_u_27)
					end
				end)
			end)
			v_u_30:Start()
		end
	else
		return
	end
end
(function() -- name: Init
	-- upvalues: (copy) v_u_13, (copy) v_u_5, (copy) v_u_28, (copy) v_u_36, (copy) v_u_20, (copy) v_u_14, (copy) v_u_80, (ref) v_u_29, (copy) v_u_68
	v_u_13:ListenFor(v_u_5, { "Currency", v_u_28 }, function()
		-- upvalues: (ref) v_u_36
		v_u_36()
	end)
	v_u_20:GetPropertyChangedSignal("Visible"):Connect(function()
		-- upvalues: (ref) v_u_5, (ref) v_u_20
		v_u_5:SetAttribute("LockViewSuspended", v_u_20.Visible)
	end)
	v_u_14.OnClientEvent:Connect(function(p81, ...)
		-- upvalues: (ref) v_u_80, (ref) v_u_29, (ref) v_u_68
		if p81 == "ShowCards" then
			v_u_80(...)
		elseif p81 == "SelectResult" then
			local v82, v83 = ...
			if not v82 then
				return
			end
			if #v_u_29 == 0 then
				return
			end
			v_u_68(tonumber(v83) or 1)
		end
	end)
end)()