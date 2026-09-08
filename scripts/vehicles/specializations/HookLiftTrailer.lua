HookLiftTrailer = {}

function HookLiftTrailer.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Foldable, specializations)
	end
	return v2_
end
function HookLiftTrailer.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("HookLiftTrailer")
	v3_:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.jointLimits#refAnimation", "Reference animation", "unfoldHand")
	v3_:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.jointLimits.key(?)#time", "Key time")
	v3_:register(XMLValueType.VECTOR_ROT, "vehicle.hookLiftTrailer.jointLimits.key(?)#rotLimit", "Rotation limit", "0 0 0")
	v3_:register(XMLValueType.VECTOR_ROT, "vehicle.hookLiftTrailer.jointLimits.key(?)#rotMinLimit", "Negative rotation limit")
	v3_:register(XMLValueType.VECTOR_ROT, "vehicle.hookLiftTrailer.jointLimits.key(?)#rotMaxLimit", "Positive rotation limit")
	v3_:register(XMLValueType.VECTOR_TRANS, "vehicle.hookLiftTrailer.jointLimits.key(?)#transLimit", "Translation limit", "0 0 0")
	v3_:register(XMLValueType.VECTOR_TRANS, "vehicle.hookLiftTrailer.jointLimits.key(?)#transMinLimit", "Negative translation limit")
	v3_:register(XMLValueType.VECTOR_TRANS, "vehicle.hookLiftTrailer.jointLimits.key(?)#transMaxLimit", "Positive translation limit")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.hookLiftTrailer.additionalJoint#node", "Additional joint to mount the container when fully lifted")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.hookLiftTrailer.additionalJoint#attacherJointNode", "Attacher joint node of the hook")
	v3_:register(XMLValueType.BOOL, "vehicle.hookLiftTrailer.additionalJoint#disableCollision", "Disable collision between trailer and container when fully lifted", false)
	v3_:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.additionalJoint#lockTime", "Animation time when the additional joint is created", 0.01)
	v3_:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.additionalJoint.key(?)#time", "Key time")
	v3_:register(XMLValueType.VECTOR_ROT, "vehicle.hookLiftTrailer.additionalJoint.key(?)#rotLimit", "Rotation limit", "0 0 0")
	v3_:register(XMLValueType.VECTOR_ROT, "vehicle.hookLiftTrailer.additionalJoint.key(?)#rotMinLimit", "Negative rotation limit")
	v3_:register(XMLValueType.VECTOR_ROT, "vehicle.hookLiftTrailer.additionalJoint.key(?)#rotMaxLimit", "Positive rotation limit")
	v3_:register(XMLValueType.VECTOR_TRANS, "vehicle.hookLiftTrailer.additionalJoint.key(?)#transLimit", "Translation limit", "0 0 0")
	v3_:register(XMLValueType.VECTOR_TRANS, "vehicle.hookLiftTrailer.additionalJoint.key(?)#transMinLimit", "Negative translation limit")
	v3_:register(XMLValueType.VECTOR_TRANS, "vehicle.hookLiftTrailer.additionalJoint.key(?)#transMaxLimit", "Positive translation limit")
	v3_:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.unloadingAnimation#name", "Unload animation", "unloading")
	v3_:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.unloadingAnimation#speed", "Unload animation speed", 1)
	v3_:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.unloadingAnimation#reverseSpeed", "Unload animation reverse speed", -1)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.hookLiftTrailer.hookLock#referenceNode", "Reference node for distance to the container")
	v3_:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.hookLock#minDistance", "Min. distance to the reference node to activate object change (in Y and Z offset)", 0.05)
	v3_:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.hookLock#minDistanceSide", "Min. distance to the reference node to activate object change (in X offset)", 0.15)
	ObjectChangeUtil.registerObjectChangeXMLPaths(v3_, "vehicle.hookLiftTrailer.hookLock")
	ObjectChangeUtil.registerObjectChangeXMLPaths(v3_, "vehicle.hookLiftTrailer.containerLock")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.hookLiftTrailer.visualRoll(?)#node", "Visual roll that spins when the container gets close")
	v3_:register(XMLValueType.FLOAT, "vehicle.hookLiftTrailer.visualRoll(?)#radius", "Radius of the roll", 0.1)
	v3_:register(XMLValueType.INT, "vehicle.hookLiftTrailer.visualRoll(?)#rotAxis", "Rotation axis", 1)
	v3_:register(XMLValueType.INT, "vehicle.hookLiftTrailer.visualRoll(?)#direction", "Rotation direction", -1)
	v3_:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.texts#unloadContainer", "Unload container text", "$l10n_unload_container")
	v3_:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.texts#loadContainer", "Load container text", "$l10n_load_container")
	v3_:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.texts#unloadArm", "Unload arm text", "$l10n_unload_arm")
	v3_:register(XMLValueType.STRING, "vehicle.hookLiftTrailer.texts#loadArm", "Load arm text", "$l10n_load_arm")
	v3_:setXMLSpecializationType()
