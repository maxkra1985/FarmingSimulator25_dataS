PlacementUtil = {}
PlacementUtil.TEST_HEIGHT = 10
PlacementUtil.TEST_STEP_SIZE = 1
PlacementUtil.NETHER_HEIGHT = -150

-- Local values: collisionMask, _, place, placeUsage, halfSizeX, width, x, y, z, terrainHeight, vehicleX, vehicleY, vehicleZ
function PlacementUtil.getPlace(places, size, usage, includeDynamics, includeKinematics, includeStatics, doExactTest)
	local v8_ = CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.DYNAMIC_OBJECT
	for _, v9_ in pairs(places) do
		if size.width <= v9_.maxWidth and (size.length <= v9_.maxLength and size.height <= v9_.maxHeight) then
			local v10_ = usage[v9_]
			local v11_ = v10_ == nil and 0 or v10_
			local v12_ = size.width * 0.5
			for v13_ = v11_ + v12_, v9_.width - v12_, PlacementUtil.TEST_STEP_SIZE do
				local v14_ = v9_.startX + v13_ * v9_.dirX
				local v15_ = v9_.startY + v13_ * v9_.dirY
				local v16_ = v9_.startZ + v13_ * v9_.dirZ
				local v17_ = getTerrainHeightAtWorldPos(g_terrainNode, v14_, v15_, v16_) + 0.5
				local v18_ = math.max(v17_, v15_)
				PlacementUtil.tempHasCollision = false
				overlapBox(v14_, v18_, v16_, v9_.rotX, v9_.rotY, v9_.rotZ, size.width * 0.5, PlacementUtil.TEST_HEIGHT * 0.5, size.length * 0.5, "PlacementUtil.collisionTestCallback", nil, v8_, includeDynamics, includeKinematics, includeStatics, doExactTest)
				if not PlacementUtil.tempHasCollision then
					local v19_ = v14_ - size.widthOffset * v9_.dirX - size.lengthOffset * v9_.dirPerpX
					local v20_ = v18_ - size.widthOffset * v9_.dirY - size.lengthOffset * v9_.dirPerpY
					local v21_ = v16_ - size.widthOffset * v9_.dirZ - size.lengthOffset * v9_.dirPerpZ
					local v22_ = getTerrainHeightAtWorldPos(g_terrainNode, v14_, v18_, v16_)
					local v23_ = v22_ + v9_.yOffset
					local v24_ = math.max(v23_, v18_)
					return v19_, v20_, v21_, v9_, v13_ + v12_, v24_ - v22_
				end
			end
		end
	end
	return nil
end

function PlacementUtil.markPlaceUsed(usage, place, width)
	usage[place] = width
end

function PlacementUtil.unmarkPlaceUsed(usage, place)
	usage[place] = nil
end

function PlacementUtil:collisionTestCallback(transformId)
	if g_currentMission.nodeToObject[transformId] == nil and (g_currentMission.players[transformId] == nil and g_currentMission:getNodeObject(transformId) == nil) then
		return true
	end
	PlacementUtil.tempHasCollision = true
	return false
end

-- Local values: startNode, endNode, isInverted, place
function PlacementUtil.loadPlaceFromXML(xmlFile, key, rootNode, i3dMappings)
	local v35_ = xmlFile:getValue(key .. "#startNode", nil, rootNode, i3dMappings)
	local v36_ = xmlFile:getValue(key .. "#endNode", nil, rootNode, i3dMappings)
	local v37_ = xmlFile:getValue(key .. "#isInverted", false)
	local v38_ = PlacementUtil.loadPlaceFromNode(v35_, v36_, v37_)
	if v38_ == nil then
		return nil
	end
	v38_.maxWidth = xmlFile:getValue(key .. "#maxWidth") or v38_.maxWidth
	v38_.maxLength = xmlFile:getValue(key .. "#maxLength") or v38_.maxLength
	v38_.maxHeight = xmlFile:getValue(key .. "#maxHeight") or v38_.maxHeight
	v38_.length = xmlFile:getValue(key .. "#length") or v38_.length
	v38_.palletRotationOffset = xmlFile:getValue(key .. "#palletRotationOffset") or v38_.palletRotationOffset
	return v38_
