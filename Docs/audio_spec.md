# Scrap & Steel: Audio Specification (v8)

Music is made in **BeepBox** and SFX in **jsfxr** (or sfxr/Bfxr). Everything is made by you (no AI audio, the jam frowns on it). I could not listen to anything while writing this, so treat the numbers as a strong starting recipe and tune by ear.

All audio files are **optional**: the game plays nothing for a missing file. When a file with the exact name is in `Assets/Audio/`, it is picked up with no code change. The wiring (`audio_director.gd`, `sfx.gd`) is already in the update.

---

## 1. File rules

| Rule | Value |
|---|---|
| Format | **OGG Vorbis**, 44.1 kHz, **mono**, 96 kbps or less |
| Location | `res://Assets/Audio/` (flat, no subfolders) |
| Music files | `music_<name>.ogg`, loops need the **Loop** checkbox on (see 5) |
| SFX files | `sfx_<name>.ogg`, no loop, no leading silence |
| Loudness | SFX peak about **-6 dBFS**, music peak about **-3 dBFS** (in-game bus volumes handle the rest) |
| Web | Audio starts only after the first click; `AudioManager` already handles this |

Converting from WAV (BeepBox and jsfxr both export WAV) with ffmpeg:

```
ffmpeg -i in.wav -ac 1 -ar 44100 -c:a libvorbis -b:a 96k out.ogg
```

Audacity works too: export as Ogg Vorbis, quality 3.

---

## 2. SFX list (12 wired, all in the original README)

"Played when" is what the code does today. Keep each sound short: they repeat all day, so avoid anything annoying after the 500th time.

| File | Played when | Length | Character | jsfxr starting point |
|---|---|---|---|---|
| `sfx_strike_hit.ogg` | Forge strike scores 0.5 or more | 0.20 to 0.35 s | Satisfying metal clang with a short ring | Start from **Hit/Hurt**, then: wave = square/noise mix, raise "Base frequency" about 0.45, short decay, add slight "Phaser/ Flanger" for ring, "Sustain time" tiny |
| `sfx_strike_miss.ogg` | Forge strike scores below 0.5 | 0.15 to 0.25 s | Dull thud, no ring | **Hit/Hurt**, low frequency, noise wave, fast decay, no sustain punch |
| `sfx_calibrator_tick.ogg` | The needle enters the bar | 0.05 to 0.08 s | Tiny clean tick | **Blip/Select**, high frequency, very short, "Square duty" 50% |
| `sfx_assembler_step.ogg` | A circuit cell is connected | 0.06 to 0.10 s | Light electronic click | **Blip/Select**, slightly rising pitch, short |
| `sfx_assembler_hazard.ogg` | A hazard cell is hit | 0.25 to 0.40 s | Zap / short circuit | **Laser/Shoot** inverted: noise wave, frequency slide down, a bit of vibrato |
| `sfx_credit_coin.ogg` | A contract pays out | 0.25 to 0.40 s | Coin / credit chime | **Pickup/Coin**, two quick notes rising, keep it bright but soft |
| `sfx_stamp.ogg` | A contract pays out (plays with the coin) | 0.15 to 0.25 s | Rubber stamp thump | **Hit/Hurt**, low, very short, little noise |
| `sfx_ui_click.ogg` | Every button press in the game | 0.03 to 0.06 s | Quiet soft click | **Blip/Select**, short, **low volume**: it plays a lot |
| `sfx_warning.ogg` | A strike, a fine or a warranty refund | 0.35 to 0.50 s | Two-tone alert, tense but not scary | **Powerup** reversed: falling two notes, square wave |
| `sfx_upgrade_buy.ogg` | An R&D upgrade is bought | 0.45 to 0.70 s | Rising power-up | **Powerup**, rising arpeggio, add a little reverb-like decay |
| `sfx_installment_due.ogg` | The syndicate installment is charged each week | 0.60 to 0.90 s | Ominous low notice | **Synth/Tone**, low frequency, slow attack, dissonant two-tone |
| `sfx_overtime_activate.ogg` | Overtime is bought | 0.40 to 0.60 s | Power-surge buzz | **Powerup** with noise, fast rising buzz then cut |

Two things to know:
- Because every Button plays `ui_click`, Assembler cells play `ui_click` **and** `assembler_step` together. Make `ui_click` very short and quiet so they blend.
- The 5% random pitch variation in `AudioManager.play_sfx` keeps repeated sounds from feeling robotic. Do not bake variations into the files.

### Nice to have later (not wired yet)

`sfx_dialogue_blip.ogg` (a soft blip per typewriter letter, 0.02 s), `sfx_hammer_swing.ogg`, `sfx_spark.ogg`, `sfx_deal_barter.ogg`. Ask for the 3-line wiring when you have them.

---

## 3. Music list (5 tracks, all wired)

