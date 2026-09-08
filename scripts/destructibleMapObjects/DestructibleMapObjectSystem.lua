-- Local values: DestructibleMapObjectSystem_mt
DestructibleMapObjectSystem = {}
DestructibleMapObjectSystem.GROUP_ID_NUM_BITS = 8
DestructibleMapObjectSystem.MAX_GORUP_ID = 2 ^ DestructibleMapObjectSystem.GROUP_ID_NUM_BITS - 1
DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS = 9
DestructibleMapObjectSystem.MAX_CHILD_INDEX = 2 ^ DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS - 1
DestructibleMapObjectSystem.ERROR_WRONG_DESTRUCTIBLE_TYPE = 0
local DestructibleMapObjectSystem_mt = Class(DestructibleMapObjectSystem)
g_xmlManager:addCreateSchemaFunction(function()
	DestructibleMapObjectSystem.xmlSchemaSavegame = XMLSchema.new("destructibleMapObjects_savegame")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = DestructibleMapObjectSystem.xmlSchemaSavegame
	v2_:register(XMLValueType.INT, "destructibleMapObjects.group(?)#id", "Group id defined as user attribute in map")
	v2_:register(XMLValueType.INT, "destructibleMapObjects.group(?).item(?)#index", "I3d child index of destroyed object in group")
end)

function DestructibleMapObjectSystem.onCreateGroup(_, node)
	g_currentMission.destructibleMapObjectSystem:addGroup(node)
end

-- Upvalues: DestructibleMapObjectSystem_mt
-- Local values: self
function DestructibleMapObjectSystem.new(mission, isServer, customMt)
	-- upvalues: (copy) DestructibleMapObjectSystem_mt
	local v7_ = customMt or DestructibleMapObjectSystem_mt
	local v8_ = setmetatable({}, v7_)
	v8_.mission = mission
	v8_.isServer = isServer
	v8_.groups = {}
	v8_.groupIdToGroupRoot = {}
	v8_.destructibleTypes = {}
	v8_.nodeToDestructible = {}
	v8_.destructibleToGroup = {}
	v8_.destructibleDamage = {}
	v8_.destructibleToRigidBodies = {}
	v8_.destructibleDestroyedListeners = {}
	v8_.activeDestructionAnimations = {}
	v8_.activeDestructionAnimationsToDelete = {}
	addConsoleCommand("gsDestructibleObjectsDebug", "Toggle DestructibleMapObjectSystem debug", "consoleCommandToggleDebug", v8_)
	if v8_.isServer then
		addConsoleCommand("gsDestructibleObjectsDamageAdd", "Add damage to destructible object camera is pointed at", "consoleCommandNodeAddDamage", v8_)
	end
	return v8_
end

function DestructibleMapObjectSystem:delete()
	g_currentMission:removeUpdateable(self)
	removeConsoleCommand("gsDestructibleObjectsDebug")
	removeConsoleCommand("gsDestructibleObjectsDestroy")
end

-- Local values: groupRoot, group, childIndices, numChildren, childIndex
function DestructibleMapObjectSystem:onClientJoined(connection)
	for v12_, v13_ in pairs(self.groups) do
		local v14_ = {}
		for v15_ = 0, getNumOfChildren(v12_) - 1 do
			v14_[v15_ + 1] = not getVisibility(getChildAt(v12_, v15_))
		end
		connection:sendEvent(DestroyedMapObjectsEvent.new(v13_.groupId, v14_))
	end
end

