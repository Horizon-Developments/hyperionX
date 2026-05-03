local services = {}

local cloneref = cloneref or function(x) return x end

services.http = cloneref(game:GetService("HttpService"))
services.players = cloneref(game:GetService("Players"))
services.lighting = cloneref(game:GetService("Lighting"))
services.textchat = cloneref(game:GetService("TextChatService"))
services.coregui = cloneref(game:GetService("CoreGui"))

local LocalPlayer = services.players.LocalPlayer
local rbxgeneral = services.textchat:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
local UIParent = (gethui and gethui()) or services.coregui or LocalPlayer:WaitForChild("PlayerGui")
local delay = 1

assert(WebSocket, "Executor does not support WebSocket.")
assert(isfile, "Executor does not support isfile.")
assert(writefile, "Executor does not support writefile.")
assert(readfile, "Executor does not support readfile.")

local cache = {
  on_hub = function() return game.PlaceId == 18397226569 end,
  say = function(m) rbxgeneral:SendAsync(m) end,
  cmd = function(m) rbxgeneral:SendAsync(";" .. tostring(m) .. " discord.gg/ARad6VdKw9") end,
  selfchat = function(m) rbxgeneral:DisplaySystemMessage('<font color="rgb(255,0,0)">[HX]: ' .. m .. '</font>') end
}

function connect()
  local ok, err = pcall(function()
    local ok, json = pcall(function()
      return services.http:JSONDecode(readfile("HyperionX.token"):gsub("..", function(cc)
        return string.char(tonumber(cc, 16))
      end))
    end)
    
    local ok, ws = pcall(function()
      return WebSocket.connect(json.url)
    end)
    if (not ok or not ws) then
      return retryconnect()
    end
    delay = 1
    ws.OnClose:Connect(retryconnect)
    ws.OnMessage:Connect(function(m)
      if (m == "challenge") then
        ws:Send(services.http:JSONEncode({ password = json.password, type = "client" }))
        return
      end
      
      task.spawn(pcall, function()
        local json =  services.http:JSONDecode(m)
        
        if (type(json) ~= "table" or not json.owner or not json.script) then
          return
        end
        
        local env = getgenv()
        
        local merged = setmetatable({
          ownerid = json.owner,
          args = json.args, -- optional
          server_arg = json.server_arg, -- optional 
          getownerinstance = function() return services.players:GetPlayerByUserId(json.owner) end
        }, {
          __index = function(_, k)
            return (cache[k] ~= nil and cache[k]) or env[k]
          end,
          __newindex = function(_, k, v)
            env[k] = v
          end,
          __metatable = "locked"
        })
        
        local fn = loadstring(json.script)
        
        setfenv(fn, merged)
        
        fn()
      end)
    end)
  end)
  if (not ok) then
    print("CONNECT ERR", err)
    retryconnect()
  end
end

function retryconnect()
  delay = math.min(delay * 2, 30)
  task.delay(delay, connect)
end

local gui = Instance.new("ScreenGui")
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = UIParent

local blur = Instance.new("BlurEffect")
blur.Size = 24
blur.Parent = services.lighting

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
bg.BackgroundTransparency = 1
bg.BorderSizePixel = 0
bg.Parent = gui

local text = Instance.new("TextLabel")
text.Size = UDim2.fromScale(1, 0.1)
text.Position = UDim2.fromScale(0, 0.3)
text.BackgroundTransparency = 1
text.Text = "to connect, place token in the box"
text.TextColor3 = Color3.fromRGB(255, 0, 0)
text.TextScaled = true
text.Font = Enum.Font.FredokaOne
text.Parent = bg

local box = Instance.new("TextBox")
box.Size = UDim2.fromScale(0.3, 0.1)
box.AnchorPoint = Vector2.new(0.5, 0.5)
box.Position = UDim2.fromScale(0.5, 0.5)
box.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.PlaceholderText = "token"
box.Text = ""
box.ClearTextOnFocus = false
box.TextScaled = true
box.Font = Enum.Font.FredokaOne
box.BorderSizePixel = 0
box.Parent = bg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = box

local button = Instance.new("TextButton")
button.Size = UDim2.fromScale(0.3, 0.1)
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.Position = UDim2.fromScale(0.5, 0.6)
button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Text = "use old"
button.TextScaled = true
button.Font = Enum.Font.FredokaOne
button.BorderSizePixel = 0
button.Parent = bg

function uihandler()
  text:Destroy()
  box:Destroy()
  button:Destroy()
  blur:Destroy()
  gui:Destroy()
  
  connect()
  
  if (game.PlaceId ~= 18397226569) then return end
  
  local hub = Instance.new("TextLabel")
  hub.Size = UDim2.fromScale(1, 0.5)
  hub.Position = UDim2.fromScale(0, 0.3)
  hub.BackgroundTransparency = 1
  hub.Text = "you are in the HyperionX hub. Please wait.\nDO NOT LEAVE"
  hub.TextColor3 = Color3.fromRGB(255, 0, 0)
  hub.TextScaled = true
  hub.Font = Enum.Font.FredokaOne
  hub.Parent = UIParent
end

local debounce1 = false
local debounce2 = false

box.FocusLost:Connect(function(enterPressed)
  if (debounce1) then return end
  if (not enterPressed) then return end
  debounce1 = true
  local chat = cache.selfchat
  
  local ok, json = pcall(function()
    return services.http:JSONDecode(box.Text:gsub("..", function(cc)
      return string.char(tonumber(cc, 16))
    end))
  end)
  
  if (not ok or not json or not json.url or not json.password or not json.type) then
    chat("token is corrupted.")
    return
  end
  if (json.type ~= "client") then
    chat("token isnt for client")
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
  
  writefile("HyperionX.token", services.http:JSONEncode({
    url = json.url,
    password = json.password
  }))
  
  uihandler()
  debounce1 = false
end)

button.MouseButton1Click:Connect(function()
  if (debounce2) then return end
  if (debounce1) then return end
  if (not isfile("HyperionX.token")) then
    debounce2 = true
    button.Active = false
    
    local oldText = button.Text
    button.Text = "no old token was set!"
    
    task.wait(0.6)
    
    button.Text = oldText
    button.Active = true
    debounce2 = false
    return
  end
  uihandler()
end)

task.spawn(function()
  if (not isfile("HyperionX.token")) then return end
  for i = 10, 0, -1 do
    button.Text = "use old (" .. i .. ")"
    task.wait(1)
  end
  uihandler()
end)