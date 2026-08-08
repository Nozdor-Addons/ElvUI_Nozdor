local E, L, V, P, G = unpack(select(2, ...))
local S = E:GetModule("Skins")

local _G = _G
local ipairs = ipairs
local unpack = unpack
local math_max = math.max
local floor = math.floor

local function SafeHandleTab(tab)
	if not tab then return end
	if tab.HighlightLeft and tab.HighlightLeft.StripTextures then tab.HighlightLeft:StripTextures() end
	if tab.HighlightMiddle and tab.HighlightMiddle.StripTextures then tab.HighlightMiddle:StripTextures() end
	if tab.HighlightRight and tab.HighlightRight.StripTextures then tab.HighlightRight:StripTextures() end
	if S.HandleTab then S:HandleTab(tab) end
end

local function GetRotateButtons()
	local f = _G.CharacterModelFrame
	local left  = _G.CharacterModelFrameRotateLeftButton or (f and f.RotateLeftButton) or _G.PaperDollFrameRotateLeftButton
	local right = _G.CharacterModelFrameRotateRightButton or (f and f.RotateRightButton) or _G.PaperDollFrameRotateRightButton
	return left, right
end

local BACKDROP_TPL = (BackdropTemplateMixin and "BackdropTemplate") or nil

local function MakeBD(parent, w, h)
    local f = CreateFrame("Frame", nil, parent, BACKDROP_TPL)
    if w and h then f:SetSize(w, h) end
    if f.SetBackdrop then
        f:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8x8",
                        edgeFile = "Interface/Buttons/WHITE8x8", edgeSize = 1 })
        f:SetBackdropColor(0,0,0, .7)
        f:SetBackdropBorderColor(0,0,0,1)
    end
    return f
end

-- NOZDOR: the redesigned PaperDollFrame decorates its inner panels and the model
-- frame with art (InsetFrameTemplate _UI-Frame borders, PaperDollInfoPart panels,
-- UI-Background-Marble, race-specific DressUpBackground behind the model), and
-- re-applies it after ElvUI's one-time strip has already run. Each of these frames
-- is purely a decorative container -- the stats text, the 3D model and the item
-- slots are separate child frames/objects, not texture regions of it -- so blank
-- ALL of the frame's own texture regions to let the flat ElvUI backdrop show,
-- without whack-a-mole per atlas. FontStrings (and the model) are left untouched.
local function BlankDecorTextures(frame)
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

-- The stat-category headers (ItemLevel / Stat1 / Stat2) use a PaperDollInfoPart1
-- plate behind their label. Replace it with a flat ElvUI panel + hover highlight.
local function StyleStatHeader(header)
	if not header then return end
	if header.Background then
		header.Background:SetTexture(nil)
		header.Background:Hide()
	end
	if header.CreateBackdrop and not header.backdrop then
		header:CreateBackdrop("Transparent")
		header.backdrop:Point("TOPLEFT", header, "TOPLEFT", 4, -4)
		header.backdrop:Point("BOTTOMRIGHT", header, "BOTTOMRIGHT", -4, 4)
		if header.HookScript and S.SetModifiedBackdrop then
			header:HookScript("OnEnter", S.SetModifiedBackdrop)
			header:HookScript("OnLeave", S.SetOriginalBackdrop)
		end
	end
end

local function CleanPaperDollDecor()
	BlankDecorTextures(_G.PaperDollFrameNewPanel)
	BlankDecorTextures(_G.PaperDollFrameEquipInset)
	BlankDecorTextures(_G.PaperDollFrameInset)
	BlankDecorTextures(_G.CharacterModelFrame)
	StyleStatHeader(_G.ItemLevelHeader)
	StyleStatHeader(_G.Stat1Header)
	StyleStatHeader(_G.Stat2Header)
