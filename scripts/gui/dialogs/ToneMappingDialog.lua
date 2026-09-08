-- Local values: ToneMappingDialog_mt
ToneMappingDialog = {}
local ToneMappingDialog_mt = Class(ToneMappingDialog, DialogElement)
function ToneMappingDialog.register()
	local v2_ = ToneMappingDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/ToneMappingDialog.xml", "ToneMappingDialog", v2_)
	ToneMappingDialog.INSTANCE = v2_
end
function ToneMappingDialog.show()
	if ToneMappingDialog.INSTANCE ~= nil then
		g_gui:showDialog("ToneMappingDialog")
	end
end

-- Upvalues: ToneMappingDialog_mt
-- Local values: self, i
function ToneMappingDialog.new(target, custom_mt)
	-- upvalues: (copy) ToneMappingDialog_mt
	local v5_ = MessageDialog.new(target, custom_mt or ToneMappingDialog_mt)
	v5_.isBackAllowed = false
	v5_.inputDelay = 250
	v5_.optionTexts = {}
	for v6_ = 0, 1.001, 0.01 do
		local v7_ = v5_.optionTexts
		local v8_ = string.format
		table.insert(v7_, v8_("%.2f", v6_))
	end
	addConsoleCommand("gsToneMapping", "Toggle Tone Mapping dialog visibility", "consoleCommandToneMapping", v5_)
	return v5_
end

function ToneMappingDialog.createFromExistingGui(gui, guiName)
	ToneMappingDialog.register()
	ToneMappingDialog.show()
end

function ToneMappingDialog:onGuiSetupFinished()
	ToneMappingDialog:superClass().onGuiSetupFinished(self)
	self.optionSlope:setTexts(self.optionTexts)
	self.optionToe:setTexts(self.optionTexts)
	self.optionShoulder:setTexts(self.optionTexts)
	self.optionBlackClip:setTexts(self.optionTexts)
	self.optionWhiteClip:setTexts(self.optionTexts)
end

function ToneMappingDialog:onOpen()
	ToneMappingDialog:superClass().onOpen(self)
	self.inputDelay = self.time + 250
	local v11_ = self.optionSlope
	local v12_ = getToneMappingCurveSlope() * 100
	v11_:setState(math.round(v12_) + 1)
	local v13_ = self.optionToe
	local v14_ = getToneMappingCurveToe() * 100
	v13_:setState(math.round(v14_) + 1)
	local v15_ = self.optionShoulder
	local v16_ = getToneMappingCurveShoulder() * 100
	v15_:setState(math.round(v16_) + 1)
	local v17_ = self.optionBlackClip
	local v18_ = getToneMappingCurveBlackClip() * 100
	v17_:setState(math.round(v18_) + 1)
	local v19_ = self.optionWhiteClip
	local v20_ = getToneMappingCurveWhiteClip() * 100
	v19_:setState(math.round(v20_) + 1)
end

function ToneMappingDialog:onClickSlope(state)
	setToneMappingCurveSlope((state - 1) / 100)
end

function ToneMappingDialog:onClickToe(state)
	setToneMappingCurveToe((state - 1) / 100)
end

function ToneMappingDialog:onClickShoulder(state)
	setToneMappingCurveShoulder((state - 1) / 100)
end

function ToneMappingDialog:onClickBlackClip(state)
	setToneMappingCurveBlackClip((state - 1) / 100)
end

function ToneMappingDialog:onClickWhiteClip(state)
	setToneMappingCurveWhiteClip((state - 1) / 100)
end

function ToneMappingDialog:consoleCommandToneMapping()
	if self.isOpen then
		g_gui:closeDialogByName("ToneMappingDialog")
		Logging.info("Closed Tone Mapping dialog")
	else
		self:show()
		Logging.info("Opened Tone Mapping dialog")
	end
end
