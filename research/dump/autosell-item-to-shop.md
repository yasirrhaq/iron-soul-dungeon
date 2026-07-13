local args = {
	"UpdateTaskProgress",
	"DialogNpc",
	"EquipmentSellNpc1|1"
}
game:GetService("ReplicatedStorage"):WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("TaskSystem"):WaitForChild("TaskRE"):FireServer(unpack(args))


local args = {
	"UpdateTaskProgress",
	"DialogNpc",
	"EquipmentSellNpc1|0"
}
game:GetService("ReplicatedStorage"):WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("TaskSystem"):WaitForChild("TaskRE"):FireServer(unpack(args))

local args = {
	"UpdateTaskProgress",
	"OpenGUIWindow",
	"ScreenEquipSell"
}
game:GetService("ReplicatedStorage"):WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("TaskSystem"):WaitForChild("TaskRE"):FireServer(unpack(args))

local args = {
	"UpdateTaskProgress",
	"OpenGUIWindow",
	"ScreenTips"
}
game:GetService("ReplicatedStorage"):WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("TaskSystem"):WaitForChild("TaskRE"):FireServer(unpack(args))

local args = {
	"Sell",
	{
		"Jade"
	}
}
game:GetService("ReplicatedStorage"):WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("ForgeSystem"):WaitForChild("ForgeRF"):InvokeServer(unpack(args))

local args = {
	"Clear",
	"Ores",
	"Jade"
}
game:GetService("ReplicatedStorage"):WaitForChild("Framework"):WaitForChild("Systems"):WaitForChild("RedPointSystem"):WaitForChild("RedPointUtil"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
