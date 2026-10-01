ConditionFlags = {}
local ConditionFlags_mt = Class(ConditionFlags)
function ConditionFlags.loadFlagFromXML(xmlFile, key, modifier, requiredFlags, preventFlags)
	local preventKey = string.format("%s.prevent#%s", key, modifier.xmlAttributeName)
	local requiredKey = string.format("%s.required#%s", key, modifier.xmlAttributeName)
	local prevent = xmlFile:getBool(preventKey)
	if prevent then
		preventFlags = bit32.bor(preventFlags, modifier.bitflag)
	end
	local required = xmlFile:getBool(requiredKey)
	if required then
		requiredFlags = bit32.bor(requiredFlags, modifier.bitflag)
	end
	return requiredFlags, preventFlags
end
function ConditionFlags.new(customMt)
	local self = setmetatable({}, customMt or ConditionFlags_mt)
	self.modifiers = {}
	self.nameToModifier = {}
	self.mask = 0
	return self
end
function ConditionFlags:delete() end
function ConditionFlags:loadFlagsFromXMLFile(xmlFile, key)
	local requiredFlags = 0
	local preventFlags = 0
	if 1 < xmlFile:getNumOfElements(string.format("%s.prevent", key)) then
		Logging.xmlWarning(xmlFile, "More than one 'prevent' element defined for '%s'", key)
	end
	if 1 < xmlFile:getNumOfElements(string.format("%s.required", key)) then
		Logging.xmlWarning(xmlFile, "More than one 'required' element defined for '%s'", key)
	end
	for _, modifier in ipairs(self.modifiers) do
		requiredFlags, preventFlags = modifier.loadFromXMLFunc(xmlFile, key, modifier, requiredFlags, preventFlags)
	end
	if bit32.band(requiredFlags, preventFlags) ~= 0 then
		for _, modifier in ipairs(self.modifiers) do
			if bit32.band(requiredFlags, modifier.bitflag) == 0 or bit32.band(preventFlags, modifier.bitflag) == 0 then
				continue
			end
			local lineNumber = xmlFile:getLineNumber(key .. ".prevent#" .. modifier.xmlAttributeName)
			Logging.xmlWarning(xmlFile, "Modifier '%s' is set for prevent and required in '%s' (line %d)", modifier.xmlAttributeName, key, lineNumber)
		end
	end
	return requiredFlags, preventFlags
end
function ConditionFlags:registerXMLPaths(xmlSchema, basePath)
	for _, modifier in ipairs(self.modifiers) do
		if modifier.hasCustomLoadFunction then
			continue
		end
		local attributeName = modifier.xmlAttributeName
		xmlSchema:register(XMLValueType.BOOL, basePath .. ".prevent#" .. attributeName, "Prevent flag " .. attributeName)
		xmlSchema:register(XMLValueType.BOOL, basePath .. ".required#" .. attributeName, "Required flag " .. attributeName)
	end
end
function ConditionFlags:registerModifier(xmlAttributeName, loadFromXMLFunc)
	local name = string.upper(xmlAttributeName)
	for _, modifier in ipairs(self.modifiers) do
		if modifier.xmlAttributeName == xmlAttributeName then
			Logging.warning("Given ConditionFlags modifier xml attribute name '%s' already used", xmlAttributeName)
			return modifier.updateFunc
		end
	end
	local modifier = {}
	modifier.name = name
	modifier.xmlAttributeName = xmlAttributeName
	modifier.hasCustomLoadFunction = loadFromXMLFunc ~= nil
	modifier.bitflag = 2 ^ (#self.modifiers + 1)
	modifier.loadFromXMLFunc = loadFromXMLFunc or ConditionFlags.loadFlagFromXML
	function modifier.updateFunc(isActive)
		if isActive then
			self.mask = bit32.bor(self.mask, modifier.bitflag)
		else
			self.mask = bit32.band(self.mask, bit32.bnot(modifier.bitflag))
		end
	end
	table.insert(self.modifiers, modifier)
	self.nameToModifier[name] = modifier
	return modifier.updateFunc
end
function ConditionFlags:setModifierValue(modifierName, value)
	local name = string.upper(modifierName)
	local modifier = self.nameToModifier[name]
	if modifier ~= nil then
		modifier.updateFunc(value)
	end
end
function ConditionFlags:getMask()
	return self.mask
end
function ConditionFlags:drawDebug(posX, posY)
	setTextColor(1, 1, 1, 1)
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_CENTER)
	renderText(posX, posY, getCorrectTextSize(0.014), "Modifiers:")
	setTextBold(false)
	local textSize = getCorrectTextSize(0.012)
	local textOffset = getCorrectTextSize(0.001)
	posY = posY - 0.02
	for _, modifier in ipairs(self.modifiers) do
		local isActive = bit32.band(self.mask, modifier.bitflag) ~= 0
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(posX, posY, textSize, modifier.xmlAttributeName .. ":  ")
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(posX, posY, textSize, tostring(isActive))
		posY = posY - textSize - textOffset
	end
	return posY
end
