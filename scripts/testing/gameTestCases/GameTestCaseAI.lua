-- Local values: GameTestCaseAI_mt
GameTestCaseAI = {}
local GameTestCaseAI_mt = Class(GameTestCaseAI, GameTestCase)

-- Upvalues: GameTestCaseAI_mt
function GameTestCaseAI.new(customMt)
	-- upvalues: (copy) GameTestCaseAI_mt
	return GameTestCase.new(customMt or GameTestCaseAI_mt)
end

-- Local values: spawnPosition, fieldId, field
function GameTestCaseAI.loadPosition(xmlFile, key)
	local v5_ = {
		["name"] = xmlFile:getString(key .. "#name"),
		["translation"] = xmlFile:getVector(key .. "#translation"),
		["rotation"] = xmlFile:getVector(key .. "#rotation")
	}
	if v5_.name == nil or (v5_.translation == nil or v5_.rotation == nil) then
		return nil
	end
	local v6_ = xmlFile:getInt(key .. "#fieldId")
	if v6_ ~= nil then
		local v7_ = g_fieldManager:getFieldById(v6_)
		if v7_ == nil then
			Logging.xmlWarning(xmlFile, "Failed to load field for spawn position from \'%s\'. Field no longer exists.", key)
			return nil
		end
		v5_.field = v7_
	end
	local v8_ = v5_.rotation
	local v9_ = v5_.rotation[1]
	v8_[1] = math.rad(v9_)
	local v10_ = v5_.rotation
	local v11_ = v5_.rotation[2]
	v10_[2] = math.rad(v11_)
	local v12_ = v5_.rotation
	local v13_ = v5_.rotation[3]
	v12_[3] = math.rad(v13_)
	v5_.index = 1
	return v5_
end

-- Local values: rotation
function GameTestCaseAI.savePosition(spawnPosition, xmlFile, key)
	xmlFile:setString(key .. "#name", spawnPosition.name)
	xmlFile:setVector(key .. "#translation", spawnPosition.translation)
	local v17_ = {}
	local v18_ = spawnPosition.rotation[1]
	v17_[1] = math.deg(v18_)
	local v19_ = spawnPosition.rotation[2]
	v17_[2] = math.deg(v19_)
	local v20_ = spawnPosition.rotation[3]
	v17_[3] = math.deg(v20_)
	xmlFile:setVector(key .. "#rotation", v17_)
	if spawnPosition.field ~= nil then
		xmlFile:setInt(key .. "#fieldId", spawnPosition.field:getId())
	end
end

-- Local values: filename, translation, rotation, k, placeable, x, y, z, rx, ry, rz
function GameTestCaseAI.loadPlaceable(xmlFile, key)
	local v23_ = xmlFile:getString(key .. "#filename")
	if v23_ ~= nil then
		v23_ = NetworkUtil.convertFromNetworkFilename(v23_)
	end
	local v24_ = xmlFile:getVector(key .. "#position")
	local v25_ = xmlFile:getVector(key .. "#rotation")
	for _, v26_ in pairs(g_currentMission.placeableSystem.placeables) do
		if v26_.configFileName == v23_ then
			local v27_, v28_, v29_ = getTranslation(v26_.rootNode)
			local v30_, v31_, v32_ = getRotation(v26_.rootNode)
			local v33_ = v27_ - v24_[1]
			if math.abs(v33_) < 0.1 then
				local v34_ = v28_ - v24_[2]
				if math.abs(v34_) < 0.1 then
					local v35_ = v29_ - v24_[3]
					if math.abs(v35_) < 0.1 then
						local v36_ = v30_ - v25_[1]
						if math.abs(v36_) < 0.1 then
							local v37_ = v31_ - v25_[2]
							if math.abs(v37_) < 0.1 then
								local v38_ = v32_ - v25_[3]
								if math.abs(v38_) < 0.1 then
									return v26_
								end
							end
						end
					end
				end
			end
		end
	end
	Logging.error("Failed to find placeable \'%s\' at \'%.1f %.1f %.1f\'", v23_, v24_[1], v24_[2], v24_[3])
	return nil
