PlaceablePlacement = {}
PlaceablePlacement.OVERLAP_COLLISION_MASK = CollisionMask.ALL - CollisionFlag.TERRAIN - CollisionFlag.TERRAIN_DELTA - CollisionFlag.TERRAIN_DISPLACEMENT

function PlaceablePlacement.prerequisitesPresent(self)
	return true
end

function PlaceablePlacement.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "loadTestArea", PlaceablePlacement.loadTestArea)
	SpecializationUtil.registerFunction(placeableType, "getIsAreaOwnedByFarm", PlaceablePlacement.getIsAreaOwnedByFarm)
	SpecializationUtil.registerFunction(placeableType, "getIsOnOwnedFarmland", PlaceablePlacement.getIsOnOwnedFarmland)
	SpecializationUtil.registerFunction(placeableType, "startPlacementCheck", PlaceablePlacement.startPlacementCheck)
	SpecializationUtil.registerFunction(placeableType, "getPlacementRotation", PlaceablePlacement.getPlacementRotation)
	SpecializationUtil.registerFunction(placeableType, "getPlacementPosition", PlaceablePlacement.getPlacementPosition)
	SpecializationUtil.registerFunction(placeableType, "getPositionSnapSize", PlaceablePlacement.getPositionSnapSize)
	SpecializationUtil.registerFunction(placeableType, "getPositionSnapOffset", PlaceablePlacement.getPositionSnapOffset)
	SpecializationUtil.registerFunction(placeableType, "getRotationSnapAngle", PlaceablePlacement.getRotationSnapAngle)
	SpecializationUtil.registerFunction(placeableType, "getPlacementOverlapMask", PlaceablePlacement.getPlacementOverlapMask)
	SpecializationUtil.registerFunction(placeableType, "isValidOverlapNode", PlaceablePlacement.isValidOverlapNode)
	SpecializationUtil.registerFunction(placeableType, "getHasOverlap", PlaceablePlacement.getHasOverlap)
	SpecializationUtil.registerFunction(placeableType, "getHasOverlapWithPlaces", PlaceablePlacement.getHasOverlapWithPlaces)
	SpecializationUtil.registerFunction(placeableType, "getCanBePlacedInWater", PlaceablePlacement.getCanBePlacedInWater)
	SpecializationUtil.registerFunction(placeableType, "getHasOverlapWithZones", PlaceablePlacement.getHasOverlapWithZones)
	SpecializationUtil.registerFunction(placeableType, "getTestParallelogramAtWorldPosition", PlaceablePlacement.getTestParallelogramAtWorldPosition)
	SpecializationUtil.registerFunction(placeableType, "playPlaceSound", PlaceablePlacement.playPlaceSound)
	SpecializationUtil.registerFunction(placeableType, "playDestroySound", PlaceablePlacement.playDestroySound)
	SpecializationUtil.registerFunction(placeableType, "getIsAreaBlocked", PlaceablePlacement.getIsAreaBlocked)
	SpecializationUtil.registerFunction(placeableType, "getHasOverlapWithDensityHeight", PlaceablePlacement.getHasOverlapWithDensityHeight)
end

function PlaceablePlacement.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceablePlacement)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceablePlacement)
	SpecializationUtil.registerEventListener(placeableType, "onPreFinalizePlacement", PlaceablePlacement)
end

function PlaceablePlacement.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Placement")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".placement#pos1Node", "Position node 1 (Required if alignToWorldY is false to calculate the terrain alignment)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".placement#pos2Node", "Position node 2 (Required if alignToWorldY is false to calculate the terrain alignment)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".placement#pos3Node", "Position node 3 (Required if alignToWorldY is false to calculate the terrain alignment)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".placement.testAreas.testArea(?)#startNode", "Start node of box for testing overlap")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".placement.testAreas.testArea(?)#endNode", "End node of box for testing overlap")
	schema:register(XMLValueType.BOOL, basePath .. ".placement#useRandomYRotation", "Use random Y rotation", false)
	schema:register(XMLValueType.BOOL, basePath .. ".placement#useManualYRotation", "Use manual Y rotation", false)
	schema:register(XMLValueType.BOOL, basePath .. ".placement#alignToWorldY", "Placeable is aligned to world Y instead of terrain", true)
	schema:register(XMLValueType.FLOAT, basePath .. ".placement#placementPositionSnapSize", "Position snap size", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".placement#placementPositionSnapOffset", "Position snap offset", 0)
	schema:register(XMLValueType.ANGLE, basePath .. ".placement#placementRotationSnapAngle", "Rotation snap angle", 0)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".placement.sounds", "place")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".placement.sounds", "placeLayered")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".placement.sounds", "destroy")
	schema:setXMLSpecializationType()
