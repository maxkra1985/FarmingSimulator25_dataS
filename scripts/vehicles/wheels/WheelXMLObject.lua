WheelXMLObject = {}
local WheelXMLObject_mt = Class(WheelXMLObject)
function WheelXMLObject.new(xmlFile, baseKey, configIndex, wheelKey, indexToParentIndex)
	local self = setmetatable({}, WheelXMLObject_mt)
	self.xmlFile = xmlFile
	self.baseKey = baseKey
	self.configIndex = configIndex
	self.baseWheelKey = wheelKey
	self.wheelKey = wheelKey
	self.indexToParentIndex = indexToParentIndex
	local _ = nil
	_, self.baseDirectory = Utils.getModNameAndBaseDirectory(self.xmlFile.filename)
	self:setXMLLoadKey("")
	return self
end
function WheelXMLObject:delete()
	if self.externalXMLFile ~= nil then
		self.externalXMLFile:delete()
		self.externalXMLFile = nil
	end
end
function WheelXMLObject:getXMLFileAndKey(configIndex, attributeKey, altAttributeKey, ignoreExternalFile)
	local key = self.baseKey .. "(" .. tostring(configIndex - 1) .. ")" .. self.wheelKey .. attributeKey
	local value = self.xmlFile:getString(key)
	if value ~= nil then
		return self.xmlFile, key
	end
	if altAttributeKey ~= nil then
		local altKey = self.baseKey .. "(" .. tostring(configIndex - 1) .. ")" .. self.wheelKey .. altAttributeKey
		value = self.xmlFile:getString(altKey)
		if value ~= nil then
			return self.xmlFile, altKey
		end
	end
	local parentIndex = self.indexToParentIndex[configIndex]
	if parentIndex ~= nil then
		return self:getXMLFileAndKey(parentIndex, attributeKey, altAttributeKey, ignoreExternalFile)
	else
		if self.externalFilename ~= nil and not ignoreExternalFile then
			if self.externalXMLFile == nil and not self:loadExternalXMLFile() then
				return nil
			end
			if self.externalConfigKey ~= nil then
				key = self.externalConfigKey .. attributeKey
				value = self.externalXMLFile:getString(key)
				if value ~= nil then
					return self.externalXMLFile, key
				end
				if altAttributeKey ~= nil then
					local altKey = self.externalConfigKey .. altAttributeKey
					value = self.externalXMLFile:getString(altKey)
					if value ~= nil then
						return self.externalXMLFile, altKey
					end
				end
			end
			key = "wheel.default" .. attributeKey
			value = self.externalXMLFile:getString(key)
			if value ~= nil then
				return self.externalXMLFile, key
			end
			if altAttributeKey ~= nil then
				local altKey = "wheel.default" .. altAttributeKey
				value = self.externalXMLFile:getString(altKey)
				if value ~= nil then
					return self.externalXMLFile, altKey
				end
			end
		end
		return nil
	end
end
function WheelXMLObject:getXMLFileAndPropertyKey(property, configIndex)
	configIndex = configIndex or self.configIndex
	local key = self.baseKey .. "(" .. tostring(configIndex - 1) .. ")" .. self.wheelKey .. property
	if self.xmlFile:hasProperty(key) then
		return self.xmlFile, key
	end
	local parentIndex = self.indexToParentIndex[configIndex]
	if parentIndex ~= nil then
		return self:getXMLFileAndPropertyKey(property, parentIndex)
	else
		if self.externalFilename ~= nil then
			if self.externalXMLFile == nil and not self:loadExternalXMLFile() then
				return nil
			end
			if self.externalConfigKey ~= nil then
				key = self.externalConfigKey .. property
				if self.externalXMLFile:hasProperty(key) then
					return self.externalXMLFile, key
				end
			end
			key = "wheel.default" .. property
			if self.externalXMLFile:hasProperty(key) then
				return self.externalXMLFile, key
			end
		end
		return nil
	end
end
function WheelXMLObject:getValue(attributeKey, ...)
	local xmlFile, key = self:getXMLFileAndKey(self.configIndex, attributeKey)
	if xmlFile ~= nil then
		if xmlFile:getString(key) == "-" then
			return nil
		else
			return xmlFile:getValue(key, ...)
		end
	end
	local defaultKey = self.baseKey .. "(" .. tostring(self.configIndex - 1) .. ")" .. self.wheelKey .. attributeKey
	return self.xmlFile:getValue(defaultKey, ...)
end
function WheelXMLObject:getLocalValue(attributeKey, ...)
	local xmlFile, key = self:getXMLFileAndKey(self.configIndex, attributeKey, nil, true)
	if xmlFile ~= nil then
		if xmlFile:getString(key) == "-" then
			return nil
		else
			return xmlFile:getValue(key, ...)
		end
	end
	local defaultKey = self.baseKey .. "(" .. tostring(self.configIndex - 1) .. ")" .. self.wheelKey .. attributeKey
	return self.xmlFile:getValue(defaultKey, ...)
