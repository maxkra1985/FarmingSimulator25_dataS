-- Local values: ForestryPhysicsRope_mt
ForestryPhysicsRope = {}
ForestryPhysicsRope.COLLISION_GROUP = CollisionFlag.DYNAMIC_OBJECT
local v1_ = ForestryPhysicsRope
local v2_ = CollisionFlag.TERRAIN
local v3_ = CollisionFlag.STATIC_OBJECT
local v4_ = CollisionFlag.DYNAMIC_OBJECT
local v5_ = CollisionFlag.TREE
local v6_ = CollisionFlag.VEHICLE
local v7_ = CollisionFlag.ROAD
local v8_ = CollisionFlag.BUILDING
v1_.COLLISION_MASK = bit32.bor(v2_, v3_, v4_, v5_, v6_, v7_, v8_)
ForestryPhysicsRope.NUM_NODE_BITS = 8
ForestryPhysicsRope.NUM_POSITION_BITS = 16
ForestryPhysicsRope.NUM_LENGTH_BITS = 16
ForestryPhysicsRope.MAX_LENGTH = 128
ForestryPhysicsRope.NUM_UPDATE_POSITION_BITS = 7
ForestryPhysicsRope.MAX_UPDATE_LENGTH = 0.75
local ForestryPhysicsRope_mt = Class(ForestryPhysicsRope)

-- Upvalues: ForestryPhysicsRope_mt
-- Local values: self
function ForestryPhysicsRope.new(vehicle, linkActor, linkNode, isServer, customMt)
	-- upvalues: (copy) ForestryPhysicsRope_mt
	local v15_ = customMt or ForestryPhysicsRope_mt
	local v16_ = setmetatable({}, v15_)
	v16_.vehicle = vehicle
	v16_.linkActor = linkActor
	v16_.linkNode = linkNode
	v16_.isServer = isServer
	v16_.physicsRopeIndex = nil
	v16_.visibility = false
	v16_.useDynamicLength = false
	v16_.visualRopes = {}
	v16_.nodes = {}
	v16_.numActiveNodes = 0
	v16_.boundingRadius = 1
	v16_.isInitialized = false
	v16_.ropeLengthToSet = nil
	return v16_
end

function ForestryPhysicsRope.registerXMLPaths(schema, baseKey)
	schema:register(XMLValueType.FILENAME, baseKey .. "#filename", "Path to rope i3d file", "$data/shared/forestry/physicsRopes.i3d")
	schema:register(XMLValueType.STRING, baseKey .. "#ropeNode", "Path to rope i3d file", "0")
	schema:register(XMLValueType.FLOAT, baseKey .. "#diameter", "Diameter of the rope", 0.02)
	schema:register(XMLValueType.FLOAT, baseKey .. "#uvScale", "UV scale of the rope", 4)
	schema:register(XMLValueType.VECTOR_4, baseKey .. "#emissiveColor", "Emissive color", "0 0 0")
	schema:register(XMLValueType.FLOAT, baseKey .. "#minLength", "Minimum length of the rope", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. "#maxLength", "Minimum length of the rope", 20)
	schema:register(XMLValueType.FLOAT, baseKey .. "#linkLength", "Length of each rope segment", 0.5)
	schema:register(XMLValueType.FLOAT, baseKey .. "#nodeDistance", "Distance between two nodes for rendering", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. "#massPerLength", "Mass of each segment in kg", 20)
	schema:register(XMLValueType.UINT, baseKey .. "#collisionGroup", "collisionGroup of the rope", ForestryPhysicsRope.COLLISION_GROUP)
	schema:register(XMLValueType.UINT, baseKey .. "#collisionMask", "CollisionMask of the rope", ForestryPhysicsRope.COLLISION_MASK)
end

function ForestryPhysicsRope.registerSavegameXMLPaths(schema, baseKey)
	schema:register(XMLValueType.VECTOR_TRANS, baseKey .. ".ropeNode(?)#translation", "Translation of rope node")
