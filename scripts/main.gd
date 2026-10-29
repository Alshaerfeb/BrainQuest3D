extends Node3D
# Large scrolling maze: 25x25 cells, smooth held-button movement and camera tracking.
const GRID := 25
const TILE := 1.6
const SPEED := 4.0
const START := Vector2i(1, 1)
const GOAL := Vector2i(23, 23)
var walls := {}
var player_position := Vector2(1.0, 1.0)
var input_direction := Vector2.ZERO
var hero: Node3D
var camera: Camera3D
var stats_label: Label
var message_label: Label
var steps := 0
var finished := false
var start_time := 0
var last_tile := START
var glow_goal: MeshInstance3D

func _ready() -> void:
 _generate_maze()
 _world()
 _ui()
 start_time = Time.get_ticks_msec()
 _update_labels()

func _mat(color: Color, glow := false) -> StandardMaterial3D:
 var m := StandardMaterial3D.new()
 m.albedo_color = color
 m.roughness = 0.78
 if glow:
  m.emission_enabled = true
  m.emission = color
  m.emission_energy_multiplier = 1.8
 return m

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, glow := false) -> MeshInstance3D:
 var n := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = size
 n.mesh = mesh
 n.position = pos
 n.material_override = _mat(color, glow)
 parent.add_child(n)
 return n

func _coord(x: float, y: float) -> Vector3:
 return Vector3((x - 12.0) * TILE, 0.0, (y - 12.0) * TILE)

func _generate_maze() -> void:
 # Seeded depth-first backtracker guarantees a path from start to finish.
 var rng := RandomNumberGenerator.new()
 rng.seed = 20261029
 for y in range(GRID):
  for x in range(GRID):
   walls[Vector2i(x,y)] = true
 var stack: Array[Vector2i] = [START]
 walls.erase(START)
 while not stack.is_empty():
  var current: Vector2i = stack.back()
  var options: Array[Vector2i] = []
  for d in [Vector2i(2,0), Vector2i(-2,0), Vector2i(0,2), Vector2i(0,-2)]:
   var next: Vector2i = current + d
   if next.x > 0 and next.x < GRID-1 and next.y > 0 and next.y < GRID-1 and walls.has(next):
    options.append(next)
  if options.is_empty():
   stack.pop_back()
  else:
   var next: Vector2i = options[rng.randi_range(0,options.size()-1)]
   walls.erase(current + (next-current)/2)
   walls.erase(next)
   stack.append(next)
 # Extra passages make exploration less linear.
 for i in range(28):
  var x := rng.randi_range(1,GRID-2)
  var y := rng.randi_range(1,GRID-2)
  var p := Vector2i(x,y)
  if walls.has(p) and ((x+y)%2 == 1):
   walls.erase(p)

func _world() -> void:
 var world := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("#0b1427")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("#b0c9dd")
 env.ambient_light_energy = 0.8
 world.environment = env
 add_child(world)
 var light := DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-55,-35,0)
 light.light_energy = 1.4
 add_child(light)
 var board := Node3D.new()
 add_child(board)
 for y in range(GRID):
  for x in range(GRID):
   var p := Vector2i(x,y)
   var pos := _coord(float(x),float(y))
   _box(board,pos + Vector3(0,-0.16,0),Vector3(TILE+0.015,0.30,TILE+0.015),Color("#25344c") if (x+y)%2==0 else Color("#2b3c56"))
   if walls.has(p):
    _box(board,pos + Vector3(0,0.62,0),Vector3(TILE-0.06,1.35,TILE-0.06),Color("#52617d") if (x+y)%3==0 else Color("#455572"))
 _box(board,_coord(1,1)+Vector3(0,0.025,0),Vector3(1.25,0.08,1.25),Color("#4de3c3"),true)
 glow_goal = _box(board,_coord(23,23)+Vector3(0,0.035,0),Vector3(1.25,0.09,1.25),Color("#f6c65b"),true)
 hero = Node3D.new()
 hero.position = _coord(player_position.x,player_position.y)
 add_child(hero)
 _box(hero,Vector3(0,0.46,0),Vector3(0.6,0.72,0.58),Color("#d9e9f5"))
 _box(hero,Vector3(0,0.99,0),Vector3(0.77,0.53,0.64),Color("#243955"))
 _box(hero,Vector3(-0.18,1.03,-0.34),Vector3(0.12,0.13,0.04),Color("#54fff0"),true)
 _box(hero,Vector3(0.18,1.03,-0.34),Vector3(0.12,0.13,0.04),Color("#54fff0"),true)
 camera = Camera3D.new()
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.size = 17.5
 camera.position = hero.position + Vector3(11,17,14)
 add_child(camera)
 camera.current = true
 camera.look_at(hero.position,Vector3.UP)
 get_viewport().size_changed.connect(_fit_camera)
 _fit_camera()

