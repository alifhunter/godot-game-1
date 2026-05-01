extends Control

signal close_requested
signal stage_advance_requested(next_stage_id: String)
signal vote_requested(vote_choice: String)

const STAGE_ORDER := ["arrival", "seating", "host_intro", "agenda_reveal", "vote", "result"]
const COLOR_SCRIM := Color(0.0313725, 0.0470588, 0.0705882, 0.82)
const COLOR_PANEL := Color(0.952941, 0.941176, 0.870588, 1)
const COLOR_PANEL_ALT := Color(0.901961, 0.878431, 0.74902, 1)
const COLOR_INK := Color(0.215686, 0.176471, 0.105882, 1)
const COLOR_MUTED := Color(0.415686, 0.34902, 0.211765, 1)
const COLOR_BORDER := Color(0.631373, 0.545098, 0.341176, 1)
const COLOR_ACCENT := Color(0.913725, 0.690196, 0.2, 1)
const COLOR_AGREE := Color(0.156863, 0.392157, 0.27451, 1)
const COLOR_DISAGREE := Color(0.560784, 0.203922, 0.203922, 1)
const COLOR_ABSTAIN := Color(0.458824, 0.384314, 0.196078, 1)

var snapshot: Dictionary = {}
var current_stage_id: String = "arrival"
var stage_labels: Dictionary = {}
var attendee_markers: Array = []
var attendee_seat_positions: Array = []
var active_tween: Tween = null

var scrim: ColorRect = null
var main_panel: PanelContainer = null
var stage_label: Label = null
var title_label: Label = null
var meta_label: Label = null
var stage_chip_row: HBoxContainer = null
var attendee_stage: Control = null
var podium_panel: PanelContainer = null
var podium_label: Label = null
var narrative_label: Label = null
var agenda_label: Label = null
var observer_label: Label = null
var result_label: Label = null
var bloc_label: Label = null
var continue_button: Button = null
var agree_button: Button = null
var disagree_button: Button = null
var abstain_button: Button = null
var close_button: Button = null


func _ready() -> void:
	_build_ui()


func configure(next_snapshot: Dictionary) -> void:
	if main_panel == null:
		_build_ui()
	snapshot = next_snapshot.duplicate(true)
	current_stage_id = _normalized_stage_id(str(snapshot.get("current_stage_id", "arrival")))
	stage_labels.clear()
	for stage_value in snapshot.get("stages", []):
		var stage_row: Dictionary = stage_value
		stage_labels[str(stage_row.get("id", ""))] = str(stage_row.get("label", "Stage"))
	_refresh_header()
	_refresh_stage_chips()
	_refresh_text_content()
	_refresh_buttons()
	_play_stage_animation()


func get_current_stage_id() -> String:
	return current_stage_id


