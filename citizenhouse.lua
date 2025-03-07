local enet = require "enet"


CitizenHouse = {
	layers = {
		updateOrder = {
			"input",
			"prediction",
			"network_in",
			"network_out"
		},
		drawOrder = {
			"newsstand",
			"draft",
			"ui"
		}
	}
};
math.randomseed(os.time());
function CitizenHouse:init()
  self.step_size = 3
  self.t = 0
  self.updaterate = 0.06
	self.entity = tostring(math.random(99999));
	self.state = {};
	self.state[self.entity] = {
		x = math.random(800),
		y = math.random(600)
	};
  self.host = enet.host_create()
  self.server = self.host:connect("localhost:6789")
	DraftNotebook = {
		predictLocalActions = function()
		end,
		reconcileWithTimeTraveler = function()
		end
	};
	Newsstand = {
		updateFromTownCrier = function()
      local event = self.host:service(100)
      if event then
        if event.type == "receive" then
          -- print("Got message: ", event.data, event.peer)
          data = event.data
          -- update state
          for line in data:gmatch("([^\n]*)\n") do
            local entity, cmd, parms = line:match("^(%S*) (%S*) (.*)")
            if cmd == "at" then
              -- print("at", entity, parms)

              local x, y = parms:match("^(%S*) (%S*)")
              self.state[entity] = {
                x = tonumber(x),
                y = tonumber(y)
              }
            else
              print("unrecognised command:", cmd)
            end
          end
        end
      end
  
		end
	};
	PigeonCourier = {
		sendToTownHall = function()
      local dx, dy = 0, 0
      moved = false
      if self.t > self.updaterate then
        if love.keyboard.isDown("up") then
          moved = true
          dy = -self.step_size
        end;
        if love.keyboard.isDown("down") then
          moved = true
          dy = self.step_size
        end;
        if love.keyboard.isDown("left") then
          moved = true
          dx = -self.step_size
        end;
        if love.keyboard.isDown("right") then
          moved = true
          dx = self.step_size
        end;
        self.t = 0
      end;
      if moved then
        local dg = string.format("%s %s %f %f", self.entity, "move", dx, dy);
        self.server:send(dg);
      end
		end,
		handleLostPigeons = function()
		end
	};
	HeartbeatSystem = {
		sendStillHerePing = function()
		end
	};
	HouseViewingWindow = {
		drawOfficialNews = function()
			for k, v in pairs(self.state) do
				love.graphics.print(k .. "  " .. v.x .. "  " .. v.y, v.x, v.y);
			end;
		end,
		drawDraftPredictions = function()
		end,
		drawCitizenUI = function()
			love.graphics.print("Citizen: " .. self.entity, 0, 0);
		end
	};

  self.host:service(100)
  local dg = string.format("%s %s %f %f", self.entity, "at", self.state[self.entity].x, self.state[self.entity].y);
  self.server:send(dg);
end;
function CitizenHouse:update(dt)
	self.t = self.t + dt;
	for _, layer in ipairs(CitizenHouse.layers.updateOrder) do
		if layer == "prediction" then
			DraftNotebook.predictLocalActions();
		elseif layer == "network_in" then
			Newsstand.updateFromTownCrier();
		elseif layer == "network_out" then
      self.host:service(100)

			PigeonCourier.handleLostPigeons();
			PigeonCourier.sendToTownHall();
			HeartbeatSystem.sendStillHerePing();
		end;
	end;
end;
function CitizenHouse:draw()
	for _, layer in ipairs(CitizenHouse.layers.drawOrder) do
		if layer == "newsstand" then
			HouseViewingWindow.drawOfficialNews();
		elseif layer == "draft" then
			HouseViewingWindow.drawDraftPredictions();
		elseif layer == "ui" then
			HouseViewingWindow.drawCitizenUI();
		end;
	end;
end;
