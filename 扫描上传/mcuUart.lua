--- 模块功能：MCU和Air模块串口透传通信.

module(..., package.seeall)

require "pm"

local uartID = 1

local function taskRead()
    local cacheData = ""
    while true do
        local s = uart.read(uartID, "*l")
        if s == "" then
            uart.on(
                uartID,
                "receive",
                function()
                    sys.publish("UART_RECEIVE")
                end
            )
            if not sys.waitUntil("UART_RECEIVE", 500) then
                if string.len(cacheData) > 1 then
                    log.info("-------uartdata-----------" .. cacheData)
                    sys.publish("UART_RECV_DATA", cacheData)
                end
                cacheData = cacheData:sub(1025, -1)
            end
            uart.on(uartID, "receive")
        else
            cacheData = cacheData .. s
            if cacheData:len() >= 1024 then
                sys.publish("UART_RECV_DATA", cacheData:sub(1, 1024))
                cacheData = cacheData:sub(1025, -1)
            end
        end
    end
end
pm.wake("mcuUart.lua")
uart.setup(uartID, 9600, 8, uart.PAR_NONE, uart.STOP_1)
sys.taskInit(taskRead)
