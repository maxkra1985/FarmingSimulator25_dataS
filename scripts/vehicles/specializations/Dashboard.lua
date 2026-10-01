Dashboard = {}
source("dataS/scripts/vehicles/DashboardValueType.lua")
Dashboard.DEFAULT_MAX_UPDATE_DISTANCE = 7.5
Dashboard.DEFAULT_MAX_UPDATE_DISTANCE_CRITICAL = 20
Dashboard.GROUP_XML_KEY = "vehicle.dashboard.groups.group(?)"
Dashboard.TYPES = {}
Dashboard.TYPES.EMITTER = 0
Dashboard.TYPES.NUMBER = 1
Dashboard.TYPES.ANIMATION = 2
Dashboard.TYPES.ROT = 3
Dashboard.TYPES.TRANS = 4
Dashboard.TYPES.VISIBILITY = 5
Dashboard.TYPES.TEXT = 6
Dashboard.TYPES.SLIDER = 7
Dashboard.TYPES.MULTI_STATE = 8
Dashboard.TYPE_DATA = {}
Dashboard.COLORS = {}
Dashboard.COLORS.GREY = { 0.3, 0.3, 0.3, 1 }
Dashboard.COLORS.DARK_GREY = { 0.15, 0.15, 0.15, 1 }
Dashboard.COLORS.BLACK = { 0.05, 0.05, 0.05, 1 }
Dashboard.COLORS.LIGHT_GREEN = { 0.05, 0.15, 0.05, 1 }
Dashboard.COLORS.RED = { 1, 0, 0, 1 }
Dashboard.COLORS.GREEN = { 0, 1, 0, 1 }
Dashboard.COLORS.BLUE = { 0, 0, 1, 1 }
Dashboard.COLORS.YELLOW = { 1, 1, 0, 1 }
Dashboard.COLORS.ORANGE = { 1, 0.5, 0, 1 }
Dashboard.COLORS.WHITE = { 1, 1, 1, 1 }
Dashboard.compoundsXMLSchema = nil
function Dashboard.prerequisitesPresent(specializations)
	return true
end
function Dashboard.initSpecialization()
	local schema = Vehicle.xmlSchema
	schema:setXMLSpecializationType("Dashboard")
	Dashboard.registerDashboardXMLPaths(schema, "vehicle.dashboard.default")
	schema:register(XMLValueType.STRING, Dashboard.GROUP_XML_KEY .. "#name", "Dashboard group name")
	schema:register(XMLValueType.FLOAT, "vehicle.dashboard#maxUpdateDistance", "Max. distance to vehicle root to update connection hoses", Dashboard.DEFAULT_MAX_UPDATE_DISTANCE)
	schema:register(XMLValueType.FLOAT, "vehicle.dashboard#maxUpdateDistanceCritical", "Max. distance to vehicle root to update critical connection hoses (All with type 'ROT')", Dashboard.DEFAULT_MAX_UPDATE_DISTANCE_CRITICAL)
	schema:register(XMLValueType.TIME, "vehicle.dashboard#tickIntervall", "If defined the low priority dashboard will get updated at this interval (otherwise every second frame)")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.dashboard.compounds.compound(?)#linkNode", "Link node for dashboard compound")
	schema:register(XMLValueType.STRING, "vehicle.dashboard.compounds.compound(?)#filename", "Path to compound xml file")
	schema:register(XMLValueType.STRING, "vehicle.dashboard.compounds.compound(?)#name", "Name of dashboard compound to load")
	schema:register(XMLValueType.STRING_LIST, "vehicle.dashboard.compounds.compound(?)#configIds", "Configuration identifiers (the given configuations will be enabled, separated by whitespace)")
	schema:register(XMLValueType.STRING, "vehicle.dashboard.compounds.compound(?).configurationDependency(?)#configName", "Name of the vehicle config")
	schema:register(XMLValueType.INT, "vehicle.dashboard.compounds.compound(?).configurationDependency(?)#configIndex", "Index of the vehicle config")
	schema:register(XMLValueType.BOOL, "vehicle.dashboard.compounds.compound(?).configurationDependency(?)#useCompound", "Use dashboard compound only when the defined configuration is set", false)
	schema:register(XMLValueType.STRING_LIST, "vehicle.dashboard.compounds.compound(?).configurationDependency(?)#additionalConfigIds", "Dashboard config ids to be used when this vehicle config is active")
	schema:register(XMLValueType.STRING_LIST, "vehicle.dashboard.compounds.compound(?).configurationDependency(?)#disabledConfigIds", "Dashboard config ids to be used when this vehicle config is active")
	schema:setXMLSpecializationType()
	if Dashboard.compoundsXMLSchema == nil then
		Dashboard.compoundsXMLSchema = XMLSchema.new("dashboardCompounds")
	end
	Dashboard.compoundsXMLSchema:register(XMLValueType.NODE_INDEX, "dashboardCompounds.dashboardCompound(?)#node", "Root node in i3d file to load")
	Dashboard.compoundsXMLSchema:register(XMLValueType.STRING, "dashboardCompounds.dashboardCompound(?)#filename", "Path to i3d file")
	Dashboard.compoundsXMLSchema:register(XMLValueType.STRING, "dashboardCompounds.dashboardCompound(?)#name", "Name of dashboard compound")
	I3DUtil.registerI3dMappingXMLPaths(Dashboard.compoundsXMLSchema, "dashboardCompounds")
	Dashboard.registerDashboardXMLPaths(Dashboard.compoundsXMLSchema, "dashboardCompounds.dashboardCompound(?)")
	Dashboard.compoundsXMLSchema:register(XMLValueType.STRING, "dashboardCompounds.dashboardCompound(?).configuration(?)#id", "Identifier of the configuration")
	Dashboard.registerDashboardXMLPaths(Dashboard.compoundsXMLSchema, "dashboardCompounds.dashboardCompound(?).configuration(?)")
	ObjectChangeUtil.registerObjectChangeXMLPaths(Dashboard.compoundsXMLSchema, "dashboardCompounds.dashboardCompound(?).configuration(?)")
end
function Dashboard.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onRegisterDashboardValueTypes")
end
function Dashboard.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "registerDashboardValueType", Dashboard.registerDashboardValueType)
	SpecializationUtil.registerFunction(vehicleType, "updateDashboards", Dashboard.updateDashboards)
	SpecializationUtil.registerFunction(vehicleType, "updateDashboardValueType", Dashboard.updateDashboardValueType)
	SpecializationUtil.registerFunction(vehicleType, "loadDashboardGroupFromXML", Dashboard.loadDashboardGroupFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsDashboardGroupActive", Dashboard.getIsDashboardGroupActive)
	SpecializationUtil.registerFunction(vehicleType, "getDashboardGroupByName", Dashboard.getDashboardGroupByName)
	SpecializationUtil.registerFunction(vehicleType, "loadDashboardCompoundFromXML", Dashboard.loadDashboardCompoundFromXML)
	SpecializationUtil.registerFunction(vehicleType, "onDashboardCompoundLoaded", Dashboard.onDashboardCompoundLoaded)
	SpecializationUtil.registerFunction(vehicleType, "loadDashboardCompoundFromExternalXML", Dashboard.loadDashboardCompoundFromExternalXML)
	SpecializationUtil.registerFunction(vehicleType, "loadDashboardsFromXML", Dashboard.loadDashboardsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadDashboardFromXML", Dashboard.loadDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "setDashboardsDirty", Dashboard.setDashboardsDirty)
	SpecializationUtil.registerFunction(vehicleType, "getDashboardValue", Dashboard.getDashboardValue)
end
function Dashboard.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Dashboard)
	SpecializationUtil.registerEventListener(vehicleType, "onPreInitComponentPlacement", Dashboard)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Dashboard)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Dashboard)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Dashboard)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", Dashboard)
end
function Dashboard:onLoad(savegame)
	local spec = self.spec_dashboard
	spec.dashboards = {}
	spec.groupDashboards = {}
	spec.dashboardsByValueType = {}
	spec.dashboardsByValueTypeDirty = {}
	spec.tickDashboards = {}
	spec.criticalDashboards = {}
	spec.numDashboards = 0
	spec.groups = {}
	spec.sortedGroups = {}
	spec.groupUpdateIndex = 1
	spec.hasGroups = false
	spec.dashboardTypesLoaded = false
	spec.dashboardValueTypes = {}
	spec.sharedLoadRequestIds = {}
	local i = 0
	while true do
		local baseKey = string.format("%s.groups.group(%d)", "vehicle.dashboard", i)
		if not self.xmlFile:hasProperty(baseKey) then
			break
		end
		local group = {}
		if self:loadDashboardGroupFromXML(self.xmlFile, baseKey, group) then
			spec.groups[group.name] = group
			table.insert(spec.sortedGroups, group)
			spec.hasGroups = true
		end
		i = i + 1
	end
	spec.isDirty = false
	spec.isDirtyTick = false
	spec.tickIntervall = self.xmlFile:getValue("vehicle.dashboard#tickIntervall")
	spec.timeSinceLastTick = 0
	spec.maxUpdateDistance = self.xmlFile:getValue("vehicle.dashboard#maxUpdateDistance", Dashboard.DEFAULT_MAX_UPDATE_DISTANCE)
	spec.maxUpdateDistanceCritical = self.xmlFile:getValue("vehicle.dashboard#maxUpdateDistanceCritical", Dashboard.DEFAULT_MAX_UPDATE_DISTANCE_CRITICAL)
	spec.lastUpdateDistance = math.huge
