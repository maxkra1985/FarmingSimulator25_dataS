-- Local values: BunkerSilo_mt, BunkerSiloActivatable_mt
BunkerSilo = {}
local BunkerSilo_mt = Class(BunkerSilo, Object)
InitStaticObjectClass(BunkerSilo, "BunkerSilo")
BunkerSilo.STATE_FILL = 0
BunkerSilo.STATE_CLOSED = 1
BunkerSilo.STATE_FERMENTED = 2
BunkerSilo.STATE_DRAIN = 3
BunkerSilo.NUM_STATES = 4
BunkerSilo.COMPACTING_BASE_MASS = 5
BunkerSilo.MILLISECONDS_PER_DAY = 86400000

function BunkerSilo:onCreate(id)
	Logging.error("BunkerSilo.onCreate is deprecated!")
end

-- Upvalues: BunkerSilo_mt
-- Local values: self
function BunkerSilo.new(isServer, isClient, customMt)
	-- upvalues: (copy) BunkerSilo_mt
	local v5_ = Object.new(isServer, isClient, customMt or BunkerSilo_mt)
	v5_.interactionTriggerNode = nil
	v5_.bunkerSiloArea = {}
	v5_.bunkerSiloArea.offsetFront = 0
	v5_.bunkerSiloArea.offsetBack = 0
	v5_.acceptedFillTypes = {}
	v5_.inputFillType = FillType.CHAFF
	v5_.outputFillType = FillType.SILAGE
	v5_.fermentingFillType = FillType.TARP
	v5_.isOpenedAtFront = false
	v5_.isOpenedAtBack = false
	v5_.distanceToCompactedFillLevel = 100
	v5_.fermentingPercent = 0
	v5_.fillLevel = 0
	v5_.compactedFillLevel = 0
	v5_.compactedPercent = 0
	v5_.emptyThreshold = 100
	v5_.playerInRange = false
	v5_.vehiclesInRange = {}
	v5_.numVehiclesInRange = 0
	v5_.siloIsFullWarningTimer = 0
	v5_.siloIsFullWarningDuration = 2000
	v5_.updateTimer = 0
	v5_.activatable = BunkerSiloActivatable.new(v5_)
	v5_.state = BunkerSilo.STATE_FILL
	v5_.bunkerSiloDirtyFlag = v5_:getNextDirtyFlag()
	g_messageCenter:subscribe(MessageType.HOUR_CHANGED, v5_.onHourChanged, v5_)
	return v5_
end

