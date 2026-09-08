WoodCrusher = {}
WoodCrusher.DAMAGED_YIELD_DECREASE = 0.4

function WoodCrusher.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(FillUnit, specializations)
	end
	return v2_
end
function WoodCrusher.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("WoodCrusher")
	WoodCrusher.registerWoodCrusherXMLPaths(v3_, "vehicle.woodCrusher")
	v3_:register(XMLValueType.BOOL, "vehicle.woodCrusher#moveColDisableCollisionPairs", "Activate collision between move collisions and components", true)
	v3_:register(XMLValueType.INT, "vehicle.woodCrusher#fillUnitIndex", "Fill unit index", 1)
	v3_:setXMLSpecializationType()
end

function WoodCrusher.registerWoodCrusherXMLPaths(schema, key)
	schema:register(XMLValueType.NODE_INDEX, key .. "#cutNode", "Cut node")
	schema:register(XMLValueType.NODE_INDEX, key .. "#mainDrumRefNode", "Main drum reference node")
	schema:register(XMLValueType.FLOAT, key .. "#mainDrumRefNodeMaxY", "Max tree size the main drum can handle")
	schema:register(XMLValueType.NODE_INDEX, key .. ".moveTriggers.trigger(?)#node", "Move trigger")
	schema:register(XMLValueType.NODE_INDEX, key .. ".moveCollisions.collision(?)#node", "Move collision")
	schema:register(XMLValueType.FLOAT, key .. "#moveVelocityZ", "Move velocity Z (m/s)", 0.8)
	schema:register(XMLValueType.FLOAT, key .. "#moveMaxForce", "Move max. force (kN)", 7)
	schema:register(XMLValueType.NODE_INDEX, key .. "#shapeSizeDetectionNode", "At this node the tree shape size will be detected to set the #mainDrumRefNode")
	schema:register(XMLValueType.FLOAT, key .. "#cutSizeY", "Cut size Y", 1)
	schema:register(XMLValueType.FLOAT, key .. "#cutSizeZ", "Cut size Z", 1)
	schema:register(XMLValueType.NODE_INDEX, key .. ".downForceNodes.downForceNode(?)#node", "Down force node")
	schema:register(XMLValueType.NODE_INDEX, key .. ".downForceNodes.downForceNode(?)#trigger", "Additional trigger (If defined the tree needs to be present in the mover trigger and inside this trigger)")
	schema:register(XMLValueType.FLOAT, key .. ".downForceNodes.downForceNode(?)#force", "Down force (kN)", 2)
	schema:register(XMLValueType.FLOAT, key .. ".downForceNodes.downForceNode(?)#sizeY", "Size Y in which the down force node detects trees", "Cut size Y")
	schema:register(XMLValueType.FLOAT, key .. ".downForceNodes.downForceNode(?)#sizeZ", "Size Z in which the down force node detects trees", "Cut size Z")
	schema:register(XMLValueType.BOOL, key .. "#automaticallyTurnOn", "Automatically turned on", false)
	EffectManager.registerEffectXMLPaths(schema, key .. ".crushEffects")
	AnimationManager.registerAnimationNodesXMLPaths(schema, key .. ".animationNodes")
	SoundManager.registerSampleXMLPaths(schema, key .. ".sounds", "start")
	SoundManager.registerSampleXMLPaths(schema, key .. ".sounds", "stop")
	SoundManager.registerSampleXMLPaths(schema, key .. ".sounds", "work")
	SoundManager.registerSampleXMLPaths(schema, key .. ".sounds", "idle")
end

function WoodCrusher.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "onCrushedSplitShape", WoodCrusher.onCrushedSplitShape)
end

function WoodCrusher.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", WoodCrusher.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", WoodCrusher.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", WoodCrusher.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", WoodCrusher.getConsumingLoad)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresPower", WoodCrusher.getRequiresPower)
end

function WoodCrusher.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WoodCrusher)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", WoodCrusher)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", WoodCrusher)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", WoodCrusher)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", WoodCrusher)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WoodCrusher)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", WoodCrusher)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", WoodCrusher)
end

