BlurUtil = {}

function BlurUtil.stackBlur(dataGetter, dataSetter, width, height, radius)
	BlurUtil.stackBlurHorizontal(dataGetter, dataSetter, width, height, radius)
	BlurUtil.stackBlurVertical(dataGetter, dataSetter, width, height, radius)
end

-- Local values: y, x
function BlurUtil.stackBlurAsync(dataGetter, dataSetter, width, height, radius, asyncManager, callback)
	local v13_ = asyncManager or g_asyncTaskManager
	for v_u_14_ = 1, height do
		v13_:addTask(function()
			-- upvalues: (copy) dataGetter, (copy) dataSetter, (copy) width, (copy) radius, (copy) v_u_14_
			BlurUtil.stackBlurRow(dataGetter, dataSetter, width, radius, v_u_14_)
		end)
	end
	for v_u_15_ = 1, width do
		v13_:addTask(function()
			-- upvalues: (copy) dataGetter, (copy) dataSetter, (copy) height, (copy) radius, (copy) v_u_15_, (copy) width, (copy) callback
			BlurUtil.stackBlurColumn(dataGetter, dataSetter, height, radius, v_u_15_)
			if v_u_15_ == width then
				callback()
			end
		end)
	end
end

-- Local values: queue, y
function BlurUtil.stackBlurHorizontal(dataGetter, dataSetter, width, height, radius)
	local v21_ = {}
	for v22_ = 1, height do
		BlurUtil.stackBlurRow(dataGetter, dataSetter, width, radius, v22_, v21_)
	end
end

-- Local values: queue, x
function BlurUtil.stackBlurVertical(dataGetter, dataSetter, width, height, radius)
	local v28_ = {}
	for v29_ = 1, width do
		BlurUtil.stackBlurColumn(dataGetter, dataSetter, height, radius, v29_, v28_)
	end
end

-- Local values: kernelSize, stackSize, edgeValue, sum, inSum, outSum, queueCounter, safeGetter, x
function BlurUtil.stackBlurRow(dataGetter, dataSetter, width, radius, y, queue)
	local v36_ = radius * 2 + 1
	local v37_ = radius * (radius + 2) + 1
	local v38_ = queue or {}
	local v39_ = dataGetter(1, y)
	local v40_, v41_, v42_ = BlurUtil.recalculateBlurQueueAndSums(v38_, v36_, radius, v39_)
	local v43_ = radius
	local function v49_(p44_, p45_)
		-- upvalues: (copy) dataGetter, (copy) radius, (copy) width
		local v46_ = dataGetter
		local v47_ = p44_ + radius
		local v48_ = width
		return v46_(math.min(v47_, v48_), p45_)
	end
	for v50_ = 1, width do
		v40_, v41_, v42_, radius = BlurUtil.iterateStackBlur(v49_, dataSetter, v38_, v36_, v37_, v43_, v40_, v41_, v42_, radius, v50_, y)
	end
end

-- Local values: kernelSize, stackSize, edgeValue, sum, inSum, outSum, queueCounter, safeGetter, y
function BlurUtil.stackBlurColumn(dataGetter, dataSetter, height, radius, x, queue)
	local v57_ = radius * 2 + 1
	local v58_ = radius * (radius + 2) + 1
	local v59_ = queue or {}
	local v60_ = dataGetter(x, 1)
	local v61_, v62_, v63_ = BlurUtil.recalculateBlurQueueAndSums(v59_, v57_, radius, v60_)
	local v64_ = radius
	local function v70_(p65_, p66_)
		-- upvalues: (copy) dataGetter, (copy) radius, (copy) height
		local v67_ = dataGetter
		local v68_ = p66_ + radius
		local v69_ = height
		return v67_(p65_, (math.min(v68_, v69_)))
	end
	for v71_ = 1, height do
		v61_, v62_, v63_, radius = BlurUtil.iterateStackBlur(v70_, dataSetter, v59_, v57_, v58_, v64_, v61_, v62_, v63_, radius, x, v71_)
	end
end

-- Local values: sum, inSum, outSum, i
function BlurUtil.recalculateBlurQueueAndSums(queue, kernelSize, radius, edgeValue)
	local v76_ = 0
	local v77_ = 0
	local v78_ = 0
	for v79_ = 1, kernelSize do
		if v79_ <= radius + 1 then
			v76_ = v76_ + edgeValue * v79_
			v77_ = v77_ + edgeValue
		else
			v76_ = v76_ + edgeValue * (kernelSize - v79_ + 1)
			v78_ = v78_ + edgeValue
		end
		queue[v79_] = edgeValue
	end
	return v76_, v78_, v77_
end

-- Local values: averagedValue, queuePosition, currentDatum
function BlurUtil.iterateStackBlur(dataGetter, dataSetter, queue, kernelSize, stackSize, radius, sum, inSum, outSum, queueCounter, x, y)
	dataSetter(x, y, sum / stackSize)
	local v92_ = queueCounter + kernelSize - radius
	if kernelSize <= v92_ then
		v92_ = v92_ - kernelSize
	end
	local v93_ = sum - outSum
	local v94_ = outSum - queue[v92_ + 1]
	local v95_ = dataGetter(x, y)
	queue[v92_ + 1] = v95_
	local v96_ = inSum + v95_
	local v97_ = v93_ + v96_
	local v98_ = queueCounter + 1
	local v99_ = kernelSize <= v98_ and 0 or v98_
	local v100_ = v94_ + queue[v99_ + 1]
	return v97_, v96_ - queue[v99_ + 1], v100_, v99_
end
