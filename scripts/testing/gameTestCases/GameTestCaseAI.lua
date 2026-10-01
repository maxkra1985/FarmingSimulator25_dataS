GameTestCaseAI = {}
local GameTestCaseAI_mt = Class(GameTestCaseAI, GameTestCase)
function GameTestCaseAI.new(customMt)
	return GameTestCase.new(customMt or GameTestCaseAI_mt)
end
function GameTestCaseAI.loadPosition(xmlFile, key)
	local spawnPosition = {}
	spawnPosition.name = xmlFile:getString(key .. "#name")
	spawnPosition.translation = xmlFile:getVector(key .. "#translation")
	spawnPosition.rotation = xmlFile:getVector(key .. "#rotation")
	if spawnPosition.name ~= nil and (spawnPosition.translation ~= nil and spawnPosition.rotation ~= nil) then
		local fieldId = xmlFile:getInt(key .. "#fieldId")
		if fieldId ~= nil then
			local field = g_fieldManager:getFieldById(fieldId)
			if field ~= nil then
				spawnPosition.field = field
			else
				Logging.xmlWarning(xmlFile, "Failed to load field for spawn position from '%s'. Field no longer exists.", key)
				return nil
			end
		end
		spawnPosition.rotation[1] = math.rad(spawnPosition.rotation[1])
		spawnPosition.rotation[2] = math.rad(spawnPosition.rotation[2])
		spawnPosition.rotation[3] = math.rad(spawnPosition.rotation[3])
		spawnPosition.index = 1
		return spawnPosition
	end
	return nil
end
function GameTestCaseAI.savePosition(spawnPosition, xmlFile, key)
	xmlFile:setString(key .. "#name", spawnPosition.name)
	xmlFile:setVector(key .. "#translation", spawnPosition.translation)
	local rotation = {}
	rotation[1] = math.deg(spawnPosition.rotation[1])
	rotation[2] = math.deg(spawnPosition.rotation[2])
	rotation[3] = math.deg(spawnPosition.rotation[3])
	xmlFile:setVector(key .. "#rotation", rotation)
	if spawnPosition.field ~= nil then
		xmlFile:setInt(key .. "#fieldId", spawnPosition.field:getId())
	end
end
function GameTestCaseAI.loadPlaceable(xmlFile, key)
	local filename = xmlFile:getString(key .. "#filename")
	if filename ~= nil then
		filename = NetworkUtil.convertFromNetworkFilename(filename)
	end
	local translation = xmlFile:getVector(key .. "#position")
	local rotation = xmlFile:getVector(key .. "#rotation")
	for k, placeable in pairs(g_currentMission.placeableSystem.placeables) do
		if placeable.configFileName == filename then
			local x, y, z = getTranslation(placeable.rootNode)
			local rx, ry, rz = getRotation(placeable.rootNode)
			if math.abs(x - translation[1]) < 0.1 and (math.abs(y - translation[2]) < 0.1 and (math.abs(z - translation[3]) < 0.1 and (math.abs(rx - rotation[1]) < 0.1 and (math.abs(ry - rotation[2]) < 0.1 and math.abs(rz - rotation[3]) < 0.1)))) then
				return placeable
			end
		end
	end
	Logging.error("Failed to find placeable '%s' at '%.1f %.1f %.1f'", filename, translation[1], translation[2], translation[3])
	return nil
end
function GameTestCaseAI.savePlaceable(placeable, xmlFile, key)
	xmlFile:setString(key .. "#filename", NetworkUtil.convertToNetworkFilename(placeable.configFileName))
	xmlFile:setVector(key .. "#position", { getTranslation(placeable.rootNode) })
	xmlFile:setVector(key .. "#rotation", { getRotation(placeable.rootNode) })
