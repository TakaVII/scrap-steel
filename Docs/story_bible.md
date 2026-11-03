# Story bible (Batch E)

One page. If a line you write does not fit this page, rewrite the line.

## The spine
You inherit a garage and a debt you did not make. Three acts, all told through the systems you already play.

| Act | Days | What changes | Beats that carry it |
|---|---|---|---|
| I. The Garage | tutorial - 8 | You learn the bench, then the debt. Kane is cold. | Prologue, Mara's bracket, Kane's speech, Day 8 first payment ("Adequate.") |
| II. The Climb | 9 - 22 | You pick a road and the city starts to know your name. Dax stops being a rumor. | Day 12 client, Dax note (Day 5, 15), Kane warms after each payment, Day 22 "it is personal now" |
| III. The Reckoning | 23 - 30 | The numbers decide. Kane is now invested. | Dax note (Day 25), debt cleared beat, Day 28 warning, endings |

## The two secrets (the reason to keep reading)
1. **Dax did not run from greed.** He borrowed to buy the bench for you, the kid he hired, then the interest frightened him. His three notes escalate: a rule (Day 5), a photo (Day 15), a confession (Day 25). Rule one is the FinLit lesson, written by the person who failed it.
2. **Kane vouched for Dax.** If the debt stays open it comes out of Kane's pocket. That is why he is cold at first, why he softens after each payment (INST_OK_8 -> 29), and why Day 22 changes the tone.

## Voices (say it in this voice or cut it)
| Who | Sounds like | Never |
|---|---|---|
| Kane | Short sentences, dry, formal. Facts first, feeling hidden under a fact. | Threatens loudly. Explains himself twice. |
| Mara | Welder: hands before words, dry jokes, calls you kid. | Lectures. |
| Sparky | Racer: jokes, exaggeration, a little too much. | Silence. |
| Zero | Few words, numbers, no warmth until it is earned. | Exclamation marks. |
| Talia | Engineer: precise, polite, brings logs. | Slang. |
| Gideon | Vain, slick, everything is about how it looks. | Admits fault. |
| Boris | Gruff, proverbs about steel and his grandfather. | Hurries. |
| Val | Impatient bounty hunter, orders instead of requests. | Small talk. |
| Ironhead | Arena champion, talks about himself in the third person. | Doubt. |
| Nyx | Soft, unsettling, treats pain as data. | Shouts. |
| Seraph-7 | Formal android. **No contractions.** Measures things. | Slang. |
| Mira | Surgeon: calm, clinical, mentions the patient. | Panic. |
| Juno | Fixer: rumors, favors, who vouches for whom. | Honesty without a price. |

## Writing rules used in this batch
1. **One concrete detail beats an adjective.** "Squeals again at 6k" not "disappointing performance".
2. **Subtext.** Kane says "I wrote it down so you do not have to" instead of "I am disappointed".
3. **Two sentences maximum per line** for clients; the player reads these in seconds.
4. **No lists of three, no "not X, it is Y", no em dashes** (the usual machine-writing tells).
5. **Reaction to quality is a joke or a stake**, never a review ("Porosity in the weld. You rushed it.").
6. Placeholders (`{debt}`, `{due}`...) are filled by `StoryData.vars()`: keep the same ones in all three languages.
7. Spanish and Arabic are machine-translated: keep the disclosure on the itch page; a native check of the Day 1 and Kane lines is the best use of one hour.

## How to add a beat
1. `story_data.gd`: add a `&"my_beat"` entry with `_say(...)` lines.
2. `translations.csv` (or a patch JSON like `translation_patch_v10.json`): add the keys in en, es, ar.
3. `story_director.gd`: enqueue it on a day or an event with `_enqueue(once_id, &"my_beat")`.
