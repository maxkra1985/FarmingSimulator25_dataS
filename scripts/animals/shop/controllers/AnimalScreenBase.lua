AnimalScreenBase = {}
AnimalScreenBase.ACTION_TYPE_NONE = 0
AnimalScreenBase.ACTION_TYPE_SOURCE = 1
AnimalScreenBase.ACTION_TYPE_TARGET = 2
local AnimalScreenBase_mt = Class(AnimalScreenBase)
function AnimalScreenBase.new(customMt)
	local self = setmetatable({}, customMt or AnimalScreenBase_mt)
	self.sourceItems = {}
	self.targetItems = {}
	self.sourceActionText = ""
	self.targetActionText = ""
	self.sourceTitle = ""
	self.targetTitle = ""
	return self
end
function AnimalScreenBase:reset()
	g_messageCenter:unsubscribe(AnimalClusterUpdateEvent, self)
end
function AnimalScreenBase:init()
	g_messageCenter:subscribe(AnimalClusterUpdateEvent, self.onAnimalsChanged, self)
	self:initItems()
end
function AnimalScreenBase:initItems()
	self:initSourceItems()
	self:initTargetItems()
	table.sort(self.targetItems, function(a, b)
		local clusterA = a.cluster
		local clusterB = b.cluster
		if clusterA.subTypeIndex ~= clusterB.subTypeIndex then
			return clusterA.subTypeIndex < clusterB.subTypeIndex
		elseif clusterA.age ~= clusterB.age then
			return clusterA.age < clusterB.age
		else
			if clusterA.name ~= clusterB.name then
				if clusterA.name == nil then
					return false
				elseif clusterB.name == nil then
					return true
				else
					return clusterA.name < clusterB.name
				end
			end
			return clusterA.id < clusterB.id
		end
	end)
end
function AnimalScreenBase:initSourceItems() end
function AnimalScreenBase:initTargetItems() end
function AnimalScreenBase:getSourceItems(animalTypeIndex)
	return self.sourceItems[animalTypeIndex] or {}
end
function AnimalScreenBase:getSourceData(id) end
function AnimalScreenBase:getSourceAnimalTypes() end
function AnimalScreenBase:getTargetItems()
	return self.targetItems
end
function AnimalScreenBase:getTargetData() end
function AnimalScreenBase:setAnimalsChangedCallback(callback, target)
	function self.animalsChangedCallback()
		callback(target)
	end
end
function AnimalScreenBase:setActionTypeCallback(callback, target)
	function self.actionTypeCallback(state)
		callback(target, state)
	end
end
function AnimalScreenBase:setErrorCallback(callback, target)
	function self.errorCallback(text)
		callback(target, text)
	end
end
function AnimalScreenBase:setSourceActionFinishedCallback(callback, target)
	function self.sourceActionFinished(isWarning, text)
		callback(target, isWarning, text)
	end
end
function AnimalScreenBase:setTargetActionFinishedCallback(callback, target)
	function self.targetActionFinished(isWarning, text)
		callback(target, isWarning, text)
	end
end
function AnimalScreenBase:onAnimalsChanged() end
function AnimalScreenBase:onAnimalBuyError(errorCode) end
function AnimalScreenBase:getMaxNumAnimals()
	return 250
end
function AnimalScreenBase:getSourceActionText()
	return self.sourceActionText
end
function AnimalScreenBase:getTargetActionText()
	return self.targetActionText
end
function AnimalScreenBase:getSourceName()
	return self.sourceTitle
end
function AnimalScreenBase:getTargetName()
	return self.targetTitle
end
function AnimalScreenBase:getSourceMaxNumAnimals(animalTypeIndex, itemIndex)
	return 0
end
function AnimalScreenBase:getTargetMaxNumAnimals(itemIndex)
	return 0
end
function AnimalScreenBase:setCurrentHusbandry(animalTypeIndex, husbandryIndex) end
