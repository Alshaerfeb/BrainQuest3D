extends Node3D
# Brain Quest 3D: playable Godot 4 prototype. All geometry is procedural.
const GRID := 7
const TILE := 1.55
var walls := {}
var player := Vector2i(1, 5)
var crate := Vector2i(3, 4)
var key_pos := Vector2i(1, 1)
var switch_pos := Vector2i(5, 4)
var door_pos := Vector2i(3, 1)
var goal := Vector2i(5, 1)
var has_key := false
var switch_on := false
var moves := 0
var message_label: Label
var stats_label: Label
var board: Node3D
var hero: Node3D
var camera: Camera3D
var tween: Tween

func _ready() -> void:
	_setup_world()
	_setup_ui()
	_refresh()

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, glow := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.25
	mat.roughness = 0.4
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.2
	mesh.material_override = mat
	mesh.position = pos
	parent.add_child(mesh)
	return mesh

func _coord(p: Vector2i) -> Vector3:
	return Vector3((p.x - 3) * TILE, 0, (p.y - 3) * TILE)

func _setup_world() -> void:
	board = Node3D.new()
	add_child(board)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#101329")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#869acb")
	env.ambient_light_energy = 0.55
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 1.3
	add_child(sun)
	for y in range(GRID):
		for x in range(GRID):
			var p := Vector2i(x,y)
			var edge := x == 0 or y == 0 or x == 6 or y == 6
			var obstacle := p in [Vector2i(2,2),Vector2i(2,3),Vector2i(4,2),Vector2i(4,3),Vector2i(2,5),Vector2i(4,5)]
			var c := _coord(p)
			_box(board,c + Vector3(0,-0.23,0),Vector3(1.48,0.38,1.48),Color("#313c63"))
			if edge or obstacle:
				walls[p] = true
				_box(board,c + Vector3(0,0.52,0),Vector3(1.47,1.35,1.47),Color("#4d577c"))
	for p in [key_pos,switch_pos,goal,door_pos]:
		var color := Color("#f9d76a") if p == key_pos else Color("#ff6d92") if p == switch_pos else Color("#2fffe2") if p == goal else Color("#8c65ff")
		_box(board,_coord(p) + Vector3(0,0.025,0),Vector3(1.1,0.09,1.1),color,true)
	hero = Node3D.new()
	board.add_child(hero)
	_box(hero,Vector3(0,0.55,0),Vector3(0.55,0.7,0.5),Color("#e7edff"))
	_box(hero,Vector3(0,1.06,0),Vector3(0.72,0.55,0.58),Color("#16294d"))
	_box(hero,Vector3(-0.18,1.08,-0.31),Vector3(0.12,0.14,0.05),Color("#00eaff"),true)
	_box(hero,Vector3(0.18,1.08,-0.31),Vector3(0.12,0.14,0.05),Color("#00eaff"),true)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.position = Vector3(12, 19, 18)
	add_child(camera)
	camera.look_at(Vector3(0,0,0), Vector3.UP)
	camera.current = true
	get_viewport().size_changed.connect(_fit_camera)
	_fit_camera()

func _fit_camera() -> void:
	if camera == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	camera.size = maxf(17.0, 14.0 / maxf(aspect, 0.35))
	camera.look_at(Vector3(0, 0, 0), Vector3.UP)

func _setup_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 18
	top.offset_right = -18
	top.offset_top = 16
	ui.add_child(top)
	var heading := Label.new()
	heading.text = "BRAIN QUEST 3D / LOST TEMPLE"
	heading.add_theme_font_size_override("font_size", 22)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(heading)
	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(stats_label)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(message_label)
	var controls := GridContainer.new()
	controls.columns = 3
	controls.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	controls.offset_left = -126
	controls.offset_right = 126
	controls.offset_top = -242
	controls.offset_bottom = -18
	ui.add_child(controls)
	for entry in ["","UP","","LEFT","RESET","RIGHT","","DOWN",""]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(82,68)
		button.text = entry
		controls.add_child(button)
		button.add_theme_font_size_override("font_size", 15)
		if entry == "":
			button.visible = false
		match entry:
			"UP": button.pressed.connect(func(): _move(Vector2i(0,-1)))
			"DOWN": button.pressed.connect(func(): _move(Vector2i(0,1)))
			"LEFT": button.pressed.connect(func(): _move(Vector2i(-1,0)))
			"RIGHT": button.pressed.connect(func(): _move(Vector2i(1,0)))
			"RESET": button.pressed.connect(_reset)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"): _move(Vector2i(0,-1))
	elif event.is_action_pressed("ui_down"): _move(Vector2i(0,1))
	elif event.is_action_pressed("ui_left"): _move(Vector2i(-1,0))
	elif event.is_action_pressed("ui_right"): _move(Vector2i(1,0))

func _move(dir: Vector2i) -> void:
	var target := player + dir
	if walls.has(target):
		message_label.text = "Ancient stone blocks your path!"
		return
	if target == door_pos and not (has_key and switch_on):
		message_label.text = "Door requires the key and activated switch."
		return
	if target == crate:
		var next := crate + dir
		if walls.has(next) or next == door_pos or next == goal:
			message_label.text = "Cannot push the stone there."
			return
		crate = next
	if target.x < 1 or target.x > 5 or target.y < 1 or target.y > 5:
		return
	player = target
	moves += 1
	if player == key_pos:
		has_key = true
		message_label.text = "Golden key collected!"
	if crate == switch_pos:
		switch_on = true
		message_label.text = "Pressure switch activated!"
	if player == goal and has_key and switch_on:
		message_label.text = "TEMPLE CLEARED! ★★★"
	_refresh()

func _refresh() -> void:
	hero.position = _coord(player)
	var old := board.get_node_or_null("MovableStone")
	if old: old.queue_free()
	var stone := Node3D.new()
	stone.name = "MovableStone"
	board.add_child(stone)
	stone.position = _coord(crate)
	_box(stone,Vector3(0,0.42,0),Vector3(0.95,0.86,0.95),Color("#c38b55"))
	stats_label.text = "MOVES %d  •  KEY %s  •  SWITCH %s" % [moves,"✓" if has_key else "—","✓" if switch_on else "—"]

func _reset() -> void:
	player = Vector2i(1,5)
	crate = Vector2i(3,4)
	has_key = false
	switch_on = false
	moves = 0
	message_label.text = "Find the key. Push the stone onto the pink switch."
	_refresh()
