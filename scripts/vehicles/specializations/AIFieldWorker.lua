source("dataS/scripts/vehicles/specializations/events/AIVehicleIsBlockedEvent.lua")
source("dataS/scripts/vehicles/specializations/events/AIFieldWorkerStateEvent.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategy.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyBaler.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyCombine.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyConveyor.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyStonePicker.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyFieldCourse.lua")
AIFieldWorker = {}
AIFieldWorker.TRAFFIC_COLLISION_BOX_FILENAME = "data/shared/ai/trafficCollision.i3d"
AIFieldWorker.TRAFFIC_COLLISION = 0
AIFieldWorker.registeredDriveStrategies = {}

function AIFieldWorker.registerDriveStrategy(func, class, prio)
	local v4_ = AIFieldWorker.registeredDriveStrategies
	local v5_ = {
		["func"] = func,
		["class"] = class,
		["prio"] = prio or #AIFieldWorker.registeredDriveStrategies + 1
	}
	table.insert(v4_, v5_)
end
AIFieldWorker.registerDriveStrategy(function()
	return true
end, AIDriveStrategyFieldCourse, 1000)
function AIFieldWorker.deleteCollisionBox()
	if AIFieldWorker.TRAFFIC_COLLISION ~= 0 then
		delete(AIFieldWorker.TRAFFIC_COLLISION)
		AIFieldWorker.TRAFFIC_COLLISION = 0
	end
end

function AIFieldWorker.prerequisitesPresent(specializations)
	local v7_ = SpecializationUtil.hasSpecialization(AIJobVehicle, specializations)
	if v7_ then
		v7_ = SpecializationUtil.hasSpecialization(Drivable, specializations)
	end
	return v7_
end
function AIFieldWorker.initSpecialization()
	local v8_ = Vehicle.xmlSchema
	v8_:setXMLSpecializationType("AIFieldWorker")
	v8_:register(XMLValueType.FLOAT, "vehicle.ai.didNotMoveTimeout#value", "Did not move time out time", 5000)
	v8_:register(XMLValueType.BOOL, "vehicle.ai.didNotMoveTimeout#deactivated", "Did not move time out deactivated", false)
	v8_:setXMLSpecializationType()
	g_i3DManager:loadI3DFileAsync(AIFieldWorker.TRAFFIC_COLLISION_BOX_FILENAME, true, false, AIFieldWorker.onTrafficCollisionLoaded, nil, nil)
end
function AIFieldWorker.terminateSpecialization()
	AIFieldWorker.deleteCollisionBox()
end
function AIFieldWorker.postInitSpecialization()
	table.sort(AIFieldWorker.registeredDriveStrategies, function(p9_, p10_)
		return p9_.prio < p10_.prio
	end)
	local v11_ = Vehicle.xmlSchemaSavegame
	v11_:register(XMLValueType.BOOL, "vehicles.vehicle(?).aiFieldWorker#isActive", "AI worker is currently active")
	for _, v12_ in ipairs(AIFieldWorker.registeredDriveStrategies) do
		if v12_.class.registerSavegameXMLPaths ~= nil then
			v12_.class.registerSavegameXMLPaths(v11_, "vehicles.vehicle(?).aiFieldWorker")
		end
	end
end

function AIFieldWorker.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerStart")
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerActive")
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerEnd")
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerPrepareForWork")
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerStartTurn")
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerTurnProgress")
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerEndTurn")
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerSideOffsetChanged")
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerBlock")
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerContinue")
end

