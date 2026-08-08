local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

--Lua functions
local _G = _G
local unpack = unpack
--WoW API / Variables

S:AddCallbackForAddon("Blizzard_TalentUI", "Skin_Blizzard_TalentUI", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.talent then return end

	PlayerTalentFrame:StripTextures(true)
	PlayerTalentFrame:CreateBackdrop("Transparent")
	PlayerTalentFrame.backdrop:Point("TOPLEFT", 2, -2)
	PlayerTalentFrame.backdrop:Point("BOTTOMRIGHT", -2, 2)

	S:SetBackdropHitRect(PlayerTalentFrame)

	-- Base metal-frame adaptation (as on the Character window): drop the metal
	-- border + spec ring icon, reskin the new close button, and hide the server's
	-- rock background + top shadow so the flat ElvUI backdrop shows. The frame is
	-- decorated in its OnLoad, so the chrome already exists at this callback.
	if S.HandleMetalFrame then S:HandleMetalFrame(PlayerTalentFrame, PlayerTalentFrame.backdrop) end
	if _G.PlayerTalentFrameBackground then _G.PlayerTalentFrameBackground:SetAlpha(0) end
	if _G.PlayerTalentFrameTopTileStreaks then _G.PlayerTalentFrameTopTileStreaks:SetAlpha(0) end
	-- The inner content inset (InsetFrameTemplate: _UI-Frame borders + marble bg) is
	-- re-textured on show, so blank its own textures and give it a darker backdrop on
	-- every show.
	local function CleanTalentInset(inset)
		if not inset then return end
		if inset.GetRegions then
			local j = 1
			while true do
				local r = select(j, inset:GetRegions())
				if not r then break end
				if r.GetObjectType and r:GetObjectType() == "Texture" then r:SetTexture(nil); r:SetAlpha(0) end
				j = j + 1
			end
		end
		if inset.CreateBackdrop and not inset.backdrop then
			inset:CreateBackdrop("Transparent")
			if inset.backdrop.SetBackdropColor then inset.backdrop:SetBackdropColor(0, 0, 0, 0.5) end
		end
	end
	local talentInset = _G.PlayerTalentFrameContentInset
	if talentInset then
		CleanTalentInset(talentInset)
		if not talentInset.__euiInsetHooked then
			talentInset.__euiInsetHooked = true
			talentInset:HookScript("OnShow", CleanTalentInset)
		end
	end


do
		local TALENT_CHARFRAME_OFFSET = 211

		-- numTalentGroups, numPetTalentGroups
		-- force = true
		local function UpdateTalentFrameOffset(numTalentGroups, numPetTalentGroups, force)
			if not numTalentGroups or not numPetTalentGroups then
				numTalentGroups = GetNumTalentGroups(false, false)
				numPetTalentGroups = GetNumTalentGroups(false, true)
			end

			local needOffset = (numTalentGroups + numPetTalentGroups) > 1

			if needOffset then
				if force or not PlayerTalentFrame.ElvUI_OffsetActive then
					S:SetUIPanelWindowInfo(PlayerTalentFrame, "width", nil, TALENT_CHARFRAME_OFFSET)
					PlayerTalentFrame.ElvUI_OffsetActive = true
				end
			else
				if force or PlayerTalentFrame.ElvUI_OffsetActive then
					S:SetUIPanelWindowInfo(PlayerTalentFrame, "width")
					PlayerTalentFrame.ElvUI_OffsetActive = false
				end
			end
		end

		PlayerTalentFrame.ElvUI_UpdateTalentOffset = UpdateTalentFrameOffset

		if not PlayerTalentFrame.ElvUI_TalentOffsetHooked then
			PlayerTalentFrame.ElvUI_TalentOffsetHooked = true

			hooksecurefunc("PlayerTalentFrame_UpdateSpecs", function(_, numTalentGroups, _, numPetTalentGroups)
				UpdateTalentFrameOffset(numTalentGroups, numPetTalentGroups)
			end)
		end

		UpdateTalentFrameOffset(nil, nil, true)
	end

	S:HandleCloseButton(PlayerTalentFrameCloseButton, PlayerTalentFrame.backdrop)

	local function glyphFrameOnShow(self)
		if GlyphFrame and GlyphFrame:IsShown() then
			self:Hide()
		end
	end

	PlayerTalentFrameStatusFrame:HookScript("OnShow", glyphFrameOnShow)
	PlayerTalentFrameActivateButton:HookScript("OnShow", glyphFrameOnShow)

	PlayerTalentFrameStatusFrame:StripTextures()
	PlayerTalentFramePointsBar:StripTextures()
	PlayerTalentFramePreviewBar:StripTextures()

	S:HandleButton(PlayerTalentFrameActivateButton)
	S:HandleButton(PlayerTalentFrameResetButton)
	S:HandleButton(PlayerTalentFrameLearnButton)

	if PlayerTalentFramePointsBarResetButton then
		S:HandleButton(PlayerTalentFramePointsBarResetButton)
	end

	--PlayerTalentFramePreviewBarFiller:StripTextures()

	PlayerTalentFrameScrollFrame:StripTextures()
	PlayerTalentFrameScrollFrame:CreateBackdrop("Default")
	S:HandleScrollBar(PlayerTalentFrameScrollFrameScrollBar)

	for i = 1, MAX_NUM_TALENTS do
		local talent = _G["PlayerTalentFrameTalent"..i]
		local icon = _G["PlayerTalentFrameTalent"..i.."IconTexture"]
		local rank = _G["PlayerTalentFrameTalent"..i.."Rank"]

		if talent then
			talent:StripTextures()
			talent:SetTemplate("Default")
			talent:StyleButton()

			icon:SetInside()
			icon:SetTexCoord(unpack(E.TexCoords))
			icon:SetDrawLayer("ARTWORK")

			rank:SetFont(E.LSM:Fetch("font", E.db.general.font), 12, "OUTLINE")
		end
	end

	for i = 1, 5 do
		local tab = _G["PlayerTalentFrameTab"..i]
		S:HandleTab(tab)
		if tab and tab.backdrop then
			tab.backdrop:Point("TOPLEFT", tab, "TOPLEFT", 2, 0)
			tab.backdrop:Point("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -2, 2)
			tab:SetHitRectInsets(0, 0, 0, 0)
		end
	end

	for i = 1, MAX_TALENT_TABS do
		local tab = _G["PlayerSpecTab"..i]
		tab:GetRegions():Hide()

		tab:SetTemplate("Default")
		tab:StyleButton(nil, true)

		tab:GetNormalTexture():SetInside()
		tab:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
	end

	PlayerTalentFrameStatusFrame:Point("TOPLEFT", 57, -40)
	PlayerTalentFrameActivateButton:Point("TOP", 0, -40)

	PlayerTalentFrameScrollFrame:Width(302)
	PlayerTalentFrameScrollFrame:Point("TOPRIGHT", PlayerTalentFrame, "TOPRIGHT", -62, -77)
	PlayerTalentFrameScrollFrame:SetPoint("BOTTOM", PlayerTalentFramePointsBar, "TOP", 0, 0)

	PlayerTalentFrameScrollFrameScrollBar:Point("TOPLEFT", PlayerTalentFrameScrollFrame, "TOPRIGHT", 4, -18)
	PlayerTalentFrameScrollFrameScrollBar:Point("BOTTOMLEFT", PlayerTalentFrameScrollFrame, "BOTTOMRIGHT", 4, 18)

	PlayerTalentFrameResetButton:Point("RIGHT", -4, 1)
	PlayerTalentFrameLearnButton:Point("RIGHT", PlayerTalentFrameResetButton, "LEFT", -3, 0)

	-- Side spec tabs stick out on the right edge (like a spellbook skill tab). The
	-- old -33 x offset was tuned to the stock frame border and pulled them INTO the
	-- new metal window ("recessed"); anchor them just past the right edge instead.
	PlayerSpecTab1:Point("TOPLEFT", PlayerTalentFrame, "TOPRIGHT", -2, -45)
	PlayerSpecTab1.ClearAllPoints = E.noop
	PlayerSpecTab1.SetPoint = E.noop

	-- Anchor the bottom tab row's TOP to the window's BOTTOM so it hangs flush below
	-- the frame (the old y=46 dragged the whole row up into the content).
	PlayerTalentFrameTab1:ClearAllPoints()
	PlayerTalentFrameTab1:Point("TOPLEFT", PlayerTalentFrame, "BOTTOMLEFT", 11, 1)
end)