end

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.character ~= true then return end

	if _G.CharacterFrame and _G.CharacterFrame.StripTextures then
		_G.CharacterFrame:StripTextures(true)
	end
	if _G.CharacterFrame and _G.CharacterFrame.CreateBackdrop and not _G.CharacterFrame.backdrop then
		_G.CharacterFrame:CreateBackdrop("Transparent", nil, nil, nil, true)
	end
	if _G.CharacterFrame and _G.CharacterFrame.backdrop and _G.CharacterFrame.backdrop.SetAllPoints then
		_G.CharacterFrame.backdrop:SetAllPoints(_G.CharacterFrame)
	end
    if _G.CharacterFrame and _G.CharacterFrame.backdrop then
        local cf = _G.CharacterFrame
        local bd = cf.backdrop

        bd:SetFrameStrata(cf:GetFrameStrata() or "MEDIUM")
        bd:SetFrameLevel(math_max((cf:GetFrameLevel() or 1) - 2, 0))
    end

	-- NOZDOR: CharacterFrame is re-skinned with a runtime "MetalFrame2X" chrome on
	-- its first OnShow (UITemplate2X loads after CharacterFrame), so the metal
	-- border, portrait ring and custom close button don't exist yet at this point.
	-- Neutralize them on show, and hide the server's rock window background so the
	-- flat ElvUI backdrop (already anchored to the whole frame) shows through. The
	-- window's own OnShow hook, which builds the chrome, is registered earlier and
	-- therefore always runs before this one.
	if _G.CharacterFrame then
		_G.CharacterFrame:HookScript("OnShow", function(frame)
			if S.HandleMetalFrame then S:HandleMetalFrame(frame, frame.backdrop) end
			if _G.CharacterFrameBg then _G.CharacterFrameBg:SetAlpha(0) end
			if _G.CharacterFrameTopTileStreaks then _G.CharacterFrameTopTileStreaks:SetAlpha(0) end
		end)
	end

	if _G.CHARACTERFRAME_SUBFRAMES then
		for i = 1, #_G.CHARACTERFRAME_SUBFRAMES do
			local tab = _G["CharacterFrameTab"..i]
			SafeHandleTab(tab)
			-- The new NozdorFinder tabs are much wider than a stock tab, so ElvUI's
			-- default 10px side insets leave big gaps between the backdrops. Hug the
			-- button instead (the backdrop still tracks the tab's runtime width).
			if tab and tab.backdrop then
				-- Hug the wide NozdorFinder tab; backdrop top flush with the tab top
				-- so the row sits right against the window edge (no gap, no overlap).
				tab.backdrop:Point("TOPLEFT", tab, "TOPLEFT", 2, 0)
				tab.backdrop:Point("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -2, 2)
				tab:SetHitRectInsets(0, 0, 0, 0)
			end
		end
		-- Anchor the tab row's TOP to the window's BOTTOM so it hangs flush below the
		-- frame regardless of tab height (the row chains off Tab1).
		if _G.CharacterFrameTab1 and _G.CharacterFrame then
			_G.CharacterFrameTab1:ClearAllPoints()
			_G.CharacterFrameTab1:Point("TOPLEFT", _G.CharacterFrame, "BOTTOMLEFT", 10, 0)
		end
	end

	if _G.GearManagerDialog then
		_G.GearManagerDialog:StripTextures()
		_G.GearManagerDialog:CreateBackdrop("Transparent")
		_G.GearManagerDialog.backdrop:Point("TOPLEFT", 5, -2)
		_G.GearManagerDialog.backdrop:Point("BOTTOMRIGHT", -1, 4)
		if S.HandleCloseButton and _G.CharacterFrameCloseButton then
			S:HandleCloseButton(_G.CharacterFrameCloseButton)
			_G.CharacterFrameCloseButton:ClearAllPoints()
			_G.CharacterFrameCloseButton:Point("TOPRIGHT", _G.CharacterFrame, "TOPRIGHT", -4, -4)
		end
		for i = 1, 10 do
			local b = _G["GearSetButton"..i]
			if b then
				b:StripTextures()
				if b.StyleButton then b:StyleButton() end
				b:CreateBackdrop("Default")
				b.backdrop:SetAllPoints()
				local icon = _G["GearSetButton"..i.."Icon"]
				if icon then
					icon:SetTexCoord(unpack(E.TexCoords))
					if icon.SetInside then icon:SetInside() end
				end
			end
		end
		if S.HandleButton then
			if _G.GearManagerDialogDeleteSet then S:HandleButton(_G.GearManagerDialogDeleteSet) end
			if _G.GearManagerDialogEquipSet then S:HandleButton(_G.GearManagerDialogEquipSet) end
			if _G.GearManagerDialogSaveSet then S:HandleButton(_G.GearManagerDialogSaveSet) end
		end
	end

	if _G.PlayerTitleFrame then
		_G.PlayerTitleFrame:StripTextures()
		_G.PlayerTitleFrame:CreateBackdrop("Default")
		_G.PlayerTitleFrame.backdrop:Point("TOPLEFT", 20, 3)
		_G.PlayerTitleFrame.backdrop:Point("BOTTOMRIGHT", -16, 15)
		_G.PlayerTitleFrame.backdrop:SetFrameLevel(_G.PlayerTitleFrame:GetFrameLevel())
	end
	if S.HandleNextPrevButton and _G.PlayerTitleFrameButton then
		S:HandleNextPrevButton(_G.PlayerTitleFrameButton)
		_G.PlayerTitleFrameButton:Size(16)
		_G.PlayerTitleFrameButton:Point("TOPRIGHT", _G.PlayerTitleFrameRight, "TOPRIGHT", -18, -16)
	end
	if _G.PlayerTitlePickerFrame then
		_G.PlayerTitlePickerFrame:StripTextures()
		_G.PlayerTitlePickerFrame:CreateBackdrop("Transparent")
		_G.PlayerTitlePickerFrame.backdrop:Point("TOPLEFT", 6, -10)
		_G.PlayerTitlePickerFrame.backdrop:Point("BOTTOMRIGHT", -13, 6)
		_G.PlayerTitlePickerFrame.backdrop:SetFrameLevel(_G.PlayerTitlePickerFrame:GetFrameLevel())
	end

if IsAddOnLoaded and IsAddOnLoaded("Blizzard_CharacterUI") then
    InstallStrengthenHooks()
else
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(_, addon)
        if addon=="Blizzard_CharacterUI" then
            InstallStrengthenHooks()
            f:UnregisterEvent("ADDON_LOADED")
        end
    end)
end


if IsAddOnLoaded("Blizzard_CharacterUI") then
    InstallStrengthenScrollbarHooks()
else
    local waiter = CreateFrame("Frame")
    waiter:RegisterEvent("ADDON_LOADED")
    waiter:SetScript("OnEvent", function(_, addon)
        if addon == "Blizzard_CharacterUI" then
            InstallStrengthenScrollbarHooks()
            waiter:UnregisterEvent("ADDON_LOADED")
        end
    end)
end


	


	if _G.PlayerTitlePickerScrollFrame and _G.PlayerTitlePickerScrollFrame.buttons then
		for _, button in ipairs(_G.PlayerTitlePickerScrollFrame.buttons) do
			if button.text and button.text.FontTemplate then button.text:FontTemplate() end
			if S.HandleButtonHighlight then S:HandleButtonHighlight(button) end
		end
	end

	local rotateLeft, rotateRight = GetRotateButtons()
	if rotateLeft and S.HandleRotateButton then S:HandleRotateButton(rotateLeft) end
	if rotateRight and S.HandleRotateButton then S:HandleRotateButton(rotateRight) end

	if _G.CharacterAttributesFrame then
		_G.CharacterAttributesFrame:StripTextures()
	end

	if _G.PaperDollFrame then
		-- The inner panels are re-textured after ElvUI's one-time strip, so clean
		-- their decorative borders/backgrounds on every show and after each stats
		-- relayout (and once now).
		_G.PaperDollFrame:HookScript("OnShow", CleanPaperDollDecor)
		if _G.PaperDollFrame_UpdateStats then hooksecurefunc("PaperDollFrame_UpdateStats", CleanPaperDollDecor) end
		if _G.CharacterModelFrame then _G.CharacterModelFrame:HookScript("OnShow", CleanPaperDollDecor) end
		CleanPaperDollDecor()

		local slots = {
			[1] = _G.CharacterHeadSlot,[2] = _G.CharacterNeckSlot,[3] = _G.CharacterShoulderSlot,[4] = _G.CharacterShirtSlot,
			[5] = _G.CharacterChestSlot,[6] = _G.CharacterWaistSlot,[7] = _G.CharacterLegsSlot,[8] = _G.CharacterFeetSlot,
			[9] = _G.CharacterWristSlot,[10] = _G.CharacterHandsSlot,[11] = _G.CharacterFinger0Slot,[12] = _G.CharacterFinger1Slot,
			[13] = _G.CharacterTrinket0Slot,[14] = _G.CharacterTrinket1Slot,[15] = _G.CharacterBackSlot,[16] = _G.CharacterMainHandSlot,
			[17] = _G.CharacterSecondaryHandSlot,[18] = _G.CharacterRangedSlot,[19] = _G.CharacterTabardSlot,[20] = _G.CharacterAmmoSlot,
		}
		for i, slotFrame in ipairs(slots) do
			if slotFrame then
				local slotFrameName = slotFrame:GetName()
				local icon = _G[slotFrameName.."IconTexture"]
				slotFrame:StripTextures()
				if slotFrame.StyleButton then slotFrame:StyleButton(false) end
				if slotFrame.SetTemplate then slotFrame:SetTemplate("Default", true, true) end
                if slotFrame.backdrop and slotFrame.GetFrameLevel then slotFrame.backdrop:SetFrameLevel(slotFrame:GetFrameLevel() + 1) end
				if icon then
					if icon.SetInside then icon:SetInside() end
					icon:SetTexCoord(unpack(E.TexCoords))
				end
				if slotFrame.SetFrameLevel then
					slotFrame:SetFrameLevel((_G.PaperDollFrame:GetFrameLevel() or 1) + 10)
                    if slotFrame.backdrop then
                        slotFrame.backdrop:SetFrameLevel(slotFrame:GetFrameLevel() + 1)
                    end
				end
				if i ~= 20 then
					local cooldown = _G[slotFrameName.."Cooldown"]
					local popout = _G[slotFrameName.."PopoutButton"]
					if cooldown then E:RegisterCooldown(cooldown) end
					if popout then
						popout:StripTextures()
						if popout.HookScript then
							popout:HookScript("OnEnter", function(self) if self.icon then self.icon:SetVertexColor(unpack(E.media.rgbvaluecolor)) end end)
							popout:HookScript("OnLeave", function(self) if self.icon then self.icon:SetVertexColor(1,1,1) end end)
						end
						if not popout.icon then
							popout.icon = popout:CreateTexture(nil, "ARTWORK")
							popout.icon:Size(24)
							popout.icon:SetPoint("CENTER")
							popout.icon:SetTexture(E.Media.Textures.ArrowUp)
						end
					end
				end
			end
		end
	end

	do
		local i, prev = 1, nil
		while true do
			local tab = _G["PaperDollFrameTab"..i]
			if not tab then break end
			SafeHandleTab(tab)
            tab:SetFrameLevel((_G.CharacterFrame:GetFrameLevel() or 1) + 20)
            if tab.backdrop then
                tab.backdrop:SetFrameLevel(tab:GetFrameLevel() - 1)
            end
			tab:ClearAllPoints()
			if i == 1 then
				tab:SetPoint("BOTTOMLEFT", _G.CharacterFrame, "BOTTOMLEFT", 0, -1)
			else
				tab:SetPoint("LEFT", prev, "RIGHT", 0, 0)
			end
			if tab.backdrop and tab.backdrop.SetInside then
				tab.backdrop:SetInside(tab, 0, 0)
			end
			prev = tab
			i = i + 1
		end
	end

	if _G.PetPaperDollFrame then
		_G.PetPaperDollFrame:StripTextures(true)
		for i = 1, 3 do
			local tab = _G["PetPaperDollFrameTab"..i]
			if not tab then break end
			tab:StripTextures()
			tab:CreateBackdrop("Default", true)
			tab.backdrop:Point("TOPLEFT", 2, -7)
			tab.backdrop:Point("BOTTOMRIGHT", -1, -10)
			if S.SetBackdropHitRect then S:SetBackdropHitRect(tab) end
			if tab.HookScript then
				tab:HookScript("OnEnter", S.SetModifiedBackdrop)
				tab:HookScript("OnLeave", S.SetOriginalBackdrop)
			end
		end
		local pl, pr = _G.PetModelFrameRotateLeftButton, _G.PetModelFrameRotateRightButton
		if pl and S.HandleRotateButton then S:HandleRotateButton(pl) end
		if pr and S.HandleRotateButton then S:HandleRotateButton(pr) end
	end

--	do
--		local parent = _G.CharacterFrame and _G.CharacterFrame.backdrop
--		if parent then
--			local model = _G.CharacterModelFrame
--			if model and model.StripTextures then model:StripTextures(true) end
--			if parent.__ModelBD then parent.__ModelBD:Hide(); parent.__ModelBD = nil end
--			if model then
--				local bd = CreateFrame("Frame", nil, parent)
--				bd:SetTemplate("Transparent")
--				bd:SetFrameStrata(parent:GetFrameStrata())
--				bd:SetFrameLevel(parent:GetFrameLevel() + 1)
--				bd:SetPoint("TOPLEFT",     model, "TOPLEFT",     -6,  6)
--				bd:SetPoint("BOTTOMRIGHT", model, "BOTTOMRIGHT",  6, -6)
--				parent.__ModelBD = bd
--			end
--
--			local stats = _G.CharacterAttributesFrame
--			if stats and stats.StripTextures then stats:StripTextures(true) end
--			if parent.__StatsBD then parent.__StatsBD:Hide(); parent.__StatsBD = nil end
--			if stats then
--				local raise = (_G.PaperDollFrameTab1 and _G.PaperDollFrameTab1.GetHeight) and (_G.PaperDollFrameTab1:GetHeight() + 8) or 36
--				local bd = CreateFrame("Frame", nil, parent)
--				bd:SetTemplate("Transparent")
--				bd:SetFrameStrata(parent:GetFrameStrata())
--				bd:SetFrameLevel(parent:GetFrameLevel() + 1)
--				bd:SetPoint("TOPLEFT",  stats, "TOPLEFT",  -6,  6)
--				bd:SetPoint("BOTTOMRIGHT", _G.CharacterFrame, "BOTTOMRIGHT", -6, raise)
--				parent.__StatsBD = bd
--			end
--		end
--	end

	do
		local function qualityColor(q)
			if not q or q < 1 then return 0.1,0.1,0.1 end
			local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
			if c then return c.r, c.g, c.b end
			return 1,1,1
		end
		local function updateSlot(slotFrame, slotId)
			if not slotFrame then return end
			local q = GetInventoryItemQuality("player", slotId)
			local r,g,b = qualityColor(q)
			local borderHost = slotFrame.backdrop or slotFrame
			if borderHost.SetBackdropBorderColor then
				borderHost:SetBackdropBorderColor(r, g, b)
			end
		end
		local slotIds = {
			HeadSlot=1, NeckSlot=2, ShoulderSlot=3, ShirtSlot=4, ChestSlot=5, WaistSlot=6, LegsSlot=7, FeetSlot=8,
			WristSlot=9, HandsSlot=10, Finger0Slot=11, Finger1Slot=12, Trinket0Slot=13, Trinket1Slot=14, BackSlot=15,
			MainHandSlot=16, SecondaryHandSlot=17, RangedSlot=18, TabardSlot=19
		}
		local frames = {}
		for name,id in pairs(slotIds) do
			local f = _G["Character"..name]
			if f then frames[id] = f end
		end

        local function updateAllOnce()
            for id,frame in pairs(frames) do
                updateSlot(frame, id)
            end
        end 

		local function updateAll()
            updateAllOnce()
			if C_Timer and C_Timer.After then
				C_Timer.After(0.10, updateAllOnce)
                C_Timer.After(0.25, updateAllOnce)
			end
		end
		local f = CreateFrame("Frame")
		f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
		f:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
		f:RegisterEvent("PLAYER_ENTERING_WORLD")
		f:SetScript("OnEvent", function(_, evt, arg1)
            if evt == "UNIT_INVENTORY_CHANGED" and arg1 ~= "player" then return end
		    updateAll()
        end)
	end
        _G.EUI_UpdateAllSlots = updateAll

	do
		local stats = _G.CharacterAttributesFrame
		if stats then
			for i = 1, stats:GetNumRegions() do
				local r = select(i, stats:GetRegions())
				if r and r.GetText and r:GetText() then
					local txt = r:GetText()
					if txt:find("Основные") or txt:find("Ближний") or txt:find("General") or txt:find("Attributes") or txt:find("Spell") or txt:find("Defense") then
						r:SetTextColor(1, 0.82, 0)
					else
						r:SetTextColor(0.6, 0.9, 0.6)
					end
					if r.FontTemplate then r:FontTemplate(nil, 12) end
				end
			end
		end
	end
	
	do
    local parent = CharacterFrame and CharacterFrame.backdrop
    local bd = parent and parent.__StatsBD
    if bd then
        local raise = (PaperDollFrameTab1 and PaperDollFrameTab1.GetHeight) and (PaperDollFrameTab1:GetHeight() + 6) or 34
        bd:ClearAllPoints()
        bd:SetPoint("TOPLEFT",  CharacterAttributesFrame, "TOPLEFT",  -6,  6)
        bd:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -6, raise)
    end