-- Local values: data, i, fillTypeIndex, inputFillTypeName, inputFillTypeIndex, outputFillTypeName, outputFillTypeIndex, leftWallNode, rightWallNode, difficultyMultiplier
function BunkerSilo:load(components, xmlFile, key, i3dMappings)
	self.bunkerSiloArea.start = xmlFile:getValue(key .. ".area#startNode", nil, components, i3dMappings)
	self.bunkerSiloArea.width = xmlFile:getValue(key .. ".area#widthNode", nil, components, i3dMappings)
	self.bunkerSiloArea.height = xmlFile:getValue(key .. ".area#heightNode", nil, components, i3dMappings)
	local v11_ = self.bunkerSiloArea
	local v12_ = self.bunkerSiloArea
	local v13_ = self.bunkerSiloArea
	local v14_, v15_, v16_ = getWorldTranslation(self.bunkerSiloArea.start)
	v11_.sx = v14_
	v12_.sy = v15_
	v13_.sz = v16_
	local v17_ = self.bunkerSiloArea
	local v18_ = self.bunkerSiloArea
	local v19_ = self.bunkerSiloArea
	local v20_, v21_, v22_ = getWorldTranslation(self.bunkerSiloArea.width)
	v17_.wx = v20_
	v18_.wy = v21_
	v19_.wz = v22_
	local v23_ = self.bunkerSiloArea
	local v24_ = self.bunkerSiloArea
	local v25_ = self.bunkerSiloArea
	local v26_, v27_, v28_ = getWorldTranslation(self.bunkerSiloArea.height)
	v23_.hx = v26_
	v24_.hy = v27_
	v25_.hz = v28_
	self.bunkerSiloArea.dhx = self.bunkerSiloArea.hx - self.bunkerSiloArea.sx
	self.bunkerSiloArea.dhy = self.bunkerSiloArea.hy - self.bunkerSiloArea.sy
	self.bunkerSiloArea.dhz = self.bunkerSiloArea.hz - self.bunkerSiloArea.sz
	local v29_ = self.bunkerSiloArea
	local v30_ = self.bunkerSiloArea
	local v31_ = self.bunkerSiloArea
	local v32_, v33_, v34_ = MathUtil.vector3Normalize(self.bunkerSiloArea.dhx, self.bunkerSiloArea.dhy, self.bunkerSiloArea.dhz)
	v29_.dhx_norm = v32_
	v30_.dhy_norm = v33_
	v31_.dhz_norm = v34_
	self.bunkerSiloArea.dwx = self.bunkerSiloArea.wx - self.bunkerSiloArea.sx
	self.bunkerSiloArea.dwy = self.bunkerSiloArea.wy - self.bunkerSiloArea.sy
	self.bunkerSiloArea.dwz = self.bunkerSiloArea.wz - self.bunkerSiloArea.sz
	local v35_ = self.bunkerSiloArea
	local v36_ = self.bunkerSiloArea
	local v37_ = self.bunkerSiloArea
	local v38_, v39_, v40_ = MathUtil.vector3Normalize(self.bunkerSiloArea.dwx, self.bunkerSiloArea.dwy, self.bunkerSiloArea.dwz)
	v35_.dwx_norm = v38_
	v36_.dwy_norm = v39_
	v37_.dwz_norm = v40_
	self.bunkerSiloArea.inner = {}
	self.bunkerSiloArea.inner.start = xmlFile:getValue(key .. ".innerArea#startNode", self.bunkerSiloArea.start, components, i3dMappings)
	self.bunkerSiloArea.inner.width = xmlFile:getValue(key .. ".innerArea#widthNode", self.bunkerSiloArea.width, components, i3dMappings)
	self.bunkerSiloArea.inner.height = xmlFile:getValue(key .. ".innerArea#heightNode", self.bunkerSiloArea.height, components, i3dMappings)
	local v41_ = self.bunkerSiloArea.inner
	local v42_ = self.bunkerSiloArea.inner
	local v43_ = self.bunkerSiloArea.inner
	local v44_, v45_, v46_ = getWorldTranslation(self.bunkerSiloArea.inner.start)
	v41_.sx = v44_
	v42_.sy = v45_
	v43_.sz = v46_
	local v47_ = self.bunkerSiloArea.inner
	local v48_ = self.bunkerSiloArea.inner
	local v49_ = self.bunkerSiloArea.inner
	local v50_, v51_, v52_ = getWorldTranslation(self.bunkerSiloArea.inner.width)
	v47_.wx = v50_
	v48_.wy = v51_
	v49_.wz = v52_
	local v53_ = self.bunkerSiloArea.inner
	local v54_ = self.bunkerSiloArea.inner
	local v55_ = self.bunkerSiloArea.inner
	local v56_, v57_, v58_ = getWorldTranslation(self.bunkerSiloArea.inner.height)
	v53_.hx = v56_
	v54_.hy = v57_
	v55_.hz = v58_
	self.interactionTriggerNode = xmlFile:getValue(key .. ".interactionTrigger#node", nil, components, i3dMappings)
	if self.interactionTriggerNode ~= nil then
		addTrigger(self.interactionTriggerNode, "interactionTriggerCallback", self)
	end
	self.acceptedFillTypes = {}
	local v59_ = xmlFile:getValue(key .. "#acceptedFillTypes", "chaff grass_windrow dryGrass_windrow"):split(" ")
	for v60_ = 1, #v59_ do
		local v61_ = g_fillTypeManager:getFillTypeIndexByName(v59_[v60_])
		if v61_ == nil then
			local v62_ = Logging.warning
			local v63_ = v59_[v60_]
			v62_("\'%s\' is an invalid fillType for bunkerSilo \'%s\'!", tostring(v63_), key .. "#acceptedFillTypes")
		else
			self.acceptedFillTypes[v61_] = true
		end
	end
	local v64_ = xmlFile:getValue(key .. "#inputFillType", "chaff")
	local v65_ = g_fillTypeManager:getFillTypeIndexByName(v64_)
	if v65_ == nil then
		Logging.warning("\'%s\' is an invalid input fillType for bunkerSilo \'%s\'!", tostring(v64_), key .. "#inputFillType")
	else
		self.inputFillType = v65_
	end
	local v66_ = xmlFile:getValue(key .. "#outputFillType", "silage")
	local v67_ = g_fillTypeManager:getFillTypeIndexByName(v66_)
	if v67_ == nil then
		Logging.warning("\'%s\' is an invalid output fillType for bunkerSilo \'%s\'!", tostring(v66_), key .. "#outputFillType")
	else
		self.outputFillType = v67_
	end
	g_densityMapHeightManager:setConvertingFillTypeAreas(self.bunkerSiloArea, self.acceptedFillTypes, self.inputFillType)
	self.distanceToCompactedFillLevel = xmlFile:getValue(key .. "#distanceToCompactedFillLevel", self.distanceToCompactedFillLevel)
	self.openingLength = xmlFile:getValue(key .. "#openingLength", 5)
	local v68_ = xmlFile:getValue(key .. ".wallLeft#node", nil, components, i3dMappings)
	if v68_ ~= nil then
		self.wallLeft = {}
		self.wallLeft.node = v68_
		self.wallLeft.visible = true
		self.wallLeft.collision = xmlFile:getValue(key .. ".wallLeft#collision", nil, components, i3dMappings)
	end
	local v69_ = xmlFile:getValue(key .. ".wallRight#node", nil, components, i3dMappings)
	if v69_ ~= nil then
		self.wallRight = {}
		self.wallRight.node = v69_
		self.wallRight.visible = true
		self.wallRight.collision = xmlFile:getValue(key .. ".wallRight#collision", nil, components, i3dMappings)
	end
	self.fillLevel = 0
	local v70_ = g_currentMission.missionInfo.economicDifficulty
	self.distanceToCompactedFillLevel = self.distanceToCompactedFillLevel / v70_
	self:setState(BunkerSilo.STATE_FILL)
	return true
end

function BunkerSilo:delete()
	if self.interactionTriggerNode ~= nil then
		removeTrigger(self.interactionTriggerNode)
	end
	g_densityMapHeightManager:removeFixedFillTypesArea(self.bunkerSiloArea)
	g_densityMapHeightManager:removeConvertingFillTypeAreas(self.bunkerSiloArea)
	g_messageCenter:unsubscribeAll(self)
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	BunkerSilo:superClass().delete(self)
end

-- Local values: state
function BunkerSilo:readStream(streamId, connection)
	BunkerSilo:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		self:setState((streamReadUIntN(streamId, 3)))
		self.isOpenedAtFront = streamReadBool(streamId)
		self.isOpenedAtBack = streamReadBool(streamId)
		self.fillLevel = streamReadFloat32(streamId)
		self.compactedPercent = streamReadUIntN(streamId, 7)
		self.fermentingPercent = NetworkUtil.readCompressedPercentages(streamId)
	end
end

function BunkerSilo:writeStream(streamId, connection)
	BunkerSilo:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		streamWriteUIntN(streamId, self.state, 3)
		streamWriteBool(streamId, self.isOpenedAtFront)
		streamWriteBool(streamId, self.isOpenedAtBack)
		streamWriteFloat32(streamId, self.fillLevel)
		streamWriteUIntN(streamId, self.compactedPercent, 7)
		NetworkUtil.writeCompressedPercentages(streamId, self.fermentingPercent)
	end
