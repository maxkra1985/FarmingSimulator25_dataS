-- Local values: ManureSensorLinkageData_mt
ManureSensorLinkageData = {}
ManureSensorLinkageData.MOD_NAME = g_currentModName
ManureSensorLinkageData.BASE_DIRECTORY = g_currentModDirectory
ManureSensorLinkageData.xmlSchema = nil
local ManureSensorLinkageData_mt = Class(ManureSensorLinkageData)

-- Upvalues: ManureSensorLinkageData_mt
-- Local values: self
function ManureSensorLinkageData.new(precisionFarming, customMt)
	-- upvalues: (copy) ManureSensorLinkageData_mt
	local v4_ = customMt or ManureSensorLinkageData_mt
	local v5_ = setmetatable({}, v4_)
	v5_.precisionFarming = precisionFarming
	v5_.configurationPrice = 0
	v5_.sensorData = {}
	v5_.linkageData = {}
	v5_.dataLoaded = false
	ManureSensorLinkageData.xmlSchema = XMLSchema.new("manureSensorLinkageData")
	v5_:registerXMLPaths(ManureSensorLinkageData.xmlSchema)
	return v5_
end

-- Local values: i
function ManureSensorLinkageData:delete()
	for v7_ = 1, #self.sensorData do
		delete(self.sensorData[v7_].node)
	end
	self.sensorData = {}
	self.linkageData = {}
end

function ManureSensorLinkageData:loadFromXML(_, _, baseDirectory, configFileName, mapFilename)
	if not self.dataLoaded then
		self:loadLinkageData()
	end
end

-- Local values: filename, xmlFile, sensorsFilename
function ManureSensorLinkageData:loadLinkageData(loadVehicleData, loadSensorData)
	local v12_ = Utils.getFilename("ManureSensorLinkageData.xml", ManureSensorLinkageData.BASE_DIRECTORY)
	local v_u_13_ = XMLFile.load("ManureSensorLinkageData", v12_, ManureSensorLinkageData.xmlSchema)
	if v_u_13_ ~= nil then
		self.configurationPrice = v_u_13_:getValue("manureSensorLinkageData.configuration#price", 0)
		if loadVehicleData ~= false then
			self.linkageData = {}
			v_u_13_:iterate("manureSensorLinkageData.vehicles.vehicle", function(_, p14_)
				-- upvalues: (copy) v_u_13_, (copy) self
				local v_u_15_ = {
					["filename"] = v_u_13_:getValue(p14_ .. "#filename")
				}
				if v_u_15_.filename ~= nil then
					v_u_15_.linkNodes = {}
					v_u_13_:iterate(p14_ .. ".linkNode", function(_, p16_)
						-- upvalues: (ref) v_u_13_, (copy) v_u_15_
						local v17_ = {
							["nodeName"] = v_u_13_:getValue(p16_ .. "#node"),
							["typeName"] = string.upper(v_u_13_:getValue(p16_ .. "#type", "DEFAULT")),
							["translation"] = v_u_13_:getValue(p16_ .. "#translation", "0 0 0", true),
							["rotation"] = v_u_13_:getValue(p16_ .. "#rotation", "0 0 0", true),
							["scale"] = v_u_13_:getValue(p16_ .. "#scale", nil, true)
						}
						local v18_ = v_u_15_.linkNodes
						table.insert(v18_, v17_)
					end)
				end
				local v19_ = self.linkageData
				table.insert(v19_, v_u_15_)
			end)
		end
		if loadSensorData == false then
			v_u_13_:delete()
		else
			local v20_ = v_u_13_:getValue("manureSensorLinkageData.sensors#filename")
			if v20_ == nil then
				v_u_13_:delete()
			else
				local v21_ = Utils.getFilename(v20_, ManureSensorLinkageData.BASE_DIRECTORY)
				g_i3DManager:loadI3DFileAsync(v21_, true, true, ManureSensorLinkageData.onSensorDataLoaded, self, { v_u_13_ })
			end
		end
	end
	self.dataLoaded = true
	return true
end

-- Local values: xmlFile, i
function ManureSensorLinkageData:onSensorDataLoaded(i3dNode, failedReason, args)
	local v_u_25_ = unpack(args)
	if i3dNode ~= 0 then
		v_u_25_:iterate("manureSensorLinkageData.sensors.sensor", function(_, p26_)
			-- upvalues: (copy) v_u_25_, (copy) i3dNode, (copy) self
			local v27_ = {
				["node"] = v_u_25_:getValue(p26_ .. "#node", nil, i3dNode)
			}
			if v27_.node ~= nil then
				v27_.type = v_u_25_:getValue(p26_ .. "#type", "DEFAULT")
				local v28_ = self.sensorData
				table.insert(v28_, v27_)
			end
		end)
		for v29_ = 1, #self.sensorData do
			unlink(self.sensorData[v29_].node)
		end
		delete(i3dNode)
	end
	v_u_25_:delete()
