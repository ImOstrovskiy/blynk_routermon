#!/usr/bin/env lua

local socket = require("socket")
local use_ssl, ssl = pcall(require, "ssl")

local Blynk = require("blynk.socket")
local Timer = require("timer")

assert(#arg >= 1, "Please specify Auth Token")
local auth = arg[1]

local blynk = Blynk.new(auth, {
  heartbeat = 30,
})

function exec_out(cmd)
  local file = io.popen(cmd)
  if not file then return nil end
  local output = file:read('*all')
  file:close()
  return output
end

function read_file(path)
  local file = io.open(path, "rb")
  if not file then return nil end
  local content = file:read "*a"
  file:close()
  return content
end

function getArpClients()
  return tonumber(exec_out("cat /proc/net/arp | grep br-lan | grep 0x2 | wc -l"))
end

function getUptime()
  return tonumber(exec_out("cat /proc/uptime | awk '{print $1}'"))
end

function getWanIP()
  return exec_out("ifconfig eth0.2 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}'")
end

function getCpuLoad()
  return tonumber(exec_out("top -bn1 | grep 'CPU:' | head -n1 | awk '{print $2+$4}'"))
end

function getRamUsage()
  return tonumber(exec_out("free | grep Mem | awk '{print ($3-$7)/$2 * 100.0}'"))
end

function getWanTxBytes()
  return tonumber(read_file("/sys/class/net/eth0.2/statistics/tx_bytes"))
end

local function connectBlynk()
  local host = "blynk-cloud.com"

  local sock = assert(socket.tcp())
  sock:setoption("tcp-nodelay", true)

  if use_ssl then
    print("Connecting Blynk (secure)...")
    sock:connect(host, 443)
    local opts = {
      mode = "client",
      protocol = "tlsv1"
    }
    sock = assert(ssl.wrap(sock, opts))
    sock:dohandshake()
  else
    print("Connecting Blynk...")
    sock:connect(host, 80)
  end

  blynk:connect(sock)
end

--[[ WiFi on/off ]]

blynk:on("V20", function(param)
  if param[1] == "1" then
    os.execute("wifi up")
  else
    os.execute("wifi down")
  end
end)

--[[ Reboot ]]

blynk:on("V31", function(param)
  if param[1] == "1" then
    os.execute("reboot")
  end
end)

--[[ Shell ]]

blynk:on("V35", function(param)
  local out = exec_out(param[1])
  blynk:virtualWrite(35, out)
end)



blynk:on("connected", function(ping)
  print("Ready. Ping: "..math.floor(ping*1000).."ms")

  blynk:virtualWrite(12, getWanIP())
end)

blynk:on("disconnected", function()
  print("Disconnected.")
  socket.sleep(5)
  connectBlynk()
end)

--[[ Timers ]]

local prev = { spin = -1 }

local tmr1 = Timer:new{interval = 700, func = function()
  local tx = getWanTxBytes()

  if prev.tx then
    local dtx = tx - prev.tx
    if prev.dtx ~= dtx then
      blynk:virtualWrite(1, dtx)
      prev.dtx = dtx
    end
  end
  prev.tx = tx

  blynk:virtualWrite(5, getCpuLoad())
  blynk:virtualWrite(6, getRamUsage())
  blynk:virtualWrite(10, getArpClients())
  blynk:virtualWrite(11, string.format("%.1f h", getUptime()/60/60))
end}

connectBlynk()

while true do
  blynk:run()
  tmr1:run()
end
