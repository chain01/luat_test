module(...,package.seeall)
require"http"
local function vsp()
	http.request("GET","115.159.50.191",nil,nil,nil,nil,cbFnc)
end
sys.timerLoopStart (vsp,5000) --系统延时5秒执行一次
