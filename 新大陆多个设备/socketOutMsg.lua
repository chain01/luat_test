--- 模块功能：socket客户端数据发送处理
-- @author openLuat
-- @module socketLongConnectionTrasparent.socketOutMsg
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.28

module(..., package.seeall)

--数据发送的消息队列
local msgQueue = {}

local function insertMsg(data, user)
    table.insert(msgQueue, {data = data, user = user})
end

--发送连接请求
--@string device 设备标识
--@string key 传输密钥
function link()
    local device = "STC15IOT"
    local key = "0338ba0fadc340c88b051f231388a05f"
    local Json_Key
    local Json_Str1 = [[{"t": 1,"device": "]]
    local Json_Str2 = [[","key":"]]
    local Json_Str3 = [[","ver":"v1.1"}]]
    Json_Key = Json_Str1 .. device .. Json_Str2 .. key .. Json_Str3
    insertMsg(Json_Key)
end

--- 去初始化“socket客户端数据发送”
-- @return 无
-- @usage socketOutMsg.unInit()
function unInit()
    while #msgQueue > 0 do
        local outMsg = table.remove(msgQueue, 1)
        if outMsg.user and outMsg.user.cb then
            outMsg.user.cb(false, outMsg.user.para)
        end
    end
end

--- socket客户端是否有数据等待发送
-- @return 有数据等待发送返回true，否则返回false
-- @usage socketOutMsg.waitForSend()
function waitForSend()
    return #msgQueue > 0
end

--- socket客户端数据发送处理
-- @param socketClient，socket客户端对象
-- @return 处理成功返回true，处理出错返回false
-- @usage socketOutMsg.proc(socketClient)
function proc(socketClient)
    while #msgQueue > 0 do
        local outMsg = table.remove(msgQueue, 1)
        local result = socketClient:send(outMsg.data)
        if outMsg.user and outMsg.user.cb then
            outMsg.user.cb(result, outMsg.user.para)
        end
        if not result then
            return
        end
    end
    return true
end

local function uartRecvData(data)
    insertMsg(data)
end
sys.subscribe("UART_RECV_DATA", uartRecvData)
