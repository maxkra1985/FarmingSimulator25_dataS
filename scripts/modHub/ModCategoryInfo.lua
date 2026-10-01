ModCategoryInfo = {}
local ModCategoryInfo_mt = Class(ModCategoryInfo)
function ModCategoryInfo.new(id, label, iconFilename, name, isHidden)
	local self = setmetatable({}, ModCategoryInfo_mt)
	self.id = id
	self.label = label
	self.iconFilename = iconFilename
	self.name = name
	self.isHidden = isHidden
	self.numAvailableUpdates = 0
	self.numNewItems = 0
	self.numConflictedItems = 0
	return self
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
function ModCategoryInfo:getNumMods()
	if self.id == ModHubController.CATEGORY_ID_TESTING then
		local numItems = 0
		for _, modInfo in pairs(g_modHubController.modIdToInfo) do
			if modInfo:getIsTesting() then
				numItems = numItems + 1
			end
		end
		return numItems
	else
		return getNumOfMods(self.id - 1)
	end
end
function ModCategoryInfo:updateInfo(id, label, iconFilename, name, isHidden)
	self.id = id
	self.label = label
	self.iconFilename = iconFilename
	self.name = name
	self.isHidden = isHidden
end
