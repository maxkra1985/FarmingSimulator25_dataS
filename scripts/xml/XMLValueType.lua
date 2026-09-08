XMLValueType = {}
XMLValueType.BASE_TYPES = {}
XMLValueType.TYPES = {}

-- Local values: value, parts
function XMLValueType.getXMLStringList(xmlFile, path, default, numItems)
	local v4_ = getXMLString(xmlFile, path)
	if v4_ == nil then
		return nil
	end
	local v5_ = string.split(string.trim(v4_), " ")
	if numItems == nil or #v5_ == numItems then
		return v5_
	end
	Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid string list in \'%s\'. Requires %d elements, %d found.", path, numItems, #v5_)
	return nil
end

-- Local values: lastDot, firstPart, secondPart
function XMLValueType.getXMLLocalization(xmlFile, path, default, customEnvironment, showWarning)
	local v11_ = path:findLast("%.")
	local v12_ = path:sub(0, v11_ - 1)
	local v13_ = path:sub(v11_ + 1, (string.len(path)))
	return XMLUtil.getXMLI18NValue(xmlFile, v12_, getXMLString, v13_, default, customEnvironment, showWarning)
end

-- Local values: value
function XMLValueType.getXMLFilename(xmlFile, path, default, baseDirectory)
	local v18_ = getXMLString(xmlFile, path) or default
	if v18_ == nil then
		return nil
	else
		return Utils.getFilename(v18_, baseDirectory)
	end
end

-- Local values: value
function XMLValueType.getXMLAngle(xmlFile, path, default)
	local v22_ = getXMLFloat(xmlFile, path)
	if v22_ ~= nil then
		return math.rad(v22_)
	end
	if default ~= nil then
		return math.rad(default)
	end
end

-- Local values: value
function XMLValueType.getXMLTime(xmlFile, path, default)
	local v26_ = getXMLFloat(xmlFile, path)
	if v26_ ~= nil then
		return v26_ * 1000
	end
	if default ~= nil then
		return default * 1000
	end
end

-- Local values: valueStr, hours, minutes, seconds, millis, value
function XMLValueType.getXMLDayTime(xmlFile, path, default)
	local v30_ = getXMLString(xmlFile, path) or default
	if v30_ == nil then
		return nil
	else
		local v31_ = string.sub(v30_, 1, 2)
		local v32_ = tonumber(v31_)
		local v33_ = string.sub(v30_, 4, 5)
		local v34_ = tonumber(v33_)
		local v35_ = string.sub(v30_, 7, 8)
		local v36_ = tonumber(v35_)
		local v37_ = string.sub(v30_, 10, 12)
		local v38_ = tonumber(v37_)
		if v32_ == nil or v34_ == nil then
			return nil
		elseif v32_ < 0 or (v32_ > 23 or (v34_ < 0 or v34_ > 59)) then
			return nil
		else
			local v39_ = v36_ or 0
			local v40_ = v38_ or 0
			if v39_ < 0 or (v39_ > 59 or (v40_ < 0 or v40_ > 999)) then
				return nil
			else
				return v40_ + v39_ * 1000 + v34_ * 60 * 1000 + v32_ * 60 * 60 * 1000
			end
		end
	end
end

-- Local values: defaultStr, node, root
function XMLValueType.getXMLNode(xmlFile, path, default, components, i3dMappings)
	if components == nil then
		Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "No components given for \'%s\'.", path)
		printCallstack()
		return default
	else
		local v46_
		if type(default) == "string" then
			v46_ = nil
		else
			v46_ = default
			default = nil
		end
		local v47_, v48_ = I3DUtil.indexToObject(components, getXMLString(xmlFile, path) or default, i3dMappings)
		return v47_ or v46_, v48_
	end
end

