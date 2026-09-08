-- Local values: LeaseYesNoDialog_mt
LeaseYesNoDialog = {}
local LeaseYesNoDialog_mt = Class(LeaseYesNoDialog, YesNoDialog)
function LeaseYesNoDialog.register()
	local v2_ = LeaseYesNoDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/LeaseYesNoDialog.xml", "LeaseYesNoDialog", v2_)
	LeaseYesNoDialog.INSTANCE = v2_
end

-- Local values: dialog
function LeaseYesNoDialog.show(callback, target, costsBase, initialCosts, costsPerOperatingHour, costsPerDay)
	if LeaseYesNoDialog.INSTANCE ~= nil then
		local v9_ = LeaseYesNoDialog.INSTANCE
		v9_:setPrices(costsBase, initialCosts, costsPerOperatingHour, costsPerDay)
		v9_:setDialogType(DialogElement.TYPE_QUESTION)
		v9_:setCallback(callback, target)
		g_gui:showDialog("LeaseYesNoDialog")
	end
end

-- Upvalues: LeaseYesNoDialog_mt
-- Local values: self
function LeaseYesNoDialog.new(target, custom_mt)
	-- upvalues: (copy) LeaseYesNoDialog_mt
	return LeaseYesNoDialog:superClass().new(target, custom_mt or LeaseYesNoDialog_mt)
end

-- Local values: callback, target, costsBase, initialCosts, costsPerOperatingHour, costsPerDay
function LeaseYesNoDialog.createFromExistingGui(gui, guiName)
	LeaseYesNoDialog.register()
	local v13_ = gui.callbackFunc
	local v14_ = gui.target
	local v15_ = gui.costsBase
	local v16_ = gui.initialCosts
	local v17_ = gui.costsPerOperatingHour
	local v18_ = gui.costsPerDay
	LeaseYesNoDialog.show(v13_, v14_, v15_, v16_, v17_, v18_)
end

function LeaseYesNoDialog:setPrices(costsBase, initialCosts, costsPerOperatingHour, costsPerDay)
	self.costsBaseValue:setValue(costsBase)
	self.costsPerDayValue:setValue(costsPerDay)
	self.costsPerOperatingHourValue:setValue(costsPerOperatingHour)
	self.leaseText = string.format(g_i18n:getText("shop_doYouWantToLease"), g_i18n:formatMoney(initialCosts, 0, true, true))
	self.dialogTextElement:setText(self.leaseText)
	self.costsBase = costsBase
	self.initialCosts = initialCosts
	self.costsPerOperatingHour = costsPerOperatingHour
	self.costsPerDay = costsPerDay
end
