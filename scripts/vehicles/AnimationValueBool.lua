-- Local values: AnimationValueBool_mt
AnimationValueBool = {}
local AnimationValueBool_mt = Class(AnimationValueBool, AnimationValueFloat)

-- Upvalues: AnimationValueBool_mt
function AnimationValueBool.new(vehicle, animation, part, startName, endName, name, initialUpdate, get, set, extraLoad, customMt)
	-- upvalues: (copy) AnimationValueBool_mt
	return AnimationValueFloat.new(vehicle, animation, part, startName, endName, name, initialUpdate, get, set, extraLoad, customMt or AnimationValueBool_mt)
end

function AnimationValueBool:load(xmlFile, key)
	self.value = xmlFile:getValue(key .. "#" .. self.startName)
	self.warningInfo = key
	self.xmlFile = xmlFile
	local v16_
	if self.value == nil then
		v16_ = false
	else
		v16_ = self:extraLoad(xmlFile, key)
	end
	return v16_
end

function AnimationValueBool:init(index, numParts) end

function AnimationValueBool:postInit() end

function AnimationValueBool:reset()
	self.curValue = nil
end

function AnimationValueBool:update(durationToEnd, dtToUse, realDt)
	if self.curValue == nil then
		self.curValue = self:get()
	end
	if self.value == self.curValue then
		return false
	end
	self.curValue = self.value
	self:set(self.value)
	return true
end
