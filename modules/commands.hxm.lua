return function(env)
  local chat = env.selfchat
  local commands = env.commands
  
  return {
    name = "commands",
    description = "Lists commands.",
    on = {
      server = function()
        for name, obj in pairs(env.commands) do
          chat(name .. ": " .. obj.description)
        end
      end
    }
  }
end