end

function GameTestCaseAI.savePlaceable(placeable, xmlFile, key)
	xmlFile:setString(key .. "#filename", NetworkUtil.convertToNetworkFilename(placeable.configFileName))
	xmlFile:setVector(key .. "#position", { getTranslation(placeable.rootNode) })
	xmlFile:setVector(key .. "#rotation", { getRotation(placeable.rootNode) })
end

-- Local values: spawnPositions, useBasePositions, useFieldCenter, useFieldBorder, includeFields, excludeFields, fields, i, field, fieldAllowed, j, j, spawnPosition, posX, posZ, numDimensions, dimWidth, dimStart, dimHeight, sx, _, sz, hx, _, hz, dirX2, dirZ2, yRot
function GameTestCaseAI.loadSpawnPositions(xmlFile, key)
	local v_u_44_ = {}
	local v45_ = xmlFile:getBool(key .. ".spawnPositions#useBasePositions", false) and "testing" or key
	xmlFile:iterate(v45_ .. ".spawnPositions.spawnPosition", function(_, p46_)
		-- upvalues: (copy) xmlFile, (copy) v_u_44_
		local v47_ = GameTestCaseAI.loadPosition(xmlFile, p46_)
		if v47_ == nil then
			Logging.xmlWarning(xmlFile, "Failed to load spawn position from \'%s\'", p46_)
		else
			v47_.index = #v_u_44_ + 1
			local v48_ = v_u_44_
			table.insert(v48_, v47_)
		end
	end)
	local v49_ = xmlFile:getBool(v45_ .. ".spawnPositions#useFieldCenter", false)
	if v49_ or xmlFile:getBool(v45_ .. ".spawnPositions#useFieldBorder", false) then
		local v50_ = xmlFile:getVector(v45_ .. ".spawnPositions#includeFields")
		local v51_ = xmlFile:getVector(v45_ .. ".spawnPositions#excludeFields")
		local v52_ = g_fieldManager:getFields()
		for v53_ = 1, #v52_ do
			local v54_ = v52_[v53_]
			if v54_:getId() ~= nil then
				local v55_ = true
				if v51_ == nil then
					if v50_ ~= nil then
						v55_ = false
						for v56_ = 1, #v50_ do
							if v54_:getId() == v50_[v56_] then
								v55_ = true
								break
							end
						end
					end
				else
					for v57_ = 1, #v51_ do
						if v54_:getId() == v51_[v57_] then
							v55_ = false
							break
						end
					end
				end
				if v55_ then
					local v58_ = {
						["name"] = string.format("Field %d", v54_:getId()),
						["field"] = v54_
					}
					if v49_ then
						local v59_, v60_ = v54_:getCenterOfFieldWorldPosition()
						v58_.translation = { v59_, 0, v60_ }
						v58_.rotation = { 0, math.random() * 3.141592653589793 * 2, 0 }
					elseif getNumOfChildren(v54_.fieldDimensions) > 0 then
						local v61_ = getChildAt(v54_.fieldDimensions, 0)
						local v62_ = getChildAt(v61_, 0)
						local v63_ = getChildAt(v61_, 1)
						if calcDistanceFrom(v62_, v61_) <= calcDistanceFrom(v62_, v63_) then
							v61_ = v63_
						end
						local v64_, _, v65_ = getWorldTranslation(v62_)
						local v66_, _, v67_ = getWorldTranslation(v61_)
						local v68_, v69_ = MathUtil.vector2Normalize(v66_ - v64_, v67_ - v65_)
						v58_.translation = { v64_, 0, v65_ }
						v58_.rotation = { 0, MathUtil.getYRotationFromDirection(v68_, v69_), 0 }
					end
					if v58_.translation ~= nil then
						v58_.index = #v_u_44_ + 1
						table.insert(v_u_44_, v58_)
					end
				end
			end
		end
	end
	return v_u_44_
