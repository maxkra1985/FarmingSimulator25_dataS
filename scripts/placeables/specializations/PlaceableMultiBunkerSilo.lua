PlaceableMultiBunkerSilo = {}

function PlaceableMultiBunkerSilo.prerequisitesPresent(specializations)
	return true
end
function PlaceableMultiBunkerSilo.initSpecialization()
	g_placeableConfigurationManager:addConfigurationType("bunkerSilo", g_i18n:getText("configuration_bunkerSilo"), "bunkerSilo", PlaceableConfigurationItem)
end

function PlaceableMultiBunkerSilo.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableMultiBunkerSilo)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableMultiBunkerSilo)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableMultiBunkerSilo)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableMultiBunkerSilo)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableMultiBunkerSilo)
	SpecializationUtil.registerEventListener(placeableType, "onSell", PlaceableMultiBunkerSilo)
end

function PlaceableMultiBunkerSilo.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateBunkerSiloWalls", PlaceableMultiBunkerSilo.updateBunkerSiloWalls)
	SpecializationUtil.registerFunction(placeableType, "setWallVisibility", PlaceableMultiBunkerSilo.setWallVisibility)
	SpecializationUtil.registerFunction(placeableType, "getIsBunkerSiloExtendable", PlaceableMultiBunkerSilo.getIsBunkerSiloExtendable)
end

function PlaceableMultiBunkerSilo.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getPlacementPosition", PlaceableMultiBunkerSilo.getPlacementPosition)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getPlacementRotation", PlaceableMultiBunkerSilo.getPlacementRotation)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getHasOverlap", PlaceableMultiBunkerSilo.getHasOverlap)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "startPlacementCheck", PlaceableMultiBunkerSilo.startPlacementCheck)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBeSold", PlaceableMultiBunkerSilo.canBeSold)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableMultiBunkerSilo.setOwnerFarmId)
end

function PlaceableMultiBunkerSilo.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("MultiBunkerSilo")
	schema:register(XMLValueType.BOOL, basePath .. ".bunkerSilo#isExtendable", "Checks if silo is extendable. If set \'siloToSiloDistance\' needs to be provided as well", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".bunkerSilo#siloToSiloDistance", "Silo to silo distance required for aligning multiple silos of the same type next to each other")
	schema:register(XMLValueType.FLOAT, basePath .. ".bunkerSilo#snapDistance", "Snap distance for building an array of the same silo", "siloToSiloDistance * 1.1")
	schema:register(XMLValueType.STRING, basePath .. ".bunkerSilo#sellWarningText", "Sell warning text")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".bunkerSilo.wallLeft#node", "Left wall node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".bunkerSilo.wallLeft#collision", "Left wall collision")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".bunkerSilo.wallBack#node", "Back wall node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".bunkerSilo.wallBack#collision", "Back wall collision")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".bunkerSilo.wallRight#node", "Right wall node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".bunkerSilo.wallRight#collision", "Right wall collision")
	local v6_ = basePath .. ".bunkerSilo.bunkerSiloConfigurations.bunkerSiloConfiguration(?)"
	BunkerSilo.registerXMLPaths(schema, v6_ .. ".bunkerSilo(?)")
	schema:setXMLSpecializationType()
end

function PlaceableMultiBunkerSilo.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("MultiBunkerSilo")
	BunkerSilo.registerSavegameXMLPaths(schema, basePath .. ".bunkerSilo(?)")
	schema:setXMLSpecializationType()
end

