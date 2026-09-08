-- Local values: Farm_mt
Farm = {}
Farm.MIN_LOAN = 500000
Farm.MAX_LOAN = 3000000
Farm.EQUITY_LOAN_RATIO = 0.8
Farm.LOAN_INTEREST_RATE = 0.04
Farm.MAX_NUM_SAVED_PLAYERS = 150
Farm.MAX_NUM_DAYS_OFFLINE = 30
Farm.PERMISSION = {
	["BUY_VEHICLE"] = "buyVehicle",
	["SELL_VEHICLE"] = "sellVehicle",
	["BUY_PLACEABLE"] = "buyPlaceable",
	["SELL_PLACEABLE"] = "sellPlaceable",
	["MANAGE_CONTRACTS"] = "manageContracts",
	["TRADE_ANIMALS"] = "tradeAnimals",
	["CREATE_FIELDS"] = "createFields",
	["LANDSCAPING"] = "landscaping",
	["HIRE_ASSISTANT"] = "hireAssistant",
	["RESET_VEHICLE"] = "resetVehicle",
	["MANAGE_PRODUCTIONS"] = "manageProductions",
	["CUT_TREES"] = "cutTrees",
	["MANAGE_RIGHTS"] = "manageRights",
	["TRANSFER_MONEY"] = "transferMoney",
	["UPDATE_FARM"] = "updateFarm",
	["MANAGE_CONTRACTING"] = "manageContracting"
}
Farm.PERMISSIONS = {
	Farm.PERMISSION.BUY_VEHICLE,
	Farm.PERMISSION.SELL_VEHICLE,
	Farm.PERMISSION.BUY_PLACEABLE,
	Farm.PERMISSION.SELL_PLACEABLE,
	Farm.PERMISSION.MANAGE_CONTRACTS,
	Farm.PERMISSION.TRADE_ANIMALS,
	Farm.PERMISSION.CREATE_FIELDS,
	Farm.PERMISSION.LANDSCAPING,
	Farm.PERMISSION.HIRE_ASSISTANT,
	Farm.PERMISSION.RESET_VEHICLE,
	Farm.PERMISSION.MANAGE_PRODUCTIONS,
	Farm.PERMISSION.CUT_TREES,
	Farm.PERMISSION.MANAGE_RIGHTS,
	Farm.PERMISSION.TRANSFER_MONEY,
	Farm.PERMISSION.UPDATE_FARM,
	Farm.PERMISSION.MANAGE_CONTRACTING
}
Farm.NO_PERMISSIONS = {}
Farm.DEFAULT_PERMISSIONS = {}
Farm.COLORS = {
	{
		1,
		0.4287,
		0,
		1
	},
	{
		1,
		0.1221,
		0.0003,
		1
	},
	{
		0.7084,
		0.0203,
		0.2086,
		1
	},
	{
		0.2541,
		0.0065,
		0.5089,
		1
	},
	{
		0.1921,
		0.0976,
		0.8632,
		1
	},
	{
		0.1248,
		0.2541,
		1,
		1
	},
	{
		0.1248,
		0.9216,
		1,
		1
	},
	{
		0.2307,
		1,
		0.2232,
		1
	}
}
Farm.COLOR_SEND_NUM_BITS = 4
Farm.ICON_UVS = {
	{
		330,
		0,
		256,
		256
	},
	{
		660,
		0,
		256,
		256
	},
	{
		330,
		310,
		256,
		256
	},
	{
		0,
		310,
		256,
		256
	},
	{
		660,
		310,
		256,
		256
	},
	{
		0,
		620,
		256,
		256
	},
	{
		330,
		620,
		256,
		256
	},
	{
		660,
		620,
		256,
		256
	}
}
Farm.ICON_SLICE_IDS = {
	"gui.multiplayer_chicken",
	"gui.multiplayer_goat",
	"gui.multiplayer_pig",
	"gui.multiplayer_horse",
	"gui.multiplayer_bull",
	"gui.multiplayer_chainsaw",
	"gui.multiplayer_barn",
	"gui.multiplayer_vehicle"
}
Farm.COLOR_SPECTATOR = {
	0,
	0,
	0,
	0
}
Farm.COLOR_NO_FARM = {
	0.89627,
	0.92158,
	0.81485,
	1
}
Farm.COLOR_SINGLEPLAYER = {
	0.22323,
	0.40724,
	0.00368,
	1
}
local Farm_mt = Class(Farm, Object)
InitStaticObjectClass(Farm, "Farm")