end

-- Local values: numSegments
function ForestryPhysicsRope:loadFromXML(xmlFile, key, minLength, maxLength, baseDirectory)
	self.i3dFilename = xmlFile:getValue(key .. "#filename", "$data/shared/forestry/physicsRopes.i3d", baseDirectory)
	self.i3dRopePath = xmlFile:getValue(key .. "#ropeNode", "0")
	self.diameter = xmlFile:getValue(key .. "#diameter", 0.02)
	self.uvScale = xmlFile:getValue(key .. "#uvScale", 4)
	self.emissiveColor = xmlFile:getValue(key .. "#emissiveColor", "0 1 0 0", true)
	self.minLength = xmlFile:getValue(key .. "#minLength", minLength)
	self.maxLength = xmlFile:getValue(key .. "#maxLength", maxLength)
	self.linkLength = xmlFile:getValue(key .. "#linkLength", 0.5)
	self.nodeDistance = xmlFile:getValue(key .. "#nodeDistance", 1)
	self.massPerLength = xmlFile:getValue(key .. "#massPerLength", 20) * 0.001
	self.collisionGroup = xmlFile:getValue(key .. "#collisionGroup", ForestryPhysicsRope.COLLISION_GROUP)
	self.collisionMask = xmlFile:getValue(key .. "#collisionMask", ForestryPhysicsRope.COLLISION_MASK)
	local v27_ = self.maxLength / self.linkLength
	if 2 ^ ForestryPhysicsRope.NUM_NODE_BITS - 1 < v27_ then
		Logging.xmlWarning(xmlFile, "Physics rope has too many segments! Max. %d segments are allowed, %d defined. (length / linkLength)", 2 ^ ForestryPhysicsRope.NUM_NODE_BITS - 1, v27_)
	end
	if self.maxLength > ForestryPhysicsRope.MAX_LENGTH then
		Logging.xmlWarning(xmlFile, "Physics rope too long! Max. %dm are allowed", ForestryPhysicsRope.MAX_LENGTH)
	end
	if self.i3dFilename ~= nil then
		if self.vehicle ~= nil then
			self.sharedLoadRequestId = self.vehicle:loadSubSharedI3DFile(self.i3dFilename, false, false, self.onI3DLoaded, self, self)
			return
		end
		self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, false, false, self.onI3DLoaded, self, self)
	end
end

-- Local values: ropeClone, i3dNode, sharedLoadRequestId, failedReason
function ForestryPhysicsRope:clone(linkActor, linkNode, maxLength)
	local v32_ = ForestryPhysicsRope.new(self.vehicle, linkActor or self.linkActor, linkNode or self.linkNode)
	v32_.i3dFilename = self.i3dFilename
	v32_.i3dRopePath = self.i3dRopePath
	v32_.diameter = self.diameter
	v32_.uvScale = self.uvScale
	v32_.emissiveColor = self.emissiveColor
	v32_.minLength = self.minLength
	v32_.maxLength = maxLength or self.maxLength
	v32_.linkLength = self.linkLength
	v32_.nodeDistance = self.nodeDistance
	v32_.massPerLength = self.massPerLength
	v32_.collisionGroup = self.collisionGroup
	v32_.collisionMask = self.collisionMask
	if v32_.i3dFilename == nil then
		return nil
	end
	local v33_, v34_, v35_ = g_i3DManager:loadSharedI3DFile(v32_.i3dFilename, false, false)
	v32_.sharedLoadRequestId = v34_
	v32_:onI3DLoaded(v33_, v35_)
	return v32_
end

