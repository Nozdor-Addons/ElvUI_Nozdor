local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

local _G = _G
local hooksecurefunc = hooksecurefunc

-- Runes tab (hosted inside PlayerTalentFrame).
--
-- The server builds the whole rune view natively and correctly: it forces the
-- window to 512x424, makes UlduarSecretsFrame fill PlayerTalentFrameRuneHost, and
-- lays out the ROUND circle itself (ApplyRuneLayout: the RuneHolder stone ring +
-- the AnimatedBg galaxy anchored to RuneHost.Inset, and the 8 BrightRunes buttons at
-- fixed pixel offsets from the inset's top-centre). At 512x424 the circle is round.
--
-- We must NOT re-implement or resize any of that. The previous approach did exactly
-- that (force-resized the window, re-anchored the host, re-scaled UlduarSecretsFrame
-- and re-placed all 8 buttons with its own tuned offsets) — tuned to one size, so any
-- other window width stretched the ring texture into an oval while the fixed-offset
-- runes stayed put. That is the distortion.
--
-- So here we only flatten the host CHROME to the ElvUI look and otherwise leave the
-- server's native layout completely alone. Keeping the window at 512x424 in the rune
-- view is handled in Talent.lua (it suppresses ElvUI's dual-spec width offset there).

S:AddCallbackForAddon("Blizzard_TalentUI", "Skin_Blizzard_Runes", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.talent then return end

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
			-- The server keeps RuneHost's stock ButtonFrameTemplate rock Bg shown
			-- (occluded by the galaxy); blank it so the flat ElvUI backdrop reads in
			-- the corners behind the circle.
			if host.Bg then host.Bg:SetAlpha(0) end
			-- RuneHost's own ButtonFrameTemplate close button sits alongside the new
			-- metal close button (it's a child frame, so the server's region-hide
			-- loop never reaches it). Hide it.
			if host.CloseButton then host.CloseButton:Hide() end
		end
	end

	if _G.PlayerTalentFrame_ShowRuneFrame then
		hooksecurefunc("PlayerTalentFrame_ShowRuneFrame", SkinRuneChrome)
	end
end)