end

-- Local values: state
function BunkerSilo:readUpdateStream(streamId, timestamp, connection)
	BunkerSilo:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local v82_ = streamReadUIntN(streamId, 3)
		if v82_ ~= self.state then
			self:setState(v82_, true)
		end
		self.fillLevel = streamReadFloat32(streamId)
		self.isOpenedAtFront = streamReadBool(streamId)
		self.isOpenedAtBack = streamReadBool(streamId)
		if self.state == BunkerSilo.STATE_FILL then
			self.compactedPercent = streamReadUIntN(streamId, 7)
			return
		end
		if self.state == BunkerSilo.STATE_CLOSED or self.state == BunkerSilo.STATE_FERMENTED then
			self.fermentingPercent = NetworkUtil.readCompressedPercentages(streamId)
		end
	end
end

function BunkerSilo:writeUpdateStream(streamId, connection, dirtyMask)
	BunkerSilo:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v87_ = streamWriteBool
		local v88_ = self.bunkerSiloDirtyFlag
		if v87_(streamId, bit32.band(dirtyMask, v88_) ~= 0) then
			streamWriteUIntN(streamId, self.state, 3)
			streamWriteFloat32(streamId, self.fillLevel)
			streamWriteBool(streamId, self.isOpenedAtFront)
			streamWriteBool(streamId, self.isOpenedAtBack)
			if self.state == BunkerSilo.STATE_FILL then
				streamWriteUIntN(streamId, self.compactedPercent, 7)
				return
			end
			if self.state == BunkerSilo.STATE_CLOSED or self.state == BunkerSilo.STATE_FERMENTED then
				NetworkUtil.writeCompressedPercentages(streamId, self.fermentingPercent)
			end
		end
	end
end

-- Local values: state, fillLevel, compactedFillLevel, fermentingTime, area, offWx, offWz, offW, offHx, offHz, offH, offWScale, offHScale, innerFillLevel1, innerFillLevel2, innerFillLevel, area, area, fermentingFillLevel, fermentingPixels, totalFermentingPixels, _inputFillLevel, inputPixels, totalInputPixels
function BunkerSilo:loadFromXMLFile(xmlFile, key)
	local v92_ = xmlFile:getValue(key .. "#state")
	if v92_ ~= nil and (v92_ >= 0 and v92_ < BunkerSilo.NUM_STATES) then
		self:setState(v92_)
	end
	local v93_ = xmlFile:getValue(key .. "#fillLevel")
	if v93_ ~= nil then
		self.fillLevel = v93_
	end
	local v94_ = xmlFile:getValue(key .. "#compactedFillLevel")
	if v94_ ~= nil then
		local v95_ = self.fillLevel
		self.compactedFillLevel = math.clamp(v94_, 0, v95_)
	end
	local v96_ = MathUtil.getFlooredPercent
	local v97_ = self.compactedFillLevel
	local v98_ = self.fillLevel
	self.compactedPercent = v96_(math.min(v97_, v98_), self.fillLevel)
	local v99_ = xmlFile:getValue(key .. "#fermentingTime")
	if v99_ ~= nil then
		self.fermentingPercent = v99_ / (BunkerSilo.MILLISECONDS_PER_DAY * g_currentMission.environment.daysPerPeriod)
	end
	self.isOpenedAtFront = xmlFile:getValue(key .. "#openedAtFront", false)
	self.isOpenedAtBack = xmlFile:getValue(key .. "#openedAtBack", false)
	if self.isOpenedAtFront then
		self.bunkerSiloArea.offsetFront = self:getBunkerAreaOffset(true, 0, self.outputFillType)
	else
		self.bunkerSiloArea.offsetFront = self:getBunkerAreaOffset(true, 0, self.fermentingFillType)
	end
	if self.isOpenedAtBack then
		self.bunkerSiloArea.offsetBack = self:getBunkerAreaOffset(false, 0, self.outputFillType)
	else
		self.bunkerSiloArea.offsetBack = self:getBunkerAreaOffset(false, 0, self.fermentingFillType)
	end
	if self.fillLevel > 0 and self.state == BunkerSilo.STATE_DRAIN then
		local v100_ = self.bunkerSiloArea
		local v101_ = v100_.wx - v100_.sx
		local v102_ = v100_.wz - v100_.sz
		local v103_ = v101_ * v101_ + v102_ * v102_
		local v104_ = math.sqrt(v103_)
		local v105_ = v100_.hx - v100_.sx
		local v106_ = v100_.hz - v100_.sz
		local v107_ = v105_ * v105_ + v106_ * v106_
		local v108_ = math.sqrt(v107_)
		if v104_ > 0.001 and v108_ > 0.001 then
			local v109_ = 0.9 / v104_
			local v110_ = math.min(0.45, v109_)
			local v111_ = v101_ * v110_
			local v112_ = v102_ * v110_
			local v113_ = 0.9 / v108_
			local v114_ = math.min(0.45, v113_)
			local v115_ = v105_ * v114_
			local v116_ = v106_ * v114_
			if DensityMapHeightUtil.getFillLevelAtArea(self.fermentingFillType, v100_.sx + v111_ + v115_, v100_.sz + v112_ + v116_, v100_.wx - v111_ + v115_, v100_.wz - v112_ + v116_, v100_.hx + v111_ - v115_, v100_.hz + v112_ - v116_) + DensityMapHeightUtil.getFillLevelAtArea(self.outputFillType, v100_.sx + v111_ + v115_, v100_.sz + v112_ + v116_, v100_.wx - v111_ + v115_, v100_.wz - v112_ + v116_, v100_.hx + v111_ - v115_, v100_.hz + v112_ - v116_) < self.emptyThreshold * 0.5 then
				DensityMapHeightUtil.removeFromGroundByArea(v100_.sx, v100_.sz, v100_.wx, v100_.wz, v100_.hx, v100_.hz, self.fermentingFillType)
				DensityMapHeightUtil.removeFromGroundByArea(v100_.sx, v100_.sz, v100_.wx, v100_.wz, v100_.hx, v100_.hz, self.outputFillType)
				self:setState(BunkerSilo.STATE_FILL, false)
			end
		end
		DensityMapHeightUtil.changeFillTypeAtArea(v100_.sx, v100_.sz, v100_.wx, v100_.wz, v100_.hx, v100_.hz, self.inputFillType, self.outputFillType)
	elseif self.fillLevel > 0 and (self.state == BunkerSilo.STATE_CLOSED or self.state == BunkerSilo.STATE_FERMENTED) then
		local v117_ = self.bunkerSiloArea
		DensityMapHeightUtil.changeFillTypeAtArea(v117_.sx, v117_.sz, v117_.wx, v117_.wz, v117_.hx, v117_.hz, self.inputFillType, self.fermentingFillType)
	elseif self.state == BunkerSilo.STATE_FILL then
		local v118_ = self.bunkerSiloArea
		local v119_, v120_, v121_ = DensityMapHeightUtil.getFillLevelAtArea(self.fermentingFillType, v118_.sx, v118_.sz, v118_.wx, v118_.wz, v118_.hx, v118_.hz)
		if self.emptyThreshold < v119_ and 0.5 * v121_ < v120_ then
			local _, v122_, v123_ = DensityMapHeightUtil.getFillLevelAtArea(self.inputFillType, v118_.sx, v118_.sz, v118_.wx, v118_.wz, v118_.hx, v118_.hz)
			if v122_ < 0.1 * v123_ then
				self:setState(BunkerSilo.STATE_FERMENTED, false)
			end
		end
	end
	return true