function AIFieldWorker.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getIsFieldWorkActive", AIFieldWorker.getIsFieldWorkActive)
	SpecializationUtil.registerFunction(vehicleType, "getAICollisionTriggers", AIFieldWorker.getAICollisionTriggers)
	SpecializationUtil.registerFunction(vehicleType, "startFieldWorker", AIFieldWorker.startFieldWorker)
	SpecializationUtil.registerFunction(vehicleType, "stopFieldWorker", AIFieldWorker.stopFieldWorker)
	SpecializationUtil.registerFunction(vehicleType, "getDirectionSnapAngle", AIFieldWorker.getDirectionSnapAngle)
	SpecializationUtil.registerFunction(vehicleType, "getAINeedsTrafficCollisionBox", AIFieldWorker.getAINeedsTrafficCollisionBox)
	SpecializationUtil.registerFunction(vehicleType, "clearAIDebugTexts", AIFieldWorker.clearAIDebugTexts)
	SpecializationUtil.registerFunction(vehicleType, "addAIDebugText", AIFieldWorker.addAIDebugText)
	SpecializationUtil.registerFunction(vehicleType, "clearAIDebugLines", AIFieldWorker.clearAIDebugLines)
	SpecializationUtil.registerFunction(vehicleType, "addAIDebugLine", AIFieldWorker.addAIDebugLine)
	SpecializationUtil.registerFunction(vehicleType, "updateAIFieldWorker", AIFieldWorker.updateAIFieldWorker)
	SpecializationUtil.registerFunction(vehicleType, "updateAIFieldWorkerImplementData", AIFieldWorker.updateAIFieldWorkerImplementData)
	SpecializationUtil.registerFunction(vehicleType, "updateAIFieldWorkerDriveStrategies", AIFieldWorker.updateAIFieldWorkerDriveStrategies)
	SpecializationUtil.registerFunction(vehicleType, "aiFieldWorkerStartTurn", AIFieldWorker.aiFieldWorkerStartTurn)
	SpecializationUtil.registerFunction(vehicleType, "aiFieldWorkerTurnProgress", AIFieldWorker.aiFieldWorkerTurnProgress)
	SpecializationUtil.registerFunction(vehicleType, "aiFieldWorkerEndTurn", AIFieldWorker.aiFieldWorkerEndTurn)
	SpecializationUtil.registerFunction(vehicleType, "aiFieldWorkerSideOffsetChanged", AIFieldWorker.aiFieldWorkerSideOffsetChanged)
	SpecializationUtil.registerFunction(vehicleType, "getCanAIFieldWorkerContinueWork", AIFieldWorker.getCanAIFieldWorkerContinueWork)
	SpecializationUtil.registerFunction(vehicleType, "setAIFieldWorkerIsTurning", AIFieldWorker.setAIFieldWorkerIsTurning)
	SpecializationUtil.registerFunction(vehicleType, "getAIFieldWorkerIsTurning", AIFieldWorker.getAIFieldWorkerIsTurning)
	SpecializationUtil.registerFunction(vehicleType, "setAIFieldWorkerIsCornerCutOutActive", AIFieldWorker.setAIFieldWorkerIsCornerCutOutActive)
	SpecializationUtil.registerFunction(vehicleType, "getAIFieldWorkerIsCornerCutOutActive", AIFieldWorker.getAIFieldWorkerIsCornerCutOutActive)
	SpecializationUtil.registerFunction(vehicleType, "getAIFieldWorkerLastTurnDirection", AIFieldWorker.getAIFieldWorkerLastTurnDirection)
	SpecializationUtil.registerFunction(vehicleType, "getAIFieldWorkerIsBlocked", AIFieldWorker.getAIFieldWorkerIsBlocked)
	SpecializationUtil.registerFunction(vehicleType, "getAttachedAIImplements", AIFieldWorker.getAttachedAIImplements)
	SpecializationUtil.registerFunction(vehicleType, "getCanStartFieldWork", AIFieldWorker.getCanStartFieldWork)
end

function AIFieldWorker.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "aiBlock", AIFieldWorker.aiBlock)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "aiContinue", AIFieldWorker.aiContinue)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getStartableAIJob", AIFieldWorker.getStartableAIJob)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getHasStartableAIJob", AIFieldWorker.getHasStartableAIJob)
end

function AIFieldWorker.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIFieldWorker)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AIFieldWorker)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AIFieldWorker)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIFieldWorker)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AIFieldWorker)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AIFieldWorker)
end

