# ToggleNotch

`togglenotch` is a small macOS CLI that hides or shows the MacBook notch by switching the built-in display between paired system display modes.

It does not draw an overlay or run a background process. When hiding the notch, it switches to the lower-height display mode below the camera area; when showing it, it restores the saved full-height mode.

## Usage

```sh
togglenotch status
togglenotch hide
togglenotch show
togglenotch toggle
togglenotch list
```

## Install

Install to a writable bin directory that is already in `PATH` when possible:

```sh
scripts/install.sh
```

On Apple Silicon Macs with Homebrew, this usually installs to `/opt/homebrew/bin/togglenotch`. If no writable common `PATH` directory is found, it falls back to `~/.local/bin/togglenotch` and prints a `PATH` warning.

Then run:

```sh
togglenotch status
togglenotch hide
togglenotch show
```

To install somewhere else:

```sh
PREFIX=/opt/homebrew scripts/install.sh
```

## How It Works

On notch MacBooks, macOS may expose paired display modes, for example:

```text
Full:   1512x982 logical, 3024x1964 pixels
Hidden: 1512x945 logical, 3024x1890 pixels
```

`togglenotch hide` finds the closest matching lower-height mode with the same width, scale family, and refresh rate. The previous mode is saved to:

```text
~/.config/togglenotch/state.json
```

`togglenotch show` restores that saved mode, or falls back to the matching highest-height mode.

## Compatibility

- Targets macOS notch MacBooks.
- Only controls the built-in display.
- External displays are ignored.
- Clamshell mode usually will not work because the built-in display is offline.
- Macs without notch-style paired display modes are reported as unsupported.

## Development

```sh
swift build
swift test
swift run togglenotch status
```
