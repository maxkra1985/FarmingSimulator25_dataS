CCTDrivable = {}

function CCTDrivable.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Enterable, specializations)
end
function CCTDrivable.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("CCTDrivable")
	v2_:register(XMLValueType.FLOAT, "vehicle.cctDrivable#cctRadius", "CCT radius", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.cctDrivable#cctHeight", "CCT height", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.cctDrivable#cctSlopeLimit", "CCT slope limit", 25)
	v2_:register(XMLValueType.FLOAT, "vehicle.cctDrivable#cctStepOffset", "CCT step offset", 0.35)
	v2_:setXMLSpecializationType()
end

function CCTDrivable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getTouchingNode", CCTDrivable.getTouchingNode)
	SpecializationUtil.registerFunction(vehicleType, "moveCCTExternal", CCTDrivable.moveCCTExternal)
	SpecializationUtil.registerFunction(vehicleType, "moveCCT", CCTDrivable.moveCCT)
	SpecializationUtil.registerFunction(vehicleType, "getIsCCTOnGround", CCTDrivable.getIsCCTOnGround)
	SpecializationUtil.registerFunction(vehicleType, "getCCTCollisionMask", CCTDrivable.getCCTCollisionMask)
	SpecializationUtil.registerFunction(vehicleType, "getCCTWorldTranslation", CCTDrivable.getCCTWorldTranslation)
end

function CCTDrivable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", CCTDrivable.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setWorldPosition", CCTDrivable.setWorldPosition)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setWorldPositionQuaternion", CCTDrivable.setWorldPositionQuaternion)
end

function CCTDrivable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", CCTDrivable)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", CCTDrivable)
end

-- Local values: spec
function CCTDrivable:onLoad(savegame)
	local v7_ = self.spec_cctdrivable
	v7_.cctRadius = self.xmlFile:getValue("vehicle.cctDrivable#cctRadius", 1)
	v7_.cctHeight = self.xmlFile:getValue("vehicle.cctDrivable#cctHeight", 1)
	v7_.cctSlopeLimit = self.xmlFile:getValue("vehicle.cctDrivable#cctSlopeLimit", 25)
	v7_.cctStepOffset = self.xmlFile:getValue("vehicle.cctDrivable#cctStepOffset", 0.3)
	v7_.cctCenterOffset = -v7_.cctRadius
	v7_.kinematicCollisionGroup = CollisionFlag.ANIMAL + CollisionFlag.CAMERA_BLOCKING
	local v8_ = CollisionMask.ALL
	local v9_ = CollisionFlag.VEHICLE
	local v10_ = CollisionFlag.ANIMAL
	local v11_ = CollisionFlag.PLAYER
	local v12_ = CollisionFlag.WATER
	local v13_ = CollisionFlag.AI_BLOCKING
	local v14_ = CollisionFlag.GROUND_TIP_BLOCKING
	local v15_ = CollisionFlag.PLACEMENT_BLOCKING
	local v16_ = CollisionFlag.CAMERA_BLOCKING
	local v17_ = CollisionFlag.PRECIPITATION_BLOCKING
	local v18_ = CollisionFlag.ANIMAL_NAV_MESH_BLOCKING
	local v19_ = CollisionFlag.TERRAIN_DISPLACEMENT
	v7_.kinematicCollisionMask = v8_ - bit32.bor(v9_, v10_, v11_, v12_, v13_, v14_, v15_, v16_, v17_, v18_, v19_)
	v7_.movementCollisionGroup = v7_.kinematicCollisionGroup
	local v20_ = CollisionMask.ALL
	local v21_ = CollisionFlag.TRIGGER
	local v22_ = CollisionFlag.WATER
	local v23_ = CollisionFlag.AI_BLOCKING
	local v24_ = CollisionFlag.GROUND_TIP_BLOCKING
	local v25_ = CollisionFlag.PLACEMENT_BLOCKING
	local v26_ = CollisionFlag.CAMERA_BLOCKING
	local v27_ = CollisionFlag.PRECIPITATION_BLOCKING
	local v28_ = CollisionFlag.ANIMAL_NAV_MESH_BLOCKING
	local v29_ = CollisionFlag.TERRAIN_DISPLACEMENT
	v7_.movementCollisionMask = v20_ - bit32.bor(v21_, v22_, v23_, v24_, v25_, v26_, v27_, v28_, v29_)
	if self.isServer then
		v7_.cctNode = createTransformGroup("cctDrivable")
		link(getRootNode(), v7_.cctNode)
	end
