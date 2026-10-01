XMLSchema = {}
source("dataS/scripts/xml/XMLValueType.lua")
XMLSchema.XML_SPECIALIZATION_NONE = "none"
XMLSchema.XML_SHARED_NONE = "none"
local XMLSchema_mt = Class(XMLSchema)
function XMLSchema.new(name)
	local self = setmetatable({}, XMLSchema_mt)
	self.name = name
	self.numPaths = 0
	self.paths = {}
	self.delayedRegistrationPaths = {}
	self.delayedRegistrationFuncs = {}
	self.delayedRegistrationSharedSchemas = {}
	self.xmlSpecializationType = XMLSchema.XML_SPECIALIZATION_NONE
	self.sharedRegistrationName = XMLSchema.XML_SHARED_NONE
	self.sharedRegistrationBase = ""
	self.subSchemas = {}
	self.hasSubSchemas = false
	self.subSchemaIdentifier = nil
	self.rootNodeName = nil
	self.supportsParentFile = true
	if g_xmlManager ~= nil then
		g_xmlManager:addSchema(self)
	end
	return self
end
function XMLSchema:register(valueTypeId, path, description, defaultValue, isRequired, allowedValues)
	if path == nil then
		Logging.error("Unable to register xml schema path, given path is nil")
		printCallstack()
	else
		if string.find(path, "%.%.") or string.find(path, "%s") then
			Logging.error("Unable to register xml path %q. Invalid format", path)
			printCallstack()
			return
		end
		if self.rootNodeName ~= nil then
			local start = string.find(path, "%.")
			path = self.rootNodeName .. path:sub(start)
		end
		if self.paths[path] == nil then
			local pathData = { ["valueTypeId"] = valueTypeId }
			if valueTypeId == nil then
				Logging.error("Unable to register xml path '%s'. Unknown value type", path)
				printCallstack()
				return
			end
			self.paths[path] = pathData
			self.numPaths = self.numPaths + 1
		end
		if self.supportsParentFile and self.numPaths == 1 then
			local rootName = path:split(".")[1]:split("#")[1]
			self:registerInheritancePaths(rootName)
		end
		self:updateSubSchemas(self.register, valueTypeId, path, description, defaultValue, isRequired, allowedValues)
	end
end
function XMLSchema:registerAutoCompletionDataSource(path, externalXMLPath, key, prefix)
	if self.rootNodeName ~= nil then
		local start = path:find("%.")
		path = self.rootNodeName .. path:sub(start)
	end
	if self.paths[path] == nil then
		return
	end
	local rawFilepath = string.gsub(externalXMLPath, "%$", "")
	if not fileExists(rawFilepath) then
		return
	else
		if not string.startsWith(externalXMLPath, "$") then
			externalXMLPath = "$" .. externalXMLPath
		end
		local pathData = self.paths[path]
		pathData.externalAutocompletionXML = externalXMLPath
		pathData.externalAutocompletionXMLKey = key
		pathData.externalAutocompletionXMLPrefix = prefix or ""
		self:updateSubSchemas(self.registerAutoCompletionDataSource, path, externalXMLPath, key, prefix)
	end
end
function XMLSchema:setRootNodeName(rootNodeName)
	self.rootNodeName = rootNodeName
end
function XMLSchema:replaceRootName(path)
	if self.rootNodeName ~= nil then
		local start = path:find("%.")
		return self.rootNodeName .. path:sub(start)
	else
		return path
	end
end
function XMLSchema:setXMLSpecializationType(specializationType)
	self.xmlSpecializationType = specializationType or XMLSchema.XML_SPECIALIZATION_NONE
	self:updateSubSchemas(self.setXMLSpecializationType, specializationType)
end
function XMLSchema:setXMLSharedRegistration(sharedRegistrationName, sharedRegistrationBase, force)
	if self.sharedRegistrationName == XMLSchema.XML_SHARED_NONE or force then
		if sharedRegistrationBase ~= nil and self.rootNodeName ~= nil then
			local start = sharedRegistrationBase:find("%.")
			sharedRegistrationBase = self.rootNodeName .. sharedRegistrationBase:sub(start)
		end
		self.sharedRegistrationName = sharedRegistrationName or XMLSchema.XML_SHARED_NONE
		self.sharedRegistrationBase = sharedRegistrationBase or ""
		self:updateSubSchemas(self.setXMLSharedRegistration, sharedRegistrationName, sharedRegistrationBase, force)
		return true
	end
	return false
end
function XMLSchema:resetXMLSharedRegistration(sharedRegistrationName, sharedRegistrationBase, force)
	if self.sharedRegistrationName == sharedRegistrationName or force then
		self.sharedRegistrationName = XMLSchema.XML_SHARED_NONE
		self.sharedRegistrationBase = ""
		self:updateSubSchemas(self.resetXMLSharedRegistration, sharedRegistrationName, sharedRegistrationBase, force)
	end
end
function XMLSchema:addDelayedRegistrationPath(basePath, name)
	table.insert(self.delayedRegistrationPaths, { basePath = basePath, name = name, sharedName = self.sharedRegistrationName, sharedBase = self.sharedRegistrationBase })
	for _, func in ipairs(self.delayedRegistrationFuncs) do
		if func.name == name then
			func.func(self, basePath)
		end
	end
	self:updateSubSchemas(self.addDelayedRegistrationPath, basePath, name)