end

function BunkerSilo:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#state", self.state)
	xmlFile:setValue(key .. "#fillLevel", self.fillLevel)
	xmlFile:setValue(key .. "#compactedFillLevel", self.compactedFillLevel)
	xmlFile:setValue(key .. "#fermentingTime", self.fermentingPercent * BunkerSilo.MILLISECONDS_PER_DAY * g_currentMission.environment.daysPerPeriod)
	xmlFile:setValue(key .. "#openedAtFront", self.isOpenedAtFront)
	xmlFile:setValue(key .. "#openedAtBack", self.isOpenedAtBack)
end

-- Local values: fillTypeIndex, fillTypeName, fillType, vehicle, state, distance, mass, compactingFactor, compactingScale, deltaCompact, wheels, numWheels, wheelsOnSilo, wheelsInAir, _, wheel, compactedFillLevel
function BunkerSilo:update(dt)
	if self:getCanInteract(true) then
		local v128_ = self.inputFillType
		if self.state == BunkerSilo.STATE_CLOSED or (self.state == BunkerSilo.STATE_FERMENTED or self.state == BunkerSilo.STATE_DRAIN) then
			v128_ = self.outputFillType
		end
		local v129_ = g_fillTypeManager:getFillTypeByIndex(v128_)
		local v130_ = v129_ == nil and "" or v129_.title
		g_currentMission:addExtraPrintText(string.format("%s %s: %d", g_i18n:getText("info_fillLevel"), v130_, self.fillLevel))
		if self.state == BunkerSilo.STATE_FILL then
			g_currentMission:addExtraPrintText(string.format("%s %d%%", g_i18n:getText("info_compacting"), self.compactedPercent))
		elseif self.state == BunkerSilo.STATE_CLOSED or self.state == BunkerSilo.STATE_FERMENTED then
			local v131_ = g_currentMission
			local v132_ = string.format
			local v133_ = g_i18n:getText("info_fermenting")
			local v134_ = self.fermentingPercent * 100
			v131_:addExtraPrintText(v132_("%s %d%%", v133_, (math.ceil(v134_))))
		end
	end
	if self.isServer and self.state == BunkerSilo.STATE_FILL then
		for v135_, v136_ in pairs(self.vehiclesInRange) do
			if v136_ and v135_:getIsActive() then
				local v137_ = v135_.lastMovedDistance
				if v137_ > 0 then
					local v138_ = v135_:getTotalMass(false) / BunkerSilo.COMPACTING_BASE_MASS
					local v139_ = 1
					if v135_.getBunkerSiloCompacterScale ~= nil then
						v139_ = v135_:getBunkerSiloCompacterScale() or v139_
					end
					local v140_ = v137_ * (v138_ * v139_) * self.distanceToCompactedFillLevel
					if v135_.getWheels ~= nil then
						local v141_ = v135_:getWheels()
						local v142_ = #v141_
						if v142_ > 0 then
							local v143_ = 0
							local v144_ = 0
							for _, v145_ in ipairs(v141_) do
								if v145_.physics.contact == WheelContactType.GROUND_HEIGHT then
									v143_ = v143_ + 1
								elseif v145_.physics.contact == WheelContactType.NONE then
									v144_ = v144_ + 1
								end
							end
							if v143_ > 0 then
								v140_ = v140_ * ((v143_ + v144_) / v142_)
							else
								v140_ = 0
							end
						else
							v140_ = 0
						end
					end
					if v140_ > 0 then
						local v146_ = self.compactedFillLevel + v140_
						local v147_ = self.fillLevel
						local v148_ = math.min(v146_, v147_)
						if v148_ ~= self.compactedFillLevel then
							self:updateCompacting(v148_)
						end
					end
				end
			end
		end
	end
	if g_currentMission ~= nil and (g_currentMission.bunkerScore ~= nil and g_currentMission.bunkerScore < self.fillLevel) then
		g_currentMission.bunkerScore = self.fillLevel
	end
	self:raiseActive()
end

