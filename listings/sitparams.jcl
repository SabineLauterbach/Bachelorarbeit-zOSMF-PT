#set ($value5 = $!{instance-DFH_REGION_SITPARMS})
#set ($multipart = "NO")
#set ($tempStr = "")
#if($value5 != "")
#foreach( $sit in $value5.split(","))
#if($multipart == "YES")
#if( $sit.indexOf(')') > 0 )
## Validate SIT
#validateSit($tempStr.concat($sit.trim()))
#set ($multipart = "NO")
#else
#set ($tempStr = $tempStr + $sit.trim() + ",")
#end
#else
#if( $sit.indexOf('(') > 0 && $sit.indexOf(')') == -1 )
#set ($multipart = "YES")
#set ($tempStr = $sit.trim() + ",")
#else
#validateSit($sit.trim())
#end
#end
#end
#end