end
	do
    local stats = CharacterAttributesFrame
    if stats then
        for i = 1, stats:GetNumRegions() do
            local r = select(i, stats:GetRegions())
            if r and r.GetText and r:GetText() then
                local t = r:GetText()
                if t:find("Основные") or t:find("Ближний") then
                    r:SetTextColor(1, 0.85, 0)
                    if r.SetFont then r:SetFont(r:GetFont(), 13, "OUTLINE") end
                else
                    r:SetTextColor(0.65, 1, 0.65)
                    if r.SetFont then r:SetFont(r:GetFont(), 12, "OUTLINE") end
                end
            end
        end
    end
end
do
    local toStrip = {
        "PaperDollFrame",
        "CharacterAttributesFrame",
        "PaperDollFrameStrengthenFrame",
        "PaperDollFrameStrengthenScrollBarScrollChildFrame",
        "PaperDollFrameNewPanel",
		"PaperDollFrameEquipInset",
		"PaperDollFrameInset",
    }
    for _, name in ipairs(toStrip) do
        local f = _G[name]
        if f then
            if f.StripTextures then f:StripTextures(true) end
            if f.DisableDrawLayer then
                f:DisableDrawLayer("BACKGROUND")
                f:DisableDrawLayer("BORDER")
                f:DisableDrawLayer("ARTWORK")
            end
            local i = 1
            while true do
                local r = select(i, f:GetRegions())
                if not r then break end
                if r.GetObjectType and r:GetObjectType() == "Texture" then
                    r:SetTexture(nil)
                    r:SetAlpha(0)
                end
                i = i + 1
            end
        end
    end
