-- Local values: platformId, vram, SlotSystem_mt
SlotSystem = {}
SlotSystem.TOTAL_VRAM_MEGABYTES = {
	[PlatformId.WIN] = math.huge,
	[PlatformId.MAC] = math.huge,
	[PlatformId.PS5] = 3500,
	[PlatformId.XBOX_SERIES] = 3500,
	[PlatformId.IOS] = 640,
	[PlatformId.ANDROID] = 640,
	[PlatformId.SWITCH] = 640,
	[PlatformId.SWITCH2] = 2000
}
SlotSystem.VRAM_MEGABYTES_PER_SLOT = {
	[PlatformId.WIN] = 1,
	[PlatformId.MAC] = 1,
	[PlatformId.PS5] = 1,
	[PlatformId.XBOX_SERIES] = 1,
	[PlatformId.IOS] = 0.5,
	[PlatformId.ANDROID] = 0.5,
	[PlatformId.SWITCH] = 0.5,
	[PlatformId.SWITCH2] = 1
}
SlotSystem.VISIBILITY_THRESHOLD = 10000
SlotSystem.CRITICAL_FACTOR = 0.9
SlotSystem.TOTAL_NUM_GARAGE_SLOTS = {}
for v1_, v2_ in pairs(SlotSystem.TOTAL_VRAM_MEGABYTES) do
	local v3_ = SlotSystem.TOTAL_NUM_GARAGE_SLOTS
	local v4_ = v2_ / SlotSystem.VRAM_MEGABYTES_PER_SLOT[v1_]
	v3_[v1_] = math.floor(v4_)
end
SlotSystem.LIMITED_OBJECT_BALE = 1
SlotSystem.LIMITED_OBJECT_PALLET = 2
local v5_ = SlotSystem
local v6_ = {
	[SlotSystem.LIMITED_OBJECT_BALE] = {
		[PlatformId.WIN] = math.huge,
		[PlatformId.MAC] = math.huge,
		[PlatformId.PS5] = 200,
		[PlatformId.XBOX_SERIES] = 200,
		[PlatformId.IOS] = 100,
		[PlatformId.ANDROID] = 100,
		[PlatformId.SWITCH] = 100,
		[PlatformId.SWITCH2] = 100
	},
	[SlotSystem.LIMITED_OBJECT_PALLET] = {
		[PlatformId.WIN] = 300,
		[PlatformId.MAC] = 300,
		[PlatformId.PS5] = 150,
		[PlatformId.XBOX_SERIES] = 150,
		[PlatformId.IOS] = 50,
		[PlatformId.ANDROID] = 50,
		[PlatformId.SWITCH] = 50,
		[PlatformId.SWITCH2] = 50
	}
}
v5_.NUM_OBJECT_LIMITS = v6_
local platformId = Class(SlotSystem)

-- Upvalues: SlotSystem_mt
-- Local values: self, k, limits
function SlotSystem.new(mission, isServer, customMt)
	-- upvalues: (copy) platformId
	local v11_ = customMt or platformId
	local v12_ = setmetatable({}, v11_)
	v12_.mission = mission
	v12_.isServer = isServer
	v12_.slotUsage = 0
	v12_.slotLimit = SlotSystem.TOTAL_NUM_GARAGE_SLOTS[getPlatformId()]
	v12_.vramPerSlot = SlotSystem.VRAM_MEGABYTES_PER_SLOT[getPlatformId()] * 1024 * 1024
	if isServer then
		v12_.objectLimits = {}
		for v13_, v14_ in pairs(SlotSystem.NUM_OBJECT_LIMITS) do
			v12_.objectLimits[v13_] = {
				["objects"] = {},
				["limit"] = v14_[getPlatformId()]
			}
		end
	end
	return v12_
end

function SlotSystem:delete() end

function SlotSystem:loadMapData(xmlFile, missionInfo)
	self:updateSlotLimit()
	return true
end

function SlotSystem:saveToXMLFile(xmlFile, key)
	setXMLInt(xmlFile, key .. "#slotUsage", self.slotUsage)
end

function SlotSystem:getIsCountableObject(object)
	return object:isa(Vehicle) or object:isa(Placeable)
end

