# Itch.io Submission & Publishing Checklist

## 1. Game Page Setup & Embed Settings
Under your game's **Edit Game** dashboard on itch.io:

- **Kind of Project**: **HTML** (You have a ZIP or HTML file that will be played in the browser).
- **Upload File**: `scrap_and_steel_web.zip` (Check: *This file will be played in the browser*).
- **Viewport Dimensions**:
  - **Width**: `960` px
  - **Height**: `540` px
- **Orientation**: Landscape default.
- **Fullscreen Button**: **Enabled** (Allows players to enter full-screen mode for immersion).
- **Enable Scrollbars**: **Disabled**.
- **Automatically Start on Page Load**: Enabled (with sound unlock on first click).

---

## 2. Mandatory Disclosures (AI Assistance & Localization)
Include the following exact disclosures in your game description / metadata section:

### AI-Assistance Disclosure
> **AI Assistance Disclosure**: The game's system architecture, mathematical balance formulas, shader mathematics, and procedural puzzle generation algorithms were designed and scaffolded with Google AI Studio assistance. All economic models, balance simulations, minigame timing, and user experience flows were manually audited, refactored, and verified by the development team.

### Localization & Translation Disclosure
> **Localization Disclosure**: English (`en`) is the native primary language of the game. Spanish (`es`) and Arabic (`ar`) translations were generated using modern machine translation (Google AI LLM) and optimized for character count, screen constraints, and bidirectional layout rules. Arabic text rendering utilizes Godot's TextServer Advanced with ICU ligature shaping and RTL window mirroring.

---

## 3. Metadata, Tags & Categorization
- **Genre**: Simulation / Management / Retro.
- **Visual Style**: 2D, Pixel Art, Cyberpunk, Industrial Sci-Fi.
- **Gameplay Tags**: `Crafting`, `Economy`, `Resource Management`, `Minigames`, `Cyberpunk`, `Rhythm`, `Puzzle`, `Singleplayer`, `Web-Playable`, `Godot 4`.
- **Custom Short Pitch**: *"A 30-day cyberpunk workshop sim where you craft high-tech contracts to pay off ruthless syndicate debt."*

---

## 4. Media & Asset Deliverables
- **Cover Image**: 630 x 500 px (PNG/JPG).
- **Screenshots**: At least 5 screenshots showcasing:
  1. Main Workshop hub with contract overview, action point pool, and ledger.
  2. Forge minigame (striking steel ingot in optimal temperature window).
  3. Calibrator minigame (pressure gauge needle stabilization).
  4. Assembler minigame (guaranteed solvable circuit routing puzzle).
  5. Night Summary financial ledger and R&D upgrade cards.
  6. Arabic RTL layout and Colorblind accessibility mode.
