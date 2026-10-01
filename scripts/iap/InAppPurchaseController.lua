InAppPurchaseController = {}
local InAppPurchaseController_mt = Class(InAppPurchaseController)
InAppPurchaseController.PENDING_DELAY = 1000
function InAppPurchaseController.new()
	local self = setmetatable({}, InAppPurchaseController_mt)
	self.isLoaded = false
	self.isInitialized = false
	self.callbacks = {}
	self.pendingTimer = InAppPurchaseController.PENDING_DELAY
	self.lastNumOfPendingPurchases = 0
	self.ignoreNextPendingPurchaseChange = false
	self.pendingProductsToRestore = {}
	self.xmlPath = "dataS/inAppProducts.xml"
	return self
end
function InAppPurchaseController:load()
	if not self.isLoaded then
		self:loadProductsFromXML()
		if inAppInit ~= nil then
			inAppInit(self.xmlPath)
		end
		self.isLoaded = true
	end
end
function InAppPurchaseController:loadProductsFromXML()
	self.products = {}
	self.productIdToProduct = {}
	local xmlFile = XMLFile.load("products", self.xmlPath)
	if xmlFile ~= nil then
		xmlFile:iterate("inAppPurchases.inAppPurchase", function(index, key)
			local productId = xmlFile:getInt(key .. "#productId")
			if productId == nil then
				Logging.xmlWarning(xmlFile, "Failed to load IAP Product. Missing productId. (%s)", key)
				return
			end
			local isConsumable = xmlFile:getBool(key .. "#isConsumable", true)
			local className = xmlFile:getString(key .. ".product#className")
			if className == nil or className == "" then
				Logging.xmlWarning(xmlFile, "Failed to load IAP Product. Missing product #className (%s)", key)
				return
			end
			local class = ClassUtil.getClassObject(className)
			if class == nil then
				Logging.xmlWarning(xmlFile, "Failed to load IAP Product. Unknown class '%s'. (%s)", className, key)
			else
				local product = class.new(productId, isConsumable)
				if product ~= nil and product:loadFromXMLFile(xmlFile, key .. ".product") then
					table.insert(self.products, product)
					self.productIdToProduct[productId] = product
				end
			end
		end)
		xmlFile:delete()
	end
end
function InAppPurchaseController:setMission(mission)
	self.mission = mission
end
function InAppPurchaseController:getIsAvailable()
	if not self.isInitialized then
		if inAppIsLoaded ~= nil and inAppIsLoaded() then
			self.isInitialized = true
			return true
		end
		return false
	else
		return true
	end
end
function InAppPurchaseController:getProducts()
	return self.products
end
function InAppPurchaseController:getProductById(id)
	for i = 1, #self.products do
		local product = self.products[i]
		if product:getId() == id then
			return product
		end
	end
	return nil
end
function InAppPurchaseController:purchase(product, callback)
	assert(product ~= nil and callback ~= nil)
	if self.mission ~= nil then
		self.callbacks[product] = callback
		inAppStartPurchase(product:getId(), "onPurchaseEnd", self)
	end
end
function InAppPurchaseController:onPurchaseEnd(errorCode, productId)
	local product = self.productIdToProduct[productId]
	if errorCode == InAppPurchase.ERROR_OK then
		if self.mission ~= nil then
			product:onProductBought(function(success, warningText)
				if success then
					inAppFinishPurchase(productId)
					self.callbacks[product](true, false, errorCode)
					self:onPendingPurchasesChanged(0)
				else
					self.callbacks[product](false, true, InAppPurchase.ERROR_FAILED)
					self.ignoreNextPendingPurchaseChange = true
				end
			end)
		end
	else
		self.callbacks[product](false, errorCode == InAppPurchase.ERROR_CANCELLED, errorCode)
	end
end
function InAppPurchaseController:getHasPendingPurchase(product)
	local numRecoverablePurchases = inAppGetNumPendingPurchases()
	local productId = product:getId()
	for i = 0, numRecoverablePurchases - 1 do
		local pendingProductId = inAppGetPendingPurchaseProductId(i)
		if pendingProductId == productId then
			return true
		end
	end
	return false
end
function InAppPurchaseController:getHasAnyPendingPurchases()
	return 0 < inAppGetNumPendingPurchases()
