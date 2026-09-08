-- Local values: SimParticleSystem_mt
SimParticleSystem = {}
local SimParticleSystem_mt = Class(SimParticleSystem)

function SimParticleSystem:onCreate(id)
	g_currentMission:addNonUpdateable(SimParticleSystem.new(id))
end

-- Upvalues: SimParticleSystem_mt
-- Local values: self, particleSystem, geometry, lifespan
function SimParticleSystem.new(name)
	-- upvalues: (copy) SimParticleSystem_mt
	local v4_ = SimParticleSystem_mt
	local v5_ = setmetatable({}, v4_)
	v5_.id = name
	local v6_ = nil
	local v7_
	if getHasClassId(v5_.id, ClassIds.SHAPE) then
		v7_ = getGeometry(v5_.id)
		if v7_ == 0 then
			v7_ = v6_
		elseif not getHasClassId(v7_, ClassIds.PRECIPITATION) then
			v7_ = v6_
		end
	else
		v7_ = v6_
	end
	if v7_ ~= nil then
		local v8_ = getParticleSystemLifespan(v7_)
		addParticleSystemSimulationTime(v7_, v8_)
	end
	return v5_
end

function SimParticleSystem:delete() end
