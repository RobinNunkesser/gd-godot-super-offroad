class_name OffroadHUD
extends CanvasLayer

var title_label: Label
var lap_label: Label
var banner_label: Label
var banner_timer: float = 0.0

var player_cards: Array[Panel] = []
var card_labels: Array[Label] = []

func _ready() -> void:
	layer = 10
	
	var root_ctrl = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_ctrl)
	
	# Top Header Bar
	var top_bar = Panel.new()
	top_bar.position = Vector2(40, 8)
	top_bar.size = Vector2(1200, 48)
	root_ctrl.add_child(top_bar)
	
	title_label = Label.new()
	title_label.position = Vector2(16, 12)
	title_label.size = Vector2(400, 24)
	title_label.text = "★ SUPER OFF ROAD ★"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	top_bar.add_child(title_label)
	
	lap_label = Label.new()
	lap_label.position = Vector2(980, 12)
	lap_label.size = Vector2(200, 24)
	lap_label.text = "LAP: 1 / 3"
	lap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lap_label.add_theme_font_size_override("font_size", 16)
	lap_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	top_bar.add_child(lap_label)
	
	# 4 Driver Cards im Infield oder Header
	for i in range(4):
		var card = Panel.new()
		card.position = Vector2(360 + i * 145, 10)
		card.size = Vector2(135, 28)
		top_bar.add_child(card)
		player_cards.append(card)
		
		var lbl = Label.new()
		lbl.position = Vector2(6, 4)
		lbl.size = Vector2(125, 20)
		lbl.text = "P%d: $0 N:3" % (i + 1)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", OffroadConfig.TRUCK_COLORS[i])
		card.add_child(lbl)
		card_labels.append(lbl)
		
	# Race Event Banner (mittig auf der Leinwand)
	banner_label = Label.new()
	banner_label.position = Vector2(0, 320)
	banner_label.size = Vector2(1280, 80)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_label.text = "🏁 RACE START! 🏁"
	banner_label.add_theme_font_size_override("font_size", 36)
	banner_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2))
	banner_label.visible = false
	root_ctrl.add_child(banner_label)
	
	# Bottom Controls Hint
	var hint = Label.new()
	hint.position = Vector2(40, 685)
	hint.size = Vector2(1200, 24)
	hint.text = "Steuerung: [WASD / Space] P1  |  [Pfeiltasten / Enter] P2  |  [IKJL / U] P3  |  Gamepads (Analog + A/B/Trigger)"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 0.7))
	root_ctrl.add_child(hint)

func _process(delta: float) -> void:
	if banner_timer > 0.0:
		banner_timer -= delta
		if banner_timer <= 0.0:
			banner_label.visible = false

func show_banner(text: String, duration: float = 2.5, color: Color = Color(1.0, 0.9, 0.2)) -> void:
	if banner_label:
		banner_label.text = text
		banner_label.add_theme_color_override("font_color", color)
		banner_label.visible = true
		banner_timer = duration

func update_trucks_info(trucks: Array[OffroadTruck], max_laps: int = 3) -> void:
	var leader_lap = 1
	for i in range(trucks.size()):
		var t = trucks[i]
		if i < card_labels.size():
			var name_tag = "P%d" % (t.truck_id + 1)
			if t.is_ai and t.truck_id == 3:
				name_tag = "IRON"
			card_labels[i].text = "%s: $%d N:%d" % [name_tag, t.cash, t.nitros_remaining]
		if t.current_lap > leader_lap:
			leader_lap = t.current_lap
			
	if lap_label:
		lap_label.text = "LAP: %d / %d" % [min(leader_lap, max_laps), max_laps]
