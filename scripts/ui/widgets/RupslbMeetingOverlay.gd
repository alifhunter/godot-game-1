extends Control

signal close_requested
signal stage_advance_requested(next_stage_id: String)
signal vote_requested(vote_choice: String)
signal lead_approach_requested(lead_id: String)

const STAGE_ORDER := ["arrival", "seating", "host_intro", "agenda_reveal", "vote", "result"]
const COLOR_SCRIM := Color(0.0313725, 0.0470588, 0.0705882, 0.82)
const COLOR_PANEL := Color(0.952941, 0.941176, 0.870588, 1)
const COLOR_PANEL_ALT := Color(0.901961, 0.878431, 0.74902, 1)
const COLOR_INK := Color(0.215686, 0.176471, 0.105882, 1)
const COLOR_MUTED := Color(0.415686, 0.34902, 0.211765, 1)
const COLOR_BORDER := Color(0.631373, 0.545098, 0.341176, 1)
const COLOR_ACCENT := Color(0.913725, 0.690196, 0.2, 1)
const COLOR_STEPPER_ACTIVE := Color(0.137255, 0.388235, 0.666667, 1)
const COLOR_AGREE := Color(0.156863, 0.392157, 0.27451, 1)
const COLOR_DISAGREE := Color(0.560784, 0.203922, 0.203922, 1)
const COLOR_ABSTAIN := Color(0.458824, 0.384314, 0.196078, 1)
const CARD_MIN_WIDTH := 620.0
const CARD_MAX_WIDTH := 880.0
const CARD_MIN_HEIGHT := 560.0
const CARD_MAX_HEIGHT := 900.0
const CARD_SCREEN_MARGIN := 44.0
const STAGE_MIN_HEIGHT := 260.0
const STAGE_MAX_HEIGHT := 330.0
const ACTION_BUTTON_WIDTH := 320.0
const ATTENDEE_STAGE_FALLBACK_SIZE := Vector2(720, 240)
const ATTENDEE_ROW_COUNT := 3
const ATTENDEE_COLUMN_COUNT := 5
const LEAD_MARKER_SLOT_INDICES := [1, 3, 11, 13]
const ATTENDEE_MARKER_SIZE := Vector2(32, 34)
const BUBBLE_SIZE := Vector2(214, 72)
const BUBBLE_MARKER_GAP := 16.0
const ATTENDEE_STAGE_PADDING := 18.0
const BUBBLE_STAGE_PADDING := 10.0
const BUBBLE_TYPE_SECONDS_PER_CHAR := 0.065
const BUBBLE_TYPE_MIN_DURATION := 1.1
const BUBBLE_TYPE_MAX_DURATION := 3.4
const BUBBLE_CAROUSEL_STAGE_START_DELAY := 0.52
const BUBBLE_CAROUSEL_HOLD_SECONDS := 0.85
const BUBBLE_CAROUSEL_FADE_SECONDS := 0.16

var snapshot: Dictionary = {}
var current_stage_id: String = "arrival"
var stage_labels: Dictionary = {}
var attendee_markers: Array = []
var attendee_bubbles: Array = []
var attendee_seat_positions: Array = []
var attendee_lead_ids: Array = []
var active_tween: Tween = null
var bubble_carousel_tween: Tween = null
var bubble_carousel_order: Array = []
var bubble_carousel_cursor: int = 0
var bubble_carousel_active_marker_index: int = -1
var bubble_carousel_generation: int = 0
var selected_meeting_lead_id: String = ""

var scrim: ColorRect = null
var main_panel: PanelContainer = null
var bubble_layer: Control = null
var stage_label: Label = null
var title_label: Label = null
var meta_label: Label = null
var stage_chip_row: HBoxContainer = null
var agenda_title_label: Label = null
var stage_panel: PanelContainer = null
var attendee_stage: Control = null
var podium_panel: PanelContainer = null
var podium_label: Label = null
var narrative_label: Label = null
var lead_card: PanelContainer = null
var lead_title_label: Label = null
var lead_prompt_label: Label = null
var lead_status_label: Label = null
var lead_approach_button: Button = null
var agenda_label: Label = null
var observer_label: Label = null
var result_label: Label = null
var bloc_label: Label = null
var continue_button: Button = null
var agree_button: Button = null
var disagree_button: Button = null
var abstain_button: Button = null
var close_button: Button = null
var action_button_stack: VBoxContainer = null


func _ready() -> void:
	_build_ui()


func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED:
		return
	var preferred_bubble_index: int = bubble_carousel_active_marker_index
	_refresh_responsive_layout()
	_refresh_meeting_leads()
	if _bubble_stage_visible():
		_restart_bubble_carousel(preferred_bubble_index, 0.0)