-- Local values: printUserAttributeInterface, destructibleType, groupId, dropFillTypeName, dropFillTypeIndex, dropAmount, destructionVolume, animDurationScrollPositionSec, animDurationHideByIndexSec, animDelayHideByIndexSec, group, numChildren, addRigidBodyToMapping, childIndex, childNode, hasCol, checkRigidBody
function DestructibleMapObjectSystem:addGroup(groupRootNode)
	local function v18_()
		print("Supported userAttributes next to DestructibleMapObjectSystem.onCreate")
		printf("    \'destructibleType\'           (string)  (required) - string used to differentiate between different types of objects, e.g. used for which tools can work on them")
		printf("    \'groupId\'                    (integer) (required if more than one group exists) default: 0; allowed values: 0 - %d)", DestructibleMapObjectSystem.MAX_GORUP_ID)
		printf("    \'dropFillTypeName\'           (string)  (optional) default: nil - fillTypeName of tipAny dropped upon destruction")
		printf("    \'dropAmount\'                 (float)   (optional) default: 500 - amount of tipAny dropped upon destruction")
		printf("    \'destructionVolume\'          (float)   (optional) default: 50 - destruction amount trequired to destroy the object")
		printf("    \'animDurationScrollPosition\' (float)   (optional) default: 2 - duration for destruction animation shader parameter scrollPosition in seconds")
		printf("    \'animDurationHideByIndex\'    (float)   (optional) default: 1 - duration for destruction animation shader parameter hideByIndex in seconds")
		printf("    \'animDelayHideByIndex\'       (float)   (optional) default: 0.75 * animDurationScrollPosition - delay for start of hideByIndex animation in seconds")
	end
	local v19_ = getUserAttribute(groupRootNode, "destructibleType")
	if v19_ == nil then
		Logging.error("Missing userAttribute \'destructibleType\' for \'%s\'", I3DUtil.getNodePath(groupRootNode))
		v18_()
		return false
	end
	local v20_ = getUserAttribute
	local v21_ = tonumber(v20_(groupRootNode, "groupId")) or 0
	local v22_ = math.floor(v21_)
	if v22_ < 0 or DestructibleMapObjectSystem.MAX_GORUP_ID < v22_ then
		Logging.error("GroupId \'%d\' for %s out of allowed rage [0 %d]", v22_, I3DUtil.getNodePath(groupRootNode), DestructibleMapObjectSystem.MAX_GORUP_ID)
		return false
	end
	if self.groupIdToGroupRoot[v22_] ~= nil then
		Logging.error("GroupId \'%d\' of \'%s\' already in use in \'%s\'. Please use a different groupId", v22_, I3DUtil.getNodePath(groupRootNode), I3DUtil.getNodePath(self.groupIdToGroupRoot[v22_]))
		v18_()
		return false
	end
	local v23_ = getUserAttribute(groupRootNode, "dropFillTypeName") or v19_
	local v24_ = g_fillTypeManager:getFillTypeIndexByName(v23_)
	local v25_ = getUserAttribute(groupRootNode, "dropAmount") or 500
	local v26_ = getUserAttribute(groupRootNode, "destructionVolume") or 50
	local v27_ = getUserAttribute(groupRootNode, "animDurationScrollPosition") or 2
	local v28_ = getUserAttribute(groupRootNode, "animDurationHideByIndex") or 2
	local v29_ = getUserAttribute(groupRootNode, "animDelayHideByIndex") or 0.75 * v27_
	local v_u_30_ = {
		["destructibleType"] = string.upper(v19_),
		["groupId"] = v22_,
		["dropFillTypeIndex"] = v24_,
		["dropAmount"] = v25_,
		["destructionVolume"] = v26_,
		["animDurationScrollPosition"] = v27_ * 1000,
		["animDurationHideByIndex"] = v28_ * 1000,
		["animDelayHideByIndex"] = v29_ * 1000
	}
	self.groupIdToGroupRoot[v22_] = groupRootNode
	self.groups[groupRootNode] = v_u_30_
	if self.destructibleTypes[v19_] == nil then
		self.destructibleTypes[v19_] = {}
	end
	self.destructibleTypes[v19_][v_u_30_] = true
	local v31_ = getNumOfChildren(groupRootNode)
	if DestructibleMapObjectSystem.MAX_CHILD_INDEX < v31_ then
		Logging.warning("Only %d child nodes supported per group, group has %d. Ignoring additional children for \'%s\'", DestructibleMapObjectSystem.MAX_CHILD_INDEX + 1, v31_, I3DUtil.getNodePath(groupRootNode))
		v31_ = DestructibleMapObjectSystem.MAX_CHILD_INDEX
	end
	for v32_ = 0, v31_ - 1 do
		local v_u_33_ = getChildAt(groupRootNode, v32_)
		local v_u_34_ = false
		local function v38_(p35_)
			-- upvalues: (copy) v_u_33_, (copy) self, (copy) v_u_30_, (ref) v_u_34_
			if getRigidBodyType(p35_) ~= RigidBodyType.NONE then
				local v36_ = v_u_33_
				self.nodeToDestructible[p35_] = v36_
				self.destructibleToGroup[v36_] = v_u_30_
				self.destructibleToRigidBodies[v36_] = self.destructibleToRigidBodies[v36_] or {}
				local v37_ = self.destructibleToRigidBodies[v36_]
				table.insert(v37_, p35_)
				v_u_34_ = true
			end
			return true
		end
		I3DUtil.iterateRecursively(v_u_33_, v38_, true)
		if not v_u_34_ then
			Logging.warning("Child %d (%s) of group \'%s\' has no collision mesh in any of its children and will not be destroyable ingame", v32_, getName(v_u_33_), I3DUtil.getNodePath(groupRootNode))
		end
	end
	return true