end
function InAppPurchaseController:checkPendingPurchasesChanged()
	self.pendingTimer = InAppPurchaseController.PENDING_DELAY
	local num = inAppGetNumPendingPurchases()
	if num ~= self.lastNumOfPendingPurchases then
		if not self.ignoreNextPendingPurchaseChange then
			self:onPendingPurchasesChanged(num - self.lastNumOfPendingPurchases)
		else
			self.ignoreNextPendingPurchaseChange = false
		end
		self.lastNumOfPendingPurchases = num
	end
end
function InAppPurchaseController:onPendingPurchasesChanged(changeAmount)
	if self.pendingPurchaseCallback ~= nil then
		self.pendingPurchaseCallback()
	end
	if 0 < changeAmount then
		local numPendingPurchases = inAppGetNumPendingPurchases()
		if 0 < numPendingPurchases then
			self.pendingProductsToRestore = {}
			for i = numPendingPurchases - changeAmount, numPendingPurchases - 1 do
				local productId = inAppGetPendingPurchaseProductId(i)
				local product = self:getProductById(productId)
				if product == nil then
					continue
				end
				table.insert(self.pendingProductsToRestore, product)
			end
			local function restoreNextProduct()
				if 0 < #self.pendingProductsToRestore then
					local product = self.pendingProductsToRestore[1]
					local callback = function(_, yes)
						if yes then
							self:tryPerformPendingPurchase(product, function(success, warningText)
								local text = g_i18n:getText(success and "ui_iap_purchaseComplete" or "ui_iap_errorFailed")
								if warningText ~= nil then
									text = text .. "\n" .. warningText
								end
								InfoDialog.show(text, function()
									restoreNextProduct()
								end)
							end)
						else
							restoreNextProduct()
						end
					end
					local text = string.format(g_i18n:getText("ui_iap_pendingPurchaseFound"), product:getTitle())
					YesNoDialog.show(callback, self, text)
					table.remove(self.pendingProductsToRestore, 1)
				end
			end
			restoreNextProduct()
		end
	end
end
function InAppPurchaseController:setPendingPurchaseCallback(callback)
	self.pendingPurchaseCallback = callback
end
function InAppPurchaseController:tryPerformPendingPurchase(product, callback)
	assert(product ~= nil and callback ~= nil)
	local numRecoverablePurchases = inAppGetNumPendingPurchases()
	local productId = product:getId()
	for i = 0, numRecoverablePurchases - 1 do
		local pendingProductId = inAppGetPendingPurchaseProductId(i)
		if pendingProductId == productId then
			product:onProductBought(function(success, warningText)
				callback(success, warningText)
				if success then
					inAppFinishPendingPurchase(i)
				end
			end)
			return true
		end
	end
	return false
end
function InAppPurchaseController:getHasPurchasesToRestore()
	if inAppHasRestorePurchases ~= nil then
		inAppHasRestorePurchases()
	end
	return true
end
function InAppPurchaseController:restorePurchases()
	inAppRestorePurchases("onPurchasesRestored", self)
end
function InAppPurchaseController:onPurchasesRestored(errorCode)
	if errorCode == InAppPurchaseResponse.OK then
		InfoDialog.show(g_i18n:getText("ui_iap_purchaseRestoreCompleted"), nil, nil, DialogElement.TYPE_INFO)
	elseif errorCode == InAppPurchaseResponse.PURCHASE_IN_PROGRESS then
		InfoDialog.show(g_i18n:getText("ui_iap_purchaseInProgress"), nil, nil, DialogElement.TYPE_INFO)
	else
		InfoDialog.show(g_i18n:getText("ui_iap_purchaseRestoreFailed"), nil, nil, DialogElement.TYPE_WARNING)
	end
	for k, v in pairs(InAppPurchaseResponse) do
		if v == errorCode then
			Logging.devInfo("Restored In-app purchases (%s):", k)
		end
	end
	for i = 1, #self.products do
		local product = self.products[i]
		Logging.devInfo("Product %d (%s) has been bought: %s", product:getId(), product:getTitle(), product:getHasBeenBought() and "Yes" or "No")
	end
end
function InAppPurchaseController:update(dt)
	if self.isLoaded and self.isInitialized then
		self.pendingTimer = self.pendingTimer - dt
		if self.pendingTimer < 0 then
			self:checkPendingPurchasesChanged()
		end
	end
end
