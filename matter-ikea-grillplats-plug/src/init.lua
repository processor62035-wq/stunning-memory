local MatterDriver = require "st.matter.driver"
local capabilities = require "st.capabilities"
local clusters = require "st.matter.clusters"

local OnOff = clusters.OnOff
local ElectricalPowerMeasurement = clusters.ElectricalPowerMeasurement
local ElectricalEnergyMeasurement = clusters.ElectricalEnergyMeasurement

local SWITCH_ENDPOINT = 1
local SENSOR_ENDPOINT = 2
local AUTO_OFF_TIMER = "voltage_auto_off_timer"

local function emit_main(device, event)
  device.profile.components["main"]:emit_event(event)
end

local function cancel_auto_off(device)
  local timer = device:get_field(AUTO_OFF_TIMER)
  if timer then
    device.thread:cancel_timer(timer)
    device:set_field(AUTO_OFF_TIMER, nil)
  end
end

local function switch_off_for_voltage(device)
  cancel_auto_off(device)
  -- 차단 직전에 경보 상태를 다시 전환해 자동화 알림을 확실히 발생시킵니다.
  emit_main(device, capabilities.alarm.alarm.off())
  emit_main(device, capabilities.alarm.alarm.siren())
  device:send(OnOff.server.commands.Off(device, SWITCH_ENDPOINT))
end

local function evaluate_voltage_auto_off(device, voltage, average)
  if device.preferences.voltageAutoOffEnabled == false or average == nil or average <= 0 then
    cancel_auto_off(device)
    return
  end
  local deviation = math.abs(voltage - average) / average
  if deviation >= 0.20 then
    switch_off_for_voltage(device)
  elseif deviation >= 0.15 then
    if device:get_field(AUTO_OFF_TIMER) == nil then
      local timer = device.thread:call_with_delay(15, function()
        local latest = device:get_latest_state("main", capabilities.voltageMeasurement.ID, capabilities.voltageMeasurement.voltage.NAME)
        local current_average = device:get_field("voltage_average")
        if latest and current_average and math.abs(latest - current_average) / current_average >= 0.15 then
          switch_off_for_voltage(device)
        else
          cancel_auto_off(device)
        end
      end)
      device:set_field(AUTO_OFF_TIMER, timer)
    end
  else
    cancel_auto_off(device)
  end
end

local function evaluate_voltage_alarm(device, voltage)
  if device.preferences.voltageAlarmEnabled == false then
    if device:get_field("voltage_alarm_active") then
      emit_main(device, capabilities.alarm.alarm.off())
      device:set_field("voltage_alarm_active", false)
    end
    device:set_field("voltage_average", nil)
    return
  end
  local average = device:get_field("voltage_average")
  if average == nil or average <= 0 then
    device:set_field("voltage_average", voltage, {persist = true})
    return
  end
  local tolerance = tonumber(device.preferences.voltageAlarmTolerance) or 5
  local out_of_range = voltage < average * (1 - tolerance / 100) or voltage > average * (1 + tolerance / 100)
  local active = device:get_field("voltage_alarm_active") == true
  if out_of_range and not active then
    emit_main(device, capabilities.alarm.alarm.siren())
    device:set_field("voltage_alarm_active", true, {persist = true})
  elseif not out_of_range and active then
    emit_main(device, capabilities.alarm.alarm.off())
    device:set_field("voltage_alarm_active", false, {persist = true})
  end
  if not out_of_range then
    device:set_field("voltage_average", average * 0.9 + voltage * 0.1, {persist = true})
  end
  evaluate_voltage_auto_off(device, voltage, average)
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
    local voltage = ib.data.value / 1000
    emit_main(device, capabilities.voltageMeasurement.voltage({value = voltage, unit = "V"}))
    evaluate_voltage_alarm(device, voltage)
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
    capabilities.alarm,
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
    infoChanged = function(driver, device, event, args)
      if args.old_st_store.preferences.voltageAlarmEnabled ~= device.preferences.voltageAlarmEnabled or
        args.old_st_store.preferences.voltageAlarmTolerance ~= device.preferences.voltageAlarmTolerance or
        args.old_st_store.preferences.voltageAutoOffEnabled ~= device.preferences.voltageAutoOffEnabled then
        cancel_auto_off(device)
        device:set_field("voltage_average", nil)
        device:set_field("voltage_alarm_active", false)
      end
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
    [capabilities.alarm.ID] = {
      [capabilities.alarm.commands.off.NAME] = function(driver, device)
        emit_main(device, capabilities.alarm.alarm.off())
        device:set_field("voltage_alarm_active", false, {persist = true})
      end,
      [capabilities.alarm.commands.siren.NAME] = function(driver, device)
        emit_main(device, capabilities.alarm.alarm.siren())
        device:set_field("voltage_alarm_active", true, {persist = true})
      end,
    },
  },
}

local driver = MatterDriver("IKEA_GRILLPLATS_Plug_Matter_Power", driver_template)
driver:run()
