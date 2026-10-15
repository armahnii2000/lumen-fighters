# Lumen Fighters

A 1v1 2D fighting game prototype built in Godot 4 where weapons are made of solid light. Attacks and defenses are directly tied to an in-engine **Lumen Energy** meter, making resource management central to every round.

## Core Mechanics

- **Lumen Resource System:** Every fighter has a 0–100 Lumen meter alongside standard health. Attacks consume or generate Lumen.
  - **Quick Jab:** Generates +5 Lumen on hit. Keeps offensive pressure alive when low on energy.
  - **Heavy Slash:** Consumes 10 Lumen to deal heavy damage (15 HP).
  - **Photon Burst (Special):** Consumes 25 Lumen to fire a projectile burst with knockback.
  - **Block:** Reduces incoming damage by 70% while active, consuming 5 Lumen per blocked attack.
- **Dynamic Weapon States:**
  - `Ignited` (>10 Lumen): Solid-light blade extends, hits harder, and casts dynamic point light.
  - `Dimmed` (<10 Lumen): Blade flickers and retracts. Attacks deal minimal damage until meter is rebuilt via jabs or passive recovery (+2/sec).
- **Two-Player Local Play:** Playable head-to-head on a single keyboard or with standard gamepads.

## Controls

### Keyboard

| Action | Player 1 | Player 2 |
| :--- | :--- | :--- |
| **Move Left / Right** | `A` / `D` | `←` / `→` |
| **Jump** | `W` | `↑` |
| **Block** | `S` | `↓` |
| **Quick Jab** (+5 Lumen) | `J` | `Numpad 1` |
| **Heavy Slash** (-10 Lumen) | `K` | `Numpad 2` |
| **Photon Burst** (-25 Lumen) | `L` | `Numpad 3` |
| **Restart Match** | `R` | `R` |

### Controller (Xbox / PlayStation)

- **Move / Jump / Crouch:** D-Pad or Left Stick
- **Jab:** `X` (Xbox) / `Square` (PS)
- **Slash:** `Y` (Xbox) / `Triangle` (PS)
- **Special:** `B` (Xbox) / `Circle` (PS)
- **Block:** Left Trigger (`LT` / `L2`) or Left Bumper (`LB` / `L1`)

## Getting Started

1. Download or clone this repository:
   ```bash
   git clone https://github.com/armahnii2000/lumen-fighters.git
   ```
2. Launch **Godot 4.3+** (or Godot 4.x).
3. Click **Import**, navigate to the project directory, and select `project.godot`.
4. Run the project (press `F5` or click **Play** in the top right to start `Main.tscn`).

## Design Document

A full breakdown of the mechanics, frame data considerations, and planned features is available in [GDD.md](GDD.md).

## License

This project is licensed under the [MIT License](LICENSE).