end
function GameTestCaseAI.loadSpawnPositions(xmlFile, key)
	local spawnPositions = {}
	local useBasePositions = xmlFile:getBool(key .. ".spawnPositions#useBasePositions", false)
	if useBasePositions then
		key = "testing"
	end
	xmlFile:iterate(key .. ".spawnPositions.spawnPosition", function(_, positionKey)
		local spawnPosition = GameTestCaseAI.loadPosition(xmlFile, positionKey)
		if spawnPosition ~= nil then
			spawnPosition.index = #spawnPositions + 1
			table.insert(spawnPositions, spawnPosition)
		else
			Logging.xmlWarning(xmlFile, "Failed to load spawn position from '%s'", positionKey)
		end
	end)
	local useFieldCenter = xmlFile:getBool(key .. ".spawnPositions#useFieldCenter", false)
	local useFieldBorder = xmlFile:getBool(key .. ".spawnPositions#useFieldBorder", false)
	if useFieldCenter or useFieldBorder then
		local includeFields = xmlFile:getVector(key .. ".spawnPositions#includeFields")
		local excludeFields = xmlFile:getVector(key .. ".spawnPositions#excludeFields")
		local fields = g_fieldManager:getFields()
		for i = 1, #fields do
			local field = fields[i]
			if field:getId() == nil then
				continue
			end
			local fieldAllowed = true
			if excludeFields ~= nil then
				for j = 1, #excludeFields do
					if field:getId() == excludeFields[j] then
						fieldAllowed = false
						break
					end
				end
			elseif includeFields ~= nil then
				fieldAllowed = false
				for j = 1, #includeFields do
					if field:getId() == includeFields[j] then
						fieldAllowed = true
						break
					end
				end
			end
			if fieldAllowed then
				local spawnPosition = {}
				spawnPosition.name = string.format("Field %d", field:getId())
				spawnPosition.field = field
				if useFieldCenter then
					local posX, posZ = field:getCenterOfFieldWorldPosition()
					spawnPosition.translation = { posX, 0, posZ }
					spawnPosition.rotation = { 0, math.random() * 3.141592653589793 * 2, 0 }
				else
					local numDimensions = getNumOfChildren(field.fieldDimensions)
					if 0 < numDimensions then
						local dimWidth = getChildAt(field.fieldDimensions, 0)
						local dimStart = getChildAt(dimWidth, 0)
						local dimHeight = getChildAt(dimWidth, 1)
						if calcDistanceFrom(dimStart, dimHeight) < calcDistanceFrom(dimStart, dimWidth) then
							dimHeight = dimWidth
						end
						local sx, _, sz = getWorldTranslation(dimStart)
						local hx, _, hz = getWorldTranslation(dimHeight)
						local dirX2, dirZ2 = MathUtil.vector2Normalize(hx - sx, hz - sz)
						local yRot = MathUtil.getYRotationFromDirection(dirX2, dirZ2)
						spawnPosition.translation = { sx, 0, sz }
						spawnPosition.rotation = { 0, yRot, 0 }
					end
				end
				if spawnPosition.translation == nil then
					continue
				end
				spawnPosition.index = #spawnPositions + 1
				table.insert(spawnPositions, spawnPosition)
			end
		end
	end
	return spawnPositions
