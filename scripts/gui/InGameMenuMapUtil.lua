InGameMenuMapUtil = {}
InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION = {
	["TOP_RIGHT"] = "topRight",
	["BOTTOM_RIGHT"] = "bottomRight",
	["BOTTOM_LEFT"] = "bottomLeft",
	["TOP_LEFT"] = "topLeft"
}

-- Local values: posX, posY, _, buttonBox, buttonBoxSize, outRight, outLeft, outTop, orientation, rotation
function InGameMenuMapUtil.getContextBoxPositionAndOrientation(hotspot, contextBox)
	local v3_, v4_, _ = hotspot:getLastScreenPositionCenter()
	local v5_ = contextBox:getDescendantByName("buttonBox")
	local v6_ = v5_ == nil and 0 or (v5_.contentSize or 0)
	local v7_ = v3_ + contextBox.size[1] > 1
	local v8_ = v3_ - contextBox.size[1] < 0
	local v9_ = v4_ + contextBox.size[2] + v6_ > 1
	local v10_ = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_RIGHT
	local v11_ = 0
	if v7_ then
		if v9_ then
			v10_ = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT
			v11_ = 3.141592653589793
		else
			v10_ = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_LEFT
			v11_ = 1.5707963267948966
		end
	elseif v8_ then
		if v9_ then
			v10_ = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
			v11_ = -1.5707963267948966
		else
			v10_ = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_RIGHT
		end
	elseif v9_ then
		v10_ = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
		v11_ = -1.5707963267948966
	end
	return v3_, v4_, v10_, v11_
end

-- Local values: posX, posY, orientation, _, goLeft, goDown, buttonBox, buttonBoxSize
function InGameMenuMapUtil.updateContextBoxPosition(contextBox, hotspot)
	if contextBox ~= nil and (contextBox:getIsVisible() and hotspot ~= nil) then
		local v14_, v15_, v16_, _ = InGameMenuMapUtil.getContextBoxPositionAndOrientation(hotspot, contextBox)
		local v17_ = v16_ == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_LEFT and true or v16_ == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT
		local v18_ = v16_ == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT and true or v16_ == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
		if v17_ then
			v14_ = v14_ - contextBox.size[1]
		end
		if v18_ then
			v15_ = v15_ - contextBox.size[2]
		end
		local v19_ = contextBox:getDescendantByName("buttonBox")
		contextBox:setAbsolutePosition(v14_, v15_ + ((v19_ == nil or v16_ ~= InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_RIGHT and v16_ ~= InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_LEFT) and 0 or (v19_.contentSize or 0)))
	end
end

-- Local values: x, y, buttonBox, buttonBoxSize, hasImage, image, text, farmland, farmElem, farm, farmName
function InGameMenuMapUtil.showContextBox(contextBox, hotspot, description, imageFilename, uvs, farmId, playerName, isPlaceable, isVehicle, isFarmland)
	if contextBox ~= nil then
		contextBox:setVisible(true)
		local v30_, v31_ = InGameMenuMapUtil.getContextBoxPositionAndOrientation(hotspot, contextBox)
		local v32_ = contextBox:getDescendantByName("buttonBox")
		contextBox:setAbsolutePosition(v30_, v31_ + (v32_ == nil and 0 or (v32_.contentSize or 0)))
		local v33_
		if imageFilename == nil then
			v33_ = false
		else
			v33_ = string.find(imageFilename, "data/store/store_empty") == nil
		end
		local v34_ = contextBox:getDescendantByName("image")
		contextBox:getDescendantByName("imageVehicle"):setVisible(false)
		if isVehicle or isPlaceable then
			v34_:setVisible(false)
			v34_ = contextBox:getDescendantByName("imageVehicle")
		end
		v34_:setVisible(v33_)
		if v33_ then
			v34_:setImageFilename(imageFilename)
			v34_:setImageUVs(GuiOverlay.STATE_NORMAL, unpack(uvs))
		end
		local v35_ = contextBox:getDescendantByName("text")
		v35_:setText(description)
		if isFarmland then
			local v36_ = hotspot:getFarmland()
			if v36_ ~= nil then
				contextBox:getDescendantByName("farmlandSize"):setText(g_i18n:formatArea(v36_.areaInHa, 2))
				contextBox:getDescendantByName("farmlandValue"):setText(g_i18n:formatMoney(v36_.price, 0, true))
				v35_:setText(g_i18n:getText("fieldInfo_farmland") .. ": " .. v36_.name)
			end
		end
		local v37_ = contextBox:getDescendantByName("farm")
		if g_currentMission.missionDynamicInfo.isMultiplayer then
			if farmId == nil then
				if playerName == nil then
					v37_:setText("")
				else
					v37_:setText(playerName)
					local v38_ = Farm.COLOR_NO_FARM
					v37_:setTextColor(unpack(v38_))
				end
			end
			local v39_ = g_farmManager:getFarmById(farmId)
			if v39_ ~= nil then
				local v40_ = v39_.name
				if playerName ~= nil then
					v40_ = playerName .. " - " .. v40_
				end
				v37_:setText(v40_)
				v37_:setTextColor(unpack(v39_:getColor()))
				return
			end
		else
			v37_:setText("")
		end
	end
