# LUMEN FIGHTERS
Street Fighter-style 1v1 with light-based weapons. Hybrid AI-driven demo.

**Engine:** Godot 4.7 | **Location:** `~/Projects/lumen-fighters` (NOT synced to OneDrive/Google Drive)

## Quick Start
1. Open Godot 4.7 -> Import -> select `project.godot` in this folder
2. Press Play (Main.tscn)

## Controls
- **P1:** A/D Move | W Jump | S Block | J Jab (+5 Lumen) | K Slash (-10 Lumen) | L Burst (-25)
- **P2:** Arrows Move/Jump/Block | Numpad 1 Jab | 2 Slash | 3 Burst
- **R** Restart

## GDD
See `GDD.md`

## Hybrid AI Pipeline
- Code: Ollama qwen2.5-coder:7b (local)
- 2D: Leonardo/Bing -> Krita
- 3D: Meshy/Hunyuan3D on HuggingFace -> Blender
- Audio: Suno
- Assembly: Godot

## Git
Repo will be `github.com/armahnii2000/lumen-fighters`
