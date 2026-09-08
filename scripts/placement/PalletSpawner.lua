-- Local values: PalletSpawner_mt
PalletSpawner = {}
PalletSpawner.RESULT_NO_SPACE = 0
PalletSpawner.RESULT_SUCCESS = 1
PalletSpawner.RESULT_ERROR_LOADING_PALLET = 2
PalletSpawner.PALLET_ALREADY_PRESENT = 3
PalletSpawner.NO_PALLET_FOR_FILLTYPE = 4
PalletSpawner.PALLET_LIMITED_REACHED = 5
local PalletSpawner_mt = Class(PalletSpawner)

-- Upvalues: PalletSpawner_mt
-- Local values: self
function PalletSpawner.new(baseDirectory, customMt)
	-- upvalues: (copy) PalletSpawner_mt
	local v4_ = customMt or PalletSpawner_mt
	local v5_ = setmetatable({}, v4_)
	v5_.baseDirectory = baseDirectory
	v5_.spawnQueue = {}
	v5_.currentObjectToSpawn = nil
	v5_.spawnOffsetY = Platform.gameplay.hasDynamicPallets and 0.2 or 0
	return v5_
end

-- Local values: hasFillTypeSpawnPlaces, _, spawnPlaceKey, spawnPlace, fillTypes, fillTypeCategories, fillTypeNames, _, fillType, fillTypeId, fillType, _, palletKey, palletFilename
function PalletSpawner:load(components, xmlFile, key, customEnv, i3dMappings)
	self.spawnPlaces = {}
	self.fillTypeToSpawnPlaces = {}
	local v11_ = false
	for _, v12_ in xmlFile:iterator(key .. ".spawnPlaces.spawnPlace") do
		local v13_ = PlacementUtil.loadPlaceFromXML(xmlFile, v12_, components, i3dMappings)
		local v14_ = nil
		local v15_ = xmlFile:getValue(v12_ .. "#fillTypeCategories")
		local v16_ = xmlFile:getValue(v12_ .. "#fillTypes")
		if v15_ == nil or v16_ ~= nil then
			if v15_ == nil and v16_ ~= nil then
				v14_ = g_fillTypeManager:getFillTypesByNames(v16_, "Warning: Palletspawner \'" .. xmlFile:getFilename() .. "\' has invalid fillType \'%s\'.")
			end
		else
			v14_ = g_fillTypeManager:getFillTypesByCategoryNames(v15_, "Warning: Palletspawner \'" .. xmlFile:getFilename() .. "\' has invalid fillTypeCategory \'%s\'.")
		end
		if v14_ == nil then
			local v17_ = self.spawnPlaces
			table.insert(v17_, v13_)
		else
			v11_ = true
			for _, v18_ in ipairs(v14_) do
				if self.fillTypeToSpawnPlaces[v18_] == nil then
					self.fillTypeToSpawnPlaces[v18_] = {}
				end
				local v19_ = self.fillTypeToSpawnPlaces[v18_]
				table.insert(v19_, v13_)
			end
		end
	end
	if #self.spawnPlaces == 0 and not v11_ then
		Logging.xmlError(xmlFile, "No spawn place(s) defined for pallet spawner %s%s", key, ".spawnPlaces")
		return false
	end
	self.pallets = {}
	self.fillTypeIdToPallet = {}
	for v20_, v21_ in pairs(g_fillTypeManager.indexToFillType) do
		if v21_.palletFilename then
			self:loadPalletFromFilename(v21_.palletFilename, v20_)
		end
	end
	for _, v22_ in xmlFile:iterator(key .. ".pallets.pallet") do
		self:loadPalletFromFilename((Utils.getFilename(xmlFile:getValue(v22_ .. "#filename"), self.baseDirectory)))
	end
	return true
end

function PalletSpawner:delete() end

