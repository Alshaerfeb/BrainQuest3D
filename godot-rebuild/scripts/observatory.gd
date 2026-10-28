extends Node3D
# Completely new landscape puzzle adventure, independent of the previous maze.
const GOLD := Color("#f4c778")
const AQUA := Color("#51e5d6")
const STONE := Color("#786d68")
var hero: Node3D
var cam: Camera3D
var dial: Node3D
var mirror_a: Node3D
var mirror_b: Node3D
var gate: Node3D
var objective: Label
var progress: Label
var joystick := Vector2.ZERO
var destination := Vector3(-6.0, 0.0, 4.0)
var dial_steps := 0
var mirror_steps := 0
var bridge_ready := false
var weight_ready := false
var solved := false
var time := 0.0
var last_input := Vector2.ZERO
var light_segments: Array[MeshInstance3D] = []
var weight: MeshInstance3D
var gate_panel: MeshInstance3D

func _ready() -> void:
 _world()
 _interface()
 _update_state()

func _mat(color: Color, metallic: float = 0.0, luminous: bool = false) -> StandardMaterial3D:
 var m := StandardMaterial3D.new()
 m.albedo_color = color
 m.metallic = metallic
 m.roughness = 0.65
 if luminous:
  m.emission_enabled = true
  m.emission = color
  m.emission_energy_multiplier = 1.8
 return m

func _mesh(parent: Node3D, mesh: Mesh, at: Vector3, color: Color, metallic: float = 0.0, luminous: bool = false) -> MeshInstance3D:
 var n := MeshInstance3D.new()
 n.mesh = mesh
 n.position = at
 n.material_override = _mat(color, metallic, luminous)
 parent.add_child(n)
 return n

func _cube(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
 var b := BoxMesh.new()
 b.size = size
 return _mesh(parent,b,at,color)

func _cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color, luminous: bool = false) -> MeshInstance3D:
 var c := CylinderMesh.new()
 c.top_radius = radius
 c.bottom_radius = radius
 c.height = height
 c.radial_segments = 16
 return _mesh(parent,c,at,color,0.2,luminous)