func configure(next_snapshot: Dictionary) -> void:
	if main_panel == null:
		_build_ui()
	_stop_bubble_carousel()
	snapshot = next_snapshot.duplicate(true)
	current_stage_id = _normalized_stage_id(str(snapshot.get("current_stage_id", "arrival")))
	stage_labels.clear()
	for stage_value in snapshot.get("stages", []):
		var stage_row: Dictionary = stage_value
		stage_labels[str(stage_row.get("id", ""))] = str(stage_row.get("label", "Stage"))
	_refresh_header()
	_refresh_stage_chips()
	_refresh_text_content()
	_refresh_responsive_layout()
	_refresh_meeting_leads()
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
	shell_margin.add_theme_constant_override("margin_left", 24)
	shell_margin.add_theme_constant_override("margin_top", 24)
	shell_margin.add_theme_constant_override("margin_right", 24)
	shell_margin.add_theme_constant_override("margin_bottom", 24)
	add_child(shell_margin)

	var center_container := CenterContainer.new()
	center_container.name = "RupslbCenterContainer"
	center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell_margin.add_child(center_container)

	bubble_layer = Control.new()
	bubble_layer.name = "RupslbBubbleLayer"
	bubble_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble_layer.z_index = 40
	bubble_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bubble_layer)

	main_panel = PanelContainer.new()
	main_panel.name = "RupslbMainPanel"
	main_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_panel.custom_minimum_size = Vector2(CARD_MAX_WIDTH, CARD_MIN_HEIGHT)
	center_container.add_child(main_panel)
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
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 14)
	main_margin.add_child(main_vbox)

	var header_row := VBoxContainer.new()
	header_row.name = "RupslbHeaderVBox"
	header_row.add_theme_constant_override("separation", 4)
	main_vbox.add_child(header_row)

	var title_box := VBoxContainer.new()
	title_box.name = "RupslbTitleBox"
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 4)
	header_row.add_child(title_box)

	stage_label = Label.new()
	stage_label.name = "RupslbStageLabel"
	stage_label.visible = false
	title_box.add_child(stage_label)
	_set_label_tone(stage_label, COLOR_MUTED)

	title_label = Label.new()
	title_label.name = "RupslbTitleLabel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(title_label)
	_set_label_tone(title_label, COLOR_INK)

	meta_label = Label.new()
	meta_label.name = "RupslbMetaLabel"
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(meta_label)
	_set_label_tone(meta_label, COLOR_MUTED)

	stage_chip_row = HBoxContainer.new()
	stage_chip_row.name = "RupslbStageChipRow"
	stage_chip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stage_chip_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_chip_row.add_theme_constant_override("separation", 8)
	main_vbox.add_child(stage_chip_row)

	agenda_title_label = Label.new()
	agenda_title_label.name = "RupslbAgendaTitleLabel"
	agenda_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	agenda_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(agenda_title_label)
	_set_label_tone(agenda_title_label, COLOR_INK)

	stage_panel = PanelContainer.new()
	stage_panel.name = "RupslbStagePanel"
	stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stage_panel.custom_minimum_size = Vector2(0, STAGE_MIN_HEIGHT)
	main_vbox.add_child(stage_panel)
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
	attendee_stage.custom_minimum_size = ATTENDEE_STAGE_FALLBACK_SIZE
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

	var info_vbox := VBoxContainer.new()
	info_vbox.name = "RupslbDescriptionVBox"
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_vbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(info_vbox)

	narrative_label = Label.new()
	narrative_label.name = "RupslbNarrativeLabel"
	narrative_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(narrative_label)
	_set_label_tone(narrative_label, COLOR_INK)

	lead_card = PanelContainer.new()
	lead_card.name = "RupslbLeadCard"
	lead_card.visible = false
	info_vbox.add_child(lead_card)
	_style_panel(lead_card, Color(0.952941, 0.92549, 0.815686, 1), 1)

	var lead_margin := MarginContainer.new()
	lead_margin.name = "RupslbLeadCardMargin"
	lead_margin.add_theme_constant_override("margin_left", 12)
	lead_margin.add_theme_constant_override("margin_top", 10)
	lead_margin.add_theme_constant_override("margin_right", 12)
	lead_margin.add_theme_constant_override("margin_bottom", 10)
	lead_card.add_child(lead_margin)

	var lead_vbox := VBoxContainer.new()
	lead_vbox.name = "RupslbLeadCardVBox"
	lead_vbox.add_theme_constant_override("separation", 6)
	lead_margin.add_child(lead_vbox)

	lead_title_label = Label.new()
	lead_title_label.name = "RupslbLeadTitleLabel"
	lead_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lead_vbox.add_child(lead_title_label)
	_set_label_tone(lead_title_label, COLOR_INK)

	lead_prompt_label = Label.new()
	lead_prompt_label.name = "RupslbLeadPromptLabel"
	lead_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lead_vbox.add_child(lead_prompt_label)
	_set_label_tone(lead_prompt_label, COLOR_MUTED)

	lead_status_label = Label.new()
	lead_status_label.name = "RupslbLeadStatusLabel"
	lead_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lead_vbox.add_child(lead_status_label)
	_set_label_tone(lead_status_label, COLOR_INK)

	lead_approach_button = Button.new()
	lead_approach_button.name = "RupslbLeadApproachButton"
	lead_approach_button.text = "Approach"
	lead_approach_button.pressed.connect(_on_lead_approach_pressed)
	lead_vbox.add_child(lead_approach_button)
	_style_button(lead_approach_button, COLOR_PANEL_ALT, COLOR_BORDER, COLOR_INK)

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

	action_button_stack = VBoxContainer.new()
	action_button_stack.name = "RupslbActionStack"
	action_button_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	action_button_stack.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	action_button_stack.custom_minimum_size = Vector2(ACTION_BUTTON_WIDTH, 0)
	action_button_stack.add_theme_constant_override("separation", 8)
	main_vbox.add_child(action_button_stack)

	continue_button = Button.new()
	continue_button.name = "RupslbContinueButton"
	continue_button.text = "Continue"
	continue_button.pressed.connect(_on_continue_pressed)
	action_button_stack.add_child(continue_button)
	_prepare_action_button(continue_button)
	_style_button(continue_button, COLOR_ACCENT, COLOR_BORDER, COLOR_INK)

	agree_button = Button.new()
	agree_button.name = "RupslbAgreeButton"
	agree_button.text = "Agree"
	agree_button.pressed.connect(func() -> void:
		_stop_bubble_carousel()
		vote_requested.emit("agree")
	)
	action_button_stack.add_child(agree_button)
	_prepare_action_button(agree_button)
	_style_button(agree_button, COLOR_ACCENT, COLOR_BORDER, COLOR_INK)

	disagree_button = Button.new()
	disagree_button.name = "RupslbDisagreeButton"
	disagree_button.text = "Disagree"
	disagree_button.pressed.connect(func() -> void:
		_stop_bubble_carousel()
		vote_requested.emit("disagree")
	)
	action_button_stack.add_child(disagree_button)
	_prepare_action_button(disagree_button)
	_style_button(disagree_button, COLOR_DISAGREE, COLOR_BORDER, Color(1, 1, 1, 1))

	abstain_button = Button.new()
	abstain_button.name = "RupslbAbstainButton"
	abstain_button.text = "Abstain"
	abstain_button.pressed.connect(func() -> void:
		_stop_bubble_carousel()
		vote_requested.emit("abstain")
	)
	action_button_stack.add_child(abstain_button)
	_prepare_action_button(abstain_button)
	_style_button(abstain_button, COLOR_ABSTAIN, COLOR_BORDER, Color(1, 1, 1, 1))

	close_button = Button.new()
	close_button.name = "RupslbCloseButton"
	close_button.text = "Close"
	close_button.pressed.connect(func() -> void:
		_stop_bubble_carousel()
		close_requested.emit()
	)
	action_button_stack.add_child(close_button)
	_prepare_action_button(close_button)
	_style_button(close_button, Color(0.827451, 0.811765, 0.760784, 1), COLOR_BORDER, COLOR_INK)
	_refresh_responsive_layout()


