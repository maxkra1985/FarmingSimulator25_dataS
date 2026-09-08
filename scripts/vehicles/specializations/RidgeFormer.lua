RidgeFormer = {}
RidgeFormer.AI_REQUIRED_GROUND_TYPES = {
	FieldGroundType.STUBBLE_TILLAGE,
	FieldGroundType.CULTIVATED,
	FieldGroundType.SEEDBED,
	FieldGroundType.PLOWED,
	FieldGroundType.ROLLED_SEEDBED
}
RidgeFormer.CLIENT_DM_UPDATE_RADIUS = 50

function RidgeFormer.prerequisitesPresent(specializations)
	return true
end
function RidgeFormer.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("ridgeFormer", true, true, true)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("RidgeFormer")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.ridgeFormer.sounds", "work")
	v1_:setXMLSpecializationType()
end

function RidgeFormer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processRidgeFormerArea", RidgeFormer.processRidgeFormerArea)
end

function RidgeFormer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", RidgeFormer.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", RidgeFormer.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", RidgeFormer.getWearMultiplier)
end

function RidgeFormer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", RidgeFormer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", RidgeFormer)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", RidgeFormer)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", RidgeFormer)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", RidgeFormer)
end

-- Local values: spec
function RidgeFormer:onLoad(savegame)
	local v6_ = self.spec_ridgeFormer
	v6_.stoneLastState = 0
	v6_.stoneWearMultiplierData = g_currentMission.stoneSystem:getWearMultiplierByType("SOWINGMACHINE")
	if self.addAIGroundTypeRequirements ~= nil then
		self:addAIGroundTypeRequirements(RidgeFormer.AI_REQUIRED_GROUND_TYPES)
	end
	if self.isClient then
		v6_.samples = {}
		v6_.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.ridgeFormer.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v6_.isWorkSamplePlaying = false
	end
end

-- Local values: spec
function RidgeFormer:onDelete()
	local v8_ = self.spec_ridgeFormer
	g_soundManager:deleteSamples(v8_.samples)
end

-- Local values: spec
function RidgeFormer:onDeactivate()
	if self.isClient then
		local v10_ = self.spec_ridgeFormer
		g_soundManager:stopSamples(v10_.samples)
		v10_.isWorkSamplePlaying = false
	end
end

-- Local values: spec
function RidgeFormer:onStartWorkAreaProcessing(dt)
	self.spec_ridgeFormer.isWorking = false
end

-- Local values: spec
function RidgeFormer:onEndWorkAreaProcessing(dt)
	local v13_ = self.spec_ridgeFormer
	if self.isClient then
		if v13_.isWorking then
			if not v13_.isWorkSamplePlaying then
				g_soundManager:playSample(v13_.samples.work)
				v13_.isWorkSamplePlaying = true
				return
			end
		elseif v13_.isWorkSamplePlaying then
			g_soundManager:stopSample(v13_.samples.work)
			v13_.isWorkSamplePlaying = false
		end
	end
end

-- Local values: spec, changedArea, totalArea, sx, _, sz, wx, _, wz, hx, _, hz, dx, _, dz, angleRad, snapAngle, angle
function RidgeFormer:processRidgeFormerArea(workArea, dt)
	local v16_ = self.spec_ridgeFormer
	local v17_ = 0
	local v18_ = 0
	v16_.isWorking = self:getLastSpeed() > 0.5
	if not v16_.isWorking then
		v16_.stoneLastState = 0
		return v17_, v18_
	end
	local v19_, _, v20_ = getWorldTranslation(workArea.start)
	local v21_, _, v22_ = getWorldTranslation(workArea.width)
	local v23_, _, v24_ = getWorldTranslation(workArea.height)
	FSDensityMapUtil.eraseTireTrack(v19_, v20_, v21_, v22_, v23_, v24_)
	if not self.isServer and self.currentUpdateDistance > RidgeFormer.CLIENT_DM_UPDATE_RADIUS then
		return v17_, v18_
	end
	local v25_, _, v26_ = localDirectionToWorld(self.rootNode, 0, 0, 1)
	local v27_ = MathUtil.getYRotationFromDirection(v25_, v26_) / 1.5707963267948966 + 0.5
	local v28_ = math.floor(v27_) * 1.5707963267948966
	local v29_ = FSDensityMapUtil.convertToDensityMapAngle(v28_, g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
	local v30_, v31_ = FSDensityMapUtil.updateRidgeFormerArea(v19_, v20_, v21_, v22_, v23_, v24_, v29_)
	v16_.stoneLastState = FSDensityMapUtil.getStoneArea(v19_, v20_, v21_, v22_, v23_, v24_)
	return v30_, v31_
end

-- Local values: spec
function RidgeFormer:doCheckSpeedLimit(superFunc)
	local v34_ = self.spec_ridgeFormer
	local v35_ = not superFunc(self) and self:getIsImplementChainLowered()
	if v35_ then
		v35_ = v34_.isWorking
	end
	return v35_
end

-- Local values: spec, multiplier
function RidgeFormer:getDirtMultiplier(superFunc)
	local v38_ = self.spec_ridgeFormer
	local v39_ = superFunc(self)
	if self.movingDirection > 0 and v38_.isWorking then
		v39_ = v39_ + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end
	return v39_
end

-- Local values: spec, multiplier, stoneMultiplier
function RidgeFormer:getWearMultiplier(superFunc)
	local v42_ = self.spec_ridgeFormer
	local v43_ = superFunc(self)
	if self.movingDirection > 0 and v42_.isWorking then
		local v44_ = (v42_.stoneLastState == 0 or v42_.stoneWearMultiplierData == nil) and 1 or (v42_.stoneWearMultiplierData[v42_.stoneLastState] or 1)
		v43_ = v43_ + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit * v44_
	end
	return v43_
end