-- Local values: _, i, x, y, z
function ForestryPhysicsRope:saveToXMLFile(xmlFile, key)
	if self.physicsRopeIndex ~= nil then
		local _, v39_ = getPhysicsRopeLength(self.physicsRopeIndex)
		self.numActiveNodes = v39_
		for v40_ = 1, self.numActiveNodes do
			local v41_, v42_, v43_ = getWorldTranslation(self.nodes[v40_])
			xmlFile:setValue(string.format("%s.ropeNode(%d)#translation", key, v40_ - 1), v41_, v42_, v43_)
		end
	end
end

-- Local values: positions
function ForestryPhysicsRope.loadPositionDataFromSavegame(xmlFile, key)
	local v_u_46_ = {}
	xmlFile:iterate(key .. ".ropeNode", function(_, p47_)
		-- upvalues: (copy) xmlFile, (copy) v_u_46_
		local v48_ = xmlFile:getValue(p47_ .. "#translation", nil, true)
		local v49_ = v_u_46_
		table.insert(v49_, v48_)
	end)
	return v_u_46_
end

-- Local values: _, node
function ForestryPhysicsRope:delete()
	g_currentMission:removeUpdateable(self)
	for _, v51_ in pairs(self.nodes) do
		delete(v51_)
	end
	if self.referenceFrame ~= nil then
		if entityExists(self.referenceFrame) then
			delete(self.referenceFrame)
		end
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
	end
end

-- Local values: _, numSegments, maxValue, i, node, x, y, z
function ForestryPhysicsRope:writeStream(streamId)
	if self.physicsRopeIndex == nil then
		streamWriteUIntN(streamId, 0, ForestryPhysicsRope.NUM_NODE_BITS)
	else
		local _, v54_ = getPhysicsRopeLength(self.physicsRopeIndex)
		streamWriteUIntN(streamId, v54_, ForestryPhysicsRope.NUM_NODE_BITS)
		local v55_ = 2 ^ (ForestryPhysicsRope.NUM_POSITION_BITS - 1) - 1
		for v56_ = 1, v54_ do
			local v57_ = self.nodes[v56_]
			local v58_, v59_, v60_ = getTranslation(v57_)
			local v61_ = streamWriteIntN
			local v62_ = v58_ / ForestryPhysicsRope.MAX_LENGTH
			v61_(streamId, math.clamp(v62_, -1, 1) * v55_, ForestryPhysicsRope.NUM_POSITION_BITS)
			local v63_ = streamWriteIntN
			local v64_ = v59_ / ForestryPhysicsRope.MAX_LENGTH
			v63_(streamId, math.clamp(v64_, -1, 1) * v55_, ForestryPhysicsRope.NUM_POSITION_BITS)
			local v65_ = streamWriteIntN
			local v66_ = v60_ / ForestryPhysicsRope.MAX_LENGTH
			v65_(streamId, math.clamp(v66_, -1, 1) * v55_, ForestryPhysicsRope.NUM_POSITION_BITS)
		end
	end
end

-- Local values: positions, maxValue, numPositions, i, x, y, z
function ForestryPhysicsRope.readStream(streamId, invert)
	local v69_ = 2 ^ (ForestryPhysicsRope.NUM_POSITION_BITS - 1) - 1
	local v70_ = {}
	for _ = 1, streamReadUIntN(streamId, ForestryPhysicsRope.NUM_NODE_BITS) do
		local v71_ = streamReadIntN(streamId, ForestryPhysicsRope.NUM_POSITION_BITS) / v69_ * ForestryPhysicsRope.MAX_LENGTH
		local v72_ = streamReadIntN(streamId, ForestryPhysicsRope.NUM_POSITION_BITS) / v69_ * ForestryPhysicsRope.MAX_LENGTH
		local v73_ = streamReadIntN(streamId, ForestryPhysicsRope.NUM_POSITION_BITS) / v69_ * ForestryPhysicsRope.MAX_LENGTH
		if invert then
			table.insert(v70_, 1, { v71_, v72_, v73_ })
		else
			table.insert(v70_, { v71_, v72_, v73_ })
		end
	end
	return v70_
end

