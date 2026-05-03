return function(env)
  local chat = env.selfchat
  return {
    name = "discord",
    description = "Shows discord (IMPORTANT)",
    on = {
      server = function(args)
        chat(game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperionX/main/internal/discord.txt"))
      end
    }
  }
end