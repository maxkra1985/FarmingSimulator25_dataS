-- Local values: EnvironmentAreaWeight_mt
EnvironmentAreaWeight = {}
local EnvironmentAreaWeight_mt = Class(EnvironmentAreaWeight)

-- Upvalues: EnvironmentAreaWeight_mt
-- Local values: self
function EnvironmentAreaWeight.new(mission, customMt)
	-- upvalues: (copy) EnvironmentAreaWeight_mt
	local v3_ = customMt or EnvironmentAreaWeight_mt
	local v4_ = setmetatable({}, v3_)
	v4_:reset()
	return v4_
end

-- Local values: _, areaTypeIndex
function EnvironmentAreaWeight:reset()
	self.isNearWallWeight = 0
	self.isNearWaterWeight = 0
	self.isUnderRoofWeight = 0
	self.isInForestWeight = 0
	self.areaTypeWeights = self.areaTypeWeights or {}
	for _, v6_ in pairs(AreaType.getAll()) do
		self.areaTypeWeights[v6_] = 0
	end
end

-- Local values: renderValue, areaTypeIndex, value
function EnvironmentAreaWeight:drawDebug(posX, posY, textSize)
	setTextBold(false)
	local function v13_(p11_, p12_)
		-- upvalues: (copy) posX, (ref) posY, (copy) textSize
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(posX, posY, textSize, p11_ .. " : ")
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(posX, posY, textSize, string.format("%.4f", p12_))
		posY = posY - textSize - 2 * g_pixelSizeY
	end
	for v14_, v15_ in pairs(self.areaTypeWeights) do
		v13_(AreaType.getName(v14_), v15_)
	end
	v13_("isNearWallWeight", self.isNearWallWeight)
	v13_("isNearWaterWeight", self.isNearWaterWeight)
	v13_("isUnderRoofWeight", self.isUnderRoofWeight)
	v13_("isInForestWeight", self.isInForestWeight)
	return posY
end