end

local function SkinStrengthenSB() --скроллбар заебал
    local sb = _G.PaperDollFrameStrengthenScrollBarScrollBar
    if not sb or sb.__MY_SKINNED then return end

    if sb.StripTextures then sb:StripTextures() end
    for _, r in next, {sb.Background, sb.Top, sb.Bottom, sb.Middle, sb.Track} do
        if r and r.Hide then r:Hide() end
    end
    local regs = { sb:GetRegions() }
    for i=1,#regs do
        local tex = regs[i]
        if tex and tex.GetObjectType and tex:GetObjectType()=="Texture" then
            tex:SetTexture(nil); tex:SetAlpha(0)
        end
    end

    local getThumb = sb.GetThumbTexture
    local thumb = sb.ThumbTexture or (getThumb and getThumb(sb))
    if thumb then
        thumb:SetAlpha(0)
        if not sb.__thumb then
			local t = MakeBD(sb)
			t:SetSize(14, 28)
            t:SetBackdrop({ bgFile="Interface/Buttons/WHITE8x8",
                            edgeFile="Interface/Buttons/WHITE8x8", edgeSize=1 })
            t:SetBackdropColor(0,0,0,.75)
            t:SetBackdropBorderColor(0,0,0,1)
            t:SetFrameLevel((sb:GetFrameLevel() or 0) + 10)
            sb.__thumb = t
        end
        sb.__thumb:ClearAllPoints()
        sb.__thumb:SetPoint("CENTER", thumb, "CENTER")
        sb.__thumb:Show()
    end

    local anchor = sb:GetParent() or _G.PaperDollFrameStrengthenFrame or _G.PaperDollFrame
    sb:ClearAllPoints()
    sb:SetPoint("TOPRIGHT",    anchor, "TOPRIGHT",    2, -14)
    sb:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 2,  15)
    sb:SetWidth(20)

    sb.__MY_SKINNED = true
