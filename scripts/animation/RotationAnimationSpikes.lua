RotationAnimationSpikes = {}
local RotationAnimationSpikes_mt = Class(RotationAnimationSpikes, RotationAnimation)
function RotationAnimationSpikes.new(customMt)
	return RotationAnimation.new(customMt or RotationAnimationSpikes_mt)
end
function RotationAnimationSpikes:load(xmlFile, key, rootNodes, owner, i3dMapping)
	if RotationAnimationSpikes:superClass().load(self, xmlFile, key, rootNodes, owner, i3dMapping) == nil then
		return nil
	elseif table.size(self.nodes) ~= 1 then
		Logging.xmlWarning(xmlFile, "RotationAnimationSpikes does only support one link node in '%s'", key)
		return nil
	else
		self.spikeRotAxis = xmlFile:getValue(key .. ".spikes#rotAxis", 3)
		self.spikeMaxRot = xmlFile:getValue(key .. ".spikes#maxRot", 0)
		self.spikeTransAxis = xmlFile:getValue(key .. ".spikes#transAxis")
		self.spikeMaxTrans = xmlFile:getValue(key .. ".spikes#maxTrans", 0)
		self.spikeInverted = xmlFile:getValue(key .. ".spikes#inverted", false)
		self.moveUpStart, self.moveUpEnd = xmlFile:getValue(key .. ".spikes#moveUpRange")
		self.moveDownStart, self.moveDownEnd = xmlFile:getValue(key .. ".spikes#moveDownRange")
		if self.moveUpStart == nil or self.moveUpEnd == nil or self.moveDownStart == nil or self.moveDownEnd == nil then
			Logging.xmlWarning(xmlFile, "Incomplete moveUp/moveDown range given for '%s", key)
			return nil
		end
		self.rotOffset = self.currentRot
		self.rotDirection = math.sign(self.rotSpeed)
		if self.rotDirection < 0 then
			self.moveUpStart = -self.moveUpStart
			self.moveUpEnd = -self.moveUpEnd
			self.moveDownStart = -self.moveDownStart
			self.moveDownEnd = -self.moveDownEnd
		end
		self.moveUpStart = self.moveUpStart + self.rotOffset
		self.moveUpEnd = self.moveUpEnd + self.rotOffset
		self.moveDownStart = self.moveDownStart + self.rotOffset
		self.moveDownEnd = self.moveDownEnd + self.rotOffset
		self.spikeOffset = 1
		self.spikes = {}
		xmlFile:iterate(key .. ".spikes.spike", function(index, spikeKey)
			local spike = {}
			spike.node = xmlFile:getValue(spikeKey .. "#node", nil, rootNodes, i3dMapping)
			if spike.node ~= nil then
				spike.initialRot = { getRotation(spike.node) }
				local _ = nil
				local dx = nil
				local dy = nil
				if self.rotAxis == 1 then
					_, dx, dy = localToLocal(spike.node, self.rootNode, 0, 0, 0)
				elseif self.rotAxis == 2 then
					dx, _, dy = localToLocal(spike.node, self.rootNode, 0, 0, 0)
				elseif self.rotAxis == 3 then
					dx, dy, _ = localToLocal(spike.node, self.rootNode, 0, 0, 0)
				end
				self.spikeOffset = MathUtil.vector2Length(dx, dy)
				dx = dx / self.spikeOffset
				dy = dy / self.spikeOffset
				spike.rotationOffset = MathUtil.getYRotationFromDirection(dx, dy)
				if self.rotAxis == 1 then
					spike.rotationOffset = -spike.rotationOffset
				end
				if spike.rotationOffset < 0 then
					spike.rotationOffset = 6.283185307179586 + spike.rotationOffset
				end
				if self.spikeTransAxis ~= nil then
					spike.startTrans = { getTranslation(spike.node) }
					if self.spikeTransAxis == 1 then
						spike.endTrans = { localToLocal(spike.node, getParent(spike.node), self.spikeMaxTrans, 0, 0) }
					elseif self.spikeTransAxis == 2 then
						spike.endTrans = { localToLocal(spike.node, getParent(spike.node), 0, self.spikeMaxTrans, 0) }
					else
						spike.endTrans = { localToLocal(spike.node, getParent(spike.node), 0, 0, self.spikeMaxTrans) }
					end
				end
				spike.alpha = nil
				table.insert(self.spikes, spike)
			end
		end)
		self:updateSpikes()
		return self
	end
end
function RotationAnimationSpikes:update(dt)
	RotationAnimationSpikes:superClass().update(self, dt)
	if VehicleDebug.state == VehicleDebug.DEBUG_ANIMATIONS then
		self:drawDebug()
	end
	if 0 < self.currentAlpha then
		self:updateSpikes()
	end
end
local getInRange = function(value, s, e)
	local invValue = value - 6.283185307179586
	if e < s then
		if value <= s and e <= value then
			return true, value
		end
		if invValue <= s and e <= invValue then
			return true, invValue
		end
		return false, value
	elseif s <= value and value <= e then
		return true, value
	elseif s <= invValue and invValue <= e then
		return true, invValue
	else
		return false, value
	end
