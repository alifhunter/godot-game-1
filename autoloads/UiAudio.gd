extends Node

const CLICK_SOUND_PATH := "res://assets/sound/ElevenLabs_Button_press_sound_of_a_gaming_mouse,_high_precision.mp3"
const CLICK_PLAYER_COUNT := 4
const CLICK_VOLUME_DB := -8.0

var click_players: Array[AudioStreamPlayer] = []
var next_click_player_index: int = 0
var click_sound: AudioStreamMP3 = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	click_sound = _load_click_sound()
	_build_click_players()
	get_tree().node_added.connect(_on_node_added)
	_connect_buttons_recursive(get_tree().root)


func play_click() -> void:
	if click_players.is_empty():
		return
	var player: AudioStreamPlayer = click_players[next_click_player_index]
	next_click_player_index = (next_click_player_index + 1) % click_players.size()
	player.stop()
	player.play()


func _build_click_players() -> void:
	if click_sound == null:
		return
	for player_index in range(CLICK_PLAYER_COUNT):
		var player := AudioStreamPlayer.new()
		player.name = "UiClickPlayer%d" % player_index
		player.stream = click_sound
		player.volume_db = CLICK_VOLUME_DB
		add_child(player)
		click_players.append(player)


func _load_click_sound() -> AudioStreamMP3:
	if not FileAccess.file_exists(CLICK_SOUND_PATH):
		push_warning("UI click sound missing: %s" % CLICK_SOUND_PATH)
		return null
	var file_bytes: PackedByteArray = FileAccess.get_file_as_bytes(CLICK_SOUND_PATH)
	if file_bytes.is_empty():
		push_warning("UI click sound is empty: %s" % CLICK_SOUND_PATH)
		return null
	var stream := AudioStreamMP3.new()
	stream.data = file_bytes
	return stream


func _on_node_added(node: Node) -> void:
	_connect_click_sources(node)


func _connect_buttons_recursive(node: Node) -> void:
	_connect_click_sources(node)
	for child in node.get_children():
		_connect_buttons_recursive(child)


func _connect_click_sources(node: Node) -> void:
	_connect_button(node)
	_connect_item_list(node)
	_connect_option_button(node)


func _connect_button(node: Node) -> void:
	if not (node is BaseButton):
		return
	var button: BaseButton = node
	var callable := Callable(self, "_on_button_pressed")
	if not button.pressed.is_connected(callable):
		button.pressed.connect(callable)


func _connect_item_list(node: Node) -> void:
	if not (node is ItemList):
		return
	var item_list: ItemList = node
	var callable := Callable(self, "_on_indexed_click_source_activated")
	if not item_list.item_selected.is_connected(callable):
		item_list.item_selected.connect(callable)
	if not item_list.item_activated.is_connected(callable):
		item_list.item_activated.connect(callable)


func _connect_option_button(node: Node) -> void:
	if not (node is OptionButton):
		return
	var option_button: OptionButton = node
	var callable := Callable(self, "_on_indexed_click_source_activated")
	if not option_button.item_selected.is_connected(callable):
		option_button.item_selected.connect(callable)


func _on_button_pressed() -> void:
	play_click()


func _on_indexed_click_source_activated(_index: int) -> void:
	play_click()