end

local function InstallStrengthenSBHooks()
    C_Timer.After(0, SkinStrengthenSB)
    if _G.CharacterFrame and _G.CharacterFrame.HookScript then
        _G.CharacterFrame:HookScript("OnShow", function() C_Timer.After(0, SkinStrengthenSB) end)
    end
    if _G.PaperDollFrame and _G.PaperDollFrame.HookScript then
        _G.PaperDollFrame:HookScript("OnShow", function() C_Timer.After(0, SkinStrengthenSB) end)
    end
    if _G.PaperDollFrameStrengthenFrame and _G.PaperDollFrameStrengthenFrame.HookScript then
        _G.PaperDollFrameStrengthenFrame:HookScript("OnShow", function() C_Timer.After(0, SkinStrengthenSB) end)
    end
    if _G.CharacterFrame_ShowSubFrame then
        hooksecurefunc("CharacterFrame_ShowSubFrame", function()
            C_Timer.After(0, SkinStrengthenSB)
        end)
    end
    if C_Timer and C_Timer.NewTicker then
        C_Timer.NewTicker(0.10, SkinStrengthenSB, 30)
    end
end

if IsAddOnLoaded and IsAddOnLoaded("Blizzard_CharacterUI") then
    InstallStrengthenSBHooks()
else
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(_, addon)
        if addon=="Blizzard_CharacterUI" then
            InstallStrengthenSBHooks()
            f:UnregisterEvent("ADDON_LOADED")
        end
    end)
end

local function SkinReputationRow(i)
    local row   = _G["ReputationBar"..i]
    if not row or row.__EUI_skinned then return end

    local name  = _G["ReputationBar"..i.."FactionName"]
    local sb    = _G["ReputationBar"..i.."ReputationBar"]
    local btn   = _G["ReputationBar"..i.."ExpandOrCollapseButton"]
    local warCB = _G["ReputationBar"..i.."AtWarCheck"]

    if row.StripTextures then row:StripTextures(true) end

    if sb then
        if sb.StripTextures then sb:StripTextures(true) end
        if sb.SetStatusBarTexture and E and E.media and E.media.normTex then
            sb:SetStatusBarTexture(E.media.normTex)
        end
        if not sb.backdrop then
            sb:CreateBackdrop("Default", true)
            sb.backdrop:SetFrameLevel(sb:GetFrameLevel() - 1)
        end
        sb:SetHeight(14)
    end

    if btn and S and S.HandleCollapseExpandButton then
        S:HandleCollapseExpandButton(btn, "+")
    elseif btn then
        if btn.SetNormalTexture then btn:SetNormalTexture(nil) end
        if btn.SetPushedTexture then btn:SetPushedTexture(nil) end
        if btn.SetHighlightTexture then btn:SetHighlightTexture(nil) end
    end

    if warCB and S and S.HandleCheckBox then
        S:HandleCheckBox(warCB)
    end

    if name and btn then
        name:ClearAllPoints()
        name:SetPoint("LEFT", btn, "RIGHT", 4, 0)
    end

    row.__EUI_skinned = true
