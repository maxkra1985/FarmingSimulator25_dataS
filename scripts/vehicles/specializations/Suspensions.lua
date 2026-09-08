Suspensions = {}
Suspensions.DEFAULT_MAX_UPDATE_DISTANCE = 40
Suspensions.SUSPENSION_NODE_XML_KEY = "vehicle.suspensions.suspension(?)"

function Suspensions.prerequisitesPresent(specializations)
	return true
end
function Suspensions.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Suspensions")
	local v2_ = Suspensions.SUSPENSION_NODE_XML_KEY
	v1_:register(XMLValueType.NODE_INDEX, v2_ .. "#node", "Suspension node")
	v1_:register(XMLValueType.BOOL, v2_ .. "#useCharacterTorso", "Use character torso instead of node")
	v1_:register(XMLValueType.FLOAT, v2_ .. "#weight", "Weight in kg", 500)
	v1_:register(XMLValueType.VECTOR_ROT, v2_ .. "#minRotation", "Min. rotation")
	v1_:register(XMLValueType.VECTOR_ROT, v2_ .. "#maxRotation", "Max. rotation")
	v1_:register(XMLValueType.VECTOR_TRANS, v2_ .. "#startTranslationOffset", "Custom translation offset")
	v1_:register(XMLValueType.VECTOR_TRANS, v2_ .. "#minTranslation", "Min. translation")
	v1_:register(XMLValueType.VECTOR_TRANS, v2_ .. "#maxTranslation", "Max. translation")
	v1_:register(XMLValueType.FLOAT, v2_ .. "#maxVelocityDifference", "Max. velocity difference", 0.1)
	v1_:register(XMLValueType.VECTOR_2, v2_ .. "#suspensionParametersX", "Suspension parameters X", "0 0")
	v1_:register(XMLValueType.VECTOR_2, v2_ .. "#suspensionParametersY", "Suspension parameters Y", "0 0")
	v1_:register(XMLValueType.VECTOR_2, v2_ .. "#suspensionParametersZ", "Suspension parameters Z", "0 0")
	v1_:register(XMLValueType.BOOL, v2_ .. "#inverseMovement", "Invert movement", false)
	v1_:register(XMLValueType.BOOL, v2_ .. "#serverOnly", "Suspension is only calculated on server side", false)
	v1_:register(XMLValueType.FLOAT, "vehicle.suspensions#maxUpdateDistance", "Max. distance to vehicle root to update suspension nodes", Suspensions.DEFAULT_MAX_UPDATE_DISTANCE)
	v1_:setXMLSpecializationType()
end

function Suspensions.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadSuspensionNodeFromXML", Suspensions.loadSuspensionNodeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getSuspensionNodeFromIndex", Suspensions.getSuspensionNodeFromIndex)
	SpecializationUtil.registerFunction(vehicleType, "getIsSuspensionNodeActive", Suspensions.getIsSuspensionNodeActive)
	SpecializationUtil.registerFunction(vehicleType, "setSuspensionNodeCharacter", Suspensions.setSuspensionNodeCharacter)
end

function Suspensions.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Suspensions)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Suspensions)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Suspensions)
	SpecializationUtil.registerEventListener(vehicleType, "onVehicleCharacterChanged", Suspensions)
end

-- Local values: spec, _, key, suspensionNode
function Suspensions:onLoad(savegame)
	if self.isClient then
		local v6_ = self.spec_suspensions
		v6_.suspensionNodes = {}
		for _, v7_ in self.xmlFile:iterator("vehicle.suspensions.suspension") do
			local v8_ = {}
			if self:loadSuspensionNodeFromXML(self.xmlFile, v7_, v8_) and (not v8_.serverOnly or self.isServer) then
				local v9_ = v6_.suspensionNodes
				table.insert(v9_, v8_)
			end
		end
		v6_.maxUpdateDistance = self.xmlFile:getValue("vehicle.suspensions#maxUpdateDistance", Suspensions.DEFAULT_MAX_UPDATE_DISTANCE)
		if #v6_.suspensionNodes > 0 then
			v6_.suspensionAvailable = true
		end
		if not Platform.gameplay.allowSuspensionNodes and self.xmlFile:hasProperty("vehicle.suspensions") then
			Logging.xmlWarning(self.xmlFile, "Suspension nodes are not allowed on this platform")
			v6_.suspensionAvailable = false
			v6_.suspensionNodes = {}
		end
	end
	if not self.spec_suspensions.suspensionAvailable then
		SpecializationUtil.removeEventListener(self, "onUpdate", Suspensions)
		SpecializationUtil.removeEventListener(self, "onEnterVehicle", Suspensions)
		SpecializationUtil.removeEventListener(self, "onVehicleCharacterChanged", Suspensions)
	end
