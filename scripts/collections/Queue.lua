-- Local values: Queue_mt
Queue = {}
local Queue_mt = Class(Queue)
function Queue.new()
	-- upvalues: (copy) Queue_mt
	local v2_ = Queue_mt
	local v3_ = setmetatable({}, v2_)
	v3_.size = 0
	v3_.first = nil
	v3_.last = nil
	return v3_
end

function Queue:delete() end

function Queue:push(value)
	if self.last then
		self.last._next = value
		value._prev = self.last
		self.last = value
	else
		self.first = value
		self.last = value
	end
	self.size = self.size + 1
end

-- Local values: value
function Queue:pop()
	if self.first then
		local v7_ = self.first
		if v7_._next then
			v7_._next._prev = nil
			self.first = v7_._next
			v7_._next = nil
		else
			self.first = nil
			self.last = nil
		end
		self.size = self.size - 1
		return v7_
	end
end

function Queue:peek()
	return self.first
end

-- Local values: item
function Queue:contains(value)
	local v11_ = self.first
	while v11_ ~= nil do
		if v11_ == value then
			return true
		end
		v11_ = v11_._next
	end
	return false
end

function Queue:remove(value)
	if not self:contains(value) then
		return false
	end
	if value._next then
		if value._prev then
			value._next._prev = value._prev
			value._prev._next = value._next
		else
			value._next._prev = nil
			self.first = value._next
		end
	elseif value._prev then
		value._prev._next = nil
		self.last = value._prev
	else
		self.first = nil
		self.last = nil
	end
	value._next = nil
	value._prev = nil
	self.size = self.size - 1
	return true
end

function Queue:isEmpty()
	return self.first == nil
end

-- Local values: i, item
function Queue:iteratePushOrder(func)
	local v17_ = self.first
	local v18_ = 1
	while v17_ ~= nil and func(v17_, v18_) ~= true do
		v18_ = v18_ + 1
		v17_ = v17_._next
	end
end

-- Local values: i, item
function Queue:iteratePopOrder(func)
	local v21_ = self.last
	local v22_ = 1
	while v21_ ~= nil and func(v21_, v22_) ~= true do
		v22_ = v22_ + 1
		v21_ = v21_._prev
	end
end
