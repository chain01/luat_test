--- 模块功能：MQTT客户端数据发送处理
-- @author openLuat
-- @module mqtt.mqttOutMsg
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.28

module(..., package.seeall)
require "misc"
require "mcuUart"
--数据发送的消息队列
local msgQueue = {}
local basedate = {
    method = "pub",
    deviceid = "",
    data = {qrdata = ""},
    version = "1.0"
}
local function insertMsg(topic, payload, qos, user)
    table.insert(msgQueue, {t = topic, p = payload, q = qos, user = user})
end

local function pubQos1TestCb(result)
    log.info("mqttOutMsg.pubQos1TestCb", result)
    if result then
        sys.timerStart(pubQos1Test, 60000)
    end
end

function pubQos1Test(uart_qrdata)
    log.info("------接收到扫描数据-------")
    if uart_qrdata ~= nil then
        basedate["data"]["qrdata"] = uart_qrdata
        basedate["deviceid"] = misc.getImei()
        jsondata = json.encode(basedate)
        log.info("--------mqtt发送数据为-----", jsondata)
        insertMsg("/pub", jsondata, 1, {cb = pubQos1TestCb})
    else
        log.info("------数据错误-------")
    end
end
--- 初始化“MQTT客户端数据发送”
-- @return 无
-- @usage mqttOutMsg.init()
function init()
    log.info("------初始化完成-------")
end

--- 去初始化“MQTT客户端数据发送”
-- @return 无
-- @usage mqttOutMsg.unInit()
function unInit()
    while #msgQueue > 0 do
        local outMsg = table.remove(msgQueue, 1)
        if outMsg.user and outMsg.user.cb then
            outMsg.user.cb(false, outMsg.user.para)
        end
    end
end

--- MQTT客户端是否有数据等待发送
-- @return 有数据等待发送返回true，否则返回false
-- @usage mqttOutMsg.waitForSend()
function waitForSend()
    return #msgQueue > 0
end

--- MQTT客户端数据发送处理
-- @param mqttClient，MQTT客户端对象
-- @return 处理成功返回true，处理出错返回false
-- @usage mqttOutMsg.proc(mqttClient)
function proc(mqttClient)
    while #msgQueue > 0 do
        local outMsg = table.remove(msgQueue, 1)
        local result = mqttClient:publish(outMsg.t, outMsg.p, outMsg.q)
        if outMsg.user and outMsg.user.cb then
            outMsg.user.cb(result, outMsg.user.para)
        end
        if not result then
            return
        end
    end
    return true
end
--注册mqtt发送任务
sys.subscribe("UART_RECV_DATA", pubQos1Test)
