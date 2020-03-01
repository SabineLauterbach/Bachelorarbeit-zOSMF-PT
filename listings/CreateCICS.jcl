##***************************************************************
##Velocity macro to 
##validate SIT parameters. The following SIT parms
##will be commented out if the user supplies them
##   APPLID
##   CICSSVC
##   CPSMCONN
##   CSDACC
##   CSDBKUP
##   CSDRECOV
##   CSDRLS
##   DFLTUSER
##   JVMPROFILEDIR
##   KEYRING
##   RLS (when needed for shared CSD)
##   SEC
##   SECPRFX
##   SIT
##   SYSIDNT
##   TCPIP
##   USSHOME
##   USSCONFIG
##   XAPPC
##   XCMD
##   XDB2
##   XDCT
##   XFCT
##   XHFS
##   XJCT
##   XPCT
##   XPPT
##   XPSB
##   XPTKT
##   XRES
##   XTRAN
##   XTST
##   XUSER
##***************************************************************
#macro(validateSit $sit)
#if($sit.toUpperCase().startsWith("APPLID") ||
   $sit.toUpperCase().startsWith("CICSSVC") ||
   $sit.toUpperCase().startsWith("CPSMCONN") ||
   $sit.toUpperCase().startsWith("CSDACC") ||
   $sit.toUpperCase().startsWith("CSDRLS") ||
   ($sit.toUpperCase().startsWith("CSDRECOV") 
   && $!{instance-DFH_REGION_LOGSTREAM} == "DUMMY") ||
   ($sit.toUpperCase().startsWith("CSDBKUP") 
   && $!{instance-DFH_REGION_LOGSTREAM} == "DUMMY") ||
   $sit.toUpperCase().startsWith("DFLTUSER") ||
   $sit.toUpperCase().startsWith("JVMPROFILEDIR") ||
   $sit.toUpperCase().startsWith("KEYRING") ||
   ($sit.toUpperCase().matches("^RLS[^A-Z].*$") 
   && $!{instance-DFH_REGION_CSD_TYPE} == "SHAREDRLS") ||
   $sit.toUpperCase().startsWith("SEC") ||
   $sit.toUpperCase().startsWith("SECPRFX") ||
   $sit.toUpperCase().startsWith("SIT") ||
   $sit.toUpperCase().startsWith("SYSIDNT") ||
   $sit.toUpperCase().startsWith("TCPIP") ||
   $sit.toUpperCase().startsWith("USSHOME") ||
   $sit.toUpperCase().startsWith("USSCONFIG") ||
   $sit.toUpperCase().startsWith("XAPPC") ||
   $sit.toUpperCase().startsWith("XCMD") ||
   $sit.toUpperCase().startsWith("XDB2") ||
   $sit.toUpperCase().startsWith("XDCT") ||
   $sit.toUpperCase().startsWith("XFCT") ||
   $sit.toUpperCase().startsWith("XHFS") ||
   $sit.toUpperCase().startsWith("XJCT") ||
   $sit.toUpperCase().startsWith("XPCT") ||
   $sit.toUpperCase().startsWith("XPPT") ||
   $sit.toUpperCase().startsWith("XPSB") ||
   $sit.toUpperCase().startsWith("XRES") ||
   $sit.toUpperCase().startsWith("XTRAN") ||
   $sit.toUpperCase().startsWith("XTST") ||
   $sit.toUpperCase().startsWith("XUSER"))
## Comment out the SIT
*The following SIT parameter is commented out as it clashes with
*a property in the provisioning template.
*$sit
#elseif($sit.toUpperCase().startsWith("GRPLIST") &&
  !$sit.toUpperCase().contains("${csdlist}"))
