-- Script Path: game:GetService("ReplicatedStorage").Framework.Features.SeasonSystem.SeasonUtil
-- Took 0.48s to decompile.
-- Executor: Delta (1.1.727.1199)

local v_u_1 = require(game.ReplicatedStorage.Configs.ResSeasonPass)
local v_u_2 = require(game.ReplicatedStorage.Configs.ResSeasonPassTask)
local v_u_3 = require(game.ReplicatedStorage.Configs.ResSeasonPassLevel)
local v_u_4 = require(game.ReplicatedStorage.Configs.ResSeasonShop)
local v_u_5 = require(game.ReplicatedStorage:WaitForChild("Utility"):WaitForChild("Timer"))
local v_u_6 = require(game.ReplicatedStorage:WaitForChild("Enum"):WaitForChild("GameEnum"))
local v_u_7 = {}
local v_u_8 = nil
local v_u_9 = nil
local v_u_10 = nil
local v_u_11 = nil
local v_u_12 = nil
local v_u_13 = nil
local function v_u_18(p14) -- name: GetLootTable
    -- upvalues: (copy) v_u_4
    local v15 = {}
    for _, v16 in pairs(v_u_4.__index) do
        local v17 = v_u_4[v16]
        if v17.IsSpecial == p14 then
            table.insert(v15, v17)
        end
    end
    return v15
