-- Local values: WheelVisualPartTire_mt
WheelVisualPartTire = {}
local WheelVisualPartTire_mt = Class(WheelVisualPartTire, WheelVisualPart)

-- Upvalues: WheelVisualPartTire_mt
-- Local values: self
function WheelVisualPartTire.new(name, visualWheel, linkNode, customMt)
	-- upvalues: (copy) WheelVisualPartTire_mt
	local v5_ = WheelVisualPart.new(name, visualWheel, linkNode, WheelVisualPartTire_mt)
	v5_.deformation = 0
	v5_.derformationPrevDirty = false
	return v5_
end

function WheelVisualPartTire:loadFromXML(xmlObject, key)
	if not WheelVisualPartTire:superClass().loadFromXML(self, xmlObject, key) then
		return false
	end
	self.maxDeformation = xmlObject:getValue(key .. "#maxDeformation", 0)
	local v9_ = key .. "#initialDeformation"
	local v10_ = self.maxDeformation * 0.6
	self.initialDeformation = xmlObject:getValue(v9_, (math.min(0.04, v10_)))
	return true
end

-- Local values: deformation, prevDeformation, curDeformation, _, tireNode
function WheelVisualPartTire:update(x, y, z, xDrive, suspensionLength, steeringAngle, changed)
	if self.node ~= nil and Platform.gameplay.wheelVisualPressure then
		local v14_ = self.initialDeformation - suspensionLength
		local v15_ = self.maxDeformation
		local v16_ = math.clamp(v14_, 0, v15_)
		local v17_ = v16_ - self.deformation
		local v18_, v19_
		if math.abs(v17_) > Platform.gameplay.wheelVisualPressureUpdateThreshold then
			v18_ = self.deformation
			self.deformation = v16_
			self.derformationPrevDirty = true
			v19_ = v16_
			changed = true
		else
			v19_ = nil
			v18_ = nil
		end
		if v19_ == nil and self.derformationPrevDirty then
			v18_ = self.deformation
			v19_ = self.deformation
			self.derformationPrevDirty = false
		end
		if v19_ ~= nil then
			for _, v20_ in ipairs(self.tireNodes) do
				setShaderParameter(v20_, "morphPos", nil, nil, nil, v19_, false)
				setShaderParameter(v20_, "prevMorphPos", nil, nil, nil, v18_, false)
			end
		end
		suspensionLength = suspensionLength + v16_
	end
	return changed, suspensionLength
end

-- Local values: _, tireNode, x, y, z, _, sx, sy, sz, _
function WheelVisualPartTire:setNode(node)
	WheelVisualPartTire:superClass().setNode(self, node)
	self.tireNodes = {}
	if getHasClassId(self.node, ClassIds.SHAPE) and (getHasShaderParameter(self.node, "morphPos") or getHasShaderParameter(self.node, "morphPosition")) then
		local v23_ = self.tireNodes
		local v24_ = self.node
		table.insert(v23_, v24_)
	end
	I3DUtil.iterateRecursively(node, function(p25_)
		-- upvalues: (copy) self
		if getHasClassId(p25_, ClassIds.SHAPE) and (getHasShaderParameter(p25_, "morphPos") or getHasShaderParameter(p25_, "morphPosition")) then
			local v26_ = self.tireNodes
			table.insert(v26_, p25_)
		end
	end)
	for _, v27_ in ipairs(self.tireNodes) do
		if getHasShaderParameter(v27_, "morphPos") then
			local v28_, v29_, v30_, _ = getShaderParameter(v27_, "morphPos")
			setShaderParameter(v27_, "morphPos", nil, nil, nil, 0, false)
			setShaderParameter(v27_, "prevMorphPos", v28_, v29_, v30_, 0, false)
		elseif getHasShaderParameter(v27_, "morphPosition") then
			local v31_, v32_, v33_, _ = getShaderParameter(v27_, "morphPosition")
			setShaderParameter(v27_, "morphPos", v31_, v32_, v33_, 0, false)
			setShaderParameter(v27_, "prevMorphPos", v31_, v32_, v33_, 0, false)
		end
	end
end

function WheelVisualPartTire.registerXMLPaths(schema, key, name)
	WheelVisualPart.registerXMLPaths(schema, key, name)
	schema:register(XMLValueType.FLOAT, key .. "#maxDeformation", "Max. deformation", 0)
	schema:register(XMLValueType.FLOAT, key .. "#initialDeformation", "Tire deformation at initial compression value", "min. 0.04 and max. 60% of the deformation")
	schema:register(XMLValueType.BOOL, key .. "#hasMudMesh", "Tire has a mud mesh included", false)
end
