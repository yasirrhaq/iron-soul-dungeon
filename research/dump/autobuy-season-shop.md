local args = {
	"UpdateTaskProgress",
	"OpenGUIWindow",
	"ScreenSeasonPass"
}
game:GetService("ReplicatedStorage"):WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("TaskSystem"):WaitForChild("TaskRE"):FireServer(unpack(args))

local args = {
	"BuySeasonShopItem",
	"SeasonShop_05"
}

game:GetService("ReplicatedStorage"):WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("SeasonSystem"):WaitForChild("SeasonUtil"):WaitForChild("RemoteEvent"):FireServer(unpack(args))yes 