func _refresh_responsive_layout() -> void:
	if main_panel == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = Vector2(1280, 720)
	var available_width: float = max(viewport_size.x - CARD_SCREEN_MARGIN * 2.0, 360.0)
	var available_height: float = max(viewport_size.y - CARD_SCREEN_MARGIN * 2.0, 420.0)
	var card_width: float = clamp(available_width, CARD_MIN_WIDTH, CARD_MAX_WIDTH)
	var card_height: float = clamp(available_height, CARD_MIN_HEIGHT, CARD_MAX_HEIGHT)
	main_panel.custom_minimum_size = Vector2(card_width, card_height)
	if stage_panel != null:
		var stage_height: float = clamp(card_height * 0.40, STAGE_MIN_HEIGHT, STAGE_MAX_HEIGHT)
		stage_panel.custom_minimum_size = Vector2(0, stage_height)
		if attendee_stage != null:
			attendee_stage.custom_minimum_size = Vector2(max(card_width - 84.0, 360.0), max(stage_height - 36.0, 170.0))
	if action_button_stack != null:
		action_button_stack.custom_minimum_size = Vector2(min(ACTION_BUTTON_WIDTH, max(card_width - 80.0, 240.0)), 0)
	_refresh_podium_layout()


func _refresh_podium_layout() -> void:
	if podium_panel == null or attendee_stage == null:
		return
	var stage_size: Vector2 = _attendee_stage_size()
	var podium_size: Vector2 = podium_panel.custom_minimum_size
	podium_panel.position = Vector2(
		stage_size.x * 0.5 - podium_size.x * 0.5,
		max(stage_size.y - podium_size.y - 18.0, stage_size.y * 0.58)
	)
	podium_panel.pivot_offset = podium_size * 0.5


