-- Local values: ForestryRope_mt
ForestryRope = {}
local ForestryRope_mt = Class(ForestryRope)

-- Upvalues: ForestryRope_mt
-- Local values: self
function ForestryRope.new(vehicle, linkNode, customMt)
	-- upvalues: (copy) ForestryRope_mt
	local v5_ = customMt or ForestryRope_mt
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
	v6_.tx = 0
	v6_.ty = 0
	v6_.tz = 0
	v6_.validTarget = false
	v6_.boundingRadius = 1
	return v6_
end

function ForestryRope.registerXMLPaths(schema, baseKey)
	schema:register(XMLValueType.STRING, baseKey .. "#filename", "Path to rope i3d file", "$data/shared/forestry/ropes.i3d")
	schema:register(XMLValueType.STRING, baseKey .. "#ropeNode", "Path to rope i3d file", "0")
	schema:register(XMLValueType.FLOAT, baseKey .. "#diameter", "Diameter of the rope", 0.02)
	schema:register(XMLValueType.FLOAT, baseKey .. "#uvScale", "UV scale of the rope", 4)
	schema:register(XMLValueType.VECTOR_4, baseKey .. "#emissiveColor", "Emissive color", "0 0 0")
	schema:register(XMLValueType.VECTOR_4, baseKey .. "#invalidEmissiveColor", "Emissive color", "0 0 0")
end

function ForestryRope:loadFromXML(xmlFile, key, baseDirectory)
	self.i3dFilename = xmlFile:getValue(key .. "#filename", "$data/shared/forestry/ropes.i3d")
	self.i3dRopePath = xmlFile:getValue(key .. "#ropeNode", "0")
	self.diameter = xmlFile:getValue(key .. "#diameter", 0.02)
	self.uvScale = xmlFile:getValue(key .. "#uvScale", 4)
	self.emissiveColor = xmlFile:getValue(key .. "#emissiveColor", "0 0 0 0", true)
	self.invalidEmissiveColor = xmlFile:getValue(key .. "#invalidEmissiveColor", "0 0 0 0", true)
	if self.i3dFilename ~= nil then
		self.i3dFilename = Utils.getFilename(self.i3dFilename, baseDirectory)
		if self.vehicle ~= nil then
			self.sharedLoadRequestId = self.vehicle:loadSubSharedI3DFile(self.i3dFilename, false, false, self.onI3DLoaded, self, self)
			return
		end
		self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, false, false, self.onI3DLoaded, self, self)
	end
end

function ForestryRope:loadFromConfigXML(xmlFile) end

-- Local values: ropeClone, i3dNode, sharedLoadRequestId, failedReason
function ForestryRope:clone(linkNode)
	local v15_ = ForestryRope.new(self.vehicle, linkNode or self.linkNode)
	v15_.i3dFilename = self.i3dFilename
	v15_.i3dRopePath = self.i3dRopePath
	v15_.diameter = self.diameter
	v15_.uvScale = self.uvScale
	v15_.emissiveColor = self.emissiveColor
	v15_.invalidEmissiveColor = self.invalidEmissiveColor
	if v15_.i3dFilename ~= nil then
		local v16_, v17_, v18_ = g_i3DManager:loadSharedI3DFile(v15_.i3dFilename, false, false)
		v15_.sharedLoadRequestId = v17_
		v15_:onI3DLoaded(v16_, v18_)
		return v15_
	end
end

function ForestryRope:delete()
	g_currentMission:removeUpdateable(self)
	if self.referenceFrame ~= nil then
		if entityExists(self.referenceFrame) then
			delete(self.referenceFrame)
		end
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
	end
end

-- Local values: dx, dy, dz, length
function ForestryRope:update(dt)
	if self.validTarget then
		if self.targetNode ~= nil then
			local v21_, v22_, v23_ = getWorldTranslation(self.targetNode)
			self.tx = v21_
			self.ty = v22_
			self.tz = v23_
		end
		local v24_, v25_, v26_ = worldToLocal(self.referenceFrame, self.tx, self.ty, self.tz)
		local v27_ = MathUtil.vector3Length(v24_, v25_, v26_)
		local v28_, v29_, v30_ = MathUtil.vector3Normalize(v24_, v25_, v26_)
		setDirection(self.ropeId, v28_, v29_, v30_, 0, 1, 0)
		self:setLength(v27_)
	end
