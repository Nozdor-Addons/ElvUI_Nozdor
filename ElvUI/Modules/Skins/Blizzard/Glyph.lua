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

	local function MatchTalentFrameSize()
		if PlayerTalentFrame then
			local w, h = PlayerTalentFrame:GetSize()
			if w and h and w > 0 and h > 0 then
				GlyphFrame:SetSize(w, h + 127)
			end
		end
	end

	GlyphFrame:HookScript("OnShow", MatchTalentFrameSize)
	MatchTalentFrameSize()

	-- ==== TUNING ====
	-- Size of the parchment area (and the layout radius) relative to Blizzard's default.
	-- The server redesigned the glyph view: the parchment area is the LEFT inset
	-- (PlayerTalentFrame.contentInset, width 436) and the glyph list lives in the
	-- right inset. Centre the parchment on that left area (not on the whole wide
	-- window) and keep the scale small enough to fit inside it, otherwise the
	-- parchment looks zoomed and the glyph rings spill across the window.
	local paperScale = 1.15
	-- Size of the glyph buttons relative to default
	local slotScale  = 1.0    -- keep close to paperScale
	-- Vertical nudge for the whole parchment block (helps center it visually)
	local yOffset    = 0
	-- =================

	-- Base size used by Blizzard/ElvUI skin in 3.3.5
	local baseW, baseH = 335, 349

	-- Create a real frame to hold parchment + buttons.
	-- IMPORTANT: Buttons cannot be parented to a Texture, only a Frame.
	local holder = _G.GlyphFrameElvUIHolder
	if not holder then
		holder = CreateFrame("Frame", "GlyphFrameElvUIHolder", GlyphFrame)
	end
	-- Anchor to the server's left glyph area when present, so the parchment sits
	-- in the glyph column rather than centred over the whole (wide) glyph window.
	local function AnchorHolder()
		local glyphArea = _G.PlayerTalentFrame and _G.PlayerTalentFrame.contentInset
		holder:ClearAllPoints()
		if glyphArea then
			holder:SetPoint("CENTER", glyphArea, "CENTER", 0, yOffset)
		else
			holder:SetPoint("CENTER", GlyphFrame, "CENTER", 0, yOffset)
		end
		holder:SetSize(baseW * paperScale, baseH * paperScale)
	end
	AnchorHolder()
	holder:SetFrameLevel(GlyphFrame:GetFrameLevel() + 1)

	-- Parchment texture
	GlyphFrameBackground:ClearAllPoints()
	GlyphFrameBackground:SetParent(holder)
	GlyphFrameBackground:SetAllPoints(holder)
	GlyphFrameBackground:SetDrawLayer("BACKGROUND", 0)
	GlyphFrameBackground:SetTexture("Interface\\Spellbook\\UI-GlyphFrame")
	-- texWidth, texHeight, cropWidth, cropHeight, offsetX, offsetY = 512, 512, 315, 340, 21, 72
	GlyphFrameBackground:SetTexCoord(0.041015625, 0.65625, 0.140625, 0.8046875)

	-- Glow
	GlyphFrameGlow:ClearAllPoints()
	GlyphFrameGlow:SetParent(holder)
	GlyphFrameGlow:SetAllPoints(holder)
	GlyphFrameGlow:SetDrawLayer("BACKGROUND", 1)
	GlyphFrameGlow:SetTexture("Interface\\Spellbook\\UI-GlyphFrame-Glow")
	-- texWidth, texHeight, cropWidth, cropHeight, offsetX, offsetY = 512, 512, 315, 340, 30, 34
	GlyphFrameGlow:SetTexCoord(0.05859375, 0.673828125, 0.06640625, 0.73046875)

	-- Positions are relative to CENTER of parchment.
	-- We scale the offsets with paperScale, and scale the buttons with slotScale.
	local glyphPositions = {
		{"CENTER", -1, 126},   -- 1 top
		{"CENTER", -1, -119},  -- 2 bottom
		{"TOPLEFT", 8, -62},   -- 3 top-left
		{"BOTTOMRIGHT", -10, 70}, -- 4 bottom-right
		{"TOPRIGHT", -8, -62}, -- 5 top-right
		{"BOTTOMLEFT", 7, 70}  -- 6 bottom-left
	}

	local function ApplyGlyphLayout()
		AnchorHolder()
		HideGlyphRock()
		local glyphFrameLevel = holder:GetFrameLevel() + 5

		for i = 1, 6 do
			local btn = _G["GlyphFrameGlyph"..i]
			if btn then
				btn:SetParent(holder) -- parent MUST be a Frame (not a Texture)
				btn:SetFrameLevel(glyphFrameLevel)
				btn:SetScale(slotScale)

				btn:ClearAllPoints()
				local p, x, y = glyphPositions[i][1], glyphPositions[i][2], glyphPositions[i][3]
				btn:SetPoint(p, holder, p, x * paperScale, y * paperScale)
			end
		end
	end

	ApplyGlyphLayout()

	-- Re-apply after Blizzard updates the glyph frame (prevents drift/overlap)
	hooksecurefunc("GlyphFrame_Update", function()
		if GlyphFrame and GlyphFrame:IsShown() then
			ApplyGlyphLayout()
		end
	end)

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
