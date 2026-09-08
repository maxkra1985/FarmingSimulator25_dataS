VehicleConfigurationDataOverwrites = {}

function VehicleConfigurationDataOverwrites.registerXMLPaths(schema, rootPath, configPath)
	schema:register(XMLValueType.STRING, configPath .. ".xmlOverwrites.remove(?)#path", "Path to remove from parent xml")
	schema:register(XMLValueType.STRING, configPath .. ".xmlOverwrites.set(?)#path", "Path change in parent xml")
	schema:register(XMLValueType.STRING, configPath .. ".xmlOverwrites.set(?)#value", "Target value to set in parent file")
	schema:register(XMLValueType.STRING, configPath .. ".xmlOverwrites.clearList(?)#path", "List to clear but keep one item")
	schema:register(XMLValueType.INT, configPath .. ".xmlOverwrites.clearList(?)#keepIndex", "Index of list to keep")
end

-- Local values: xmlFile, configKey
function VehicleConfigurationDataOverwrites.onPreLoad(vehicle, configItem, configId)
	local v_u_5_ = vehicle.xmlFile
	local v6_ = configItem.configKey
	if v6_ ~= "" then
		v_u_5_:iterate(v6_ .. ".xmlOverwrites.remove", function(_, p7_)
			-- upvalues: (copy) v_u_5_
			v_u_5_:removeProperty((v_u_5_:getString(p7_ .. "#path")))
		end)
		v_u_5_:iterate(v6_ .. ".xmlOverwrites.set", function(_, p8_)
			-- upvalues: (copy) v_u_5_
			v_u_5_:setString(v_u_5_:getString(p8_ .. "#path"), (v_u_5_:getString(p8_ .. "#value")))
		end)
		v_u_5_:iterate(v6_ .. ".xmlOverwrites.clearList", function(_, p9_)
			-- upvalues: (copy) v_u_5_
			local v10_ = v_u_5_:getString(p9_ .. "#path")
			local v11_ = v_u_5_:getInt(p9_ .. "#keepIndex")
			local v12_ = 0
			while v_u_5_:hasProperty(string.format(v10_ .. "(%d)", v12_)) do
				v12_ = v12_ + 1
			end
			for v13_ = v12_, 1, -1 do
				if v13_ ~= v11_ then
					v_u_5_:removeProperty(string.format(v10_ .. "(%d)", v13_ - 1))
				end
			end
		end)
	end
end
VehicleConfigurationItem.registerGlobalConfigurationData(VehicleConfigurationDataOverwrites)
