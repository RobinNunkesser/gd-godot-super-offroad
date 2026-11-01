class_name OffroadTruck
extends CharacterBody2D

signal lap_completed(truck: OffroadTruck, lap: int)
signal race_finished(truck: OffroadTruck, rank: int)

@export var truck_id: int = 0
@export var is_ai: bool = false

var truck_color: Color = Color.RED
var truck_name: String = "TRUCK"

# Vehicle Kinematics
var heading_angle: float = 0.0 # Bogenmaß (0 = nach rechts)
var current_speed: float = 0.0
var drift_velocity: Vector2 = Vector2.ZERO

# Z-Elevation Jump Physics
var z_height: float = 0.0
var z_velocity: float = 0.0

# Surface State
var current_surface: OffroadConfig.SurfaceType = OffroadConfig.SurfaceType.DIRT

# Nitro State
var nitro_active: bool = false
var nitro_timer: float = 0.0
var nitros_remaining: int = OffroadConfig.STARTING_NITROS

# Cash & Upgrades
var cash: int = 15000
var upgrades: Dictionary = {
	"shocks": 1,
	"tires": 1,
	"accel": 1,
	"top_speed": 1
}

# Race Progress
var current_lap: int = 1
var next_checkpoint: int = 0
var has_finished: bool = false
var finish_rank: int = 0

# Visual Nodes
var shadow_node: Polygon2D
var visual_body: Node2D
var chassis_poly: Polygon2D
var nitro_flames: CPUParticles2D
var dirt_spray: CPUParticles2D

# AI Navigation
var ai_waypoints: Array[Vector2] = []
var ai_waypoint_index: int = 0

func _init(id: int = 0, ai: bool = false) -> void:
	truck_id = id
	is_ai = ai
	if truck_id >= 0 and truck_id < OffroadConfig.TRUCK_COLORS.size():
		truck_color = OffroadConfig.TRUCK_COLORS[truck_id]
		truck_name = OffroadConfig.TRUCK_NAMES[truck_id]

func _ready() -> void:
	collision_layer = OffroadConfig.COLLISION_LAYER_TRUCKS
	collision_mask = OffroadConfig.COLLISION_LAYER_WORLD | OffroadConfig.COLLISION_LAYER_TRUCKS
	
	# Collider
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(36, 22)
	col.shape = rect
	add_child(col)
	
	_setup_visuals()