end

-- Local values: spec, xmlFile
function PlaceablePlacement:onLoad(savegame)
	local v_u_6_ = self.spec_placement
	local v_u_7_ = self.xmlFile
	v_u_6_.testAreas = {}
	v_u_7_:iterate("placeable.placement.testAreas.testArea", function(_, p8_)
		-- upvalues: (copy) self, (copy) v_u_7_, (copy) v_u_6_
		local v9_ = {}
		if self:loadTestArea(v_u_7_, p8_, v9_) then
			local v10_ = v_u_6_.testAreas
			table.insert(v10_, v9_)
		end
	end)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.placement#sizeX")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.placement#sizeZ")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.placement#sizeOffsetX")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.placement#sizeOffsetZ")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.placement#testSizeX", "placeable.placement.testAreas.testArea")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.placement#testSizeZ", "placeable.placement.testAreas.testArea")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.placement#testSizeOffsetX", "placeable.placement.testAreas.testArea")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.placement#testSizeOffsetZ", "placeable.placement.testAreas.testArea")
	v_u_6_.useRandomYRotation = v_u_7_:getValue("placeable.placement#useRandomYRotation", v_u_6_.useRandomYRotation)
	v_u_6_.useManualYRotation = v_u_7_:getValue("placeable.placement#useManualYRotation", v_u_6_.useManualYRotation)
	local v11_ = v_u_7_:getValue("placeable.placement#placementPositionSnapSize", 0)
	v_u_6_.positionSnapSize = math.abs(v11_)
	local v12_ = v_u_7_:getValue("placeable.placement#placementPositionSnapOffset", 0)
	v_u_6_.positionSnapOffset = math.abs(v12_)
	local v13_ = v_u_7_:getValue("placeable.placement#placementRotationSnapAngle", 0)
	v_u_6_.rotationSnapAngle = math.abs(v13_)
	v_u_6_.alignToWorldY = v_u_7_:getValue("placeable.placement#alignToWorldY", true)
	if not v_u_6_.alignToWorldY then
		v_u_6_.pos1Node = v_u_7_:getValue("placeable.placement#pos1Node", nil, self.components, self.i3dMappings)
		v_u_6_.pos2Node = v_u_7_:getValue("placeable.placement#pos2Node", nil, self.components, self.i3dMappings)
		v_u_6_.pos3Node = v_u_7_:getValue("placeable.placement#pos3Node", nil, self.components, self.i3dMappings)
		if v_u_6_.pos1Node == nil or (v_u_6_.pos2Node == nil or v_u_6_.pos3Node == nil) then
			v_u_6_.alignToWorldY = true
			Logging.xmlWarning(v_u_7_, "pos1Node, pos2Node and pos3Node has to be set when alignToWorldY is false!")
		end
	end
	if self.isClient and Platform.hasContruction then
		v_u_6_.samples = {}
		v_u_6_.samples.place = g_soundManager:loadSample2DFromXML(v_u_7_.handle, "placeable.placement.sounds", "place", self.baseDirectory, 1, AudioGroup.GUI)
		v_u_6_.samples.placeLayered = g_soundManager:loadSample2DFromXML(v_u_7_.handle, "placeable.placement.sounds", "placeLayered", self.baseDirectory, 1, AudioGroup.GUI)
		v_u_6_.samples.destroy = g_soundManager:loadSample2DFromXML(v_u_7_.handle, "placeable.placement.sounds", "destroy", self.baseDirectory, 1, AudioGroup.GUI)
	end
end

-- Local values: spec
function PlaceablePlacement:onDelete()
	if self.isClient then
		local v15_ = self.spec_placement
		g_soundManager:deleteSamples(v15_.samples)
	end
end

