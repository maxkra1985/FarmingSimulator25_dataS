-- Local values: XMLFile_mt
source("dataS/scripts/xml/XMLValueType.lua")
XMLFile = {}
local XMLFile_mt = Class(XMLFile)

-- Local values: handle
function XMLFile.load(objectName, filename, schema)
	local v5_ = loadXMLFile(objectName, filename)
	if v5_ == 0 then
		return nil
	else
		return XMLFile.new(objectName, filename, v5_, schema)
	end
end

function XMLFile.loadIfExists(objectName, filename, schema)
	if filename == nil or not fileExists(filename) then
		return nil
	else
		return XMLFile.load(objectName, filename, schema)
	end
end

-- Local values: handle
function XMLFile.create(objectName, filepath, rootNodeName, schema)
	local v13_ = createXMLFile(objectName, filepath, rootNodeName)
	if v13_ ~= 0 then
		return XMLFile.new(objectName, filepath, v13_, schema)
	end
	Logging.error("Failed to create \'%s\' xml file", objectName)
	return nil
end

-- Upvalues: XMLFile_mt
-- Local values: self
function XMLFile.new(objectName, filename, handle, schema)
	-- upvalues: (copy) XMLFile_mt
	if type(schema) ~= "table" and schema ~= nil then
		schema = nil
		if g_isDevelopmentVersion then
			Logging.devError("XMLFile.new: schema is not a table or nil")
			printCallstack()
		end
	end
	local v18_ = XMLFile_mt
	local v19_ = setmetatable({}, v18_)
	v19_.objectName = objectName
	v19_.filename = filename
	v19_.schema = schema
	v19_.handle = handle
	v19_:initInheritance()
	if g_xmlManager ~= nil then
		g_xmlManager:addFile(v19_)
	end
	return v19_
end

-- Local values: self
function XMLFile.wrap(handle, schema)
	local v22_ = XMLFile.new(getName(handle) .. "<wrapped>", getXMLFilename(handle), handle, schema)
	v22_.noDeletion = true
	return v22_
end

function XMLFile:delete()
	if not self.noDeletion then
		delete(self.handle)
	end
	if g_xmlManager ~= nil then
		g_xmlManager:removeFile(self)
	end
end

function XMLFile:getHandle()
	return self.handle
end

function XMLFile:getFilename()
	return self.filename
end

function XMLFile:getAsString()
	return saveXMLFileToMemory(self.handle)
end

-- Local values: hasElementOrAttribute, hasElement
function XMLFile:hasProperty(property)
	local v29_, v30_ = hasXMLProperty(self.handle, property)
	return v29_, v30_
end

function XMLFile:getNumOfChildren(elementPath)
	return getXMLNumOfChildren(self.handle, elementPath)
end

function XMLFile:getNumOfElements(elementPath)
	return getXMLNumOfElements(self.handle, elementPath)
end

function XMLFile:getElementName(elementPath)
	return getXMLElementName(self.handle, elementPath)
end

function XMLFile:getLineNumber(path)
	return getXMLLineNum(self.handle, path)
end

function XMLFile:save(printToLog, ignoreError)
	if saveXMLFile(self.handle) then
		if printToLog then
			Logging.info("Saved xml file \'%s\' to \'%s\'", self.objectName, self.filename)
		end
		return true
	else
		if not ignoreError then
			Logging.error("Could not save xml file \'%s\' to \'%s\'", self.objectName, self.filename)
		end
		return false
	end
end

function XMLFile:saveTo(filepath, printToLog, ignoreError)
	if saveXMLFileTo(self.handle, filepath) then
		if printToLog then
			Logging.info("Saved xml file \'%s\' to \'%s\'", self.objectName, filepath)
		end
		return true
	else
		if not ignoreError then
			Logging.error("Could not save xml file \'%s\' to \'%s\'", self.objectName, filepath)
		end
		return false
	end
end

function XMLFile:removeProperty(path)
	removeXMLProperty(self.handle, path)
end

function XMLFile:setString(path, value)
	setXMLString(self.handle, path, value)
