import os
import json
import collections
import plotly.plotly as py
import plotly.graph_objs as go
import plotly.offline as offline
from operator import itemgetter

path='/home/sawmill/Documents/GroupWN3-ET4394-TUDelft/Wireshark/Dataset/JSON'
os.chdir(path)
for file in os.listdir(path):
    print file
    f=open(file)
    data=json.load(f)

    phyNumberToLetter={0:'Unknown',1:'FHSS',2:'IR',3:'DSSS',4:'B',5:'A',6:'G',7:'N',8:'AC'}
    channelDistribution={}
    phyDistribution={}
    apBssid={}
    apDistribution={}
    for packet in data:
        wlanInfo=packet['_source']['layers']
        # Recording Channel distribuition in a dict with channel as key and its count as value
        try:
            channel =  int(str(wlanInfo['wlan_radio.channel'][0]))
            p = int(str(wlanInfo["wlan_radio.phy"][0]))
            phy = phyNumberToLetter.get(p)
            bssid = str(wlanInfo['wlan.bssid'][0])
            if(['wlan_mgt.vht.op.channelwidth'][0] in wlanInfo):
                apType='AC'
            elif(['wlan_mgt.ht.capabilities'][0] in wlanInfo):
                apType='N'
            else:
                apType=phy
        except:
            pass
        if(channel not in channelDistribution):
            channelDistribution.update({channel:1})     
        else:
            channelCount=channelDistribution.get(channel)
            channelCount+=1
            channelDistribution.update({channel:channelCount})
    

              

        # Recording bssid's that use a particular channel in a dict with channel as key and list of bssid's as value
        
        if (apType not in apBssid):
            apBssid.update({apType:[bssid]})
        else:
            bssidList=apBssid.get(apType)
            if(bssid not in bssidList): #Storing only unique bssids per Access Point
                bssidList.append(bssid)
                apBssid.update({apType:bssidList})
        
        # Recording phy distribuition in a dict with phy as key and its count as value 
        if(phy not in phyDistribution):
            phyDistribution.update({phy:1})     
        else:
            phyCount=phyDistribution.get(phy)
            phyCount+=1
            phyDistribution.update({phy:phyCount})

    # print(channelBssid)
    for key,value in apBssid.iteritems():
        apDistribution.update({key:len(value)})
    # print apDistribution
    # orderedChannelDistribution=sorted(channelDistribution.items())
    orderedChannelDistribution=collections.OrderedDict(sorted(channelDistribution.items(), key=lambda t:t[1], reverse=True))
    orderedPhyDistribution=collections.OrderedDict(sorted(phyDistribution.items(), key=lambda t:t[1], reverse=True))
    orderedAPDistribution=collections.OrderedDict(sorted(apDistribution.items(), key=lambda t:t[1], reverse=True))
    #Setting up Bar graph for Channel Distribution
    labels1 = orderedChannelDistribution.keys()
    values1 = orderedChannelDistribution.values()
    trace1 = go.Bar(x=labels1, y=values1, name='Channel Distribution')
    data=[trace1]
    layout = go.Layout(
        title='Channel Distribution '+'('+os.path.splitext(file)[0]+')',
        xaxis=dict(
            title='Channel Type',
            dtick=1,
            ticklen=8,
            tickwidth=1,
        ),
        yaxis=dict(
            title='Packets',            
        )
    )
    fig1 = go.Figure(data=data, layout=layout)

    #Setting up Bar Graph for Phy Distribution
    labels2 = orderedPhyDistribution.keys()
    values2 = orderedPhyDistribution.values()
    trace2 = go.Bar(x=labels2, y=values2, name='Phy Distribution')
    data=[trace2]
    layout = go.Layout(
        title='Message PHY Distribution '+'('+os.path.splitext(file)[0]+')',
        xaxis=dict(
            title='Phy Type',
        ),
        yaxis=dict(
            title='Packets',
        )
    )
    fig2 = go.Figure(data=data, layout=layout)

    #Setting the Bar Graph for Types of Access points
    labels3 = orderedAPDistribution.keys()
    values3 = orderedAPDistribution.values()
    trace3 = go.Bar(x=labels3, y=values3, name='Phy Distribution')
    data=[trace3]
    layout = go.Layout(
        title='Access Point PHY Distribution '+'('+os.path.splitext(file)[0]+')',
        xaxis=dict(
            title='Phy Type',
        ),
        yaxis=dict(
            title='Number of Access Points',
        )
    )
    fig3 = go.Figure(data=data, layout=layout)


    #Creating the Graph
    offline.plot(fig1,filename=os.path.splitext(file)[0]+' Channel Distribution.html',image_filename=os.path.splitext(file)[0]+' Channel Distribution', image='jpeg')
    offline.plot(fig2,filename=os.path.splitext(file)[0]+' Phy Distribution.html',image_filename=os.path.splitext(file)[0]+' Phy Distribution', image='jpeg')
    offline.plot(fig3,filename=os.path.splitext(file)[0]+' AP Distribution.html',image_filename=os.path.splitext(file)[0]+' AP Distribution', image='jpeg')