-- Local values: defaultType, defaultStr, nodes, nodesStr, nodeParts, i, node
function XMLValueType.getXMLNodes(xmlFile, path, default, components, i3dMappings, packed)
	local v55_ = type(default)
	local v56_ = nil
	local v57_
	if v55_ == "number" or v55_ == "nil" then
		default = v56_
		v57_ = { default }
	elseif v55_ == "string" then
		v57_ = {}
	else
		v57_ = default
		default = v56_
	end
	if components == nil then
		Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "No components given for \'%s\'.", path)
		printCallstack()
		if packed then
			return v57_
		else
			return unpack(v57_)
		end
	else
		local v58_ = {}
		local v59_ = getXMLString(xmlFile, path) or default
		if v59_ ~= nil then
			local v60_ = v59_:split(" ")
			for v61_ = 1, #v60_ do
				local v62_ = I3DUtil.indexToObject(components, v60_[v61_], i3dMappings)
				if v62_ == nil then
					Logging.xmlWarning(xmlFile, "Unknown node \'%s\' in \'%s\'!", v60_[v61_], path)
				else
					table.insert(v58_, v62_)
				end
			end
		end
		if #v58_ == 0 then
			if packed then
				return v57_
			else
				return unpack(v57_)
			end
		elseif packed then
			return v58_
		else
			return unpack(v58_)
		end
	end
end

-- Local values: valueStr, result
function XMLValueType.getVectorFromXML(xmlFile, path, default)
	local v66_ = getXMLString(xmlFile, path)
	if v66_ ~= nil then
		local v67_ = string.getVector(v66_)
		if v67_ ~= nil then
			return v67_
		end
	end
	if default == nil then
		return nil
	end
	if type(default) == "string" then
		return string.getVector(default)
	end
	if type(default) == "table" then
		return default
	end
	Logging.warning("Default value is neither a table nor a string")
	printCallstack()
	return nil
end

-- Local values: vector
function XMLValueType.getXMLVector2(xmlFile, path, default, packed)
	local v72_ = XMLValueType.getVectorFromXML(xmlFile, path, default)
	if v72_ == nil then
		return nil
	elseif #v72_ == 2 then
		if packed then
			return v72_
		else
			return unpack(v72_)
		end
	else
		Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid vector 2 for \'%s\'.", path)
		return nil
	end
end

-- Local values: vector
function XMLValueType.getXMLVector3(xmlFile, path, default, packed)
	local v77_ = XMLValueType.getVectorFromXML(xmlFile, path, default)
	if v77_ == nil then
		return nil
	elseif #v77_ == 3 then
		if packed then
			return v77_
		else
			return unpack(v77_)
		end
	else
		Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid vector 3 for \'%s\'.", path)
		return nil
	end
end

-- Local values: vector
function XMLValueType.getXMLVector4(xmlFile, path, default, packed)
	local v82_ = XMLValueType.getVectorFromXML(xmlFile, path, default)
	if v82_ == nil then
		return nil
	elseif #v82_ == 4 then
		if packed then
			return v82_
		else
			return unpack(v82_)
		end
	else
		Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid vector 4 for \'%s\'.", path)
		return nil
	end
end

function XMLValueType.getXMLVectorN(xmlFile, path, default, packed)
	if packed then
		return XMLValueType.getVectorFromXML(xmlFile, path, default)
	end
	local v87_ = XMLValueType.getVectorFromXML
	return unpack(v87_(xmlFile, path, default))
end

-- Local values: i, vector
function XMLValueType.getXMLVector3Angle(xmlFile, path, default, packed)
	if type(default) == "table" then
		for v92_ = 1, #default do
			local v93_ = default[v92_]
			default[v92_] = math.deg(v93_)
		end
	end
	local v94_ = XMLValueType.getVectorFromXML(xmlFile, path, default)
	if v94_ ~= nil then
		if #v94_ == 3 then
			if not packed then
				local v95_ = v94_[1]
				local v96_ = math.rad(v95_)
				local v97_ = v94_[2]
				local v98_ = math.rad(v97_)
				local v99_ = v94_[3]
				return v96_, v98_, math.rad(v99_)
			end
			local v100_ = v94_[1]
			local v101_ = math.rad(v100_)
			local v102_ = v94_[2]
			local v103_ = math.rad(v102_)
			local v104_ = v94_[3]
			local v105_ = math.rad(v104_)
			v94_[1] = v101_
			v94_[2] = v103_
			v94_[3] = v105_
			return v94_
		end
		Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid vector 3 for \'%s\'.", path)
	end
	return nil
end

