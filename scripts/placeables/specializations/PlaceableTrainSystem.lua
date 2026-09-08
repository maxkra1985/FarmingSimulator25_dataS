PlaceableTrainSystem = {}
source("dataS/scripts/placeables/specializations/events/PlaceableTrainSystemRentEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableTrainSystemSellEvent.lua")

function PlaceableTrainSystem.prerequisitesPresent(specializations)
	return true
end

function PlaceableTrainSystem.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateRailroadVehiclePositions", PlaceableTrainSystem.updateRailroadVehiclePositions)
	SpecializationUtil.registerFunction(placeableType, "createVehicles", PlaceableTrainSystem.createVehicles)
	SpecializationUtil.registerFunction(placeableType, "railroadVehicleLoaded", PlaceableTrainSystem.railroadVehicleLoaded)
	SpecializationUtil.registerFunction(placeableType, "finalizeTrain", PlaceableTrainSystem.finalizeTrain)
	SpecializationUtil.registerFunction(placeableType, "setIsTrainTabbable", PlaceableTrainSystem.setIsTrainTabbable)
	SpecializationUtil.registerFunction(placeableType, "getIsTrainInDriveableRange", PlaceableTrainSystem.getIsTrainInDriveableRange)
	SpecializationUtil.registerFunction(placeableType, "getSplineTime", PlaceableTrainSystem.getSplineTime)
	SpecializationUtil.registerFunction(placeableType, "setSplineTime", PlaceableTrainSystem.setSplineTime)
	SpecializationUtil.registerFunction(placeableType, "addSplinePositionUpdateListener", PlaceableTrainSystem.addSplinePositionUpdateListener)
	SpecializationUtil.registerFunction(placeableType, "removeSplinePositionUpdateListener", PlaceableTrainSystem.removeSplinePositionUpdateListener)
	SpecializationUtil.registerFunction(placeableType, "updateTrainPositionByLocomotiveSpeed", PlaceableTrainSystem.updateTrainPositionByLocomotiveSpeed)
	SpecializationUtil.registerFunction(placeableType, "updateTrainPositionByLocomotiveSplinePosition", PlaceableTrainSystem.updateTrainPositionByLocomotiveSplinePosition)
	SpecializationUtil.registerFunction(placeableType, "updateTrainLength", PlaceableTrainSystem.updateTrainLength)
	SpecializationUtil.registerFunction(placeableType, "toggleRent", PlaceableTrainSystem.toggleRent)
	SpecializationUtil.registerFunction(placeableType, "getCanBeRented", PlaceableTrainSystem.getCanBeRented)
	SpecializationUtil.registerFunction(placeableType, "rentRailroad", PlaceableTrainSystem.rentRailroad)
	SpecializationUtil.registerFunction(placeableType, "returnRailroad", PlaceableTrainSystem.returnRailroad)
	SpecializationUtil.registerFunction(placeableType, "onDeleteObject", PlaceableTrainSystem.onDeleteObject)
	SpecializationUtil.registerFunction(placeableType, "getIsRented", PlaceableTrainSystem.getIsRented)
	SpecializationUtil.registerFunction(placeableType, "getSplineLength", PlaceableTrainSystem.getSplineLength)
	SpecializationUtil.registerFunction(placeableType, "getElectricitySpline", PlaceableTrainSystem.getElectricitySpline)
	SpecializationUtil.registerFunction(placeableType, "getElectricitySplineLength", PlaceableTrainSystem.getElectricitySplineLength)
	SpecializationUtil.registerFunction(placeableType, "getLengthSplineTime", PlaceableTrainSystem.getLengthSplineTime)
	SpecializationUtil.registerFunction(placeableType, "getSpline", PlaceableTrainSystem.getSpline)
	SpecializationUtil.registerFunction(placeableType, "updateDriveableState", PlaceableTrainSystem.updateDriveableState)
	SpecializationUtil.registerFunction(placeableType, "gsIsTrainFilled", PlaceableTrainSystem.gsIsTrainFilled)
	SpecializationUtil.registerFunction(placeableType, "onSellGoodsQuestion", PlaceableTrainSystem.onSellGoodsQuestion)
	SpecializationUtil.registerFunction(placeableType, "sellGoods", PlaceableTrainSystem.sellGoods)
	SpecializationUtil.registerFunction(placeableType, "getTrainPosition", PlaceableTrainSystem.getTrainPosition)
end

function PlaceableTrainSystem.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedDayChanged", PlaceableTrainSystem.getNeedDayChanged)
end

function PlaceableTrainSystem.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableTrainSystem)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableTrainSystem)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableTrainSystem)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableTrainSystem)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableTrainSystem)
	SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableTrainSystem)
	SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableTrainSystem)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableTrainSystem)
	SpecializationUtil.registerEventListener(placeableType, "onDayChanged", PlaceableTrainSystem)
end

function PlaceableTrainSystem.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Train")
	schema:register(XMLValueType.FLOAT, basePath .. ".trainSystem.rent#pricePerHour", "Rent price per real time hour", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".trainSystem.spline#node", "Spline node")
	schema:register(XMLValueType.FLOAT, basePath .. ".trainSystem.spline#splineYOffset", "Spline Y offset", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".trainSystem.drivingRange#startNode", "Start of range node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".trainSystem.drivingRange#endNode", "End of range node")
	schema:register(XMLValueType.STRING, basePath .. ".trainSystem.drivingRange#sellingStationId", "Unique id of selling station")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".trainSystem.electricitySpline#node", "Electricity spline")
	schema:register(XMLValueType.FLOAT, basePath .. ".trainSystem.electricitySpline#splineYOffset", "Electricity spline Y offset", 0)
	schema:register(XMLValueType.STRING, basePath .. ".trainSystem.train.vehicle(?)#xmlFilename", "XMl filename")
	RailroadCrossing.registerXMLPaths(schema, basePath .. ".trainSystem.railroadCrossings.railroadCrossing(?)")
	RailroadCaller.registerXMLPaths(schema, basePath .. ".trainSystem.railroadCallers.railroadCaller(?)")
	schema:setXMLSpecializationType()