end

-- Local values: spec, timeDelta, _, suspension, wx, wy, wz, direction, newVelX, newVelY, newVelZ, oldVelX, oldVelY, oldVelZ, velDiffX, velDiffY, velDiffZ, i, suspensionParameter, f, k, c, x, vx, force, m, h, numerator, denumerator, curRotationSpeed, newRotation, x, vx, force, m, h, numerator, denumerator, curTranslationSpeed, newTranslation
function Suspensions:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v12_ = self.spec_suspensions
	if self.currentUpdateDistance < v12_.maxUpdateDistance then
		local v13_
		if self.isServer then
			v13_ = 0.001 * g_physicsDt
		else
			v13_ = 0.001 * dt
		end
		for _, v14_ in ipairs(v12_.suspensionNodes) do
			if v14_.node == nil or not entityExists(v14_.node) then
				if v14_.node ~= nil then
					Logging.xmlError(self.xmlFile, "Failed to update suspension node %d. Node does not exist anymore!", v14_.node)
					v14_.node = nil
				end
			else
				local v15_ = v14_.curAcc
				local v16_ = v14_.curAcc
				local v17_ = v14_.curAcc
				v15_[1] = 0
				v16_[2] = 0
				v17_[3] = 0
				if self:getIsSuspensionNodeActive(v14_) then
					local v18_ = localToWorld
					local v19_ = v14_.component
					local v20_ = v14_.refNodeOffset
					local v21_, v22_, v23_ = v18_(v19_, unpack(v20_))
					if v14_.lastRefNodePosition == nil then
						v14_.lastRefNodePosition = { v21_, v22_, v23_ }
						v14_.lastRefNodeVelocity = { 0, 0, 0 }
					end
					local v24_ = v14_.inverseMovement and -1 or 1
					local v25_ = (v21_ - v14_.lastRefNodePosition[1]) / v13_ * v24_
					local v26_ = (v22_ - v14_.lastRefNodePosition[2]) / v13_ * v24_
					local v27_ = (v23_ - v14_.lastRefNodePosition[3]) / v13_ * v24_
					local v28_ = v14_.lastRefNodeVelocity
					local v29_, v30_, v31_ = unpack(v28_)
					local v32_, v33_, v34_ = worldDirectionToLocal(getParent(v14_.node), v25_ - v29_, v26_ - v30_, v27_ - v31_)
					local v35_ = -v14_.maxVelocityDifference
					local v36_ = v14_.maxVelocityDifference
					local v37_ = math.clamp(v32_, v35_, v36_)
					local v38_ = -v14_.maxVelocityDifference
					local v39_ = v14_.maxVelocityDifference
					local v40_ = math.clamp(v33_, v38_, v39_)
					local v41_ = -v14_.maxVelocityDifference
					local v42_ = v14_.maxVelocityDifference
					local v43_ = math.clamp(v34_, v41_, v42_)
					if v14_.isRotational then
						if v14_.useCharacterTorso then
							local v44_ = v14_.curAcc
							local v45_ = v14_.curAcc
							local v46_ = v14_.curAcc
							local v47_, v48_, v49_ = MathUtil.crossProduct(v37_ / v13_, v40_ / v13_, v43_ / v13_, 1, 0, 0)
							v44_[1] = v47_
							v45_[2] = v48_
							v46_[3] = v49_
						else
							local v50_ = v14_.curAcc
							local v51_ = v14_.curAcc
							local v52_ = v14_.curAcc
							local v53_, v54_, v55_ = MathUtil.crossProduct(v37_ / v13_, v40_ / v13_, v43_ / v13_, 0, 1, 0)
							v50_[1] = v53_
							v51_[2] = v54_
							v52_[3] = v55_
						end
					else
						local v56_ = v14_.curAcc
						local v57_ = v14_.curAcc
						local v58_ = v14_.curAcc
						local v59_ = -v37_ / v13_
						local v60_ = -v40_ / v13_
						local v61_ = -v43_ / v13_
						v56_[1] = v59_
						v57_[2] = v60_
						v58_[3] = v61_
					end
					v14_.lastRefNodePosition[1] = v21_
					v14_.lastRefNodePosition[2] = v22_
					v14_.lastRefNodePosition[3] = v23_
					v14_.lastRefNodeVelocity[1] = v25_
					v14_.lastRefNodeVelocity[2] = v26_
					v14_.lastRefNodeVelocity[3] = v27_
				end
				for v62_ = 1, 3 do
					local v63_ = v14_.suspensionParameters[v62_]
					if v63_[1] > 0 and v63_[2] > 0 then
						local v64_ = v14_.weight * v14_.curAcc[v62_]
						local v65_ = v63_[1]
						local v66_ = v63_[2]
						if v14_.isRotational then
							local v67_ = v14_.curRotation[v62_]
							local v68_ = v14_.curRotationSpeed[v62_]
							local v69_ = v64_ - v65_ * v67_ - v66_ * v68_
							local v70_ = v14_.weight
							local v71_ = v67_ + (v68_ + v13_ * (v69_ + v13_ * -v65_ * v68_) / v70_ / (1 - (-v66_ + v13_ * -v65_) * v13_ / v70_)) * v13_
							local v72_ = v14_.minRotation[v62_]
							local v73_ = v14_.maxRotation[v62_]
							local v74_ = math.clamp(v71_, v72_, v73_)
							v14_.curRotationSpeed[v62_] = (v74_ - v67_) / v13_
							v14_.curRotation[v62_] = v74_
						else
							local v75_ = v14_.curTranslation[v62_]
							local v76_ = v14_.curTranslationSpeed[v62_]
							local v77_ = v64_ - v65_ * v75_ - v66_ * v76_
							local v78_ = v14_.weight
							local v79_ = v75_ + (v76_ + v13_ * (v77_ + v13_ * -v65_ * v76_) / v78_ / (1 - (-v66_ + v13_ * -v65_) * v13_ / v78_)) * v13_
							local v80_ = v14_.minTranslation[v62_]
							local v81_ = v14_.maxTranslation[v62_]
							local v82_ = math.clamp(v79_, v80_, v81_)
							v14_.curTranslationSpeed[v62_] = (v82_ - v75_) / v13_
							v14_.curTranslation[v62_] = v82_
						end
					end
				end
				if v14_.isRotational then
					setRotation(v14_.node, v14_.curRotation[1], v14_.curRotation[2], v14_.curRotation[3])
				elseif v14_.minTranslation ~= nil then
					setTranslation(v14_.node, v14_.baseTranslation[1] + v14_.curTranslation[1], v14_.baseTranslation[2] + v14_.curTranslation[2], v14_.baseTranslation[3] + v14_.curTranslation[3])
				end
				if self.setMovingToolDirty ~= nil then
					self:setMovingToolDirty(v14_.node)
				end
			end
		end
	end
