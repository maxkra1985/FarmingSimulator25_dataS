HandToolUtil = {}
HandToolUtil.CLICK_BOX_TARGET_MASK = CollisionFlag.INTERACTABLE_TARGET
HandToolUtil.HOLDER_DEFAULT_MINIMUM_DISTANCE = 0.25
HandToolUtil.HOLDER_DEFAULT_MAXIMUM_DISTANCE = 5

function HandToolUtil.addHandToolHolderTarget(playerTargeter, minDistance, maxDistance)
	local v4_ = minDistance or HandToolUtil.HOLDER_DEFAULT_MINIMUM_DISTANCE
	local v5_ = maxDistance or HandToolUtil.HOLDER_DEFAULT_MAXIMUM_DISTANCE
	playerTargeter:addTargetType(HandToolHolder, HandToolUtil.CLICK_BOX_TARGET_MASK, v4_, v5_)
	playerTargeter:addFilterToTargetType(HandToolHolder, function(p6_, _, _, _)
		local v7_
		if p6_ == nil or p6_ == 0 then
			v7_ = false
		else
			v7_ = g_currentMission.handToolSystem:getHandToolHolderByClickBox(p6_) ~= nil
		end
		return v7_
	end)
end

-- Local values: clickBox, handToolHolder
function HandToolUtil.getTargetedHandToolHolder(playerTargeter)
	if not playerTargeter:getHasTargetedKey(HandToolHolder) then
		Logging.warning("HandToolUtil.getTargetedHandToolHolder was called, but HandToolUtil.CLICK_BOX_TARGET_MASK was not targeted!")
		return nil
	end
	local v9_ = playerTargeter.closestTargetsByKey[HandToolHolder]
	local v10_ = g_currentMission.handToolSystem
	local v11_
	if v9_ then
		v11_ = v9_.node
	else
		v11_ = v9_
	end
	local v12_ = v10_:getHandToolHolderByClickBox(v11_)
	if v9_ == nil then
		return nil
	end
	if v12_ ~= nil then
		return v12_
	end
	Logging.warning("Node with name %s is not a registered hand tool holder, yet somehow was picked up by the targeter as one!", getName(v9_.node))
	return nil
end

function HandToolUtil.linkAndTransformRelativeToParent(rootNode, childNode, parentNode)
	link(parentNode, rootNode)
	HandToolUtil.transformRelativeToParent(rootNode, childNode, parentNode)
end

-- Local values: childForwardX, childForwardY, childForwardZ, childUpX, childUpY, childUpZ, localChildPositionX, localChildPositionY, localChildPositionZ
function HandToolUtil.transformRelativeToParent(rootNode, childNode, parentNode)
	local v19_, v20_, v21_ = localDirectionToLocal(rootNode, childNode, 0, 0, 1)
	local v22_, v23_, v24_ = localDirectionToLocal(rootNode, childNode, 0, 1, 0)
	setDirection(rootNode, v19_, v20_, v21_, v22_, v23_, v24_)
	setTranslation(rootNode, 0, 0, 0)
	local v25_, v26_, v27_ = localToLocal(parentNode, childNode, 0, 0, 0)
	setTranslation(rootNode, v25_, v26_, v27_)
end