-- Local values: spec, xmlKey, bunkerSiloConfigurationId, configKey, leftWallNode, backWallNode, rightWallNode, _, key, bunkerSilo
function PlaceableMultiBunkerSilo:onLoad(savegame)
	local v10_ = self.spec_multiBunkerSilo
	v10_.bunkerSilos = {}
	local v11_ = Utils.getNoNil(self.configurations.bunkerSilo, 1)
	local v12_ = string.format("%s.bunkerSiloConfigurations.bunkerSiloConfiguration(%d)", "placeable.bunkerSilo", v11_ - 1)
	local v13_ = self.xmlFile:getValue("placeable.bunkerSilo.wallLeft#node", nil, self.components, self.i3dMappings)
	if v13_ ~= nil then
		v10_.wallLeft = {}
		v10_.wallLeft.node = v13_
		v10_.wallLeft.visible = true
		v10_.wallLeft.collision = self.xmlFile:getValue("placeable.bunkerSilo.wallLeft#collision", nil, self.components, self.i3dMappings)
	end
	local v14_ = self.xmlFile:getValue("placeable.bunkerSilo.wallRight#node", nil, self.components, self.i3dMappings)
	if v14_ ~= nil then
		v10_.wallRight = {}
		v10_.wallRight.node = v14_
		v10_.wallRight.visible = true
		v10_.wallRight.collision = self.xmlFile:getValue("placeable.bunkerSilo.wallRight#collision", nil, self.components, self.i3dMappings)
	end
	local v15_ = self.xmlFile:getValue("placeable.bunkerSilo.wallBack#node", nil, self.components, self.i3dMappings)
	if v15_ ~= nil then
		v10_.wallRight = {}
		v10_.wallRight.node = v15_
		v10_.wallRight.visible = true
		v10_.wallRight.collision = self.xmlFile:getValue("placeable.bunkerSilo.wallBack#collision", nil, self.components, self.i3dMappings)
	end
	v10_.sellWarningText = g_i18n:convertText(self.xmlFile:getValue("placeable.bunkerSilo#sellWarningText", "$l10n_info_bunkerSiloNotEmpty"))
	for _, v16_ in self.xmlFile:iterator(v12_ .. ".bunkerSilo") do
		local v17_ = BunkerSilo.new(self.isServer, self.isClient)
		if not v17_:load(self.components, self.xmlFile, v16_, self.i3dMappings) then
			v17_:delete()
			return
		end
		local v18_ = v10_.bunkerSilos
		table.insert(v18_, v17_)
	end
	v10_.isExtendable = self.xmlFile:getValue("placeable.bunkerSilo#isExtendable", false)
	if v10_.isExtendable then
		v10_.siloSiloDistance = self.xmlFile:getValue("placeable.bunkerSilo#siloToSiloDistance")
		if v10_.siloSiloDistance == nil then
			Logging.xmlError(self.xmlFile, "Bunker Silo is marked as extendable but \'placeable.bunkerSilo#siloToSiloDistance\' is not set")
			self:setLoadingState(PlaceableLoadingState.ERROR)
			return
		end
		v10_.snapDistance = self.xmlFile:getValue("placeable.bunkerSilo#snapDistance") or v10_.siloSiloDistance * 1.1
	end
end

-- Local values: spec, i, bunkerSilo
function PlaceableMultiBunkerSilo:onDelete()
	local v20_ = self.spec_multiBunkerSilo
	self:updateBunkerSiloWalls(true)
	for v21_, v22_ in ipairs_reverse(v20_.bunkerSilos) do
		v22_:delete()
		table.remove(v20_.bunkerSilos, v21_)
	end
	g_currentMission.placeableSystem:removeBunkerSilo(self)
end

-- Local values: spec, ownerFarmId, _, bunkerSilo
function PlaceableMultiBunkerSilo:onFinalizePlacement()
	local v24_ = self.spec_multiBunkerSilo
	local v25_ = self:getOwnerFarmId()
	self:updateBunkerSiloWalls(false)
	for _, v26_ in ipairs(v24_.bunkerSilos) do
		v26_:register(true)
		v26_:setOwnerFarmId(v25_, true)
	end
	g_currentMission.placeableSystem:addBunkerSilo(self)
end

-- Local values: spec, _, bunkerSilo, bunkerSiloId
function PlaceableMultiBunkerSilo:onReadStream(streamId, connection)
	local v30_ = self.spec_multiBunkerSilo
	for _, v31_ in ipairs(v30_.bunkerSilos) do
		local v32_ = NetworkUtil.readNodeObjectId(streamId)
		v31_:readStream(streamId, connection)
		g_client:finishRegisterObject(v31_, v32_)
	end
end

-- Local values: spec, _, bunkerSilo
function PlaceableMultiBunkerSilo:onWriteStream(streamId, connection)
	local v36_ = self.spec_multiBunkerSilo
	for _, v37_ in ipairs(v36_.bunkerSilos) do
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v37_))
		v37_:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, v37_)
	end
