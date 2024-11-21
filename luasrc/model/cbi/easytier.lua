local fs = require "luci.fs"
local http = luci.http
local nixio = require "nixio"

m = Map("easytier")
m.description = translate('Простое, безопасное, децентрализованное решение VPN основанное на Rust：<a href="https://github.com/EasyTier/EasyTier">github.com/EasyTier/EasyTier</a>&nbsp;&nbsp;<a href="http://easytier.rs">官网文档</a>&nbsp;&nbsp;<a href="http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=jhP2Z4UsEZ8wvfGPLrs0VwLKn_uz0Q_p&authKey=OGKSQLfg61YPCpVQuvx%2BxE7hUKBVBEVi9PljrDKbHlle6xqOXx8sOwPPTncMambK&noverify=0&group_code=949700262">QQ群</a>&nbsp;&nbsp;<a href="https://doc.oee.icu">菜鸟教程</a>')

-- easytier
m:section(SimpleSection).template  = "easytier/easytier_status"

s=m:section(TypedSection, "easytier", translate("Конфигурация EasyTier"))
s.addremove=false
s.anonymous=true
s:tab("general", translate("Общие"))
s:tab("privacy", translate("Расширенные"))
s:tab("infos", translate("Информация о соединении"))
s:tab("upload", translate("Загрузить .bin файл"))

switch = s:taboption("general",Flag, "enabled", translate("Enable"))
switch.rmempty = false

btncq = s:taboption("general", Button, "btncq", translate("Перезагрузка"))
btncq.inputtitle = translate("Перезагрузка")
btncq.description = translate("Быстрая перезагрузка без изменения параметров")
btncq.inputstyle = "apply"
btncq:depends("enabled", "1")
btncq.write = function()
  os.execute("/etc/init.d/easytier restart &")
end

etcmd = s:taboption("privacy",ListValue, "etcmd", translate("Режим запуска"),
	translate("Запуск из командной строки по умолчанию, также можно использовать запуск из файла конфигурации<br>При переключении метода запуска запуск будет происходить указанным способом, пожалуйста, выбирайте внимательно!"))
etcmd.default = "etcmd"
etcmd:value("etcmd",translate("командная строка"))
etcmd:value("config",translate("файл конфигурации"))

et_config = s:taboption("privacy",TextValue, "et_config", translate("файл конфигурации"),
	translate("Файл конфигурации находится в /etc/easytier/config.toml <br>Параметры запуска в командной строке не синхронизированы с параметрами в этом файле конфигурации, поэтому измените их самостоятельно<br>Ознакомление с файлом конфигурации:<a href='https://easytier.rs/guide/network/config-file.html '> Нажмите здесь для просмотра</a>"))
et_config.rows = 18
et_config.wrap = "off"
et_config:depends("etcmd", "config")

et_config.cfgvalue = function(self, section)
    return nixio.fs.readfile("/etc/easytier/config.toml") or ""
end
et_config.write = function(self, section, value)
    local dir = "/etc/easytier/"
    local file = dir .. "config.toml"
    -- Проверьте сушествует ли каталог, если нет, создайте.
    if not nixio.fs.access(dir) then
        nixio.fs.mkdir(dir)
    end
    fs.writefile(file, value:gsub("\r\n", "\n"))
end

network_name = s:taboption("general", Value, "network_name", translate("имя сети"),
	translate("Имя сети VPN （--network-name параметр）"))
network_name.password = true
network_name.placeholder = "test"

network_secret = s:taboption("general", Value, "network_secret", translate("сетевой ключ"),
	translate("Испльзуется для проверки надёжности этого узла VPN сетевой ключ（--network-secret параметр）"))
network_secret.password = true
network_secret.placeholder = "test"

ip_dhcp = s:taboption("general",Flag, "ip_dhcp", translate("dhcp"),
	translate("IP-адрес автоматически определяется и устанавливается Easytier, начиная с 10.0.0.1 по умолчанию. ВНИМАНИЕ: При использовании DHCP, если в сети возникнет конфликт IP-адресов, IP-адрес будет изменен автоматически. (параметр -d)"))

ipaddr = s:taboption("general",Value, "ipaddr", translate("IP интерфейса"),
	translate("IPv4-адрес этого VPN-узла, если пустой, то этот узел будет только пересылать пакеты и не будет создавать TUN-устройства (параметр -i)"))
ipaddr.datatype = "ip4addr"
ipaddr.placeholder = "10.0.0.1"

