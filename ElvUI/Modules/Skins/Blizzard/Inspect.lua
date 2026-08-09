local E, L, V, P, G = unpack(select(2, ...)) -- Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

--Lua functions
local _G = _G
local unpack = unpack
local ipairs = ipairs
local type = type
local hooksecurefunc = hooksecurefunc
--WoW API / Variables
local GetInventoryItemID = GetInventoryItemID
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetInventoryItemLink = GetInventoryItemLink
local CreateFrame = CreateFrame
local floor = math.floor

-- InsetFrameTemplate marble border pieces (parentKeys) to hide.
local INSET_BORDER = {
	"InsetBorderTopLeft", "InsetBorderTopRight",
	"InsetBorderBottomLeft", "InsetBorderBottomRight",
	"InsetBorderTop", "InsetBorderBottom", "InsetBorderLeft", "InsetBorderRight",
}
local GRID_BG_SUFFIX = {
	"Background", "BackgroundTopLeft", "BackgroundTopRight",
	"BackgroundBottomLeft", "BackgroundBottomRight",
}

-- Blank every Texture region a frame owns (leaves child frames / fontstrings alone).
local function blankTextureRegions(frame)
	if not frame or not frame.GetRegions then return end
	for _, r in ipairs({ frame:GetRegions() }) do
		if r.GetObjectType and r:GetObjectType() == "Texture" then
			r:SetAlpha(0)
		end
	end
end

-- Hide rock/marble background textures on a frame by texture path (keeps the rest,
-- e.g. the glyph parchment).
local function hideRockRegions(frame)
	if not frame or not frame.GetRegions then return end
	for _, r in ipairs({ frame:GetRegions() }) do
		if r.GetObjectType and r:GetObjectType() == "Texture" and r.GetTexture then
			local t = r:GetTexture()
			if type(t) == "string" then
				local lt = t:lower()
				if lt:find("ui%-background%-rock") or lt:find("_ui%-frame") then
					r:SetAlpha(0)
				end
			end
		end
	end
end

-- Hide the marble border pieces of an InsetFrameTemplate.
local function hideInsetBorder(inset)
	if not inset then return end
	for _, key in ipairs(INSET_BORDER) do
		local r = inset[key]
		if r then r:SetAlpha(0); if r.Hide then r:Hide() end end
	end
end