func _world() -> void:
 var env_node := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("#0b182b")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("#8eabc6")
 env.ambient_light_energy = 0.85
 env_node.environment = env
 add_child(env_node)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-54,-35,0)
 sun.light_energy = 1.35
 add_child(sun)
 _add_nature_assets()
 _cylinder(self,Vector3(0,-1.0,0),10.0,1.7,Color("#3a3e54"))
 _cylinder(self,Vector3(0,-0.12,0),8.8,0.4,STONE)
 for i in range(16):
  var a := TAU*float(i)/16.0
  var p := Vector3(cos(a)*8.2,0,sin(a)*8.2)
  _cylinder(self,p+Vector3(0,0.5,0),0.36,1.25,Color("#a69578"))
  _cylinder(self,p+Vector3(0,1.25,0),0.48,0.17,GOLD)
 for i in range(8):
  var a := TAU*float(i)/8.0
  var p := Vector3(cos(a)*10.2,0,sin(a)*10.2)
  _cylinder(self,p+Vector3(0,0.8,0),0.55,2.1,Color("#716b70"))
  _cylinder(self,p+Vector3(0,2.0,0),0.7,0.28,Color("#b7a481"))
 for i in range(24):
  var a := TAU*float(i)/24.0
  var p := Vector3(cos(a)*7.0,0.13,sin(a)*7.0)
  _cube(self,p,Vector3(0.4,0.12,0.8),Color("#a58c69"))
 _cylinder(self,Vector3(0,0.1,0),3.6,0.34,Color("#b7a17c"))
 _cylinder(self,Vector3(0,0.3,0),2.5,0.11,Color("#283e51"))
 dial = Node3D.new()
 dial.position = Vector3(-4,0.25,-2.4)
 add_child(dial)
 _cylinder(dial,Vector3.ZERO,1.3,0.32,GOLD)
 for i in range(8):
  var a := TAU*float(i)/8.0
  _cube(dial,Vector3(cos(a),0.25,sin(a)),Vector3(0.28,0.16,0.28),AQUA)
 mirror_a = Node3D.new()
 mirror_a.position = Vector3(2.4,0.45,-2.4)
 add_child(mirror_a)
 _cylinder(mirror_a,Vector3.ZERO,0.65,0.8,STONE)
 _cube(mirror_a,Vector3(0,0.8,0),Vector3(1.5,1.2,0.15),AQUA)
 mirror_b = Node3D.new()
 mirror_b.position = Vector3(4.6,0.45,1.6)
 add_child(mirror_b)
 _cylinder(mirror_b,Vector3.ZERO,0.65,0.8,STONE)
 _cube(mirror_b,Vector3(0,0.8,0),Vector3(1.5,1.2,0.15),AQUA)
 _cylinder(self,Vector3(-3,0.18,3.3),0.9,0.25,Color("#b15e80"),true)
 weight = _cube(self,Vector3(-5.0,0.45,4.0),Vector3(1.0,0.9,1.0),Color("#bd9462"))
 gate = Node3D.new()
 gate.position = Vector3(0,0,-7.2)
 add_child(gate)
 _cube(gate,Vector3(-1.4,1.8,0),Vector3(0.6,3.8,0.9),STONE)
 _cube(gate,Vector3(1.4,1.8,0),Vector3(0.6,3.8,0.9),STONE)
 _cube(gate,Vector3(0,3.7,0),Vector3(3.5,0.6,1.0),GOLD)
 gate_panel = _cube(gate,Vector3(0,1.65,0),Vector3(2.3,3.1,0.35),Color("#31656c"))
 hero = Node3D.new()
 hero.position = destination
 add_child(hero)
 _cylinder(hero,Vector3(0,0.55,0),0.32,0.65,Color("#e3e5df"))
 _cube(hero,Vector3(0,1.13,0),Vector3(0.75,0.57,0.58),Color("#edf3ec"))
 _cube(hero,Vector3(0,1.15,-0.32),Vector3(0.54,0.28,0.04),Color("#173746"))
 for x in [-0.15,0.15]:
  _cube(hero,Vector3(x,1.16,-0.35),Vector3(0.09,0.12,0.05),AQUA)
 _cylinder(hero,Vector3(0,1.5,0),0.1,0.18,GOLD)
 cam = Camera3D.new()
 cam.projection = Camera3D.PROJECTION_ORTHOGONAL
 cam.size = 23.0
 cam.position = Vector3(15,22,23)
 add_child(cam)
 cam.look_at(Vector3(0,0,0))
 cam.current = true
 get_viewport().size_changed.connect(_fit_camera)
 _fit_camera()

func _add_nature_assets() -> void:
 var names := ["tree_oak", "tree_pine", "rock_large"]
 for i in range(12):
  var path := "res://assets/nature/%s.glb" % names[i % names.size()]
  if not ResourceLoader.exists(path):
   continue
  var scene := load(path) as PackedScene
  if scene == null:
   continue
  var instance := scene.instantiate() as Node3D
  if instance == null:
   continue
  var a := TAU * float(i) / 12.0
  instance.position = Vector3(cos(a)*12.8,-0.2,sin(a)*12.8)
  instance.scale = Vector3.ONE * (1.4 if i % 3 != 2 else 1.8)
  add_child(instance)

func _fit_camera() -> void:
 if cam == null:
  return
 var s := get_viewport().get_visible_rect().size
 var aspect := s.x/maxf(s.y,1.0)
 cam.size = maxf(23.0,20.0/maxf(aspect,0.6))

