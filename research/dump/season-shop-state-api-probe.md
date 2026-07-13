# Season Shop State API Probe

Goal: find a direct Season shop state API so auto-buy can work outside lobby without relying on `PlayerGui` season shop slots.

Run this in executor in both places:
1. Lobby, with Season Pass store opened once.
2. Dungeon, without opening Season Pass.

Copy F9 lines starting with `[SeasonApiDump]`.

Safety:
- Does **not** call `BuySeasonShopItem`.
- Does **not** fire Season shop buy remotes.
- Calls only read-looking methods: names starting with `Get`, `Is`, `Has`, or `Can`, and skips names containing `buy`, `claim`, `set`, `update`, `fire`, `invoke`, `send`, or `remote`.

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Prefix = "[SeasonApiDump]"
local MaxTableItems = 14
local MaxStringLength = 180

local function TypeOf(Value)
    return typeof and typeof(Value) or type(Value)
end

local function Short(Value, Depth, Seen)
    Depth = Depth or 2
    Seen = Seen or {}

    local ValueType = TypeOf(Value)
    if ValueType == "string" then
        if #Value > MaxStringLength then
            Value = string.sub(Value, 1, MaxStringLength) .. "..."
        end
        return string.format("%q", Value)
    end

    if ValueType == "Instance" then
        return Value:GetFullName() .. " <" .. Value.ClassName .. ">"
    end

    if type(Value) ~= "table" then
        return tostring(Value)
    end

    if Seen[Value] then
        return "{cycle}"
    end

    if Depth <= 0 then
        return "{...}"
    end

    Seen[Value] = true
    local Parts = {}
    local Count = 0
    for Key, ChildValue in pairs(Value) do
        Count = Count + 1
        if Count <= MaxTableItems then
            table.insert(Parts, tostring(Key) .. "=" .. Short(ChildValue, Depth - 1, Seen))
        end
    end
    if Count > MaxTableItems then
        table.insert(Parts, "...+" .. tostring(Count - MaxTableItems))
    end
    Seen[Value] = nil

    return "{" .. table.concat(Parts, ", ") .. "}"
end

local function SortedKeys(Table)
    local Keys = {}
    if type(Table) ~= "table" then
        return Keys
    end

    for Key in pairs(Table) do
        table.insert(Keys, Key)
    end
    table.sort(Keys, function(A, B)
        return tostring(A) < tostring(B)
    end)
    return Keys
end

local function PrintLine(...)
    print(Prefix, ...)
end

local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local SeasonUtil = Framework.Modules and Framework.Modules.SeasonUtil
local DataUtil = Framework.Modules and Framework.Modules.DataUtil

PrintLine("START place=", game.PlaceId, "job=", game.JobId)
PrintLine("SeasonUtil", TypeOf(SeasonUtil), Short(SeasonUtil, 1))

local FunctionEntries = {}
local SeenFunctionNames = {}

local function AddMembers(Label, Table)
    if type(Table) ~= "table" then
        PrintLine("MEMBERS", Label, "not table", TypeOf(Table))
        return
    end

    PrintLine("MEMBERS", Label, "START")
    for _, Key in ipairs(SortedKeys(Table)) do
        local Value = Table[Key]
        local Name = tostring(Key)
        PrintLine("MEMBER", Label .. "." .. Name, TypeOf(Value), type(Value) == "table" and Short(Value, 1) or "")
        if type(Value) == "function" and not SeenFunctionNames[Label .. "." .. Name] then
            SeenFunctionNames[Label .. "." .. Name] = true
            table.insert(FunctionEntries, {Label = Label .. "." .. Name, Name = Name, Fn = Value})
        end
    end
    PrintLine("MEMBERS", Label, "END")
end

AddMembers("SeasonUtil", SeasonUtil)

local MetaOk, Meta = pcall(function()
    return getmetatable(SeasonUtil)
end)
if MetaOk and type(Meta) == "table" then
    AddMembers("SeasonUtil.__index", Meta.__index)
end

if Framework.Modules then
    PrintLine("FRAMEWORK SEASON MODULES START")
    for _, Key in ipairs(SortedKeys(Framework.Modules)) do
        if string.find(string.lower(tostring(Key)), "season") then
            PrintLine("FRAMEWORK MODULE", tostring(Key), TypeOf(Framework.Modules[Key]), Short(Framework.Modules[Key], 1))
        end
    end
    PrintLine("FRAMEWORK SEASON MODULES END")
end

local function DumpFunctionDebug(Entry)
    local Fn = Entry.Fn
    if debug and debug.getinfo then
        local Ok, Info = pcall(debug.getinfo, Fn)
        if Ok and type(Info) == "table" then
            PrintLine("FUNCINFO", Entry.Label, "source=", tostring(Info.source), "line=", tostring(Info.linedefined), "params=", tostring(Info.nparams), "vararg=", tostring(Info.isvararg))
        end
    end

    if getconstants then
        local Ok, Constants = pcall(getconstants, Fn)
        if Ok and type(Constants) == "table" then
            for Index, Constant in pairs(Constants) do
                local Text = tostring(Constant)
                local Lower = string.lower(Text)
                if string.find(Lower, "shop") or string.find(Lower, "season") or string.find(Lower, "normalids") or string.find(Lower, "specialid") or string.find(Lower, "buycount") or string.find(Lower, "refresh") then
                    PrintLine("CONSTANT", Entry.Label, tostring(Index), Short(Constant, 1))
                end
            end
        end
    end

    if getupvalues then
        local Ok, Upvalues = pcall(getupvalues, Fn)
        if Ok and type(Upvalues) == "table" then
            for Key, Upvalue in pairs(Upvalues) do
                local Summary = Short(Upvalue, 2)
                local Lower = string.lower(Summary)
                if string.find(Lower, "shop") or string.find(Lower, "season") or string.find(Lower, "normalids") or string.find(Lower, "specialid") or string.find(Lower, "buycount") or string.find(Lower, "remote") then
                    PrintLine("UPVALUE", Entry.Label, tostring(Key), TypeOf(Upvalue), Summary)
                end
            end
        end
    end
