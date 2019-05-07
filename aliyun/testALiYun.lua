module(..., package.seeall)
require "aLiYun"
require "misc"
require "pm"
require "pins"

--采用一机一密认证方案时：
--PRODUCT_KEY为阿里云华东2站点上创建的产品的ProductKey，用户根据实际值自行修改
local PRODUCT_KEY = "a1G3499DlJp"
--除了上面的PRODUCT_KEY外，还需要提供获取DeviceName的函数、获取DeviceSecret的函数
--设备名称使用函数getDeviceName的返回值，默认为设备的IMEI
--设备密钥使用函数getDeviceSecret的返回值，默认为设备的SN
--单体测试时，可以直接修改getDeviceName和getDeviceSecret的返回值
--或者用户自建一个服务器，设备上报IMEI给服务器，服务器返回对应的设备密钥，然后调用misc.setSn接口写到设备的SN中

--采用一型一密认证方案时：
--PRODUCT_KEY和PRODUCE_SECRET为阿里云华东2站点上创建的产品的ProductKey和ProductSecret，用户根据实际值自行修改
--local PRODUCT_KEY = "b1KCi45LcCP"
--local PRODUCE_SECRET = "VWll9fiYWKiwraBk"
--除了上面的PRODUCT_KEY和PRODUCE_SECRET外，还需要提供获取DeviceName的函数、获取DeviceSecret的函数、设置DeviceSecret的函数
--设备第一次在某个product下使用时，会先去云端动态注册，获取到DeviceSecret后，调用设置DeviceSecret的函数保存DeviceSecret

--[[
函数名：getDeviceName
功能  ：获取设备名称
参数  ：无
返回值：设备名称
]]
local function getDeviceName()
    --默认使用设备的IMEI作为设备名称，用户可以根据项目需求自行修改
    --return misc.getImei()

    --用户单体测试时，可以在此处直接返回阿里云的iot控制台上注册的设备名称，例如return "862991419835241"
    return "gary-air"
end

--[[
函数名：setDeviceSecret
功能  ：修改设备密钥
参数  ：设备密钥
返回值：无
]]
local function setDeviceSecret(s)
    --默认使用设备的SN作为设备密钥，用户可以根据项目需求自行修改
    misc.setSn(s)
end

--[[
函数名：getDeviceSecret
功能  ：获取设备密钥
参数  ：无
返回值：设备密钥
]]
local function getDeviceSecret()
    --默认使用设备的SN作为设备密钥，用户可以根据项目需求自行修改
    --return misc.getSn()

    --用户单体测试时，可以在此处直接返回阿里云的iot控制台上生成的设备密钥，例如return "y7MTCG6Gk33Ux26bbWSpANl4OaI0bg5Q"
    return "49pHfwgZzo0UszKLLbWTkmaosYJTdH1B"
end

--阿里云客户端是否处于连接状态
local sConnected

local publishCnt = 1

--[[
函数名：pubqos1testackcb
功能  ：发布1条qos为1的消息后收到PUBACK的回调函数
参数  ：
		usertag：调用mqttclient:publish时传入的usertag
		result：true表示发布成功，false或者nil表示失败
返回值：无
]]
local function publishTestCb(result, para)
    log.info("testALiYun.publishTestCb", result, para)
    sys.timerStart(publishTest, 20000)
    publishCnt = publishCnt + 1
end

--发布一条QOS为1的消息
local io
io =
    [[{
  "method": "thing.event.property.post",
  "id": "52490979",
  "params": {
    "Status": 0,
    "Data": 0
  },
  "version": "1.0"
}
]]
function publishTest()
    if sConnected then
        --注意：在此处自己去控制payload的内容编码，aLiYun库中不会对payload的内容做任何编码转换
        aLiYun.publish(
            "/sys/" .. PRODUCT_KEY .. "/" .. getDeviceName() .. "/thing/event/property/post",
            io,
            1,
            publishTestCb,
            "publishTest_" .. publishCnt
        )
    end
end

---数据接收的处理函数
-- @string topic，UTF8编码的消息主题
-- @number qos，消息质量等级
-- @string payload，原始编码的消息负载
local function rcvCbFnc(topic, qos, payload)
    local led1 = pins.setup(pio.P0_6, 0)
    log.info("testALiYun.rcvCbFnc", topic, qos, payload)
    local dastr = {}
    print(topic)
    print(payload)
    lendata = string.len(payload)
    for i = 1, lendata do
        dastr[i] = string.sub(payload, i, i)
    end
    for i = 1, lendata do
        print(dastr[i])
    end
    if dastr[1] == "1" then
        led1(1)
        log.info("ledon")
    else
        if dastr[1] == "0" then
            led1(0)
            log.info("ledoff")
        end
    end
end

--- 连接结果的处理函数
-- @bool result，连接结果，true表示连接成功，false或者nil表示连接失败
local function connectCbFnc(result)
    log.info("testALiYun.connectCbFnc", result)
    sConnected = result
    if result then
        --订阅主题，不需要考虑订阅结果，如果订阅失败，aLiYun库中会自动重连
        aLiYun.subscribe(
            {
                ["/sys/" .. PRODUCT_KEY .. "/" .. getDeviceName() .. "/thing/service/property/set"] = 0,
                ["/" .. PRODUCT_KEY .. "/" .. getDeviceName() .. "/get"] = 1
            }
        )
        --注册数据接收的处理函数
        aLiYun.on("receive", rcvCbFnc)
        --PUBLISH消息测试
        publishTest()
    end
end

-- 认证结果的处理函数
-- @bool result，认证结果，true表示认证成功，false或者nil表示认证失败
local function authCbFnc(result)
    log.info("testALiYun.authCbFnc", result)
end

--采用一机一密认证方案时：
--配置：ProductKey、获取DeviceName的函数、获取DeviceSecret的函数；其中aLiYun.setup中的第二个参数必须传入nil
aLiYun.setup(PRODUCT_KEY, nil, getDeviceName, getDeviceSecret)

--采用一型一密认证方案时：
--配置：ProductKey、ProductSecret、获取DeviceName的函数、获取DeviceSecret的函数、设置DeviceSecret的函数
--aLiYun.setup(PRODUCT_KEY,PRODUCE_SECRET,getDeviceName,getDeviceSecret,setDeviceSecret)

--setMqtt接口不是必须的，aLiYun.lua中有这个接口设置的参数默认值，如果默认值满足不了需求，参考下面注释掉的代码，去设置参数
--aLiYun.setMqtt(0)
aLiYun.on("auth", authCbFnc)
aLiYun.on("connect", connectCbFnc)
