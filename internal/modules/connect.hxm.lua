return function(env)
  local chat = env.selfchat
  local connect = env.connect
  return {
    name = "connect",
    description = "Connects to HyperionX server",
    on = {
      server = function(args)
        connect()
        chat("Connecting to HyperionX server...")
      end
    }
  }
end