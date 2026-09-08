-- Local values: AnimalItemNew_mt
AnimalItemNew = {}
local AnimalItemNew_mt = Class(AnimalItemNew)

-- Upvalues: AnimalItemNew_mt
-- Local values: self, subType
function AnimalItemNew.new(subTypeIndex, age)
	-- upvalues: (copy) AnimalItemNew_mt
	local v4_ = AnimalItemNew_mt
	local v5_ = setmetatable({}, v4_)
	v5_.subTypeIndex = subTypeIndex
	v5_.age = age
	v5_.visual = g_currentMission.animalSystem:getVisualByAge(subTypeIndex, age)
	local v6_ = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
	v5_.title = g_fillTypeManager:getFillTypeTitleByIndex(v6_.fillTypeIndex)
	v5_.infos = {
		{
			["title"] = g_i18n:getText("ui_age"),
			["value"] = g_i18n:formatNumMonth(v5_.visual.minAge)
		}
	}
	if v6_.supportsReproduction then
		local v7_ = v5_.infos
		local v8_ = {
			["title"] = g_i18n:getText("infohud_reproductionDuration"),
			["value"] = g_i18n:formatNumMonth(v6_.reproductionDurationMonth)
		}
		table.insert(v7_, v8_)
		local v9_ = v5_.infos
		local v10_ = {
			["title"] = g_i18n:getText("infohud_reproductionMinAge"),
			["value"] = g_i18n:formatNumMonth(v6_.reproductionMinAgeMonth)
		}
		table.insert(v9_, v10_)
	end
	return v5_
end

function AnimalItemNew:getName()
	return g_i18n:formatNumMonth(self.age)
end

function AnimalItemNew:getTitle()
	return self.title
end

function AnimalItemNew:getPrice()
	return g_currentMission.animalSystem:getAnimalBuyPrice(self.subTypeIndex, self.age)
end

function AnimalItemNew:getTranportationFee(numItems)
	return g_currentMission.animalSystem:getAnimalTransportFee(self.subTypeIndex, self.age) * numItems
end

function AnimalItemNew:getSubTypeIndex()
	return self.subTypeIndex
end

function AnimalItemNew:getAge()
	return self.age
end

function AnimalItemNew:getDescription()
	return self.visual.store.description
end

function AnimalItemNew:getFilename()
	return self.visual.store.imageFilename
end

function AnimalItemNew:getInfos()
	return self.infos
end