-- Local values: oldFillLevel
function BunkerSilo:updateTick(dt)
	if self.isServer then
		self.updateTimer = self.updateTimer - dt
		if self.updateTimer <= 0 then
			self.updateTimer = 200 + math.random() * 100
			local v151_ = self.fillLevel
			self:updateFillLevel()
			if v151_ ~= self.fillLevel then
				self:updateCompacting(self.compactedFillLevel)
			end
		end
	end
	if not self.adjustedOpeningLength then
		self.adjustedOpeningLength = true
		local v152_ = self.openingLength
		local v153_ = DensityMapHeightUtil.getDefaultMaxRadius(self.outputFillType) + 1
		self.openingLength = math.max(v152_, v153_)
	end
end

function BunkerSilo:updateCompacting(compactedFillLevel)
	self.compactedFillLevel = compactedFillLevel
	local v156_ = MathUtil.getFlooredPercent
	local v157_ = self.compactedFillLevel
	local v158_ = self.fillLevel
	self.compactedPercent = v156_(math.min(v157_, v158_), self.fillLevel)
	self:raiseDirtyFlags(self.bunkerSiloDirtyFlag)
end

-- Local values: area, fillLevel, fillType, fillLevel1, fillLevel2, fillLevel1, fillLevel2
function BunkerSilo:updateFillLevel()
	local v160_ = self.bunkerSiloArea.inner
	local v161_ = self.fillLevel
	local v162_ = self.inputFillType
	if v162_ ~= FillType.UNKNOWN then
		if self.state == BunkerSilo.STATE_FILL then
			v161_ = DensityMapHeightUtil.getFillLevelAtArea(v162_, v160_.sx, v160_.sz, v160_.wx, v160_.wz, v160_.hx, v160_.hz)
		elseif self.state == BunkerSilo.STATE_CLOSED then
			v161_ = DensityMapHeightUtil.getFillLevelAtArea(self.fermentingFillType, v160_.sx, v160_.sz, v160_.wx, v160_.wz, v160_.hx, v160_.hz)
		elseif self.state == BunkerSilo.STATE_FERMENTED then
			v161_ = DensityMapHeightUtil.getFillLevelAtArea(self.fermentingFillType, v160_.sx, v160_.sz, v160_.wx, v160_.wz, v160_.hx, v160_.hz) + DensityMapHeightUtil.getFillLevelAtArea(self.outputFillType, v160_.sx, v160_.sz, v160_.wx, v160_.wz, v160_.hx, v160_.hz)
		elseif self.state == BunkerSilo.STATE_DRAIN then
			v161_ = DensityMapHeightUtil.getFillLevelAtArea(self.fermentingFillType, v160_.sx, v160_.sz, v160_.wx, v160_.wz, v160_.hx, v160_.hz) + DensityMapHeightUtil.getFillLevelAtArea(self.outputFillType, v160_.sx, v160_.sz, v160_.wx, v160_.wz, v160_.hx, v160_.hz)
			if v161_ < self.emptyThreshold then
				DensityMapHeightUtil.removeFromGroundByArea(v160_.sx, v160_.sz, v160_.wx, v160_.wz, v160_.hx, v160_.hz, self.fermentingFillType)
				DensityMapHeightUtil.removeFromGroundByArea(v160_.sx, v160_.sz, v160_.wx, v160_.wz, v160_.hx, v160_.hz, self.outputFillType)
				self:setState(BunkerSilo.STATE_FILL, true)
			end
		end
	end
	self.fillLevel = v161_
end

-- Local values: area, offsetFront, offsetBack, x0, z0, x1, z1, x2, z2, _changed, fillTypes
function BunkerSilo:setState(state, showNotification)
	if state ~= self.state then
		if state == BunkerSilo.STATE_FILL then
			self.fermentingPercent = 0
			self.compactedFillLevel = 0
			self.compactedPercent = 0
			self.isOpenedAtFront = false
			self.isOpenedAtBack = false
			self.bunkerSiloArea.offsetFront = 0
			self.bunkerSiloArea.offsetBack = 0
			if showNotification then
				self:showBunkerMessage(g_i18n:getText("ingameNotification_bunkerSiloIsEmpty"))
			end
			if self.isServer then
				g_densityMapHeightManager:removeFixedFillTypesArea(self.bunkerSiloArea)
				g_densityMapHeightManager:setConvertingFillTypeAreas(self.bunkerSiloArea, self.acceptedFillTypes, self.inputFillType)
			end
		elseif state == BunkerSilo.STATE_CLOSED then
			local v166_ = self.bunkerSiloArea
			local v167_ = self:getBunkerAreaOffset(true, 0, self.inputFillType)
			local v168_ = self:getBunkerAreaOffset(false, 0, self.inputFillType)
			local v169_ = v166_.sx + v167_ * v166_.dhx_norm
			local v170_ = v166_.sz + v167_ * v166_.dhz_norm
			local v171_ = v169_ + v166_.dwx
			local v172_ = v170_ + v166_.dwz
			local v173_ = v166_.sx + v166_.dhx - v168_ * v166_.dhx_norm
			local v174_ = v166_.sz + v166_.dhz - v168_ * v166_.dhz_norm
			if self.isServer then
				DensityMapHeightUtil.changeFillTypeAtArea(v169_, v170_, v171_, v172_, v173_, v174_, self.inputFillType, self.fermentingFillType)
				g_densityMapHeightManager:removeFixedFillTypesArea(self.bunkerSiloArea)
				g_densityMapHeightManager:removeConvertingFillTypeAreas(self.bunkerSiloArea)
			end
			g_currentMission.tireTrackSystem:eraseParallelogram(v169_, v170_, v171_, v172_, v173_, v174_)
			FSDensityMapUtil.resetDisplacementArea(v169_, v170_, v171_, v172_, v173_, v174_)
			if showNotification then
				self:showBunkerMessage(g_i18n:getText("ingameNotification_bunkerSiloCovered"))
			end
		elseif state == BunkerSilo.STATE_FERMENTED then
			if showNotification then
				self:showBunkerMessage(g_i18n:getText("ingameNotification_bunkerSiloDoneFermenting"))
			end
		elseif state == BunkerSilo.STATE_DRAIN then
			self.bunkerSiloArea.offsetFront = 0
			self.bunkerSiloArea.offsetBack = 0
			if showNotification then
				self:showBunkerMessage(g_i18n:getText("ingameNotification_bunkerSiloOpened"))
			end
			if self.isServer then
				g_densityMapHeightManager:removeConvertingFillTypeAreas(self.bunkerSiloArea)
				local v175_ = {
					[self.outputFillType] = true
				}
				g_densityMapHeightManager:setFixedFillTypesArea(self.bunkerSiloArea, v175_)
			end
		end
		self.state = state
		if self.isServer then
			self:raiseDirtyFlags(self.bunkerSiloDirtyFlag)
		end
	end