end

function PlaceableTrainSystem.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Train")
	schema:register(XMLValueType.FLOAT, basePath .. "#splineTime", "Current spline time")
	schema:register(XMLValueType.BOOL, basePath .. "#isRented", "Is train rented")
	schema:register(XMLValueType.INT, basePath .. "#rentFarmId", "Train is rented by farm")
	schema:register(XMLValueType.FLOAT, basePath .. "#currentPrice", "Current pending rent price")
	schema:register(XMLValueType.STRING, basePath .. ".railroadVehicle(?)#vehicleUniqueId", "Vehicle unique id")
	schema:register(XMLValueType.INT, basePath .. ".railroadObjects(?)#index", "Object index")
	schema:setXMLSpecializationType()
end

-- Local values: spec, nearestDistanceStart, nearestDistanceEnd, x1, y1, z1, x2, y2, z2, i, sx, sy, sz, distance1, distance2, secondValue, sx, _, sz, esx, _, esz, _, baseString, filename, _, key, railroadCrossing, _, key, railroadCaller, t, x1, y1, z1, _, object, x2, y2, z2, distance
function PlaceableTrainSystem:onLoad(savegame)
	local v9_ = self.spec_trainSystem
	v9_.lastUpdateLoopIndex = -1
	v9_.splineTime = -1
	v9_.splineTimeSent = v9_.splineTime
	v9_.splineEndTime = 0
	v9_.trainLengthSplineTime = 0
	v9_.splinePositionUpdateListener = {}
	v9_.startSplineTime = v9_.startSplineTime or 0
	v9_.railroadVehicles = {}
	v9_.trainLength = 0
	v9_.x = 0
	v9_.y = 0
	v9_.z = 0
	v9_.splinePositionSpeedReal = 0
	v9_.splinePositionSpeed = 0
	v9_.firstUpdate = true
	v9_.dirtyFlag = self:getNextDirtyFlag()
	v9_.stationDirtyFlag = self:getNextDirtyFlag()
	v9_.networkTimeInterpolator = InterpolationTime.new(1.2)
	v9_.networkSplineTimeInterpolator = InterpolatorValue.new(0)
	v9_.isRented = false
	v9_.rentFarmId = FarmManager.SPECTATOR_FARM_ID
	v9_.lastRentFarmId = FarmManager.SPECTATOR_FARM_ID
	v9_.currentPrice = 0
	v9_.rentPricePerHour = self.xmlFile:getValue("placeable.trainSystem.rent#pricePerHour", 0)
	v9_.rentPricePerMS = v9_.rentPricePerHour / 60 / 60 / 1000
	v9_.rootLocomotive = nil
	v9_.spline = self.xmlFile:getValue("placeable.trainSystem.spline#node", nil, self.components, self.i3dMappings)
	if v9_.spline == nil then
		Logging.xmlError(self.xmlFile, "Missing spline node!")
		self:setLoadingState(PlaceableLoadingState.ERROR)
		return
	elseif getHasClassId(getGeometry(v9_.spline), ClassIds.SPLINE) then
		if getIsSplineClosed(v9_.spline) then
			v9_.splineLength = getSplineLength(v9_.spline)
			v9_.splineYOffset = self.xmlFile:getValue("placeable.trainSystem.spline#splineYOffset", 0)
			v9_.splineDriveRange = { 0, 1 }
			v9_.drivingRangeStart = self.xmlFile:getValue("placeable.trainSystem.drivingRange#startNode", nil, self.components, self.i3dMappings)
			v9_.drivingRangeEnd = self.xmlFile:getValue("placeable.trainSystem.drivingRange#endNode", nil, self.components, self.i3dMappings)
			v9_.drivingRangeSellingStationId = self.xmlFile:getValue("placeable.trainSystem.drivingRange#sellingStationId")
			v9_.textDriveInfo = g_i18n:getText("ui_infoTrainDrive")
			v9_.textSellQuestion = g_i18n:getText("ui_questionTrainSellGoods")
			v9_.hasLimitedRange = false
			if v9_.drivingRangeStart ~= nil and v9_.drivingRangeEnd ~= nil then
				local v10_, v11_, v12_ = getWorldTranslation(v9_.drivingRangeStart)
				local v13_, v14_, v15_ = getWorldTranslation(v9_.drivingRangeEnd)
				local v16_ = math.huge
				local v17_ = math.huge
				for v18_ = 0, 1, 0.5 / v9_.splineLength do
					local v19_, v20_, v21_ = getSplinePosition(v9_.spline, v18_)
					local v22_ = MathUtil.vector3Length(v19_ - v10_, v20_ - v11_, v21_ - v12_)
					if v22_ < v17_ then
						v9_.splineDriveRange[1] = v18_
					else
						v22_ = v17_
					end
					local v23_ = MathUtil.vector3Length(v19_ - v13_, v20_ - v14_, v21_ - v15_)
					if v23_ < v16_ then
						v9_.splineDriveRange[2] = v18_
						v17_ = v22_
						v16_ = v23_
					else
						v17_ = v22_
					end
				end
				if v9_.splineDriveRange[1] > v9_.splineDriveRange[2] then
					local v24_ = v9_.splineDriveRange[2]
					v9_.splineDriveRange[2] = v9_.splineDriveRange[1]
					v9_.splineDriveRange[1] = v24_
				end
				v9_.hasLimitedRange = true
			end
			v9_.sellingStationPlaceable = nil
			v9_.sellingStationPlaceableId = nil
			v9_.sellingStation = nil
			v9_.showDialog = 0
			v9_.showDialogDelay = 0
			v9_.lastIsInDriveableRange = true
			v9_.lastSplineTime = 0
			v9_.electricitySpline = self.xmlFile:getValue("placeable.trainSystem.electricitySpline#node", nil, self.components, self.i3dMappings)
			if v9_.electricitySpline ~= nil then
				if getHasClassId(getGeometry(v9_.electricitySpline), ClassIds.SPLINE) then
					if getIsSplineClosed(v9_.electricitySpline) then
						local v25_, _, v26_ = getSplinePosition(v9_.spline, 0)
						local v27_, _, v28_ = getSplinePosition(v9_.spline, 0)
						if MathUtil.vector2Length(v25_ - v27_, v26_ - v28_) < 5 then
							v9_.electricitySplineLength = getSplineLength(v9_.electricitySpline)
							v9_.electricitySplineYOffset = self.xmlFile:getValue("placeable.trainSystem.electricitySpline#splineYOffset", 0)
						else
							Logging.xmlError(self.xmlFile, "Railroad and electricity spline should almost start at the same x and z positions. Ignoring electricity spline!")
							v9_.electricitySpline = nil
						end
					else
						Logging.xmlError(self.xmlFile, "Railroad electricity spline has to be closed. Ignoring electricity spline!")
						v9_.electricitySpline = nil
					end
				else
					Logging.xmlError(self.xmlFile, "Given electricitySpline node is not a spline. Ignoring electricity spline!")
					v9_.electricitySpline = nil
				end
			end
			v9_.vehiclesToLoad = {}
			if self.isServer then
				for _, v29_ in self.xmlFile:iterator("placeable.trainSystem.train.vehicle") do
					local v30_ = self.xmlFile:getValue(v29_ .. "#xmlFilename")
					if v30_ ~= nil then
						local v31_ = v9_.vehiclesToLoad
						table.insert(v31_, v30_)
					end
				end
			end
			v9_.railroadObjects = {}
			v9_.railroadCrossings = {}
			for _, v32_ in self.xmlFile:iterator("placeable.trainSystem.railroadCrossings.railroadCrossing") do
				local v33_ = RailroadCrossing.new(self.isServer, self.isClient, self, self.rootNode)
				if v33_:loadFromXML(self.xmlFile, v32_, self.components, self.i3dMappings) then
					local v34_ = v9_.railroadCrossings
					table.insert(v34_, v33_)
					local v35_ = v9_.railroadObjects
					table.insert(v35_, v33_)
				else
					v33_:delete()
				end
			end
			v9_.railroadCallers = {}
			for _, v36_ in self.xmlFile:iterator("placeable.trainSystem.railroadCallers.railroadCaller") do
				local v37_ = RailroadCaller.new(self.isServer, self.isClient, self, self.rootNode)
				if v37_:loadFromXML(self.xmlFile, v36_, self.components, self.i3dMappings) then
					local v38_ = v9_.railroadCallers
					table.insert(v38_, v37_)
					local v39_ = v9_.railroadObjects
					table.insert(v39_, v37_)
				end
			end
			for v40_ = 0, 1, 0.5 / v9_.splineLength do
				local v41_, v42_, v43_ = getSplinePosition(v9_.spline, v40_)
				for _, v44_ in ipairs(v9_.railroadObjects) do
					local v45_, v46_, v47_ = getWorldTranslation(v44_.rootNode)
					local v48_ = MathUtil.vector3Length(v41_ - v45_, v42_ - v46_, v43_ - v47_)
					if v44_.nearestDistance == nil then
						v44_.nearestDistance = v48_
						v44_.nearestTime = v40_
					elseif v48_ < v44_.nearestDistance then
						v44_.nearestDistance = v48_
						v44_.nearestTime = v40_
					end
				end
			end
			v9_.railroadVehiclesEndTimes = {}
			v9_.railroadVehicleUpdateIndex = 0
			v9_.lastVehicle = nil
			v9_.numVehiclesToLoad = 0
		else
			Logging.xmlError(self.xmlFile, "Train spline is not closed. Open splines are not supported!")
			self:setLoadingState(PlaceableLoadingState.ERROR)
		end
	else
		Logging.xmlError(self.xmlFile, "Given node is not a spline!")
		self:setLoadingState(PlaceableLoadingState.ERROR)
		return
	end