-- Local values: startNode, endNode, ySafetyOffset, offsetX, offsetY, offsetZ, centerX, centerY, centerZ, sizeX, sizeY, sizeZ, dirX, _, dirZ, rotY
function PlaceablePlacement:loadTestArea(xmlFile, key, area)
	local v20_ = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
	local v21_ = xmlFile:getValue(key .. "#endNode", nil, self.components, self.i3dMappings)
	if v20_ == nil then
		Logging.xmlWarning(xmlFile, "Missing test area start node for \'%s\'", key)
		return false
	end
	if v21_ == nil then
		Logging.xmlWarning(xmlFile, "Missing test area end node for \'%s\'", key)
		return false
	end
	if getParent(v21_) ~= v20_ then
		Logging.xmlWarning(xmlFile, "Test area end node is not a direct child of startNode for \'%s\'", key)
		return false
	end
	area.startNode = v20_
	area.endNode = v21_
	local v22_, v23_, v24_ = localToLocal(v21_, v20_, 0, -0.05, 0)
	local v25_, v26_, v27_ = localToLocal(v20_, self.rootNode, v22_ * 0.5, v23_ * 0.5, v24_ * 0.5)
	local v28_ = math.abs(v22_)
	local v29_ = v23_ + 0.05
	local v30_ = math.abs(v29_)
	local v31_ = math.abs(v24_)
	if v23_ < 0.01 then
		Logging.xmlDevWarning(xmlFile, "TestArea \'%s \'has no height (endNode has same y as startNode)", key)
	end
	area.size = {}
	area.size.x = math.abs(v28_)
	area.size.y = math.abs(v30_)
	area.size.z = math.abs(v31_)
	area.center = {}
	area.center.x = v25_
	area.center.y = v26_
	area.center.z = v27_
	local v32_, _, v33_ = localDirectionToLocal(v20_, self.rootNode, 0, 0, 1)
	area.rotYOffset = MathUtil.getYRotationFromDirection(v32_, v33_)
	return true
end

-- Local values: spec, degAngle
function PlaceablePlacement:getPlacementRotation(x, y, z)
	local v38_ = self.spec_placement
	if v38_.rotationSnapAngle ~= 0 then
		local v39_ = MathUtil.snapValue
		local v40_ = math.deg(y)
		local v41_ = v38_.rotationSnapAngle
		local v42_ = v39_(v40_, (math.deg(v41_)))
		y = math.rad(v42_)
	end
	return x, y, z
end

-- Local values: spec, snapSize
function PlaceablePlacement:getPlacementPosition(x, y, z)
	local v47_ = self.spec_placement
	local v48_ = v47_.positionSnapSize
	if v48_ ~= 0 then
		local v49_ = 1 / v48_
		local v50_ = x * v49_
		x = math.floor(v50_) / v49_ + v47_.positionSnapOffset
		local v51_ = z * v49_
		z = math.floor(v51_) / v49_ + v47_.positionSnapOffset
	end
	return x, y, z
end

function PlaceablePlacement:getPositionSnapSize()
	return self.spec_placement.positionSnapSize
end

function PlaceablePlacement:getPositionSnapOffset()
	return self.spec_placement.positionSnapOffset
end

function PlaceablePlacement:getRotationSnapAngle()
	return self.spec_placement.rotationSnapAngle
end

-- Local values: spec, x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, dirX, dirY, dirZ, dir2X, dir2Y, dir2Z, upX, upY, upZ
function PlaceablePlacement:onPreFinalizePlacement()
	local v56_ = self.spec_placement
	if not v56_.alignToWorldY and self.isServer then
		local v57_, v58_, v59_ = getWorldTranslation(self.rootNode)
		local v60_ = getTerrainHeightAtWorldPos(g_terrainNode, v57_, v58_, v59_)
		setTranslation(self.rootNode, v57_, v60_, v59_)
		local v61_, v62_, v63_ = getWorldTranslation(v56_.pos1Node)
		local v64_ = getTerrainHeightAtWorldPos(g_terrainNode, v61_, v62_, v63_)
		local v65_, v66_, v67_ = getWorldTranslation(v56_.pos2Node)
		local v68_ = getTerrainHeightAtWorldPos(g_terrainNode, v65_, v66_, v67_)
		local v69_, v70_, v71_ = getWorldTranslation(v56_.pos3Node)
		local v72_ = getTerrainHeightAtWorldPos(g_terrainNode, v69_, v70_, v71_)
		local v73_ = v61_ - v57_
		local v74_ = v64_ - v60_
		local v75_ = v63_ - v59_
		local v76_ = v65_ - v69_
		local v77_ = v68_ - v72_
		local v78_ = v67_ - v71_
		local v79_, v80_, v81_ = MathUtil.crossProduct(v76_, v77_, v78_, v73_, v74_, v75_)
		setDirection(self.rootNode, v73_, v74_, v75_, v79_, v80_, v81_)
	end