end
function v_u_7.GetCurrentSeason(_) -- name: GetCurrentSeason
    -- upvalues: (ref) v_u_11, (copy) v_u_1
    if not v_u_11 then
        local v19 = v_u_1.__index
        v_u_11 = v19[#v19]
    end
    return v_u_11
end
function v_u_7.GetNowTime(_) -- name: GetNowTime
    -- upvalues: (ref) v_u_9
    if not v_u_9 then
        v_u_9 = game.ReplicatedStorage:WaitForChild("Time")
    end
    while v_u_9.Value <= 0 do
        task.wait()
    end
    local v20 = v_u_9.Value
    return math.floor(v20)
end
function v_u_7.GetSeasonInfo(_, p21) -- name: GetSeasonInfo
    -- upvalues: (copy) v_u_7, (copy) v_u_1
    return v_u_1[p21 or v_u_7:GetCurrentSeason()]
end
function v_u_7.GetSeasonName(_) -- name: GetSeasonName
    -- upvalues: (copy) v_u_7
    local v22 = v_u_7:GetSeasonInfo()
    return not v22 and "Season" or v22.Name
end
function v_u_7.GetSeasonEndTime(_) -- name: GetSeasonEndTime
    -- upvalues: (ref) v_u_12, (copy) v_u_7
    if not v_u_12 then
        local v23 = v_u_7:GetSeasonInfo().EndTime
        local v24
        if v23 == "" then
            v24 = nil
        else
            local v25, v26, v27, v28, v29 = v23:match("(%d+)-(%d+)-(%d+)-(%d+):(%d+)")
            v24 = os.time({
                ["year"] = v25,
                ["month"] = v26,
                ["day"] = v27,
                ["hour"] = v28,
                ["min"] = v29
            })
        end
        v_u_12 = v24
    end
    return v_u_12
end
function v_u_7.GetSeasonCloseTime(_) -- name: GetSeasonCloseTime
    -- upvalues: (ref) v_u_13, (copy) v_u_7
    if not v_u_13 then
        local v30 = v_u_7:GetSeasonInfo().CloseTime
        local v31
        if v30 == "" then
            v31 = nil
        else
            local v32, v33, v34, v35, v36 = v30:match("(%d+)-(%d+)-(%d+)-(%d+):(%d+)")
            v31 = os.time({
                ["year"] = v32,
                ["month"] = v33,
                ["day"] = v34,
                ["hour"] = v35,
                ["min"] = v36
            })
        end
        v_u_13 = v31
    end
    return v_u_13
end
function v_u_7.IsSeasonClose(_) -- name: IsSeasonClose
    -- upvalues: (copy) v_u_7
    return v_u_7:GetSeasonCloseTime() < v_u_7:GetNowTime()
end
function v_u_7.IsSeasonEnd(_) -- name: IsSeasonEnd
    -- upvalues: (copy) v_u_7
    return v_u_7:GetSeasonEndTime() < v_u_7:GetNowTime()
end
function v_u_7.GetCurrentDate(_) -- name: GetCurrentDate
    -- upvalues: (ref) v_u_9
    if not v_u_9 then
        v_u_9 = game.ReplicatedStorage:WaitForChild("Time")
    end
    while v_u_9.Value <= 0 do
        task.wait()
    end
    return v_u_9:GetAttribute("Date")
end
function v_u_7.GetQuestCompleteVaule(_, p37) -- name: GetQuestCompleteVaule
    -- upvalues: (copy) v_u_2
    if p37 then
        local v38 = v_u_2[p37]
        if v38 then
            local v39 = v38.CompleteVaule
            return tonumber(v39)
        end
    end
end
function v_u_7.IsQuestCompleted(_, p40, p41) -- name: IsQuestCompleted
    -- upvalues: (copy) v_u_7, (ref) v_u_8
    if p40 and p41 then
        local v42 = v_u_7:GetCurrentSeason()
        local v43 = v_u_8:GetPlayerData(p40)
        if v43 then
            if v43.Seasons[v42] then
                local v44 = v_u_7:GetQuestCompleteVaule(p41)
                if v44 then
                    local v45 = v43.Seasons[v42][p41] or 0
                    return v44 <= v45, v45
                end
            end
        else
            return
        end
    else
        return
    end
end
function v_u_7.ProcessQuests(_, p46, p47, p48, p49) -- name: ProcessQuests
    -- upvalues: (copy) v_u_7, (copy) v_u_2, (copy) v_u_6, (ref) v_u_8
    if p46 then
        if v_u_7:IsSeasonEnd() then
            return
        elseif p49 and p49 >= 0 then
            if p47 and p47 ~= "" then
                local v50 = v_u_7:GetCurrentSeason()
                local v51 = v_u_7:GetSeasonPass(p46, v50)
                for _, v52 in pairs(v_u_2.__index) do
                    local v53 = v_u_2[v52]
                    if v53 and (p47 == v53.CompleteType and (v53.ItemId == "" or p48 == v53.ItemId)) then
                        local v54 = v53.CompleteVaule
                        local v55 = tonumber(v54) or 0
                        if v53.CompleteType == v_u_6.TaskAction.InfinityTowerClear then
                            local v56 = v51[v52] or 0
                            if v56 < v55 then
                                local v57 = math.max(p49, v56)
                                v_u_8:SetValue(p46, { "Seasons", v50, v52 }, v57)
                                if v55 <= v57 then
                                    local v58 = v53.TaskPoints or 0
                                    if v_u_7:IsOwnDungeonExpUp(p46, v50) then
                                        v58 = v58 * 2
                                    end
                                    v_u_7:AddSeasonExp(p46, v58, v50)
                                end
                            end
                        else
                            local v59 = v51[v52] or 0
                            if v59 < v55 then
                                local v60 = v59 + p49
                                local v61 = math.min(v60, v55)
                                v_u_8:SetValue(p46, { "Seasons", v50, v52 }, v61)
                                if v55 <= v61 then
                                    local v62 = v53.TaskPoints or 0
                                    if v_u_7:IsOwnDungeonExpUp(p46, v50) then
                                        v62 = v62 * 2
                                    end
                                    v_u_7:AddSeasonExp(p46, v62, v50)
                                end
                            end
                        end
                    end
                end
            end
        else
            return
        end
    else
        return
    end
end
function v_u_7.RefreshSeasonShop(p63, _, p64) -- name: RefreshSeasonShop
    -- upvalues: (copy) v_u_7, (copy) v_u_18
    if not p64.ShopData then
        p64.ShopData = {
            ["BuyCount"] = nil,
            ["SpecialId"] = nil,
            ["NormalIds"] = nil,
            ["BuyCount"] = {},
            ["NormalIds"] = {}
        }
    end
    local v65 = v_u_7:GetNowTime()
    local v66 = v65 % 3600
    local v67 = v66 / 60
    local v68 = math.floor(v67) / 15
    local v69 = (math.floor(v68) + 1) * 15 * 60 - v66
    p64.ShopData.RefreshTime = v65 + v69
    local v70 = p63.Modules.LootServiceUtil
    local v71 = v_u_18(true)
    local v72 = {}
    for _, v73 in pairs(v71) do
        if not p64.ShopData.BuyCount[v73.Id] or p64.ShopData.BuyCount[v73.Id] < v73.LimitTimes then
            table.insert(v72, v73)
        end
    end
    if #v72 <= 0 then
        for _, v74 in pairs(v71) do
            table.insert(v72, v74)
        end
    end
    local v75 = v70:GetRandomResultByWeight(v72)
    p64.ShopData.SpecialId = v75.Id
    local v76 = v_u_18(false)
    p64.ShopData.NormalIds = {}
    local v77 = {}
    for _, v78 in pairs(v76) do
        p64.ShopData.BuyCount[v78.Id] = nil
        table.insert(v77, v78)
    end
    for v79 = 1, 6 do
        local v80 = v70:GetRandomResultByWeight(v77)
        p64.ShopData.NormalIds[tostring(v79)] = v80.Id
        for v81, v82 in ipairs(v77) do
            if v82.Id == v80.Id then
                table.remove(v77, v81)
                break
            end
        end
    end
end
function v_u_7.GenerateSeasonTime(_, p83) -- name: GenerateSeasonTime
    -- upvalues: (copy) v_u_7, (ref) v_u_9, (ref) v_u_8, (copy) v_u_6
    if v_u_7:IsSeasonEnd() then
        return
    else
        local v84 = v_u_7:GetCurrentDate()
        local v85 = v_u_9:GetAttribute("Year")
        local v86 = v_u_9:GetAttribute("Week")
        if v84 and (v85 and v86) then
            local v87 = v_u_7:GetCurrentSeason()
            local v88 = v_u_7:GetNowTime()
            local v89 = v88 / 60
            local v90 = math.floor(v89) % 60
            local v91 = v88 / 3600
            local v92 = math.floor(v91) % 24
            local v93 = (v90 == 0 or (v90 == 15 or v90 == 30)) and true or v90 == 45
            for _, v94 in pairs(game.Players:GetPlayers()) do
                local v95 = v_u_7:GetSeasonPass(v94, v87)
                local v96 = false
                local v97 = false
                local v98
                if v95.Date == v84 then
                    v98 = false
                else
                    v95.Date = v84
                    v98 = true
                end
                if v95.Year ~= v85 or v95.Week ~= v86 then
                    v95.Year = v85
                    v95.Week = v86
                    v98 = true
                    v96 = true
                end
                if v93 or (not v95.ShopData or (not v95.ShopData.RefreshTime or v95.ShopData.RefreshTime < v88)) then
                    local v99 = v84 .. "_" .. v92 .. "_" .. v90
                    if v95.ShopRefreshId ~= v99 then
                        v95.ShopRefreshId = v99
                        v97 = true
                    end
                end
                if v98 then
                    for v100, _ in pairs(v95) do
                        if string.find(v100, "DailyTask") then
                            v95[v100] = nil
                        end
                    end
                end
                if v96 then
                    for v101, _ in pairs(v95) do
                        if string.find(v101, "WeekTask") then
                            v95[v101] = nil
                        end
                    end
                end
                if v97 then
                    v_u_7:RefreshSeasonShop(v94, v95)
                end
                if v98 or (v96 or v97) then
                    v_u_8:SetValue(v94, { "Seasons", v87 }, v95)
                end
                if p83 and p83 > 0 then
                    v_u_7:ProcessQuests(v94, v_u_6.TaskAction.OnlineTime, "Time", p83)
                end
            end
        end
    end
end
function v_u_7.ClaimSeasonReward(p102, p103, p104, p105) -- name: ClaimSeasonReward
    -- upvalues: (copy) v_u_7, (copy) v_u_3, (ref) v_u_8
    if p103 and p104 then
        if v_u_7:IsSeasonClose() then
            return
        else
            local v106, v107 = v_u_7:IsClaimedLvReward(p103, p104, p105)
            if v106 or not v107 then
                return
            else
                local v108 = v_u_7:GetSeasonInfo()
                if v108 then
                    local v109 = v108.ID
                    local v110 = v_u_7:GetSeasonExp(p103, v109)
                    local v111 = v108.MaxLevel
                    local v112 = v110 / v108.EachEXP
                    local v113 = math.floor(v112) + 1
                    if math.min(v111, v113) < p104 then
                        return
                    else
                        local v114 = v_u_3[p104]
                        if v114 then
                            if v_u_7:GetSeasonPass(p103, v109) then
                                local v115 = {
                                    ["RewardId"] = v114["Reward" .. (p105 and "Adv" or "F")],
                                    ["RewardType"] = v114["Type" .. (p105 and "Adv" or "F")],
                                    ["RewardCount"] = v114["Count" .. (p105 and "Adv" or "F")]
                                }
                                p102.Modules.GiveThingsUtil:Give(p103, v115.RewardId, v115.RewardType, v115.RewardCount, true, "SeasonLvReward", true)
                                v_u_8:SetValue(p103, { "Seasons", v109, v107 }, true)
                            end
                        else
                            return
                        end
                    end
                else
                    return
                end
            end
        end
    else
        return
    end
end
function v_u_7.IsClaimedLvReward(_, p116, p117, p118) -- name: IsClaimedLvReward
    -- upvalues: (copy) v_u_7, (ref) v_u_8
    if p116 and p117 then
        local v119 = v_u_7:GetCurrentSeason()
        local v120 = v_u_8:GetPlayerData(p116)
        if v120 then
            local v121
            if p118 then
                v121 = string.format("C%dA", p117)
            else
                v121 = string.format("C%dF", p117)
            end
            if v120.Seasons[v119] then
                return v120.Seasons[v119][v121], v121
            else
                return nil, v121
            end
        else
            return
        end
    else
        return
    end
end
function v_u_7.IsOwnAdvSeason(_, p122, p123) -- name: IsOwnAdvSeason
    -- upvalues: (copy) v_u_7, (ref) v_u_8
    if p122 then
        local v124 = p123 or v_u_7:GetCurrentSeason()
        local v125 = v_u_8:GetPlayerData(p122)
        if v125 then
            if v125.Seasons[v124] then
                return v125.Seasons[v124].OwnAdv
            end
        end
    else
        return
    end
end
function v_u_7.IsOwnMaxSeason(_, p126, p127) -- name: IsOwnMaxSeason
    -- upvalues: (copy) v_u_7, (ref) v_u_8
    if p126 then
        local v128 = p127 or v_u_7:GetCurrentSeason()
        local v129 = v_u_8:GetPlayerData(p126)
        if v129 then
            if v129.Seasons[v128] then
                return v129.Seasons[v128].OwnMax
            end
        end
    else
        return
    end
end
function v_u_7.IsOwnDungeonSpeedUp(_, p130, p131) -- name: IsOwnDungeonSpeedUp
    -- upvalues: (copy) v_u_7, (ref) v_u_8
    if p130 then
        local v132 = p131 or v_u_7:GetCurrentSeason()
        local v133 = v_u_8:GetPlayerData(p130)
        if v133 then
            if v133.Seasons[v132] then
                return v133.Seasons[v132].OwnDungeonSpeedUp
            end
        end
    else
        return
    end
end
function v_u_7.UnlockSeasonPass(_, p134, p135) -- name: UnlockSeasonPass
    -- upvalues: (copy) v_u_7, (ref) v_u_8
    if p134 then
        local v136 = p135 or v_u_7:GetCurrentSeason()
        if not v_u_7:IsOwnAdvSeason(p134, v136) then
            if not v_u_7:GetSeasonPass(p134, v136).OwnAdv then
                v_u_8:SetValue(p134, { "Seasons", v136, "OwnAdv" }, true)
            end
            p134:SetAttribute("SeasonAdv", true)
        end
    else
        return
    end
end
function v_u_7.UnlockSeasonMax(_, p137, p138) -- name: UnlockSeasonMax
    -- upvalues: (copy) v_u_7, (ref) v_u_8
    if p137 then
        local v139 = p138 or v_u_7:GetCurrentSeason()
        if not v_u_7:IsOwnMaxSeason(p137, v139) then
            if not v_u_7:GetSeasonPass(p137, v139).OwnMax then
                v_u_8:SetValue(p137, { "Seasons", v139, "OwnMax" }, true)
            end
            p137:SetAttribute("SeasonMax", true)
        end
    else
        return
    end
end
function v_u_7.IsOwnDungeonExpUp(_, p140, p141) -- name: IsOwnDungeonExpUp
    -- upvalues: (copy) v_u_7, (ref) v_u_8
    if p140 then
        local v142 = p141 or v_u_7:GetCurrentSeason()
        local v143 = v_u_8:GetPlayerData(p140)
        if v143 then
            if v143.Seasons[v142] then
                return v143.Seasons[v142].OwnDungeonExpUp
            end
        end
    else
        return
    end
end
function v_u_7.UnlockSeasonDungeonSpeedUp(_, p144, p145) -- name: UnlockSeasonDungeonSpeedUp
 