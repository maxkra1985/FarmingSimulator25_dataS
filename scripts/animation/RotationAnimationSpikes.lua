-- Local values: RotationAnimationSpikes_mt, getInRange, getInRangeAndLerp, DEBUG_TEXT_COLOR, DEBUG_UP_COLOR, DEBUG_DOWN_COLOR
RotationAnimationSpikes = {}
local RotationAnimationSpikes_mt = Class(RotationAnimationSpikes, RotationAnimation)

-- Upvalues: RotationAnimationSpikes_mt
function RotationAnimationSpikes.new(customMt)
	-- upvalues: (copy) RotationAnimationSpikes_mt
	return RotationAnimation.new(customMt or RotationAnimationSpikes_mt)
end

function RotationAnimationSpikes:load(xmlFile, key, rootNodes, owner, i3dMapping)
	if RotationAnimationSpikes:superClass().load(self, xmlFile, key, rootNodes, owner, i3dMapping) == nil then
		return nil
	end
	if table.size(self.nodes) ~= 1 then
		Logging.xmlWarning(xmlFile, "RotationAnimationSpikes does only support one link node in \'%s\'", key)
		return nil
	end
	self.spikeRotAxis = xmlFile:getValue(key .. ".spikes#rotAxis", 3)
	self.spikeMaxRot = xmlFile:getValue(key .. ".spikes#maxRot", 0)
	self.spikeTransAxis = xmlFile:getValue(key .. ".spikes#transAxis")
	self.spikeMaxTrans = xmlFile:getValue(key .. ".spikes#maxTrans", 0)
	self.spikeInverted = xmlFile:getValue(key .. ".spikes#inverted", false)
	local v9_, v10_ = xmlFile:getValue(key .. ".spikes#moveUpRange")
	self.moveUpStart = v9_
	self.moveUpEnd = v10_
	local v11_, v12_ = xmlFile:getValue(key .. ".spikes#moveDownRange")
	self.moveDownStart = v11_
	self.moveDownEnd = v12_
	if self.moveUpStart == nil or (self.moveUpEnd == nil or (self.moveDownStart == nil or self.moveDownEnd == nil)) then
		Logging.xmlWarning(xmlFile, "Incomplete moveUp/moveDown range given for \'%s", key)
		return nil
	end
	self.rotOffset = self.currentRot
	local v13_ = self.rotSpeed
	self.rotDirection = math.sign(v13_)
	if self.rotDirection < 0 then
		local v14_ = -self.moveUpStart
		local v15_ = -self.moveUpEnd
		self.moveUpStart = v14_
		self.moveUpEnd = v15_
		local v16_ = -self.moveDownStart
		local v17_ = -self.moveDownEnd
		self.moveDownStart = v16_
		self.moveDownEnd = v17_
	end
	local v18_ = self.moveUpStart + self.rotOffset
	local v19_ = self.moveUpEnd + self.rotOffset
	self.moveUpStart = v18_
	self.moveUpEnd = v19_
	local v20_ = self.moveDownStart + self.rotOffset
	local v21_ = self.moveDownEnd + self.rotOffset
	self.moveDownStart = v20_
	self.moveDownEnd = v21_
	self.spikeOffset = 1
	self.spikes = {}
	xmlFile:iterate(key .. ".spikes.spike", function(_, p22_)
		-- upvalues: (copy) xmlFile, (copy) rootNodes, (copy) i3dMapping, (copy) self
		local v23_ = {
			["node"] = xmlFile:getValue(p22_ .. "#node", nil, rootNodes, i3dMapping)
		}
		if v23_.node ~= nil then
			v23_.initialRot = { getRotation(v23_.node) }
			local v24_ = nil
			local v25_ = nil
			if self.rotAxis == 1 then
				local v26_
				v26_, v24_, v25_ = localToLocal(v23_.node, self.rootNode, 0, 0, 0)
			elseif self.rotAxis == 2 then
				local v27_
				v24_, v27_, v25_ = localToLocal(v23_.node, self.rootNode, 0, 0, 0)
			elseif self.rotAxis == 3 then
				local v28_
				v24_, v25_, v28_ = localToLocal(v23_.node, self.rootNode, 0, 0, 0)
			end
			self.spikeOffset = MathUtil.vector2Length(v24_, v25_)
			local v29_ = v24_ / self.spikeOffset
			local v30_ = v25_ / self.spikeOffset
			v23_.rotationOffset = MathUtil.getYRotationFromDirection(v29_, v30_)
			if self.rotAxis == 1 then
				v23_.rotationOffset = -v23_.rotationOffset
			end
			if v23_.rotationOffset < 0 then
				v23_.rotationOffset = 6.283185307179586 + v23_.rotationOffset
			end
			if self.spikeTransAxis ~= nil then
				v23_.startTrans = { getTranslation(v23_.node) }
				if self.spikeTransAxis == 1 then
					v23_.endTrans = { localToLocal(v23_.node, getParent(v23_.node), self.spikeMaxTrans, 0, 0) }
				elseif self.spikeTransAxis == 2 then
					v23_.endTrans = { localToLocal(v23_.node, getParent(v23_.node), 0, self.spikeMaxTrans, 0) }
				else
					v23_.endTrans = { localToLocal(v23_.node, getParent(v23_.node), 0, 0, self.spikeMaxTrans) }
				end
			end
			v23_.alpha = nil
			local v31_ = self.spikes
			table.insert(v31_, v23_)
		end
	end)
	self:updateSpikes()
	return self