end
function XMLSchema:addDelayedRegistrationFunc(name, func, isSub)
	for _, path in ipairs(self.delayedRegistrationPaths) do
		if path.name == name then
			local startSharedName = self.sharedRegistrationName
			local startSharedBase = self.sharedRegistrationBase
			self:setXMLSharedRegistration(path.sharedName, path.sharedBase, true)
			func(self, path.basePath)
			self:setXMLSharedRegistration(startSharedName, startSharedBase, true)
		end
	end
	if not isSub then
		table.insert(self.delayedRegistrationFuncs, { name = name, func = func })
	end
	self:updateSubSchemas(self.addDelayedRegistrationFunc, name, func)
	for i = 1, #self.delayedRegistrationSharedSchemas do
		local subSchema = self.delayedRegistrationSharedSchemas[i]
		subSchema:addDelayedRegistrationFunc(name, func, true)
	end
end
function XMLSchema:shareDelayedRegistrationFuncs(parentSchema)
	self.delayedRegistrationFuncs = parentSchema.delayedRegistrationFuncs
	table.insert(parentSchema.delayedRegistrationSharedSchemas, self)
	self:updateSubSchemas(self.shareDelayedRegistrationFuncs, parentSchema)
end
function XMLSchema:addSubSchema(xmlSchema, identifier)
	if xmlSchema ~= nil and identifier ~= nil then
		table.insert(self.subSchemas, { identifier = identifier, xmlSchema = xmlSchema })
		self.hasSubSchemas = true
	end
end
function XMLSchema:setSubSchemaIdentifier(identifier)
	self.subSchemaIdentifier = identifier
end
function XMLSchema:updateSubSchemas(func, ...)
	if self.hasSubSchemas then
		for i = 1, #self.subSchemas do
			local subSchema = self.subSchemas[i]
			if subSchema.identifier == self.subSchemaIdentifier then
				func(subSchema.xmlSchema, ...)
			end
		end
	end
end
function XMLSchema:registerInheritancePaths(rootName)
	self:register(XMLValueType.STRING, rootName .. ".parentFile#xmlFilename", "Parent xml filepath used as basis")
	self:register(XMLValueType.STRING, rootName .. ".parentFile.attributes.remove(?)#path", "Path to remove from parent xml")
	self:register(XMLValueType.STRING, rootName .. ".parentFile.attributes.set(?)#path", "Path change in parent xml")
	self:register(XMLValueType.STRING, rootName .. ".parentFile.attributes.set(?)#value", "Target value to set in parent file")
	self:register(XMLValueType.STRING, rootName .. ".parentFile.attributes.clearList(?)#path", "List to clear but keep one item")
	self:register(XMLValueType.INT, rootName .. ".parentFile.attributes.clearList(?)#keepIndex", "Index of list to keep")