S:AddCallbackForAddon("Blizzard_InspectUI", "Skin_Blizzard_InspectUI", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.inspect then return end

	-- =========================================================================
	-- Main window frame + backdrop (one-time)
	-- =========================================================================
	InspectFrame:StripTextures(true)
	InspectFrame:CreateBackdrop("Transparent")
	InspectFrame.backdrop:Point("TOPLEFT", 2, -2)
	InspectFrame.backdrop:Point("BOTTOMRIGHT", -2, 2)

	S:SetUIPanelWindowInfo(InspectFrame, "width")
	S:SetBackdropHitRect(InspectFrame)

	-- Flatten the MetalFrame2X chrome (border + corner ring + spec/ring icon +
	-- redbutton2x close). The server re-textures the ring portrait on every
	-- show/unit-change, so re-flatten on those events.
	local function FlattenChrome()
		if S.HandleMetalFrame then
			S:HandleMetalFrame(InspectFrame, InspectFrame.backdrop)
		end
	end
	FlattenChrome()
	if _G.InspectFrame_UpdateRingPortrait then
		hooksecurefunc("InspectFrame_UpdateRingPortrait", FlattenChrome)
	end

	-- 5 NozdorFinder tabs (Character / PVP / Talents / Symbols / Runes).
	for i = 1, 5 do
		local tab = _G["InspectFrameTab"..i]
		if tab then
			S:HandleTab(tab)
			if tab.backdrop then
				tab.backdrop:Point("TOPLEFT", tab, "TOPLEFT", 2, 0)
				tab.backdrop:Point("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -2, 2)
				tab:SetHitRectInsets(0, 0, 0, 0)
			end
		end
	end

	-- =========================================================================
	-- Paperdoll (gear) — one-time
	-- =========================================================================
	InspectPaperDollFrame:StripTextures()

	local slots = {
		"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot",
		"ShirtSlot", "TabardSlot", "WristSlot", "HandsSlot", "WaistSlot",
		"LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot",
		"Trinket1Slot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot",
	}
	for _, slot in ipairs(slots) do
		local icon = _G["Inspect"..slot.."IconTexture"]
		local frame = _G["Inspect"..slot]
		if frame then
			frame:StripTextures()
			frame:SetFrameLevel(frame:GetFrameLevel() + 2)
			frame:CreateBackdrop("Default")
			frame.backdrop:SetAllPoints()
			frame:StyleButton()
			if icon then
				icon:SetTexCoord(unpack(E.TexCoords))
				icon:SetInside()
			end
		end
	end

	local styleButton
	do
		local function awaitCache(button)
			if InspectFrame.unit then styleButton(button) end
		end
		styleButton = function(button)
			if button.hasItem then
				local itemID = GetInventoryItemID(InspectFrame.unit, button:GetID())
				if itemID then
					local _, _, quality = GetItemInfo(itemID)
					if not quality then
						E:Delay(0.1, awaitCache, button)
						return
					elseif quality then
						button.backdrop:SetBackdropBorderColor(GetItemQualityColor(quality))
						return
					end
				end
			end
			button.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
		end
	end
	hooksecurefunc("InspectPaperDollItemSlotButton_Update", styleButton)

	S:HandleRotateButton(InspectModelRotateLeftButton)
	S:HandleRotateButton(InspectModelRotateRightButton)

	-- =========================================================================
	-- PVP — one-time
	-- =========================================================================
	InspectPVPFrame:StripTextures()
	for i = 1, MAX_ARENA_TEAMS do
		local frame = _G["InspectPVPTeam"..i]
		if frame then
			frame:StripTextures()
			frame:CreateBackdrop("Transparent")
			frame.backdrop:Point("TOPLEFT", 9, -6)
			frame.backdrop:Point("BOTTOMRIGHT", -24, -5)
			S:SetBackdropHitRect(frame)
		end
	end

	-- =========================================================================
	-- Per-tab skinning (re-applied on every tab switch / show)
	-- =========================================================================

	-- Talents: three grid columns wrapped in InsetFrameTemplate (marble border +
	-- tree art) + rock bg + content inset — same as the player. Flat dark panels.
	local function SkinInspectGridColumns()
		for c = 1, 3 do
			local inset = _G["InspectTalentFrameGridColumn"..c.."Inset"]
			if inset then
				hideInsetBorder(inset)
				if inset.Bgs then
					inset.Bgs:Show()
					inset.Bgs:SetHorizTile(false)
					inset.Bgs:SetVertTile(false)
					inset.Bgs:SetTexture("Interface\\Buttons\\WHITE8X8")
					inset.Bgs:SetVertexColor(0, 0, 0, 0.6)
				end
			end
			for _, sfx in ipairs(GRID_BG_SUFFIX) do
				local bg = _G["InspectTalentFrameGridColumn"..c..sfx]
				if bg then bg:SetTexture(nil); bg:SetAlpha(0) end
			end
		end
	end

	local function CleanInspectTalentInset(inset)
		if not inset or not inset.GetRegions then return end
		for _, r in ipairs({ inset:GetRegions() }) do
			if r.GetObjectType and r:GetObjectType() == "Texture" then
				r:SetTexture(nil)
				r:SetAlpha(0)
				-- server re-shows marble on tab switch; noop the setters.
				r.SetTexture = E.noop
				r.SetAlpha = E.noop
				r.Show = E.noop
			end
		end
	end

	local function SkinInspectTalents()
		local frame = _G.InspectTalentFrame
		if not frame then return end
		frame:StripTextures()
		hideRockRegions(frame)
		CleanInspectTalentInset(frame.contentInset or _G.InspectTalentFrameContentInset)
		SkinInspectGridColumns()
	end

	-- Glyphs: keep the server glyph-bg parchment + sockets; flatten the content
	-- inset marble/rock and make the parchment semi-transparent (like the player).
	local function SkinInspectGlyphs()
		local frame = _G.InspectGlyphFrame
		if not frame then return end
		hideRockRegions(frame)
		local inset = frame.contentInset or _G.InspectGlyphFrameContentInset
		if inset then
			hideInsetBorder(inset)
			if inset.Bgs then inset.Bgs:SetAlpha(0) end
		end
		if _G.InspectGlyphFrameBackground then
			_G.InspectGlyphFrameBackground:SetAlpha(0.6)
		end
	end

	-- Runes: native circle (InspectUlduarSecretsFrame) is left alone; only flatten
	-- the host chrome (blank all RuneHost regions incl. leftover metal corners,
	-- hide its stray close button).
	local function SkinInspectRunes()
		local host = _G.InspectRuneFrameHost
		if not host then return end
		blankTextureRegions(host)
		if host.CloseButton then host.CloseButton:Hide() end
	end

	local function SkinCurrentTab()
		SkinInspectTalents()
		SkinInspectGlyphs()
		SkinInspectRunes()
		FlattenChrome()
	end
	SkinCurrentTab()

	-- Grid insets are (re)built lazily by the shared base — catch them there too.
	if _G.TalentFrame_ApplyColumnInsets then
		hooksecurefunc("TalentFrame_ApplyColumnInsets", function(tf)
			if tf == _G.InspectTalentFrame then SkinInspectGridColumns() end
		end)
	end
	-- Re-skin after every tab switch and on show (the full inspect UI flow).
	if _G.InspectSwitchTabs then
		hooksecurefunc("InspectSwitchTabs", SkinCurrentTab)
	end
	if _G.InspectFrame_OnShow then
		hooksecurefunc("InspectFrame_OnShow", SkinCurrentTab)
	end

	-- =========================================================================
	-- Average item level readout — one-time
	-- =========================================================================
	local InspectILvl = InspectPaperDollFrame:CreateFontString(nil, "OVERLAY")
	InspectILvl:FontTemplate(E.LSM:Fetch("font", E.db.general.font), 21, "OUTLINE")
	InspectILvl:Point("TOPLEFT", InspectModelFrame, "BOTTOMLEFT", 100, 50)
	InspectILvl:SetText("—")

	local INSPECT_SLOT_IDS = {
		1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17, 18,
	}
	local function ColorByILvl(ilvl)
		if ilvl <= 190 then
			return GetItemQualityColor(2)
		elseif ilvl <= 200 then
			return GetItemQualityColor(3)
		else
			return GetItemQualityColor(4)
		end
	end
	local function UpdateInspectAverage()
		if not InspectFrame or not InspectFrame.unit or not InspectFrame:IsShown() then return end
		local unit = InspectFrame.unit
		local total, count, needsRetry = 0, 0, false
		for _, slotID in ipairs(INSPECT_SLOT_IDS) do
			local link = GetInventoryItemLink(unit, slotID)
			if link then
				local _, _, _, ilvl = GetItemInfo(link)
				if not ilvl then
					needsRetry = true
				elseif ilvl > 0 then
					total = total + ilvl
					count = count + 1
				end
			end
		end
		if needsRetry then
			E:Delay(0.1, UpdateInspectAverage)
			return
		end
		if count > 0 then
			local rounded = floor(total / count + 0.5)
			InspectILvl:SetFormattedText("%d", rounded)
			InspectILvl:SetTextColor(ColorByILvl(rounded))
		else
			InspectILvl:SetText("—")
			InspectILvl:SetTextColor(1, 1, 1)
		end
	end

	InspectFrame:HookScript("OnShow", UpdateInspectAverage)
	hooksecurefunc("InspectPaperDollItemSlotButton_Update", function()
		if InspectFrame:IsShown() then UpdateInspectAverage() end
	end)

	local InspectILvlEvent = CreateFrame("Frame")
	InspectILvlEvent:RegisterEvent("INSPECT_READY")
	InspectILvlEvent:SetScript("OnEvent", function()
		if InspectFrame:IsShown() then UpdateInspectAverage() end
	end)
end)
