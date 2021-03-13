# blynk_routermon
Easy OpenWRT router monitoring &amp; controll via blynk app.
Created with ❤ by Im_Ostrovskiy
## OpenWrt installation

```
# Getting needed packages
opkg update
opkg install lua luasocket luasec unzip openssl-util libustream-openssl wget

# Geting blynk_routermon from github
cd /root
wget --no-check-certificate https://github.com/ImOstrovskiy/blynk_routermon/releases/download/2.0/blynk_routermon-2.0.zip && unzip blynk_routermon-2.0.zip && rm -rf blynk_routermon-2.0.zip
cd blynk_routermon-2.0

# Run it
lua routermon.lua <your_auth_token>
```

## Blynk project preview

![Preview](https://github.com/ImOstrovskiy/blynk_routermon/blob/main/InApp_preview.png)

## Autorun in background
Go to 192.168.1.1 >System >Startup >Local Startup
Insert ```cd /root/blynk_routermon-2.0 && lua routermon.lua <your_auth_token> > /dev/null &``` (in front of 'exit 0').
Enjoy!

## QR-Code for Blynk project
![Qr-blynk](https://github.com/ImOstrovskiy/blynk_routermon/blob/main/BlynkApp.png)

You can copy my Blynk project with this QR-code