-- Local values: length, maxValue
function ForestryPhysicsRope:writeUpdateStream(streamId)
	if streamWriteBool(streamId, self.physicsRopeIndex ~= nil) then
		local v76_ = getPhysicsRopeLength(self.physicsRopeIndex)
		local v77_ = ForestryPhysicsRope.MAX_LENGTH
		local v78_ = math.clamp(v76_, 0, v77_)
		local v79_ = 2 ^ ForestryPhysicsRope.NUM_LENGTH_BITS - 1
		streamWriteUIntN(streamId, v78_ / ForestryPhysicsRope.MAX_LENGTH * v79_, ForestryPhysicsRope.NUM_LENGTH_BITS)
	end
end

-- Local values: maxValue, length
function ForestryPhysicsRope:readUpdateStream(streamId)
	if streamReadBool(streamId) then
		local v82_ = 2 ^ ForestryPhysicsRope.NUM_LENGTH_BITS - 1
		self.ropeLength = streamReadUIntN(streamId, ForestryPhysicsRope.NUM_LENGTH_BITS) / v82_ * ForestryPhysicsRope.MAX_LENGTH
		if self.physicsRopeIndex ~= nil then
			setPhysicsRopeMaxLength(self.physicsRopeIndex, self.ropeLength)
		end
	end
end

-- Local values: _, numSegments, lx, ly, lz, lwx, lwy, lwz, distance, move, numPositions, wx, wy, wz, i, x, y, z, ropeLength, numActiveNodes, foundRope, i, visualRope, xSum, ySum, zSum, nodeIndex, x, y, z, cx, cy, cz, bvx, bvy, bvz
function ForestryPhysicsRope:update(dt)
	if self.physicsRopeIndex ~= nil and self.useDynamicLength then
		local _, v84_ = getPhysicsRopeLength(self.physicsRopeIndex)
		local v85_, v86_, v87_ = getWorldTranslation(self.curTargetNode)
		local v88_ = self.dynamicLengthLastPosition[1]
		local v89_ = self.dynamicLengthLastPosition[2]
		local v90_ = self.dynamicLengthLastPosition[3]
		local v91_ = MathUtil.vector3Length(v85_ - v88_, v86_ - v89_, v87_ - v90_)
		local v92_ = v91_ - (self.dynamicLengthLastDistance or v91_)
		local v93_ = v84_ - 10
		local v94_ = 0
		local v95_ = 0
		local v96_ = 0
		local v97_ = 0
		for v98_ = v84_, math.max(1, v93_), -1 do
			if self.nodes[v98_] ~= nil then
				local v99_, v100_, v101_ = getWorldTranslation(self.nodes[v98_])
				v94_ = v94_ + v99_
				v95_ = v95_ + v100_
				v96_ = v96_ + v101_
				v97_ = v97_ + 1
			end
		end
		local v102_, v103_, v104_
		if v97_ > 0 then
			v102_ = v94_ / v97_
			v103_ = v95_ / v97_
			v104_ = v96_ / v97_
		else
			v102_, v103_, v104_ = getWorldTranslation(self.curLinkNode)
		end
		self:adjustLength(v92_ < 0 and self:getRopeDirectLengthPercentage() > 1 and 0 or v92_, true)
		local v105_ = self.dynamicLengthLastPosition
		local v106_ = self.dynamicLengthLastPosition
		local v107_ = self.dynamicLengthLastPosition
		v105_[1] = v102_
		v106_[2] = v103_
		v107_[3] = v104_
		self.dynamicLengthLastDistance = MathUtil.vector3Length(v85_ - v102_, v86_ - v103_, v87_ - v104_)
	end
	if self.physicsRopeIndex ~= nil then
		local v108_, v109_ = getPhysicsRopeLength(self.physicsRopeIndex)
		if self.isInitialized then
			if self.customTargetNode ~= nil and v109_ ~= 0 then
				setWorldTranslation(self.nodes[v109_], getWorldTranslation(self.customTargetNode))
				setWorldRotation(self.nodes[v109_], getWorldRotation(self.customTargetNode))
			end
			if self.customLinkNode ~= nil then
				setWorldTranslation(self.nodes[1], getWorldTranslation(self.customLinkNode))
				setWorldRotation(self.nodes[1], getWorldRotation(self.customLinkNode))
			end
		end
		if v108_ ~= self.ropeLength or v109_ ~= self.numActiveNodes then
			self.ropeLength = v108_
			self.numActiveNodes = v109_
			local v110_ = false
			for v111_ = 1, #self.visualRopes do
				local v112_ = self.visualRopes[v111_]
				if v109_ <= v112_.numBones and not v110_ then
					setVisibility(v112_.node, v109_ <= v112_.numBones)
					setShaderParameter(v112_.node, "numNodesAndLength", v109_, v108_, 0, 0, false)
					if v109_ > 1 then
						local v113_ = 0
						local v114_ = 0
						local v115_ = 0
						for v116_ = 1, v109_ do
							local v117_, v118_, v119_ = getWorldTranslation(self.nodes[v116_])
							v113_ = v113_ + v117_
							v114_ = v114_ + v118_
							v115_ = v115_ + v119_
						end
						local v120_ = v113_ / v109_
						local v121_ = v114_ / v109_
						local v122_ = v115_ / v109_
						local v123_ = v108_ * 0.5
						local v124_ = math.ceil(v123_)
						v112_.boundingRadius = math.max(v124_, 2)
						local v125_, v126_, v127_ = worldToLocal(self.nodes[1], v120_, v121_, v122_)
						setShapeBoundingSphere(v112_.node, v125_, v126_, v127_, v112_.boundingRadius)
					end
					v110_ = true
				else
					setVisibility(v112_.node, false)
					v112_.boundingRadius = nil
				end
			end
		end
		if not self.isInitialized and (v108_ ~= 0 and v109_ ~= 0) then
			self.isInitialized = true
			self:setVisibility(true)
			if self.ropeLengthToSet ~= nil then
				self:setLength(self.ropeLengthToSet)
				self.ropeLengthToSet = nil
			end
			if self.callback ~= nil then
				if self.callbackTarget == nil then
					self.callback(v108_, v109_)
				else
					self.callback(self.callbackTarget, v108_, v109_)
				end
				self.callback = nil
				self.callbackTarget = nil
			end
		end
	end