end

function DestructibleMapObjectSystem:registerDestructibleDestroyedListener(target, func)
	self.destructibleDestroyedListeners[target] = func
end

function DestructibleMapObjectSystem:unregisterDestructibleDestroyedListener(target)
	self.destructibleDestroyedListeners[target] = nil
end

-- Local values: destructible, group
function DestructibleMapObjectSystem:getDestructibleFromNode(nodeId, destructibleTypes)
	local v47_ = self.nodeToDestructible[nodeId]
	if v47_ and destructibleTypes ~= nil then
		local v48_ = self.destructibleToGroup[v47_]
		if v48_ == nil or not destructibleTypes[v48_.destructibleType] then
			return nil, DestructibleMapObjectSystem.ERROR_WRONG_DESTRUCTIBLE_TYPE
		else
			return v47_
		end
	else
		return v47_
	end
end

function DestructibleMapObjectSystem:getGroupAndIndexForDestructible(destructible)
	return self.destructibleToGroup[destructible], getChildIndex(destructible)
end

function DestructibleMapObjectSystem:getGroupRootById(groupId)
	return self.groupIdToGroupRoot[groupId]
end

function DestructibleMapObjectSystem:getDestructibleRigidBodies(destructible)
	return self.destructibleToRigidBodies[destructible]
end

-- Local values: group, totalDamage, relativeProgress
function DestructibleMapObjectSystem:addDestructibleDamage(destructible, damage)
	local v58_ = self.destructibleToGroup[destructible]
	if v58_ == nil then
		return nil
	end
	local v59_ = (self.destructibleDamage[destructible] or 0) + damage
	local v60_ = math.max(0, v59_)
	local v61_ = v60_ / v58_.destructionVolume
	if v58_.destructionVolume <= v60_ then
		if self.isServer then
			self:destroyDestructible(destructible, true)
			return 1, v58_.destructionVolume
		end
	else
		self.destructibleDamage[destructible] = v60_
	end
	return v61_, v60_
end

-- Local values: lx, ly, lz, bvRadius, wx, wz, minX, maxX, minZ, maxZ, rigidBodies, _, rigidBody
function DestructibleMapObjectSystem:setDestructiblePhysicsActive(destructible, isActive)
	local v65_ = nil
	local v66_ = self.destructibleToRigidBodies[destructible]
	if v66_ ~= nil then
		for _, v67_ in ipairs(v66_) do
			if isActive then
				addToPhysics(v67_)
			else
				removeFromPhysics(v67_)
			end
			local v68_, v69_, v70_
			v68_, v69_, v70_, v65_ = getShapeBoundingSphere(v67_)
			local v71_, _, v72_ = localToWorld(v67_, v68_, v69_, v70_)
			local v73_ = v71_ - v65_
			local v74_ = v71_ + v65_
			local v75_ = v72_ - v65_
			local v76_ = v72_ + v65_
			g_densityMapHeightManager:setCollisionMapAreaDirty(v73_, v75_, v74_, v76_, true)
			self.mission.aiSystem:setAreaDirty(v73_, v74_, v75_, v76_)
		end
	end
	return v65_
