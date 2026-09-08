PlaceableTriggerMarkers = {}

function PlaceableTriggerMarkers.prerequisitesPresent(specializations)
	return true
end

function PlaceableTriggerMarkers.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableTriggerMarkers)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableTriggerMarkers)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableTriggerMarkers)
	SpecializationUtil.registerEventListener(placeableType, "onOwnerChanged", PlaceableTriggerMarkers)
end

function PlaceableTriggerMarkers.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onPlayerFarmChanged", PlaceableTriggerMarkers.onPlayerFarmChanged)
	SpecializationUtil.registerFunction(placeableType, "onMarkerFileLoaded", PlaceableTriggerMarkers.onMarkerFileLoaded)
	SpecializationUtil.registerFunction(placeableType, "getTriggerMarkerPosition", PlaceableTriggerMarkers.getTriggerMarkerPosition)
	SpecializationUtil.registerFunction(placeableType, "setShowMarkers", PlaceableTriggerMarkers.setShowMarkers)
end

function PlaceableTriggerMarkers.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("TriggerMarkers")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".triggerMarkers.triggerMarker(?)#node", "Trigger marker node")
	schema:register(XMLValueType.FILENAME, basePath .. ".triggerMarkers.triggerMarker(?)#filename", "Trigger marker i3d filename")
	schema:register(XMLValueType.BOOL, basePath .. ".triggerMarkers.triggerMarker(?)#adjustToGround", "Trigger marker adjusted to ground")
	schema:register(XMLValueType.FLOAT, basePath .. ".triggerMarkers.triggerMarker(?)#groundOffset", "Height of the trigger marker above the ground if adjustToGround is enabled", 0.03)
	schema:register(XMLValueType.BOOL, basePath .. ".triggerMarkers.triggerMarker(?)#showAllPlayers", "Show marker for all players even if they do not have access to the placeable", false)
	schema:register(XMLValueType.BOOL, basePath .. ".triggerMarkers.triggerMarker(?)#showOnlyIfOwned", "Show marker only if owned", false)
	schema:setXMLSpecializationType()
end

-- Local values: spec, xmlFile, _, key, node, adjustToGround, groundOffset, i3dFilename, showAllPlayers, showOnlyIfOwned, marker, loadingTask, args, sharedLoadRequestId
function PlaceableTriggerMarkers:onLoad(savegame)
	local v6_ = self.spec_triggerMarkers
	local v7_ = self.xmlFile
	v6_.sharedLoadRequestIds = {}
	v6_.triggerMarkers = {}
	for _, v8_ in v7_:iterator("placeable.triggerMarkers.triggerMarker") do
		local v9_ = v7_:getValue(v8_ .. "#node", nil, self.components, self.i3dMappings)
		if v9_ == nil then
			Logging.xmlWarning(v7_, "Missing trigger marker node for \'%s\'", v8_)
		else
			local v10_ = v7_:getValue(v8_ .. "#adjustToGround", false)
			local v11_ = v7_:getValue(v8_ .. "#groundOffset")
			if v11_ ~= nil and not v10_ then
				Logging.xmlWarning(v7_, "\'groundOffset=%.2f\' given but \'adjustToGround\' is false for \'%s\'", v11_, v8_)
			end
			local v12_ = self.xmlFile:getValue(v8_ .. "#filename", nil, self.baseDirectory)
			local v13_ = {
				["node"] = v9_,
				["i3dFilename"] = v12_,
				["adjustToGround"] = v10_,
				["groundOffset"] = v11_ or 0.03,
				["showAllPlayers"] = self.xmlFile:getValue(v8_ .. "#showAllPlayers", false),
				["showOnlyIfOwned"] = self.xmlFile:getValue(v8_ .. "#showOnlyIfOwned", false)
			}
			if v12_ ~= nil then
				local v14_ = {
					["marker"] = v13_,
					["loadingTask"] = self:createLoadingTask()
				}
				local v15_ = g_i3DManager:loadSharedI3DFileAsync(v12_, false, false, self.onMarkerFileLoaded, self, v14_)
				local v16_ = v6_.sharedLoadRequestIds
				table.insert(v16_, v15_)
			end
			local v17_ = v6_.triggerMarkers
			table.insert(v17_, v13_)
		end
	end
end

-- Local values: linkNode, loadingTask
function PlaceableTriggerMarkers:onMarkerFileLoaded(i3dNode, failedReason, args)
	local v21_ = args.marker.node
	local v22_ = args.loadingTask
	if i3dNode ~= 0 then
		link(v21_, i3dNode)
		args.marker.node = i3dNode
	end
	self:finishLoadingTask(v22_)
end

-- Local values: spec, _, sharedLoadRequestId, _, marker
function PlaceableTriggerMarkers:onDelete()
	local v24_ = self.spec_triggerMarkers
	if v24_.sharedLoadRequestIds ~= nil then
		for _, v25_ in ipairs(v24_.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(v25_)
		end
		v24_.sharedLoadRequestIds = nil
	end
	if v24_.triggerMarkers ~= nil then
		for _, v26_ in ipairs(v24_.triggerMarkers) do
			g_currentMission:removeTriggerMarker(v26_.node)
		end
	end
	g_messageCenter:unsubscribe(MessageType.PLAYER_FARM_CHANGED, self)
	g_messageCenter:unsubscribe(MessageType.PLAYER_CREATED, self)
end

-- Local values: spec, _, marker, x, _, z, y
function PlaceableTriggerMarkers:onFinalizePlacement()
	local v28_ = self.spec_triggerMarkers
	if g_terrainNode ~= nil then
		for _, v29_ in ipairs(v28_.triggerMarkers) do
			if v29_.adjustToGround then
				local v30_, _, v31_ = getWorldTranslation(v29_.node)
				local v32_ = getTerrainHeightAtWorldPos(g_terrainNode, v30_, 0, v31_) + v29_.groundOffset
				setWorldTranslation(v29_.node, v30_, v32_, v31_)
			end
		end
	end
	self:setShowMarkers(g_currentMission.accessHandler:canPlayerAccess(self))
	g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.onPlayerFarmChanged, self)
	g_messageCenter:subscribe(MessageType.PLAYER_CREATED, self.onPlayerFarmChanged, self)
end

function PlaceableTriggerMarkers:onOwnerChanged()
	self:setShowMarkers(g_currentMission.accessHandler:canPlayerAccess(self))
end

function PlaceableTriggerMarkers:onPlayerFarmChanged()
	self:setShowMarkers(g_currentMission.accessHandler:canPlayerAccess(self))
end

-- Local values: spec, ownerFarmId, isOwned, _, marker, show
function PlaceableTriggerMarkers:setShowMarkers(doShow)
	local v37_ = self.spec_triggerMarkers
	local v38_ = self:getOwnerFarmId()
	local v39_
	if v38_ == AccessHandler.EVERYONE then
		v39_ = false
	else
		v39_ = v38_ ~= AccessHandler.NOBODY
	end
	for _, v40_ in ipairs(v37_.triggerMarkers) do
		local v41_ = doShow or v40_.showAllPlayers
		if v40_.showOnlyIfOwned and not v39_ then
			v41_ = false
		end
		if v41_ then
			g_currentMission:addTriggerMarker(v40_.node)
		else
			g_currentMission:removeTriggerMarker(v40_.node)
		end
	end
end

-- Local values: spec, marker
function PlaceableTriggerMarkers:getTriggerMarkerPosition(index)
	local v44_ = self.spec_triggerMarkers.triggerMarkers[index]
	if v44_ == nil then
		return nil
	else
		return getWorldTranslation(v44_.node)
	end
end
