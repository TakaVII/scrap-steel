# Dialogue guide (Batch B)

All scenes live in **Scripts/Utils/story_data.gd** (structure) and **Data/translations.csv** (text).

## Change a line of text
1. Find its key in `story_data.gd` (e.g. `DLG_J1`).
2. Edit the `en`, `es`, `ar` cells of that key in `Data/translations.csv`, then Reimport the CSV.

## Add a line to a scene
Add a `_say(who, "NEW_KEY")` entry to the scene's array in `story_data.gd`, then add the key to the CSV (all 3 languages).
`who` = `&"narrator"`, `&"player"` or a client id from `client_roster.gd` (`&"mara"`, `&"kane"`...). Mood = `&"happy"`, `&"unhappy"`, `&"neutral"` (needs `Portraits/<id>_<mood>.png`, falls back to neutral).

## Beats
| Builder | What it does |
|---|---|
| `_say(who, key, vars, mood, act)` | A spoken line. `{placeholders}` in the text are filled from `vars` (use `v` for the shared run values). |
| `_pause(0.5)` | A silent beat (a click skips it). Use it before a reveal. |
| `_choice([_opt(...), _opt(...)])` | The player picks a reply (mouse or keys 1-3). The chosen text is spoken by the player, then the option's `then` lines play. |
| `_choice([...], true)` | Topic menu: comes back after each reply without the used option, until an option created with `_opt(key, [], true)` (exit) is picked. |
| `_act(&"shake")` / `_act(&"sfx", "stamp")` | Side effect without a line. |

Extra keys on a `_say` dictionary: `d["fx"] = &"shake"`, `d["cps"] = 30.0` (typing speed), `d["auto"] = 2.5` (auto-continue after N seconds; a click still skips).

## Example
```gdscript
&"my_scene":
    return [
        _say(&"mara", "DLG_X1"),
        _pause(0.4),
        _choice([
            _opt("DLG_X_OPT_A", [_say(&"mara", "DLG_X_A")]),
            _opt("DLG_X_OPT_B", [_say(&"mara", "DLG_X_B", {}, &"unhappy")]),
        ]),
        _say(&"mara", "DLG_X2"),
    ]
```
Play it from code with `dialogue.play(&"my_scene", StoryData.sequence(&"my_scene"))`. In-game beats (Dax notes, installments, Day 12) are queued by `story_director.gd`.

## Tutorial flow (pathway_select.gd, unchanged)
prologue -> job_intro (Mara, 1 choice) -> guided Forge job -> job_done -> kane_intro (debt, interest, first installment; strikes and rent are optional topics) -> choose pathway -> path_*.