-- Local values: spec, moveColDisableCollisionPairs, _, component, _, moveColNodes
function WoodCrusher:onLoad(savegame)
	local v10_ = self.spec_woodCrusher
	WoodCrusher.loadWoodCrusher(self, v10_, self.xmlFile, self.components, self.i3dMappings)
	if self.xmlFile:getValue("vehicle.woodCrusher#moveColDisableCollisionPairs", true) then
		for _, v11_ in pairs(self.components) do
			for _, v12_ in pairs(v10_.moveColNodes) do
				setPairCollision(v11_.node, v12_.node, false)
			end
		end
	end
	v10_.fillUnitIndex = self.xmlFile:getValue("vehicle.woodCrusher#fillUnitIndex", 1)
end

function WoodCrusher:onDelete()
	WoodCrusher.deleteWoodCrusher(self, self.spec_woodCrusher)
end

-- Local values: spec
function WoodCrusher:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v17_ = self.spec_woodCrusher
		if streamReadBool(streamId) then
			v17_.crushingTime = 1000
			return
		end
		v17_.crushingTime = 0
	end
end

-- Local values: spec
function WoodCrusher:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v21_ = self.spec_woodCrusher
		streamWriteBool(streamId, v21_.crushingTime > 0)
	end
end

function WoodCrusher:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	WoodCrusher.updateWoodCrusher(self, self.spec_woodCrusher, dt, self:getIsTurnedOn())
end

-- Local values: spec, rootAttacherVehicle
function WoodCrusher:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	WoodCrusher.updateTickWoodCrusher(self, self.spec_woodCrusher, dt, self:getIsTurnedOn())
	local v26_ = self.spec_woodCrusher
	if self.isServer and (g_currentMission.missionInfo.automaticMotorStartEnabled and (v26_.turnOnAutomatically and self.setIsTurnedOn ~= nil)) then
		if next(v26_.moveTriggerNodes) ~= nil then
			if self.getIsMotorStarted == nil then
				if self.attacherVehicle ~= nil and (self.attacherVehicle.getIsMotorStarted ~= nil and not self.attacherVehicle:getIsMotorStarted()) then
					self.attacherVehicle:startMotor()
				end
			elseif not self:getIsMotorStarted() then
				self:startMotor()
			end
			if (self.getIsControlled == nil or not self:getIsControlled()) and (not self:getIsTurnedOn() and self:getCanBeTurnedOn()) then
				self:setIsTurnedOn(true)
			end
			v26_.turnOffTimer = 3000
			return
		end
		if self:getIsTurnedOn() then
			if v26_.turnOffTimer == nil then
				v26_.turnOffTimer = 3000
			end
			v26_.turnOffTimer = v26_.turnOffTimer - dt
			if v26_.turnOffTimer < 0 and not self:getRootVehicle().isControlled then
				if self.getIsMotorStarted ~= nil and self:getIsMotorStarted() then
					self:stopMotor()
				end
				self:setIsTurnedOn(false)
			end
		end
	end
end

function WoodCrusher:onTurnedOn()
	WoodCrusher.turnOnWoodCrusher(self, self.spec_woodCrusher)
end

function WoodCrusher:onTurnedOff()
	WoodCrusher.turnOffWoodCrusher(self, self.spec_woodCrusher)
end

-- Local values: spec
function WoodCrusher:getCanBeTurnedOn(superFunc)
	if self.spec_woodCrusher.turnOnAutomatically then
		return false
	else
		return superFunc(self)
	end
end

-- Local values: value, count, spec
function WoodCrusher:getConsumingLoad(superFunc)
	local v33_, v34_ = superFunc(self)
	if self.spec_woodCrusher.crushingTime > 0 then
		v33_ = v33_ + 1
	end
	return v33_, v34_ + 1
end

function WoodCrusher:getRequiresPower(superFunc)
	return self:getIsTurnedOn() and true or superFunc(self)
end

-- Local values: multiplier, spec
function WoodCrusher:getDirtMultiplier(superFunc)
	local v39_ = superFunc(self)
	if self.spec_woodCrusher.crushingTime > 0 then
		v39_ = v39_ + self:getWorkDirtMultiplier()
	end
	return v39_
end

-- Local values: multiplier, spec
function WoodCrusher:getWearMultiplier(superFunc)
	local v42_ = superFunc(self)
	if self.spec_woodCrusher.crushingTime > 0 then
		v42_ = v42_ + self:getWorkWearMultiplier()
	end
	return v42_
end

