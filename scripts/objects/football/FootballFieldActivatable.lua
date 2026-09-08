-- Local values: FootballFieldResetActivatable_mt
FootballFieldResetActivatable = {}
local FootballFieldResetActivatable_mt = Class(FootballFieldResetActivatable)

-- Upvalues: FootballFieldResetActivatable_mt
-- Local values: self
function FootballFieldResetActivatable.new(footballField)
	-- upvalues: (copy) FootballFieldResetActivatable_mt
	local v3_ = FootballFieldResetActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.footballField = footballField
	v4_.activateText = g_i18n:getText("action_resetFootballField")
	return v4_
end

function FootballFieldResetActivatable:getIsActivatable()
	return true
end

function FootballFieldResetActivatable:run()
	self.footballField:reset()
end

-- Local values: tx, ty, tz
function FootballFieldResetActivatable:getDistance(x, y, z)
	if self.footballField.resetTriggerNode == nil then
		return math.huge
	end
	local v10_, v11_, v12_ = getWorldTranslation(self.footballField.resetTriggerNode)
	return MathUtil.vector3Length(x - v10_, y - v11_, z - v12_)
end
