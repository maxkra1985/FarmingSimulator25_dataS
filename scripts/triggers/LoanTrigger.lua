-- Local values: LoanTrigger_mt, LoanTriggerActivatable_mt
LoanTrigger = {}
local LoanTrigger_mt = Class(LoanTrigger)

function LoanTrigger:onCreate(id)
	g_currentMission:addNonUpdateable(LoanTrigger.new(id))
end

-- Upvalues: LoanTrigger_mt
-- Local values: self

-- Upvalues: LoanTriggerActivatable_mt
-- Local values: self
function LoanTrigger.new(loanTrigger)
	-- upvalues: (copy) LoanTrigger_mt
	local v4_ = LoanTrigger_mt
	local v5_ = setmetatable({}, v4_)
	if g_currentMission:getIsClient() then
		v5_.triggerId = loanTrigger
		addTrigger(loanTrigger, "triggerCallback", v5_)
	end
	v5_.loanSymbol = getChildAt(loanTrigger, 0)
	v5_.activatable = LoanTriggerActivatable.new(v5_)
	v5_.isEnabled = true
	g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, v5_.playerFarmChanged, v5_)
	v5_:updateIconVisibility()
	return v5_
end

function LoanTrigger:delete()
	g_messageCenter:unsubscribeAll(self)
	if self.triggerId ~= nil then
		removeTrigger(self.triggerId)
	end
	self.loanSymbol = nil
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
end

function LoanTrigger:openFinanceMenu()
	g_gui:showGui("InGameMenu")
	g_messageCenter:publish(MessageType.GUI_INGAME_OPEN_FINANCES_SCREEN)
end

function LoanTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (g_currentMission.missionInfo:isa(FSCareerMissionInfo) and (onEnter or onLeave)) and (g_localPlayer ~= nil and otherId == g_localPlayer.rootNode) then
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
			return
		end
		g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	end
end

-- Local values: isAvailable, farmId, visibleForFarm
function LoanTrigger:updateIconVisibility()
	if self.loanSymbol ~= nil then
		local v12_ = self.isEnabled
		if v12_ then
			v12_ = g_currentMission.missionInfo:isa(FSCareerMissionInfo)
		end
		local v13_ = g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID
		setVisibility(self.loanSymbol, v12_ and v13_)
	end
end

function LoanTrigger:playerFarmChanged(player)
	if player == g_localPlayer then
		self:updateIconVisibility()
	end
end
LoanTriggerActivatable = {}
local v_u_16_ = Class(LoanTriggerActivatable)
function LoanTriggerActivatable.new(p17_)
	-- upvalues: (copy) v_u_16_
	local v18_ = v_u_16_
	local v19_ = setmetatable({}, v18_)
	v19_.loanTrigger = p17_
	v19_.activateText = g_i18n:getText("action_checkFinances")
	return v19_
end

function LoanTriggerActivatable:getIsActivatable()
	local v21_ = self.loanTrigger.isEnabled and not g_localPlayer:getIsInVehicle()
	if v21_ then
		v21_ = g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID
	end
	return v21_
end

function LoanTriggerActivatable:run()
	self.loanTrigger:openFinanceMenu()
end
