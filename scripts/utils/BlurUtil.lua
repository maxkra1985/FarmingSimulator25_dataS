BlurUtil = {}
function BlurUtil.stackBlur(dataGetter, dataSetter, width, height, radius)
	BlurUtil.stackBlurHorizontal(dataGetter, dataSetter, width, height, radius)
	BlurUtil.stackBlurVertical(dataGetter, dataSetter, width, height, radius)
end
function BlurUtil.stackBlurAsync(dataGetter, dataSetter, width, height, radius, asyncManager, callback)
	asyncManager = asyncManager or g_asyncTaskManager
	for y = 1, height do
		asyncManager:addTask(function()
			BlurUtil.stackBlurRow(dataGetter, dataSetter, width, radius, y)
		end)
	end
	for x = 1, width do
		asyncManager:addTask(function()
			BlurUtil.stackBlurColumn(dataGetter, dataSetter, height, radius, x)
			if x == width then
				callback()
			end
		end)
	end
end
function BlurUtil.stackBlurHorizontal(dataGetter, dataSetter, width, height, radius)
	local queue = {}
	for y = 1, height do
		BlurUtil.stackBlurRow(dataGetter, dataSetter, width, radius, y, queue)
	end
end
function BlurUtil.stackBlurVertical(dataGetter, dataSetter, width, height, radius)
	local queue = {}
	for x = 1, width do
		BlurUtil.stackBlurColumn(dataGetter, dataSetter, height, radius, x, queue)
	end
end
function BlurUtil.stackBlurRow(dataGetter, dataSetter, width, radius, y, queue)
	local kernelSize = radius * 2 + 1
	local stackSize = radius * (radius + 2) + 1
	queue = queue or {}
	local edgeValue = dataGetter(1, y)
	local sum, inSum, outSum = BlurUtil.recalculateBlurQueueAndSums(queue, kernelSize, radius, edgeValue)
	local queueCounter = radius
	local safeGetter = function(x, y)
		return dataGetter(math.min(x + radius, width), y)
	end
	for x = 1, width do
		sum, inSum, outSum, queueCounter = BlurUtil.iterateStackBlur(safeGetter, dataSetter, queue, kernelSize, stackSize, radius, sum, inSum, outSum, queueCounter, x, y)
	end
end
function BlurUtil.stackBlurColumn(dataGetter, dataSetter, height, radius, x, queue)
	local kernelSize = radius * 2 + 1
	local stackSize = radius * (radius + 2) + 1
	queue = queue or {}
	local edgeValue = dataGetter(x, 1)
	local sum, inSum, outSum = BlurUtil.recalculateBlurQueueAndSums(queue, kernelSize, radius, edgeValue)
	local queueCounter = radius
	local safeGetter = function(x, y)
		return dataGetter(x, math.min(y + radius, height))
	end
	for y = 1, height do
		sum, inSum, outSum, queueCounter = BlurUtil.iterateStackBlur(safeGetter, dataSetter, queue, kernelSize, stackSize, radius, sum, inSum, outSum, queueCounter, x, y)
	end
end
function BlurUtil.recalculateBlurQueueAndSums(queue, kernelSize, radius, edgeValue)
	local sum = 0
	local inSum = 0
	local outSum = 0
	for i = 1, kernelSize do
		if i <= radius + 1 then
			sum = sum + edgeValue * i
			outSum = outSum + edgeValue
		else
			sum = sum + edgeValue * (kernelSize - i + 1)
			inSum = inSum + edgeValue
		end
		queue[i] = edgeValue
	end
	return sum, inSum, outSum
end
function BlurUtil.iterateStackBlur(dataGetter, dataSetter, queue, kernelSize, stackSize, radius, sum, inSum, outSum, queueCounter, x, y)
	local averagedValue = sum / stackSize
	dataSetter(x, y, averagedValue)
	local queuePosition = queueCounter + kernelSize - radius
	if kernelSize <= queuePosition then
		queuePosition = queuePosition - kernelSize
	end
	sum = sum - outSum
	outSum = outSum - queue[queuePosition + 1]
	local currentDatum = dataGetter(x, y)
	queue[queuePosition + 1] = currentDatum
	inSum = inSum + currentDatum
	sum = sum + inSum
	queueCounter = queueCounter + 1
	if kernelSize <= queueCounter then
		queueCounter = 0
	end
	outSum = outSum + queue[queueCounter + 1]
	inSum = inSum - queue[queueCounter + 1]
	return sum, inSum, outSum, queueCounter
end