end

function RotationAnimationSpikes:update(dt)
	RotationAnimationSpikes:superClass().update(self, dt)
	if VehicleDebug.state == VehicleDebug.DEBUG_ANIMATIONS then
		self:drawDebug()
	end
	if self.currentAlpha > 0 then
		self:updateSpikes()
	end
end

-- Local values: _, spike, yRot, alpha, value, s, e, invValue, isUp, _, value, s, e, inRange, value, s, e, invValue, alpha, alpha, isMovingUp, moveUpAlpha, value, s, e, inRange, value, s, e, invValue, alpha, alpha, isMovingDown, moveDownAlpha, x, y, z, rot
function RotationAnimationSpikes:updateSpikes()
	for _, v35_ in ipairs(self.spikes) do
		local v36_ = (self.currentRot + v35_.rotationOffset) % 6.283185307179586
		local v37_ = nil
		local v38_ = self.moveUpEnd
		local v39_ = self.moveDownStart
		local v40_ = v36_ - 6.283185307179586
		local v41_
		if v39_ < v38_ then
			v41_ = v36_ <= v38_ and v39_ <= v36_ and true or v40_ <= v38_ and v39_ <= v40_
		else
			v41_ = v38_ <= v36_ and v36_ <= v39_ and true or v38_ <= v40_ and v40_ <= v39_
		end
		if v41_ then
			v37_ = 1
		else
			local v42_ = self.moveUpStart
			local v43_ = self.moveUpEnd
			local v44_ = v36_ - 6.283185307179586
			local v45_
			if v43_ < v42_ then
				if v36_ <= v42_ and v43_ <= v36_ then
					v44_ = v36_
					v45_ = true
				elseif v44_ <= v42_ and v43_ <= v44_ then
					v45_ = true
				else
					v44_ = v36_
					v45_ = false
				end
			elseif v42_ <= v36_ and v36_ <= v43_ then
				v44_ = v36_
				v45_ = true
			elseif v42_ <= v44_ and v44_ <= v43_ then
				v45_ = true
			else
				v44_ = v36_
				v45_ = false
			end
			local v46_, v47_
			if v45_ then
				if v43_ < v42_ then
					v46_ = (v44_ - v43_) / (v42_ - v43_)
					v47_ = true
				else
					v46_ = (v44_ - v42_) / (v43_ - v42_)
					v47_ = true
				end
			else
				v47_ = false
				v46_ = nil
			end
			if v47_ then
				v37_ = v46_
			else
				local v48_ = self.moveDownStart
				local v49_ = self.moveDownEnd
				local v50_ = v36_ - 6.283185307179586
				local v51_
				if v49_ < v48_ then
					if v36_ <= v48_ and v49_ <= v36_ then
						v50_ = v36_
						v51_ = true
					elseif v50_ <= v48_ and v49_ <= v50_ then
						v51_ = true
					else
						v50_ = v36_
						v51_ = false
					end
				elseif v48_ <= v36_ and v36_ <= v49_ then
					v50_ = v36_
					v51_ = true
				elseif v48_ <= v50_ and v50_ <= v49_ then
					v51_ = true
				else
					v50_ = v36_
					v51_ = false
				end
				local v52_, v53_
				if v51_ then
					if v49_ < v48_ then
						v52_ = (v50_ - v49_) / (v48_ - v49_)
						v53_ = true
					else
						v52_ = (v50_ - v48_) / (v49_ - v48_)
						v53_ = true
					end
				else
					v53_ = false
					v52_ = nil
				end
				if v53_ then
					v37_ = 1 - v52_
				end
			end
			if v37_ ~= nil and self.rotDirection < 0 then
				v37_ = 1 - v37_
			end
		end
		local v54_ = v37_ or 0
		if self.spikeInverted then
			v54_ = 1 - v54_
		end
		if v54_ ~= v35_.alpha then
			v35_.alpha = v54_
			if self.spikeTransAxis == nil then
				local v55_ = self.spikeMaxRot * v54_
				if self.spikeRotAxis == 1 then
					setRotation(v35_.node, v35_.initialRot[1] + v55_, v35_.initialRot[2], v35_.initialRot[3])
				elseif self.spikeRotAxis == 2 then
					setRotation(v35_.node, v35_.initialRot[1], v35_.initialRot[2] + v55_, v35_.initialRot[3])
				else
					setRotation(v35_.node, v35_.initialRot[1], v35_.initialRot[2], v35_.initialRot[3] + v55_)
				end
			else
				local v56_, v57_, v58_ = MathUtil.vector3ArrayLerp(v35_.startTrans, v35_.endTrans, v54_)
				setTranslation(v35_.node, v56_, v57_, v58_)
			end
		end
	end