end

local function IsSafeReadName(Name)
    local Lower = string.lower(Name)
    if string.find(Lower, "buy") or string.find(Lower, "claim") or string.find(Lower, "set") or string.find(Lower, "update") or string.find(Lower, "fire") or string.find(Lower, "invoke") or string.find(Lower, "send") or string.find(Lower, "remote") then
        return false
    end

    return string.match(Lower, "^get") or string.match(Lower, "^is") or string.match(Lower, "^has") or string.match(Lower, "^can")
end

PrintLine("FUNCTION DEBUG START")
for _, Entry in ipairs(FunctionEntries) do
    DumpFunctionDebug(Entry)
end
PrintLine("FUNCTION DEBUG END")

PrintLine("SAFE GETTER CALLS START")
for _, Entry in ipairs(FunctionEntries) do
    if IsSafeReadName(Entry.Name) then
        local Calls = {
            {Label = "colon-player", Fn = function() return Entry.Fn(SeasonUtil, LocalPlayer) end},
            {Label = "colon-none", Fn = function() return Entry.Fn(SeasonUtil) end},
            {Label = "dot-player", Fn = function() return Entry.Fn(LocalPlayer) end},
            {Label = "dot-none", Fn = function() return Entry.Fn() end}
        }

        for _, Call in ipairs(Calls) do
            local Ok, Result = pcall(Call.Fn)
            if Ok then
                PrintLine("CALL", Entry.Label, Call.Label, "=>", TypeOf(Result), Short(Result, 2))
            else
                local ErrorText = tostring(Result)
                if string.find(string.lower(Entry.Name), "shop") or string.find(string.lower(Entry.Name), "season") then
                    PrintLine("CALL_FAIL", Entry.Label, Call.Label, ErrorText)
                end
            end
        end
    end
end
PrintLine("SAFE GETTER CALLS END")

local DataPaths = {
    {"Season"},
    {"SeasonData"},
    {"SeasonPass"},
    {"SeasonShop"},
    {"SeasonShopData"},
    {"SeasonStore"},
    {"SeasonCurrency"},
    {"Currency", "SeasonCurrency"},
    {"Currencies", "SeasonCurrency"},
    {"Season", "Shop"},
    {"Season", "ShopData"},
    {"Season", "ShopRefresh"},
    {"Season", "BuyCount"},
    {"SeasonPass", "Shop"},
    {"SeasonPass", "ShopData"},
    {"SeasonPass", "BuyCount"}
}

PrintLine("DATAUTIL PATHS START")
if DataUtil and DataUtil.GetValue then
    for _, Path in ipairs(DataPaths) do
        local Ok, Value = pcall(function()
            return DataUtil:GetValue(LocalPlayer, Path)
        end)
        if Ok then
            PrintLine("DATA", table.concat(Path, "."), TypeOf(Value), Short(Value, 3))
        else
            PrintLine("DATA_FAIL", table.concat(Path, "."), tostring(Value))
        end
    end
else
    PrintLine("DATAUTIL missing")
end
PrintLine("DATAUTIL PATHS END")

PrintLine("PLAYER ATTRIBUTES START")
for Name, Value in pairs(LocalPlayer:GetAttributes()) do
    local Lower = string.lower(tostring(Name))
    if string.find(Lower, "season") or string.find(Lower, "shop") or string.find(Lower, "currency") then
        PrintLine("ATTR", tostring(Name), TypeOf(Value), Short(Value, 1))
    end
end
PrintLine("PLAYER ATTRIBUTES END")

PrintLine("SEASON FEATURE TREE START")
local FeatureRoot = ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("SeasonSystem")
for _, Obj in ipairs(FeatureRoot:GetDescendants()) do
    if Obj:IsA("RemoteEvent") or Obj:IsA("RemoteFunction") or Obj:IsA("BindableEvent") or Obj:IsA("BindableFunction") or Obj:IsA("ModuleScript") then
        PrintLine("FEATURE", Obj:GetFullName(), Obj.ClassName)
    end
end
PrintLine("SEASON FEATURE TREE END")

PrintLine("GUI SHOPIDS START")
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
if PlayerGui then
    for _, Obj in ipairs(PlayerGui:GetDescendants()) do
        local ShopId = Obj:GetAttribute("ShopId")
        if ShopId then
            PrintLine("GUI_SHOPID", Obj:GetFullName(), tostring(ShopId))
        end
    end
else
    PrintLine("GUI missing")
end
PrintLine("GUI SHOPIDS END")

PrintLine("END")
```
