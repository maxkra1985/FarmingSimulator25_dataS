-- Local values: DoghouseActivatable_mt
DoghouseActivatable = {}
local DoghouseActivatable_mt = Class(DoghouseActivatable)

-- Upvalues: DoghouseActivatable_mt
-- Local values: self
function DoghouseActivatable.new(doghousePlaceable)
	-- upvalues: (copy) DoghouseActivatable_mt
	local v3_ = DoghouseActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.doghousePlaceable = doghousePlaceable
	v4_.activateText = g_i18n:getText("action_doghouseFillbowl")
	return v4_
end

function DoghouseActivatable:run()
	self.doghousePlaceable:setFoodBowlState(true)
end

-- Local values: dog, name
function DoghouseActivatable:draw()
	local v7_ = self.doghousePlaceable:getDog()
	local v8_ = v7_ == nil and "" or v7_.name
	g_currentMission:showFillDogBowlContext(v8_)
end

function DoghouseActivatable:activate()
	g_currentMission:addDrawable(self)
end

function DoghouseActivatable:deactivate()
	g_currentMission:removeDrawable(self)
end