end

-- Local values: spec
function CCTDrivable:onDelete()
	local v31_ = self.spec_cctdrivable
	if v31_.controllerIndex ~= nil then
		removeCCT(v31_.controllerIndex)
		delete(v31_.cctNode)
	end
end

-- Local values: spec
function CCTDrivable:moveCCT(moveX, moveY, moveZ)
	if self.isServer then
		local v36_ = self.spec_cctdrivable
		moveCCT(v36_.controllerIndex, moveX, moveY, moveZ, v36_.movementCollisionGroup, v36_.movementCollisionMask)
		self:raiseActive()
	end
end

function CCTDrivable:moveCCTExternal(moveX, moveY, moveZ)
	self:moveCCT(moveX, moveY, moveZ)
end

-- Local values: spec, node
function CCTDrivable:getTouchingNode()
	local v42_ = self.spec_cctdrivable
	local v43_ = v42_.controllerIndex == nil and 0 or getCCTGroundObject(v42_.controllerIndex)
	if v43_ == 0 or not v43_ then
		v43_ = nil
	end
	return v43_
end

-- Local values: spec, _, _, isOnGround
function CCTDrivable:getIsCCTOnGround()
	local v45_ = self.spec_cctdrivable
	if not self.isServer then
		return false
	end
	local _, _, v46_ = getCCTCollisionFlags(v45_.controllerIndex)
	return v46_
end

-- Local values: spec
function CCTDrivable:getCCTCollisionMask()
	return self.spec_cctdrivable.kinematicCollisionMask
end

-- Local values: spec, cctX, cctY, cctZ
function CCTDrivable:getCCTWorldTranslation()
	local v49_ = self.spec_cctdrivable
	local v50_, v51_, v52_ = getTranslation(v49_.cctNode)
	return v50_, v51_ + v49_.cctCenterOffset, v52_
end

-- Local values: spec
function CCTDrivable:setWorldPosition(superFunc, x, y, z, xRot, yRot, zRot, i, changeInterp)
	superFunc(self, x, y, z, xRot, yRot, zRot, i, changeInterp)
	if self.isServer and i == 1 then
		local v63_ = self.spec_cctdrivable
		setTranslation(v63_.cctNode, x, y - v63_.cctCenterOffset, z)
	end
end

-- Local values: spec
function CCTDrivable:setWorldPositionQuaternion(superFunc, x, y, z, qx, qy, qz, qw, i, changeInterp)
	superFunc(self, x, y, z, qx, qy, qz, qw, i, changeInterp)
	if self.isServer and i == 1 then
		local v75_ = self.spec_cctdrivable
		setTranslation(v75_.cctNode, x, y - v75_.cctCenterOffset, z)
	end
end

-- Local values: spec, mass
function CCTDrivable:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	if self.isServer then
		local v78_ = self.spec_cctdrivable
		local v79_ = self.components[1].defaultMass * 1000
		if v78_.controllerIndex ~= nil then
			removeCCT(v78_.controllerIndex)
		end
		v78_.controllerIndex = createCCT(v78_.cctNode, v78_.cctRadius, v78_.cctHeight, v78_.cctStepOffset, v78_.cctSlopeLimit, 0.2, v78_.kinematicCollisionGroup, v78_.kinematicCollisionMask, v79_)
		setCCTPairCollision(v78_.controllerIndex, self.rootNode, false)
	end
	return true
end