end

-- Local values: rigidBodies, _, rigidBody, _, _, _, bvRadius, wx, _, wz, circle
function DestructibleMapObjectSystem:restoreDestructible(destructible)
	local v79_ = self.destructibleToRigidBodies[destructible]
	if v79_ ~= nil then
		for _, v80_ in ipairs(v79_) do
			local _, _, _, v81_ = getShapeBoundingSphere(v80_)
			local v82_, _, v83_ = getWorldTranslation(v80_)
			local v84_ = DensityMapCircle.createCircle(v82_, v83_, v81_, 8)
			DensityMapHeightUtil.clear(v84_)
		end
	end
	I3DUtil.setShaderParameterRec(destructible, "scrollPos", 0, nil, nil, nil)
	I3DUtil.setShaderParameterRec(destructible, "prevScrollPos", 0, nil, nil, nil)
	I3DUtil.setShaderParameterRec(destructible, "hidePieces", 0, nil, nil, nil)
	self:setDestructiblePhysicsActive(destructible, true)
	setVisibility(destructible, true)
	self.destructibleDamage[destructible] = nil
end

-- Local values: bvRadius, group, wx, wy, wz, halfWidth, startX, startY, startZ, endX, endY, endZ, heightX, heightY, heightZ, lsx, lsy, lsz, lex, ley, lez, radius, group, childIndex, target, func
function DestructibleMapObjectSystem:destroyDestructible(destructible, dropTipAny)
	local v88_ = self:setDestructiblePhysicsActive(destructible, false)
	if dropTipAny then
		local v89_ = self.destructibleToGroup[destructible]
		if v89_.dropFillTypeIndex ~= nil and v89_.dropAmount > 0 then
			local v90_, v91_, v92_ = getWorldTranslation(destructible)
			local v93_ = v88_ / 2
			local v94_ = v90_ - v93_
			local v95_ = v92_ - v93_
			local v96_ = v90_ - v93_
			local v97_ = v92_ + v93_
			local v98_ = v90_ + v93_
			local v99_ = v92_ - v93_
			local v100_, v101_, v102_, v103_, v104_, v105_, v106_ = DensityMapHeightUtil.getLineByAreaDimensions(v94_, v91_, v95_, v96_, v91_, v97_, v98_, v91_, v99_, false)
			DensityMapHeightUtil.tipToGroundAroundLine(nil, v89_.dropAmount, v89_.dropFillTypeIndex, v100_, v101_, v102_, v103_, v104_, v105_, v106_, nil, nil, nil, nil)
		end
	end
	if g_server ~= nil then
		local v107_ = self.destructibleToGroup[destructible]
		if v107_ ~= nil then
			local v108_ = getChildIndex(destructible)
			g_server:broadcastEvent(MapObjectDestroyedEvent.new(v107_.groupId, v108_))
		end
	end
	for v109_, v110_ in pairs(self.destructibleDestroyedListeners) do
		v110_(v109_, destructible)
	end
	if I3DUtil.getHasShaderParameterRec(destructible, "hidePieces") or I3DUtil.getHasShaderParameterRec(destructible, "scrollPos") then
		if self.activeDestructionAnimations[destructible] == nil then
			self.activeDestructionAnimations[destructible] = 0
			g_currentMission:addUpdateable(self)
			return
		end
	else
		self:setDestructibleDestroyed(destructible, false)
	end
end

function DestructibleMapObjectSystem:setDestructibleDestroyed(destructible, updatePhysics)
	if updatePhysics then
		self:setDestructiblePhysicsActive(destructible, false)
	end
	setVisibility(destructible, false)
	self.destructibleDamage[destructible] = nil
end

-- Local values: groupRoot
function DestructibleMapObjectSystem:setGroupChildIndexDestroyed(groupId, childIndex, dropTipAny, playAnimation)
	local v119_ = self.groupIdToGroupRoot[groupId]
	if v119_ == nil then
		Logging.error("DestructibleMapObjectSystem: Unable to get groupRoot for group id \'%s\'", groupId)
	end
	self:setChildIndexDestroyed(v119_, childIndex, dropTipAny, playAnimation)