end

-- Local values: dx1, dz1, dx2, dz2
function PlaceablePlacement:getIsAreaOwnedByFarm(sx, sz, wx, wz, hx, hz, farmId)
	local v89_ = wx - sx
	local v90_ = wz - sz
	local v91_ = hx - sx
	local v92_ = hz - sz
	local v93_ = g_farmlandManager:getIsOwnedByFarmAlongLine(farmId, sx, sz, wx, wz) and (g_farmlandManager:getIsOwnedByFarmAlongLine(farmId, sx, sz, hx, hz) and g_farmlandManager:getIsOwnedByFarmAlongLine(farmId, hx, hz, hx + v89_, hz + v90_))
	if v93_ then
		v93_ = g_farmlandManager:getIsOwnedByFarmAlongLine(farmId, wx, wz, wx + v91_, wz + v92_)
	end
	return v93_
end

function PlaceablePlacement:startPlacementCheck(x, y, z, rotY) end

-- Local values: spec, farmId, _, area, size, center, dirX, dirZ, normX, _, normZ, posX, posZ, sizeXHalf, sizeZHalf, frontLeftX, frontLeftZ, frontRightX, frontRightZ, backLeftX, backLeftZ
function PlaceablePlacement:getIsOnOwnedFarmland(x, y, z, rotY)
	local v98_ = self.spec_placement
	local v99_ = g_localPlayer.farmId
	if not g_currentMission.accessHandler:canFarmAccessLand(v99_, x, z, true) then
		return false
	end
	for _, v100_ in ipairs(v98_.testAreas) do
		local v101_ = v100_.size
		local v102_ = v100_.center
		local v103_, v104_ = MathUtil.getDirectionFromYRotation(rotY)
		local v105_, _, v106_ = MathUtil.crossProduct(0, 1, 0, v103_, 0, v104_)
		local v107_ = x + v103_ * v102_.z + v105_ * v102_.x
		local v108_ = z + v104_ * v102_.z + v106_ * v102_.x
		local v109_ = v101_.x * 0.5
		local v110_ = v101_.z * 0.5
		if not self:getIsAreaOwnedByFarm(v107_ + v103_ * v110_ - v105_ * v109_, v108_ + v104_ * v110_ - v106_ * v109_, v107_ + v103_ * v110_ + v105_ * v109_, v108_ + v104_ * v110_ + v106_ * v109_, v107_ - v103_ * v110_ - v105_ * v109_, v108_ - v104_ * v110_ - v106_ * v109_, v99_) then
			return false
		end
	end
	return true
end

function PlaceablePlacement:isValidOverlapNode(node)
	return node ~= g_terrainNode
end

function PlaceablePlacement.getPlacementOverlapMask(self)
	return PlaceablePlacement.OVERLAP_COLLISION_MASK
end

function PlaceablePlacement:getIsAreaBlocked(frontLeftX, frontLeftZ, frontRightX, frontRightZ, backLeftX, backLeftZ)
	return g_densityMapHeightManager:getIsPlacementAreaBlocked(frontLeftX, frontLeftZ, frontRightX, frontRightZ, backLeftX, backLeftZ)
end

-- Local values: startX, startZ, widthX, widthZ, heightX, heightZ, density
function PlaceablePlacement:getHasOverlapWithDensityHeight(area, x, z, rotY)
	local v123_, v124_, v125_, v126_, v127_, v128_ = self:getTestParallelogramAtWorldPosition(area, x, z, rotY)
	return DensityMapHeightUtil.getValueAtArea(v123_, v124_, v125_, v126_, v127_, v128_, true) > 0
end

