return function(env)
  local chat = env.selfchat
  local connect = env.connect
  return {
    name = "donate",
    description = "Donates ALL bots time to you.",
    on = {
      client = [[(function(plr)
if (not plr) then return end
local time = tonumber(game:GetService("Players").LocalPlayer.Character:WaitForChild("Tiempo"):WaitForChild("Text1"):WaitForChild("Text").Text:match("%d+"))
if (not time) then return end
cmd("donate " .. plr.Name .. " " .. time)
end)(getownerinstance())]]
    }
  }
end