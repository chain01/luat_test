--- 模块功能：MCU和Air模块串口透传通信.
-- Air模块的串口接收到1024字节的数据，或者接收数据后超时1秒钟不再收到数据，则透传给服务器
--
-- 服务器下发的数据，通过服务器直接透传给MCU
-- @author openLuat
-- @module socketLongConnectionTrasparent.mcuUart
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.30

module(...,package.seeall)

require"pm"

local uartID = 1

local function taskRead()
    local cacheData = ""
	local Uart_Datalen
	local Uart_Num
	local Json_Struart1=[[{"t": 3,"datatype":1,"datas":{"home":"]]
	local Json_Struart2=[["},"msgid": 123}]]
	local Json_StrUart
    while true do
        local s = uart.read(uartID,"*l")
        if s == "" then
            uart.on(uartID,"receive",function() sys.publish("UART_RECEIVE") end)
            if not sys.waitUntil("UART_RECEIVE",1000) then
				if	string.find(cacheData,"on") then
					Uart_Datalen=string.len(cacheData)
					Uart_Num=cacheData:sub(3,Uart_Datalen)
					Json_StrUart=Json_Struart1..Uart_Num..Json_Struart2
					sys.publish("UART_RECV_DATA",Json_StrUart)
				end
                sys.publish("UART_RECV_DATA",cacheData:sub(1,1024))
                cacheData = cacheData:sub(1025,-1)
            end
            uart.on(uartID,"receive")
        else
            cacheData = cacheData..s
			if	string.find(cacheData,"on") then
				if cacheData:len()>=1024 then
					Uart_Datalen=string.len(cacheData)
					Uart_Num=cacheData:sub(3,Uart_Datalen)
					Json_StrUart=Json_Struart1..Uart_Num..Json_Struart2
					--datastr=[[{"t": 3,"datatype":1,"datas":{"temp":"23","humy":"46"},"msgid": 123}]]
					sys.publish("UART_RECV_DATA",Json_StrUart)
					cacheData = cacheData:sub(1025,-1)
				end
			end	
        end
    end
end

local function socketRecvData(data)
    uart.write(uartID,data)
end


pm.wake("mcuUart.lua")
uart.setup(uartID,115200,8,uart.PAR_NONE,uart.STOP_1)
sys.taskInit(taskRead)

sys.subscribe("SOCKET_RECV_DATA",socketRecvData)