end

function HookLiftTrailer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "startTipping", HookLiftTrailer.startTipping)
	SpecializationUtil.registerFunction(vehicleType, "stopTipping", HookLiftTrailer.stopTipping)
	SpecializationUtil.registerFunction(vehicleType, "getIsTippingAllowed", HookLiftTrailer.getIsTippingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getCanDetachContainer", HookLiftTrailer.getCanDetachContainer)
	SpecializationUtil.registerFunction(vehicleType, "updateHookLiftContainerLockState", HookLiftTrailer.updateHookLiftContainerLockState)
	SpecializationUtil.registerFunction(vehicleType, "updateAdditionalHookLiftContainerJoint", HookLiftTrailer.updateAdditionalHookLiftContainerJoint)
	SpecializationUtil.registerFunction(vehicleType, "setHookLiftContainerPhysicsState", HookLiftTrailer.setHookLiftContainerPhysicsState)
end

function HookLiftTrailer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", HookLiftTrailer.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", HookLiftTrailer.isDetachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", HookLiftTrailer.getDoConsumePtoPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getPtoRpm", HookLiftTrailer.getPtoRpm)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", HookLiftTrailer.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", HookLiftTrailer.removeFromPhysics)
end

function HookLiftTrailer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", HookLiftTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", HookLiftTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", HookLiftTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", HookLiftTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", HookLiftTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateAnimation", HookLiftTrailer)
end

