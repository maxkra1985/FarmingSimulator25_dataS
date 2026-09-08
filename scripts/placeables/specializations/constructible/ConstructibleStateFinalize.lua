-- Local values: ConstructibleStateFinalize_mt
ConstructibleStateFinalize = {}
local ConstructibleStateFinalize_mt = Class(ConstructibleStateFinalize, ConstructibleState)

function ConstructibleStateFinalize.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.L10N_STRING, basePath .. "#finalizeText")
	schema:register(XMLValueType.STRING, basePath .. ".extraContent#key")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".extraContent#text")
end

-- Upvalues: ConstructibleStateFinalize_mt
-- Local values: self
function ConstructibleStateFinalize.new(constructible, dirtyFlag, customMt)
	-- upvalues: (copy) ConstructibleStateFinalize_mt
	return ConstructibleState.new(constructible, dirtyFlag, customMt or ConstructibleStateFinalize_mt)
end

-- Local values: finalizeText, extraContentText
function ConstructibleStateFinalize:load(xmlFile, key)
	ConstructibleStateFinalize:superClass().load(self, xmlFile, key)
	local v10_ = xmlFile:getI18NValue(key .. "#finalizeText", nil, self.constructible.customEnvironment, false)
	if not string.isNilOrWhitespace(v10_) then
		self.finalizeText = v10_
	end
	self.extraContentKey = xmlFile:getString(key .. ".extraContent#key")
	local v11_ = xmlFile:getI18NValue(key .. ".extraContent#text", nil, self.constructible.customEnvironment, false)
	if not string.isNilOrWhitespace(v11_) then
		self.extraContentText = v11_
	end
end

-- Local values: item, errorCode, text
function ConstructibleStateFinalize:activate()
	ConstructibleStateFinalize:superClass().activate(self)
	if self.finalizeText ~= nil and self.extraContentText == nil then
		InfoDialog.show(g_i18n:getText(self.finalizeText))
	end
	if self.extraContentKey ~= nil then
		local v13_, v14_ = g_extraContentSystem:unlockItem(self.extraContentKey, false)
		if v13_ ~= nil and (v14_ == ExtraContentSystem.UNLOCKED and g_currentMission.gameStarted) then
			if self.extraContentText ~= nil then
				local v15_ = string.namedFormat(self.extraContentText, "contentName", v13_.title)
				InfoDialog.show(v15_)
			end
			Logging.info("ExtraContent: Unlock \'" .. v13_.id .. "\'")
		end
	end
end

function ConstructibleStateFinalize:isDone()
	return true
end

function ConstructibleStateFinalize:raiseActive()
	return true
end

function ConstructibleStateFinalize:deactivate()
	ConstructibleStateFinalize:superClass().deactivate(self)
	self.constructible:finalizeConstruction()
end