func _setup_visuals() -> void:
	# 1. Shadow Node (bleibt auf dem Boden)
	shadow_node = Polygon2D.new()
	var shadow_pts = PackedVector2Array()
	var segments = 12
	for i in range(segments):
		var a = (float(i) / float(segments)) * TAU
		shadow_pts.append(Vector2(cos(a) * 20.0, sin(a) * 12.0))
	shadow_node.polygon = shadow_pts
	shadow_node.color = Color(0.0, 0.0, 0.0, 0.35)
	add_child(shadow_node)
	
	# 2. Visual Body (hebt bei Sprüngen ab)
	visual_body = Node2D.new()
	add_child(visual_body)
	
	# 4 Räder (Tires)
	var tire_color = Color(0.12, 0.12, 0.14)
	var wheel_offsets = [
		Vector2(11, -12), Vector2(-11, -12),
		Vector2(11, 12), Vector2(-11, 12)
	]
	for off in wheel_offsets:
		var wheel = Polygon2D.new()
		wheel.polygon = PackedVector2Array([
			Vector2(-5, -3), Vector2(5, -3), Vector2(5, 3), Vector2(-5, 3)
		])
		wheel.position = off
		wheel.color = tire_color
		visual_body.add_child(wheel)
		
		# Felge
		var rim = Polygon2D.new()
		rim.polygon = PackedVector2Array([
			Vector2(-2, -1.5), Vector2(2, -1.5), Vector2(2, 1.5), Vector2(-2, 1.5)
		])
		rim.position = off
		rim.color = Color(0.7, 0.7, 0.75)
		visual_body.add_child(rim)
	
	# Karosserie / Chassis
	chassis_poly = Polygon2D.new()
	chassis_poly.polygon = PackedVector2Array([
		Vector2(-16, -10), Vector2(12, -10), Vector2(17, -7),
		Vector2(17, 7), Vector2(12, 10), Vector2(-16, 10)
	])
	chassis_poly.color = truck_color
	visual_body.add_child(chassis_poly)
	
	# Windschutzscheibe & Dach
	var roof_poly = Polygon2D.new()
	roof_poly.polygon = PackedVector2Array([
		Vector2(-4, -7), Vector2(7, -6), Vector2(7, 6), Vector2(-4, 7)
	])
	roof_poly.color = Color(0.15, 0.2, 0.28)
	visual_body.add_child(roof_poly)
	
	# Ladefläche Überrollbügel
	var rollbar = Polygon2D.new()
	rollbar.polygon = PackedVector2Array([
		Vector2(-12, -8), Vector2(-8, -8), Vector2(-8, 8), Vector2(-12, 8)
	])
	rollbar.color = Color(0.85, 0.85, 0.9)
	visual_body.add_child(rollbar)
	
	# Dirt Spray Particles
	dirt_spray = CPUParticles2D.new()
	dirt_spray.position = Vector2(-16, 0)
	dirt_spray.emitting = false
	dirt_spray.amount = 12
	dirt_spray.lifetime = 0.4
	dirt_spray.spread = 45.0
	dirt_spray.gravity = Vector2.ZERO
	dirt_spray.initial_velocity_min = 40.0
	dirt_spray.initial_velocity_max = 80.0
	dirt_spray.color = Color(0.45, 0.32, 0.18, 0.8) # Lehmbraun
	dirt_spray.scale_amount_min = 2.0
	dirt_spray.scale_amount_max = 4.0
	visual_body.add_child(dirt_spray)
	
	# Nitro Flame Particles
	nitro_flames = CPUParticles2D.new()
	nitro_flames.position = Vector2(-18, 0)
	nitro_flames.emitting = false
	nitro_flames.amount = 20
	nitro_flames.lifetime = 0.25
	nitro_flames.spread = 15.0
	nitro_flames.gravity = Vector2.ZERO
	nitro_flames.initial_velocity_min = 120.0
	nitro_flames.initial_velocity_max = 200.0
	nitro_flames.color = Color(1.0, 0.4, 0.1, 0.9)
	nitro_flames.scale_amount_min = 3.0
	nitro_flames.scale_amount_max = 6.0
	visual_body.add_child(nitro_flames)

