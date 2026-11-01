extends GodotTestRunner

# Headless integration test suite using Italbytz/godot-test-harness

const OffroadConfig = preload("res://scripts/offroad_config.gd")
const OffroadTruck = preload("res://scripts/offroad_truck.gd")
const OffroadPickup = preload("res://scripts/pickup.gd")
const StadiumTrack = preload("res://scripts/stadium_track.gd")
const OffroadHUD = preload("res://scripts/hud.gd")
const OffroadSpeedShop = preload("res://scripts/speed_shop.gd")
const MainOffroadGame = preload("res://scenes/main.gd")

func _init() -> void:
	start("Super Off Road Gameplay & Italbytz Shared Modules Test Suite")
	
	run_suite("OffroadConfig Parameters", _test_config)
	run_suite("MultiplayerInput Integration", _test_multiplayer_input)
	run_suite("Truck Kinematics & Drift", _test_truck_kinematics)
	run_suite("Nitro Boost System", _test_nitro_boost)
	run_suite("Ramp Jump & Z-Elevation Landing", _test_jump_and_landing)
	run_suite("Surfaces (Mud drag & Water)", _test_surfaces)
	run_suite("Dynamic Pickups (Cash & Nitro)", _test_pickups)
	run_suite("Checkpoint Order & Lap Progression", _test_checkpoints_and_laps)
	run_suite("Speed Shop Upgrade Economics", _test_speed_shop)
	run_suite("Main Game Orchestration & 4 Trucks", _test_full_game_orchestration)
	
	finish()

func _test_config() -> void:
	assert_gt(OffroadConfig.BASE_ACCEL, 0.0, "Base accel must be positive")
	assert_gt(OffroadConfig.BASE_MAX_SPEED, 0.0, "Max speed must be positive")
	assert_gt(OffroadConfig.BASE_TIRE_GRIP, 0.0, "Tire grip must be positive")
	assert_lt(OffroadConfig.BASE_TIRE_GRIP, 1.0, "Tire grip must be normalized (< 1.0)")
	assert_eq(OffroadConfig.STARTING_NITROS, 3, "Should start with 3 nitros")
	assert_eq(OffroadConfig.TRUCK_COLORS.size(), 4, "Must have 4 truck colors")

func _test_multiplayer_input() -> void:
	var mp_input = root.get_node_or_null("MultiplayerInput")
	if not mp_input:
		var script = load("res://packages/godot-multiplayer-input/addons/multiplayer_input/multiplayer_input_manager.gd")
		assert_not_null(script, "MultiplayerInputManager script loads successfully")
		mp_input = script.new()
		root.add_child(mp_input)
		mp_input._ready()
	
	assert_not_null(mp_input, "MultiplayerInput manager active in root tree")
	assert_true(mp_input.has_method("get_move_vector"), "MultiplayerInput has get_move_vector")
	assert_true(mp_input.has_method("is_action_pressed"), "MultiplayerInput has is_action_pressed")
	var slot0 = mp_input.get_slot(0)
	assert_not_null(slot0, "Slot 0 is allocated")
	if slot0:
		assert_true(slot0.device_type != PlayerInputSlot.DeviceType.NONE, "Slot 0 has valid device assignment")
	var vec = mp_input.get_move_vector(0)
	assert_vector_approx_eq(vec, Vector2.ZERO, 0.001, "Initial move vector is Vector2.ZERO")

func _test_truck_kinematics() -> void:
	var truck = OffroadTruck.new(0, false)
	root.add_child(truck)
	truck._ready()
	
	assert_eq(truck.truck_id, 0, "Truck ID mismatch")
	assert_true(truck.truck_name.begins_with("PLAYER 1"), "Truck 1 name mismatch")
	assert_approx_eq(truck.current_speed, 0.0, 0.001, "Truck should start stopped")
	
	# Simulate acceleration
	truck.current_speed = 200.0
	truck.heading_angle = PI / 2.0
	truck._update_visual_transforms()
	assert_approx_eq(truck.visual_body.rotation, PI / 2.0, 0.001, "Visual rotation must match heading")
	
	truck.queue_free()

func _test_nitro_boost() -> void:
	var truck = OffroadTruck.new(0, false)
	root.add_child(truck)
	truck._ready()
	
	var initial_nitros = truck.nitros_remaining
	assert_eq(initial_nitros, 3, "Must start with 3 nitros")
	
	var activated = truck.activate_nitro()
	assert_true(activated, "Nitro should activate successfully")
	assert_true(truck.nitro_active, "Nitro must be active")
	assert_eq(truck.nitros_remaining, initial_nitros - 1, "Nitro count must decrease by 1")
	assert_gt(truck.current_speed, 200.0, "Speed must boost on nitro")
	
	# Cannot double activate while already firing
	assert_false(truck.activate_nitro(), "Cannot activate nitro while already boosting")
	
	# Simulate timer expiration
	truck._process_nitro(2.0)
	assert_false(truck.nitro_active, "Nitro should deactivate after duration")
	
	truck.queue_free()

