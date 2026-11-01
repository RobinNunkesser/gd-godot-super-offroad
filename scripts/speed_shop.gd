class_name OffroadSpeedShop
extends CanvasLayer

signal next_race_requested()

var target_truck: OffroadTruck
var cash_label: Label
var status_label: Label

var upgrade_labels: Dictionary = {}

func setup_shop(truck: OffroadTruck) -> void:
	target_truck = truck
	_update_ui()

func _ready() -> void:
	layer = 20
	
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.08, 0.08, 0.12, 0.92) # Abdunkeln
	add_child(overlay)
	
	var panel = Panel.new()
	panel.position = Vector2(240, 80)
	panel.size = Vector2(800, 560)
	overlay.add_child(panel)
	
	# Title
	var title = Label.new()
	title.position = Vector2(0, 24)
	title.size = Vector2(800, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "★ SPEED SHOP - TRUCK UPGRADES ★"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	panel.add_child(title)
	
	# Cash Display
	cash_label = Label.new()
	cash_label.position = Vector2(0, 68)
	cash_label.size = Vector2(800, 30)
	cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cash_label.text = "CASH: $0"
	cash_label.add_theme_font_size_override("font_size", 18)
	cash_label.add_theme_color_override("font_color", Color(0.3, 0.95, 0.4))
	panel.add_child(cash_label)
	
	# Upgrade Rows
	var items = [
		{"key": "shocks", "name": "SHOCKS (Stoßdämpfer)", "desc": "Minimiert Geschwindigkeitsverlust nach Schanzensprüngen", "price": OffroadConfig.UPGRADE_PRICE},
		{"key": "tires", "name": "TIRES (Reifen)", "desc": "Erhöht Grip und Kurvenkontrolle auf losem Lehm", "price": OffroadConfig.UPGRADE_PRICE},
		{"key": "accel", "name": "ACCELERATION (Motor)", "desc": "Schnelleres Herausbeschleunigen aus Kurven und Schlamm", "price": OffroadConfig.UPGRADE_PRICE},
		{"key": "top_speed", "name": "TOP SPEED (Endgeschwindigkeit)", "desc": "Maximale Geschwindigkeit auf geraden Streckenabschnitten", "price": OffroadConfig.UPGRADE_PRICE},
		{"key": "nitro", "name": "NITRO BOOST (Zusatz-Turbo)", "desc": "+1 Nitro-Ladung für das nächste Rennen", "price": OffroadConfig.NITRO_PRICE}
	]
	
	var start_y = 120
	for i in range(items.size()):
		var item = items[i]
		var y = start_y + i * 72
		
		var lbl_name = Label.new()
		lbl_name.position = Vector2(50, y)
		lbl_name.size = Vector2(400, 24)
		lbl_name.text = "%s ($%d)" % [item["name"], item["price"]]
		lbl_name.add_theme_font_size_override("font_size", 14)
		panel.add_child(lbl_name)
		
		var lbl_desc = Label.new()
		lbl_desc.position = Vector2(50, y + 22)
		lbl_desc.size = Vector2(450, 20)
		lbl_desc.text = item["desc"]
		lbl_desc.add_theme_font_size_override("font_size", 11)
		lbl_desc.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		panel.add_child(lbl_desc)
		
		var lbl_val = Label.new()
		lbl_val.position = Vector2(520, y + 8)
		lbl_val.size = Vector2(100, 24)
		lbl_val.text = "LVL 1"
		lbl_val.add_theme_font_size_override("font_size", 13)
		lbl_val.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		panel.add_child(lbl_val)
		upgrade_labels[item["key"]] = lbl_val
		
		var btn = Button.new()
		btn.position = Vector2(640, y + 6)
		btn.size = Vector2(110, 32)
		btn.text = "BUY [+]"
		var key = item["key"]
		var price = item["price"]
		btn.pressed.connect(func(): _buy_upgrade(key, price))
		panel.add_child(btn)
		
	# Status Toast Label
	status_label = Label.new()
	status_label.position = Vector2(0, 480)
	status_label.size = Vector2(800, 24)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	panel.add_child(status_label)
	
	# Next Race Button
	var btn_next = Button.new()
	btn_next.position = Vector2(300, 508)
	btn_next.size = Vector2(200, 38)
	btn_next.text = "🏁 START NEXT RACE"
	btn_next.pressed.connect(func(): next_race_requested.emit())
	panel.add_child(btn_next)

func _buy_upgrade(key: String, price: int) -> void:
	if not target_truck:
		return
	if target_truck.cash < price:
		status_label.text = "⚠ Nicht genügend Cash für dieses Upgrade!"
		return
		
	if key == "nitro":
		target_truck.cash -= price
		target_truck.nitros_remaining += 1
		status_label.text = "✓ Nitro gekauft! (+1)"
	else:
		var current_lvl = target_truck.upgrades.get(key, 1)
		if current_lvl >= OffroadConfig.MAX_UPGRADE_LEVEL:
			status_label.text = "⚠ Dieses Upgrade hat bereits das Maximum erreicht (LVL 5)!"
			return
		target_truck.cash -= price
		target_truck.upgrades[key] = current_lvl + 1
		status_label.text = "✓ Upgrade gekauft: %s auf Stufe %d!" % [key.to_upper(), current_lvl + 1]
		
	_update_ui()

func _update_ui() -> void:
	if not target_truck:
		return
	if cash_label:
		cash_label.text = "DRIVER: %s  |  CASH: $%d" % [target_truck.truck_name, target_truck.cash]
	
	for key in ["shocks", "tires", "accel", "top_speed"]:
		if key in upgrade_labels:
			var lvl = target_truck.upgrades.get(key, 1)
			upgrade_labels[key].text = "★".repeat(lvl) + "☆".repeat(OffroadConfig.MAX_UPGRADE_LEVEL - lvl)
			
	if "nitro" in upgrade_labels:
		upgrade_labels["nitro"].text = "VORRAT: %d" % target_truck.nitros_remaining
