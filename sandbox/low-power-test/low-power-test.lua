--[[
--https://github.com/tekkies/NodeMcu-LIS3DSH-MQTT-Accelerometer
--Firmware: https://drive.google.com/file/d/1bj2EzizW73LsHUNW7XQAOsKIsnVfJMvn/view?usp=sharing
  --adc, bit, file, gpio, mqtt, net, node, rtctime, spi, tmr, uart, wifi, tls, float

1. Post to MQTT
2. Flash twice
3. Sleep

--]]
  

dofile("device-info.lua");
dofile("constants.lua");




function costlyGetStateName()
    for key,value in pairs(_G) do
        if(state == value and key ~= "state") then
            return key
        end
    end
end

function print1(message)
    if(ENABLE_PRINT) then
        print(message)
    end
end

function print2(message)
    print1("    "..message)
end

function epochSeconds()
    return (tmr.now() - epochStartTime)/1000000
end

function setLed(ledState)
    if(ledState) then
        gpio.write(4, gpio.LOW)
        gpio.mode(4, gpio.OUTPUT)
    else
        gpio.write(4, gpio.HIGH)
        gpio.mode(4, gpio.INPUT)
    end
end

function panic(newPanicReason)
    panicReason = newPanicReason
    panicCallback()
end

function panicCallback()
    print1("FLASH " .. panicReason)
    if (((panicCounter % 2) == 0) and (panicCounter < panicReason * 2)) then
        setLed(true)
    else
        setLed(false)
    end
    panicCounter = panicCounter + 1
    if(panicCounter > 20) then
        panicCounter = 0
        SLEEP_SECONDS = 5*60
        queueState(sleepNow)
        return
    end
    tmr.create():alarm(300, tmr.ALARM_SINGLE, panicCallback)
end

function appendJsonValue(key, value)
    --jsonData = jsonData .. "a"
    if(#jsonData ~= 1) then
        jsonData = jsonData .. ','
    end
    jsonData = jsonData .. '"'  .. key .. '":"' .. value .. '"' 
end

function queueState(newState)
    state = newState
    queueNextState()
end

function queueNextState()
    print1(costlyGetStateName())
    node.task.post(state)
end

function initAdc()
    if adc.force_init_mode(adc.INIT_VDD33)
    then
      node.restart()
      return -- don't bother continuing, the restart is scheduled
    end
    queueState(waitForWiFi)
end

function waitForWiFi()
    if(epochSeconds() > 20) then
        panic(PANIC_NO_WIFI)
        return
    end
    if(wifi.sta.status() == wifi.STA_GOTIP) then
        state=postMqtt     
    end
    queueNextState()
end


function postMqtt()
    mqttClient:connect(MQTT_BROKER, 1883, false, function(client)
      print2("connected")
      appendJsonValue("heap", node.heap())
      jsonData = jsonData .. '}'
      print2(jsonData)
      client:publish("/tekkies.co.uk/NodeMCU/"..DEVICE_NAME, jsonData, 0, 0, function(client) 
        print2("sent")
        mqttClient:close()
      end)
    end,
    function(client, reason)
      print2("Connection failed reason: " .. reason)
      panic(PANIC_MQTT_FAIL)
    end)
end

function mqttOffline(client)
    panic(2)
end

function sleepNow()
    jsonData = "{"
    setLed(false)
    print2("Going to sleep...")
    local us = SLEEP_SECONDS*1000*1000
    node.dsleep(us, 1, nil)
end

function init()
    epochStartTime = tmr.now()
    dofile("config.lua");
    appendJsonValue("program", "low-power-test")
    appendJsonValue("battery", adc.readvdd33(0)/1000)
    
    if(USE_LED) then
        setLed(true)
    end
    tmr.create():alarm(60 * 1000, tmr.ALARM_SINGLE, sleepNow)
    queueState(initAdc)
end

state = nil
epochStartTime = tmr.now()
panicCounter = 0
panicReason = 0
jsonData = '{'

mqttClient = mqtt.Client(MQTT_CLIENTID, 120)
mqttClient:on("offline", mqttOffline)
queueState(init)
