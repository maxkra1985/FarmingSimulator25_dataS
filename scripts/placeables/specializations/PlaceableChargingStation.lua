PlaceableChargingStation = {}

function PlaceableChargingStation.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(PlaceableBuyingStation, specializations)
end

function PlaceableChargingStation.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "getIsCharging", PlaceableChargingStation.getIsCharging)
	SpecializationUtil.registerFunction(placeableType, "getChargeState", PlaceableChargingStation.getChargeState)
end

function PlaceableChargingStation.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableChargingStation)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableChargingStation)
end

function PlaceableChargingStation.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("BuyingStation")
	BuyingStation.registerXMLPaths(schema, basePath .. ".buyingStation")
	schema:register(XMLValueType.FLOAT, basePath .. ".chargingStation.chargeIndicator#intensity", "Light intensity", 20)
	schema:register(XMLValueType.FLOAT, basePath .. ".chargingStation.chargeIndicator#blinkSpeed", "Blinking speed", 5)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".chargingStation.chargeIndicator#node", "Charge indicator node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".chargingStation.chargeIndicator#light", "Charge indicator light node")
	schema:register(XMLValueType.VECTOR_4, basePath .. ".chargingStation.chargeIndicator#colorFull", "Color while battery is charged", "0 1 0 1")
	schema:register(XMLValueType.VECTOR_4, basePath .. ".chargingStation.chargeIndicator#colorEmpty", "Color while battery is empty", "1 1 0 1")
	schema:register(XMLValueType.FLOAT, basePath .. ".chargingStation#interactionRadius", "While player is in this range the battery state is displayed", 5)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".chargingStation.sounds", "fill")
	schema:setXMLSpecializationType()
end

-- Local values: spec, j, loadTrigger
function PlaceableChargingStation:onLoad(savegame)
	local v7_ = self.spec_chargingStation
	v7_.chargeIndicatorIntensity = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#intensity", 20)
	v7_.chargeIndicatorBlinkSpeed = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#blinkSpeed", 5)
	v7_.chargeIndicatorNode = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#node", nil, self.components, self.i3dMappings)
	if v7_.chargeIndicatorNode ~= nil then
		setShaderParameter(v7_.chargeIndicatorNode, "lightControl", v7_.chargeIndicatorIntensity, 0, 0, 0, false)
		setShaderParameter(v7_.chargeIndicatorNode, "emitColor", 1, 1, 0, 0, false)
	end
	v7_.chargeIndicatorLight = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#light", nil, self.components, self.i3dMappings)
	if v7_.chargeIndicatorLight then
		setLightColor(v7_.chargeIndicatorLight, 0, 0, 0)
	end
	v7_.chargeIndicatorColorFull = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#colorFull", "0 1 0 1", true)
	v7_.chargeIndicatorColorEmpty = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#colorEmpty", "1 1 0 1", true)
	v7_.chargeIndicatorLightColor = v7_.chargeIndicatorColorFull
	v7_.interactionRadius = self.xmlFile:getValue("placeable.chargingStation#interactionRadius", 5)
	v7_.loadTrigger = nil
	v7_.buyingStation = self:getBuyingStation()
	if v7_.buyingStation ~= nil then
		for v8_ = 1, #v7_.buyingStation.loadTriggers do
			local v9_ = v7_.buyingStation.loadTriggers[v8_]
			v7_.loadTrigger = v9_
			v7_.fillSample = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.chargingStation.sounds", "fill", self.baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, nil)
			if v7_.fillSample ~= nil and v9_.samples.load == nil then
				v9_.samples.load = v7_.fillSample
			end
		end
	end
end

-- Local values: spec
function PlaceableChargingStation:getIsCharging()
	local v11_ = self.spec_chargingStation
	if v11_.loadTrigger == nil then
		return false
	else
		return v11_.loadTrigger.isLoading
	end
end

