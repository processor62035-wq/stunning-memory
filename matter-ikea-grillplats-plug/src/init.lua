local MatterDriver = require "st.matter.driver"
local capabilities = require "st.capabilities"
local clusters = require "st.matter.clusters"

local OnOff = clusters.OnOff
local ElectricalPowerMeasurement = clusters.ElectricalPowerMeasurement
local ElectricalEnergyMeasurement = clusters.ElectricalEnergyMeasurement

local SWITCH_ENDPOINT = 1
local SENSOR_ENDPOINT = 2

local function emit_main(device, event)
  device.profile.components["main"]:emit_event(event)
end

local function on_off_handler(driver, device, ib)
  emit_main(device, ib.data.value and capabilities.switch.switch.on() or capabilities.switch.switch.off())
end

local function power_handler(driver, device, ib)
  if ib.data.value ~= nil then
    emit_main(device, capabilities.powerMeter.power({value = ib.data.value / 1000, unit = "W"}))
  end
end

local function voltage_handler(driver, device, ib)
  if ib.data.value ~= nil then
    emit_main(device, capabilities.voltageMeasurement.voltage({value = ib.data.value / 1000, unit = "V"}))
  end
end

local function current_handler(driver, device, ib)
  if ib.data.value ~= nil then
    emit_main(device, capabilities.currentMeasurement.current({value = ib.data.value / 1000, unit = "A"}))
  end
end

local function energy_handler(driver, device, ib)
  local energy = ib.data.elements and ib.data.elements.energy
  if energy and energy.value ~= nil then
    emit_main(device, capabilities.energyMeter.energy({value = energy.value / 1000, unit = "Wh"}))
  end
end

local function read_all(device)
  device:send(OnOff.attributes.OnOff:read(device, SWITCH_ENDPOINT))
  device:send(ElectricalPowerMeasurement.attributes.ActivePower:read(device, SENSOR_ENDPOINT))
  device:send(ElectricalPowerMeasurement.attributes.Voltage:read(device, SENSOR_ENDPOINT))
  device:send(ElectricalPowerMeasurement.attributes.ActiveCurrent:read(device, SENSOR_ENDPOINT))
  device:send(ElectricalEnergyMeasurement.attributes.CumulativeEnergyImported:read(device, SENSOR_ENDPOINT))
end

local driver_template = {
  supported_capabilities = {
    capabilities.switch,
    capabilities.powerMeter,
    capabilities.energyMeter,
    capabilities.powerConsumptionReport,
    capabilities.voltageMeasurement,
    capabilities.currentMeasurement,
    capabilities.refresh,
  },
  lifecycle_handlers = {
    init = function(driver, device)
      device:subscribe()
    end,
    doConfigure = function(driver, device)
      device:subscribe()
      read_all(device)
      device:try_update_metadata({provisioning_state = "PROVISIONED"})
    end,
  },
  matter_handlers = {
    attr = {
      [OnOff.ID] = {
        [OnOff.attributes.OnOff.ID] = on_off_handler,
      },
      [ElectricalPowerMeasurement.ID] = {
        [ElectricalPowerMeasurement.attributes.ActivePower.ID] = power_handler,
        [ElectricalPowerMeasurement.attributes.Voltage.ID] = voltage_handler,
        [ElectricalPowerMeasurement.attributes.ActiveCurrent.ID] = current_handler,
      },
      [ElectricalEnergyMeasurement.ID] = {
        [ElectricalEnergyMeasurement.attributes.CumulativeEnergyImported.ID] = energy_handler,
      },
    },
  },
  subscribed_attributes = {
    [capabilities.switch.ID] = {
      OnOff.attributes.OnOff,
    },
    [capabilities.powerMeter.ID] = {
      ElectricalPowerMeasurement.attributes.ActivePower,
    },
    [capabilities.voltageMeasurement.ID] = {
      ElectricalPowerMeasurement.attributes.Voltage,
    },
    [capabilities.currentMeasurement.ID] = {
      ElectricalPowerMeasurement.attributes.ActiveCurrent,
    },
    [capabilities.energyMeter.ID] = {
      ElectricalEnergyMeasurement.attributes.CumulativeEnergyImported,
    },
  },
  capability_handlers = {
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = function(driver, device)
        device:send(OnOff.server.commands.On(device, SWITCH_ENDPOINT))
      end,
      [capabilities.switch.commands.off.NAME] = function(driver, device)
        device:send(OnOff.server.commands.Off(device, SWITCH_ENDPOINT))
      end,
    },
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = function(driver, device)
        read_all(device)
      end,
    },
  },
}

local driver = MatterDriver("IKEA_GRILLPLATS_Plug_Matter_Power", driver_template)
driver:run()
