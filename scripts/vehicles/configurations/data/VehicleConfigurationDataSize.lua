VehicleConfigurationDataSize = {}

-- Local values: sizeKey
function VehicleConfigurationDataSize.registerXMLPaths(schema, rootPath, configPath)
	schema:setXMLSharedRegistration("VehicleConfigurationDataSize", configPath)
	local v3_ = configPath .. ".size"
	schema:register(XMLValueType.FLOAT, v3_ .. "#width", "occupied width of the vehicle when loaded in this configuration")
	schema:register(XMLValueType.FLOAT, v3_ .. "#length", "occupied length of the vehicle when loaded in this configuration")
	schema:register(XMLValueType.FLOAT, v3_ .. "#height", "occupied height of the vehicle when loaded in this configuration")
	schema:register(XMLValueType.FLOAT, v3_ .. "#minWidth", "Minimum width of the vehicle when loaded in this configuration")
	schema:register(XMLValueType.FLOAT, v3_ .. "#minLength", "Minimum length of the vehicle when loaded in this configuration")
	schema:register(XMLValueType.FLOAT, v3_ .. "#minHeight", "Minimum height of the vehicle when loaded in this configuration")
	schema:register(XMLValueType.FLOAT, v3_ .. "#widthOffset", "width offset")
	schema:register(XMLValueType.FLOAT, v3_ .. "#lengthOffset", "length offset")
	schema:register(XMLValueType.FLOAT, v3_ .. "#heightOffset", "height offset")
	schema:resetXMLSharedRegistration("VehicleConfigurationDataSize", configPath)
end

-- Local values: key, minWidth, minLength, minHeight
function VehicleConfigurationDataSize.onSizeLoad(configItem, xmlFile, sizeData)
	if configItem.configKey ~= "" then
		local v7_ = configItem.configKey .. ".size"
		sizeData.width = xmlFile:getValue(v7_ .. "#width", sizeData.width)
		sizeData.length = xmlFile:getValue(v7_ .. "#length", sizeData.length)
		sizeData.height = xmlFile:getValue(v7_ .. "#height", sizeData.height)
		sizeData.widthOffset = xmlFile:getValue(v7_ .. "#widthOffset", sizeData.widthOffset)
		sizeData.lengthOffset = xmlFile:getValue(v7_ .. "#lengthOffset", sizeData.lengthOffset)
		sizeData.heightOffset = xmlFile:getValue(v7_ .. "#heightOffset", sizeData.heightOffset)
		local v8_ = xmlFile:getValue(v7_ .. "#minWidth")
		if v8_ ~= nil then
			local v9_ = sizeData.minWidth or 0
			sizeData.minWidth = math.max(v8_, v9_)
		end
		local v10_ = xmlFile:getValue(v7_ .. "#minLength")
		if v10_ ~= nil then
			local v11_ = sizeData.minLength or 0
			sizeData.minLength = math.max(v10_, v11_)
		end
		local v12_ = xmlFile:getValue(v7_ .. "#minHeight")
		if v12_ ~= nil then
			local v13_ = sizeData.minHeight or 0
			sizeData.minHeight = math.max(v12_, v13_)
		end
	end
end
VehicleConfigurationItem.registerGlobalConfigurationData(VehicleConfigurationDataSize)