end

local function SkinReputation()
    if _G.ReputationFrame then
        _G.ReputationFrame:StripTextures(true)
    end
    if _G.ReputationFrameInset then
        _G.ReputationFrameInset:StripTextures(true)
        _G.ReputationFrameInset:SetAlpha(0)
    end

    local sf = _G.ReputationListScrollFrame
    if sf then
        if sf.StripTextures then sf:StripTextures(true) end
        local sb = sf.ScrollBar or _G.ReputationListScrollFrameScrollBar
        if sb and S and S.HandleScrollBar then
            S:HandleScrollBar(sb)
            sb:ClearAllPoints()
            sb:SetPoint("TOPLEFT",  sf, "TOPRIGHT",  1, -14)
            sb:SetPoint("BOTTOMLEFT", sf, "BOTTOMRIGHT", 1,  15)
        end
    end

    local NUM = _G.NUM_FACTIONS_DISPLAYED or 15
    for i = 1, NUM do
        SkinReputationRow(i)
    end

    local det = _G.ReputationDetailFrame
    if det then
        det:StripTextures(true)
        if det.backdrop then det.backdrop:StripTextures() end
        det:CreateBackdrop("Transparent")

        if _G.ReputationDetailCloseButton and S and S.HandleCloseButton then
            S:HandleCloseButton(_G.ReputationDetailCloseButton)
        end
        if S and S.HandleCheckBox then
            if _G.ReputationDetailAtWarCheckBox       then S:HandleCheckBox(_G.ReputationDetailAtWarCheckBox) end
            if _G.ReputationDetailInactiveCheckBox    then S:HandleCheckBox(_G.ReputationDetailInactiveCheckBox) end
            if _G.ReputationDetailMainScreenCheckBox  then S:HandleCheckBox(_G.ReputationDetailMainScreenCheckBox) end
            if _G.ReputationDetailLFGBonusReputationCheckBox then S:HandleCheckBox(_G.ReputationDetailLFGBonusReputationCheckBox) end
        end
    end
end

if _G.CharacterFrame and _G.CharacterFrame.HookScript then
    _G.CharacterFrame:HookScript("OnShow", function() if _G.ReputationFrame and _G.ReputationFrame:IsShown() then SkinReputation() end end)
end
if _G.ReputationFrame and _G.ReputationFrame.HookScript then
    _G.ReputationFrame:HookScript("OnShow", SkinReputation)
end
if _G.CharacterFrame_ShowSubFrame then
    hooksecurefunc("CharacterFrame_ShowSubFrame", function(frameName)
        if frameName == "ReputationFrame" then SkinReputation() end
    end)
end

C_Timer.After(0, SkinReputation)

local function KillTextures(frame)
    if not frame then return end
    if frame.StripTextures then frame:StripTextures(true) end
    local regs = { frame:GetRegions() }
    for i = 1, #regs do
        local r = regs[i]
        if r and r.GetObjectType and r:GetObjectType() == "Texture" then
            r:SetTexture(nil); r:SetAlpha(0)
        end
    end
    if frame.NineSlice then frame.NineSlice:SetAlpha(0) end
    if frame.Bg then frame.Bg:SetAlpha(0) end
end

local function ClearReputationBackground()
    KillTextures(_G.CharacterFrameInset)
    if _G.CharacterFrameInset then _G.CharacterFrameInset:Hide() end

    local sf = _G.ReputationListScrollFrame
    KillTextures(sf)
    if sf and sf.backdrop then sf.backdrop:Hide() end

    local NUM = _G.NUM_FACTIONS_DISPLAYED or 15
    for i = 1, NUM do
        local bg = _G["ReputationBar"..i.."Background"]
        if bg then bg:Hide(); bg:SetAlpha(0) end
        local row = _G["ReputationBar"..i]
        if row and row.backdrop then row.backdrop:SetAlpha(0) end
    end
end

if _G.ReputationFrame and _G.ReputationFrame.HookScript then
    _G.ReputationFrame:HookScript("OnShow", ClearReputationBackground)
end
if _G.CharacterFrame and _G.CharacterFrame.HookScript then
    _G.CharacterFrame:HookScript("OnShow", function()
        if _G.ReputationFrame and _G.ReputationFrame:IsShown() then
            ClearReputationBackground()
        end
    end)
end
if _G.CharacterFrame_ShowSubFrame then
    hooksecurefunc("CharacterFrame_ShowSubFrame", function(name)
        if name == "ReputationFrame" then ClearReputationBackground() end
    end)
end
C_Timer.After(0, ClearReputationBackground)

local function SkinSkillRow(i)
    local name   = _G["SkillName"..i]
    local btn    = _G["SkillExpandButton"..i]
    local rank   = _G["SkillRankFrame"..i]
    local border = _G["SkillRankFrame"..i.."Border"]

    if not name or name.__EUI_skinned then return end

    if btn then
        if S and S.HandleCollapseExpandButton then
            S:HandleCollapseExpandButton(btn, "+")
        else
            if btn.SetNormalTexture then btn:SetNormalTexture(nil) end
            if btn.SetPushedTexture then btn:SetPushedTexture(nil) end
            if btn.SetHighlightTexture then btn:SetHighlightTexture(nil) end
        end
    end

    if rank then
        if rank.StripTextures then rank:StripTextures(true) end
        if border then border:Hide() end
        if rank.SetStatusBarTexture and E and E.media and E.media.normTex then
            rank:SetStatusBarTexture(E.media.normTex)
        end
        rank:SetHeight(12)
        if not rank.backdrop then
            rank:CreateBackdrop("Default", true)
            rank.backdrop:SetFrameLevel(rank:GetFrameLevel() - 1)
        end
    end

    name.__EUI_skinned = true
