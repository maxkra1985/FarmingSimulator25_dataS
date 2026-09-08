PlaceableBunkerSilo = {}

function PlaceableBunkerSilo.prerequisitesPresent(specializations)
	return true
end

function PlaceableBunkerSilo.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableBunkerSilo)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableBunkerSilo)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableBunkerSilo)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableBunkerSilo)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableBunkerSilo)
	SpecializationUtil.registerEventListener(placeableType, "onSell", PlaceableBunkerSilo)
end

function PlaceableBunkerSilo.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateBunkerSiloWalls", PlaceableBunkerSilo.updateBunkerSiloWalls)
	SpecializationUtil.registerFunction(placeableType, "setWallVisibility", PlaceableBunkerSilo.setWallVisibility)
	SpecializationUtil.registerFunction(placeableType, "getIsBunkerSiloExtendable", PlaceableBunkerSilo.getIsBunkerSiloExtendable)
end

function PlaceableBunkerSilo.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getPlacementPosition", PlaceableBunkerSilo.getPlacementPosition)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getPlacementRotation", PlaceableBunkerSilo.getPlacementRotation)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getHasOverlap", PlaceableBunkerSilo.getHasOverlap)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "startPlacementCheck", PlaceableBunkerSilo.startPlacementCheck)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBeSold", PlaceableBunkerSilo.canBeSold)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableBunkerSilo.setOwnerFarmId)
end

function PlaceableBunkerSilo.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("BunkerSilo")
	BunkerSilo.registerXMLPaths(schema, basePath .. ".bunkerSilo")
	schema:register(XMLValueType.BOOL, basePath .. ".bunkerSilo#isExtendable", "Checks if silo is extendable. If set \'siloToSiloDistance\' needs to be provided as well", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".bunkerSilo#siloToSiloDistance", "Silo to silo distance required for aligning multiple silos of the same type next to each other")
	schema:register(XMLValueType.FLOAT, basePath .. ".bunkerSilo#snapDistance", "Snap distance for building an array of the same silo", "siloToSiloDistance * 1.1")
	schema:register(XMLValueType.STRING, basePath .. ".bunkerSilo#sellWarningText", "Sell warning text")
	schema:setXMLSpecializationType()
end

function PlaceableBunkerSilo.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("BunkerSilo")
	BunkerSilo.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType()
end

-- Local values: spec
function PlaceableBunkerSilo:onLoad(savegame)
	local v9_ = self.spec_bunkerSilo
	v9_.bunkerSilo = BunkerSilo.new(self.isServer, self.isClient)
	if not v9_.bunkerSilo:load(self.components, self.xmlFile, "placeable.bunkerSilo", self.i3dMappings) then
		v9_.bunkerSilo:delete()
	end
	v9_.isExtendable = self.xmlFile:getValue("placeable.bunkerSilo#isExtendable", false)
	if v9_.isExtendable then
		v9_.siloSiloDistance = self.xmlFile:getValue("placeable.bunkerSilo#siloToSiloDistance")
		if v9_.siloSiloDistance == nil then
			Logging.xmlError(self.xmlFile, "Bunker Silo is marked as extendable but \'placeable.bunkerSilo#siloToSiloDistance\' is not set")
			self:setLoadingState(PlaceableLoadingState.ERROR)
			return
		end
		v9_.snapDistance = self.xmlFile:getValue("placeable.bunkerSilo#snapDistance") or v9_.siloSiloDistance * 1.1
	end
	v9_.sellWarningText = g_i18n:convertText(self.xmlFile:getValue("placeable.bunkerSilo#sellWarningText", "$l10n_info_bunkerSiloNotEmpty"))
end

-- Local values: spec
function PlaceableBunkerSilo:onDelete()
	local v11_ = self.spec_bunkerSilo
	self:updateBunkerSiloWalls(true)
	if v11_.bunkerSilo ~= nil then
		v11_.bunkerSilo:delete()
	end
	g_currentMission.placeableSystem:removeBunkerSilo(self)
end

-- Local values: spec, ownerFarmId
function PlaceableBunkerSilo:onFinalizePlacement()
	local v13_ = self.spec_bunkerSilo
	local v14_ = self:getOwnerFarmId()
	self:updateBunkerSiloWalls(false)
	v13_.bunkerSilo:register(true)
	v13_.bunkerSilo:setOwnerFarmId(v14_, true)
	g_currentMission.placeableSystem:addBunkerSilo(self)
end

-- Local values: spec, bunkerSiloId
function PlaceableBunkerSilo:onReadStream(streamId, connection)
	local v18_ = self.spec_bunkerSilo
	local v19_ = NetworkUtil.readNodeObjectId(streamId)
	v18_.bunkerSilo:readStream(streamId, connection)
	g_client:finishRegisterObject(v18_.bunkerSilo, v19_)
end

-- Local values: spec
function PlaceableBunkerSilo:onWriteStream(streamId, connection)
	local v23_ = self.spec_bunkerSilo
	NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v23_.bunkerSilo))
	v23_.bunkerSilo:writeStream(streamId, connection)
	g_server:registerObjectInStream(connection, v23_.bunkerSilo)
end

-- Local values: spec
function PlaceableBunkerSilo:loadFromXMLFile(xmlFile, key)
	return self.spec_bunkerSilo.bunkerSilo:loadFromXMLFile(xmlFile, key)
end