end
function Dashboard:onPreInitComponentPlacement(savegame)
	local spec = self.spec_dashboard
	if self.isClient then
		SpecializationUtil.raiseEvent(self, "onRegisterDashboardValueTypes")
		spec.dashboardTypesLoaded = true
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.default")
		for _, dashboardValueType in ipairs(spec.dashboardValueTypes) do
			dashboardValueType:loadFromXML(self.xmlFile, self)
		end
		spec.dashboardCompounds = {}
		self.xmlFile:iterate("vehicle.dashboard.compounds.compound", function(index, compoundKey)
			local dashboardCompound = {}
			if self:loadDashboardCompoundFromXML(self.xmlFile, compoundKey, dashboardCompound) then
				table.insert(spec.dashboardCompounds, dashboardCompound)
			end
		end)
	end
	if not self.isClient or spec.numDashboards == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", Dashboard)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", Dashboard)
	end
end
function Dashboard:onDelete()
	local spec = self.spec_dashboard
	if spec.sharedLoadRequestIds ~= nil then
		for _, sharedLoadRequestId in ipairs(spec.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
		end
		spec.sharedLoadRequestIds = nil
	end
end
function Dashboard:registerDashboardValueType(dashboardValueType)
	local spec = self.spec_dashboard
	table.insert(spec.dashboardValueTypes, dashboardValueType)
	if spec.dashboardTypesLoaded then
		dashboardValueType:loadFromXML(self.xmlFile, self)
	end
end
function Dashboard:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_dashboard
		if spec.hasGroups then
			local group = spec.sortedGroups[spec.groupUpdateIndex]
			if self:getIsDashboardGroupActive(group) ~= group.isActive then
				group.isActive = not group.isActive
				self:updateDashboards(spec.groupDashboards, dt, true)
				self:updateDashboards(spec.tickDashboards, dt, true)
				self:updateDashboards(spec.criticalDashboards, dt, true)
				for _, dashboards in pairs(spec.dashboardsByValueType) do
					self:updateDashboards(dashboards, dt, true)
				end
			end
			spec.groupUpdateIndex = spec.groupUpdateIndex + 1
			if #spec.sortedGroups < spec.groupUpdateIndex then
				spec.groupUpdateIndex = 1
			end
		end
		if self.currentUpdateDistance < spec.maxUpdateDistanceCritical or spec.isDirty then
			self:updateDashboards(spec.criticalDashboards, dt)
			spec.isDirty = false
		end
		if spec.isDirtyTick then
			self:raiseActive()
		end
	end
end
function Dashboard:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_dashboard
		if self.currentUpdateDistance < spec.maxUpdateDistance or spec.isDirtyTick then
			local updateAllowed = true
			if spec.tickIntervall ~= nil then
				spec.timeSinceLastTick = spec.timeSinceLastTick + dt
				if spec.timeSinceLastTick < spec.tickIntervall then
					updateAllowed = false
				else
					spec.timeSinceLastTick = 0
				end
			end
			if updateAllowed then
				self:updateDashboards(spec.tickDashboards, dt)
				spec.isDirtyTick = false
			end
		end
		if self.currentUpdateDistance < spec.maxUpdateDistance then
			for valueType, dashboards in pairs(spec.dashboardsByValueType) do
				if spec.dashboardsByValueTypeDirty[valueType] then
					self:updateDashboards(dashboards, dt, true)
					spec.dashboardsByValueTypeDirty[valueType] = false
				end
			end
		end
	end
end
function Dashboard:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_dashboard
		self:updateDashboards(spec.tickDashboards, dt, true)
		self:updateDashboards(spec.criticalDashboards, dt, true)
	end
end
function Dashboard:updateDashboardValueType(valueTypeName)
	self.spec_dashboard.dashboardsByValueTypeDirty[valueTypeName] = true
end
function Dashboard:updateDashboards(dashboards, dt, force)
	for i = 1, #dashboards do
		local dashboard = dashboards[i]
		local isActive = true
		for j = 1, #dashboard.groups do
			if not dashboard.groups[j].isActive then
				isActive = false
				break
			end
		end
		if dashboard.valueType ~= nil then
			local value, min, max, center, isNumber = dashboard.valueType:getValue(dashboard)
			if dashboard.useStateChange then
				if value ~= dashboard.stateChangeLastValue then
					dashboard.stateChangeLastValue = value
					if not isNumber then
						value = value and 1 or 0
					end
					if dashboard.stateChangeValue == nil or value == dashboard.stateChangeValue then
						dashboard.stateChangeEndTime = g_time + dashboard.stateChangeTime
					end
				end
				value = g_time < dashboard.stateChangeEndTime and 1 or 0
				isNumber = true
			end
			if dashboard.minActiveValue ~= nil and value < dashboard.minActiveValue then
				isActive = false
			end
			if dashboard.maxActiveValue ~= nil and dashboard.maxActiveValue < value then
				isActive = false
			end
			if isNumber then
				if dashboard.scaleFactor ~= nil then
					value = value * dashboard.scaleFactor
				end
				if dashboard.offsetValue ~= nil then
					value = value + dashboard.offsetValue
				end
				if dashboard.valueMapping ~= nil then
					value = dashboard.valueMapping:get(value)
				end
			end
			if not isActive then
				if isNumber then
					value = dashboard.idleValue
				else
					value = 0.5 < dashboard.idleValue
				end
			end
			if dashboard.doInterpolation then
				if not isNumber then
					value = value and 1 or 0
				end
				if value ~= dashboard.lastInterpolationValue then
					local dir = math.sign(value - dashboard.lastInterpolationValue)
					local limitFunc = math.min
					if dir < 0 then
						limitFunc = math.max
					end
					value = limitFunc(dashboard.lastInterpolationValue + dashboard.interpolationSpeed * dir * dt, value)
					dashboard.lastInterpolationValue = value
				end
			end
			if value ~= dashboard.lastValue or force then
				dashboard.lastValue = value
				if isNumber then
					if min ~= nil then
						if dashboard.doInterpolation then
							min = math.min(min, dashboard.idleValue)
						end
						value = math.max(min, value)
					end
					if max ~= nil and isActive then
						if dashboard.doInterpolation then
							max = math.max(max, dashboard.idleValue)
						end
						value = math.min(max, value)
					end
					if center ~= nil then
						local maxValue = math.max(math.abs(min), math.abs(max))
						if value < center then
							value = -value / min * maxValue
						elseif center < value then
							value = value / max * maxValue
						end
						max = maxValue
						min = -maxValue
					end
				end
				dashboard.stateFunc(self, dashboard, value, min, max, isActive)
			end
		elseif force then
			dashboard.stateFunc(self, dashboard, true, nil, nil, isActive)
		end
	end
end
function Dashboard:loadDashboardGroupFromXML(xmlFile, key, group)
	group.name = xmlFile:getValue(key .. "#name")
	if group.name == nil then
		Logging.xmlWarning(self.xmlFile, "Missing name for dashboard group '%s'", key)
		return false
	elseif self:getDashboardGroupByName(group.name) ~= nil then
		Logging.xmlWarning(self.xmlFile, "Duplicated dashboard group name '%s' for group '%s'", group.name, key)
		return false
	else
		group.isActive = false
		return true
	end
end
function Dashboard:getIsDashboardGroupActive(group)
	return true
end
function Dashboard:getDashboardGroupByName(name)
	return self.spec_dashboard.groups[name]
end
function Dashboard:loadDashboardCompoundFromXML(xmlFile, key, compound)
	compound.linkNode = xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings)
	if compound.linkNode == nil then
		return false
	end
	compound.filename = xmlFile:getValue(key .. "#filename")
	if compound.filename ~= nil then
		compound.filename = Utils.getFilename(compound.filename, self.baseDirectory)
		if compound.filename ~= nil then
			compound.name = xmlFile:getValue(key .. "#name")
			compound.configIds = xmlFile:getValue(key .. "#configIds", nil, true)
			local isAllowed = true
			for _, configDependencyKey in xmlFile:iterator(key .. ".configurationDependency") do
				local configName = xmlFile:getValue(configDependencyKey .. "#configName")
				local configIndex = xmlFile:getValue(configDependencyKey .. "#configIndex")
				if configName == nil or configIndex == nil then
					continue
				end
				if self.configurations[configName] == configIndex then
					local configIds = xmlFile:getValue(configDependencyKey .. "#additionalConfigIds", nil, true)
					if configIds ~= nil then
						for _, _configId in ipairs(configIds) do
							table.insert(compound.configIds, _configId)
						end
					end
					configIds = xmlFile:getValue(configDependencyKey .. "#disabledConfigIds", nil, true)
					if configIds == nil then
						continue
					end
					for _, _configId in ipairs(configIds) do
						for i = #compound.configIds, 1, -1 do
							if compound.configIds[i] == _configId then
								table.remove(compound.configIds, i)
							end
						end
					end
				else
					local useCompound = xmlFile:getValue(configDependencyKey .. "#useCompound", false)
					if useCompound then
						isAllowed = false
					end
				end
			end
			if compound.name ~= nil then
				if isAllowed then
					local dashboardXMLFile = XMLFile.load("dashboardCompoundsXML", compound.filename, Dashboard.compoundsXMLSchema)
					if dashboardXMLFile ~= nil then
						local compoundKey = nil
						dashboardXMLFile:iterate("dashboardCompounds.dashboardCompound", function(index, _compoundKey)
							if dashboardXMLFile:getValue(_compoundKey .. "#name") == compound.name then
								compoundKey = _compoundKey
							end
						end)
						if compoundKey ~= nil then
							local i3dFilename = dashboardXMLFile:getValue(compoundKey .. "#filename")
							if i3dFilename ~= nil then
								i3dFilename = Utils.getFilename(i3dFilename, self.baseDirectory)
							end
							if i3dFilename == nil then
								Logging.xmlWarning(dashboardXMLFile, "Missing filename for compound '%s'", compound.name)
								return false
							else
								local arguments = { dashboardXMLFile = dashboardXMLFile, compound = compound, compoundKey = compoundKey }
								local sharedLoadRequestId = self:loadSubSharedI3DFile(i3dFilename, false, false, self.onDashboardCompoundLoaded, self, arguments)
								table.insert(self.spec_dashboard.sharedLoadRequestIds, sharedLoadRequestId)
								return true
							end
						else
							Logging.xmlWarning(dashboardXMLFile, "Unable to find compound by name '%s'", compound.name)
							dashboardXMLFile:delete()
							return false
						end
					end
				end
			else
				Logging.xmlWarning(xmlFile, "Missing name in '%s'", key)
				return false
			end
		end
		return false
	else
		return false
	end
