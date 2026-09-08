-- Local values: AnimalLoadingTrigger_mt, AnimalLoadingTriggerActivatable_mt
AnimalLoadingTrigger = {}
local AnimalLoadingTrigger_mt = Class(AnimalLoadingTrigger)
InitStaticObjectClass(AnimalLoadingTrigger, "AnimalLoadingTrigger")

function AnimalLoadingTrigger.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Trigger node of animal loading trigger")
	schema:register(XMLValueType.BOOL, basePath .. "#isDealer", "Is dealer or not", false)
	schema:register(XMLValueType.STRING, basePath .. "#animalTypes", "List of supported animal types (only for dealer)")
	schema:register(XMLValueType.STRING, basePath .. "#title", "Title to show in the UI", "ui_farm")
end

-- Local values: trigger
function AnimalLoadingTrigger:onCreate(id)
	local v5_ = AnimalLoadingTrigger.new(g_server ~= nil, g_client ~= nil)
	if v5_ ~= nil then
		if v5_:load(id) then
			g_currentMission:addNonUpdateable(v5_)
			return
		end
		v5_:delete()
	end
end

-- Upvalues: AnimalLoadingTrigger_mt
-- Local values: self
function AnimalLoadingTrigger.new(isServer, isClient)
	-- upvalues: (copy) AnimalLoadingTrigger_mt
	local v8_ = Object.new(isServer, isClient, AnimalLoadingTrigger_mt)
	v8_.customEnvironment = g_currentMission.loadingMapModName
	v8_.isDealer = false
	v8_.triggerNode = nil
	v8_.title = g_i18n:getText("ui_farm")
	v8_.animals = nil
	v8_.activatable = AnimalLoadingTriggerActivatable.new(v8_)
	v8_.isPlayerInRange = false
	v8_.isEnabled = false
	v8_.loadingVehicle = nil
	v8_.activatedTarget = nil
	return v8_
end

-- Local values: animalTypesString, animalTypes, _, animalTypeStr, animalTypeIndex
function AnimalLoadingTrigger:loadFromXML(xmlFile, key, components, i3dMappings)
	self.triggerNode = xmlFile:getValue(key .. "#node", nil, components, i3dMappings)
	if self.triggerNode == nil then
		Logging.xmlWarning(xmlFile, "Missing trigger node for animalLoadingTrigger!")
		return false
	end
	self.husbandry = nil
	self.isDealer = xmlFile:getValue(key .. "#isDealer", false)
	if self.isDealer then
		local v14_ = xmlFile:getValue(key .. "#animalTypes")
		if v14_ ~= nil then
			local v15_ = v14_:split(" ")
			for _, v16_ in pairs(v15_) do
				local v17_ = g_currentMission.animalSystem:getTypeIndexByName(v16_)
				if v17_ == nil then
					Logging.xmlWarning(xmlFile, "Invalid animal type \'%s\' for animalLoadingTrigger!", v16_)
				else
					if self.animalTypes == nil then
						self.animalTypes = {}
					end
					local v18_ = self.animalTypes
					table.insert(v18_, v17_)
				end
			end
		end
	end
	addTrigger(self.triggerNode, "triggerCallback", self)
	self.title = g_i18n:convertText(xmlFile:getValue(key .. "#title", "ui_farm"), self.customEnvironment)
	self.isEnabled = true
	return true
end

-- Local values: animalTypesString, animalTypes, _, animalTypeStr, animalTypeIndex
function AnimalLoadingTrigger:load(node, husbandry)
	self.husbandry = husbandry
	self.isDealer = Utils.getNoNil(getUserAttribute(node, "isDealer"), false)
	if self.isDealer then
		local v22_ = getUserAttribute(node, "animalTypes")
		if v22_ ~= nil then
			local v23_ = v22_:split(" ")
			for _, v24_ in pairs(v23_) do
				local v25_ = g_currentMission.animalSystem:getTypeIndexByName(v24_)
				if v25_ == nil then
					Logging.warning("Invalid animal type \'%s\' for animalLoadingTrigger \'%s\'!", v24_, getName(node))
				else
					if self.animalTypes == nil then
						self.animalTypes = {}
					end
					local v26_ = self.animalTypes
					table.insert(v26_, v25_)
				end
			end
		end
	end
	self.triggerNode = node
	addTrigger(self.triggerNode, "triggerCallback", self)
	self.title = g_i18n:getText(Utils.getNoNil(getUserAttribute(node, "title"), "ui_farm"), self.customEnvironment)
	self.isEnabled = true
	return true