-- Local values: spec, loadJointLimits, _, key, visualRoll
function HookLiftTrailer:onLoad(savegame)
	local v8_ = self.spec_hookLiftTrailer
	v8_.refAnimation = self.xmlFile:getValue("vehicle.hookLiftTrailer.jointLimits#refAnimation", "unfoldHand")
	local function v35_(p9_, p10_)
		local v11_ = AnimCurve.new(linearInterpolatorN)
		for _, v12_ in p9_:iterator(p10_ .. ".key") do
			local v13_ = p9_:getValue(v12_ .. "#time")
			if v13_ ~= nil then
				local v14_, v15_, v16_ = p9_:getValue(v12_ .. "#rotLimit", "0 0 0")
				local v17_, v18_, v19_ = p9_:getValue(v12_ .. "#rotMinLimit")
				local v20_, v21_, v22_ = p9_:getValue(v12_ .. "#rotMaxLimit")
				local v23_ = v17_ or -v14_
				local v24_ = v18_ or -v15_
				local v25_ = v19_ or -v16_
				local v26_, v27_, v28_ = p9_:getValue(v12_ .. "#transLimit", "0 0 0")
				local v29_, v30_, v31_ = p9_:getValue(v12_ .. "#transMinLimit")
				local v32_, v33_, v34_ = p9_:getValue(v12_ .. "#transMaxLimit")
				v11_:addKeyframe({
					v23_,
					v24_,
					v25_,
					v20_ or v14_,
					v21_ or v15_,
					v22_ or v16_,
					v29_ or -v26_,
					v30_ or -v27_,
					v31_ or -v28_,
					v32_ or v26_,
					v33_ or v27_,
					v34_ or v28_,
					["time"] = v13_
				})
			end
		end
		if v11_.numKeyframes == 0 then
			return nil
		else
			return v11_
		end
	end
	v8_.jointLimits = v35_(self.xmlFile, "vehicle.hookLiftTrailer.jointLimits")
	v8_.additionalJointNode = self.xmlFile:getValue("vehicle.hookLiftTrailer.additionalJoint#node", nil, self.components, self.i3dMappings)
	v8_.additionalJointReferenceJointNode = self.xmlFile:getValue("vehicle.hookLiftTrailer.additionalJoint#attacherJointNode", nil, self.components, self.i3dMappings)
	v8_.additionalJointDisableCollision = self.xmlFile:getValue("vehicle.hookLiftTrailer.additionalJoint#disableCollision", false)
	v8_.additionalJointLockTime = self.xmlFile:getValue("vehicle.hookLiftTrailer.additionalJoint#lockTime", 0.01)
	v8_.additionalJointState = false
	if v8_.additionalJointNode ~= nil and v8_.additionalJointReferenceJointNode ~= nil then
		v8_.additionalJointOffset = { localToLocal(v8_.additionalJointNode, v8_.additionalJointReferenceJointNode, 0, 0, 0) }
	end
	v8_.additionalJointLimits = v35_(self.xmlFile, "vehicle.hookLiftTrailer.additionalJoint")
	v8_.unloadingAnimation = self.xmlFile:getValue("vehicle.hookLiftTrailer.unloadingAnimation#name", "unloading")
	v8_.unloadingAnimationSpeed = self.xmlFile:getValue("vehicle.hookLiftTrailer.unloadingAnimation#speed", 1)
	v8_.unloadingAnimationReverseSpeed = self.xmlFile:getValue("vehicle.hookLiftTrailer.unloadingAnimation#reverseSpeed", -1)
	if self.isClient then
		v8_.hookLock = {}
		v8_.hookLock.state = false
		v8_.hookLock.referenceNode = self.xmlFile:getValue("vehicle.hookLiftTrailer.hookLock#referenceNode", nil, self.components, self.i3dMappings)
		v8_.hookLock.minDistance = self.xmlFile:getValue("vehicle.hookLiftTrailer.hookLock#minDistance", 0.05)
		v8_.hookLock.minDistanceSide = self.xmlFile:getValue("vehicle.hookLiftTrailer.hookLock#minDistanceSide", 0.15)
		v8_.hookLock.changeObjects = {}
		ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, "vehicle.hookLiftTrailer.hookLock", v8_.hookLock.changeObjects, self.components, self)
		ObjectChangeUtil.setObjectChanges(v8_.hookLock.changeObjects, false, self, self.setMovingToolDirty)
	end
	v8_.containerLockState = false
	v8_.containerLockChangeObjects = {}
	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, "vehicle.hookLiftTrailer.containerLock", v8_.containerLockChangeObjects, self.components, self)
	ObjectChangeUtil.setObjectChanges(v8_.containerLockChangeObjects, false, self, self.setMovingToolDirty)
	v8_.visualRolls = {}
	for _, v36_ in self.xmlFile:iterator("vehicle.hookLiftTrailer.visualRoll") do
		local v37_ = {
			["node"] = self.xmlFile:getValue(v36_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v37_.node ~= nil then
			v37_.radius = self.xmlFile:getValue(v36_ .. "#radius", 0.1)
			v37_.rotAxis = self.xmlFile:getValue(v36_ .. "#rotAxis", 1)
			v37_.direction = self.xmlFile:getValue(v36_ .. "#direction", 1)
			local v38_ = v8_.visualRolls
			table.insert(v38_, v37_)
		end
	end
	v8_.texts = {}
	v8_.texts.unloadContainer = g_i18n:convertText(self.xmlFile:getValue("vehicle.hookLiftTrailer.texts#unloadContainer", "$l10n_unload_container"), self.customEnvironment)
	v8_.texts.loadContainer = g_i18n:convertText(self.xmlFile:getValue("vehicle.hookLiftTrailer.texts#loadContainer", "$l10n_load_container"), self.customEnvironment)
	v8_.texts.unloadArm = g_i18n:convertText(self.xmlFile:getValue("vehicle.hookLiftTrailer.texts#unloadArm", "$l10n_unload_arm"), self.customEnvironment)
	v8_.texts.loadArm = g_i18n:convertText(self.xmlFile:getValue("vehicle.hookLiftTrailer.texts#loadArm", "$l10n_load_arm"), self.customEnvironment)
end

-- Local values: spec, foldableSpec
function HookLiftTrailer:onPostLoad(savegame)
	local v40_ = self.spec_hookLiftTrailer
	local v41_ = self.spec_foldable
	v41_.posDirectionText = v40_.texts.unloadArm
	v41_.negDirectionText = v40_.texts.loadArm
end

-- Local values: spec, animTime, minRx, minRy, minRz, maxRx, maxRy, maxRz, minTx, minTy, minTz, maxTx, maxTy, maxTz, minRx, minRy, minRz, maxRx, maxRy, maxRz, minTx, minTy, minTz, maxTx, maxTy, maxTz, state, attachableInfo, inputAttacherJoint, x, y, z, distance
function HookLiftTrailer:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v43_ = self.spec_hookLiftTrailer
	if v43_.attachedContainer ~= nil then
		local v44_ = self:getAnimationTime(v43_.refAnimation)
		v43_.attachedContainer.object.allowsDetaching = v44_ > 0.95
		if (self:getIsAnimationPlaying(v43_.refAnimation) or not v43_.attachedContainer.limitLocked) and not v43_.attachedContainer.implement.attachingIsInProgress then
			if v43_.jointLimits ~= nil then
				local v45_, v46_, v47_, v48_, v49_, v50_, v51_, v52_, v53_, v54_, v55_, v56_ = v43_.jointLimits:get(v44_)
				setJointRotationLimit(v43_.attachedContainer.jointIndex, 0, true, v45_, v48_)
				setJointRotationLimit(v43_.attachedContainer.jointIndex, 1, true, v46_, v49_)
				setJointRotationLimit(v43_.attachedContainer.jointIndex, 2, true, v47_, v50_)
				setJointTranslationLimit(v43_.attachedContainer.jointIndex, 0, true, v51_, v54_)
				setJointTranslationLimit(v43_.attachedContainer.jointIndex, 1, true, v52_, v55_)
				setJointTranslationLimit(v43_.attachedContainer.jointIndex, 2, true, v53_, v56_)
			end
			if v43_.additionalJointLimits ~= nil and v43_.attachedContainer.additionalJointIndex ~= nil then
				local v57_, v58_, v59_, v60_, v61_, v62_, v63_, v64_, v65_, v66_, v67_, v68_ = v43_.additionalJointLimits:get(v44_)
				setJointRotationLimit(v43_.attachedContainer.additionalJointIndex, 0, true, v57_, v60_)
				setJointRotationLimit(v43_.attachedContainer.additionalJointIndex, 1, true, v58_, v61_)
				setJointRotationLimit(v43_.attachedContainer.additionalJointIndex, 2, true, v59_, v62_)
				setJointTranslationLimit(v43_.attachedContainer.additionalJointIndex, 0, true, v63_, v66_)
				setJointTranslationLimit(v43_.attachedContainer.additionalJointIndex, 1, true, v64_, v67_)
				setJointTranslationLimit(v43_.attachedContainer.additionalJointIndex, 2, true, v65_, v68_)
			end
			if v44_ >= 0.99 then
				v43_.attachedContainer.limitLocked = true
			end
		end
	end
	if self.isClient and v43_.hookLock.referenceNode ~= nil then
		local v69_ = false
		local v70_ = self.spec_attacherJoints.attachableInfo
		if v70_.attachable ~= nil and v70_.attachableJointDescIndex ~= nil then
			local v71_ = v70_.attachable:getInputAttacherJointByJointDescIndex(v70_.attachableJointDescIndex)
			if v71_ ~= nil then
				local v72_, v73_, v74_ = localToLocal(v71_.node, v43_.hookLock.referenceNode, 0, 0, 0)
				v69_ = MathUtil.vector2Length(v73_, v74_) < v43_.hookLock.minDistance and math.abs(v72_) < v43_.hookLock.minDistanceSide and true or v69_
			end
		end
		if v69_ ~= v43_.hookLock.state then
			v43_.hookLock.state = v69_
			ObjectChangeUtil.setObjectChanges(v43_.hookLock.changeObjects, v69_, self, self.setMovingToolDirty)
		end
	end
end

-- Local values: spec, attacherJoint, jointDesc, foldableSpec
function HookLiftTrailer:onPostAttachImplement(attachable, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local v78_ = self.spec_hookLiftTrailer
	local v79_ = attachable:getActiveInputAttacherJoint()
	if v79_ ~= nil and v79_.jointType == AttacherJoints.JOINTTYPE_HOOKLIFT then
		local v80_ = self:getAttacherJointByJointDescIndex(jointDescIndex)
		v78_.attachedContainer = {}
		v78_.attachedContainer.jointIndex = v80_.jointIndex
		v78_.attachedContainer.jointDescIndex = jointDescIndex
		v78_.attachedContainer.implement = self:getImplementByObject(attachable)
		v78_.attachedContainer.object = attachable
		v78_.attachedContainer.limitLocked = false
		local v81_ = self.spec_foldable
		v81_.posDirectionText = v78_.texts.unloadContainer
		v81_.negDirectionText = v78_.texts.loadContainer
	end
	self:updateHookLiftContainerLockState()
end

-- Local values: spec, foldableSpec
function HookLiftTrailer:onPreDetachImplement(implement)
	local v84_ = self.spec_hookLiftTrailer
	if v84_.attachedContainer ~= nil and implement == v84_.attachedContainer.implement then
		v84_.attachedContainer.object:onHookLiftContainerLockChanged(false)
		local v85_ = self.spec_foldable
		v85_.posDirectionText = v84_.texts.unloadArm
		v85_.negDirectionText = v84_.texts.loadArm
		if v84_.attachedContainer.additionalJointIndex ~= nil then
			removeJoint(v84_.attachedContainer.additionalJointIndex)
			v84_.attachedContainer.additionalJointIndex = nil
		end
		if v84_.attachedContainer.jointNodeContainer ~= nil then
			delete(v84_.attachedContainer.jointNodeContainer)
			v84_.attachedContainer.jointNodeContainer = nil
		end
		v84_.attachedContainer = nil
	end
	self:updateHookLiftContainerLockState()
end

-- Local values: spec, spec_hookLiftContainer, startNode, endNode, _, y1, z1, _, y2, z2, dirY, dirZ, length, _, visualRoll, _, y3, z3, positionOnLine, y4, z4, distance, moved, rotOffset
function HookLiftTrailer:onUpdateAnimation(name)
	local v88_ = self.spec_hookLiftTrailer
	if name == v88_.refAnimation then
		self:updateHookLiftContainerLockState()
		if v88_.attachedContainer ~= nil then
			local v89_ = v88_.attachedContainer.object.spec_hookLiftContainer
			local v90_ = v89_.visualReferenceNodeStart
			local v91_ = v89_.visualReferenceNodeEnd
			if v90_ ~= nil and v91_ ~= nil then
				local _, v92_, v93_ = localToLocal(v90_, self.rootNode, 0, 0, 0)
				local _, v94_, v95_ = localToLocal(v91_, self.rootNode, 0, 0, 0)
				local v96_ = v94_ - v92_
				local v97_ = v95_ - v93_
				local v98_ = MathUtil.vector2Length(v96_, v97_)
				if v98_ > 0 then
					local v99_ = v96_ / v98_
					local v100_ = v97_ / v98_
					for _, v101_ in ipairs(v88_.visualRolls) do
						local _, v102_, v103_ = localToLocal(v101_.node, self.rootNode, 0, 0, 0)
						local v104_ = MathUtil.getProjectOnLineParameter(v102_, v103_, v92_, v93_, v99_, v100_)
						if v104_ >= 0 and v104_ <= v98_ then
							local v105_ = v92_ + v99_ * v104_
							local v106_ = v93_ + v100_ * v104_
							if MathUtil.vector2Length(v102_ - v105_, v103_ - v106_) <= v101_.radius + 0.025 then
								if v101_.lastPositionOnLine == nil then
									v101_.lastPositionOnLine = v104_
								end
								local v107_ = (v101_.lastPositionOnLine - v104_) / v101_.radius * v101_.direction
								if v101_.rotAxis == 1 then
									rotate(v101_.node, v107_, 0, 0)
								elseif v101_.rotAxis == 2 then
									rotate(v101_.node, 0, v107_, 0)
								elseif v101_.rotAxis == 3 then
									rotate(v101_.node, 0, 0, v107_)
								end
								v101_.lastPositionOnLine = v104_
							else
								v101_.lastPositionOnLine = nil
							end
						else
							v101_.lastPositionOnLine = nil
						end
					end
				end
			end
		end
	end
	if self.isServer and (name == v88_.unloadingAnimation and (v88_.attachedContainer ~= nil and v88_.attachedContainer.additionalJointIndex ~= nil)) then
		setJointFrame(v88_.attachedContainer.additionalJointIndex, 1, v88_.additionalJointNode)
	end
end

-- Local values: spec
function HookLiftTrailer:startTipping()
	local v109_ = self.spec_hookLiftTrailer
	self:playAnimation(v109_.unloadingAnimation, v109_.unloadingAnimationSpeed, self:getAnimationTime(v109_.unloadingAnimation), true)
end

-- Local values: spec
function HookLiftTrailer:stopTipping()
	local v111_ = self.spec_hookLiftTrailer
	self:playAnimation(v111_.unloadingAnimation, v111_.unloadingAnimationReverseSpeed, self:getAnimationTime(v111_.unloadingAnimation), true)
end

-- Local values: spec
function HookLiftTrailer:getIsTippingAllowed()
	return self:getAnimationTime(self.spec_hookLiftTrailer.refAnimation) == 0
end

-- Local values: spec
function HookLiftTrailer:getCanDetachContainer()
	return self:getAnimationTime(self.spec_hookLiftTrailer.refAnimation) == 1
end

-- Local values: spec, animTime, state, additionalJointState
function HookLiftTrailer:updateHookLiftContainerLockState()
	local v115_ = self.spec_hookLiftTrailer
	local v116_ = self:getAnimationTime(v115_.refAnimation)
	local v117_
	if v116_ < 0.001 then
		v117_ = v115_.attachedContainer ~= nil
	else
		v117_ = false
	end
	if v117_ ~= v115_.containerLockState then
		v115_.containerLockState = v117_
		ObjectChangeUtil.setObjectChanges(v115_.containerLockChangeObjects, v117_, self, self.setMovingToolDirty)
		if v115_.attachedContainer ~= nil then
			v115_.attachedContainer.object:onHookLiftContainerLockChanged(v117_)
		end
	end
	if self.isServer then
		local v118_
		if v116_ < v115_.additionalJointLockTime then
			v118_ = v115_.attachedContainer ~= nil
		else
			v118_ = false
		end
		if v118_ ~= v115_.additionalJointState then
			v115_.additionalJointState = v118_
			self:updateAdditionalHookLiftContainerJoint()
		end
	end
end

-- Local values: spec, attachedContainer, jointDesc, inputAttacherJoint, ox, oy, oz, jointNodeContainer, constr, animTime, minRx, minRy, minRz, maxRx, maxRy, maxRz, minTx, minTy, minTz, maxTx, maxTy, maxTz
function HookLiftTrailer:updateAdditionalHookLiftContainerJoint()
	local v120_ = self.spec_hookLiftTrailer
	if v120_.additionalJointNode == nil then
		return
	else
		local v121_ = v120_.attachedContainer
		if v120_.additionalJointState and (v121_ ~= nil and (self.isAddedToPhysics and v121_.object.isAddedToPhysics)) then
			local v122_ = self:getAttacherJointByJointDescIndex(v121_.jointDescIndex)
			local v123_ = v121_.object:getActiveInputAttacherJoint()
			local v124_, v125_, v126_
			if v120_.additionalJointOffset == nil then
				v124_, v125_, v126_ = localToLocal(v120_.additionalJointNode, v122_.jointTransform, 0, 0, 0)
			else
				v124_ = v120_.additionalJointOffset[1]
				v125_ = v120_.additionalJointOffset[2]
				v126_ = v120_.additionalJointOffset[3]
			end
			local v127_ = createTransformGroup("hookLiftJointContainer")
			link(v123_.node, v127_)
			setTranslation(v127_, v124_, v125_, v126_)
			setRotation(v127_, 0, 0, 0)
			local v128_ = JointConstructor.new()
			v128_:setActors(v123_.rootNode, v122_.rootNode)
			v128_:setJointTransforms(v127_, v120_.additionalJointNode)
			local v129_ = self:getAnimationTime(v120_.refAnimation)
			local v130_, v131_, v132_, v133_, v134_, v135_, v136_, v137_, v138_, v139_, v140_, v141_ = v120_.additionalJointLimits:get(v129_)
			v128_:setRotationLimit(0, v130_, v133_)
			v128_:setRotationLimit(1, v131_, v134_)
			v128_:setRotationLimit(2, v132_, v135_)
			v128_:setTranslationLimit(0, true, v136_, v139_)
			v128_:setTranslationLimit(1, true, v137_, v140_)
			v128_:setTranslationLimit(2, true, v138_, v141_)
			v128_:setEnableCollision(not v120_.additionalJointDisableCollision)
			v121_.additionalJointIndex = v128_:finalize()
			v121_.jointNodeContainer = v127_
		elseif v121_ ~= nil then
			if v121_.additionalJointIndex ~= nil then
				removeJoint(v120_.attachedContainer.additionalJointIndex)
				v121_.additionalJointIndex = nil
			end
			if v121_.jointNodeContainer ~= nil then
				delete(v120_.attachedContainer.jointNodeContainer)
				v121_.jointNodeContainer = nil
			end
		end
	end
end

-- Local values: spec, jointDesc
function HookLiftTrailer:setHookLiftContainerPhysicsState(container, state)
	local v145_ = self.spec_hookLiftTrailer
	if v145_.attachedContainer ~= nil and v145_.attachedContainer.object == container then
		if state then
			local v146_ = self:getAttacherJointByJointDescIndex(v145_.attachedContainer.jointDescIndex)
			if v146_.jointIndex ~= 0 then
				v145_.attachedContainer.jointIndex = v146_.jointIndex
				v145_.attachedContainer.limitLocked = false
			end
		else
			v145_.attachedContainer.jointIndex = 0
		end
		self:updateAdditionalHookLiftContainerJoint()
	end
end

-- Local values: spec
function HookLiftTrailer:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	local v149_ = self.spec_hookLiftTrailer
	if v149_.attachedContainer ~= nil then
		self:setHookLiftContainerPhysicsState(v149_.attachedContainer.object, true)
	end
	return true
end

-- Local values: spec
function HookLiftTrailer:removeFromPhysics(superFunc)
	local v152_ = self.spec_hookLiftTrailer
	if v152_.attachedContainer ~= nil then
		self:setHookLiftContainerPhysicsState(v152_.attachedContainer.object, false)
	end
	return superFunc(self) and true or false
end

-- Local values: spec
function HookLiftTrailer:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	if self:getAnimationTime(self.spec_hookLiftTrailer.unloadingAnimation) > 0 then
		return false
	else
		return superFunc(self, direction, onAiTurnOn)
	end
end

function HookLiftTrailer:isDetachAllowed(superFunc)
	if self:getAnimationTime(self.spec_hookLiftTrailer.unloadingAnimation) == 0 then
		return superFunc(self)
	else
		return false, nil
	end
end

-- Local values: spec, doConsume
function HookLiftTrailer:getDoConsumePtoPower(superFunc)
	local v161_ = self.spec_hookLiftTrailer
	return superFunc(self) or (self:getIsAnimationPlaying(v161_.refAnimation) or self:getIsAnimationPlaying(v161_.unloadingAnimation))
end

-- Local values: spec, rpm
function HookLiftTrailer:getPtoRpm(superFunc)
	local v164_ = self.spec_hookLiftTrailer
	local v165_ = superFunc(self)
	if self:getIsAnimationPlaying(v164_.refAnimation) or self:getIsAnimationPlaying(v164_.unloadingAnimation) then
		return self.spec_powerConsumer.ptoRpm
	else
		return v165_
	end
end