| File | Played when | Loop | Length |
|---|---|---|---|
| `music_workshop_loop.ogg` | Menu, tutorial, morning, workshop | Yes | 16 bars, about 25 s at 155 BPM |
| `music_minigame_loop.ogg` | While a minigame runs (crossfades from the workshop loop in 1 s) | Yes | **Same tempo, key and bar count** as the workshop loop |
| `music_night_summary.ogg` | Night summary; also used for the Day 30 "timeout" ending | Yes | 4 bars, about 6 s |
| `music_victory_sting.ogg` | Victory | No | 2 to 4 bars |
| `music_seizure_sting.ogg` | Seized by the syndicate | No | 2 to 4 bars |

Because the workshop and minigame loops share tempo, key and bar count, the crossfade lands musically. **Do that first, before anything else.**

---

## 4. Music recipe: "didgeridoo meets cyberpunk" in BeepBox

### 4.1 The sound idea

A **didgeridoo (yidaki)** has three signature features. Each one maps to something BeepBox can do:

| Didgeridoo trait | How to fake it |
|---|---|
| Constant low **drone** (about D2) with a buzzy, hollow timbre | A very low sustained note, harmonics-rich waveform, low-pass filtered |
| **Rhythmic "wob"**: the player pulses the sound with the tongue and cheeks | Draw the drone as short repeated notes in a **3-3-3-3-4 groove** with volume accents |
| **"Toot" overtone**: a sudden high bark, about a 12th above the drone | A short bright note on the off-beats, a perfect 12th above (D drone, A above) |
| **Breath / circular breathing** | A quiet filtered-noise "shh" on 16ths that never fully stops |

Then add the **Cyberpunk 2077** side (heavy industrial electronics, big dark synth bass, rapid hi-hats, metallic hits, tense minor/Phrygian harmony). I am describing the *style family* only, not copying any piece.

### 4.2 Song settings (set once, same for all loops)

| Setting | Value | Why |
|---|---|---|
| Tempo | **155 BPM** (try 150 to 160) | Spec says 150 to 160, high-energy |
| Key | **D** | Matches the drone range of a real didgeridoo |
| Scale | **Minor**, or **Phrygian** if your version has it (the flat 2nd, E-flat, gives the dark sting) | Tense, dark |
| Beats per bar | **4** | 4/4 |
| Rhythm | **÷4** (16th-note grid) | The 3-3-3-3-4 groove needs 16ths |
| Song length | **16 bars** (loop the whole song) | About 25 s at 155 BPM |

Layout: **5 pitch channels + 2 noise (drum) channels** if your BeepBox version allows it (the standard site shows 4 pitch + 1 noise; add channels with the "+" in the channel area, or use a mod such as JummBox if you want more).

> **Version note.** BeepBox has several versions and forks (BeepBox 3.x/4.x, JummBox, UltraBox, GoldBox) and the names of instrument types and effects differ a little. Where I name an option, a **fallback** is given. If a name does not exist in your version, use the fallback.

### 4.3 The 16-step groove (used by drums and drone)

One bar = 16 steps. `x` = hit.

```
step:        1 . . 4 . . 7 . . 10. . 13. . .
Kick:        x . . x . . x . . x . . x . . .      (3-3-3-3-4 "tresillo" groove)
Snare/clap:  . . . . x . . . . . . . x . . .      (steps 5 and 13, beats 2 and 4)
Closed hat:  x . x . x . x . x . x . x . x .      (8ths, Workshop)  /  all 16ths (Minigame)
Open hat:    . . . . . . . . . . . . . . x .      (step 15, lift into the next bar)
Drone wob:   x . . x . . x . . x . . x . . .      (same hits as the kick, with volume accents)
```

The drone follows the kick groove. That gives the "didgeridoo pulse" and keeps the track driving.

### 4.4 Channels (build in this order)

**Channel 1: "Yidaki" drone (the signature)**
- Instrument type: **Harmonics** (fallback: **Chip wave** "sawtooth" or "rounded").
- Pitch: **D2** (very low). Notes follow the drone-wob line above, 1 step long, tied with tiny gaps.
- Harmonics: strong 1st and 2nd harmonics, bump at the 3rd and 8th to 10th (hollow "formant"), remove the highest ones.
- Filter: **low-pass around 900 to 1500 Hz**, medium resonance. If your version has filter envelopes, set the cutoff envelope to a slow "wibble" / tremolo type at about 1/8-note rate to get the "wah" of a mouth opening and closing. Fallback: no filter envelope, instead alternate note volumes between 100% and 60% every step.
- Vibrato: **light/delayed** (it should wobble a little late in each note).
- Transition: **slide** or "normal"; Chord: **simultaneous** off.
- Volume: loudest of the melodic channels.

**Channel 2: "Toot" overtone**
- Instrument: **FM** (fallback: Chip wave "square" or pulse 25%).
- Pitch: **A3** (a 12th above D2), occasionally **D4**.
- Pattern: short staccato notes on steps 3 and 9 (off-beats) with a rest every other bar so it feels played by a person.
- Envelope: very short decay (a "bark"), a touch of pitch slide up at the start if available.
- Volume: medium-low, brighter than the drone.