peeradd = s:taboption("general",DynamicList, "peeradd", translate("Одноранговый узел"),
	translate("Начальное соединение с пиром, то же самое, что и ниже (параметр -p) <br>Запрос статуса доступности публичного сервера：<a href='https://easytier.gd.nkbpal.cn/status/easytier' target='_blank'>узнать</a>"))
peeradd.placeholder = "tcp://public.easytier.top:11010"
peeradd:value("tcp://public.easytier.top:11010", translate("Официальный публичный сервер – Гуандун Хэюань-tcp://public.easytier.top:11010"))
peeradd:value("tcp://43.136.45.249:11010", translate("ГуанчжоуV4-tcp://43.136.45.249:11010"))
peeradd:value("tcp://et.ie12vps.xyz:11010", translate("НанкинV4/V6-tcp://et.ie12vps.xyz:11010"))
peeradd:value("tcp://minebg.top:11010", translate("ГуанчжоуV4-tcp://minebg.top:11010"))
peeradd:value("tcp://ah.nkbpal.cn:11010", translate("Аньхой ТелекомV4-tcp://ah.nkbpal.cn:11010"))
peeradd:value("udp://ah.nkbpal.cn:11010", translate("Аньхой ТелекомV4-udp://ah.nkbpal.cn:11010"))
peeradd:value("wss://ah.nkbpal.cn:11012", translate("Аньхой ТелекомV4-wss://ah.nkbpal.cn:11012"))
peeradd:value("tcp://222.186.59.80:11113", translate("Чжэньцзян, ЦзянсуV4-tcp://222.186.59.80:11113"))
peeradd:value("wss://222.186.59.80:11115", translate("Чжэньцзян, ЦзянсуV4-wss://222.186.59.80:11115"))
peeradd:value("tcp://hw.gz.9z1.me:58443", translate("ГуанчжоуV4-tcp://hw.gz.9z1.me:58443"))
peeradd:value("tcp://c.oee.icu:60006", translate("ГонконгV4/V6-tcp://c.oee.icu:60006"))
peeradd:value("udp://c.oee.icu:60006", translate("ГонконгV4/V6-udp://c.oee.icu:60006"))
peeradd:value("wss://c.oee.icu:60007", translate("ГонконгV4/V6-wss://c.oee.icu:60007"))
peeradd:value("tcp://etvm.oee.icu:31572", translate("ЯпонияV4-tcp://etvm.oee.icu:31572"))
peeradd:value("wss://etvm.oee.icu:30845", translate("ЯпонияV4-wss://etvm.oee.icu:30845"))
peeradd:value("tcp://et.pub.moe.gift:11010", translate("Колорадо, СШАV4-tcp://et.pub.moe.gift:11010"))
peeradd:value("wss://et.pub.moe.gift:11012", translate("Колорадо, СШАV4-tcp://et.pub.moe.gift:11012"))
peeradd:value("tcp://et.323888.xyz:11010", translate("Хубэй ШиянV4-tcp://et.323888.xyz:11010"))
peeradd:value("udp://et.323888.xyz:11010", translate("Хубэй ШиянV4-udp://et.323888.xyz:11010"))
peeradd:value("wss://et.323888.xyz:11012", translate("Хубэй ШиянV4-wss://et.323888.xyz:11012"))
peeradd:value("tcp://s1.ct8.pl:1101", translate("Саксония ГерманияV4-tcp://s1.ct8.pl:1101"))
peeradd:value("ws://s1.ct8.pl:11012", translate("Саксония ГерманияV4-ws://s1.ct8.pl:11012"))

external_node = s:taboption("general", Value, "external_node", translate("Общий адрес узла"),
	translate("Используйте публичный общий узел для обнаружения узла-аналога, как описано выше. （парамерт -e）"))
external_node.default = ""
external_node.placeholder = "tcp://public.easytier.top:11010"
external_node:value("tcp://public.easytier.top:11010", translate("Официальный публичный сервер – Гуандун Хэюань-tcp://public.easytier.top:11010"))

proxy_network = s:taboption("general",DynamicList, "proxy_network", translate("прокси подсети"),
	translate("Экспорт локальной сети другим участникам VPN для доступа к другим устройствам в текущей локальной сети. （параметр -n）"))