end

local function SkinSkills()
    if _G.SkillFrame then _G.SkillFrame:StripTextures(true) end
    if _G.CharacterFrameInset then
        _G.CharacterFrameInset:StripTextures(true)
        _G.CharacterFrameInset:SetAlpha(0)
    end

    local list = _G.SkillListScrollFrame
    if list then
        if list.StripTextures then list:StripTextures(true) end
        local sb = list.ScrollBar or _G.SkillListScrollFrameScrollBar
        if sb and S and S.HandleScrollBar then
            S:HandleScrollBar(sb)
            sb:ClearAllPoints()
            sb:SetPoint("TOPLEFT",  list, "TOPRIGHT",  1, -14)
            sb:SetPoint("BOTTOMLEFT", list, "BOTTOMRIGHT", 1,  15)
        end
    end

    if _G.SkillDetailScrollFrame and _G.SkillDetailScrollFrame.StripTextures then
        _G.SkillDetailScrollFrame:StripTextures(true)
    end
    local dSB = _G.SkillDetailScrollFrame and (_G.SkillDetailScrollFrame.ScrollBar or _G.SkillDetailScrollFrameScrollBar)
    if dSB and S and S.HandleScrollBar then
        S:HandleScrollBar(dSB)
    end

    local detailBar = _G.SkillDetailStatusBar or _G.SkillRankFrame
    local detailBorder = _G.SkillDetailStatusBarBorder
    if detailBar then
        if detailBar.StripTextures then detailBar:StripTextures(true) end
        if detailBorder then detailBorder:Hide() end
        if detailBar.SetStatusBarTexture and E and E.media and E.media.normTex then
            detailBar:SetStatusBarTexture(E.media.normTex)
        end
        detailBar:SetHeight(12)
        if not detailBar.backdrop then
            detailBar:CreateBackdrop("Default", true)
            detailBar.backdrop:SetFrameLevel(detailBar:GetFrameLevel() - 1)
        end
    end

    if _G.SkillFrameCollapseAllButton then
        if S and S.HandleCollapseExpandButton then
            S:HandleCollapseExpandButton(_G.SkillFrameCollapseAllButton, "+")
        else
            _G.SkillFrameCollapseAllButton:SetNormalTexture(nil)
            _G.SkillFrameCollapseAllButton:SetPushedTexture(nil)
            _G.SkillFrameCollapseAllButton:SetHighlightTexture(nil)
        end
    end
    if _G.SkillFrameFilterCheckButton and S and S.HandleCheckBox then
        S:HandleCheckBox(_G.SkillFrameFilterCheckButton)
    end

    local NUM = _G.SKILLS_TO_DISPLAY or 12
    for i = 1, NUM do
        SkinSkillRow(i)
    end
end

if _G.SkillFrame and _G.SkillFrame.HookScript then
    _G.SkillFrame:HookScript("OnShow", SkinSkills)
end
if _G.CharacterFrame and _G.CharacterFrame.HookScript then
    _G.CharacterFrame:HookScript("OnShow", function()
        if _G.SkillFrame and _G.SkillFrame:IsShown() then SkinSkills() end
    end)
end
if _G.CharacterFrame_ShowSubFrame then
    hooksecurefunc("CharacterFrame_ShowSubFrame", function(name)
        if name == "SkillFrame" then SkinSkills() end
    end)
end
C_Timer.After(0, function() if _G.SkillFrame and _G.SkillFrame:IsShown() then SkinSkills() end end)

local function KillTex(f) if not f or not f.GetRegions then return end local t={f:GetRegions()} for i=1,#t do local r=t[i] if r and r.GetObjectType and r:GetObjectType()=="Texture" then if r.Hide then r:Hide() end if r.SetAlpha then r:SetAlpha(0) end if r.SetTexture then r:SetTexture(nil) end end end end

local function FindHeaderFS(row)
  local regs={row:GetRegions()}
  for i=1,#regs do local r=regs[i]; if r and r.GetObjectType and r:GetObjectType()=="FontString" then local tx=r:GetText(); if tx and tx~="" then return r end end end
  return row.text or row.Text or row:GetFontString()
end

local function StyleHeader(row)
  KillTex(row)
  for _,r in next,{row.CategoryLeft,row.CategoryRight,row.CategoryMiddle,row.Left,row.Right,row.Middle,row.Bg,row.Background,row.Highlight} do if r and r.Hide then r:Hide() end end
  if row.Highlight then row.Highlight:Hide() end
  if row.__hdr then row.__hdr:Hide() end
  local fs=FindHeaderFS(row)
  if fs then
    fs:SetParent(row)
    fs:ClearAllPoints()
    fs:SetPoint("CENTER",row,"CENTER",-8,0)
    fs:SetDrawLayer("OVERLAY",7)
    fs:SetAlpha(1)
    fs:Show()
  end
  local collapse=row.expandIcon or row.Expand or row.expandCollapseButton or row.ExpandCollapseButton
  if collapse then collapse:Hide() end
end

