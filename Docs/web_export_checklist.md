# Web Export Pre-Flight Checklist: Godot 4.7.2

## 1. Export Preset Settings
In Godot, navigate to **Project -> Export -> Web (Runnable)** and enforce these exact parameters:

| Configuration Item | Required Value | Rationale |
|---|---|---|
| **Export Type** | **Single-Threaded** (Threads OFF) | Multi-threading in Godot 4 Web requires `SharedArrayBuffer`, which mandates strict `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` response headers. Itch.io and standard static hosts do not support these by default without reverse-proxy hacks. Single-threaded guarantees instant web loading. |
| **VRAM Texture Compression** | **Basis Universal / VRAM Compressed** | Minimizes GPU texture memory footprint on mobile and Chromebook browsers. |
| **Extensions Support** | **WebAssembly (.wasm)** | Standard 32-bit WASM execution target. |
| **Head Include** | Unlocked Autoplay snippet (optional) | Ensures WebAudio initializes immediately upon first user click. |

---

## 2. Display & Viewport Configuration
Verify under **Project -> Project Settings -> Display -> Window**:
- **Viewport Width**: 480
- **Viewport Height**: 270
- **Window Width Override**: 960 (2x integer upscale)
- **Window Height Override**: 540 (2x integer upscale)
- **Stretch Mode**: `viewport`
- **Stretch Aspect**: `keep`
- **Scale Mode**: `integer`
- **Rendering Method**: `gl_compatibility` (Compatibility renderer / WebGL 2.0)

---

## 3. Size Budget & Asset Footprint Audit
- **Target Size Budget**: **< 35 MB total uncompressed bundle** (< 20 MB compressed zip).
- **Engine WASM Binary**: ~18–22 MB.
- **Game PCK / Assets**: ~6–10 MB.
- **Audio Assets**: Standardized on compressed `.ogg` for music loops and procedurally synthesized waveforms (`AudioStreamGenerator`) for SFX.
- **Fonts**: Pixel monospace font for Latin text (< 100 KB); dynamic vector fallback font (`NotoSansArabic-Regular.ttf`) strictly isolated for Arabic locale (< 3.5 MB).

---

## 4. Cross-Browser Verification Protocol

### A. Google Chrome / Chromium (Desktop & Android)
1. **Audio Autoplay Gate**: Verify audio does not throw console autoplay exceptions on initial page load. Confirm music crossfades and SFX start cleanly after first canvas click.
2. **WebGL Context**: Open DevTools (`F12`) -> Console. Confirm WebGL 2.0 context initializes without shader compilation warnings.
3. **IndexedDB Autosave**: Play through Day 1 to Morning Day 2. Open **DevTools -> Application -> IndexedDB -> /userfs**. Verify `savegame.json` and `telemetry.csv` exist and contain valid JSON/CSV records.
4. **Keyboard Focus**: Click canvas and test keys (`Space`, `E`, `L`, `Esc`, `F1-F9`). Confirm keys are not intercepted by the browser window scroll.

### B. Mozilla Firefox (Desktop)
1. **Canvas Resizing**: Switch between standard 960x540 embed and full-screen mode. Verify integer pixel ratio is maintained with crisp sharp text and zero blurring.
2. **WebAudio Latency**: Play the Forge minigame. Confirm rhythm strike audio feedback has sub-40ms latency and no buffer underrun crackle.
3. **IndexedDB Sync**: Refresh page after night summary; click **Continue** on main menu. Verify career state restores seamlessly.