-- Local values: i, vector
function XMLValueType.getXMLVector2Angle(xmlFile, path, default, packed)
	if type(default) == "table" then
		for v110_ = 1, #default do
			local v111_ = default[v110_]
			default[v110_] = math.deg(v111_)
		end
	end
	local v112_ = XMLValueType.getVectorFromXML(xmlFile, path, default)
	if v112_ ~= nil then
		if #v112_ == 2 then
			if not packed then
				local v113_ = v112_[1]
				local v114_ = math.rad(v113_)
				local v115_ = v112_[2]
				return v114_, math.rad(v115_)
			end
			local v116_ = v112_[1]
			local v117_ = math.rad(v116_)
			local v118_ = v112_[2]
			local v119_ = math.rad(v118_)
			v112_[1] = v117_
			v112_[2] = v119_
			return v112_
		end
		Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid vector 2 for \'%s\'.", path)
	end
	return nil
end

-- Local values: colorStr, color
function XMLValueType.getXMLColor(xmlFile, path, default, packed, customEnvironment)
	local v125_ = getXMLString(xmlFile, path)
	if v125_ == nil then
		if type(default) ~= "string" then
			return default
		end
		v125_ = default
	end
	local v126_ = g_vehicleMaterialManager:getMaterialTemplateColorByName(v125_, customEnvironment)
	if v126_ == nil then
		local v127_ = string.split(v125_, " ", tonumber)
		if #v127_ == 3 then
			default = v127_
		else
			if v125_ ~= nil then
				Logging.xmlWarning(xmlFile, "Invalid color value \'%s\' in \'%s\'.", v125_, path)
			end
			if type(default) == "string" then
				default = string.getVector(default)
				if #default ~= 3 then
					return nil
				end
			elseif default == nil then
				return nil
			end
		end
	else
		default = v126_
	end
	if packed then
		return default
	else
		return unpack(default)
	end
end

-- Local values: colorStr, material, materialTemplate, color
function XMLValueType.getXMLVehicleMaterial(xmlFile, path, default, customEnvironment)
	local v132_ = getXMLString(xmlFile, path)
	if v132_ == nil then
		return default
	else
		local v133_ = VehicleMaterial.new()
		if g_vehicleMaterialManager:getMaterialTemplateByName(v132_, customEnvironment) == nil then
			local v134_ = string.split(v132_, " ", tonumber)
			if #v134_ >= 3 then
				v133_.colorScale = { v134_[1], v134_[2], v134_[3] }
				return v133_
			else
				Logging.xmlWarning(xmlFile, "Invalid vehicle material template \'%s\' in \'%s\'.", v132_, path)
				return default
			end
		else
			v133_:setTemplateName(v132_, nil, customEnvironment)
			return v133_
		end
	end
end
function XMLValueType.setXMLStringList(p135_, p136_, ...)
	local v137_ = ""
	for v138_ = 1, select("#", ...) do
		if v138_ > 1 then
			v137_ = v137_ .. " "
		end
		v137_ = v137_ .. select(v138_, ...)
	end
	setXMLString(p135_, p136_, v137_)
end

function XMLValueType.setXMLAngle(xmlFile, path, value)
	setXMLFloat(xmlFile, path, (math.deg(value or 0)))
end

function XMLValueType.setXMLTime(xmlFile, path, value)
	setXMLFloat(xmlFile, path, (value or 0) / 1000)
end

-- Local values: millis, seconds, minutes, hours, str
function XMLValueType.setXMLDayTime(xmlFile, path, value)
	local v148_ = value % 1000
	local v149_ = value / 1000 % 60
	local v150_ = value / 60000 % 60
	local v151_ = value / 3600000 % 24
	local v152_ = string.format("%02d:%02d:%02d.%03d", v151_, v150_, v149_, v148_)
	setXMLString(xmlFile, path, v152_)
end

function XMLValueType.setXMLNode(xmlFile, path, value)
	if entityExists(value) then
		setXMLString(xmlFile, path, getName(value))
	end