end

-- Local values: group, destructible
function DestructibleMapObjectSystem:setChildIndexDestroyed(groupRoot, childIndex, dropTipAny, playAnimation)
	if getNumOfChildren(groupRoot) < childIndex then
		local v125_ = self.groups[groupRoot]
		Logging.warning("DestructibleMapObjectSystem: Unable to set state on child index %d, group %d at \'%s\' only has %d children", childIndex, v125_.groupId, I3DUtil.getNodePath(groupRoot), getNumOfChildren(groupRoot))
		return
	else
		local v126_ = getChildAt(groupRoot, childIndex)
		if playAnimation then
			self:destroyDestructible(v126_, dropTipAny)
		else
			self:setDestructibleDestroyed(v126_, true)
		end
	end
end

-- Local values: destructedChildIndices, numChildren, childIndex
function DestructibleMapObjectSystem:getDestructedChildIndices(groupRoot)
	local v128_ = {}
	for v129_ = 0, getNumOfChildren(groupRoot) - 1 do
		if not getVisibility(getChildAt(groupRoot, v129_)) then
			table.insert(v128_, v129_)
		end
	end
	return v128_
end

-- Local values: xmlFile, numItems
function DestructibleMapObjectSystem:saveToXMLFile(xmlPath, usedModNames)
	if xmlPath ~= nil and next(self.groups) ~= nil then
		local v_u_132_ = XMLFile.create("DestructibleMapObjectSystemXML", xmlPath, "destructibleMapObjects", DestructibleMapObjectSystem.xmlSchemaSavegame)
		local v_u_133_ = 0
		v_u_132_:setTable("destructibleMapObjects.group", self.groups, function(p134_, p135_, p136_)
			-- upvalues: (copy) self, (ref) v_u_133_, (copy) v_u_132_
			local v137_ = self:getDestructedChildIndices(p136_)
			if #v137_ == 0 then
				return 0
			end
			v_u_133_ = v_u_133_ + #v137_
			v_u_132_:setValue(p134_ .. "#id", p135_.groupId)
			v_u_132_:setTable(p134_ .. ".item", v137_, function(p138_, p139_, _)
				-- upvalues: (ref) v_u_132_
				v_u_132_:setValue(p138_ .. "#index", p139_)
			end)
		end)
		v_u_132_:save()
		v_u_132_:delete()
	end
end

-- Local values: xmlFile, loadedGroups, loadedChildren
function DestructibleMapObjectSystem:loadFromSavegameXML(xmlPath)
	if xmlPath ~= nil and next(self.groups) ~= nil then
		local v_u_142_ = XMLFile.loadIfExists("DestructibleMapObjectSystemXML", xmlPath, DestructibleMapObjectSystem.xmlSchemaSavegame)
		if v_u_142_ ~= nil then
			local v_u_143_ = 0
			local v_u_144_ = 0
			v_u_142_:iterate("destructibleMapObjects.group", function(_, p145_)
				-- upvalues: (copy) v_u_142_, (copy) self, (ref) v_u_143_, (ref) v_u_144_
				local v146_ = v_u_142_:getValue(p145_ .. "#id")
				if v146_ == nil then
					Logging.xmlWarning(v_u_142_, "Group %s is missing an \'id\' attribute", p145_)
					return true
				end
				local v_u_147_ = self.groupIdToGroupRoot[v146_]
				if v_u_147_ == nil then
					Logging.xmlWarning(v_u_142_, "Group with id \'%s\' (%s) does not exist in map", v146_, p145_)
					return true
				end
				v_u_143_ = v_u_143_ + 1
				v_u_142_:iterate(p145_ .. ".item", function(_, p148_)
					-- upvalues: (ref) v_u_142_, (ref) v_u_144_, (ref) self, (copy) v_u_147_
					local v149_ = v_u_142_:getValue(p148_ .. "#index")
					v_u_144_ = v_u_144_ + 1
					self:setChildIndexDestroyed(v_u_147_, v149_, false)
				end)
				return true
			end)
			v_u_142_:delete()
			return
		end
		Logging.devInfo("DestructibleMapObjectSystem: no xml to load from savegame")
	end