end

-- Local values: sx, sy, sz, ex, ey, ez
function ForestryPhysicsRope:updateAnchorNodes()
	if self.physicsRopeIndex ~= nil then
		local v129_, v130_, v131_ = worldToLocal(self.curLinkActor, getWorldTranslation(self.curLinkNode))
		setPhysicsRopeAnchor(self.physicsRopeIndex, 0, self.curLinkActor, v129_, v130_, v131_, false)
		local v132_, v133_, v134_ = worldToLocal(self.curTargetActor, getWorldTranslation(self.curTargetNode))
		setPhysicsRopeAnchor(self.physicsRopeIndex, 999999, self.curTargetActor, v132_, v133_, v134_, false)
	end
end

function ForestryPhysicsRope:setUseDynamicLength(useDynamicLength)
	self.useDynamicLength = useDynamicLength
	self.dynamicLengthLastPosition = { getWorldTranslation(self.curTargetNode) }
	self.dynamicLengthLastDistance = nil
end

-- Local values: i, position
function ForestryPhysicsRope:applySavegamePositions(savegamePositions)
	for v139_ = 1, #savegamePositions do
		local v140_ = savegamePositions[v139_]
		if self.nodes[v139_] ~= nil then
			setTranslation(self.nodes[v139_], v140_[1], v140_[2], v140_[3])
		end
	end
end

