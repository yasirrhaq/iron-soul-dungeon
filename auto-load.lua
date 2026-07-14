-- IRON SOUL - CLOUD AUTOEXEC LAUNCHER

local SourceUrl = "https://raw.githubusercontent.com/yasirrhaq/iron-soul-dungeon/main/holygrail/script-v6-full-run-dg.lua"
local Source = game:HttpGet(SourceUrl)
local Chunk, CompileError = loadstring(Source)

if not Chunk then
    error("[Iron Soul Loader] compile error: " .. tostring(CompileError), 0)
end

local Success, RuntimeError = pcall(Chunk)
if not Success then
    error("[Iron Soul Loader] runtime error: " .. tostring(RuntimeError), 0)
end
