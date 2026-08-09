local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

--Lua functions
local _G = _G
local unpack = unpack
--WoW API / Variables
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetLFGDungeonRewardLink = GetLFGDungeonRewardLink
local GetLFGDungeonRewards = GetLFGDungeonRewards
local hooksecurefunc = hooksecurefunc

S:AddCallback("Skin_LFD", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.lfd then return end

	LFDQueueFrame:StripTextures(true)
	LFDQueueFrame:CreateBackdrop("Transparent")
	LFDQueueFrame.backdrop:Point("TOPLEFT", 11, -12)
	LFDQueueFrame.backdrop:Point("BOTTOMRIGHT", -3, 4)

	S:HookScript(LFDParentFrame, "OnShow", function(self)
		S:SetUIPanelWindowInfo(self, "width", 341)
		S:SetBackdropHitRect(self, LFDQueueFrame.backdrop)
		S:Unhook(self, "OnShow")
	end)

	S:HandleCloseButton((LFDParentFrame:GetChildren()), LFDQueueFrame.backdrop)

	LFDParentFramePortrait:Kill()

	S:HandleCheckBox(LFDQueueFrameRoleButtonTank.checkButton)
	LFDQueueFrameRoleButtonTank.checkButton:SetFrameLevel(LFDQueueFrameRoleButtonTank.checkButton:GetFrameLevel() + 2)
	S:HandleCheckBox(LFDQueueFrameRoleButtonHealer.checkButton)
	LFDQueueFrameRoleButtonHealer.checkButton:SetFrameLevel(LFDQueueFrameRoleButtonHealer.checkButton:GetFrameLevel() + 2)
	S:HandleCheckBox(LFDQueueFrameRoleButtonDPS.checkButton)
	LFDQueueFrameRoleButtonDPS.checkButton:SetFrameLevel(LFDQueueFrameRoleButtonDPS.checkButton:GetFrameLevel() + 2)
	S:HandleCheckBox(LFDQueueFrameRoleButtonLeader.checkButton)
	LFDQueueFrameRoleButtonLeader.checkButton:SetFrameLevel(LFDQueueFrameRoleButtonLeader.checkButton:GetFrameLevel() + 2)

	S:HandleDropDownBox(LFDQueueFrameTypeDropDown)
	LFDQueueFrameTypeDropDown:HookScript("OnShow", function(self) self:Width(200) end)

	for i = 1, NUM_LFD_CHOICE_BUTTONS do
		local button = _G["LFDQueueFrameSpecificListButton"..i]
		button.enableButton:StripTextures()
		button.enableButton:CreateBackdrop("Default")
		button.enableButton.backdrop:SetInside(nil, 4, 4)

		S:HandleCollapseExpandButton(button.expandOrCollapseButton, "+")
	end

	LFDQueueFrameSpecificListScrollFrame:StripTextures()
	S:HandleScrollBar(LFDQueueFrameRandomScrollFrameScrollBar)
	S:HandleScrollBar(LFDQueueFrameSpecificListScrollFrameScrollBar)

	S:HandleButton(LFDQueueFrameFindGroupButton)
	S:HandleButton(LFDQueueFrameCancelButton)

	S:HandleButton(LFDQueueFramePartyBackfillBackfillButton)
	S:HandleButton(LFDQueueFramePartyBackfillNoBackfillButton)

	S:HandleButton(LFDQueueFrameNoLFDWhileLFRLeaveQueueButton)

	LFDQueueFrameRandomScrollFrameScrollBar:Point("TOPLEFT", LFDQueueFrameRandomScrollFrame, "TOPRIGHT", 5, -22)
	LFDQueueFrameRandomScrollFrameScrollBar:Point("BOTTOMLEFT", LFDQueueFrameRandomScrollFrame, "BOTTOMRIGHT", 5, 19)

	LFDQueueFrameSpecificListScrollFrameScrollBar:Point("TOPLEFT", LFDQueueFrameSpecificListScrollFrame, "TOPRIGHT", 5, -17)
	LFDQueueFrameSpecificListScrollFrameScrollBar:Point("BOTTOMLEFT", LFDQueueFrameSpecificListScrollFrame, "BOTTOMRIGHT", 5, 17)

	LFDQueueFrameFindGroupButton:Point("BOTTOMLEFT", 19, 12)
	LFDQueueFrameCancelButton:Point("BOTTOMRIGHT", -11, 12)

	LFDQueueFrameTypeDropDown:Point("TOPLEFT", 152, -119)

	LFDQueueFrameSpecificListButton1:Point("TOPLEFT", 25, -154)
	LFDQueueFrameRandomScrollFrame:Point("BOTTOMRIGHT", -34, 41)

	LFDQueueFrameCooldownFrame:Size(325, 259)
	LFDQueueFrameCooldownFrame:Point("BOTTOMRIGHT", LFDQueueFrame, "BOTTOMRIGHT", -11, 37)

	LFDQueueFrameCooldownFrame:HookScript("OnShow", function(self)
		self:SetFrameLevel(self:GetParent():GetFrameLevel() + 5)
	end)

	local function skinLFDRandomDungeonLoot(frame)
		if frame.isSkinned then return end

		local icon = _G[frame:GetName().."IconTexture"]
		local nameFrame = _G[frame:GetName().."NameFrame"]
		local count = _G[frame:GetName().."Count"]

		frame:StripTextures()
		frame:CreateBackdrop("Transparent")
		frame.backdrop:SetOutside(icon)

		icon:SetTexCoord(unpack(E.TexCoords))
		icon:SetDrawLayer("BORDER")
		icon:SetParent(frame.backdrop)

		nameFrame:SetSize(118, 39)

		count:SetParent(frame.backdrop)

		frame.isSkinned = true
	end

	local function getLFGDungeonRewardLinkFix(dungeonID, rewardIndex)
		local _, link = GetLFGDungeonRewardLink(dungeonID, rewardIndex)

		if not link then
			E.ScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
			E.ScanTooltip:SetLFGDungeonReward(dungeonID, rewardIndex)
			_, link = E.ScanTooltip:GetItem()
			E.ScanTooltip:Hide()
		end

		return link
	end

	hooksecurefunc("LFDQueueFrameRandom_UpdateFrame", function()
		local dungeonID = LFDQueueFrame.type
		if not dungeonID then return end

		local _, _, _, _, _, numRewards = GetLFGDungeonRewards(dungeonID)
		for i = 1, numRewards do
			local frame = _G["LFDQueueFrameRandomScrollFrameChildFrameItem"..i]
			local name = _G["LFDQueueFrameRandomScrollFrameChildFrameItem"..i.."Name"]

			skinLFDRandomDungeonLoot(frame)

			local link = getLFGDungeonRewardLinkFix(dungeonID, i)
			if link then
				local _, _, quality = GetItemInfo(link)
				if quality then
					local r, g, b = GetItemQualityColor(quality)
					frame.backdrop:SetBackdropBorderColor(r, g, b)
					name:SetTextColor(r, g, b)
				end
			else
				frame.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
				name:SetTextColor(1, 1, 1)
			end
		end
	end)

	-- LFDDungeonReadyStatus
	LFDDungeonReadyStatus:SetTemplate("Transparent")
	S:HandleCloseButton(LFDDungeonReadyStatusCloseButton, nil, "-")

	LFDSearchStatus:SetTemplate("Transparent")

	-- LFDRoleCheckPopup
	LFDRoleCheckPopup:SetTemplate("Transparent")

	S:HandleCheckBox(LFDRoleCheckPopupRoleButtonTank.checkButton)
	S:HandleCheckBox(LFDRoleCheckPopupRoleButtonHealer.checkButton)
	S:HandleCheckBox(LFDRoleCheckPopupRoleButtonDPS.checkButton)

	S:HandleButton(LFDRoleCheckPopupAcceptButton)
	S:HandleButton(LFDRoleCheckPopupDeclineButton)

	-- LFDDungeonReadyDialog
	LFDDungeonReadyDialog:SetTemplate("Transparent")

	LFDDungeonReadyDialog.label:Size(280, 0)
	LFDDungeonReadyDialog.label:Point("TOP", 0, -10)

	LFDDungeonReadyDialog:CreateBackdrop("Default")
	LFDDungeonReadyDialog.backdrop:Point("TOPLEFT", 10, -35)
	LFDDungeonReadyDialog.backdrop:Point("BOTTOMRIGHT", -10, 40)

	LFDDungeonReadyDialog.backdrop:SetFrameLevel(LFDDungeonReadyDialog:GetFrameLevel())
	LFDDungeonReadyDialog.background:SetInside(LFDDungeonReadyDialog.backdrop)

	LFDDungeonReadyDialogFiligree:SetTexture("")
	LFDDungeonReadyDialogBottomArt:SetTexture("")

	S:HandleCloseButton(LFDDungeonReadyDialogCloseButton, nil, "-")

	LFDDungeonReadyDialogEnterDungeonButton:Point("BOTTOMRIGHT", LFDDungeonReadyDialog, "BOTTOM", -7, 10)
	S:HandleButton(LFDDungeonReadyDialogEnterDungeonButton)
	LFDDungeonReadyDialogLeaveQueueButton:Point("BOTTOMLEFT", LFDDungeonReadyDialog, "BOTTOM", 7, 10)
	S:HandleButton(LFDDungeonReadyDialogLeaveQueueButton)

--[[
	LFDDungeonReadyDialogRoleIcon:Size(57)
	LFDDungeonReadyDialogRoleIcon:Point("BOTTOM", 1, 54)
	LFDDungeonReadyDialogRoleIcon:SetTemplate("Default")
	LFDDungeonReadyDialogRoleIconTexture:SetInside()

	function GetTexCoordsForRole(role)
		if role == "GUIDE" then
			return 0.0625, 0.1953125, 0.05859375, 0.19140625
		elseif role == "TANK" then
			return 0.0625, 0.1953125, 0.3203125, 0.453125
		elseif role == "HEALER" ) then
			return 0.32421875, 0.45703125, 0.0546875, 0.1875
		elseif role == "DAMAGER" then
			return 0.32421875, 0.453125, 0.31640625, 0.4453125
		end
	end
	GameTooltip:SetLFGDungeonReward(287, 1)
--]]

	local function skinLFDDungeonReadyDialogReward(button)
		if button.isSkinned then return end

		button:Size(28)
		button:SetTemplate("Default")
		button.texture:SetInside()
		button.texture:SetTexCoord(unpack(E.TexCoords))
		button:DisableDrawLayer("OVERLAY")

		button.isSkinned = true
	end

	hooksecurefunc("LFDDungeonReadyDialogReward_SetMisc", function(button)
		skinLFDDungeonReadyDialogReward(button)

		SetPortraitToTexture(button.texture, "")
		button.texture:SetTexture("Interface\\Icons\\inv_misc_coin_02")
	end)

	hooksecurefunc("LFDDungeonReadyDialogReward_SetReward", function(button, dungeonID, rewardIndex)
		skinLFDDungeonReadyDialogReward(button)

		local link = getLFGDungeonRewardLinkFix(dungeonID, rewardIndex)
		if link then
			local _, _, quality = GetItemInfo(link)
			button:SetBackdropBorderColor(GetItemQualityColor(quality))
		else
			button:SetBackdropBorderColor(unpack(E.media.bordercolor))
		end

		local texturePath = button.texture:GetTexture()
		if texturePath then
			SetPortraitToTexture(button.texture, "")
			button.texture:SetTexture(texturePath)
		end
	end)