end
function WheelXMLObject:getValueAlternative(attributeKey, altAttributeKey, ...)
	local xmlFile, key = self:getXMLFileAndKey(self.configIndex, attributeKey, altAttributeKey)
	if xmlFile ~= nil then
		if xmlFile:getString(key) == "-" then
			return nil
		else
			return xmlFile:getValue(key, ...)
		end
	end
	local defaultKey = self.baseKey .. "(" .. tostring(self.configIndex - 1) .. ")" .. self.wheelKey .. attributeKey
	return self.xmlFile:getValue(defaultKey, ...)
end
function WheelXMLObject.getValueStatic(configIndex, indexToParentIndex, xmlFile, baseKey, wheelKey, attributeKey, ...)
	local key = baseKey .. "(" .. tostring(configIndex - 1) .. ")" .. wheelKey .. attributeKey
	local value = xmlFile:getString(key)
	if value == nil then
		local parentIndex = indexToParentIndex[configIndex]
		if parentIndex ~= nil then
			return WheelXMLObject.getValueStatic(parentIndex, indexToParentIndex, xmlFile, baseKey, wheelKey, attributeKey, ...)
		else
			local defaultKey = baseKey .. "(" .. tostring(configIndex - 1) .. ")" .. wheelKey .. attributeKey
			return xmlFile:getValue(defaultKey, ...)
		end
	elseif value ~= "-" then
		return xmlFile:getValue(key, ...)
	else
		return nil
	end
end
function WheelXMLObject:xmlWarning(attributeKey, text, ...)
	Logging.xmlWarning(self.xmlFile, text .. " (" .. self.baseKey .. "(" .. tostring(self.configIndex - 1) .. ")" .. self.wheelKey .. attributeKey .. ")", ...)
end
function WheelXMLObject:checkDeprecatedXMLElements(oldAttributeKey, newAttribute)
	local baseKey = self.baseKey .. "(" .. tostring(self.configIndex - 1) .. ")" .. self.wheelKey
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseKey .. oldAttributeKey, baseKey .. newAttribute)
end
function WheelXMLObject:setXMLLoadKey(key, alternativeFilename)
	self.wheelKey = self.baseWheelKey .. key
	local filename = self:getLocalValue("#filename", alternativeFilename)
	if filename ~= nil and filename ~= "" then
		local configId = self:getLocalValue("#configId", "default")
		self:setExternalFilename(filename, configId)
		return
	end
	if self.externalXMLFile ~= nil then
		self.externalXMLFile:delete()
		self.externalXMLFile = nil
	end
	self.externalFilename = nil
	self.externalConfigId = nil
end
function WheelXMLObject:setExternalFilename(externalFilename, configId)
	externalFilename = Utils.getFilename(externalFilename, self.baseDirectory)
	if externalFilename ~= self.externalFilename or configId ~= self.externalConfigId then
		self.externalFilename = externalFilename
		self.externalConfigId = configId
		if self.externalXMLFile ~= nil then
			self.externalXMLFile:delete()
			self.externalXMLFile = nil
		end
		self.externalWheelName = nil
	end
end
function WheelXMLObject:loadExternalXMLFile()
	if self.externalXMLFile ~= nil then
		self.externalXMLFile:delete()
		self.externalXMLFile = nil
	end
	local xmlFile = XMLFile.load("wheelXML", self.externalFilename, Wheels.xmlSchema)
	if xmlFile ~= nil then
		self.externalXMLFile = xmlFile
		self.externalWheelName = self.externalXMLFile:getValue("wheel.metadata#name")
		xmlFile:iterate("wheel.configurations.configuration", function(index, key)
			if xmlFile:getValue(key .. "#id") == self.externalConfigId then
				self.externalConfigKey = key
			end
		end)
		return true
	else
		self.externalFilename = nil
		self.externalXMLFile = nil
		self.externalConfigId = nil
		return false
	end
end
WheelXMLObject.wheelMassCache = {}
function WheelXMLObject:cacheWheelMass()
	local vehicleXMLMass = self:getLocalValue(".physics#mass", nil)
	if vehicleXMLMass ~= nil then
		return vehicleXMLMass
	else
		if self.externalFilename ~= nil then
			if WheelXMLObject.wheelMassCache[self.externalFilename] == nil then
				WheelXMLObject.wheelMassCache[self.externalFilename] = {}
			end
			local mass = WheelXMLObject.wheelMassCache[self.externalFilename][self.externalConfigId]
			if mass ~= nil then
				return mass
			else
				local mass = self:getValue(".physics#mass", 0.1)
				for name, _ in pairs(WheelVisual.PARTS) do
					local i = 0
					while true do
						local keyAdditional = string.format(".%s(%d)", name, i)
						local xmlFile, _ = self:getXMLFileAndPropertyKey(keyAdditional)
						if xmlFile == nil then
							break
						end
						mass = mass + self:getValue(keyAdditional .. "#mass", 0)
						i = i + 1
					end
				end
				if self.externalFilename == nil or self.externalConfigId == nil then
					return 0
				end
				WheelXMLObject.wheelMassCache[self.externalFilename][self.externalConfigId] = mass
				return mass
			end
		end
		return 0.1
	end
end