end

-- Local values: vehicleSetup
function GameTestCaseAI.loadVehicleSetup(xmlFile, key)
	local v_u_72_ = {
		["name"] = xmlFile:getString(key .. "#name"),
		["zOffset"] = xmlFile:getFloat(key .. "#zOffset", 0),
		["vehicles"] = {}
	}
	xmlFile:iterate(key .. ".vehicle", function(_, p73_)
		-- upvalues: (copy) xmlFile, (copy) v_u_72_
		local v74_ = {
			["xmlFilename"] = xmlFile:getString(p73_ .. "#xmlFilename")
		}
		if v74_.xmlFilename ~= nil then
			v74_.xmlFilename = NetworkUtil.convertFromNetworkFilename(v74_.xmlFilename)
			v74_.offset = xmlFile:getVector(p73_ .. "#offset") or { 0, 0, 0 }
			v74_.offset[3] = v74_.offset[3] + v_u_72_.zOffset
			v74_.rotationOffset = xmlFile:getFloat(p73_ .. "#rotationOffset", 0)
			if v74_.xmlFilename:startsWith("$data") then
				v74_.xmlFilename = v74_.xmlFilename:gsub("$data", "data")
			end
			v74_.storeItem = g_storeManager:getItemByXMLFilename(v74_.xmlFilename)
			if v74_.storeItem == nil then
				v_u_72_.isInvalid = true
				Logging.xmlWarning(xmlFile, "Unable to find store item for \'%s\'", v74_.xmlFilename)
				return
			end
			StoreItemUtil.loadSpecsFromXML(v74_.storeItem)
			v74_.fillTypes = FillUnit.getSpecValueFillTypes(v74_.storeItem, nil, nil)
			local v75_ = v_u_72_.vehicles
			table.insert(v75_, v74_)
		end
	end)
	if v_u_72_.isInvalid then
		return nil
	else
		v_u_72_.attachments = {}
		xmlFile:iterate(key .. ".attachment", function(_, p76_)
			-- upvalues: (copy) xmlFile, (copy) v_u_72_
			local v77_ = {
				["rootVehicleId"] = xmlFile:getInt(p76_ .. "#rootVehicleId", 1),
				["attachmentId"] = xmlFile:getInt(p76_ .. "#attachmentId", 2),
				["jointIndex"] = xmlFile:getInt(p76_ .. "#jointIndex", 1),
				["inputAttacherJointIndex"] = xmlFile:getInt(p76_ .. "#inputAttacherJointIndex", 1)
			}
			local v78_ = v_u_72_.attachments
			table.insert(v78_, v77_)
		end)
		v_u_72_.index = 1
		if #v_u_72_.vehicles > 0 then
			return v_u_72_
		else
			return nil
		end
	end
end

-- Local values: index, vehicle, vehicleKey, index, attachment, attachmentKey
function GameTestCaseAI.saveVehicleSetup(vehicleSetup, xmlFile, key)
	xmlFile:setString(key .. "#name", vehicleSetup.name)
	for v82_, v83_ in ipairs(vehicleSetup.vehicles) do
		local v84_ = string.format("%s.vehicle(%d)", key, v82_ - 1)
		xmlFile:setString(v84_ .. "#xmlFilename", NetworkUtil.convertToNetworkFilename(v83_.xmlFilename))
		xmlFile:setVector(v84_ .. "#offset", v83_.offset)
		xmlFile:setFloat(v84_ .. "#rotationOffset", v83_.rotationOffset)
	end
	for v85_, v86_ in ipairs(vehicleSetup.attachments) do
		local v87_ = string.format("%s.attachment(%d)", key, v85_ - 1)
		xmlFile:setInt(v87_ .. "#rootVehicleId", v86_.rootVehicleId)
		xmlFile:setInt(v87_ .. "#attachmentId", v86_.attachmentId)
		xmlFile:setInt(v87_ .. "#jointIndex", v86_.jointIndex)
		xmlFile:setInt(v87_ .. "#inputAttacherJointIndex", v86_.inputAttacherJointIndex)
	end