-- Local values: spec, wasActive, strategyIndex, strategyData
function AIFieldWorker:onLoad(savegame)
	local v19_ = self.spec_aiFieldWorker
	v19_.aiImplementList = {}
	v19_.aiImplementDataDirtyFlag = true
	v19_.aiDriveParams = {
		["valid"] = false
	}
	v19_.aiUpdateLowFrequencyDt = 0
	v19_.aiUpdateDt = 0
	v19_.driveStrategies = {}
	v19_.reconstructionData = {}
	v19_.aiTrafficCollision = nil
	v19_.aiTrafficCollisionTranslation = { 0, 0, 10 }
	v19_.debugTexts = {}
	v19_.debugLines = {}
	v19_.fieldJob = g_currentMission.aiJobTypeManager:createJob(AIJobType.FIELDWORK)
	v19_.didNotMoveTimeout = self.xmlFile:getValue("vehicle.ai.didNotMoveTimeout#value", 5000)
	if self.xmlFile:getValue("vehicle.ai.didNotMoveTimeout#deactivated") then
		v19_.didNotMoveTimeout = math.huge
	end
	v19_.didNotMoveTimer = v19_.didNotMoveTimeout
	v19_.isActive = false
	v19_.isBlocked = false
	v19_.lastTurnDirection = false
	v19_.isTurning = false
	v19_.isCornerCutOutActive = false
	if savegame ~= nil and (not savegame.resetVehicles and savegame.xmlFile:getValue(savegame.key .. ".aiFieldWorker#isActive")) then
		v19_.pendingAIFieldWorkerStart = true
		v19_.strategyLoadingData = {}
		for v20_, v21_ in ipairs(AIFieldWorker.registeredDriveStrategies) do
			if v21_.class.loadFromXML ~= nil then
				v19_.strategyLoadingData[v20_] = v21_.class.loadFromXML(v19_.reconstructionData, savegame.xmlFile, savegame.key .. ".aiFieldWorker")
			end
		end
	end
end

-- Local values: spec
function AIFieldWorker:onDelete()
	local v23_ = self.spec_aiFieldWorker
	if v23_.aiTrafficCollision ~= nil and entityExists(v23_.aiTrafficCollision) then
		delete(v23_.aiTrafficCollision)
		v23_.aiTrafficCollision = nil
	end
end

-- Local values: spec, i, strategy, strategyIndex, strategyData
function AIFieldWorker:saveToXMLFile(xmlFile, key, usedModNames)
	local v27_ = self.spec_aiFieldWorker
	if v27_.isActive ~= nil then
		xmlFile:setValue(key .. "#isActive", v27_.isActive)
	end
	if v27_.driveStrategies ~= nil and #v27_.driveStrategies > 0 then
		v27_.reconstructionData = {}
		for _, v28_ in ipairs(v27_.driveStrategies) do
			if v28_.fillReconstructionData ~= nil then
				v28_:fillReconstructionData(v27_.reconstructionData)
			end
		end
	end
	for _, v29_ in ipairs(AIFieldWorker.registeredDriveStrategies) do
		if v29_.class.saveToXML ~= nil then
			v29_.class.saveToXML(v27_.reconstructionData, xmlFile, key)
		end
	end
end

function AIFieldWorker:onReadStream(streamId, connection)
	if streamReadBool(streamId) then
		self:startFieldWorker()
	end
end

-- Local values: spec
function AIFieldWorker:onWriteStream(streamId, connection)
	local v34_ = self.spec_aiFieldWorker
	streamWriteBool(streamId, v34_.isActive)
end

