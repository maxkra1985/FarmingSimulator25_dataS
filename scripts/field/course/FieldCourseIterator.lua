FieldCourseIterator = {}
local FieldCourseIterator_mt = Class(FieldCourseIterator)
function FieldCourseIterator.new(x, z, fieldCourseSettings, func, finishedCallback)
	local self = setmetatable({}, FieldCourseIterator_mt)
	self.func = func
	self.finishedCallback = finishedCallback
	self.frameBudget = 0.00025
	self.fieldCourseSegmentIndex = 1
	self.fieldCourseSegmentPosIndex = 1
	FieldCourse.generateByFieldPosition(x, z, fieldCourseSettings, function(fieldCourse)
		if fieldCourse ~= nil then
			self.fieldCourse = fieldCourse
			g_fieldCourseManager:addUpdateable(self)
		else
			self:onFinish(false)
		end
	end)
end
function FieldCourseIterator:update(dt)
	local startTime = getTimeSec()
	while getTimeSec() - startTime < self.frameBudget do
		local segment = self.fieldCourse.segments[self.fieldCourseSegmentIndex]
		if segment ~= nil then
			local position = segment.positions[self.fieldCourseSegmentPosIndex]
			local nextPosition = segment.positions[self.fieldCourseSegmentPosIndex + 1]
			self.func(position[1], position[2], nextPosition[1], nextPosition[2], segment.length, segment.headlandIndex, segment.islandIndex, self.fieldCourse.totalLength)
			self.fieldCourseSegmentPosIndex = self.fieldCourseSegmentPosIndex + 1
			if #segment.positions - 1 < self.fieldCourseSegmentPosIndex then
				self.fieldCourseSegmentPosIndex = 1
				self.fieldCourseSegmentIndex = self.fieldCourseSegmentIndex + 1
				if #self.fieldCourse.segments < self.fieldCourseSegmentIndex then
					self:onFinish(true)
					return
				end
			end
		else
			self:onFinish(true)
		end
	end
end
function FieldCourseIterator:onFinish(success)
	g_fieldCourseManager:removeUpdateable(self)
	if self.finishedCallback ~= nil then
		self.finishedCallback(success)
	end
end