end

-- Local values: spec, _, object, _, vehicle
function PlaceableTrainSystem:onDelete()
	local v50_ = self.spec_trainSystem
	if v50_.railroadObjects ~= nil then
		for _, v51_ in ipairs(v50_.railroadObjects) do
			v51_:delete()
		end
	end
	if v50_.railroadVehicles ~= nil then
		for _, v52_ in ipairs(v50_.railroadVehicles) do
			v52_.trainSystem = nil
		end
	end
	g_currentMission:removeTrainSystem(self)
end

-- Local values: spec, _, railroadCrossing, _, object
function PlaceableTrainSystem:onFinalizePlacement()
	local v54_ = self.spec_trainSystem
	if v54_.railroadCrossings ~= nil then
		for _, v55_ in ipairs(v54_.railroadCrossings) do
			v55_:findBlockingPositions()
		end
	end
	for _, v56_ in ipairs(v54_.railroadObjects) do
		if v56_.setSplineTimeByPosition ~= nil then
			v56_:setSplineTimeByPosition(v56_.nearestTime, v54_.splineLength)
		end
		if v56_.onSplinePositionTimeUpdate ~= nil then
			v56_:onSplinePositionTimeUpdate(v54_.splineTime, v54_.splineEndTime)
		end
	end
	g_currentMission:addTrainSystem(self)
	if g_currentMission.isMissionStarted then
		self:createVehicles()
	else
		g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, PlaceableTrainSystem.createVehicles, self)
	end
end

