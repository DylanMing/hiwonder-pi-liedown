#!/usr/bin/env python3
"""Send mDNS browse queries for common services on the local segment."""
import socket, struct, sys, time

def build_query(name):
    # PTR query, IN class
    q = b''
    for label in name.split('.'):
        q += bytes([len(label)]) + label.encode()
    q += b'\x00'
    q += struct.pack('>HH', 12, 1)  # type PTR, class IN
    header = struct.pack('>HHHHHH', 0, 0, 1, 0, 0, 0)
    return header + q

services = ['_ssh._tcp.local', '_http._tcp.local', '_workstation._tcp.local', '_ros._tcp.local']
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
mreq = socket.inet_aton('224.0.0.251') + socket.inet_aton('0.0.0.0')
try:
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
except Exception as e:
    print('multicast join failed:', e)
sock.settimeout(3.0)
sock.bind(('', 5353))

import threading
responses = []
deadline = time.time() + 6
for svc in services:
    try:
        sock.sendto(build_query(svc), ('224.0.0.251', 5353))
    except Exception as e:
        print('send failed:', e)
end = time.time() + 3
while time.time() < end:
    try:
        data, addr = sock.recvfrom(4096)
        responses.append((addr, data))
    except socket.timeout:
        break

print(f'got {len(responses)} mDNS packets')
seen = set()
for addr, data in responses:
    if addr in seen: continue
    seen.add(addr)
    print('from', addr[0])
    # crude: extract printable names from packet
    import re
    txt = data.decode('latin1')
    names = re.findall(r'[A-Za-z0-9_-]+\.local', txt)
    if names: print('   names:', set(names))
    ancount = struct.unpack('>H', data[6:8])[0]
    print('   answers:', ancount, 'bytes:', len(data))