end
function Dashboard:onDashboardCompoundLoaded(i3dNode, failedReason, args)
	local dashboardXMLFile = args.dashboardXMLFile
	local compound = args.compound
	local compoundKey = args.compoundKey
	if i3dNode ~= 0 then
		local components = {}
		for i = 1, getNumOfChildren(i3dNode) do
			table.insert(components, { node = getChildAt(i3dNode, i - 1) })
		end
		compound.i3dMappings = {}
		I3DUtil.loadI3DMapping(dashboardXMLFile, "dashboardCompounds", components, compound.i3dMappings, nil)
		self:loadDashboardCompoundFromExternalXML(dashboardXMLFile, compound, compoundKey, components)
		delete(i3dNode)
	end
	dashboardXMLFile:delete()
end
function Dashboard:loadDashboardCompoundFromExternalXML(dashboardXMLFile, compound, compoundKey, components)
	local node = dashboardXMLFile:getValue(compoundKey .. "#node", nil, components, compound.i3dMappings)
	if node ~= nil then
		link(compound.linkNode, node)
		setTranslation(node, 0, 0, 0)
		setRotation(node, 0, 0, 0)
		self:loadDashboardsFromXML(dashboardXMLFile, compoundKey, nil, components, compound.i3dMappings, node)
		for _, configKey in dashboardXMLFile:iterator(compoundKey .. ".configuration") do
			local isActive = false
			local id = dashboardXMLFile:getValue(configKey .. "#id")
			if id ~= nil and compound.configIds ~= nil then
				for _, _id in ipairs(compound.configIds) do
					if string.lower(id) == string.lower(_id) then
						isActive = true
					end
				end
			end
			local objects = {}
			ObjectChangeUtil.loadObjectChangeFromXML(dashboardXMLFile, configKey, objects, components, compound)
			ObjectChangeUtil.setObjectChanges(objects, isActive, compound)
			if isActive then
				self:loadDashboardsFromXML(dashboardXMLFile, configKey, nil, components, compound.i3dMappings, node)
			end
		end
		return true
	else
		Logging.xmlWarning(dashboardXMLFile, "Unable to find node for compound at '%s'", compoundKey)
		return false
	end
end
function Dashboard:loadDashboardsFromXML(xmlFile, key, dashboardValueType, components, i3dMappings, parentNode)
	if self.isClient then
		local spec = self.spec_dashboard
		xmlFile:iterate(key .. ".dashboard", function(index, dashboardKey)
			local valueTypeName = xmlFile:getValue(dashboardKey .. "#valueType")
			local dashboardValueTypeToUse = dashboardValueType
			local numMatches = 0
			if dashboardValueTypeToUse == nil and valueTypeName ~= nil then
				for _, _dashboardValueType in ipairs(spec.dashboardValueTypes) do
					if valueTypeName == _dashboardValueType.name or valueTypeName == _dashboardValueType.fullName then
						dashboardValueTypeToUse = _dashboardValueType
						numMatches = numMatches + 1
					end
				end
			end
			if 1 < numMatches and dashboardValueTypeToUse.xmlKey == nil then
				Logging.xmlWarning(xmlFile, "Dashboard valueType name '%s' is used in multiple specializations. Please specify with specialization prefix. (e.g. 'motorized.rpm')", valueTypeName)
			end
			if valueTypeName ~= nil and dashboardValueTypeToUse == nil then
				Logging.xmlWarning(xmlFile, "Unknown dashboard valueType '%s' for dashboard '%s'", valueTypeName, dashboardKey)
				return
			end
			local dashboard = {}
			if self:loadDashboardFromXML(xmlFile, dashboardKey, dashboard, dashboardValueTypeToUse, components or self.components, i3dMappings or self.i3dMappings, parentNode) then
				local typeData = Dashboard.TYPE_DATA[dashboard.displayTypeIndex]
				local isCritical = typeData.isCritical
				if dashboard.isCritical ~= nil then
					isCritical = dashboard.isCritical
				end
				if isCritical and dashboardValueTypeToUse ~= nil then
					if dashboardValueTypeToUse.pollUpdate or dashboard.doInterpolation then
						table.insert(spec.criticalDashboards, dashboard)
					else
						if dashboardValueTypeToUse ~= nil and not dashboardValueTypeToUse.pollUpdate then
							if not dashboard.doInterpolation then
								local fullName = dashboardValueTypeToUse.fullName
								if spec.dashboardsByValueType[fullName] == nil then
									spec.dashboardsByValueType[fullName] = {}
									spec.dashboardsByValueTypeDirty[fullName] = false
								end
								table.insert(spec.dashboardsByValueType[fullName], dashboard)
							elseif dashboardValueTypeToUse == nil then
								table.insert(spec.groupDashboards, dashboard)
							else
								table.insert(spec.tickDashboards, dashboard)
							end
						end
					end
				end
				spec.numDashboards = spec.numDashboards + 1
			end
		end)
	end
	return true
end
function Dashboard:loadDashboardFromXML(xmlFile, key, dashboard, valueType, components, i3dMappings, parentNode)
	dashboard.valueType = valueType
	if valueType ~= nil then
		if valueType.isa == nil or not valueType:isa(DashboardValueType) then
			Logging.error("Deprecated call of Dashboard:loadDashboardFromXML. Needs to be called with DashboardValueType object or nil.")
			printCallstack()
			return false
		end
		local valueTypeName = xmlFile:getValue(key .. "#valueType")
		if valueTypeName ~= dashboard.valueType.name and valueTypeName ~= dashboard.valueType.fullName then
			return false
		end
	end
	local displayType = xmlFile:getValue(key .. "#displayType")
	if displayType ~= nil then
		local displayTypeIndex = Dashboard.TYPES[string.upper(displayType)]
		if displayTypeIndex ~= nil then
			dashboard.displayTypeIndex = displayTypeIndex
			dashboard.doInterpolation = xmlFile:getValue(key .. "#doInterpolation", false)
			dashboard.isCritical = xmlFile:getValue(key .. "#isCritical")
			dashboard.useStateChange = xmlFile:getValue(key .. "#useStateChange", false)
			if dashboard.useStateChange then
				dashboard.stateChangeValue = xmlFile:getValue(key .. "#stateChangeValue")
				dashboard.stateChangeTime = xmlFile:getValue(key .. "#stateChangeTime", 0.2)
				dashboard.stateChangeLastValue = nil
				dashboard.stateChangeEndTime = -math.huge
			end
			local _v95 = key
			dashboard.idleValue = xmlFile:getValue(_v95 .. "#idleValue", _v95)
			dashboard.lastInterpolationValue = dashboard.idleValue
			dashboard.offsetValue = xmlFile:getValue(key .. "#offsetValue")
			dashboard.scaleFactor = xmlFile:getValue(key .. "#scaleFactor")
			dashboard.minActiveValue = xmlFile:getValue(key .. "#minActiveValue")
			dashboard.maxActiveValue = xmlFile:getValue(key .. "#maxActiveValue")
			if xmlFile:hasProperty(key .. ".valueMapping") then
				dashboard.valueMapping = AnimCurve.new(linearInterpolator1)
				for _, valueMappingKey in xmlFile:iterator(key .. ".valueMapping") do
					local sourceValue = xmlFile:getValue(valueMappingKey .. "#sourceValue")
					local dashboardValue = xmlFile:getValue(valueMappingKey .. "#dashboardValue")
					if sourceValue == nil or dashboardValue == nil then
						continue
					end
					dashboard.valueMapping:addKeyframe({ dashboardValue, ["time"] = sourceValue })
				end
				if dashboard.valueMapping.numKeyframes == 0 then
					dashboard.valueMapping = nil
				end
			end
			dashboard.groups = {}
			local groupsStr = xmlFile:getValue(key .. "#groups")
			if groupsStr ~= nil then
				local groups = string.split(groupsStr, " ")
				for _, name in ipairs(groups) do
					local group = self:getDashboardGroupByName(name)
					if group ~= nil then
						table.insert(dashboard.groups, group)
					else
						Logging.xmlWarning(xmlFile, "Unable to find dashboard group '%s' for dashboard '%s'", name, key)
					end
				end
			end
			if valueType ~= nil then
				if valueType.stateFunction ~= nil then
					dashboard.stateFunc = valueType.stateFunction
				else
					dashboard.stateFunc = Dashboard.defaultDashboardStateFunc
				end
			end
			local interpolationSpeed = nil
			if valueType ~= nil then
				interpolationSpeed = valueType:getInterpolationSpeed(dashboard)
			end
			dashboard.interpolationSpeed = xmlFile:getValue(key .. "#interpolationSpeed", interpolationSpeed or 0.005)
			local typeData = Dashboard.TYPE_DATA[dashboard.displayTypeIndex]
			if typeData ~= nil then
				if not typeData.loadFunc(self, xmlFile, key, dashboard, components, i3dMappings, parentNode) then
					return false
				elseif valueType ~= nil and (valueType.loadFunction ~= nil and not valueType.loadFunction(self, xmlFile, key, dashboard, components, i3dMappings, parentNode)) then
					return false
				else
					dashboard.lastValue = nil
					return true
				end
			end
			return false
		else
			Logging.xmlWarning(xmlFile, "Unknown displayType '%s' for dashboard '%s'", displayType, key)
			return false
		end
	end
	Logging.xmlWarning(xmlFile, "Missing displayType for dashboard '%s'", key)
	return false
