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

#Setting up Pie Chart for Channel Distribution
labels1 = orderedChannelDistribution.keys()
values1 = orderedChannelDistribution.values()
trace1 = go.Pie(labels=labels1, values=values1,  name='Channel Distribution')

#Setting up Pie Chart for Phy Distribution
labels2 = orderedPhyDistribution.keys()
values2 = orderedPhyDistribution.values()
trace2 = go.Pie(labels=labels2, values=values2, name='Phy Distribution')

#Creating the Graph
offline.plot([trace1],filename='Channel Distribution.html',image_filename='Channel Distribution', image='jpeg')
offline.plot([trace2],filename='Phy Distribution.html',image_filename='Phy Distribution', image='jpeg')


# fig = {
#     'data': [
#         {
#             'labels': orderedChannelDistribution.keys(),
#             'values': orderedChannelDistribution.values(),
#             'type': 'pie',
#             'name': 'Channel Distribution',
#             'marker': {'colors': ['rgb(56, 75, 126)',
#                                   'rgb(18, 36, 37)',
#                                   'rgb(34, 53, 101)',
#                                   'rgb(36, 55, 57)',
#                                   'rgb(6, 4, 4)']},
#             'domain': {'x': [0, .48],
#                        'y': [0, .49]},
#             'hoverinfo':'label+percent+name',
#             'textinfo': orderedChannelDistribution.keys()
#             'name' : orderedChannelDistribution.keys()
#         },
#         {
#             'labels': orderedPhyDistribution.keys(),
#             'values': orderedPhyDistribution.values(),
#             'marker': {'colors': ['rgb(177, 127, 38)',
#                                   'rgb(205, 152, 36)',
#                                   'rgb(99, 79, 37)',
#                                   'rgb(129, 180, 179)',
#                                   'rgb(124, 103, 37)']},
#             'type': 'pie',
#             'name': 'Phy Distribution',
#             'domain': {'x': [.52, 1],
#                        'y': [0, .49]},
#             'hoverinfo':'label+percent+name',
#             'textinfo': orderedPhyDistribution.keys()
#             'name' : orderedPhyDistribution.keys()

#         }
#     ],
#     'layout': {'title': 'Channel Distribution and Phy Distribution',
#                'showlegend': True}
#        }

# py.plot(fig, filename='pie_chart_subplots')

    # frequency = 'Frequency : ' + wlanInfo['radiotap.channel.freq'][0] + '\n'
    # print frequency 