end

-- Local values: playerElem, farmElem, farm
function InGameMenuMapUtil.showPlayerContextBox(contextBox, playerName, farmId)
	if contextBox ~= nil then
		contextBox:setVisible(true)
		local v44_ = contextBox:getDescendantByName("player")
		v44_:setText(playerName)
		local v45_ = contextBox:getDescendantByName("farm")
		if farmId ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer then
			local v46_ = g_farmManager:getFarmById(farmId)
			if v46_ == nil or v46_.isSpectator then
				v45_:setText("")
				v44_:setTextColor(0.89627, 0.92158, 0.81485, 1)
			else
				v45_:setText(v46_.name)
				v45_:setTextColor(unpack(v46_:getColor()))
				v44_:setTextColor(unpack(v46_:getColor()))
			end
		end
		v45_:setText("")
	end
end

function InGameMenuMapUtil.hideContextBox(contextBox)
	if contextBox ~= nil then
		contextBox:setVisible(false)
	end
end

function InGameMenuMapUtil.getHotspotVehicle(hotspot)
	if hotspot == nil or hotspot.getVehicle == nil then
		return nil
	else
		return hotspot:getVehicle()
	end
end

-- Local values: orientation, goLeft, goDown
function InGameMenuMapUtil.updateFieldInfoBoxPosition(fieldInfoBox, posX, posY)
	if fieldInfoBox ~= nil and fieldInfoBox:getIsVisible() then
		local v52_ = InGameMenuMapUtil.getFieldInfoBoxOrientation(posX, posY, fieldInfoBox)
		local v53_ = v52_ == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_LEFT and true or v52_ == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT
		local v54_ = v52_ == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT and true or v52_ == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
		if v53_ then
			posX = posX - fieldInfoBox.size[1]
		end
		if v54_ then
			posY = posY - fieldInfoBox.size[2]
		end
		fieldInfoBox:setAbsolutePosition(posX, posY)
	end
end

-- Local values: outRight, outLeft, outTop, orientation
function InGameMenuMapUtil.getFieldInfoBoxOrientation(posX, posY, fieldInfoBox)
	local v58_ = posX + fieldInfoBox.size[1] > 1
	local v59_ = posX - fieldInfoBox.size[1] < 0
	local v60_ = posY + fieldInfoBox.size[2] > 1
	local v61_ = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_RIGHT
	if v58_ then
		if v60_ then
			return InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT
		else
			return InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_LEFT
		end
	elseif v59_ then
		if v60_ then
			return InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
		else
			return InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_RIGHT
		end
	else
		if v60_ then
			v61_ = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
		end
		return v61_
	end
end