-- Local values: spec, placementOverlapMask, callbackTarget, _, area, size, center, dirX, dirZ, normX, _, normZ, posX, posY, posZ, sizeXHalf, sizeZHalf, frontLeftX, frontLeftZ, frontRightX, frontRightZ, backLeftX, backLeftZ, backRightX, backRightZ, frontLeftY, frontRightY, backLeftY, backRightY, centerY, terrainBasedCenterY, extendX, extendY, extendZ
function PlaceablePlacement:getHasOverlap(x, y, z, rotY, checkFunc)
	local v135_ = self.spec_placement
	local v136_ = self:getPlacementOverlapMask()
	local v_u_138_ = {
		["hasOverlap"] = false,
		["overlapCallback"] = function(_, p137_, _, _, _, _)
			-- upvalues: (copy) checkFunc, (copy) v_u_138_, (copy) self
			if checkFunc == nil then
				if self:isValidOverlapNode(p137_) then
					v_u_138_.hasOverlap = true
					v_u_138_.node = p137_
					return false
				end
			elseif checkFunc(p137_) then
				v_u_138_.hasOverlap = true
				v_u_138_.node = p137_
				return false
			end
			return true
		end
	}
	for _, v139_ in ipairs(v135_.testAreas) do
		local v140_ = v139_.size
		local v141_ = v139_.center
		local v142_, v143_ = MathUtil.getDirectionFromYRotation(rotY)
		local v144_, _, v145_ = MathUtil.crossProduct(0, 1, 0, v142_, 0, v143_)
		local v146_ = x + v142_ * v141_.z + v144_ * v141_.x
		local v147_ = y + v141_.y
		local v148_ = z + v143_ * v141_.z + v145_ * v141_.x
		local v149_ = v140_.x * 0.5
		local v150_ = v140_.z * 0.5
		local v151_ = v146_ + v142_ * v150_ - v144_ * v149_
		local v152_ = v148_ + v143_ * v150_ - v145_ * v149_
		local v153_ = v146_ + v142_ * v150_ + v144_ * v149_
		local v154_ = v148_ + v143_ * v150_ + v145_ * v149_
		local v155_ = v146_ - v142_ * v150_ - v144_ * v149_
		local v156_ = v148_ - v143_ * v150_ - v145_ * v149_
		local v157_ = v146_ - v142_ * v150_ + v144_ * v149_
		local v158_ = v148_ - v143_ * v150_ + v145_ * v149_
		if self:getIsAreaBlocked(v151_, v152_, v153_, v154_, v155_, v156_) then
			return true, nil
		end
		local v159_ = getTerrainHeightAtWorldPos(g_terrainNode, v151_, 0, v152_)
		local v160_ = getTerrainHeightAtWorldPos(g_terrainNode, v153_, 0, v154_)
		local v161_ = getTerrainHeightAtWorldPos(g_terrainNode, v155_, 0, v156_)
		local v162_ = getTerrainHeightAtWorldPos(g_terrainNode, v157_, 0, v158_)
		local v163_ = getTerrainHeightAtWorldPos(g_terrainNode, v146_, 0, v148_)
		local v164_ = math.min(v159_, v160_, v161_, v162_, v163_) + v140_.y * 0.5 - 0.5
		local v165_ = math.max(v164_, v147_)
		local v166_ = v140_.x * 0.5
		local v167_ = v140_.y * 0.5
		local v168_ = v140_.z * 0.5
		overlapBox(v146_, v165_, v148_, 0, rotY + v139_.rotYOffset, 0, v166_, v167_, v168_, "overlapCallback", v_u_138_, v136_, true, true, true, true)
		if v_u_138_.hasOverlap then
			return true, v_u_138_.node
		end
		if self:getHasOverlapWithDensityHeight(v139_, x, z, rotY) then
			return true, nil
		end
	end
	return false, nil
end

-- Local values: spec, _, area, x1, z1, x2, z2, x3, z3, x4, z4
function PlaceablePlacement:getHasOverlapWithPlaces(places, x, y, z, rotY)
	local v175_ = self.spec_placement
	for _, v176_ in ipairs(v175_.testAreas) do
		local v177_, v178_, v179_, v180_, v181_, v182_, v183_, v184_ = self:getTestParallelogramAtWorldPosition(v176_, x, z, rotY)
		if PlacementUtil.isInsidePlacementPlaces(places, v177_, y, v178_) then
			return true
		end
		if PlacementUtil.isInsidePlacementPlaces(places, v179_, y, v180_) then
			return true
		end
		if PlacementUtil.isInsidePlacementPlaces(places, v181_, y, v182_) then
			return true
		end
		if PlacementUtil.isInsidePlacementPlaces(places, v183_, y, v184_) then
			return true
		end
	end
	return false
