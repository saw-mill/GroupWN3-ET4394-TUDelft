import json
import collections
import plotly.plotly as py
import plotly.graph_objs as go
import plotly.offline as offline
from operator import itemgetter

with open('Lecturehalldelta_21_02_channelhop_airodump.json') as f:
    data=json.load(f)

phyNumberToLetter={0:'Unknown',1:'FHSS',2:'IR',3:'DSSS',4:'B',5:'A',6:'G',7:'N',8:'AC'}
channelDistribution={}
phyDistribution={}
channelBssid={}

for packet in data:
    wlanInfo=packet['_source']['layers']

    # Recording Channel distribuition in a dict with channel as key and its count as value
    channel =  int(str(wlanInfo['wlan_radio.channel'][0]))
    if(channel not in channelDistribution):
        channelDistribution.update({channel:1})     
    else:
        channelCount=channelDistribution.get(channel)
        channelCount+=1
        channelDistribution.update({channel:channelCount})

    # Recording bssid's that use a particular channel in a dict with channel as key and list of bssid's as value
    bssid = str(wlanInfo['wlan.bssid'][0])
    if (channel not in channelBssid):
        channelBssid.update({channel:[bssid]})
    else:
        bssidList=channelBssid.get(channel)
        if(bssid not in bssidList): #Storing only unique bssids per channel
            bssidList.append(bssid)
            channelBssid.update({channel:bssidList})
    
    # Recording phy distribuition in a dict with phy as key and its count as value
    p = int(str(wlanInfo["wlan_radio.phy"][0]))
    phy = phyNumberToLetter.get(p) 
    if(phy not in phyDistribution):
        phyDistribution.update({phy:1})     
    else:
        phyCount=phyDistribution.get(phy)
        phyCount+=1
        phyDistribution.update({phy:phyCount})

print(channelBssid)

# orderedChannelDistribution=sorted(channelDistribution.items())
orderedChannelDistribution=collections.OrderedDict(sorted(channelDistribution.items(), key=lambda t:t[1], reverse=True))
orderedPhyDistribution=collections.OrderedDict(sorted(phyDistribution.items(), key=lambda t:t[1], reverse=True))

#Setting up Pie Chart for Channel Distribution

fig1 = {
  "data": [
    {
      "values": orderedChannelDistribution.values(),
      "labels": orderedChannelDistribution.keys(),
      "name": "Channel Distribution",
      "type": "pie"
    }],
    "layout": {
        "title": "Channel Distribution"
    }
    }

#Setting up Bar Graph for Phy Distribution
labels2 = orderedPhyDistribution.keys()
values2 = orderedPhyDistribution.values()
trace2 = go.Bar(x=labels2, y=values2, name='Phy Distribution')
data=[trace2]
layout = go.Layout(
    title='Phy Distribution',
    xaxis=dict(
        title='Phy Type',
    ),
    yaxis=dict(
        title='Occurrence',
    )
)
fig2 = go.Figure(data=data, layout=layout)

#Creating the Graph
offline.plot(fig1,filename='Channel Distribution.html',image_filename='Channel Distribution', image='jpeg')
offline.plot(fig2,filename='Phy Distribution.html',image_filename='Phy Distribution', image='jpeg')