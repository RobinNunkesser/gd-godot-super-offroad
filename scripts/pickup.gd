class_name OffroadPickup
extends Area2D

enum PickupType {
	CASH,
	NITRO
}

@export var type: PickupType = PickupType.CASH

var visual_node: Node2D
var bob_time: float = 0.0

func _init(pickup_type: PickupType = PickupType.CASH) -> void:
	type = pickup_type

func _ready() -> void:
	collision_layer = OffroadConfig.COLLISION_LAYER_PICKUPS
	collision_mask = OffroadConfig.COLLISION_LAYER_TRUCKS
	
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 16.0
	col.shape = circle
	add_child(col)
	
	visual_node = Node2D.new()
	add_child(visual_node)
	_draw_visual()
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _draw_visual() -> void:
	var base_poly = Polygon2D.new()
	var points = PackedVector2Array()
	var segments = 12
	var rad = 14.0
	for i in range(segments):
		var angle = (float(i) / float(segments)) * TAU
		points.append(Vector2(cos(angle) * rad, sin(angle) * rad))
	base_poly.polygon = points
	
	if type == PickupType.CASH:
		base_poly.color = Color(0.2, 0.85, 0.3) # Bright Green
	else:
		base_poly.color = Color(0.95, 0.3, 0.2) # Nitro Red
	visual_node.add_child(base_poly)
	
	# Icon Label
	var lbl = Label.new()
	lbl.position = Vector2(-10, -11)
	lbl.size = Vector2(20, 20)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.text = "$" if type == PickupType.CASH else "N"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	visual_node.add_child(lbl)

func _process(delta: float) -> void:
	bob_time += delta * 4.0
	if visual_node:
		visual_node.position.y = sin(bob_time) * 3.0
		visual_node.scale = Vector2.ONE * (1.0 + sin(bob_time * 2.0) * 0.1)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("collect_pickup"):
		body.collect_pickup(type)
		queue_free()
