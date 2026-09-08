PlaceableHusbandryFeedingRobot = {}
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobot.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotState.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStateLoading.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStatePaused.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStateFilling.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStateStarting.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStateDriving.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStateFinished.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStateReset.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStateWait.lua")
source("dataS/scripts/animals/husbandry/objects/feedingRobot/FeedingRobotStateEvent.lua")

function PlaceableHusbandryFeedingRobot.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(PlaceableHusbandryFood, specializations)
end

function PlaceableHusbandryFeedingRobot.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onFeedingRobotLoaded", PlaceableHusbandryFeedingRobot.onFeedingRobotLoaded)
end

function PlaceableHusbandryFeedingRobot.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableHusbandryFeedingRobot.setOwnerFarmId)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateFeeding", PlaceableHusbandryFeedingRobot.updateFeeding)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableHusbandryFeedingRobot.collectPickObjects)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryFeedingRobot.updateInfo)
end

function PlaceableHusbandryFeedingRobot.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryFeedingRobot)
	SpecializationUtil.registerEventListener(placeableType, "onPostLoad", PlaceableHusbandryFeedingRobot)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryFeedingRobot)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryFeedingRobot)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryFeedingRobot)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryFeedingRobot)
end

function PlaceableHusbandryFeedingRobot.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	local v7_ = basePath .. ".husbandry.feedingRobot"
	schema:register(XMLValueType.NODE_INDEX, v7_ .. "#linkNode", "Feedingrobot link node")
	schema:register(XMLValueType.STRING, v7_ .. "#class", "Feedingrobot class name")
	schema:register(XMLValueType.STRING, v7_ .. "#filename", "Feedingrobot config file")
	schema:register(XMLValueType.NODE_INDEX, v7_ .. ".splines.spline(?)#node", "Feedingrobot spline")
	schema:register(XMLValueType.INT, v7_ .. ".splines.spline(?)#direction", "Feedingrobot spline direction")
	schema:register(XMLValueType.BOOL, v7_ .. ".splines.spline(?)#isFeeding", "Feedingrobot spline feeding part")
	schema:register(XMLValueType.FLOAT, v7_ .. ".splines.spline(?)#fakeLength", "Fake length of spline for simulating a waiting point")
	schema:register(XMLValueType.BOOL, v7_ .. ".splines.spline(?)#stopAtEnd", "If robot should stop at the end of the spline and switch to next state")
	schema:register(XMLValueType.INT, v7_ .. ".animatedObjects.animatedObject(?)#index", "Dependent animated object index")
	schema:register(XMLValueType.INT, v7_ .. ".animatedObjects.animatedObject(?)#direction", "Dependent animated object direction")
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryFeedingRobot.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	FeedingRobot.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType()
end

-- Local values: spec, filename, className, class, linkNode, loadingTask, _, splineKey, fakeLength, stopAtEnd, spline, direction, isFeeding
function PlaceableHusbandryFeedingRobot:onLoad(savegame)
	local v_u_11_ = self.spec_husbandryFeedingRobot
	if not self.xmlFile:hasProperty("placeable.husbandry.feedingRobot") then
		return
	end
	local v12_ = self.xmlFile:getValue("placeable.husbandry.feedingRobot#filename")
	if v12_ == nil then
		Logging.xmlError(self.xmlFile, "Feedingrobot filename missing")
		self:setLoadingState(PlaceableLoadingState.ERROR)
		return
	end
	local v13_ = Utils.getFilename(v12_, self.baseDirectory)
	local v14_ = self.xmlFile:getValue("placeable.husbandry.feedingRobot#class", "")
	local v15_ = ClassUtil.getClassObject(v14_)
	if v15_ == nil then
		Logging.xmlError(self.xmlFile, "Feedingrobot class \'%s\' not defined", v14_)
		self:setLoadingState(PlaceableLoadingState.ERROR)
		return
	end
	local v16_ = self.xmlFile:getValue("placeable.husbandry.feedingRobot#linkNode", nil, self.components, self.i3dMappings)
	if v16_ == nil then
		Logging.xmlError(self.xmlFile, "Feedingrobot linkNode not defined")
		self:setLoadingState(PlaceableLoadingState.ERROR)
		return
	end
	local v17_ = self:createLoadingTask(self)
	v_u_11_.feedingRobot = v15_.new(self.isServer, self.isClient, self, self.baseDirectory)
	v_u_11_.feedingRobot:load(v16_, v13_, self.onFeedingRobotLoaded, self, {
		["loadingTask"] = v17_
	})
	v_u_11_.feedingRobot:register(true)
	for _, v18_ in self.xmlFile:iterator("placeable.husbandry.feedingRobot.splines.spline") do
		local v19_ = self.xmlFile:getFloat(v18_ .. "#fakeLength", nil)
		local v20_ = self.xmlFile:getBool(v18_ .. "#stopAtEnd", false)
		if v19_ == nil then
			local v21_ = self.xmlFile:getValue(v18_ .. "#node", nil, self.components, self.i3dMappings)
			if v21_ == nil then
				Logging.xmlWarning(self.xmlFile, "Feedingrobot spline not defined for \'%s\'", v18_)
				break
			end
			if not getHasClassId(getGeometry(v21_), ClassIds.SPLINE) then
				Logging.xmlWarning(self.xmlFile, "Given node is not a spline for \'%s\'", v18_)
				break
			end
			local v22_ = self.xmlFile:getValue(v18_ .. "#direction", 1)
			local v23_ = self.xmlFile:getValue(v18_ .. "#isFeeding", false)
			v_u_11_.feedingRobot:addSpline(v21_, v22_, v23_, v20_)
		else
			v_u_11_.feedingRobot:addSplineWaitingPoint(v19_)
		end
	end
	v_u_11_.feedingRobot:finishSplines()
	v_u_11_.dependedAnimatedObjects = {}
	self.xmlFile:iterate("placeable.husbandry.feedingRobot.animatedObjects.animatedObject", function(_, p24_)
		-- upvalues: (copy) self, (copy) v_u_11_
		local v25_ = self.xmlFile:getInt(p24_ .. "#index")
		local v26_ = self.xmlFile:getInt(p24_ .. "#direction", 1)
		local v27_ = v_u_11_.dependedAnimatedObjects
		table.insert(v27_, {
			["animatedObjectIndex"] = v25_,
			["direction"] = v26_
		})
	end)