-- Upvalues: Farm_mt
-- Local values: self
function Farm.new(isServer, isClient, spectator, customMt)
	-- upvalues: (copy) Farm_mt
	local v6_ = Object.new(isServer, isClient, customMt or Farm_mt)
	v6_.farmId = nil
	v6_.name = ""
	v6_.color = 1
	v6_.showInFarmScreen = true
	v6_.isSpectator = spectator or false
	v6_:setInitialEconomy()
	v6_.players = {}
	v6_.uniqueUserIdToPlayer = {}
	v6_.userIdToPlayer = {}
	v6_.activeUsers = {}
	v6_.contractingFor = {}
	v6_.stats = FarmStats.new()
	g_messageCenter:subscribe(MessageType.FARM_PROPERTY_CHANGED, v6_.farmPropertyChanged, v6_)
	if v6_.isServer then
		g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, v6_.periodChanged, v6_)
	end
	v6_.farmMoneyDirtyFlag = v6_:getNextDirtyFlag()
	v6_.lastMoneySent = v6_.money
	v6_.lastMoneyPublished = v6_.money
	return v6_
end

function Farm:setInitialEconomy()
	self.loanMax = 0
	self:updateMaxLoan()
	if self.isSpectator then
		self.money = 0
		self.loan = 0
	else
		self.money = g_currentMission.missionInfo.initialMoney
		self.loan = g_currentMission.missionInfo.initialLoan
	end
end

function Farm:delete()
	g_messageCenter:unsubscribeAll(self)
	Farm:superClass().delete(self)
end

-- Local values: _, playerKey, player, _, permission, _, contractKey, farmId
function Farm:loadFromXMLFile(xmlFile, key)
	self.farmId = xmlFile:getInt(key .. "#farmId")
	self.name = xmlFile:getString(key .. "#name")
	self.color = xmlFile:getInt(key .. "#color")
	self.password = xmlFile:getString(key .. "#password")
	self.loan = xmlFile:getFloat(key .. "#loan", 0)
	self.money = xmlFile:getFloat(key .. "#money", 9999999999)
	for _, v12_ in xmlFile:iterator(key .. ".players.player") do
		local v13_ = {
			["uniqueUserId"] = xmlFile:getString(v12_ .. "#uniqueUserId"),
			["isFarmManager"] = xmlFile:getBool(v12_ .. "#farmManager", false),
			["lastNickname"] = xmlFile:getString(v12_ .. "#lastNickname", ""),
			["timeLastConnected"] = xmlFile:getString(v12_ .. "#timeLastConnected") or getDate("%Y/%m/%d %H:%M"),
			["permissions"] = {}
		}
		for _, v14_ in ipairs(Farm.PERMISSIONS) do
			v13_.permissions[v14_] = xmlFile:getBool(v12_ .. "#" .. v14_, false) or v13_.isFarmManager
		end
		local v15_ = self.players
		table.insert(v15_, v13_)
		self.uniqueUserIdToPlayer[v13_.uniqueUserId] = v13_
	end
	for _, v16_ in xmlFile:iterator(key .. ".contracting.farm") do
		local v17_ = xmlFile:getInt(v16_ .. "#farmId")
		self.contractingFor[v17_] = true
	end
	self.stats:loadFromXMLFile(xmlFile, key)
	return true
end

