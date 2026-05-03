return function(env)
  local chat = env.selfchat
  local dir = env.dir
  local http = env.services.http
  local localplr = env.services.players.LocalPlayer
  local msgInstance;
  
  if (http:JSONDecode(readfile(dir .. "/settings.json")).url == "") then
    local gui = Instance.new("ScreenGui")
    gui.ResetOnSpawn = false
    gui.Parent = (gethui and gethui()) or localplr:WaitForChild("PlayerGui")
    
    msgInstance = Instance.new("TextLabel")
    msgInstance.Size = UDim2.new(0, 220, 0, 50)
    msgInstance.Position = UDim2.new(0.5, -110, 0, -50)
    msgInstance.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    msgInstance.BorderSizePixel = 0
    msgInstance.Text = "set your token. (hx.token)"
    msgInstance.TextColor3 = Color3.fromRGB(255, 255, 255)
    msgInstance.TextScaled = true
    msgInstance.Font = Enum.Font.FredokaOne
    msgInstance.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = msgInstance
  end
  
  return {
    name = "token",
    description = "Sets token.",
    on = {
      server = function(args)
        local token = args[1]
        if not token then
          chat("usage hx.token <token>")
          return
        end
        
        local ok, json = pcall(function()
          return http:JSONDecode(token:gsub("..", function(cc)
            return string.char(tonumber(cc, 16))
          end))
        end)
        
        if (not ok or not json or not json.url or not json.password or not json.type) then
          chat("token is corrupted.")
          return
        end
        
        if (json.type ~= "RhWuvwF3FZ") then
          chat("token isnt for owner")
          return
        end
        
        if not json.url:find("^wss://[^%?]+$") then
          chat("token url is invaild.")
          return
        end
        
        if not json.password:find("^[A-Za-z0-9._-]+$") then
          chat("token password is invaild.")
          return
        end
        
        writefile(dir .. "/settings.json", http:JSONEncode({
          url = json.url,
          password = json.password
        }))
        
        chat("token set.")
        
        if msgInstance then msgInstance:Destroy() end
      end
    }
  }
end