 UI Dump
  Run when party create screen open:

```lua
local Players = game:GetService("Players")
  local LocalPlayer = Players.LocalPlayer
  local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

  local Lines = {"# UI Dump", ""}

  local function S(value)
      return tostring(value or "")
  end

  local function FullName(obj)
      local ok, result = pcall(function()
          return obj:GetFullName()
      end)
      return ok and S(result) or S(obj)
  end

  local function TextOf(obj)
      if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
          local ok, result = pcall(function()
              return obj.Text
          end)
          return ok and S(result) or ""
      end
      return ""
  end

  local function Add(line)
      print(line)
      table.insert(Lines, line)
  end

  for _, obj in ipairs(PlayerGui:GetDescendants()) do
      if obj:IsA("TextButton") or obj:IsA("ImageButton") or obj:IsA("TextLabel") or obj:IsA("TextBox") then
          local path = FullName(obj)
          local name = S(obj.Name)
          local className = S(obj.ClassName)
          local text = TextOf(obj)
          local visible = S(obj.Visible)

          local combined = string.lower(path .. " " .. name .. " " .. text)
          if string.find(combined, "dungeon")
              or string.find(combined, "party")
              or string.find(combined, "create")
              or string.find(combined, "start")
              or string.find(combined, "return")
              or string.find(combined, "lobby")
              or string.find(combined, "player")
              or string.find(combined, "max") then
              Add(string.format(
                  "- `%s` | `%s` | Name=`%s` | Text=`%s` | Visible=`%s`",
                  path,
                  className,
                  name,
                  text,
                  visible
              ))
          end
      end
  end

  local Output = table.concat(Lines, "\n")

  if writefile then
      if makefolder then
          pcall(function()
              makefolder("dump")
          end)
      end
      writefile("dump/UI-dump.md", Output)
      print("[UIDump] wrote dump/UI-dump.md")
  elseif setclipboard then
      setclipboard(Output)
      print("[UIDump] copied to clipboard")
  else
      print("[UIDump] no writefile/setclipboard; copy F9 lines manually")
  end

  Remote Sniff
  Run before manual create/start:

  local oldNamecall
  oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
      local method = getnamecallmethod()
      local args = {...}

      if method == "FireServer" or method == "InvokeServer" then
          local path = self:GetFullName()
          local joined = ""
          for i, v in ipairs(args) do
              joined ..= " [" .. i .. "]=" .. tostring(v)
          end
          if string.find(string.lower(path .. joined), "dungeon")
              or string.find(string.lower(path .. joined), "party")
              or string.find(string.lower(path .. joined), "match")
              or string.find(string.lower(path .. joined), "room") then
              print("[DungeonRemote]", method, path, joined)
          end
      end

      return oldNamecall(self, ...)
  end)

Pakai remote sniff ini. Run dulu, lalu manual:

  1. pilih World3
  2. difficulty 10
  3. set party 1/1
  4. klik create/start

  local oldNamecall
  oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
      local method = getnamecallmethod()
      local args = {...}

          local line = "[RemoteSniff] " .. method .. " " .. path

          for i, v in ipairs(args) do
              line ..= " [" .. i .. "]=" .. tostring(v)
          end

          local lower = string.lower(line)
          if string.find(lower, "match")
              or string.find(lower, "world")
              or string.find(lower, "dungeon")
              or string.find(lower, "room")
              or string.find(lower, "party")
              or string.find(lower, "create")
              or string.find(lower, "start") then
              print(line)
          end
      end

      return oldNamecall(self, ...)
  end)

  print("[RemoteSniff] ready")
```