end

-- Local values: spec, isSuccessful, i, bunkerSilo, bunkerSiloKey
function PlaceableMultiBunkerSilo:loadFromXMLFile(xmlFile, key)
	local v41_ = self.spec_multiBunkerSilo
	local v42_ = true
	for v43_, v44_ in ipairs(v41_.bunkerSilos) do
		if not v44_:loadFromXMLFile(xmlFile, (string.format("%s.bunkerSilo(%d)", key, v43_ - 1))) then
			v42_ = false
		end
	end
	return v42_
end

-- Local values: spec, i, bunkerSilo, bunkerSiloKey
function PlaceableMultiBunkerSilo:saveToXMLFile(xmlFile, key, usedModNames)
	local v49_ = self.spec_multiBunkerSilo
	for v50_, v51_ in ipairs(v49_.bunkerSilos) do
		v51_:saveToXMLFile(xmlFile, string.format("%s.bunkerSilo(%d)", key, v50_ - 1), usedModNames)
	end
end

-- Local values: spec
function PlaceableMultiBunkerSilo:setWallVisibility(isLeftVisible, isBackVisible, isRightVisible)
	local v55_ = self.spec_multiBunkerSilo
	if v55_.wallLeft ~= nil then
		isLeftVisible = isLeftVisible or v55_.wallLeft.visible
		if v55_.wallLeft.visible ~= isLeftVisible then
			v55_.wallLeft.visible = isLeftVisible
			setVisibility(v55_.wallLeft.node, isLeftVisible)
			if v55_.wallLeft.collision ~= nil then
				setRigidBodyType(v55_.wallLeft.collision, isLeftVisible and RigidBodyType.STATIC or RigidBodyType.NONE)
			end
		end
	end
	if v55_.wallBack ~= nil then
		local v56_ = isBackVisible or v55_.wallBack.visible
		if v55_.wallBack.visible ~= v56_ then
			v55_.wallBack.visible = v56_
			setVisibility(v55_.wallBack.node, v56_)
			if v55_.wallBack.collision ~= nil then
				setRigidBodyType(v55_.wallBack.collision, v56_ and RigidBodyType.STATIC or RigidBodyType.NONE)
			end
		end
	end
	if v55_.wallRight ~= nil then
		local v57_ = isLeftVisible or v55_.wallRight.visible
		if v55_.wallRight.visible ~= v57_ then
			v55_.wallRight.visible = v57_
			setVisibility(v55_.wallRight.node, v57_)
			if v55_.wallRight.collision ~= nil then
				setRigidBodyType(v55_.wallRight.collision, v57_ and RigidBodyType.STATIC or RigidBodyType.NONE)
			end
		end
	end
end

-- Local values: spec
function PlaceableMultiBunkerSilo:getIsBunkerSiloExtendable()
	return self.spec_multiBunkerSilo.isExtendable
end

-- Local values: spec, x, y, z, placeableSystem, _, placeable, lx, _, lz, distance, isLeft, isBack
function PlaceableMultiBunkerSilo:updateBunkerSiloWalls(isDeleting)
	local v61_ = self.spec_multiBunkerSilo
	if self.rootNode ~= nil then
		local v62_, v63_, v64_ = getWorldTranslation(self.rootNode)
		local v65_ = g_currentMission.placeableSystem
		for _, v66_ in ipairs(v65_:getBunkerSilos()) do
			if v66_:getIsBunkerSiloExtendable() and (v66_ ~= self and (v66_:getOwnerFarmId() == self:getOwnerFarmId() and v66_.configFileName == self.configFileName)) then
				local v67_, _, v68_ = worldToLocal(v66_.rootNode, v62_, v63_, v64_)
				if MathUtil.vector2Length(v67_, v68_) < v61_.siloSiloDistance + 0.5 then
					local v69_ = v67_ > 0
					local v70_ = v68_ < 0
					if isDeleting then
						if v69_ then
							v66_:setWallVisibility(true, nil, nil)
						elseif v70_ then
							v66_:setWallVisibility(nil, true, nil)
						else
							v66_:setWallVisibility(nil, nil, true)
						end
					elseif v69_ then
						v66_:setWallVisibility(false, nil, nil)
					elseif v70_ then
						v66_:setWallVisibility(nil, false, nil)
					else
						v66_:setWallVisibility(nil, nil, false)
					end
				end
			end
		end
	end