end

function XMLFile:setFloat(path, value)
	setXMLFloat(self.handle, path, value)
end

function XMLFile:setInt(path, value)
	setXMLInt(self.handle, path, value)
end

function XMLFile:setUInt(path, value)
	setXMLUInt(self.handle, path, value)
end

function XMLFile:setBool(path, value)
	setXMLBool(self.handle, path, value)
end

function XMLFile:addComment(path, comment)
	addXMLComment(self.handle, path, comment)
end

function XMLFile:getString(path, default)
	return getXMLString(self.handle, path) or default
end

function XMLFile:getFloat(path, default)
	return getXMLFloat(self.handle, path) or default
end

-- Local values: angle
function XMLFile:getAngle(path, default)
	local v75_ = self:getFloat(path, default)
	if v75_ == nil then
		return nil
	else
		return math.rad(v75_)
	end
end

function XMLFile:getInt(path, default)
	return getXMLInt(self.handle, path) or default
end

function XMLFile:getUInt(path, default)
	return getXMLUInt(self.handle, path) or default
end

-- Local values: v
function XMLFile:getBool(path, default)
	local v85_ = getXMLBool(self.handle, path)
	if v85_ == nil then
		return default
	else
		return v85_
	end
end

function XMLFile:getNode(path, default, components, i3dMappings)
	return XMLValueType.getXMLNode(self.handle, path, default, components, i3dMappings)
end

function XMLFile:getRootName()
	return getXMLRootName(self.handle)
end
function XMLFile.getValue(p92_, p93_, p94_, ...)
	local v95_ = XMLFile.getValueType(p92_, p93_)
	if v95_ == nil then
		return nil
	elseif v95_.isBasicFunction then
		local v96_ = v95_.get(p92_.handle, p93_)
		if v96_ == nil then
			return p94_
		else
			return v96_
		end
	else
		return v95_.get(p92_.handle, p93_, p94_, ...)
	end
end
function XMLFile.setValue(p97_, p98_, ...)
	local v99_ = XMLFile.getValueType(p97_, p98_)
	if v99_ ~= nil then
		v99_.set(p97_.handle, p98_, ...)
	end
end

-- Local values: i
function XMLFile:iterate(path, closure)
	for v103_ = 0, getXMLNumOfElements(self.handle, path) - 1 do
		if closure(v103_ + 1, path .. "(" .. v103_ .. ")") == false then
			break
		end
	end
end

-- Local values: currentIndex, numElements, iterator
function XMLFile:iterator(path)
	local v_u_106_ = 0
	local v_u_107_ = getXMLNumOfElements(self.handle, path)
	return function()
		-- upvalues: (ref) v_u_106_, (copy) v_u_107_, (copy) path
		if v_u_107_ <= v_u_106_ then
			return nil
		end
		v_u_106_ = v_u_106_ + 1
		return v_u_106_, path .. "(" .. v_u_106_ - 1 .. ")"
	end
end

-- Local values: currentIndex, numElements, iterator
function XMLFile:iterator_reverse(path)
	local v_u_110_ = 0
	local v_u_111_ = getXMLNumOfElements(self.handle, path)
	return function()
		-- upvalues: (ref) v_u_110_, (copy) v_u_111_, (copy) path
		if v_u_111_ <= v_u_110_ then
			return nil
		end
		v_u_110_ = v_u_110_ + 1
		return v_u_110_, path .. "(" .. v_u_111_ - v_u_110_ .. ")"
	end
end

-- Local values: i, childName, childPath
function XMLFile:iterateRecursively(path, closure, depth)
	local v116_ = depth or 0
	for v117_ = 0, getXMLNumOfChildren(self.handle, path) - 1 do
		local v118_ = getXMLElementName(self.handle, path .. ".*(" .. v117_ .. ")")
		local v119_ = path .. ".*(" .. v117_ .. ")"
		if closure(v118_, v119_, v117_ + 1, v116_) == false then
			return false
		end
		if getXMLNumOfChildren(self.handle, v119_) > 0 and self:iterateRecursively(v119_, closure, v116_ + 1) == false then
			return false
		end
	end
	return true