end
function GameTestCaseAI.loadVehicleSetup(xmlFile, key)
	local vehicleSetup = {}
	vehicleSetup.name = xmlFile:getString(key .. "#name")
	vehicleSetup.zOffset = xmlFile:getFloat(key .. "#zOffset", 0)
	vehicleSetup.vehicles = {}
	xmlFile:iterate(key .. ".vehicle", function(_, vehicleKey)
		local vehicle = {}
		vehicle.xmlFilename = xmlFile:getString(vehicleKey .. "#xmlFilename")
		if vehicle.xmlFilename ~= nil then
			vehicle.xmlFilename = NetworkUtil.convertFromNetworkFilename(vehicle.xmlFilename)
			vehicle.offset = xmlFile:getVector(vehicleKey .. "#offset") or { 0, 0, 0 }
			vehicle.offset[3] = vehicle.offset[3] + vehicleSetup.zOffset
			vehicle.rotationOffset = xmlFile:getFloat(vehicleKey .. "#rotationOffset", 0)
			if vehicle.xmlFilename:startsWith("$data") then
				vehicle.xmlFilename = vehicle.xmlFilename:gsub("$data", "data")
			end
			vehicle.storeItem = g_storeManager:getItemByXMLFilename(vehicle.xmlFilename)
			if vehicle.storeItem ~= nil then
				StoreItemUtil.loadSpecsFromXML(vehicle.storeItem)
				vehicle.fillTypes = FillUnit.getSpecValueFillTypes(vehicle.storeItem, nil, nil)
				table.insert(vehicleSetup.vehicles, vehicle)
			else
				vehicleSetup.isInvalid = true
				Logging.xmlWarning(xmlFile, "Unable to find store item for '%s'", vehicle.xmlFilename)
			end
		end
	end)
	if vehicleSetup.isInvalid then
		return nil
	end
	vehicleSetup.attachments = {}
	xmlFile:iterate(key .. ".attachment", function(_, attachmentKey)
		local attachment = {}
		attachment.rootVehicleId = xmlFile:getInt(attachmentKey .. "#rootVehicleId", 1)
		attachment.attachmentId = xmlFile:getInt(attachmentKey .. "#attachmentId", 2)
		attachment.jointIndex = xmlFile:getInt(attachmentKey .. "#jointIndex", 1)
		attachment.inputAttacherJointIndex = xmlFile:getInt(attachmentKey .. "#inputAttacherJointIndex", 1)
		table.insert(vehicleSetup.attachments, attachment)
	end)
	vehicleSetup.index = 1
	if 0 < #vehicleSetup.vehicles then
		return vehicleSetup
	else
		return nil
	end
end
function GameTestCaseAI.saveVehicleSetup(vehicleSetup, xmlFile, key)
	xmlFile:setString(key .. "#name", vehicleSetup.name)
	for index, vehicle in ipairs(vehicleSetup.vehicles) do
		local vehicleKey = string.format("%s.vehicle(%d)", key, index - 1)
		xmlFile:setString(vehicleKey .. "#xmlFilename", NetworkUtil.convertToNetworkFilename(vehicle.xmlFilename))
		xmlFile:setVector(vehicleKey .. "#offset", vehicle.offset)
		xmlFile:setFloat(vehicleKey .. "#rotationOffset", vehicle.rotationOffset)
	end
	for index, attachment in ipairs(vehicleSetup.attachments) do
		local attachmentKey = string.format("%s.attachment(%d)", key, index - 1)
		xmlFile:setInt(attachmentKey .. "#rootVehicleId", attachment.rootVehicleId)
		xmlFile:setInt(attachmentKey .. "#attachmentId", attachment.attachmentId)
		xmlFile:setInt(attachmentKey .. "#jointIndex", attachment.jointIndex)
		xmlFile:setInt(attachmentKey .. "#inputAttacherJointIndex", attachment.inputAttacherJointIndex)
	end
