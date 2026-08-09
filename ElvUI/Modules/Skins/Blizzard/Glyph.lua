local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

--Lua functions
local _G = _G
local unpack = unpack
local type = type

S:AddCallbackForAddon("Blizzard_GlyphUI", "Skin_Blizzard_GlyphUI", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.talent then return end

	if not PlayerTalentFrame then
		TalentFrame_LoadUI()
	end

	-- Keep Blizzard's parchment texture; just remove ElvUI's full-frame textures
	GlyphFrame:StripTextures()

	if not GlyphFrame.backdrop then
		GlyphFrame:CreateBackdrop("Transparent")
	end
	GlyphFrame.backdrop:ClearAllPoints()
	GlyphFrame.backdrop:Point("TOPLEFT", 11, -12)
	GlyphFrame.backdrop:Point("BOTTOMRIGHT", -32, 76)
	S:SetBackdropHitRect(GlyphFrame)

	-- Base metal-frame cleanup on the shared PlayerTalentFrame: drop the metal
	-- border + spec ring icon (reskin the close button) and hide the rock/shadow, so
	-- the glyph view doesn't show the leftover ring/corner chrome. The glyph parchment
	-- itself is kept below.
	-- The glyph view has its own full-window rock base (PlayerTalentFrameGlyphRock,
	-- stored as PlayerTalentFrame.glyphRockBase). Blank it so the flat ElvUI
	-- backdrop shows instead of the rock tile bleeding through.
	local function HideGlyphRock()
		local base = _G.PlayerTalentFrame and _G.PlayerTalentFrame.glyphRockBase
		if base then
			if base.GetRegions then
				local j = 1
				while true do
					local r = select(j, base:GetRegions())
					if not r then break end
					if r.SetAlpha then r:SetAlpha(0) end
					j = j + 1
				end
			end
			base:Hide()
		end
	end

	local function CleanTalentChrome()
		if S.HandleMetalFrame and _G.PlayerTalentFrame then
			S:HandleMetalFrame(_G.PlayerTalentFrame, _G.PlayerTalentFrame.backdrop)
		end
		if _G.PlayerTalentFrameBackground then _G.PlayerTalentFrameBackground:SetAlpha(0) end
		if _G.PlayerTalentFrameTopTileStreaks then _G.PlayerTalentFrameTopTileStreaks:SetAlpha(0) end
		HideGlyphRock()
	end
	CleanTalentChrome()
	GlyphFrame:HookScript("OnShow", CleanTalentChrome)

	-- Parchment + glyph rings are OWNED BY THE SERVER now. The redesigned glyph view
	-- draws GlyphFrameBackground (Interface\FrameGeneral\glyph-bg, ~430x408) anchored
	-- to PlayerTalentFrame.contentInset, and positions the six glyph sockets relative
	-- to that background (GlyphFrame_PositionSockets, tuned glyphPositions). The old
	-- ElvUI code re-parented the parchment into its own holder, swapped it for the
	-- Spellbook UI-GlyphFrame texture and re-laid the rings at stock offsets — which
	-- is exactly what made the parchment look zoomed and scattered the rings. Leave
	-- the server layout alone; we only do window chrome + the finder-panel skin.
	-- Just make sure the rock base stays hidden as the view updates.
	hooksecurefunc("GlyphFrame_Update", function()
		if GlyphFrame and GlyphFrame:IsShown() then
			HideGlyphRock()
		end
	end)

	-- Right-hand glyph finder panel (server custom on PlayerTalentFrame.contentInset2):
	-- parchment side-bg, "Поиск" search box, availability dropdown, a bespoke
	-- scrollbar and category header buttons. Reskin them to match the ElvUI window.
	-- Rows themselves are left alone. Everything is created lazily as the list
	-- populates, so skin after the (global) GlyphSidebar_Populate builds it.
	local function BlankTextures(frame)
		if not frame or not frame.GetRegions then return end
		local i = 1
		while true do
			local r = select(i, frame:GetRegions())
			if not r then break end
			if r.GetObjectType and r:GetObjectType() == "Texture" then
				r:SetTexture(nil)
				r:SetAlpha(0)
			end
			i = i + 1
		end
	end

	local function SkinGlyphSidebar()
		local pt = _G.PlayerTalentFrame
		local ci2 = pt and pt.contentInset2
		if not ci2 then return end

		-- Parchment side background -> flat ElvUI backdrop.
		if ci2.Bgs then ci2.Bgs:SetTexture(nil); ci2.Bgs:SetAlpha(0) end
		if not ci2.__euiBackdrop then
			ci2.__euiBackdrop = true
			ci2:CreateBackdrop("Transparent")
		end

		-- Search box + availability dropdown.
		local sb = _G.GlyphFrameSearchBox
		if sb and not sb.__euiSkinned then
			sb.__euiSkinned = true
			S:HandleEditBox(sb)
		end
		local dd = _G.GlyphFrameAvailDropDown
		if dd and not dd.__euiSkinned then
			dd.__euiSkinned = true
			S:HandleDropDownBox(dd)
		end

		-- Bespoke scrollbar: the server drew a black rail + UI-Character-ScrollBar
		-- art onto the list's inset border. Blank that border's textures and give
		-- the scrollbar the ElvUI look.
		local scroll = _G.GlyphFrameListScroll
		if scroll and not scroll.__euiSkinned then
			scroll.__euiSkinned = true
			local border = scroll:GetParent()
			BlankTextures(border)
			if border and not border.__euiBackdrop then
				border.__euiBackdrop = true
				border:CreateBackdrop("Transparent")
			end
			local sbar = _G.GlyphFrameListScrollScrollBar
			if sbar then S:HandleScrollBar(sbar) end
		end

		-- Category header buttons (collapsibleheader plate + "+/-"): strip the
		-- server plate (textures only, keep the label/sign FontStrings) and give
		-- them a flat ElvUI backdrop.
		local list = ci2._glyphList
		if list and list.headers then
			for _, h in ipairs(list.headers) do
				if h and not h.__euiSkinned then
					h.__euiSkinned = true
					BlankTextures(h)
					h:CreateBackdrop("Transparent")
				end
			end
		end
	end
	if _G.GlyphSidebar_Populate then
		hooksecurefunc("GlyphSidebar_Populate", SkinGlyphSidebar)
	end
	GlyphFrame:HookScript("OnShow", SkinGlyphSidebar)

	local function FadeBackdropBG(bd, alpha)
	if not bd then return end
	if not bd.__savedGlyphBG then
		bd.__savedGlyphBG = { bd:GetBackdropColor() }
	end

	local r, g, b = bd.__savedGlyphBG[1], bd.__savedGlyphBG[2], bd.__savedGlyphBG[3]
		bd:SetBackdropColor(r, g, b, alpha)
	end

	local function RestoreBackdropBG(bd)
		if not bd or not bd.__savedGlyphBG then return end
		bd:SetBackdropColor(unpack(bd.__savedGlyphBG))
		bd.__savedGlyphBG = nil
	end

	local function FadeBackdropBorder(bd, alpha)
	if not bd then return end
	if not bd.__savedGlyphBorder then
		bd.__savedGlyphBorder = { bd:GetBackdropBorderColor() }
	end

	local r, g, b = bd.__savedGlyphBorder[1], bd.__savedGlyphBorder[2], bd.__savedGlyphBorder[3]
		bd:SetBackdropBorderColor(r, g, b, alpha)
	end

	local function RestoreBackdropBorder(bd)
		if not bd or not bd.__savedGlyphBorder then return end
		bd:SetBackdropBorderColor(unpack(bd.__savedGlyphBorder))
		bd.__savedGlyphBorder = nil
	end

	-- Keep the original ElvUI behavior hiding Talent UI bits while glyph tab is open
	GlyphFrame:HookScript("OnShow", function()
		PlayerTalentFrameTitleText:Hide()
		PlayerTalentFramePointsBar:Hide()
		PlayerTalentFrameScrollFrame:Hide()
		PlayerTalentFrameStatusFrame:Hide()
		PlayerTalentFrameActivateButton:Hide()

		if PlayerTalentFrame.ElvUI_UpdateTalentOffset then
			PlayerTalentFrame.ElvUI_UpdateTalentOffset(nil, nil, true)
		end
		FadeBackdropBG(GlyphFrame.backdrop, 0)
		FadeBackdropBorder(GlyphFrame.backdrop, 0)
		-- FadeBackdropBG(PlayerTalentFrame.backdrop, 0)
	end)

	GlyphFrame:SetScript("OnHide", function()
		PlayerTalentFrameTitleText:Show()
		PlayerTalentFramePointsBar:Show()
		PlayerTalentFrameScrollFrame:Show()

		if PlayerTalentFrame.ElvUI_UpdateTalentOffset then
			PlayerTalentFrame.ElvUI_UpdateTalentOffset(nil, nil, true)
		end
		RestoreBackdropBG(GlyphFrame.backdrop)
		RestoreBackdropBorder(GlyphFrame.backdrop)
		-- RestoreBackdropBG(PlayerTalentFrame.backdrop)
	end)

	hooksecurefunc(PlayerTalentFrame, "updateFunction", function()
		if GlyphFrame:IsShown() then
			PlayerTalentFramePreviewBar:Hide()
		end
	end)
end)
