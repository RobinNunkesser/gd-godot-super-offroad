class_name StadiumTrack
extends Node2D

const OffroadPickup = preload("res://scripts/pickup.gd")
const OffroadTruck = preload("res://scripts/offroad_truck.gd")

# Spawnpunkte für 4 Trucks nebeneinander auf der Startgeraden (unten)
const SPAWN_POINTS: Array[Vector2] = [
	Vector2(480, 560), # P1 (Red)
	Vector2(530, 560), # P2 (Blue)
	Vector2(480, 600), # P3 (Yellow)
	Vector2(530, 600)  # P4 (Ironman)
]

# AI-Wegpunkte im Uhrzeigersinn um die Arena
const AI_WAYPOINTS: Array[Vector2] = [
	Vector2(640, 580),  # Startgerade
	Vector2(880, 580),  # Anfahrt Kurve 1
	Vector2(1060, 520), # Kurve 1 außen
	Vector2(1080, 360), # Scheitelpunkt Ost
	Vector2(1040, 200), # Ausgang Kurve 1
	Vector2(880, 140),  # Gegengerade Nord
	Vector2(640, 140),  # Gegengerade Mitte (über die Schanze)
	Vector2(400, 140),  # Anfahrt Kurve 2
	Vector2(220, 200),  # Kurve 2 Einlenken
	Vector2(180, 360),  # Scheitelpunkt West
	Vector2(240, 520),  # Ausgang Kurve 2
	Vector2(400, 580)   # Zurück auf die Zielgerade
]

var pickup_container: Node2D
var pickup_spawn_timer: float = 0.0

func _ready() -> void:
	_build_visuals()
	_build_collision_walls()
	_build_surface_zones()
	_build_checkpoints()
	
	pickup_container = Node2D.new()
	pickup_container.name = "Pickups"
	add_child(pickup_container)
	
	# Initiale Pickups auf der Strecke
	spawn_pickup(Vector2(950, 480), OffroadPickup.PickupType.CASH)
	spawn_pickup(Vector2(640, 100), OffroadPickup.PickupType.NITRO)
	spawn_pickup(Vector2(300, 260), OffroadPickup.PickupType.CASH)

func _process(delta: float) -> void:
	pickup_spawn_timer += delta
	if pickup_spawn_timer >= 6.0:
		pickup_spawn_timer = 0.0
		_spawn_random_pickup()

func _spawn_random_pickup() -> void:
	if pickup_container.get_child_count() >= 5:
		return
	var rand_pts = [
		Vector2(750, 560), Vector2(1020, 320),
		Vector2(520, 150), Vector2(250, 420),
		Vector2(880, 220), Vector2(360, 560)
	]
	var pos = rand_pts[randi() % rand_pts.size()]
	var type = OffroadPickup.PickupType.CASH if randf() < 0.65 else OffroadPickup.PickupType.NITRO
	spawn_pickup(pos, type)

func spawn_pickup(pos: Vector2, type: OffroadPickup.PickupType) -> OffroadPickup:
	var item = OffroadPickup.new(type)
	item.position = pos
	pickup_container.add_child(item)
	return item