-- Local values: spec, damage
function WoodCrusher:onCrushedSplitShape(splitType, volume)
	local v46_ = self.spec_woodCrusher
	local v47_ = self:getVehicleDamage()
	if v47_ > 0 then
		volume = volume * (1 - v47_ * WoodCrusher.DAMAGED_YIELD_DECREASE)
	end
	self:addFillUnitFillLevel(self:getOwnerFarmId(), v46_.fillUnitIndex, volume * splitType.volumeToLiter * splitType.woodChipsPerLiter, FillType.WOODCHIPS, ToolType.UNDEFINED)
end

-- Local values: xmlRoot, baseKey, mainDrumRefNodeParent, i, key, node, key, moveColNode, _, node
function WoodCrusher:loadWoodCrusher(woodCrusher, xmlFile, rootNode, i3dMappings)
	woodCrusher.vehicle = self
	woodCrusher.woodCrusherSplitShapeCallback = WoodCrusher.woodCrusherSplitShapeCallback
	woodCrusher.woodCrusherMoveTriggerCallback = WoodCrusher.woodCrusherMoveTriggerCallback
	woodCrusher.woodCrusherDownForceTriggerCallback = WoodCrusher.woodCrusherDownForceTriggerCallback
	local v53_ = xmlFile:getRootName()
	local v54_ = v53_ .. ".woodCrusher"
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v53_ .. ".woodCrusher.moveTrigger(0)#index", v53_ .. ".woodCrusher.moveTriggers.trigger#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v53_ .. ".woodCrusher.moveCollision(0)#index", v53_ .. ".woodCrusher.moveCollisions.collision#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v53_ .. ".woodCrusher.emitterShape(0)", v53_ .. ".woodCrusher.crushEffects with effectClass \'ParticleEffect\'")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v53_ .. ".woodCrusherStartSound", v53_ .. ".woodCrusher.sounds.start")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v53_ .. ".woodCrusherIdleSound", v53_ .. ".woodCrusher.sounds.idle")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v53_ .. ".woodCrusherWorkSound", v53_ .. ".woodCrusher.sounds.work")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v53_ .. ".woodCrusherStopSound", v53_ .. ".woodCrusher.sounds.stop")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v53_ .. ".turnedOnRotationNodes.turnedOnRotationNode#type", v53_ .. ".woodCrusher.animationNodes.animationNode", "woodCrusher")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v53_ .. ".turnedOnScrollers.turnedOnScroller", v53_ .. ".woodCrusher.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v54_ .. "#downForceNode", v54_ .. ".downForceNodes.downForceNode#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v54_ .. "#downForce", v54_ .. ".downForceNodes.downForceNode#force")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v54_ .. "#downForceSizeY", v54_ .. ".downForceNodes.downForceNode#sizeY")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, v54_ .. "#downForceSizeZ", v54_ .. ".downForceNodes.downForceNode#sizeZ")
	woodCrusher.cutNode = xmlFile:getValue(v54_ .. "#cutNode", nil, rootNode, i3dMappings)
	woodCrusher.mainDrumRefNode = xmlFile:getValue(v54_ .. "#mainDrumRefNode", nil, rootNode, i3dMappings)
	woodCrusher.mainDrumRefNodeMaxY = xmlFile:getValue(v54_ .. "#mainDrumRefNodeMaxY", math.huge)
	if woodCrusher.mainDrumRefNode ~= nil then
		local v55_ = createTransformGroup("mainDrumRefNodeParent")
		link(getParent(woodCrusher.mainDrumRefNode), v55_, getChildIndex(woodCrusher.mainDrumRefNode))
		setTranslation(v55_, getTranslation(woodCrusher.mainDrumRefNode))
		setRotation(v55_, getRotation(woodCrusher.mainDrumRefNode))
		link(v55_, woodCrusher.mainDrumRefNode)
		setTranslation(woodCrusher.mainDrumRefNode, 0, 0, 0)
		setRotation(woodCrusher.mainDrumRefNode, 0, 0, 0)
	end
	woodCrusher.moveTriggers = {}
	local v56_ = 0
	while true do
		local v57_ = string.format("%s.moveTriggers.trigger(%d)", v54_, v56_)
		if not xmlFile:hasProperty(v57_) then
			break
		end
		local v58_ = xmlFile:getValue(v57_ .. "#node", nil, rootNode, i3dMappings)
		if v58_ ~= nil then
			if not CollisionFlag.getHasMaskFlagSet(v58_, CollisionFlag.TREE) then
				Logging.xmlWarning(self.xmlFile, "Missing collision filter mask %s. Please add this bit to move trigger node \'%s\' in \'%s\'", CollisionFlag.getBitAndName(CollisionFlag.TREE), getName(v58_), v57_)
				break
			end
			local v59_ = woodCrusher.moveTriggers
			table.insert(v59_, v58_)
		end
		v56_ = v56_ + 1
	end
	woodCrusher.moveColNodes = {}
	local v60_ = 0
	while true do
		local v61_ = string.format("%s.moveCollisions.collision(%d)", v54_, v60_)
		if not xmlFile:hasProperty(v61_) then
			break
		end
		local v62_ = {
			["node"] = xmlFile:getValue(v61_ .. "#node", nil, rootNode, i3dMappings)
		}
		if v62_.node ~= nil then
			local v63_, v64_, v65_ = getTranslation(v62_.node)
			v62_.transX = v63_
			v62_.transY = v64_
			v62_.transZ = v65_
			local v66_ = woodCrusher.moveColNodes
			table.insert(v66_, v62_)
		end
		v60_ = v60_ + 1
	end
	woodCrusher.moveVelocityZ = xmlFile:getValue(v54_ .. "#moveVelocityZ", 0.8)
	woodCrusher.moveMaxForce = xmlFile:getValue(v54_ .. "#moveMaxForce", 7)
	woodCrusher.shapeSizeDetectionNode = xmlFile:getValue(v54_ .. "#shapeSizeDetectionNode", nil, rootNode, i3dMappings)
	woodCrusher.cutSizeY = xmlFile:getValue(v54_ .. "#cutSizeY", 1)
	woodCrusher.cutSizeZ = xmlFile:getValue(v54_ .. "#cutSizeZ", 1)
	woodCrusher.downForceNodes = {}
	woodCrusher.downForceTriggers = {}
	xmlFile:iterate(v54_ .. ".downForceNodes.downForceNode", function(_, p67_)
		-- upvalues: (copy) xmlFile, (copy) rootNode, (copy) i3dMappings, (copy) woodCrusher, (copy) self
		local v68_ = {
			["node"] = xmlFile:getValue(p67_ .. "#node", nil, rootNode, i3dMappings)
		}
		if v68_.node ~= nil then
			v68_.force = xmlFile:getValue(p67_ .. "#force", 2)
			v68_.trigger = xmlFile:getValue(p67_ .. "#trigger", nil, rootNode, i3dMappings)
			v68_.sizeY = xmlFile:getValue(p67_ .. "#sizeY", woodCrusher.cutSizeY)
			v68_.sizeZ = xmlFile:getValue(p67_ .. "#sizeZ", woodCrusher.cutSizeZ)
			v68_.woodCrusher = woodCrusher
			v68_.triggerNodes = {}
			if v68_.trigger ~= nil and (woodCrusher.downForceTriggers[v68_.trigger] == nil and self.isServer) then
				woodCrusher.downForceTriggers[v68_.trigger] = true
				addTrigger(v68_.trigger, "woodCrusherDownForceTriggerCallback", woodCrusher)
			end
			local v69_ = woodCrusher.downForceNodes
			table.insert(v69_, v68_)
		end
	end)
	woodCrusher.moveTriggerNodes = {}
	if self.isServer and woodCrusher.moveTriggers ~= nil then
		for _, v70_ in pairs(woodCrusher.moveTriggers) do
			addTrigger(v70_, "woodCrusherMoveTriggerCallback", woodCrusher)
		end
	end
	woodCrusher.crushNodes = {}
	woodCrusher.crushingTime = 0
	woodCrusher.turnOnAutomatically = xmlFile:getValue(v54_ .. "#automaticallyTurnOn", false)
	if self.isClient then
		woodCrusher.crushEffects = g_effectManager:loadEffect(xmlFile, v54_ .. ".crushEffects", rootNode, self, i3dMappings)
		woodCrusher.animationNodes = g_animationManager:loadAnimations(xmlFile, v54_ .. ".animationNodes", rootNode, self, i3dMappings)
		woodCrusher.isWorkSamplePlaying = false
		woodCrusher.samples = {}
		woodCrusher.samples.start = g_soundManager:loadSampleFromXML(xmlFile, v54_ .. ".sounds", "start", self.baseDirectory, rootNode, 1, AudioGroup.VEHICLE, i3dMappings, self)
		woodCrusher.samples.stop = g_soundManager:loadSampleFromXML(xmlFile, v54_ .. ".sounds", "stop", self.baseDirectory, rootNode, 1, AudioGroup.VEHICLE, i3dMappings, self)
		woodCrusher.samples.work = g_soundManager:loadSampleFromXML(xmlFile, v54_ .. ".sounds", "work", self.baseDirectory, rootNode, 0, AudioGroup.VEHICLE, i3dMappings, self)
		woodCrusher.samples.idle = g_soundManager:loadSampleFromXML(xmlFile, v54_ .. ".sounds", "idle", self.baseDirectory, rootNode, 0, AudioGroup.VEHICLE, i3dMappings, self)
	end