end

-- Local values: component, suspensionParametersX, suspensionParametersY, suspensionParametersZ, j
function Suspensions:loadSuspensionNodeFromXML(xmlFile, key, suspensionNode)
	suspensionNode.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if suspensionNode.node ~= nil then
		local v87_ = self:getParentComponent(suspensionNode.node)
		if v87_ ~= nil then
			suspensionNode.component = v87_
			suspensionNode.refNodeOffset = { localToLocal(suspensionNode.node, v87_, 0, 0, 0) }
		end
	end
	suspensionNode.refNodeOffset = suspensionNode.refNodeOffset or { 0, 0, 0 }
	suspensionNode.useCharacterTorso = xmlFile:getValue(key .. "#useCharacterTorso", false)
	if (suspensionNode.node == nil or suspensionNode.component == nil) and not suspensionNode.useCharacterTorso then
		return false
	end
	suspensionNode.weight = xmlFile:getValue(key .. "#weight", 500)
	suspensionNode.minRotation = xmlFile:getValue(key .. "#minRotation", nil, true)
	suspensionNode.maxRotation = xmlFile:getValue(key .. "#maxRotation", nil, true)
	local v88_
	if suspensionNode.minRotation == nil then
		v88_ = false
	else
		v88_ = suspensionNode.maxRotation ~= nil
	end
	suspensionNode.isRotational = v88_
	if not (suspensionNode.isRotational or suspensionNode.useCharacterTorso) then
		suspensionNode.baseTranslation = { getTranslation(suspensionNode.node) }
		suspensionNode.startTranslationOffset = xmlFile:getValue(key .. "#startTranslationOffset", "0 0 0", true)
		suspensionNode.baseTranslation[1] = suspensionNode.baseTranslation[1] + suspensionNode.startTranslationOffset[1]
		suspensionNode.baseTranslation[2] = suspensionNode.baseTranslation[2] + suspensionNode.startTranslationOffset[2]
		suspensionNode.baseTranslation[3] = suspensionNode.baseTranslation[3] + suspensionNode.startTranslationOffset[3]
		setTranslation(suspensionNode.node, suspensionNode.baseTranslation[1], suspensionNode.baseTranslation[2], suspensionNode.baseTranslation[3])
		suspensionNode.minTranslation = xmlFile:getValue(key .. "#minTranslation", nil, true)
		suspensionNode.maxTranslation = xmlFile:getValue(key .. "#maxTranslation", nil, true)
		if suspensionNode.minTranslation == nil or suspensionNode.maxTranslation == nil then
			Logging.xmlWarning(xmlFile, "suspension \'%s\' has neither rotational nor translational limits, ignoring", key)
			return false
		end
	end
	suspensionNode.maxVelocityDifference = xmlFile:getValue(key .. "#maxVelocityDifference", 0.1)
	local v89_ = xmlFile:getValue(key .. "#suspensionParametersX", "0 0", true)
	local v90_ = xmlFile:getValue(key .. "#suspensionParametersY", "0 0", true)
	local v91_ = xmlFile:getValue(key .. "#suspensionParametersZ", "0 0", true)
	suspensionNode.suspensionParameters = {}
	suspensionNode.suspensionParameters[1] = {}
	suspensionNode.suspensionParameters[2] = {}
	suspensionNode.suspensionParameters[3] = {}
	for v92_ = 1, 2 do
		suspensionNode.suspensionParameters[1][v92_] = v89_[v92_] * 1000
		suspensionNode.suspensionParameters[2][v92_] = v90_[v92_] * 1000
		suspensionNode.suspensionParameters[3][v92_] = v91_[v92_] * 1000
	end
	suspensionNode.inverseMovement = xmlFile:getValue(key .. "#inverseMovement", false)
	suspensionNode.serverOnly = xmlFile:getValue(key .. "#serverOnly", false)
	suspensionNode.lastRefNodePosition = nil
	suspensionNode.lastRefNodeVelocity = nil
	suspensionNode.curRotation = { 0, 0, 0 }
	suspensionNode.curRotationSpeed = { 0, 0, 0 }
	suspensionNode.curTranslation = { 0, 0, 0 }
	suspensionNode.curTranslationSpeed = { 0, 0, 0 }
	suspensionNode.curAcc = { 0, 0, 0 }
	return true