-- Local values: spec, index, vehicle, fillUnitIndex
function PlaceableChargingStation:getChargeState()
	local v13_ = self.spec_chargingStation
	if v13_.loadTrigger ~= nil then
		local v14_ = next(v13_.loadTrigger.fillableObjects)
		if v14_ ~= nil then
			local v15_ = v13_.loadTrigger.fillableObjects[v14_].object
			if v15_.getConsumerFillUnitIndex ~= nil then
				local v16_ = v15_:getConsumerFillUnitIndex(FillType.ELECTRICCHARGE)
				if v16_ ~= nil then
					return v15_:getFillUnitFillLevel(v16_), v15_:getFillUnitCapacity(v16_)
				end
			end
		end
	end
	return 0, 1
end

-- Local values: spec, isActive, color, fillLevel, capacity, blinkSpeed, alpha, blinkFrequency, blinkTimeOffset, _, _, allowDisplay, localPlayer, distance, playerVehicle, _, object, fillLevel, capacity, fillLevelToFill, literPerSecond, seconds, minutes, hours, percentage, chargingInfoText
function PlaceableChargingStation:onUpdate(dt)
	local v18_ = self.spec_chargingStation
	if v18_.loadTrigger ~= nil then
		local v19_ = next(v18_.loadTrigger.fillableObjects) ~= nil
		if v18_.chargeIndicatorNode ~= nil then
			if v19_ then
				local v20_ = v18_.chargeIndicatorColorEmpty
				local v21_, v22_ = self:getChargeState()
				if v21_ / v22_ > 0.95 then
					v20_ = v18_.chargeIndicatorColorFull
				end
				setShaderParameter(v18_.chargeIndicatorNode, "colorScale", v20_[1], v20_[2], v20_[3], v20_[4], false)
				v18_.chargeIndicatorLightColor = v20_
			end
			local v23_ = v18_.loadTrigger.isLoading and (v18_.chargeIndicatorBlinkSpeed or 0) or 0
			setShaderParameter(v18_.chargeIndicatorNode, "blinkSimple", v23_, 0, 0, 0, false)
			setShaderParameter(v18_.chargeIndicatorNode, "lightControl", v19_ and (v18_.chargeIndicatorIntensity or 0) or 0, 0, 0, 0, false)
			if v18_.chargeIndicatorLight ~= nil then
				local v24_
				if v19_ then
					local v25_, v26_, _, _ = getShaderParameter(v18_.chargeIndicatorNode, "blinkSimple")
					local v27_ = v25_ * getShaderTimeSec() + v26_
					local v28_ = math.fmod(v27_, 1) - 0.5
					local v29_ = 4 * math.abs(v28_) - 0.8
					v24_ = math.clamp(v29_, 0, 1)
				else
					v24_ = 0
				end
				setLightColor(v18_.chargeIndicatorLight, v18_.chargeIndicatorLightColor[1] * v24_, v18_.chargeIndicatorLightColor[2] * v24_, v18_.chargeIndicatorLightColor[3] * v24_)
			end
		end
		if v18_.loadTrigger.isLoading then
			local v30_ = false
			local v31_ = g_localPlayer
			if v31_ == nil or v31_:getIsInVehicle() then
				local v32_ = v31_:getCurrentVehicle()
				if v32_ ~= nil then
					for _, v33_ in pairs(v18_.loadTrigger.fillableObjects) do
						if v33_.object == v32_ then
							v30_ = true
						end
					end
				end
			elseif calcDistanceFrom(v31_.rootNode, self.rootNode) < v18_.interactionRadius then
				v30_ = true
			end
			if v30_ then
				local v34_, v35_ = self:getChargeState()
				local v36_ = (v35_ - v34_) / (v18_.loadTrigger.fillLitersPerMS * 1000)
				if v36_ >= 1 then
					local v37_ = v36_ / 60
					local v38_ = math.floor(v37_)
					local v39_ = v38_ / 60
					local v40_ = math.floor(v39_)
					local v41_ = v38_ - v40_ * 60
					local v42_ = v34_ / v35_ * 100
					local v43_ = string.namedFormat(g_i18n:getText("info_chargeTime"), "hours", v40_, "minutes", v41_, "percentage", v42_)
					g_currentMission:addExtraPrintText(v43_)
				end
			end
		end
		if v19_ then
			self:raiseActive()
		end
	end
end