end

function BunkerSilo:showBunkerMessage(msg)
	if g_localPlayer.farmId == self:getOwnerFarmId() then
		g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, msg)
	end
end

-- Local values: openAtFront
function BunkerSilo:openSilo(px, py, pz)
	self:setState(BunkerSilo.STATE_DRAIN, true)
	self.bunkerSiloArea.offsetFront = self:getBunkerAreaOffset(true, 0, self.fermentingFillType)
	self.bunkerSiloArea.offsetBack = self:getBunkerAreaOffset(false, 0, self.fermentingFillType)
	if self:getIsCloserToFront(px, py, pz) and not self.isOpenedAtFront then
		self:switchFillTypeAtOffset(true, self.bunkerSiloArea.offsetFront, self.openingLength)
		self.isOpenedAtFront = true
		self:raiseDirtyFlags(self.bunkerSiloDirtyFlag)
	elseif not self.isOpenedAtBack then
		self:switchFillTypeAtOffset(false, self.bunkerSiloArea.offsetBack, self.openingLength)
		self.isOpenedAtBack = true
		self:raiseDirtyFlags(self.bunkerSiloDirtyFlag)
	end
end

-- Local values: area, hx, hz, hl, pos, d1x, d1z, d2x, d2z, a0x, a0z, a1x, a1z, a2x, a2z, fillLevel
function BunkerSilo:getBunkerAreaOffset(updateAtFront, offset, fillType)
	local v186_ = self.bunkerSiloArea
	local v187_ = v186_.dhx_norm
	local v188_ = v186_.dhz_norm
	local v189_ = MathUtil.vector3Length(v186_.dhx, v186_.dhy, v186_.dhz)
	while offset <= v189_ - 1 do
		local v190_
		if updateAtFront then
			v190_ = offset
		else
			v190_ = v189_ - offset - 1
		end
		local v191_ = v190_ * v187_
		local v192_ = v190_ * v188_
		local v193_ = (v190_ + 1) * v187_
		local v194_ = (v190_ + 1) * v188_
		local v195_ = v186_.sx + v191_
		local v196_ = v186_.sz + v192_
		local v197_ = v186_.wx + v191_
		local v198_ = v186_.wz + v192_
		local v199_ = v186_.sx + v193_
		local v200_ = v186_.sz + v194_
		if DensityMapHeightUtil.getFillLevelAtArea(fillType, v195_, v196_, v197_, v198_, v199_, v200_) > 0 then
			return offset
		end
		offset = offset + 1
	end
	local v201_ = v189_ - 1
	return math.max(v201_, 0)
end

-- Local values: fillType, newFillType, a0x, a0z, a1x, a1z, a2x, a2z, area
function BunkerSilo:switchFillTypeAtOffset(switchAtFront, offset, length)
	local v206_ = self.fermentingFillType
	local v207_ = self.outputFillType
	local v208_ = self.bunkerSiloArea
	local v209_, v210_, v211_, v212_, v213_, v214_
	if switchAtFront then
		v209_ = v208_.sx + offset * v208_.dhx_norm
		v210_ = v208_.sz + offset * v208_.dhz_norm
		v211_ = v209_ + v208_.dwx
		v212_ = v210_ + v208_.dwz
		v213_ = v208_.sx + (offset + length) * v208_.dhx_norm
		v214_ = v208_.sz + (offset + length) * v208_.dhz_norm
	else
		v209_ = v208_.hx - offset * v208_.dhx_norm
		v210_ = v208_.hz - offset * v208_.dhz_norm
		v211_ = v209_ + v208_.dwx
		v212_ = v210_ + v208_.dwz
		v213_ = v208_.hx - (offset + length) * v208_.dhx_norm
		v214_ = v208_.hz - (offset + length) * v208_.dhz_norm
	end
	DensityMapHeightUtil.changeFillTypeAtArea(v209_, v210_, v211_, v212_, v213_, v214_, v206_, v207_)
end

-- Local values: area, x, y, z, distFront, distBack
function BunkerSilo:getIsCloserToFront(ix, iy, iz)
	local v219_ = self.bunkerSiloArea
	local v220_ = v219_.sx + 0.5 * v219_.dwx + v219_.offsetFront * v219_.dhx_norm
	local v221_ = v219_.sy + 0.5 * v219_.dwy + v219_.offsetFront * v219_.dhy_norm
	local v222_ = v219_.sz + 0.5 * v219_.dwz + v219_.offsetFront * v219_.dhz_norm
	local v223_ = MathUtil.vector3Length(v220_ - ix, v221_ - iy, v222_ - iz)
	local v224_ = v219_.sx + 0.5 * v219_.dwx + v219_.dhx - v219_.offsetBack * v219_.dhx_norm
	local v225_ = v219_.sy + 0.5 * v219_.dwy + v219_.dhy - v219_.offsetBack * v219_.dhy_norm
	local v226_ = v219_.sz + 0.5 * v219_.dwz + v219_.dhz - v219_.offsetBack * v219_.dhz_norm
	return v223_ < MathUtil.vector3Length(v224_ - ix, v225_ - iy, v226_ - iz)
end