func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)

	scrim = ColorRect.new()
	scrim.name = "RupslbScrim"
	scrim.color = COLOR_SCRIM
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)

	var shell_margin := MarginContainer.new()
	shell_margin.name = "RupslbShellMargin"
	shell_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell_margin.add_theme_constant_override("margin_left", 48)
	shell_margin.add_theme_constant_override("margin_top", 44)
	shell_margin.add_theme_constant_override("margin_right", 48)
	shell_margin.add_theme_constant_override("margin_bottom", 36)
	add_child(shell_margin)

	main_panel = PanelContainer.new()
	main_panel.name = "RupslbMainPanel"
	main_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell_margin.add_child(main_panel)
	_style_panel(main_panel, COLOR_PANEL, 2)

	var main_margin := MarginContainer.new()
	main_margin.name = "RupslbMainMargin"
	main_margin.add_theme_constant_override("margin_left", 24)
	main_margin.add_theme_constant_override("margin_top", 20)
	main_margin.add_theme_constant_override("margin_right", 24)
	main_margin.add_theme_constant_override("margin_bottom", 20)
	main_panel.add_child(main_margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.name = "RupslbMainVBox"
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 14)
	main_margin.add_child(main_vbox)

	var header_row := HBoxContainer.new()
	header_row.name = "RupslbHeaderRow"
	header_row.add_theme_constant_override("separation", 18)
	main_vbox.add_child(header_row)

	var title_box := VBoxContainer.new()
	title_box.name = "RupslbTitleBox"
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 4)
	header_row.add_child(title_box)

	stage_label = Label.new()
	stage_label.name = "RupslbStageLabel"
	title_box.add_child(stage_label)
	_set_label_tone(stage_label, COLOR_MUTED)

	title_label = Label.new()
	title_label.name = "RupslbTitleLabel"
	title_box.add_child(title_label)
	_set_label_tone(title_label, COLOR_INK)

	meta_label = Label.new()
	meta_label.name = "RupslbMetaLabel"
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_box.add_child(meta_label)
	_set_label_tone(meta_label, COLOR_MUTED)

	stage_chip_row = HBoxContainer.new()
	stage_chip_row.name = "RupslbStageChipRow"
	stage_chip_row.add_theme_constant_override("separation", 8)
	main_vbox.add_child(stage_chip_row)

	var content_row := HBoxContainer.new()
	content_row.name = "RupslbContentRow"
	content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 18)
	main_vbox.add_child(content_row)

	var stage_panel := PanelContainer.new()
	stage_panel.name = "RupslbStagePanel"
	stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_panel.custom_minimum_size = Vector2(520, 320)
	content_row.add_child(stage_panel)
	_style_panel(stage_panel, Color(0.933333, 0.909804, 0.803922, 1), 2)

	var stage_margin := MarginContainer.new()
	stage_margin.name = "RupslbStageMargin"
	stage_margin.add_theme_constant_override("margin_left", 18)
	stage_margin.add_theme_constant_override("margin_top", 18)
	stage_margin.add_theme_constant_override("margin_right", 18)
	stage_margin.add_theme_constant_override("margin_bottom", 18)
	stage_panel.add_child(stage_margin)

	attendee_stage = Control.new()
	attendee_stage.name = "RupslbAttendeeStage"
	attendee_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attendee_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	attendee_stage.custom_minimum_size = Vector2(500, 300)
	stage_margin.add_child(attendee_stage)

	podium_panel = PanelContainer.new()
	podium_panel.name = "RupslbPodiumPanel"
	podium_panel.custom_minimum_size = Vector2(170, 72)
	podium_panel.position = Vector2(170, 204)
	attendee_stage.add_child(podium_panel)
	_style_panel(podium_panel, COLOR_PANEL_ALT, 2)

	var podium_margin := MarginContainer.new()
	podium_margin.name = "RupslbPodiumMargin"
	podium_margin.add_theme_constant_override("margin_left", 10)
	podium_margin.add_theme_constant_override("margin_top", 8)
	podium_margin.add_theme_constant_override("margin_right", 10)
	podium_margin.add_theme_constant_override("margin_bottom", 8)
	podium_panel.add_child(podium_margin)

	podium_label = Label.new()
	podium_label.name = "RupslbPodiumLabel"
	podium_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	podium_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	podium_label.text = "HOST / PODIUM"
	podium_margin.add_child(podium_label)
	_set_label_tone(podium_label, COLOR_INK)

	_build_attendee_markers()

	var info_panel := PanelContainer.new()
	info_panel.name = "RupslbInfoPanel"
	info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_panel.custom_minimum_size = Vector2(440, 320)
	content_row.add_child(info_panel)
	_style_panel(info_panel, Color(0.976471, 0.972549, 0.917647, 1), 2)

	var info_margin := MarginContainer.new()
	info_margin.name = "RupslbInfoMargin"
	info_margin.add_theme_constant_override("margin_left", 18)
	info_margin.add_theme_constant_override("margin_top", 18)
	info_margin.add_theme_constant_override("margin_right", 18)
	info_margin.add_theme_constant_override("margin_bottom", 18)
	info_panel.add_child(info_margin)

	var info_vbox := VBoxContainer.new()
	info_vbox.name = "RupslbInfoVBox"
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 10)
	info_margin.add_child(info_vbox)

	narrative_label = Label.new()
	narrative_label.name = "RupslbNarrativeLabel"
	narrative_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(narrative_label)
	_set_label_tone(narrative_label, COLOR_INK)

	agenda_label = Label.new()
	agenda_label.name = "RupslbAgendaLabel"
	agenda_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(agenda_label)
	_set_label_tone(agenda_label, COLOR_INK)

	observer_label = Label.new()
	observer_label.name = "RupslbObserverLabel"
	observer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(observer_label)
	_set_label_tone(observer_label, COLOR_MUTED)

	result_label = Label.new()
	result_label.name = "RupslbResultLabel"
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(result_label)
	_set_label_tone(result_label, COLOR_INK)

	bloc_label = Label.new()
	bloc_label.name = "RupslbBlocLabel"
	bloc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bloc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(bloc_label)
	_set_label_tone(bloc_label, COLOR_MUTED)

	var button_row := HBoxContainer.new()
	button_row.name = "RupslbButtonRow"
	button_row.alignment = BoxContainer.ALIGNMENT_END
	button_row.add_theme_constant_override("separation", 8)
	main_vbox.add_child(button_row)

	continue_button = Button.new()
	continue_button.name = "RupslbContinueButton"
	continue_button.text = "Continue"
	continue_button.pressed.connect(_on_continue_pressed)
	button_row.add_child(continue_button)
	_style_button(continue_button, COLOR_PANEL_ALT, COLOR_BORDER, COLOR_INK)

	agree_button = Button.new()
	agree_button.name = "RupslbAgreeButton"
	agree_button.text = "Agree"
	agree_button.pressed.connect(func() -> void:
		vote_requested.emit("agree")
	)
	button_row.add_child(agree_button)
	_style_button(agree_button, COLOR_AGREE, COLOR_BORDER, Color(1, 1, 1, 1))

	disagree_button = Button.new()
	disagree_button.name = "RupslbDisagreeButton"
	disagree_button.text = "Disagree"
	disagree_button.pressed.connect(func() -> void:
		vote_requested.emit("disagree")
	)
	button_row.add_child(disagree_button)
	_style_button(disagree_button, COLOR_DISAGREE, COLOR_BORDER, Color(1, 1, 1, 1))

	abstain_button = Button.new()
	abstain_button.name = "RupslbAbstainButton"
	abstain_button.text = "Abstain"
	abstain_button.pressed.connect(func() -> void:
		vote_requested.emit("abstain")
	)
	button_row.add_child(abstain_button)
	_style_button(abstain_button, COLOR_ABSTAIN, COLOR_BORDER, Color(1, 1, 1, 1))

	close_button = Button.new()
	close_button.name = "RupslbCloseButton"
	close_button.text = "Close"
	close_button.pressed.connect(func() -> void:
		close_requested.emit()
	)
	button_row.add_child(close_button)
	_style_button(close_button, Color(0.827451, 0.811765, 0.760784, 1), COLOR_BORDER, COLOR_INK)