end

-- Local values: destructible, animationTime, group, shaderValue, shaderValue, i, destructible
function DestructibleMapObjectSystem:update(dt)
	for v152_, v153_ in pairs(self.activeDestructionAnimations) do
		local v154_ = v153_ + dt
		self.activeDestructionAnimations[v152_] = v154_
		local v155_ = self.destructibleToGroup[v152_]
		if v154_ < v155_.animDurationScrollPosition then
			local v156_ = v154_ / v155_.animDurationScrollPosition
			I3DUtil.setShaderParameterRec(v152_, "scrollPos", v156_, nil, nil, nil)
			local v157_ = (v154_ - dt) / v155_.animDurationScrollPosition
			I3DUtil.setShaderParameterRec(v152_, "prevScrollPos", v157_, nil, nil, nil)
		end
		if v155_.animDelayHideByIndex < v154_ and v154_ < v155_.animDelayHideByIndex + v155_.animDurationHideByIndex then
			local v158_ = (v154_ - v155_.animDelayHideByIndex) / v155_.animDurationHideByIndex
			I3DUtil.setShaderParameterRec(v152_, "hidePieces", v158_, nil, nil, nil)
		end
		if v155_.animDelayHideByIndex + v155_.animDurationHideByIndex < v154_ then
			self:setDestructibleDestroyed(v152_, false)
			local v159_ = self.activeDestructionAnimationsToDelete
			table.insert(v159_, v152_)
		end
	end
	for v160_ = #self.activeDestructionAnimationsToDelete, 1, -1 do
		local v161_ = self.activeDestructionAnimationsToDelete[v160_]
		self.activeDestructionAnimations[v161_] = nil
		table.remove(self.activeDestructionAnimationsToDelete, v160_)
	end
	if next(self.activeDestructionAnimations) == nil then
		g_currentMission:removeUpdateable(self)
	end
end

-- Local values: cam, wx, wy, wz, dx, dy, dz, distance, callbackNode, destructible, destructibleTypeGroups, destuctionPercentage, totalDamange, group
function DestructibleMapObjectSystem:consoleCommandNodeAddDamage(damageAmount, destructibleType)
	local v165_ = tonumber(damageAmount) or 5
	if destructibleType then
		destructibleType = string.upper(destructibleType)
	end
	local v166_ = getCamera()
	local v167_, v168_, v169_ = getWorldTranslation(v166_)
	local v170_, v171_, v172_ = localDirectionToWorld(v166_, 0, 0, -1)
	local v173_ = v167_ + v170_
	local v174_ = v168_ + v171_
	local v175_ = v169_ + v172_
	raycastClosest(v173_, v174_, v175_, v170_, v171_, v172_, 30, "consoleCommandNodeAddDamageRaycastCallback", self, CollisionMask.ALL - CollisionFlag.PLAYER)
	local v176_ = self.callbackNode
	self.callbackNode = nil
	local v177_ = self.nodeToDestructible[v176_]
	if v177_ then
		if destructibleType ~= nil then
			local v178_ = self.destructibleTypes[destructibleType]
			if not (v178_ and v178_[self.destructibleToGroup[v177_]]) then
				return string.format("No destructible found for given destructible type \'%s\'", destructibleType)
			end
		end
		local v179_, v180_ = self:addDestructibleDamage(v177_, v165_, true)
		local v181_ = self.destructibleToGroup[v177_]
		if v179_ >= 1 then
			return string.format("Destroyed destructible %d (Type:%s) of group %d", getChildIndex(v177_), v181_.destructibleType, v181_.groupId)
		else
			return string.format("Added %d damage (%d%%, %d total) to destructible %d (Type:%s) of group %d", v165_, v179_ * 100, v180_, getChildIndex(v177_), v181_.destructibleType, v181_.groupId)
		end
	else
		return "No destructible found"
	end
end

function DestructibleMapObjectSystem:consoleCommandNodeAddDamageRaycastCallback(transformId, x, y, z, distance, nx, ny, nz)
	if getName(transformId) == "playerCCT" then
		return true
	end
	self.callbackNode = transformId
	return false
