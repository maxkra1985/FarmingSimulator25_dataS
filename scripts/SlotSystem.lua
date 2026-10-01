SlotSystem = {}
SlotSystem.TOTAL_VRAM_MEGABYTES = { [PlatformId.WIN] = math.huge, [PlatformId.MAC] = math.huge, [PlatformId.PS5] = 3500, [PlatformId.XBOX_SERIES] = 3500, [PlatformId.IOS] = 640, [PlatformId.ANDROID] = 640, [PlatformId.SWITCH] = 640, [PlatformId.SWITCH2] = 2000 }
SlotSystem.VRAM_MEGABYTES_PER_SLOT = { [PlatformId.WIN] = 1, [PlatformId.MAC] = 1, [PlatformId.PS5] = 1, [PlatformId.XBOX_SERIES] = 1, [PlatformId.IOS] = 0.5, [PlatformId.ANDROID] = 0.5, [PlatformId.SWITCH] = 0.5, [PlatformId.SWITCH2] = 1 }
SlotSystem.VISIBILITY_THRESHOLD = 10000
SlotSystem.CRITICAL_FACTOR = 0.9
SlotSystem.TOTAL_NUM_GARAGE_SLOTS = {}
for platformId, vram in pairs(SlotSystem.TOTAL_VRAM_MEGABYTES) do
	SlotSystem.TOTAL_NUM_GARAGE_SLOTS[platformId] = math.floor(vram / SlotSystem.VRAM_MEGABYTES_PER_SLOT[platformId])
end
SlotSystem.LIMITED_OBJECT_BALE = 1
SlotSystem.LIMITED_OBJECT_PALLET = 2
SlotSystem.NUM_OBJECT_LIMITS = { [SlotSystem.LIMITED_OBJECT_BALE] = { [PlatformId.WIN] = math.huge, [PlatformId.MAC] = math.huge, [PlatformId.PS5] = 200, [PlatformId.XBOX_SERIES] = 200, [PlatformId.IOS] = 100, [PlatformId.ANDROID] = 100, [PlatformId.SWITCH] = 100, [PlatformId.SWITCH2] = 100 }, [SlotSystem.LIMITED_OBJECT_PALLET] = { [PlatformId.WIN] = 300, [PlatformId.MAC] = 300, [PlatformId.PS5] = 150, [PlatformId.XBOX_SERIES] = 150, [PlatformId.IOS] = 50, [PlatformId.ANDROID] = 50, [PlatformId.SWITCH] = 50, [PlatformId.SWITCH2] = 50 } }
local SlotSystem_mt = Class(SlotSystem)
function SlotSystem.new(mission, isServer, customMt)
	local self = setmetatable({}, customMt or SlotSystem_mt)
	self.mission = mission
	self.isServer = isServer
	self.slotUsage = 0
	self.slotLimit = SlotSystem.TOTAL_NUM_GARAGE_SLOTS[getPlatformId()]
	self.vramPerSlot = SlotSystem.VRAM_MEGABYTES_PER_SLOT[getPlatformId()] * 1024 * 1024
	if isServer then
		self.objectLimits = {}
		for k, limits in pairs(SlotSystem.NUM_OBJECT_LIMITS) do
			self.objectLimits[k] = { objects = {}, limit = limits[getPlatformId()] }
		end
	end
	return self
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
function SlotSystem:updateSlotUsage()
	local mapVRAMUsage = self.mission.vertexBufferMemoryUsage + self.mission.indexBufferMemoryUsage + self.mission.textureMemoryUsage
	self.slotUsage = math.ceil(mapVRAMUsage / self.vramPerSlot)
	for storeItem, item in pairs(self.mission.ownedItems) do
		if 0 < item.numItems then
			if storeItem.ignoreVramUsage then
				continue
			end
			local baseSlots = self:getStoreItemSlotUsage(storeItem, true)
			local sharedSlots = self:getStoreItemSlotUsage(storeItem, false) * (item.numItems - 1)
			self.slotUsage = self.slotUsage + baseSlots + sharedSlots
		end
	end
	for storeItem, item in pairs(self.mission.leasedItems) do
		if 0 < item.numItems then
			if storeItem.ignoreVramUsage then
				continue
			end
			self.slotUsage = self.slotUsage + self:getStoreItemSlotUsage(storeItem, true) + self:getStoreItemSlotUsage(storeItem, false) * (item.numItems - 1)
		end
	end
	g_shopMenu:onSlotUsageChanged(self.slotUsage, self.slotLimit)
	g_shopConfigScreen:onSlotUsageChanged(self.slotUsage, self.slotLimit)
	g_messageCenter:publish(MessageType.SLOT_USAGE_CHANGED, self.slotUsage, self.slotLimit)
