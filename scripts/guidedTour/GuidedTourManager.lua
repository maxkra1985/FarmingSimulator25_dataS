-- Local values: GuidedTourManager_mt
GuidedTourManager = {}
local GuidedTourManager_mt = Class(GuidedTourManager, AbstractManager)
g_xmlManager:addCreateSchemaFunction(function()
	GuidedTourManager.xmlSchema = XMLSchema.new("savegame_guidedTour")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = Mission00.xmlSchema
	v2_:register(XMLValueType.STRING, "map.guidedTours.guidedTour(?)#name", "Name identifier of the guided tour", nil, true)
	v2_:register(XMLValueType.STRING, "map.guidedTours.guidedTour(?)#filename", "Path to guided tour config file", nil, true)
	local v3_ = GuidedTourManager.xmlSchema
	v3_:register(XMLValueType.STRING, "guidedTour.tour#name", "Name identifier of the guided tour", nil, true)
	GuidedTour.registerSavegameXMLPaths(v3_, "guidedTour.tour")
end)

-- Upvalues: GuidedTourManager_mt
-- Local values: self
function GuidedTourManager.new(customMt)
	-- upvalues: (copy) GuidedTourManager_mt
	return AbstractManager.new(customMt or GuidedTourManager_mt)
end

function GuidedTourManager:initDataStructures()
	self.guidedTours = {}
	self.nameToGuidedTour = {}
	self.nameToVehicle = {}
	self.nameToPlaceable = {}
	self.goalClasses = {}
	self.actionClasses = {}
	self.progressClasses = {}
end

function GuidedTourManager:unloadMapData()
	g_messageCenter:unsubscribeAll(self)
	GuidedTourManager:superClass().unloadMapData(self)
end

-- Local values: success
function GuidedTourManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	GuidedTourManager:superClass().loadMapData(self)
	local v11_ = XMLUtil.loadDataFromMapXML(xmlFile, "guidedTours", baseDirectory, self, self.loadGuidedTours, missionInfo, baseDirectory)
	if v11_ then
		GuidedTourHelp.init()
	end
	return v11_
end

-- Local values: xmlFile, _, key, xmlFilename, name, upperName, guidedTour
function GuidedTourManager:loadGuidedTours(xmlFileHandle, missionInfo, baseDirectory, isBaseType)
	local v15_ = XMLFile.wrap(xmlFileHandle, Mission00.xmlSchema)
	for _, v16_ in v15_:iterator("map.guidedTours.guidedTour") do
		local v17_ = v15_:getValue(v16_ .. "#filename")
		if v17_ == nil then
			Logging.xmlWarning(v15_, "Missing filename for guidedTour \'%s\'", v16_)
		else
			local v18_ = v15_:getValue(v16_ .. "#name")
			if v18_ == nil then
				Logging.xmlWarning(v15_, "Missing name for guidedTour \'%s\'", v16_)
			else
				local v19_ = Utils.getFilename(v17_, baseDirectory)
				local v20_ = string.upper(v18_)
				if self.nameToGuidedTour[v20_] == nil then
					local v21_ = GuidedTourUtil.createFromXML(v19_)
					if v21_ ~= nil then
						local v22_ = self.guidedTours
						table.insert(v22_, v21_)
						self.nameToGuidedTour[v20_] = v21_
						v21_.name = v20_
						v21_.index = #self.guidedTours
					end
				else
					Logging.xmlWarning(v15_, "GuidedTour with name \'%s\' already exists for \'%s\'!", v18_, v16_)
				end
			end
		end
	end
	g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, GuidedTourManager.onMissionStarted, self)
	v15_:delete()
	return true
end

-- Local values: xmlFile, tour
function GuidedTourManager:saveToXMLFile(xmlFilename)
	local v25_ = XMLFile.create("guidedTourXML", xmlFilename, "guidedTour", GuidedTourManager.xmlSchema)
	if v25_ == nil then
		Logging.error("Failed to create guidedTour xml file")
		return false
	end
	local v26_ = self.activeTour
	if v26_ ~= nil then
		v25_:setValue("guidedTour.tour#name", v26_.name)
		v26_:saveToXMLFile(v25_, "guidedTour.tour")
	end
	v25_:save()
	v25_:delete()
	return true
end