-- Local values: spec, job, wx, _, wz, dx, _, dz, _, implement, yRot, i, text, _, l, x, y, z, _, driveStrategy
function AIFieldWorker:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v37_ = self.spec_aiFieldWorker
	if self.isServer and v37_.pendingAIFieldWorkerStart then
		local v38_ = g_currentMission.aiJobTypeManager:createJob(AIJobType.FIELDWORK)
		v38_.vehicleParameter:setVehicle(self)
		local v39_, _, v40_ = getWorldTranslation(self.rootNode)
		local v41_, _, v42_ = localDirectionToWorld(self.rootNode, 0, 0, 1)
		v38_.positionAngleParameter:setPosition(v39_, v40_)
		v38_.positionAngleParameter:setAngle(MathUtil.getYRotationFromDirection(v41_, v42_))
		v38_:setValues()
		g_client:getServerConnection():sendEvent(AIJobStartRequestEvent.new(v38_, self:getOwnerFarmId()))
		v37_.pendingAIFieldWorkerStart = false
	end
	if v37_.checkImplementDirection then
		v37_.checkImplementDirection = false
		for _, v43_ in pairs(self:getAttachedAIImplements()) do
			if v43_.object:getAINeedsRootAlignment() then
				local v44_ = Utils.getYRotationBetweenNodes(self:getAIDirectionNode(), v43_.object.components[1].node, self.yRotationOffset, v43_.object.yRotationOffset, false)
				if math.abs(v44_) > 1.5707963267948966 then
					self:stopCurrentAIJob(AIMessageErrorImplementWrongWay.new())
					return
				end
			end
		end
	end
	if VehicleDebug.state == VehicleDebug.DEBUG_AI and self.isActiveForInputIgnoreSelectionIgnoreAI then
		if #v37_.debugTexts > 0 then
			for v45_, v46_ in pairs(v37_.debugTexts) do
				renderText(0.7, 0.87 - 0.02 * v45_, 0.02, v46_)
			end
		end
		if #v37_.debugLines > 0 then
			for _, v47_ in pairs(v37_.debugLines) do
				drawDebugLine(v47_.s[1], v47_.s[2], v47_.s[3], v47_.c[1], v47_.c[2], v47_.c[3], v47_.e[1], v47_.e[2], v47_.e[3], v47_.c[1], v47_.c[2], v47_.c[3])
			end
		end
	end
	if v37_.aiImplementDataDirtyFlag then
		v37_.aiImplementDataDirtyFlag = false
		self:updateAIFieldWorkerImplementData()
	end
	if self:getIsFieldWorkActive() and self.isServer then
		if v37_.aiTrafficCollision ~= nil and not self:getAIFieldWorkerIsTurning() then
			local v48_ = localToWorld
			local v49_ = self.components[1].node
			local v50_ = v37_.aiTrafficCollisionTranslation
			local v51_, v52_, v53_ = v48_(v49_, unpack(v50_))
			setTranslation(v37_.aiTrafficCollision, v51_, v52_, v53_)
			setRotation(v37_.aiTrafficCollision, localRotationToWorld(self.components[1].node, 0, 0, 0))
		end
		for _, v54_ in ipairs(v37_.driveStrategies) do
			v54_:update(dt)
		end
		self:updateAIFieldWorker(dt)
	end
end

