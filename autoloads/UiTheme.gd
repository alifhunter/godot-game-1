extends Node

const FONT_REGULAR_PATH := "res://assets/fonts/OpenSans-Regular.ttf"
const FONT_SEMIBOLD_PATH := "res://assets/fonts/OpenSans-SemiBold.ttf"
const FONT_BOLD_PATH := "res://assets/fonts/OpenSans-Bold.ttf"

const DEFAULT_UI_SCALE := "normal"
const VALID_UI_SCALES := ["compact", "normal", "large", "accessibility"]

const COLORS := {
	"desktop.bg": Color(0.909804, 0.909804, 0.803922, 1),
	"desktop.panel": Color(0.945098, 0.909804, 0.803922, 1),
	"desktop.cream": Color(1.0, 0.976471, 0.929412, 1),
	"desktop.text": Color(0.184314, 0.172549, 0.109804, 1),
	"desktop.muted": Color(0.352941, 0.337255, 0.239216, 1),
	"desktop.brown": Color(0.509804, 0.231373, 0.0941176, 1),
	"desktop.olive": Color(0.247059, 0.278431, 0.117647, 1),
	"desktop.gold": Color(0.972549, 0.713726, 0.0627451, 1),
	"desktop.frame": Color(0.729412, 0.694118, 0.603922, 1),
	"desktop.green": Color(0.176471, 0.439216, 0.231373, 1),
	"desktop.window_shadow": Color(0.251, 0.188, 0.102, 0.18),
	"desktop.card_fill": Color(0.984314, 0.94902, 0.835294, 1),
	"desktop.shortcut_border": Color(0.870588, 0.788235, 0.647059, 1),
	"desktop.shortcut_hover": Color(0.992157, 0.941176, 0.760784, 1),
	"desktop.shortcut_pressed": Color(0.882353, 0.831373, 0.65098, 1),
	"terminal.bg": Color(0.0901961, 0.129412, 0.164706, 0.98),
	"terminal.panel": Color(0.109804, 0.14902, 0.184314, 0.94),
	"terminal.panel_alt": Color(0.0901961, 0.129412, 0.164706, 0.96),
	"terminal.panel_green": Color(0.0862745, 0.152941, 0.133333, 0.95),
	"terminal.panel_gold": Color(0.192157, 0.152941, 0.0823529, 0.95),
	"terminal.border": Color(0.333333, 0.462745, 0.580392, 0.8),
	"terminal.text": Color(0.92549, 0.941176, 0.956863, 1),
	"terminal.muted": Color(0.694118, 0.756863, 0.803922, 1),
	"terminal.accent": Color(0.560784, 0.772549, 1, 1),
	"terminal.nav_fill": Color(0.126, 0.188, 0.251, 1),
	"terminal.nav_active_fill": Color(0.219608, 0.439216, 0.65098, 1),
	"terminal.nav_active_border": Color(0.690196, 0.87451, 1, 1),
	"semantic.positive": Color(0.513726, 0.886275, 0.662745, 1),
	"semantic.negative": Color(0.968627, 0.513726, 0.513726, 1),
	"semantic.warning": Color(0.980392, 0.792157, 0.392157, 1),
	"semantic.accent": Color(0.560784, 0.772549, 1, 1),
	"state.disabled_fill": Color(0.752941, 0.717647, 0.596078, 1),
	"state.transparent": Color(0, 0, 0, 0),
	"dialog.bg": Color(1.0, 0.976471, 0.929412, 1),
	"dialog.border": Color(0.509804, 0.231373, 0.0941176, 1),
	"buy.fill": Color(0.117647, 0.32549, 0.239216, 1),
	"buy.border": Color(0.309804, 0.631373, 0.486275, 1),
	"sell.fill": Color(0.27451, 0.164706, 0.180392, 1),
	"sell.border": Color(0.690196, 0.34902, 0.372549, 1)
}