end

-- Local values: currentIndex, numElements, currentPath, iterator
function XMLFile:iteratorChildren(path)
	local v_u_122_ = 0
	local v_u_123_ = getXMLNumOfChildren(self.handle, path)
	local v_u_124_ = nil
	local v_u_125_ = path .. ".*"
	return function()
		-- upvalues: (ref) v_u_122_, (copy) v_u_123_, (ref) v_u_124_, (ref) v_u_125_, (copy) self
		if v_u_123_ <= v_u_122_ then
			return nil
		end
		v_u_122_ = v_u_122_ + 1
		v_u_124_ = v_u_125_ .. "(" .. v_u_122_ - 1 .. ")"
		return v_u_122_, v_u_124_, getXMLElementName(self.handle, v_u_124_)
	end
end

-- Local values: prefixedPath, i, key, value, valuePath, res
function XMLFile:setTable(path, tbl, closure)
	local v129_ = path .. "("
	local v130_ = 0
	for v131_, v132_ in pairs(tbl) do
		local v133_ = closure(v129_ .. v130_ .. ")", v132_, v131_)
		if v133_ == false then
			break
		end
		if v133_ ~= 0 then
			v130_ = v130_ + 1
		end
	end
	return v130_
end

-- Local values: prefixedPath, i, index, value, valuePath, res
function XMLFile:setSortedTable(path, tbl, closure)
	local v137_ = path .. "("
	local v138_ = 0
	for v139_, v140_ in ipairs(tbl) do
		local v141_ = closure(v137_ .. v138_ .. ")", v140_, v139_)
		if v141_ == false then
			break
		end
		if v141_ ~= 0 then
			v138_ = v138_ + 1
		end
	end
	return v138_
end

-- Local values: schema, normalizedPath, pathData
function XMLFile:getValueType(path)
	local v144_ = self.schema
	if v144_ == nil then
		Logging.xmlError(self, "Unable to get schema for xml file.")
		printCallstack()
		return
	elseif path == nil then
		Logging.xmlError(self, "Unable to get value from unknown path.")
		printCallstack()
	else
		local v145_ = string.gsub(path, "%(%d*%)", "(?)")
		local v146_ = v144_.paths[v145_]
		if v146_ == nil then
			local v147_ = v145_:gsub("%d+%.", "%?%."):gsub("%d+#", "%?#"):gsub("%d+$", "%?")
			v146_ = v144_.paths[v147_]
		end
		if v146_ ~= nil then
			return XMLValueType.TYPES[v146_.valueTypeId]
		end
		Logging.xmlError(self, "Failed to validate xml path \'%s\' for schema \'%s\'. Path not registered.", path, v144_.name)
		printCallstack()
	end
end

function XMLFile:setVector(path, vector)
	setXMLString(self.handle, path, table.concat(vector, " "))
end

-- Local values: vector
function XMLFile:getVector(path, default, size)
	local v155_ = getXMLString(self.handle, path)
	if v155_ == nil then
		return default
	else
		return string.getVector(v155_, size)
	end
end

function XMLFile:setTranslation(path, x, y, z, precision)
	local v162_ = precision or 3
	setXMLString(self.handle, path, string.format("%." .. v162_ .. "f %." .. v162_ .. "f %." .. v162_ .. "f", x, y, z))
end

function XMLFile:getTranslation(path, default)
	return XMLValueType.getXMLVector3(self.handle, path, default, false)
end

function XMLFile:setRotation(path, x, y, z)
	XMLValueType.setXMLVector3Angle(self.handle, path, x, y, z)
end

function XMLFile:getRotation(path, default)
	return XMLValueType.getXMLVector3Angle(self.handle, path, default, false)
end

function XMLFile:getScale(path, default)
	return XMLValueType.getXMLVector3(self.handle, path, default, false)
end

function XMLFile:getStringList(path, default, numItems)
	return XMLValueType.getXMLStringList(self.handle, path, default, numItems) or default
end

