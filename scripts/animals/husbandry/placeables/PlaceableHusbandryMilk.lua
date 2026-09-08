PlaceableHusbandryMilk = {}
source("dataS/scripts/animals/husbandry/objects/MilkingRobot.lua")

function PlaceableHusbandryMilk.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(PlaceableHusbandry, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, specializations)
	end
	return v2_
end
function PlaceableHusbandryMilk.initSpecialization()
	g_placeableConfigurationManager:addConfigurationType("milk", g_i18n:getText("configuration_milk"), "husbandry.milk", PlaceableConfigurationItem)
end

function PlaceableHusbandryMilk.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onMilkingRobotLoaded", PlaceableHusbandryMilk.onMilkingRobotLoaded)
end

function PlaceableHusbandryMilk.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PlaceableHusbandryMilk.updateOutput)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateProduction", PlaceableHusbandryMilk.updateProduction)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryMilk.updateInfo)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryMilk.getConditionInfos)
end

function PlaceableHusbandryMilk.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryMilk)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryMilk)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryMilk)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryMilk)
end

function PlaceableHusbandryMilk.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	PlaceableHusbandryMilk.registerMilkXMLPaths(schema, basePath .. ".husbandry.milk")
	PlaceableHusbandryMilk.registerMilkXMLPaths(schema, basePath .. ".husbandry.milk.milkConfigurations.milkConfiguration(?)")
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryMilk.registerMilkXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#hasMilkProduction", "If milk production is available")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".milkingRobots.milkingRobot(?)#linkNode", "Milkingrobot link node")
	schema:register(XMLValueType.STRING, basePath .. ".milkingRobots.milkingRobot(?)#class", "Milkingrobot class name")
	schema:register(XMLValueType.STRING, basePath .. ".milkingRobots.milkingRobot(?)#filename", "Milkingrobot config file")
end

-- Local values: spec, milkConfigurationId, configKey, animalTypeIndex, animalType, _, subTypeIndex, subType, milk, _, key, filename, className, class, linkNode, args, robot
function PlaceableHusbandryMilk:onLoad(savegame)
	local v11_ = self.spec_husbandryMilk
	local v12_ = Utils.getNoNil(self.configurations.milk, 1)
	local v13_ = string.format("placeable.husbandry.milk.milkConfigurations.milkConfiguration(%d)", v12_ - 1)
	local v14_ = not self.xmlFile:hasProperty(v13_) and "placeable.husbandry.milk" or v13_
	v11_.hasMilkProduction = self.xmlFile:getBool(v14_ .. "#hasMilkProduction", true)
	if v11_.hasMilkProduction then
		local v15_ = self:getAnimalTypeIndex()
		local v16_ = g_currentMission.animalSystem:getTypeByIndex(v15_)
		v11_.litersPerHour = {}
		v11_.fillTypes = {}
		v11_.infos = {}
		v11_.activeFillTypes = {}
		if v16_ ~= nil then
			for _, v17_ in ipairs(v16_.subTypes) do
				local v18_ = g_currentMission.animalSystem:getSubTypeByIndex(v17_)
				if v18_.output ~= nil then
					local v19_ = v18_.output.milk
					if v19_ ~= nil then
						v11_.litersPerHour[v19_.fillType] = 0
						table.addElement(v11_.fillTypes, v19_.fillType)
						v11_.infos[v19_.fillType] = {
							["title"] = g_fillTypeManager:getFillTypeTitleByIndex(v19_.fillType),
							["text"] = ""
						}
					end
				end
			end
		end
		v11_.milkingRobots = {}
		for _, v20_ in self.xmlFile:iterator(v14_ .. ".milkingRobots.milkingRobot") do
			local v21_ = Utils.getFilename(self.xmlFile:getValue(v20_ .. "#filename", nil), self.baseDirectory)
			if v21_ == nil then
				Logging.xmlWarning(self.xmlFile, "Milkingrobot filename missing for \'%s\'", v20_)
			else
				local v22_ = self.xmlFile:getValue(v20_ .. "#class", "")
				local v23_ = ClassUtil.getClassObject(v22_)
				if v23_ == nil then
					Logging.xmlWarning(self.xmlFile, "Milkingrobot class \'%s\' not defined for \'%s\'", v22_, v20_)
				else
					local v24_ = self.xmlFile:getValue(v20_ .. "#linkNode", nil, self.components, self.i3dMappings)
					if v24_ == nil then
						Logging.xmlWarning(self.xmlFile, "Milkingrobot linkNode not defined for \'%s\'", v20_)
					else
						local v25_ = {
							["loadingTask"] = self:createLoadingTask(self)
						}
						local v26_ = v23_.new(self, self.baseDirectory)
						if v26_:load(v24_, v21_, self.onMilkingRobotLoaded, self, v25_) then
							local v27_ = v11_.milkingRobots
							table.insert(v27_, v26_)
						else
							self:finishLoadingTask(v25_.loadingTask)
							v26_:delete()
						end
					end
				end
			end
		end
	end
