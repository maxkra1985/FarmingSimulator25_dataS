-- Local values: CropSensorLinkageData_mt
CropSensorLinkageData = {}
CropSensorLinkageData.MOD_NAME = g_currentModName
CropSensorLinkageData.BASE_DIRECTORY = g_currentModDirectory
CropSensorLinkageData.xmlSchema = nil
local CropSensorLinkageData_mt = Class(CropSensorLinkageData)

-- Upvalues: CropSensorLinkageData_mt
-- Local values: self
function CropSensorLinkageData.new(precisionFarming, customMt)
	-- upvalues: (copy) CropSensorLinkageData_mt
	local v4_ = customMt or CropSensorLinkageData_mt
	local v5_ = setmetatable({}, v4_)
	v5_.precisionFarming = precisionFarming
	v5_.configurationPrice = 0
	v5_.sensorData = {}
	v5_.linkageData = {}
	v5_.dataLoaded = false
	CropSensorLinkageData.xmlSchema = XMLSchema.new("cropSensorLinkageData")
	v5_:registerXMLPaths(CropSensorLinkageData.xmlSchema)
	return v5_
end

-- Local values: i
function CropSensorLinkageData:delete()
	for v7_ = 1, #self.sensorData do
		delete(self.sensorData[v7_].node)
	end
	self.sensorData = {}
	self.linkageData = {}
end

function CropSensorLinkageData:loadFromXML(_, _, baseDirectory, configFileName, mapFilename)
	if not self.dataLoaded then
		self:loadLinkageData()
	end
end

-- Local values: filename, xmlFile, sensorsFilename
function CropSensorLinkageData:loadLinkageData(loadVehicleData, loadSensorData)
	local v12_ = Utils.getFilename("CropSensorLinkageData.xml", CropSensorLinkageData.BASE_DIRECTORY)
	local v_u_13_ = XMLFile.load("CropSensorLinkageData", v12_, CropSensorLinkageData.xmlSchema)
	if v_u_13_ ~= nil then
		self.configurationPrice = v_u_13_:getValue("cropSensorLinkageData.configuration#price", 0)
		if loadVehicleData ~= false then
			self.linkageData = {}
			v_u_13_:iterate("cropSensorLinkageData.vehicles.vehicle", function(_, p14_)
				-- upvalues: (copy) v_u_13_, (copy) self
				local v_u_15_ = {
					["filename"] = v_u_13_:getValue(p14_ .. "#filename")
				}
				if v_u_15_.filename ~= nil then
					v_u_15_.linkNodes = {}
					v_u_13_:iterate(p14_ .. ".linkNode", function(_, p16_)
						-- upvalues: (ref) v_u_13_, (copy) v_u_15_
						local v_u_17_ = {
							["nodeName"] = v_u_13_:getValue(p16_ .. "#node"),
							["typeName"] = string.upper(v_u_13_:getValue(p16_ .. "#type", "SENSOR_LEFT")),
							["translation"] = v_u_13_:getValue(p16_ .. "#translation", "0 0 0", true),
							["rotation"] = v_u_13_:getValue(p16_ .. "#rotation", "0 0 0", true),
							["rotationNodes"] = {}
						}
						v_u_13_:iterate(p16_ .. ".rotationNode", function(_, p18_)
							-- upvalues: (ref) v_u_13_, (copy) v_u_17_
							local v19_ = {
								["autoRotate"] = v_u_13_:getValue(p18_ .. "#autoRotate"),
								["rotation"] = v_u_13_:getValue(p18_ .. "#rotation", nil, true)
							}
							local v20_ = v_u_17_.rotationNodes
							table.insert(v20_, v19_)
						end)
						local v21_ = v_u_15_.linkNodes
						table.insert(v21_, v_u_17_)
					end)
				end
				local v22_ = self.linkageData
				table.insert(v22_, v_u_15_)
			end)
		end
		if loadSensorData == false then
			v_u_13_:delete()
		else
			local v23_ = v_u_13_:getValue("cropSensorLinkageData.sensors#filename")
			if v23_ == nil then
				v_u_13_:delete()
			else
				local v24_ = Utils.getFilename(v23_, CropSensorLinkageData.BASE_DIRECTORY)
				g_i3DManager:loadI3DFileAsync(v24_, true, true, CropSensorLinkageData.onSensorDataLoaded, self, { v_u_13_ })
			end
		end
	end
	self.dataLoaded = true
	return true