func _build_visuals() -> void:
	# 1. Stadion-Tribüne / Hintergrund
	var arena_bg = Polygon2D.new()
	arena_bg.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)
	])
	arena_bg.color = Color(0.22, 0.20, 0.25) # Tribünen-Dunkelgrau
	add_child(arena_bg)
	
	# Tribünen-Ränge (Dekorative Streifen für Publikum)
	for i in range(4):
		var crowd = Polygon2D.new()
		var y_off = i * 16.0
		crowd.polygon = PackedVector2Array([
			Vector2(40, 10 + y_off), Vector2(1240, 10 + y_off),
			Vector2(1240, 22 + y_off), Vector2(40, 22 + y_off)
		])
		crowd.color = Color(0.35 + (i * 0.08), 0.25, 0.35)
		add_child(crowd)
		
	# 2. Dirt Track Oval (Spielfläche)
	var track_poly = Polygon2D.new()
	track_poly.polygon = PackedVector2Array([
		Vector2(120, 80), Vector2(1160, 80),
		Vector2(1200, 140), Vector2(1200, 580),
		Vector2(1160, 640), Vector2(120, 640),
		Vector2(80, 580), Vector2(80, 140)
	])
	track_poly.color = Color(0.58, 0.42, 0.28) # Erdiger Lehm-Ton
	add_child(track_poly)
	
	# 3. Inneninsel (Grünfläche / Tribüne in der Mitte)
	var infield_poly = Polygon2D.new()
	infield_poly.polygon = PackedVector2Array([
		Vector2(320, 240), Vector2(960, 240),
		Vector2(980, 280), Vector2(980, 440),
		Vector2(960, 480), Vector2(320, 480),
		Vector2(300, 440), Vector2(300, 280)
	])
	infield_poly.color = Color(0.22, 0.48, 0.24) # Grasgrün
	add_child(infield_poly)
	
	# 4. Schlamm-Zone (Südost-Kurve)
	var mud_vis = Polygon2D.new()
	mud_vis.polygon = PackedVector2Array([
		Vector2(960, 480), Vector2(1180, 500),
		Vector2(1160, 620), Vector2(900, 620)
	])
	mud_vis.color = Color(0.36, 0.24, 0.14) # Dunkler Schlamm
	add_child(mud_vis)
	
	# 5. Wasser-Pfütze (Nordwest-Kurve)
	var water_vis = Polygon2D.new()
	water_vis.polygon = PackedVector2Array([
		Vector2(140, 180), Vector2(260, 150),
		Vector2(290, 240), Vector2(180, 270)
	])
	water_vis.color = Color(0.25, 0.55, 0.75, 0.85) # Reflektierendes Wasser
	add_child(water_vis)
	
	# 6. Sprungschanze (Nordgerade bei x=640, y=140)
	var ramp_vis = Polygon2D.new()
	ramp_vis.polygon = PackedVector2Array([
		Vector2(700, 90), Vector2(760, 90),
		Vector2(780, 190), Vector2(680, 190)
	])
	ramp_vis.color = Color(0.72, 0.55, 0.35) # Erhöhte Erdrampe
	add_child(ramp_vis)
	
	# Rampen-Pfeile
	var ramp_label = Label.new()
	ramp_label.position = Vector2(700, 125)
	ramp_label.text = "▲ JUMP ▲"
	ramp_label.add_theme_font_size_override("font_size", 13)
	ramp_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	add_child(ramp_label)
	
	# 7. Start- & Ziellinie (Schachbrettmuster bei x=600, y=480..640)
	for row in range(8):
		for col in range(2):
			var tile = Polygon2D.new()
			tile.polygon = PackedVector2Array([
				Vector2(600 + col * 12, 480 + row * 20),
				Vector2(612 + col * 12, 480 + row * 20),
				Vector2(612 + col * 12, 500 + row * 20),
				Vector2(600 + col * 12, 500 + row * 20)
			])
			var is_white = (row + col) % 2 == 0
			tile.color = Color.WHITE if is_white else Color.BLACK
			add_child(tile)

func _build_collision_walls() -> void:
	var walls = StaticBody2D.new()
	walls.name = "TrackWalls"
	walls.collision_layer = OffroadConfig.COLLISION_LAYER_WORLD
	walls.collision_mask = 0
	
	# Außenwände (4 Boxen)
	_add_wall_box(walls, Vector2(640, 70), Vector2(1200, 20)) # Nord
	_add_wall_box(walls, Vector2(640, 650), Vector2(1200, 20)) # Süd
	_add_wall_box(walls, Vector2(70, 360), Vector2(20, 580)) # West
	_add_wall_box(walls, Vector2(1210, 360), Vector2(20, 580)) # Ost
	
	# Inneninsel-Wand (Mitte)
	_add_wall_box(walls, Vector2(640, 230), Vector2(680, 20)) # Infield Nord
	_add_wall_box(walls, Vector2(640, 490), Vector2(680, 20)) # Infield Süd
	_add_wall_box(walls, Vector2(290, 360), Vector2(20, 240)) # Infield West
	_add_wall_box(walls, Vector2(990, 360), Vector2(20, 240)) # Infield Ost
	
	add_child(walls)

