import json
import collections
import plotly.plotly as py
import plotly.graph_objs as go
import plotly.offline as offline

with open('Lecturehalldelta_21_02_channelhop_airodump.json') as f:
    data=json.load(f)

channelDistribution={}
phyDistribution={}
bssidChannelUse={}

for packet in data:
    wlanInfo=packet['_source']['layers']

    channel =  int(str(wlanInfo['wlan_radio.channel'][0]))
    if(channel not in channelDistribution):
        channelDistribution.update({channel:1})     
    else:
        channelCount=channelDistribution.get(channel)
        channelCount+=1
        channelDistribution.update({channel:channelCount})

    phy = int(str(wlanInfo["wlan_radio.phy"][0]))
    if(phy not in phyDistribution):
        phyDistribution.update({phy:1})     
    else:
        phyCount=phyDistribution.get(phy)
        phyCount+=1
        phyDistribution.update({phy:phyCount})

    # bssid = int(str(wlanInfo["wlan.bssid"][0]))



# orderedChannelDistribution=sorted(channelDistribution.items())
orderedChannelDistribution=collections.OrderedDict(sorted(channelDistribution.items()))
orderedPhyDistribution=collections.OrderedDict(sorted(phyDistribution.items()))

labels = orderedChannelDistribution.keys()
values = orderedChannelDistribution.values()
trace = go.Pie(labels=labels, values=values, name='Channel Distribution')
offline.plot([trace], image_filename='Channel Distribution', image='jpeg')

# labels = orderedPhyDistribution.keys()
# values = orderedPhyDistribution.values()
# trace = go.Pie(labels=labels, values=values, name='Phy Distribution')
# offline.plot([trace], image_filename='Phy Distribution', image='jpeg')

    # frequency = 'Frequency : ' + wlanInfo['radiotap.channel.freq'][0] + '\n'
    # print frequency 