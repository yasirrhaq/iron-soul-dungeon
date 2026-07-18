-- IRON SOUL - CLOUD AUTOEXEC LAUNCHER

local SourceUrl = "https://raw.githubusercontent.com/yasirrhaq/iron-soul-dungeon/main/holygrail/script-v6-full-run-dg.lua?cb=" .. tostring(os.time())
local FetchOk, Source = pcall(function()
    return game:HttpGet(SourceUrl)
end)

if not FetchOk then
    error("[Iron Soul Loader] fetch error: " .. tostring(Source), 0)
end

if type(Source) ~= "string" or Source == "" then
    error("[Iron Soul Loader] fetch error: empty source", 0)
end

print("[Iron Soul Loader] fetched v6 source: " .. tostring(#Source) .. " bytes")
local Chunk, CompileError = loadstring(Source)

if not Chunk then
    error("[Iron Soul Loader] compile error: " .. tostring(CompileError), 0)
end

local Success, RuntimeError = pcall(Chunk)
if not Success then
    error("[Iron Soul Loader] runtime error: " .. tostring(RuntimeError), 0)
end