end

-- Local values: xmlFile, i
function CropSensorLinkageData:onSensorDataLoaded(i3dNode, failedReason, args)
	local v_u_28_ = unpack(args)
	if i3dNode ~= 0 then
		v_u_28_:iterate("cropSensorLinkageData.sensors.sensor", function(_, p29_)
			-- upvalues: (copy) v_u_28_, (copy) i3dNode, (copy) self
			local v_u_30_ = {
				["node"] = v_u_28_:getValue(p29_ .. "#node", nil, i3dNode)
			}
			if v_u_30_.node ~= nil then
				v_u_30_.type = v_u_28_:getValue(p29_ .. "#type", "SENSOR_LEFT")
				v_u_30_.measurementNodePath = v_u_28_:getValue(p29_ .. "#measurementNode")
				v_u_30_.requiresDaylight = v_u_28_:getValue(p29_ .. "#requiresDaylight", true)
				v_u_30_.rotationNodes = {}
				v_u_28_:iterate(p29_ .. ".rotationNode", function(_, p31_)
					-- upvalues: (ref) v_u_28_, (copy) v_u_30_
					local v32_ = {
						["nodePath"] = v_u_28_:getValue(p31_ .. "#node"),
						["autoRotate"] = v_u_28_:getValue(p31_ .. "#autoRotate")
					}
					local v33_ = v_u_30_.rotationNodes
					table.insert(v33_, v32_)
				end)
				local v34_ = self.sensorData
				table.insert(v34_, v_u_30_)
			end
		end)
		for v35_ = 1, #self.sensorData do
			unlink(self.sensorData[v35_].node)
		end
		delete(i3dNode)
	end
	v_u_28_:delete()
end

-- Local values: i, vehicleData
function CropSensorLinkageData:getCropSensorLinkageData(configFileName)
	if configFileName ~= nil then
		for v38_ = 1, #self.linkageData do
			local v39_ = self.linkageData[v38_]
			if string.endsWith(configFileName, v39_.filename) then
				return v39_
			end
		end
	end
	return nil
end

-- Local values: i, sensorData, clonedData, j, rotationNode
function CropSensorLinkageData:getClonedCropSensorNode(typeName)
	for v42_ = 1, #self.sensorData do
		local v43_ = self.sensorData[v42_]
		if string.upper(v43_.type) == string.upper(typeName) then
			local v44_ = table.clone(v43_, 10)
			v44_.node = clone(v43_.node, false, false, false)
			for v45_ = 1, #v44_.rotationNodes do
				local v46_ = v44_.rotationNodes[v45_]
				v46_.node = I3DUtil.indexToObject(v44_.node, v46_.nodePath)
			end
			if v44_.measurementNodePath ~= nil then
				v44_.measurementNode = I3DUtil.indexToObject(v44_.node, v44_.measurementNodePath)
			end
			return v44_
		end
	end
	return nil
end