end

-- Local values: groupRootNode, group, color, numChildren, childIndex, destructibleNode, text, note, groupRootNode, group, numChildren, childIndex, destructibleNode, note
function DestructibleMapObjectSystem:consoleCommandToggleDebug()
	if self.mission:getHasDrawable(self) then
		self.mission:removeDrawable(self)
		for v185_, _ in pairs(self.groups) do
			for v186_ = 0, getNumOfChildren(v185_) - 1 do
				local v187_ = getChildAt(v185_, v186_)
				local v188_ = getChild(v187_, "destructibleDebugNote")
				if v188_ ~= 0 then
					delete(v188_)
				end
			end
		end
		return "DestructibleMapObjectSystem: Disabled debug"
	end
	self.mission:addDrawable(self)
	for v189_, v190_ in pairs(self.groups) do
		local v191_ = DebugUtil.tableToColor(v190_)
		for v192_ = 0, getNumOfChildren(v189_) - 1 do
			local v193_ = getChildAt(v189_, v192_)
			if getVisibility(v193_) then
				local v194_ = string.format("%s #%d\ndestuction volume %d\ndrop amount %d", getName(v189_), v192_, v190_.destructionVolume, v190_.dropAmount)
				local v195_ = createNoteNode(v193_, v194_, v191_[1], v191_[2], v191_[3])
				setName(v195_, "destructibleDebugNote")
				setTranslation(v195_, 0, 2.5, 0)
			end
		end
	end
	if g_isDevelopmentVersion then
		executeConsoleCommand("enableNoteRendering true")
	end
	return "DestructibleMapObjectSystem: Enabled debug"
end

-- Local values: textSize, startY, i, groupRootNode, group, destructedChildIndices, childNumber, childIndex, typeName, groups, destructible, damage
function DestructibleMapObjectSystem:draw()
	setTextBold(false)
	local v197_ = 1
	if next(self.groups) then
		renderText(0.28, 0.97, 0.015, string.format("%d Groups - Total num destructibles: %d", table.size(self.groups), table.size(self.nodeToDestructible)))
		for v198_, v199_ in pairs(self.groups) do
			local v200_ = self:getDestructedChildIndices(v198_)
			renderText(0.3, 0.97 - v197_ * 0.015, 0.015, string.format("%s (%s) (%s) - %d destructibles - %d destroyed", getName(v198_), v198_, v199_.destructibleType, getNumOfChildren(v198_), #v200_))
			for v201_, v202_ in ipairs(v200_) do
				v197_ = v197_ + 1
				renderText(0.32, 0.97 - v197_ * 0.015, 0.015, string.format("#%d - node child index: %d", v201_, v202_))
			end
			v197_ = v197_ + 1
		end
		local v203_ = v197_ + 1
		if next(self.destructibleTypes) then
			renderText(0.28, 0.97 - v203_ * 0.015, 0.015, "Destructible Types")
			v203_ = v203_ + 1
			for v204_, v205_ in pairs(self.destructibleTypes) do
				renderText(0.3, 0.97 - v203_ * 0.015, 0.015, string.format("%s - num groups: %d", v204_, table.size(v205_)))
				v203_ = v203_ + 1
			end
		end
		local v206_ = v203_ + 1
		if next(self.destructibleDamage) then
			renderText(0.28, 0.97 - v206_ * 0.015, 0.015, "Destructible Damage")
			local v207_ = v206_ + 1
			for v208_, v209_ in pairs(self.destructibleDamage) do
				renderText(0.3, 0.97 - v207_ * 0.015, 0.015, string.format("%s: %d", getName(v208_), v209_))
				v207_ = v207_ + 1
			end
		end
		if g_currentMission:getHasUpdateable(self) then
			setTextColor(1, 0, 0, 1)
			renderText(0.5, 0.2, 0.02, "update/animation active")
			setTextColor(1, 1, 1, 1)
		end
	else
		renderText(0.32, 0.97 - v197_ * 0.015, 0.015, string.format("no destructibles defined in map"))
	end
end