**Channel 3: Reese / dark bass (Minigame loop only, silent or very quiet in Workshop)**
- Instrument: **Supersaw** if available, otherwise **Chip wave "sawtooth" with Chorus on** and a small detune.
- Pitch: **D1 / D2** following the chord table below.
- Effects: **Distortion** medium, **Chorus** on, low-pass at about 700 to 1000 Hz. Fallback: no distortion, use "double saw" chip wave.
- Pattern: same kick groove, long notes on the first hit of each chord.

**Channel 4: Pad / drone texture (both loops)**
- Instrument: **FM** with a slow attack or a **Harmonics** pad.
- Notes: whole-bar chords, two notes (root + fifth).
- Effects: **Reverb** up high, **Echo** low. Volume low, it only fills space.

**Channel 5: Arpeggio (Minigame loop only)**
- Instrument: **Pulse width** 25% (fallback: Chip wave "square").
- Notes: 16th-note arpeggio of the chord using the **Chord = Arpeggio** option, or hand-written 1-step notes.
- Octave: D4 to D5.
- Effects: light **Echo**. Volume low-medium.

**Noise channel A: Drums** (Drumset instrument; fallback: Noise type "retro" for each hit)
- Kick: sub-heavy, fast pitch drop. Snare/clap: short noise + a tone. Closed/open hats: high noise, very short.
- Add a **metal hit** (FM bell or hat with long decay) on step 1 of every 4th bar for the industrial feel.
- Workshop loop: **kick + closed hat 8ths only**, no snare.
- Minigame loop: **kick + snare + 16th hats + open hat**.

**Noise channel B: Breath (both loops)**
- Instrument: **Spectrum** (fallback: Noise type "shine" or "hollow").
- 16th-note "shh", volume low and slightly varied. This is the circular-breathing layer.

### 4.5 Chord progression (16 bars)

All bars use the 16-step groove. Root note for drone, bass and pad:

| Bars | Chord | Notes (root-fifth) |
|---|---|---|
| 1 to 4 | **Dm** | D - A |
| 5 to 6 | **B-flat** | B♭ - F |
| 7 to 8 | **C** | C - G |
| 9 to 12 | **Dm** | D - A |
| 13 to 14 | **E-flat** (the dark Phrygian sting) | E♭ - B♭ |
| 15 | **A** | A - E |
| 16 | **A** with a snare roll | A - E, then loops back to Dm |

If it sounds too busy, keep the drone on **D only** through the whole song and change only the bass and pad. A real didgeridoo is one drone: that constraint also gives the style.

### 4.6 The two loops

| Layer | Workshop (calm) | Minigame (intense) |
|---|---|---|
| Yidaki drone | Yes, accent volume lower | Yes, full |
| Toot | Yes, every other bar | Yes, every bar |
| Reese bass | Off | **On** |
| Pad | **On** (louder) | On (quieter) |
| Arpeggio | Off | **On** |
| Kick | Soft | Hard |
| Snare | Off | **On** |
| Hats | 8ths | 16ths + open hat |
| Breath | Quiet | Louder |

Save one BeepBox song, then **duplicate it** and mute/unmute channels to make the second one. Keep tempo, key, bars and chords identical so the crossfade is seamless.

### 4.7 Short tracks

- **Night summary (4 bars):** same key, tempo halved feel (play the pad and a single arpeggio, no drums). Notes: Dm, B♭, C, Dm. End on a long Dm so a loop point is not noticeable.
- **Victory sting (2 to 4 bars, no loop):** D major lift (D, F#, A), the toot rising an octave, one big metal hit and a reverb tail.
- **Seizure sting (2 to 4 bars, no loop):** D minor with E♭ (the Phrygian clash), distorted bass hit, low drone dying out, a heavy metal hit.

---

## 5. Exporting and importing the music

1. In BeepBox, set the **loop** markers (the song loops from bar 1 to 16 by default).
2. Export: **Export > .wav**. Use "Intro once, loop forever" **off**; export 1 full pass.
3. Open the WAV in Audacity, trim to **exactly** the bar boundaries (16 bars at 155 BPM is `16 x 4 x 60 / 155 = 24.77 s`). If a reverb tail crosses the loop point, copy that tail onto the start of the loop so it wraps cleanly.
4. Convert to OGG mono 96 kbps (see section 1).
5. In Godot: select the `.ogg` in the FileSystem dock > **Import** dock > tick **Loop** > **Reimport**. Do **not** loop the stings or the SFX.
6. Test the crossfade: start a day (workshop loop), press a part (minigame loop). It should feel like one piece of music getting heavier.

## 6. Mixing

| Bus | Level |
|---|---|
| Music | -8 dB relative to SFX at default settings |
| SFX | 0 dB, with `ui_click` quiet |
| Player sliders | Already in the Settings menu (music and SFX are separate) |

## 7. Checklist

1. All names match exactly (case and underscores).
2. Loops reach their end with no click or gap.
3. Workshop and minigame loops are the same tempo and key.
4. SFX are short and not tiring after 50 repeats.
5. Total audio size under about 3 MB (the whole web build budget is 25 MB).