end

-- Local values: spec, _, bunkerSilo
function PlaceableMultiBunkerSilo:setOwnerFarmId(superFunc, farmId, noEventSend)
	local v75_ = self.spec_multiBunkerSilo
	superFunc(self, farmId, noEventSend)
	if v75_.bunkerSilos ~= nil then
		for _, v76_ in ipairs(v75_.bunkerSilos) do
			v76_:setOwnerFarmId(farmId, true)
		end
	end
end

-- Local values: spec, _, bunkerSilo
function PlaceableMultiBunkerSilo:onSell()
	local v78_ = self.spec_multiBunkerSilo
	for _, v79_ in ipairs(v78_.bunkerSilos) do
		v79_:clearSiloArea()
	end
end

-- Local values: spec, _, bunkerSilo
function PlaceableMultiBunkerSilo:canBeSold(superFunc)
	local v81_ = self.spec_multiBunkerSilo
	for _, v82_ in ipairs(v81_.bunkerSilos) do
		if v82_.fillLevel > 0 then
			return true, v81_.sellWarningText
		end
	end
	return true, nil
end

-- Local values: spec, nearestDistance, _, placeable, lx, _, lz, distance
function PlaceableMultiBunkerSilo:startPlacementCheck(superFunc, x, y, z, rotY)
	local v89_ = self.spec_multiBunkerSilo
	superFunc(self, x, y, z, rotY)
	if x == nil then
		return
	elseif v89_.isExtendable then
		v89_.foundSnappingSilo = nil
		v89_.foundSnappingSiloSide = 0
		local v90_ = v89_.snapDistance
		for _, v91_ in ipairs(g_currentMission.placeableSystem:getBunkerSilos()) do
			if v91_:getOwnerFarmId() == g_localPlayer.farmId and v91_.configFileName == self.configFileName then
				local v92_, _, v93_ = worldToLocal(v91_.rootNode, x, y, z)
				local v94_ = MathUtil.vector2Length(v92_, v93_)
				if v94_ < v90_ then
					v89_.foundSnappingSilo = v91_
					v89_.foundSnappingSiloSide = math.sign(v92_)
					v90_ = v94_
				end
			end
		end
	end
end

-- Local values: spec, overwrittenCheckFunc
function PlaceableMultiBunkerSilo:getHasOverlap(superFunc, x, y, z, rotY, checkFunc)
	local v_u_102_ = self.spec_multiBunkerSilo
	return superFunc(self, x, y, z, rotY, v_u_102_.foundSnappingSilo ~= nil and function(p103_)
		-- upvalues: (copy) v_u_102_, (copy) checkFunc
		if g_currentMission:getNodeObject(p103_) == v_u_102_.foundSnappingSilo then
			return false
		elseif checkFunc == nil then
			return p103_ ~= g_terrainNode
		else
			return checkFunc(p103_)
		end
	end or checkFunc)
end

-- Local values: spec, dx, _, dz
function PlaceableMultiBunkerSilo:getPlacementRotation(superFunc, x, y, z)
	local v109_, v110_, v111_ = superFunc(self, x, y, z)
	local v112_ = self.spec_multiBunkerSilo
	if v112_.foundSnappingSilo ~= nil then
		local v113_, _, v114_ = localDirectionToWorld(v112_.foundSnappingSilo.rootNode, 0, 0, 1)
		v110_ = MathUtil.getYRotationFromDirection(v113_, v114_)
		v109_ = 0
		v111_ = 0
	end
	return v109_, v110_, v111_
end

-- Local values: spec
function PlaceableMultiBunkerSilo:getPlacementPosition(superFunc, x, y, z)
	local v120_, v121_, v122_ = superFunc(self, x, y, z)
	local v123_ = self.spec_multiBunkerSilo
	if v123_.foundSnappingSilo ~= nil then
		v120_, v121_, v122_ = localToWorld(v123_.foundSnappingSilo.rootNode, v123_.siloSiloDistance * v123_.foundSnappingSiloSide, 0, 0)
	end
	return v120_, v121_, v122_
end