## Take what they have and append after CICS region specific list
## Obtain the data after the =
#set ($index = $sit.indexOf('='))
#set ($index = $index + 1)
#set ($sitvalue = $sit.substring($index))
## Check the first char if its ( then more work is required
#if($sitvalue.charAt(0) == "(")
#set ($endsit = $sitvalue.length() - 1)
#set ($sitvalue = $sitvalue.substring(1,$endsit))
#end
#if($sitvalue.toUpperCase().startsWith("DFHLIST,"))
#set ($sitvalue = $sitvalue.substring(8))
*The list DFHLIST has been removed from the provided GRPLIST
*specified in the DFH_REGION_SITPARMS 
*property. It is not required.
*The groups from DFHLIST have been added to the list ${csdlist}.
#end
#if(!$sitvalue.toUpperCase().equals("DFHLIST"))
GRPLIST=(${csdlist},$sitvalue)
#else
*The GRPLIST SIT parameter only contains DFHLIST. 
*This list is not
*required. The groups from DFHLIST have been added to the list
*${csdlist}.
*$sit
#end
## End of GRPLIST processing
#else
## Output the SIT as is
$sit
#end
#end
##***************************************************************
#macro(validateEyuparm $eyuparm)
#if($eyuparm.toUpperCase().startsWith("CMASSYSID") ||
   $eyuparm.toUpperCase().startsWith("NAME") ||
   $eyuparm.toUpperCase().startsWith("CICSPLEX"))