-- Local values: playersToSave, yearCur, monthCur, dayCur, hourCur, minuteCur, maxTimeSinceLastConnectionSec, xmlIndex, i, player, playerKey, year, month, day, hour, minute, _, permission, value
function Farm:saveToXMLFile(xmlFile, key)
	xmlFile:setInt(key .. "#farmId", self.farmId)
	xmlFile:setString(key .. "#name", self.name)
	xmlFile:setInt(key .. "#color", self.color)
	if self.password ~= nil then
		xmlFile:setString(key .. "#password", self.password)
	end
	xmlFile:setFloat(key .. "#loan", self.loan)
	xmlFile:setFloat(key .. "#money", self.money)
	local v21_ = table.clone(self.players)
	table.sort(v21_, function(p22_, p23_)
		return p22_.timeLastConnected > p23_.timeLastConnected
	end)
	local v24_, v25_, v26_, v27_, v28_ = string.match(getDate("%Y/%m/%d %H:%M"), "(%d+)/(%d+)/(%d+) (%d+):(%d+)")
	local v29_ = tonumber(v24_)
	local v30_ = tonumber(v25_)
	local v31_ = tonumber(v26_)
	local v32_ = tonumber(v27_)
	local v33_ = tonumber(v28_)
	local v34_ = Farm.MAX_NUM_DAYS_OFFLINE * 24 * 60 * 60
	local v35_ = 0
	for _, v36_ in ipairs(v21_) do
		local v37_ = string.format("%s.players.player(%d)", key, v35_)
		if Farm.MAX_NUM_SAVED_PLAYERS <= v35_ then
			local v38_, v39_, v40_, v41_, v42_ = string.match(v36_.timeLastConnected, "(%d+)/(%d+)/(%d+) (%d+):(%d+)")
			local v43_ = tonumber(v38_)
			local v44_ = tonumber(v39_)
			local v45_ = tonumber(v40_)
			local v46_ = tonumber(v41_)
			local v47_ = tonumber(v42_)
			if v43_ then
				local v48_ = getDateDiffSeconds(v43_, v44_, v45_, v46_, v47_, 0, v29_, v30_, v31_, v32_, v33_, 0)
				if v34_ < math.abs(v48_) then
					Logging.info("Excluded %d players from \'%s\': Limit reached and affected players did not join the server for more than %d days", #v21_ - v35_, xmlFile:getFilename(), Farm.MAX_NUM_DAYS_OFFLINE)
					break
				end
			end
		end
		xmlFile:setString(v37_ .. "#uniqueUserId", v36_.uniqueUserId)
		xmlFile:setBool(v37_ .. "#farmManager", v36_.isFarmManager)
		xmlFile:setString(v37_ .. "#lastNickname", v36_.lastNickname or "")
		xmlFile:setString(v37_ .. "#timeLastConnected", v36_.timeLastConnected)
		for _, v49_ in ipairs(Farm.PERMISSIONS) do
			local v50_ = Utils.getNoNil(v36_.permissions[v49_], false)
			xmlFile:setBool(v37_ .. "#" .. v49_, v50_)
		end
		v35_ = v35_ + 1
	end
	xmlFile:setTable(key .. ".contracting.farm", self.contractingFor, function(p51_, _, p52_)
		-- upvalues: (copy) xmlFile
		xmlFile:setInt(p51_ .. "#farmId", p52_)
	end)
	self.stats:saveToXMLFile(xmlFile, key)
end

-- Local values: numPlayers, _, player, _, permission, farmId, _
function Farm:writeStream(streamId, connection)
	Farm:superClass().writeStream(self, streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteString(streamId, self.name)
	streamWriteUIntN(streamId, self.color, Farm.COLOR_SEND_NUM_BITS)
	streamWriteFloat32(streamId, self.money)
	streamWriteFloat32(streamId, self.loan)
	streamWriteBool(streamId, self.isSpectator)
	streamWriteBool(streamId, self.showInFarmScreen)
	local v56_ = #self.activeUsers
	streamWriteUInt8(streamId, v56_)
	for _, v57_ in ipairs(self.activeUsers) do
		User.streamWriteUserId(streamId, v57_.userId)
		streamWriteBool(streamId, v57_.isFarmManager)
		for _, v58_ in ipairs(Farm.PERMISSIONS) do
			streamWriteBool(streamId, v57_.permissions[v58_] or v57_.isFarmManager)
		end
	end
	streamWriteUInt8(streamId, table.size(self.contractingFor))
	for v59_, _ in pairs(self.contractingFor) do
		streamWriteUIntN(streamId, v59_, FarmManager.FARM_ID_SEND_NUM_BITS)
	end
end

-- Local values: numPlayers, _, player, _, permission, numContracting, _, farmId
function Farm:readStream(streamId, connection)
	Farm:superClass().readStream(self, streamId, connection)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.name = streamReadString(streamId)
	self.color = streamReadUIntN(streamId, Farm.COLOR_SEND_NUM_BITS)
	self.money = streamReadFloat32(streamId)
	self.loan = streamReadFloat32(streamId)
	self.isSpectator = streamReadBool(streamId)
	self.showInFarmScreen = streamReadBool(streamId)
	if self.farmId == FarmManager.SPECTATOR_FARM_ID then
		self.isSpectator = true
	end
	local v63_ = streamReadUInt8(streamId)
	self.players = {}
	self.activeUsers = {}
	for _ = 1, v63_ do
		local v64_ = {
			["userId"] = User.streamReadUserId(streamId),
			["isFarmManager"] = streamReadBool(streamId),
			["permissions"] = {}
		}
		for _, v65_ in ipairs(Farm.PERMISSIONS) do
			v64_.permissions[v65_] = streamReadBool(streamId)
		end
		self.userIdToPlayer[v64_.userId] = v64_
		local v66_ = self.players
		table.insert(v66_, v64_)
		local v67_ = self.activeUsers
		table.insert(v67_, v64_)
	end
	for _ = 1, streamReadUInt8(streamId) do
		local v68_ = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		self.contractingFor[v68_] = true
	end
end

function Farm:writeUpdateStream(streamId, connection, dirtyMask)
	Farm:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	local v73_ = streamWriteBool
	local v74_ = self.farmMoneyDirtyFlag
	if v73_(streamId, bit32.band(dirtyMask, v74_) ~= 0) then
		streamWriteFloat32(streamId, self.money)
		self.lastMoneySent = self.money
	end
end

function Farm:readUpdateStream(streamId, timestamp, connection)
	Farm:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if streamReadBool(streamId) then
		self.money = streamReadFloat32(streamId)
		g_messageCenter:publish(MessageType.MONEY_CHANGED, self.farmId, self.money)
	end
end

function Farm:merge(other)
	self.money = self.money + other.money
	self.loan = self.loan + other.loan
	self.stats:merge(other.stats)
end

-- Local values: player, _, permission
function Farm:resetToSingleplayer()
	local v82_ = {
		["uniqueUserId"] = getUniqueUserId(),
		["isFarmManager"] = true,
		["permissions"] = {}
	}
	for _, v83_ in ipairs(Farm.PERMISSIONS) do
		v82_.permissions[v83_] = true
	end
	v82_.timeLastConnected = getDate("%Y/%m/%d %H:%M")
	self.players = { v82_ }
	self.color = 1
	self.uniqueUserIdToPlayer[v82_.uniqueUserId] = v82_
end

function Farm:getId()
	return self.farmId
end

function Farm:getFarmhouse()
	return g_currentMission.placeableSystem:getFarmhouse(self.farmId)
end

-- Local values: farmhouse
function Farm:getSpawnPoint()
	if not self.isSpectator then
		local v87_ = self:getFarmhouse()
		if v87_ ~= nil then
			return v87_:getSpawnPoint()
		end
	end
	return g_mission00StartPoint
end

-- Local values: farmhouse
function Farm:getSleepCamera()
	if not self.isSpectator then
		local v89_ = self:getFarmhouse()
		if v89_ ~= nil then
			return v89_:getSleepCamera()
		end
	end
	return nil
end

function Farm:getNumActivePlayers()
	return #self.activeUsers
end

function Farm:getNumPlayers()
	return #self.players
end

function Farm:getActiveUsers()
	return self.activeUsers
end

-- Local values: player
function Farm:isUserFarmManager(userId)
	local v95_ = self.userIdToPlayer[userId]
	local v96_
	if v95_ == nil then
		v96_ = false
	else
		v96_ = v95_.isFarmManager
	end
	return v96_
end

-- Local values: player
function Farm:getUserPermissions(userId)
	local v99_ = self.userIdToPlayer[userId]
	return v99_ ~= nil and v99_.permissions or Farm.NO_PERMISSIONS
end

-- Local values: player
function Farm:setUserPermission(userId, permission, hasPermission)
	local v104_ = self.userIdToPlayer[userId]
	if v104_ ~= nil then
		v104_.permissions[permission] = hasPermission
		g_client:getServerConnection():sendEvent(PlayerPermissionsEvent.new(userId, v104_.permissions, v104_.isFarmManager))
	end
end

-- Local values: player, fullPermissions, _, permissionKey
function Farm:promoteUser(userId)
	if self.userIdToPlayer[userId] ~= nil then
		local v107_ = {}
		for _, v108_ in ipairs(Farm.PERMISSIONS) do
			v107_[v108_] = true
		end
		g_client:getServerConnection():sendEvent(PlayerPermissionsEvent.new(userId, v107_, true))
	end
end

-- Local values: player, fullPermissions, _, permissionKey
function Farm:demoteUser(userId)
	if self.userIdToPlayer[userId] ~= nil then
		local v111_ = {}
		for _, v112_ in ipairs(Farm.PERMISSIONS) do
			v111_[v112_] = false
		end
		g_client:getServerConnection():sendEvent(PlayerPermissionsEvent.new(userId, v111_, false))
	end
end

function Farm:canBeDestroyed()
	if #self.activeUsers > 0 then
		return false, "ui_farmDeleteHasPlayers"
	else
		return true
	end
end

function Farm:getColor()
	if g_currentMission.missionDynamicInfo.isMultiplayer then
		if self.isSpectator then
			return Farm.COLOR_SPECTATOR
		else
			return Farm.COLORS[self.color]
		end
	else
		return Farm.COLOR_SINGLEPLAYER
	end
end

function Farm:getIconUVs()
	return Farm.ICON_UVS[self.color]
end

function Farm:getIconSliceId()
	return Farm.ICON_SLICE_IDS[self.color]
end

function Farm:getIsContractingFor(farmId)
	return self.contractingFor[farmId] or false
end

function Farm:setIsContractingFor(farmId, isContracting, noSendEvent)
	if self.isServer or noSendEvent then
		if isContracting then
			self.contractingFor[farmId] = true
		else
			self.contractingFor[farmId] = nil
		end
		if self.isServer and not noSendEvent then
			g_server:broadcastEvent(ContractingStateEvent.new(self.farmId, farmId, isContracting))
		end
		g_messageCenter:publish(ContractingStateEvent, self.farmId, farmId, isContracting)
	elseif not noSendEvent then
		g_client:getServerConnection():sendEvent(ContractingStateEvent.new(self.farmId, farmId, isContracting))
	end
end

function Farm:farmPropertyChanged(farmId)
	if farmId == self.farmId and not self.isSpectator then
		self:updateMaxLoan()
	end
end

-- Local values: equity, farmlands, _, farmlandId, farmland, _, placeable
function Farm:getEquity()
	local v126_ = g_farmlandManager:getOwnedFarmlandIdsByFarmId(self.farmId)
	local v127_ = 0
	for _, v128_ in pairs(v126_) do
		v127_ = v127_ + g_farmlandManager:getFarmlandById(v128_).price
	end
	for _, v129_ in pairs(g_currentMission.placeableSystem.placeables) do
		if v129_:getOwnerFarmId() == self.farmId then
			v127_ = v127_ + v129_:getMonetaryValue()
		end
	end
	return v127_
end

-- Local values: roundedTo5000
function Farm:updateMaxLoan()
	local v131_ = MathUtil.snapValue(Farm.EQUITY_LOAN_RATIO * self:getEquity(), 5000)
	local v132_ = Farm.MIN_LOAN
	local v133_ = Farm.MAX_LOAN
	self.loanMax = math.clamp(v131_, v132_, v133_)
end

-- Local values: yearInterest, daysInYear
function Farm:calculateDailyLoanInterest()
	local v135_ = Farm.LOAN_INTEREST_RATE / (g_currentMission.environment.daysPerPeriod * Environment.PERIODS_IN_YEAR) * self.loan
	return math.floor(v135_)
end

-- Local values: statistic
function Farm:changeBalance(amount, moneyType)
	self.money = self.money + amount
	local v139_
	if moneyType == nil then
		v139_ = nil
	else
		v139_ = moneyType.statistic or nil
	end
	self.stats:changeFinanceStats(amount, v139_)
	if amount > 0 then
		self.stats:addHeroStat("moneyEarned", amount)
	end
	local v140_ = self.lastMoneyPublished - self.money
	if math.abs(v140_) >= 1 then
		::l7::
		self:raiseDirtyFlags(self.farmMoneyDirtyFlag)
		self.lastMoneyPublished = self.money
		g_messageCenter:publish(MessageType.MONEY_CHANGED, self.farmId, self.money)
		goto l9
	else
		if g_currentMission.missionDynamicInfo.isMultiplayer then
			local v141_ = self.lastMoneySent - self.money
			if math.abs(v141_) >= 1 then
				goto l7
			end
		end
		::l9::
		return
	end
end

function Farm:addPurchasedCoins(amount)
	self.money = self.money + amount
	g_messageCenter:publish(MessageType.MONEY_CHANGED, self.farmId, self.money)
end

function Farm:getBalance()
	return self.money
end

function Farm:getLoan()
	return self.loan
end

function Farm:periodChanged()
	self.stats:archiveFinances()
end

-- Local values: player, _, permission, _, permission
function Farm:addUser(userId, uniqueUserId, isFarmManager, user)
	if g_currentMission.connectedToDedicatedServer and userId == g_currentMission:getServerUserId() then
		return
	elseif self.userIdToPlayer[userId] == nil then
		local v152_ = {}
		local v153_ = isFarmManager or false
		v152_.isFarmManager = v153_
		v152_.userId = userId
		v152_.permissions = {}
		for _, v154_ in ipairs(Farm.PERMISSIONS) do
			v152_.permissions[v154_] = v153_
		end
		if not v153_ then
			for _, v155_ in pairs(Farm.DEFAULT_PERMISSIONS) do
				v152_.permissions[v155_] = true
			end
		end
		if self.isServer then
			v152_.uniqueUserId = uniqueUserId
			v152_.timeLastConnected = getDate("%Y/%m/%d %H:%M")
			self.uniqueUserIdToPlayer[uniqueUserId] = v152_
		end
		local v156_ = self.players
		table.insert(v156_, v152_)
		local v157_ = self.activeUsers
		table.insert(v157_, v152_)
		self.userIdToPlayer[userId] = v152_
		self:updateLastNickname(userId, user)
	end
end

-- Local values: player
function Farm:removeUser(userId)
	local v160_ = self.userIdToPlayer[userId]
	if v160_ ~= nil then
		table.removeElement(self.players, v160_)
		table.removeElement(self.activeUsers, v160_)
		self.userIdToPlayer[userId] = nil
		if self.isServer then
			self.uniqueUserIdToPlayer[v160_.uniqueUserId] = nil
		end
	end
end

-- Local values: player
function Farm:onUserJoinGame(uniqueUserId, userId, user)
	local v165_ = self.uniqueUserIdToPlayer[uniqueUserId]
	if not g_currentMission.connectedToDedicatedServer or userId ~= g_currentMission:getServerUserId() then
		if self.isSpectator and v165_ == nil then
			self:addUser(userId, uniqueUserId, nil, user)
			return true
		end
		if self.userIdToPlayer[userId] ~= nil then
			return false
		end
		v165_.userId = userId
		self.userIdToPlayer[userId] = v165_
		self:updateLastNickname(userId, user)
		local v166_ = self.activeUsers
		table.insert(v166_, v165_)
		return true
	end
end

-- Local values: player
function Farm:onUserQuitGame(userId)
	local v169_ = self.userIdToPlayer[userId]
	if v169_ ~= nil then
		v169_.userId = nil
		self.userIdToPlayer[userId] = nil
		table.removeElement(self.activeUsers, v169_)
	end
end

-- Local values: player
function Farm:updateLastNickname(userId, user)
	if user == nil then
		user = g_currentMission.userManager:getUserByUserId(userId)
	end
	if user ~= nil then
		self.userIdToPlayer[userId].lastNickname = user:getNickname()
	end
end
