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

## 🧩 ServiceSettings.cfg --- Variable Reference Table

  --------------------------------------------------------------------------
  **Setting**                      **Description**
  -------------------------------- -----------------------------------------
  `service_x`                      X-coordinate where the toolhead parks for
                                   servicing.

  `service_y`                      Y-coordinate where the toolhead parks for
                                   servicing.

  `z_clearance`                    Z height lifted before XY moves to avoid
                                   collisions.

  `home_speed`                     Speed used when homing the printer.

  `travel_speed`                   Speed used for XY travel during service
                                   moves.

  `cooldown_on_start`              Automatically cools down hotend/bed at
                                   the start of service.

  `restore_temps_on_end`           Restores previously used temperatures
                                   when service ends.

  `tightening_temp`                Temperature used for tightening a new
                                   nozzle during a hot swap.

  `retract_before_service`         Retracts filament before servicing if
                                   enabled.

  `retract_length`                 Amount of filament retraction performed
                                   before service.

  `extruder_hold`                  Locks extruder motor during service to
                                   prevent movement.

  `service_leds`                   Enables LED color changes during service
                                   routines.

  `service_led_color`              LED color used during service (commonly
                                   bright white).

  `led_restore_delay`              Delay before restoring original LED color
                                   after service.

  `enable_hot_swap`                Enables guided hot-nozzle replacement
                                   workflow.

  `enable_cold_swap`               Enables guided cold-nozzle replacement
                                   workflow.

  `pause_for_steps`                Shows UI prompts that pause and guide
                                   each step.

  `lock_steppers_during_service`   Keeps steppers locked to prevent drifting
                                   during service.

  `require_homing`                 Ensures homing is performed before moving
                                   to service position.

  `safe_approach_x`                Optional safe intermediate X position to
                                   avoid clips/obstacles.

  `safe_approach_y`                Optional safe intermediate Y position for
                                   collision-free approach.

  `wait_for_cooldown`              Waits until nozzle cools to a safe
                                   temperature before service begins.
  --------------------------------------------------------------------------

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
