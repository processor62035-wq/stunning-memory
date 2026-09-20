local capabilities = require "st.capabilities"
local ZigbeeDriver = require "st.zigbee"
local defaults = require "st.zigbee.defaults"
local clusters = require "st.zigbee.zcl.clusters"
local device_management = require "st.zigbee.device_management"

local OnOff = clusters.OnOff
local ElectricalMeasurement = clusters.ElectricalMeasurement

local REPORT_MIN = 1
local REPORT_MAX = 60
local POLL_SECONDS = 60

local function read_measurements(device)
  device:send(OnOff.attributes.OnOff:read(device))
  device:send(ElectricalMeasurement.attributes.RMSVoltage:read(device))
  device:send(ElectricalMeasurement.attributes.RMSCurrent:read(device))
  device:send(ElectricalMeasurement.attributes.ActivePower:read(device))
end

local function scale(device, value, multiplier_key, divisor_key, default_divisor)
  local multiplier = device:get_field(multiplier_key) or 1
  local divisor = device:get_field(divisor_key) or default_divisor
  if divisor == 0 then divisor = default_divisor end
  return (value.value * multiplier) / divisor
end

local function voltage_handler(driver, device, value)
  local voltage = scale(device, value, "voltage_multiplier", "voltage_divisor", 10)
  device:emit_event(capabilities.voltageMeasurement.voltage({value = voltage, unit = "V"}))
end

local function current_handler(driver, device, value)
  local current = scale(device, value, "current_multiplier", "current_divisor", 1000)
  device:emit_event(capabilities.currentMeasurement.current({value = current, unit = "A"}))
end

local function power_handler(driver, device, value)
  local power = scale(device, value, "power_multiplier", "power_divisor", 1)
  device:emit_event(capabilities.powerMeter.power({value = power, unit = "W"}))
end

local function save_multiplier(field, default)
  return function(driver, device, value)
    local number = value.value
    if number == 0 then number = default end
    device:set_field(field, number, {persist = true})
  end
end

local function configure_reporting(driver, device)
  device:send(device_management.build_bind_request(device, OnOff.ID, driver.environment_info.hub_zigbee_eui))
  device:send(device_management.build_bind_request(device, ElectricalMeasurement.ID, driver.environment_info.hub_zigbee_eui))
  device:send(OnOff.attributes.OnOff:configure_reporting(device, 0, REPORT_MAX))
  device:send(ElectricalMeasurement.attributes.RMSVoltage:configure_reporting(device, REPORT_MIN, REPORT_MAX, 1))
  device:send(ElectricalMeasurement.attributes.RMSCurrent:configure_reporting(device, REPORT_MIN, REPORT_MAX, 1))
  device:send(ElectricalMeasurement.attributes.ActivePower:configure_reporting(device, REPORT_MIN, REPORT_MAX, 1))
  device:send(ElectricalMeasurement.attributes.ACVoltageMultiplier:read(device))
  device:send(ElectricalMeasurement.attributes.ACVoltageDivisor:read(device))
  device:send(ElectricalMeasurement.attributes.ACCurrentMultiplier:read(device))
  device:send(ElectricalMeasurement.attributes.ACCurrentDivisor:read(device))
  device:send(ElectricalMeasurement.attributes.ACPowerMultiplier:read(device))
  device:send(ElectricalMeasurement.attributes.ACPowerDivisor:read(device))
  read_measurements(device)
end

local function schedule_polling(driver, device)
  local timer = device:get_field("measurement_poll_timer")
  if timer ~= nil then device.thread:cancel_timer(timer) end
  timer = device.thread:call_on_schedule(POLL_SECONDS, function()
    read_measurements(device)
  end, "grillplats_measurement_poll")
  device:set_field("measurement_poll_timer", timer)
end

local driver_template = {
  supported_capabilities = {
    capabilities.switch,
    capabilities.currentMeasurement,
    capabilities.powerMeter,
    capabilities.voltageMeasurement,
    capabilities.refresh,
  },
  lifecycle_handlers = {
    added = function(driver, device)
      device.thread:call_with_delay(2, function()
        configure_reporting(driver, device)
        schedule_polling(driver, device)
      end, "grillplats_configure")
    end,
    init = function(driver, device)
      device:set_field("voltage_multiplier", device:get_field("voltage_multiplier") or 1, {persist = true})
      device:set_field("voltage_divisor", device:get_field("voltage_divisor") or 10, {persist = true})
      device:set_field("current_multiplier", device:get_field("current_multiplier") or 1, {persist = true})
      device:set_field("current_divisor", device:get_field("current_divisor") or 1000, {persist = true})
      device:set_field("power_multiplier", device:get_field("power_multiplier") or 1, {persist = true})
      device:set_field("power_divisor", device:get_field("power_divisor") or 1, {persist = true})
      schedule_polling(driver, device)
    end,
    doConfigure = configure_reporting,
    removed = function(driver, device)
      local timer = device:get_field("measurement_poll_timer")
      if timer ~= nil then device.thread:cancel_timer(timer) end
    end,
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = function(driver, device)
        read_measurements(device)
      end,
    },
  },
  zigbee_handlers = {
    attr = {
      [OnOff.ID] = {
        [OnOff.attributes.OnOff.ID] = function(driver, device, value)
          device:emit_event(value.value and capabilities.switch.switch.on() or capabilities.switch.switch.off())
        end,
      },
      [ElectricalMeasurement.ID] = {
        [ElectricalMeasurement.attributes.RMSVoltage.ID] = voltage_handler,
        [ElectricalMeasurement.attributes.RMSCurrent.ID] = current_handler,
        [ElectricalMeasurement.attributes.ActivePower.ID] = power_handler,
        [ElectricalMeasurement.attributes.ACVoltageMultiplier.ID] = save_multiplier("voltage_multiplier", 1),
        [ElectricalMeasurement.attributes.ACVoltageDivisor.ID] = save_multiplier("voltage_divisor", 10),
        [ElectricalMeasurement.attributes.ACCurrentMultiplier.ID] = save_multiplier("current_multiplier", 1),
        [ElectricalMeasurement.attributes.ACCurrentDivisor.ID] = save_multiplier("current_divisor", 1000),
        [ElectricalMeasurement.attributes.ACPowerMultiplier.ID] = save_multiplier("power_multiplier", 1),
        [ElectricalMeasurement.attributes.ACPowerDivisor.ID] = save_multiplier("power_divisor", 1),
      },
    },
  },
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local driver = ZigbeeDriver("IKEA_GRILLPLATS_Plug_Power", driver_template)
driver:run()