func _interface() -> void:
 var layer := CanvasLayer.new()
 add_child(layer)
 var root := Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 layer.add_child(root)
 var title := Label.new()
 title.text = "BRAIN QUEST  |  THE SUNKEN OBSERVATORY"
 title.add_theme_font_size_override("font_size",26)
 title.set_anchors_preset(Control.PRESET_TOP_WIDE)
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 title.offset_top = 14
 root.add_child(title)
 progress = Label.new()
 progress.set_anchors_preset(Control.PRESET_TOP_WIDE)
 progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 progress.offset_top = 54
 progress.add_theme_font_size_override("font_size",19)
 root.add_child(progress)
 objective = Label.new()
 objective.set_anchors_preset(Control.PRESET_TOP_WIDE)
 objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 objective.offset_top = 86
 objective.add_theme_font_size_override("font_size",18)
 root.add_child(objective)
 var buttons := HBoxContainer.new()
 buttons.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
 buttons.offset_left = 22
 buttons.offset_right = -22
 buttons.offset_top = -95
 buttons.offset_bottom = -16
 buttons.add_theme_constant_override("separation",12)
 root.add_child(buttons)
 for action in ["◀","▲","▼","▶","DIAL","MIRROR","WEIGHT","RESET"]:
  var b := Button.new()
  b.text = action
  b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  b.custom_minimum_size = Vector2(75,72)
  b.add_theme_font_size_override("font_size",18)
  buttons.add_child(b)
  match action:
   "◀": b.pressed.connect(func(): _step(Vector3(-0.6,0,0)))
   "▶": b.pressed.connect(func(): _step(Vector3(0.6,0,0)))
   "▲": b.pressed.connect(func(): _step(Vector3(0,0,-0.6)))
   "▼": b.pressed.connect(func(): _step(Vector3(0,0,0.6)))
   "DIAL": b.pressed.connect(_turn_dial)
   "MIRROR": b.pressed.connect(_turn_mirror)
   "WEIGHT": b.pressed.connect(_place_weight)
   "RESET": b.pressed.connect(_reset)

func _step(dir: Vector3) -> void:
 if solved:
  return
 var target := destination + dir
 if target.length() < 7.3:
  destination = target

func _turn_dial() -> void:
 if hero.position.distance_to(dial.position) > 5.5:
  objective.text = "Move Pip closer to the golden dial."
  return
 dial_steps = (dial_steps+1)%4
 dial.rotation.y = float(dial_steps)*PI/2.0
 _update_state()

func _turn_mirror() -> void:
 if dial_steps != 2:
  objective.text = "Align the golden dial first (two turns)."
  return
 if hero.position.distance_to(mirror_a.position) > 6.0:
  objective.text = "Move Pip near the first mirror."
  return
 mirror_steps += 1
 mirror_a.rotation.y = float(mirror_steps)*PI/4.0
 mirror_b.rotation.y = float(mirror_steps)*PI/3.0
 bridge_ready = mirror_steps >= 2
 _update_state()

func _place_weight() -> void:
 if not bridge_ready:
  objective.text = "Redirect the light with the mirrors first."
  return
 if hero.position.distance_to(Vector3(-3,0,3.3)) > 4.2:
  objective.text = "Move Pip near the pink pressure plate."
  return
 weight_ready = true
 solved = true
 weight.position = Vector3(-3,0.6,3.3)
 _update_state()

func _update_state() -> void:
 progress.text = "DIAL %s   •   LIGHT %s   •   GATE %s" % ["✓" if dial_steps==2 else "○","✓" if bridge_ready else "○","✓" if weight_ready else "○"]
 if solved:
  objective.text = "OBSERVATORY CLEARED! ✦ YOU RESTORED THE LIGHT ✦"
  gate_panel.position.y = 5.2
 elif dial_steps != 2:
  objective.text = "Puzzle 1: Rotate the golden dial until the runes align."
 elif not bridge_ready:
  objective.text = "Puzzle 2: Turn the mirrors to redirect the turquoise light."
 else:
  objective.text = "Puzzle 3: Move Pip to the pink plate and place the weight."

func _reset() -> void:
 destination = Vector3(-6,0,4)
 dial_steps = 0
 mirror_steps = 0
 bridge_ready = false
 weight_ready = false
 solved = false
 dial.rotation.y = 0
 mirror_a.rotation.y = 0
 mirror_b.rotation.y = 0
 gate_panel.position.y = 1.65
 weight.position = Vector3(-5,0.45,4)
 _update_state()

func _process(delta: float) -> void:
 time += delta
 if hero:
  hero.position = hero.position.lerp(destination,minf(delta*8.0,1.0))
  hero.rotation.y = sin(time*2.5)*0.04
