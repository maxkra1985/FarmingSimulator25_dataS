PlaceableAnimatedObjects = {}

function PlaceableAnimatedObjects.prerequisitesPresent(specializations)
	return true
end

function PlaceableAnimatedObjects.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "getCanTriggerAnimatedObject", PlaceableAnimatedObjects.getCanTriggerAnimatedObject)
	SpecializationUtil.registerFunction(placeableType, "getAnimatedObjectBySaveId", PlaceableAnimatedObjects.getAnimatedObjectBySaveId)
end

function PlaceableAnimatedObjects.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableAnimatedObjects.setOwnerFarmId)
end

function PlaceableAnimatedObjects.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableAnimatedObjects)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableAnimatedObjects)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableAnimatedObjects)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableAnimatedObjects)
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableAnimatedObjects)
end

function PlaceableAnimatedObjects.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("AnimatedObjects")
	AnimatedObject.registerXMLPaths(schema, basePath .. ".animatedObjects")
	schema:register(XMLValueType.INT, basePath .. ".animatedObjects.animatedObject(?).dependency(?)#animatedObjectIndex", "Animated object index")
	schema:register(XMLValueType.FLOAT, basePath .. ".animatedObjects.animatedObject(?).dependency(?)#minTime", "Min Time")
	schema:register(XMLValueType.FLOAT, basePath .. ".animatedObjects.animatedObject(?).dependency(?)#maxTime", "Max Time")
	schema:setXMLSpecializationType()
end

function PlaceableAnimatedObjects.registerSavegameXMLPaths(schema, basePath)
	AnimatedObject.registerSavegameXMLPaths(schema, basePath .. ".animatedObject(?)")
end

-- Local values: spec, xmlFile, index, animationKey, animatedObject, _, dependencyKey, dependendIndex, minTime, maxTime, dependency, _, animatedObject
function PlaceableAnimatedObjects:onLoad(savegame)
	local v_u_9_ = self.spec_animatedObjects
	local v_u_10_ = self.xmlFile
	v_u_9_.animatedObjects = {}
	for v11_, v12_ in v_u_10_:iterator("placeable.animatedObjects.animatedObject") do
		local v13_ = AnimatedObject.new(self.isServer, self.isClient)
		v13_.dependencies = {}
		for _, v14_ in v_u_10_:iterator(v12_ .. ".dependency") do
			local v15_ = v_u_10_:getInt(v14_ .. "#animatedObjectIndex")
			if v15_ == nil then
				Logging.xmlError(v_u_10_, "Missing animatedObjectIndex for \'%s\'", v14_)
			else
				local v16_ = {
					["objectIndex"] = v15_,
					["minTime"] = v_u_10_:getValue(v14_ .. "#minTime", 0),
					["maxTime"] = v_u_10_:getValue(v14_ .. "#maxTime", 0)
				}
				local v17_ = v13_.dependencies
				table.insert(v17_, v16_)
			end
		end
		if v13_:load(self.components, v_u_10_, v12_, self.configFileName, self.i3dMappings) then
			local v18_ = v_u_9_.animatedObjects
			table.insert(v18_, v13_)
		else
			Logging.xmlError(v_u_10_, "Failed to load animated object %i", v11_)
		end
	end
	for _, v_u_19_ in ipairs(v_u_9_.animatedObjects) do
		v_u_19_.getCanBeTriggered = Utils.overwrittenFunction(v_u_19_.getCanBeTriggered, function(_, p20_)
			-- upvalues: (copy) v_u_19_, (copy) self, (copy) v_u_9_, (copy) v_u_10_
			if not p20_(v_u_19_) then
				return false
			end
			if not self:getCanTriggerAnimatedObject(v_u_19_) then
				return false
			end
			if #v_u_19_.dependencies > 0 then
				for _, v21_ in ipairs(v_u_19_.dependencies) do
					local v22_ = v_u_9_.animatedObjects[v21_.objectIndex]
					if v22_ == nil then
						Logging.xmlWarning(v_u_10_, "Invalid dependency animated object index \'%d\'", v21_.objectIndex)
					else
						local v23_ = v22_.animation.time
						if v23_ < v21_.minTime or v21_.maxTime < v23_ then
							return false
						end
					end
				end
			end
			return true
		end)
	end
end

-- Local values: spec, _, animatedObject
function PlaceableAnimatedObjects:onDelete()
	local v25_ = self.spec_animatedObjects
	if v25_.animatedObjects ~= nil then
		for _, v26_ in ipairs(v25_.animatedObjects) do
			v26_:delete()
		end
		v25_.animatedObjects = nil
	end
end

-- Local values: spec, _, animatedObject
function PlaceableAnimatedObjects:onPostFinalizePlacement()
	local v28_ = self.spec_animatedObjects
	for _, v29_ in ipairs(v28_.animatedObjects) do
		v29_:register(true)
		v29_:setOwnerFarmId(self.ownerFarmId, true)
	end
end

-- Local values: spec, _, animatedObject, animatedObjectId
function PlaceableAnimatedObjects:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local v33_ = self.spec_animatedObjects
		for _, v34_ in ipairs(v33_.animatedObjects) do
			local v35_ = NetworkUtil.readNodeObjectId(streamId)
			v34_:readStream(streamId, connection)
			g_client:finishRegisterObject(v34_, v35_)
		end
	end
end

-- Local values: spec, _, animatedObject
function PlaceableAnimatedObjects:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local v39_ = self.spec_animatedObjects
		for _, v40_ in ipairs(v39_.animatedObjects) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v40_))
			v40_:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, v40_)
		end
	end
end

-- Local values: spec, i, animatedObject
function PlaceableAnimatedObjects:loadFromXMLFile(xmlFile, key)
	local v44_ = self.spec_animatedObjects
	for v45_, v46_ in ipairs(v44_.animatedObjects) do
		v46_:loadFromXMLFile(xmlFile, string.format("%s.animatedObject(%d)", key, v45_ - 1))
	end
end

-- Local values: spec, i, animatedObject
function PlaceableAnimatedObjects:saveToXMLFile(xmlFile, key, usedModNames)
	local v51_ = self.spec_animatedObjects
	for v52_, v53_ in ipairs(v51_.animatedObjects) do
		v53_:saveToXMLFile(xmlFile, string.format("%s.animatedObject(%d)", key, v52_ - 1), usedModNames)
	end
end

-- Local values: ownerFarmId
function PlaceableAnimatedObjects:getCanTriggerAnimatedObject(animatedObject)
	local v55_ = self:getOwnerFarmId()
	return g_currentMission.accessHandler:canFarmAccessOtherId(g_currentMission:getFarmId(), v55_) and true or false
end

-- Local values: spec, i, animatedObject
function PlaceableAnimatedObjects:getAnimatedObjectBySaveId(saveId)
	local v58_ = self.spec_animatedObjects
	for _, v59_ in ipairs(v58_.animatedObjects) do
		if v59_.saveId == saveId then
			return v59_
		end
	end
	return nil
end

-- Local values: spec, _, animatedObject
function PlaceableAnimatedObjects:setOwnerFarmId(superFunc, ownerFarmId, noEventSend)
	superFunc(self, ownerFarmId, noEventSend)
	local v64_ = self.spec_animatedObjects
	if v64_.animatedObjects ~= nil then
		for _, v65_ in ipairs(v64_.animatedObjects) do
			v65_:setOwnerFarmId(ownerFarmId, true)
		end
	end
end
