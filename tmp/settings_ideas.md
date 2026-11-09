Here are settings ideas, grouped by tab. Each one teaches you a different Godot concept, so I've noted what you'd learn and how hard it is. Since you're building the schema-and-autoload version, each is a small addition rather than a rewrite.

## Display

| Setting                                     | What you'll learn                                                           | Difficulty |
| ------------------------------------------- | --------------------------------------------------------------------------- | ---------- |
| Window mode, window size, V-Sync, FPS limit | `DisplayServer`, `Window.mode`, `Engine.max_fps`                            | Easy       |
| FPS counter                                 | a CanvasLayer overlay that reacts to a setting                              | Easy       |
| Monitor selection                           | `DisplayServer.window_set_current_screen`, listing screens                  | Medium     |
| Brightness                                  | a full-screen shader or `WorldEnvironment` adjustments                      | Medium     |
| CRT / scanline filter (toggle + strength)   | canvas_item shaders with a uniform driven by a setting. It suits pixel art. | Medium     |

## Audio

| Setting                         | What you'll learn                          | Difficulty |
| ------------------------------- | ------------------------------------------ | ---------- |
| Master / music / effects volume | `AudioServer`, buses, `linear_to_db`       | Easy       |
| Mute all, mute when unfocused   | `NOTIFICATION_APPLICATION_FOCUS_OUT`       | Easy       |
| Separate UI sounds volume       | adding a bus and routing nodes to it       | Easy       |
| Audio preview on slider release | `drag_ended`, one-shot `AudioStreamPlayer` | Easy       |

## Game and accessibility

| Setting                                                       | What you'll learn                                          | Difficulty |
| ------------------------------------------------------------- | ---------------------------------------------------------- | ---------- |
| Screen shake intensity                                        | your game code reading a setting                           | Easy       |
| Reduced motion (stops title bob, shakes, flashes)             | one setting checked in many places                         | Easy       |
| Flash warning / reduced flashing                              | making effects conditional                                 | Easy       |
| Assist options (jump forgiveness, damage taken, extra health) | exposing gameplay constants as settings                    | Medium     |
| Speedrun timer toggle                                         | HUD elements shown or hidden by a setting                  | Easy       |
| Hold vs. toggle for actions                                   | reading input two different ways                           | Medium     |
| Colorblind mode                                               | a shader that remaps colors                                | Hard       |
| Language                                                      | `TranslationServer.set_locale()`, `tr()`, CSV translations | Medium     |

## Controls

| Setting                                | What you'll learn                                                          | Difficulty                 |
| -------------------------------------- | -------------------------------------------------------------------------- | -------------------------- |
| Key rebinding                          | `InputMap`, `InputEventKey`, waiting for the next key press, saving events | Hard, but a great exercise |
| Controller vibration on/off + strength | `Input.start_joy_vibration`                                                | Easy                       |
| Stick deadzone                         | action deadzones, `InputMap.action_set_deadzone`                           | Easy                       |

## Data and misc

| Setting                                               | What you'll learn                                 | Difficulty |
| ----------------------------------------------------- | ------------------------------------------------- | ---------- |
| Reset to defaults                                     | looping your schema                               | Easy       |
| Revert countdown ("keep these display settings? 10…") | timers and confirmation dialogs                   | Medium     |
| Delete save data (with confirmation)                  | `ConfirmationDialog`, `DirAccess`                 | Medium     |
| Open save folder                                      | `OS.shell_open`, `ProjectSettings.globalize_path` | Easy       |
| Version and credits                                   | `ProjectSettings.get_setting` for the version     | Easy       |

## A good order to build them in

1. **First batch:** window mode, window size, V-Sync, FPS limit, and the three volume sliders. They exercise everything in the guide (autoload, signal, apply, save), and the logic for the rest is the same.
2. **Second batch:** reduced motion, screen shake, and mute when unfocused. They teach how a setting affects code in other scenes.
3. **Then a milestone:** the CRT filter, to learn how a setting drives a shader.
4. **Last, key rebinding:** it's the hardest and also the most useful to understand. Do it after the rest feels natural.