rpc_portal = s:taboption("privacy", Value, "rpc_portal", translate("RPC"),
	translate("Адрес портала RPC для управления. 0 означает случайный порт, 12345 - прослушивать порт 12345 на локальном хосте, 0.0.0.0:12345 - прослушивать порт 12345 на всех интерфейсах. Значение по умолчанию - 0. Предпочтительно использовать значение 15888. （-r 参数）"))
rpc_portal.placeholder = "0"
rpc_portal.datatype = "range(1,65535)"

listenermode = s:taboption("general",ListValue, "listenermode", translate("порт прослушивания"),
	translate("OFF: не прослушивает никакие порты, подключается только к узлам-аналогам (параметр --no-listener) <br>Используется исключительно как клиент (не как сервер), можно не прослушивать порты."))
listenermode:value("ON",translate("Влючено"))
listenermode:value("OFF",translate("Выключено"))
listenermode.default = "OFF"

listener6 = s:taboption("general",Flag, "listener6", translate("мониторить IPV6"),
	translate("По умолчанию он слушает только IPV4, а одноранговый узел может использовать для подключения только IPV4. Если этот параметр включен, он также будет слушать, например, IPV6. -l tcp://[::]:11010"))
listener6:depends("listenermode", "ON")

tcp_port = s:taboption("general",Value, "tcp_port", translate("tcp/udp порт"),
	translate("tcp/udp протокол， порт：11010. Означает что tcp/udp монитор включен на 11010 порту"))
tcp_port.datatype = "range(1,65535)"
tcp_port.default = "11010"
tcp_port:depends("listenermode", "ON")

ws_port = s:taboption("general",Value, "ws_port", translate("ws порт"),
	translate("ws протокол， порт：11010. Означает что ws монитотор включен на 11011 порту"))
ws_port.datatype = "range(1,65535)"
ws_port.default = "11011"
ws_port:depends("listenermode", "ON")

wss_port = s:taboption("general",Value, "wss_port", translate("wss порт"),
	translate("wss протокол，порт：11012. Означает что wss монитор включее на 11012 порту"))
wss_port.datatype = "range(1,65535)"
wss_port.default = "11012"
wss_port:depends("listenermode", "ON")

wg_port = s:taboption("general",Value, "wg_port", translate("wg порт"),
	translate("wireguard протокол，порт：11011. Означает что wg монитор включен на 11011 порту"))
wg_port.datatype = "range(1,65535)"
wg_port.placeholder = "11011"
wg_port:depends("listenermode", "ON")

local model = fs.readfile("/proc/device-tree/model") or ""
local hostname = fs.readfile("/proc/sys/kernel/hostname") or ""
model = model:gsub("\n", "")
hostname = hostname:gsub("\n", "")
local device_name = (model ~= "" and model) or (hostname ~= "" and hostname) or "OpenWrt"
device_name = device_name:gsub(" ", "_")
desvice_name = s:taboption("general", Value, "desvice_name", translate("имя хоста"),
    translate("Имя хоста, используемое для идентификации этого устройства. （--hostname парамер）"))
desvice_name.placeholder = device_name
desvice_name.default = device_name

instance_name = s:taboption("privacy",Value, "instance_name", translate("Имя экземпляра"),
	translate("Имя экземпляра, используемое для идентификации этого узла VPN на этой же машине （--instance-name параметр）"))
instance_name.placeholder = "default"

vpn_portal = s:taboption("privacy",Value, "vpn_portal", translate("VPN URL"),
	translate("定义 VPN 门户的 URL，允许其他 VPN 客户端连接。<br> 示例：wg://0.0.0.0:11011/10.14.14.0/24，表示 VPN 门户是一个在 vpn.example.com:11010 上监听的 WireGuard 服务器，并且 VPN 客户端位于 10.14.14.0/24 网络中（--vpn-portal 参数）"))
vpn_portal.placeholder = "wg://0.0.0.0:11011/10.14.14.0/24"

mtu = s:taboption("privacy",Value, "mtu", translate("MTU"),
	translate("TUN 设备的 MTU，默认值为非加密时的 1380，加密时为 1360"))
mtu.datatype = "range(1,1500)"
mtu.placeholder = "1300"

default_protocol = s:taboption("privacy",ListValue, "default_protocol", translate("默认协议"),
	translate("连接对等节点时使用的默认协议（--default-protocol 参数）"))
default_protocol:value("-",translate("默认"))
default_protocol:value("tcp")
default_protocol:value("udp")
default_protocol:value("ws")
default_protocol:value("wss")

