-- Local values: ConditionFlags_mt
ConditionFlags = {}
local ConditionFlags_mt = Class(ConditionFlags)

-- Local values: preventKey, requiredKey, prevent, required
function ConditionFlags.loadFlagFromXML(xmlFile, key, modifier, requiredFlags, preventFlags)
	local v7_ = string.format("%s.prevent#%s", key, modifier.xmlAttributeName)
	local v8_ = string.format("%s.required#%s", key, modifier.xmlAttributeName)
	if xmlFile:getBool(v7_) then
		local v9_ = modifier.bitflag
		preventFlags = bit32.bor(preventFlags, v9_)
	end
	if xmlFile:getBool(v8_) then
		local v10_ = modifier.bitflag
		requiredFlags = bit32.bor(requiredFlags, v10_)
	end
	return requiredFlags, preventFlags
end

-- Upvalues: ConditionFlags_mt
-- Local values: self
function ConditionFlags.new(customMt)
	-- upvalues: (copy) ConditionFlags_mt
	local v12_ = customMt or ConditionFlags_mt
	local v13_ = setmetatable({}, v12_)
	v13_.modifiers = {}
	v13_.nameToModifier = {}
	v13_.mask = 0
	return v13_
end

function ConditionFlags:delete() end

-- Local values: requiredFlags, preventFlags, _, modifier, _, modifier, lineNumber
function ConditionFlags:loadFlagsFromXMLFile(xmlFile, key)
	local v17_ = 0
	local v18_ = 0
	if xmlFile:getNumOfElements(string.format("%s.prevent", key)) > 1 then
		Logging.xmlWarning(xmlFile, "More than one \'prevent\' element defined for \'%s\'", key)
	end
	if xmlFile:getNumOfElements(string.format("%s.required", key)) > 1 then
		Logging.xmlWarning(xmlFile, "More than one \'required\' element defined for \'%s\'", key)
	end
	for _, v19_ in ipairs(self.modifiers) do
		v17_, v18_ = v19_.loadFromXMLFunc(xmlFile, key, v19_, v17_, v18_)
	end
	if bit32.band(v17_, v18_) ~= 0 then
		for _, v20_ in ipairs(self.modifiers) do
			local v21_ = v20_.bitflag
			if bit32.band(v17_, v21_) ~= 0 then
				local v22_ = v20_.bitflag
				if bit32.band(v18_, v22_) ~= 0 then
					local v23_ = xmlFile:getLineNumber(key .. ".prevent#" .. v20_.xmlAttributeName)
					Logging.xmlWarning(xmlFile, "Modifier \'%s\' is set for prevent and required in \'%s\' (line %d)", v20_.xmlAttributeName, key, v23_)
				end
			end
		end
	end
	return v17_, v18_
end

-- Local values: _, modifier, attributeName
function ConditionFlags:registerXMLPaths(xmlSchema, basePath)
	for _, v27_ in ipairs(self.modifiers) do
		if not v27_.hasCustomLoadFunction then
			local v28_ = v27_.xmlAttributeName
			xmlSchema:register(XMLValueType.BOOL, basePath .. ".prevent#" .. v28_, "Prevent flag " .. v28_)
			xmlSchema:register(XMLValueType.BOOL, basePath .. ".required#" .. v28_, "Required flag " .. v28_)
		end
	end
end

-- Local values: name, _, modifier, modifier
function ConditionFlags:registerModifier(xmlAttributeName, loadFromXMLFunc)
	local v32_ = string.upper(xmlAttributeName)
	for _, v33_ in ipairs(self.modifiers) do
		if v33_.xmlAttributeName == xmlAttributeName then
			Logging.warning("Given ConditionFlags modifier xml attribute name \'%s\' already used", xmlAttributeName)
			return v33_.updateFunc
		end
	end
	local v_u_42_ = {
		["name"] = v32_,
		["xmlAttributeName"] = xmlAttributeName,
		["hasCustomLoadFunction"] = loadFromXMLFunc ~= nil,
		["bitflag"] = 2 ^ (#self.modifiers + 1),
		["loadFromXMLFunc"] = loadFromXMLFunc or ConditionFlags.loadFlagFromXML,
		["updateFunc"] = function(p34_)
			-- upvalues: (copy) self, (copy) v_u_42_
			if p34_ then
				local v35_ = self
				local v36_ = self.mask
				local v37_ = v_u_42_.bitflag
				v35_.mask = bit32.bor(v36_, v37_)
			else
				local v38_ = self
				local v39_ = self.mask
				local v40_ = v_u_42_.bitflag
				local v41_ = bit32.bnot(v40_)
				v38_.mask = bit32.band(v39_, v41_)
			end
		end
	}
	local v43_ = self.modifiers
	table.insert(v43_, v_u_42_)
	self.nameToModifier[v32_] = v_u_42_
	return v_u_42_.updateFunc
end

-- Local values: name, modifier
function ConditionFlags:setModifierValue(modifierName, value)
	local v47_ = string.upper(modifierName)
	local v48_ = self.nameToModifier[v47_]
	if v48_ ~= nil then
		v48_.updateFunc(value)
	end
end

function ConditionFlags:getMask()
	return self.mask
end

-- Local values: textSize, textOffset, _, modifier, isActive
function ConditionFlags:drawDebug(posX, posY)
	setTextColor(1, 1, 1, 1)
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_CENTER)
	renderText(posX, posY, getCorrectTextSize(0.014), "Modifiers:")
	setTextBold(false)
	local v53_ = getCorrectTextSize(0.012)
	local v54_ = getCorrectTextSize(0.001)
	local v55_ = posY - 0.02
	for _, v56_ in ipairs(self.modifiers) do
		local v57_ = self.mask
		local v58_ = v56_.bitflag
		local v59_ = bit32.band(v57_, v58_) ~= 0
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(posX, v55_, v53_, v56_.xmlAttributeName .. ":  ")
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(posX, v55_, v53_, (tostring(v59_)))
		v55_ = v55_ - v53_ - v54_
	end
	return v55_
end
