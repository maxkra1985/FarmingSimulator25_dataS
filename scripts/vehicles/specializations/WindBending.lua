WindBending = {}

function WindBending.prerequisitesPresent(vehicleType)
	return true
end
function WindBending.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("WindBending")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.windBending.windBendingNodes.windBendingNode(?)#node", "Shader node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.windBending.windBendingNodes.windBendingNode(?)#decalNode", "Extra node that gets the exact same shader parameters")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.windBending.windBendingNodes.windBendingNode(?)#speedReferenceNode", "Reference node to calculate speed of wind")
	v1_:register(XMLValueType.FLOAT, "vehicle.windBending.windBendingNodes.windBendingNode(?)#maxBending", "Bending in meters", 0.15)
	v1_:register(XMLValueType.FLOAT, "vehicle.windBending.windBendingNodes.windBendingNode(?)#maxBendingNeg", "Negative bending in meters (used if the vehicle drives in reverse)", "same as #maxBending")
	v1_:register(XMLValueType.FLOAT, "vehicle.windBending.windBendingNodes.windBendingNode(?)#maxBendingSpeed", "Speed at which max bending state is reached in kmph", 20)
	v1_:setXMLSpecializationType()
end

function WindBending.registerFunctions(vehicleType) end

function WindBending.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WindBending)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", WindBending)
end

-- Local values: spec
function WindBending:onLoad(savegame)
	local v_u_4_ = self.spec_windBending
	if self.isClient then
		v_u_4_.windBending = {}
		self.xmlFile:iterate("vehicle.windBending.windBendingNodes.windBendingNode", function(_, p5_)
			-- upvalues: (copy) self, (copy) v_u_4_
			local v6_ = {
				["node"] = self.xmlFile:getValue(p5_ .. "#node", nil, self.components, self.i3dMappings)
			}
			if v6_.node == nil then
				Logging.xmlError(self.xmlFile, "Unable to load wind bending node from xml. Node not found. \'%s\'", p5_)
				return
			elseif getHasClassId(v6_.node, ClassIds.SHAPE) and getHasShaderParameter(v6_.node, "directionBend") then
				v6_.speedReferenceNode = self.xmlFile:getValue(p5_ .. "#speedReferenceNode", v6_.node, self.components, self.i3dMappings)
				v6_.parentComponent = self:getParentComponent(v6_.speedReferenceNode)
				v6_.maxBending = self.xmlFile:getValue(p5_ .. "#maxBending", 0.15)
				v6_.maxBendingNeg = self.xmlFile:getValue(p5_ .. "#maxBendingNeg", v6_.maxBending)
				v6_.maxBendingSpeed = self.xmlFile:getValue(p5_ .. "#maxBendingSpeed", 20)
				v6_.decalNode = self.xmlFile:getValue(p5_ .. "#decalNode", nil, self.components, self.i3dMappings)
				v6_.lastPosition = nil
				local v7_ = v_u_4_.windBending
				table.insert(v7_, v6_)
			else
				Logging.xmlError(self.xmlFile, "Unable to load wind bending node from xml. Node has not shader parameter \'directionBend\'. \'%s\'", p5_)
			end
		end)
	end
	if not self.isClient or #v_u_4_.windBending == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", WindBending)
	end
end

-- Local values: spec, lastSpeed, i, windBendingNode, x, y, z, vx, vy, vz, maxBending, bendingAmount
function WindBending:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v9_ = self.spec_windBending
	local v10_ = self:getLastSpeed()
	for v11_ = 1, #v9_.windBending do
		local v12_ = v9_.windBending[v11_]
		local v13_, v14_, v15_ = localToWorld(v12_.speedReferenceNode, 0, 0, 0)
		if v12_.lastPosition == nil then
			v12_.lastPosition = { v13_, v14_, v15_ }
		end
		local v16_ = (v13_ - v12_.lastPosition[1]) * 10
		local v17_ = (v14_ - v12_.lastPosition[2]) * 10
		local v18_ = (v15_ - v12_.lastPosition[3]) * 10
		if v16_ ~= 0 or (v17_ ~= 0 or v18_ ~= 0) then
			local v19_, v20_, v21_ = worldDirectionToLocal(getParent(v12_.node), v16_, v17_, v18_)
			local v22_, v23_, v24_ = MathUtil.vector3Normalize(v19_, v20_, v21_)
			local v25_ = (self.movingDirection >= 0 and v12_.maxBending or v12_.maxBendingNeg) * (v10_ / v12_.maxBendingSpeed)
			g_animationManager:setPrevShaderParameter(v12_.node, "directionBend", v22_, v23_, v24_, v25_, false, "prevDirectionBend")
			if v12_.decalNode ~= nil then
				g_animationManager:setPrevShaderParameter(v12_.decalNode, "directionBend", v22_, v23_, v24_, v25_, false, "prevDirectionBend")
			end
		end
		v12_.lastPosition[1] = v13_
		v12_.lastPosition[2] = v14_
		v12_.lastPosition[3] = v15_
	end
end