-- Local values: spec, vX, vY, vZ, tX, tZ, moveForwards, maxSpeedStra, maxSpeed, distanceToStop, _, driveStrategy, minimumSpeed, lookAheadDistance, distSpeed, speedLimit, _, moveForwards, tX, tY, tZ, maxSpeed, pX, _, pZ, acceleration, isAllowedToDrive
function AIFieldWorker:updateAIFieldWorker(dt)
	local v57_ = self.spec_aiFieldWorker
	self:clearAIDebugTexts()
	self:clearAIDebugLines()
	if self:getIsFieldWorkActive() then
		if #v57_.driveStrategies > 0 then
			local v58_, v59_, v60_ = getWorldTranslation(self:getAISteeringNode())
			local v61_ = nil
			local v62_ = nil
			local v63_ = nil
			local v64_ = nil
			local v65_ = nil
			for _, v66_ in ipairs(v57_.driveStrategies) do
				local v67_
				v63_, v62_, v65_, v67_, v64_ = v66_:getDriveData(dt, v58_, v59_, v60_)
				v61_ = math.min(v67_ or math.huge, v61_ or math.huge)
				if v63_ ~= nil or not self:getIsFieldWorkActive() then
					break
				end
			end
			if (v63_ == nil or (MathUtil.isNan(v63_) or MathUtil.isNan(v62_))) and self:getIsFieldWorkActive() then
				self:stopCurrentAIJob(AIMessageSuccessFinishedJob.new())
			end
			if not self:getIsFieldWorkActive() then
				return
			end
			local v68_, v69_
			if self:getAIFieldWorkerIsTurning() then
				v68_ = 2
				v69_ = 1.5
			else
				v68_ = 5
				v69_ = 5
			end
			local v70_ = v64_ / v68_
			local v71_ = v61_ * math.min(1, v70_)
			local v72_ = math.max(v69_, v71_)
			local v73_, _ = self:getSpeedLimit(true)
			local v74_ = math.min(v61_, v72_, v73_)
			local v75_ = math.min(v74_, self:getCruiseControlMaxSpeed())
			if VehicleDebug.state == VehicleDebug.DEBUG_AI then
				self:addAIDebugText(string.format("===> maxSpeed = %.2f", v75_))
			end
			v57_.aiDriveParams.moveForwards = v65_
			v57_.aiDriveParams.tX = v63_
			v57_.aiDriveParams.tY = v59_
			v57_.aiDriveParams.tZ = v62_
			v57_.aiDriveParams.maxSpeed = v75_
			v57_.aiDriveParams.valid = true
		end
		if v57_.aiDriveParams.valid then
			local v76_ = v57_.aiDriveParams.moveForwards
			local v77_ = v57_.aiDriveParams.tX
			local v78_ = v57_.aiDriveParams.tY
			local v79_ = v57_.aiDriveParams.tZ
			local v80_ = v57_.aiDriveParams.maxSpeed
			local v81_, v82_
			if v76_ then
				local v83_
				v81_, v83_, v82_ = worldToLocal(self:getAISteeringNode(), v77_, v78_, v79_)
			else
				local v84_
				v81_, v84_, v82_ = worldToLocal(self:getAIReverserNode(), v77_, v78_, v79_)
			end
			local v85_ = v80_ ~= 0
			AIVehicleUtil.driveToPoint(self, dt, 1, v85_, v76_, v81_, v82_, v80_)
		end
		self:raiseAIEvent("onAIFieldWorkerActive", "onAIImplementActive")
	end
end

-- Local values: spec
function AIFieldWorker:getIsFieldWorkActive()
	return self.spec_aiFieldWorker.isActive
end

-- Local values: job, spec, fieldJob, success
function AIFieldWorker:getStartableAIJob(superFunc)
	local v89_ = superFunc(self)
	local v90_
	if v89_ == nil then
		self:updateAIFieldWorkerImplementData()
		if self:getCanStartFieldWork() then
			v90_ = self.spec_aiFieldWorker.fieldJob
			v90_:applyCurrentState(self, g_currentMission, g_localPlayer.farmId, true)
			v90_:setValues()
			if not v90_:validate(false) then
				v90_ = v89_
			end
		else
			v90_ = v89_
		end
	else
		v90_ = v89_
	end
	return v90_
end

function AIFieldWorker:getHasStartableAIJob(superFunc)
	return self:getCanStartFieldWork()
end

-- Local values: spec
function AIFieldWorker:getCanStartFieldWork()
	local v93_ = self.spec_aiFieldWorker
	if v93_.isActive then
		return false
	else
		return #v93_.aiImplementList > 0
	end
end

-- Local values: spec, collision
function AIFieldWorker:startFieldWorker()
	local v95_ = self.spec_aiFieldWorker
	v95_.isActive = true
	if self.isServer then
		self:updateAIFieldWorkerImplementData()
		self:updateAIFieldWorkerDriveStrategies()
		v95_.checkImplementDirection = true
	end
	self:raiseAIEvent("onAIFieldWorkerStart", "onAIImplementStart")
	if self:getAINeedsTrafficCollisionBox() and (AIFieldWorker.TRAFFIC_COLLISION ~= nil and (AIFieldWorker.TRAFFIC_COLLISION ~= 0 and v95_.aiTrafficCollision == nil)) then
		v95_.aiTrafficCollision = clone(AIFieldWorker.TRAFFIC_COLLISION, true, false, true)
	end
end

