# Remote call
local Event = game:GetService("ReplicatedStorage").Framework.Gameplay.EquipmentSystem.ForgeRF
Event:InvokeServer(
    "Sell",
    {
        Frostheart = 2
    }
)

# V6 Integration Notes

- Current remote path is `Framework.Gameplay.EquipmentSystem.ForgeRF`.
- Sell payload is an ore-to-count map, not an array of ore IDs.
- Each count should equal the full currently owned amount to sell maximum available quantity.
- Example for multiple ores:

```lua
Event:InvokeServer("Sell", {
    Frostheart = 2,
    Corundum = 40,
})
```

- V6 resolves the updated path first and retains `Framework.Features.ForgeSystem.ForgeRF` as compatibility fallback.
- Empty map checks use `next(SellList) == nil`; confirmation iterates `for OreId in pairs(SellList)`.

# Decompiled Script
local v_u_1 = require(game.ReplicatedStorage:WaitForChild("Framework"))
local _ = game.Players.LocalPlayer
local v_u_2 = require(game.ReplicatedStorage:WaitForChild("Utility"):WaitForChild("CountDownUtility"))
local v_u_3 = script.Parent
v_u_3.Visible = false
local v_u_4 = v_u_3:WaitForChild("Title")
local v_u_5 = v_u_3:WaitForChild("Desc")
local v6 = v_u_3:WaitForChild("BtnGroup")
local v7 = v6:WaitForChild("Confirm")
local v_u_8 = v7:WaitForChild("TXT")
local v_u_9 = v7:WaitForChild("Disable")
local v_u_10 = v6:WaitForChild("Cancel")
local v_u_11 = v_u_10:WaitForChild("TXT")
local v_u_12 = v_u_1.Modules.TranslationUtil
local v_u_13 = nil
local v_u_14 = nil
local v_u_15 = nil
local function v16() -- name: OnConfirm
	-- upvalues: (copy) v_u_9, (ref) v_u_13, (copy) v_u_1, (copy) v_u_3
	if not v_u_9.Visible then
		if v_u_13 then
			v_u_13()
			v_u_13 = nil
		end
		v_u_1.Modules.WindowUtil:Close(v_u_3.Name)
	end
end
local function v17() -- name: OnCancel
	-- upvalues: (ref) v_u_14, (copy) v_u_1, (copy) v_u_3
	if v_u_14 then
		v_u_14()
		v_u_14 = nil
	end
	v_u_1.Modules.WindowUtil:Close(v_u_3.Name)
end
v7.MouseButton1Down:Connect(v16)
v_u_10.MouseButton1Down:Connect(v17)
local function v_u_22() -- name: OnOpen
	-- upvalues: (copy) v_u_1, (copy) v_u_3, (copy) v_u_10, (ref) v_u_14, (copy) v_u_11, (copy) v_u_12, (ref) v_u_13, (copy) v_u_9, (ref) v_u_15, (copy) v_u_2, (copy) v_u_8, (copy) v_u_4, (copy) v_u_5
	local v18 = v_u_1.Modules.WindowUtil:GetOpenData(v_u_3.Name) or {}
	if v18.IgnoreCancel then
		v_u_10.Visible = false
	else
		v_u_10.Visible = true
		v_u_14 = v18.CancelCallback
		v_u_11.Text = v_u_12:TranslateByKey(v18.CancelKey or "K_CANCEL")
	end
	v_u_13 = v18.ConfirmCallback
	local v_u_19 = v_u_12:TranslateByKey(v18.ConfirmKey or "K_CONFIRM")
	local v20 = v18.ConfirmDelay
	if v20 then
		v_u_9.Visible = true
		if v_u_15 then
			v_u_15:Stop()
			v_u_15 = nil
		end
		v_u_15 = v_u_2:new(v20, 1, function(p21)
			-- upvalues: (ref) v_u_8, (copy) v_u_19
			v_u_8.Text = string.format("%s(%d)", v_u_19, (math.floor(p21)))
		end, function()
			-- upvalues: (ref) v_u_9, (ref) v_u_8, (copy) v_u_19
			v_u_9.Visible = false
			v_u_8.Text = v_u_19
		end)
		v_u_15:Start()
	else
		v_u_9.Visible = false
		v_u_8.Text = v_u_19
	end
	v_u_4.Text = v_u_12:TranslateByKey(v18.TitleKey or "K_TIPS")
	v_u_5.Text = v_u_12:TranslateByKey(v18.DescKey or "", v18.DescParams)
end
v_u_3:GetPropertyChangedSignal("Visible"):Connect(function()
	-- upvalues: (copy) v_u_3, (copy) v_u_22, (ref) v_u_13, (ref) v_u_14, (ref) v_u_15
	if v_u_3.Visible then
		v_u_22()
	else
		v_u_13 = nil
		v_u_14 = nil
		if v_u_15 then
			v_u_15:Stop()
			v_u_15 = nil
		end
	end
end)