end

-- Local values: spec
function Suspensions:getSuspensionNodeFromIndex(suspensionIndex)
	if self.spec_suspensions.suspensionAvailable then
		return self.spec_suspensions.suspensionNodes[suspensionIndex]
	else
		return nil
	end
end

function Suspensions:getIsSuspensionNodeActive(suspensionNode)
	local v96_
	if suspensionNode.node == nil then
		v96_ = false
	else
		v96_ = suspensionNode.component ~= nil
	end
	return v96_
end

-- Local values: component
function Suspensions:setSuspensionNodeCharacter(suspensionNode, character)
	if suspensionNode.useCharacterTorso and character.playerModel ~= nil then
		suspensionNode.node = character.playerModel.thirdPersonSuspensionNode
		if suspensionNode.node ~= nil then
			local v100_ = self:getParentComponent(suspensionNode.node)
			if v100_ ~= nil then
				suspensionNode.refNodeOffset = { localToLocal(character.characterNode, v100_, 0, 0, 0) }
				suspensionNode.component = v100_
			end
		end
	end
end

-- Local values: vehicleCharacter, spec, _, suspensionNode
function Suspensions:onEnterVehicle(isControlling)
	if self.getVehicleCharacter ~= nil then
		local v102_ = self:getVehicleCharacter()
		if v102_ ~= nil then
			local v103_ = self.spec_suspensions
			for _, v104_ in ipairs(v103_.suspensionNodes) do
				self:setSuspensionNodeCharacter(v104_, v102_)
			end
		end
	end
end

-- Local values: spec, _, suspensionNode
function Suspensions:onVehicleCharacterChanged(character)
	local v107_ = self.spec_suspensions
	for _, v108_ in ipairs(v107_.suspensionNodes) do
		if v108_.useCharacterTorso then
			if character == nil then
				v108_.node = nil
			else
				self:setSuspensionNodeCharacter(v108_, character)
			end
		end
	end
end

function Suspensions.subCollisionErrorFunction(collisionNode, xmlFile, nodeName)
	if getHasClassId(collisionNode, ClassIds.SHAPE) then
		Logging.xmlError(xmlFile, "Found collision \'%s\' as child of suspension node \'%s\'. This can cause the vehicle to never sleep!", getName(collisionNode), nodeName)
	end
end

-- Local values: spec, index, suspensionNode
function Suspensions:getSuspensionModfier()
	local v113_ = self.spec_suspensions
	local v114_ = #v113_.suspensionNodes >= 2 and not (v113_.suspensionNodes[2].useCharacterTorso or v113_.suspensionNodes[2].isRotational) and 2 or 1
	local v115_ = v113_.suspensionNodes[v114_]
	return (v115_ == nil or v115_.isRotational) and 0 or v115_.curTranslation[2]
end
g_soundManager:registerModifierType("SUSPENSION", Suspensions.getSuspensionModfier)