-- Local values: localPlayer, playerVehicle, vehicle
function BunkerSilo:getCanInteract(showInformationOnly)
	local v229_ = g_localPlayer
	if v229_ == nil then
		return false
	end
	if showInformationOnly then
		if not v229_:getIsInVehicle() and self.playerInRange then
			return true
		end
		local v230_ = v229_:getCurrentVehicle()
		if v230_ ~= nil then
			for v231_ in pairs(self.vehiclesInRange) do
				if v231_:getIsActiveForInput(true) and v231_ == v230_ then
					return true
				end
			end
		end
	elseif not v229_:getIsInVehicle() and self.playerInRange then
		return true
	end
	return false
end

function BunkerSilo:getCanCloseSilo()
	local v233_
	if self.state == BunkerSilo.STATE_FILL and self.fillLevel > 0 then
		v233_ = self.compactedPercent >= 100
	else
		v233_ = false
	end
	return v233_
end

-- Local values: ix, iy, iz, closerToFront
function BunkerSilo:getCanOpenSilo()
	if self.state ~= BunkerSilo.STATE_FERMENTED and self.state ~= BunkerSilo.STATE_DRAIN then
		return false
	end
	local v235_, v236_, v237_ = self:getInteractionPosition()
	if v235_ ~= nil then
		local v238_ = self:getIsCloserToFront(v235_, v236_, v237_)
		if v238_ and not self.isOpenedAtFront then
			return true
		end
		if not (v238_ or self.isOpenedAtBack) then
			return true
		end
	end
	return false
end

-- Local values: xs, _, zs, xw, _, zw, xh, _, zh
function BunkerSilo:clearSiloArea()
	local v240_, _, v241_ = getWorldTranslation(self.bunkerSiloArea.start)
	local v242_, _, v243_ = getWorldTranslation(self.bunkerSiloArea.width)
	local v244_, _, v245_ = getWorldTranslation(self.bunkerSiloArea.height)
	DensityMapHeightUtil.clearArea(v240_, v241_, v242_, v243_, v244_, v245_)
end

function BunkerSilo:setWallVisibility(isLeftVisible, isRightVisible)
	if self.wallLeft ~= nil then
		local v249_ = Utils.getNoNil(isLeftVisible, self.wallLeft.visible)
		if self.wallLeft.visible ~= v249_ then
			self.wallLeft.visible = v249_
			setVisibility(self.wallLeft.node, v249_)
			if self.wallLeft.collision ~= nil then
				setRigidBodyType(self.wallLeft.collision, v249_ and RigidBodyType.STATIC or RigidBodyType.NONE)
			end
		end
	end
	if self.wallRight ~= nil then
		local v250_ = Utils.getNoNil(isRightVisible, self.wallRight.visible)
		if self.wallRight.visible ~= v250_ then
			self.wallRight.visible = v250_
			setVisibility(self.wallRight.node, v250_)
			if self.wallRight.collision ~= nil then
				setRigidBodyType(self.wallRight.collision, v250_ and RigidBodyType.STATIC or RigidBodyType.NONE)
			end
		end
	end
end

function BunkerSilo:onHourChanged()
	if self.state == BunkerSilo.STATE_CLOSED and self.isServer then
		local v252_ = self.fermentingPercent + 0.041666666666666664 / g_currentMission.environment.daysPerPeriod
		self.fermentingPercent = math.min(v252_, 1)
		self:raiseDirtyFlags(self.bunkerSiloDirtyFlag)
		if self.fermentingPercent >= 0.999 then
			self:setState(BunkerSilo.STATE_FERMENTED, true)
		end
	end
end

-- Local values: localPlayer, playerVehicle
function BunkerSilo:getInteractionPosition()
	local v254_ = g_localPlayer
	if v254_ == nil then
		return nil
	elseif v254_:getIsInVehicle() or not self.playerInRange then
		local v255_ = v254_:getCurrentVehicle()
		if self.vehiclesInRange[v255_] == nil then
			return nil
		else
			return getWorldTranslation(self.vehiclesInRange[v255_].components[1].node)
		end
	else
		return v254_:getPosition()
	end
end

-- Local values: vehicle
function BunkerSilo:interactionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if onEnter or onLeave then
		if g_localPlayer == nil or otherId ~= g_localPlayer.rootNode then
			local v261_ = g_currentMission:getNodeObject(otherShapeId)
			if v261_ ~= nil and v261_:isa(Vehicle) then
				if onEnter then
					if self.vehiclesInRange[v261_] == nil then
						self.vehiclesInRange[v261_] = true
						self.numVehiclesInRange = self.numVehiclesInRange + 1
						g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
						if v261_.setBunkerSiloInteractorCallback ~= nil then
							v261_:setBunkerSiloInteractorCallback(BunkerSilo.onChangedFillLevelCallback, self)
							return
						end
					end
				elseif self.vehiclesInRange[v261_] then
					self.vehiclesInRange[v261_] = nil
					self.numVehiclesInRange = self.numVehiclesInRange - 1
					if self.numVehiclesInRange == 0 and not self.playerInRange then
						g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
					end
					if v261_.setBunkerSiloInteractorCallback ~= nil then
						v261_:setBunkerSiloInteractorCallback(nil)
					end
				end
			end
		else
			if onEnter then
				self.playerInRange = true
				g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
				return
			end
			self.playerInRange = false
			if self.numVehiclesInRange == 0 then
				g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
				return
			end
		end
	end
end

