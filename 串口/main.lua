PROJECT = "UART"
VERSION = "2.0.0"
--加载日志功能模块，并且设置日志输出等级
require "log"
LOG_LEVEL = log.LOGLEVEL_TRACE
require "sys"

require "net"
--每1分钟查询一次GSM信号强度
--每1分钟查询一次基站信息
net.startQueryAll(60000, 60000)
--加载网络指示灯功能模块
--根据自己的项目需求和硬件配置决定：1、是否加载此功能模块；2、配置指示灯引脚
require "netLed"
netLed.setup(true,pio.P1_1)
--网络指示灯功能模块中，默认配置了各种工作状态下指示灯的闪烁规律，参考netLed.lua中ledBlinkTime配置的默认值
--如果默认值满足不了需求，此处调用netLed.updateBlinkTime去配置闪烁时长

--加载错误日志管理功能模块【强烈建议打开此功能】
--如下2行代码，只是简单的演示如何使用errDump功能，详情参考errDump的api
require "errDump"
errDump.request("udp://ota.airm2m.com:9072")
--加载串口功能测试模块（串口2，TASK方式实现，串口帧没有自定义的结构，依靠软件定时器来处理帧数据）
require "testUartTask"
--启动系统框架
sys.init(0, 0)
sys.run()