end
function XMLValueType.setXMLNodes(p156_, p157_, ...)
	local v158_ = ""
	for v159_, v160_ in ipairs({ ... }) do
		if v159_ > 1 then
			v158_ = v158_ + " "
		end
		if entityExists(v160_) then
			v158_ = v158_ + getName(v160_)
		end
	end
	setXMLString(p156_, p157_, v158_)
end

function XMLValueType.setXMLVector2(xmlFile, path, val1, val2)
	setXMLString(xmlFile, path, string.format("%s %s", val1, val2))
end

function XMLValueType.setXMLVector3(xmlFile, path, val1, val2, val3)
	setXMLString(xmlFile, path, string.format("%s %s %s", val1, val2, val3))
end

function XMLValueType.setXMLVector4(xmlFile, path, val1, val2, val3, val4)
	setXMLString(xmlFile, path, string.format("%s %s %s %s", val1, val2, val3, val4))
end
function XMLValueType.setXMLVectorN(p176_, p177_, ...)
	setXMLString(p176_, p177_, table.concat({ ... }, " "))
end

function XMLValueType.setXMLVectorTrans(xmlFile, path, x, y, z)
	setXMLString(xmlFile, path, string.format("%.3f %.3f %.3f", x, y, z))
end

function XMLValueType.setXMLVector3Angle(xmlFile, path, rx, ry, rz)
	setXMLString(xmlFile, path, string.format("%.2f %.2f %.2f", math.deg(rx), math.deg(ry), (math.deg(rz))))
end

function XMLValueType.setXMLVector2Angle(xmlFile, path, r1, r2)
	setXMLString(xmlFile, path, string.format("%.2f %.2f", math.deg(r1), (math.deg(r2))))
end
function XMLValueType.setXMLColor(p192_, p193_, ...)
	setXMLString(p192_, p193_, table.concat({ ... }, " "))
end

function XMLValueType.setXMLVehicleMaterial(xmlFile, path, r, g, b)
	if type(r) == "string" then
		setXMLString(xmlFile, path, r)
	else
		setXMLString(xmlFile, path, string.format("%s %s %s", r, g, b))
	end
end
function XMLValueType.registerBaseType(p199_, p200_)
	XMLValueType.BASE_TYPES[#XMLValueType.BASE_TYPES + 1] = {
		["name"] = p199_,
		["content"] = p200_
	}
end
XMLValueType.registerBaseType("VECTOR_FLOAT", "<xs:list itemType=\"xs:float\"/>")
function XMLValueType.register(p201_, p202_, p203_, p204_, p205_, p206_, p207_, p208_, p209_, p210_)
	XMLValueType.TYPES[#XMLValueType.TYPES + 1] = {
		["name"] = p201_,
		["description"] = p202_,
		["get"] = p203_,
		["set"] = p204_,
		["isBasicFunction"] = p205_,
		["luaType"] = p206_,
		["defaultStr"] = p207_,
		["xsdBase"] = p208_,
		["xsdPattern"] = p209_,
		["luaPattern"] = p210_
	}
	XMLValueType[string.upper(p201_)] = #XMLValueType.TYPES
	return #XMLValueType.TYPES
