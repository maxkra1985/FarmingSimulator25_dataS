-- Local values: Graph_mt
Graph = {}
local Graph_mt = Class(Graph)
Graph.STYLE_BARS = 0
Graph.STYLE_LINES = 1

-- Upvalues: Graph_mt
-- Local values: self
function Graph.new(numValues, left, bottom, width, height, minValue, maxValue, showLabels, textExtra, graphStyle, verticalStep, verticalLabel, textSize)
	-- upvalues: (copy) Graph_mt
	local v13_ = Graph_mt
	local v14_ = setmetatable({}, v13_)
	v14_.values = {}
	v14_.lowValues = {}
	v14_.numValues = numValues
	v14_.nextIndex = 1
	v14_.overlayId = createImageOverlay("dataS/menu/base/graph_pixel.png")
	v14_.left = left
	v14_.bottom = bottom
	v14_.width = width
	v14_.height = height
	v14_.minValue = minValue
	v14_.maxValue = maxValue
	v14_.textExtra = textExtra
	v14_.showLabels = showLabels
	v14_.graphStyle = graphStyle
	v14_.textSize = textSize or getCorrectTextSize(0.011)
	if v14_.graphStyle == nil then
		v14_.graphStyle = Graph.STYLE_BARS
	end
	return v14_
end

function Graph:delete()
	delete(self.overlayId)
	if self.overlayBg ~= nil then
		delete(self.overlayBg)
	end
	if self.overlayHLine ~= nil then
		delete(self.overlayHLine)
	end
	if self.overlayVLine ~= nil then
		delete(self.overlayVLine)
	end
end

function Graph:setColor(r, g, b, a)
	setOverlayColor(self.overlayId, r, g, b, a)
end

function Graph:setBackgroundColor(r, g, b, a)
	if r == nil then
		if self.overlayBg ~= nil then
			delete(self.overlayBg)
			self.overlayBg = nil
			return
		end
	else
		if self.overlayBg == nil then
			self.overlayBg = createImageOverlay("dataS/menu/base/graph_pixel.png")
		end
		setOverlayColor(self.overlayBg, r, g, b, a)
	end
end

function Graph:setHorizontalLine(stepSize, showLabel, r, g, b, a)
	if stepSize == nil or stepSize <= 0 then
		if self.overlayHLine ~= nil then
			delete(self.overlayHLine)
			self.overlayHLine = nil
			return
		end
	else
		if self.overlayHLine == nil then
			self.overlayHLine = createImageOverlay("dataS/menu/base/graph_pixel.png")
		end
		setOverlayColor(self.overlayHLine, r, g, b, a)
		self.hLineStepSize = stepSize
		self.hLineShowLabel = showLabel
	end
end

function Graph:setVerticalLine(stepSize, showLabel, r, g, b, a)
	if stepSize == nil or stepSize <= 0 then
		if self.overlayVLine ~= nil then
			delete(self.overlayVLine)
			self.overlayVLine = nil
			return
		end
	else
		if self.overlayVLine == nil then
			self.overlayVLine = createImageOverlay("dataS/menu/base/graph_pixel.png")
		end
		setOverlayColor(self.overlayVLine, r, g, b, a)
		self.vLineStepSize = stepSize
		self.vLineShowLabel = showLabel
	end
end

-- Local values: i
function Graph:addValue(value, lowValue, fillFromRight)
	if fillFromRight then
		for v44_ = 1, self.numValues - 1 do
			self.values[v44_] = self.values[v44_ + 1]
			self.lowValues[v44_] = self.lowValues[v44_ + 1]
		end
		self.values[self.numValues] = value
		self.lowValues[self.numValues] = lowValue
	else
		self.values[self.nextIndex] = value
		self.lowValues[self.nextIndex] = lowValue
		self.nextIndex = self.nextIndex + 1
		if self.nextIndex > self.numValues then
			self.nextIndex = 1
		end
	end
end

function Graph:setValue(index, value, lowValue)
	local v49_ = (index + self.nextIndex - 2) % self.numValues + 1
	self.values[v49_] = value
	self.lowValues[v49_] = lowValue
end

function Graph:setXPosition(index, posX)
	local v53_ = (index + self.nextIndex - 2) % self.numValues + 1
	if self.xPositions == nil then
		self.xPositions = {}
	end
	self.xPositions[v53_] = posX
end

