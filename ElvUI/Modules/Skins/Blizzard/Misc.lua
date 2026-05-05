local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

--Lua functions
local _G = _G
local type = type
local unpack = unpack
--WoW API / Variables

S:AddCallback("Skin_Misc", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.misc then return end

	-- ESC/Menu Buttons
	GameMenuFrame:StripTextures()
	GameMenuFrame:CreateBackdrop("Transparent")

	local bd = GameMenuFrame.backdrop
	bd:ClearAllPoints()
	bd:SetPoint("TOPLEFT",  GameMenuFrame, "TOPLEFT", 0, 0)
	bd:SetPoint("BOTTOMRIGHT", GameMenuFrame, "BOTTOMRIGHT", 0, -45)

	GameMenuFrameHeader:Point("TOP", 0, 7)

	local handledButtons = {}
	local hookedButtons = {}

	local function GetFeedbackButton()
		return _G.GameMenuButtonFeedback or _G.GameMenuButtonFeedbeck
	end

	local function GetAddonsButton()
		return _G.GameMenuButtonAddons or _G.GameMenuButtonAddOns
	end

	local function SkinGameMenuButton(button)
		if button and not handledButtons[button] then
			S:HandleButton(button)
			handledButtons[button] = true
		end
	end

	local function HideAddonsButton()
		local addonsButton = GetAddonsButton()

		if addonsButton then
			addonsButton:SetScript("OnShow", nil)
			addonsButton:ClearAllPoints()
			addonsButton:Hide()
			addonsButton:SetAlpha(0)
			addonsButton:EnableMouse(false)

			addonsButton.Show = addonsButton.Hide
		end
	end

	local UpdateGameMenuLayout

	local function ScheduleGameMenuLayout()
		UpdateGameMenuLayout()

		if C_Timer and C_Timer.After then
			C_Timer.After(0, UpdateGameMenuLayout)
			C_Timer.After(0.05, UpdateGameMenuLayout)
			C_Timer.After(0.15, UpdateGameMenuLayout)
		end
	end

	local function HookButtonLayout(button)
		if button and not hookedButtons[button] then
			button:HookScript("OnShow", ScheduleGameMenuLayout)
			hookedButtons[button] = true
		end
	end

	UpdateGameMenuLayout = function()
		local feedbackButton = GetFeedbackButton()

		if feedbackButton then
			feedbackButton:SetScript("OnShow", nil)
		end

		HideAddonsButton()

	local handledButtons = {}
	local layoutTicker = CreateFrame("Frame")
	layoutTicker:Hide()

	local function GetFeedbackButton()
		return _G.GameMenuButtonFeedback or _G.GameMenuButtonFeedbeck
	end

	local function GetBlizzardAddonsButton()
		return _G.GameMenuButtonAddons or _G.GameMenuButtonAddOns
	end

	local function KillBlizzardAddonsButton()
		local button = GetBlizzardAddonsButton()

		if button then
			button:SetScript("OnShow", nil)
			button:SetScript("OnClick", nil)
			button:ClearAllPoints()
			button:SetAlpha(0)
			button:EnableMouse(false)
			button:Hide()

			button.Show = function(self)
				self:Hide()
			end
		end
	end

	local function SkinGameMenuButton(button)
		if button and not handledButtons[button] then
			S:HandleButton(button)
			handledButtons[button] = true
		end
	end

	local function UpdateGameMenuLayout()
		local feedbackButton = GetFeedbackButton()

		if feedbackButton then
			feedbackButton:SetScript("OnShow", nil)
		end

		KillBlizzardAddonsButton()

		local menuButtons = {
			_G.GameMenuButtonHelp,
			feedbackButton,

			_G.GameMenuButtonOptions,
			_G.GameMenuButtonSoundOptions,
			_G.GameMenuButtonUIOptions,
			_G.GameMenuButtonKeybindings,
			_G.GameMenuButtonMacros,
			_G.ElvUI_AddonListButton,

			_G.ElvUI_MenuButton,

			_G.GameMenuButtonLogout,
			_G.GameMenuButtonQuit,
			_G.GameMenuButtonContinue,
		}

		local lastButton

		for i = 1, #menuButtons do
			local button = menuButtons[i]

			if button and button:IsShown() then
				SkinGameMenuButton(button)

				button:SetParent(GameMenuFrame)
				button:ClearAllPoints()

				if not lastButton then
					button:Point("TOP", GameMenuFrame, "TOP", 0, -28)
				else
					local offsetY = -1

					if lastButton == feedbackButton and button == _G.GameMenuButtonOptions then
						offsetY = -16
					end

					if lastButton == _G.ElvUI_MenuButton and button == _G.GameMenuButtonLogout then
						offsetY = -16
					end

					button:Point("TOP", lastButton, "BOTTOM", 0, offsetY)
				end

				lastButton = button
			end
		end
	end

	local function ScheduleGameMenuLayout()
		UpdateGameMenuLayout()

		layoutTicker.elapsed = 0
		layoutTicker.count = 0
		layoutTicker:Show()
	end

	layoutTicker:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = self.elapsed + elapsed

		if self.elapsed < 0.05 then return end

		self.elapsed = 0
		self.count = self.count + 1

		UpdateGameMenuLayout()

		if self.count >= 6 then
			self:Hide()
		end
	end)

	ScheduleGameMenuLayout()

	GameMenuFrame:HookScript("OnShow", ScheduleGameMenuLayout)

	if type(_G.GameMenuFrame_Update) == "function" then
		hooksecurefunc("GameMenuFrame_Update", ScheduleGameMenuLayout)
	end
	end

	ScheduleGameMenuLayout()

	GameMenuFrame:HookScript("OnShow", ScheduleGameMenuLayout)

	if type(_G.GameMenuFrame_Update) == "function" then
		hooksecurefunc("GameMenuFrame_Update", ScheduleGameMenuLayout)
	end

	-- Static Popups
	for i = 1, 4 do
		local staticPopup = _G["StaticPopup"..i]
		local itemFrame = _G["StaticPopup"..i.."ItemFrame"]
		local itemFrameBox = _G["StaticPopup"..i.."EditBox"]
		local itemFrameTexture = _G["StaticPopup"..i.."ItemFrameIconTexture"]
		local itemFrameNormal = _G["StaticPopup"..i.."ItemFrameNormalTexture"]
		local itemFrameName = _G["StaticPopup"..i.."ItemFrameNameFrame"]
		local closeButton = _G["StaticPopup"..i.."CloseButton"]
		local wideBox = _G["StaticPopup"..i.."WideEditBox"]

		staticPopup:SetTemplate("Transparent")

		S:HandleEditBox(itemFrameBox)
		itemFrameBox.backdrop:Point("TOPLEFT", -2, -4)
		itemFrameBox.backdrop:Point("BOTTOMRIGHT", 2, 4)

		S:HandleEditBox(_G["StaticPopup"..i.."MoneyInputFrameGold"])
		S:HandleEditBox(_G["StaticPopup"..i.."MoneyInputFrameSilver"])
		S:HandleEditBox(_G["StaticPopup"..i.."MoneyInputFrameCopper"])

		for j = 1, itemFrameBox:GetNumRegions() do
			local region = select(j, itemFrameBox:GetRegions())
			if region and region:GetObjectType() == "Texture" then
				if region:GetTexture() == "Interface\\ChatFrame\\UI-ChatInputBorder-Left" or region:GetTexture() == "Interface\\ChatFrame\\UI-ChatInputBorder-Right" then
					region:Kill()
				end
			end
		end

		closeButton:StripTextures()
		S:HandleCloseButton(closeButton, staticPopup)

		itemFrame:GetNormalTexture():Kill()
		itemFrame:SetTemplate()
		itemFrame:StyleButton()

		hooksecurefunc("StaticPopup_Show", function(which, _, _, data)
			local info = StaticPopupDialogs[which]
			if not info then return nil end

			if info.hasItemFrame then
				if data and type(data) == "table" then
					if data.color then
						itemFrame:SetBackdropBorderColor(unpack(data.color))
					else
						itemFrame:SetBackdropBorderColor(1, 1, 1, 1)
					end
				end
			end
		end)

		itemFrameTexture:SetTexCoord(unpack(E.TexCoords))
		itemFrameTexture:SetInside()

		itemFrameNormal:SetAlpha(0)
		itemFrameName:Kill()

		select(8, wideBox:GetRegions()):Hide()
		S:HandleEditBox(wideBox)
		wideBox:Height(22)

		for j = 1, 3 do
			S:HandleButton(_G["StaticPopup"..i.."Button"..j])
		end
	end

	-- Other Frames
	TicketStatusFrameButton:SetTemplate("Transparent")
	AutoCompleteBox:SetTemplate("Transparent")
	ConsolidatedBuffsTooltip:SetTemplate("Transparent")

	-- Basic Script Errors
	BasicScriptErrors:SetScale(E.global.general.UIScale)
	BasicScriptErrors:SetTemplate("Transparent")
	S:HandleButton(BasicScriptErrorsButton)

	-- BNToast Frame
	BNToastFrame:SetTemplate("Transparent")

	BNToastFrameCloseButton:Size(32)
	S:HandleCloseButton(BNToastFrameCloseButton, BNToastFrame)

	-- Ready Check Frame
	ReadyCheckFrame:EnableMouse(true)
	ReadyCheckFrame:SetTemplate("Transparent")

	S:HandleButton(ReadyCheckFrameYesButton)
	ReadyCheckFrameYesButton:SetParent(ReadyCheckFrame)
	ReadyCheckFrameYesButton:ClearAllPoints()
	ReadyCheckFrameYesButton:Point("TOPRIGHT", ReadyCheckFrame, "CENTER", -3, -5)

	S:HandleButton(ReadyCheckFrameNoButton)
	ReadyCheckFrameNoButton:SetParent(ReadyCheckFrame)
	ReadyCheckFrameNoButton:ClearAllPoints()
	ReadyCheckFrameNoButton:Point("TOPLEFT", ReadyCheckFrame, "CENTER", 4, -5)

	ReadyCheckFrameText:SetParent(ReadyCheckFrame)
	ReadyCheckFrameText:Point("TOP", 0, -15)
	ReadyCheckFrameText:SetTextColor(1, 1, 1)

	ReadyCheckListenerFrame:SetAlpha(0)

	-- Coin PickUp Frame
	CoinPickupFrame:StripTextures()
	CoinPickupFrame:SetTemplate("Transparent")

	S:HandleButton(CoinPickupOkayButton)
	S:HandleButton(CoinPickupCancelButton)

	-- Zone Text Frame
	ZoneTextFrame:ClearAllPoints()
	ZoneTextFrame:Point("TOP", 0, -128)

	-- Stack Split Frame
	StackSplitFrame:SetTemplate("Transparent")
	StackSplitFrame:GetRegions():Hide()
	StackSplitFrame:SetFrameStrata("DIALOG")

	StackSplitFrame.bg1 = CreateFrame("Frame", nil, StackSplitFrame)
	StackSplitFrame.bg1:SetFrameLevel(StackSplitFrame.bg1:GetFrameLevel() - 1)
	StackSplitFrame.bg1:SetTemplate("Transparent")
	StackSplitFrame.bg1:Point("TOPLEFT", 10, -15)
	StackSplitFrame.bg1:Point("BOTTOMRIGHT", -10, 55)

	S:HandleButton(StackSplitOkayButton)
	S:HandleButton(StackSplitCancelButton)

	-- Opacity Frame
	OpacityFrame:StripTextures()
	OpacityFrame:SetTemplate("Transparent")

	S:HandleSliderFrame(OpacityFrameSlider)

	-- Channel Pullout Frame
	ChannelPullout:SetTemplate("Transparent")

	ChannelPulloutBackground:Kill()

	S:HandleTab(ChannelPulloutTab)
	ChannelPulloutTab:Size(107, 26)
	ChannelPulloutTabText:Point("LEFT", ChannelPulloutTabLeft, "RIGHT", 0, 4)

	S:HandleCloseButton(ChannelPulloutCloseButton, ChannelPullout)
	ChannelPulloutCloseButton:Size(32)

	-- Dropdown Menu
	local checkBoxSkin = E.private.skins.dropdownCheckBoxSkin
	local menuLevel = 0
	local maxButtons = 0

	local function dropDownButtonShow(self)
		if self.notCheckable then
			self.check.backdrop:Hide()
		else
			self.check.backdrop:Show()
		end
	end

	local function skinDropdownMenu()
		local updateButtons = maxButtons < UIDROPDOWNMENU_MAXBUTTONS

		if updateButtons or menuLevel < UIDROPDOWNMENU_MAXLEVELS then
			for i = 1, UIDROPDOWNMENU_MAXLEVELS do
				local frame = _G["DropDownList"..i]

				if not frame.isSkinned then
					_G["DropDownList"..i.."Backdrop"]:SetTemplate("Transparent")
					_G["DropDownList"..i.."MenuBackdrop"]:SetTemplate("Transparent")

					frame.isSkinned = true
				end

				if updateButtons then
					for j = 1, UIDROPDOWNMENU_MAXBUTTONS do
						local button = _G["DropDownList"..i.."Button"..j]

						if not button.isSkinned then
							S:HandleButtonHighlight(_G["DropDownList"..i.."Button"..j.."Highlight"])

							if checkBoxSkin then
								local check = _G["DropDownList"..i.."Button"..j.."Check"]
								check:Size(12)
								check:Point("LEFT", 1, 0)
								check:CreateBackdrop()
								check:SetTexture(E.media.normTex)
								check:SetVertexColor(1, 0.82, 0, 0.8)

								button.check = check
								hooksecurefunc(button, "Show", dropDownButtonShow)
							end

							S:HandleColorSwatch(_G["DropDownList"..i.."Button"..j.."ColorSwatch"], 14)

							button.isSkinned = true
						end
					end
				end
			end

			menuLevel = UIDROPDOWNMENU_MAXLEVELS
			maxButtons = UIDROPDOWNMENU_MAXBUTTONS
		end
	end

	skinDropdownMenu()
	hooksecurefunc("UIDropDownMenu_InitializeHelper", skinDropdownMenu)

	-- Chat Menu
	local chatMenus = {
		"ChatMenu",
		"EmoteMenu",
		"LanguageMenu",
		"VoiceMacroMenu",
	}

	ChatMenu:ClearAllPoints()
	ChatMenu:Point("BOTTOMLEFT", ChatFrame1, "TOPLEFT", 0, 30)
	ChatMenu.ClearAllPoints = E.noop
	ChatMenu.SetPoint = E.noop

	local chatMenuOnShow = function(self)
		self:SetBackdropBorderColor(unpack(E.media.bordercolor))
		self:SetBackdropColor(unpack(E.media.backdropfadecolor))
	end

	for i = 1, #chatMenus do
		local frame = _G[chatMenus[i]]
		frame:SetTemplate("Transparent")
		frame:HookScript("OnShow", chatMenuOnShow)

		for j = 1, 32 do
			_G[chatMenus[i].."Button"..j]:StyleButton()
		end
	end

	-- Localization specific frames
	local locale = GetLocale()
	if locale == "koKR" then
		S:HandleButton(GameMenuButtonRatings)

		-- RatingMenuFrame
		RatingMenuFrame:SetTemplate("Transparent")
		RatingMenuFrameHeader:SetTexture()
		S:HandleButton(RatingMenuButtonOkay)

		RatingMenuButtonOkay:Point("BOTTOMRIGHT", -8, 8)
	elseif locale == "ruRU" then
		-- Declension Frame
		DeclensionFrame:SetTemplate("Transparent")

		S:HandleNextPrevButton(DeclensionFrameSetPrev, "left")
		S:HandleNextPrevButton(DeclensionFrameSetNext, "right")
		S:HandleButton(DeclensionFrameOkayButton)
		S:HandleButton(DeclensionFrameCancelButton)

		DeclensionFrameSet:Point("BOTTOM", 0, 40)
		DeclensionFrameOkayButton:Point("RIGHT", DeclensionFrame, "BOTTOM", -3, 19)
		DeclensionFrameCancelButton:Point("LEFT", DeclensionFrame, "BOTTOM", 3, 19)

		hooksecurefunc("DeclensionFrame_Update", function()
			for i = 1, RUSSIAN_DECLENSION_PATTERNS do
				_G["DeclensionFrameDeclension"..i.."Edit"]:SetTemplate("Default")
			end
		end)
	end
end)