end

-- Local values: _, node, trigger, _
function WoodCrusher:deleteWoodCrusher(woodCrusher)
	if woodCrusher.moveTriggers ~= nil then
		for _, v72_ in pairs(woodCrusher.moveTriggers) do
			removeTrigger(v72_)
		end
	end
	if woodCrusher.downForceTriggers ~= nil then
		for v73_, _ in pairs(woodCrusher.downForceTriggers) do
			removeTrigger(v73_)
		end
	end
	g_effectManager:deleteEffects(woodCrusher.crushEffects)
	g_soundManager:deleteSamples(woodCrusher.samples)
	g_animationManager:deleteAnimations(woodCrusher.animationNodes)
end

-- Local values: node, maxTreeSizeY, id, i, downForceNode, x, y, z, nx, ny, nz, yx, yy, yz, minY, maxY, minZ, maxZ, cx, cy, cz, downX, downY, downZ, x, y, z, nx, ny, nz, yx, yy, yz, minY, maxY, _, _, x, y, z, ty
function WoodCrusher:updateWoodCrusher(woodCrusher, dt, isTurnedOn)
	if isTurnedOn and self.isServer then
		for v78_ in pairs(woodCrusher.crushNodes) do
			WoodCrusher.crushSplitShape(self, woodCrusher, v78_)
			woodCrusher.crushNodes[v78_] = nil
			woodCrusher.moveTriggerNodes[v78_] = nil
		end
		local v79_ = 0
		for v80_ in pairs(woodCrusher.moveTriggerNodes) do
			if entityExists(v80_) then
				for v81_ = 1, #woodCrusher.downForceNodes do
					local v82_ = woodCrusher.downForceNodes[v81_]
					if v82_.triggerNodes[v80_] ~= nil or v82_.trigger == nil then
						local v83_, v84_, v85_ = getWorldTranslation(v82_.node)
						local v86_, v87_, v88_ = localDirectionToWorld(v82_.node, 1, 0, 0)
						local v89_, v90_, v91_ = localDirectionToWorld(v82_.node, 0, 1, 0)
						local v92_, v93_, v94_, v95_ = testSplitShape(v80_, v83_, v84_, v85_, v86_, v87_, v88_, v89_, v90_, v91_, v82_.sizeY, v82_.sizeZ)
						if v92_ ~= nil then
							local v96_, v97_, v98_ = localToWorld(v82_.node, 0, (v92_ + v93_) * 0.5, (v94_ + v95_) * 0.5)
							local v99_, v100_, v101_ = localDirectionToWorld(v82_.node, 0, -v82_.force, 0)
							addForce(v80_, v99_, v100_, v101_, v96_, v97_, v98_, false)
						end
					end
				end
				if woodCrusher.shapeSizeDetectionNode ~= nil then
					local v102_, v103_, v104_ = getWorldTranslation(woodCrusher.shapeSizeDetectionNode)
					local v105_, v106_, v107_ = localDirectionToWorld(woodCrusher.shapeSizeDetectionNode, 1, 0, 0)
					local v108_, v109_, v110_ = localDirectionToWorld(woodCrusher.shapeSizeDetectionNode, 0, 1, 0)
					local v111_, v112_, _, _ = testSplitShape(v80_, v102_, v103_, v104_, v105_, v106_, v107_, v108_, v109_, v110_, woodCrusher.cutSizeY, woodCrusher.cutSizeZ)
					if v111_ ~= nil and woodCrusher.mainDrumRefNode ~= nil then
						v79_ = math.max(v79_, v112_)
					end
				end
			else
				woodCrusher.moveTriggerNodes[v80_] = nil
			end
		end
		if woodCrusher.mainDrumRefNode ~= nil then
			local v113_, v114_, v115_ = getTranslation(woodCrusher.mainDrumRefNode)
			local v116_ = woodCrusher.mainDrumRefNodeMaxY
			local v117_ = math.min(v79_, v116_)
			local v118_
			if v114_ < v117_ then
				local v119_ = v114_ + 0.0003 * dt
				v118_ = math.min(v119_, v117_)
			else
				local v120_ = v114_ - 0.0003 * dt
				v118_ = math.max(v120_, v117_)
			end
			setTranslation(woodCrusher.mainDrumRefNode, v113_, v118_, v115_)
		end
		if next(woodCrusher.moveTriggerNodes) ~= nil or woodCrusher.crushingTime > 0 then
			self:raiseActive()
		end
	end