-- Local values: i, otherNode, otherIndex
function ForestryPhysicsRope:copyNodePositions(otherRope, invert)
	for v144_ = 1, #otherRope.nodes do
		local v145_ = otherRope.nodes[v144_]
		local v146_
		if invert then
			v146_ = #self.nodes - (v144_ - 1)
		else
			v146_ = v144_
		end
		if self.nodes[v146_] ~= nil then
			setWorldTranslation(self.nodes[v146_], getWorldTranslation(v145_))
		end
	end
end

-- Local values: sx, sy, sz, ex, ey, ez
function ForestryPhysicsRope:create(targetActor, targetNode, linkActor, linkNode, inverted, useNodePositions, callback, callbackTarget)
	local v156_ = Utils.getNoNil(useNodePositions, false)
	local v157_ = linkActor or self.linkActor
	local v158_ = linkNode or self.linkNode
	if not inverted then
		local v159_ = v158_
		v158_ = targetNode
		targetNode = v159_
		v159_ = v157_
		v157_ = targetActor
		targetActor = v159_
	end
	local v160_, v161_, v162_ = worldToLocal(targetActor, getWorldTranslation(targetNode))
	local v163_, v164_, v165_ = worldToLocal(v157_, getWorldTranslation(v158_))
	self.physicsRopeIndex = addPhysicsRope(self.nodes, self.nodeDistance, self.linkLength, self.massPerLength, self.collisionGroup, self.collisionMask, targetActor, v160_, v161_, v162_, v157_, v163_, v164_, v165_, v156_)
	self.ropeLength = getPhysicsRopeLength(self.physicsRopeIndex)
	self.ropeLengthSumUp = self.ropeLength
	self.curLinkActor = targetActor
	self.curLinkNode = targetNode
	self.curTargetActor = v157_
	self.curTargetNode = v158_
	self.isInitialized = false
	g_currentMission:addUpdateable(self)
	self:setVisibility(false)
	self.callback = callback
	self.callbackTarget = callbackTarget
	return self.physicsRopeIndex ~= nil
end

function ForestryPhysicsRope:setCustomVisualNodes(targetNode, linkNode)
	self.customTargetNode = targetNode
	self.customLinkNode = linkNode
end

function ForestryPhysicsRope:destroy()
	if self.physicsRopeIndex ~= nil then
		removePhysicsRope(self.physicsRopeIndex)
		self.physicsRopeIndex = nil
	end
	self.ropeLength = 0
	self.ropeLengthSumUp = 0
	self.numActiveNodes = 0
	self.curLinkActor = nil
	self.curLinkNode = nil
	self.curTargetActor = nil
	self.curTargetNode = nil
	self.isInitialized = false
	self.ropeLengthToSet = nil
	self.callback = nil
	self.callbackTarget = nil
	g_currentMission:removeUpdateable(self)
	self:setVisibility(false)
end

-- Local values: numSegments
function ForestryPhysicsRope:setMaxLength(maxLength)
	self.maxLength = maxLength
	local v172_ = self.maxLength / self.linkLength
	if 2 ^ ForestryPhysicsRope.NUM_NODE_BITS - 1 < v172_ then
		Logging.warning("Physics rope has too many segments! Max. %d segments are allowed, %d defined. (length / linkLength)", 2 ^ ForestryPhysicsRope.NUM_NODE_BITS - 1, v172_)
	end
	if self.maxLength > ForestryPhysicsRope.MAX_LENGTH then
		Logging.warning("Physics rope too long! Max. %dm are allowed", ForestryPhysicsRope.MAX_LENGTH)
	end
end

-- Local values: i, i, node
function ForestryPhysicsRope:generateNodes()
	for v174_ = #self.nodes, 1, -1 do
		delete(self.nodes[v174_])
		self.nodes[v174_] = nil
	end
	local v175_ = self.maxLength / self.linkLength
	for v176_ = 1, math.ceil(v175_) + 1 do
		local v177_ = createTransformGroup("ropeNode" .. v176_)
		link(self.linkNode, v177_)
		local v178_ = self.nodes
		table.insert(v178_, v177_)
	end