end
function XMLSchema:generateSchema(outputPath)
	log(string.format("Generating Schema for '%s'. Num. paths: %d", self.name, self.numPaths))
	outputPath = outputPath or XMLManager.EXPORT_DIRECTORY_XSD
	local orderedPaths = {}
	for _, data in pairs(self.paths) do
		table.insert(orderedPaths, data)
	end
	table.sort(orderedPaths, function(a, b)
		return string.lower(a.path) < string.lower(b.path)
	end)
	local root = {}
	root.children = {}
	for _, data in ipairs(orderedPaths) do
		local path = data.path
		local parentElement = root.children
		local pathParts = path:split(".")
		local allowSubElements = true
		if pathParts[#pathParts]:find("#") ~= nil then
			local subParts = pathParts[#pathParts]:split("#")
			if #subParts == 2 then
				pathParts[#pathParts] = subParts[1]
				table.insert(pathParts, subParts[2])
			end
			allowSubElements = false
		end
		for i = 1, #pathParts do
			local oldTag = pathParts[i]
			local tag = oldTag:gsub("%(%?%)", "")
			local partAllowSubElements = allowSubElements or i < #pathParts
			local hasMultipleElements = false
			if oldTag ~= tag then
				hasMultipleElements = true
			end
			local added = false
			local addedElement = nil
			for _, otherChild in ipairs(parentElement) do
				if otherChild.tag == tag and otherChild.allowSubElements then
					addedElement = otherChild
					added = true
					break
				end
			end
			if not added then
				local sharedName = data.sharedName
				if sharedName ~= XMLSchema.XML_SHARED_NONE then
					local parts = data.sharedBase:split(".")
					for j = 1, #parts do
						if parts[j]:gsub("%(%?%)", "") == tag then
							sharedName = XMLSchema.XML_SHARED_NONE
							break
						end
					end
				end
				addedElement = { tag = tag, allowSubElements = partAllowSubElements, hasMultipleElements = hasMultipleElements, sharedName = sharedName, children = {} }
				table.insert(parentElement, addedElement)
			elseif data.sharedName ~= XMLSchema.XML_SHARED_NONE then
				if addedElement.sharedName == XMLSchema.XML_SHARED_NONE then
					local readdSharedName = true
					local parts = data.sharedBase:split(".")
					for j = 1, #parts do
						if parts[j]:gsub("%(%?%)", "") == tag then
							readdSharedName = false
							break
						end
					end
					if readdSharedName then
						addedElement.sharedName = data.sharedName
					end
				end
			end
			if i == #pathParts then
				addedElement.data = data
			end
			parentElement = addedElement.children
		end
	end
	local TAB = "    "
	local lastInsert = 0
	local schema = {}
	local add = function(str, i, indent)
		indent = indent or ""
		if i ~= nil then
			table.insert(schema, i, indent .. str)
			lastInsert = i
		else
			table.insert(schema, indent .. str)
			lastInsert = #schema
		end
		return lastInsert
	end
	local indent = nil
	indent = indent or ""
	table.insert(schema, indent .. '<?xml version="1.0" encoding="UTF-8" ?>')
	lastInsert = #schema
	local indent = nil
	indent = indent or ""
	table.insert(schema, indent .. '<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">')
	lastInsert = #schema
	local indent = nil
	indent = indent or ""
	table.insert(schema, indent .. "</xs:schema>")
	lastInsert = #schema
	local currentLine = lastInsert
	local currentIndent = "    "
	local formatTypeName = function(name)
		return "g_" .. string.lower(name)
	end
	local addSimpleType = function(line, indent, name, description, isBaseType, base, pattern, content)
		local str = string.format('<xs:simpleType name="%s">', "g_" .. string.lower(name))
		local i = line
		local indent = indent
		indent = indent or ""
		if i ~= nil then
			table.insert(schema, i, indent .. str)
			lastInsert = i
		else
			table.insert(schema, indent .. str)
			lastInsert = #schema
		end
		line = lastInsert + 1
		if description ~= nil then
			local str = string.format("<xs:annotation><xs:appinfo><typeStr>%s</typeStr></xs:appinfo></xs:annotation>", description)
			local i = line
			local indent = indent .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. str)
				lastInsert = i
			else
				table.insert(schema, indent .. str)
				lastInsert = #schema
			end
			line = lastInsert + 1
		end
		if not isBaseType then
			local str = string.format('<xs:restriction base="%s"%s>', base, pattern ~= nil and "" or "/")
			local i = line
			local indent = indent .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. str)
				lastInsert = i
			else
				table.insert(schema, indent .. str)
				lastInsert = #schema
			end
			line = lastInsert + 1
			if pattern ~= nil then
				local str = string.format('<xs:pattern value="%s"/>', pattern)
				local i = line
				local indent = indent .. "    " .. "    "
				indent = indent or ""
				if i ~= nil then
					table.insert(schema, i, indent .. str)
					lastInsert = i
				else
					table.insert(schema, indent .. str)
					lastInsert = #schema
				end
				line = lastInsert + 1
				if string.startsWith(base, "xs:") then
					local i = line
					local indent = indent .. "    " .. "    "
					indent = indent or ""
					if i ~= nil then
						table.insert(schema, i, indent .. '<xs:whiteSpace value="preserve"/>')
						lastInsert = i
					else
						table.insert(schema, indent .. '<xs:whiteSpace value="preserve"/>')
						lastInsert = #schema
					end
					line = lastInsert + 1
				end
				local i = line
				local indent = indent .. "    "
				indent = indent or ""
				if i ~= nil then
					table.insert(schema, i, indent .. "</xs:restriction>")
					lastInsert = i
				else
					table.insert(schema, indent .. "</xs:restriction>")
					lastInsert = #schema
				end
				line = lastInsert + 1
			end
		else
			local i = line
			local indent = indent .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. content)
				lastInsert = i
			else
				table.insert(schema, indent .. content)
				lastInsert = #schema
			end
			line = lastInsert + 1
		end
		local i = line
		local indent = indent
		indent = indent or ""
		if i ~= nil then
			table.insert(schema, i, indent .. "</xs:simpleType>")
			lastInsert = i
		else
			table.insert(schema, indent .. "</xs:simpleType>")
			lastInsert = #schema
		end
		line = lastInsert + 1
		local i = line
		local indent = ""
		indent = indent or ""
		if i ~= nil then
			table.insert(schema, i, indent .. "")
			lastInsert = i
		else
			table.insert(schema, indent .. "")
			lastInsert = #schema
		end
		line = lastInsert + 1
		return line, indent
	end
	for _, xmlBaseValueType in ipairs(XMLValueType.BASE_TYPES) do
		currentLine, currentIndent = addSimpleType(currentLine, currentIndent, xmlBaseValueType.name, xmlBaseValueType.description, true, nil, nil, xmlBaseValueType.content)
	end
	for _, xmlValueType in ipairs(XMLValueType.TYPES) do
		currentLine, currentIndent = addSimpleType(currentLine, currentIndent, xmlValueType.name, xmlValueType.description, false, xmlValueType.xsdBase, xmlValueType.xsdPattern)
	end
	function self.checkForSharedNames(data, isSub)
		if (data.sharedName ~= XMLSchema.XML_SHARED_NONE or isSub) and 0 < #data.children then
			for _, subData in ipairs(data.children) do
				if subData.sharedName == XMLSchema.XML_SHARED_NONE or not self.checkForSharedNames(subData, true) then
					return false
				end
				if subData.data == nil then
					continue
				end
				if subData.data.sharedName == XMLSchema.XML_SHARED_NONE then
					return false
				end
			end
		end
		return true
	end
	local getSupportsNativeDefault = function(data)
		local defaultValue = data.defaultValue
		if defaultValue == nil then
			return false
		end
		local valueType = XMLValueType.TYPES[data.valueTypeId]
		if type(defaultValue) ~= valueType.luaType then
			return false
		elseif valueType.luaPattern == nil then
			return true
		else
			if type(valueType.luaPattern) == "string" then
				if string.match(defaultValue, valueType.luaPattern) == defaultValue then
					return true
				end
			elseif type(valueType.luaPattern) == "table" then
				for i = 1, #valueType.luaPattern do
					if defaultValue == valueType.luaPattern[i] then
						return true
					end
				end
			end
			return false
		end
	end
	local addAnnotation = function(data, line, indent)
		local appInfo = ""
		local defaultStr = nil
		if data.defaultValue ~= nil and not getSupportsNativeDefault(data) then
			defaultStr = string.format("<defaultStr>%s</defaultStr>", XMLSchema.escapeXML(data.defaultValue))
		end
		if defaultStr ~= nil then
			appInfo = string.format("<xs:appinfo>%s</xs:appinfo>", defaultStr)
		end
		local docElement = ""
		if not string.isNilOrWhitespace(data.description) then
			docElement = string.format('<xs:documentation xml:lang="en">%s</xs:documentation>', XMLSchema.escapeXML(data.description))
		end
		if data.allowedValues then
			local i = line
			local indent = indent .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. "<xs:simpleType>")
				lastInsert = i
			else
				table.insert(schema, indent .. "<xs:simpleType>")
				lastInsert = #schema
			end
			line = lastInsert + 1
			if docElement ~= "" or appInfo ~= "" then
				local str = string.format("<xs:annotation>%s%s</xs:annotation>", docElement, appInfo)
				local i = line
				local indent = indent .. "    " .. "    "
				indent = indent or ""
				if i ~= nil then
					table.insert(schema, i, indent .. str)
					lastInsert = i
				else
					table.insert(schema, indent .. str)
					lastInsert = #schema
				end
				line = lastInsert + 1
			end
			local i = line
			local indent = indent .. "    " .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. '<xs:restriction base="xs:string">')
				lastInsert = i
			else
				table.insert(schema, indent .. '<xs:restriction base="xs:string">')
				lastInsert = #schema
			end
			line = lastInsert + 1
			for _, value in ipairs(data.allowedValues) do
				local str = string.format('<xs:enumeration value="%s" />', value)
				local i = line
				local indent = indent .. "    " .. "    " .. "    "
				indent = indent or ""
				if i ~= nil then
					table.insert(schema, i, indent .. str)
					lastInsert = i
				else
					table.insert(schema, indent .. str)
					lastInsert = #schema
				end
				line = lastInsert + 1
			end
			local i = line
			local indent = indent .. "    " .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. "</xs:restriction>")
				lastInsert = i
			else
				table.insert(schema, indent .. "</xs:restriction>")
				lastInsert = #schema
			end
			line = lastInsert + 1
			local i = line
			local indent = indent .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. "</xs:simpleType>")
				lastInsert = i
			else
				table.insert(schema, indent .. "</xs:simpleType>")
				lastInsert = #schema
			end
			line = lastInsert + 1
			return line
		elseif data.externalAutocompletionXML then
			local valueType = XMLValueType.TYPES[data.valueTypeId]
			local i = line
			local indent = indent .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. "<xs:annotation>")
				lastInsert = i
			else
				table.insert(schema, indent .. "<xs:annotation>")
				lastInsert = #schema
			end
			line = lastInsert + 1
			if docElement ~= "" then
				local str = docElement
				local i = line
				local indent = indent .. "    " .. "    "
				indent = indent or ""
				if i ~= nil then
					table.insert(schema, i, indent .. str)
					lastInsert = i
				else
					table.insert(schema, indent .. str)
					lastInsert = #schema
				end
				line = lastInsert + 1
			end
			local i = line
			local indent = indent .. "    " .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. "<xs:appinfo>")
				lastInsert = i
			else
				table.insert(schema, indent .. "<xs:appinfo>")
				lastInsert = #schema
			end
			line = lastInsert + 1
			local str = string.format("<typeStr>%s</typeStr>", valueType.description)
			local i = line
			local indent = indent .. "    " .. "    " .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. str)
				lastInsert = i
			else
				table.insert(schema, indent .. str)
				lastInsert = #schema
			end
			line = lastInsert + 1
			if defaultStr then
				local str = defaultStr
				local i = line
				local indent = indent .. "    " .. "    " .. "    "
				indent = indent or ""
				if i ~= nil then
					table.insert(schema, i, indent .. str)
					lastInsert = i
				else
					table.insert(schema, indent .. str)
					lastInsert = #schema
				end
				line = lastInsert + 1
			end
			local str = string.format('<giantsAutoCompletion sourceFile="%s" prefix="%s">', data.externalAutocompletionXML, data.externalAutocompletionXMLPrefix)
			local i = line
			local indent = indent .. "    " .. "    " .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. str)
				lastInsert = i
			else
				table.insert(schema, indent .. str)
				lastInsert = #schema
			end
			line = lastInsert + 1
			local str = string.format("<path>%s</path>", data.externalAutocompletionXMLKey)
			local i = line
			local indent = indent .. "    " .. "    " .. "    " .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. str)
				lastInsert = i
			else
				table.insert(schema, indent .. str)
				lastInsert = #schema
			end
			line = lastInsert + 1
			local i = line
			local indent = indent .. "    " .. "    " .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. "</giantsAutoCompletion>")
				lastInsert = i
			else
				table.insert(schema, indent .. "</giantsAutoCompletion>")
				lastInsert = #schema
			end
			line = lastInsert + 1
			local i = line
			local indent = indent .. "    " .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. "</xs:appinfo>")
				lastInsert = i
			else
				table.insert(schema, indent .. "</xs:appinfo>")
				lastInsert = #schema
			end
			line = lastInsert + 1
			local i = line
			local indent = indent .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. "</xs:annotation>")
				lastInsert = i
			else
				table.insert(schema, indent .. "</xs:annotation>")
				lastInsert = #schema
			end
			line = lastInsert + 1
			return line
		else
			if docElement ~= "" or appInfo ~= "" then
				local str = string.format("<xs:annotation>%s%s</xs:annotation>", docElement, appInfo)
				local i = line
				local indent = indent .. "    "
				indent = indent or ""
				if i ~= nil then
					table.insert(schema, i, indent .. str)
					lastInsert = i
				else
					table.insert(schema, indent .. str)
					lastInsert = #schema
				end
				line = lastInsert + 1
			end
			return line
		end
	end
	local addAttribute = function(data, line, indent)
		local valueType = XMLValueType.TYPES[data.data.valueTypeId]
		local name = valueType.name
		local valueTypeName = "g_" .. string.lower(name)
		local additional = ""
		if data.data.isRequired then
			additional = additional .. ' use="required"'
		end
		if data.data.defaultValue ~= nil and getSupportsNativeDefault(data.data) then
			additional = additional .. string.format(' default="%s"', data.data.defaultValue)
		end
		if data.data.allowedValues then
			local str = string.format('<xs:attribute name="%s"%s>', data.tag, additional)
			local i = line
			local indent = indent
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. str)
				lastInsert = i
			else
				table.insert(schema, indent .. str)
				lastInsert = #schema
			end
			line = lastInsert + 1
		else
			local str = string.format('<xs:attribute name="%s" type="%s"%s>', data.tag, valueTypeName, additional)
			local i = line
			local indent = indent
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. str)
				lastInsert = i
			else
				table.insert(schema, indent .. str)
				lastInsert = #schema
			end
			line = lastInsert + 1
		end
		line = addAnnotation(data.data, line, indent)
		local str = string.format("</xs:attribute>")
		local i = line
		local indent = indent
		indent = indent or ""
		if i ~= nil then
			table.insert(schema, i, indent .. str)
			lastInsert = i
		else
			table.insert(schema, indent .. str)
			lastInsert = #schema
		end
		line = lastInsert + 1
		return line
	end
	function self.addElement(line, indent, name, data, isRoot, onlyChildren, additionalAttributes, printSharedAttributes)
		if not onlyChildren then
			local printShared = false
			if data.sharedName ~= XMLSchema.XML_SHARED_NONE and not printSharedAttributes then
				if self.checkForSharedNames(data) then
					printShared = true
				else
					printSharedAttributes = true
				end
			end
			if printShared then
				local maxOccurs = ' maxOccurs="1"'
				if data.hasMultipleElements then
					maxOccurs = ' maxOccurs="unbounded"'
				end
				local str = string.format('<xs:element name="%s" type="%s" minOccurs="0"%s/>', name, data.sharedName, maxOccurs)
				local i = line
				local indent = indent
				indent = indent or ""
				if i ~= nil then
					table.insert(schema, i, indent .. str)
					lastInsert = i
				else
					table.insert(schema, indent .. str)
					lastInsert = #schema
				end
				line = lastInsert + 1
				return line
			elseif 0 >= #data.children then
				local valueType = XMLValueType.TYPES[data.data.valueTypeId]
				if valueType == nil then
					log(data.data.valueTypeId)
				end
				local name = valueType.name
				local valueTypeName = "g_" .. string.lower(name)
				local additional = ""
				if data.data.isRequired then
					additional = additional .. 'use="required"'
				end
				if data.data.allowedValues then
					local str = string.format('<xs:element name="%s"%s>', name, additional)
					local i = line
					local indent = indent
					indent = indent or ""
					if i ~= nil then
						table.insert(schema, i, indent .. str)
						lastInsert = i
					else
						table.insert(schema, indent .. str)
						lastInsert = #schema
					end
					line = lastInsert + 1
				else
					local str = string.format('<xs:element name="%s" type="%s" %s>', name, valueTypeName, additional)
					local i = line
					local indent = indent
					indent = indent or ""
					if i ~= nil then
						table.insert(schema, i, indent .. str)
						lastInsert = i
					else
						table.insert(schema, indent .. str)
						lastInsert = #schema
					end
					line = lastInsert + 1
				end
				line = addAnnotation(data.data, line, indent)
				local str = string.format("</xs:element>")
				local indent = line
				indent = indent or ""
				table.insert(schema, true, indent .. str)
				lastInsert = true
				line = lastInsert + 1
			else
				local minOccurs = ' minOccurs="0"'
				local maxOccurs = ' maxOccurs="1"'
				if data.hasMultipleElements then
					maxOccurs = ' maxOccurs="unbounded"'
				end
				if isRoot then
					minOccurs = ""
					maxOccurs = ""
				end
				local str = string.format('<xs:element name="%s"%s%s>', name, minOccurs, maxOccurs)
				local i = line
				local indent = indent
				indent = indent or ""
				if i ~= nil then
					table.insert(schema, i, indent .. str)
					lastInsert = i
				else
					table.insert(schema, indent .. str)
					lastInsert = #schema
				end
				line = lastInsert + 1
			end
		end
		if 0 < #data.children then
			local str = string.format("<xs:complexType%s>", additionalAttributes or "")
			local i = line
			local indent = indent .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. str)
				lastInsert = i
			else
				table.insert(schema, indent .. str)
				lastInsert = #schema
			end
			line = lastInsert + 1
		end
		local hasSubElements = false
		for _, subData in ipairs(data.children) do
			if subData.data == nil or subData.data.path:find("#") == nil then
				hasSubElements = true
			end
		end
		if hasSubElements then
			local indicator = "xs:all"
			local indicatorAtt = ""
			for _, subData in ipairs(data.children) do
				if subData.hasMultipleElements then
					indicator = "xs:choice"
					indicatorAtt = ' maxOccurs="unbounded"'
				end
			end
			local str = string.format("<%s%s>", indicator, indicatorAtt)
			local i = line
			local indent = indent .. "    " .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. str)
				lastInsert = i
			else
				table.insert(schema, indent .. str)
				lastInsert = #schema
			end
			line = lastInsert + 1
			for _, subData in ipairs(data.children) do
				if subData.data == nil then
					line = self.addElement(line, indent .. "    " .. "    " .. "    ", subData.tag, subData, nil, nil, nil, printSharedAttributes)
				elseif subData.data.path:find("#") == nil then
					local valueType = XMLValueType.TYPES[subData.data.valueTypeId]
					local name = valueType.name
					local valueTypeName = "g_" .. string.lower(name)
					local minOccurs = 0
					if subData.data.isRequired then
						minOccurs = 1
					end
					if #subData.children == 0 then
						if subData.data.allowedValues then
							local str = string.format('<xs:element name="%s" minOccurs="%d">', subData.tag, minOccurs)
							local i = line
							local indent = indent .. "    " .. "    " .. "    "
							indent = indent or ""
							if i ~= nil then
								table.insert(schema, i, indent .. str)
								lastInsert = i
							else
								table.insert(schema, indent .. str)
								lastInsert = #schema
							end
							line = lastInsert + 1
						else
							local str = string.format('<xs:element name="%s" type="%s" minOccurs="%d">', subData.tag, valueTypeName, minOccurs)
							local i = line
							local indent = indent .. "    " .. "    " .. "    "
							indent = indent or ""
							if i ~= nil then
								table.insert(schema, i, indent .. str)
								lastInsert = i
							else
								table.insert(schema, indent .. str)
								lastInsert = #schema
							end
							line = lastInsert + 1
						end
						line = addAnnotation(subData.data, line, indent .. "    " .. "    " .. "    ")
						local i = line
						local indent = indent .. "    " .. "    " .. "    "
						indent = indent or ""
						if i ~= nil then
							table.insert(schema, i, indent .. "</xs:element>")
							lastInsert = i
						else
							table.insert(schema, indent .. "</xs:element>")
							lastInsert = #schema
						end
						line = lastInsert + 1
					else
						local baseIndent = indent .. "    " .. "    " .. "    "
						local str = string.format('<xs:element name="%s" minOccurs="%d">', subData.tag, minOccurs)
						local i = line
						local indent = baseIndent
						indent = indent or ""
						if i ~= nil then
							table.insert(schema, i, indent .. str)
							lastInsert = i
						else
							table.insert(schema, indent .. str)
							lastInsert = #schema
						end
						line = lastInsert + 1
						line = addAnnotation(subData.data, line, baseIndent)
						local i = line
						local indent = baseIndent .. "    "
						indent = indent or ""
						if i ~= nil then
							table.insert(schema, i, indent .. "<xs:complexType>")
							lastInsert = i
						else
							table.insert(schema, indent .. "<xs:complexType>")
							lastInsert = #schema
						end
						line = lastInsert + 1
						local i = line
						local indent = baseIndent .. "    " .. "    "
						indent = indent or ""
						if i ~= nil then
							table.insert(schema, i, indent .. "<xs:simpleContent>")
							lastInsert = i
						else
							table.insert(schema, indent .. "<xs:simpleContent>")
							lastInsert = #schema
						end
						line = lastInsert + 1
						local str = string.format('<xs:extension base="%s">', valueTypeName)
						local i = line
						local indent = baseIndent .. "    " .. "    " .. "    "
						indent = indent or ""
						if i ~= nil then
							table.insert(schema, i, indent .. str)
							lastInsert = i
						else
							table.insert(schema, indent .. str)
							lastInsert = #schema
						end
						line = lastInsert + 1
						for _, attData in ipairs(subData.children) do
							if attData.data == nil or attData.data.path:find("#") == nil then
								continue
							end
							line = addAttribute(attData, line, baseIndent .. "    " .. "    " .. "    " .. "    ")
						end
						local i = line
						local indent = baseIndent .. "    " .. "    " .. "    "
						indent = indent or ""
						if i ~= nil then
							table.insert(schema, i, indent .. "</xs:extension>")
							lastInsert = i
						else
							table.insert(schema, indent .. "</xs:extension>")
							lastInsert = #schema
						end
						line = lastInsert + 1
						local i = line
						local indent = baseIndent .. "    " .. "    "
						indent = indent or ""
						if i ~= nil then
							table.insert(schema, i, indent .. "</xs:simpleContent>")
							lastInsert = i
						else
							table.insert(schema, indent .. "</xs:simpleContent>")
							lastInsert = #schema
						end
						line = lastInsert + 1
						local i = line
						local indent = baseIndent .. "    "
						indent = indent or ""
						if i ~= nil then
							table.insert(schema, i, indent .. "</xs:complexType>")
							lastInsert = i
						else
							table.insert(schema, indent .. "</xs:complexType>")
							lastInsert = #schema
						end
						line = lastInsert + 1
						local i = line
						local indent = baseIndent
						indent = indent or ""
						if i ~= nil then
							table.insert(schema, i, indent .. "</xs:element>")
							lastInsert = i
						else
							table.insert(schema, indent .. "</xs:element>")
							lastInsert = #schema
						end
						line = lastInsert + 1
					end
				end
			end
			local str = string.format("</%s>", indicator)
			local i = line
			local indent = indent .. "    " .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. str)
				lastInsert = i
			else
				table.insert(schema, indent .. str)
				lastInsert = #schema
			end
			line = lastInsert + 1
		end
		for _, subData in ipairs(data.children) do
			if subData.data == nil or subData.data.path:find("#") == nil then
				continue
			end
			line = addAttribute(subData, line, indent .. "    " .. "    ")
		end
		if 0 < #data.children then
			local i = line
			local indent = indent .. "    "
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. "</xs:complexType>")
				lastInsert = i
			else
				table.insert(schema, indent .. "</xs:complexType>")
				lastInsert = #schema
			end
			line = lastInsert + 1
		end
		if 0 < #data.children and not onlyChildren then
			local i = line
			local indent = indent
			indent = indent or ""
			if i ~= nil then
				table.insert(schema, i, indent .. "</xs:element>")
				lastInsert = i
			else
				table.insert(schema, indent .. "</xs:element>")
				lastInsert = #schema
			end
			line = lastInsert + 1
		end
		return line
	end
	local addedSharedNames = {}
	function self.addSharedElement(line, name, data)
		if data.sharedName ~= XMLSchema.XML_SHARED_NONE and addedSharedNames[data.sharedName] == nil then
			if self.checkForSharedNames(data) then
				line = self.addElement(line, "", name, data, false, true, string.format(' name="%s"', data.sharedName), true)
				local i = line
				local indent = ""
				indent = indent or ""
				if i ~= nil then
					table.insert(schema, i, indent .. "")
					lastInsert = i
				else
					table.insert(schema, indent .. "")
					lastInsert = #schema
				end
				line = lastInsert + 1
				addedSharedNames[data.sharedName] = true
			else
				return line
			end
		end
		for _, subData in ipairs(data.children) do
			line = self.addSharedElement(line, subData.tag, subData)
		end
		return line
	end
	for _, element in ipairs(root.children) do
		currentLine = self.addSharedElement(currentLine, element.tag, element)
	end
	for _, element in ipairs(root.children) do
		currentLine = self.addElement(currentLine, currentIndent, element.tag, element, true)
	end
	local schemaPath = string.format("%s%s.xsd", outputPath, self.name)
	local file = io.open(schemaPath, "w")
	for _, v in pairs(schema) do
		file:write(v .. "\n")
	end
	file:close()
	log("Saved XML Schema to: ", schemaPath)
