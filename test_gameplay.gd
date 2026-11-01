extends SceneTree

const OffroadConfig = preload("res://scripts/offroad_config.gd")
const OffroadTruck = preload("res://scripts/offroad_truck.gd")
const OffroadPickup = preload("res://scripts/pickup.gd")
const StadiumTrack = preload("res://scripts/stadium_track.gd")
const OffroadHUD = preload("res://scripts/hud.gd")
const OffroadSpeedShop = preload("res://scripts/speed_shop.gd")
const MainOffroadGame = preload("res://scenes/main.gd")

func _init() -> void:
	print("\n--- Running Headless Godot 4 Unit & Gameplay Tests for Super Off Road ---")
	var success = true
	success = success and _test_config()
	success = success and _test_truck_kinematics()
	success = success and _test_nitro_boost()
	success = success and _test_jump_and_landing()
	success = success and _test_surfaces()
	success = success and _test_pickups()
	success = success and _test_checkpoints_and_laps()
	success = success and _test_speed_shop()
	success = success and _test_full_game_orchestration()
	
	if success:
		print("=== ALL 9 TEST SUITES FOR SUPER OFF ROAD PASSED SUCCESSFULLY! ===")
		quit(0)
	else:
		printerr("=== TESTS FAILED ===")
		quit(1)

func _test_config() -> bool:
	print("[1/9] Testing OffroadConfig parameters...")
	assert(OffroadConfig.BASE_ACCEL > 0.0, "Base accel must be positive")
	assert(OffroadConfig.BASE_MAX_SPEED > 0.0, "Max speed must be positive")
	assert(OffroadConfig.BASE_TIRE_GRIP > 0.0 and OffroadConfig.BASE_TIRE_GRIP < 1.0, "Tire grip must be normalized")
	assert(OffroadConfig.STARTING_NITROS == 3, "Should start with 3 nitros")
	assert(OffroadConfig.TRUCK_COLORS.size() == 4, "Must have 4 truck colors")
	print("  -> OffroadConfig OK.")
	return true

func _test_truck_kinematics() -> bool:
	print("[2/9] Testing Truck Kinematics & Drift...")
	var truck = OffroadTruck.new(0, false)
	root.add_child(truck)
	truck._ready()
	
	assert(truck.truck_id == 0, "Truck ID mismatch")
	assert(truck.truck_name.begins_with("PLAYER 1"), "Truck 1 name mismatch")
	assert(truck.current_speed == 0.0, "Truck should start stopped")
	
	# Simulate acceleration
	truck.current_speed = 200.0
	truck.heading_angle = PI / 2.0 # 90 Grad nach unten
	truck._update_visual_transforms()
	assert(is_equal_approx(truck.visual_body.rotation, PI / 2.0), "Visual rotation must match heading")
	
	truck.queue_free()
	print("  -> Truck Kinematics OK.")
	return true

func _test_nitro_boost() -> bool:
	print("[3/9] Testing Nitro Turbo Boost System...")
	var truck = OffroadTruck.new(0, false)
	root.add_child(truck)
	truck._ready()
	
	var initial_nitros = truck.nitros_remaining
	assert(initial_nitros == 3, "Must start with 3 nitros")
	
	var activated = truck.activate_nitro()
	assert(activated, "Nitro should activate successfully")
	assert(truck.nitro_active, "Nitro must be active")
	assert(truck.nitros_remaining == initial_nitros - 1, "Nitro count must decrease by 1")
	assert(truck.current_speed > 200.0, "Speed must boost on nitro")
	
	# Cannot double activate while already firing
	assert(not truck.activate_nitro(), "Cannot activate nitro while already boosting")
	
	# Simulate timer expiration
	truck._process_nitro(2.0)
	assert(not truck.nitro_active, "Nitro should deactivate after duration")
	
	truck.queue_free()
	print("  -> Nitro Boost OK.")
	return true

func _test_jump_and_landing() -> bool:
	print("[4/9] Testing Ramp Jump & Z-Elevation Landing...")
	var truck = OffroadTruck.new(0, false)
	root.add_child(truck)
	truck._ready()
	truck.current_speed = 300.0
	
	# Ramp Launch
	truck.launch_ramp(350.0)
	assert(truck.z_velocity == 350.0, "Z-velocity must be set by ramp")
	assert(truck.z_height > 0.0, "Z-height must be above ground")
	
	# Simulate air physics
	truck._process_elevation(0.1)
	assert(truck.z_height > 10.0, "Truck should rise in air")
	assert(truck.z_velocity < 350.0, "Gravity must pull Z-velocity down")
	
	# Simulate flight until landing (approx 0.8s)
	for i in range(20):
		truck._process_elevation(0.05)
	assert(truck.z_height == 0.0, "Truck must land on ground")
	assert(truck.z_velocity == 0.0, "Z-velocity should zero on landing")
	assert(truck.current_speed > 0.0, "Truck should retain momentum on landing")
	
	truck.queue_free()
	print("  -> Ramp Jump & Z-Elevation OK.")
	return true

