function love.load()
	ents = {}
	colliders = {}
	love.window.setMode(800, 600, {
		fullscreen = true,
		fullscreentype = "desktop",
	})
	WIDTH, HEIGHT = love.window.getDimensions()

	function screenToWorld(x, y)
		return x - WIDTH / 2, -(y - HEIGHT / 2)
	end
	function center(x1, y1, x2, y2)
		return (x1 + x2) / 2, (y1 + y2) / 2
	end

	World = {
		gx = 0,
		gy = 500,
	}
	Entity = {
		class = "Entity",
		x = 0,
		y = 0,
		w = 0,
		h = 0,
		cr = 0,
		cg = 0,
		cb = 0,
		ca = 255,
		rotation = 0,
		collide = true,
	}
	function Entity:new(o)
		o = o or {}
		setmetatable(o, {
			__index = self,
		})
		return o
	end
	function Entity:getPos()
		return self.x, self.y
	end
	function Entity:setPos(x, y)
		self.x, self.y = x, y
	end
	function Entity:getSize()
		return self.w, self.h
	end
	function Entity:setSize(w, h)
		self.w, self.h = w, h
	end
	function Entity:getColor()
		return self.cr, self.cg, self.cb, self.ca
	end
	function Entity:setColor(r, g, b, a)
		self.cr, self.cg, self.cb = r, g, b
		self.ca = a or self.ca
	end
	function Entity:getRotation()
		return self.rotation
	end
	function Entity:setRotation(r)
		self.rotation = r
	end
	function Entity:getCollide()
		return self.collide
	end
	function Entity:setCollide(b)
		self.collide = b
	end
	function Entity:spawn()
		table.insert(ents, self) 
		local w, h = self:getSize()
		if w + h ~= 0 and self:getCollide() then
			table.insert(colliders, self)
		end
		self:init()
	end
	function Entity:init()

	end
	function Entity:draw()
		local w, h = self:getSize()
		love.graphics.rectangle("fill", -w/2, -h/2, w, h)
	end
	function Entity:update(dt)

	end
	
	Phys = Entity:new{
		class = "Phys",
		vx = 0,
		vy = 0,
		bounciness = 1,
		friction = 0,
	}
	function Phys:getVel()
		return self.vx, self.vy
	end
	function Phys:setVel(x, y)
		self.vx, self.vy = x, y
	end
	function Phys:getBounciness()
		return self.bounciness
	end
	function Phys:setBounciness(b)
		self.bounciness	= b
	end
	function Phys:getFriction()
		return self.friction
	end
	function Phys:setFriction(f)
		self.friction = f
	end
	function Phys:doVelocity(dt)
		local vx, vy = self:getVel()
		local x, y = self:getPos()
		self:setPos(x + vx * dt, y + vy * dt)
	end
	function Phys:isTouching(obj_or_x, y, w, h)
		local px, py, pw, ph, ox, oy, ow, oh
		if y then
			px, py = self:getPos()
			pw, ph = self:getSize()
			ox, oy = obj_or_x, y
			ow, oh = w, h
		else
			x, y = self:getPos()
			w, h = self:getSize()
			ox, oy = obj_or_x:getPos()
			ow, oh = obj_or_x:getSize()
		end
		if  x + w / 2 >= ox - ow / 2 --right edge > left edge
		and x - w / 2 <= ox + ow / 2 --left edge < right edge
		and y + h / 2 >= oy - oh / 2 --top edge > bottom edge
		and y - h / 2 <= oy + oh / 2 --bottom edge < top edge
		then
			return true
		end
	end
	function Phys:doFriction(dt)
		local vx, vy = self:getVel()
		local ax, ay = 0, 0
		if vx ~= 0 then
			ax = math.abs(vx) / vx
		end
		if vy ~= 0 then
			ay = math.abs(vy) / vy
		end
		local f = self:getFriction()
		vx = vx - math.sqrt(vx * ax) * ax * dt * f
		vy = vy - math.sqrt(vy * ay) * ay * dt * f
		self:setVel(vx, vy)
	end
	function Phys:doCollision(dt)
		local x, y = self:getPos()
		local px, py = x, y
		local w, h = self:getSize()
		local vx, vy = self:getVel()
		local b = self:getBounciness()
		local changed = false
		for i, obj in ipairs(colliders) do
			if obj ~= self then
				if self:isTouching(obj) then
					local ox, oy = obj:getPos()
					local ow, oh = obj:getSize()
					
					local ob = obj.getBouncines and obj:getBouncines() or 0
					local left = 	(ox - ow / 2) - (x - w / 2) --left edge		< left edge
					local right = 	(x + w / 2) - (ox + ow / 2) --right edge	> right edge
					local bottom =	(y + h / 2) - (oy + oh / 2) --top edge		> top edge
					local top = 	(oy - oh / 2) - (y - h / 2) --bottom edge	< bottom edge	
					
					local edges = {
						{key = "left", val = left}, 
						{key = "right", val = right}, 
						{key = "bottom", val = bottom}, 
						{key = "top", val = top}
					}
					table.sort(edges, function(a, b)
						return a.val > b.val
					end)
					if edges[1].key == "left" then
						px = (ox - ow / 2) - w / 2
						vx = -vx * (b + ob)
					elseif edges[1].key == "right" then
						px = (ox + ow / 2) + w / 2
						vx = -vx * (b + ob)
					elseif edges[1].key == "bottom" then
						py = (oy + oh / 2) + h / 2
						vy = -vy * (b + ob)
					elseif edges[1].key == "top" then
						py = (oy - oh / 2) - h / 2 - 1
						vy = -vy * (b + ob)
					end

					local max = 0
					local bot = 0
					for i, obj in ipairs(colliders) do --TODO: FINISH THIS
						if obj ~= self then
							if self:isTouching(px, py, self:getSize()) then
								local ox, oy = px, py
								local ow, oh = self:getSize()
								
								local left = 	(ox - ow / 2) - (x - w / 2) --left edge		< left edge
								local right = 	(x + w / 2) - (ox + ow / 2) --right edge	> right edge
								local bottom = 	(y + h / 2) - (oy + oh / 2) --top edge		> top edge
								local top = 	(oy - oh / 2) - (y - h / 2) --bottom edge	< bottom edge
								
								local edges = {
									{key = "left", val = left}, 
									{key = "right", val = right}, 
									{key = "bottom", val = bottom}, 
									{key = "top", val = top}
								}
								table.sort(edges, function(a, b)
									return a.val > b.val
								end)
								local m = 0
								for i = 1, #edges do
									m = m + edges[i].val
								end
								if m > max then
									max = m
								end	
								if bottom > bot then
									bot = bottom
								end
							end
						end
					end
					if bot <= 8 then
						--self:setPos(px, py)
					end
					self:setPos(px, py)
					self:setVel(vx, vy)
				end
			end
		end
		return changed
	end
	function Phys:doGravity(dt)
		local vx, vy = self:getVel()
		vx = vx + World.gx * dt
		vy = vy - World.gy * dt
		self:setVel(vx, vy)
	end
	function Phys:update(dt)
		self:doVelocity(dt)
		self:doGravity(dt)
		if self:doCollision(dt) then
			self:doFriction(dt)
		end
	end

	Player = Phys:new{
		class = "Player",
	}
	function Player:update(dt)
		self:doVelocity(dt)
		self:doGravity(dt)
		onground = false
		if self:doCollision(dt) then
			self:doFriction(dt)
			onground = true
		end
		local vx, vy = self:getVel()
		if love.keyboard.isDown("a") then
			vx = vx - 500 * dt
		end
		if love.keyboard.isDown("d") then
			vx = vx + 500 * dt
		end
		self:setVel(vx, vy)
	end
	Player:setSize(32, 64)
	Player:setBounciness(0.1)
	Player:spawn()

	Ground = Entity:new()
	Ground:setSize(1024, 32)
	Ground:setPos(0, -256)
	Ground:spawn()
	
	Ghost = Entity:new()
	Ghost:setSize(32, 32)
	Ghost:setCollide(false)
	function Ghost:update(dt)
		local mx, my = screenToWorld(love.mouse.getPosition())
		mx = mx + 16
		my = my + 16
		self:setPos((mx - mx % 32), (my - my % 32))
	end
	Ghost:setColor(0, 0, 0, 128)
	Ghost:spawn()

	love.graphics.setBackgroundColor(255, 255, 255)