tunname = s:taboption("privacy",Value, "tunname", translate("虚拟网卡名称"),
	translate("自定义虚拟网卡TUN接口的名称（--dev-name 参数）"))
tunname.placeholder = "easytier"

disable_encryption = s:taboption("general",Flag, "disable_encryption", translate("禁用加密"),
	translate("禁用对等节点通信的加密，若关闭加密则其他节点也必须关闭加密 （-u 参数）"))

multi_thread = s:taboption("general",Flag, "multi_thread", translate("启用多线程"),
	translate("使用多线程运行时，默认为单线程 （--multi-thread 参数）"))

disable_ipv6 = s:taboption("privacy",Flag, "disable_ipv6", translate("禁用ipv6"),
	translate("不使用ipv6 （--disable-ipv6 参数）"))
	
latency_first = s:taboption("general",Flag, "latency_first", translate("启用延迟优先"),
	translate("延迟优先模式，将尝试使用最低延迟路径转发流量，默认使用最短路径 （--latency-first 参数）"))
	
exit_node = s:taboption("privacy",Flag, "exit_node", translate("启用出口节点"),
	translate("允许此节点成为出口节点 （--enable-exit-node 参数）"))
	
exit_nodes = s:taboption("privacy",DynamicList, "exit_nodes", translate("出口节点地址"),
	translate("转发所有流量的出口节点，虚拟 IPv4 地址，优先级由列表顺序确定（--exit-nodes 参数）"))
	
smoltcp = s:taboption("privacy",Flag, "smoltcp", translate("启用smoltcp堆栈"),
	translate("为子网代理启用smoltcp堆栈（--use-smoltcp 参数）"))
smoltcp.rmempty = false

no_tun = s:taboption("privacy",Flag, "no_tun", translate("无tun模式"),
	translate("不创建TUN设备，可以使用子网代理访问节点（ --no-tun 参数）"))
no_tun.rmempty = false

manual_routes = s:taboption("privacy",DynamicList, "manual_routes", translate("路由CIDR"),
	translate("手动分配路由CIDR，将禁用子网代理和从对等节点传播的wireguard路由。（--manual-routes 参数）"))
manual_routes.placeholder = "192.168.0.0/16"

relay_network = s:taboption("privacy",Flag, "relay_network", translate("转发白名单网络的流量"),
	translate("仅转发白名单网络的流量，默认允许所有网络"))
relay_network.rmempty = false

whitelist = s:taboption("privacy",DynamicList, "whitelist", translate("白名单网络"),
	translate("仅转发白名单网络的流量，输入是通配符字符串，例如：'*'（所有网络），'def*'（以def为前缀的网络）<br>可以指定多个网络。如果参数为空，则禁用转发。（--relay-network-whitelist 参数）"))
whitelist:depends("relay_network", "1")

socks_port = s:taboption("privacy",Value, "socks_port", translate("socks5端口"),
	translate("启用 socks5 服务器，允许 socks5 客户端访问虚拟网络，留空则不开启（--socks5 参数）"))
socks_port.datatype = "range(1,65535)"
socks_port.placeholder = "1080"

disable_p2p = s:taboption("privacy",Flag, "disable_p2p", translate("禁用P2P"),
	translate("禁用P2P通信，只通过-p指定的节点转发数据包 （ --disable-p2p 参数）"))
disable_p2p.rmempty = false

disable_udp = s:taboption("privacy",Flag, "disable_udp", translate("禁用UDP"),
	translate("禁用UDP打洞功能（ --disable-udp-hole-punching 参数）"))
disable_udp.rmempty = false

relay_all = s:taboption("privacy",Flag, "relay_all", translate("允许转发"),
	translate("转发所有对等节点的RPC数据包，即使对等节点不在转发网络白名单中。<br>这可以帮助白名单外网络中的对等节点建立P2P连接。"))
relay_all.rmempty = false

log = s:taboption("general",ListValue, "log", translate("程序日志"),
	translate("运行日志在/tmp/easytier.log,可在上方日志查看<br>若启动失败，请前往 状态- 系统日志 查看具体启动失败日志<br>详细程度：警告<信息<调试<跟踪"))
log.default = "info"
log:value("off",translate("关闭"))
log:value("warn",translate("警告"))
log:value("info",translate("信息"))
log:value("debug",translate("调试"))
log:value("trace",translate("跟踪"))