-- Local values: spec, numVehicles, i, splineTime, _, railroadObject
function PlaceableTrainSystem:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local v60_ = self.spec_trainSystem
		v60_.railroadVehicleIds = {}
		for v61_ = 1, streamReadInt8(streamId) do
			v60_.railroadVehicleIds[v61_] = NetworkUtil.readNodeObjectId(streamId)
		end
		local v62_ = streamReadFloat32(streamId)
		v60_.networkSplineTimeInterpolator:setValue(v62_)
		v60_.networkTimeInterpolator:reset()
		v60_.splineTime = v62_
		for _, v63_ in ipairs(v60_.railroadObjects) do
			if v63_.readStream ~= nil then
				v63_:readStream(streamId, connection)
			end
		end
		v60_.isRented = streamReadBool(streamId)
		v60_.rentFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		v60_.sellingStationPlaceableId = NetworkUtil.readNodeObjectId(streamId)
		self:raiseActive()
	end
end

-- Local values: spec, numVehicles, i, _, railroadObject
function PlaceableTrainSystem:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local v67_ = self.spec_trainSystem
		local v68_ = #v67_.railroadVehicles
		streamWriteInt8(streamId, v68_)
		for v69_ = 1, v68_ do
			NetworkUtil.writeNodeObject(streamId, v67_.railroadVehicles[v69_])
		end
		streamWriteFloat32(streamId, v67_.splineTimeSent)
		for _, v70_ in ipairs(v67_.railroadObjects) do
			if v70_.writeStream ~= nil then
				v70_:writeStream(streamId, connection)
			end
		end
		streamWriteBool(streamId, v67_.isRented)
		streamWriteUIntN(streamId, v67_.rentFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		NetworkUtil.writeNodeObject(streamId, v67_.sellingStationPlaceable)
	end
end

-- Local values: spec, splineTime, _, railroadObject
function PlaceableTrainSystem:onReadUpdateStream(streamId, timestamp, connection)
	local v75_ = self.spec_trainSystem
	if connection:getIsServer() then
		if streamReadBool(streamId) then
			local v76_ = streamReadFloat32(streamId)
			v75_.networkTimeInterpolator:startNewPhaseNetwork()
			v75_.networkSplineTimeInterpolator:setTargetValue(v76_)
			for _, v77_ in ipairs(v75_.railroadObjects) do
				if v77_.readUpdateStream ~= nil then
					v77_:readUpdateStream(streamId, timestamp, connection)
				end
			end
		end
		if streamReadBool(streamId) then
			v75_.sellingStationPlaceableId = NetworkUtil.readNodeObjectId(streamId)
		end
	end
end

-- Local values: spec, _, railroadObject
function PlaceableTrainSystem:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v82_ = self.spec_trainSystem
	if not connection:getIsServer() then
		local v83_ = streamWriteBool
		local v84_ = v82_.dirtyFlag
		if v83_(streamId, bit32.band(dirtyMask, v84_) ~= 0) then
			streamWriteFloat32(streamId, v82_.splineTimeSent)
			for _, v85_ in ipairs(v82_.railroadObjects) do
				if v85_.writeUpdateStream ~= nil then
					v85_:writeUpdateStream(streamId, connection, dirtyMask)
				end
			end
		end
		local v86_ = streamWriteBool
		local v87_ = v82_.stationDirtyFlag
		if v86_(streamId, bit32.band(dirtyMask, v87_) ~= 0) then
			NetworkUtil.writeNodeObject(streamId, v82_.sellingStationPlaceable)
		end
	end
end

-- Local values: spec, _, railroadKey, index, object, _, vehicleKey, vehicleUniqueId
function PlaceableTrainSystem:loadFromXMLFile(xmlFile, key)
	local v91_ = self.spec_trainSystem
	for _, v92_ in xmlFile:iterator(key .. ".railroadObjects") do
		local v93_ = xmlFile:getValue(v92_ .. "#index")
		if v93_ ~= nil then
			local v94_ = v91_.railroadObjects[v93_]
			if v94_ ~= nil then
				v94_:loadFromXMLFile(xmlFile, v92_)
			end
		end
	end
	v91_.isRented = xmlFile:getValue(key .. "#isRented", v91_.isRented)
	v91_.rentFarmId = xmlFile:getValue(key .. "#rentFarmId", v91_.rentFarmId)
	v91_.lastRentFarmId = v91_.rentFarmId
	v91_.currentPrice = xmlFile:getValue(key .. "#currentPrice", v91_.currentPrice)
	v91_.startSplineTime = SplineUtil.getValidSplineTime(xmlFile:getValue(key .. "#splineTime") or 0)
	v91_.vehicleIdsToLoad = {}
	for _, v95_ in xmlFile:iterator(key .. ".railroadVehicle") do
		local v96_ = xmlFile:getValue(v95_ .. "#vehicleUniqueId")
		if v96_ ~= nil then
			local v97_ = v91_.vehicleIdsToLoad
			table.insert(v97_, v96_)
		end
	end
end

-- Local values: spec, k, railroadVehicle, railroadKey, k, railroadObject, railroadKey
function PlaceableTrainSystem:saveToXMLFile(xmlFile, key, usedModNames)
	local v102_ = self.spec_trainSystem
	xmlFile:setValue(key .. "#splineTime", SplineUtil.getValidSplineTime(v102_.splineTime))
	for v103_, v104_ in ipairs(v102_.railroadVehicles) do
		xmlFile:setValue(string.format("%s.railroadVehicle(%d)", key, v103_ - 1) .. "#vehicleUniqueId", v104_:getUniqueId())
	end
	for v105_, v106_ in ipairs(v102_.railroadObjects) do
		local v107_ = string.format("%s.railroadObjects(%d)", key, v105_ - 1)
		if v106_.saveToXMLFile ~= nil then
			xmlFile:setValue(v107_ .. "#index", v105_)
			v106_.saveToXMLFile(xmlFile, v107_, usedModNames)
		end
	end
	xmlFile:setValue(key .. "#isRented", v102_.isRented)
	xmlFile:setValue(key .. "#rentFarmId", v102_.rentFarmId)
	xmlFile:setValue(key .. "#currentPrice", v102_.currentPrice)
end

-- Local values: spec, _, railroadObject, allVehiclesSynchronized, index, id, vehicle, index, id, vehicle, interpolationAlpha, splineTime, placeable, placeable, stationName, textDriveInfo, textSellQuestion
function PlaceableTrainSystem:onUpdate(dt)
	local v110_ = self.spec_trainSystem
	if not self.finishedFirstUpdate then
		local v111_ = v110_.isRented
		if v111_ then
			v111_ = g_currentMission:getFarmId() == v110_.rentFarmId
		end
		self:setIsTrainTabbable(v111_)
		self.finishedFirstUpdate = true
	end
	if self.isClient then
		v110_.splinePositionSpeed = v110_.splinePositionSpeed * 0.975 + v110_.splinePositionSpeedReal * 0.025
	end
	for _, v112_ in ipairs(v110_.railroadObjects) do
		if v112_.update ~= nil then
			v112_:update(dt)
		end
	end
	if v110_.isRented then
		v110_.currentPrice = v110_.currentPrice + v110_.rentPricePerMS * dt
	end
	if not self.isServer and self.isClient then
		if v110_.railroadVehicleIds ~= nil then
			local v113_ = true
			for _, v114_ in pairs(v110_.railroadVehicleIds) do
				local v115_ = NetworkUtil.getObject(v114_)
				if v115_ == nil or not v115_:getIsSynchronized() then
					v113_ = false
				end
			end
			if v113_ then
				v110_.rootLocomotive = nil
				for v116_, v117_ in pairs(v110_.railroadVehicleIds) do
					local v118_ = NetworkUtil.getObject(v117_)
					if v118_ ~= nil then
						v118_:setTrainSystem(self)
						v110_.trainLength = v110_.trainLength + v118_:getFrontToBackDistance()
						v110_.trainLengthSplineTime = v110_.trainLength / v110_.splineLength
						local v119_ = v110_.railroadVehicles
						table.insert(v119_, v116_, v118_)
						if v110_.rootLocomotive == nil and v118_.startAutomatedTrainTravel ~= nil then
							v110_.rootLocomotive = v118_
						end
					end
					v110_.railroadVehicleIds[v116_] = nil
				end
				if next(v110_.railroadVehicleIds) == nil then
					v110_.railroadVehicleIds = nil
					local v120_ = v110_.isRented
					if v120_ then
						v120_ = g_currentMission:getFarmId() == v110_.rentFarmId
					end
					self:setIsTrainTabbable(v120_)
				end
			end
		end
		v110_.networkTimeInterpolator:update(dt)
		local v121_ = v110_.networkTimeInterpolator:getAlpha()
		local v122_ = v110_.networkSplineTimeInterpolator:getInterpolatedValue(v121_)
		self:updateTrainPositionByLocomotiveSplinePosition((SplineUtil.getValidSplineTime(v122_)))
	end
	if v110_.hasLimitedRange then
		if self.isServer and (v110_.sellingStationPlaceable == nil and v110_.drivingRangeSellingStationId ~= nil) then
			local v123_ = g_currentMission.placeableSystem:getPlaceableByUniqueId(v110_.drivingRangeSellingStationId)
			if v123_ == nil then
				Logging.xmlWarning(self.configFileName, "Unable to find selling station placeable with id %q", v110_.drivingRangeSellingStationId)
			elseif v123_.spec_sellingStation ~= nil then
				v110_.sellingStationPlaceable = v123_
				v110_.sellingStation = v123_.spec_sellingStation.sellingStation
				self:raiseDirtyFlags(v110_.stationDirtyFlag)
			end
			v110_.drivingRangeSellingStationId = nil
		end
		if v110_.sellingStationPlaceable == nil and v110_.sellingStationPlaceableId ~= nil then
			local v124_ = NetworkUtil.getObject(v110_.sellingStationPlaceableId)
			if v124_ ~= nil and v124_.spec_sellingStation ~= nil then
				v110_.sellingStationPlaceable = v124_
				v110_.sellingStation = v124_.spec_sellingStation.sellingStation
			end
		end
		if v110_.showDialogDelay > 0 then
			v110_.showDialogDelay = v110_.showDialogDelay - dt
			if v110_.showDialogDelay <= 0 then
				local v125_ = v110_.sellingStationPlaceable == nil and "UNKNOWN" or v110_.sellingStationPlaceable:getName()
				local v126_ = string.format(v110_.textDriveInfo, v125_)
				local v127_ = string.format(v110_.textSellQuestion, v125_)
				if v110_.showDialog == 2 then
					YesNoDialog.show(self.onSellGoodsQuestion, self, v126_ .. "\n\n" .. v127_)
				else
					InfoDialog.show(v126_)
				end
				v110_.showDialog = 0
			end
		end
	end
	self:updateRailroadVehiclePositions(dt)
	self:raiseActive()
end

-- Local values: spec, _, railroadVehicle, locomotiveSpeed, interpDt, maxNumVehicleUpdatesPerFrame, _, railroadVehicle, clipDistance, numUpdates, railroadVehicle, vehicleSplineStartTime, railroadVehiclePredecessor, vehicleSplineEndTime
function PlaceableTrainSystem:updateRailroadVehiclePositions(dt)
	local v129_ = self.spec_trainSystem
	if v129_.lastUpdateLoopIndex < g_updateLoopIndex then
		v129_.lastUpdateLoopIndex = g_updateLoopIndex
		for _, v130_ in pairs(v129_.railroadVehicles) do
			if v130_.getLocomotiveSpeed ~= nil then
				local v131_ = v130_:getLocomotiveSpeed()
				local v132_ = g_physicsDt
				if g_server == nil then
					v132_ = g_physicsDtUnclamped
				end
				if v131_ ~= 0 then
					self:updateTrainPositionByLocomotiveSpeed(v132_, v131_)
				end
			end
		end
		local v133_ = 3
		for _, v134_ in pairs(v129_.railroadVehicles) do
			if getClipDistance(v134_.rootNode) > v134_.currentUpdateDistance then
				v133_ = math.huge
				break
			end
		end
		local v135_ = 0
		while true do
			local v136_ = v129_.railroadVehicles[v129_.railroadVehicleUpdateIndex + 1]
			if v136_ == nil then
				break
			end
			local v137_ = v129_.splineTime
			if v129_.railroadVehicleUpdateIndex > 0 then
				local v138_ = v129_.railroadVehicles[v129_.railroadVehicleUpdateIndex]
				v137_ = v129_.railroadVehiclesEndTimes[v138_]
			end
			local v139_ = v136_:alignToSplineTime(v129_.spline, v129_.splineYOffset, v137_)
			v129_.railroadVehiclesEndTimes[v136_] = v139_
			v129_.railroadVehicleUpdateIndex = (v129_.railroadVehicleUpdateIndex + 1) % #v129_.railroadVehicles
			v135_ = v135_ + 1
			if v135_ == v133_ or v135_ == #v129_.railroadVehicles then
				break
			end
		end
	end
end

-- Local values: spec, k, uniqueId, vehicle, k, filename, arguments, data
function PlaceableTrainSystem:createVehicles()
	local v141_ = self.spec_trainSystem
	if v141_.vehicleIdsToLoad == nil or #v141_.vehicleIdsToLoad <= 0 then
		for v142_, v143_ in ipairs(v141_.vehiclesToLoad) do
			local v144_ = Utils.getFilename(v143_, v141_.baseDirectory)
			v141_.numVehiclesToLoad = v141_.numVehiclesToLoad + 1
			local v145_ = VehicleLoadingData.new()
			v145_:setFilename(v144_)
			v145_:setPropertyState(VehiclePropertyState.NONE)
			v145_:setOwnerFarmId(AccessHandler.EVERYONE)
			v145_:load(v141_.railroadVehicleLoaded, self, {
				["filename"] = v144_,
				["vehicleIndex"] = v142_
			})
		end
	else
		for v146_, v147_ in ipairs(v141_.vehicleIdsToLoad) do
			local v148_ = g_currentMission.vehicleSystem:getVehicleByUniqueId(v147_)
			if v148_ ~= nil then
				if v148_.setTrainSystem ~= nil then
					v148_:setTrainSystem(self)
					v148_.trainVehicleIndex = v146_
					local v149_ = v141_.railroadVehicles
					table.insert(v149_, v148_)
				end
			end
		end
		self:finalizeTrain(false)
	end
	v141_.vehiclesToLoad = {}
end

-- Local values: filename, vehicleIndex, spec, vehicle
function PlaceableTrainSystem:railroadVehicleLoaded(vehicles, vehicleLoadState, args)
	local v154_ = args.filename
	local v155_ = args.vehicleIndex
	local v156_ = self.spec_trainSystem
	if vehicleLoadState == VehicleLoadingState.OK and #vehicles > 0 then
		local v157_ = vehicles[1]
		if not self:getIsBeingDeleted() then
			v157_:setTrainSystem(self)
			v157_.trainVehicleIndex = v155_
		end
		local v158_ = v156_.railroadVehicles
		table.insert(v158_, v157_)
	else
		Logging.warning("(%s) Could not create trainsystem vehicle!", v154_)
	end
	v156_.numVehiclesToLoad = v156_.numVehiclesToLoad - 1
	if v156_.numVehiclesToLoad == 0 and #v156_.vehiclesToLoad == 0 then
		self:finalizeTrain(true)
	end
end

-- Local values: spec, lastVehicle, _, railroadVehicle
function PlaceableTrainSystem:finalizeTrain(attachVehicles)
	if not self:getIsBeingDeleted() then
		local v161_ = self.spec_trainSystem
		table.sort(v161_.railroadVehicles, function(p162_, p163_)
			return p162_.trainVehicleIndex < p163_.trainVehicleIndex
		end)
		v161_.rootLocomotive = nil
		local v164_ = nil
		for _, v165_ in ipairs(v161_.railroadVehicles) do
			if not v165_:getIsBeingDeleted() then
				v165_:addDeleteListener(self)
				if v161_.rootLocomotive == nil and v165_.startAutomatedTrainTravel ~= nil then
					v161_.rootLocomotive = v165_
				end
				if attachVehicles and v164_ ~= nil then
					v164_:attachImplement(v165_, 1, 1, true)
				end
				v164_ = v165_
			end
		end
		self:updateTrainLength(v161_.startSplineTime)
		local v166_ = v161_.isRented
		if v166_ then
			v166_ = g_currentMission:getFarmId() == v161_.rentFarmId
		end
		self:setIsTrainTabbable(v166_)
	end
end

-- Local values: spec, _, railroadVehicle
function PlaceableTrainSystem:setIsTrainTabbable(isTabbable)
	local v169_ = self.spec_trainSystem
	if isTabbable then
		isTabbable = g_gameSettings:getValue(GameSettings.SETTING.IS_TRAIN_TABBABLE)
	end
	if v169_.hasLimitedRange then
		if isTabbable then
			isTabbable = v169_.lastIsInDriveableRange
		end
	end
	for _, v170_ in ipairs(v169_.railroadVehicles) do
		if v170_.setIsTabbable ~= nil then
			v170_:setIsTabbable(isTabbable)
		end
	end
end

function PlaceableTrainSystem:getIsTrainInDriveableRange()
	return self.spec_trainSystem.lastIsInDriveableRange
end

function PlaceableTrainSystem:getSplineTime()
	return self.spec_trainSystem.splineTime
end

-- Local values: spec, _, listener, delta, interpDt, _, railroadVehicle, threshold
function PlaceableTrainSystem:setSplineTime(startTime, endTime)
	local v176_ = self.spec_trainSystem
	local v177_ = SplineUtil.getValidSplineTime(startTime)
	local v178_ = SplineUtil.getValidSplineTime(endTime)
	if v177_ ~= v176_.splineTime then
		if v176_.hasLimitedRange then
			self:updateDriveableState(v177_)
		end
		for _, v179_ in ipairs(v176_.splinePositionUpdateListener) do
			v179_:onSplinePositionTimeUpdate(v177_, v178_)
		end
		local v180_ = v177_ - v176_.splineTime
		v176_.splineTime = v177_
		v176_.splineEndTime = v178_
		local v181_, v182_, v183_ = getSplinePosition(v176_.spline, v176_.splineTime)
		v176_.x = v181_
		v176_.y = v182_
		v176_.z = v183_
		local v184_ = g_physicsDt
		if g_server == nil then
			v184_ = g_physicsDtUnclamped
		end
		v176_.splinePositionSpeedReal = v180_ * v176_.splineLength * (1000 / v184_)
		if self.isServer then
			v176_.splinePositionSpeed = v176_.splinePositionSpeedReal
		end
		if v176_.firstUpdate then
			v176_.splinePositionSpeedReal = 0
			v176_.splinePositionSpeed = 0
			v176_.firstUpdate = false
		end
		for _, v185_ in ipairs(v176_.railroadVehicles) do
			v185_:setSplineSpeed(v176_.splinePositionSpeed, v176_.splinePositionSpeedReal)
		end
		if self.isServer then
			local v186_ = 0.02 / v176_.splineLength
			local v187_ = v176_.splineTime - v176_.splineTimeSent
			if v186_ < math.abs(v187_) then
				v176_.splineTimeSent = v176_.splineTime
				self:raiseDirtyFlags(v176_.dirtyFlag)
			end
		end
	end
end

-- Local values: spec
function PlaceableTrainSystem:getTrainPosition()
	local v189_ = self.spec_trainSystem
	return v189_.x, v189_.y, v189_.z
end

-- Local values: spec
function PlaceableTrainSystem:addSplinePositionUpdateListener(listener)
	if listener ~= nil then
		local v192_ = self.spec_trainSystem
		table.addElement(v192_.splinePositionUpdateListener, listener)
	end
end

-- Local values: spec
function PlaceableTrainSystem:removeSplinePositionUpdateListener(listener)
	if listener ~= nil then
		local v195_ = self.spec_trainSystem
		table.removeElement(v195_.splinePositionUpdateListener, listener)
	end
end

-- Local values: spec, distance, increment, splineTime
function PlaceableTrainSystem:updateTrainPositionByLocomotiveSpeed(dt, speed)
	local v199_ = self.spec_trainSystem
	local v200_ = speed * (dt / 1000) / v199_.splineLength
	local v201_ = self:getSplineTime() + v200_
	self:setSplineTime(v201_, v201_ - v199_.trainLengthSplineTime)
end

-- Local values: spec, splineTime
function PlaceableTrainSystem:updateTrainPositionByLocomotiveSplinePosition(splinePosition)
	self:setSplineTime(splinePosition, splinePosition - self.spec_trainSystem.trainLengthSplineTime)
end

-- Local values: spec, _, railroadVehicle
function PlaceableTrainSystem:updateTrainLength(splinePosition)
	local v206_ = self.spec_trainSystem
	for _, v207_ in ipairs(v206_.railroadVehicles) do
		v206_.trainLength = v206_.trainLength + v207_:getFrontToBackDistance()
	end
	v206_.trainLengthSplineTime = v206_.trainLength / v206_.splineLength
	self:updateTrainPositionByLocomotiveSplinePosition(splinePosition)
end

-- Local values: spec
function PlaceableTrainSystem:toggleRent(farmId, position)
	local v211_ = self.spec_trainSystem
	if v211_.isRented then
		if v211_.rentFarmId == farmId then
			self:returnRailroad()
			return
		end
	else
		self:rentRailroad(farmId, position, false)
	end
end

-- Local values: spec, _, railroadVehicle
function PlaceableTrainSystem:rentRailroad(farmId, position, noEventSend)
	local v216_ = self.spec_trainSystem
	if v216_.rootLocomotive ~= nil then
		v216_.isRented = true
		v216_.rentFarmId = farmId
		v216_.lastRentFarmId = farmId
		v216_.rootLocomotive:setRequestedSplinePosition(position)
		for _, v217_ in ipairs(v216_.railroadVehicles) do
			v217_:setOwnerFarmId(v216_.rentFarmId, true)
		end
		self:setIsTrainTabbable(g_currentMission:getFarmId() == farmId)
		PlaceableTrainSystemRentEvent.sendEvent(self, true, farmId, position, noEventSend)
	end
end

-- Local values: spec, _, railroadVehicle
function PlaceableTrainSystem:returnRailroad(noEventSend)
	local v220_ = self.spec_trainSystem
	v220_.isRented = false
	if self.isServer then
		if v220_.currentPrice > 0 then
			g_currentMission:addMoney(-v220_.currentPrice, v220_.rentFarmId, MoneyType.LEASING_COSTS, true)
			g_currentMission:showMoneyChange(MoneyType.LEASING_COSTS, nil, false, v220_.rentFarmId)
			v220_.currentPrice = 0
		end
		v220_.rootLocomotive:startAutomatedTrainTravel()
	end
	v220_.rentFarmId = FarmManager.SPECTATOR_FARM_ID
	for _, v221_ in ipairs(v220_.railroadVehicles) do
		v221_:setOwnerFarmId(v220_.rentFarmId, true)
	end
	self:setIsTrainTabbable(false)
	PlaceableTrainSystemRentEvent.sendEvent(self, false, nil, nil, noEventSend)
end

-- Local values: spec
function PlaceableTrainSystem:onDayChanged()
	if self.isServer then
		local v223_ = self.spec_trainSystem
		if v223_.currentPrice > 0 then
			g_currentMission:addMoney(-v223_.currentPrice, v223_.rentFarmId, MoneyType.LEASING_COSTS, true)
			g_currentMission:showMoneyChange(MoneyType.LEASING_COSTS, nil, false, v223_.rentFarmId)
			v223_.currentPrice = 0
		end
	end
end

-- Local values: spec
function PlaceableTrainSystem:getIsRented()
	return self.spec_trainSystem.isRented
end

-- Local values: spec
function PlaceableTrainSystem:getCanBeRented(farmId)
	local v227_ = self.spec_trainSystem
	return (not v227_.isRented or v227_.rentFarmId == farmId) and true or false
end

-- Local values: spec
function PlaceableTrainSystem:onDeleteObject(object)
	local v230_ = self.spec_trainSystem
	if table.removeElement(v230_.railroadVehicles, object) then
		self:updateTrainLength(v230_.splineTime)
	end
end

-- Local values: spec
function PlaceableTrainSystem:getSplineLength()
	return self.spec_trainSystem.splineLength
end

-- Local values: spec
function PlaceableTrainSystem:getElectricitySpline()
	return self.spec_trainSystem.electricitySpline
end

-- Local values: spec
function PlaceableTrainSystem:getElectricitySplineLength()
	return self.spec_trainSystem.electricitySplineLength or 0
end

function PlaceableTrainSystem:getNeedDayChanged(superFunc)
	return true
end

-- Local values: spec
function PlaceableTrainSystem:getLengthSplineTime()
	return self.spec_trainSystem.trainLengthSplineTime
end

-- Local values: spec
function PlaceableTrainSystem:getSpline()
	return self.spec_trainSystem.spline
end

-- Local values: spec, isInDriveableRange, _, railroadVehicle, locomotiveSpec, _, railroadVehicle, locomotiveSpec
function PlaceableTrainSystem:updateDriveableState(newSplineTime)
	local v238_ = self.spec_trainSystem
	local v239_
	if newSplineTime % 1 >= v238_.splineDriveRange[1] then
		v239_ = newSplineTime % 1 <= v238_.splineDriveRange[2]
	else
		v239_ = false
	end
	if v239_ ~= v238_.lastIsInDriveableRange then
		v238_.lastIsInDriveableRange = v239_
		if v239_ then
			if self.isServer then
				for _, v240_ in ipairs(v238_.railroadVehicles) do
					local v241_ = v240_.spec_locomotive
					if v241_ ~= nil then
						if v240_:getIsReadyForAutomatedTrainTravel() then
							if v241_.sellingDirection ~= nil and v241_.sellingDirection < 0 then
								v241_.sellingDirection = 1
								v240_:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_INACTIVE)
							end
						elseif v241_.state == Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE then
							v240_:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_INACTIVE)
							v241_.sellingDirection = 1
						end
					end
				end
			end
		else
			for _, v242_ in ipairs(v238_.railroadVehicles) do
				if self.isClient and (v242_.getIsEntered ~= nil and v242_:getIsEntered()) then
					g_localPlayer:leaveVehicle()
					v238_.showDialogDelay = 100
					v238_.showDialog = 1
					if self:gsIsTrainFilled() then
						v238_.showDialog = 2
					end
				end
				if self.isServer then
					local v243_ = v242_.spec_locomotive
					if v243_ ~= nil and (v243_.state ~= Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE and (v243_.state ~= Locomotive.STATE_REQUESTED_POSITION and v243_.state ~= Locomotive.STATE_REQUESTED_POSITION_BRAKING)) then
						v242_:setLocomotiveState(Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE)
						if not self:gsIsTrainFilled() and v238_.isRented then
							self:returnRailroad()
						end
						if v238_.splineTime < newSplineTime then
							v243_.sellingDirection = 1
						else
							v243_.sellingDirection = -1
						end
					end
				end
			end
		end
		local v244_ = v238_.isRented
		if v244_ then
			v244_ = g_currentMission:getFarmId() == v238_.rentFarmId
		end
		self:setIsTrainTabbable(v244_)
	end
