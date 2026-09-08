-- Local values: TensionBeltManager_mt
TensionBeltManager = {}
local TensionBeltManager_mt = Class(TensionBeltManager)

-- Upvalues: TensionBeltManager_mt
-- Local values: self
function TensionBeltManager.new(customMt)
	-- upvalues: (copy) TensionBeltManager_mt
	local v3_ = customMt or TensionBeltManager_mt
	local v4_ = setmetatable({}, v3_)
	v4_:initDataStructures()
	return v4_
end

function TensionBeltManager:initDataStructures()
	self.belts = {}
	self.defaultBeltData = nil
end

function TensionBeltManager:unloadMapData()
	self:initDataStructures()
end

-- Local values: self, name, width, beltType, belt, i, node, _, _, z, _, _, z, _, _, z
function TensionBeltManager.onCreateTensionBelt(_, id)
	local v8_ = g_tensionBeltManager
	local v9_ = Utils.getNoNil(getUserAttribute(id, "name"), "default")
	local v10_ = Utils.getNoNil(getUserAttribute(id, "width"), 0.15)
	local v11_ = v8_:getType(v9_)
	if v8_.belts[v11_] == nil then
		local v12_ = {
			["width"] = v10_
		}
		for v13_ = 0, getNumOfChildren(id) - 1 do
			local v14_ = getChildAt(id, v13_)
			if getUserAttribute(v14_, "isMaterial") then
				v12_.material = {
					["materialId"] = getMaterial(v14_, 0),
					["uvScale"] = Utils.getNoNil(getUserAttribute(v14_, "uvScale"), 0.1)
				}
			elseif getUserAttribute(v14_, "isDummyMaterial") then
				v12_.dummyMaterial = {
					["materialId"] = getMaterial(v14_, 0),
					["uvScale"] = Utils.getNoNil(getUserAttribute(v14_, "uvScale"), 0.1)
				}
			elseif getUserAttribute(v14_, "isHook") then
				if v12_.hook == nil then
					local _, _, v15_ = getTranslation(getChildAt(v14_, 0))
					v12_.hook = {
						["node"] = v14_,
						["sizeRatio"] = v15_
					}
				else
					local _, _, v16_ = getTranslation(getChildAt(v14_, 0))
					v12_.hook2 = {
						["node"] = v14_,
						["sizeRatio"] = v16_
					}
				end
			elseif getUserAttribute(v14_, "isRatchet") then
				local _, _, v17_ = getTranslation(getChildAt(v14_, 0))
				v12_.ratchet = {
					["node"] = v14_,
					["sizeRatio"] = v17_
				}
			end
		end
		if v12_.material == nil then
			printWarning("Warning: No material defined for tension belt type \'" .. v9_ .. "\'!")
			return
		elseif v12_.dummyMaterial == nil then
			printWarning("Warning: No material defined for tension belt type \'" .. v9_ .. "\'!")
		else
			v8_.belts[v11_] = v12_
			if v8_.defaultBeltData == nil then
				v8_.defaultBeltData = v12_
			end
		end
	else
		printWarning("Warning: Tension belt type \'" .. v9_ .. "\' already exists!")
		return
	end
end

function TensionBeltManager:getType(beltName)
	return "BELT_TYPE_" .. string.upper(beltName)
end

-- Local values: beltType, beltData
function TensionBeltManager:getBeltData(beltName)
	if beltName == nil then
		return self.defaultBeltData
	else
		local v21_ = self:getType(beltName)
		local v22_ = self.belts[v21_]
		if v22_ == nil then
			return self.defaultBeltData
		else
			return v22_
		end
	end
end
g_tensionBeltManager = TensionBeltManager.new()
