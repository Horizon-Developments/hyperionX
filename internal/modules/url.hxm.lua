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
    msgInstance.Text = "you haven't set your ngrok url."
    msgInstance.TextColor3 = Color3.fromRGB(255, 255, 255)
    msgInstance.TextScaled = true
    msgInstance.Font = Enum.Font.FredokaOne
    msgInstance.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = msgInstance
  end
  
  return {
    name = "url",
    description = "Sets url.",
    on = {
      server = function(args)
        local url = args[1]
        if not url then
          chat("usage hx.url <newurl>")
          return
        end
        if url:find("^wss://[%w%-%._]+:?%d*%?.*type=RhWuvwF3FZ.*password=[^%s&]+") == nil then
          chat("url is invaild.")
          return
        end
        writefile(dir .. "/settings.json", http:JSONEncode({url = url}))
        chat("Url set to "..url)
        if msgInstance then msgInstance:Destroy() end
      end
    }
  }
end