func _prepare_action_button(target: Button) -> void:
	target.custom_minimum_size = Vector2(ACTION_BUTTON_WIDTH, 38)
	target.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _build_attendee_markers() -> void:
	attendee_markers.clear()
	attendee_bubbles.clear()
	attendee_seat_positions.clear()
	attendee_lead_ids.clear()
	for row in range(ATTENDEE_ROW_COUNT):
		for column in range(ATTENDEE_COLUMN_COUNT):
			var marker_index: int = attendee_markers.size()
			var marker := Button.new()
			marker.name = "RupslbAttendeeMarker_%d_%d" % [row, column]
			marker.text = ""
			marker.focus_mode = Control.FOCUS_NONE
			marker.custom_minimum_size = ATTENDEE_MARKER_SIZE
			marker.size = ATTENDEE_MARKER_SIZE
			marker.position = _entry_position_for_marker(marker_index)
			marker.modulate.a = 0.15
			marker.pressed.connect(_on_attendee_marker_pressed.bind(marker_index))
			_style_marker_button(marker, false)
			attendee_stage.add_child(marker)
			attendee_markers.append(marker)
			attendee_lead_ids.append("")

			var bubble := PanelContainer.new()
			bubble.name = "RupslbLeadBubble_%d_%d" % [row, column]
			bubble.visible = false
			bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bubble.custom_minimum_size = BUBBLE_SIZE
			bubble.size = BUBBLE_SIZE
			bubble.scale = Vector2(0.92, 0.92)
			bubble.z_index = 40
			if bubble_layer != null:
				bubble_layer.add_child(bubble)
			else:
				attendee_stage.add_child(bubble)
			_style_panel(bubble, Color(0.988235, 0.976471, 0.901961, 0.96), 1)
			var bubble_margin := MarginContainer.new()
			bubble_margin.add_theme_constant_override("margin_left", 8)
			bubble_margin.add_theme_constant_override("margin_top", 5)
			bubble_margin.add_theme_constant_override("margin_right", 8)
			bubble_margin.add_theme_constant_override("margin_bottom", 5)
			bubble_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bubble.add_child(bubble_margin)
			var bubble_label := Label.new()
			bubble_label.name = "RupslbLeadBubbleLabel"
			bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			bubble_label.add_theme_font_size_override("font_size", 10)
			bubble_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bubble_margin.add_child(bubble_label)
			_set_label_tone(bubble_label, COLOR_INK)
			attendee_bubbles.append(bubble)

			attendee_seat_positions.append(_marker_target_position(marker_index))


func _attendee_stage_size() -> Vector2:
	if attendee_stage == null:
		return ATTENDEE_STAGE_FALLBACK_SIZE
	var stage_size: Vector2 = attendee_stage.size
	if stage_size.x <= 1.0 or stage_size.y <= 1.0:
		stage_size = attendee_stage.custom_minimum_size
	if stage_size.x <= 1.0 or stage_size.y <= 1.0:
		stage_size = ATTENDEE_STAGE_FALLBACK_SIZE
	return Vector2(
		max(stage_size.x, 360.0),
		max(stage_size.y, 170.0)
	)


func _podium_rect_for_stage_size(stage_size: Vector2) -> Rect2:
	var podium_size: Vector2 = Vector2(170, 72)
	if podium_panel != null:
		podium_size = podium_panel.custom_minimum_size
	return Rect2(
		Vector2(
			stage_size.x * 0.5 - podium_size.x * 0.5,
			max(stage_size.y - podium_size.y - 18.0, stage_size.y * 0.58)
		),
		podium_size
	)


func _stage_position_from_center(center: Vector2, marker_size: Vector2, padding: float) -> Vector2:
	var stage_size: Vector2 = _attendee_stage_size()
	return Vector2(
		clamp(center.x - marker_size.x * 0.5, padding, max(padding, stage_size.x - marker_size.x - padding)),
		clamp(center.y - marker_size.y * 0.5, padding, max(padding, stage_size.y - marker_size.y - padding))
	)


func _lead_index_for_marker(marker_index: int) -> int:
	return LEAD_MARKER_SLOT_INDICES.find(marker_index)


func _marker_target_position(marker_index: int) -> Vector2:
	var stage_size: Vector2 = _attendee_stage_size()
	var marker_size: Vector2 = ATTENDEE_MARKER_SIZE
	var podium_rect: Rect2 = _podium_rect_for_stage_size(stage_size)
	var safe_index: int = clamp(marker_index, 0, ATTENDEE_ROW_COUNT * ATTENDEE_COLUMN_COUNT - 1)
	var row_index: int = int(safe_index / ATTENDEE_COLUMN_COUNT)
	var column_index: int = safe_index % ATTENDEE_COLUMN_COUNT
	var left_center: float = max(ATTENDEE_STAGE_PADDING + marker_size.x * 0.5, stage_size.x * 0.18)
	var right_center: float = min(stage_size.x - ATTENDEE_STAGE_PADDING - marker_size.x * 0.5, stage_size.x * 0.82)
	var column_spacing: float = (right_center - left_center) / float(max(ATTENDEE_COLUMN_COUNT - 1, 1))
	var top_center: float = ATTENDEE_STAGE_PADDING + marker_size.y * 0.5
	var bottom_center: float = max(
		top_center,
		podium_rect.position.y - 12.0 - marker_size.y * 0.5
	)
	var row_spacing: float = (bottom_center - top_center) / float(max(ATTENDEE_ROW_COUNT - 1, 1))
	return _stage_position_from_center(
		Vector2(
			left_center + column_spacing * float(column_index),
			top_center + row_spacing * float(row_index)
		),
		marker_size,
		ATTENDEE_STAGE_PADDING
	)


func _entry_position_for_marker(marker_index: int) -> Vector2:
	var target_position: Vector2 = _marker_target_position(marker_index)
	var stage_size: Vector2 = _attendee_stage_size()
	if _marker_enters_from_left(marker_index):
		return Vector2(-80.0 - float(marker_index * 8), target_position.y)
	return Vector2(stage_size.x + 80.0 + float(marker_index * 8), target_position.y)


func _marker_enters_from_left(marker_index: int) -> bool:
	var column_index: int = marker_index % ATTENDEE_COLUMN_COUNT
	return column_index < int(ATTENDEE_COLUMN_COUNT / 2)


