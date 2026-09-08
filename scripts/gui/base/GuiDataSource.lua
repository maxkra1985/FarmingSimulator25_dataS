-- Local values: GuiDataSource_mt, NO_DATA, NO_CALLBACK
GuiDataSource = {}
local GuiDataSource_mt = Class(GuiDataSource)
local NO_DATA = {}
local function NO_CALLBACK() end

-- Upvalues: GuiDataSource_mt, NO_DATA
-- Local values: self
function GuiDataSource.new(subclass_mt)
	-- upvalues: (copy) GuiDataSource_mt, (copy) NO_DATA
	local v5_ = subclass_mt or GuiDataSource_mt
	local v6_ = setmetatable({}, v5_)
	v6_.data = NO_DATA
	v6_.changeListeners = {}
	return v6_
end

-- Upvalues: NO_DATA
function GuiDataSource:setData(data)
	-- upvalues: (copy) NO_DATA
	self.data = data or NO_DATA
	self:notifyChange()
end

-- Upvalues: NO_CALLBACK
function GuiDataSource:addChangeListener(target, callback)
	-- upvalues: (copy) NO_CALLBACK
	self.changeListeners[target] = callback or NO_CALLBACK
end

function GuiDataSource:removeChangeListener(target)
	self.changeListeners[target] = nil
end

-- Local values: target, callback
function GuiDataSource:notifyChange()
	for v15_, v16_ in pairs(self.changeListeners) do
		v16_(v15_)
	end
end

function GuiDataSource:getCount()
	return #self.data
end

function GuiDataSource:getItem(index)
	return self.data[index]
end

function GuiDataSource:setItem(index, value, needsNotification)
	if index > 0 and index <= #self.data then
		self.data[index] = value
		if needsNotification then
			self:notifyChange()
		end
	end
end

-- Local values: iterator
function GuiDataSource:iterateRange(startIndex, endIndex)
	return function(p27_, p28_)
		-- upvalues: (copy) endIndex
		local v29_ = p27_[p28_]
		if p28_ <= endIndex and v29_ ~= nil then
			return p28_ + 1, v29_
		else
			return nil, nil
		end
	end, self.data, startIndex
end
GuiDataSource.EMPTY_SOURCE = GuiDataSource.new()