end
function GameTestCaseAI.loadVehicleSetups(xmlFile, key)
	local vehicleSetups = {}
	xmlFile:iterate(key .. ".vehicleSetups.vehicleSetup", function(_, setupKey)
		local vehicleSetup = GameTestCaseAI.loadVehicleSetup(xmlFile, setupKey)
		if vehicleSetup ~= nil then
			vehicleSetup.index = #vehicleSetups + 1
			table.insert(vehicleSetups, vehicleSetup)
		end
	end)
	local categoryNames = xmlFile:getString(key .. ".vehicleSetups.random#categoryNames")
	if categoryNames ~= nil then
		local numVehicles = xmlFile:getInt(key .. ".vehicleSetups.random#numVehicles", 1)
		local availableItems = {}
		local categories = string.upper(categoryNames):split(" ")
		local storeItems = g_storeManager:getItems()
		for i = 1, #storeItems do
			local storeItem = storeItems[i]
			for j = 1, #categories do
				if storeItem.categoryName == categories[j] then
					table.insert(availableItems, storeItem)
				end
			end
		end
		while 0 < numVehicles do
			numVehicles = numVehicles - 1
			if 0 < #availableItems then
				local index = math.random(1, #availableItems)
				local storeItem = availableItems[index]
				if storeItem ~= nil and (storeItem.showInStore and not storeItem.isBundleItem) then
					local vehicleSetup = {}
					vehicleSetup.name = storeItem.name
					vehicleSetup.vehicles = {}
					vehicleSetup.attachments = {}
					local vehicle = {}
					vehicle.xmlFilename = storeItem.xmlFilename
					vehicle.offset = { 0, 0, 0 }
					vehicle.rotationOffset = 0
					vehicle.fillTypes = {}
					vehicle.storeItem = storeItem
					StoreItemUtil.loadSpecsFromXML(vehicle.storeItem)
					table.insert(vehicleSetup.vehicles, vehicle)
					vehicleSetup.index = #vehicleSetups + 1
					table.insert(vehicleSetups, vehicleSetup)
				end
				table.remove(availableItems, index)
			end
		end
	end
	return vehicleSetups
end
function GameTestCaseAI.generateTestCases(targetTable, xmlFile, key) end
function GameTestCaseAI.fillMetaData(xmlFile, key)
	key = key .. ".aiSystem"
	local splines = {}
	local aiSystem = g_currentMission.aiSystem
	for _, roadSplineOrTG in ipairs(aiSystem.roadSplines) do
		if I3DUtil.getIsSpline(roadSplineOrTG) then
			splines[roadSplineOrTG] = false
		end
		I3DUtil.iterateRecursively(roadSplineOrTG, function(node)
			if I3DUtil.getIsSpline(node) then
				splines[node] = false
			end
		end)
	end
	if g_currentMission.trafficSystem ~= nil and g_currentMission.trafficSystem.rootNodeId ~= nil then
		I3DUtil.iterateRecursively(g_currentMission.trafficSystem.rootNodeId, function(node)
			if I3DUtil.getIsSpline(node) then
				splines[node] = true
			end
		end)
	end
	local index = 0
	for splineId, isTrafficSpline in pairs(splines) do
		local splineKey = string.format("%s.splines.spline(%d)", key, index)
		local length = getSplineLength(splineId)
		if 0 < length then
			xmlFile:setFloat(splineKey .. "#length", length)
			xmlFile:setBool(splineKey .. "#isTrafficSpline", isTrafficSpline)
			local posIndex = 0
			local numPositions = length / 2.5
			for i = 0, numPositions do
				local posKey = string.format("%s.pos(%d)", splineKey, posIndex)
				local t = math.clamp(i / numPositions, 0, 1)
				xmlFile:setVector(posKey .. "#translation", { getSplinePosition(splineId, t) })
				posIndex = posIndex + 1
			end
			index = index + 1
		end
	end
	local unloadingStationIndex = 0
	for _, unloadingStation in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
		if unloadingStation:isa(UnloadingStation) then
			local x, _, _, _, unloadTrigger = unloadingStation:getAITargetPositionAndDirection(FillType.UNKNOWN)
			if x == nil then
				continue
			end
			local wx, wy, wz = getWorldTranslation(unloadTrigger.aiNode)
			local dx, _, dz = localDirectionToWorld(unloadTrigger.aiNode, 0, 0, 1)
			dx, dz = MathUtil.vector2Normalize(dx, dz)
			local yRot = MathUtil.getYRotationFromDirection(dx, dz)
			local unloadingStationKey = string.format("%s.unloadingStations.unloadingStation(%d)", key, unloadingStationIndex)
			xmlFile:setString(unloadingStationKey .. "#name", unloadingStation:getName())
			xmlFile:setVector(unloadingStationKey .. "#translation", { wx, wy, wz })
			xmlFile:setFloat(unloadingStationKey .. "#rotation", math.deg(yRot))
			xmlFile:setString(unloadingStationKey .. "#filename", NetworkUtil.convertToNetworkFilename(unloadingStation.owningPlaceable.configFileName))
			unloadingStationIndex = unloadingStationIndex + 1
		end
	end
	local loadingStationIndex = 0
	for _, loadingStation in pairs(g_currentMission.storageSystem:getLoadingStations()) do
		local x, _, _, _, loadTrigger = loadingStation:getAITargetPositionAndDirection(FillType.UNKNOWN)
		if x == nil then
			continue
		end
		local wx, wy, wz = getWorldTranslation(loadTrigger.aiNode)
		local dx, _, dz = localDirectionToWorld(loadTrigger.aiNode, 0, 0, 1)
		dx, dz = MathUtil.vector2Normalize(dx, dz)
		local yRot = MathUtil.getYRotationFromDirection(dx, dz)
		local unloadingStationKey = string.format("%s.loadingStations.loadingStation(%d)", key, loadingStationIndex)
		xmlFile:setString(unloadingStationKey .. "#name", loadingStation:getName())
		xmlFile:setVector(unloadingStationKey .. "#translation", { wx, wy, wz })
		xmlFile:setFloat(unloadingStationKey .. "#rotation", math.deg(yRot))
		xmlFile:setString(unloadingStationKey .. "#filename", NetworkUtil.convertToNetworkFilename(loadingStation.owningPlaceable.configFileName))
		loadingStationIndex = loadingStationIndex + 1
	end
end
function GameTestCaseAI.overwriteFunctions()
	AISystem.onMissionStarted = Utils.overwrittenFunction(AISystem.onMissionStarted, function(superFunc, isNewSavegame)
		superFunc(self, isNewSavegame)
		local filename = g_currentMission.aiSystem:getNavigationMapFilename()
		local path = g_gameTestManager.currentTestFolder .. "/" .. filename
		saveVehicleNavigationCostMapToFile(g_currentMission.aiSystem.navigationMap, path)
	end)
end
function GameTestCaseAI.registerXMLPaths(schema, baseKey)
	schema:register(XMLValueType.BOOL, baseKey .. ".spawnPositions#useFieldCenter", "All field center positions will be added as spawn position", false)
	schema:register(XMLValueType.VECTOR_N, baseKey .. ".spawnPositions#includeFields", "If defined, they are the only fields used")
	schema:register(XMLValueType.VECTOR_N, baseKey .. ".spawnPositions#execludeFields", "Indices of fields to execluded")
	schema:register(XMLValueType.STRING, baseKey .. ".spawnPositions.spawnPosition(?)#name", "Custom name of the spawn position")
	schema:register(XMLValueType.VECTOR_TRANS, baseKey .. ".spawnPositions.spawnPosition(?)#translation", "World translation of the spawn position")
	schema:register(XMLValueType.VECTOR_ROT, baseKey .. ".spawnPositions.spawnPosition(?)#rotation", "World rotation of the spawn position")
	schema:register(XMLValueType.STRING, baseKey .. ".vehicleSetups.random#categoryNames", "Random vehicles of the listed categories will be spawned as single vehicle setup")
	schema:register(XMLValueType.INT, baseKey .. ".vehicleSetups.random#numVehicles", "Num. of total vehicles to spawn", 1)
	schema:register(XMLValueType.STRING, baseKey .. ".vehicleSetups.vehicleSetup(?)#name", "Custom name of the vehicle setup")
	schema:register(XMLValueType.STRING, baseKey .. ".vehicleSetups.vehicleSetup(?).vehicle(?)#xmlFilename", "Path to vehicle xml file")
	schema:register(XMLValueType.VECTOR_TRANS, baseKey .. ".vehicleSetups.vehicleSetup(?).vehicle(?)#offset", "Spawn offset from spawn position")
	schema:register(XMLValueType.ANGLE, baseKey .. ".vehicleSetups.vehicleSetup(?).vehicle(?)#rotationOffset", "Spawn Y rotation offset from spawn position", 0)
	schema:register(XMLValueType.INT, baseKey .. ".vehicleSetups.vehicleSetup(?).attachment(?)#rootVehicleId", "Index of root vehicle (as it is defined in the xml)", 1)
	schema:register(XMLValueType.INT, baseKey .. ".vehicleSetups.vehicleSetup(?).attachment(?)#attachmentId", "Index of attachment vehicle (as it is defined in the xml)", 2)
	schema:register(XMLValueType.INT, baseKey .. ".vehicleSetups.vehicleSetup(?).attachment(?)#jointIndex", "Index of the attacher joint on the root vehicle", 1)
	schema:register(XMLValueType.INT, baseKey .. ".vehicleSetups.vehicleSetup(?).attachment(?)#inputAttacherJointIndex", "Index of the input attacher joint on the attachment vehicle", 1)
end
GameTestManager.registerTestCase(GameTestCaseAI)
