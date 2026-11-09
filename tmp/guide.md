# The Settings Panel: A Build-It-Yourself Guide

This guide combines the step-by-step plan and the settings ideas into one document. It uses your existing `global` autoload, so you don't need another singleton. It tells you what to build, what to learn, and how to check each step, but you write the code. Paste your attempts whenever you're stuck and I'll review them.

---

## 0. The big picture

The design has three layers, and each only talks to its neighbor:

```
Settings panel (UI)  ──sets values──▶  Global (data + apply + save)  ──applies──▶  Engine
        ▲                                          │
        └─────────── "changed" signal ─────────────┘
```

- The **UI** never touches `DisplayServer` or `AudioServer` itself. It only asks Global to change a value.
- **Global** stores the value, applies it to the engine, saves it, and announces that it changed.
- Everything that cares (the panel's rows, the volume button on the main menu, your gameplay code) listens for that announcement.

Because of this, the same panel works in the main menu and the pause menu, and the volume button and the panel can never disagree.

---

## 1. Decide where the settings live (no new singleton)

You have one autoload and want to keep it that way. Your realistic options:

**A. Put everything straight into `global.gd`.** Fine to start, and it's the fastest. The downside is that the script gets long and mixes unrelated things (respawning objects, audio buses, saving).

**B. Make a small settings class and let Global own one instance.** Write a separate script with a `class_name` that extends `RefCounted` (or `Resource`). It holds the values, applies them, and saves them. In `global.gd` you create one instance and expose it as a variable, so the rest of the game calls something like `Global.settings.…`. You still have exactly one autoload, but the settings code lives in its own file.

I'd start with B if you're comfortable with classes, and A otherwise. Moving from A to B later is just cut and paste.

One catch: a `RefCounted` isn't a Node, so it can't use `_notification`, create a `Timer` as a child, or call `get_tree()`. Think about which of the later steps need that and how Global could help (for example, Global forwards the focus and close notifications to it).

**Questions to answer before you code:**
- Which of the two options fits how much you want to learn right now?
- Should signals live on Global, or on the settings object? (If the settings object has the signal, who connects to it?)

---

## 2. Step 1: Data, defaults, and the schema

**Goal:** a place that stores every setting's current value, with defaults, before any UI exists.

**Concepts:** `Dictionary`, constants, signals with parameters.

**Do this:**
1. Make a dictionary of defaults. Think about which type each value should be. For choices like window mode, an **index** (0, 1, 2) is easier to wire to arrow buttons than strings like `"fullscreen"`. Your current `match mode_type` on strings works, but ask yourself how a `< Windowed >` selector would turn its position into a string, and whether an index plus a list of option names is simpler.
2. Write a getter and a setter. The setter should do three things in order: store the value, apply it, then emit a signal that carries the key. Make it do nothing if the value didn't change, and think about why that matters when sliders fire constantly.
3. Add a signal like `changed(key)`.

**The schema idea (this is what makes the UI easy later):** besides the values, keep a list that *describes* each setting. Each entry is a dictionary. Decide which fields it needs. A good starting set:

- the key, the label shown to the player, and the tab it appears on
- the kind of control (choice, slider, or toggle)
- the default value
- for choices: the list of option names. For sliders: min, max, and step
- optionally, a condition for when it's enabled (for example, window size only matters in windowed mode)

If you build the UI by looping over this list, adding a new setting later takes one entry and no new scene work. Notice that the defaults dictionary could even be generated from the schema, so you only define each default once.

**Checkpoint:** from your main menu's `_ready`, print a value, change it, and watch the signal fire. No UI needed.

---

## 3. Step 2: Make one setting really work

**Goal:** window mode, end to end.

You've already started this in `set_window_mode`. Some notes on it:

- It works, but a few options don't belong in a player-facing menu. **Minimized** would make the window vanish when the player picks it, and **maximized** is usually the same as windowed from a player's perspective. A typical list is windowed, fullscreen, and exclusive fullscreen. Decide what you want to offer.
- `Window.MODE_FULLSCREEN` isn't exclusive. It's a borderless window covering the screen. Test whether exclusive fullscreen actually looks different on your system. On some platforms they're nearly identical, and then offering both isn't useful.
- Look up what happens to the window **size** when you go back to windowed from fullscreen. You may need to set it yourself.
- Since it's a window property, compare `DisplayServer.window_set_mode` with `get_window().mode`. They do the same job, so decide which you prefer and use it everywhere.

**Windowed size:** pick a base resolution (yours is 640×360, and the scale options are whole multiples of it). Work out how a "2x" choice becomes a window size, and look up how to center a window after resizing it. Then think about **when it should be enabled**: choosing 3x while fullscreen means nothing.

**When settings get applied:** autoloads run before your first scene. So loading saved values and applying all of them in Global's `_ready` means the game starts in the player's chosen state. Make sure you apply *every* setting at startup, not only the ones the player just changed.

**Checkpoint:** a temporary key press cycles window mode, and it works from a fresh launch.

---

## 4. Step 3: Saving and loading

**Goal:** settings survive closing the game.

**Concepts:** `ConfigFile`, the `user://` path, notifications.

**Do this:**
1. Save values into a `ConfigFile` and load them at startup. Look at `get_value`'s third parameter, which is a default. Think about what happens when you ship an update with a *new* setting: an old save file won't contain it. Loading should start from the defaults and overlay whatever the file has.
2. **Don't save on every change.** A slider drag changes the value dozens of times a second. Look up how to wait a short moment (a `Timer` or `get_tree().create_timer`) and save once after the changes stop.
3. Also save when the window is closing. Look up `NOTIFICATION_WM_CLOSE_REQUEST` and where a notification handler needs to live.

**Checkpoint:** change a few values, quit, relaunch, and confirm they stuck. Then delete the file from `user://` and confirm defaults return. (In the editor, **Project → Open User Data Folder** opens it.)

---

## 5. Step 4: The popup shell

**Goal:** an empty, animated popup that opens and closes cleanly, which every panel in your menu (not just settings) can reuse.

**Structure to build (as a scene):**

- A root Control set to full rect
- A full-screen dim `ColorRect` (semi-transparent black)
- A centered window (`PanelContainer`) with margins inside it
- Inside: a header row (a heading label and a close button) above a content container

**Things to get right:**
- **Blocking clicks:** the dim layer must stop mouse input to the menu behind it (look at `mouse_filter`). It can also close the panel when clicked.
- **Size:** 384×240 on a 640×360 base is a good fit. It's a multiple of 8, it leaves a clear dim frame around the window, and it fits five 24px rows plus tabs, a header, and a footer button. Set it with a custom minimum size so tabs of different heights don't resize the window.
- **Animation:** reuse what you learned on the title: scale up from about 0.85 with a back-ease, fade in, and play the reverse on close. Remember `pivot_offset` must be the center, and it only has the right value after the layout has run (what does `await get_tree().process_frame` do for you here?).
- **Closing:** the close button, a click on the dim, and the `ui_cancel` action. Look up `set_input_as_handled`, and think about what happens in the pause menu if Escape closes *both* panels at once.
- **Focus:** give the close button focus on open, so keyboard and gamepad players land somewhere sensible.
- **Reuse:** make this a scene you can **inherit** (New Inherited Scene), so Settings, Levels, and Achievements each add their own content.

**Checkpoint:** a test button opens and closes it smoothly, and it works fast-clicked (opening, then closing mid-animation). What should happen to the running tween?

---

## 6. Step 5: Rows and controls

**Goal:** controls that edit settings and always show the real value.

**Build one row by hand first.** Use a Label and an `HSlider` for master volume.

**The rule that prevents most bugs:** the UI should never be the source of truth. The flow is *control changes → Global's setter → signal → UI refresh*. Two details:

- When the panel refreshes a slider from the stored value, that must not trigger the slider's own change signal, or you create a loop. Look up `set_value_no_signal`.
- Each time the panel opens, refresh every control from the current values, in case something else changed them (like the volume button).

**Then the other two control types:**
- **Choice:** two buttons (`<` and `>`) and a label. Think about wrap-around: what's the nicest math for going from the last option to the first? (Look up `posmod`.)
- **Toggle:** a toggle-mode button that reads ON or OFF. Look up `set_pressed_no_signal`.

**Only after all three work by hand**, consider generating rows by looping over your schema from Step 1. The three control types become three small builder functions, and the "enabled when" condition becomes a check each time you refresh. You'll see why the schema was worth writing.

**Tabs:** `TabContainer` titles its tabs from each child's node name. Keep each tab to **five rows or fewer** so the window size stays fixed. If you ever need more, look at `ScrollContainer`.

**Styling:** make one `Theme` resource (font, button, slider, tab styleboxes), set it on the panel root, and every control inherits it. Use Nearest filtering, whole-number font sizes, and 9-slice textures with whole-pixel margins.

**Checkpoint:** change a setting by clicking, by keyboard, and from code elsewhere. In all cases the panel should end up correct.

---

## 7. Step 6: Connect it to the rest of the game

**Main menu**
- Connect your settings icon to the panel's open function.
- Your volume button and the panel's "mute all" must stay in sync. The button should set the shared value, and it should *listen* for the change signal to update its own pressed state (without re-emitting its signal).
- Decide what the intro animations and the title bob do when "reduced motion" is on.

**Pause menu (reusing the same scene)**
- When `get_tree().paused` is true, nodes with the default process mode stop, including their input handling and tweens. Look up `process_mode`, and which nodes need `Always`.
- A tween bound to a node follows that node's process mode. That's why setting the panel root to always-process is enough.
- Think about what should receive focus when the panel closes, so a controller player isn't stranded.

**Gameplay**
- Settings only matter if the game reads them. Find the place where screen shake is applied. How would it use a 0–100 setting? Where does the "reduced motion" check belong?

---

## 8. The settings catalog

Pick what suits your game. Difficulty is rough.

### Display
| Setting | You'll learn | Level |
|---|---|---|
| Window mode, window size, V-Sync, FPS limit | `Window.mode`, `DisplayServer`, `Engine.max_fps` | Easy |
| FPS counter | a CanvasLayer overlay driven by a setting | Easy |
| Monitor selection | listing screens, `window_set_current_screen` | Medium |
| Brightness | a full-screen shader or `WorldEnvironment` adjustment | Medium |
| CRT / scanline filter (toggle + strength) | canvas_item shaders with a uniform driven by a setting; it suits pixel art | Medium |

### Audio
| Setting | You'll learn | Level |
|---|---|---|
| Master, music, effects volume | the Audio tab, buses, `AudioServer`, `linear_to_db` | Easy |
| Mute all, mute when unfocused | `NOTIFICATION_APPLICATION_FOCUS_OUT` | Easy |
| Separate UI sounds bus | creating a bus and routing players to it | Easy |
| Audio preview when you release a slider | `drag_ended`, a one-shot player | Easy |

### Game and accessibility
| Setting | You'll learn | Level |
|---|---|---|
| Screen shake intensity | your own code reading a setting | Easy |
| Reduced motion | one setting checked in many places | Easy |
| Reduced flashing | making effects conditional | Easy |
| Assist options (jump forgiveness, damage taken, extra health) | turning gameplay constants into settings | Medium |
| Speedrun timer toggle | HUD elements shown by a setting | Easy |
| Hold vs. toggle for actions | reading input two ways | Medium |
| Colorblind mode | a shader that remaps colors | Hard |
| Language | `TranslationServer.set_locale()`, `tr()`, CSV translations | Medium |

### Controls
| Setting | You'll learn | Level |
|---|---|---|
| Key rebinding | `InputMap`, `InputEventKey`, waiting for the next key press, saving events | Hard, but a great exercise |
| Controller vibration + strength | `Input.start_joy_vibration` | Easy |
| Stick deadzone | action deadzones | Easy |

### Data and misc
| Setting | You'll learn | Level |
|---|---|---|
| Reset to defaults | looping your schema | Easy |
| Revert countdown ("keep these display settings? 10…") | timers and confirmation dialogs | Medium |
| Delete save data (with confirmation) | `ConfirmationDialog`, `DirAccess` | Medium |
| Open save folder | `OS.shell_open`, `ProjectSettings.globalize_path` | Easy |
| Version and credits | reading the project version setting | Easy |

---

## 9. A good build order

1. **Foundation:** Steps 1 to 3, with just window mode working, saved and loaded.
2. **Shell:** Step 4, the empty popup, then Step 5 with one slider row.
3. **First batch of settings:** window size, V-Sync, FPS limit, the three volumes, and mute. They use every part of the system.
4. **Wire it up:** Step 6, the main menu volume button, then the pause menu.
5. **Second batch:** reduced motion, screen shake, and mute when unfocused, which teach how settings reach other scenes.
6. **Milestone:** the CRT filter, to learn how a setting drives a shader.
7. **Last:** key rebinding.

---

## 10. Common traps

- **A missing audio bus:** `get_bus_index` returns `-1` for a name that doesn't exist. Check for it before using it.
- **Silent volume:** `linear_to_db(0)` is negative infinity. How will you handle a slider at zero?
- **Slider feedback loops** (see Step 5).
- **Saving too often** (see Step 3).
- **A dim layer that doesn't block clicks:** check `mouse_filter` on the dim and on every container above it.
- **Panels that stop working when paused:** `process_mode` (see Step 6).
- **Non-integer sizes:** fractional scales make pixel art uneven, and the same goes for window sizes. Stay on whole multiples.
- **Applying only on change:** if you don't apply every setting at startup, the saved values do nothing until the player touches them.

---

## How we'll work through it

Start with Steps 1 and 2: the data, getter and setter, and the signal in whichever structure you choose from Section 1. Paste what you've got, even if it's broken or half-done, and I'll tell you what to fix and why. If you want to reflect on your current `set_window_mode` first, I'm happy to start there.

Which structure are you going with, A or B?