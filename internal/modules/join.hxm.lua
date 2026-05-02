return function(env)
  local chat = env.selfchat
  local connect = env.connect
  return {
    name = "join",
    description = "All bots join your server.",
    on = {
      server = function(args)
        chat("Sending join request to clients...")
        return { JobId = game.JobId, PlaceId = game.PlaceId }
      end,
      client = [[(function()
  local data = server_arg
  if not data then return end
  
  game:GetService("TeleportService"):TeleportToPlaceInstance(data.PlaceId, data.JobId, game:GetService("Players").LocalPlayer)
end)()]]
    }
  }
end