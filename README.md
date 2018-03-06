# ET4394 Wireless Networking-- Group WN3

## Wireshark Project
A mini project for the course ET4394 Wireless Networking offered at TU Delft. The goal of the project is to provide data on the wireless channel distribution, channel sizes and Phy types i.e. to observe and record which channels are being used mostly and by whom at different locations such as @Campus, @Dorm or @Street etc.

### Setup and Run
#### To capture packets:
Put the network adapter on your PC in adapter mode: 
`sudo airmon-ng start wlan0`

Capture the packets using TShark:
`tshark -i mon0 -w capture-output.pcap`

To filter and covert to JSON:
`tshark -r capture-output.pcapng -T json > capture-output.json -e wlan_mgt.ssid -e radiotap.channel.freq -e wlan_radio.channel -e wlan_radio.phy -e wlan.bssid -e wlan_mgt.vht.op.channelwidth -e wlan_mgt.ht.capabilities`

Place the Captured JSON files to *Dataset/JSON* directory in Wireshark Folder (OR You can use the JSON Files already in the *Dataset/JSON* directory)

#### To run the python script:
To run the *jsonParser.py* file, first setup the [Plotly Library in Python](https://plot.ly/python/getting-started/)

Replace the path in the 11th line in the python script to the path of the *Dataset/JSON* directory in your system: 
> path='/home/sawmill/Documents/GroupWN3-ET4394-TUDelft/Wireshark/Dataset/JSON'

Run the script
`python jsonParser.py`