end

-- Local values: place, numChildren, x, y, z, dx, dy, dz, dirX, dirY, dirZ, wdirX, wdirY, wdirZ, upX, upY, upZ
function PlacementUtil.loadPlaceFromNode(startNode, endNode, isInverted)
	if startNode == nil then
		return nil
	end
	local v42_ = {}
	local v43_, v44_, v45_ = getWorldTranslation(startNode)
	v42_.startX = v43_
	v42_.startY = v44_
	v42_.startZ = v45_
	v42_.width = getUserAttribute(startNode, "width") or 2
	v42_.length = getUserAttribute(startNode, "length") or 20
	v42_.yOffset = getUserAttribute(startNode, "yOffset") or 1
	v42_.maxWidth = getUserAttribute(startNode, "maxWidth") or math.huge
	v42_.maxLength = getUserAttribute(startNode, "maxLength") or math.huge
	v42_.maxHeight = getUserAttribute(startNode, "maxHeight") or math.huge
	local v46_ = getUserAttribute(startNode, "palletRotationOffset") or 0
	v42_.palletRotationOffset = math.rad(v46_)
	local v47_ = getNumOfChildren(startNode)
	if endNode == nil then
		if v47_ == 1 then
			endNode = getChildAt(startNode, 0)
		else
			Logging.warning("No end node given and no child node present for place %s", getName(startNode))
		end
	end
	if endNode ~= nil then
		local v48_, v49_, v50_ = getWorldTranslation(endNode)
		local v51_ = v48_ - v42_.startX
		local v52_ = v49_ - v42_.startY
		local v53_ = v50_ - v42_.startZ
		if v51_ == 0 and v53_ == 0 then
			Logging.error("PlacementUtil.loadPlaceFromNode(): Start node %q and end node %q are on the same location", getName(startNode), getName(endNode))
			return nil
		end
		v42_.width = MathUtil.vector3Length(v51_, v52_, v53_)
		local v54_, v55_, v56_ = MathUtil.vector3Normalize(v51_, v52_, v53_)
		local v57_, v58_, v59_ = worldDirectionToLocal(getParent(startNode), v54_, v55_, v56_)
		local v60_, v61_, v62_ = localDirectionToLocal(startNode, getParent(startNode), 0, 1, 0)
		setDirection(startNode, v57_, v58_, v59_, v60_, v61_, v62_)
		rotateAboutLocalAxis(startNode, -1.5707963267948966, 0, 1, 0)
	end
	if v47_ > 1 then
		Logging.warning("loadPlaceFromNode: Node \'%s\' has more than one child node. Use \'maxLength\' user- or xml-attribute to limit the maximum vehicle length.", getName(startNode))
	end
	local v63_, v64_, v65_ = getWorldRotation(startNode)
	v42_.rotX = v63_
	v42_.rotY = v64_
	v42_.rotZ = v65_
	if isInverted then
		v42_.rotY = v42_.rotY + 3.141592653589793
	end
	local v66_, v67_, v68_ = localDirectionToWorld(startNode, 1, 0, 0)
	v42_.dirX = v66_
	v42_.dirY = v67_
	v42_.dirZ = v68_
	local v69_, v70_, v71_ = localDirectionToWorld(startNode, 0, 0, isInverted and -1 or 1)
	v42_.dirPerpX = v69_
	v42_.dirPerpY = v70_
	v42_.dirPerpZ = v71_
	v42_.startNode = startNode
	setWorldRotation(startNode, v42_.rotX, v42_.rotY, v42_.rotZ)
	return v42_
end

