-- Local values: HelpIcons_mt
HelpIcons = {}
local HelpIcons_mt = Class(HelpIcons)

-- Local values: helpIcons
function HelpIcons:onCreate(id)
	local v3_ = HelpIcons.new(id)
	g_currentMission:addNonUpdateable(v3_)
	g_currentMission.helpIconsBase = v3_
end

-- Upvalues: HelpIcons_mt
-- Local values: self, num, i, helpIconTriggerId, helpIconId, helpIconCustomNumber, helpIcon
function HelpIcons.new(name)
	-- upvalues: (copy) HelpIcons_mt
	local v5_ = HelpIcons_mt
	local v6_ = setmetatable({}, v5_)
	v6_.me = name
	local v7_ = getNumOfChildren(v6_.me)
	v6_.helpIcons = {}
	for v8_ = 0, v7_ - 1 do
		local v9_ = getChildAt(v6_.me, v8_)
		local v10_ = getChildAt(v9_, 0)
		local v11_ = Utils.getNoNil(getUserAttribute(v9_, "customNumber"), 0)
		addTrigger(v9_, "triggerCallback", v6_)
		local v12_ = v6_.helpIcons
		table.insert(v12_, {
			["helpIconTriggerId"] = v9_,
			["helpIconId"] = v10_,
			["helpIconCustomNumber"] = v11_
		})
	end
	v6_.visible = true
	return v6_
end

-- Local values: _, helpIcon
function HelpIcons:delete()
	for _, v14_ in pairs(self.helpIcons) do
		removeTrigger(v14_.helpIconTriggerId)
	end
end

function HelpIcons:update(dt) end

-- Local values: localPlayer, playerVehicle, missionInfo, i, helpIcon, _, helpIcon, messageNumber
function HelpIcons:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter then
		local v19_ = g_localPlayer
		if v19_ == nil then
			return
		elseif v19_:getIsInVehicle() or otherId == v19_.rootNode then
			local v20_ = v19_:getCurrentVehicle()
			if v20_ ~= nil and v20_ == g_currentMission.nodeToObject[otherId] then
				local v21_ = g_currentMission.missionInfo
				for v26_, v23_ in ipairs(self.helpIcons) do
					if v23_.helpIconTriggerId == triggerId and getVisibility(v23_.helpIconId) then
						setVisibility(v23_.helpIconId, false)
						setCollisionFilterMask(v23_.helpIconTriggerId, 0)
						v21_.foundHelpIcons = ""
						for _, v24_ in ipairs(self.helpIcons) do
							if getVisibility(v24_.helpIconId) then
								v21_.foundHelpIcons = v21_.foundHelpIcons .. "0"
							else
								v21_.foundHelpIcons = v21_.foundHelpIcons .. "1"
							end
						end
						local v25_ = v23_.helpIconCustomNumber
						if v25_ ~= 0 then
							local v26_ = v25_
						end
						g_currentMission.inGameMessage:showMessage(g_i18n:getText("helpIcon_title" .. v26_), g_i18n:getText("helpIcon_text" .. v26_), 0)
					end
				end
			end
		else
			return
		end
	else
		return
	end
end

-- Local values: oldStates, i, helpIcon, isVisible
function HelpIcons:showHelpIcons(visible, clearIconStates)
	self.visible = visible
	local v30_ = g_currentMission.missionInfo.foundHelpIcons
	for v31_, v32_ in ipairs(self.helpIcons) do
		local v33_
		if clearIconStates == nil or not clearIconStates then
			if visible then
				v33_ = string.sub(v30_, v31_, v31_) == "0"
			else
				v33_ = visible
			end
		else
			v33_ = visible
		end
		setVisibility(v32_.helpIconId, v33_)
		if v33_ then
			setCollisionFilterMask(v32_.helpIconTriggerId, 3145728)
		else
			setCollisionFilterMask(v32_.helpIconTriggerId, 0)
		end
	end
end

function HelpIcons:deleteHelpIcon(i)
	if self.helpIcons[i] ~= nil then
		setVisibility(self.helpIcons[i].helpIconId, false)
		setCollisionFilterMask(self.helpIcons[i].helpIconTriggerId, 0)
	end
end