end

-- Local values: x, y, z, nx, ny, nz, yx, yy, yz, id, lenBelow, lenAbove, minY, _, moveColNode, isCrushing
function WoodCrusher:updateTickWoodCrusher(woodCrusher, dt, isTurnedOn)
	if isTurnedOn and self.isServer then
		if woodCrusher.cutNode ~= nil and next(woodCrusher.moveTriggerNodes) ~= nil then
			local v125_, v126_, v127_ = getWorldTranslation(woodCrusher.cutNode)
			local v128_, v129_, v130_ = localDirectionToWorld(woodCrusher.cutNode, 1, 0, 0)
			local v131_, v132_, v133_ = localDirectionToWorld(woodCrusher.cutNode, 0, 1, 0)
			for v134_ in pairs(woodCrusher.moveTriggerNodes) do
				if entityExists(v134_) then
					local v135_, v136_ = getSplitShapePlaneExtents(v134_, v125_, v126_, v127_, v128_, v129_, v130_)
					if v136_ ~= nil and v135_ ~= nil then
						if v135_ <= 0.4 then
							woodCrusher.moveTriggerNodes[v134_] = nil
							WoodCrusher.crushSplitShape(self, woodCrusher, v134_)
						elseif v136_ >= 0.2 then
							self.shapeBeingCut = v134_
							local v137_ = splitShape(v134_, v125_, v126_, v127_, v128_, v129_, v130_, v131_, v132_, v133_, woodCrusher.cutSizeY, woodCrusher.cutSizeZ, "woodCrusherSplitShapeCallback", woodCrusher)
							g_treePlantManager:removingSplitShape(v134_)
							if v137_ ~= nil then
								woodCrusher.moveTriggerNodes[v134_] = nil
							end
						end
					end
				else
					woodCrusher.moveTriggerNodes[v134_] = nil
				end
			end
		end
		if self.isServer and woodCrusher.moveColNodes ~= nil then
			for _, v138_ in pairs(woodCrusher.moveColNodes) do
				setTranslation(v138_.node, v138_.transX, v138_.transY + math.random() * 0.005, v138_.transZ)
			end
		end
	end
	if woodCrusher.crushingTime > 0 then
		local v139_ = woodCrusher.crushingTime - dt
		woodCrusher.crushingTime = math.max(v139_, 0)
	end
	local v140_ = woodCrusher.crushingTime > 0
	if self.isClient then
		if v140_ then
			g_effectManager:setEffectTypeInfo(woodCrusher.crushEffects, FillType.WOODCHIPS)
			g_effectManager:startEffects(woodCrusher.crushEffects)
		else
			g_effectManager:stopEffects(woodCrusher.crushEffects)
		end
		if isTurnedOn and v140_ then
			if not woodCrusher.isWorkSamplePlaying then
				g_soundManager:playSample(woodCrusher.samples.work)
				woodCrusher.isWorkSamplePlaying = true
				return
			end
		elseif woodCrusher.isWorkSamplePlaying then
			g_soundManager:stopSample(woodCrusher.samples.work)
			woodCrusher.isWorkSamplePlaying = false
		end
	end
