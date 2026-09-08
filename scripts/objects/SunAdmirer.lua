-- Local values: SunAdmirer_mt
SunAdmirer = {}
local SunAdmirer_mt = Class(SunAdmirer)

function SunAdmirer:onCreate(id)
	g_currentMission:addNonUpdateable(SunAdmirer.new(id))
end

-- Upvalues: SunAdmirer_mt
-- Local values: self
function SunAdmirer.new(id)
	-- upvalues: (copy) SunAdmirer_mt
	local v4_ = SunAdmirer_mt
	local v5_ = setmetatable({}, v4_)
	v5_.id = id
	v5_.switchCollision = Utils.getNoNil(getUserAttribute(id, "switchCollision"), false)
	if v5_.switchCollision then
		v5_.collisionMask = getCollisionFilterMask(id)
	end
	v5_:setVisibility(true)
	g_messageCenter:subscribe(MessageType.DAY_NIGHT_CHANGED, v5_.onWeatherChanged, v5_)
	return v5_
end

function SunAdmirer:delete()
	g_messageCenter:unsubscribeAll(self)
end

function SunAdmirer:setVisibility(visible)
	setVisibility(self.id, visible)
	if self.switchCollision then
		setCollisionFilterMask(self.id, visible and self.collisionMask or 0)
	end
end

function SunAdmirer:onWeatherChanged()
	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		local v10_ = g_currentMission.environment.isSunOn
		if v10_ then
			v10_ = not g_currentMission.environment.weather:getIsRaining()
		end
		self:setVisibility(v10_)
	end
end
