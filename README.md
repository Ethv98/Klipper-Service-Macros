# 🔧 Klipper Toolhead Service & Nozzle-Change Macros

This repository provides a set of Klipper macros that automate and
simplify common 3D-printer maintenance tasks, including nozzle changes,
cold swaps, and general toolhead servicing. The macros park the toolhead
front-and-center for easy access, guide the user through each step with
on-screen prompts, and handle movement, retraction, LED control, and
heater management automatically.

## ✨ Features

-   **One-click toolhead servicing**\
    Automatically homes the printer, lifts Z, and parks the hotend in an
    ideal service position.

-   **Fully guided workflow**\
    Integrated UI prompts walk the user through each step of swapping or
    servicing a nozzle.

-   **Safe & consistent nozzle changes**\
    Supports both **hot nozzle swaps** and **cold swaps**, depending on
    your workflow.

-   **Automatic printer state management**

    -   Turns heaters on/off based on settings\
    -   Retracts filament\
    -   Locks steppers\
    -   Restores temps afterward\
    -   Returns LEDs to their previous color

-   **Centralized settings file**\
    All service behavior is controlled through `ServiceSettings.cfg` for
    easy customization.

-   **LED support**\
    Temporarily sets work lighting to bright white and restores your
    existing setup afterward.

## 🧩 Macro Overview

### SERVICE_START

Prepares the printer for maintenance: - Optional heater shutdown\
- Homing and safe Z-lift\
- Moves XY to service position\
- Optional filament retraction\
- Turns LEDs white\
- Displays start prompts

### SERVICE_END

Restores the printer to a ready state: - Re-homes if configured\
- Restores LEDs\
- Restores previously-used temps\
- Clears internal service flags

### NOZZLE_SWAP

A fully guided hot-nozzle change: - Calls `SERVICE_START`\
- Prompts user to heat, loosen, and install new nozzle\
- Optional tightening heat cycle\
- Calls `SERVICE_END`

### COLD_SWAP

Nozzle change without heating: - Guides user through cold removal and
installation\
- Uses same park & restore logic as other macros

## ⚙️ Configuration

All user-adjustable settings---service position, speeds, heaters,
lighting, retraction, and optional behaviors---are stored in:

    ServiceSettings.cfg

## 📥 Installation

1.  Copy both `.cfg` files into your Klipper configuration folder.\
2.  Add the following include lines to your `printer.cfg`:

```{=html}
<!-- -->
```
    [include ServiceSettings.cfg]
    [include ServiceMacros.cfg]

3.  Restart Klipper.\
4.  Run macros from the UI: `NOZZLE_SWAP`, `COLD_SWAP`, `SERVICE_START`,
    `SERVICE_END`.

## 🙌 Contributions

Pull requests and improvements are welcome.