func _test_jump_and_landing() -> void:
	var truck = OffroadTruck.new(0, false)
	root.add_child(truck)
	truck._ready()
	truck.current_speed = 300.0
	
	# Ramp Launch
	truck.launch_ramp(350.0)
	assert_approx_eq(truck.z_velocity, 350.0, 0.001, "Z-velocity must be set by ramp")
	assert_gt(truck.z_height, 0.0, "Z-height must be above ground")
	
	# Simulate air physics
	truck._process_elevation(0.1)
	assert_gt(truck.z_height, 10.0, "Truck should rise in air")
	assert_lt(truck.z_velocity, 350.0, "Gravity must pull Z-velocity down")
	
	# Simulate flight until landing (approx 0.8s)
	for i in range(20):
		truck._process_elevation(0.05)
	assert_approx_eq(truck.z_height, 0.0, 0.001, "Truck must land on ground")
	assert_approx_eq(truck.z_velocity, 0.0, 0.001, "Z-velocity should zero on landing")
	assert_gt(truck.current_speed, 0.0, "Truck should retain momentum on landing")
	
	truck.queue_free()

func _test_surfaces() -> void:
	var truck = OffroadTruck.new(0, false)
	root.add_child(truck)
	truck._ready()
	
	assert_eq(truck.current_surface, OffroadConfig.SurfaceType.DIRT, "Default surface must be DIRT")
	
	# Mud
	truck.current_surface = OffroadConfig.SurfaceType.MUD
	assert_eq(truck.current_surface, OffroadConfig.SurfaceType.MUD, "Should switch to MUD")
	
	# Water
	truck.current_surface = OffroadConfig.SurfaceType.WATER
	assert_eq(truck.current_surface, OffroadConfig.SurfaceType.WATER, "Should switch to WATER")
	
	truck.queue_free()

func _test_pickups() -> void:
	var truck = OffroadTruck.new(0, false)
	root.add_child(truck)
	truck._ready()
	
	var initial_cash = truck.cash
	var initial_nitros = truck.nitros_remaining
	
	# Cash Pickup
	truck.collect_pickup(OffroadPickup.PickupType.CASH)
	assert_eq(truck.cash, initial_cash + 10000, "Cash should increase by $10,000")
	
	# Nitro Pickup
	truck.collect_pickup(OffroadPickup.PickupType.NITRO)
	assert_eq(truck.nitros_remaining, initial_nitros + 1, "Nitro count should increase by 1")
	
	truck.queue_free()

func _test_checkpoints_and_laps() -> void:
	var truck = OffroadTruck.new(0, false)
	root.add_child(truck)
	truck._ready()
	
	assert_eq(truck.current_lap, 1, "Must start on lap 1")
	assert_eq(truck.next_checkpoint, 0, "First checkpoint should be 0 (Finish line)")
	
	# Passing wrong checkpoint should do nothing
	truck.trigger_checkpoint(2)
	assert_eq(truck.current_lap, 1, "Skipping checkpoints must not advance lap")
	assert_eq(truck.next_checkpoint, 0, "Next checkpoint should remain 0")
	
	# Correct sequence: 0 -> 1 -> 2 -> 3 -> 0 (Lap 2!)
	truck.trigger_checkpoint(0)
	assert_eq(truck.current_lap, 2, "Crossing CP 0 increments lap")
	assert_eq(truck.next_checkpoint, 1, "Next checkpoint should be 1")
	
	truck.trigger_checkpoint(1)
	assert_eq(truck.next_checkpoint, 2, "Next checkpoint should be 2")
	truck.trigger_checkpoint(2)
	assert_eq(truck.next_checkpoint, 3, "Next checkpoint should be 3")
	truck.trigger_checkpoint(3)
	assert_eq(truck.next_checkpoint, 0, "Next checkpoint should cycle to 0")
	
	truck.queue_free()

func _test_speed_shop() -> void:
	var truck = OffroadTruck.new(0, false)
	root.add_child(truck)
	truck._ready()
	truck.cash = 25000
	
	var shop = OffroadSpeedShop.new()
	root.add_child(shop)
	shop._ready()
	shop.setup_shop(truck)
	
	# Buy Shocks upgrade ($10,000)
	shop._buy_upgrade("shocks", OffroadConfig.UPGRADE_PRICE)
	assert_eq(truck.cash, 15000, "Cash should be deducted by $10,000")
	assert_eq(truck.upgrades["shocks"], 2, "Shocks should now be level 2")
	
	# Buy Nitro ($5,000)
	var old_nitros = truck.nitros_remaining
	shop._buy_upgrade("nitro", OffroadConfig.NITRO_PRICE)
	assert_eq(truck.cash, 10000, "Cash should be deducted by $5,000")
	assert_eq(truck.nitros_remaining, old_nitros + 1, "Nitros should increase")
	
	# Fail buy with insufficient cash
	truck.cash = 2000
	shop._buy_upgrade("top_speed", OffroadConfig.UPGRADE_PRICE)
	assert_eq(truck.upgrades["top_speed"], 1, "Upgrade must not succeed with insufficient cash")
	assert_eq(truck.cash, 2000, "Cash must remain unchanged on failed purchase")
	
	shop.queue_free()
	truck.queue_free()

func _test_full_game_orchestration() -> void:
	var game = MainOffroadGame.new()
	root.add_child(game)
	game._ready()
	
	assert_not_null(game.track, "StadiumTrack must be instantiated")
	assert_not_null(game.hud, "HUD must be instantiated")
	assert_eq(game.trucks.size(), 4, "Must have 4 trucks on the grid")
	assert_true(game.is_race_active, "Race must start active")
	
	# Verify Player 4 is The Ironman AI
	assert_true(game.trucks[3].is_ai, "Player 4 must be AI")
	assert_eq(game.trucks[3].truck_name, "THE IRONMAN", "Player 4 must be The Ironman")
	
	game.queue_free()
