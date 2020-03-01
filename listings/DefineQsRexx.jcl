//P$PRVMQ1 JOB (6709,00000,30193,00000),KRUG,
//             CLASS=V,MSGCLASS=V,TIME=(4,3),
//             MSGLEVEL=(1,1),REGION=0M,
//             USER=TU11998,NOTIFY=${_step-stepOwnerUpper}
//********************************************************
//*         COPY STEP - IEBGENER -                       *
//********************************************************
//*
//GENER    EXEC PGM=IEBGENER
//*
//SYSPRINT DD SYSOUT=*
//*
//SYSIN    DD DUMMY
//*
//SYSUT2   DD DISP=(NEW,PASS),DSN=&&TMP(TSOREXX),
//             SPACE=(1024,(1000,500,1))
//*
//SYSUT1  DD *,DLM=$$
/*REXX*/
/***************************************************************/
/* Erzeugen AWTB-Queues aus Template (c)NorbertPfister 05/2012 */
/* Ermitteln QSGDISP Template Anpassung NorbertPfister 12/2013 */
/* Wartezeit sleep eingebaut          Norbert Pfister 08/2014  */
/*                                    ............... MM/20JJ  */
/***************************************************************/
/*  Aufruf : "DEFQAWTB" +                                      */
/*             QM(mx00)                         |Ziel-QMGR     */
/*             QN(AWTB.xxxxxxxxxxxxx)           |Queue-Prefix  */
/*             ANZ(NNN)                         |Anzahl Queues */
/*                                                             */
/*  Erzeugen Queues per "DEFINE REPLACE QL(.) LIKE(.)" .       */
/*  REXX connectet mit ME1C und uebergibt                      */
/*  Commands an Ziel-QMGR QM(.)                                */
/*  Der uebergebene Queue-Prefix dient                         */
/*  1.) zum Bilden des Namens der LIKE-Queue: QN+".TEMPLATE"   */
/*  2.) zum Bilden der neuen Queues: QN+".nnnnnn",             */
/*    eine sechstellige                                        */
/*    laufende Nummer beginnend mit 000001 bis Parameter ANZ . */
/***************************************************************/
/* ------------------------------------ */
/* interaktiv                           */
/* ------------------------------------ */
target_qm='${instance-DFH_MQ_TARGET_QUEUEMANAGER}'
source_qm=${instance-DFH_MQ_SOURCE_QUEUEMANAGER}
q_hlq=${instance-DFH_MQ_HLQ}
#if($!{instance-DFH_MQ_ANZAHL})
Loop=${instance-DFH_MQ_ANZAHL}
#else
Loop=03
#end

i=0
#set ($names = $!{instance-DFH_MQ_QUEUENAMES})
#set ($tempStr = "")
#if($names != "")
#foreach( $queue in $names.split(","))
i=i+1
names.i="$queue"
#end
#end
names.0=i

/* ------------------------------------ */                                      
/* Commands generieren                  */                                      
/* ------------------------------------ */                                      
   k    = 0                                                                     
   rcci = RXMQVC('INIT')                                                        
   
    Do i=1 to names.0

      q_name=q_hlq||'.'||names.i||'.'
      select
       when names.i="L1.GPNRBERINFO" then do
       maxdepth=150000
       maxlength=128
       end
       when names.i="L1.KLAMMERINFOLIST" then do
       maxdepth=10000
       maxlength=100
       end
       when names.i="L1.KUNDENPREISINFOLIST" then do
       maxdepth=150000
       maxlength=1300
       end
       when names.i="L1.PABHREFERENZLIST" then do
       maxdepth=100000
       maxlength=100
       end
       otherwise do
       maxdepth=100
       maxlength=100
       end
      end
      rccg = generate()                                                         

    End
                                                                                
   rcct = RXMQVC('TERM')                                                        
                                                                                
   csqout.0 = k                                                                 
                                                                                
   /* aus Batchjob ? */                                                         
   if datatype(Loop,'N') then do                                              
      do ix = 1 to k                                                            
         say csqout.ix                                                          
      end                                                                       
   end                                                                          
   /* interaktiv   ? */                                                         
   else                                                                         
      address $datev "browse stem csqout. 200"                                  
                                                                                
   Exit rccg                                                                    
/* ------------------------------------------------------------*/               
generate:                                                                       
/* ------------------------------------ */                                      
/* Template abfragen                    */                                      
/* ------------------------------------ */                                 
   if rcg > 0 then return rcg                                                   
                                                                                
   Do l=1    to Loop                                                            
                                                                                
      q_new= q_name||Right(l,6,'0')                                         
      command   = "DEFINE REPLACE QL("q_new")",
                  "MAXDEPTH("maxdepth")",
                  "NOTRIGGER",     
                  "MAXMSGL("maxlength")",    
                  "SHARE",      
                  "DEFSOPT(SHARED)",
                  "QDEPTHHI(80)",
                  "QDEPTHLO(40)"
      /* ------------------------------------ */                                
      /* alle 10 Schleifen kurz warten        */                                
      /* ------------------------------------ */                                
      if l//10 = 0 then ,                                                       
         Call Wait 1                                                            
      cmd_qm=target_qm
      rcg = command_send()                                                      
      if rcg > 0 then leave                                                     
      
      rcg = q_test()
      if rcg > 0 then leave
  
   End                                                                          
