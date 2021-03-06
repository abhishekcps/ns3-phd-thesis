# Creation of the wavefront timeline using a single execution file
# parses the traces file and look for Received BPDUs
# creates an output file with a table: col1=>bpdu.rootId col2=>time

# use from output folder:
# awk -f rstp_wavefront_timeline.awk n64_grid4_rstp_txHld1_1000000_rnd_r0_srX_f0-all_0.txt > rstp_wavefront_timeline.txt

BEGIN{
  cold_start=0;
  failure=1;
  rootfailure=1;
  
  if(cold_start==1) capture=1;
  if(failure==1) capture=0;
}

# key input parameters that vary
/numNodes/          		  { num_nodes=$2} 
/forcedRootNode/   			  { forced_root_node=$2}
/nodeAToFail/     			  { node_a_to_fail=$2} 
/nodeBToFail/        		  { node_b_to_fail=$2}

# check before/after failure
/EthPointToPointChannel\(\): Failed Link/{
  if(failure==1) capture=1;
  time_link_failure=$1;
}

# Match nodeId<=>bridgeId
#########################
/Installing RSTP with bridge Id/{
  split($1,a,"[");
  split(a[2],b,"]");

  bridgeId2nodeId[$8]=b[1]
  nodeId2bridgeId[b[1]]=$8
}  

# BPDU counters
###############
/Recvs BPDU/{
  if(capture==1)
    {
      split($6,a,"|");
      split(a[1],b,":");
      split(a[5],c,":");
 
      if(cold_start==1) print b[2],"\t",$1
      if(failure==1) print b[2],"\t",$1-time_link_failure,"\t",c[2]
    }
}

# CONF counters
###############
/Recvs CONF/{
  if(capture==1)
    {
      if(cold_start==1) print "C","\t",$1,"\t",-1
      if(failure==1) print "C","\t",$1-time_link_failure,"\t",-1
    }
}

# special events
################
/Periodical BPDUs/{
  if(rootfailure==0) if($1!="0ns") capture=0;
}

END{
}