end
local function round(...)
	local args = {...}
	for i = 1, #args do
		args[i] = math.floor(args[i])
	end
	return unpack(args)
end
function love.draw()
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.print(table.concat({round(Player:getPos())}, ", "), 0, 0)
	love.graphics.push()
		love.graphics.translate(WIDTH / 2, HEIGHT / 2)
		love.graphics.scale(1, -1)
		for k, v in ipairs(ents) do
			love.graphics.push()
				love.graphics.translate(v:getPos())
				love.graphics.rotate(v:getRotation())
				love.graphics.setColor(v:getColor())
				v:draw()
			love.graphics.pop()
		end
	love.graphics.pop()
end
function love.update(dt)
	for k, v in ipairs(ents) do
		v:update(dt)
	end
end
function love.keypressed(key)
	if key == " " then
		local vx, vy = Player:getVel()
		vy = vy + 200
		Player:setVel(vx, vy)
	end
	if key == "r" then
		Player:setPos(0, 0)
		Player:setVel(0, 0)
	end
end
function love.mousepressed(x, y, but)
	GhostPosX, GhostPosY = Ghost:getPos()
end
function love.mousereleased(x, y, but)
	if but == "l" then
		local gx, gy = Ghost:getPos()
		local w, h = math.abs(GhostPosX - gx), math.abs(GhostPosY - gy)
		w = w + 32
		h = h + 32
		local a = Entity:new()
		a:setSize(w, h)
		a:setPos(center(gx, gy, GhostPosX, GhostPosY))
		a:spawn()
	end
end