-- Local values: xmlFile, tourName, tour
function GuidedTourManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		return false
	end
	local v29_ = XMLFile.load("guidedTourXML", xmlFilename, GuidedTourManager.xmlSchema)
	if v29_ == nil then
		return false
	end
	local v30_ = v29_:getValue("guidedTour.tour#name")
	local v31_ = self.nameToGuidedTour[v30_]
	if v31_ ~= nil then
		if v31_:loadFromXMLFile(v29_, "guidedTour.tour") then
			self.pendingStartTour = v31_
		else
			Logging.xmlWarning(v29_, "Could not load guided tour from savegame!")
		end
	end
	v29_:delete()
	return true
end

-- Local values: tour
function GuidedTourManager:onMissionStarted(isNewSavegame)
	if g_server ~= nil then
		local v34_ = self.pendingStartTour
		if isNewSavegame and g_currentMission:getIsTourSupported() then
			v34_ = self:getTourByName("INTRO")
			if v34_ == nil then
				g_currentMission.hud:showInGameMessage(nil, g_i18n:getText("guidedTour_intro_notAvailable"), 0)
				return
			end
		end
		if g_currentMission.missionDynamicInfo.isMultiplayer then
			if self.pendingStartTour ~= nil then
				self:abortTour(self.pendingStartTour)
				self.pendingStartTour:delete()
			end
		elseif v34_ ~= nil then
			self:startTour(v34_)
			return
		end
	end
end

function GuidedTourManager:update(dt)
	if self.pendingTour ~= nil then
		self:startPendingTour()
	end
	if self.activeTour ~= nil then
		self.activeTour:update(dt)
	end
end

function GuidedTourManager:draw()
	if self.activeTour ~= nil then
		self.activeTour:draw()
	end
end

-- Local values: tour
function GuidedTourManager:startPendingTour()
	local v39_ = self.pendingTour
	self.pendingTour = nil
	self.activeTour = v39_
	v39_:start(function(p40_)
		-- upvalues: (copy) self
		if p40_ then
			self:onTourFinished()
		else
			self:onTourCanceled()
		end
	end)
end

function GuidedTourManager:startTour(tour)
	self.pendingTour = tour
end

function GuidedTourManager:abortTour(tour)
	local v45_ = tour or self.activeTour
	if v45_ ~= nil then
		v45_:cancel()
		g_currentMission.hud:showInGameMessage(nil, g_i18n:getText("guidedTour_aborted"), 0, nil, nil, nil)
	end
end

function GuidedTourManager:onTourFinished()
	self.activeTour = nil
	g_currentMission.hud:showInGameMessage(nil, g_i18n:getText("guidedTour_finished"), 0, nil, nil, nil)
end

function GuidedTourManager:onTourCanceled()
	self.activeTour = nil
end

function GuidedTourManager:getTourByName(name)
	if name == nil then
		return nil
	end
	local v50_ = string.upper(name)
	return self.nameToGuidedTour[v50_]
end

function GuidedTourManager:getIsTourRunning()
	return self.activeTour ~= nil
end

function GuidedTourManager:getActiveTour()
	return self.activeTour
end

function GuidedTourManager:getVehicleByName(name)
	return self.nameToVehicle[name]
end

function GuidedTourManager:addVehicle(vehicle, name)
	self.nameToVehicle[name] = vehicle
end

function GuidedTourManager:removeVehicle(name)
	if name ~= nil then
		self.nameToVehicle[name] = nil
	end
end

function GuidedTourManager:getPlaceableByName(name)
	return self.nameToPlaceable[name]
end

function GuidedTourManager:addPlaceable(placeable, name)
	self.nameToPlaceable[name] = placeable
end

function GuidedTourManager:removePlaceable(name)
	self.nameToPlaceable[name] = nil
end

function GuidedTourManager:registerGoalClass(name, class)
	self.goalClasses[name] = class
end

function GuidedTourManager:getAllGoalClasses()
	return self.goalClasses
end

function GuidedTourManager:registerActionClass(name, class)
	self.actionClasses[name] = class
end

function GuidedTourManager:getAllActionClasses()
	return self.actionClasses
end

function GuidedTourManager:registerProgressClass(name, class)
	self.progressClasses[name] = class
end

function GuidedTourManager:getAllProgressClasses()
	return self.progressClasses
end
g_guidedTourManager = GuidedTourManager.new()
