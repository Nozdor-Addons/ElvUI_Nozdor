local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

local _G = _G
local ipairs = ipairs
local hooksecurefunc = hooksecurefunc

-- Runes tab (hosted inside PlayerTalentFrame).
--
-- The server builds the whole rune view natively and correctly: it forces the
-- window to 512x424, makes UlduarSecretsFrame fill PlayerTalentFrameRuneHost, and
-- lays out the ROUND circle itself (ApplyRuneLayout: the RuneHolder stone ring +
-- the AnimatedBg galaxy anchored to RuneHost.Inset, and the 8 BrightRunes buttons at
-- fixed pixel offsets from the inset's top-centre). At 512x424 the circle is round.
--
-- We must NOT re-implement or resize any of that. We only flatten the host CHROME to
-- the ElvUI look and leave the native circle layout completely alone. Keeping the
-- window at 512x424 (round) is handled in Talent.lua (it suppresses ElvUI's dual-spec
-- width offset in the rune view).

-- Blank every Texture region a frame owns (leaves child frames/fontstrings alone).
local function blankTextureRegions(frame)
	if not frame or not frame.GetRegions then return end
	for _, r in ipairs({ frame:GetRegions() }) do
		if r.GetObjectType and r:GetObjectType() == "Texture" then
			r:SetAlpha(0)
		end
	end
end

S:AddCallbackForAddon("Blizzard_TalentUI", "Skin_Blizzard_Runes", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.talent then return end

	-- ===================== rune circle view chrome =====================
	-- Flatten only the host chrome; never touch UlduarSecretsFrame (the circle).
	local function SkinRuneChrome()
		local ptf = _G.PlayerTalentFrame
		if not ptf then return end

		-- MetalFrame2X border + corner ring/spec icon + close button -> ElvUI.
		if S.HandleMetalFrame then
			S:HandleMetalFrame(ptf, ptf.backdrop)
		end

		local host = ptf.RuneHost
		if host then
			-- Blank ALL of RuneHost's own ButtonFrameTemplate regions: the kept rock
			-- Bg and any leftover _UI-Frame corners/borders (e.g. topLeftCorner) that
			-- the template re-shows. The circle is a child frame (UlduarSecretsFrame),
			-- not a region, so it stays untouched.
			blankTextureRegions(host)
			-- RuneHost's own ButtonFrameTemplate close button sits alongside the new
			-- metal close button (it's a child frame, so the region hide never reaches
			-- it). Hide it.
			if host.CloseButton then host.CloseButton:Hide() end
		end
	end

	if _G.PlayerTalentFrame_ShowRuneFrame then
		hooksecurefunc("PlayerTalentFrame_ShowRuneFrame", SkinRuneChrome)
	end

	-- ===================== rune selection popup =====================
	-- UlduarRuneSelectionPanel: a server ButtonFrameTemplate decorated with
	-- MetalFrame2X. Bring it fully to the ElvUI look — background, frame, scrollbar
	-- and action buttons. The rune list rows are the server's content and are left
	-- as-is. Buttons re-texture themselves on state/show, so re-apply on every show.
	local function ReapplyRunePopup()
		local panel = _G.UlduarRuneSelectionPanel
		if not panel then return end

		-- Background + any leftover host chrome -> flat.
		if panel.Bg then panel.Bg:SetAlpha(0) end
		if panel.topLeftCorner then panel.topLeftCorner:Hide() end
		blankTextureRegions(panel)

		-- Action buttons -> ElvUI (Activate / Remove-all).
		if _G.UlduarRuneActivateButton then S:HandleButton(_G.UlduarRuneActivateButton) end
		if _G.UlduarRuneRemoveAllButton then S:HandleButton(_G.UlduarRuneRemoveAllButton) end
	end

	local function SkinRunePopup()
		local panel = _G.UlduarRuneSelectionPanel
		if not panel then return end

		if not panel.__euiSkinned then
			panel.__euiSkinned = true

			-- Flat window background + border.
			panel:CreateBackdrop("Transparent")
			panel.backdrop:Point("TOPLEFT", 2, -2)
			panel.backdrop:Point("BOTTOMRIGHT", -2, 2)

			-- Metal border + close button -> ElvUI.
			if S.HandleMetalFrame then S:HandleMetalFrame(panel, panel.backdrop) end

			-- Recessed list inset -> flat inner backdrop.
			if panel.Inset then
				panel.Inset:StripTextures()
				if not panel.Inset.backdrop then
					panel.Inset:CreateBackdrop("Transparent")
				end
			end

			-- Scrollbar -> ElvUI.
			if _G.UlduarRuneScrollFrameScrollBar then
				S:HandleScrollBar(_G.UlduarRuneScrollFrameScrollBar)
			end

			panel:HookScript("OnShow", ReapplyRunePopup)
		end

		ReapplyRunePopup()
	end

	if _G.UlduarSecretsFrame_BrightRunes_OnClick then
		hooksecurefunc("UlduarSecretsFrame_BrightRunes_OnClick", SkinRunePopup)
	end
end)