end
function Dashboard:defaultDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	local typeData = Dashboard.TYPE_DATA[dashboard.displayTypeIndex]
	typeData.updateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
end
function Dashboard:setDashboardsDirty()
	self.spec_dashboard.isDirty = true
	self.spec_dashboard.isDirtyTick = true
	self:raiseActive()
end
function Dashboard:getDashboardValue(valueObject, valueFunc, dashboard)
	if type(valueFunc) == "number" or type(valueFunc) == "boolean" then
		return valueFunc
	end
	if type(valueFunc) == "function" then
		return valueFunc(valueObject, dashboard)
	end
	local object = valueObject[valueFunc]
	if type(object) == "function" then
		return valueObject[valueFunc](valueObject, dashboard)
	elseif type(object) == "number" or type(object) == "boolean" then
		return object
	else
		return nil
	end
end
function Dashboard.getDashboardColor(xmlFile, colorStr, customEnvironment)
	if colorStr == nil then
		return nil
	end
	if Dashboard.COLORS[string.upper(colorStr)] ~= nil then
		return Dashboard.COLORS[string.upper(colorStr)]
	end
	local brandColor = g_vehicleMaterialManager:getMaterialTemplateColorByName(colorStr, customEnvironment)
	if brandColor ~= nil then
		return brandColor
	else
		local vector = string.getVector(colorStr)
		if vector ~= nil and 3 <= #vector then
			if #vector == 3 then
				vector[4] = 1
			end
			return vector
		end
		Logging.xmlWarning(xmlFile, "Unable to resolve color '%s'", colorStr)
		return nil
	end
end
function Dashboard:warningAttributes(xmlFile, key, dashboard, isActive)
	dashboard.warningThresholdMin = xmlFile:getValue(key .. "#warningThresholdMin", -math.huge)
	dashboard.warningThresholdMax = xmlFile:getValue(key .. "#warningThresholdMax", math.huge)
	return true
end
function Dashboard.registerDisplayType(typeIndex, isCritical, schemaFunc, loadFunc, updateFunc)
	local typeData = { ["isCritical"] = isCritical, ["schemaFunc"] = schemaFunc, ["loadFunc"] = loadFunc, ["updateFunc"] = updateFunc }
	Dashboard.TYPE_DATA[typeIndex] = typeData