## Comment out the EYUPARM
*The following EYU parameter is commented out as it clashes with
*a property in the provisioning template.
*$eyuparm
#else
## Output the EYUPARM as is
$eyuparm
#end
#end
##***************************************************************
//***************************************************************
//**           CICS START PROCEDURE                             *
//**           YYYY                                             *
//***************************************************************
#set ($applid = "${instance-DFH_REGION_APPLID}")
## csdlist auf leer gesetzt um groessere Aenderungen zu vermeiden
#set ($csdlist = "")
//COPY1 EXEC PGM=IEBGENER,MEMLIMIT=0M
//SYSUT2 DD DISP=SHR,
//       DSN=
//     ${instance-DFH_ZOS_PROCLIB}(${instance-DFH_REGION_APPLID})
//SYSPRINT DD SYSOUT=*
//SYSIN  DD *
//SYSUT1 DD DATA,DLM='@@'
//DFHSTART  PROC CICSAPPL='${applid}',                   
//             CICSREL='TS54',                         
//             CPSMREL='TS54',                          
//             START='AUTO',                             
//             PARMLIB='CICS.STARTUP.PARM'                
//**                                                         
//**                                                          
//RMUTL    EXEC PGM=DFHRMUTL,PARM='SYSIN',REGION=1M         
//**                                                        
//STEPLIB  DD  DISP=SHR,DSN=CICS.&CICSREL..SDFHLOAD          
//SYSPRINT DD  SYSOUT=M                                      
//DFHGCD   DD  DISP=SHR,DSN=TCICS.&CICSAPPL..DFHGCD           
//SYSIN    DD  DISP=SHR,DSN=&PARMLIB(&START)                 
//**                                                      
//**                                                       
//CICS     EXEC PGM=DFHSIP,PARM='SYSIN',REGION=0M,        
//            MEMLIMIT=50G
//**
//** Include STEPLIB Libraries ******************************
#set($stladded = 0)
#set ($value1 = $!{instance-DFH_REGION_STEPLIB})
#if($value1 != "")
#foreach( $dataset in $value1.split(","))
#if($stladded == 0)
//STEPLIB  DD DISP=SHR,DSN=$dataset.trim()
#set($stladded = 1)
#else
//         DD DISP=SHR,DSN=$dataset.trim()
#end
#end
#end                
//**
//**CICS DATASETS                         
//**                                  
//** Include the DFHRPL Libraries ***********************
#set($rpladded = 0)
#set ($value2 = $!{instance-DFH_REGION_RPL})
#if($value2 != "")
#foreach( $dataset in $value2.split(","))
#if($rpladded == 0)
//DFHRPL   DD DISP=SHR,DSN=$dataset.trim()
#set($rpladded = 1)
#else
//         DD DISP=SHR,DSN=$dataset.trim()
#end
#end
#end            
//**                                                            
//**        DFHRPL-USER-DATEIEN WERDEN DYNAMISCH VERKETTET     
//**                                                        
//**CICS PARAMETERS
//**
//EYUPARM  DD  DISP=SHR,
//             DSN=CICS.&CPSMREL..CPSM.SEYUPARM.TEST(TESTPLEX)
//DFHINTRA DD  DISP=SHR,DSN=TCICS.&CICSAPPL..DFHINTRA
//DFHTEMP  DD  DISP=SHR,DSN=TCICS.&CICSAPPL..DFHTEMP
//DFHDMPA  DD  DISP=SHR,DSN=TCICS.&CICSAPPL..DFHDMPA
//DFHDMPB  DD  DISP=SHR,DSN=TCICS.&CICSAPPL..DFHDMPB
//DFHGCD   DD  DISP=SHR,DSN=TCICS.&CICSAPPL..DFHGCD
//DFHLCD   DD  DISP=SHR,DSN=TCICS.&CICSAPPL..DFHLCD
//DFHLRQ   DD  DISP=SHR,DSN=TCICS.&CICSAPPL..DFHLRQ
//CIGSSUBM DD  SYSOUT=(A,INTRDR)                   
//**                                              
//**EXTRAPARTION DATA SETS                        
//**                                             
//LOGUSR   DD  SYSOUT=M                          
//MSGUSR   DD  SYSOUT=M                       
//AUDITLOG DD  SYSOUT=M                         
//JVMOUT   DD  SYSOUT=M                     * JVMSERVER STDOUT
//JVMERR   DD  SYSOUT=M                     * JVMSERVER STDERR
//JVMTRACE DD  SYSOUT=M                     * JVMSERVER TRACE 
//SYSUDUMP DD  DUMMY                                        
//SYSABEND DD  DUMMY                                       
//TRACEOUT DD  SYSOUT=M                                    
//PRINTER  DD  SYSOUT=M                                   
//DFHAUXT  DD  DUMMY                                        
//DFHBUXT  DD  DUMMY                                      
//COUT     DD  DUMMY                                    
//DFHCXRF  DD  SYSOUT=M                                   
//**                                                   
//**LE/370-DESTINATIONS                                 
//**                                                   
//CEEMSG   DD  SYSOUT=M                                  
//CEEOUT   DD  SYSOUT=M                                  
//**                                                        
//**CICS REXX DATASETS                                   
//**                                                       
//CICAUTH  DD  DISP=SHR,DSN=CICS.&CICSREL..REXX.SCICCMDS.TEST        
//CICEXEC  DD  DISP=SHR,DSN=CICS.REXX.EXEC.TEST                      
//         DD  DISP=SHR,DSN=CICS.&CICSREL..REXX.SCICEXEC.TEST
//CICUSER  DD  DISP=SHR,DSN=CICS.&CICSREL..REXX.SCICUSER.TEST         
//         DD  DISP=SHR,DSN=CICS.&CICSREL..REXX.SCICPNL.TEST          
//**                                                                  
//**DEBUGTOOL                                                         
//**                                                                  
//EQADPFMB DD  DISP=SHR,DSN=CICS.DEBUG.PROFILES.&CICSAPPL             
//**------------------------------------------------------------------
//**END OF CICS-START PROCEDURE                                       
//**------------------------------------------------------------------
//SYSIN    DD *
* Abend the region if any SIT parameters are invalid
PARMERR=ABEND
****************************************************************
* The SIT parameters in this first section are auto-generated  *
* based on the configured provisioning template properties     *
* GRPLIST=(${csdlist}) unter CICSSVC rausgenommen wegen csdlist*
****************************************************************
SIT=${instance-DFH_REGION_SIT}
#if($!{instance-DFH_REGION_CICSSVC} 
# && $!{instance-DFH_REGION_CICSSVC} !="")
CICSSVC=${instance-DFH_REGION_CICSSVC}
#end
#if($!{instance-DFH_ZFS_MOUNTPOINT} 
# && $!{instance-DFH_ZFS_MOUNTPOINT} != "")
JVMPROFILEDIR=${instance-DFH_ZFS_MOUNTPOINT}/
${instance-DFH_REGION_APPLID}/JVMProfiles
#end
#if($!{instance-DFH_REGION_LOGSTREAM} == "DUMMY")
START=INITIAL
#else
START=AUTO
#end
#if($!{instance-DFH_REGION_CSD_TYPE} == "NORLSREADWRITE")
CSDRLS=NO
#else
#if($!{instance-DFH_REGION_CSD_TYPE} == "SHAREDRLS")
CSDRLS=YES
#else
CSDRLS=NO
#if($!{instance-DFH_REGION_LOGSTREAM} == "DUMMY")
CSDRECOV=NONE
CSDBKUP=STATIC
#end
#end
#end
#if($!{instance-DFH_REGION_CSD_TYPE} == "SHAREDREADONLY")
CSDACC=READONLY
#else
CSDACC=READWRITE
#end
TRANISO=YES
IRCSTRT=YES
ISC=YES
APPLID=${instance-DFH_REGION_APPLID}
SYSIDNT=${instance-DFH_REGION_SYSIDNT}
DFLTUSER=${instance-DFH_REGION_DFLTUSER}
USSHOME=${instance-DFH_CICS_USSHOME}
USSCONFIG=${instance-DFH_CICS_USSCONFIG}
TCPIP=YES
## Security Settings
#if(${instance-DFH_REGION_SEC} == "YES")
SEC=YES
#if($!{instance-DFH_REGION_XAPPC} 
# && $!{instance-DFH_REGION_XAPPC} != "")
XAPPC=${instance-DFH_REGION_XAPPC}
#end
#if($!{instance-DFH_REGION_XCMD} 
# && $!{instance-DFH_REGION_XCMD} != "")
XCMD=${instance-DFH_REGION_XCMD}
#end
#if($!{instance-DFH_REGION_XDB2} 
# && $!{instance-DFH_REGION_XDB2} != "")
XDB2=${instance-DFH_REGION_XDB2}
#end
#if($!{instance-DFH_REGION_XDCT} 
# && $!{instance-DFH_REGION_XDCT} != "")
XDCT=${instance-DFH_REGION_XDCT}
#end
#if($!{instance-DFH_REGION_XFCT} 
# && $!{instance-DFH_REGION_XFCT} != "")
XFCT=${instance-DFH_REGION_XFCT}
#end
#if($!{instance-DFH_REGION_XHFS} 
# && $!{instance-DFH_REGION_XHFS} != "")
XHFS=${instance-DFH_REGION_XHFS}
#end
#if($!{instance-DFH_REGION_XJCT} 
# && $!{instance-DFH_REGION_XJCT} != "")
XJCT=${instance-DFH_REGION_XJCT}
#end
#if($!{instance-DFH_REGION_XPCT} 
# && $!{instance-DFH_REGION_XPCT} != "")
XPCT=${instance-DFH_REGION_XPCT}
#end
#if($!{instance-DFH_REGION_XPPT} 
# && $!{instance-DFH_REGION_XPPT} != "")
XPPT=${instance-DFH_REGION_XPPT}
#end
#if($!{instance-DFH_REGION_XPSB} 
# && $!{instance-DFH_REGION_XPSB} != "")
XPSB=${instance-DFH_REGION_XPSB}
#end
#if($!{instance-DFH_REGION_XPTKT} 
# && $!{instance-DFH_REGION_XPTKT} != "")
XPTKT=${instance-DFH_REGION_XPTKT}
#end
#if($!{instance-DFH_REGION_XRES} 
# && $!{instance-DFH_REGION_XRES} != "")
XRES=${instance-DFH_REGION_XRES}
#end
#if($!{instance-DFH_REGION_XTRAN} 
# && $!{instance-DFH_REGION_XTRAN} != "")
XTRAN=${instance-DFH_REGION_XTRAN}
#end
#if($!{instance-DFH_REGION_XTST} 
# && $!{instance-DFH_REGION_XTST} != "")
XTST=${instance-DFH_REGION_XTST}
#end
#if($!{instance-DFH_REGION_XUSER} 
# && $!{instance-DFH_REGION_XUSER} != "")
XUSER=${instance-DFH_REGION_XUSER}
#end
#else
SEC=NO
#end
##
## Is an MQCONN required
##
#if($!{instance-DFH_MQ_SSID} && $!{instance-DFH_MQ_SSID} != "")
MQCONN=YES
#end
## Is a DB2CONN required
##
#if($!{instance-DFH_DB2_HLQ} && $!{instance-DFH_DB2_HLQ} != "")
DB2CONN=YES
#end
##
## Setup the SIT PARAMETERS
##
****************************************************************
* The SIT parameters below this line were provided by the      *
* DFH_REGION_SITPARMS property of the provisioning template.   *
* Some SIT parameters are not allowed to be specified in this  *
* property, as they would overwrite the auto-generated         *
* properties above. Those properties are provided below but    *
* are commented out.                                           *
****************************************************************
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
.END
/*
//
@@
/*