local function StyleNormal(row)
  if row.Highlight then row.Highlight:Hide() end
  for _,r in next,{row.Left,row.Right,row.Middle,row.Bg,row.Background,row.Highlight} do if r and r.Hide then r:Hide() end end
  local icon = row.icon or row.Icon
	if icon then
    icon:SetDesaturated(false)
    icon:SetVertexColor(1,1,1)
    icon:SetAlpha(1)
    icon:SetTexCoord(.08,.92,.08,.92)
    icon:SetDrawLayer("ARTWORK", 1)

    if not icon.backdrop then
        local b = CreateFrame("Frame", nil, row, BACKDROP_TPL)
        b:SetPoint("TOPLEFT",  icon, -1,  1)
        b:SetPoint("BOTTOMRIGHT", icon,  1, -1)
        b:SetFrameLevel((row:GetFrameLevel() or 2) - 1)
        b:SetBackdrop({ edgeFile = "Interface/Buttons/WHITE8x8", edgeSize = 1 })
        b:SetBackdropBorderColor(0,0,0,1)
        icon.backdrop = b
    else
        icon.backdrop:SetFrameLevel((row:GetFrameLevel() or 2) - 1)
    end
end
  local watch=row.Watch or row.watch or row.Check or row.WatchCheck
  if watch and S and S.HandleCheckBox then S:HandleCheckBox(watch) end
end

local function FixTokenIcon(icon)
    if not icon or icon.__patched then return end
    icon._SetDesaturated = icon.SetDesaturated
    icon._SetVertexColor = icon.SetVertexColor
    icon.SetDesaturated = function(self, _)  return self:_SetDesaturated(false) end
    icon.SetVertexColor = function(self, _,_,_,a) return self:_SetVertexColor(1,1,1,a) end
    icon:_SetDesaturated(false)
    icon:_SetVertexColor(1,1,1, icon:GetAlpha() or 1)
    icon:SetTexCoord(.08,.92,.08,.92)
    icon.__patched = true
end

local function SkinTokenRow(i)
    local row = _G["TokenFrameContainerButton"..i]
    if not row then return end

    if row.isHeader then
        StyleHeader(row)
    else
        StyleNormal(row)
        local ic = row.icon or row.Icon
        if ic then
            FixTokenIcon(ic)
            if not ic.backdrop then
                local b = MakeBD(row)
                b:SetPoint("TOPLEFT", ic, -1, 1)
                b:SetPoint("BOTTOMRIGHT", ic, 1, -1)
                b:SetFrameLevel((row:GetFrameLevel() or 2) + 2)
                ic.backdrop = b
            end
        end
        for _, k in next, {"IconBorder","iconBorder","IconOverlay","iconOverlay","DisabledIcon","disabledIcon"} do
            local t = row[k]; if t then t:Hide(); t:SetAlpha(0) end
        end
    end
end


local function SkinTokenPopup()
  local f=_G.TokenFramePopup; if not f then return end
  f:StripTextures(true)
  if not f.__bd then local b=MakeBD(f); b:SetAllPoints(f); f.__bd=b end
  if _G.TokenFramePopupCloseButton and S and S.HandleCloseButton then S:HandleCloseButton(_G.TokenFramePopupCloseButton) end
  if S and S.HandleCheckBox then
    if _G.TokenFramePopupInactiveCheckBox then S:HandleCheckBox(_G.TokenFramePopupInactiveCheckBox) end
    if _G.TokenFramePopupBackpackCheckBox then S:HandleCheckBox(_G.TokenFramePopupBackpackCheckBox) end
  end
end

local function SkinTokenFrame()
  if CharacterFrameInset then CharacterFrameInset:StripTextures(true) CharacterFrameInset:Hide() CharacterFrameInset:SetAlpha(0) end
  if TokenFrame then TokenFrame:StripTextures(true) end
  if TokenFrameContainer and TokenFrameContainer.StripTextures then TokenFrameContainer:StripTextures(true) end
  local sb=(TokenFrameContainer and (TokenFrameContainer.ScrollBar or TokenFrameContainer.Scrollbar)) or TokenFrameContainerScrollBar
  if sb and S and S.HandleScrollBar then S:HandleScrollBar(sb) end
  for i=1,30 do SkinTokenRow(i) end
  SkinTokenPopup()
end

if TokenFrame and TokenFrame.HookScript then TokenFrame:HookScript("OnShow", SkinTokenFrame) end
if CharacterFrame and CharacterFrame.HookScript then CharacterFrame:HookScript("OnShow", function() if TokenFrame and TokenFrame:IsShown() then SkinTokenFrame() end end) end
if CharacterFrame_ShowSubFrame then hooksecurefunc("CharacterFrame_ShowSubFrame", function(n) if n=="TokenFrame" then SkinTokenFrame() end end) end
if TokenFramePopup and TokenFramePopup.HookScript then TokenFramePopup:HookScript("OnShow", SkinTokenPopup) end
C_Timer.After(0, function() if TokenFrame and TokenFrame:IsShown() then SkinTokenFrame() end end)

hooksecurefunc("TokenFrame_Update", function()
    for i=1,30 do SkinTokenRow(i) end
    SkinTokenPopup()
end)

end

local function EUI_ApplyCharacterDecor()
	if CharacterFrame and CharacterFrame:IsShown() and _G.EUI_UpdateAllSlots then
		_G.EUI_UpdateAllSlots()
	end
end

if CharacterFrame and CharacterFrame.HookScript then
	CharacterFrame:HookScript("OnShow", EUI_ApplyCharacterDecor)
end
if hooksecurefunc then
	hooksecurefunc("PaperDollFrame_UpdateStats", EUI_ApplyCharacterDecor)
	hooksecurefunc("PaperDollItemSlotButton_Update", EUI_ApplyCharacterDecor)
end

S:AddCallback("Skin_Character", LoadSkin)