end

-- Local values: length
function ForestryPhysicsRope:getRopeDirectLengthPercentage(referenceMaxLength)
	return self.physicsRopeIndex == nil and 0 or (calcDistanceFrom(self.curLinkNode, self.curTargetNode) - self.minLength) / ((referenceMaxLength or self.maxLength) - self.minLength)
end

function ForestryPhysicsRope:getLength()
	return self.physicsRopeIndex == nil and 0 or getPhysicsRopeLength(self.physicsRopeIndex)
end

function ForestryPhysicsRope:setLength(length)
	if self.isInitialized then
		setPhysicsRopeMaxLength(self.physicsRopeIndex, length)
	else
		self.ropeLengthToSet = length
	end
end

-- Local values: ropeLength, ropeSegments, newRopeLength
function ForestryPhysicsRope:adjustLength(lengthDelta, sumUp)
	if self.physicsRopeIndex ~= nil then
		local v187_, v188_ = getPhysicsRopeLength(self.physicsRopeIndex)
		if v188_ > 0 then
			if sumUp and self.ropeLengthSumUp ~= 0 then
				v187_ = self.ropeLengthSumUp
			end
			local v189_ = v187_ + lengthDelta
			local v190_ = self.minLength
			local v191_ = self.maxLength
			local v192_ = math.clamp(v189_, v190_, v191_)
			setPhysicsRopeMaxLength(self.physicsRopeIndex, v192_)
			self.ropeLengthSumUp = v192_
			local v193_ = v192_ - v187_
			return math.sign(v193_)
		end
	end
	return 0
end

function ForestryPhysicsRope:setVisibility(visibility)
	self.visibility = visibility
	if self.referenceFrame ~= nil and entityExists(self.referenceFrame) then
		setVisibility(self.referenceFrame, self.visibility)
	end
end

-- Local values: i
function ForestryPhysicsRope:setEmissiveColor(r, g, b, a)
	if r ~= self.emissiveColor[1] or (g ~= self.emissiveColor[2] or (b ~= self.emissiveColor[3] or a ~= self.emissiveColor[4])) then
		self.emissiveColor[1] = r
		self.emissiveColor[2] = g
		self.emissiveColor[3] = b
		self.emissiveColor[4] = a
		for v201_ = 1, #self.visualRopes do
			setShaderParameter(self.visualRopes[v201_].node, "ropeEmissiveColor", self.emissiveColor[1], self.emissiveColor[2], self.emissiveColor[3], self.emissiveColor[4], false)
		end
	end
end

-- Local values: ropeRoot, i, node, visualRope, jointRoot, i, node
function ForestryPhysicsRope:onI3DLoaded(i3dNode, failedReason)
	if i3dNode ~= 0 then
		self.referenceFrame = createTransformGroup("ropeReferenceFrame")
		link(self.linkNode, self.referenceFrame)
		setVisibility(self.referenceFrame, self.visibility)
		local v204_ = getChildAt(i3dNode, 0)
		for _ = 1, getNumOfChildren(v204_) do
			local v205_ = getChildAt(v204_, 0)
			link(self.referenceFrame, v205_)
			local v206_ = {
				["node"] = v205_,
				["numBones"] = getNumOfShapeBones(v205_)
			}
			local v207_ = self.visualRopes
			table.insert(v207_, v206_)
			setShaderParameter(v205_, "numBonesAndBoneDistanceAndDiameterAndVScale", v206_.numBones, self.nodeDistance, self.diameter, self.uvScale, false)
		end
		local v208_ = getChildAt(i3dNode, 1)
		for _ = 1, getNumOfChildren(v208_) do
			local v209_ = getChildAt(v208_, 0)
			unlink(v209_)
			local v210_ = self.nodes
			table.insert(v210_, v209_)
		end
		delete(i3dNode)
	end
end
