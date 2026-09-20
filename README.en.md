# stunning-memory

Matter over Thread Edge driver for the IKEA GRILLPLATS Plug

[View the Korean document](README.md)

## Matter Driver

This repository provides the following features for an IKEA GRILLPLATS Plug paired through Matter over Thread:

- On and off
- Power: `W`
- Voltage: `V`
- Current: `A`
- Cumulative energy: `Wh`
- Manual refresh

Verified on the SmartThings hub:

- Power: `146.3 W`
- Voltage: `227 V`
- Current: `0.663 A`
- Energy: `39 Wh`

## Installation

1. Factory-reset the GRILLPLATS Plug and pair it with SmartThings Station using Matter over Thread.
2. Join the distribution channel through the invitation link below.
3. Install `IKEA GRILLPLATS Plug Matter Power` on the hub.
4. Change the device to the new Matter driver.

Invitation link: <https://bestow-regional.api.smartthings.com/invite/Y7236AZwknMr>

## Driver Folder

```text
matter-ikea-grillplats-plug/
├── config.yml
├── fingerprints.yml
├── matter-ikea-grillplats-plug.zip
├── profiles/
│   └── matter-ikea-grillplats-plug.yml
└── src/
    └── init.lua
```

## Matter Identification

```text
Vendor ID: 0x117C
Product ID: 0x1000
Transport: Thread
Electrical measurement endpoint: 2
```

Voltage, current, and power are read from the Matter `ElectricalPowerMeasurement` cluster.
Cumulative energy is read from the `ElectricalEnergyMeasurement` cluster.
