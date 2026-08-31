# LUMEN FIGHTERS - Game Design Document
### Genre: 1v1 2D Light-Weapons Fighter | Inspired by Street Fighter | Engine: Godot 4.7 | Platform: PC/Mac

#### 1. CORE CONCEPT
Two duelists fight with solid-light weapons. Light is not just VFX - it's the core mechanic. Weapons generate **Lumen Energy** that powers offense/defense. Managing light = managing the fight.

Tagline: *"Forge Light. Break Light."*

#### 2. PILLARS
*   **Light as Weapon & Resource:** Every attack consumes/generator Lumen. No light = weak punches.
*   **Readability:** Like Street Fighter - clear hitboxes, 60fps, readable silhouettes + bright light trails.
*   **Risk/Reward:** Overcharge = massive damage but blinds you/leaves you open.

#### 3. PLAYERS & CONTROLS (Demo Scope)
*   **P1:** WASD - A/D Move, W Jump, S Block. **Attacks:** J (Quick Light Jab), K (Heavy Light Slash), L (Special - Photon Burst)
*   **P2:** Arrows - Left/Right Move, Up Jump, Down Block. **Attacks:** Numpad 1 (Jab), 2 (Slash), 3 (Special)
*   Supports 2 players on one keyboard. Gamepad ready.

#### 4. COMBAT MECHANICS (Hybrid AI-Driven Vision)
*   **Health:** 100 HP per fighter
*   **Lumen Meter:** 0-100. Jab (+5), Slash (-10, 15 dmg), Block drains if hit, Special (-40, 30 dmg + knockback)
*   **Light Weapon Types (Full Game):** Saber (balanced), Spear (range), Gauntlets (fast), Hammer (slow/heavy). *Demo: Saber only (light blade)*
*   **Systems:**
    *   Hitstun / Knockback
    *   Block (hold S/Down) - reduces damage 70% if has Lumen, costs 5 Lumen per blocked hit
    *   Dash: Double-tap A/D or Left/Right
    *   Clash: If blades hit simultaneously -> Lumen Burst + pushback

#### 5. LIGHT MECHANICS - THE TWIST
*   **Weapon State:**
    *   `IGNITED` (Lumen >10): Blade glows, extended hitbox, leaves light trails, emits PointLight2D
    *   `DIMMED` (Lumen <10): Short weak blade, flickers, must recharge with jabs / idle regen (+2/sec)
*   **Photon Burst (Special):** Fires 3 light projectiles. If blocked -> Blinds opponent (screen flash 0.2s)
*   **Overcharge:** Hold Special 1s at >80 Lumen -> Super Slash (50 dmg) but drains to 0 and you are stunned 0.8s if missed.

#### 6. STAGE (Demo)
Single Arena: *Prism Arena* - dark void with neon grid, reflective floor. Keeps focus on fighters/light.

#### 7. VISUAL & AUDIO DIRECTION (Hybrid AI Generation Plan)
*   **Style:** Stylized sci-fi, TRON-like. Silhouetted fighters with bright blade. Dark backgrounds to make light pop.
*   **Sprites (AI Cloud -> Krita cleanup):** Generate in Leonardo/Bing: `2D side-view fighting game sprite sheet, silhouette fighter with light saber, black background, 4 frames idle, 3 attack`
*   **VFX (Godot-native):** Line2D trails, PointLight2D, Particles2D for clash
*   **SFX (Suno/SFXR):** `light_saber_hum.wav`, `light_slash.wav`, `photon_burst.wav`, `clash.wav`
*   **Music:** Synthwave 100 BPM (Suno: "TRON synthwave fighting arena")

#### 8. DEMO SCOPE (This Build)
*   [x] 2 fighters (capsule + light blade) with collision
*   [x] Movement, Jump, Gravity
*   [x] Jab/Slash/Special with Lumen cost & cooldown
*   [x] Hit detection via Area2D + health + Lumen
*   [x] Block
*   [x] Health + Lumen UI bars
*   [x] Light blade grows/shrinks + glow
*   [x] Hit flash, KO, Restart (R)
*   [ ] AI Opponent (Future) | [ ] Full sprite sheets | [ ] 4 weapon types

#### 9. CONTROLS SUMMARY FOR DEMO
```
P1: A/D Move | W Jump | S Block | J Jab | K Slash | L Burst
P2: Arrows Move/Jump/Block | 1 Jab | 2 Slash | 3 Burst
R = Restart when KO
```

#### 10. NEXT STEPS (Post-Demo)
*   Replace capsules with AI-generated sprite sheets (Kenney or Leonardo)
*   Add AI bot using Godot Navigation + state machine
*   Add 4 light weapon types + Character Select
*   Add combo system (J->K->L)