func _bubble_stage_visible() -> bool:
	return STAGE_ORDER.find(current_stage_id) >= STAGE_ORDER.find("seating") and current_stage_id != "result"


func _bubble_target_position(marker_index: int) -> Vector2:
	if attendee_stage == null:
		return Vector2.ZERO
	var stage_rect: Rect2 = attendee_stage.get_global_rect()
	if stage_rect.size.x <= 1.0 or stage_rect.size.y <= 1.0:
		stage_rect = Rect2(attendee_stage.global_position, _attendee_stage_size())
	var marker_position: Vector2 = _marker_target_position(marker_index)
	var marker_size: Vector2 = ATTENDEE_MARKER_SIZE
	var marker_center: Vector2 = stage_rect.position + marker_position + marker_size * 0.5
	var left_margin: float = stage_rect.position.x + BUBBLE_STAGE_PADDING
	var right_margin: float = max(left_margin, stage_rect.end.x - BUBBLE_SIZE.x - BUBBLE_STAGE_PADDING)
	var top_margin: float = stage_rect.position.y + BUBBLE_STAGE_PADDING
	var bottom_margin: float = max(top_margin, stage_rect.end.y - BUBBLE_SIZE.y - BUBBLE_STAGE_PADDING)
	var global_position: Vector2 = Vector2(marker_center.x - BUBBLE_SIZE.x * 0.5, marker_center.y)
	var above_y: float = marker_center.y - marker_size.y * 0.5 - BUBBLE_SIZE.y - BUBBLE_MARKER_GAP
	var below_y: float = marker_center.y + marker_size.y * 0.5 + BUBBLE_MARKER_GAP
	var prefer_below: bool = marker_center.y < stage_rect.position.y + stage_rect.size.y * 0.5
	if prefer_below and below_y <= bottom_margin:
		global_position.y = below_y
	elif above_y >= top_margin:
		global_position.y = above_y
	elif below_y <= bottom_margin:
		global_position.y = below_y
	else:
		global_position.y = marker_center.y - BUBBLE_SIZE.y * 0.5
	global_position.x = clamp(global_position.x, left_margin, right_margin)
	global_position.y = clamp(global_position.y, top_margin, bottom_margin)
	if bubble_layer == null:
		return global_position
	return global_position - bubble_layer.get_global_rect().position


func _position_bubble(marker_index: int, bubble: PanelContainer) -> void:
	if bubble == null:
		return
	bubble.size = BUBBLE_SIZE
	bubble.pivot_offset = BUBBLE_SIZE * 0.5
	bubble.position = _bubble_target_position(marker_index)


func _marker_has_visible_bubble(marker_index: int) -> bool:
	return marker_index >= 0 and marker_index < attendee_lead_ids.size() and not str(attendee_lead_ids[marker_index]).is_empty()


func _visible_bubble_marker_indices() -> Array:
	var indices: Array = []
	for marker_index in range(attendee_bubbles.size()):
		if _marker_has_visible_bubble(marker_index):
			indices.append(marker_index)
	indices.sort_custom(func(left_value, right_value) -> bool:
		var left_index: int = int(left_value)
		var right_index: int = int(right_value)
		var left_position: Vector2 = _marker_target_position(left_index)
		var right_position: Vector2 = _marker_target_position(right_index)
		if absf(left_position.y - right_position.y) > 16.0:
			return left_position.y < right_position.y
		return left_position.x < right_position.x
	)
	return indices


func _hide_all_bubbles() -> void:
	for bubble_value in attendee_bubbles:
		var bubble: PanelContainer = bubble_value as PanelContainer
		if bubble == null:
			continue
		bubble.visible = false
		bubble.modulate.a = 0.0
		bubble.scale = Vector2(0.9, 0.9)
		var bubble_label: Label = bubble.find_child("RupslbLeadBubbleLabel", true, false) as Label
		if bubble_label != null:
			bubble_label.visible_characters = 0


func _stop_bubble_carousel() -> void:
	bubble_carousel_generation += 1
	if bubble_carousel_tween != null:
		bubble_carousel_tween.kill()
		bubble_carousel_tween = null
	bubble_carousel_order.clear()
	bubble_carousel_cursor = 0
	bubble_carousel_active_marker_index = -1
	_hide_all_bubbles()


func _restart_bubble_carousel(preferred_marker_index: int = -1, start_delay: float = 0.0) -> void:
	_stop_bubble_carousel()
	if not _bubble_stage_visible():
		return
	bubble_carousel_order = _visible_bubble_marker_indices()
	if bubble_carousel_order.is_empty():
		return
	bubble_carousel_cursor = 0
	if preferred_marker_index >= 0:
		var preferred_order_index: int = bubble_carousel_order.find(preferred_marker_index)
		if preferred_order_index >= 0:
			bubble_carousel_cursor = preferred_order_index
	var generation: int = bubble_carousel_generation
	if start_delay > 0.0:
		bubble_carousel_tween = create_tween()
		bubble_carousel_tween.tween_interval(start_delay)
		bubble_carousel_tween.tween_callback(Callable(self, "_play_bubble_carousel_step").bind(generation))
		return
	_play_bubble_carousel_step(generation)