end

-- Local values: ox, oy, oz, x1, y1, z1, x2, y2, z2, i, spike, x1, y1, z1
function RotationAnimationSpikes:drawDebug()
	local v60_, v61_, v62_ = getTranslation(self.rootNode)
	RotationAnimationSpikes.drawDebugCircleRange(getParent(self.rootNode), v60_, v61_, v62_, self.spikeOffset, 20, self.rotAxis, self.moveUpStart, self.moveUpEnd, 1)
	RotationAnimationSpikes.drawDebugCircleRange(getParent(self.rootNode), v60_, v61_, v62_, self.spikeOffset, 20, self.rotAxis, self.moveDownStart, self.moveDownEnd, -1)
	local v63_, v64_, v65_ = getWorldTranslation(self.rootNode)
	local v66_, v67_, v68_ = localToWorld(self.rootNode, 0, 0, 0.75)
	drawDebugLine(v63_, v64_, v65_, 0, 1, 1, v66_, v67_, v68_, 0, 1, 1)
	local v69_ = Utils.renderTextAtWorldPosition
	local v70_ = string.format
	local v71_ = self.currentRot % 6.283185307179586
	v69_(v63_, v64_, v65_, v70_("%.1f\194\176", (math.deg(v71_))), 0.01)
	for v72_ = 1, #self.spikes do
		local v73_ = self.spikes[v72_]
		local v74_, v75_, v76_ = getWorldTranslation(v73_.node)
		Utils.renderTextAtWorldPosition(v74_, v75_, v76_, string.format("%s", getName(v73_.node):sub(-3)), 0.006)
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
local v_u_79_ = {
	0,
	1,
	1,
	1
}
local v_u_80_ = {
	0,
	1,
	0,
	1
}
local v_u_81_ = {
	1,
	0,
	0,
	1
}

-- Upvalues: DEBUG_UP_COLOR, DEBUG_DOWN_COLOR, DEBUG_TEXT_COLOR
-- Local values: directionStr, startColor, endColor, range, i, a1, a2, c1, s1, c2, s2, x1, y1, z1, x2, y2, z2, r1, g1, b1, r2, g2, b2
function RotationAnimationSpikes.drawDebugCircleRange(node, ox, oy, oz, radius, steps, axis, minRot, maxRot, direction)
	-- upvalues: (copy) v_u_80_, (copy) v_u_81_, (copy) v_u_79_
	local v92_ = direction > 0 and "up" or "down"
	local v93_ = direction > 0 and v_u_80_ or v_u_81_
	local v94_ = direction > 0 and v_u_81_ or v_u_80_
	local v95_ = maxRot - minRot
	for v96_ = 1, steps do
		local v97_ = 1.5707963267948966 + minRot + (v96_ - 1) / steps * v95_
		local v98_ = 1.5707963267948966 + minRot + v96_ / steps * v95_
		local v99_ = math.cos(v97_) * radius
		local v100_ = math.sin(v97_) * radius
		local v101_ = math.cos(v98_) * radius
		local v102_ = math.sin(v98_) * radius
		local v103_, v104_, v105_, v106_, v107_, v108_
		if axis == 1 then
			v103_, v104_, v105_ = localToWorld(node, ox + 0, oy + v99_, oz + v100_)
			v106_, v107_, v108_ = localToWorld(node, ox + 0, oy + v101_, oz + v102_)
		elseif axis == 2 then
			v103_, v104_, v105_ = localToWorld(node, ox - v99_, oy + 0, oz + v100_)
			v106_, v107_, v108_ = localToWorld(node, ox - v101_, oy + 0, oz + v102_)
		else
			v103_, v104_, v105_ = localToWorld(node, ox - v99_, oy + v100_, oz + 0)
			v106_, v107_, v108_ = localToWorld(node, ox - v101_, oy + v102_, oz + 0)
		end
		local v109_, v110_, v111_ = MathUtil.vector3Lerp(v93_[1], v93_[2], v93_[3], v94_[1], v94_[2], v94_[3], (v96_ - 1) / (steps - 1))
		local v112_, v113_, v114_ = MathUtil.vector3Lerp(v93_[1], v93_[2], v93_[3], v94_[1], v94_[2], v94_[3], v96_ / (steps - 1))
		drawDebugLine(v103_, v104_, v105_, v109_, v110_, v111_, v106_, v107_, v108_, v112_, v113_, v114_)
		local v115_ = steps * 0.5
		if v96_ == math.floor(v115_) then
			local v116_ = v_u_79_
			Utils.renderTextAtWorldPosition((v103_ + v106_) * 0.5, (v104_ + v107_) * 0.5, (v105_ + v108_) * 0.5, string.format("%s %.1f\194\176 - %.1f\194\176", v92_, math.deg(minRot), (math.deg(maxRot))), 0.0075, nil, unpack(v116_))
		end
	end
end
