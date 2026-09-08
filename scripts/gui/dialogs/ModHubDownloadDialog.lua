-- Local values: ModHubDownloadDialog_mt
ModHubDownloadDialog = {}
local ModHubDownloadDialog_mt = Class(ModHubDownloadDialog, MessageDialog)
function ModHubDownloadDialog.register()
	local v2_ = ModHubDownloadDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/ModHubDownloadDialog.xml", "ModHubDownloadDialog", v2_)
	ModHubDownloadDialog.INSTANCE = v2_
end

-- Local values: dialog
function ModHubDownloadDialog.show(downloads)
	if ModHubDownloadDialog.INSTANCE ~= nil then
		local _ = ModHubDownloadDialog.INSTANCE
		g_gui:showDialog("ModHubDownloadDialog")
	end
end

-- Upvalues: ModHubDownloadDialog_mt
-- Local values: self
function ModHubDownloadDialog.new(target, custom_mt)
	-- upvalues: (copy) ModHubDownloadDialog_mt
	local v5_ = MessageDialog.new(target, custom_mt or ModHubDownloadDialog_mt)
	v5_.activeDownloads = nil
	v5_.updateTime = 200
	v5_.disableOpenSound = true
	return v5_
end

function ModHubDownloadDialog.createFromExistingGui(gui, guiName)
	ModHubDownloadDialog.register()
	ModHubDownloadDialog.show()
end

function ModHubDownloadDialog:onOpen()
	ModHubDownloadDialog:superClass().onOpen(self)
	self:updateActiveDownloads()
end

-- Local values: category, categoryId
function ModHubDownloadDialog:updateActiveDownloads()
	local v8_ = g_modHubController:getCategory("download")
	self.activeDownloads = {}
	if v8_ ~= nil then
		local v9_ = v8_.id
		self.activeDownloads = g_modHubController:getModsByCategory(v9_, true)
	end
	self.downloadList:reloadData()
end

-- Local values: isDownloading, isInstalled, isDownload, isFailed, percent, downloadedKBText, downloaded, fileSize, fileSizeKB, fileSizeMB, downloadedKB, downloadedMB, fileSizeText, downloadedText, statusBar, minSize
function ModHubDownloadDialog:updateDownloadCell(cell, modInfo)
	local v12_ = modInfo:getIsDownloading()
	local v13_ = modInfo:getIsInstalled()
	local v14_ = modInfo:getIsDownload()
	local v15_ = modInfo:getIsFailed()
	local v16_ = 0
	local v17_ = ""
	if v12_ or v14_ then
		local v18_ = modInfo:getDownloadedBytes()
		local v19_ = modInfo:getFilesize()
		local v20_ = v19_ / 1024
		local v21_ = v20_ / 1024
		local v22_ = v18_ / 1024
		local v23_ = v22_ / 1024
		local v24_
		if v21_ < 1 then
			v24_ = string.format("%d KB", v20_)
		else
			v24_ = string.format("%d MB", v21_)
		end
		local v25_
		if v23_ < 1 then
			v25_ = string.format("%d KB", v22_)
		else
			v25_ = string.format("%d MB", v23_)
		end
		v17_ = string.format("( %s / %s )", v25_, v24_)
		if v19_ ~= 0 then
			local v26_ = v18_ / v19_
			v16_ = math.clamp(v26_, 0, 1) or v16_
		end
	elseif v13_ then
		v16_ = 1
	end
	local v27_ = cell:getAttribute("statusBar")
	local v28_ = v27_.startSize[1] + v27_.endSize[1]
	local v29_ = v27_.parent.size[1] * v16_ + g_pixelSizeX
	v27_:setSize(math.max(v29_, v28_), nil)
	cell:getAttribute("percentage"):setText(v17_ .. " " .. g_i18n:formatNumber(v16_ * 100, 0) .. "%")
	v27_.parent:setVisible(not v15_)
	cell:getAttribute("failed"):setVisible(v15_)
end

function ModHubDownloadDialog:update(dt)
	ModHubDownloadDialog:superClass().update(self, dt)
	self.updateTime = self.updateTime - dt
	if self.updateTime < 0 then
		self:updateActiveDownloads()
		self.updateTime = 200
	end
end

function ModHubDownloadDialog:getNumberOfItemsInSection(list, section)
	return #self.activeDownloads
end

-- Local values: modInfo, iconElement
function ModHubDownloadDialog:populateCellForItemInSection(list, section, index, cell)
	local v36_ = self.activeDownloads[index]
	local v37_ = cell:getAttribute("icon")
	v37_:setIsWebOverlay(not v36_:getIsIconLocal())
	v37_:setImageFilename(v36_:getIconFilename())
	cell:getAttribute("name"):setText(v36_:getName())
	self:updateDownloadCell(cell, v36_)
end
