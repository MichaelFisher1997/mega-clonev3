# Mega Clone v3 (Love2D)

A retro, Mega Bomberman-style game built with Love2D on a 16x16 tile grid. Tight tile-based movement, layered tilemaps, and classic bomb mechanics with clean, pixel-perfect rendering.

## Features
- 16x16 tile grid with precise 16x16 collision hitbox (sprite is 16x20, anchored at the feet)
- Pixel-perfect rendering and virtual resolution/letterboxing (desktop + mobile friendly)
- Layered tilemap rendering with overhead/overlay layers (player can walk under objects)
- Camera that follows the player
- Menu with:
  - Character select (auto-detects folders in `images/player/`, natural-sorted)
  - Level select (auto-detects modules under `maps/`)
- Player animation per row has 3 columns: left step (1), standing (2), right step (3)
- Bomberman-style bombs:
  - Place exactly on your current tile center
  - Bomb sprite renders as exactly 1 tile in size
  - Ticking uses a clear brightness flicker
  - Explodes in a cross (range 2), blocked by walls
  - Only one active bomb at a time (extensible later)
  - After you step off your bomb, it becomes solid and you cannot walk back over it

## Requirements
- Love2D 11.x (https://love2d.org/)
- Windows/macOS/Linux supported

## Getting Started
```bash
# Clone
git clone git@github.com:MichaelFisher1997/mega-clonev3.git
cd mega-clonev3

# Run (Linux/macOS)
love .
```
On Windows, you can drag the project folder onto `love.exe`, or run from a terminal:
```bat
"C:\\path\\to\\love.exe" .
```

## Controls
- Move: WASD or Arrow Keys
- Place Bomb: Space or Z
- Toggle Fullscreen: F
- Toggle Debug Overlay: F1 (only in debug builds)
- Menu: Esc

## Content (Characters & Levels)
- Characters
  - Put each character in `images/player/<character_name>/`
  - The loader will prefer `<character_name>_frame16x20.png`, or it will use the first `.png` it finds in the folder
  - Characters are listed using natural sort (e.g., 1, 2, 10 instead of 1, 10, 2)
- Levels
  - Place map modules under the `maps/` directory
  - Any file matching `Map*.lua` is auto-discovered recursively
  - Example: `maps/Level1/Map1.lua` is loaded as module `maps.Level1.Map1`

## Bomb & Explosion Assets
- Bomb image: `images/bombs/Bomb.png`
- Explosion image: `images/bombs/Explosion.png`
- Both are drawn pixel-perfectly and scaled to tile size

## Debug Overlay & Release Builds
There is a simple debug overlay that can be toggled at runtime and easily disabled for release.

- Toggle overlay at runtime: press `F1` (only when debug build is enabled)
- Coordinates display (top-right): shows player pixel X/Y and tile X/Y
- To disable for release: set `DEBUG_BUILD = false` near the top of `main.lua`

```lua
-- main.lua
-- Debug build toggle: set to false before releasing
local DEBUG_BUILD = true  -- change to false for release builds
```
When `DEBUG_BUILD` is false, the overlay and F1 hint are disabled and excluded from the build.

## Packaging / Distribution
- The standard Love2D approach applies:
  1. Zip the game contents (without the `.git` directory) and rename to `game.love`
  2. "Fuse" with platform Love2D binaries (Windows/macOS) or distribute `game.love` with Love2D installed
- See the official Love2D wiki for details: https://love2d.org/wiki/Game_Distribution

## Roadmap / Ideas
- Sound effects for ticking and explosion
- Player damage/death if caught in the blast
- Destructible blocks and chain reactions
- Power-ups (extra bombs, increased range, etc.)
- Additional polish for animations and transitions

## License
TBD.
