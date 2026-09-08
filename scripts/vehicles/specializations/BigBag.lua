BigBag = {}

function BigBag.prerequisitesPresent(vehicleType)
	return true
end
function BigBag.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("BigBag")
	v1_:register(XMLValueType.INT, "vehicle.bigBag#fillUnitIndex", "Fill unit index")
	v1_:register(XMLValueType.STRING, "vehicle.bigBag.sizeAnimation#name", "Name of size animation")
	v1_:register(XMLValueType.FLOAT, "vehicle.bigBag.sizeAnimation#minTime", "Min. animation that is used while it\'s empty", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.bigBag.sizeAnimation#maxTime", "Max. animation that is used while it\'s full", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.bigBag.sizeAnimation#liftShrinkTime", "Time of animation that is reduced while the big bag is lifted", 0.2)
	v1_:register(XMLValueType.INT, "vehicle.bigBag.componentJoint#index", "Component Joint Index", 1)
	v1_:register(XMLValueType.VECTOR_ROT, "vehicle.bigBag.componentJoint#minRotLimit", "Rot Limit if trans limit is at min")
	v1_:register(XMLValueType.VECTOR_ROT, "vehicle.bigBag.componentJoint#maxRotLimit", "Rot Limit if trans limit is at max")
	v1_:register(XMLValueType.VECTOR_TRANS, "vehicle.bigBag.componentJoint#minTransLimit", "Trans Limit if big bag is empty")
	v1_:register(XMLValueType.VECTOR_TRANS, "vehicle.bigBag.componentJoint#maxTransLimit", "Trans Limit if big bag is full")
	v1_:register(XMLValueType.FLOAT, "vehicle.bigBag.componentJoint#angularDamping", "Angular damping of components", 0.01)
	v1_:setXMLSpecializationType()
end

function BigBag.registerFunctions(vehicleType) end

function BigBag.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getInfoBoxTitle", BigBag.getInfoBoxTitle)
end

function BigBag.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", BigBag)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", BigBag)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", BigBag)
end

-- Local values: spec, jointDesc
function BigBag:onLoad(savegame)
	local v5_ = self.spec_bigBag
	v5_.fillUnitIndex = self.xmlFile:getValue("vehicle.bigBag#fillUnitIndex", 1)
	v5_.sizeAnimationName = self.xmlFile:getValue("vehicle.bigBag.sizeAnimation#name")
	v5_.sizeAnimationMinTime = self.xmlFile:getValue("vehicle.bigBag.sizeAnimation#minTime", 0)
	v5_.sizeAnimationMaxTime = self.xmlFile:getValue("vehicle.bigBag.sizeAnimation#maxTime", 1)
	v5_.sizeAnimationLiftShrinkTime = self.xmlFile:getValue("vehicle.bigBag.sizeAnimation#liftShrinkTime", 0.2)
	v5_.componentJointIndex = self.xmlFile:getValue("vehicle.bigBag.componentJoint#index", 1)
	local v6_ = self.componentJoints[v5_.componentJointIndex]
	if v6_ ~= nil then
		v5_.minRotLimit = self.xmlFile:getValue("vehicle.bigBag.componentJoint#minRotLimit", nil, true)
		v5_.maxRotLimit = self.xmlFile:getValue("vehicle.bigBag.componentJoint#maxRotLimit", nil, true)
		v5_.minTransLimit = self.xmlFile:getValue("vehicle.bigBag.componentJoint#minTransLimit", nil, true)
		v5_.maxTransLimit = self.xmlFile:getValue("vehicle.bigBag.componentJoint#maxTransLimit", nil, true)
		v5_.componentJoint = v6_
		v5_.jointNode = v6_.jointNode
		v5_.jointNodeReferenceNode = createTransformGroup("jointNodeReference")
		link(self.components[v6_.componentIndices[2]].node, v5_.jointNodeReferenceNode)
		setWorldTranslation(v5_.jointNodeReferenceNode, getWorldTranslation(v5_.jointNode))
		setWorldRotation(v5_.jointNodeReferenceNode, getWorldRotation(v5_.jointNode))
		v5_.component1 = self.components[v5_.componentJoint.componentIndices[1]]
		v5_.component2 = self.components[v5_.componentJoint.componentIndices[2]]
		v5_.angularDamping = self.xmlFile:getValue("vehicle.bigBag.componentJoint#angularDamping", 0.01)
		setAngularDamping(v5_.component1.node, v5_.angularDamping)
		setAngularDamping(v5_.component2.node, v5_.angularDamping)
		v5_.lastJointLimitAlpha = -1
	end
	v5_.currentShrinkTime = 0
	v5_.currentSizeTime = 1
	v5_.currentAnimationTime = 1
