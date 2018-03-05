import os
import json
import collections
import plotly.plotly as py
import plotly.graph_objs as go
import plotly.offline as offline
from operator import itemgetter
from plotly import tools

#Set the path of the Dataset folder containing JSON files captured using TShark
path='/home/sawmill/Documents/GroupWN3-ET4394-TUDelft/Wireshark/Dataset/JSON'
os.chdir(path)
for file in os.listdir(path):
    print file
    f=open(file)
    data=json.load(f)

    #Initializing
    phyNumberToLetter={0:'Unknown',1:'FHSS',2:'IR',3:'DSSS',4:'B',5:'A',6:'G',7:'N',8:'AC'}
    channelDistribution={}
    phyDistribution={}
    apBssid={}
    widthBssid={}
    apDistribution={}
    channelWidthDistribution={}

    #Parse Logic
    for packet in data:
        wlanInfo=packet['_source']['layers']
        try:
            channel =  int(str(wlanInfo['wlan_radio.channel'][0]))
            p = int(str(wlanInfo["wlan_radio.phy"][0]))
            phy = phyNumberToLetter.get(p)
            bssid = str(wlanInfo['wlan.bssid'][0])
            if(['wlan_mgt.vht.op.channelwidth'][0] in wlanInfo):
                apType='AC'
                if(wlanInfo['wlan_mgt.vht.op.channelwidth'][0]=="0x00000001"):
                    channelWidth='80'
                elif(wlanInfo['wlan_mgt.vht.op.channelwidth'][0]=="0x00000000"):
                    channelWidth='20 or 40'
            elif(['wlan_mgt.ht.capabilities'][0] in wlanInfo):
                apType='N'
                channelWidth='20 or 40'
            else:
                apType=phy
                channelWidth='20'
        except:
            pass 
        # Recording Channel distribuition in a dict with channel as key and its count as value
        if(channel not in channelDistribution):
            channelDistribution.update({channel:1})     
        else:
            channelCount=channelDistribution.get(channel)
            channelCount+=1
            channelDistribution.update({channel:channelCount})
    
        # Recording bssid's according to their PHY type in a dict with PHY type as key and list of bssid as value        
        if (apType not in apBssid):
            apBssid.update({apType:[bssid]})
        else:
            bssidList=apBssid.get(apType)
            if(bssid not in bssidList):  #Storing only unique bssids per Access Point
                bssidList.append(bssid)
                apBssid.update({apType:bssidList})
        
        
        # Recording phy distribution in a dict with phy as key and number of packets as value 
        if(phy not in phyDistribution):
            phyDistribution.update({phy:1})     
        else:
            phyCount=phyDistribution.get(phy)
            phyCount+=1
            phyDistribution.update({phy:phyCount})

        #Recording Channel Width distribution
        if (channelWidth not in widthBssid):
            widthBssid.update({channelWidth:[bssid]})
        else:
            bssidList=widthBssid.get(channelWidth)
            if(bssid not in bssidList):
               bssidList.append(bssid)
               widthBssid.update({channelWidth:bssidList}) 

    for key,value in apBssid.iteritems():
        apDistribution.update({key:len(value)})

    for key,value in widthBssid.iteritems():
        channelWidthDistribution.update({key:len(value)})

    # Sorting the Dicts based on Value
    orderedChannelDistribution=collections.OrderedDict(sorted(channelDistribution.items(), key=lambda t:t[1], reverse=True))
    orderedPhyDistribution=collections.OrderedDict(sorted(phyDistribution.items(), key=lambda t:t[1], reverse=True))
    orderedAPDistribution=collections.OrderedDict(sorted(apDistribution.items(), key=lambda t:t[1], reverse=True))
    orderedWidthDistribution=collections.OrderedDict(sorted(channelWidthDistribution.items(), key=lambda t:t[1], reverse=True))
    
    #Setting up Bar graph for Channel Distribution
    labels1 = map(str,orderedChannelDistribution.keys())
    values1 = orderedChannelDistribution.values()
    trace1 = go.Bar(x=labels1, y=values1, name='Channel Distribution')
    
    #Setting up Bar Graph for Phy Distribution
    labels2 = orderedPhyDistribution.keys()
    values2 = orderedPhyDistribution.values()
    trace2 = go.Bar(x=labels2, y=values2, name='Message Phy Distribution')

    #Setting the Bar Graph for PHY Types of Access points
    labels3 = orderedAPDistribution.keys()
    values3 = orderedAPDistribution.values()
    trace3 = go.Bar(x=labels3, y=values3, name='Router Phy Distribution')

    #Setting the Bar Graph for Channel Width Distribution
    labels4 = orderedWidthDistribution.keys()
    values4 = orderedWidthDistribution.values()
    trace4 = go.Bar(x=labels4, y=values4, name='Router Channel Width Distribution')

    #Creating the Graph
    fig5 = tools.make_subplots(rows=2, cols=2, subplot_titles=('Channel Distribution', 'Message Phy Distribution',
                                                          'Router Phy Distribution', 'Router Channel Width Distribution'))
    fig5.append_trace(trace1, 1, 1)
    fig5.append_trace(trace2, 1, 2)
    fig5.append_trace(trace3, 2, 1)
    fig5.append_trace(trace4, 2, 2)

    fig5['layout']['xaxis1'].update(title='Channel Type',type='category')
    fig5['layout']['xaxis2'].update(title='PHY Type')
    fig5['layout']['xaxis3'].update(title='PHY Type')
    fig5['layout']['xaxis4'].update(title='Channel Width in MHz',type='category')

    fig5['layout']['yaxis1'].update(title='Number of Packets')
    fig5['layout']['yaxis2'].update(title='Number of Packets')
    fig5['layout']['yaxis3'].update(title='Number of Routers')
    fig5['layout']['yaxis4'].update(title='Number of Routers')

    fig5['layout'].update(title=os.path.splitext(file)[0])

    #Plotting the graph
    offline.plot(fig5, filename=os.path.splitext(file)[0],image_filename=os.path.splitext(file)[0],image='jpeg')
    