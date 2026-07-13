# Forge Sell API Probe

Goal: find an ore sell API that works outside lobby, instead of `ForgeRF:InvokeServer("Sell", SellList)` silently doing nothing in dungeon.

Run this in executor in dungeon. Copy F9 lines starting with `[ForgeSellProbe]`.

Safety:
- Does **not** call `ForgeRF:InvokeServer("Sell", ...)`.
- Does **not** fire sell remotes.
- Calls only read-looking methods (`Get*`, `Is*`, `Has*`, `Can*`) and skips names containing `sell`, `buy`, `claim`, `set`, `update`, `fire`, `invoke`, `send`, `remote`.
- Uses `debug/getconstants/getupvalues` when available to inspect function internals without executing sell actions.

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))

local Prefix = "[ForgeSellProbe]"
local ClipboardLines = {}
local ImportantLines = {}
local MaxTableItems = 18
local MaxStringLength = 220

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
    for Key, Child in pairs(Value) do
        Count = Count + 1
        if Count <= MaxTableItems then
            table.insert(Parts, tostring(Key) .. "=" .. Short(Child, Depth - 1, Seen))
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

local function Log(...)
    local Parts = {Prefix}
    for Index = 1, select("#", ...) do
        table.insert(Parts, tostring(select(Index, ...)))
    end

    local Line = table.concat(Parts, " ")
    print(Line)
    table.insert(ClipboardLines, Line)
    if string.find(Line, "START") or string.find(Line, "END") or string.find(Line, "REMOTE") or string.find(Line, "TREE") or string.find(Line, "DATA") or string.find(Line, "CALL") or string.find(Line, "Sell") or string.find(Line, "Forge") or string.find(Line, "Ore") or string.find(Line, "Ores") or string.find(Line, "EquipmentRE") or string.find(Line, "RemoteEvent") or string.find(Line, "RemoteFunction") then
        table.insert(ImportantLines, Line)
    end
end