end
XMLValueType.STRING = XMLValueType.register("STRING", "String", getXMLString, setXMLString, true, "string", "string", "xs:string")
XMLValueType.STRING_LIST = XMLValueType.register("STRING_LIST", "One or more strings separated by a single whitespace", XMLValueType.getXMLStringList, XMLValueType.setXMLStringList, true, "string", "str1 str2 ..", "xs:string", "\\S+( \\S+)*")
XMLValueType.L10N_STRING = XMLValueType.register("L10N_STRING", "String or l10n key", XMLValueType.getXMLLocalization, setXMLString, false, "string", "string", "xs:string")
XMLValueType.FILENAME = XMLValueType.register("FILENAME", "Path to a certain file", XMLValueType.getXMLFilename, setXMLString, false, "string", "string", "xs:string")
XMLValueType.FLOAT = XMLValueType.register("FLOAT", "Float", getXMLFloat, setXMLFloat, true, "number", "float", "xs:float")
XMLValueType.ANGLE = XMLValueType.register("ANGLE", "Angle", XMLValueType.getXMLAngle, XMLValueType.setXMLAngle, false, "number", "angle", "xs:float")
XMLValueType.TIME = XMLValueType.register("TIME", "Time in seconds", XMLValueType.getXMLTime, XMLValueType.setXMLTime, false, "number", "time", "xs:float")
XMLValueType.DAY_TIME = XMLValueType.register("DAY_TIME", "Time hh:mm:ss.sss format", XMLValueType.getXMLDayTime, XMLValueType.setXMLDayTime, false, "string", "hh:mm:ss", "xs:time")
XMLValueType.INT = XMLValueType.register("INT", "Integer", getXMLInt, setXMLInt, true, "number", "integer", "xs:integer")
XMLValueType.UINT = XMLValueType.register("UINT", "Integer (unsigned)", getXMLUInt, setXMLUInt, true, "number", "integer", "xs:integer")
XMLValueType.BOOL = XMLValueType.register("BOOL", "Boolean", getXMLBool, setXMLBool, true, "boolean", "boolean", "xs:string", "true|false", { true, false })
XMLValueType.NODE_INDEX = XMLValueType.register("NODE_INDEX", "Index to i3d node or i3d mapping identifier", XMLValueType.getXMLNode, XMLValueType.setXMLNode, false, "string", "node", "xs:string", nil, {})
XMLValueType.NODE_INDICES = XMLValueType.register("NODE_INDICES", "List of indices to i3d nodes or i3d mapping identifiers", XMLValueType.getXMLNodes, XMLValueType.setXMLNodes, false, "string", "node", "xs:string", nil, {})
XMLValueType.VECTOR_2 = XMLValueType.register("VECTOR_2", "Multiple values (x, y)", XMLValueType.getXMLVector2, XMLValueType.setXMLVector2, false, "string", "x y", "g_vector_float", "\\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.VECTOR_3 = XMLValueType.register("VECTOR_3", "Multiple values (x, y, z)", XMLValueType.getXMLVector3, XMLValueType.setXMLVector3, false, "string", "x y z", "g_vector_float", "\\S+ \\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.VECTOR_4 = XMLValueType.register("VECTOR_4", "Multiple values (x, y, z, w)", XMLValueType.getXMLVector4, XMLValueType.setXMLVector4, false, "string", "x y z w", "g_vector_float", "\\S+ \\S+ \\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+%s%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.VECTOR_N = XMLValueType.register("VECTOR_N", "Multiple values", XMLValueType.getXMLVectorN, XMLValueType.setXMLVectorN, false, "string", "1 2 .. n", "g_vector_float")
XMLValueType.VECTOR_TRANS = XMLValueType.register("VECTOR_TRANS", "Translation values (x, y, z)", XMLValueType.getXMLVector3, XMLValueType.setXMLVectorTrans, false, "string", "x y z", "g_vector_float", "\\S+ \\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.VECTOR_ROT = XMLValueType.register("VECTOR_ROT", "Rotation values (x, y, z)", XMLValueType.getXMLVector3Angle, XMLValueType.setXMLVector3Angle, false, "string", "x y z", "g_vector_float", "\\S+ \\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.VECTOR_ROT_2 = XMLValueType.register("VECTOR_ROT_2", "Rotation values (x, y)", XMLValueType.getXMLVector2Angle, XMLValueType.setXMLVector2Angle, false, "string", "x y", "g_vector_float", "\\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.VECTOR_SCALE = XMLValueType.register("VECTOR_SCALE", "Scale values (x, y, z)", XMLValueType.getXMLVector3, XMLValueType.setXMLVector3, false, "string", "x y z", "g_vector_float", "\\S+ \\S+ \\S+", "(%d*%.?%d+%s%d*%.?%d+%s%d*%.?%d+)")
XMLValueType.COLOR = XMLValueType.register("COLOR", "Color values (r, g, b) or brand color id", XMLValueType.getXMLColor, XMLValueType.setXMLColor, false, "string", "r g b", "xs:string")
XMLValueType.VEHICLE_MATERIAL = XMLValueType.register("VEHICLE_MATERIAL", "Name of brand material template or color values (r,g,b)", XMLValueType.getXMLVehicleMaterial, XMLValueType.setXMLVehicleMaterial, false, "string", "string", "xs:string")