-- Local values: spec, i, strategy, actionController
function AIFieldWorker:stopFieldWorker()
	local v97_ = self.spec_aiFieldWorker
	v97_.aiDriveParams.valid = false
	self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF, true)
	if self.isServer then
		WheelsUtil.updateWheelsPhysics(self, 0, v97_.lastSpeedReal * v97_.movingDirection, 0, true, true)
		if v97_.driveStrategies ~= nil and #v97_.driveStrategies > 0 then
			v97_.reconstructionData = {}
			for v98_ = #v97_.driveStrategies, 1, -1 do
				local v99_ = v97_.driveStrategies[v98_]
				if v99_.fillReconstructionData ~= nil then
					v99_:fillReconstructionData(v97_.reconstructionData)
				end
				v99_:delete()
				table.remove(v97_.driveStrategies, v98_)
			end
			v97_.driveStrategies = {}
		end
	end
	if self:getAINeedsTrafficCollisionBox() and v97_.aiTrafficCollision ~= nil then
		setTranslation(v97_.aiTrafficCollision, 0, -1000, 0)
	end
	if self.brake ~= nil then
		self:brake(1)
	end
	local v100_ = self.rootVehicle.actionController
	if v100_ ~= nil then
		v100_:resetCurrentState()
	end
	self:raiseAIEvent("onAIFieldWorkerEnd", "onAIImplementEnd")
	v97_.isBlocked = false
	v97_.lastTurnStrategy = nil
	v97_.isActive = false
end

function AIFieldWorker:getAICollisionTriggers(collisionTriggers) end

function AIFieldWorker:getDirectionSnapAngle()
	return 0
end

function AIFieldWorker:getAINeedsTrafficCollisionBox()
	return self.isServer
end

-- Local values: i
function AIFieldWorker:clearAIDebugTexts()
	for v103_ = #self.spec_aiFieldWorker.debugTexts, 1, -1 do
		self.spec_aiFieldWorker.debugTexts[v103_] = nil
	end
end

-- Local values: spec
function AIFieldWorker:addAIDebugText(text)
	local v106_ = self.spec_aiFieldWorker.debugTexts
	table.insert(v106_, text)
end

-- Local values: i
function AIFieldWorker:clearAIDebugLines()
	for v108_ = #self.spec_aiFieldWorker.debugLines, 1, -1 do
		self.spec_aiFieldWorker.debugLines[v108_] = nil
	end
end

-- Local values: spec
function AIFieldWorker:addAIDebugLine(s, e, c)
	local v113_ = self.spec_aiFieldWorker.debugLines
	table.insert(v113_, {
		["s"] = s,
		["e"] = e,
		["c"] = c
	})
end

-- Local values: spec
function AIFieldWorker:onStateChange(state, data)
	if state == VehicleStateChange.ATTACH or state == VehicleStateChange.DETACH then
		self.spec_aiFieldWorker.aiImplementDataDirtyFlag = true
	end
end

-- Local values: spec
function AIFieldWorker:updateAIFieldWorkerImplementData()
	local v117_ = self.spec_aiFieldWorker
	v117_.aiImplementList = {}
	self:addVehicleToAIImplementList(v117_.aiImplementList)
end

-- Local values: spec, i, strategyIndex, strategyData, _, childVehicle, i
function AIFieldWorker:updateAIFieldWorkerDriveStrategies()
	local v119_ = self.spec_aiFieldWorker
	if #v119_.aiImplementList > 0 then
		if v119_.driveStrategies ~= nil and #v119_.driveStrategies > 0 then
			for v120_ = #v119_.driveStrategies, 1, -1 do
				v119_.driveStrategies[v120_]:delete()
				table.remove(v119_.driveStrategies, v120_)
			end
			v119_.driveStrategies = {}
		end
		for _, v121_ in ipairs(AIFieldWorker.registeredDriveStrategies) do
			for _, v122_ in pairs(self.rootVehicle.childVehicles) do
				if v121_.func(v122_) then
					local v123_ = v119_.driveStrategies
					local v124_ = v121_.class.new
					local v125_ = v119_.reconstructionData
					table.insert(v123_, v124_(v125_))
					break
				end
			end
		end
		for v126_ = 1, #v119_.driveStrategies do
			v119_.driveStrategies[v126_]:setAIVehicle(self)
		end
	end
end

