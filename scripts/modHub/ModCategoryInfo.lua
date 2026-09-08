-- Local values: ModCategoryInfo_mt
ModCategoryInfo = {}
local ModCategoryInfo_mt = Class(ModCategoryInfo)

-- Upvalues: ModCategoryInfo_mt
-- Local values: self
function ModCategoryInfo.new(id, label, iconFilename, name, isHidden)
	-- upvalues: (copy) ModCategoryInfo_mt
	local v7_ = ModCategoryInfo_mt
	local v8_ = setmetatable({}, v7_)
	v8_.id = id
	v8_.label = label
	v8_.iconFilename = iconFilename
	v8_.name = name
	v8_.isHidden = isHidden
	v8_.numAvailableUpdates = 0
	v8_.numNewItems = 0
	v8_.numConflictedItems = 0
	return v8_
end

function ModCategoryInfo:setNumAvailableUpdates(numAvailableUpdates)
	self.numAvailableUpdates = numAvailableUpdates
end

function ModCategoryInfo:setNumNewItems(numNewItems)
	self.numNewItems = numNewItems
end

function ModCategoryInfo:setNumConflictedItems(numConflictedItems)
	self.numConflictedItems = numConflictedItems
end

-- Local values: numItems, _, modInfo
function ModCategoryInfo:getNumMods()
	if self.id ~= ModHubController.CATEGORY_ID_TESTING then
		return getNumOfMods(self.id - 1)
	end
	local v16_ = 0
	for _, v17_ in pairs(g_modHubController.modIdToInfo) do
		if v17_:getIsTesting() then
			v16_ = v16_ + 1
		end
	end
	return v16_
end

function ModCategoryInfo:updateInfo(id, label, iconFilename, name, isHidden)
	self.id = id
	self.label = label
	self.iconFilename = iconFilename
	self.name = name
	self.isHidden = isHidden
end
