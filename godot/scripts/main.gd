extends Node3D
## Brain Quest 3D — native Godot 4 prototype. No external assets required.

const MAPS := [
	["#########", "#S..#...#", "#.#.#.#G#", "#.#...#D#", "#...#...#", "###.#.#.#", "#K..#...#", "#...P...#", "#########"],
	["#########", "#S..#..G#", "#.#.#.###", "#...#...#", "###.###D#", "#K..P...#", "#.#.###.#", "#.......#", "#########"],
	["#########", "#S....#G#", "###.#.#D#", "#...#...#", "#.#####.#", "#...K...#", "#.###.#.#", "#P......#", "#########"]
]
const CELL := 2.0
var level := 0
var map_data: Array[String] = []
var pos := Vector2i.ZERO
var start_pos := Vector2i.ZERO
var has_key := false
var switch_on := false
var moves := 0
var player: MeshInstance3D
var world: Node3D
var camera: Camera3D
var status: Label
var heading: Label
var move_label: Label
var language_ar := false
var busy := false

func _ready() -> void:
	_build_lights()
	_build_ui()
	_load_level()

func _build_lights() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_energy = 1.6
	add_child(light)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#10142c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8694cd")
	env.ambient_light_energy = 0.8
	environment.environment = env
	add_child(environment)
	camera = Camera3D.new()
	camera.position = Vector3(0, 23, 19)
	camera.rotation_degrees = Vector3(-51, 0, 0)
	camera.current = true
	add_child(camera)

