-- Local values: FieldCourseIterator_mt
FieldCourseIterator = {}
local FieldCourseIterator_mt = Class(FieldCourseIterator)

-- Upvalues: FieldCourseIterator_mt
-- Local values: self
function FieldCourseIterator.new(x, z, fieldCourseSettings, func, finishedCallback)
	-- upvalues: (copy) FieldCourseIterator_mt
	local v7_ = FieldCourseIterator_mt
	local v_u_8_ = setmetatable({}, v7_)
	v_u_8_.func = func
	v_u_8_.finishedCallback = finishedCallback
	v_u_8_.frameBudget = 0.00025
	v_u_8_.fieldCourseSegmentIndex = 1
	v_u_8_.fieldCourseSegmentPosIndex = 1
	FieldCourse.generateByFieldPosition(x, z, fieldCourseSettings, function(p9_)
		-- upvalues: (copy) v_u_8_
		if p9_ == nil then
			v_u_8_:onFinish(false)
		else
			v_u_8_.fieldCourse = p9_
			g_fieldCourseManager:addUpdateable(v_u_8_)
		end
	end)
end

-- Local values: startTime, segment, position, nextPosition
function FieldCourseIterator:update(dt)
	local v11_ = getTimeSec()
	while getTimeSec() - v11_ < self.frameBudget do
		local v12_ = self.fieldCourse.segments[self.fieldCourseSegmentIndex]
		if v12_ == nil then
			self:onFinish(true)
		else
			local v13_ = v12_.positions[self.fieldCourseSegmentPosIndex]
			local v14_ = v12_.positions[self.fieldCourseSegmentPosIndex + 1]
			self.func(v13_[1], v13_[2], v14_[1], v14_[2], v12_.length, v12_.headlandIndex, v12_.islandIndex, self.fieldCourse.totalLength)
			self.fieldCourseSegmentPosIndex = self.fieldCourseSegmentPosIndex + 1
			if self.fieldCourseSegmentPosIndex > #v12_.positions - 1 then
				self.fieldCourseSegmentPosIndex = 1
				self.fieldCourseSegmentIndex = self.fieldCourseSegmentIndex + 1
				if self.fieldCourseSegmentIndex > #self.fieldCourse.segments then
					self:onFinish(true)
					return
				end
			end
		end
	end
end

function FieldCourseIterator:onFinish(success)
	g_fieldCourseManager:removeUpdateable(self)
	if self.finishedCallback ~= nil then
		self.finishedCallback(success)
	end
end