func _fit_camera() -> void:
 if camera == null: return
 var size := get_viewport().get_visible_rect().size
 var aspect := size.x / maxf(size.y,1.0)
 camera.size = maxf(15.5,12.0/maxf(aspect,0.4))

func _ui() -> void:
 var layer := CanvasLayer.new()
 add_child(layer)
 var root := Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 layer.add_child(root)
 var top := VBoxContainer.new()
 top.set_anchors_preset(Control.PRESET_TOP_WIDE)
 top.offset_left = 10
 top.offset_right = -10
 top.offset_top = 12
 root.add_child(top)
 var title := Label.new()
 title.text = "BRAIN QUEST 3D  |  EXPEDITION MAZE"
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 title.add_theme_font_size_override("font_size",21)
 top.add_child(title)
 stats_label = Label.new()
 stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 top.add_child(stats_label)
 message_label = Label.new()
 message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 top.add_child(message_label)
 var controls := GridContainer.new()
 controls.columns = 3
 controls.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
 controls.offset_left = -120
 controls.offset_right = 120
 controls.offset_top = -222
 controls.offset_bottom = -10
 root.add_child(controls)
 for label in ["","UP","","LEFT","RESET","RIGHT","","DOWN",""]:
  var button := Button.new()
  button.text = label
  button.custom_minimum_size = Vector2(78,65)
  button.add_theme_font_size_override("font_size",16)
  controls.add_child(button)
  if label == "":
   button.mouse_filter = Control.MOUSE_FILTER_IGNORE
   button.modulate.a = 0.0
  elif label == "RESET":
   button.pressed.connect(_reset)
  else:
   var d := Vector2.ZERO
   match label:
    "UP": d = Vector2(0,-1)
    "DOWN": d = Vector2(0,1)
    "LEFT": d = Vector2(-1,0)
    "RIGHT": d = Vector2(1,0)
   button.button_down.connect(_press.bind(d))
   button.button_up.connect(_release.bind(d))
 message_label.text = "Explore the maze. Find the golden exit!"

func _press(dir: Vector2) -> void:
 input_direction = dir

func _release(dir: Vector2) -> void:
 if input_direction == dir:
  input_direction = Vector2.ZERO

func _unhandled_key_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_up"): input_direction = Vector2(0,-1)
 elif event.is_action_pressed("ui_down"): input_direction = Vector2(0,1)
 elif event.is_action_pressed("ui_left"): input_direction = Vector2(-1,0)
 elif event.is_action_pressed("ui_right"): input_direction = Vector2(1,0)
 elif not event.pressed:
  input_direction = Vector2.ZERO

func _walkable(pos: Vector2) -> bool:
 var p := Vector2i(int(round(pos.x)),int(round(pos.y)))
 return p.x >= 1 and p.x < GRID-1 and p.y >= 1 and p.y < GRID-1 and not walls.has(p)

func _physics_process(delta: float) -> void:
 if not finished and input_direction != Vector2.ZERO:
  var desired := player_position + input_direction * SPEED * delta
  var margin := 0.30
  var tx := desired.x
  var ty := desired.y
  if _walkable(Vector2(tx + signf(input_direction.x)*margin,player_position.y)):
   player_position.x = tx
  if _walkable(Vector2(player_position.x,ty + signf(input_direction.y)*margin)):
   player_position.y = ty
  var tile := Vector2i(int(round(player_position.x)),int(round(player_position.y)))
  if tile != last_tile:
   steps += 1
   last_tile = tile
   _update_labels()
  if tile == GOAL:
   finished = true
   input_direction = Vector2.ZERO
   message_label.text = "MAZE COMPLETED!  Tap RESET to explore again."
 hero.position = hero.position.lerp(_coord(player_position.x,player_position.y),minf(delta*14.0,1.0))
 if input_direction != Vector2.ZERO:
  hero.rotation.y = lerp_angle(hero.rotation.y,atan2(input_direction.x,input_direction.y),minf(delta*10.0,1.0))
 var camera_target := hero.position + Vector3(11,17,14)
 camera.position = camera.position.lerp(camera_target,minf(delta*4.0,1.0))
 camera.look_at(hero.position,Vector3.UP)

func _update_labels() -> void:
 stats_label.text = "25 × 25 MAZE  •  STEPS %d  •  EXIT: GOLD" % steps

func _reset() -> void:
 player_position = Vector2(1,1)
 last_tile = START
 steps = 0
 finished = false
 input_direction = Vector2.ZERO
 hero.position = _coord(1,1)
 camera.position = hero.position + Vector3(11,17,14)
 message_label.text = "Explore the maze. Find the golden exit!"
 _update_labels()