end

function PlaceablePlacement:getCanBePlacedInWater()
	return false
end

-- Local values: spec, doWaterCheck, _, area, x1, z1, x2, z2, x3, z3, x4, z4
function PlaceablePlacement:getHasOverlapWithZones(zones, x, y, z, rotY)
	local v191_ = self.spec_placement
	local v192_ = not self:getCanBePlacedInWater()
	for _, v193_ in ipairs(v191_.testAreas) do
		local v194_, v195_, v196_, v197_, v198_, v199_, v200_, v201_ = self:getTestParallelogramAtWorldPosition(v193_, x, z, rotY)
		if PlacementUtil.isInsideRestrictedZone(zones, v194_, y, v195_, v192_) then
			return true
		end
		if PlacementUtil.isInsideRestrictedZone(zones, v196_, y, v197_, v192_) then
			return true
		end
		if PlacementUtil.isInsideRestrictedZone(zones, v198_, y, v199_, v192_) then
			return true
		end
		if PlacementUtil.isInsideRestrictedZone(zones, v200_, y, v201_, v192_) then
			return true
		end
		if not g_currentMission.placeableSystem:getIsInsideBoundary(v194_, v195_) then
			return true
		end
		if not g_currentMission.placeableSystem:getIsInsideBoundary(v196_, v197_) then
			return true
		end
		if not g_currentMission.placeableSystem:getIsInsideBoundary(v198_, v199_) then
			return true
		end
		if not g_currentMission.placeableSystem:getIsInsideBoundary(v200_, v201_) then
			return true
		end
	end
	return false
end

-- Local values: dirX, dirZ, normX, _, normZ, centerXOffset, centerZOffset, centerX, centerZ, startOffsetX, startOffsetZ, startX, startZ, widthOffset, widthX, widthZ, heightOffset, heightX, heightZ, heightX2, heightZ2
function PlaceablePlacement:getTestParallelogramAtWorldPosition(testArea, x, z, rotY)
	local v206_, v207_ = MathUtil.getDirectionFromYRotation(rotY)
	local v208_, _, v209_ = MathUtil.crossProduct(0, 1, 0, v206_, 0, v207_)
	local v210_ = testArea.center.x
	local v211_ = testArea.center.z
	local v212_ = x + v206_ * v211_ + v208_ * v210_
	local v213_ = z + v207_ * v211_ + v209_ * v210_
	local v214_, v215_ = MathUtil.getDirectionFromYRotation(rotY + testArea.rotYOffset)
	local v216_, _, v217_ = MathUtil.crossProduct(0, 1, 0, v214_, 0, v215_)
	local v218_ = testArea.size.x * 0.5
	local v219_ = testArea.size.z * 0.5
	local v220_ = v212_ - v214_ * v219_ - v216_ * v218_
	local v221_ = v213_ - v215_ * v219_ - v217_ * v218_
	local v222_ = testArea.size.x
	local v223_ = v220_ + v216_ * v222_
	local v224_ = v221_ + v217_ * v222_
	local v225_ = testArea.size.z
	return v220_, v221_, v223_, v224_, v220_ + v214_ * v225_, v221_ + v215_ * v225_, v223_ + v214_ * v225_, v224_ + v215_ * v225_
end

-- Local values: spec
function PlaceablePlacement:playPlaceSound()
	if self.isClient then
		local v227_ = self.spec_placement
		g_soundManager:playSample(v227_.samples.place)
		g_soundManager:playSample(v227_.samples.placeLayered)
	end
end

-- Local values: spec
function PlaceablePlacement:playDestroySound(onlyIfNotPlaying)
	if self.isClient then
		local v230_ = self.spec_placement
		if not (onlyIfNotPlaying and g_soundManager:getIsSamplePlaying(v230_.samples.destroy)) then
			g_soundManager:playSample(v230_.samples.destroy)
		end
	end
end