const FONT_SIZE_PRESETS := {
	"compact": {
		"caption": 11,
		"body": 12,
		"button": 12,
		"section": 14,
		"title": 16,
		"metric": 18
	},
	"normal": {
		"caption": 12,
		"body": 14,
		"button": 14,
		"section": 16,
		"title": 18,
		"metric": 20
	},
	"large": {
		"caption": 14,
		"body": 16,
		"button": 16,
		"section": 18,
		"title": 20,
		"metric": 22
	},
	"accessibility": {
		"caption": 16,
		"body": 18,
		"button": 18,
		"section": 20,
		"title": 22,
		"metric": 26
	}
}

var current_ui_scale := DEFAULT_UI_SCALE
var cached_fonts: Dictionary = {}


func color(token: String) -> Color:
	return COLORS.get(token, Color.WHITE)


func font(role: String = "regular") -> Font:
	var normalized_role: String = role.strip_edges().to_lower()
	if normalized_role.is_empty():
		normalized_role = "regular"
	if cached_fonts.has(normalized_role):
		return cached_fonts[normalized_role]

	var font_path := FONT_REGULAR_PATH
	if normalized_role == "semibold":
		font_path = FONT_SEMIBOLD_PATH
	elif normalized_role == "bold":
		font_path = FONT_BOLD_PATH

	var loaded_font: Font = null
	if ResourceLoader.exists(font_path):
		var resource := load(font_path)
		if resource is Font:
			loaded_font = resource
	if loaded_font == null and normalized_role != "regular":
		loaded_font = font("regular")
	cached_fonts[normalized_role] = loaded_font
	return loaded_font


func font_size(role: String, scale_id: String = "") -> int:
	var scale_key: String = scale_id if not scale_id.is_empty() else current_ui_scale
	if not FONT_SIZE_PRESETS.has(scale_key):
		scale_key = DEFAULT_UI_SCALE
	var scale_sizes: Dictionary = FONT_SIZE_PRESETS[scale_key]
	return int(scale_sizes.get(role, scale_sizes.get("body", 12)))


func set_ui_scale(scale_id: String) -> void:
	if VALID_UI_SCALES.has(scale_id):
		current_ui_scale = scale_id


func get_ui_scale() -> String:
	return current_ui_scale


func apply_tree_font(root: Node, role: String = "body") -> void:
	if root == null:
		return
	if root is Control:
		_apply_font_override_to_control(root as Control, role)
	for child: Node in root.get_children():
		apply_tree_font(child, role)