-- Local values: mapVRAMUsage, storeItem, item, baseSlots, sharedSlots, storeItem, item
function SlotSystem:updateSlotUsage()
	local v21_ = (self.mission.vertexBufferMemoryUsage + self.mission.indexBufferMemoryUsage + self.mission.textureMemoryUsage) / self.vramPerSlot
	self.slotUsage = math.ceil(v21_)
	for v22_, v23_ in pairs(self.mission.ownedItems) do
		if v23_.numItems > 0 and not v22_.ignoreVramUsage then
			local v24_ = self:getStoreItemSlotUsage(v22_, true)
			local v25_ = self:getStoreItemSlotUsage(v22_, false) * (v23_.numItems - 1)
			self.slotUsage = self.slotUsage + v24_ + v25_
		end
	end
	for v26_, v27_ in pairs(self.mission.leasedItems) do
		if v27_.numItems > 0 and not v26_.ignoreVramUsage then
			self.slotUsage = self.slotUsage + self:getStoreItemSlotUsage(v26_, true) + self:getStoreItemSlotUsage(v26_, false) * (v27_.numItems - 1)
		end
	end
	g_shopMenu:onSlotUsageChanged(self.slotUsage, self.slotLimit)
	g_shopConfigScreen:onSlotUsageChanged(self.slotUsage, self.slotLimit)
	g_messageCenter:publish(MessageType.SLOT_USAGE_CHANGED, self.slotUsage, self.slotLimit)
end

-- Local values: slots, _, user, userSlotLimit
function SlotSystem:updateSlotLimit()
	local v29_ = SlotSystem.TOTAL_NUM_GARAGE_SLOTS[getPlatformId()]
	for _, v30_ in ipairs(self.mission.userManager:getUsers()) do
		local v31_ = SlotSystem.TOTAL_NUM_GARAGE_SLOTS[v30_:getPlatformId()]
		if v31_ ~= nil then
			v29_ = math.min(v29_, v31_)
		end
	end
	self:setSlotLimit(v29_)
end

-- Local values: changed, text, notificationType
function SlotSystem:setSlotLimit(slotLimit)
	local v34_
	if slotLimit == self.slotLimit then
		v34_ = false
	else
		local v35_ = g_i18n:getText("ingameNotification_crossPlaySlotLimitInactive")
		local v36_ = FSBaseMission.INGAME_NOTIFICATION_OK
		if slotLimit < math.huge then
			v35_ = string.format(g_i18n:getText("ingameNotification_crossPlayNewSlotLimit"), slotLimit)
			v36_ = FSBaseMission.INGAME_NOTIFICATION_CRITICAL
		end
		self.mission:addIngameNotification(v36_, v35_)
		self.slotLimit = slotLimit
		if g_server == nil then
			v34_ = true
		else
			g_server:broadcastEvent(SlotSystemUpdateEvent.new(slotLimit))
			v34_ = true
		end
	end
	g_shopMenu:onSlotUsageChanged(self.slotUsage, slotLimit)
	g_messageCenter:publish(MessageType.SLOT_USAGE_CHANGED, self.slotUsage, self.slotLimit)
	return v34_
end

-- Local values: slotUsage
function SlotSystem:hasEnoughSlots(storeItem)
	if storeItem.ignoreVramUsage then
		return true
	end
	local v39_ = self:getStoreItemSlotUsage(storeItem, self.mission:getNumOfItems(storeItem) == 0)
	return self.slotLimit >= self.slotUsage + v39_
end

function SlotSystem:getAreSlotsVisible()
	return self.slotLimit < SlotSystem.VISIBILITY_THRESHOLD and true or self.slotUsage >= self.slotLimit * SlotSystem.CRITICAL_FACTOR
end

-- Local values: vramUsage
function SlotSystem:getStoreItemSlotUsage(storeItem, includeShared)
	if storeItem == nil or (StoreItemUtil.getIsAnimal(storeItem) or StoreItemUtil.getIsObject(storeItem)) then
		return 0
	end
	local v44_
	if includeShared then
		v44_ = storeItem.perInstanceVramUsage + storeItem.sharedVramUsage * 1.2
	else
		local v45_ = storeItem.perInstanceVramUsage
		local v46_ = storeItem.sharedVramUsage * 0.05
		v44_ = math.max(v45_, v46_)
	end
	local v47_ = v44_ / self.vramPerSlot
	local v48_ = math.ceil(v47_)
	return math.max(v48_, 1)
end

-- Local values: platformSlots
function SlotSystem:getCanConnect(uniqueUserId, platformId)
	local v51_ = SlotSystem.TOTAL_NUM_GARAGE_SLOTS[platformId]
	return v51_ == nil and true or self.slotUsage <= v51_
end

-- Local values: objectData
function SlotSystem:addLimitedObject(objectType, object)
	if self.isServer then
		local v55_ = self.objectLimits[objectType]
		if v55_ ~= nil then
			table.addElement(v55_.objects, object)
		end
	else
		return
	end
end

-- Local values: objectData
function SlotSystem:removeLimitedObject(objectType, object)
	if self.isServer then
		local v59_ = self.objectLimits[objectType]
		if v59_ ~= nil then
			table.removeElement(v59_.objects, object)
		end
	else
		return
	end
end

-- Local values: objectData, numObjectsNew
function SlotSystem:getCanAddLimitedObjects(objectType, numObjects)
	if self.isServer then
		local v63_ = self.objectLimits[objectType]
		if v63_ == nil then
			return false
		else
			return #v63_.objects + (numObjects or 1) <= v63_.limit
		end
	else
		return true
	end
end