func _physics_process(delta: float) -> void:
	if has_finished:
		# Ausrollen nach Zieldurchfahrt
		current_speed = move_toward(current_speed, 0.0, 150.0 * delta)
		drift_velocity = drift_velocity.move_toward(Vector2.ZERO, 300.0 * delta)
		velocity = Vector2.from_angle(heading_angle) * current_speed + drift_velocity
		move_and_slide()
		_update_visual_transforms()
		return
		
	_process_nitro(delta)
	_process_elevation(delta)
	
	var input_steer = 0.0
	var input_gas = 0.0
	var input_brake = 0.0
	var trigger_nitro = false
	
	if is_ai:
		var ai_in = _calculate_ai_inputs()
		input_steer = ai_in.steer
		input_gas = ai_in.gas
		trigger_nitro = ai_in.nitro
	else:
		input_steer = _read_steer_input()
		input_gas = _read_gas_input()
		input_brake = _read_brake_input()
		trigger_nitro = _read_nitro_input()
		
	if trigger_nitro:
		activate_nitro()
		
	# Lenkung nur wenn Bodenkontakt
	if z_height <= 0.0:
		var steer_mult = 1.0
		# Rückwärts lenken umkehren
		if current_speed < -10.0:
			steer_mult = -1.0
		var steer_rate = OffroadConfig.BASE_STEER_SPEED * steer_mult
		heading_angle += input_steer * steer_rate * delta
		heading_angle = wrapf(heading_angle, -PI, PI)
		
	# Antrieb & Bremsen
	var max_spd = get_max_speed()
	var accel_rate = get_accel_rate()
	
	# Oberflächen-Effekte
	match current_surface:
		OffroadConfig.SurfaceType.MUD:
			max_spd *= 0.55
			accel_rate *= 0.6
		OffroadConfig.SurfaceType.WATER:
			max_spd *= 0.85
			accel_rate *= 0.4
	
	if nitro_active:
		max_spd = OffroadConfig.NITRO_BOOST_SPEED
		accel_rate = OffroadConfig.NITRO_ACCEL_BOOST
		
	if z_height <= 0.0:
		if input_gas > 0.0:
			current_speed = move_toward(current_speed, max_spd, accel_rate * delta)
		elif input_brake > 0.0:
			current_speed = move_toward(current_speed, -OffroadConfig.BASE_REVERSE_SPEED, OffroadConfig.BASE_BRAKE_FORCE * delta)
		else:
			# Rollwiderstand / Ausrollen
			var drag = 160.0
			if current_surface == OffroadConfig.SurfaceType.MUD:
				drag = 380.0
			current_speed = move_toward(current_speed, 0.0, drag * delta)
	
	# Drift-Berechnung (Schlupfwinkel)
	var forward_dir = Vector2.from_angle(heading_angle)
	var grip = get_tire_grip()
	if current_surface == OffroadConfig.SurfaceType.WATER:
		grip = 0.18 # Aquaplaning
	elif current_surface == OffroadConfig.SurfaceType.MUD:
		grip *= 0.7
		
	# Drift-Dämpfung
	drift_velocity = drift_velocity.move_toward(Vector2.ZERO, grip * 600.0 * delta)
	
	# Wenn wir lenken, entsteht Querschlupf
	if abs(input_steer) > 0.1 and abs(current_speed) > 50.0:
		var lateral_impulse = forward_dir.orthogonal() * (-input_steer * current_speed * (1.0 - grip) * 0.45)
		drift_velocity += lateral_impulse * delta
		if dirt_spray and z_height <= 0.0:
			dirt_spray.emitting = true
	else:
		if dirt_spray:
			dirt_spray.emitting = false
			
	velocity = forward_dir * current_speed + drift_velocity
	move_and_slide()
	
	_update_visual_transforms()

func _process_nitro(delta: float) -> void:
	if nitro_active:
		nitro_timer -= delta
		if nitro_timer <= 0.0:
			nitro_active = false
			if nitro_flames:
				nitro_flames.emitting = false

func _process_elevation(delta: float) -> void:
	if z_height > 0.0 or z_velocity != 0.0:
		z_height += z_velocity * delta
		z_velocity -= OffroadConfig.GRAVITY_Z * delta
		
		if z_height <= 0.0:
			# Landung auf dem Boden
			z_height = 0.0
			var landing_shock = get_shocks_absorption()
			# Je schwächer die Shocks, desto mehr Speedverlust bei der Landung
			current_speed *= landing_shock
			z_velocity = 0.0

func _update_visual_transforms() -> void:
	# Drehung
	visual_body.rotation = heading_angle
	shadow_node.rotation = heading_angle
	
	# Elevation (Z-Sprung)
	visual_body.position.y = -z_height
	var scale_factor = 1.0 + (z_height * 0.0018)
	visual_body.scale = Vector2.ONE * scale_factor
	
	# Schatten wächst und wandert ab
	shadow_node.position = Vector2(0, z_height * 0.3)
	shadow_node.scale = Vector2.ONE * max(0.6, 1.0 - (z_height * 0.002))

func activate_nitro() -> bool:
	if nitros_remaining > 0 and not nitro_active:
		nitros_remaining -= 1
		nitro_active = true
		nitro_timer = OffroadConfig.NITRO_DURATION
		current_speed = max(current_speed + 180.0, OffroadConfig.NITRO_BOOST_SPEED * 0.8)
		if nitro_flames:
			nitro_flames.emitting = true
		return true
	return false

func launch_ramp(force: float = OffroadConfig.RAMP_LAUNCH_VEL_Z) -> void:
	if z_height <= 5.0:
		z_velocity = force
		z_height = 5.0

func collect_pickup(type: OffroadPickup.PickupType) -> void:
	if type == OffroadPickup.PickupType.CASH:
		cash += 10000
	elif type == OffroadPickup.PickupType.NITRO:
		nitros_remaining += 1