end

-- Local values: i, vehicleData
function ManureSensorLinkageData:getManureSensorLinkageData(configFileName)
	if configFileName ~= nil then
		for v32_ = 1, #self.linkageData do
			local v33_ = self.linkageData[v32_]
			if string.endsWith(configFileName, v33_.filename) then
				return v33_
			end
		end
	end
	return nil
end

-- Local values: i, sensorData, clonedData
function ManureSensorLinkageData:getClonedManureSensorNode(typeName)
	for v36_ = 1, #self.sensorData do
		local v37_ = self.sensorData[v36_]
		if string.upper(v37_.type) == string.upper(typeName) then
			local v38_ = table.clone(v37_, 10)
			v38_.node = clone(v37_.node, false, false, false)
			setTranslation(v38_.node, 0, 0, 0)
			setRotation(v38_.node, 0, 0, 0)
			setScale(v38_.node, 1, 1, 1)
			return v38_
		end
	end
	return nil
end

function ManureSensorLinkageData:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(VehicleSystem, "consoleCommandReloadVehicle", function(p41_, p42_, p43_, p44_)
		-- upvalues: (copy) self
		self:loadLinkageData(true, false)
		return p41_(p42_, p43_, p44_)
	end)
	pfModule:overwriteGameFunction(ConfigurationUtil, "getConfigurationsFromXML", function(p45_, p46_, p47_, p48_, p49_, p50_, p51_, p52_)
		-- upvalues: (copy) self
		local v53_, v54_ = p45_(p46_, p47_, p48_, p49_, p50_, p51_, p52_)
		if not self.dataLoaded then
			self:loadLinkageData(true)
		end
		if self:getManureSensorLinkageData(p47_.filename) ~= nil then
			v53_ = v53_ == nil and {} or v53_
			v54_ = v54_ == nil and {} or v54_
			local v55_ = {}
			local v56_ = VehicleConfigurationItem.new("manureSensor")
			v56_.isDefault = true
			v56_.name = g_i18n:getText("configuration_valueNo")
			v56_.index = 1
			v56_.saveId = "1"
			v56_.price = 0
			v56_.isYesNoOption = true
			table.insert(v55_, v56_)
			local v57_ = VehicleConfigurationItem.new("manureSensor")
			v57_.name = g_i18n:getText("configuration_valueYes")
			v57_.index = 2
			v57_.saveId = "2"
			v57_.price = self.configurationPrice
			v57_.isYesNoOption = true
			table.insert(v55_, v57_)
			v54_.manureSensor = ConfigurationUtil.getDefaultConfigIdFromItems(v55_)
			v53_.manureSensor = v55_
		end
		return v53_, v54_
	end)
end

function ManureSensorLinkageData:registerXMLPaths(schema)
	schema:register(XMLValueType.STRING, "manureSensorLinkageData.sensors#filename", "Link to i3d filename containing the sensors")
	schema:register(XMLValueType.STRING, "manureSensorLinkageData.sensors.sensor(?)#type", "Type of sensor (DEFAULT)")
	schema:register(XMLValueType.NODE_INDEX, "manureSensorLinkageData.sensors.sensor(?)#node", "Path to sensor node")
	schema:register(XMLValueType.STRING, "manureSensorLinkageData.vehicles.vehicle(?)#filename", "Last part of vehicle filename")
	schema:register(XMLValueType.STRING, "manureSensorLinkageData.vehicles.vehicle(?).linkNode(?)#node", "Name of node in i3d mapping")
	schema:register(XMLValueType.STRING, "manureSensorLinkageData.vehicles.vehicle(?).linkNode(?)#type", "Type of node to link (DEFAULT)")
	schema:register(XMLValueType.VECTOR_TRANS, "manureSensorLinkageData.vehicles.vehicle(?).linkNode(?)#translation", "Translation offset from node", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, "manureSensorLinkageData.vehicles.vehicle(?).linkNode(?)#rotation", "Rotation offset from node", "0 0 0")
	schema:register(XMLValueType.VECTOR_SCALE, "manureSensorLinkageData.vehicles.vehicle(?).linkNode(?)#scale", "Scale of sensor node", "1 1 1")
	schema:register(XMLValueType.FLOAT, "manureSensorLinkageData.configuration#price", "Price of crop sensor config", 0)
end
