# stunning-memory

SmartThings Edge Zigbee driver for the IKEA GRILLPLATS Plug

[View the Korean document](README.md)

## Matter Driver

For a device paired through Matter over Thread, use the dedicated `matter-ikea-grillplats-plug` driver.

- On and off
- Power: `W`
- Voltage: `V`
- Current: `A`
- Cumulative energy: `Wh`

Verified on the hub: power `146.3 W`, voltage `227 V`, current `0.663 A`, and energy `39 Wh`.

This requires pairing the Matter device and selecting the Matter driver; it is separate from the Zigbee driver.

## Important: Enable Zigbee Mode

This driver is **only for the Zigbee mode of the IKEA GRILLPLATS Plug**.
It does not work with a Wi-Fi or cloud-connected device.

1. Make sure the SmartThings Station hub is online.
2. Open the invitation link below in the SmartThings app or on your phone.
3. Accept the channel invitation and install `IKEA GRILLPLATS Plug Power` on the hub.
4. Change the existing device driver to `IKEA GRILLPLATS Plug Power`.
5. Check that switch state, current, power, and voltage are shown on the device screen.

Invitation link: <https://bestow-regional.api.smartthings.com/invite/Y7236AZwknMr>

If the device still appears as `Generic Dimmer` or remains `NONFUNCTIONAL`,
remove the existing device, pair it again in Zigbee mode, and select the new driver.

## How to Enable Zigbee Mode on GRILLPLATS

GRILLPLATS is sold primarily as a Matter over Thread product. Zigbee mode is a hidden compatibility mode and is not shown in the normal official setup flow.
The sequence may vary by firmware.

1. Plug the device into a power outlet.
2. Press and hold the plug's power button for about 10 seconds to factory-reset it.
3. Wait until the red LED flashes and the reset finishes. Some units show a white LED after the red LED.
4. Quickly press the button 8 times.
5. Start Zigbee device discovery on the SmartThings Station and select `IKEA GRILLPLATS Plug Power`.

If the device is not discovered after eight presses, try the alternate sequence reported for some firmware: `press 4 times quickly, then press 8 times quickly`.
Keep discovery running after the button sequence and remove any previous Matter pairing first.

This is an unofficial compatibility path rather than IKEA's normal Matter setup procedure.
Depending on the model and firmware, Zigbee mode may not expose current, voltage, or power-measurement clusters.

References:

- <https://www.zigbee2mqtt.io/devices/E2435.html>
- <https://www.ikea.com/se/sv/p/grillplats-stickpropp-smart-60604238/>

## Purpose

This is a dedicated SmartThings Edge driver for the IKEA `GRILLPLATS Plug`.
It is intended to avoid incorrect matching as a generic dimmer and to help recover devices shown as `NONFUNCTIONAL`.

## Supported Features

- Turn on
- Turn off
- Actual switch state reporting
- Manual refresh
- Current: `A`
- Power consumption: `W`
- Voltage: `V`

Brightness control is intentionally excluded because this is a plug, not a dimmer.

## Refresh Behavior

Current, power, and voltage are read from the Zigbee `ElectricalMeasurement` cluster.

- Voltage: `RMSVoltage` (`0x0505`)
- Current: `RMSCurrent` (`0x0508`)
- Power consumption: `ActivePower` (`0x050B`)
- Zigbee reporting: configured from the selected automatic refresh mode
- Default interval: variable between 5 and 10 seconds
- Manual refresh: reads the values immediately

The device settings provide these modes:

- Variable (5–10 seconds): default
- Variable (5–30 seconds)
- Fixed 5 seconds
- Fixed 10 seconds
- Fixed 30 seconds
- Fixed 60 seconds
- Disabled (manual only)

When `Disabled (manual only)` is selected, automatic Zigbee reporting and periodic reads are disabled.
Values are read only when `Refresh` is pressed.

If the device reports measurement multipliers and divisors, the driver uses them to convert raw values into real units.

## Supported Fingerprint

```text
Manufacturer: IKEA of Sweden
Model: GRILLPLATS Plug
Connection: Zigbee
```

## Installation and Device Driver Selection

1. Upload the driver package with the SmartThings CLI.
2. Assign the driver to a channel.
3. Enroll the SmartThings Station hub in the channel.
4. Install the driver on the hub.
5. Change the existing `Generic Dimmer` device to `IKEA GRILLPLATS Plug Power`.

Installing a driver on the hub and assigning an existing device to that driver are separate steps.
If values remain empty after switching drivers, inspect the hub logs for `ElectricalMeasurement` reports.

## Distribution Invitation

Open the invitation link in the SmartThings app to join the channel and install the driver.

<https://bestow-regional.api.smartthings.com/invite/Y7236AZwknMr>

Invitation code: `Y7236AZwknMr`

## Folder Layout

```text
zigbee-ikea-grillplats-plug/
├── config.yml
├── fingerprints.yml
├── ikea-grillplats-plug.zip
├── profiles/
│   └── ikea-grillplats-plug.yml
└── src/
    └── init.lua
```

## Attribution

This project references the SmartThings Edge Zigbee driver structure and implementation patterns from:

- Reference repository: <https://github.com/Mariano-Github/Edge-Drivers-Beta>
- Reference author: Mariano-Github

The `zigbee-ikea-grillplats-plug` driver in this repository was written specifically for the IKEA GRILLPLATS Plug.
If files are directly copied from or modified from the reference repository, retain its Apache-2.0 license notices.