func _play_bubble_carousel_step(generation: int) -> void:
	if generation != bubble_carousel_generation or not _bubble_stage_visible():
		return
	bubble_carousel_order = _visible_bubble_marker_indices()
	if bubble_carousel_order.is_empty():
		_stop_bubble_carousel()
		return
	if bubble_carousel_cursor < 0 or bubble_carousel_cursor >= bubble_carousel_order.size():
		bubble_carousel_cursor = 0
	var marker_index: int = int(bubble_carousel_order[bubble_carousel_cursor])
	if marker_index < 0 or marker_index >= attendee_bubbles.size():
		_advance_bubble_carousel(generation)
		return
	var bubble: PanelContainer = attendee_bubbles[marker_index] as PanelContainer
	if bubble == null:
		_advance_bubble_carousel(generation)
		return
	_hide_all_bubbles()
	bubble_carousel_active_marker_index = marker_index
	_position_bubble(marker_index, bubble)
	bubble.visible = true
	bubble.scale = Vector2(0.9, 0.9)
	bubble.modulate.a = 0.0
	var bubble_label: Label = bubble.find_child("RupslbLeadBubbleLabel", true, false) as Label
	var type_duration: float = BUBBLE_TYPE_MIN_DURATION
	if bubble_label != null:
		bubble_label.visible_characters = 0
		type_duration = clamp(float(bubble_label.text.length()) * BUBBLE_TYPE_SECONDS_PER_CHAR, BUBBLE_TYPE_MIN_DURATION, BUBBLE_TYPE_MAX_DURATION)
	bubble_carousel_tween = create_tween()
	bubble_carousel_tween.tween_property(bubble, "scale", Vector2.ONE, BUBBLE_CAROUSEL_FADE_SECONDS)
	bubble_carousel_tween.parallel().tween_property(bubble, "modulate:a", 1.0, BUBBLE_CAROUSEL_FADE_SECONDS)
	if bubble_label != null:
		bubble_carousel_tween.parallel().tween_property(bubble_label, "visible_characters", bubble_label.text.length(), type_duration)
	bubble_carousel_tween.tween_interval(BUBBLE_CAROUSEL_HOLD_SECONDS)
	bubble_carousel_tween.tween_property(bubble, "modulate:a", 0.0, BUBBLE_CAROUSEL_FADE_SECONDS)
	bubble_carousel_tween.tween_callback(Callable(self, "_advance_bubble_carousel").bind(generation))


func _advance_bubble_carousel(generation: int) -> void:
	if generation != bubble_carousel_generation:
		return
	if bubble_carousel_order.is_empty():
		_stop_bubble_carousel()
		return
	bubble_carousel_cursor = (bubble_carousel_cursor + 1) % bubble_carousel_order.size()
	bubble_carousel_tween = null
	_play_bubble_carousel_step(generation)


func _marker_size_for_state(_has_lead: bool) -> Vector2:
	return ATTENDEE_MARKER_SIZE