-- Local values: pallet, palletXmlFile, fillTypeNamesAndCategories, fillTypes, hadMatchingFillType, _, fillTypeId
function PalletSpawner:loadPalletFromFilename(palletFilename, limitFillTypeId)
	if palletFilename ~= nil then
		local v26_ = {
			["filename"] = palletFilename,
			["size"] = StoreItemUtil.getSizeValues(palletFilename, "vehicle", 0, {})
		}
		local v27_ = XMLFile.load("palletXmlFilename", palletFilename, Vehicle.xmlSchema)
		if v27_ == nil then
			return nil
		end
		local v28_ = FillUnit.getFillTypeNamesFromXML(v27_)
		v26_.capacity = FillUnit.getCapacityFromXml(v27_)
		v27_:delete()
		local v29_ = g_fillTypeManager:getFillTypesByCategoryNames(v28_.fillTypeCategoryNames, nil, {})
		local v30_ = g_fillTypeManager:getFillTypesByNames(v28_.fillTypeNames, nil, v29_)
		local v31_ = false
		for _, v32_ in ipairs(v30_) do
			if limitFillTypeId == nil or limitFillTypeId == v32_ then
				self.fillTypeIdToPallet[v32_] = v26_
				v31_ = true
			end
		end
		if v31_ then
			local v33_ = self.pallets
			table.insert(v33_, v26_)
			return v26_
		end
	end
	return nil
end

function PalletSpawner:getSupportedFillTypes()
	return self.fillTypeIdToPallet
end

-- Local values: pallet
function PalletSpawner:spawnPallet(farmId, fillTypeId, callback, callbackTarget)
	if g_currentMission.slotSystem:getCanAddLimitedObjects(SlotSystem.LIMITED_OBJECT_PALLET, 1) then
		local v40_ = self.fillTypeIdToPallet[fillTypeId]
		if v40_ == nil then
			Logging.devError("PalletSpawner: no pallet for fillTypeId \'%s\'", fillTypeId)
			callback(callbackTarget, nil, PalletSpawner.NO_PALLET_FOR_FILLTYPE, fillTypeId)
		else
			local v41_ = self.spawnQueue
			table.insert(v41_, {
				["pallet"] = v40_,
				["fillType"] = fillTypeId,
				["farmId"] = farmId,
				["callback"] = callback,
				["callbackTarget"] = callbackTarget
			})
			g_currentMission:addUpdateable(self)
		end
	else
		callback(callbackTarget, nil, PalletSpawner.PALLET_LIMITED_REACHED, fillTypeId)
		return
	end
end

-- Local values: spawnPlaces, i, place, x, y, z
function PalletSpawner:getOrSpawnPallet(farmId, fillTypeId, callback, callbackTarget)
	self.foundExistingPallet = nil
	self.getOrSpawnPalletFilltype = fillTypeId
	local v47_ = self.fillTypeToSpawnPlaces[fillTypeId] or self.spawnPlaces
	for v48_ = 1, #v47_ do
		local v49_ = v47_[v48_]
		local v50_ = v49_.startX + v49_.width / 2 * v49_.dirX
		local v51_ = v49_.startY + v49_.width / 2 * v49_.dirY
		local v52_ = v49_.startZ + v49_.width / 2 * v49_.dirZ
		overlapBox(v50_, v51_, v52_, v49_.rotX, v49_.rotY, v49_.rotZ, v49_.width / 2, 1, 1, "onFindExistingPallet", self, CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT, true, true, false, true)
	end
	if self.foundExistingPallet == nil then
		self:spawnPallet(farmId, fillTypeId, callback, callbackTarget)
	else
		callback(callbackTarget, self.foundExistingPallet, PalletSpawner.PALLET_ALREADY_PRESENT, fillTypeId)
	end
end

-- Local values: spawnPlaces, i, place, x, y, z
function PalletSpawner:getAllPallets(fillTypeId, callbackFunc, callbackTarget)
	self.getAllPalletsFoundPallets = {}
	self.getAllPalletsFilltype = fillTypeId
	local v57_ = self.fillTypeToSpawnPlaces[fillTypeId] or self.spawnPlaces
	for v58_ = 1, #v57_ do
		local v59_ = v57_[v58_]
		local v60_ = v59_.startX + v59_.width / 2 * v59_.dirX
		local v61_ = v59_.startY + v59_.width / 2 * v59_.dirY
		local v62_ = v59_.startZ + v59_.width / 2 * v59_.dirZ
		overlapBox(v60_, v61_, v62_, v59_.rotX, v59_.rotY, v59_.rotZ, v59_.width / 2, 1, 1, "onFindPallet", self, CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT, true, true, false, true)
	end
	callbackFunc(callbackTarget, table.toList(self.getAllPalletsFoundPallets), fillTypeId)
