PlowPacker = {}
PlowPacker.CULTIVATED_GROUND_TYPES = {
	FieldGroundType.STUBBLE_TILLAGE,
	FieldGroundType.CULTIVATED,
	FieldGroundType.SEEDBED,
	FieldGroundType.ROLLED_SEEDBED
}
PlowPacker.CLIENT_DM_UPDATE_RADIUS = 50
source("dataS/scripts/vehicles/specializations/events/PlowPackerStateEvent.lua")
function PlowPacker.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("PlowPacker")
	v1_:register(XMLValueType.STRING, "vehicle.plow.packer#inputAction", "Input action name for packer toggling", "IMPLEMENT_EXTRA4")
	v1_:register(XMLValueType.STRING, "vehicle.plow.packer#deactivateLeft", "Packer deactivate animation left side")
	v1_:register(XMLValueType.STRING, "vehicle.plow.packer#deactivateRight", "Packer deactivate animation left side")
	v1_:register(XMLValueType.FLOAT, "vehicle.plow.packer#animationSpeed", "Packer animation speed", 1)
	v1_:register(XMLValueType.INT, "vehicle.plow.packer#foldingConfig", "Folding configuration with available packer", 1)
	v1_:register(XMLValueType.BOOL, "vehicle.plow.packer#partialDeactivated", "Only some parts of the packer are deactivated", false)
	v1_:register(XMLValueType.STRING, "vehicle.plow.packer.lowerAnimation#name", "Lower animation that is played while packer is active")
	v1_:register(XMLValueType.FLOAT, "vehicle.plow.packer.lowerAnimation#speed", "Lower animation speed", 1)
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	v2_:register(XMLValueType.BOOL, "vehicles.vehicle(?).plowPacker#packerState", "Packer state")
	v2_:register(XMLValueType.BOOL, "vehicles.vehicle(?).plowPacker#lastPackerState", "Last packer state while turning")
end

function PlowPacker.prerequisitesPresent(specializations)
	local v4_ = SpecializationUtil.hasSpecialization(Plow, specializations) and SpecializationUtil.hasSpecialization(Cultivator, specializations)
	if v4_ then
		v4_ = SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end
	return v4_
end

function PlowPacker.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setPackerState", PlowPacker.setPackerState)
	SpecializationUtil.registerFunction(vehicleType, "getIsPackerAllowed", PlowPacker.getIsPackerAllowed)
end

function PlowPacker.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setRotationMax", PlowPacker.setRotationMax)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setPlowAIRequirements", PlowPacker.setPlowAIRequirements)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setFoldState", PlowPacker.setFoldState)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "processCultivatorArea", PlowPacker.processCultivatorArea)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUseCultivatorAIRequirements", PlowPacker.getUseCultivatorAIRequirements)
end

function PlowPacker.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", PlowPacker)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", PlowPacker)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", PlowPacker)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", PlowPacker)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", PlowPacker)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", PlowPacker)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", PlowPacker)
	SpecializationUtil.registerEventListener(vehicleType, "onSetLowered", PlowPacker)
end

-- Local values: spec, actionName
function PlowPacker:onLoad(savegame)
	local v9_ = self.spec_plowPacker
	local v10_ = self.xmlFile:getValue("vehicle.plow.packer#inputAction", "IMPLEMENT_EXTRA4")
	if v10_ ~= nil then
		v9_.packerInputActionIndex = InputAction[v10_]
	end
	v9_.packerDeactivateLeftAnimation = self.xmlFile:getValue("vehicle.plow.packer#deactivateLeft")
	v9_.packerDeactivateRightAnimation = self.xmlFile:getValue("vehicle.plow.packer#deactivateRight")
	v9_.packerDeactivateAnimSpeed = self.xmlFile:getValue("vehicle.plow.packer#animationSpeed", 1)
	v9_.packerFoldingConfiguration = self.xmlFile:getValue("vehicle.plow.packer#foldingConfig", 1)
	local v11_
	if self.configurations.folding == v9_.packerFoldingConfiguration and v9_.packerDeactivateLeftAnimation ~= nil then
		v11_ = v9_.packerDeactivateRightAnimation ~= nil
	else
		v11_ = false
	end
	v9_.packerAvailable = v11_
	v9_.partialDeactivated = self.xmlFile:getValue("vehicle.plow.packer#partialDeactivated", false)
	v9_.lowerAnimation = self.xmlFile:getValue("vehicle.plow.packer.lowerAnimation#name")
	v9_.lowerAnimationSpeed = self.xmlFile:getValue("vehicle.plow.packer.lowerAnimation#speed", 1)
	v9_.packerActivateText = g_i18n:getText("action_activatePacker", self.customEnvironment)
	v9_.packerDeactivateText = g_i18n:getText("action_deactivatePacker", self.customEnvironment)
	v9_.packerState = true
	v9_.delayedFoldStateChange = nil
	v9_.delayedLowerAnimationUpdate = false
end