end

-- Local values: vehicleSetups, categoryNames, numVehicles, availableItems, categories, storeItems, i, storeItem, j, index, storeItem, vehicleSetup, vehicle
function GameTestCaseAI.loadVehicleSetups(xmlFile, key)
	local v_u_90_ = {}
	xmlFile:iterate(key .. ".vehicleSetups.vehicleSetup", function(_, p91_)
		-- upvalues: (copy) xmlFile, (copy) v_u_90_
		local v92_ = GameTestCaseAI.loadVehicleSetup(xmlFile, p91_)
		if v92_ ~= nil then
			v92_.index = #v_u_90_ + 1
			local v93_ = v_u_90_
			table.insert(v93_, v92_)
		end
	end)
	local v94_ = xmlFile:getString(key .. ".vehicleSetups.random#categoryNames")
	if v94_ ~= nil then
		local v95_ = xmlFile:getInt(key .. ".vehicleSetups.random#numVehicles", 1)
		local v96_ = string.upper(v94_):split(" ")
		local v97_ = g_storeManager:getItems()
		local v98_ = {}
		for v99_ = 1, #v97_ do
			local v100_ = v97_[v99_]
			for v101_ = 1, #v96_ do
				if v100_.categoryName == v96_[v101_] then
					table.insert(v98_, v100_)
				end
			end
		end
		while v95_ > 0 do
			v95_ = v95_ - 1
			if #v98_ > 0 then
				local v102_ = math.random(1, #v98_)
				local v103_ = v98_[v102_]
				if v103_ ~= nil and (v103_.showInStore and not v103_.isBundleItem) then
					local v104_ = {
						["name"] = v103_.name,
						["vehicles"] = {},
						["attachments"] = {}
					}
					local v105_ = {
						["xmlFilename"] = v103_.xmlFilename,
						["offset"] = { 0, 0, 0 },
						["rotationOffset"] = 0,
						["fillTypes"] = {},
						["storeItem"] = v103_
					}
					StoreItemUtil.loadSpecsFromXML(v105_.storeItem)
					local v106_ = v104_.vehicles
					table.insert(v106_, v105_)
					v104_.index = #v_u_90_ + 1
					table.insert(v_u_90_, v104_)
				end
				table.remove(v98_, v102_)
			end
		end
	end
	return v_u_90_
end

function GameTestCaseAI.generateTestCases(targetTable, xmlFile, key) end

-- Local values: splines, aiSystem, _, roadSplineOrTG, index, splineId, isTrafficSpline, splineKey, length, posIndex, numPositions, i, posKey, t, unloadingStationIndex, _, unloadingStation, x, _, _, _, unloadTrigger, wx, wy, wz, dx, _, dz, yRot, unloadingStationKey, loadingStationIndex, _, loadingStation, x, _, _, _, loadTrigger, wx, wy, wz, dx, _, dz, yRot, unloadingStationKey
function GameTestCaseAI.fillMetaData(xmlFile, key)
	local v109_ = key .. ".aiSystem"
	local v110_ = g_currentMission.aiSystem
	local v_u_111_ = {}
	for _, v112_ in ipairs(v110_.roadSplines) do
		if I3DUtil.getIsSpline(v112_) then
			v_u_111_[v112_] = false
		end
		I3DUtil.iterateRecursively(v112_, function(p113_)
			-- upvalues: (copy) v_u_111_
			if I3DUtil.getIsSpline(p113_) then
				v_u_111_[p113_] = false
			end
		end)
	end
	if g_currentMission.trafficSystem ~= nil and g_currentMission.trafficSystem.rootNodeId ~= nil then
		I3DUtil.iterateRecursively(g_currentMission.trafficSystem.rootNodeId, function(p114_)
			-- upvalues: (copy) v_u_111_
			if I3DUtil.getIsSpline(p114_) then
				v_u_111_[p114_] = true
			end
		end)
	end
	local v115_ = 0
	for v116_, v117_ in pairs(v_u_111_) do
		local v118_ = string.format("%s.splines.spline(%d)", v109_, v115_)
		local v119_ = getSplineLength(v116_)
		if v119_ > 0 then
			xmlFile:setFloat(v118_ .. "#length", v119_)
			xmlFile:setBool(v118_ .. "#isTrafficSpline", v117_)
			local v120_ = v119_ / 2.5
			local v121_ = 0
			for v122_ = 0, v120_ do
				local v123_ = string.format("%s.pos(%d)", v118_, v121_)
				local v124_ = v122_ / v120_
				local v125_ = math.clamp(v124_, 0, 1)
				xmlFile:setVector(v123_ .. "#translation", { getSplinePosition(v116_, v125_) })
				v121_ = v121_ + 1
			end
			v115_ = v115_ + 1
		end
	end
	local v126_ = 0
	for _, v127_ in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
		if v127_:isa(UnloadingStation) then
			local v128_, _, _, _, v129_ = v127_:getAITargetPositionAndDirection(FillType.UNKNOWN)
			if v128_ ~= nil then
				local v130_, v131_, v132_ = getWorldTranslation(v129_.aiNode)
				local v133_, _, v134_ = localDirectionToWorld(v129_.aiNode, 0, 0, 1)
				local v135_, v136_ = MathUtil.vector2Normalize(v133_, v134_)
				local v137_ = MathUtil.getYRotationFromDirection(v135_, v136_)
				local v138_ = string.format("%s.unloadingStations.unloadingStation(%d)", v109_, v126_)
				xmlFile:setString(v138_ .. "#name", v127_:getName())
				xmlFile:setVector(v138_ .. "#translation", { v130_, v131_, v132_ })
				xmlFile:setFloat(v138_ .. "#rotation", (math.deg(v137_)))
				xmlFile:setString(v138_ .. "#filename", NetworkUtil.convertToNetworkFilename(v127_.owningPlaceable.configFileName))
				v126_ = v126_ + 1
			end
		end
	end
	local v139_ = 0
	for _, v140_ in pairs(g_currentMission.storageSystem:getLoadingStations()) do
		local v141_, _, _, _, v142_ = v140_:getAITargetPositionAndDirection(FillType.UNKNOWN)
		if v141_ ~= nil then
			local v143_, v144_, v145_ = getWorldTranslation(v142_.aiNode)
			local v146_, _, v147_ = localDirectionToWorld(v142_.aiNode, 0, 0, 1)
			local v148_, v149_ = MathUtil.vector2Normalize(v146_, v147_)
			local v150_ = MathUtil.getYRotationFromDirection(v148_, v149_)
			local v151_ = string.format("%s.loadingStations.loadingStation(%d)", v109_, v139_)
			xmlFile:setString(v151_ .. "#name", v140_:getName())
			xmlFile:setVector(v151_ .. "#translation", { v143_, v144_, v145_ })
			xmlFile:setFloat(v151_ .. "#rotation", (math.deg(v150_)))
			xmlFile:setString(v151_ .. "#filename", NetworkUtil.convertToNetworkFilename(v140_.owningPlaceable.configFileName))
			v139_ = v139_ + 1
		end
	end
end
function GameTestCaseAI.overwriteFunctions()
	AISystem.onMissionStarted = Utils.overwrittenFunction(AISystem.onMissionStarted, function(p152_, p153_, p154_)
		p153_(p152_, p154_)
		local v155_ = g_currentMission.aiSystem:getNavigationMapFilename()
		local v156_ = g_gameTestManager.currentTestFolder .. "/" .. v155_
		saveVehicleNavigationCostMapToFile(g_currentMission.aiSystem.navigationMap, v156_)
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