return rcg                                                              
/* ------------------------------------------------------------*/               
command_send:                                                                   
/* ------------------------------------ */                                      
/* execute commands (only on mainframe) */                                      
/* ------------------------------------ */                                      
k=k+1;csqout.k = Time('l') command                                              
CONN.QM   = "ME1C"                                                              
CONN.CQ   = "ADMIN.PCF."cmd_qm                                               
CONN.RQ   = "SYSTEM.DEFAULT.MODEL.QUEUE"                                        
CONN.TO   = 5000                                                                
rcc = RXMQVC('COMMAND', 'CONN.', command, 'Reply.' )                            
rcc_RXMQVC = word(rcc,1)                                                        
rcc_QMGR   = word(rcc,2)                                                        
rcc_REASON = word(rcc,3)                                                        
                                                                                
do fw = 1 to Reply.0                                                            
   k=k+1;csqout.k = Reply.fw                                                    
end                                                                             
                                                                                
if (rcc_RXMQVC <> 0) | (rcc_QMGR <> 0) then do                                  
  k=k+1;csqout.k = ,                                                            
      'Command' command 'zu' CONN.QM 'fehlgeschlagen:' rcc                      
  return 99                                                                     
end                                                                             
return 0                                                                        
/* ----------------------------------------------------------- */          
Wait: Procedure                                                                 
   call syscalls 'ON'                                                           
   Address syscall 'sleep 'Arg(1)                                               
   return 0                                                                     
/* ----------------------------------------------------------- */          
q_test:
/* ------------------------------------ */                                      
/* einfacher Put und Get auf Queue      */                                      
/* ------------------------------------ */                                      
/*---- OPEN ----*/                                                              
say RXMQCONN( target_qm )                             
oo = mqoo_inquire+mqoo_output+mqoo_input_as_q_def                               
say RXMQOPEN(q_new, oo, 'hobj', 'ood.')                                         
/*---- PUT ----*/                                                               
d.1      = q_new||' Put Get OK'                                                 
d.0      = Length(d.1)                                                          
imd.PER  = MQPER_PERSISTENT                                                     
ipmo.opt = MQPMO_SYNCPOINT  + MQPMO_LOGICAL_ORDER                               
ipmo.VER = 2                                                                    
imd.ver  = MQMD_CURRENT_VERSION                                                 
imd.form = MQFMT_STRING                                                         
imd.MF   = MQMF_MSG_IN_GROUP                                                    
rcc = RXMQPUT( hobj ,'d.', 'imd.', 'omd.', 'ipmo.', 'opmo.')                    
rcc_RXMQPUT = word(rcc,1)                                                       
rcc_QMGR   = word(rcc,2)                                                        
rcc_REASON = word(rcc,3)                                                        
                                                                                
if (rcc_RXMQPUT <> 0 | rcc_QMGR <> 0) then do                                   
  k=k+1;csqout.k=                                                               
     'RXMQPUT ist Fehlgeschlagen: ' rcc                                         
  return 98                                                                     
end                                                                             
/*---- GET ----*/                                                               
immd.ver   = 2                                                                  
immo.opt = MQGMO_FAIL_IF_QUIESCING +,                                           
           MQGMO_WAIT,                                                          
           MQGMO_ALL_MSGS_AVAILABLE +,                                          
           MQGMO_LOGICAL_ORDER+,                                                
           MQGMO_VERSION_2                                                      
data.0     = 300                                                                
data.1     = ''                                                                 
                                                                                
rcc = RXMQGET(Hobj,'data.','immd.','ommd.','immo.','ommo.')                     
rcc_RXMQGET = word(rcc,1)                                                       
rcc_QMGR   = word(rcc,2)                                                        
rcc_REASON = word(rcc,3)                                                        
                                                                                
if (rcc_RXMQGET <> 0 | rcc_QMGR <> 0) then do                                   
  k=k+1;csqout.k=                                                               
     'RXMQGET ist Fehlgeschlagen: ' rcc                                         
  return 97                                                                     
 end                                                                            
else say data.1                                                                 
/*---- CLOSE ----*/                                                             
say RXMQCLOS(hobj,mqco_none)                                                    
say RXMQDISC()                                                                  
return 0                                                                        
$$                                                                              
//*                                                                             
//***************************************************************         
//*         RUN  STEP - IKJEFT01 -                              *         
//***************************************************************         
//*                                                                             
//RUNIT    EXEC PGM=IKJEFT01                                                    
//*                                                                             
//SYSEXEC  DD DISP=(OLD,DELETE),DSN=&&TMP                                       
//*                                                                             
//SYSTSPRT DD SYSOUT=*                                                          
//*                                                                             
//SYSTSIN  DD *                                                                 
  %TSOREXX                                                                      
/*                                                                              
//*                                                                             
//***************************************************************         