end

-- Local values: spec, xLimit, _, _, xOffset, _, _, alpha, rx, ry, rz, newAnimationTime
function BigBag:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v8_ = self.spec_bigBag
	if v8_.jointNode ~= nil then
		local v9_, _, _ = MathUtil.lerp(v8_.minTransLimit[1], v8_.maxTransLimit[1], self:getFillUnitFillLevelPercentage(v8_.fillUnitIndex))
		local v10_, _, _ = localToLocal(v8_.jointNode, v8_.jointNodeReferenceNode, 0, 0, 0)
		local v11_ = (v10_ / v9_ + 1) / 2
		local v12_ = 1 - math.clamp(v11_, 0, 1)
		v8_.currentShrinkTime = v12_ * v8_.sizeAnimationLiftShrinkTime
		if self.isServer then
			local v13_ = v8_.lastJointLimitAlpha - v12_
			if math.abs(v13_) > 0.05 then
				if v8_.minRotLimit ~= nil and v8_.maxRotLimit ~= nil then
					local v14_, v15_, v16_ = MathUtil.vector3ArrayLerp(v8_.minRotLimit, v8_.maxRotLimit, v12_)
					self:setComponentJointRotLimit(v8_.componentJoint, 1, -v14_, v14_)
					self:setComponentJointRotLimit(v8_.componentJoint, 2, -v15_, v15_)
					self:setComponentJointRotLimit(v8_.componentJoint, 3, -v16_, v16_)
				end
				v8_.lastJointLimitAlpha = v12_
			end
		end
		local v17_ = v8_.currentSizeTime * (1 - v8_.currentShrinkTime)
		local v18_ = v17_ - v8_.currentAnimationTime
		if math.abs(v18_) > 0.01 then
			self:setAnimationTime(v8_.sizeAnimationName, v17_)
			v8_.currentAnimationTime = v17_
		end
	end
end

-- Local values: spec, fillLevelPct, x, y, z
function BigBag:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local v21_ = self.spec_bigBag
	if v21_.fillUnitIndex == fillUnitIndex then
		local v22_ = self:getFillUnitFillLevelPercentage(fillUnitIndex)
		v21_.currentSizeTime = v22_ * (v21_.sizeAnimationMaxTime - v21_.sizeAnimationMinTime) + v21_.sizeAnimationMinTime
		v21_.currentAnimationTime = v21_.currentSizeTime * (1 - v21_.currentShrinkTime)
		self:setAnimationTime(v21_.sizeAnimationName, v21_.currentAnimationTime)
		if self.isServer and (v21_.minTransLimit ~= nil and v21_.maxTransLimit ~= nil) then
			local v23_, v24_, v25_ = MathUtil.vector3ArrayLerp(v21_.minTransLimit, v21_.maxTransLimit, v22_)
			self:setComponentJointTransLimit(v21_.componentJoint, 1, -v23_, v23_)
			self:setComponentJointTransLimit(v21_.componentJoint, 2, -v24_, v24_)
			self:setComponentJointTransLimit(v21_.componentJoint, 3, -v25_, v25_)
		end
	end
end

function BigBag:getInfoBoxTitle(superFunc)
	return g_i18n:getText("shopItem_bigBag")
end