-- Local values: area, closerToFront, length, p1, offset, targetOffset, p1, offset, targetOffset
function BunkerSilo:onChangedFillLevelCallback(vehicle, fillDelta, fillType, x, y, z)
	if fillDelta < 0 then
		local v268_ = self.bunkerSiloArea
		if x == nil or (y == nil or z == nil) then
			x, y, z = getWorldTranslation(vehicle.components[1].node)
		end
		local v269_ = self:getIsCloserToFront(x, y, z)
		local v270_ = self.openingLength
		if v269_ then
			if self.isOpenedAtFront then
				local v271_ = MathUtil.getProjectOnLineParameter(x, z, v268_.sx, v268_.sz, v268_.dhx_norm, v268_.dhz_norm)
				if v268_.offsetFront - v270_ < v271_ then
					local v272_ = self:getBunkerAreaOffset(true, v268_.offsetFront, self.fermentingFillType)
					local v273_ = math.max(v271_, v272_) + v270_
					self:switchFillTypeAtOffset(true, v268_.offsetFront, v273_ - v268_.offsetFront)
					v268_.offsetFront = v273_
					return
				end
			end
		elseif self.isOpenedAtBack then
			local v274_ = MathUtil.getProjectOnLineParameter(x, z, v268_.hx, v268_.hz, -v268_.dhx_norm, -v268_.dhz_norm)
			if v268_.offsetBack - v270_ < v274_ then
				local v275_ = self:getBunkerAreaOffset(false, v268_.offsetBack, self.fermentingFillType)
				local v276_ = math.max(v274_, v275_) + v270_
				self:switchFillTypeAtOffset(false, v268_.offsetBack, v276_ - v268_.offsetBack)
				v268_.offsetBack = v276_
			end
		end
	end
end

function BunkerSilo.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#startNode", "Area start node (placed in the middle of the walls)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#widthNode", "Area width node (placed in the middle of the walls)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".area#heightNode", "Area height node (placed in the middle of the walls)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".innerArea#startNode", "Inner area start node (Used to detect fill level - placed 25cm from inner walls)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".innerArea#widthNode", "Inner area width node (Used to detect fill level - placed 25cm from inner walls)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".innerArea#heightNode", "Inner area height node (Used to detect fill level - placed 25cm from inner walls)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wallLeft#node", "Left wall node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wallLeft#collision", "Left wall collision")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wallRight#node", "Right wall node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".wallRight#collision", "Right wall collision")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".interactionTrigger#node", "Interaction trigger node")
	schema:register(XMLValueType.STRING, basePath .. "#acceptedFillTypes", "Accepted fill types", "chaff grass_windrow dryGrass_windrow")
	schema:register(XMLValueType.STRING, basePath .. "#inputFillType", "Input fill type", "chaff")
	schema:register(XMLValueType.STRING, basePath .. "#outputFillType", "Output fill type", "silage")
	schema:register(XMLValueType.FLOAT, basePath .. "#distanceToCompactedFillLevel", "Distance to drive on bunker silo for full compaction", 100)
	schema:register(XMLValueType.FLOAT, basePath .. "#openingLength", "Opening length", 5)
end

function BunkerSilo.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#state", "Current silo state (FILL = 0, CLOSED = 1, FERMENTED = 2, DRAIN = 3)", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#fillLevel", "Current fill level")
	schema:register(XMLValueType.FLOAT, basePath .. "#compactedFillLevel", "Compacted fill level")
	schema:register(XMLValueType.FLOAT, basePath .. "#fermentingTime", "Fermenting time")
	schema:register(XMLValueType.BOOL, basePath .. "#openedAtFront", "Is opened at front", false)
	schema:register(XMLValueType.BOOL, basePath .. "#openedAtBack", "Is opened at back", false)
end
BunkerSiloActivatable = {}
local v_u_281_ = Class(BunkerSiloActivatable)
function BunkerSiloActivatable.new(p282_)
	-- upvalues: (copy) v_u_281_
	local v283_ = v_u_281_
	local v284_ = setmetatable({}, v283_)
	v284_.bunkerSilo = p282_
	v284_.activateText = "unknown"
	return v284_
end

function BunkerSiloActivatable:getIsActivatable()
	if not (self.bunkerSilo:getCanInteract() and (self.bunkerSilo:getCanCloseSilo() or self.bunkerSilo:getCanOpenSilo())) then
		return false
	end
	self:updateActivateText()
	return true
end

function BunkerSiloActivatable:getHasAccess(farmId)
	return g_currentMission.accessHandler:canFarmAccessOtherId(farmId, self.bunkerSilo:getOwnerFarmId())
end

-- Local values: text, ix, iy, iz
function BunkerSiloActivatable:run()
	if self.bunkerSilo:getCanCloseSilo() then
		local v289_ = string.namedFormat(g_i18n:getText("ui_doYouWantToCoverTheSilo"), "fillLevel", g_i18n:formatVolume(self.bunkerSilo.fillLevel, 0))
		YesNoDialog.show(function(p290_)
			-- upvalues: (copy) self
			if p290_ then
				if g_server ~= nil then
					self.bunkerSilo:setState(BunkerSilo.STATE_CLOSED, true)
					return
				end
				g_client:getServerConnection():sendEvent(BunkerSiloCloseEvent.new(self.bunkerSilo))
			end
		end, nil, v289_)
	elseif self.bunkerSilo:getCanOpenSilo() then
		local v291_, v292_, v293_ = self.bunkerSilo:getInteractionPosition()
		if v291_ ~= nil then
			if g_server == nil then
				g_client:getServerConnection():sendEvent(BunkerSiloOpenEvent.new(self.bunkerSilo, v291_, v292_, v293_))
			else
				self.bunkerSilo:openSilo(v291_, v292_, v293_)
			end
		end
	end
	self:updateActivateText()
end

function BunkerSiloActivatable:updateActivateText()
	self.activateText = "unknown"
	if self.bunkerSilo.state == BunkerSilo.STATE_FILL then
		self.activateText = g_i18n:getText("action_blanketSilo")
		return
	elseif self.bunkerSilo.state == BunkerSilo.STATE_FERMENTED then
		self.activateText = g_i18n:getText("action_openSilo")
	elseif self.bunkerSilo.state == BunkerSilo.STATE_DRAIN and not (self.bunkerSilo.isOpenedAtFront and self.bunkerSilo.isOpenedAtBack) then
		self.activateText = g_i18n:getText("action_openSilo")
	end
end