end
function SlotSystem:updateSlotLimit()
	local slots = SlotSystem.TOTAL_NUM_GARAGE_SLOTS[getPlatformId()]
	for _, user in ipairs(self.mission.userManager:getUsers()) do
		local userSlotLimit = SlotSystem.TOTAL_NUM_GARAGE_SLOTS[user:getPlatformId()]
		if userSlotLimit == nil then
			continue
		end
		slots = math.min(slots, userSlotLimit)
	end
	self:setSlotLimit(slots)
end
function SlotSystem:setSlotLimit(slotLimit)
	local changed = false
	if slotLimit ~= self.slotLimit then
		local text = g_i18n:getText("ingameNotification_crossPlaySlotLimitInactive")
		local notificationType = FSBaseMission.INGAME_NOTIFICATION_OK
		if slotLimit < math.huge then
			text = string.format(g_i18n:getText("ingameNotification_crossPlayNewSlotLimit"), slotLimit)
			notificationType = FSBaseMission.INGAME_NOTIFICATION_CRITICAL
		end
		self.mission:addIngameNotification(notificationType, text)
		self.slotLimit = slotLimit
		if g_server ~= nil then
			g_server:broadcastEvent(SlotSystemUpdateEvent.new(slotLimit))
		end
		changed = true
	end
	g_shopMenu:onSlotUsageChanged(self.slotUsage, slotLimit)
	g_messageCenter:publish(MessageType.SLOT_USAGE_CHANGED, self.slotUsage, self.slotLimit)
	return changed
end
function SlotSystem:hasEnoughSlots(storeItem)
	if storeItem.ignoreVramUsage then
		return true
	else
		local slotUsage = self:getStoreItemSlotUsage(storeItem, self.mission:getNumOfItems(storeItem) == 0)
		return self.slotUsage + slotUsage <= self.slotLimit
	end
end
function SlotSystem:getAreSlotsVisible()
	if self.slotLimit < SlotSystem.VISIBILITY_THRESHOLD then
		return true
	elseif self.slotLimit * SlotSystem.CRITICAL_FACTOR <= self.slotUsage then
		return true
	else
		return false
	end
end
function SlotSystem:getStoreItemSlotUsage(storeItem, includeShared)
	if storeItem == nil or StoreItemUtil.getIsAnimal(storeItem) or StoreItemUtil.getIsObject(storeItem) then
		return 0
	end
	local vramUsage = nil
	vramUsage = includeShared and storeItem.perInstanceVramUsage + storeItem.sharedVramUsage * 1.2 or math.max(storeItem.perInstanceVramUsage, storeItem.sharedVramUsage * 0.05)
	return math.max(math.ceil(vramUsage / self.vramPerSlot), 1)
end
function SlotSystem:getCanConnect(uniqueUserId, platformId)
	local platformSlots = SlotSystem.TOTAL_NUM_GARAGE_SLOTS[platformId]
	return platformSlots == nil or self.slotUsage <= platformSlots
end
function SlotSystem:addLimitedObject(objectType, object)
	if not self.isServer then
		return
	end
	local objectData = self.objectLimits[objectType]
	if objectData == nil then
		return
	else
		table.addElement(objectData.objects, object)
	end
end
function SlotSystem:removeLimitedObject(objectType, object)
	if not self.isServer then
		return
	end
	local objectData = self.objectLimits[objectType]
	if objectData == nil then
		return
	else
		table.removeElement(objectData.objects, object)
	end
end
function SlotSystem:getCanAddLimitedObjects(objectType, numObjects)
	if not self.isServer then
		return true
	end
	local objectData = self.objectLimits[objectType]
	if objectData == nil then
		return false
	else
		local numObjectsNew = #objectData.objects + (numObjects or 1)
		return numObjectsNew <= objectData.limit
	end
end