check = s:taboption("privacy",Flag, "check", translate("通断检测"),
        translate("开启通断检测后，可以指定对端的设备IP，当所有指定的IP都ping不通时将会重启easytier程序"))

checkip=s:taboption("privacy",DynamicList,"checkip",translate("检测IP"),
        translate("确保这里的对端设备IP地址填写正确且可访问，若填写错误将会导致无法ping通，程序反复重启"))
checkip.rmempty = true
checkip.datatype = "ip4addr"
checkip:depends("check", "1")

checktime = s:taboption("privacy",ListValue, "checktime", translate("间隔时间 (分钟)"),
        translate("检测间隔的时间，每隔多久检测指定的IP通断一次"))
for s=1,60 do
checktime:value(s)
end
checktime:depends("check", "1")

local process_status = luci.sys.exec("ps | grep easytier-core| grep -v grep")

btn0 = s:taboption("infos", Button, "btn0")
btn0.inputtitle = translate("node信息")
btn0.description = translate("点击按钮刷新，查看本机信息")
btn0.inputstyle = "apply"
btn0.write = function()
if process_status ~= "" then
   luci.sys.call("$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli node >/tmp/easytier-cli_node")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier-cli_node")
end
end

btn0info = s:taboption("infos", DummyValue, "btn0info")
btn0info.rawhtml = true
btn0info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_node") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn1 = s:taboption("infos", Button, "btn1")
btn1.inputtitle = translate("peer信息")
btn1.description = translate("点击按钮刷新，查看对端信息")
btn1.inputstyle = "apply"
btn1.write = function()
if process_status ~= "" then
   luci.sys.call("$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli peer >/tmp/easytier-cli_peer")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier-cli_peer")
end
end

btn1info = s:taboption("infos", DummyValue, "btn1info")
btn1info.rawhtml = true
btn1info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_peer") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn2 = s:taboption("infos", Button, "btn2")
btn2.inputtitle = translate("connector信息")
btn2.description = translate("点击按钮刷新，查看connector信息")
btn2.inputstyle = "apply"
btn2.write = function()
if process_status ~= "" then
   luci.sys.call("$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli connector >/tmp/easytier-cli_connector")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier-cli_connector")
end
end

btn2info = s:taboption("infos", DummyValue, "btn2info")
btn2info.rawhtml = true
btn2info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_connector") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn3 = s:taboption("infos", Button, "btn3")
btn3.inputtitle = translate("stun信息")
btn3.description = translate("点击按钮刷新，查看stun信息")
btn3.inputstyle = "apply"
btn3.write = function()
if process_status ~= "" then
   luci.sys.call("$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli stun >/tmp/easytier-cli_stun")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier-cli_stun")
end
end

btn3info = s:taboption("infos", DummyValue, "btn3info")
btn3info.rawhtml = true
btn3info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_stun") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end


btn4 = s:taboption("infos", Button, "btn4")
btn4.inputtitle = translate("route信息")
btn4.description = translate("点击按钮刷新，查看route信息")
btn4.inputstyle = "apply"
btn4.write = function()
if process_status ~= "" then
   luci.sys.call("$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli route >/tmp/easytier-cli_route")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier-cli_route")
end
end

btn4info = s:taboption("infos", DummyValue, "btn4info")
btn4info.rawhtml = true
btn4info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_route") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn6 = s:taboption("infos", Button, "btn6")
btn6.inputtitle = translate("peer-center信息")
btn6.description = translate("点击按钮刷新，查看peer-center信息")
btn6.inputstyle = "apply"
btn6.write = function()
if process_status ~= "" then
   luci.sys.call("$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli peer-center >/tmp/easytier-cli_peer-center")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier-cli_peer-center")
end
end

btn6info = s:taboption("infos", DummyValue, "btn6info")
btn6info.rawhtml = true
btn6info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_peer-center") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn7 = s:taboption("infos", Button, "btn7")
btn7.inputtitle = translate("vpn-portal信息")
btn7.description = translate("点击按钮刷新，查看vpn-portal信息")
btn7.inputstyle = "apply"
btn7.write = function()
if process_status ~= "" then
   luci.sys.call("$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli vpn-portal >/tmp/easytier-cli_vpn-portal")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier-cli_vpn-portal")
end
end