end

-- Local values: boundingRadius
function ForestryRope:setLength(length)
	if self.referenceFrame ~= nil then
		g_animationManager:setPrevShaderParameter(self.ropeId, "ropeLengthBendSizeUv", length, 0, self.diameter, self.uvScale, false, "prevRopeLengthBendSizeUv")
		local v33_ = math.ceil(length)
		local v34_ = math.max(v33_, 1) * 0.5
		if math.ceil(v34_) ~= self.boundingRadius then
			setShapeBoundingSphere(self.ropeId, 0, 0, v34_, v34_)
			self.boundingRadius = v34_
		end
	end
end

function ForestryRope:setTargetNode(nodeId, isActiveDirty)
	self.targetNode = nodeId
	local v38_, v39_, v40_ = getWorldTranslation(self.targetNode)
	self.tx = v38_
	self.ty = v39_
	self.tz = v40_
	if isActiveDirty then
		g_currentMission:removeUpdateable(self)
		g_currentMission:addUpdateable(self)
	else
		g_currentMission:removeUpdateable(self)
	end
	self.validTarget = true
	self:update(9999)
end

function ForestryRope:setTargetPosition(x, y, z)
	self.tx = x
	self.ty = y
	self.tz = z
	self.validTarget = true
	self:update(9999)
end

function ForestryRope:link(node, x, y, z, rx, ry, rz)
	self.linkNode = node
	local v53_ = x or self.x
	local v54_ = y or self.y
	local v55_ = z or self.z
	self.x = v53_
	self.y = v54_
	self.z = v55_
	local v56_ = rx or self.rx
	local v57_ = ry or self.ry
	local v58_ = rz or self.rz
	self.rx = v56_
	self.ry = v57_
	self.rz = v58_
	if self.referenceFrame ~= nil then
		link(self.linkNode, self.referenceFrame)
		setVisibility(self.referenceFrame, self.visibility)
		setTranslation(self.referenceFrame, self.x, self.y, self.z)
		setRotation(self.referenceFrame, self.rx, self.ry, self.rz)
	end
end

function ForestryRope:setPositionAndDirection(x, y, z, dx, dz)
	local v65_, v66_, v67_ = worldToLocal(self.linkNode, x, y, z)
	self.x = v65_
	self.y = v66_
	self.z = v67_
	if dx ~= nil and dz ~= nil then
		local v68_, v69_, v70_ = worldRotationToLocal(self.linkNode, 0, MathUtil.getYRotationFromDirection(dx, dz), 0)
		self.rx = v68_
		self.ry = v69_
		self.rz = v70_
	end
	if self.referenceFrame ~= nil then
		link(self.linkNode, self.referenceFrame)
		setVisibility(self.referenceFrame, self.visibility)
		setTranslation(self.referenceFrame, self.x, self.y, self.z)
		setRotation(self.referenceFrame, self.rx, self.ry, self.rz)
	end
end

function ForestryRope:setVisibility(visibility)
	self.visibility = visibility
	if self.referenceFrame ~= nil then
		setVisibility(self.referenceFrame, self.visibility)
	end
end

-- Local values: color
function ForestryRope:setEmissiveColor(valid)
	if self.ropeId ~= nil then
		local v75_ = valid and self.emissiveColor or self.invalidEmissiveColor
		setShaderParameter(self.ropeId, "ropeEmissiveColor", v75_[1], v75_[2], v75_[3], v75_[4], false)
	end
end

function ForestryRope:onI3DLoaded(i3dNode, failedReason)
	if i3dNode ~= 0 then
		self.ropeId = I3DUtil.indexToObject(i3dNode, self.i3dRopePath)
		if self.ropeId ~= nil then
			self.referenceFrame = createTransformGroup("ropeReferenceFrame")
			link(self.referenceFrame, self.ropeId)
			link(self.linkNode, self.referenceFrame)
			setVisibility(self.referenceFrame, self.visibility)
			setTranslation(self.referenceFrame, self.x, self.y, self.z)
			setRotation(self.referenceFrame, self.rx, self.ry, self.rz)
			setShaderParameter(self.ropeId, "ropeEmissiveColor", self.emissiveColor[1], self.emissiveColor[2], self.emissiveColor[3], self.emissiveColor[4], false)
			self:update(9999)
		end
		delete(i3dNode)
	end
end
