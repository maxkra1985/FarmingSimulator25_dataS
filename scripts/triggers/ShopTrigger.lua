-- Local values: ShopTrigger_mt, ShopTriggerActivatable_mt
ShopTrigger = {}
local ShopTrigger_mt = Class(ShopTrigger)

function ShopTrigger:onCreate(id)
	g_currentMission:addNonUpdateable(ShopTrigger.new(id))
end

-- Upvalues: ShopTrigger_mt
-- Local values: self

-- Upvalues: ShopTriggerActivatable_mt
-- Local values: self
function ShopTrigger.new(shopTrigger)
	-- upvalues: (copy) ShopTrigger_mt
	local v4_ = ShopTrigger_mt
	local v5_ = setmetatable({}, v4_)
	if g_currentMission:getIsClient() then
		v5_.triggerId = shopTrigger
		if not CollisionFlag.getHasMaskFlagSet(shopTrigger, CollisionFlag.PLAYER) then
			Logging.warning("Missing collision mask bit \'%d\'. Please add this bit to shop trigger shopTrigger \'%s\'", CollisionFlag.getBit(CollisionFlag.PLAYER), I3DUtil.getNodePath(shopTrigger))
		end
		addTrigger(shopTrigger, "triggerCallback", v5_)
	end
	v5_.shopSymbol = getChildAt(shopTrigger, 0)
	v5_.shopPlayerSpawn = getChildAt(shopTrigger, 1)
	v5_.isEnabled = true
	g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, v5_.playerFarmChanged, v5_)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_TRIGGER_MARKER], v5_.onTriggerVisibilityChanged, v5_)
	v5_:updateIconVisibility()
	v5_.activatable = ShopTriggerActivatable.new(v5_)
	return v5_
end

function ShopTrigger:delete()
	g_messageCenter:unsubscribeAll(self)
	if self.triggerId ~= nil then
		removeTrigger(self.triggerId)
	end
	self.shopSymbol = nil
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
end

-- Local values: x, y, z, dx, _, dz
function ShopTrigger:openShop()
	if g_guidedTourManager:getIsTourRunning() then
		InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
	else
		g_gui:changeScreen(nil, ShopMenu)
		local v8_, v9_, v10_ = getWorldTranslation(self.shopPlayerSpawn)
		local v11_, _, v12_ = localDirectionToWorld(self.shopPlayerSpawn, 0, 0, -1)
		g_localPlayer:teleportTo(v8_, v9_, v10_)
		g_localPlayer:setMovementYaw(MathUtil.getYRotationFromDirection(v11_, v12_))
	end
end

function ShopTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (g_currentMission.missionInfo:isa(FSCareerMissionInfo) and (onEnter or onLeave)) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
		if onEnter then
			if Platform.gameplay.autoActivateTrigger and self.activatable:getIsActivatable() then
				self.activatable:run()
			else
				g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
			end
		end
		g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	end
end

-- Local values: isAvailable, farmId, visibleForFarm, settingVisible
function ShopTrigger:updateIconVisibility()
	if self.shopSymbol ~= nil then
		local v18_ = self.isEnabled
		if v18_ then
			v18_ = g_currentMission.missionInfo:isa(FSCareerMissionInfo)
		end
		local v19_ = g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID
		local v20_ = g_gameSettings:getValue(GameSettings.SETTING.SHOW_TRIGGER_MARKER)
		local v21_ = setVisibility
		local v22_ = self.shopSymbol
		if v18_ then
			if not v19_ then
				v20_ = v19_
			end
		else
			v20_ = v18_
		end
		v21_(v22_, v20_)
	end
end

function ShopTrigger:playerFarmChanged(player)
	if player == g_localPlayer then
		self:updateIconVisibility()
	end
end

function ShopTrigger:onTriggerVisibilityChanged()
	self:updateIconVisibility()
end
ShopTriggerActivatable = {}
local v_u_26_ = Class(ShopTriggerActivatable)
function ShopTriggerActivatable.new(p27_)
	-- upvalues: (copy) v_u_26_
	local v28_ = v_u_26_
	local v29_ = setmetatable({}, v28_)
	v29_.shopTrigger = p27_
	v29_.activateText = g_i18n:getText("action_activateShop")
	return v29_
end

function ShopTriggerActivatable:getIsActivatable()
	local v31_ = self.shopTrigger.isEnabled and not g_localPlayer:getIsInVehicle()
	if v31_ then
		v31_ = g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID
	end
	return v31_
end

function ShopTriggerActivatable:run()
	self.shopTrigger:openShop()
end
