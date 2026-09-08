-- Local values: ForestryHook_mt
ForestryHook = {}
local ForestryHook_mt = Class(ForestryHook)

-- Upvalues: ForestryHook_mt
-- Local values: self
function ForestryHook.new(vehicle, linkNode, customMt)
	-- upvalues: (copy) ForestryHook_mt
	local v5_ = customMt or ForestryHook_mt
	local v6_ = setmetatable({}, v5_)
	v6_.vehicle = vehicle
	v6_.linkNode = linkNode
	v6_.x = 0
	v6_.y = 0
	v6_.z = 0
	v6_.rx = 0
	v6_.ry = 0
	v6_.rz = 0
	v6_.visibility = true
	v6_.targetNode = nil
	v6_.validTarget = false
	v6_.tx = 0
	v6_.ty = 0
	v6_.tz = 0
	v6_.subTargetNodes = {}
	v6_.rotationNodes = {}
	return v6_
end

function ForestryHook.registerXMLPaths(schema, baseKey)
	schema:register(XMLValueType.STRING, baseKey .. "#filename", "Path to hook xml file", "$data/shared/forestry/treeHook01.xml")
end

function ForestryHook:isValid()
	return self.i3dFilename ~= nil
end

function ForestryHook:loadFromXML(xmlFile, key, baseDirectory)
	self.xmlFilename = xmlFile:getValue(key .. "#filename", "$data/shared/forestry/treeHook01.xml")
	if self.xmlFilename ~= nil then
		self.xmlFilename = Utils.getFilename(self.xmlFilename, baseDirectory)
		self.hookXMLFile = XMLFile.load("hookXMLFile", self.xmlFilename)
		if self.hookXMLFile ~= nil then
			self.i3dFilename = self.hookXMLFile:getString("forestryHook.filename", "$data/shared/forestry/treeHook01.i3d")
			if self.i3dFilename ~= nil then
				self.i3dFilename = Utils.getFilename(self.i3dFilename, baseDirectory)
				if self.vehicle ~= nil then
					self.sharedLoadRequestId = self.vehicle:loadSubSharedI3DFile(self.i3dFilename, false, false, self.onI3DLoaded, self, self)
					return
				end
				self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, false, false, self.onI3DLoaded, self, self)
			end
		end
	end
end

