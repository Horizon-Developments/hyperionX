return function(env)
  local chat = env.selfchat
  local connect = env.connect
  return {
    name = "donate",
    description = "Donates ALL bots time to you.",
    on = {
      client = [[(function(plr)
if (not plr) then return end
local time = game:GetService("Players").LocalPlayer.Character:WaitForChild("Tiempo"):WaitForChild("Text1"):WaitForChild("Text").Text
cmd("donate " .. plr.Name .. " " .. time)
end)(getownerinstance())]]
    }
  }
end