-- Local values: spec
function PlaceableBunkerSilo:saveToXMLFile(xmlFile, key, usedModNames)
	self.spec_bunkerSilo.bunkerSilo:saveToXMLFile(xmlFile, key, usedModNames)
end

-- Local values: spec
function PlaceableBunkerSilo:setWallVisibility(isLeftVisible, isRightVisible)
	self.spec_bunkerSilo.bunkerSilo:setWallVisibility(isLeftVisible, isRightVisible)
end

-- Local values: spec
function PlaceableBunkerSilo:getIsBunkerSiloExtendable()
	return self.spec_bunkerSilo.isExtendable
end

-- Local values: spec, x, y, z, placeableSystem, _, placeable, lx, _, lz, distance, isLeft
function PlaceableBunkerSilo:updateBunkerSiloWalls(isDeleting)
	local v37_ = self.spec_bunkerSilo
	if self.rootNode ~= nil then
		local v38_, v39_, v40_ = getWorldTranslation(self.rootNode)
		local v41_ = g_currentMission.placeableSystem
		for _, v42_ in ipairs(v41_:getBunkerSilos()) do
			if v42_:getIsBunkerSiloExtendable() and (v42_ ~= self and (v42_:getOwnerFarmId() == self:getOwnerFarmId() and v42_.configFileName == self.configFileName)) then
				local v43_, _, v44_ = worldToLocal(v42_.rootNode, v38_, v39_, v40_)
				if MathUtil.vector2Length(v43_, v44_) < v37_.siloSiloDistance + 0.5 then
					local v45_ = v43_ > 0
					if isDeleting then
						if v45_ then
							v42_:setWallVisibility(true, nil)
						else
							v42_:setWallVisibility(nil, true)
						end
					elseif v45_ then
						v42_:setWallVisibility(false, nil)
					else
						v42_:setWallVisibility(nil, false)
					end
				end
			end
		end
	end
end

-- Local values: spec
function PlaceableBunkerSilo:setOwnerFarmId(superFunc, farmId, noEventSend)
	local v50_ = self.spec_bunkerSilo
	superFunc(self, farmId, noEventSend)
	if v50_.bunkerSilo ~= nil then
		v50_.bunkerSilo:setOwnerFarmId(farmId, true)
	end
end

-- Local values: spec
function PlaceableBunkerSilo:onSell()
	self.spec_bunkerSilo.bunkerSilo:clearSiloArea()
end

-- Local values: spec
function PlaceableBunkerSilo:canBeSold(superFunc)
	local v53_ = self.spec_bunkerSilo
	if v53_.bunkerSilo.fillLevel > 0 then
		return true, v53_.sellWarningText
	else
		return true, nil
	end
end

-- Local values: spec, nearestDistance, _, placeable, lx, _, lz, distance
function PlaceableBunkerSilo:startPlacementCheck(superFunc, x, y, z, rotY)
	local v60_ = self.spec_bunkerSilo
	superFunc(self, x, y, z, rotY)
	if x == nil then
		return
	elseif v60_.isExtendable then
		v60_.foundSnappingSilo = nil
		v60_.foundSnappingSiloSide = 0
		local v61_ = v60_.snapDistance
		for _, v62_ in ipairs(g_currentMission.placeableSystem:getBunkerSilos()) do
			if v62_:getOwnerFarmId() == g_localPlayer.farmId and v62_.configFileName == self.configFileName then
				local v63_, _, v64_ = worldToLocal(v62_.rootNode, x, y, z)
				local v65_ = MathUtil.vector2Length(v63_, v64_)
				if v65_ < v61_ then
					v60_.foundSnappingSilo = v62_
					v60_.foundSnappingSiloSide = math.sign(v63_)
					v61_ = v65_
				end
			end
		end
	end
end

-- Local values: spec, overwrittenCheckFunc
function PlaceableBunkerSilo:getHasOverlap(superFunc, x, y, z, rotY, checkFunc)
	local v_u_73_ = self.spec_bunkerSilo
	return superFunc(self, x, y, z, rotY, v_u_73_.foundSnappingSilo ~= nil and function(p74_)
		-- upvalues: (copy) v_u_73_, (copy) checkFunc
		if g_currentMission:getNodeObject(p74_) == v_u_73_.foundSnappingSilo then
			return false
		elseif checkFunc == nil then
			return p74_ ~= g_terrainNode
		else
			return checkFunc(p74_)
		end
	end or checkFunc)
end

-- Local values: spec, dx, _, dz
function PlaceableBunkerSilo:getPlacementRotation(superFunc, x, y, z)
	local v80_, v81_, v82_ = superFunc(self, x, y, z)
	local v83_ = self.spec_bunkerSilo
	if v83_.foundSnappingSilo ~= nil then
		local v84_, _, v85_ = localDirectionToWorld(v83_.foundSnappingSilo.rootNode, 0, 0, 1)
		v81_ = MathUtil.getYRotationFromDirection(v84_, v85_)
		v80_ = 0
		v82_ = 0
	end
	return v80_, v81_, v82_
end

-- Local values: spec
function PlaceableBunkerSilo:getPlacementPosition(superFunc, x, y, z)
	local v91_, v92_, v93_ = superFunc(self, x, y, z)
	local v94_ = self.spec_bunkerSilo
	if v94_.foundSnappingSilo ~= nil then
		v91_, v92_, v93_ = localToWorld(v94_.foundSnappingSilo.rootNode, v94_.siloSiloDistance * v94_.foundSnappingSiloSide, 0, 0)
	end
	return v91_, v92_, v93_
end