end
local getInRangeAndLerp = function(value, s, e)
	local inRange = nil
	local value = value
	local invValue = value - 6.283185307179586
	local _v34
	local _v35
	if e < s then
		if value <= s then
			if e <= value then
				_v34 = true
				_v35 = value
			elseif invValue <= s then
				if e <= invValue then
					_v34 = true
					_v35 = invValue
				else
					_v34 = false
					_v35 = value
				end
			end
		end
	elseif s <= value then
		if value <= e then
			_v34 = true
			_v35 = value
		elseif s <= invValue then
			if invValue <= e then
				_v34 = true
				_v35 = invValue
			else
				_v34 = false
				_v35 = value
			end
		end
	end
	inRange = _v34
	value = _v35
	if inRange then
		if e < s then
			local alpha = (value - e) / (s - e)
			return true, alpha
		else
			local alpha = (value - s) / (e - s)
			return true, alpha
		end
	end
	return false
end
function RotationAnimationSpikes:updateSpikes()
	for _, spike in ipairs(self.spikes) do
		local yRot = (self.currentRot + spike.rotationOffset) % 6.283185307179586
		local alpha = nil
		local s = self.moveUpEnd
		local e = self.moveDownStart
		local invValue = yRot - 6.283185307179586
		if e < s then
			if yRot <= s then
				if e <= yRot then
					local isUp = true
					local _ = yRot
				elseif invValue <= s then
					if e <= invValue then
						isUp = true
						_ = invValue
					else
						isUp = false
						_ = yRot
					end
				end
			end
		elseif s <= yRot then
			if yRot <= e then
				isUp = true
				_ = yRot
			elseif s <= invValue then
				if invValue <= e then
					isUp = true
					_ = invValue
				else
					isUp = false
					_ = yRot
				end
			end
		end
		if isUp then
			alpha = 1
		else
			local value = yRot
			local s = self.moveUpStart
			local e = self.moveUpEnd
			local inRange = nil
			local value = value
			local invValue = value - 6.283185307179586
			local _v166
			local _v167
			if e < s then
				if value <= s then
					if e <= value then
						_v166 = true
						_v167 = value
					elseif invValue <= s then
						if e <= invValue then
							_v166 = true
							_v167 = invValue
						else
							_v166 = false
							_v167 = value
						end
					end
				end
			elseif s <= value then
				if value <= e then
					_v166 = true
					_v167 = value
				elseif s <= invValue then
					if invValue <= e then
						_v166 = true
						_v167 = invValue
					else
						_v166 = false
						_v167 = value
					end
				end
			end
			inRange = _v166
			value = _v167
			if inRange then
				if e < s then
					local alpha = (value - e) / (s - e)
					local isMovingUp = true
					local moveUpAlpha = alpha
				else
					local alpha = (value - s) / (e - s)
					isMovingUp = true
					moveUpAlpha = alpha
				end
			else
				isMovingUp = false
				moveUpAlpha = nil
			end
			if isMovingUp then
				alpha = moveUpAlpha
			else
				local value = yRot
				local s = self.moveDownStart
				local e = self.moveDownEnd
				local inRange = nil
				local value = value
				local invValue = value - 6.283185307179586
				inRange = value
				value = invValue
				if inRange then
					if e < s then
						local alpha = (value - e) / (s - e)
						local isMovingDown = true
						local moveDownAlpha = alpha
					else
						local alpha = (value - s) / (e - s)
						isMovingDown = true
						moveDownAlpha = alpha
					end
				else
					isMovingDown = false
					moveDownAlpha = nil
				end
				if isMovingDown then
					alpha = 1 - moveDownAlpha
				end
			end
			if alpha ~= nil and self.rotDirection < 0 then
				alpha = 1 - alpha
			end
		end
		alpha = alpha or 0
		if self.spikeInverted then
			alpha = 1 - alpha
		end
		if alpha == spike.alpha then
			continue
		end
		spike.alpha = alpha
		if self.spikeTransAxis ~= nil then
			local x, y, z = MathUtil.vector3ArrayLerp(spike.startTrans, spike.endTrans, alpha)
			setTranslation(spike.node, x, y, z)
		else
			local rot = self.spikeMaxRot * alpha
			if self.spikeRotAxis == 1 then
				setRotation(spike.node, spike.initialRot[1] + rot, spike.initialRot[2], spike.initialRot[3])
			elseif self.spikeRotAxis == 2 then
				setRotation(spike.node, spike.initialRot[1], spike.initialRot[2] + rot, spike.initialRot[3])
			else
				setRotation(spike.node, spike.initialRot[1], spike.initialRot[2], spike.initialRot[3] + rot)
			end
		end
	end