end

-- Local values: spawnPlaces
function PalletSpawner:update(dt)
	if #self.spawnQueue > 0 then
		if self.currentObjectToSpawn == nil then
			self.currentObjectToSpawn = self.spawnQueue[1]
			local v64_ = self.fillTypeToSpawnPlaces[self.currentObjectToSpawn.fillType] or self.spawnPlaces
			g_currentMission.placementManager:getPlaceAsync(v64_, self.currentObjectToSpawn.pallet.size, self.onSpawnSearchFinished, self, nil, self.spawnOffsetY, nil, nil)
			return
		end
	else
		g_currentMission:removeUpdateable(self)
	end
end

-- Local values: objectToSpawn, terrainHeight, data
function PalletSpawner:onSpawnSearchFinished(location)
	local v67_ = self.currentObjectToSpawn
	if location == nil then
		v67_.callback(v67_.callbackTarget, nil, PalletSpawner.RESULT_NO_SPACE, v67_.fillType)
		self.currentObjectToSpawn = nil
		table.remove(self.spawnQueue, 1)
	else
		local v68_ = getTerrainHeightAtWorldPos(g_terrainNode, location.x, 0, location.z) + self.spawnOffsetY
		local v69_ = location.y
		location.y = math.max(v68_, v69_)
		local v70_ = VehicleLoadingData.new()
		v70_:setFilename(v67_.pallet.filename)
		v70_:setPosition(location.x, location.y, location.z)
		v70_:setRotation(location.xRot, location.yRot, location.zRot)
		v70_:setPropertyState(VehiclePropertyState.OWNED)
		v70_:setOwnerFarmId(v67_.farmId)
		v70_:setCustomParameter("spawnEmpty", true)
		v70_:load(self.onFinishLoadingPallet, self)
	end
end

-- Local values: objectToSpawn, statusCode
function PalletSpawner:onFinishLoadingPallet(vehicles, vehicleLoadState)
	local v74_ = self.currentObjectToSpawn
	local v75_ = vehicleLoadState == VehicleLoadingState.OK and PalletSpawner.RESULT_SUCCESS or PalletSpawner.RESULT_ERROR_LOADING_PALLET
	v74_.callback(v74_.callbackTarget, vehicles[1], v75_, v74_.fillType)
	self.currentObjectToSpawn = nil
	table.remove(self.spawnQueue, 1)
end

-- Local values: object
function PalletSpawner:onFindExistingPallet(node)
	local v78_ = g_currentMission.nodeToObject[node]
	if v78_ ~= nil and (v78_.isa ~= nil and (v78_:isa(Vehicle) and (v78_.isPallet and (v78_:getFillUnitSupportsFillType(1, self.getOrSpawnPalletFilltype) and v78_:getFillUnitFreeCapacity(1, self.getOrSpawnPalletFilltype) > 0)))) then
		self.foundExistingPallet = v78_
		return false
	end
end

-- Local values: object, fillUnitIndex
function PalletSpawner:onFindPallet(node)
	local v81_ = g_currentMission.nodeToObject[node]
	if v81_ ~= nil and (v81_.isa ~= nil and (v81_:isa(Vehicle) and (v81_.isPallet and v81_:getFillUnitFillType(v81_.spec_pallet.fillUnitIndex) == self.getAllPalletsFilltype))) then
		self.getAllPalletsFoundPallets[v81_] = true
	end
end

function PalletSpawner.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".spawnPlaces.spawnPlace(?)#fillTypes", "Supported filltypes for this spawnPlace")
	schema:register(XMLValueType.STRING, basePath .. ".spawnPlaces.spawnPlace(?)#fillTypeCategories", "Supported filltype categories for this spawnPlace")
	PlacementUtil.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".pallets.pallet(?)#filename", "Path to pallet xml file")
end
