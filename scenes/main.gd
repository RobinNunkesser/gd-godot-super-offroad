class_name MainOffroadGame
extends Node2D

const OffroadConfig = preload("res://scripts/offroad_config.gd")
const OffroadTruck = preload("res://scripts/offroad_truck.gd")
const StadiumTrack = preload("res://scripts/stadium_track.gd")
const OffroadHUD = preload("res://scripts/hud.gd")
const OffroadSpeedShop = preload("res://scripts/speed_shop.gd")

var track: StadiumTrack
var hud: OffroadHUD
var speed_shop: OffroadSpeedShop

var trucks: Array[OffroadTruck] = []
var finish_counter: int = 0
var is_race_active: bool = false

func _ready() -> void:
	track = StadiumTrack.new()
	track.name = "StadiumTrack"
	add_child(track)
	
	hud = OffroadHUD.new()
	hud.name = "HUD"
	add_child(hud)
	
	_spawn_trucks()
	_start_race()

func _spawn_trucks() -> void:
	# 4 Trucks: P1 Human, P2 Human/AI, P3 Human/AI, P4 Ironman AI
	# Für lokale Single-Player-Sessions standardmäßig P1 Human, P2/P3/P4 AI
	# Sobald P2/P3 Tasten drücken, können sie mitfahren
	for i in range(4):
		var is_ai_driver = (i > 0) # P1 steuert menschlich, Rest AI
		var truck = OffroadTruck.new(i, is_ai_driver)
		truck.name = "Truck_%d" % i
		truck.position = StadiumTrack.SPAWN_POINTS[i]
		truck.heading_angle = 0.0 # Blickt nach rechts Richtung Kurve 1
		truck.ai_waypoints = StadiumTrack.AI_WAYPOINTS
		
		truck.lap_completed.connect(_on_truck_lap_completed)
		truck.race_finished.connect(_on_truck_race_finished)
		
		track.add_child(truck)
		trucks.append(truck)

func _start_race() -> void:
	finish_counter = 0
	is_race_active = true
	
	for i in range(trucks.size()):
		var t = trucks[i]
		t.position = StadiumTrack.SPAWN_POINTS[i % StadiumTrack.SPAWN_POINTS.size()]
		t.heading_angle = 0.0
		t.current_speed = 0.0
		t.drift_velocity = Vector2.ZERO
		t.z_height = 0.0
		t.z_velocity = 0.0
		t.current_lap = 1
		t.next_checkpoint = 0
		t.has_finished = false
		t.finish_rank = 0
		t.ai_waypoint_index = 0
		
	if hud:
		hud.show_banner("🏁 READY... GO! 🏁", 2.2, Color(0.2, 0.95, 0.3))

func _process(_delta: float) -> void:
	if hud and trucks.size() > 0:
		hud.update_trucks_info(trucks, OffroadConfig.DEFAULT_TOTAL_LAPS)

func _on_truck_lap_completed(truck: OffroadTruck, lap: int) -> void:
	if lap == OffroadConfig.DEFAULT_TOTAL_LAPS and not truck.is_ai:
		if hud:
			hud.show_banner("🏳 FINAL LAP! (WHITE FLAG) 🏳", 2.0, Color.WHITE)

func _on_truck_race_finished(truck: OffroadTruck, _rank: int) -> void:
	finish_counter += 1
	truck.finish_rank = finish_counter
	
	# Preisgeld
	var prize = 0
	match finish_counter:
		1: prize = 20000
		2: prize = 10000
		3: prize = 5000
		_: prize = 1000
	truck.cash += prize
	
	if finish_counter == 1:
		if hud:
			var banner_color = truck.truck_color
			hud.show_banner("🏆 1ST PLACE: %s! 🏆\nPrize: +$%d" % [truck.truck_name, prize], 3.0, banner_color)
			
	# Wenn P1 (oder alle) fertig sind, öffnen wir nach kurzer Pause den Speed Shop
	if truck.truck_id == 0 or finish_counter >= trucks.size():
		var timer = get_tree().create_timer(3.2)
		timer.timeout.connect(_open_speed_shop)

func _open_speed_shop() -> void:
	if speed_shop:
		speed_shop.queue_free()
		
	speed_shop = OffroadSpeedShop.new()
	speed_shop.name = "SpeedShop"
	add_child(speed_shop)
	speed_shop.setup_shop(trucks[0]) # P1 tunen
	speed_shop.next_race_requested.connect(_on_next_race_from_shop)

func _on_next_race_from_shop() -> void:
	if speed_shop:
		speed_shop.queue_free()
		speed_shop = null
	_start_race()
