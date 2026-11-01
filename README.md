# Super Off Road (1989) Arcade Remake & Prototype in Godot 4

> **Educational Game Development Prototype**  
> **Original Arcade Classic:** *Ivan "Ironman" Stewart's Super Off Road* (Leland Corp, 1989)  
> **Engine:** Godot Engine 4 (GDScript, Forward Plus / Mobile)  
> **Target Audience:** Lecture series *Interaktive Grafikanwendungen* (IGA) & Game Architecture.

---

## 🏁 Über das Projekt

Dieses Repository ist ein spielbarer Architektur- und Didaktik-Prototyp des legendären 1989er Arcade-Klassikers **Super Off Road**. Es demonstriert, wie die spezifischen Stärken des Single-Screen-Rennspiels in einer modernen 2D/2.5D-Engine umgesetzt werden:

1. **Single-Screen Stadium Dirt Track (Zero Camera Friction):**
   - Das gesamte Stadionrennen findet auf einem einzigen 1280×720 Viewport statt.
   - Kein Split-Screen, keine Kamera-Verzögerung, maximaler Überblick und intensive Rad-an-Rad-Duelle.
2. **Dual-Angle Fahrzeug-Kinematik mit Schlupfwinkel (Dirt Drift):**
   - Trennung von Fahrzeugorientierung (*Heading Angle*) und Translationsvektor (*Velocity Vector*).
   - Physikalisches Rutschen und Reifenschlupf auf losem Lehmboden inklusive Staub-Partikeln (`CPUParticles2D`).
3. **Z-Elevation Jump Physics (Schanzen & Waschbrett-Hügel):**
   - Überfahren von Rampen katapultiert die Trucks in die Höhe ($z > 0$).
   - Dynamischer Schattenwurf auf dem Boden, Größenskalierung im Flug und Gravitationssimulation.
   - Shocks-Dämpfung bei der Landung: minderwertige Dämpfer führen zu Drehungen oder massivem Tempoverlust!
4. **Dynamische Streckenoberflächen:**
   - **Trockener Lehm (Dirt):** Standard-Grip und Beschleunigung.
   - **Schlammgruben (Mud):** Hoher Rollwiderstand und drastische Abbremsung.
   - **Wasserpfützen (Water):** Verlust der Seitenführung (Aquaplaning).
5. **In-Race Pickups:**
   - Auf der Piste spawnende Geldsäcke ($\$10.000$) und Nitro-Kanister ($+1$).
6. **Speed Shop Metagame & Upgrade-Ökonomie:**
   - Investition des Preisgelds zwischen den Rennen in **Shocks**, **Tires**, **Acceleration**, **Top Speed** und **Nitros**.

---

## 🕹️ Steuerung (Local Multiplayer)

Das Spiel unterstützt bis zu 4 gleichzeitige Fahrer:

| Spieler | Lenkung | Gas / Bremse | Nitro Boost | Gamepad |
| :--- | :--- | :--- | :--- | :--- |
| **Player 1 (Rot)** | `A` / `D` | `W` (Gas) / `S` (Bremse) | `Leertaste` | Device 0: Analog-Stick + A / B / Trigger |
| **Player 2 (Blau)** | `Pfeil Links` / `Rechts` | `Pfeil Oben` / `Unten` | `Enter` | Device 1: Analog-Stick + A / B / Trigger |
| **Player 3 (Gelb)** | `J` / `L` | `I` (Gas) / `K` (Bremse) | `U` | Device 2: Analog-Stick + A / B / Trigger |
| **The Ironman (Weiß)** | *Autonome KI* | *Autonome KI* | *Autonome KI* | KI-Wegpunkt-Spline |

---

## 🏗️ Architektur & Projektstruktur

```
gd-godot-super-offroad/
├── project.godot            # Engine-Konfiguration & InputMap
├── scenes/
│   ├── main.tscn            # Hauptszene
│   └── main.gd              # Renn-Orchestrierung, Podium & Shop-Flow
├── scripts/
│   ├── offroad_config.gd    # Zentrale Parameter, Oberflächen & Farbdefinitionen
│   ├── offroad_truck.gd     # CharacterBody2D mit Drift, Z-Elevation & Nitro
│   ├── stadium_track.gd     # Streckengeometrie, Wände, Schanze & Checkpoints
│   ├── pickup.gd            # Dynamische Items (Cash, Nitro)
│   ├── hud.gd               # Stadion-Anzeigetafel, Runden & Renn-Banner
│   └── speed_shop.gd        # Interaktiver Upgrade-Shop zwischen Rennen
└── test_gameplay.gd         # 100 % automatisierte Headless-Testsuite
```

---

## 🧪 Verifikation & CI/CD Testing

Das gesamte Projekt kann vollständig autonom und headless getestet werden:

```bash
# Headless Ausführung aller 9 Test-Suiten
/Applications/Godot.app/Contents/MacOS/Godot --headless -s test_gameplay.gd

# Spiel starten
/Applications/Godot.app/Contents/MacOS/Godot scenes/main.tscn
```