end
function XMLSchema:generateHTML(outputPath)
	log(string.format("Generating HTML for '%s'. Num. paths: %d", self.name, self.numPaths))
	outputPath = outputPath or XMLManager.EXPORT_DIRECTORY_HTML
	local orderedPaths = {}
	for _, data in pairs(self.paths) do
		table.insert(orderedPaths, data)
	end
	local root = {}
	root.children = {}
	for _, data in ipairs(orderedPaths) do
		local path = data.path
		local parentElement = root.children
		local pathParts = path:split(".")
		local allowSubElements = true
		if pathParts[#pathParts]:find("#") ~= nil then
			local subParts = pathParts[#pathParts]:split("#")
			if #subParts == 2 then
				pathParts[#pathParts] = subParts[1]
				table.insert(pathParts, subParts[2])
			end
			allowSubElements = false
		end
		for i = 1, #pathParts do
			local oldTag = pathParts[i]
			local tag = oldTag:gsub("%(%?%)", "")
			local partAllowSubElements = allowSubElements or i < #pathParts
			local hasMultipleElements = false
			if oldTag ~= tag then
				hasMultipleElements = true
			end
			local added = false
			local addedElement = nil
			for _, otherChild in ipairs(parentElement) do
				if otherChild.tag == tag and otherChild.allowSubElements then
					addedElement = otherChild
					added = true
					break
				end
			end
			if not added then
				addedElement = { tag = tag, allowSubElements = partAllowSubElements, hasMultipleElements = hasMultipleElements, children = {} }
				table.insert(parentElement, addedElement)
			end
			if i == #pathParts then
				addedElement.data = data
			end
			parentElement = addedElement.children
		end
	end
	local TAB = " "
	local lastInsert = 0
	local schema = {}
	local add = function(str, i, indent, lineBreak)
		local prefix = ""
		local postfix = ""
		local tabLength = (indent or prefix):len()
		if 0 < tabLength then
			prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
			postfix = "</span>"
		end
		if lineBreak == true then
			postfix = postfix .. "<br>"
		end
		if i ~= nil then
			table.insert(schema, i, prefix .. str .. postfix)
			lastInsert = i
		else
			table.insert(schema, prefix .. str .. postfix)
			lastInsert = #schema
		end
		return lastInsert
	end
	local OPEN = "&lt;"
	local OPEN_END = "&lt;/"
	local CLOSE = "&gt;"
	local CLOSE_END = "/&gt;"
	local TYPE_TAG = 1
	local TYPE_ATTRIBUTE = 2
	local TYPE_ATTRIBUTE_VALUE = 3
	local TYPE_VALUE = 4
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "<!DOCTYPE html>" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "<head>" .. postfix)
	lastInsert = #schema
	add(string.format("  <title>XML Documentation (v%s): %s</title>", g_gameVersionDisplay, self.name))
	local currentLine = nil
	local currentIndent = ""
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "<style>" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "body {" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. '  font-family: "Courier New";' .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  overflow-x: scroll;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "}" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. ".idTag {" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  color: rgb(0, 0, 255);" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "}" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. ".idAttr {" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  color: rgb(255, 0, 0);" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "}" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. ".idAttrVal {" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  color: rgb(0, 0, 0);" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "}" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. ".idVal {" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  color: rgb(128, 0, 255);" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "}" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. ".attr {" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  position: relative;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  display: inline-block;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  font-weight: normal;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "}" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. ".attr .attrInfo {" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  visibility: hidden;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  width: 350px;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  top: 100%;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  left: 50%;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  margin-left: -175px;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  background-color: white;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  text-align: left;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  padding: 5px 0;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  border-radius: 6px;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  border-style: solid;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  border-color: black;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  color: black;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  position: absolute;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  z-index: 1;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "}" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. ".attr:hover .attrInfo {" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  visibility: visible;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "}" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. ".attr:hover{" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "  font-weight: bold;" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "}" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "</style>" .. postfix)
	lastInsert = #schema
	local prefix = ""
	local postfix = ""
	local tabLength = prefix:len()
	if 0 < tabLength then
		prefix = string.format('<span style="margin-left:%dem">', tabLength * 2)
		postfix = "</span>"
	end
	table.insert(schema, prefix .. "</head>" .. postfix)
	lastInsert = #schema
	currentLine = lastInsert + 1
	local format = function(str, type)
		if type == 1 then
			str = string.format('<span class="idTag">%s</span>', str)
			return str
		elseif type == 2 then
			str = string.format('<span class="idAttr">%s</span>', str)
			return str
		elseif type == 3 then
			str = string.format('<span class="idAttrVal">%s</span>', str)
			return str
		else
			if type == 4 then
				str = string.format('<span class="idVal">%s</span>', str)
			end
			return str
		end
	end
	local getAttributeInfo = function(data)
		local valueType = XMLValueType.TYPES[data.valueTypeId]
		local desc = string.format("Description: %s<br>", data.description or "missing")
		local type = string.format("Type: %s<br>", valueType.description)
		local default = ""
		if data.defaultValue ~= nil then
			default = string.format("Default: %s<br>", data.defaultValue)
		end
		local required = string.format("Required: %s<br>", data.isRequired and "yes" or "no")
		return desc .. type .. default .. required
	end
	local buildAttribute = function(data, attributeType, spacing, useAllTypes, isDirect)
		if data.data ~= nil and (data.data.path:find("#") ~= nil or useAllTypes) then
			local valueType = XMLValueType.TYPES[data.data.valueTypeId]
			local valueStr = valueType.defaultStr
			if data.data.defaultValue ~= nil and type(data.data.defaultValue) == valueType.luaType then
				if valueType.luaPattern ~= nil then
					if type(valueType.luaPattern) == "string" then
						if string.match(data.data.defaultValue, valueType.luaPattern) == data.data.defaultValue then
							valueStr = data.data.defaultValue
						end
					elseif type(valueType.luaPattern) == "table" then
						for i = 1, #valueType.luaPattern do
							if data.data.defaultValue == valueType.luaPattern[i] then
								valueStr = data.data.defaultValue
							end
						end
					end
				else
					valueStr = data.data.defaultValue
				end
			end
			local attributeRaw = nil
			if isDirect then
				attributeRaw = format(valueStr, attributeType or 4)
			else
				attributeRaw = string.format("%s=%s", format(data.tag, 2), format(string.format('"%s"', valueStr), attributeType or 4))
			end
			local attributeInfo = getAttributeInfo(data.data)
			local attribute = string.format('<span class="attr">%s<span class="attrInfo">%s</span></span>', attributeRaw, attributeInfo)
			return (spacing or " ") .. attribute
		end
		return ""
	end
	function self.addElement(line, indent, name, data, isRoot)
		if indent:len() == 1 then
			line = add("", line, indent, true) + 1
		end
		local hasOnlyAttributeChildren = true
		for _, subData in ipairs(data.children) do
			if subData.data == nil then
				hasOnlyAttributeChildren = false
				break
			end
			if subData.data.path:find("#") == nil then
				hasOnlyAttributeChildren = false
				break
			end
		end
		local attributes = ""
		for _, subData in ipairs(data.children) do
			attributes = attributes .. buildAttribute(subData)
		end
		if hasOnlyAttributeChildren then
			line = add(string.format("%s%s%s", format("&lt;" .. name, 1), format(attributes, 2), format("/&gt;", 1)), line, indent, true) + 1
		else
			line = add(string.format("%s%s%s", format("&lt;" .. name, 1), format(attributes, 2), format("&gt;", 1)), line, indent, true) + 1
		end
		for _, subData in ipairs(data.children) do
			if subData.data == nil then
				line = self.addElement(line, indent .. " ", subData.tag, subData)
			elseif subData.data.path:find("#") == nil then
				if (indent .. " "):len() == 1 then
					line = add("", line, indent, true) + 1
				end
				local subAttributes = ""
				for _, subSubData in ipairs(subData.children) do
					subAttributes = subAttributes .. buildAttribute(subSubData)
				end
				local attribute = buildAttribute(subData, 3, "", true, true)
				line = add(string.format("%s%s%s%s%s%s", format("&lt;" .. subData.tag, 1), subAttributes, format("&gt;", 1), attribute, format("&lt;/" .. subData.tag, 1), format("&gt;", 1)), line, indent .. " ", true) + 1
			end
		end
		if not hasOnlyAttributeChildren then
			line = add(format("&lt;/" .. name .. "&gt;", 1), line, indent, true) + 1
		end
		return line
	end
	for _, element in ipairs(root.children) do
		currentLine = self.addElement(currentLine, "", element.tag, element, true)
	end
	local htmlPath = string.format("%s%s.html", outputPath, self.name)
	local file = io.open(htmlPath, "w")
	for _, v in pairs(schema) do
		file:write(v .. "\n")
	end
	file:close()
	log("Saved XML HTML to: ", htmlPath)
end
local replacementRules = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;;", ['"'] = "&quot;", ["'"] = "&apos;" }
function XMLSchema.escapeXML(str)
	if str == nil then
		return ""
	else
		return string.gsub(tostring(str), ".", replacementRules)
	end
end
