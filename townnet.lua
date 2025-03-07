enet = require "enet"


-- ========================
-- Town Hall (Host) Module
-- ========================
TownHall = {
  layers = {
    updateOrder = {"input", "logic", "network_in", "network_out"},
    drawOrder = {"world", "ui"}
  }
}


function TownHall:init()
  self.state = {}
  self.data = nil
  self.cmd = nil
  self.parms = nil
  self.host = enet.host_create("localhost:6789")
  self.t = 0
  self.updaterate = 0.1

  ControlPanel = {
    -- Dashboard translating player inputs to actions
    handleLocalInputs = function()
    end
  }

  MasterClock = {
    -- Central game state updater
    updateWorldState = function(k, v)
      if k and v then
        self.state[k] = v
      end
    end,
    checkForCheatingMerchants = function() end  -- Anti-cheat
  }

  TownCrier = {
    -- Broadcasts world state to all
    broadcastWorldState = function(dt)
      if self.t < self.updaterate then return end
      -- Broadcast entire state for all entities
      local dg = ""
      for k, v in pairs(self.state) do
        dg = dg .. string.format("%s %s %d %d\n", k, 'at', v.x, v.y)
      end
      self.host:broadcast(dg)
      -- t is just a variable we use to help us with the update rate in love.update.
      self.t = self.t - self.updaterate
    
    end,
    throttleChattyUpdates = function() end  -- Bandwidth control
  }

  MailDropbox = {
    -- Receives citizen inputs
    collectIncomingLetters = function()
      local event = self.host:service(100)

      if event then
        if event.type == "receive" then
          data = event.data
          -- update state
          entity, cmd, parms = data:match("^(%S*) (%S*) (.*)")
          if cmd == 'move' then
            local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
            assert(x and y) -- validation is better, but asserts will serve.
            x, y = tonumber(x), tonumber(y)
            local ent = self.state[entity] or {x=0, y=0}
            self.state[entity] = {x=ent.x+x, y=ent.y+y}
          elseif cmd == 'at' then
            local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
            assert(x and y) -- validation is better, but asserts will serve.
            x, y = tonumber(x), tonumber(y)
            self.state[entity] = {x=x, y=y}
          elseif cmd == 'quit' then
            running = false;
          else
            print("unrecognised command:", cmd)
          end
        elseif event.type == "connect" then
          print(event.peer, "connected.")
        elseif event.type == "disconnect" then
          print(event.peer, "disconnected.")
        end
      end
           
    end,
    sortWithNumberedLetters = function() end  -- Fix packet reordering
  }

  ViewingWindow = {
    drawTownActivity = function()
      for k, v in pairs(self.state) do
        love.graphics.print(k .. "  " .. v.x .. "  " .. v.y, v.x, v.y)
      end
    end,
    drawTownBulletin = function()
      -- love.graphics.print("Town Hall", 0, 0)
    end  -- UI layer
  }
end

function TownHall:update(dt)
  self.t = self.t + dt
  for _, layer in ipairs(TownHall.layers.updateOrder) do
    if layer == "input" then
      ControlPanel.handleLocalInputs()
    elseif layer == "logic" then
      MasterClock.updateWorldState()
      MasterClock.checkForCheatingMerchants()
    elseif layer == "network_in" then
      MailDropbox.collectIncomingLetters()
      MailDropbox.sortWithNumberedLetters()
    elseif layer == "network_out" then
      TownCrier.throttleChattyUpdates()
      TownCrier.broadcastWorldState(dt)
    end
  end
end

function TownHall:draw()
  -- print('hii', self.state)
  for _, layer in ipairs(TownHall.layers.drawOrder) do
    if layer == "world" then
      ViewingWindow.drawTownActivity()
    elseif layer == "ui" then
      ViewingWindow.drawTownBulletin()
    end
  end
end