-- Local values: spec, packerState
function PlowPacker:onPostLoad(savegame)
	local v14_ = self.spec_plowPacker
	self:setPlowAIRequirements()
	if savegame ~= nil and (not savegame.resetVehicles and v14_.packerAvailable) then
		local v15_ = savegame.xmlFile:getValue(savegame.key .. ".plowPacker#packerState")
		if v15_ ~= nil then
			self:setPackerState(v15_, true, true)
			AnimatedVehicle.updateAnimations(self, 99999999, true)
		end
		v14_.lastPackerState = savegame.xmlFile:getValue(savegame.key .. ".plowPacker#lastPackerState")
	end
end

-- Local values: spec
function PlowPacker:saveToXMLFile(xmlFile, key, usedModNames)
	local v19_ = self.spec_plowPacker
	if v19_.packerAvailable then
		xmlFile:setValue(key .. "#packerState", v19_.packerState)
		if v19_.lastPackerState ~= nil then
			xmlFile:setValue(key .. "#lastPackerState", v19_.lastPackerState)
		end
	end
end

-- Local values: spec, packerState
function PlowPacker:onReadStream(streamId, connection)
	if self.spec_plowPacker.packerAvailable then
		local v22_ = streamReadBool(streamId)
		if self:getIsPackerAllowed() then
			self:setPackerState(v22_, true, true)
			AnimatedVehicle.updateAnimations(self, 99999999, true)
		end
	end
end

-- Local values: spec
function PlowPacker:onWriteStream(streamId, connection)
	local v25_ = self.spec_plowPacker
	if v25_.packerAvailable then
		streamWriteBool(streamId, v25_.packerState)
	end
end

-- Local values: spec, data, isLowered, animationTime
function PlowPacker:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local v27_ = self.spec_plowPacker
		if v27_.packerAvailable then
			if v27_.lastPackerState ~= nil and self:getIsPackerAllowed() then
				if v27_.lastPackerState == false then
					self:setPackerState(false, true)
				end
				v27_.lastPackerState = nil
			end
			if v27_.delayedFoldStateChange ~= nil and not (self:getIsAnimationPlaying(v27_.packerDeactivateLeftAnimation) or self:getIsAnimationPlaying(v27_.packerDeactivateRightAnimation)) then
				local v28_ = v27_.delayedFoldStateChange
				v28_.superFunc(self, v28_.direction, v28_.moveToMiddle, false)
				v27_.delayedFoldStateChange = nil
			end
			if v27_.delayedLowerAnimationUpdate and not (self:getIsAnimationPlaying(v27_.packerDeactivateLeftAnimation) or self:getIsAnimationPlaying(v27_.packerDeactivateRightAnimation)) then
				local v29_ = self:getIsLowered()
				local v30_ = self:getAnimationTime(v27_.lowerAnimation)
				if v29_ and v30_ <= 0.5 or not v29_ and v30_ > 0.5 then
					self:playAnimation(v27_.lowerAnimation, v29_ and v27_.lowerAnimationSpeed or -v27_.lowerAnimationSpeed, nil, true)
				end
				v27_.delayedLowerAnimationUpdate = false
			end
		end
	end
end

function PlowPacker:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient and self.spec_plowPacker.packerAvailable then
		PlowPacker.updateActionEventText(self)
	end
end

-- Local values: spec
function PlowPacker:setRotationMax(superFunc, rotationMax, noEventSend, turnAnimationTime)
	if self.isServer and self.spec_plow.rotationMax ~= rotationMax then
		local v37_ = self.spec_plowPacker
		if v37_.packerAvailable and v37_.lastPackerState == nil then
			v37_.lastPackerState = v37_.packerState
			self:setPackerState(true, true)
		end
	end
	superFunc(self, rotationMax, noEventSend, turnAnimationTime)
end

-- Local values: spec
function PlowPacker:setPlowAIRequirements(superFunc, excludedGroundTypes)
	local v41_ = self.spec_plowPacker
	if v41_.packerAvailable and (v41_.packerState or v41_.partialDeactivated) then
		return superFunc(self, PlowPacker.CULTIVATED_GROUND_TYPES)
	else
		return superFunc(self, excludedGroundTypes)
	end
end

-- Local values: spec, specFoldable
function PlowPacker:setFoldState(superFunc, direction, moveToMiddle, noEventSend)
	local v47_ = self.spec_plowPacker
	if v47_.packerAvailable and (direction ~= 0 and (direction ~= self.spec_foldable.turnOnFoldDirection and (self:getIsPackerAllowed() and not v47_.packerState))) then
		if self.isServer and v47_.lastPackerState == nil then
			v47_.lastPackerState = v47_.packerState
			self:setPackerState(true, true)
			v47_.delayedFoldStateChange = {
				["superFunc"] = superFunc,
				["direction"] = direction,
				["moveToMiddle"] = moveToMiddle
			}
		end
		local v48_ = self.spec_foldable
		if v48_.foldMiddleAnimTime == nil then
			moveToMiddle = false
		end
		if (v48_.foldMoveDirection ~= direction or v48_.moveToMiddle ~= moveToMiddle) and (noEventSend == nil or noEventSend == false) then
			if g_server ~= nil then
				g_server:broadcastEvent(FoldableSetFoldDirectionEvent.new(self, direction, moveToMiddle), nil, nil, self)
				return
			end
			g_client:getServerConnection():sendEvent(FoldableSetFoldDirectionEvent.new(self, direction, moveToMiddle))
		end
	else
		superFunc(self, direction, moveToMiddle, noEventSend)
	end
