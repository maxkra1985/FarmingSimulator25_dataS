VehicleConfigurationDataSprayerNodes = {}

function VehicleConfigurationDataSprayerNodes.registerXMLPaths(schema, rootPath, configPath)
	schema:register(XMLValueType.NODE_INDEX, configPath .. ".sprayerNozzles.nozzle(?)#node", "Nozzle Node")
	schema:register(XMLValueType.VECTOR_TRANS, configPath .. ".sprayerNozzles.nozzle(?)#translation", "Translation offset from the defined node")
	schema:register(XMLValueType.VECTOR_ROT, configPath .. ".sprayerNozzles.nozzle(?)#rotation", "Rotation offset from the defined node")
	schema:register(XMLValueType.STRING, configPath .. ".weedSpotSpraySensors.sensorNode(?)#id", "Sensor identifier of the type to use")
	schema:register(XMLValueType.STRING, configPath .. ".weedSpotSpraySensors.sensorNode(?)#node", "Name of node in i3d mapping")
	schema:register(XMLValueType.VECTOR_TRANS, configPath .. ".weedSpotSpraySensors.sensorNode(?)#translation", "Translation offset from node", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, configPath .. ".weedSpotSpraySensors.sensorNode(?)#rotation", "Rotation offset from node", "0 0 0")
	schema:register(XMLValueType.FLOAT, configPath .. ".weedSpotSpraySensors.sensorNode(?)#bracketSize", "Size of the bracket", 1)
end

-- Local values: spec, _, key, linkNode, effectNode, effectNodeData, effectData, linkData, _, sensorNodeKey, sensorNode
function VehicleConfigurationDataSprayerNodes.onPrePostLoad(vehicle, configItem, configId)
	if configItem.configKey ~= "" then
		local v5_ = vehicle[ExtendedSprayerEffects.SPEC_TABLE_NAME]
		if v5_ ~= nil then
			for _, v6_ in vehicle.xmlFile:iterator(configItem.configKey .. ".sprayerNozzles.nozzle") do
				local v7_ = vehicle.xmlFile:getValue(v6_ .. "#node", nil, vehicle.components, vehicle.i3dMappings)
				if v7_ ~= nil then
					local v8_ = g_precisionFarming:getClonedSprayerEffectNode()
					if v8_ ~= nil then
						local v9_ = {}
						if vehicle:addExtendedSprayerNozzleEffect(v9_, v8_, v7_, {
							["translation"] = vehicle.xmlFile:getValue(v6_ .. "#translation", { 0, 0, 0 }, true),
							["rotation"] = vehicle.xmlFile:getValue(v6_ .. "#rotation", { 0, 0, 0 }, true)
						}) then
							local v10_ = v5_.sprayerEffects
							table.insert(v10_, v9_)
						end
					end
				end
			end
		end
		if vehicle[WeedSpotSpray.SPEC_TABLE_NAME] ~= nil and vehicle[WeedSpotSpray.SPEC_TABLE_NAME].isEnabled then
			local v11_ = {
				["sensorNodes"] = {}
			}
			for _, v12_ in vehicle.xmlFile:iterator(configItem.configKey .. ".weedSpotSpraySensors.sensorNode") do
				local v13_ = {
					["id"] = vehicle.xmlFile:getValue(v12_ .. "#id"),
					["nodeName"] = vehicle.xmlFile:getValue(v12_ .. "#node"),
					["translation"] = vehicle.xmlFile:getValue(v12_ .. "#translation", "0 0 0", true),
					["rotation"] = vehicle.xmlFile:getValue(v12_ .. "#rotation", "0 0 0", true),
					["bracketSize"] = vehicle.xmlFile:getValue(v12_ .. "#bracketSize", 1)
				}
				local v14_ = v11_.sensorNodes
				table.insert(v14_, v13_)
			end
			if #v11_.sensorNodes > 0 then
				vehicle:addWeedSpotSpraySensorNodes(v11_)
			end
		end
	end
end
VehicleConfigurationItem.registerGlobalConfigurationData(VehicleConfigurationDataSprayerNodes)
