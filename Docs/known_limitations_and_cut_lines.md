# Known Limitations and Cut Lines (Spec Part F)

This document formalizes the scope control decisions, activated cut lines, and technical trade-offs established in accordance with Spec Part F.

---

## 1. Scope Control & Cut Lines Review

During early production and milestone reviews, four contingent cut lines were defined to safeguard delivery of the core 30-day economic sim:

| Cut Line ID | Description | Jam Checkpoint | Final Disposition | Rationale |
|---|---|---|---|---|
| **CL1** | Arabic Localization & RTL Mirroring | Checkpoint 1 (End of Phase 1) | **RETAINED & IMPLEMENTED** | Preserved full tri-language localization (`en`, `es`, `ar`) with Godot 4 TextServer Advanced and `Window.layout_direction` root mirroring. |
| **CL2** | Secondary Upgrades (Warranty Insurance & Rolodex) | Checkpoint 1 (End of Phase 1) | **RETAINED & IMPLEMENTED** | Integrated into UpgradeManager with clear payback calculations alongside primary workshop tooling. |
| **CL3** | Assembler Multi-Step Routing Sequence | Checkpoint 2 (End of Phase 3) | **RESTRUCTURED (Streamlined)** | Replaced open-ended multi-stage circuits with single-circuit guaranteed-solvable random walk grids, eliminating unwinnable dead-ends. |
| **CL4** | Scrap Scavenging Action Point Activity | Checkpoint 2 (End of Phase 3) | **CUT (Exercised)** | Scavenging minigame removed from scope. Replaced with clean workshop part ordering and Forge scrap reduction mechanics (up to -30% material costs). |

---

## 2. Technical Limitations & Architectural Trade-offs

### 1. Single-Threaded WebAssembly Target
- **Constraint**: Multi-threaded Godot 4 web exports require SharedArrayBuffer, which is blocked by modern browsers unless served with strict `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` HTTP headers.
- **Disposition**: Single-threaded export preset enabled. Audio synthesis, minigame physics, and JSON serialization run deterministically on the main browser thread without web workers.

### 2. Browser WebAudio Autoplay Policy
- **Constraint**: Chrome, Firefox, and Safari prevent web audio contexts from playing until the user has performed an explicit interaction (click or keypress) within the iframe or page window.
- **Disposition**: Audio manager includes a safe first-input unlock hook. All background music and SFX streams remain deferred until the player clicks anywhere on the canvas.

### 3. Local IndexedDB Persistence Scope
- **Constraint**: In Godot Web exports, `user://` maps to Emscripten's virtual in-memory filesystem backed asynchronously by browser IndexedDB (`/userfs`).
- **Disposition**: Autosaves (`user://savegame.json`) and daily telemetry logs (`user://telemetry.csv`) persist locally per browser profile. Opening the game in Private / Incognito mode or clearing browsing data will clear local saves.

### 4. Compatibility Renderer Shader Constraints
- **Constraint**: High-end Godot Forward+ or Mobile multi-pass post-processing (screen-reading bloom, heavy chromatic aberration) causes major performance degradation or visual artifacts on WebGL2 mobile browsers.
- **Disposition**: All shaders (`crt_scanlines.gdshader`, `neon_glow.gdshader`) are built using lightweight procedural UV math and single-pass distance fields, guaranteeing smooth 60 FPS on integrated GPUs.

### 5. Fixed Pixel-Perfect 480x270 Canvas Scaling
- **Constraint**: Non-16:9 aspect ratios or arbitrary window scaling can cause pixel distortion on retro monospace typography and 1px borders.
- **Disposition**: Canvas is set to 480x270 viewport with integer upscale (`scale_mode = integer`, `aspect = keep`). Non-standard aspect ratios display clean retro pillarboxes/letterboxes.
