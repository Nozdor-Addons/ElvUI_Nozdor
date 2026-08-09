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
	PlayerTalentFrame.backdrop:Point("TOPLEFT", 11, -12)
	PlayerTalentFrame.backdrop:Point("BOTTOMRIGHT", -32, 76)

	S:SetBackdropHitRect(PlayerTalentFrame)


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
		S:HandleTab(_G["PlayerTalentFrameTab"..i])
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

	-- Bottom tabs: sit outside below PlayerTalentFrame
	if PlayerTalentFrameTab1 then
		PlayerTalentFrameTab1:ClearAllPoints()
		PlayerTalentFrameTab1:Point("BOTTOMLEFT", PlayerTalentFrame, "BOTTOMLEFT", 11, -30)
	end
	if PlayerTalentFrameTab2 then
		PlayerTalentFrameTab2:ClearAllPoints()
		PlayerTalentFrameTab2:Point("LEFT", PlayerTalentFrameTab1, "RIGHT", -15, 0)
	end
	if PlayerTalentFrameTab3 then
		PlayerTalentFrameTab3:ClearAllPoints()
		PlayerTalentFrameTab3:Point("LEFT", PlayerTalentFrameTab2, "RIGHT", -15, 0)
	end

	-- Right-side specialization tabs: sit outside to the right of PlayerTalentFrame
	if PlayerSpecTab1 then
		PlayerSpecTab1:ClearAllPoints()
		PlayerSpecTab1:Point("TOPLEFT", PlayerTalentFrame, "TOPRIGHT", 1, -40)
		PlayerSpecTab1.ClearAllPoints = E.noop
		PlayerSpecTab1.SetPoint = E.noop
	end

	for i = 2, 10 do
		local tab = _G["PlayerSpecTab"..i]
		local prev = _G["PlayerSpecTab"..(i - 1)]
		if tab and prev then
			tab:ClearAllPoints()
			tab:Point("TOPLEFT", prev, "BOTTOMLEFT", 0, -5)
		end
	end
end)