func _build_attendee_markers() -> void:
	attendee_markers.clear()
	attendee_seat_positions.clear()
	var start_x: float = 54.0
	var start_y: float = 44.0
	var spacing_x: float = 82.0
	var spacing_y: float = 78.0
	for row in range(2):
		for column in range(5):
			var marker := ColorRect.new()
			marker.name = "RupslbAttendeeMarker_%d_%d" % [row, column]
			marker.color = Color(0.321569, 0.235294, 0.117647, 0.85)
			marker.custom_minimum_size = Vector2(16, 20)
			marker.size = Vector2(16, 20)
			marker.position = Vector2(-48.0 - float(column * 18), 34.0 + float(row * 22))
			marker.modulate.a = 0.15
			attendee_stage.add_child(marker)
			attendee_markers.append(marker)
			attendee_seat_positions.append(Vector2(
				start_x + float(column) * spacing_x,
				start_y + float(row) * spacing_y
			))


func _refresh_header() -> void:
	var meeting: Dictionary = snapshot.get("meeting", {})
	stage_label.text = str(snapshot.get("current_stage_label", "Meeting"))
	title_label.text = "%s  |  %s" % [
		str(meeting.get("company_name", meeting.get("ticker", "RUPSLB"))),
		str(meeting.get("meeting_label", "RUPSLB"))
	]
	meta_label.text = "%s  |  %s  |  %s" % [
		str(meeting.get("ticker", "")),
		_format_trade_date(meeting.get("trade_date", {})),
		str(meeting.get("family_label", "Rights Issue"))
	]


func _refresh_stage_chips() -> void:
	for child in stage_chip_row.get_children():
		stage_chip_row.remove_child(child)
		child.queue_free()
	for stage_id_value in STAGE_ORDER:
		var stage_id: String = str(stage_id_value)
		var chip := PanelContainer.new()
		chip.name = "RupslbStageChip_%s" % stage_id
		stage_chip_row.add_child(chip)
		_style_panel(
			chip,
			COLOR_ACCENT if stage_id == current_stage_id else Color(0.890196, 0.87451, 0.772549, 1),
			1
		)
		var chip_margin := MarginContainer.new()
		chip_margin.add_theme_constant_override("margin_left", 10)
		chip_margin.add_theme_constant_override("margin_top", 6)
		chip_margin.add_theme_constant_override("margin_right", 10)
		chip_margin.add_theme_constant_override("margin_bottom", 6)
		chip.add_child(chip_margin)
		var chip_label := Label.new()
		chip_label.text = str(stage_labels.get(stage_id, stage_id.replace("_", " ").capitalize()))
		chip_margin.add_child(chip_label)
		_set_label_tone(chip_label, COLOR_INK)