end

function PlaceableHusbandryMilk:onMilkingRobotLoaded(robot, args)
	self:finishLoadingTask(args.loadingTask)
end

-- Local values: spec, _, robot
function PlaceableHusbandryMilk:onDelete()
	local v31_ = self.spec_husbandryMilk
	if v31_.milkingRobots ~= nil then
		for _, v32_ in ipairs(v31_.milkingRobots) do
			v32_:delete()
		end
		v31_.milkingRobots = {}
	end
end

-- Local values: spec, _, fillTypeIndex, fillTypeName, _, robot
function PlaceableHusbandryMilk:onFinalizePlacement()
	local v34_ = self.spec_husbandryMilk
	if v34_.hasMilkProduction then
		for _, v35_ in ipairs(v34_.fillTypes) do
			if not self:getHusbandryIsFillTypeSupported(v35_) then
				local v36_ = g_fillTypeManager:getFillTypeNameByIndex(v35_)
				Logging.xmlWarning(self.xmlFile, "Missing filltype \'%s\' in husbandry storage!", v36_)
			end
		end
		for _, v37_ in ipairs(v34_.milkingRobots) do
			v37_:finalizePlacement()
		end
	end
end

-- Local values: spec, _, fillTypeIndex, litersPerHour, liters
function PlaceableHusbandryMilk:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
	local v43_ = self.spec_husbandryMilk
	if v43_.hasMilkProduction and (self.isServer and #v43_.fillTypes > 0) then
		for _, v44_ in ipairs(v43_.fillTypes) do
			local v45_ = v43_.litersPerHour[v44_]
			local v46_ = productionFactor * globalProductionFactor * v45_ * g_currentMission.environment.timeAdjustment
			self:addHusbandryFillLevelFromTool(self:getOwnerFarmId(), v46_, v44_, nil, nil, nil)
		end
	end
	superFunc(self, foodFactor, productionFactor, globalProductionFactor)
end

-- Local values: spec, factor, _, fillTypeIndex, freeCapacity
function PlaceableHusbandryMilk:updateProduction(superFunc, foodFactor)
	local v50_ = self.spec_husbandryMilk
	local v51_ = superFunc(self, foodFactor)
	if v50_.hasMilkProduction then
		for _, v52_ in ipairs(v50_.fillTypes) do
			if self:getHusbandryFreeCapacity(v52_) <= 0 then
				return 0
			end
		end
	end
	return v51_
end

-- Local values: spec, fillType, _, _, cluster, subType, milk, age, litersPerAnimals, litersPerDay
function PlaceableHusbandryMilk:onHusbandryAnimalsUpdate(clusters)
	local v55_ = self.spec_husbandryMilk
	if v55_.hasMilkProduction then
		for v56_, _ in pairs(v55_.litersPerHour) do
			v55_.litersPerHour[v56_] = 0
		end
		v55_.activeFillTypes = {}
		for _, v57_ in ipairs(clusters) do
			local v58_ = g_currentMission.animalSystem:getSubTypeByIndex(v57_.subTypeIndex)
			if v58_ ~= nil then
				local v59_ = v58_.output.milk
				if v59_ ~= nil then
					local v60_ = v57_:getAge()
					local v61_ = v59_.curve:get(v60_) * v57_:getNumAnimals()
					v55_.litersPerHour[v59_.fillType] = v55_.litersPerHour[v59_.fillType] + v61_ / 24
					table.addElement(v55_.activeFillTypes, v59_.fillType)
				end
			end
		end
	end
end

-- Local values: spec, k, fillTypeIndex, info, fillLevel
function PlaceableHusbandryMilk:updateInfo(superFunc, infoTable)
	local v65_ = self.spec_husbandryMilk
	superFunc(self, infoTable)
	if v65_.hasMilkProduction then
		for _, v66_ in ipairs(v65_.activeFillTypes) do
			local v67_ = v65_.infos[v66_]
			local v68_ = self:getHusbandryFillLevel(v66_)
			v67_.text = string.format("%d l", v68_)
			table.insert(infoTable, v67_)
		end
	end
end

-- Local values: spec, infos, _, fillTypeIndex, info, fillType, capacity, ratio
function PlaceableHusbandryMilk:getConditionInfos(superFunc)
	local v71_ = self.spec_husbandryMilk
	local v72_ = superFunc(self)
	if v71_.hasMilkProduction then
		for _, v73_ in ipairs(v71_.activeFillTypes) do
			local v74_ = {}
			local v75_ = g_fillTypeManager:getFillTypeByIndex(v73_)
			if v75_ ~= nil then
				v74_.title = v75_.title
				v74_.value = self:getHusbandryFillLevel(v73_)
				local v76_ = self:getHusbandryCapacity(v73_)
				local v77_ = v76_ <= 0 and 0 or v74_.value / v76_
				v74_.ratio = math.clamp(v77_, 0, 1)
				v74_.invertedBar = true
				table.insert(v72_, v74_)
			end
		end
	end
	return v72_
end
