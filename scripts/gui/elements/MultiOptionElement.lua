-- Local values: MultiOptionElement_mt
MultiOptionElement = {}
local MultiOptionElement_mt = Class(MultiOptionElement, MultiTextOptionElement)
Gui.registerGuiElement("MultiOption", MultiOptionElement)

-- Upvalues: MultiOptionElement_mt
-- Local values: self
function MultiOptionElement.new(target, custom_mt)
	-- upvalues: (copy) MultiOptionElement_mt
	local v4_ = MultiTextOptionElement.new(target, custom_mt or MultiOptionElement_mt)
	v4_.options = {}
	return v4_
end

function MultiOptionElement:loadFromXML(xmlFile, key)
	MultiOptionElement:superClass().loadFromXML(self, xmlFile, key)
end

function MultiOptionElement:loadProfile(profile, applyProfile)
	MultiOptionElement:superClass().loadProfile(self, profile, applyProfile)
end

function MultiOptionElement:copyAttributes(src)
	MultiOptionElement:superClass().copyAttributes(self, src)
end

function MultiOptionElement:setState(state, forceEvent)
	MultiOptionElement:superClass().setState(self, state, forceEvent)
end

function MultiOptionElement:getState()
	return self.state
end

function MultiOptionElement:setOptions(options)
	self.options = options or {}
	self:updateContents()
end

-- Local values: texts, _, option
function MultiOptionElement:updateContents()
	local v20_ = {}
	for _, v21_ in ipairs(self.options) do
		local v22_ = v21_.title
		table.insert(v20_, v22_)
	end
	self:setTexts(v20_)
	self:setDisabled(#self.options == 0)
end

-- Local values: option
function MultiOptionElement:raiseClickCallback(v)
	local v25_ = self.options[self.state]
	if v25_ ~= nil then
		self:raiseCallback("onClickCallback", v25_, self, v)
	end
end