func _refresh_text_content() -> void:
	var meeting: Dictionary = snapshot.get("meeting", {})
	var result_summary: Dictionary = snapshot.get("result_summary", {})
	var session: Dictionary = snapshot.get("session", {})
	var agenda_lines: Array = []
	for agenda_value in snapshot.get("agenda_payload", []):
		var agenda: Dictionary = agenda_value
		agenda_lines.append("- %s: %s" % [
			str(agenda.get("label", "Agenda")),
			str(agenda.get("description", ""))
		])
	var vote_prompt: String = str(snapshot.get("vote_prompt", "Cast your vote."))
	var host_intro_text: String = str(snapshot.get("host_intro_text", "The room settles as management moves to the podium."))
	var observer_copy: String = str(snapshot.get("observer_copy", "Only shareholders can vote today."))
	match current_stage_id:
		"arrival":
			narrative_label.text = "You enter the hall as shareholder registration wraps up for %s." % str(meeting.get("company_name", "the company"))
		"seating":
			narrative_label.text = "Attendees file into their seats and the room starts to settle."
		"host_intro":
			narrative_label.text = host_intro_text
		"agenda_reveal":
			narrative_label.text = "The meeting clerk projects the published agenda and the room focuses on the main proposal."
		"vote":
			narrative_label.text = vote_prompt
		"result":
			narrative_label.text = str(snapshot.get("result_copy", "The board closes the vote and the final tally is projected to the room."))
		_:
			narrative_label.text = "The room is in session."
	agenda_label.text = "Agenda\n%s" % ("\n".join(agenda_lines) if not agenda_lines.is_empty() else "No agenda published.")
	var voting_eligible: bool = bool(session.get("voting_eligible", false))
	var player_weight_pct: float = float(session.get("player_vote_weight_pct", 0.0))
	observer_label.text = ""
	if current_stage_id == "vote":
		if voting_eligible:
			observer_label.text = "Voting eligibility: yes  |  Player weight: %s" % _format_pct(player_weight_pct)
		else:
			observer_label.text = "%s  |  Player weight: %s" % [observer_copy, _format_pct(player_weight_pct)]
	result_label.text = ""
	bloc_label.text = ""
	if current_stage_id == "result" and not result_summary.is_empty():
		if str(result_summary.get("result_category", "")) == "tender_election":
			result_label.text = "Election Board\nTender %s  |  Hold %s  |  Observe %s" % [
				_format_pct(float(result_summary.get("yes_pct", 0.0))),
				_format_pct(float(result_summary.get("no_pct", 0.0))),
				_format_pct(float(result_summary.get("abstain_pct", 0.0)))
			]
		else:
			result_label.text = "Result Board\nAgree %s  |  Disagree %s  |  Abstain %s" % [
				_format_pct(float(result_summary.get("yes_pct", 0.0))),
				_format_pct(float(result_summary.get("no_pct", 0.0))),
				_format_pct(float(result_summary.get("abstain_pct", 0.0)))
			]
		var bloc_lines: Array = []
		for bloc_value in result_summary.get("bloc_rows", []):
			var bloc: Dictionary = bloc_value
			bloc_lines.append("%s  |  A %s / D %s / Abs %s  |  %s" % [
				str(bloc.get("label", "Bloc")),
				_format_pct(float(bloc.get("agree_pct", 0.0))),
				_format_pct(float(bloc.get("disagree_pct", 0.0))),
				_format_pct(float(bloc.get("abstain_pct", 0.0))),
				str(bloc.get("note", ""))
			])
		bloc_label.text = "Bloc Attribution\n%s" % "\n".join(bloc_lines)


