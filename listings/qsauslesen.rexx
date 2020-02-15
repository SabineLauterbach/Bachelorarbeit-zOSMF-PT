i=0
#set ($names = $!{instance-DFH_MQ_QUEUENAMES})
#set ($multipart = "NO")
#set ($tempStr = "")
#if($names != "")
#foreach( $queue in $names.split(","))
i=i+1
names.i="$queue"
#end
#end
names.0=i