end)
-- =====================================================================
-- NOZDOR "Finder" redesign (LFDParentFrame inherits MetalFrame2X natively;
-- the HK_LFDShell re-decorates on every view switch). Applied as its own
-- callback so a crash in the stock LFD skin above can't block it.
--
-- Rather than name every HK_ inset/background one by one, RECURSIVELY sweep the
-- whole finder subtree: flatten any InsetFrameTemplate (Bgs + border pieces) and
-- blank any texture whose file is a known decorative background (rock / marble /
-- blue menu / pvp queue / LFG bg / _UI-Frame inset border / questpaper). Re-run on
-- every view switch + show.
-- =====================================================================
do
	local _G = _G
	local ipairs = ipairs
	local type = type
	local hooksecurefunc = hooksecurefunc

	local INSET_BORDER = {
		"InsetBorderTopLeft", "InsetBorderTopRight",
		"InsetBorderBottomLeft", "InsetBorderBottomRight",
		"InsetBorderTop", "InsetBorderBottom", "InsetBorderLeft", "InsetBorderRight",
	}

	-- Decorative background art paths anywhere in the finder tree. Kept broad on
	-- purpose: [_!]ui-frame catches both _UI-Frame and !UI-Frame; "bluemenu" catches
	-- bluemenu-main AND bluemenu-goldborder-*; char-paperdoll/char-inner catch the
	-- Blizzard divider bars.
	local BG_PATTERNS = {
		"ui%-background%-rock", "ui%-background%-marble", "bluemenu",
		"pvpqueue", "ui%-lfg%-background", "ui%-lfg%-bluebg", "ui%-frame",
		"pvp%-conquest", "questpaper", "dressupbackground", "uigroupfinderflipbook",
		"char%-paperdoll", "char%-inner", "%-goldborder", "common%-dropdown",
		"common%-input%-border",
	}
	local function isBgTexture(t)
		if type(t) ~= "string" then return false end
		local lt = t:lower()
		for _, p in ipairs(BG_PATTERNS) do
			if lt:find(p) then return true end
		end
		return false
	end

	local function hide(obj)
		if obj and obj.SetAlpha then obj:SetAlpha(0) end
	end

	-- Recursively flatten every inset + background texture in a frame subtree, and
	-- skin any dropdown/scrollbar found along the way.
	local function sweep(frame, depth)
		depth = depth or 0
		if not frame or depth > 12 then return end
		-- Skip the arena-points bar: its track/fill/ring use Interface\FrameGeneral\
		-- pvpqueue (same texture as the container bg), so the pattern sweep would
		-- wrongly blank the whole bar. Leave it to the server.
		local apb = _G.HK_PvpDevContainer and _G.HK_PvpDevContainer._hkArenaBar
		if apb and frame == apb then return end
		-- InsetFrameTemplate marble + border pieces (parentKeys).
		local isInset = frame.Bgs ~= nil
		for _, key in ipairs(INSET_BORDER) do
			local r = frame[key]
			if r then isInset = true; if r.SetAlpha then r:SetAlpha(0); if r.Hide then r:Hide() end end end
		end
		if frame.Bgs and frame.Bgs.SetAlpha then frame.Bgs:SetAlpha(0) end
		-- Content panels (a sizeable InsetFrameTemplate) get a dark recessed ElvUI
		-- backdrop so the darkening follows the actual content per view, instead of
		-- one big rectangle. Tiny chrome insets are just flattened above.
		if isInset and not frame.__euiBackdrop and frame.CreateBackdrop and frame.GetWidth then
			local w, h = frame:GetWidth() or 0, frame:GetHeight() or 0
			if w > 60 and h > 60 then
				frame.__euiBackdrop = true
				frame:CreateBackdrop("Transparent")
			end
		end
		-- Own decorative background texture regions.
		if frame.GetRegions then
			for _, r in ipairs({ frame:GetRegions() }) do
				if r.GetObjectType and r:GetObjectType() == "Texture" and r.GetTexture and isBgTexture(r:GetTexture()) then
					r:SetAlpha(0)
				end
			end
		end
		-- Dropdowns / scrollbars found anywhere in the tree.
		local name = frame.GetName and frame:GetName()
		if name and not frame.__euiFinder then
			local ot = frame.GetObjectType and frame:GetObjectType()
			if ot == "Slider" and name:find("ScrollBar$") then
				frame.__euiFinder = true
				if S.HandleScrollBar then S:HandleScrollBar(frame) end
			elseif ot == "EditBox" then
				-- Search fields etc.
				frame.__euiFinder = true
				if S.HandleEditBox then S:HandleEditBox(frame) end
			elseif ot == "Button" and _G[name.."Left"] and _G[name.."Middle"] and _G[name.."Right"] then
				-- 3-slice UIPanelButtonTemplate (e.g. HK_PvpDevContainerJoinBtn).
				frame.__euiFinder = true
				if S.HandleButton then S:HandleButton(frame) end
			elseif ot ~= "Button" and _G[name.."Button"] and _G[name.."Middle"] then
				-- Dropdown (UIDropDownMenu-like): a Frame with an arrow button + middle.
				frame.__euiFinder = true
				if S.HandleDropDownBox then S:HandleDropDownBox(frame) end
				-- Force the ElvUI arrow: HandleDropDownBox skips the arrow when a
				-- backdrop already exists, and the server's custom arrow texture
				-- (common-dropdown-a-button) otherwise stays.
				local ddbtn = _G[name.."Button"]
				if ddbtn and S.HandleNextPrevButton then S:HandleNextPrevButton(ddbtn) end
			end
		end
		-- Recurse into child frames.
		if frame.GetChildren then
			for _, c in ipairs({ frame:GetChildren() }) do
				sweep(c, depth + 1)
			end
		end
	end

	S:AddCallback("Skin_LFD_Nozdor", function()
		if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.lfd then return end
		local frame = _G.LFDParentFrame
		-- Only the redesigned finder (native MetalFrame2X + HK shell).
		if not frame or not _G.HK_LFDShell_SetTab then return end

		-- Flat window backdrop.
		if not frame.backdrop then
			frame:CreateBackdrop("Transparent")
			frame.backdrop:Point("TOPLEFT", 2, -2)
			frame.backdrop:Point("BOTTOMRIGHT", -2, 2)
			S:SetBackdropHitRect(frame)
		end

		-- Chrome: metal border + corner ring + close; hide the eye/ring portrait.
		local function FlattenChrome()
			if S.HandleMetalFrame then S:HandleMetalFrame(frame, frame.backdrop) end
			hide(_G.LFDParentFramePortrait)
			if _G.HK_LFDPortraitFrame then _G.HK_LFDPortraitFrame:Hide() end
		end

		-- Top tabs (Dungeons / PvP / Stats / Gear / Keys).
		local TOP_TABS = {
			"HK_LFDTopTabDungeons", "HK_LFDTopTabPvp", "HK_LFDTopTabStats",
			"HK_LFDTopTabGear", "HK_LFDTopTabKeys",
		}
		local function SkinTabs()
			for _, n in ipairs(TOP_TABS) do
				local tab = _G[n]
				if tab and not tab.__euiSkinned then
					tab.__euiSkinned = true
					if tab.bg then tab.bg:SetAlpha(0) end
					if tab.selection then tab.selection:SetAlpha(0) end
					if S.HandleTab then S:HandleTab(tab) end
					-- Tighten the backdrop to the tab (default HandleTab insets detach it).
					if tab.backdrop then
						tab.backdrop:ClearAllPoints()
						tab.backdrop:Point("TOPLEFT", tab, "TOPLEFT", 2, -2)
						tab.backdrop:Point("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -2, 2)
					end
				end
			end
		end

		-- Battle Pass sidebar button -> small ElvUI button (was 185x44 store art).
		local function SkinButtons()
			local bp = _G.HK_LFDBattlePassButton
			if bp and not bp.__euiSkinned then
				bp.__euiSkinned = true
				if S.HandleButton then S:HandleButton(bp) end
				bp:SetSize(120, 22)
				if bp.Highlight then bp.Highlight:SetTexture(nil) end
				-- Re-centre the "Боевой пропуск" label (was offset for the store icon).
				if bp.GetRegions then
					for _, r in ipairs({ bp:GetRegions() }) do
						if r.GetObjectType and r:GetObjectType() == "FontString" then
							r:ClearAllPoints()
							r:SetPoint("CENTER", bp, "CENTER", 0, 0)
							r:SetJustifyH("CENTER")
						end
					end
				end
			end
		end

		-- Narrow the queue-frame dark backdrop (added by the stock LFD skin) to just
		-- the right-hand content, i.e. right of the sidebar (it spanned the whole width).
		local function FixContentBackdrop()
			local q = _G.LFDQueueFrame
			if q and q.backdrop and _G.HK_LFDSidebar then
				q.backdrop:ClearAllPoints()
				q.backdrop:Point("TOPLEFT", _G.HK_LFDSidebar, "TOPRIGHT", 4, 0)
				q.backdrop:Point("BOTTOMRIGHT", q, "BOTTOMRIGHT", -3, 4)
			end
		end

		local function SkinAll()
			FlattenChrome()
			sweep(frame, 0)
			-- The spectate view (PVPSpectatorFrame) is a sibling frame, not a child of
			-- LFDParentFrame — sweep it too so its buttons/backgrounds get done.
			if _G.PVPSpectatorFrame then sweep(_G.PVPSpectatorFrame, 0) end
			SkinTabs()
			SkinButtons()
			FixContentBackdrop()
		end
		SkinAll()

		if _G.HK_LFDShell_SetTab then
			hooksecurefunc("HK_LFDShell_SetTab", SkinAll)
		end
		frame:HookScript("OnShow", SkinAll)
	end)
end