func trigger_checkpoint(cp_index: int) -> void:
	if cp_index == next_checkpoint:
		next_checkpoint = (next_checkpoint + 1) % 4
		if cp_index == 0:
			# Start / Finish Line überquert
			current_lap += 1
			lap_completed.emit(self, current_lap)
			if current_lap > OffroadConfig.DEFAULT_TOTAL_LAPS:
				has_finished = true
				race_finished.emit(self, finish_rank)

# Upgrade Query Helpers
func get_accel_rate() -> float:
	var lvl = upgrades.get("accel", 1)
	return OffroadConfig.BASE_ACCEL + (lvl - 1) * 45.0

func get_max_speed() -> float:
	var lvl = upgrades.get("top_speed", 1)
	return OffroadConfig.BASE_MAX_SPEED + (lvl - 1) * 30.0

func get_tire_grip() -> float:
	var lvl = upgrades.get("tires", 1)
	return min(0.96, OffroadConfig.BASE_TIRE_GRIP + (lvl - 1) * 0.025)

func get_shocks_absorption() -> float:
	var lvl = upgrades.get("shocks", 1)
	# Level 1 = 0.75, Level 5 = 0.98 (fast kein Speedverlust)
	return 0.70 + (lvl * 0.06)

# Input Readers (Human Players via MultiplayerInput Addon with InputMap Fallback)
func _read_steer_input() -> float:
	var mi = get_node_or_null("/root/MultiplayerInput")
	if mi:
		var move = mi.get_move_vector(truck_id)
		if abs(move.x) > 0.05:
			return move.x
	var prefix = "p%d_" % (truck_id + 1)
	var left = Input.get_action_strength(prefix + "steer_left")
	var right = Input.get_action_strength(prefix + "steer_right")
	return right - left

func _read_gas_input() -> float:
	var mi = get_node_or_null("/root/MultiplayerInput")
	if mi:
		var move = mi.get_move_vector(truck_id)
		if move.y < -0.1:
			return -move.y
		if mi.is_action_pressed(truck_id, "gas") or mi.is_action_pressed(truck_id, "primary"):
			return 1.0
	var prefix = "p%d_" % (truck_id + 1)
	return Input.get_action_strength(prefix + "gas")

func _read_brake_input() -> float:
	var mi = get_node_or_null("/root/MultiplayerInput")
	if mi:
		var move = mi.get_move_vector(truck_id)
		if move.y > 0.1:
			return move.y
		if mi.is_action_pressed(truck_id, "brake") or mi.is_action_pressed(truck_id, "tertiary"):
			return 1.0
	var prefix = "p%d_" % (truck_id + 1)
	return Input.get_action_strength(prefix + "brake")

func _read_nitro_input() -> bool:
	var mi = get_node_or_null("/root/MultiplayerInput")
	if mi:
		if mi.is_action_just_pressed(truck_id, "nitro") or mi.is_action_just_pressed(truck_id, "secondary"):
			return true
	var prefix = "p%d_" % (truck_id + 1)
	return Input.is_action_just_pressed(prefix + "nitro")

# AI Waypoint Tracking
func _calculate_ai_inputs() -> Dictionary:
	if ai_waypoints.is_empty():
		return {"steer": 0.0, "gas": 1.0, "nitro": false}
		
	var target = ai_waypoints[ai_waypoint_index]
	var dist = global_position.distance_to(target)
	if dist < 60.0:
		ai_waypoint_index = (ai_waypoint_index + 1) % ai_waypoints.size()
		target = ai_waypoints[ai_waypoint_index]
		
	var target_angle = (target - global_position).angle()
	var angle_diff = wrapf(target_angle - heading_angle, -PI, PI)
	
	var steer = clamp(angle_diff * 2.2, -1.0, 1.0)
	var gas = 1.0
	if abs(angle_diff) > 1.0:
		gas = 0.65 # In engen Haarnadelkurven leicht vom Gas gehen
		
	# Nitro auf geraden Streckenabschnitten zünden
	var nitro = false
	if abs(angle_diff) < 0.2 and dist > 200.0 and nitros_remaining > 0 and randf() < 0.015:
		nitro = true
		
	return {"steer": steer, "gas": gas, "nitro": nitro}