end

-- Local values: spec, _, railroadVehicle2, fillUnits, fillUnitIndex, fillUnit
function PlaceableTrainSystem:gsIsTrainFilled()
	local v246_ = self.spec_trainSystem
	for _, v247_ in ipairs(v246_.railroadVehicles) do
		if v247_.getFillUnits ~= nil then
			local v248_ = v247_:getFillUnits()
			for _, v249_ in ipairs(v248_) do
				if v249_.fillLevel > 0 then
					return true
				end
			end
		end
	end
	return false
end

function PlaceableTrainSystem:onSellGoodsQuestion(yes)
	if yes then
		g_client:getServerConnection():sendEvent(PlaceableTrainSystemSellEvent.new(self))
	end
end

-- Local values: spec, soldDelta, _, railroadVehicle, fillUnits, fillUnitIndex, fillUnit, delta
function PlaceableTrainSystem:sellGoods()
	local v253_ = self.spec_trainSystem
	if v253_.sellingStation ~= nil and v253_.rentFarmId ~= 0 then
		local v254_ = 0
		for _, v255_ in ipairs(v253_.railroadVehicles) do
			if v255_.getFillUnits ~= nil then
				local v256_ = v255_:getFillUnits()
				for v257_, v258_ in ipairs(v256_) do
					local v259_ = v253_.sellingStation:addFillLevelFromTool(v253_.rentFarmId, v258_.fillLevel, v258_.fillType, nil, ToolType.UNDEFINED)
					v255_:addFillUnitFillLevel(v255_:getOwnerFarmId(), v257_, -v259_, v258_.fillType, ToolType.UNDEFINED, nil)
					v254_ = v254_ + v259_
				end
			end
		end
		if v254_ > 0 and v253_.isRented then
			self:returnRailroad()
		end
	end
end
