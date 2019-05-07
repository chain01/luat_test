--- 模块功能：MQTT客户端数据接收处理
-- @author openLuat
-- @module mqtt.mqttInMsg
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.28

module(..., package.seeall)
local led = pins.setup(pio.P0_6, 0) --配置IO口初始化为低电平
--- MQTT客户端数据接收处理
-- @param mqttClient，MQTT客户端对象
-- @return 处理成功返回true，处理出错返回false
-- @usage mqttInMsg.proc(mqttClient)
function proc(mqttClient)
    local result, data
    while true do
        result, data = mqttClient:receive(2000)
        --接收到数据
        if result then
            log.info("mqttInMsg.proc", data.topic, data.payload)
            if string.find(data.payload, "cmd") then
                Data = json.decode(data.payload)
                Cmd = Data["cmd"]["light"]
                if Cmd == "0" then
                    led(0)
                    log.info("ledoff")
                end
                if Cmd == "1" then
                    led(1)
                    log.info("ledon")
                end
            end
            --如果mqttOutMsg中有等待发送的数据，则立即退出本循环
            if mqttOutMsg.waitForSend() then
                return true
            end
        else
            break
        end
    end

    return result or data == "timeout"
end