end

-- Local values: spec, animatedObjects, _, data, animatedObject
function PlaceableHusbandryFeedingRobot:onPostLoad(savegame)
	local v_u_29_ = self.spec_husbandryFeedingRobot
	if v_u_29_.dependedAnimatedObjects ~= nil and self.spec_animatedObjects ~= nil then
		local v30_ = self.spec_animatedObjects.animatedObjects
		for _, v_u_31_ in ipairs(v_u_29_.dependedAnimatedObjects) do
			local v_u_32_ = v30_[v_u_31_.animatedObjectIndex]
			if v_u_32_ ~= nil then
				v_u_32_.getCanBeTriggered = Utils.overwrittenFunction(v_u_32_.getCanBeTriggered, function(_, p33_)
					-- upvalues: (copy) v_u_32_, (copy) v_u_29_
					if p33_(v_u_32_) then
						return not v_u_29_.feedingRobot:getIsDriving()
					else
						return false
					end
				end)
				v_u_29_.feedingRobot:addStateChangedListener(function(_)
					-- upvalues: (copy) v_u_29_, (copy) v_u_32_, (copy) v_u_31_
					if v_u_29_.feedingRobot:getIsDriving() and v_u_32_.animation.direction ~= v_u_31_.direction then
						v_u_32_:setDirection(v_u_31_.direction)
					end
				end)
			end
		end
	end
end

function PlaceableHusbandryFeedingRobot:onFeedingRobotLoaded(robot, args)
	self:finishLoadingTask(args.loadingTask)
end

-- Local values: spec
function PlaceableHusbandryFeedingRobot:onDelete()
	local v37_ = self.spec_husbandryFeedingRobot
	if v37_.feedingRobot ~= nil then
		v37_.feedingRobot:delete()
		v37_.feedingRobot = nil
	end
end

-- Local values: spec
function PlaceableHusbandryFeedingRobot:onFinalizePlacement()
	local v39_ = self.spec_husbandryFeedingRobot
	if v39_.feedingRobot ~= nil then
		v39_.feedingRobot:finalizePlacement()
	end
end

-- Local values: spec, feedingRobotId
function PlaceableHusbandryFeedingRobot:onReadStream(streamId, connection)
	local v43_ = self.spec_husbandryFeedingRobot
	if v43_.feedingRobot ~= nil then
		local v44_ = NetworkUtil.readNodeObjectId(streamId)
		v43_.feedingRobot:readStream(streamId, connection)
		g_client:finishRegisterObject(v43_.feedingRobot, v44_)
	end
end

-- Local values: spec
function PlaceableHusbandryFeedingRobot:onWriteStream(streamId, connection)
	local v48_ = self.spec_husbandryFeedingRobot
	if v48_.feedingRobot ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v48_.feedingRobot))
		v48_.feedingRobot:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, v48_.feedingRobot)
	end
end

-- Local values: spec
function PlaceableHusbandryFeedingRobot:loadFromXMLFile(xmlFile, key)
	local v52_ = self.spec_husbandryFeedingRobot
	if v52_.feedingRobot ~= nil then
		v52_.feedingRobot:loadFromXMLFile(xmlFile, key)
	end
end

-- Local values: spec
function PlaceableHusbandryFeedingRobot:saveToXMLFile(xmlFile, key, usedModNames)
	local v57_ = self.spec_husbandryFeedingRobot
	if v57_.feedingRobot ~= nil then
		v57_.feedingRobot:saveToXMLFile(xmlFile, key, usedModNames)
	end
end

-- Local values: spec
function PlaceableHusbandryFeedingRobot:setOwnerFarmId(superFunc, farmId)
	superFunc(self, farmId)
	local v61_ = self.spec_husbandryFeedingRobot
	if v61_.feedingRobot ~= nil then
		v61_.feedingRobot:setOwnerFarmId(farmId, true)
	end
end

-- Local values: spec, litersPerHour
function PlaceableHusbandryFeedingRobot:updateFeeding(superFunc)
	local v64_ = self.spec_husbandryFeedingRobot
	if self.isServer and v64_.feedingRobot ~= nil then
		local v65_ = self:getFoodLitersPerHour() * g_currentMission.environment.timeAdjustment
		v64_.feedingRobot:createFoodMixture(v65_ * 1.5)
	end
	return superFunc(self)
end

-- Local values: spec
function PlaceableHusbandryFeedingRobot:collectPickObjects(superFunc, node)
	local v69_ = self.spec_husbandryFeedingRobot
	if v69_.feedingRobot == nil or not v69_.feedingRobot:getIsNodeUsed(node) then
		superFunc(self, node)
	end
end

-- Local values: spec
function PlaceableHusbandryFeedingRobot:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)
	local v73_ = self.spec_husbandryFeedingRobot
	if v73_.feedingRobot ~= nil then
		v73_.feedingRobot:updateInfo(infoTable)
	end
end
