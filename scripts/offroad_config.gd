class_name OffroadConfig
extends RefCounted

# --- Collision Layers ---
const COLLISION_LAYER_WORLD: int = 1
const COLLISION_LAYER_TRUCKS: int = 2
const COLLISION_LAYER_CHECKPOINTS: int = 4
const COLLISION_LAYER_PICKUPS: int = 8

# --- Surface Types ---
enum SurfaceType {
	DIRT,
	MUD,
	WATER,
	RAMP
}

# --- Base Truck Physics ---
const BASE_ACCEL: float = 460.0
const BASE_MAX_SPEED: float = 330.0
const BASE_REVERSE_SPEED: float = 120.0
const BASE_BRAKE_FORCE: float = 580.0
const BASE_STEER_SPEED: float = 3.8 # Radian pro Sekunde
const BASE_TIRE_GRIP: float = 0.86 # 0.0 = pure ice, 1.0 = on rails

# --- Nitro Turbo ---
const NITRO_BOOST_SPEED: float = 520.0
const NITRO_ACCEL_BOOST: float = 900.0
const NITRO_DURATION: float = 1.3
const NITRO_PRICE: int = 5000
const STARTING_NITROS: int = 3

# --- Z-Elevation Jump Physics (Schanzen) ---
const GRAVITY_Z: float = 980.0
const RAMP_LAUNCH_VEL_Z: float = 380.0

# --- Race Settings ---
const DEFAULT_TOTAL_LAPS: int = 3

# --- Upgrade System ---
const UPGRADE_PRICE: int = 10000
const MAX_UPGRADE_LEVEL: int = 5

# --- Truck Visual Colors ---
const TRUCK_COLORS: Array[Color] = [
	Color(0.92, 0.22, 0.24), # P1: Red (#e63946)
	Color(0.18, 0.45, 0.88), # P2: Blue
	Color(0.96, 0.72, 0.20), # P3: Yellow
	Color(0.95, 0.96, 0.98)  # P4: The Ironman (White)
]

const TRUCK_NAMES: Array[String] = [
	"PLAYER 1 (RED)",
	"PLAYER 2 (BLUE)",
	"PLAYER 3 (YELLOW)",
	"THE IRONMAN"
]