func _add_wall_box(parent: Node2D, pos: Vector2, size: Vector2) -> void:
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	col.position = pos
	parent.add_child(col)

func _build_surface_zones() -> void:
	# Schlamm Zone Area
	var mud_area = Area2D.new()
	mud_area.collision_layer = 0
	mud_area.collision_mask = OffroadConfig.COLLISION_LAYER_TRUCKS
	var mud_col = CollisionShape2D.new()
	var mud_rect = RectangleShape2D.new()
	mud_rect.size = Vector2(240, 130)
	mud_col.shape = mud_rect
	mud_col.position = Vector2(1040, 560)
	mud_area.add_child(mud_col)
	mud_area.body_entered.connect(func(b): if b is OffroadTruck: b.current_surface = OffroadConfig.SurfaceType.MUD)
	mud_area.body_exited.connect(func(b): if b is OffroadTruck and b.current_surface == OffroadConfig.SurfaceType.MUD: b.current_surface = OffroadConfig.SurfaceType.DIRT)
	add_child(mud_area)
	
	# Wasser Zone Area
	var water_area = Area2D.new()
	water_area.collision_layer = 0
	water_area.collision_mask = OffroadConfig.COLLISION_LAYER_TRUCKS
	var water_col = CollisionShape2D.new()
	var water_rect = RectangleShape2D.new()
	water_rect.size = Vector2(140, 120)
	water_col.shape = water_rect
	water_col.position = Vector2(210, 210)
	water_area.add_child(water_col)
	water_area.body_entered.connect(func(b): if b is OffroadTruck: b.current_surface = OffroadConfig.SurfaceType.WATER)
	water_area.body_exited.connect(func(b): if b is OffroadTruck and b.current_surface == OffroadConfig.SurfaceType.WATER: b.current_surface = OffroadConfig.SurfaceType.DIRT)
	add_child(water_area)
	
	# Schanze (Ramp) Area
	var ramp_area = Area2D.new()
	ramp_area.collision_layer = 0
	ramp_area.collision_mask = OffroadConfig.COLLISION_LAYER_TRUCKS
	var ramp_col = CollisionShape2D.new()
	var ramp_rect = RectangleShape2D.new()
	ramp_rect.size = Vector2(70, 100)
	ramp_col.shape = ramp_rect
	ramp_col.position = Vector2(730, 140)
	ramp_area.add_child(ramp_col)
	ramp_area.body_entered.connect(func(b): if b is OffroadTruck: b.launch_ramp())
	add_child(ramp_area)

func _build_checkpoints() -> void:
	# 4 Checkpoints im Uhrzeigersinn:
	# CP 0: Start / Finish Line (unten, x=605, y=560)
	# CP 1: Ost-Kurve (rechts, x=1090, y=360)
	# CP 2: Nord-Gerade (oben, x=640, y=140)
	# CP 3: West-Kurve (links, x=190, y=360)
	var cp_configs = [
		{"pos": Vector2(605, 560), "size": Vector2(20, 160)},
		{"pos": Vector2(1090, 360), "size": Vector2(200, 20)},
		{"pos": Vector2(640, 140), "size": Vector2(20, 140)},
		{"pos": Vector2(190, 360), "size": Vector2(200, 20)}
	]
	
	for i in range(cp_configs.size()):
		var cfg = cp_configs[i]
		var cp = Area2D.new()
		cp.collision_layer = OffroadConfig.COLLISION_LAYER_CHECKPOINTS
		cp.collision_mask = OffroadConfig.COLLISION_LAYER_TRUCKS
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = cfg["size"]
		shape.shape = rect
		shape.position = cfg["pos"]
		cp.add_child(shape)
		
		var cp_idx = i
		cp.body_entered.connect(func(b):
			if b is OffroadTruck:
				b.trigger_checkpoint(cp_idx)
		)
		add_child(cp)
