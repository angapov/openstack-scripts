#!/usr/bin/env python
import json
import os
import glob
import re
from pprint import pprint
PATH="/root/angapov/randrw2/"
FILE_PATTERN="*.json"
CPU_LOG_PATTERN="cpu.log."
HOSTS = ['localhost', 'slpeah001']
t = "\t"
logs = {}
for host in HOSTS:
    for file in glob.glob(PATH + CPU_LOG_PATTERN + host):
        with open(file) as log_data:
            logs[host] = log_data.readlines()
hosts_header = "\t".join(['CPU(' + host + '),%' for host in HOSTS] + ['RAM('+ host+'),GB' for host in HOSTS])

print "Name" +t+ "%READ" +t+ "bs" +t+ "QD" +t+ "R_IOPS" +t+ "R_BANDW(MB/s)" +t+ "R_LATENCY(ms)" +t+ "W_IOPS" +t+ "W_BANDW(MB/s)" +t+ "W_LATENCY(ms)" +t+ hosts_header
for file in sorted(glob.glob(PATH + FILE_PATTERN)):
  os.system("sed -i '/rbd.*/d' " + file)
  json_data = open(file)
  try:
    data = json.load(json_data)
  except ValueError:
    print file + " cannot be parsed"
  job = {}
  job["name"]  = file.split('/')[-1].replace('.json','')
  job["QD"]    = str(max(data["jobs"][0]["iodepth_level"], key=data["jobs"][0]["iodepth_level"].get))
  job["bs"]    = job["name"].split("-")[-1][2:4]
  read         = re.search(r'\d+$', job["name"].split("-")[-2])
  job["%read"] = read.group()
  job['CPU']           = str(data["jobs"][0]["usr_cpu"] + data["jobs"][0]["sys_cpu"])
  if data["jobs"][0]["read"]["runtime"] > 0:
    job["r_iops"]        = str(data["jobs"][0]["read"]["iops"])
    job["r_bw_mean"]     = str(round(data["jobs"][0]["read"]["bw_mean"]/1024.0, 2))
    job["r_bw_stddev"]   = str(round(data["jobs"][0]["read"]["bw_dev"]/1024.0, 2))
    job["r_lat_median"]  = str(round(data["jobs"][0]["read"]["clat"]["percentile"]["50.000000"]/1024.0, 1))
    job["r_lat_stddev"]  = str(data["jobs"][0]["read"]["clat"]["stddev"])
  else:
    job["r_iops"] = job["r_bw_mean"] = job["r_bw_stddev"] = job["r_lat_median"] = job["r_lat_stddev"] = "-"
  if data["jobs"][0]["write"]["runtime"] > 0:
    job["w_iops"]        = str(data["jobs"][0]["write"]["iops"])
    job["w_bw_mean"]     = str(round(data["jobs"][0]["write"]["bw_mean"]/1024.0, 2))
    job["w_bw_stddev"]   = str(round(data["jobs"][0]["write"]["bw_dev"]/1024.0, 2))
    job["w_lat_median"]  = str(round(data["jobs"][0]["write"]["clat"]["percentile"]["50.000000"]/1024.0, 1))
    job["w_lat_stddev"]  = str(data["jobs"][0]["write"]["clat"]["stddev"])
  else:
    job["w_iops"] = job["w_bw_mean"] = job["w_bw_stddev"] = job["w_lat_median"] = job["w_lat_stddev"] = "-"
  json_data.close()
  j = job["name"]
  duration, load, mem = {}, {}, {}
  duration[j], load[j], mem[j] = {}, {}, {}
  for host in HOSTS:
    duration[j][host], load[j][host], mem[j][host] = [], [], []
    for line in logs[host]:
        if j in line:
            #duration[j][host].append(float(line.split('\t')[0]))
            load    [j][host].append(int(float(line.split('\t')[1])))
            mem     [j][host].append(float(line.split('\t')[2]))
    #print j +t+ str(max(duration[j][host]) - min(duration[j][host])) +t+ str(sum(load[j][host])/len(load[j][host]))  +t+ str(sum(mem[j][host])/len(mem[j][host]))
  #durations = "\t".join([str(max(duration[j][host]) - min(duration[j][host]))   for host in HOSTS])
  loads     = "\t".join([str(sum(load[j][host])/len(load[j][host])) for host in HOSTS])
  mems      = "\t".join([str("%.2f" % (sum(mem[j][host])/len(mem[j][host])/1048576))   for host in HOSTS])
  print job["name"] +t+ job["%read"] +t+ job["bs"] +t+ job["QD"] +t+ job["r_iops"] +t+ job["r_bw_mean"] +t+ job["r_lat_median"] +t+ job["w_iops"] +t+ job["w_bw_mean"] +t+ job["w_lat_median"] +t+ loads +t+ mems 