end

-- Local values: _, moveColNode
function WoodCrusher:turnOnWoodCrusher(woodCrusher)
	if self.isServer and woodCrusher.moveColNodes ~= nil then
		for _, v143_ in pairs(woodCrusher.moveColNodes) do
			setFrictionVelocity(v143_.node, woodCrusher.moveVelocityZ)
		end
	end
	if self.isClient then
		g_soundManager:stopSamples(woodCrusher.samples)
		woodCrusher.isWorkSamplePlaying = false
		g_soundManager:playSample(woodCrusher.samples.start)
		g_soundManager:playSample(woodCrusher.samples.idle, 0, woodCrusher.samples.start)
		if self.isClient then
			g_animationManager:startAnimations(woodCrusher.animationNodes)
		end
	end
end

-- Local values: node, _, moveColNode
function WoodCrusher:turnOffWoodCrusher(woodCrusher)
	if self.isServer then
		for v146_ in pairs(woodCrusher.crushNodes) do
			WoodCrusher.crushSplitShape(self, woodCrusher, v146_)
			woodCrusher.crushNodes[v146_] = nil
		end
		if woodCrusher.moveColNodes ~= nil then
			for _, v147_ in pairs(woodCrusher.moveColNodes) do
				setFrictionVelocity(v147_.node, 0)
			end
		end
	end
	if self.isClient then
		g_effectManager:stopEffects(woodCrusher.crushEffects)
		g_soundManager:stopSamples(woodCrusher.samples)
		g_soundManager:playSample(woodCrusher.samples.stop)
		woodCrusher.isWorkSamplePlaying = false
		if self.isClient then
			g_animationManager:stopAnimations(woodCrusher.animationNodes)
		end
	end