local function CopyProbeLogToClipboard()
    local Lines = #ImportantLines > 0 and ImportantLines or ClipboardLines
    local Text = table.concat(Lines, "\n")
    if setclipboard then
        local Ok, Err = pcall(function()
            setclipboard(Text)
        end)
        if Ok then
            print(Prefix, "COPIED_TO_CLIPBOARD", tostring(#Lines), "important lines")
        else
            print(Prefix, "COPY_FAILED", tostring(Err))
        end
    else
        print(Prefix, "COPY_UNAVAILABLE", "setclipboard missing")
    end
end

local FunctionEntries = {}
local SeenFunctions = {}

local function LogMultiline(Label, Text)
    Text = tostring(Text)
    for Line in string.gmatch(Text .. "\n", "([^\n]*)\n") do
        if Line ~= "" then
            Log(Label, Line)
        end
    end
end

local function AddMembers(Label, Table)
    if type(Table) ~= "table" then
        Log("MEMBERS", Label, "not table", TypeOf(Table), Short(Table, 1))
        return
    end

    Log("MEMBERS", Label, "START")
    for _, Key in ipairs(SortedKeys(Table)) do
        local Value = Table[Key]
        local Name = tostring(Key)
        local Lower = string.lower(Name)
        if string.find(Lower, "sell") or string.find(Lower, "forge") or string.find(Lower, "ore") or string.find(Lower, "inventory") or string.find(Lower, "bag") or string.find(Lower, "item") or type(Value) == "function" then
            Log("MEMBER", Label .. "." .. Name, TypeOf(Value), type(Value) == "table" and Short(Value, 1) or "")
        end
        if type(Value) == "function" and not SeenFunctions[Label .. "." .. Name] then
            SeenFunctions[Label .. "." .. Name] = true
            table.insert(FunctionEntries, {Label = Label .. "." .. Name, Name = Name, Fn = Value})
        end
    end
    Log("MEMBERS", Label, "END")
end

local function AddMetaMembers(Label, Table)
    local Ok, Meta = pcall(function()
        return getmetatable(Table)
    end)
    if Ok and type(Meta) == "table" then
        AddMembers(Label .. ".__index", Meta.__index)
    end
end

local function IsInterestingText(Text)
    local Lower = string.lower(tostring(Text))
    return string.find(Lower, "sell") or string.find(Lower, "forge") or string.find(Lower, "ore") or string.find(Lower, "inventory") or string.find(Lower, "bag") or string.find(Lower, "equip") or string.find(Lower, "screen") or string.find(Lower, "remote") or string.find(Lower, "clear")
end

local function DumpFunctionDebug(Entry)
    if debug and debug.getinfo then
        local Ok, Info = pcall(debug.getinfo, Entry.Fn)
        if Ok and type(Info) == "table" then
            Log("FUNCINFO", Entry.Label, "source=", tostring(Info.source), "line=", tostring(Info.linedefined), "params=", tostring(Info.nparams), "vararg=", tostring(Info.isvararg))
        end
    end

    if getconstants then
        local Ok, Constants = pcall(getconstants, Entry.Fn)
        if Ok and type(Constants) == "table" then
            for Index, Constant in pairs(Constants) do
                if IsInterestingText(Constant) then
                    Log("CONSTANT", Entry.Label, tostring(Index), Short(Constant, 1))
                end
            end
        end
    end

    if getupvalues then
        local Ok, Upvalues = pcall(getupvalues, Entry.Fn)
        if Ok and type(Upvalues) == "table" then
            for Key, Upvalue in pairs(Upvalues) do
                local Summary = Short(Upvalue, 2)
                if IsInterestingText(Summary) then
                    Log("UPVALUE", Entry.Label, tostring(Key), TypeOf(Upvalue), Summary)
                end
            end
        end
    end

end

local function IsSafeReadName(Name)
    local Lower = string.lower(Name)
    if string.find(Lower, "sell") or string.find(Lower, "buy") or string.find(Lower, "claim") or string.find(Lower, "set") or string.find(Lower, "update") or string.find(Lower, "fire") or string.find(Lower, "invoke") or string.find(Lower, "send") or string.find(Lower, "remote") or string.find(Lower, "clear") then
        return false
    end
    return string.match(Lower, "^get") or string.match(Lower, "^is") or string.match(Lower, "^has") or string.match(Lower, "^can")
end

local function LogCall(Label, Fn)
    local Ok, A, B, C = pcall(Fn)
    if Ok then
        Log("CALL", Label, "OK", TypeOf(A), Short(A, 2), Short(B, 1), Short(C, 1))
    else
        Log("CALL", Label, "FAIL", tostring(A))
    end
end

Log("START", "place", game.PlaceId, "job", game.JobId)

local ForgeUtilScript = ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("ForgeSystem"):FindFirstChild("ForgeUtil")
if decompile and ForgeUtilScript then
    local Ok, Source = pcall(decompile, ForgeUtilScript)
    if Ok then
        LogMultiline("DECOMPILE ForgeUtil", string.sub(tostring(Source), 1, 20000))
    else
        Log("DECOMPILE_FAIL", "ForgeUtil", tostring(Source))
    end
end

local ModuleNames = {}
for Name, Module in pairs(Framework.Modules or {}) do
    local Lower = string.lower(tostring(Name))
    if string.find(Lower, "forge") or string.find(Lower, "ore") or string.find(Lower, "inventory") or string.find(Lower, "equip") or string.find(Lower, "item") or string.find(Lower, "redpoint") or string.find(Lower, "data") then
        table.insert(ModuleNames, Name)
        Log("FRAMEWORK MODULE", tostring(Name), TypeOf(Module), Short(Module, 1))
        AddMembers(tostring(Name), Module)
        AddMetaMembers(tostring(Name), Module)
    end
end

Log("FUNCTION DEBUG START")
for _, Entry in ipairs(FunctionEntries) do
    DumpFunctionDebug(Entry)
end
Log("FUNCTION DEBUG END")

Log("SAFE CALLS START")
for _, Entry in ipairs(FunctionEntries) do
    if IsSafeReadName(Entry.Name) then
        local ModuleLabel = string.match(Entry.Label, "^([^%.]+)")
        local Module = Framework.Modules and Framework.Modules[ModuleLabel]
        if Module then
            LogCall(Entry.Label .. " colon-player", function()
                return Entry.Fn(Module, LocalPlayer)
            end)
            LogCall(Entry.Label .. " dot-player", function()
                return Entry.Fn(LocalPlayer)
            end)
            LogCall(Entry.Label .. " colon-noarg", function()
                return Entry.Fn(Module)
            end)
        end
    end
end
Log("SAFE CALLS END")

local FeaturePaths = {
    ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):FindFirstChild("ForgeSystem"),
    ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):FindFirstChild("InventorySystem"),
    ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):FindFirstChild("EquipmentSystem"),
    ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Systems"):FindFirstChild("RedPointSystem")
}

Log("REMOTE TREE START")
for _, Root in ipairs(FeaturePaths) do
    if Root then
        Log("TREE_ROOT", Root:GetFullName())
        for _, Obj in ipairs(Root:GetDescendants()) do
            if Obj:IsA("RemoteEvent") or Obj:IsA("RemoteFunction") or Obj:IsA("BindableEvent") or Obj:IsA("BindableFunction") or Obj:IsA("ModuleScript") then
                Log("TREE", Obj:GetFullName(), Obj.ClassName)
            end
        end
    end
end
Log("REMOTE TREE END")

local DataUtil = Framework.Modules and Framework.Modules.DataUtil
Log("DATA PATHS START")
if DataUtil and DataUtil.GetValue then
    local Paths = {
        {"Ores"},
        {"Inventory"},
        {"Backpack"},
        {"Bag"},
        {"Forge"},
        {"Forge", "Ores"},
        {"Equipment"},
        {"Materials"},
        {"Items"}
    }
    for _, Path in ipairs(Paths) do
        local Ok, Value = pcall(function()
            return DataUtil:GetValue(LocalPlayer, Path)
        end)
        if Ok then
            Log("DATA", table.concat(Path, "."), TypeOf(Value), Short(Value, 2))
        else
            Log("DATA_FAIL", table.concat(Path, "."), tostring(Value))
        end
    end
else
    Log("DATAUTIL missing")
end
Log("DATA PATHS END")

Log("END")
CopyProbeLogToClipboard()
```
