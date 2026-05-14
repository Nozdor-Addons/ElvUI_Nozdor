local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts")

--Lua functions
local format, join = string.format, string.join
--WoW API / Variables
local GetCombatRating = GetCombatRating
local GetCombatRatingBonus = GetCombatRatingBonus
local UnitAttackSpeed = UnitAttackSpeed
local UnitRangedDamage = UnitRangedDamage
local UnitSpellHaste = UnitSpellHaste
local ATTACK_SPEED = ATTACK_SPEED
local CR_HASTE_MELEE = CR_HASTE_MELEE
local CR_HASTE_RANGED = CR_HASTE_RANGED
local CR_HASTE_RATING_TOOLTIP = CR_HASTE_RATING_TOOLTIP
local CR_HASTE_SPELL = CR_HASTE_SPELL
local PAPERDOLLFRAME_TOOLTIP_FORMAT = PAPERDOLLFRAME_TOOLTIP_FORMAT
local SPELL_HASTE = SPELL_HASTE
local SPELL_HASTE_ABBR = SPELL_HASTE_ABBR

local haste_rating = 0
local display_number_string = ""
local last_panel

--- @brief Возвращает актуальный тип рейтинга скорости для текущей роли персонажа.
--- @return number Идентификатор combat rating для заклинаний, дальнего или ближнего боя.
local function get_haste_rating_id()
	if E.Role == "Caster" then
		return CR_HASTE_SPELL
	elseif E.myclass == "HUNTER" then
		return CR_HASTE_RANGED
	else
		return CR_HASTE_MELEE
	end
end

--- @brief Обновляет сохранённый рейтинг скорости, который используется текстом панели и подсказкой.
--- @return number Текущий рейтинг скорости. Если API вернул nil, возвращается 0.
local function update_haste_rating()
	haste_rating = GetCombatRating(get_haste_rating_id()) or 0

	return haste_rating
end

--- @brief Возвращает общий процент скорости произнесения заклинаний.
--- @return number Процент spell haste с учётом эффектов персонажа или бонуса рейтинга, если UnitSpellHaste недоступен.
local function get_spell_haste()
	if UnitSpellHaste then
		return UnitSpellHaste("player") or 0
	else
		return GetCombatRatingBonus(CR_HASTE_SPELL) or 0
	end
end

--- @brief Обновляет отображаемое значение дататекста скорости.
--- @param self frame Панель дататекста, текст которой нужно обновить.
--- @param event string|nil Название события, вызвавшего обновление.
--- @return nil
local function on_event(self, event)
	last_panel = self

	if event == "SPELL_UPDATE_USABLE" then
		self:UnregisterEvent(event)
	end

	update_haste_rating()

	self.text:SetFormattedText(display_number_string, haste_rating)
end

--- @brief Показывает подсказку с текущей скоростью атаки или произнесения и рейтингом haste.
--- @param self frame Панель дататекста, над которой находится курсор.
--- @return nil
local function on_enter(self)
	DT:SetupTooltip(self)
	update_haste_rating()

	local text, tooltip
	if E.Role == "Caster" then
		text = format("%s %.2f%%", SPELL_HASTE, get_spell_haste())
		tooltip = format(CR_HASTE_RATING_TOOLTIP, haste_rating, GetCombatRatingBonus(CR_HASTE_SPELL) or 0)
	elseif E.myclass == "HUNTER" then
		text = format("%s %.2f", format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED), UnitRangedDamage("player") or 0)
		tooltip = format(CR_HASTE_RATING_TOOLTIP, haste_rating, GetCombatRatingBonus(CR_HASTE_RANGED) or 0)
	else
		local speed, offhandSpeed = UnitAttackSpeed("player")
		speed = speed or 0

		if offhandSpeed then
			text = format("%s %.2f / %.2f", format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED), speed, offhandSpeed)
		else
			text = format("%s %.2f", format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED), speed)
		end

		tooltip = format(CR_HASTE_RATING_TOOLTIP, haste_rating, GetCombatRatingBonus(CR_HASTE_MELEE) or 0)
	end

	DT.tooltip:AddLine(text, 1, 1, 1)
	DT.tooltip:AddLine(tooltip, nil, nil, nil, 1)

	DT.tooltip:Show()
end

--- @brief Обновляет цветовую строку дататекста и перерисовывает последнюю активную панель.
--- @param hex string Цветовая escape-последовательность ElvUI для значения.
--- @return nil
local function value_color_update(hex)
	display_number_string = join("", SPELL_HASTE_ABBR, ": ", hex, "%d|r")

	if last_panel ~= nil then
		on_event(last_panel)
	end
end
E.valueColorUpdateFuncs[value_color_update] = true

DT:RegisterDatatext("Haste", {"SPELL_UPDATE_USABLE", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE", "UNIT_ATTACK_SPEED", "UNIT_SPELL_HASTE"}, on_event, nil, nil, on_enter, nil, SPELL_HASTE)