-- Local values: restrictedZone, _, x, _, z
function PlacementUtil.createRestrictedZone(node)
	local v73_ = {}
	local v74_, _, v75_ = getWorldTranslation(node)
	v73_.x = v74_
	v73_.z = v75_
	if getNumOfChildren(node) > 0 then
		local v76_, _, v77_ = getTranslation(getChildAt(node, 0))
		v73_.width = math.abs(v76_)
		v73_.length = math.abs(v77_)
		if v76_ < 0 then
			v73_.x = v73_.x + v76_
		end
		if v77_ < 0 then
			v73_.z = v73_.z + v77_
			return v73_
		end
	else
		v73_.width = 1
		v73_.length = 1
	end
	return v73_
end

-- Local values: _, restrictedZone, dx, dz, waterY
function PlacementUtil.isInsideRestrictedZone(restrictedZones, x, y, z, doWaterCheck)
	for _, v83_ in pairs(restrictedZones) do
		local v84_ = v83_.x + v83_.width - x
		local v85_ = v83_.z + v83_.length - z
		if v84_ > 0 and (v84_ < v83_.width and (v85_ > 0 and v85_ < v83_.length)) then
			return true
		end
	end
	return Utils.getNoNil(doWaterCheck, true) and y < (g_currentMission.environmentAreaSystem:getWaterYAtWorldPosition(x, y, z) or -2000) - 0.5 and true or false
end

-- Local values: _, place, dx, dz, sx, sz, width, t, distance, ex, ez
function PlacementUtil.isInsidePlacementPlaces(places, x, y, z)
	for _, v89_ in pairs(places) do
		local v90_ = v89_.dirX
		local v91_ = v89_.dirZ
		local v92_ = v89_.startX
		local v93_ = v89_.startZ
		local v94_ = v89_.width
		local v95_ = (x - v92_) * v90_ + (z - v93_) * v91_
		local v96_
		if v95_ >= 0 and v95_ <= v94_ then
			local v97_ = (v93_ - z) * v90_ - (v92_ - x) * v91_
			v96_ = math.abs(v97_)
		elseif v95_ < 0 then
			local v98_ = (v92_ - x) * (v92_ - x) + (v93_ - z) * (v93_ - z)
			v96_ = math.sqrt(v98_)
		else
			local v99_ = v89_.startX + v94_ * v90_
			local v100_ = v89_.startZ + v94_ * v91_
			local v101_ = (v99_ - x) * (v99_ - x) + (v100_ - z) * (v100_ - z)
			v96_ = math.sqrt(v101_)
		end
		if v96_ <= v89_.length * 0.5 then
			return true
		end
	end
	return false
end

function PlacementUtil.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".spawnPlaces.spawnPlace(?)#startNode", "Spawn area start node, end node default is first child")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".spawnPlaces.spawnPlace(?)#endNode", "Spawn area end node, end node is first child")
	schema:register(XMLValueType.FLOAT, basePath .. ".spawnPlaces.spawnPlace(?)#width", "Spawn area width in m if no child is present for node")
	schema:register(XMLValueType.FLOAT, basePath .. ".spawnPlaces.spawnPlace(?)#length", "Spawn area length in m if no child is present for node")
	schema:register(XMLValueType.FLOAT, basePath .. ".spawnPlaces.spawnPlace(?)#maxWidth", "Spawn area maximum width of object to spawn")
	schema:register(XMLValueType.FLOAT, basePath .. ".spawnPlaces.spawnPlace(?)#maxLength", "Spawn area maximum length of object to spawn")
	schema:register(XMLValueType.FLOAT, basePath .. ".spawnPlaces.spawnPlace(?)#maxHeight", "Spawn area maximum height of object to spawn")
	schema:register(XMLValueType.BOOL, basePath .. ".spawnPlaces.spawnPlace(?)#isInverted", "Invert the spawn direction of the vehicles", false)
	schema:register(XMLValueType.ANGLE, basePath .. ".spawnPlaces.spawnPlace(?)#palletRotationOffset", "Rotation offset in degrees used for the spawned pallets (offset of 0 spawns pallets perpendicular to line between start and end)", 0)
end