end

-- Local values: splitType, volume
function WoodCrusher:crushSplitShape(woodCrusher, shape)
	local v151_ = g_splitShapeManager:getSplitTypeByIndex(getSplitType(shape))
	if v151_ ~= nil and v151_.woodChipsPerLiter > 0 then
		local v152_ = getVolume(shape)
		delete(shape)
		woodCrusher.crushingTime = 1000
		self:onCrushedSplitShape(v151_, v152_)
	end
end

function WoodCrusher:woodCrusherSplitShapeCallback(shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	if not isBelow then
		self.crushNodes[shape] = shape
		g_treePlantManager:addingSplitShape(shape, self.shapeBeingCut)
	end
end

-- Local values: vehicle, splitType, c
function WoodCrusher:woodCrusherMoveTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if g_currentMission.nodeToObject[otherActorId] == nil and getRigidBodyType(otherActorId) == RigidBodyType.DYNAMIC then
		local v160_ = g_splitShapeManager:getSplitTypeByIndex(getSplitType(otherActorId))
		if v160_ ~= nil and v160_.woodChipsPerLiter > 0 then
			if onEnter then
				self.moveTriggerNodes[otherActorId] = Utils.getNoNil(self.moveTriggerNodes[otherActorId], 0) + 1
				self.vehicle:raiseActive()
				return
			end
			if onLeave then
				local v161_ = self.moveTriggerNodes[otherActorId]
				if v161_ ~= nil then
					local v162_ = v161_ - 1
					if v162_ == 0 then
						self.moveTriggerNodes[otherActorId] = nil
						return
					end
					self.moveTriggerNodes[otherActorId] = v162_
				end
			end
		end
	end
end

-- Local values: vehicle, splitType, i, downForceNode, c
function WoodCrusher:woodCrusherDownForceTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if g_currentMission.nodeToObject[otherActorId] == nil and getRigidBodyType(otherActorId) == RigidBodyType.DYNAMIC then
		local v168_ = g_splitShapeManager:getSplitTypeByIndex(getSplitType(otherActorId))
		if v168_ ~= nil and v168_.woodChipsPerLiter > 0 then
			for v169_ = 1, #self.downForceNodes do
				local v170_ = self.downForceNodes[v169_]
				if v170_.trigger == triggerId then
					if onEnter then
						v170_.triggerNodes[otherActorId] = Utils.getNoNil(v170_.triggerNodes[otherActorId], 0) + 1
						self.vehicle:raiseActive()
					elseif onLeave then
						local v171_ = v170_.triggerNodes[otherActorId]
						if v171_ ~= nil then
							local v172_ = v171_ - 1
							if v172_ == 0 then
								v170_.triggerNodes[otherActorId] = nil
							else
								v170_.triggerNodes[otherActorId] = v172_
							end
						end
					end
				end
			end
		end
	end
end
