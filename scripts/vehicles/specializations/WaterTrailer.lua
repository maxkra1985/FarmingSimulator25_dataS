-- Local values: WaterTrailerActivatable_mt
source("dataS/scripts/vehicles/specializations/events/WaterTrailerSetIsFillingEvent.lua")
WaterTrailer = {}

function WaterTrailer.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end
function WaterTrailer.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("WaterTrailer")
	v2_:register(XMLValueType.INT, "vehicle.waterTrailer#fillUnitIndex", "Fill unit index")
	v2_:register(XMLValueType.FLOAT, "vehicle.waterTrailer#fillLitersPerSecond", "Fill liters per second", 500)
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.waterTrailer#fillNode", "Fill node", "Root component")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.waterTrailer.sounds", "refill")
	v2_:setXMLSpecializationType()
end

function WaterTrailer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setIsWaterTrailerFilling", WaterTrailer.setIsWaterTrailerFilling)
end

function WaterTrailer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", WaterTrailer.getDrawFirstFillText)
end

function WaterTrailer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WaterTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", WaterTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", WaterTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", WaterTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WaterTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", WaterTrailer)
end

-- Local values: spec, fillUnitIndex
function WaterTrailer:onLoad(savegame)
	local v7_ = self.spec_waterTrailer
	local v8_ = self.xmlFile:getValue("vehicle.waterTrailer#fillUnitIndex")
	if v8_ ~= nil then
		v7_.fillUnitIndex = v8_
		v7_.fillLitersPerSecond = self.xmlFile:getValue("vehicle.waterTrailer#fillLitersPerSecond", 500)
		v7_.waterFillNode = self.xmlFile:getValue("vehicle.waterTrailer#fillNode", self.components[1].node, self.components, self.i3dMappings)
	end
	v7_.isFilling = false
	v7_.activatable = WaterTrailerActivatable.new(self)
	if self.isClient then
		v7_.samples = {}
		v7_.samples.refill = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.waterTrailer.sounds", "refill", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	self.needWaterInfo = true
end

-- Local values: spec
function WaterTrailer:onDelete()
	local v10_ = self.spec_waterTrailer
	g_currentMission.activatableObjectsSystem:removeActivatable(v10_.activatable)
	g_soundManager:deleteSamples(v10_.samples)
end

-- Local values: isFilling
function WaterTrailer:onReadStream(streamId, connection)
	self:setIsWaterTrailerFilling(streamReadBool(streamId), true)
end

-- Local values: spec
function WaterTrailer:onWriteStream(streamId, connection)
	local v15_ = self.spec_waterTrailer
	streamWriteBool(streamId, v15_.isFilling)
end

-- Local values: spec, _, y, _, isNearWater, delta
function WaterTrailer:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v18_ = self.spec_waterTrailer
	local _, v19_, _ = getWorldTranslation(v18_.waterFillNode)
	local v20_ = v19_ <= self.waterY + 0.2
	if v20_ then
		g_currentMission.activatableObjectsSystem:addActivatable(v18_.activatable)
	else
		g_currentMission.activatableObjectsSystem:removeActivatable(v18_.activatable)
	end
	if self.isServer then
		if v18_.isFilling and not v20_ then
			self:setIsWaterTrailerFilling(false)
		end
		if v18_.isFilling and (self:getFillUnitAllowsFillType(v18_.fillUnitIndex, FillType.WATER) and self:addFillUnitFillLevel(self:getOwnerFarmId(), v18_.fillUnitIndex, v18_.fillLitersPerSecond * dt * 0.001, FillType.WATER, ToolType.TRIGGER, nil) <= 0) then
			self:setIsWaterTrailerFilling(false)
		end
	end
end

-- Local values: spec
function WaterTrailer:setIsWaterTrailerFilling(isFilling, noEventSend)
	local v24_ = self.spec_waterTrailer
	if isFilling ~= v24_.isFilling then
		WaterTrailerSetIsFillingEvent.sendEvent(self, isFilling, noEventSend)
		v24_.isFilling = isFilling
		if self.isClient then
			if isFilling then
				g_soundManager:playSample(v24_.samples.refill)
				return
			end
			g_soundManager:stopSample(v24_.samples.refill)
		end
	end
end

-- Local values: spec
function WaterTrailer:getDrawFirstFillText(superFunc)
	local v27_ = self.spec_waterTrailer
	return self.isClient and (self:getIsActiveForInput() and (self:getIsSelected() and (self:getFillUnitFillLevel(v27_.fillUnitIndex) <= 0 and self:getFillUnitCapacity(v27_.fillUnitIndex) ~= 0))) and true or superFunc(self)
end

-- Local values: spec
function WaterTrailer:onPreDetach(attacherVehicle, implement)
	local v29_ = self.spec_waterTrailer
	g_currentMission.activatableObjectsSystem:removeActivatable(v29_.activatable)
end
WaterTrailerActivatable = {}
local v_u_30_ = Class(WaterTrailerActivatable)

-- Upvalues: WaterTrailerActivatable_mt
-- Local values: self
function WaterTrailerActivatable.new(trailer)
	-- upvalues: (copy) v_u_30_
	local v32_ = v_u_30_
	local v33_ = setmetatable({}, v32_)
	v33_.trailer = trailer
	v33_.activateText = "unknown"
	return v33_
end

-- Local values: fillUnitIndex
function WaterTrailerActivatable:getIsActivatable()
	local v35_ = self.trailer.spec_waterTrailer.fillUnitIndex
	if not self.trailer:getIsActiveForInput(true) or (self.trailer:getFillUnitFillLevel(v35_) >= self.trailer:getFillUnitCapacity(v35_) or not self.trailer:getFillUnitAllowsFillType(v35_, FillType.WATER)) then
		return false
	end
	self:updateActivateText()
	return true
end

function WaterTrailerActivatable:run()
	self.trailer:setIsWaterTrailerFilling(not self.trailer.spec_waterTrailer.isFilling)
	self:updateActivateText()
end

function WaterTrailerActivatable:updateActivateText()
	if self.trailer.spec_waterTrailer.isFilling then
		self.activateText = string.format(g_i18n:getText("action_stopRefillingOBJECT"), self.trailer.typeDesc)
	else
		self.activateText = string.format(g_i18n:getText("action_refillOBJECT"), self.trailer.typeDesc)
	end
end