-- Local values: v, y, v, numValues, x, hasValues, prevValue, prevPosX, i, posX, i, posX
function Graph:draw()
	if self.overlayBg ~= nil then
		renderOverlay(self.overlayBg, self.left, self.bottom, self.width, self.height)
	end
	if self.overlayHLine ~= nil then
		local v55_ = 0
		while v55_ <= self.maxValue do
			local v56_ = self.bottom + v55_ / self.maxValue * self.height
			renderOverlay(self.overlayHLine, self.left, v56_, self.width, g_pixelSizeY)
			if self.hLineShowLabel then
				setTextAlignment(RenderText.ALIGN_RIGHT)
				renderText(self.left - 0.005, v56_, self.textSize, string.format("%1.2f", self.minValue + v55_) .. self.textExtra)
				setTextAlignment(RenderText.ALIGN_LEFT)
			end
			v55_ = v55_ + self.hLineStepSize
		end
	end
	if self.overlayVLine ~= nil then
		local v57_ = #self.values
		local v58_ = 0
		while v58_ <= v57_ do
			local v59_ = self.left + v58_ / v57_ * self.width
			renderOverlay(self.overlayHLine, v59_, self.bottom, g_pixelSizeX, self.height)
			if self.vLineShowLabel and v58_ % self.vLineStepSize == 0 then
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(v59_, self.bottom - self.textSize - 0.005, self.textSize, (tostring(v58_)))
				setTextAlignment(RenderText.ALIGN_LEFT)
			end
			v58_ = v58_ + 1
		end
	end
	local v60_ = nil
	local v61_ = nil
	local v62_ = false
	for v63_ = self.nextIndex, self.numValues do
		local v64_
		if self.xPositions == nil then
			v64_ = self.left + self.width * (v63_ - self.nextIndex) / (self.numValues - 1)
		else
			v64_ = self.left + self.width * self.xPositions[v63_]
		end
		if self.values[v63_] ~= nil then
			if self.graphStyle == Graph.STYLE_BARS then
				self:drawBar(v64_, self.values[v63_], self.lowValues[v63_])
				v62_ = true
			elseif self.graphStyle == Graph.STYLE_LINES then
				if v60_ ~= nil then
					self:drawLine(v61_, v64_, v60_, self.values[v63_])
					v62_ = true
				end
				v60_ = self.values[v63_]
				v61_ = v64_
			end
		end
	end
	for v65_ = 1, self.nextIndex - 1 do
		local v66_
		if self.xPositions == nil then
			v66_ = self.left + self.width * (self.numValues - self.nextIndex + v65_) / (self.numValues - 1)
		else
			v66_ = self.left + self.width * self.xPositions[v65_]
		end
		if self.values[v65_] ~= nil then
			if self.graphStyle == Graph.STYLE_BARS then
				self:drawBar(v66_, self.values[v65_], self.lowValues[v65_])
				v62_ = true
			elseif self.graphStyle == Graph.STYLE_LINES then
				if v60_ ~= nil then
					self:drawLine(v61_, v66_, v60_, self.values[v65_])
					v62_ = true
				end
				v60_ = self.values[v65_]
				v61_ = v66_
			end
		end
	end
	if v62_ and self.showLabels then
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(self.left - 0.005, self.bottom, self.textSize, string.format("%1.2f", self.minValue) .. self.textExtra)
		renderText(self.left - 0.005, self.bottom + self.height, self.textSize, string.format("%1.2f", self.maxValue) .. self.textExtra)
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
end

-- Local values: height, posY
function Graph:drawBar(posX, value, lowValue)
	local v71_ = lowValue == nil and 0.002 or self.height / (self.maxValue - self.minValue) * (value - lowValue)
	if v71_ > 0 then
		local v72_ = self.bottom + self.height / (self.maxValue - self.minValue) * (value - self.minValue) - v71_
		renderOverlay(self.overlayId, posX, v72_, self.width / (self.numValues - 1), v71_)
	end
end

-- Local values: posY1, posY2, dx, dy, rot, length
function Graph:drawLine(posX1, posX2, value1, value2)
	local v78_ = self.bottom + self.height / (self.maxValue - self.minValue) * (value1 - self.minValue)
	local v79_ = self.bottom + self.height / (self.maxValue - self.minValue) * (value2 - self.minValue)
	local v80_ = posX2 - posX1
	local v81_ = v79_ - v78_
	local v82_ = v81_ / (v80_ * g_screenAspectRatio)
	local v83_ = math.atan(v82_)
	local v84_ = v81_ / g_screenAspectRatio
	local v85_ = v80_ * v80_ + v84_ * v84_
	local v86_ = math.sqrt(v85_)
	setOverlayRotation(self.overlayId, v83_, 0, 0)
	renderOverlay(self.overlayId, posX1, v78_, v86_, 0.002)
end
