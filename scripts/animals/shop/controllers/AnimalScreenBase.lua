-- Local values: AnimalScreenBase_mt
AnimalScreenBase = {}
AnimalScreenBase.ACTION_TYPE_NONE = 0
AnimalScreenBase.ACTION_TYPE_SOURCE = 1
AnimalScreenBase.ACTION_TYPE_TARGET = 2
local AnimalScreenBase_mt = Class(AnimalScreenBase)

-- Upvalues: AnimalScreenBase_mt
-- Local values: self
function AnimalScreenBase.new(customMt)
	-- upvalues: (copy) AnimalScreenBase_mt
	local v3_ = customMt or AnimalScreenBase_mt
	local v4_ = setmetatable({}, v3_)
	v4_.sourceItems = {}
	v4_.targetItems = {}
	v4_.sourceActionText = ""
	v4_.targetActionText = ""
	v4_.sourceTitle = ""
	v4_.targetTitle = ""
	return v4_
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
end

function AnimalScreenBase:initSourceItems() end

function AnimalScreenBase:initTargetItems() end

function AnimalScreenBase:getSourceItems(animalTypeIndex)
	return self.sourceItems[animalTypeIndex] or {}
end

function AnimalScreenBase:getSourceData(id) end

function AnimalScreenBase:getSourceAnimalTypes() end

function AnimalScreenBase:getTargetItems()
	table.sort(self.targetItems, function(p11_, p12_)
		if p11_.cluster.subTypeIndex == p12_.cluster.subTypeIndex then
			return p11_.cluster.age < p12_.cluster.age
		else
			return p11_.cluster.subTypeIndex < p12_.cluster.subTypeIndex
		end
	end)
	return self.targetItems
end

function AnimalScreenBase:getTargetData() end

function AnimalScreenBase:setAnimalsChangedCallback(callback, target)
	function self.animalsChangedCallback()
		-- upvalues: (copy) callback, (copy) target
		callback(target)
	end
end

function AnimalScreenBase:setActionTypeCallback(callback, target)
	function self.actionTypeCallback(p19_)
		-- upvalues: (copy) callback, (copy) target
		callback(target, p19_)
	end
end

function AnimalScreenBase:setErrorCallback(callback, target)
	function self.errorCallback(p23_)
		-- upvalues: (copy) callback, (copy) target
		callback(target, p23_)
	end
end

function AnimalScreenBase:setSourceActionFinishedCallback(callback, target)
	function self.sourceActionFinished(p27_, p28_)
		-- upvalues: (copy) callback, (copy) target
		callback(target, p27_, p28_)
	end
end

function AnimalScreenBase:setTargetActionFinishedCallback(callback, target)
	function self.targetActionFinished(p32_, p33_)
		-- upvalues: (copy) callback, (copy) target
		callback(target, p32_, p33_)
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
