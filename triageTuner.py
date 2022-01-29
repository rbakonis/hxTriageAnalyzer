from asyncio.windows_events import NULL
from time import time
import os
import time
from xml.etree.ElementPath import findtext
import xml.etree.cElementTree as ET


class dns_lookup_event:
  def __init__(self, id, timestamp, hostname, pid, process, username):
    self.timestamp = timestamp
    self.hostname = hostname
    self.pid = pid
    self.proces = process
    self.username = username
    self.id = id

class regKey_event:
  def __init__(self, id, timestamp, hostname, pid, process, username):
    self.timestamp = timestamp
    self.hostname = hostname
    self.pid = pid
    self.process = process
    self.username = username
    self.id = id

class file_event:
  def __init__(self, id, timestamp, hostname, pid, process, username):
    self.timestamp = timestamp
    self.hostname = hostname
    self.pid = pid
    self.process = process
    self.username = username
    self.id = id

class file_event:
  def __init__(self, id, timestamp, hostname, pid, process, username):
    self.timestamp = timestamp
    self.hostname = hostname
    self.pid = pid
    self.process = process
    self.username = username
    self.id = id


dir = os.path.dirname(os.path.realpath(__file__))
file = dir + "\\new.xml"
tree = ET.parse(file)
root = tree.getroot()

dnsEvents = []
processEvents = []
fileEvents = []
registryEvents = []

for item in root:
    type = item.findtext('eventType')
    if type == 'dnsLookupEvent':
        event = dns_lookup_event('','','','','','')
        for d in item.find('details'):
            for gc in d:
                if gc.text == 'hostname':
                    event.hostname = d.findtext('value')
                elif gc.text == 'pid':
                    event.pid = d.findtext('value')
                elif gc.text == 'process':
                    event.process = d.findtext('value')
                elif gc.text == 'username':
                    event.username = d.findtext('value')
        event.timestamp = item.findtext('timestamp')
        event.id = item.attrib['uid']
        dnsEvents.append(event)
    elif type == 'regKeyEvent':
        print('TBD')
    else:
        print('pass')



for event in dnsEvents:
    print("ID:", event.id)
    print("Host:", event.hostname)
    print("PID:", event.pid)
    print("Process:", event.process)
    print("User:", event.username)
    print("Timestamp:", event.timestamp)


        # if len(child):
        #     for gc in child:
        #         if len(gc):
        #             for d in gc:
        #                 print(gc.tag,': ',d.text)
        # else:
        #     print(child.text)
        #     type = 