-- Local values: _, targetKey, node
function ForestryHook:loadFromConfigXML(xmlFile)
	xmlFile:iterate("forestryHook.rotationNode", function(_, p16_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v17_ = {
			["node"] = XMLValueType.getXMLNode(xmlFile.handle, p16_ .. "#node", nil, self.hookId, nil)
		}
		if v17_.node ~= nil then
			v17_.alignYRot = xmlFile:getBool(p16_ .. "#alignYRot", false)
			v17_.alignXRot = xmlFile:getBool(p16_ .. "#alignXRot", false)
			local v18_ = xmlFile:getFloat(p16_ .. "#minYRot", -180)
			v17_.minYRot = math.rad(v18_)
			local v19_ = xmlFile:getFloat(p16_ .. "#maxYRot", 180)
			v17_.maxYRot = math.rad(v19_)
			local v20_ = xmlFile:getFloat(p16_ .. "#minXRot", -180)
			v17_.minXRot = math.rad(v20_)
			local v21_ = xmlFile:getFloat(p16_ .. "#maxXRot", 180)
			v17_.maxXRot = math.rad(v21_)
			v17_.alignToTarget = xmlFile:getBool(p16_ .. "#alignToTarget", true)
			v17_.targetIndices = xmlFile:getVector(p16_ .. "#targetIndices", nil)
			v17_.referenceFrame = createTransformGroup("hookNodeReferenceFrame")
			link(getParent(v17_.node), v17_.referenceFrame)
			setTranslation(v17_.referenceFrame, getTranslation(v17_.node))
			setRotation(v17_.referenceFrame, getRotation(v17_.node))
			local v22_ = self.rotationNodes
			table.insert(v22_, v17_)
		end
	end)
	self.ropeTargets = {}
	for _, v23_ in xmlFile:iterator("forestryHook.ropeTarget") do
		local v24_ = XMLValueType.getXMLNode(xmlFile.handle, v23_ .. "#node", nil, self.hookId, nil)
		if v24_ ~= nil and self.ropeTarget == nil then
			self.ropeTarget = v24_
		end
		local v25_ = self.ropeTargets
		table.insert(v25_, v24_)
	end
	self.treeBelt = {}
	self.treeBelt.offset = xmlFile:getFloat("forestryHook.treeBelt#offset", 0.01)
	self.treeBelt.maxDeltaY = xmlFile:getFloat("forestryHook.treeBelt#maxDeltaY", 0.075)
	self.treeBelt.spacing = xmlFile:getFloat("forestryHook.treeBelt#spacing", 0.0025)
	self.treeBelt.tensionBeltType = xmlFile:getString("forestryHook.treeBelt#tensionBeltType", "forestryTreeBelt")
	self.treeBelt.beltData = g_tensionBeltManager:getBeltData(self.treeBelt.tensionBeltType)
	self.treeBelt.dynamicBeltSpacing = {}
	self.treeBelt.dynamicBeltSpacing.isActive = xmlFile:getBool("forestryHook.treeBelt.dynamicBeltSpacing#isActive", false)
	self.treeBelt.dynamicBeltSpacing.minRadius = xmlFile:getFloat("forestryHook.treeBelt.dynamicBeltSpacing#minRadius", 0.1)
	self.treeBelt.dynamicBeltSpacing.maxRadius = xmlFile:getFloat("forestryHook.treeBelt.dynamicBeltSpacing#maxRadius", 0.5)
	self.treeBelt.dynamicBeltSpacing.minSpacing = xmlFile:getFloat("forestryHook.treeBelt.dynamicBeltSpacing#minSpacing", 0.01)
	self.treeBelt.dynamicBeltSpacing.maxSpacing = xmlFile:getFloat("forestryHook.treeBelt.dynamicBeltSpacing#maxSpacing", 0.1)
	self.treeBelt.dynamicBeltSpacing.adjustmentNodes = {}
	xmlFile:iterate("forestryHook.treeBelt.dynamicBeltSpacing.adjustmentNode", function(_, p26_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v27_ = {
			["node"] = XMLValueType.getXMLNode(xmlFile.handle, p26_ .. "#node", nil, self.hookId, nil)
		}
		if v27_.node ~= nil then
			v27_.minRot = XMLValueType.getXMLVector3Angle(xmlFile.handle, p26_ .. "#minRot", nil, true)
			v27_.maxRot = XMLValueType.getXMLVector3Angle(xmlFile.handle, p26_ .. "#maxRot", nil, true)
			v27_.minTrans = XMLValueType.getXMLVector3(xmlFile.handle, p26_ .. "#minTrans", nil, true)
			v27_.maxTrans = XMLValueType.getXMLVector3(xmlFile.handle, p26_ .. "#maxTrans", nil, true)
			local v28_ = self.treeBelt.dynamicBeltSpacing.adjustmentNodes
			table.insert(v28_, v27_)
		end
	end)
end

-- Local values: hookClone, i3dNode, sharedLoadRequestId, failedReason
function ForestryHook:clone()
	local v30_ = ForestryHook.new(self.vehicle, self.linkNode)
	v30_.xmlFilename = self.xmlFilename
	v30_.i3dFilename = self.i3dFilename
	if v30_.i3dFilename ~= nil then
		v30_.hookXMLFile = XMLFile.load("hookXMLFile", v30_.xmlFilename)
		local v31_, v32_, v33_ = g_i3DManager:loadSharedI3DFile(v30_.i3dFilename, false, false)
		v30_.sharedLoadRequestId = v32_
		v30_:onI3DLoaded(v31_, v33_)
		return v30_
	end
end

function ForestryHook:delete()
	g_currentMission:removeUpdateable(self)
	if self.hookId ~= nil then
		if entityExists(self.hookId) then
			delete(self.hookId)
		end
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
	end
	if self.beltShape ~= nil and entityExists(self.beltShape) then
		delete(self.beltShape)
	end
	if self.splitShapeId ~= nil and entityExists(self.splitShapeId) then
		if getRigidBodyType(self.splitShapeId) == RigidBodyType.STATIC then
			setShaderParameterRecursive(self.splitShapeId, "windSnowLeafScale", 1, nil, nil, nil, false)
		end
		self.splitShapeId = nil
	end
end

-- Local values: j, rotationNode, tx, ty, tz, numTargets, _, targetIndex, subTargetNode, sx, sy, sz, x, _, z, angle, rx, _, _, _, y, z, angle, _, ry, _, x, y, z
function ForestryHook:update(dt)
	if self.targetNode ~= nil and entityExists(self.targetNode) then
		local v36_, v37_, v38_ = getWorldTranslation(self.targetNode)
		self.tx = v36_
		self.ty = v37_
		self.tz = v38_
	end
	if entityExists(self.hookId) then
		if self.validTarget then
			for v39_ = 1, #self.rotationNodes do
				local v40_ = self.rotationNodes[v39_]
				local v41_, v42_, v43_
				if v40_.targetIndices == nil then
					v41_ = nil
					v42_ = nil
					v43_ = nil
				else
					v41_ = 0
					v42_ = 0
					v43_ = 0
					local v44_ = 0
					for _, v45_ in ipairs(v40_.targetIndices) do
						local v46_ = self.subTargetNodes[v45_]
						if v46_ ~= nil and entityExists(v46_) then
							local v47_, v48_, v49_ = getWorldTranslation(v46_)
							v41_ = v41_ + v47_
							v42_ = v42_ + v48_
							v43_ = v43_ + v49_
							v44_ = v44_ + 1
						end
					end
					if v44_ > 0 then
						v41_ = v41_ / v44_
						v42_ = v42_ / v44_
						v43_ = v43_ / v44_
					end
				end
				if v41_ == nil then
					v41_ = self.tx
					v42_ = self.ty
					v43_ = self.tz
				end
				if v40_.alignYRot then
					local v50_, _, v51_ = worldToLocal(v40_.referenceFrame, v41_, v42_, v43_)
					local v52_, v53_ = MathUtil.vector2Normalize(v50_, v51_)
					local v54_ = math.atan2(v52_, v53_)
					local v55_ = v40_.minYRot
					local v56_ = v40_.maxYRot
					local v57_ = math.clamp(v54_, v55_, v56_)
					local v58_, _, _ = getRotation(v40_.node)
					setRotation(v40_.node, v58_, v57_, 0)
				end
				if v40_.alignXRot then
					local _, v59_, v60_ = worldToLocal(v40_.referenceFrame, v41_, v42_, v43_)
					local v61_, v62_ = MathUtil.vector2Normalize(v59_, v60_)
					local v63_ = -math.atan2(v61_, v62_)
					local v64_ = v40_.minXRot
					local v65_ = v40_.maxXRot
					local v66_ = math.clamp(v63_, v64_, v65_)
					local _, v67_, _ = getRotation(v40_.node)
					setRotation(v40_.node, v66_, v67_, 0)
				end
				if not v40_.alignYRot and (not v40_.alignXRot and v40_.alignToTarget) then
					local v68_, v69_, v70_ = worldToLocal(v40_.referenceFrame, v41_, v42_, v43_)
					local v71_, v72_, v73_ = MathUtil.vector3Normalize(v68_, v69_, v70_)
					setDirection(v40_.node, v71_, v72_, v73_, 0, 1, 0)
				end
			end
			return
		end
	else
		g_currentMission:removeUpdateable(self)
	end
end

function ForestryHook:setTargetNode(nodeId, isActiveDirty)
	self.targetNode = nodeId
	self.validTarget = nodeId ~= nil
	if self.validTarget then
		local v77_, v78_, v79_ = getWorldTranslation(self.targetNode)
		self.tx = v77_
		self.ty = v78_
		self.tz = v79_
		self:update(9999)
	end
	if isActiveDirty and self.validTarget then
		g_currentMission:removeUpdateable(self)
		g_currentMission:addUpdateable(self)
	else
		g_currentMission:removeUpdateable(self)
	end
end

function ForestryHook:setTargetPosition(x, y, z)
	self.tx = x
	self.ty = y
	self.tz = z
	self.validTarget = true
	self:update(9999)
end

function ForestryHook:setSubTargetNode(nodeId, index)
	self.subTargetNodes[index] = nodeId
end

-- Local values: i, _
function ForestryHook:resetSubTargetNodes()
	for v88_, _ in pairs(self.subTargetNodes) do
		self.subTargetNodes[v88_] = nil
	end
end

function ForestryHook:link(node, x, y, z, rx, ry, rz)
	self.linkNode = node
	local v97_ = x or self.x
	local v98_ = y or self.y
	local v99_ = z or self.z
	self.x = v97_
	self.y = v98_
	self.z = v99_
	local v100_ = rx or self.rx
	local v101_ = ry or self.ry
	local v102_ = rz or self.rz
	self.rx = v100_
	self.ry = v101_
	self.rz = v102_
	if self.hookId ~= nil then
		link(self.linkNode, self.hookId)
		setVisibility(self.hookId, self.visibility)
		setTranslation(self.hookId, self.x, self.y, self.z)
		setRotation(self.hookId, self.rx, self.ry, self.rz)
	end
end

function ForestryHook:setPositionAndDirection(x, y, z, dx, dz)
	local v109_, v110_, v111_ = worldToLocal(self.linkNode, x, y, z)
	self.x = v109_
	self.y = v110_
	self.z = v111_
	local v112_, v113_, v114_ = worldRotationToLocal(self.linkNode, 0, MathUtil.getYRotationFromDirection(dx, dz), 0)
	self.rx = v112_
	self.ry = v113_
	self.rz = v114_
	if self.hookId ~= nil then
		link(self.linkNode, self.hookId)
		setVisibility(self.hookId, self.visibility)
		setTranslation(self.hookId, self.x, self.y, self.z)
		setRotation(self.hookId, self.rx, self.ry, self.rz)
	end
end

-- Local values: alpha, spacing
function ForestryHook:getBeltSpacing(radius)
	if not self.treeBelt.dynamicBeltSpacing.isActive then
		return self.treeBelt.spacing
	end
	local v117_ = MathUtil.inverseLerp(self.treeBelt.dynamicBeltSpacing.minRadius, self.treeBelt.dynamicBeltSpacing.maxRadius, radius)
	return MathUtil.lerp(self.treeBelt.dynamicBeltSpacing.minSpacing, self.treeBelt.dynamicBeltSpacing.maxSpacing, v117_)
end

-- Local values: alpha, i, nodeData, rx, ry, rz, x, y, z
function ForestryHook:updateDynamicSpacingNodes(radius)
	if self.treeBelt.dynamicBeltSpacing.isActive then
		local v120_ = MathUtil.inverseLerp(self.treeBelt.dynamicBeltSpacing.minRadius, self.treeBelt.dynamicBeltSpacing.maxRadius, radius)
		for v121_ = 1, #self.treeBelt.dynamicBeltSpacing.adjustmentNodes do
			local v122_ = self.treeBelt.dynamicBeltSpacing.adjustmentNodes[v121_]
			if v122_.minRot ~= nil and v122_.maxRot ~= nil then
				local v123_, v124_, v125_ = MathUtil.vector3ArrayLerp(v122_.minRot, v122_.maxRot, v120_)
				setRotation(v122_.node, v123_, v124_, v125_)
			end
			if v122_.minTrans ~= nil and v122_.maxTrans ~= nil then
				local v126_, v127_, v128_ = MathUtil.vector3ArrayLerp(v122_.minTrans, v122_.maxTrans, v120_)
				setTranslation(v122_.node, v126_, v127_, v128_)
			end
		end
	end
	return self.treeBelt.spacing
end

-- Local values: cx, cy, cz, upX, upY, upZ, radius, dx, dy, dz, beltShape, wtx, wty, wtz, wrx, wry, wrz
function ForestryHook:mountToTree(splitShapeId, x, y, z, maxRadius, tx, ty, tz)
	local v137_, v138_, v139_, v140_, v141_, v142_, v143_ = SplitShapeUtil.getTreeOffsetPosition(splitShapeId, x, y, z, 4)
	if v137_ == nil then
		return nil
	end
	local v144_ = tx or x
	local v145_ = ty or y
	local v146_ = tz or z
	if getRigidBodyType(splitShapeId) == RigidBodyType.STATIC then
		local v147_, v148_, v149_ = MathUtil.vector3Normalize(v144_ - v137_, v145_ - v138_, v146_ - v139_)
		v144_ = v137_ + v147_ * v143_
		local v150_ = v138_ + v148_ * v143_
		v146_ = v139_ + v149_ * v143_
		local v151_ = v138_ - self.treeBelt.maxDeltaY
		local v152_ = v138_ + self.treeBelt.maxDeltaY
		v145_ = math.clamp(v150_, v151_, v152_)
		local v153_ = v138_ - v145_
		v143_ = v143_ + math.abs(v153_)
		setShaderParameterRecursive(splitShapeId, "windSnowLeafScale", 0, nil, nil, nil, false)
	end
	local v154_ = SplitShapeUtil.createTreeBelt(self.treeBelt.beltData, splitShapeId, v137_, v138_, v139_, v144_, v145_, v146_, v140_, v141_, v142_, v143_ + self.treeBelt.offset, false, self:getBeltSpacing(v143_))
	local v155_, v156_, v157_ = getWorldTranslation(v154_)
	local v158_, v159_, v160_ = getWorldRotation(v154_)
	link(splitShapeId, v154_)
	setWorldTranslation(v154_, v155_, v156_, v157_)
	setWorldRotation(v154_, v158_, v159_, v160_)
	self:link(v154_, 0, 0, 0, 0, 0, 0)
	self:updateDynamicSpacingNodes(v143_)
	if self.beltShape ~= nil then
		delete(self.beltShape)
	end
	self.splitShapeId = splitShapeId
	self.beltShape = v154_
	return v137_, v138_, v139_
end

function ForestryHook:setVisibility(visibility)
	self.visibility = visibility
	if self.hookId ~= nil then
		setVisibility(self.hookId, self.visibility)
	end
end

function ForestryHook:getRopeTargetPosition()
	if self.ropeTarget == nil or not entityExists(self.ropeTarget) then
		return 0, 0, 0
	else
		return getWorldTranslation(self.ropeTarget)
	end
end

function ForestryHook:getRopeTarget()
	return self.ropeTarget or (self.hookId or self.linkNode)
end

function ForestryHook:getRopeTargets()
	return self.ropeTargets
end

function ForestryHook:onI3DLoaded(i3dNode, failedReason)
	if i3dNode ~= 0 then
		self.hookId = getChildAt(i3dNode, 0)
		link(self.linkNode, self.hookId)
		setVisibility(self.hookId, self.visibility)
		setTranslation(self.hookId, self.x, self.y, self.z)
		setRotation(self.hookId, self.rx, self.ry, self.rz)
		self:loadFromConfigXML(self.hookXMLFile)
		self.hookXMLFile:delete()
		self.hookXMLFile = nil
		self:update(9999)
		delete(i3dNode)
	end
end