function CropSensorLinkageData:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(VehicleSystem, "consoleCommandReloadVehicle", function(p49_, p50_, p51_, p52_)
		-- upvalues: (copy) self
		self:loadLinkageData(true, false)
		return p49_(p50_, p51_, p52_)
	end)
	pfModule:overwriteGameFunction(ConfigurationUtil, "getConfigurationsFromXML", function(p53_, p54_, p55_, p56_, p57_, p58_, p59_, p60_)
		-- upvalues: (copy) self
		local v61_, v62_ = p53_(p54_, p55_, p56_, p57_, p58_, p59_, p60_)
		if not self.dataLoaded then
			self:loadLinkageData(true)
		end
		if self:getCropSensorLinkageData(p55_.filename) ~= nil then
			v61_ = v61_ == nil and {} or v61_
			v62_ = v62_ == nil and {} or v62_
			local v63_ = {}
			local v64_ = VehicleConfigurationItem.new("cropSensor")
			v64_.isDefault = true
			v64_.name = g_i18n:getText("configuration_valueNo")
			v64_.index = 1
			v64_.saveId = "1"
			v64_.price = 0
			v64_.isYesNoOption = true
			table.insert(v63_, v64_)
			local v65_ = VehicleConfigurationItem.new("cropSensor")
			v65_.name = g_i18n:getText("configuration_valueYes")
			v65_.index = 2
			v65_.saveId = "2"
			v65_.price = self.configurationPrice
			v65_.isYesNoOption = true
			table.insert(v63_, v65_)
			v62_.cropSensor = ConfigurationUtil.getDefaultConfigIdFromItems(v63_)
			v61_.cropSensor = v63_
		end
		return v61_, v62_
	end)
end

function CropSensorLinkageData:registerXMLPaths(schema)
	schema:register(XMLValueType.STRING, "cropSensorLinkageData.sensors#filename", "Link to i3d filename containing the sensors")
	schema:register(XMLValueType.STRING, "cropSensorLinkageData.sensors.sensor(?)#type", "Type of sensor (SENSOR_LEFT | SENSOR_RIGHT | SENSOR_TOP)")
	schema:register(XMLValueType.NODE_INDEX, "cropSensorLinkageData.sensors.sensor(?)#node", "Path to sensor node")
	schema:register(XMLValueType.STRING, "cropSensorLinkageData.sensors.sensor(?)#measurementNode", "Reference node for measuring")
	schema:register(XMLValueType.BOOL, "cropSensorLinkageData.sensors.sensor(?)#requiresDaylight", "Sensor requires daylight", true)
	schema:register(XMLValueType.STRING, "cropSensorLinkageData.sensors.sensor(?).rotationNode(?)#node", "Path to rotation node")
	schema:register(XMLValueType.BOOL, "cropSensorLinkageData.sensors.sensor(?).rotationNode(?)#autoRotate", "Rotation will be automatically adjusted to the vehicle orientation", false)
	schema:register(XMLValueType.STRING, "cropSensorLinkageData.vehicles.vehicle(?)#filename", "Last part of vehicle filename")
	schema:register(XMLValueType.STRING, "cropSensorLinkageData.vehicles.vehicle(?).linkNode(?)#node", "Name of node in i3d mapping")
	schema:register(XMLValueType.STRING, "cropSensorLinkageData.vehicles.vehicle(?).linkNode(?)#type", "Type of node to link (SENSOR_LEFT | SENSOR_RIGHT | SENSOR_TOP)")
	schema:register(XMLValueType.VECTOR_TRANS, "cropSensorLinkageData.vehicles.vehicle(?).linkNode(?)#translation", "Translation offset from node", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, "cropSensorLinkageData.vehicles.vehicle(?).linkNode(?)#rotation", "Rotation offset from node", "0 0 0")
	schema:register(XMLValueType.BOOL, "cropSensorLinkageData.vehicles.vehicle(?).linkNode(?).rotationNode(?)#autoRotate", "Rotation will be automatically adjusted to the vehicle orientation")
	schema:register(XMLValueType.VECTOR_ROT, "cropSensorLinkageData.vehicles.vehicle(?).linkNode(?).rotationNode(?)#rotation", "Rotation of rotation node", "0 0 0")
	schema:register(XMLValueType.FLOAT, "cropSensorLinkageData.configuration#price", "Price of crop sensor config", 0)
end
