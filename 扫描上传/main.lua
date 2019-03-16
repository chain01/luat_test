--必须在这个位置定义PROJECT和VERSION变量
--PROJECT：ascii string类型
--VERSION：ascii string类型
PROJECT = "MQTT"
VERSION = "2.0.0"

--加载日志功能模块，并且设置日志输出等级
--如果关闭调用log模块接口输出的日志，等级设置为log.LOG_SILENT即可
require "log"
LOG_LEVEL = log.LOGLEVEL_TRACE
require "sys"
require "net"
--每1分钟查询一次GSM信号强度
--每1分钟查询一次基站信息
net.startQueryAll(60000, 60000)
--加载硬件看门狗功能模块
require "wdt"
wdt.setup(pio.P0_30, pio.P0_31)
--加载网络指示灯功能模块
require "netLed"
netLed.setup(true,pio.P1_1)
--网络指示灯功能模块中，默认配置了各种工作状态下指示灯的闪烁规律，参考netLed.lua中ledBlinkTime配置的默认值
--如果默认值满足不了需求，此处调用netLed.updateBlinkTime去配置闪烁时长
--加载MQTT功能测试模块
require "mqttTask"
--启动系统框架
sys.init(0, 0)
sys.run()
