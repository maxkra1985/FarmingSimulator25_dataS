XMLUtil = {}

-- Local values: i18n, defaultVal, s, val
function XMLUtil.getXMLI18NValue(xmlFile, baseKey, func, name, defaultValue, customEnvironment, showWarning)
	local v8_ = g_i18n
	if customEnvironment ~= nil then
		v8_ = _G[customEnvironment].g_i18n
	end
	local v9_ = (name == nil or name == "") and "" or "." .. name
	local v10_ = func(xmlFile, baseKey .. ".en" .. v9_)
	if v10_ == nil then
		local v11_ = func(xmlFile, baseKey .. v9_ .. ".en")
		if v11_ == nil then
			local v12_ = func(xmlFile, baseKey .. ".de" .. v9_)
			if v12_ == nil then
				local v13_ = func(xmlFile, baseKey .. v9_ .. ".de")
				if v13_ == nil then
					local v14_ = func(xmlFile, baseKey .. v9_)
					if v14_ == nil then
						v14_ = v13_
					elseif type(v14_) == "string" and string.startsWith(v14_, "$l10n_") then
						v14_ = v8_:getText(v14_:sub(7))
					end
					if v14_ == nil then
						if v8_:hasText(defaultValue) then
							defaultValue = v8_:getText(defaultValue)
						end
					else
						defaultValue = v14_
					end
				else
					defaultValue = v13_
				end
			else
				defaultValue = v12_
			end
		else
			defaultValue = v11_
		end
	else
		defaultValue = v10_
	end
	if defaultValue == nil and (showWarning == nil or showWarning) then
		print("Error: loading xml I18N item, missing \'en\' or global value of attribute \'" .. baseKey .. v9_ .. "\'")
		return nil
	end
	local v15_ = getXMLString(xmlFile, baseKey .. "." .. g_languageShort .. v9_)
	if v15_ == nil then
		local v16_ = getXMLString(xmlFile, baseKey .. v9_ .. "." .. g_languageShort)
		if v16_ ~= nil then
			defaultValue = v16_
		end
	else
		defaultValue = v15_
	end
	return defaultValue
end

-- Local values: found, extraWarning
function XMLUtil.checkDeprecatedXMLElements(xmlFile, oldElement, newElement, oldValue, checkForValue)
	local v22_ = false
	local v23_ = ""
	if oldValue == nil then
		if xmlFile:getString(oldElement) ~= nil or xmlFile:hasProperty(oldElement) and not (oldElement:find("#") or checkForValue) then
			v22_ = true
		end
	elseif xmlFile:getString(oldElement) == oldValue then
		v23_ = string.format(" with value \'%s\'", oldValue)
		v22_ = true
	end
	if v22_ then
		if newElement ~= nil then
			Logging.xmlWarning(xmlFile, "\'%s\'%s is not supported anymore, use \'%s\' instead!", oldElement, v23_, newElement)
			return
		end
		Logging.xmlWarning(xmlFile, "\'%s\'%s is not supported anymore!", oldElement, v23_)
	end
end

function XMLUtil.checkDeprecatedUserAttribute(node, name, xmlFile, xmlKey)
	if getUserAttribute(node, name) ~= nil then
		Logging.warning("User attribute \'%s\' of node \'%s\' is not supported anymore.", name, getName(node))
		if xmlFile ~= nil then
			Logging.warning("Please replace with \'%s\' in file \'%s\'", xmlKey, xmlFile:getFilename())
		end
	end
end

-- Local values: value
function XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, name, node)
	local v32_
	if type(node) == "number" then
		v32_ = getUserAttribute(node, name)
	else
		v32_ = nil
	end
	if v32_ == nil and xmlFile ~= nil then
		v32_ = xmlFile:getValue(xmlNode .. "#" .. name)
	end
	return v32_
end

-- Local values: r
function XMLUtil.getXMLStringWithDefault(xmlFile, key, defkey, overridekey, attrname)
	local v38_ = getXMLString(xmlFile, key .. "#" .. attrname)
	if not v38_ and defkey then
		v38_ = getXMLString(xmlFile, defkey .. "#" .. attrname)
	end
	if overridekey then
		v38_ = getXMLString(xmlFile, overridekey .. "#" .. attrname) or v38_
	end
	return v38_
end

-- Local values: r
function XMLUtil.getXMLIntWithDefault(xmlFile, key, defkey, overridekey, attrname)
	local v44_ = getXMLInt(xmlFile, key .. "#" .. attrname)
	if not v44_ and defkey then
		v44_ = getXMLInt(xmlFile, defkey .. "#" .. attrname)
	end
	if overridekey then
		v44_ = getXMLInt(xmlFile, overridekey .. "#" .. attrname) or v44_
	end
	return v44_
end

-- Local values: r
function XMLUtil.getXMLFloatWithDefault(xmlFile, key, defkey, overridekey, attrname)
	local v50_ = getXMLFloat(xmlFile, key .. "#" .. attrname)
	if not v50_ and defkey then
		v50_ = getXMLFloat(xmlFile, defkey .. "#" .. attrname)
	end
	if overridekey then
		v50_ = getXMLFloat(xmlFile, overridekey .. "#" .. attrname) or v50_
	end
	return v50_
end
function XMLUtil.getXMLOverwrittenValue(p51_, p52_, p53_, p54_, p55_, ...)
	local v56_
	if p52_ == nil then
		v56_ = nil
	else
		if getXMLString(p51_.handle, p52_ .. p53_) == "-" then
			return nil
		end
		v56_ = p51_:getValue(p52_ .. p53_ .. p54_, p55_, ...)
	end
	return v56_
end
function XMLUtil.loadDataFromMapXML(p57_, p58_, p59_, p60_, p61_, ...)
	local v62_ = getXMLString(p57_, string.format("map.%s#filename", p58_))
	local v63_
	if v62_ == nil then
		v63_ = p57_
	else
		local v64_ = Utils.getFilename(v62_, p59_)
		v63_ = loadXMLFile("mapDataXML", v64_)
		if v63_ == 0 then
			return false
		end
	end
	local v65_ = p61_(p60_, v63_, ...)
	if v63_ ~= p57_ then
		delete(v63_)
	end
	return v65_
end
