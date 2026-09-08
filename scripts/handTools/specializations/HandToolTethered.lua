HandToolTethered = {}

function HandToolTethered.registerXMLPaths(xmlSchema)
	xmlSchema:setXMLSpecializationType("HandToolTethered")
	xmlSchema:register(XMLValueType.L10N_STRING, "handTool.tethered#warningText", "The l10n text string to use when warning the player of the range. The remaining range is the first argument", nil, false)
	xmlSchema:register(XMLValueType.FLOAT, "handTool.tethered#actionRange", "The range in metres in which this tool can work. When outside of this range, the range warning is shown", "3 metres", false)
	xmlSchema:register(XMLValueType.FLOAT, "handTool.tethered#range", "The range in metres before this tool snaps back into its holder", "5 metres", false)
end

function HandToolTethered.registerFunctions(handToolType)
	SpecializationUtil.registerFunction(handToolType, "showRangeWarning", HandToolTethered.showRangeWarning)
	SpecializationUtil.registerFunction(handToolType, "returnToHolder", HandToolTethered.returnToHolder)
	SpecializationUtil.registerFunction(handToolType, "setAttachedHolder", HandToolTethered.setAttachedHolder)
end

function HandToolTethered.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setHolder", HandToolTethered.setHolder)
end

function HandToolTethered.registerEventListeners(handToolType)
	SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolTethered)
	SpecializationUtil.registerEventListener(handToolType, "onDelete", HandToolTethered)
	SpecializationUtil.registerEventListener(handToolType, "onCarryingPlayerEnteredVehicle", HandToolTethered)
	SpecializationUtil.registerEventListener(handToolType, "onCarryingPlayerLeftGame", HandToolTethered)
	SpecializationUtil.registerEventListener(handToolType, "onPreUpdate", HandToolTethered)
end

function HandToolTethered.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(HandToolStorable, specializations)
end

-- Local values: spec
function HandToolTethered:onLoad(xmlFile, baseDirectory)
	local v8_ = self.spec_tethered
	v8_.attachedHolder = nil
	v8_.rangeWarningText = self.xmlFile:getValue("handTool.tethered#warningText", "DistanceWarning %d", self.customEnvironment, true)
	v8_.actionRange = xmlFile:getValue("handTool.tethered#actionRange", 3)
	v8_.maximumRange = xmlFile:getValue("handTool.tethered#range", 5)
	if not self.mustBeHeld then
		Logging.warning("HandTool %q has its mustBeHeld value set to false, but tethered tools cannot be put away! Setting to true!", self.typeName)
		self.mustBeHeld = true
	end
	if self.canBeSaved then
		Logging.warning("HandTool %q has its canBeSaved value set to true, but tethered tools cannot be saved! Setting to false!", self.typeName)
		self.canBeSaved = false
	end
	v8_.warningIdentifier = getMD5((tostring(self)))
end

-- Local values: spec
function HandToolTethered:onDelete()
	local v10_ = self.spec_tethered
	if v10_.attachedHolder ~= nil then
		v10_.attachedHolder.spawnedHandTool = nil
	end
end

-- Local values: spec, player, playerPositionX, playerPositionY, playerPositionZ, holderPositionX, holderPositionY, holderPositionZ, holderPlayerDistance
function HandToolTethered:onPreUpdate(dt)
	local v12_ = self.spec_tethered
	if v12_.attachedHolder == nil then
		return
	elseif self:getIsHeld() then
		local v13_ = self:getCarryingPlayer()
		if v13_ == nil then
			return
		else
			local v14_, v15_, v16_ = v13_:getPosition()
			local v17_, v18_, v19_ = getWorldTranslation(v12_.attachedHolder.holderNode)
			local v20_ = MathUtil.vector3Length(v14_ - v17_, v15_ - v18_, v16_ - v19_)
			if v12_.maximumRange < v20_ then
				self:returnToHolder()
			elseif v12_.actionRange < v20_ and v13_ == g_localPlayer then
				self:showRangeWarning(v20_)
			end
		end
	else
		return
	end
end

-- Local values: spec
function HandToolTethered:setAttachedHolder(holder)
	local v23_ = self.spec_tethered
	if v23_.attachedHolder == nil then
		v23_.attachedHolder = holder
	else
		Logging.devWarning("Tethered tool holder already set")
	end
end

function HandToolTethered:onCarryingPlayerLeftGame()
	self:returnToHolder()
end

function HandToolTethered:onCarryingPlayerEnteredVehicle()
	self:returnToHolder()
end

-- Local values: spec
function HandToolTethered:setHolder(superFunc, holder, noEventSend)
	if holder == nil then
		local v30_ = self.spec_tethered
		if v30_.attachedHolder == nil then
			return
		end
		holder = v30_.attachedHolder
	end
	superFunc(self, holder, noEventSend)
end

-- Local values: spec
function HandToolTethered:returnToHolder(noEventSend)
	local v33_ = self.spec_tethered
	if v33_.attachedHolder ~= nil then
		self:setHolder(v33_.attachedHolder, noEventSend)
	end
end

-- Local values: spec, remainingDistance, mission
function HandToolTethered:showRangeWarning(holderPlayerDistance)
	if g_gui:getIsGuiVisible() then
		return
	else
		local v36_ = self.spec_tethered
		if not string.isNilOrWhitespace(v36_.rangeWarningText) then
			local v37_ = v36_.maximumRange - holderPlayerDistance
			g_currentMission:showBlinkingWarning(string.format(v36_.rangeWarningText, v37_), 100, v36_.warningIdentifier)
		end
	end
end
