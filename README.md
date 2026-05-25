# 番茄钟 · Pomodoro Timer

A native macOS Pomodoro timer. As the session counts down, the tomato's red body fills with green from the bottom up — when the body is fully green, your focus block is over.

<p align="center">
  <img src="assets/tomato-progress-demo.png" alt="Tomato about halfway through a focus session — bottom half of the body has turned green" width="320">
</p>

## How the visual works

The character is a single static image. Each frame of the timer, the app draws the red base, then overlays a green-bodied copy clipped to a rectangle that grows upward from the bottom of the body.

- **Linear with time** — the clip's height = `body_height × elapsed / total`, so the green/red boundary rises at a constant rate.
- **Bounded to the body** — the clip stops exactly at the top of the round body (just under the leaves), so the leaves stay their natural green throughout and the body finishes turning green **precisely** when the timer hits 00:00.
- **Reset between modes** — focus → short break → long break each restart from full red.

Body extent (red pixel bbox `y = 0.246..0.908`) was measured directly from the source PNG and is the only "magic number" in `StaticTomatoView`.

## Features

- Native macOS app (Swift / AppKit) — single self-contained `.app`, no runtime dependencies
- Focus / short break / long break modes with auto-advance after every 4 focus blocks
- Configurable durations via the in-app settings sheet
- macOS notifications + system beep on session completion
- Bonus: a Python CLI (`pomodoro.py`) and a Tkinter GUI (`pomodoro_gui.py`) variant for terminal lovers

## Requirements

| Use case | Requirement |
|----------|-------------|
| **Run** the prebuilt `.app` | macOS 12+ |
| **Build** the `.app` from source | macOS 12+, Xcode command-line tools (`swiftc`), Python 3.10+ with Pillow (only for asset processing during build) |
| Run the Python CLI / Tkinter GUI | Python 3.10+, no extra packages |

## Build

```bash
# One-time: install the only build-time Python dependency
pip install pillow

# Build the .app — that's it
./build_mac_app.sh
# → output/番茄钟.app
```

Now open `output/番茄钟.app` (double-click in Finder, or `open output/番茄钟.app`). The built `.app` is self-contained — Python is **not** required to run it.

## Project Structure

```
pomodoro-mac/
├── src/
│   └── PomodoroNative.swift           # Native macOS app (AppKit + UserNotifications)
├── scripts/
│   ├── prepare_tomato_sprite.py       # Generates GIF preview + .icns app icon at build time
│   └── GenerateTomatoIcon.swift       # Alternate icon generator
├── assets/
│   ├── tomato-static.png              # Red base image used by the timer view
│   ├── tomato-static-green.png        # Green-body variant for the fill overlay
│   ├── tomato-run-sequence.png        # Legacy 8-frame sprite (kept for icon generation)
│   └── tomato-progress-demo.png       # Demo image used in this README
├── pomodoro.py                        # Terminal Pomodoro timer (CLI)
├── pomodoro_design.py                 # Shared design constants and helpers
├── pomodoro_gui.py                    # Tkinter GUI timer
├── test_pomodoro.py                   # Unit tests
└── build_mac_app.sh                   # One-step build script
```

## Optional: Python CLI

If you don't want the GUI, the same Pomodoro logic ships as a terminal script:

```bash
python3 pomodoro.py                          # 4 × 25-minute sessions, 5-minute breaks
python3 pomodoro.py -w 50 -s 10 -l 30 -n 6   # Custom schedule
python3 pomodoro.py --dry-run                # Preview the schedule without waiting
```

## Optional: Tkinter GUI

```bash
python3 pomodoro_gui.py
```

## Tests

```bash
python3 -m pytest test_pomodoro.py -v
# or
python3 -m unittest test_pomodoro
```

## License

MIT