-- Local values: spec, _, driveStrategy
function AIFieldWorker:aiFieldWorkerStartTurn(left, turnStrategy)
	local v130_ = self.spec_aiFieldWorker
	v130_.lastTurnDirection = left
	v130_.lastTurnStrategy = turnStrategy
	for _, v131_ in ipairs(v130_.driveStrategies) do
		if v131_.setTurnData ~= nil then
			v131_:setTurnData(left, turnStrategy)
		end
	end
	self:raiseAIEvent("onAIFieldWorkerStartTurn", "onAIImplementStartTurn", left, turnStrategy)
end

function AIFieldWorker:aiFieldWorkerTurnProgress(progress, isLeft, movingDirection)
	self:raiseAIEvent("onAIFieldWorkerTurnProgress", "onAIImplementTurnProgress", progress, isLeft, movingDirection)
end

-- Local values: spec, _, driveStrategy
function AIFieldWorker:aiFieldWorkerEndTurn(left)
	local v138_ = self.spec_aiFieldWorker
	v138_.lastTurnStrategy = nil
	for _, v139_ in ipairs(v138_.driveStrategies) do
		if v139_.setTurnData ~= nil then
			v139_:setTurnData()
		end
	end
	self:raiseAIEvent("onAIFieldWorkerEndTurn", "onAIImplementEndTurn", left)
end

function AIFieldWorker:aiFieldWorkerSideOffsetChanged(isLeft, isInitial)
	self:raiseAIEvent("onAIFieldWorkerSideOffsetChanged", "onAIImplementSideOffsetChanged", isLeft, isInitial)
end

-- Local values: spec
function AIFieldWorker:aiBlock(superFunc)
	superFunc(self)
	local v145_ = self.spec_aiFieldWorker
	if v145_.isActive and not v145_.isTurning then
		self:raiseAIEvent("onAIFieldWorkerBlock", "onAIImplementBlock")
	end
	v145_.isBlocked = true
end

-- Local values: spec
function AIFieldWorker:aiContinue(superFunc)
	superFunc(self)
	local v148_ = self.spec_aiFieldWorker
	if v148_.isActive and not v148_.isTurning then
		self:raiseAIEvent("onAIFieldWorkerContinue", "onAIImplementContinue")
	end
	v148_.isBlocked = false
end

-- Local values: _, implement, canContinue, stopAI, stopReason, canContinue, stopAI, stopReason
function AIFieldWorker:getCanAIFieldWorkerContinueWork(isTurning)
	for _, v151_ in ipairs(self:getAttachedAIImplements()) do
		local v152_, v153_, v154_ = v151_.object:getCanAIImplementContinueWork(isTurning)
		if not v152_ then
			return false, v153_, v154_
		end
	end
	if SpecializationUtil.hasSpecialization(AIImplement, self.specializations) then
		local v155_, v156_, v157_ = self:getCanAIImplementContinueWork(isTurning)
		if not v155_ then
			return false, v156_, v157_
		end
	end
	return true, false
end

function AIFieldWorker:setAIFieldWorkerIsTurning(isTurning)
	self.spec_aiFieldWorker.isTurning = isTurning
end

function AIFieldWorker:getAIFieldWorkerIsTurning()
	return self.spec_aiFieldWorker.isTurning
end

function AIFieldWorker:setAIFieldWorkerIsCornerCutOutActive(isCornerCutOutActive)
	self.spec_aiFieldWorker.isCornerCutOutActive = isCornerCutOutActive
end

function AIFieldWorker:getAIFieldWorkerIsCornerCutOutActive()
	return self.spec_aiFieldWorker.isCornerCutOutActive
end

function AIFieldWorker:getAIFieldWorkerLastTurnDirection()
	return self.spec_aiFieldWorker.lastTurnDirection
end

function AIFieldWorker:getAIFieldWorkerIsBlocked()
	return self.spec_aiFieldWorker.isBlocked
end

function AIFieldWorker:getAttachedAIImplements()
	return self.spec_aiFieldWorker.aiImplementList
end

-- Local values: collision
function AIFieldWorker.onTrafficCollisionLoaded(_, i3dNode)
	if i3dNode ~= 0 then
		local v168_ = getChildAt(i3dNode, 0)
		link(getRootNode(), v168_)
		AIFieldWorker.TRAFFIC_COLLISION = v168_
		delete(i3dNode)
	end
end