end

function AnimalLoadingTrigger:delete()
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	if self.triggerNode ~= nil then
		removeTrigger(self.triggerNode)
		self.triggerNode = nil
	end
	self.husbandry = nil
end

-- Local values: vehicle, rootVehicle
function AnimalLoadingTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (onEnter or onLeave) then
		local v32_ = g_currentMission.nodeToObject[otherId]
		if v32_ == nil or v32_.getSupportsAnimalType == nil then
			if g_localPlayer ~= nil and otherId == g_localPlayer.rootNode then
				if onEnter then
					self.isPlayerInRange = true
					if Platform.gameplay.autoActivateTrigger and self.activatable:getIsActivatable() then
						self.activatable:run()
					end
				else
					self.isPlayerInRange = false
				end
				self:updateActivatableObject()
			end
		elseif onEnter then
			self:setLoadingTrailer(v32_)
			if Platform.gameplay.autoActivateTrigger and self.activatable:getIsActivatable() then
				self.activatable:run()
				local v33_ = v32_.rootVehicle
				if v33_.brakeToStop ~= nil then
					v33_:brakeToStop()
				end
				return
			end
		elseif onLeave then
			if v32_ == self.loadingVehicle then
				self:setLoadingTrailer(nil)
			end
			if v32_ == self.activatedTarget then
				g_animalScreen:onVehicleLeftTrigger()
				return
			end
		end
	end
end

function AnimalLoadingTrigger:updateActivatableObject()
	if self.loadingVehicle == nil and not self.isPlayerInRange then
		if self.loadingVehicle == nil and not self.isPlayerInRange then
			g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
		end
	else
		g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
	end
end

function AnimalLoadingTrigger:setLoadingTrailer(loadingVehicle)
	if self.loadingVehicle ~= nil and self.loadingVehicle.setLoadingTrigger ~= nil then
		self.loadingVehicle:setLoadingTrigger(nil)
	end
	self.loadingVehicle = loadingVehicle
	if self.loadingVehicle ~= nil and self.loadingVehicle.setLoadingTrigger ~= nil then
		self.loadingVehicle:setLoadingTrigger(self)
	end
	self:updateActivatableObject()
end

function AnimalLoadingTrigger:getAnimals()
	return self.animalTypes
end

function AnimalLoadingTrigger:openAnimalMenu()
	if self.husbandry == nil then
		self:updateActivatableObject()
	end
	AnimalScreen.show(self.husbandry, self.loadingVehicle, self.isDealer)
	self.activatedTarget = self.loadingVehicle
end
AnimalLoadingTriggerActivatable = {}
local v_u_39_ = Class(AnimalLoadingTriggerActivatable)
function AnimalLoadingTriggerActivatable.new(p40_)
	-- upvalues: (copy) v_u_39_
	local v41_ = v_u_39_
	local v42_ = setmetatable({}, v41_)
	v42_.owner = p40_
	v42_.activateText = g_i18n:getText("animals_openAnimalScreen", p40_.customEnvironment)
	return v42_
end

-- Local values: owner, canAccess, rootAttacherVehicle
function AnimalLoadingTriggerActivatable:getIsActivatable()
	local v44_ = self.owner
	if not v44_.isEnabled then
		return false
	end
	if g_gui.currentGui ~= nil then
		return false
	end
	if not g_currentMission:getHasPlayerPermission("tradeAnimals") then
		return false
	end
	if v44_.husbandry ~= nil and v44_.husbandry:getOwnerFarmId() ~= g_currentMission:getFarmId() then
		return false
	end
	local v45_
	if v44_.loadingVehicle == nil then
		v45_ = nil
	else
		v45_ = v44_.loadingVehicle.rootVehicle
	end
	return v44_.isPlayerInRange or v45_ == g_localPlayer:getCurrentVehicle()
end

function AnimalLoadingTriggerActivatable:run()
	if g_guidedTourManager:getIsTourRunning() then
		InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
	else
		self.owner:openAnimalMenu()
	end
end

-- Local values: tx, ty, tz
function AnimalLoadingTriggerActivatable:getDistance(x, y, z)
	if self.owner.triggerNode == nil then
		return math.huge
	end
	local v51_, v52_, v53_ = getWorldTranslation(self.owner.triggerNode)
	return MathUtil.vector3Length(x - v51_, y - v52_, z - v53_)
end