end
function RotationAnimationSpikes:drawDebug()
	local ox, oy, oz = getTranslation(self.rootNode)
	RotationAnimationSpikes.drawDebugCircleRange(getParent(self.rootNode), ox, oy, oz, self.spikeOffset, 20, self.rotAxis, self.moveUpStart, self.moveUpEnd, 1)
	RotationAnimationSpikes.drawDebugCircleRange(getParent(self.rootNode), ox, oy, oz, self.spikeOffset, 20, self.rotAxis, self.moveDownStart, self.moveDownEnd, -1)
	local x1, y1, z1 = getWorldTranslation(self.rootNode)
	local x2, y2, z2 = localToWorld(self.rootNode, 0, 0, 0.75)
	drawDebugLine(x1, y1, z1, 0, 1, 1, x2, y2, z2, 0, 1, 1)
	Utils.renderTextAtWorldPosition(x1, y1, z1, string.format("%.1f\194\176", math.deg(self.currentRot % 6.283185307179586)), 0.01)
	for i = 1, #self.spikes do
		local spike = self.spikes[i]
		local x1, y1, z1 = getWorldTranslation(spike.node)
		Utils.renderTextAtWorldPosition(x1, y1, z1, string.format("%s", getName(spike.node):sub(-3)), 0.006)
	end
end
function RotationAnimationSpikes.registerAnimationClassXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_ROT_2, basePath .. ".spikes#moveUpRange", "(RotationAnimationSpikes) Move up range")
	schema:register(XMLValueType.VECTOR_ROT_2, basePath .. ".spikes#moveDownRange", "(RotationAnimationSpikes) Move down range")
	schema:register(XMLValueType.INT, basePath .. ".spikes#rotAxis", "(RotationAnimationSpikes) Rotation axis", 3)
	schema:register(XMLValueType.ANGLE, basePath .. ".spikes#maxRot", "(RotationAnimationSpikes) Max. spike rotation")
	schema:register(XMLValueType.INT, basePath .. ".spikes#transAxis", "(RotationAnimationSpikes) Translation axis (disables the rotation adjustment of the spike)", 3)
	schema:register(XMLValueType.FLOAT, basePath .. ".spikes#maxTrans", "(RotationAnimationSpikes) Max. spike translation")
	schema:register(XMLValueType.BOOL, basePath .. ".spikes#inverted", "(RotationAnimationSpikes) Min. and max. rotation/translation of spikes are inverted", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".spikes.spike(?)#node", "(RotationAnimationSpikes) Spike node")
end
local DEBUG_TEXT_COLOR = { 0, 1, 1, 1 }
local DEBUG_UP_COLOR = { 0, 1, 0, 1 }
local DEBUG_DOWN_COLOR = { 1, 0, 0, 1 }
function RotationAnimationSpikes.drawDebugCircleRange(node, ox, oy, oz, radius, steps, axis, minRot, maxRot, direction)
	local directionStr = 0 < direction and "up" or "down"
	local startColor = 0 < direction and DEBUG_UP_COLOR or DEBUG_DOWN_COLOR
	local endColor = 0 < direction and DEBUG_DOWN_COLOR or DEBUG_UP_COLOR
	local range = maxRot - minRot
	for i = 1, steps do
		local a1 = 1.5707963267948966 + minRot + (i - 1) / steps * range
		local a2 = 1.5707963267948966 + minRot + i / steps * range
		local c1 = math.cos(a1) * radius
		local s1 = math.sin(a1) * radius
		local c2 = math.cos(a2) * radius
		local s2 = math.sin(a2) * radius
		local x1 = nil
		local y1 = nil
		local z1 = nil
		local x2 = nil
		local y2 = nil
		local z2 = nil
		if axis == 1 then
			x1, y1, z1 = localToWorld(node, ox + 0, oy + c1, oz + s1)
			x2, y2, z2 = localToWorld(node, ox + 0, oy + c2, oz + s2)
		elseif axis == 2 then
			x1, y1, z1 = localToWorld(node, ox - c1, oy + 0, oz + s1)
			x2, y2, z2 = localToWorld(node, ox - c2, oy + 0, oz + s2)
		else
			x1, y1, z1 = localToWorld(node, ox - c1, oy + s1, oz + 0)
			x2, y2, z2 = localToWorld(node, ox - c2, oy + s2, oz + 0)
		end
		local r1, g1, b1 = MathUtil.vector3Lerp(startColor[1], startColor[2], startColor[3], endColor[1], endColor[2], endColor[3], (i - 1) / (steps - 1))
		local r2, g2, b2 = MathUtil.vector3Lerp(startColor[1], startColor[2], startColor[3], endColor[1], endColor[2], endColor[3], i / (steps - 1))
		drawDebugLine(x1, y1, z1, r1, g1, b1, x2, y2, z2, r2, g2, b2)
		if i == math.floor(steps * 0.5) then
			Utils.renderTextAtWorldPosition((x1 + x2) * 0.5, (y1 + y2) * 0.5, (z1 + z2) * 0.5, string.format("%s %.1f\194\176 - %.1f\194\176", directionStr, math.deg(minRot), math.deg(maxRot)), 0.0075, nil, unpack(DEBUG_TEXT_COLOR))
		end
	end
end