func _apply_marker_size(target: Button, has_lead: bool) -> void:
	var marker_size: Vector2 = _marker_size_for_state(has_lead)
	target.custom_minimum_size = marker_size
	target.size = marker_size
	target.pivot_offset = marker_size * 0.5
	target.z_index = 12 if has_lead else 0


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
		var is_active: bool = stage_id == current_stage_id
		var chip := PanelContainer.new()
		chip.name = "RupslbStageChip_%s" % stage_id
		stage_chip_row.add_child(chip)
		_style_panel(
			chip,
			COLOR_STEPPER_ACTIVE if is_active else Color(0.890196, 0.87451, 0.772549, 1),
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
		_set_label_tone(chip_label, Color(0.941176, 0.972549, 1, 1) if is_active else COLOR_INK)


func _refresh_text_content() -> void:
	var meeting: Dictionary = snapshot.get("meeting", {})
	var result_summary: Dictionary = snapshot.get("result_summary", {})
	var session: Dictionary = snapshot.get("session", {})
	var agenda_lines: Array = []
	var agenda_title: String = str(meeting.get("family_label", "RUPSLB Agenda"))
	for agenda_value in snapshot.get("agenda_payload", []):
		var agenda: Dictionary = agenda_value
		if agenda_lines.is_empty():
			agenda_title = str(agenda.get("label", agenda_title))
		agenda_lines.append("- %s: %s" % [
			str(agenda.get("label", "Agenda")),
			str(agenda.get("description", ""))
		])
	if agenda_title_label != null:
		agenda_title_label.text = agenda_title
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
	agenda_label.text = "\n".join(agenda_lines) if not agenda_lines.is_empty() else "No agenda published."
	agenda_label.visible = not agenda_label.text.strip_edges().is_empty()
	var voting_eligible: bool = bool(session.get("voting_eligible", false))
	var player_weight_pct: float = float(session.get("player_vote_weight_pct", 0.0))
	observer_label.text = ""
	if current_stage_id == "vote":
		if voting_eligible:
			observer_label.text = "Voting eligibility: yes  |  Player weight: %s" % _format_pct(player_weight_pct)
		else:
			observer_label.text = "%s  |  Player weight: %s" % [observer_copy, _format_pct(player_weight_pct)]
	observer_label.visible = not observer_label.text.strip_edges().is_empty()
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
	result_label.visible = not result_label.text.strip_edges().is_empty()
	bloc_label.visible = not bloc_label.text.strip_edges().is_empty()


func _refresh_meeting_leads() -> void:
	var leads: Array = snapshot.get("meeting_leads", [])
	var visible_lead_ids := {}
	for marker_index in range(attendee_markers.size()):
		var marker: Button = attendee_markers[marker_index]
		var bubble: PanelContainer = attendee_bubbles[marker_index] if marker_index < attendee_bubbles.size() else null
		if marker_index < attendee_seat_positions.size():
			attendee_seat_positions[marker_index] = _marker_target_position(marker_index)
		var lead: Dictionary = {}
		var lead_index: int = _lead_index_for_marker(marker_index)
		if lead_index >= 0 and lead_index < leads.size() and typeof(leads[lead_index]) == TYPE_DICTIONARY:
			lead = leads[lead_index]
		var lead_id: String = str(lead.get("lead_id", ""))
		attendee_lead_ids[marker_index] = lead_id
		if not lead_id.is_empty():
			visible_lead_ids[lead_id] = true
		var has_lead: bool = not lead_id.is_empty()
		var is_selected: bool = has_lead and lead_id == selected_meeting_lead_id
		_apply_marker_size(marker, has_lead)
		marker.disabled = not has_lead
		marker.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if has_lead else Control.CURSOR_ARROW
		marker.tooltip_text = ""
		if has_lead:
			marker.tooltip_text = "%s\n%s" % [
				str(lead.get("display_label", lead.get("role_label", "Meeting Attendee"))),
				str(lead.get("speech_bubble", ""))
			]
		marker.text = ""
		if has_lead:
			marker.text = "!" if bool(lead.get("approachable", false)) else "?"
		_style_marker_button(marker, has_lead, is_selected, bool(lead.get("approached", false)), bool(lead.get("approachable", false)))
		if bubble != null:
			bubble.visible = false
			bubble.tooltip_text = marker.tooltip_text
			bubble.modulate.a = 0.0
			bubble.scale = Vector2(0.9, 0.9)
			var bubble_label: Label = bubble.find_child("RupslbLeadBubbleLabel", true, false) as Label
			if bubble_label != null:
				bubble_label.text = str(lead.get("speech_bubble", ""))
				bubble_label.visible_characters = 0
			_position_bubble(marker_index, bubble)
	if not selected_meeting_lead_id.is_empty() and not visible_lead_ids.has(selected_meeting_lead_id):
		selected_meeting_lead_id = ""
	_refresh_lead_card()


func _refresh_lead_card() -> void:
	if lead_card == null:
		return
	var lead: Dictionary = _selected_meeting_lead()
	if lead.is_empty():
		lead_card.visible = false
		return
	lead_card.visible = true
	lead_title_label.text = "%s  |  %s" % [
		str(lead.get("display_label", "Meeting Attendee")),
		str(lead.get("role_label", "Lead"))
	]
	lead_prompt_label.text = str(lead.get("approach_prompt", "Approach this attendee."))
	if bool(lead.get("approached", false)):
		lead_status_label.text = str(lead.get("response_text", "They already shared a quick read."))
		lead_approach_button.visible = false
		return
	var locked_reason: String = str(lead.get("locked_reason", ""))
	lead_status_label.text = "Requirement: recognition %d  |  Cost: %d AP" % [
		int(lead.get("recognition_required", 0)),
		int(lead.get("ap_cost", 1))
	]
	if not locked_reason.is_empty():
		lead_status_label.text = locked_reason
	lead_approach_button.visible = true
	lead_approach_button.disabled = not bool(lead.get("approachable", false))
	lead_approach_button.text = "Approach (%d AP)" % int(lead.get("ap_cost", 1))


func _selected_meeting_lead() -> Dictionary:
	if selected_meeting_lead_id.is_empty():
		return {}
	for lead_value in snapshot.get("meeting_leads", []):
		if typeof(lead_value) != TYPE_DICTIONARY:
			continue
		var lead: Dictionary = lead_value
		if str(lead.get("lead_id", "")) == selected_meeting_lead_id:
			return lead
	return {}


func _on_attendee_marker_pressed(marker_index: int) -> void:
	if marker_index < 0 or marker_index >= attendee_lead_ids.size():
		return
	var lead_id: String = str(attendee_lead_ids[marker_index])
	if lead_id.is_empty():
		return
	selected_meeting_lead_id = lead_id
	_refresh_meeting_leads()
	_restart_bubble_carousel(marker_index, 0.0)


func _on_lead_approach_pressed() -> void:
	if selected_meeting_lead_id.is_empty():
		return
	lead_approach_requested.emit(selected_meeting_lead_id)


func _refresh_buttons() -> void:
	var session: Dictionary = snapshot.get("session", {})
	var result_summary: Dictionary = snapshot.get("result_summary", {})
	var voting_eligible: bool = bool(session.get("voting_eligible", false))
	var has_result: bool = not result_summary.is_empty()
	continue_button.visible = current_stage_id != "vote" and current_stage_id != "result"
	agree_button.visible = current_stage_id == "vote" and not has_result and voting_eligible
	disagree_button.visible = current_stage_id == "vote" and not has_result and voting_eligible
	abstain_button.visible = current_stage_id == "vote" and not has_result
	close_button.visible = true
	var presentation: Dictionary = snapshot.get("presentation", {})
	agree_button.text = str(presentation.get("agree_button_label", "Agree"))
	disagree_button.text = str(presentation.get("disagree_button_label", "Disagree"))
	var default_abstain_label: String = "Observe Result" if current_stage_id == "vote" and not voting_eligible else "Abstain"
	abstain_button.text = str(presentation.get("abstain_button_label", default_abstain_label))
	close_button.text = "Finish" if current_stage_id == "result" else "Close"
	_style_button(continue_button, COLOR_ACCENT, COLOR_BORDER, COLOR_INK)
	_style_button(agree_button, COLOR_ACCENT, COLOR_BORDER, COLOR_INK)
	_style_button(disagree_button, COLOR_DISAGREE, COLOR_BORDER, Color(1, 1, 1, 1))
	_style_button(abstain_button, COLOR_ABSTAIN, COLOR_BORDER, Color(1, 1, 1, 1))
	if current_stage_id == "result":
		_style_button(close_button, COLOR_ACCENT, COLOR_BORDER, COLOR_INK)
	else:
		_style_button(close_button, Color(0.827451, 0.811765, 0.760784, 1), COLOR_BORDER, COLOR_INK)


func _play_stage_animation() -> void:
	if attendee_stage == null:
		return
	_refresh_podium_layout()
	if active_tween != null:
		active_tween.kill()
	active_tween = create_tween()
	var settled: bool = STAGE_ORDER.find(current_stage_id) >= STAGE_ORDER.find("seating")
	var show_bubbles: bool = _bubble_stage_visible()
	var marker_move_duration: float = 0.58 if current_stage_id == "seating" else 0.24
	for marker_index in range(attendee_markers.size()):
		var marker: Button = attendee_markers[marker_index]
		if marker == null:
			continue
		var target_position: Vector2 = _entry_position_for_marker(marker_index)
		var target_alpha: float = 0.18
		if settled:
			target_position = _marker_target_position(marker_index)
			target_alpha = 0.92
		var move_tween = active_tween.parallel().tween_property(marker, "position", target_position, marker_move_duration)
		move_tween.set_trans(Tween.TRANS_CUBIC)
		move_tween.set_ease(Tween.EASE_OUT)
		active_tween.parallel().tween_property(marker, "modulate:a", target_alpha, 0.24)
		if marker_index < attendee_bubbles.size():
			var bubble: PanelContainer = attendee_bubbles[marker_index]
			if bubble != null:
				_position_bubble(marker_index, bubble)
				if not show_bubbles:
					bubble.visible = false
					bubble.modulate.a = 0.0
	var podium_target_scale: Vector2 = Vector2(0.94, 0.94)
	var podium_target_modulate: Color = Color(1, 1, 1, 0.8)
	if STAGE_ORDER.find(current_stage_id) >= STAGE_ORDER.find("host_intro"):
		podium_target_scale = Vector2.ONE
		podium_target_modulate = Color(1, 1, 1, 1)
	active_tween.parallel().tween_property(podium_panel, "scale", podium_target_scale, 0.24)
	active_tween.parallel().tween_property(podium_panel, "modulate", podium_target_modulate, 0.24)
	if show_bubbles:
		_restart_bubble_carousel(-1, BUBBLE_CAROUSEL_STAGE_START_DELAY if current_stage_id == "seating" else 0.12)
	else:
		_stop_bubble_carousel()


func _on_continue_pressed() -> void:
	_stop_bubble_carousel()
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
	var disabled_style := normal_style.duplicate()
	disabled_style.bg_color = fill_color
	target.add_theme_stylebox_override("normal", normal_style)
	target.add_theme_stylebox_override("hover", hover_style)
	target.add_theme_stylebox_override("pressed", pressed_style)
	target.add_theme_stylebox_override("disabled", disabled_style)
	target.add_theme_stylebox_override("focus", normal_style)
	target.add_theme_color_override("font_color", font_color)
	target.add_theme_color_override("font_hover_color", font_color)
	target.add_theme_color_override("font_pressed_color", font_color)
	target.add_theme_color_override("font_disabled_color", font_color)


func _style_marker_button(target: Button, has_lead: bool, is_selected: bool = false, approached: bool = false, approachable: bool = false) -> void:
	var fill_color: Color = Color(0.545098, 0.521569, 0.411765, 0.82)
	var border_color: Color = COLOR_BORDER
	var font_color: Color = Color(0.901961, 0.878431, 0.74902, 1)
	if has_lead:
		fill_color = Color(0.745098, 0.560784, 0.196078, 1)
		border_color = Color(0.215686, 0.176471, 0.105882, 1)
		font_color = Color(1, 0.984314, 0.898039, 1)
	if approachable:
		fill_color = Color(0.913725, 0.690196, 0.2, 1)
	if approached:
		fill_color = Color(0.156863, 0.392157, 0.27451, 1)
	if is_selected:
		border_color = Color(1.0, 0.929412, 0.560784, 1)
	_style_button(target, fill_color, border_color, font_color)
	target.add_theme_font_size_override("font_size", 18 if has_lead else 10)


func _set_label_tone(target: Label, tone: Color) -> void:
	target.add_theme_color_override("font_color", tone)
