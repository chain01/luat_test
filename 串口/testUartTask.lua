module(..., package.seeall)

require "utils"
require "pm"

--[[
功能定义：
uart接收数据，如果100毫秒没有收到新数据，则打印出来所有已收到的数据，清空数据缓冲区，回复received x frame给对端，然后等待下次数据接收
注意：
串口帧没有定义结构，仅靠软件延时，无法保证帧的完整性，如果对帧接收的完整性有严格要求，必须自定义帧结构（参考testUart.lua）
因为在整个GSM模块软件系统中，软件定时器的精确性无法保证，例如本demo配置的是100毫秒，在系统繁忙时，实际延时可能远远超过100毫秒，达到200毫秒、300毫秒、400毫秒等
设置的延时时间越短，误差越大
]]
--串口ID,2对应uart2
--如果要修改为uart1，把UART_ID赋值为2即可
local UART_ID = 2
local function taskRead()
    local cacheData = ""
    --底层core中，串口收到数据时：
    --如果接收缓冲区为空，则会以中断方式通知Lua脚本收到了新数据；
    --如果接收缓冲器不为空，则不会通知Lua脚本
    --所以Lua脚本中收到中断读串口数据时，每次都要把接收缓冲区中的数据全部读出，这样才能保证底层core中的新数据中断上来，此read函数中的while语句中就保证了这一点
    while true do
        local s = uart.read(UART_ID, "*l")
        if s == "" then
            uart.on(
                UART_ID,
                "receive",
                function()
                    sys.publish("UART_RECEIVE")
                end
            )
            if not sys.waitUntil("UART_RECEIVE", 100) then
                --uart接收数据，如果100毫秒没有收到数据，则打印出来所有已收到的数据，清空数据缓冲区，等待下次数据接收
                --注意：
                --串口帧没有定义结构，仅靠软件延时，无法保证帧的完整性，如果对帧接收的完整性有严格要求，必须自定义帧结构（参考testUart.lua）
                --因为在整个GSM模块软件系统中，软件定时器的精确性无法保证，例如本demo配置的是100毫秒，在系统繁忙时，实际延时可能远远超过100毫秒，达到200毫秒、300毫秒、400毫秒等
                --设置的延时时间越短，误差越大
                if cacheData:len() > 0 then
                    write("len " .. cacheData:len() .. "data:" .. cacheData) --打印到串口
                    cacheData = "" --清空数组，如果接收缓冲器不为空，则不会通知Lua脚本
                end
            end
            uart.on(UART_ID, "receive")
        else
            cacheData = cacheData .. s
        end
    end
end

--[[
函数名：write
功能  ：通过串口发送数据
参数  ：
        s：要发送的数据
返回值：无
]]
function write(s)
    uart.write(UART_ID, s .. "\r\n") --添加回车换行可以在这里定义数据头尾等格式
end
local function vsp()
    local vbt
    vbt = misc.getVbatt()
    vbt = vbt / 1000
    write(vbt)
end
--sys.timerStart(vsp,3000)
sys.timerLoopStart(vsp, 3000)
--保持系统处于唤醒状态，此处只是为了测试需要，所以此模块没有地方调用pm.sleep("testUartTask")休眠，不会进入低功耗休眠状态
--在开发“要求功耗低”的项目时，一定要想办法保证pm.wake("testUartTask")后，在不需要串口时调用pm.sleep("testUartTask")
pm.wake("testUartTask")
--注册串口的数据发送通知函数
uart.on(UART_ID, "sent")
--配置并且打开串口
uart.setup(UART_ID, 115200, 8, uart.PAR_NONE, uart.STOP_1)
--如果需要打开“串口发送数据完成后，通过异步消息通知”的功能，则使用下面的这行setup，注释掉上面的一行setup
--uart.setup(UART_ID,115200,8,uart.PAR_NONE,uart.STOP_1,nil,1)
--启动串口数据接收任务
sys.taskInit(taskRead)