end

-- Local values: spec, xs, _, zs, xw, _, zw, xh, _, zh, params, realArea, area
function PlowPacker:processCultivatorArea(superFunc, workArea, dt)
	local v51_ = self.spec_cultivator
	local v52_, _, v53_ = getWorldTranslation(workArea.start)
	local v54_, _, v55_ = getWorldTranslation(workArea.width)
	local v56_, _, v57_ = getWorldTranslation(workArea.height)
	FSDensityMapUtil.eraseTireTrack(v52_, v53_, v54_, v55_, v56_, v57_)
	if not self.isServer and self.currentUpdateDistance > PlowPacker.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	local v58_ = v51_.workAreaParameters
	local v59_, v60_ = FSDensityMapUtil.updatePlowPackerArea(v52_, v53_, v54_, v55_, v56_, v57_, v58_.angle)
	v58_.lastChangedArea = v58_.lastChangedArea + v59_
	v58_.lastStatsArea = v58_.lastStatsArea + v59_
	v58_.lastTotalArea = v58_.lastTotalArea + v60_
	v51_.isWorking = self:getLastSpeed() > 0.5
	return v59_, v60_
end

function PlowPacker:getUseCultivatorAIRequirements(superFunc)
	return false
end

-- Local values: spec, direction, isLowered, animationTime
function PlowPacker:setPackerState(newState, updateAnimations, noEventSend)
	local v65_ = self.spec_plowPacker
	if newState == nil then
		newState = not v65_.packerState
	end
	local v66_ = updateAnimations == nil and true or updateAnimations
	if newState ~= v65_.packerState then
		v65_.packerState = newState
		if v66_ then
			local v67_ = newState and -1 or 1
			if self.spec_plow.rotationMax then
				self:playAnimation(v65_.packerDeactivateLeftAnimation, v65_.packerDeactivateAnimSpeed * v67_, nil, true)
			else
				self:playAnimation(v65_.packerDeactivateRightAnimation, v65_.packerDeactivateAnimSpeed * v67_, nil, true)
			end
		end
		if newState and v65_.lowerAnimation ~= nil then
			local v68_ = self:getIsLowered()
			local v69_ = self:getAnimationTime(v65_.lowerAnimation)
			if v68_ and v69_ <= 0.5 or not v68_ and v69_ > 0.5 then
				v65_.delayedLowerAnimationUpdate = true
			end
		end
		self:setPlowAIRequirements()
		PlowPackerStateEvent.sendEvent(self, newState, v66_, noEventSend)
	end
	PlowPacker.updateActionEventText(self)
end

-- Local values: spec
function PlowPacker:getIsPackerAllowed()
	if self:getIsAnimationPlaying(self.spec_plow.rotationPart.turnAnimation) then
		return false
	elseif self:getFoldAnimTime() == (self.spec_foldable.turnOnFoldDirection > 0 and 1 or 0) then
		local v71_ = self.spec_plowPacker
		if v71_.delayedFoldStateChange == nil then
			return v71_.packerAvailable and true or false
		else
			return false
		end
	else
		return false
	end
end

-- Local values: spec
function PlowPacker:onSetLowered(lowered)
	local v74_ = self.spec_plowPacker
	if self:getIsPackerAllowed() and (v74_.packerState and v74_.lowerAnimation ~= nil) then
		self:playAnimation(v74_.lowerAnimation, lowered and v74_.lowerAnimationSpeed or -v74_.lowerAnimationSpeed, nil, true)
	end
end

-- Local values: spec, _, actionEventId
function PlowPacker:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v77_ = self.spec_plowPacker
		if v77_.packerAvailable then
			self:clearActionEventsTable(v77_.actionEvents)
			if isActiveForInput and v77_.packerInputActionIndex ~= nil then
				local _, v78_ = self:addPoweredActionEvent(v77_.actionEvents, v77_.packerInputActionIndex, self, PlowPacker.actionEventPackerDeactivate, false, true, false, true)
				g_inputBinding:setActionEventTextPriority(v78_, GS_PRIO_NORMAL)
				PlowPacker.updateActionEventText(self)
			end
		end
	end
end

-- Local values: spec, actionEvent
function PlowPacker:updateActionEventText()
	local v80_ = self.spec_plowPacker
	local v81_ = v80_.actionEvents[v80_.packerInputActionIndex]
	if v81_ ~= nil then
		if v80_.packerState then
			g_inputBinding:setActionEventText(v81_.actionEventId, v80_.packerDeactivateText)
		else
			g_inputBinding:setActionEventText(v81_.actionEventId, v80_.packerActivateText)
		end
		g_inputBinding:setActionEventActive(v81_.actionEventId, self:getIsPackerAllowed())
	end
end

function PlowPacker:actionEventPackerDeactivate(actionName, inputValue, callbackState, isAnalog, isMouse)
	self:setPackerState()
end
