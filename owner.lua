local services = {}

local cloneref = cloneref or function(x) return x end

services.tcs = cloneref(game:GetService("TextChatService"))
services.http = cloneref(game:GetService("HttpService"))
services.players = cloneref(game:GetService("Players"))
services.tp = cloneref(game:GetService("TeleportService"))
services.sg  = cloneref(game:GetService("StarterGui"))

local tcs = services.tcs
local http = services.http
local players = services.players

local rbxgeneral = tcs:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
local request = http_request or request or syn.request

local LocalPlayer = players.LocalPlayer

local retryDelay = 1
local dir = "HyperionX"
local ws

function selfchat(m)
  rbxgeneral:DisplaySystemMessage('<font color="#FF0000">[HX]: ' .. m .. '</font>')
end

selfchat("Loading HyperionX")
(function(funcs)
  for name, fn in pairs(funcs) do
    assert(typeof(fn) == "function", "Executor does not support: " .. name)
  end
end)({
  getgenv = getgenv,
  WebSocket = WebSocket,
  isfolder = isfolder,
  makefolder = makefolder,
  listfiles = listfiles,
  writefile = writefile,
  readfile = readfile,
  delfile = delfile,
  isfile = isfile,
  request = request
})


if not isfolder(dir) then
  makefolder(dir)
  makefolder(dir .. "/modules")
  makefolder(dir .. "/internal")
end

if not isfile(dir .. "/settings.json") then 
  writefile(dir .. "/settings.json", '{"url":"","password":""}')
else
  local ok = pcall(function() http:JSONDecode(readfile(dir .. "/settings.json")) end)
  if (not ok) then writefile(dir .. "/settings.json", '{"url":"","password":""}') end
end

function connect()
  local ok = pcall(function()
    local json = http:JSONDecode(readfile(dir .. "/settings.json"))
    local url = json.url
    local password = json.password
    
    if (not url or url == "" or not password or password == "") then
      selfchat("Set token first")
      return
    end
    
    if ws then
      pcall(function() ws:Close() end)
    end
    
    local success, val = pcall(function()
      return WebSocket.connect(url)
    end)
    
    if not success then
      selfchat("failed to reconnect to ws. err in console")
      print(val)
      return
    end
    
    ws = val
    retryDelay = 1
    
    ws.OnMessage:Connect(function(m)
      if (m == "challenge") then
        ws:Send(http:JSONEncode({ password = password, type = "RhWuvwF3FZ" }))
      end
    end)
    
    ws.OnClose:Connect(retryconnect)
  end)
end

function retryconnect()
  task.delay(retryDelay, function()
    retryDelay = math.min(retryDelay * 2, 30)
    connect()
  end)
end

local commands = {}

do
  for i, file in ipairs(http:JSONDecode(game:HttpGet("https://api.github.com/repos/Horizon-Developments/hyperionX/contents/internal/modules?ref=main"))) do
    if file.type == "file" and not isfile(dir .. "/modules/" .. file.name) then
      writefile(dir .. "/modules/" .. file.name, game:HttpGet(file.download_url))
    end
  end
  
  if isfile(dir .. "/modules/delete.json") then
    pcall(function()
      local json = http:JSONDecode(readfile(dir .. "/modules/delete.json"))
      for _, name in ipairs(json) do
        local file = dir .. "/modules/" .. name
        if isfile(file) then
          pcall(delfile, file)
        end
      end
    end)
    delfile(dir .. "/modules/delete.json")
  end
  for _, path in ipairs(listfiles(dir .. "/modules")) do
    local name = path:match("[^/\\]+$")
    
    if name:sub(-8) == ".hxm.lua" then
      continue
    end
    local ok, obj = pcall(function()
      return loadstring(readfile(path))()({
        commands = commands,
        connect = newcclosure(function()
          connect()
        end),
        dir = dir,
        selfchat = selfchat,
        request = request,
        services = services
      })
    end)
    if ok and typeof(obj) == "table" then
      if obj.__ONLY_INIT then
        continue
      end
      
      if typeof(obj.on) == "table"
        and (typeof(obj.on.server) == "function" or typeof(obj.on.client) == "string")
        and typeof(obj.description) == "string"
        and typeof(obj.name) == "string"
        and obj.name:match("^[0-9a-zA-Z]+$")
      then
        commands[obj.name] = obj
        selfchat("module " .. name .. " loaded.")
      else
        selfchat("module " .. tostring(name) .. " is invalid.")
      end
    else
      selfchat("module " .. tostring(name) .. " is invalid.")
    end
  end
end

function handler(m)
  local args = {}

  local text = m.Text or ""
  local cmd = text:match("^hx%.%s*(.*)") or ""

  for w in cmd:gmatch("%S+") do
    args[#args + 1] = w
  end

  local name = table.remove(args, 1)
  local obj = commands[name]

  local onServerarg
  local env = getgenv()

  if not obj then
    return selfchat("unknown command.")
  end

  local merged = setmetatable({
    onServerarg = onServerarg
  }, {
    __index = env,
    __newindex = function(_, k, v)
      env[k] = v
    end,
    __metatable = "locked"
  })

  if typeof(obj.on.server) == "function" then
    setfenv(obj.on.server, merged)
    local ok, val = pcall(obj.on.server, args)
    if ok then onServerarg = val end
  end

  if not obj.on.client then
    return
  end

  if not ws then
    return selfchat("Client not connected")
  end
  
  pcall(function() ws:Send(http:JSONEncode({
    script = obj.on.client,
    serverarg = onServerarg,
    args = args,
    owner = LocalPlayer.UserId
  })) end)
end

do
  local tcmp = Instance.new("TextChatMessageProperties")
  tcs.OnIncomingMessage = function(m)
    if m.Text and m.Text:sub(1, 3) == "hx." and m.TextSource and m.TextSource.UserId == LocalPlayer.UserId then
      task.spawn(handler, m)
      m.Text = ""
    end
    return tcmp
  end
end

selfchat("HyperionX loaded.")