end
Dashboard.registerDisplayType(Dashboard.TYPES.EMITTER, false, function(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#baseColor", "(EMITTER) Base color (DashboardColor OR BrandColor OR r g b a)")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#emitColor", "(EMITTER) Emit color (DashboardColor OR BrandColor OR r g b a)")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#intensity", "Intensity", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".dashboard(?)#inverted", "(EMITTER) State will be inverted", false)
	schema:register(XMLValueType.BOOL, basePath .. ".dashboard(?)#toggleVisibility", "(EMITTER) If the mesh is not emitting (idle), the mesh will be hidden", false)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#inactiveGroups", "(EMITTER) If defined, the inactive color/intensity will only be set if this group is active (if not active, the disabled color/intensity is used)")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#disabledIntensity", "(EMITTER) Intensity while the dashboard group is not active")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#disabledColor", "(EMITTER) Disabled emit color (DashboardColor OR BrandColor OR r g b a)")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#inactiveIntensity", "(EMITTER) Intensity while the dashboard state is not active, but the group is active")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#inactiveColor", "(EMITTER) Inactive emit color (DashboardColor OR BrandColor OR r g b a)")
	schema:register(XMLValueType.BOOL, basePath .. ".dashboard(?)#hideInactive", "(EMITTER) Hide the emitter shape when the dashboard is inactive", false)
	schema:register(XMLValueType.BOOL, basePath .. ".dashboard(?)#hideInactiveChildren", "(EMITTER) Hide all the children when the dashboard is inactive", false)
end, function(vehicle, xmlFile, key, dashboard, components, i3dMappings, parentNode)
	local node = xmlFile:getValue(key .. "#node", nil, components, i3dMappings)
	if node ~= nil then
		if parentNode ~= nil and not I3DUtil.getIsLinkedToNode(parentNode, node) then
			Logging.xmlWarning(xmlFile, "Emitter dashboard node '%s' is not a child of the parent node '%s' in '%s'", getName(node), getName(parentNode), key)
			return false
		end
		if getHasClassId(node, ClassIds.SHAPE) then
			if not getHasShaderParameter(node, "lightControl") and not getHasShaderParameter(node, "lightIds0") then
				Logging.xmlWarning(xmlFile, "Emitter dashboard shape not using 'lightControl' or 'lightIds0' shader parameter in '%s'", key)
				return false
			end
			dashboard.node = node
			dashboard.inverted = xmlFile:getValue(key .. "#inverted", false)
			dashboard.toggleVisibility = xmlFile:getValue(key .. "#toggleVisibility", false)
			dashboard.baseColor = Dashboard.getDashboardColor(xmlFile, xmlFile:getValue(key .. "#baseColor"), vehicle.customEnvironment)
			if dashboard.baseColor ~= nil then
				setShaderParameter(dashboard.node, "baseColor", dashboard.baseColor[1], dashboard.baseColor[2], dashboard.baseColor[3], 1, false)
			end
			dashboard.disabledIntensity = xmlFile:getValue(key .. "#disabledIntensity")
			dashboard.disabledColor = Dashboard.getDashboardColor(xmlFile, xmlFile:getValue(key .. "#disabledColor"), vehicle.customEnvironment)
			dashboard.inactiveIntensity = xmlFile:getValue(key .. "#inactiveIntensity")
			dashboard.inactiveColor = Dashboard.getDashboardColor(xmlFile, xmlFile:getValue(key .. "#inactiveColor"), vehicle.customEnvironment)
			dashboard.inactiveGroups = {}
			local groupsStr = xmlFile:getValue(key .. "#inactiveGroups")
			if groupsStr ~= nil then
				local groups = string.split(groupsStr, " ")
				for _, name in ipairs(groups) do
					local group = vehicle:getDashboardGroupByName(name)
					if group ~= nil then
						table.insert(dashboard.inactiveGroups, group)
					else
						Logging.xmlWarning(xmlFile, "Unable to find inactive dashboard group '%s' for dashboard '%s'", name, key)
					end
				end
			end
			dashboard.emitColor = Dashboard.getDashboardColor(xmlFile, xmlFile:getValue(key .. "#emitColor"), vehicle.customEnvironment)
			if dashboard.emitColor ~= nil then
				setShaderParameter(dashboard.node, "emitColor", dashboard.emitColor[1], dashboard.emitColor[2], dashboard.emitColor[3], 1, false)
			end
			dashboard.intensity = xmlFile:getValue(key .. "#intensity", 1)
			dashboard.hideInactive = xmlFile:getValue(key .. "#hideInactive", false)
			dashboard.hideInactiveChildren = xmlFile:getValue(key .. "#hideInactiveChildren", false)
			dashboard.useLightControlShaderParameter = getHasShaderParameter(node, "lightControl")
			if dashboard.stateFunc ~= nil then
				dashboard.stateFunc(vehicle, dashboard, dashboard.inverted, nil, nil, dashboard.inverted)
			end
			return true
		else
			Logging.xmlWarning(xmlFile, "Emitter Dashboard node is not a shape! '%s' in '%s'", getName(node), key)
			return false
		end
	end
	Logging.xmlWarning(xmlFile, "Missing node for emitter dashboard '%s'", key)
	return false
end, function(vehicle, dashboard, newValue, minValue, maxValue, isActive)
	if type(newValue) == "number" then
		newValue = 0.5 < newValue and true or false
	end
	local intensity = 1
	local emitColor = nil
	if dashboard.hideInactive then
		if not isActive then
			setVisibility(dashboard.node, false)
			return
		end
		setVisibility(dashboard.node, true)
	end
	if dashboard.hideInactiveChildren then
		for i = 1, getNumOfChildren(dashboard.node) do
			setVisibility(getChildAt(dashboard.node, i - 1), isActive)
		end
	end
	if newValue ~= nil then
		if dashboard.inverted then
			newValue = not newValue
		end
		local inactiveIntensity = dashboard.inactiveIntensity
		local inactiveColor = dashboard.inactiveColor
		for j = 1, #dashboard.inactiveGroups do
			if not dashboard.inactiveGroups[j].isActive then
				inactiveIntensity = dashboard.disabledIntensity
				inactiveColor = dashboard.disabledColor
				break
			end
		end
		if newValue then
			local _v41 = dashboard.intensity or inactiveIntensity or dashboard.idleValue
		end
		intensity = _v41
		emitColor = newValue and dashboard.emitColor or inactiveColor
		if not isActive then
			intensity = dashboard.disabledIntensity or dashboard.idleValue
			emitColor = dashboard.disabledColor
		end
		if dashboard.toggleVisibility then
			setVisibility(dashboard.node, newValue)
		end
	end
	setShaderParameter(dashboard.node, "emitColor", emitColor[1], emitColor[2], emitColor[3], 1, false)
	local isEmitting = emitColor ~= nil and 0 < intensity
	if dashboard.baseColor ~= nil then
		setShaderParameter(dashboard.node, "baseColor", dashboard.baseColor[1], dashboard.baseColor[2], dashboard.baseColor[3], 1, false)
	elseif isEmitting then
		setShaderParameter(dashboard.node, "baseColor", 0, 0, 0, 1, false)
	else
		setShaderParameter(dashboard.node, "baseColor", nil, nil, nil, 0, false)
	end
	if dashboard.useLightControlShaderParameter then
		setShaderParameter(dashboard.node, "lightControl", intensity, nil, nil, nil, false)
	else
		setShaderParameter(dashboard.node, "lightIds0", intensity, intensity, intensity, intensity, false)
		setShaderParameter(dashboard.node, "lightIds1", intensity, intensity, intensity, intensity, false)
		setShaderParameter(dashboard.node, "lightIds2", intensity, intensity, intensity, intensity, false)
		setShaderParameter(dashboard.node, "lightIds3", intensity, intensity, intensity, intensity, false)
	end
end)
Dashboard.registerDisplayType(Dashboard.TYPES.NUMBER, false, function(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".dashboard(?)#numbers", "(NUMBER) Numbers node")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#numberColor", "(NUMBER) Numbers color (DashboardColor OR BrandColor OR r g b a)")
	schema:register(XMLValueType.INT, basePath .. ".dashboard(?)#precision", "(NUMBER) Precision", 1)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#font", "(NUMBER) Name of font to apply to mesh", "DIGIT")
	schema:register(XMLValueType.BOOL, basePath .. ".dashboard(?)#hasNormalMap", "(NUMBER) Normal map will be applied to number decals", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#emissiveScale", "(NUMBER) Scale of emissive map", 0.2)
end, function(vehicle, xmlFile, key, dashboard, components, i3dMappings, parentNode)
	dashboard.numbers = xmlFile:getValue(key .. "#numbers", nil, components, i3dMappings)
	if parentNode ~= nil and not I3DUtil.getIsLinkedToNode(parentNode, dashboard.numbers) then
		Logging.xmlWarning(xmlFile, "Numbers dashboard node '%s' is not a child of the parent node '%s' in '%s'", getName(dashboard.numbers), getName(parentNode), key)
		return false
	end
	dashboard.numberColor = Dashboard.getDashboardColor(xmlFile, xmlFile:getValue(key .. "#numberColor"), vehicle.customEnvironment)
	if dashboard.numberColor == nil then
		dashboard.numberColor = { 0.9, 0.9, 0.9, 1 }
	end
	if dashboard.numbers ~= nil then
		dashboard.precision = xmlFile:getValue(key .. "#precision", 1)
		dashboard.numChildren = getNumOfChildren(dashboard.numbers)
		dashboard.fontMaterialName = xmlFile:getValue(key .. "#font", "DIGIT")
		dashboard.hasNormalMap = xmlFile:getValue(key .. "#hasNormalMap", false)
		dashboard.emissiveScale = xmlFile:getValue(key .. "#emissiveScale", 0.2)
		XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#hiddenAlpha")
		dashboard.fontMaterial = g_materialManager:getFontMaterial(dashboard.fontMaterialName, vehicle.customEnvironment)
		if dashboard.fontMaterial ~= nil then
			dashboard.numberNodes = {}
			if dashboard.numChildren - dashboard.precision <= 0 then
				Logging.xmlWarning(xmlFile, "Not enough number meshes for vehicle hud '%s'", key)
				return false
			else
				for i = 1, dashboard.numChildren do
					local numberNode = getChildAt(dashboard.numbers, i - 1)
					if numberNode == nil then
						continue
					end
					dashboard.fontMaterial:assignFontMaterialToNode(numberNode, dashboard.hasNormalMap)
					if dashboard.numberColor ~= nil then
						dashboard.fontMaterial:setFontCharacterColor(numberNode, dashboard.numberColor[1], dashboard.numberColor[2], dashboard.numberColor[3], 1, dashboard.emissiveScale)
					end
					setVisibility(numberNode, false)
					table.insert(dashboard.numberNodes, numberNode)
				end
				dashboard.maxValue = 10 ^ dashboard.numChildren - 1 / 10 ^ dashboard.precision
				return true
			end
		end
		Logging.xmlWarning(xmlFile, "Unknown font '%s' in '%s'", dashboard.fontMaterialName, key)
		return false
	else
		Logging.xmlWarning(xmlFile, "Missing numbers node for dashboard '%s'", key)
		return false
	end
end, function(vehicle, dashboard, newValue, minValue, maxValue, isActive)
	if type(newValue) == "number" then
		local value = tonumber(string.format("%." .. dashboard.precision .. "f", newValue))
		value = math.floor(value * 10 ^ dashboard.precision)
		for i = 1, #dashboard.numberNodes do
			local numberNode = dashboard.numberNodes[i]
			if 0 < value then
				local curNumber = value - math.floor(value / 10) * 10
				value = (value - curNumber) / 10
				dashboard.fontMaterial:setFontCharacter(numberNode, ("%d"):format(curNumber))
				setVisibility(numberNode, true)
			else
				dashboard.fontMaterial:setFontCharacter(numberNode, "0")
				if not isActive or not (i - 1 <= dashboard.precision) then
					setVisibility(numberNode, false)
				end
			end
		end
	elseif type(newValue) == "string" then
		local length = newValue:len()
		for i = 1, #dashboard.numberNodes do
			local numberNode = dashboard.numberNodes[i]
			if i <= length then
				local index = length - (i - 1)
				dashboard.fontMaterial:setFontCharacter(numberNode, newValue:sub(index, index))
			end
			setVisibility(numberNode, isActive)
		end
	end
end)
Dashboard.registerDisplayType(Dashboard.TYPES.ANIMATION, true, function(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#animName", "(ANIMATION) Animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#minValueAnim", "(ANIMATION) Min. reference value for animation")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#maxValueAnim", "(ANIMATION) Max. reference value for animation")
end, function(vehicle, xmlFile, key, dashboard, components, i3dMappings)
	dashboard.animName = xmlFile:getValue(key .. "#animName")
	if dashboard.animName ~= nil then
		dashboard.minValueAnim = xmlFile:getValue(key .. "#minValueAnim")
		dashboard.maxValueAnim = xmlFile:getValue(key .. "#maxValueAnim")
		return true
	else
		Logging.xmlWarning(xmlFile, "Missing animation for dashboard '%s'", key)
		return false
	end
end, function(vehicle, dashboard, newValue, minValue, maxValue, isActive)
	if dashboard.animName ~= nil then
		if vehicle:getAnimationExists(dashboard.animName) then
			if type(newValue) == "boolean" then
				newValue = newValue and 1 or 0
			end
			local normValue = nil
			if dashboard.minValueAnim ~= nil then
				if dashboard.maxValueAnim ~= nil then
					newValue = math.clamp(newValue, dashboard.minValueAnim, dashboard.maxValueAnim)
					normValue = MathUtil.round((newValue - dashboard.minValueAnim) / (dashboard.maxValueAnim - dashboard.minValueAnim), 3)
				else
					minValue = minValue or 0
					maxValue = maxValue or 1
					normValue = MathUtil.round((newValue - minValue) / (maxValue - minValue), 3)
				end
			end
			vehicle:setAnimationTime(dashboard.animName, normValue, true)
			return
		end
		Logging.xmlWarning(vehicle.xmlFile, "Unknown animation name '%s' for dashboard!", dashboard.animName)
		dashboard.animName = nil
	end
end)
Dashboard.registerDisplayType(Dashboard.TYPES.ROT, true, function(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#rotAxis", "(ROT) Rotation axis")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#minRot", "(ROT) Min. rotation (Rotation value if rotAxis is given | Rotation Vector of rotAxis is not given)")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#maxRot", "(ROT) Max. rotation (Rotation value if rotAxis is given | Rotation Vector of rotAxis is not given)")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#minValueRot", "(ROT) Min. reference value for rotation")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#maxValueRot", "(ROT) Max. reference value for rotation")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#intensity", "Intensity", 1)
end, function(vehicle, xmlFile, key, dashboard, components, i3dMappings, parentNode)
	dashboard.node = xmlFile:getValue(key .. "#node", nil, components, i3dMappings)
	if dashboard.node == nil then
		Logging.xmlWarning(xmlFile, "Missing 'node' for dashboard '%s'", key)
		return false
	elseif parentNode ~= nil and not I3DUtil.getIsLinkedToNode(parentNode, dashboard.node) then
		Logging.xmlWarning(xmlFile, "Rotation dashboard node '%s' is not a child of the parent node '%s' in '%s'", getName(dashboard.node), getName(parentNode), key)
		return false
	else
		dashboard.rotAxis = xmlFile:getValue(key .. "#rotAxis")
		local minRotStr = xmlFile:getValue(key .. "#minRot")
		if minRotStr ~= nil then
			if dashboard.rotAxis ~= nil then
				dashboard.minRot = math.rad(tonumber(minRotStr))
			else
				dashboard.minRot = minRotStr:getRadians(3)
			end
			local maxRotStr = xmlFile:getValue(key .. "#maxRot")
			if maxRotStr ~= nil then
				if dashboard.rotAxis ~= nil then
					dashboard.maxRot = math.rad(tonumber(maxRotStr))
				else
					dashboard.maxRot = maxRotStr:getRadians(3)
				end
				dashboard.minValueRot = xmlFile:getValue(key .. "#minValueRot")
				dashboard.maxValueRot = xmlFile:getValue(key .. "#maxValueRot")
				dashboard.intensity = xmlFile:getValue(key .. "#intensity")
				if dashboard.intensity ~= nil and (getHasClassId(dashboard.node, ClassIds.SHAPE) and getHasShaderParameter(dashboard.node, "lightControl")) then
					setShaderParameter(dashboard.node, "lightControl", dashboard.intensity, 0, 0, 0, false)
				end
				return true
			else
				Logging.xmlWarning(xmlFile, "Missing 'maxRot' attribute for dashboard '%s'", key)
				return false
			end
		end
		Logging.xmlWarning(xmlFile, "Missing 'minRot' attribute for dashboard '%s'", key)
		return false
	end
end, function(vehicle, dashboard, newValue, minValue, maxValue, isActive)
	local alpha = nil
	if type(newValue) == "boolean" then
		alpha = newValue and 1 or 0
	elseif dashboard.minValueRot ~= nil then
		if dashboard.maxValueRot ~= nil then
			newValue = math.clamp(newValue, dashboard.minValueRot, dashboard.maxValueRot)
			alpha = MathUtil.round((newValue - dashboard.minValueRot) / (dashboard.maxValueRot - dashboard.minValueRot), 3)
		else
			minValue = minValue or 0
			maxValue = maxValue or 1
			alpha = (newValue - minValue) / (maxValue - minValue)
		end
	end
	if dashboard.rotAxis ~= nil then
		local x, y, z = getRotation(dashboard.node)
		local rot = MathUtil.lerp(dashboard.minRot, dashboard.maxRot, alpha)
		if dashboard.rotAxis == 1 then
			x = rot
		elseif dashboard.rotAxis == 2 then
			y = rot
		else
			z = rot
		end
		setRotation(dashboard.node, x, y, z)
		if vehicle.setCharacterTargetNodeStateDirty ~= nil then
			vehicle:setCharacterTargetNodeStateDirty(dashboard.node)
		end
		if vehicle.setMovingToolDirty ~= nil then
			vehicle:setMovingToolDirty(dashboard.node)
		end
	else
		local x, y, z = MathUtil.vector3ArrayLerp(dashboard.minRot, dashboard.maxRot, alpha)
		setRotation(dashboard.node, x, y, z)
		if vehicle.setCharacterTargetNodeStateDirty ~= nil then
			vehicle:setCharacterTargetNodeStateDirty(dashboard.node)
		end
		if vehicle.setMovingToolDirty ~= nil then
			vehicle:setMovingToolDirty(dashboard.node)
		end
	end
end)
Dashboard.registerDisplayType(Dashboard.TYPES.TRANS, true, function(schema, basePath)
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".dashboard(?)#minTrans", "(TRANS) Min. translation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".dashboard(?)#maxTrans", "(TRANS) Max. translation")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#minValueTrans", "(TRANS) Min. reference value for translation")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#maxValueTrans", "(TRANS) Max. reference value for translation")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#intensity", "Intensity", 1)
end, function(vehicle, xmlFile, key, dashboard, components, i3dMappings, parentNode)
	dashboard.node = xmlFile:getValue(key .. "#node", nil, components, i3dMappings)
	if dashboard.node == nil then
		Logging.xmlWarning(xmlFile, "Missing 'node' for dashboard '%s'", key)
		return false
	elseif parentNode ~= nil and not I3DUtil.getIsLinkedToNode(parentNode, dashboard.node) then
		Logging.xmlWarning(xmlFile, "Translation dashboard node '%s' is not a child of the parent node '%s' in '%s'", getName(dashboard.node), getName(parentNode), key)
		return false
	else
		dashboard.minTrans = xmlFile:getValue(key .. "#minTrans", nil, true)
		dashboard.maxTrans = xmlFile:getValue(key .. "#maxTrans", nil, true)
		if dashboard.minTrans ~= nil then
			if dashboard.maxTrans == nil then
				Logging.xmlWarning(xmlFile, "Missing 'maxTrans' attribute for dashboard '%s'", key)
			elseif dashboard.maxTrans ~= nil then
				if dashboard.minTrans == nil then
					Logging.xmlWarning(xmlFile, "Missing 'minTrans' attribute for dashboard '%s'", key)
				end
			end
		end
		dashboard.minValueTrans = xmlFile:getValue(key .. "#minValueTrans")
		dashboard.maxValueTrans = xmlFile:getValue(key .. "#maxValueTrans")
		dashboard.intensity = xmlFile:getValue(key .. "#intensity")
		if dashboard.intensity ~= nil and (getHasClassId(dashboard.node, ClassIds.SHAPE) and getHasShaderParameter(dashboard.node, "lightControl")) then
			setShaderParameter(dashboard.node, "lightControl", dashboard.intensity, 0, 0, 0, false)
		end
		return true
	end
end, function(vehicle, dashboard, newValue, minValue, maxValue, isActive)
	local alpha = nil
	if type(newValue) == "boolean" then
		alpha = newValue and 1 or 0
	elseif dashboard.minValueTrans ~= nil then
		if dashboard.maxValueTrans ~= nil then
			newValue = math.clamp(newValue, dashboard.minValueTrans, dashboard.maxValueTrans)
			alpha = MathUtil.round((newValue - dashboard.minValueTrans) / (dashboard.maxValueTrans - dashboard.minValueTrans), 3)
		else
			minValue = minValue or 0
			maxValue = maxValue or 1
			alpha = (newValue - minValue) / (maxValue - minValue)
		end
	end
	local x, y, z = MathUtil.vector3ArrayLerp(dashboard.minTrans, dashboard.maxTrans, alpha)
	setTranslation(dashboard.node, x, y, z)
	if vehicle.setCharacterTargetNodeStateDirty ~= nil then
		vehicle:setCharacterTargetNodeStateDirty(dashboard.node)
	end
	if vehicle.setMovingToolDirty ~= nil then
		vehicle:setMovingToolDirty(dashboard.node)
	end
end)
Dashboard.registerDisplayType(Dashboard.TYPES.VISIBILITY, false, function(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. ".dashboard(?)#inverted", "(VISIBILITY) State will be inverted", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#intensity", "Intensity", 1)
end, function(vehicle, xmlFile, key, dashboard, components, i3dMappings, parentNode)
	dashboard.node = xmlFile:getValue(key .. "#node", nil, components, i3dMappings)
	if dashboard.node == nil then
		Logging.xmlWarning(xmlFile, "Missing 'node' for dashboard '%s'", key)
		return false
	elseif parentNode ~= nil and not I3DUtil.getIsLinkedToNode(parentNode, dashboard.node) then
		Logging.xmlWarning(xmlFile, "Visibility dashboard node '%s' is not a child of the parent node '%s' in '%s'", getName(dashboard.node), getName(parentNode), key)
		return false
	else
		dashboard.inverted = xmlFile:getValue(key .. "#inverted", false)
		setVisibility(dashboard.node, dashboard.inverted)
		dashboard.intensity = xmlFile:getValue(key .. "#intensity")
		if dashboard.intensity ~= nil and (getHasClassId(dashboard.node, ClassIds.SHAPE) and getHasShaderParameter(dashboard.node, "lightControl")) then
			setShaderParameter(dashboard.node, "lightControl", dashboard.intensity, 0, 0, 0, false)
		end
		return true
	end
end, function(vehicle, dashboard, newValue, minValue, maxValue, isActive)
	if type(newValue) == "number" then
		newValue = 0.5 < newValue
	end
	newValue = newValue == nil and isActive or newValue and isActive
	if dashboard.inverted then
		newValue = not newValue
	end
	setVisibility(dashboard.node, newValue)
end)
Dashboard.registerDisplayType(Dashboard.TYPES.TEXT, false, function(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#textColor", "(TEXT) Font color (DashboardColor OR BrandColor OR r g b a)")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#hiddenColor", "(TEXT) Color of hidden character (if defined a '0' in this color is display instead of nothing)")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#textAlignment", "(TEXT) Alignment of text (LEFT | RIGHT | CENTER)", "RIGHT")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#textSize", "(TEXT) Size of font in meter", 0.03)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#fontThickness", "(TEXT) Thickness factor for font characters", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#textScaleX", "(TEXT) Global X scale of text", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#textScaleY", "(TEXT) Global Y scale of text", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#textSpacing", "(TEXT) Scale factor for spacing between the characters", 1)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#textMask", "(TEXT) Font Mask", "00.0")
end, function(vehicle, xmlFile, key, dashboard, components, i3dMappings, parentNode)
	dashboard.node = xmlFile:getValue(key .. "#node", nil, components, i3dMappings)
	if dashboard.node == nil then
		Logging.xmlWarning(xmlFile, "Missing 'node' for text dashboard '%s'", key)
		return false
	elseif parentNode ~= nil and not I3DUtil.getIsLinkedToNode(parentNode, dashboard.node) then
		Logging.xmlWarning(xmlFile, "Visibility dashboard node '%s' is not a child of the parent node '%s' in '%s'", getName(dashboard.node), getName(parentNode), key)
		return false
	else
		dashboard.textColor = Dashboard.getDashboardColor(xmlFile, xmlFile:getValue(key .. "#textColor"), vehicle.customEnvironment)
		if dashboard.textColor == nil then
			dashboard.textColor = { 0.9, 0.9, 0.9, 1 }
		end
		dashboard.hiddenColor = Dashboard.getDashboardColor(xmlFile, xmlFile:getValue(key .. "#hiddenColor"), vehicle.customEnvironment)
		local textAlignmentStr = xmlFile:getValue(key .. "#textAlignment", "RIGHT")
		dashboard.textAlignment = RenderText["ALIGN_" .. string.upper(textAlignmentStr)] or RenderText.ALIGN_RIGHT
		dashboard.textSize = xmlFile:getValue(key .. "#textSize", 0.03)
		dashboard.textScaleX = xmlFile:getValue(key .. "#textScaleX", 1)
		dashboard.textScaleY = xmlFile:getValue(key .. "#textScaleY", 1)
		dashboard.textSpacing = xmlFile:getValue(key .. "#textSpacing", 1)
		dashboard.textMask = xmlFile:getValue(key .. "#textMask", "00.0")
		dashboard.textFormatStr, dashboard.textFormatPrecision = Utils.maskToFormat(dashboard.textMask)
		dashboard.fontName = string.upper(xmlFile:getValue(key .. "#font", "DIGIT"))
		dashboard.fontThickness = xmlFile:getValue(key .. "#fontThickness", 1)
		dashboard.emissiveScale = xmlFile:getValue(key .. "#emissiveScale", 0.2)
		local fontMaterial = g_materialManager:getFontMaterial(dashboard.fontName, vehicle.customEnvironment)
		if fontMaterial ~= nil then
			dashboard.characterLine = CharacterLine.new(dashboard.node, fontMaterial, dashboard.textMask:len())
			dashboard.characterLine:setSizeAndScale(dashboard.textSize, dashboard.textScaleX, dashboard.textScaleY)
			dashboard.characterLine:setTextAlignment(dashboard.textAlignment)
			dashboard.characterLine:setFontThickness(dashboard.fontThickness)
			dashboard.characterLine:setUseNormalMap(false)
			dashboard.characterLine:setColor(dashboard.textColor, dashboard.hiddenColor, dashboard.emissiveScale)
			dashboard.characterLine:setDecalLayer(2)
			dashboard.characterLine:setCharacterSpacing(dashboard.textSpacing)
			if dashboard.characterLine == nil then
				Logging.xmlWarning(xmlFile, "Failed to create text in '%s'", key)
				return false
			else
				dashboard.characterLine:setText(dashboard.textMask)
				dashboard.lastIntValue = nil
				dashboard.lastFloatValue = nil
				dashboard.lastTextLength = string.len(dashboard.textMask)
				setVisibility(dashboard.characterLine.rootNode, false)
				return true
			end
		end
		Logging.xmlWarning(xmlFile, "Unknown font '%s' in '%s'", dashboard.fontName, key)
		return false
	end
end, function(vehicle, dashboard, newValue, minValue, maxValue, isActive)
	if type(newValue) == "number" then
		local int, floatPart = math.modf(newValue)
		floatPart = math.abs(math.floor((floatPart + 0.000001) * 10 ^ dashboard.textFormatPrecision))
		if int ~= dashboard.lastIntValue or floatPart ~= dashboard.lastFloatValue then
			local value = string.ltrim(string.format(dashboard.textFormatStr, int, floatPart))
			local textLength = string.len(value)
			dashboard.characterLine:setText(value, textLength ~= dashboard.lastTextLength)
			dashboard.lastIntValue = int
			dashboard.lastFloatValue = floatPart
			dashboard.lastTextLength = textLength
		end
	elseif type(newValue) == "string" then
		local textLength = string.len(newValue)
		dashboard.characterLine:setText(newValue, textLength ~= dashboard.lastTextLength)
		dashboard.lastTextLength = textLength
	end
	setVisibility(dashboard.characterLine.rootNode, isActive)
end)
Dashboard.registerDisplayType(Dashboard.TYPES.SLIDER, false, function(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#minValueSlider", "(SLIDER) Min. reference value for slider")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#maxValueSlider", "(SLIDER) Max. reference value for slider")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#intensity", "Intensity", 1)
end, function(vehicle, xmlFile, key, dashboard, components, i3dMappings, parentNode)
	dashboard.node = xmlFile:getValue(key .. "#node", nil, components, i3dMappings)
	if dashboard.node == nil then
		Logging.xmlWarning(xmlFile, "Missing 'node' for dashboard '%s'", key)
		return false
	end
	if parentNode ~= nil and not I3DUtil.getIsLinkedToNode(parentNode, dashboard.node) then
		Logging.xmlWarning(xmlFile, "Slider dashboard node '%s' is not a child of the parent node '%s' in '%s'", getName(dashboard.node), getName(parentNode), key)
		return false
	end
	if not getHasClassId(dashboard.node, ClassIds.SHAPE) then
		Logging.xmlWarning(xmlFile, "Slider Dashboard node is not a shape! '%s' in '%s'", getName(dashboard.node), key)
		return false
	elseif getHasShaderParameter(dashboard.node, "sliderPos") then
		setShaderParameter(dashboard.node, "sliderPos", 0, 0, 0, 0, false)
		dashboard.minValueSlider = xmlFile:getValue(key .. "#minValueSlider")
		dashboard.maxValueSlider = xmlFile:getValue(key .. "#maxValueSlider")
		if dashboard.minValueSlider ~= nil then
			if dashboard.maxValueSlider == nil then
				Logging.xmlWarning(xmlFile, "Missing 'maxValueSlider' attribute for dashboard '%s'", key)
				dashboard.minValueSlider = nil
			elseif dashboard.maxValueSlider ~= nil then
				if dashboard.minValueSlider == nil then
					Logging.xmlWarning(xmlFile, "Missing 'minValueSlider' attribute for dashboard '%s'", key)
					dashboard.maxValueSlider = nil
				end
			end
		end
		dashboard.intensity = xmlFile:getValue(key .. "#intensity", 1)
		setShaderParameter(dashboard.node, "lightControl", dashboard.intensity, 0, 0, 0, false)
		return true
	else
		Logging.xmlWarning(xmlFile, "Node '%s' does not have a 'sliderPos' shader parameter for dashboard '%s'", getName(dashboard.node), key)
		return false
	end
end, function(vehicle, dashboard, newValue, minValue, maxValue, isActive)
	if dashboard.node ~= nil then
		if type(newValue) == "boolean" then
			newValue = newValue and 1 or 0
		end
		local normValue = nil
		if dashboard.minValueSlider ~= nil then
			if dashboard.maxValueSlider ~= nil then
				newValue = math.clamp(newValue, dashboard.minValueSlider, dashboard.maxValueSlider)
				normValue = MathUtil.round((newValue - dashboard.minValueSlider) / (dashboard.maxValueSlider - dashboard.minValueSlider), 3)
			else
				minValue = minValue or 0
				maxValue = maxValue or 1
				normValue = MathUtil.round((newValue - minValue) / (maxValue - minValue), 3)
			end
		end
		setShaderParameter(dashboard.node, "sliderPos", normValue, 0, 0, 0, false)
	end
end)
Dashboard.registerDisplayType(Dashboard.TYPES.MULTI_STATE, false, function(schema, basePath)
	schema:register(XMLValueType.VECTOR_N, basePath .. ".dashboard(?).state(?)#value", "(MULTI_STATE) One or multiple values separated by space to activate the state")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".dashboard(?).state(?)#rotation", "(MULTI_STATE) Rotation while state is active")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".dashboard(?).state(?)#translation", "(MULTI_STATE) Translation while state is active")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".dashboard(?).state(?)#scale", "(MULTI_STATE) Scale while state is active")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?).state(?)#intensity", "(MULTI_STATE) Intensity if the node is a emitter")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?).state(?)#emitColor", "(MULTI_STATE) Emit color if the node is a emitter")
	schema:register(XMLValueType.BOOL, basePath .. ".dashboard(?).state(?)#visibility", "(MULTI_STATE) Visibility while state is active")
end, function(vehicle, xmlFile, key, dashboard, components, i3dMappings, parentNode)
	dashboard.node = xmlFile:getValue(key .. "#node", nil, components, i3dMappings)
	if dashboard.node == nil then
		Logging.xmlWarning(xmlFile, "Missing 'node' for dashboard '%s'", key)
		return false
	end
	if parentNode ~= nil and not I3DUtil.getIsLinkedToNode(parentNode, dashboard.node) then
		Logging.xmlWarning(xmlFile, "Multi state dashboard node '%s' is not a child of the parent node '%s' in '%s'", getName(dashboard.node), getName(parentNode), key)
		return false
	end
	dashboard.hasVisibility = false
	dashboard.hasEmitColor = false
	dashboard.hasIntensity = false
	dashboard.defaultStateIndex = -1
	dashboard.states = {}
	xmlFile:iterate(key .. ".state", function(index, stateKey)
		local state = {}
		state.values = xmlFile:getValue(stateKey .. "#value", nil, true)
		if state.values == nil then
			dashboard.defaultStateIndex = index
		end
		state.rotation = xmlFile:getValue(stateKey .. "#rotation", nil, true)
		state.translation = xmlFile:getValue(stateKey .. "#translation", nil, true)
		state.scale = xmlFile:getValue(stateKey .. "#scale", nil, true)
		state.visibility = xmlFile:getValue(stateKey .. "#visibility")
		dashboard.hasVisibility = dashboard.hasVisibility or state.visibility ~= nil
		state.emitColor = Dashboard.getDashboardColor(xmlFile, xmlFile:getValue(stateKey .. "#emitColor"), vehicle.customEnvironment)
		dashboard.hasEmitColor = dashboard.hasEmitColor or state.emitColor ~= nil
		state.intensity = xmlFile:getValue(stateKey .. "#intensity")
		dashboard.hasIntensity = dashboard.hasIntensity or state.intensity ~= nil
		table.insert(dashboard.states, state)
	end)
	if (dashboard.hasEmitColor or dashboard.hasIntensity) and not getHasClassId(dashboard.node, ClassIds.SHAPE) then
		Logging.xmlWarning(xmlFile, "Intensity or emitColor defined for non shape node in '%s'", key)
		return false
	end
	if #dashboard.states == 0 then
		Logging.xmlWarning(xmlFile, "No states defined for dashboard '%s'", key)
		return false
	else
		dashboard.multiStateInterpolationTime = 1 / dashboard.interpolationSpeed
		dashboard.interpolationSpeed = 99999
		dashboard.lastState = nil
		function dashboard.get()
			local x, y, z = getTranslation(dashboard.node)
			local rx, ry, rz = getRotation(dashboard.node)
			local sx, sy, sz = getScale(dashboard.node)
			local vis = getVisibility(dashboard.node) and 1 or 0
			local r = 1
			local g = 1
			local b = 1
			if dashboard.hasEmitColor and getHasShaderParameter(dashboard.node, "emitColor") then
				r, g, b = getShaderParameter(dashboard.node, "emitColor")
			end
			local intensity = 0
			if dashboard.hasIntensity and getHasShaderParameter(dashboard.node, "lightControl") then
				intensity = getShaderParameter(dashboard.node, "lightControl")
			end
			return x, y, z, rx, ry, rz, sx, sy, sz, vis, r, g, b, intensity
		end
		function dashboard.set(x, y, z, rx, ry, rz, sx, sy, sz, vis, r, g, b, intensity)
			setTranslation(dashboard.node, x, y, z)
			setRotation(dashboard.node, rx, ry, rz)
			setScale(dashboard.node, sx, sy, sz)
			if dashboard.hasVisibility then
				setVisibility(dashboard.node, 0.5 <= vis)
			end
			if dashboard.hasEmitColor and getHasShaderParameter(dashboard.node, "emitColor") then
				setShaderParameter(dashboard.node, "emitColor", r, g, b, 1, false)
			end
			if dashboard.hasIntensity and getHasShaderParameter(dashboard.node, "lightControl") then
				setShaderParameter(dashboard.node, "lightControl", intensity, nil, nil, nil, false)
			end
			if vehicle.setCharacterTargetNodeStateDirty ~= nil then
				vehicle:setCharacterTargetNodeStateDirty(dashboard.node)
			end
			if vehicle.setMovingToolDirty ~= nil then
				vehicle:setMovingToolDirty(dashboard.node)
			end
		end
		dashboard.defaultRotation = { getRotation(dashboard.node) }
		dashboard.defaultTranslation = { getTranslation(dashboard.node) }
		dashboard.defaultScale = { getScale(dashboard.node) }
		dashboard.defaultVisibility = getVisibility(dashboard.node)
		dashboard.defaultEmitColor = { 1, 1, 1 }
		dashboard.defaultIntensity = 0
		local doInterpolation = dashboard.doInterpolation
		dashboard.doInterpolation = false
		Dashboard.defaultDashboardStateFunc(vehicle, dashboard, dashboard.idleValue, nil, nil, false)
		dashboard.doInterpolation = doInterpolation
		return true
	end
end, function(vehicle, dashboard, newValue, minValue, maxValue, isActive)
	if dashboard.node ~= nil then
		local activeState = nil
		if isActive then
			for i = 1, #dashboard.states do
				local state = dashboard.states[i]
				if state.values ~= nil then
					if type(newValue) == "table" then
						for j = 1, #state.values do
							if newValue[state.values[j]] == true then
								activeState = state
							end
						end
					elseif type(newValue) == "number" then
						newValue = MathUtil.round(newValue)
						for j = 1, #state.values do
							if state.values[j] == newValue then
								activeState = state
							end
						end
					elseif type(newValue) == "string" then
						newValue = MathUtil.round(tonumber(newValue) or 0)
						for j = 1, #state.values do
							if state.values[j] == newValue then
								activeState = state
							end
						end
					end
				end
			end
		end
		if activeState == nil and 0 < dashboard.defaultStateIndex then
			activeState = dashboard.states[dashboard.defaultStateIndex]
		end
		if activeState ~= dashboard.lastState then
			local rotation = dashboard.defaultRotation
			local translation = dashboard.defaultTranslation
			local scale = dashboard.defaultScale
			local visibility = dashboard.defaultVisibility
			local emitColor = dashboard.defaultEmitColor
			local intensity = dashboard.defaultIntensity
			if activeState ~= nil then
				rotation = activeState.rotation or rotation
				translation = activeState.translation or translation
				scale = activeState.scale or scale
				if activeState.visibility ~= nil then
					visibility = activeState.visibility
				end
				if activeState.emitColor ~= nil then
					emitColor = activeState.emitColor
				end
				if activeState.intensity ~= nil then
					intensity = activeState.intensity
				end
			end
			if dashboard.doInterpolation then
				if dashboard.interpolator ~= nil then
					dashboard.interpolator:update(9999999)
				end
				local interpolator = ValueInterpolator.new(dashboard.node .. "_dashboard", dashboard.get, dashboard.set, { translation[1], translation[2], translation[3], rotation[1], rotation[2], rotation[3], scale[1], scale[2], scale[3], visibility and 1 or 0, emitColor[1], emitColor[2], emitColor[3], intensity }, dashboard.multiStateInterpolationTime)
				if interpolator ~= nil then
					dashboard.interpolator = interpolator
					dashboard.interpolator:setDeleteListenerObject(vehicle)
					dashboard.interpolator:setFinishedFunc(function(dash)
						dash.interpolator = nil
					end, dashboard)
				end
			else
				dashboard.set(translation[1], translation[2], translation[3], rotation[1], rotation[2], rotation[3], scale[1], scale[2], scale[3], visibility and 1 or 0, emitColor[1], emitColor[2], emitColor[3], intensity)
			end
			dashboard.lastState = activeState
		end
	end
end)
function Dashboard.registerDashboardXMLPaths(schema, basePath, availableValueTypes)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#valueType", "Value type name", nil, nil, availableValueTypes)
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#displayType", "Display type name", nil, nil, table.toList(Dashboard.TYPES))
	schema:register(XMLValueType.BOOL, basePath .. ".dashboard(?)#doInterpolation", "Do interpolation", false)
	schema:register(XMLValueType.BOOL, basePath .. ".dashboard(?)#isCritical", "Defines if dashboard update is critical and should be done every frame", "automatically based on type")
	schema:register(XMLValueType.BOOL, basePath .. ".dashboard(?)#useStateChange", "Dashboard is active for a defined amount of time when the source value changes", false)
	schema:register(XMLValueType.TIME, basePath .. ".dashboard(?)#stateChangeTime", "Defines how long the dashboard is active when the state changes (seconds)", 0.2)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#stateChangeValue", "Defines the dashboard value which triggers the state change. If not defined, any state change will trigger it")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#interpolationSpeed", "Interpolation speed", 0.005)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#idleValue", "Idle value", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#offsetValue", "Offset the value by the given amount", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#scaleFactor", "Scale the value by the given factor", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#minActiveValue", "Min. value to activate this dashboard")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#maxActiveValue", "Max. value to activate this dashboard")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?).valueMapping(?)#sourceValue", "Source value")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?).valueMapping(?)#dashboardValue", "Value to be used for dashboard at this source value")
	schema:register(XMLValueType.STRING, basePath .. ".dashboard(?)#groups", "List of groups")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".dashboard(?)#node", "Node")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#warningThresholdMin", "(WARNING) Threshold min.")
	schema:register(XMLValueType.FLOAT, basePath .. ".dashboard(?)#warningThresholdMax", "(WARNING) Threshold max.")
	for _, typeData in pairs(Dashboard.TYPE_DATA) do
		typeData.schemaFunc(schema, basePath)
	end
	schema:addDelayedRegistrationPath(basePath .. ".dashboard(?)", "Dashboard")
end
function Dashboard.addDelayedRegistrationFunc(schema, func)
	schema:addDelayedRegistrationFunc("Dashboard", func)
	if Dashboard.compoundsXMLSchema == nil then
		Dashboard.compoundsXMLSchema = XMLSchema.new("dashboardCompounds")
	end
	Dashboard.compoundsXMLSchema:addDelayedRegistrationFunc("Dashboard", func)
end
