-- Local values: modName, additionals, additionalsSpec, globalSpec, oldFinalizeTypes
local v_u_1_ = g_currentModName
local v_u_2_ = {}
local v_u_3_ = {
	["sprayer"] = {
		v_u_1_ .. ".extendedSprayer",
		v_u_1_ .. ".extendedSprayerEffects",
		v_u_1_ .. ".manureSensor",
		v_u_1_ .. ".weedSpotSpray"
	},
	["sowingMachine"] = { v_u_1_ .. ".extendedSowingMachine" },
	["motorized"] = { v_u_1_ .. ".extendedMotorized", v_u_1_ .. ".cropSensor" },
	["wearable"] = { v_u_1_ .. ".extendedWearable" },
	["combine"] = { v_u_1_ .. ".extendedCombine" },
	["mower"] = { v_u_1_ .. ".extendedMower" }
}
local v_u_4_ = { v_u_1_ .. ".precisionFarmingStatistic" }
local v_u_5_ = TypeManager.finalizeTypes
function TypeManager.finalizeTypes(p6_, ...)
	-- upvalues: (copy) v_u_1_, (copy) v_u_4_, (copy) v_u_3_, (copy) v_u_2_, (copy) v_u_5_
	if p6_.typeName == "vehicle" and g_modIsLoaded[v_u_1_] then
		for v7_, v8_ in pairs(p6_:getTypes()) do
			for _, v9_ in pairs(v_u_4_) do
				if v8_.specializationsByName[v9_] == nil then
					p6_:addSpecialization(v7_, v9_)
				end
			end
			for v10_ = #v8_.specializationNames, 1, -1 do
				local v11_ = v8_.specializationNames[v10_]
				for v12_, v13_ in pairs(v_u_3_) do
					if v11_ == v12_ then
						for v14_ = 1, #v13_ do
							if v8_.specializationsByName[v13_[v14_]] == nil then
								p6_:addSpecialization(v7_, v13_[v14_])
							end
						end
					end
				end
			end
			for v15_, v16_ in pairs(v_u_2_) do
				if v7_ == v15_ then
					for v17_ = 1, #v16_ do
						if v8_.specializationsByName[v16_[v17_]] == nil then
							p6_:addSpecialization(v7_, v16_[v17_])
						end
					end
				end
			end
		end
	end
	v_u_5_(p6_, ...)
end
