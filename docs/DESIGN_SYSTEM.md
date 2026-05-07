# Gorengan Design System

Status: official v1 foundation. Code lives in `autoloads/UiTheme.gd`; docs describe how to use and extend it.

## Principles

- Extend `UiTheme` before creating one-off `StyleBoxFlat` styling in UI scripts.
- Keep dense trading surfaces readable and predictable. Use fixed UI scale presets, not continuous viewport-width font scaling.
- Use desktop components for News, Network, Academy, Thesis, Life, Company, Settings, Shop, dialogs, and the main desktop shell.
- Use terminal components for STOCKBOT, charts, trade tickets, watchlists, and dark research tools.
- Keep app-specific widgets stable unless a migration explicitly includes them.

## Color Tokens

Desktop palette:

- `desktop.bg`: main desktop background.
- `desktop.panel`: warm app/window panel fill.
- `desktop.cream`: elevated button/dialog fill.
- `desktop.text`: primary warm text.
- `desktop.muted`: secondary warm text.
- `desktop.brown`: primary desktop border/title accent.
- `desktop.gold`: primary action fill.
- `desktop.green`: selected difficulty/card highlight.
- `desktop.frame`: quiet frame border.

Terminal palette:

- `terminal.bg`: STOCKBOT and dark app background.
- `terminal.panel`: primary dark panel.
- `terminal.panel_alt`: secondary dark panel.
- `terminal.border`: default dark border.
- `terminal.text`: primary terminal text.
- `terminal.muted`: secondary terminal text.
- `terminal.accent`: active/focused terminal accent.
- `terminal.nav_fill`, `terminal.nav_active_fill`, `terminal.nav_active_border`: dark navigation states.

Semantic palette:

- `semantic.positive`: gains, valid confirmations, success.
- `semantic.negative`: losses, danger, destructive states.
- `semantic.warning`: neutral alerts and caution.
- `semantic.accent`: informational focus/accent.

## Typography

Font roles:

- `regular`: `OpenSans-Regular.ttf`
- `semibold`: `OpenSans-SemiBold.ttf`
- `bold`: `OpenSans-Bold.ttf`

Normal scale sizes:

- `caption`: 12
- `body`: 14
- `button`: 14
- `section`: 16
- `title`: 18
- `metric`: 20

Scale presets:

- `compact`: one step smaller for dense screens.
- `normal`: default, with `body` and `button` at `14`.
- `large`: larger readable UI without major layout shock.
- `accessibility`: largest supported preset for comfort.

Do not scale font size continuously from viewport width. Responsive screens should first change spacing, wrapping, visible columns, and available area. Font size changes should come from `UiTheme.set_ui_scale()`.

## Public Helpers

Core:

- `UiTheme.color(token: String) -> Color`
- `UiTheme.font(role: String = "regular") -> Font`
- `UiTheme.font_size(role: String, scale_id: String = "") -> int`
- `UiTheme.make_stylebox(bg: Color, border: Color, border_width: int = 1, radius: int = 4, margins: Dictionary = {}) -> StyleBoxFlat`

Typography:

- `UiTheme.set_ui_scale(scale_id: String) -> void`
- `UiTheme.get_ui_scale() -> String`
- `UiTheme.apply_tree_font(root: Node, role: String = "body") -> void`

Components:

- `UiTheme.style_label(label: Label, variant: String) -> void`
- `UiTheme.style_button(button: Button, variant: String, options: Dictionary = {}) -> void`
- `UiTheme.style_tab_button(button: Button, variant: String, selected: bool, options: Dictionary = {}) -> void`
- `UiTheme.style_panel(panel: Object, variant: String, options: Dictionary = {}) -> void`
- `UiTheme.style_progress_bar(progress_bar: ProgressBar, variant: String = "desktop") -> void`
- `UiTheme.style_checkbox(checkbox: CheckBox, variant: String = "desktop") -> void`
- `UiTheme.style_item_list(list: ItemList, variant: String = "desktop") -> void`
- `UiTheme.style_option_button(option: OptionButton, variant: String = "desktop") -> void`

## Components

Button variants:

- `desktop_primary`: main warm CTA, gold fill.
- `desktop_secondary`: neutral warm button.
- `desktop_danger`: destructive desktop action.
- `buy`: trading buy action.
- `sell`: trading sell action.
- `window_control`: small window buttons.
- `desktop_nav`: desktop bottom/task navigation.
- `terminal_button`: dark terminal action.
- `desktop_shortcut`: desktop icon tile.
  Disabled shortcuts must stay in the warm desktop palette with muted brown icon/text, never the dark terminal fallback.
- `desktop_advance`: Advance Day button.
- `desktop_icon`: dark icon-only app launcher.
- `taskbar_launch`: dark taskbar app button.
- `desktop_card_selectable`: selected/unselected card button, including green selected state.

Tab variants:

- `desktop_tab`: warm app tabs for desktop-style screens.
- `terminal_tab`: dark STOCKBOT-style tabs and sidebar nav.
- `filter_chip`: compact feed filters and segmented controls.

Panel/window variants:

- `desktop_window`: warm window with brown title border.
- `desktop_card`: warm card/panel.
- `desktop_card_banner`: compact title banner inside selectable desktop cards.
- `dialog`: readable confirmation/dialog panel.
- `terminal_panel`: dark app panel.
- `terminal_card`: compact dark card.
- `desktop_cash`: desktop cash/status plaque.

Label variants:

- `desktop_title`, `desktop_body`, `desktop_muted`
- `terminal_title`, `terminal_body`, `terminal_muted`
- `positive`, `negative`, `warning`, `accent`

## Migration Rules

- Main Menu, desktop chrome, taskbar controls, common buttons, desktop tabs, progress bars, checkboxes, option buttons, and item lists should use `UiTheme`.
- Specialized views such as STOCKBOT chart drawing, Twooter post layouts, Life, Thesis, RUPSLB, and deep app-specific controls may keep local styling until their own migration pass.
- New UI should not introduce a new color or component variant inline. Add it to `UiTheme`, document it here, then consume it from the feature script.