func _material(color: Color, emission := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = 0.25
	m.roughness = 0.35
	if emission:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.6
	return m

func _cube(at: Vector3, size: Vector3, color: Color, glow := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _material(color, glow)
	node.position = at
	world.add_child(node)
	return node

func _sphere(at: Vector3, radius: float, color: Color, glow := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	node.mesh = mesh
	node.material_override = _material(color, glow)
	node.position = at
	world.add_child(node)
	return node

func _point(cell: Vector2i) -> Vector3:
	return Vector3((cell.x - 4) * CELL, 0, (cell.y - 4) * CELL)

func _load_level() -> void:
	if is_instance_valid(world):
		world.queue_free()
	world = Node3D.new()
	add_child(world)
	map_data.clear()
	for line in MAPS[level % MAPS.size()]:
		map_data.append(line)
	has_key = false
	switch_on = false
	moves = 0
	for y in range(map_data.size()):
		for x in range(map_data[y].length()):
			var cell := Vector2i(x, y)
			var tile := map_data[y][x]
			var p := _point(cell)
			if tile == "#":
				_cube(p + Vector3(0, 0.8, 0), Vector3(1.9, 1.6, 1.9), Color("#29375d"))
				continue
			_cube(p + Vector3(0, -0.15, 0), Vector3(1.85, 0.25, 1.85), Color("#36476d"))
			match tile:
				"S":
					pos = cell
					start_pos = cell
				"K":
					_sphere(p + Vector3(0, 0.55, 0), 0.38, Color("#ffd36a"), true)
				"P":
					_cube(p + Vector3(0, 0.12, 0), Vector3(1.3, 0.16, 1.3), Color("#4be0d1"), true)
				"D":
					_cube(p + Vector3(0, 0.8, 0), Vector3(1.5, 1.6, 0.3), Color("#e46c91"), true)
				"G":
					_sphere(p + Vector3(0, 0.8, 0), 0.7, Color("#a97aff"), true)
	player = _sphere(_point(pos) + Vector3(0, 0.65, 0), 0.58, Color("#69e7ff"), true)
	_update_ui()

func _tile(cell: Vector2i) -> String:
	if cell.y < 0 or cell.y >= map_data.size():
		return "#"
	if cell.x < 0 or cell.x >= map_data[cell.y].length():
		return "#"
	return map_data[cell.y][cell.x]

func _replace_tile(cell: Vector2i, value: String) -> void:
	var line := map_data[cell.y]
	map_data[cell.y] = line.substr(0, cell.x) + value + line.substr(cell.x + 1)

func _move(dx: int, dy: int) -> void:
	if busy:
		return
	var next := pos + Vector2i(dx, dy)
	var tile := _tile(next)
	if tile == "#":
		_set_status("Wall blocked!" if not language_ar else "جدار يسد الطريق!")
		return
	if tile == "D" and not (has_key and switch_on):
		_set_status("Find the key AND activate the switch!" if not language_ar else "اجمع المفتاح وفعّل المفتاح الأرضي!")
		return
	pos = next
	moves += 1
	busy = true
	var tween := create_tween()
	tween.tween_property(player, "position", _point(pos) + Vector3(0, 0.65, 0), 0.16)
	tween.finished.connect(func(): busy = false)
	match tile:
		"K":
			has_key = true
			_replace_tile(pos, ".")
			_set_status("Key collected!" if not language_ar else "حصلت على المفتاح!")
		"P":
			switch_on = true
			_set_status("Switch activated! Door unlocked if you have the key." if not language_ar else "تم تفعيل المفتاح الأرضي!")
		"G":
			if has_key and switch_on:
				level += 1
				_set_status("Level cleared!" if not language_ar else "نجحت في المرحلة!")
				await get_tree().create_timer(0.55).timeout
				_load_level()
				return
			else:
				_set_status("Portal needs key + switch!" if not language_ar else "البوابة تحتاج المفتاح وتفعيل الزر!")
	_update_ui()

func _set_status(message: String) -> void:
	status.text = message

func _make_button(text_value: String, action: Callable, parent: Control, minimum := Vector2(94, 76)) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = minimum
	button.add_theme_font_size_override("font_size", 27)
	parent.add_child(button)
	button.pressed.connect(action)
	return button

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 20
	top.offset_right = -20
	top.offset_top = 34
	root.add_child(top)
	heading = Label.new()
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 38)
	top.add_child(heading)
	move_label = Label.new()
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.add_theme_font_size_override("font_size", 23)
	top.add_child(move_label)
	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 80
	status.add_theme_font_size_override("font_size", 22)
	top.add_child(status)
	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.offset_left = -165
	bottom.offset_right = 165
	bottom.offset_top = -280
	bottom.offset_bottom = -24
	bottom.add_theme_constant_override("separation", 5)
	root.add_child(bottom)
	var up := HBoxContainer.new()
	up.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_child(up)
	_make_button("↑", func(): _move(0, -1), up)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_child(row)
	_make_button("←", func(): _move(-1, 0), row)
	_make_button("↓", func(): _move(0, 1), row)
	_make_button("→", func(): _move(1, 0), row)
	var tools := HBoxContainer.new()
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_child(tools)
	_make_button("↻", func(): _load_level(), tools, Vector2(85, 55))
	_make_button("AR / EN", func(): language_ar = not language_ar; _update_ui(), tools, Vector2(140, 55))
	_make_button("?", func(): _set_status("Collect gold key, step on cyan switch, reach purple portal." if not language_ar else "اجمع المفتاح الذهبي ثم فعّل الزر السماوي وادخل البوابة."), tools, Vector2(85, 55))

func _update_ui() -> void:
	heading.text = ("المهمة " if language_ar else "BRAIN QUEST 3D  •  LEVEL ") + str(level + 1)
	move_label.text = ("الخطوات: " if language_ar else "Moves: ") + str(moves) + ("  |  مفتاح: " if language_ar else "  |  Key: ") + ("✓" if has_key else "—") + ("  |  زر: " if language_ar else "  |  Switch: ") + ("✓" if switch_on else "—")
	if status.text.is_empty():
		_set_status("Find the key, activate the switch, reach the portal!" if not language_ar else "اجمع المفتاح وفعّل الزر وادخل البوابة!")

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_UP, KEY_W: _move(0, -1)
		KEY_DOWN, KEY_S: _move(0, 1)
		KEY_LEFT, KEY_A: _move(-1, 0)
		KEY_RIGHT, KEY_D: _move(1, 0)
