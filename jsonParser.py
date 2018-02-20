import json

with open('/home/sawmill/Documents/Wireshark/sample2.json') as f:
	data=json.load(f)
	#print(data)



for packet in data:
	wlanInfo=packet['_source']['layers']['wlan_radio']
	if('wlan_radio.phy' in wlanInfo):
		print wlanInfo['wlan_radio.phy']

	if('wlan_radio.channel' in wlanInfo):
		print wlanInfo['wlan_radio.channel']

	if('wlan_radio.frequency' in wlanInfo):
		print wlanInfo['wlan_radio.frequency']