func make_stylebox(
	bg: Color,
	border: Color,
	border_width: int = 1,
	radius: int = 4,
	margins: Dictionary = {}
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	_apply_content_margins(style, margins)
	return style


func style_label(label: Label, variant: String) -> void:
	if label == null:
		return
	var font_role := "regular"
	var size_role := "body"
	var text_color := color("desktop.text")
	match variant:
		"desktop_title":
			font_role = "semibold"
			size_role = "title"
			text_color = color("desktop.brown")
		"desktop_body":
			text_color = color("desktop.text")
		"desktop_muted":
			text_color = color("desktop.muted")
		"terminal_title":
			font_role = "semibold"
			size_role = "section"
			text_color = color("terminal.text")
		"terminal_body":
			text_color = color("terminal.text")
		"terminal_muted":
			text_color = color("terminal.muted")
		"positive":
			font_role = "semibold"
			text_color = color("semantic.positive")
		"negative":
			font_role = "semibold"
			text_color = color("semantic.negative")
		"warning":
			font_role = "semibold"
			text_color = color("semantic.warning")
		"accent":
			font_role = "semibold"
			text_color = color("semantic.accent")
	label.add_theme_font_override("font", font(font_role))
	label.add_theme_font_size_override("font_size", font_size(size_role))
	label.add_theme_color_override("font_color", text_color)


func style_button(button: Button, variant: String, options: Dictionary = {}) -> void:
	if button == null:
		return
	var selected: bool = bool(options.get("selected", false))
	var fill_color := color("terminal.nav_fill")
	var border_color := color("terminal.border")
	var text_color := color("terminal.text")
	var hover_color := fill_color.lightened(0.1)
	var pressed_color := fill_color.darkened(0.08)
	var disabled_color := Color(0.137255, 0.176471, 0.211765, 1)
	var disabled_text_color := color("terminal.muted")
	var radius := 8
	var border_width := 1
	var font_role := "semibold"
	var size_role := "button"
	var margins: Dictionary = {}
	var icon_color := text_color

	match variant:
		"desktop_primary":
			fill_color = color("desktop.gold")
			border_color = color("desktop.brown")
			text_color = color("desktop.text")
			hover_color = fill_color.lightened(0.08)
			pressed_color = fill_color.darkened(0.10)
			disabled_color = color("state.disabled_fill")
			disabled_text_color = color("desktop.muted")
			radius = 4
			border_width = 2
		"desktop_secondary":
			fill_color = color("desktop.cream")
			border_color = color("desktop.brown")
			text_color = color("desktop.text")
			hover_color = fill_color.lightened(0.08)
			pressed_color = fill_color.darkened(0.10)
			disabled_color = color("state.disabled_fill")
			disabled_text_color = color("desktop.muted")
			radius = 4
			border_width = 2
		"desktop_danger":
			fill_color = Color(0.368627, 0.160784, 0.176471, 1)
			border_color = color("desktop.brown")
			text_color = color("desktop.cream")
			hover_color = Color(0.709804, 0.34902, 0.372549, 1)
			pressed_color = fill_color.darkened(0.10)
			disabled_color = color("desktop.frame")
			disabled_text_color = color("desktop.muted")
			radius = 4
			border_width = 2
		"buy":
			fill_color = color("buy.fill")
			border_color = color("buy.border")
			text_color = color("terminal.text")
			hover_color = fill_color.lightened(0.10)
			pressed_color = fill_color.darkened(0.08)
			radius = int(options.get("radius", 0))
		"sell":
			fill_color = color("sell.fill")
			border_color = color("sell.border")
			text_color = color("terminal.text")
			hover_color = fill_color.lightened(0.10)
			pressed_color = fill_color.darkened(0.08)
			radius = int(options.get("radius", 0))
		"window_control":
			fill_color = Color(0.164706, 0.215686, 0.278431, 1)
			border_color = color("terminal.border")
			text_color = color("terminal.text")
			hover_color = fill_color.lightened(0.10)
			pressed_color = fill_color.darkened(0.08)
			radius = 4
		"desktop_nav":
			fill_color = color("desktop.card_fill") if selected else color("desktop.panel")
			border_color = color("desktop.brown") if selected else Color(color("desktop.brown").r, color("desktop.brown").g, color("desktop.brown").b, 0.28)
			text_color = color("desktop.brown")
			hover_color = color("desktop.shortcut_hover")
			pressed_color = hover_color
			disabled_color = color("desktop.frame")
			disabled_text_color = color("desktop.muted")
			radius = 6
			border_width = 2
		"terminal_button":
			fill_color = color("terminal.nav_fill")
			border_color = color("terminal.border")
			text_color = color("terminal.text")
			hover_color = fill_color.lightened(0.08)
			pressed_color = color("terminal.nav_active_fill")
		"desktop_shortcut":
			fill_color = color("desktop.panel")
			border_color = color("desktop.shortcut_border")
			text_color = color("desktop.brown")
			hover_color = color("desktop.shortcut_hover")
			pressed_color = color("desktop.shortcut_pressed")
			disabled_color = Color(0.917647, 0.878431, 0.721569, 1)
			disabled_text_color = Color(color("desktop.brown").r, color("desktop.brown").g, color("desktop.brown").b, 0.48)
			radius = 0
			border_width = 4
			icon_color = color("desktop.brown")
		"desktop_advance":
			fill_color = color("desktop.gold")
			border_color = color("desktop.gold")
			text_color = color("desktop.text")
			hover_color = Color(1.0, 0.792157, 0.168627, 1)
			pressed_color = Color(0.862745, 0.580392, 0.0392157, 1)
			disabled_color = Color(0.937255, 0.752941, 0.211765, 1)
			disabled_text_color = color("desktop.text")
			radius = 0
			border_width = 0
			size_role = "metric"
			margins = {"left": 24, "right": 22, "top": 8, "bottom": 8}
		"desktop_icon":
			fill_color = Color(0.0156863, 0.0156863, 0.0196078, 1)
			border_color = color("terminal.border")
			text_color = color("state.transparent")
			hover_color = Color(0.0784314, 0.0941176, 0.117647, 1)
			pressed_color = Color(0.164706, 0.215686, 0.278431, 1)
			radius = 0
		"taskbar_launch":
			fill_color = Color(0.101961, 0.141176, 0.180392, 1)
			border_color = color("terminal.border")
			text_color = color("terminal.text")
			hover_color = Color(0.14902, 0.211765, 0.27451, 1)
			pressed_color = color("terminal.nav_active_fill")
			radius = 6
		"desktop_card_selectable":
			fill_color = color("desktop.green") if selected else color("desktop.cream")
			border_color = color("desktop.gold") if selected else color("desktop.frame")
			text_color = color("desktop.cream") if selected else color("desktop.text")
			hover_color = color("desktop.green").lightened(0.08) if selected else color("desktop.panel").lightened(0.04)
			pressed_color = color("desktop.green")
			disabled_color = color("desktop.frame")
			disabled_text_color = color("desktop.muted")
			radius = 4
			border_width = 2
			margins = {"left": 16, "right": 16, "top": 14, "bottom": 14}
		"custom":
			fill_color = options.get("fill", fill_color)
			border_color = options.get("border", border_color)
			text_color = options.get("font", text_color)
			hover_color = options.get("hover", fill_color.lightened(0.1))
			pressed_color = options.get("pressed", fill_color.darkened(0.08))
			disabled_color = options.get("disabled", disabled_color)
			disabled_text_color = options.get("disabled_font", disabled_text_color)
			radius = int(options.get("radius", radius))
			border_width = int(options.get("border_width", border_width))

	if options.has("margins") and typeof(options.get("margins")) == TYPE_DICTIONARY:
		margins = options.get("margins")
	if options.has("radius"):
		radius = int(options.get("radius"))
	if options.has("border_width"):
		border_width = int(options.get("border_width"))
	if options.has("font_role"):
		font_role = str(options.get("font_role"))
	if options.has("size_role"):
		size_role = str(options.get("size_role"))

	var normal := make_stylebox(fill_color, border_color, border_width, radius, margins)
	if variant == "desktop_shortcut":
		normal.shadow_color = Color(0.24, 0.22, 0.15, 0.18)
		normal.shadow_size = 0
		normal.shadow_offset = Vector2(5, 5)
	var hover := normal.duplicate()
	hover.bg_color = hover_color
	var pressed := normal.duplicate()
	pressed.bg_color = pressed_color
	if variant == "desktop_icon":
		pressed.border_color = color("terminal.accent")
		pressed.set_border_width_all(2)
	if variant == "terminal_button":
		pressed.border_color = color("terminal.nav_active_border")
		pressed.set_border_width_all(2)
	if variant == "taskbar_launch":
		pressed.border_color = color("terminal.nav_active_border")
		pressed.set_border_width_all(2)
	var disabled := normal.duplicate()
	disabled.bg_color = disabled_color
	var hover_pressed := pressed.duplicate()
	if variant == "desktop_card_selectable":
		hover_pressed.bg_color = color("desktop.green").lightened(0.08)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", pressed)
	button.add_theme_stylebox_override("hover_pressed", hover_pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)
	button.add_theme_color_override("font_hover_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", disabled_text_color)
	button.add_theme_color_override("icon_normal_color", icon_color)
	button.add_theme_color_override("icon_hover_color", icon_color)
	button.add_theme_color_override("icon_pressed_color", icon_color)
	button.add_theme_color_override("icon_focus_color", icon_color)
	button.add_theme_color_override("icon_disabled_color", disabled_text_color)
	button.add_theme_font_override("font", font(font_role))
	button.add_theme_font_size_override("font_size", font_size(size_role))


func style_tab_button(button: Button, variant: String, selected: bool, options: Dictionary = {}) -> void:
	var forwarded_options := options.duplicate()
	forwarded_options["selected"] = selected
	match variant:
		"desktop_tab":
			style_button(button, "desktop_nav", forwarded_options)
		"terminal_tab":
			if selected:
				style_button(
					button,
					"custom",
					{
						"fill": color("terminal.nav_active_fill"),
						"border": color("terminal.nav_active_border"),
						"font": color("terminal.text"),
						"radius": int(options.get("radius", 4)),
						"border_width": 2
					}
				)
			else:
				style_button(button, "terminal_button", {"radius": int(options.get("radius", 4))})
		"filter_chip":
			var fill_color := color("desktop.gold") if selected else color("desktop.cream")
			var border_color := color("desktop.brown") if selected else color("desktop.frame")
			style_button(
				button,
				"custom",
				{
					"fill": fill_color,
					"border": border_color,
					"font": color("desktop.text"),
					"hover": fill_color.lightened(0.08),
					"pressed": fill_color.darkened(0.08),
					"radius": int(options.get("radius", 4)),
					"border_width": 1,
					"size_role": "caption"
				}
			)
		_:
			style_button(button, "desktop_nav", forwarded_options)


func style_panel(panel, variant: String, options: Dictionary = {}) -> void:
	if panel == null:
		return
	var panel_style: StyleBoxFlat = null
	match variant:
		"desktop_window":
			panel_style = make_stylebox(color("desktop.panel"), color("desktop.brown"), 2, 4)
			panel_style.border_width_top = 26
			panel_style.shadow_color = color("desktop.window_shadow")
			panel_style.shadow_size = 10
			panel_style.shadow_offset = Vector2(0, 4)
		"desktop_card":
			panel_style = make_stylebox(color("desktop.cream"), color("desktop.frame"), 1, 4)
		"desktop_card_banner":
			var selected: bool = bool(options.get("selected", false))
			var banner_bg := color("desktop.brown") if selected else Color(0.917647, 0.878431, 0.721569, 1)
			var banner_border := color("desktop.brown") if selected else Color(0.788235, 0.705882, 0.552941, 1)
			panel_style = make_stylebox(banner_bg, banner_border, 1, 3)
		"dialog":
			panel_style = make_stylebox(color("dialog.bg"), color("dialog.border"), 2, 6)
		"terminal_panel":
			panel_style = make_stylebox(color("terminal.panel"), color("terminal.border"), 1, int(options.get("radius", 8)))
		"terminal_card":
			panel_style = make_stylebox(color("terminal.panel_alt"), color("terminal.border"), 1, int(options.get("radius", 4)))
		"desktop_cash":
			panel_style = make_stylebox(Color(0.956863, 0.913725, 0.780392, 1), Color(color("desktop.brown").r, color("desktop.brown").g, color("desktop.brown").b, 0.12), 1, 0)
		_:
			panel_style = make_stylebox(color("desktop.panel"), color("desktop.frame"), 1, 4)
	panel.add_theme_stylebox_override("panel", panel_style)
	if panel is AcceptDialog:
		panel.add_theme_color_override("font_color", color("desktop.text"))
		panel.add_theme_color_override("title_color", color("desktop.brown"))


func style_progress_bar(progress_bar: ProgressBar, variant: String = "desktop") -> void:
	if progress_bar == null:
		return
	var background_style := make_stylebox(color("desktop.cream"), color("desktop.brown"), 2, 4)
	var fill_style := make_stylebox(color("desktop.olive"), color("state.transparent"), 0, 3)
	if variant == "terminal":
		background_style = make_stylebox(color("terminal.panel_alt"), color("terminal.border"), 1, 3)
		fill_style = make_stylebox(color("terminal.accent"), color("state.transparent"), 0, 3)
	progress_bar.add_theme_stylebox_override("background", background_style)
	progress_bar.add_theme_stylebox_override("fill", fill_style)


func style_checkbox(checkbox: CheckBox, variant: String = "desktop") -> void:
	if checkbox == null:
		return
	var text_color := color("desktop.text") if variant == "desktop" else color("terminal.text")
	var muted_color := color("desktop.muted") if variant == "desktop" else color("terminal.muted")
	checkbox.add_theme_font_override("font", font("regular"))
	checkbox.add_theme_font_size_override("font_size", font_size("body"))
	checkbox.add_theme_color_override("font_color", text_color)
	checkbox.add_theme_color_override("font_hover_color", text_color)
	checkbox.add_theme_color_override("font_pressed_color", text_color)
	checkbox.add_theme_color_override("font_disabled_color", muted_color)


func style_item_list(list: ItemList, variant: String = "desktop") -> void:
	if list == null:
		return
	var panel_style: StyleBoxFlat
	var cursor_style: StyleBoxFlat
	var text_color: Color
	var muted_color: Color
	match variant:
		"terminal":
			panel_style = make_stylebox(color("terminal.panel_alt"), color("terminal.border"), 1, 8)
			cursor_style = make_stylebox(Color(0.239216, 0.407843, 0.572549, 0.7), color("terminal.accent"), 1, 6)
			text_color = color("terminal.text")
			muted_color = color("terminal.muted")
		"light":
			panel_style = make_stylebox(Color(0.980392, 0.976471, 0.921569, 1), Color(0.572549, 0.482353, 0.309804, 0.8), 1, 0)
			cursor_style = make_stylebox(Color(0.835294, 0.764706, 0.529412, 0.52), Color(0.52549, 0.396078, 0.160784, 1), 1, 0)
			text_color = color("desktop.text")
			muted_color = Color(0.352941, 0.309804, 0.203922, 0.82)
		_:
			panel_style = make_stylebox(color("desktop.card_fill"), color("desktop.frame"), 1, 4)
			cursor_style = make_stylebox(Color(color("desktop.gold").r, color("desktop.gold").g, color("desktop.gold").b, 0.42), color("desktop.brown"), 1, 3)
			text_color = color("desktop.text")
			muted_color = color("desktop.muted")
	list.add_theme_stylebox_override("panel", panel_style)
	list.add_theme_stylebox_override("panel_focus", panel_style)
	list.add_theme_stylebox_override("focus", panel_style)
	list.add_theme_stylebox_override("cursor", cursor_style)
	list.add_theme_stylebox_override("cursor_unfocused", cursor_style)
	list.add_theme_stylebox_override("selected", cursor_style)
	list.add_theme_stylebox_override("selected_focus", cursor_style)
	list.add_theme_color_override("font_color", text_color)
	list.add_theme_color_override("font_hovered_color", text_color)
	list.add_theme_color_override("font_selected_color", text_color)
	list.add_theme_color_override("font_hovered_selected_color", text_color)
	list.add_theme_color_override("font_disabled_color", muted_color)
	list.add_theme_color_override("guide_color", color("state.transparent"))
	list.add_theme_constant_override("h_separation", 6)
	list.add_theme_constant_override("v_separation", 6)
	list.add_theme_font_override("font", font("regular"))
	list.add_theme_font_size_override("font_size", font_size("body"))


func style_option_button(option: OptionButton, variant: String = "desktop") -> void:
	if option == null:
		return
	if variant == "terminal":
		style_button(option, "terminal_button", {"radius": 0})
	else:
		style_button(
			option,
			"custom",
			{
				"fill": Color(0.909804, 0.87451, 0.737255, 1),
				"border": Color(0.52549, 0.396078, 0.160784, 1),
				"font": color("desktop.text"),
				"radius": 0
			}
		)
	var popup: PopupMenu = option.get_popup()
	if popup == null:
		return
	var panel_style := make_stylebox(Color(0.980392, 0.976471, 0.921569, 1), Color(0.572549, 0.482353, 0.309804, 0.9), 1, 0)
	popup.add_theme_stylebox_override("panel", panel_style)
	popup.add_theme_color_override("font_color", color("desktop.text"))
	popup.add_theme_color_override("font_hover_color", color("desktop.text"))
	popup.add_theme_color_override("font_disabled_color", color("desktop.muted"))


func style_tab_container(tab_container: TabContainer, variant: String = "terminal", corner_radius: int = 6) -> void:
	if tab_container == null:
		return
	var panel_style: StyleBoxFlat
	var tab_normal: StyleBoxFlat
	var tab_selected: StyleBoxFlat
	var tab_hover: StyleBoxFlat
	if variant == "desktop":
		panel_style = make_stylebox(color("state.transparent"), color("state.transparent"), 0, 0)
		tab_normal = make_stylebox(color("desktop.cream"), color("desktop.frame"), 1, corner_radius, {"left": 12, "right": 12, "top": 6, "bottom": 6})
		tab_selected = make_stylebox(color("desktop.card_fill"), color("desktop.brown"), 2, corner_radius, {"left": 12, "right": 12, "top": 6, "bottom": 6})
		tab_hover = tab_normal.duplicate()
		tab_hover.bg_color = color("desktop.shortcut_hover")
		tab_container.add_theme_color_override("font_selected_color", color("desktop.text"))
		tab_container.add_theme_color_override("font_unselected_color", color("desktop.muted"))
		tab_container.add_theme_color_override("font_hovered_color", color("desktop.text"))
	else:
		panel_style = make_stylebox(Color(0.0588235, 0.0823529, 0.109804, 0.35), color("state.transparent"), 0, 0)
		tab_normal = make_stylebox(Color(0.0823529, 0.117647, 0.156863, 0.9), color("terminal.border"), 1, corner_radius, {"left": 12, "right": 12, "top": 6, "bottom": 6})
		tab_selected = make_stylebox(Color(0.184314, 0.247059, 0.309804, 0.98), color("terminal.accent"), 2, corner_radius, {"left": 12, "right": 12, "top": 6, "bottom": 6})
		tab_hover = tab_normal.duplicate()
		tab_hover.bg_color = Color(0.117647, 0.168627, 0.223529, 1)
		tab_container.add_theme_color_override("font_selected_color", color("terminal.text"))
		tab_container.add_theme_color_override("font_unselected_color", color("terminal.muted"))
		tab_container.add_theme_color_override("font_hovered_color", color("terminal.text"))
	tab_container.add_theme_stylebox_override("panel", panel_style)
	tab_container.add_theme_stylebox_override("tab_unselected", tab_normal)
	tab_container.add_theme_stylebox_override("tab_selected", tab_selected)
	tab_container.add_theme_stylebox_override("tab_hovered", tab_hover)
	tab_container.add_theme_font_override("font", font("semibold"))
	tab_container.add_theme_font_size_override("font_size", font_size("button"))


func _apply_font_override_to_control(control: Control, role: String) -> void:
	var app_font := font("regular")
	var resolved_font_size := font_size(role)
	control.add_theme_font_size_override("font_size", resolved_font_size)
	if app_font != null:
		control.add_theme_font_override("font", app_font)
	if control is RichTextLabel:
		var rich_text: RichTextLabel = control
		rich_text.add_theme_font_size_override("normal_font_size", resolved_font_size)
		rich_text.add_theme_font_size_override("bold_font_size", resolved_font_size)
		rich_text.add_theme_font_size_override("italics_font_size", resolved_font_size)
		rich_text.add_theme_font_size_override("mono_font_size", resolved_font_size)
		if app_font != null:
			rich_text.add_theme_font_override("normal_font", app_font)
			rich_text.add_theme_font_override("bold_font", app_font)
			rich_text.add_theme_font_override("italics_font", app_font)
			rich_text.add_theme_font_override("mono_font", app_font)


func _apply_content_margins(style: StyleBoxFlat, margins: Dictionary) -> void:
	if margins.has("left"):
		style.content_margin_left = float(margins.get("left"))
	if margins.has("top"):
		style.content_margin_top = float(margins.get("top"))
	if margins.has("right"):
		style.content_margin_right = float(margins.get("right"))
	if margins.has("bottom"):
		style.content_margin_bottom = float(margins.get("bottom"))