btn7info = s:taboption("infos", DummyValue, "btn7info")
btn7info.rawhtml = true
btn7info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_vpn-portal") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn5 = s:taboption("infos", Button, "btn5")
btn5.inputtitle = translate("本机启动参数")
btn5.description = translate("点击按钮刷新，查看本机完整启动参数")
btn5.inputstyle = "apply"
btn5.write = function()
if process_status ~= "" then
    luci.sys.call("echo $(cat /proc/$(pidof easytier-core)/cmdline | awk '{print $1}') >/tmp/easytier_cmd")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier_cmd")
end
end

btn5cmd = s:taboption("infos", DummyValue, "btn5cmd")
btn5cmd.rawhtml = true
btn5cmd.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier_cmd") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btnrm = s:taboption("infos", Button, "btnrm")
btnrm.inputtitle = translate("检测更新")
btnrm.description = translate("点击按钮开始检测更新，上方状态栏显示")
btnrm.inputstyle = "apply"
btnrm.write = function()
  os.execute("rm -rf /tmp/easytier*.tag /tmp/easytier*.newtag /tmp/easytier-core_*")
end


easytierbin = s:taboption("upload", Value, "easytierbin", translate("easytier-core程序路径"),
	translate("自定义easytier-core的存放路径，确保填写完整的路径及名称,若指定的路径可用空间不足将会自动移至/tmp/easytier-core"))
easytierbin.placeholder = "/tmp/vnt-cli"

local upload = s:taboption("upload", FileUpload, "upload_file")
upload.optional = true
upload.default = ""
upload.template = "easytier/other_upload"
upload.description = translate("可直接上传二进制程序easytier-core和easytier-cli或者以.zip结尾的压缩包,上传新版本会自动覆盖旧版本，下载地址：<a href='https://github.com/EasyTier/EasyTier/releases' target='_blank'>github.com/EasyTier/EasyTier</a><br>上传的文件将会保存在/tmp文件夹里，如果自定义了程序路径那么启动程序时将会自动移至自定义的路径<br>")
local um = s:taboption("upload",DummyValue, "", nil)
um.template = "easytier/other_dvalue"

local dir, fd, chunk
dir = "/tmp/"
nixio.fs.mkdir(dir)
http.setfilehandler(
    function(meta, chunk, eof)
        if not fd then
            if not meta then return end

            if meta and chunk then fd = nixio.open(dir .. meta.file, "w") end

            if not fd then
                um.value = translate("错误：上传失败！")
                return
            end
        end
        if chunk and fd then
            fd:write(chunk)
        end
        if eof and fd then
            fd:close()
            fd = nil
            um.value = translate("文件已上传至") .. ' "/tmp/' .. meta.file .. '"'

            if string.sub(meta.file, -4) == ".zip" then
                local file_path = dir .. meta.file
                os.execute("unzip -q " .. file_path .. " -d " .. dir)
                local extracted_dir = "/tmp/easytier-linux-*/"
                os.execute("mv " .. extracted_dir .. "easytier-cli /tmp/easytier-cli")
                os.execute("mv " .. extracted_dir .. "easytier-core /tmp/easytier-core")
               if nixio.fs.access("/tmp/easytier-cli") then
                    um.value = um.value .. "\n" .. translate("-程序/tmp/easytier-cli上传成功，重启一次插件才生效")
                end
               if nixio.fs.access("/tmp/easytier-core") then
                    um.value = um.value .. "\n" .. translate("-程序/tmp/easytier-core上传成功，重启一次插件才生效")
                end
               end
	    if string.sub(meta.file, -7) == ".tar.gz" then
                local file_path = dir .. meta.file
                os.execute("tar -xzf " .. file_path .. " -C " .. dir)
		local extracted_dir = "/tmp/easytier-linux-*/"
                os.execute("mv " .. extracted_dir .. "easytier-cli /tmp/easytier-cli")
                os.execute("mv " .. extracted_dir .. "easytier-core /tmp/easytier-core")
               if nixio.fs.access("/tmp/easytier-cli") then
                    um.value = um.value .. "\n" .. translate("-程序/tmp/easytier-cli上传成功，重启一次插件才生效")
                end
               if nixio.fs.access("/tmp/easytier-core") then
                    um.value = um.value .. "\n" .. translate("-程序/tmp/easytier-core上传成功，重启一次插件才生效")
                end
               end
                os.execute("chmod +x /tmp/easytier-core")
                os.execute("chmod +x /tmp/easytier-cli")                
        end
    end
)
if luci.http.formvalue("upload") then
    local f = luci.http.formvalue("ulfile")
end

return m