-- Local values: vector
function XMLFile:getRadiansVector(path, default, size)
	local v185_ = getXMLString(self.handle, path)
	if v185_ == nil then
		return default
	else
		return string.getRadians(v185_, size)
	end
end

function XMLFile:getI18NValue(path, default, customEnvironment, showWarning)
	return XMLUtil.getXMLI18NValue(self.handle, path, getXMLString, nil, default, customEnvironment, showWarning)
end

-- Local values: rootName, parentFilename, _, baseDirectory, parentHandle
function XMLFile:initInheritance()
	local v192_ = self:getRootName()
	local v193_ = self:getString(v192_ .. ".parentFile#xmlFilename")
	if v193_ ~= nil then
		if string.contains(v193_, "$pdlcdir") or string.contains(v193_, "$moddir") then
			Logging.xmlError(self, "Overwriting of dlc or mod files is not allowed!")
			return
		end
		local _, v194_ = Utils.getModNameAndBaseDirectory(self.filename)
		local v195_ = Utils.getFilename(v193_, v194_)
		local v_u_196_ = loadXMLFile(self.objectName, v195_)
		if v_u_196_ ~= 0 then
			self:iterate(v192_ .. ".parentFile.attributes.remove", function(_, p197_)
				-- upvalues: (copy) self, (copy) v_u_196_
				local v198_ = self:getString(p197_ .. "#path")
				removeXMLProperty(v_u_196_, v198_)
			end)
			self:iterate(v192_ .. ".parentFile.attributes.set", function(_, p199_)
				-- upvalues: (copy) self, (copy) v_u_196_
				local v200_ = self:getString(p199_ .. "#path")
				local v201_ = self:getString(p199_ .. "#value")
				setXMLString(v_u_196_, v200_, v201_)
			end)
			self:iterate(v192_ .. ".parentFile.attributes.clearList", function(_, p202_)
				-- upvalues: (copy) self, (copy) v_u_196_
				local v203_ = self:getString(p202_ .. "#path")
				local v204_ = self:getInt(p202_ .. "#keepIndex")
				local v205_ = 0
				while hasXMLProperty(v_u_196_, string.format(v203_ .. "(%d)", v205_)) do
					v205_ = v205_ + 1
				end
				for v206_ = v205_, 1, -1 do
					if v206_ ~= v204_ then
						removeXMLProperty(v_u_196_, string.format(v203_ .. "(%d)", v206_ - 1))
					end
				end
			end)
			delete(self.handle)
			self.handle = v_u_196_
			return
		end
		Logging.xmlWarning(self, "Failed to load parent xml file \'%s\'", v195_)
	end
end

-- Local values: atributeIndex, name, usedElementNames, i, elementName, j, tagName, allowed
function XMLFile:copyTree(oldPath, newPath, excludeFirstLevel, excludeSubAttribute)
	if not excludeFirstLevel then
		for v212_ = 1, getXMLNumOfAttributes(self.handle, oldPath) do
			local v213_ = getXMLAttributeName(self.handle, oldPath, v212_ - 1)
			setXMLString(self.handle, newPath .. "#" .. v213_, getXMLString(self.handle, oldPath .. "#" .. v213_))
		end
	end
	local v214_ = {}
	for v215_ = 1, getXMLNumOfChildren(self.handle, oldPath) do
		local v216_ = getXMLElementName(self.handle, string.format("%s.*(%d)", oldPath, v215_ - 1))
		if v214_[v216_] == nil then
			v214_[v216_] = true
			for v217_ = 1, getXMLNumOfElements(self.handle, oldPath .. "." .. v216_) do
				local v218_ = string.format(".%s(%d)", v216_, v217_ - 1)
				if (excludeSubAttribute == nil or not string.endsWith(oldPath .. "." .. v216_, excludeSubAttribute)) and true or false then
					self:copyTree(oldPath .. "." .. v216_, newPath .. "." .. v216_, false, excludeSubAttribute)
					self:copyTree(oldPath .. v218_, newPath .. v218_, false, excludeSubAttribute)
				end
			end
		end
	end
end