func _refresh_buttons() -> void:
	var session: Dictionary = snapshot.get("session", {})
	var result_summary: Dictionary = snapshot.get("result_summary", {})
	var voting_eligible: bool = bool(session.get("voting_eligible", false))
	var has_result: bool = not result_summary.is_empty()
	continue_button.visible = current_stage_id != "vote" and current_stage_id != "result"
	agree_button.visible = current_stage_id == "vote" and not has_result and voting_eligible
	disagree_button.visible = current_stage_id == "vote" and not has_result and voting_eligible
	abstain_button.visible = current_stage_id == "vote" and not has_result
	var presentation: Dictionary = snapshot.get("presentation", {})
	agree_button.text = str(presentation.get("agree_button_label", "Agree"))
	disagree_button.text = str(presentation.get("disagree_button_label", "Disagree"))
	var default_abstain_label: String = "Observe Result" if current_stage_id == "vote" and not voting_eligible else "Abstain"
	abstain_button.text = str(presentation.get("abstain_button_label", default_abstain_label))
	close_button.text = "Finish" if current_stage_id == "result" else "Close"


func _play_stage_animation() -> void:
	if attendee_stage == null:
		return
	if active_tween != null:
		active_tween.kill()
	active_tween = create_tween()
	var settled: bool = STAGE_ORDER.find(current_stage_id) >= STAGE_ORDER.find("seating")
	for marker_index in range(attendee_markers.size()):
		var marker: ColorRect = attendee_markers[marker_index]
		if marker == null:
			continue
		var target_position: Vector2 = Vector2(-48.0 - float(marker_index * 12), 26.0 + float(marker_index % 2) * 18.0)
		var target_alpha: float = 0.18
		if settled and marker_index < attendee_seat_positions.size():
			target_position = attendee_seat_positions[marker_index]
			target_alpha = 0.92
		active_tween.parallel().tween_property(marker, "position", target_position, 0.28)
		active_tween.parallel().tween_property(marker, "modulate:a", target_alpha, 0.28)
	var podium_target_scale: Vector2 = Vector2(0.94, 0.94)
	var podium_target_modulate: Color = Color(1, 1, 1, 0.8)
	if STAGE_ORDER.find(current_stage_id) >= STAGE_ORDER.find("host_intro"):
		podium_target_scale = Vector2.ONE
		podium_target_modulate = Color(1, 1, 1, 1)
	active_tween.parallel().tween_property(podium_panel, "scale", podium_target_scale, 0.24)
	active_tween.parallel().tween_property(podium_panel, "modulate", podium_target_modulate, 0.24)


func _on_continue_pressed() -> void:
	var next_stage_id: String = current_stage_id
	var stage_index: int = STAGE_ORDER.find(current_stage_id)
	if stage_index >= 0 and stage_index < STAGE_ORDER.size() - 1:
		next_stage_id = STAGE_ORDER[stage_index + 1]
	stage_advance_requested.emit(next_stage_id)


func _normalized_stage_id(stage_id: String) -> String:
	var normalized_stage_id: String = stage_id.strip_edges().to_lower()
	if STAGE_ORDER.has(normalized_stage_id):
		return normalized_stage_id
	return STAGE_ORDER[0]


func _format_trade_date(trade_date: Dictionary) -> String:
	var year_value: int = int(trade_date.get("year", 2020))
	var month_value: int = int(trade_date.get("month", 1))
	var day_value: int = int(trade_date.get("day", 1))
	return "%04d-%02d-%02d" % [year_value, month_value, day_value]


func _format_pct(value: float) -> String:
	return "%s%%" % String.num(value * 100.0, 2)


func _style_panel(target: Control, fill_color: Color, border_width: int) -> void:
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = fill_color
	style_box.border_color = COLOR_BORDER
	style_box.border_width_left = border_width
	style_box.border_width_top = border_width
	style_box.border_width_right = border_width
	style_box.border_width_bottom = border_width
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	target.add_theme_stylebox_override("panel", style_box)


func _style_button(target: Button, fill_color: Color, border_color: Color, font_color: Color) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = fill_color
	normal_style.border_color = border_color
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	var hover_style := normal_style.duplicate()
	hover_style.bg_color = fill_color.lightened(0.05)
	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = fill_color.darkened(0.08)
	target.add_theme_stylebox_override("normal", normal_style)
	target.add_theme_stylebox_override("hover", hover_style)
	target.add_theme_stylebox_override("pressed", pressed_style)
	target.add_theme_stylebox_override("focus", normal_style)
	target.add_theme_color_override("font_color", font_color)
	target.add_theme_color_override("font_hover_color", font_color)
	target.add_theme_color_override("font_pressed_color", font_color)


func _set_label_tone(target: Label, tone: Color) -> void:
	target.add_theme_color_override("font_color", tone)