func _test_surfaces() -> bool:
	print("[5/9] Testing Surfaces (Mud drag & Water aquaplaning)...")
	var truck = OffroadTruck.new(0, false)
	root.add_child(truck)
	truck._ready()
	
	assert(truck.current_surface == OffroadConfig.SurfaceType.DIRT, "Default surface must be DIRT")
	
	# Mud
	truck.current_surface = OffroadConfig.SurfaceType.MUD
	assert(truck.current_surface == OffroadConfig.SurfaceType.MUD, "Should switch to MUD")
	
	# Water
	truck.current_surface = OffroadConfig.SurfaceType.WATER
	assert(truck.current_surface == OffroadConfig.SurfaceType.WATER, "Should switch to WATER")
	
	truck.queue_free()
	print("  -> Surfaces OK.")
	return true

func _test_pickups() -> bool:
	print("[6/9] Testing Dynamic Pickups (Cash & Nitro)...")
	var truck = OffroadTruck.new(0, false)
	root.add_child(truck)
	truck._ready()
	
	var initial_cash = truck.cash
	var initial_nitros = truck.nitros_remaining
	
	# Cash Pickup
	truck.collect_pickup(OffroadPickup.PickupType.CASH)
	assert(truck.cash == initial_cash + 10000, "Cash should increase by $10,000")
	
	# Nitro Pickup
	truck.collect_pickup(OffroadPickup.PickupType.NITRO)
	assert(truck.nitros_remaining == initial_nitros + 1, "Nitro count should increase by 1")
	
	truck.queue_free()
	print("  -> Pickups OK.")
	return true

func _test_checkpoints_and_laps() -> bool:
	print("[7/9] Testing Checkpoint Order & Lap Counting...")
	var truck = OffroadTruck.new(0, false)
	root.add_child(truck)
	truck._ready()
	
	assert(truck.current_lap == 1, "Must start on lap 1")
	assert(truck.next_checkpoint == 0, "First checkpoint should be 0 (Finish line)")
	
	# Passing wrong checkpoint should do nothing
	truck.trigger_checkpoint(2)
	assert(truck.current_lap == 1, "Skipping checkpoints must not advance lap")
	assert(truck.next_checkpoint == 0, "Next checkpoint should remain 0")
	
	# Correct sequence: 0 -> 1 -> 2 -> 3 -> 0 (Lap 2!)
	truck.trigger_checkpoint(0) # Cross line on start
	assert(truck.current_lap == 2, "Crossing CP 0 increments lap")
	assert(truck.next_checkpoint == 1, "Next checkpoint should be 1")
	
	truck.trigger_checkpoint(1)
	assert(truck.next_checkpoint == 2, "Next checkpoint should be 2")
	truck.trigger_checkpoint(2)
	assert(truck.next_checkpoint == 3, "Next checkpoint should be 3")
	truck.trigger_checkpoint(3)
	assert(truck.next_checkpoint == 0, "Next checkpoint should cycle to 0")
	
	truck.queue_free()
	print("  -> Checkpoints & Laps OK.")
	return true

func _test_speed_shop() -> bool:
	print("[8/9] Testing Speed Shop Upgrade Economics...")
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
	assert(truck.cash == 15000, "Cash should be deducted by $10,000")
	assert(truck.upgrades["shocks"] == 2, "Shocks should now be level 2")
	
	# Buy Nitro ($5,000)
	var old_nitros = truck.nitros_remaining
	shop._buy_upgrade("nitro", OffroadConfig.NITRO_PRICE)
	assert(truck.cash == 10000, "Cash should be deducted by $5,000")
	assert(truck.nitros_remaining == old_nitros + 1, "Nitros should increase")
	
	# Fail buy with insufficient cash
	truck.cash = 2000
	shop._buy_upgrade("top_speed", OffroadConfig.UPGRADE_PRICE)
	assert(truck.upgrades["top_speed"] == 1, "Upgrade must not succeed with insufficient cash")
	assert(truck.cash == 2000, "Cash must remain unchanged on failed purchase")
	
	shop.queue_free()
	truck.queue_free()
	print("  -> Speed Shop OK.")
	return true

func _test_full_game_orchestration() -> bool:
	print("[9/9] Testing Main Game Orchestration & Single-Screen Track...")
	var game = MainOffroadGame.new()
	root.add_child(game)
	game._ready()
	
	assert(game.track != null, "StadiumTrack must be instantiated")
	assert(game.hud != null, "HUD must be instantiated")
	assert(game.trucks.size() == 4, "Must have 4 trucks on the grid")
	assert(game.is_race_active, "Race must start active")
	
	# Verify Player 4 is The Ironman AI
	assert(game.trucks[3].is_ai, "Player 4 must be AI")
	assert(game.trucks[3].truck_name == "THE IRONMAN", "Player 4 must be The Ironman")
	
	game.queue_free()
	print("  -> Main Game Orchestration OK.")
	return true
