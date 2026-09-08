-- Local values: AnimalItemStock_mt
AnimalItemStock = {}
local AnimalItemStock_mt = Class(AnimalItemStock)

-- Upvalues: AnimalItemStock_mt
-- Local values: self, subType
function AnimalItemStock.new(cluster)
	-- upvalues: (copy) AnimalItemStock_mt
	local v3_ = AnimalItemStock_mt
	local v4_ = setmetatable({}, v3_)
	v4_.cluster = cluster
	v4_.visual = g_currentMission.animalSystem:getVisualByAge(cluster.subTypeIndex, cluster:getAge())
	local v5_ = g_currentMission.animalSystem:getSubTypeByIndex(cluster.subTypeIndex)
	v4_.title = g_fillTypeManager:getFillTypeTitleByIndex(v5_.fillTypeIndex)
	v4_.infos = {
		{
			["title"] = g_i18n:getText("ui_age"),
			["value"] = g_i18n:formatNumMonth(cluster:getAge())
		},
		{
			["title"] = g_i18n:getText("ui_horseHealth"),
			["value"] = string.format("%.f%%", cluster:getHealthFactor() * 100)
		}
	}
	if v5_.supportsReproduction then
		local v6_ = v4_.infos
		local v7_ = {
			["title"] = g_i18n:getText("infohud_reproductionStatus"),
			["value"] = string.format("%.f%%", cluster:getReproductionFactor() * 100)
		}
		table.insert(v6_, v7_)
	end
	if cluster.getFitnessFactor ~= nil then
		local v8_ = v4_.infos
		local v9_ = {
			["title"] = g_i18n:getText("ui_horseFitness"),
			["value"] = string.format("%.f%%", cluster:getFitnessFactor() * 100)
		}
		table.insert(v8_, v9_)
	end
	if cluster.getRidingFactor ~= nil then
		local v10_ = v4_.infos
		local v11_ = {
			["title"] = g_i18n:getText("ui_horseDailyRiding"),
			["value"] = string.format("%.f%%", cluster:getRidingFactor() * 100)
		}
		table.insert(v10_, v11_)
	end
	if Platform.gameplay.needHorseCleaning and cluster.getDirtFactor ~= nil then
		local v12_ = v4_.infos
		local v13_ = {
			["title"] = g_i18n:getText("statistic_cleanliness"),
			["value"] = string.format("%.f%%", (1 - cluster:getDirtFactor()) * 100)
		}
		table.insert(v12_, v13_)
	end
	return v4_
end

function AnimalItemStock:getName()
	if self.cluster.getName == nil then
		return g_i18n:formatNumMonth(self.cluster:getAge())
	else
		return self.cluster:getName()
	end
end

function AnimalItemStock:getTitle()
	return self.title
end

function AnimalItemStock:getPrice()
	return self.cluster:getSellPrice()
end

function AnimalItemStock:getTranportationFee(numItems)
	return self.cluster:getTranportationFee(numItems)
end

function AnimalItemStock:getDescription()
	return self.visual.store.description
end

function AnimalItemStock:getFilename()
	return self.visual.store.imageFilename
end

function AnimalItemStock:getSubTypeIndex()
	return self.cluster:getSubTypeIndex()
end

function AnimalItemStock:getInfos()
	return self.infos
end

function AnimalItemStock:getNumAnimals()
	return self.cluster:getNumAnimals()
end

function AnimalItemStock:getClusterId()
	return self.cluster.id
end

function AnimalItemStock:getCluster()
	return self.cluster
end

function AnimalItemStock:getCanBeSold()
	return self.cluster:getCanBeSold()
end
