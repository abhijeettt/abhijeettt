

SET ECHO OFF TERMOUT OFF 
ALTER SESSION SET NLS_NUMERIC_CHARACTERS=".'"; 
#SET MARKUP HTML ON SPOOL ON 
set markup HTML ON HEAD "<style type='text/css'> -
body { -
font:10pt Arial,Helvetica,sans-serif; color:blue; background:White; } -
p { font:8pt Arial,sans-serif; color:grey; background:white; } -
table,tr,td { font:10pt Arial,Helvetica,sans-serif; text-align:left; -
color:Black; background:white; padding:0px 0px 0px 0px; margin:0px 0px 0px 0px; } -
th { font:bold 10pt Arial,Helvetica,sans-serif; ; text-align:left;color:#336699; background:#cccc99; padding:0px 0px 0px 0px;} -
h1 { font:16pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; -
border-bottom:1px solid #cccc99; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;} -
h2 { font:bold 10pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; -
margin-top:4pt; margin-bottom:0pt;} -
a { font:9pt Arial,Helvetica,sans-serif; color:#663300; background:#ffffff; margin-top:0pt; margin-bottom:0pt; vertical-align:top;} -
.threshold-critical { font:bold 10pt Arial,Helvetica,sans-serif; color:red; } -
.threshold-warning { font:bold 10pt Arial,Helvetica,sans-serif; color:orange; } -
.threshold-ok { font:bold 10pt Arial,Helvetica,sans-serif; color:green; } -
.row:nth-child(even) { background: #dde; } -
.row:nth-child(odd) { background: yellow; } -
</style> -
<title>CITDBA DAILY HEALTH REPORT</title>" -
BODY "" - 
TABLE "border='1' width='90%' align='left'" -

ENTMAP OFF SPOOL ON

SET LINESIZE 200 PAGESIZE 200 embedded ON WRAP ON RECSEP WRAPPED RECSEPCHAR "-" UNDERLINE "=" HEADING ON AUTOPRINT ON 
SET AUTOTRACE OFF TERMOUT ON NEWPAGE 0

SET TRIMSPOOL ON

--  
COLUMN global_name new_value v_global_name  NOPRINT  
COLUMN datum       new_value v_datum        NOPRINT  
COLUMN rptnum      new_value v_rptnum       NOPRINT  
COLUMN rptnum1     new_value v_rptnum1      NOPRINT  
COLUMN gdesc       new_value v_gdesc        NOPRINT  
COLUMN gdesc1      new_value v_gdesc1       NOPRINT  
COLUMN gdesc2      new_value v_gdesc2       NOPRINT  


SELECT TO_CHAR(SYSDATE, 'DD/MM/YYYY') AS DATUM FROM dual;

select count(1) as rptnum from RMAN_MNTR_USER.INV_STATUS_EXT_TBL;

--  
	TTITL " " -
SKIP 1 LEFT  " " -
SKIP 1	LEFT 'CITDBA'        CENTER 'DATABASE DB CHECK REPORT for CRITICAL databases'                
SKIP 1 LEFT '======'        CENTER "==============================="           
SKIP 1 LEFT  " " -
SKIP 1 LEFT  " " -
SKIP 1 LEFT  " " -


COLUMN type       FORMAT A10       HEADING 'type'                     JUSTIFY LEFT
COLUMN ODBNAME    FORMAT A12       HEADING 'DB-NAME'                     JUSTIFY LEFT
--COLUMN HOST_NAME   FORMAT A20       HEADING 'HOSTNAME'                     JUSTIFY LEFT

set feedback off
set ENTMAP on
COL HOST_NAME FOR A15

spool /wfmarc_sys/oracle/availabilityreports/prod/dailyhealth/dailyhealth.html;


with query_backup as
(SELECT distinct B.DB_NAME,
(CASE
when ((select count(*) from RMAN_MNTR_USER.DAILYHEALTH_BACKUP_V1 SQ1 where SQ1.STATUS='RUNNING' and ODBNAME=B.DB_NAME)>0)
 then '<strong><font color="green" face="Comic Sans MS" size=2>'||'RUNNING'||'</font></strong>'
WHEN ( (select count(*) from RMAN_MNTR_USER.DAILYHEALTH_BACKUP_V1 SQ1 where SQ1.STATUS='FAILED' AND SQ1.ODBNAME=B.DB_NAME )=0 AND
(select count(*) from RMAN_MNTR_USER.DAILYHEALTH_BACKUP_V1 SQ1 where SQ1.ODBNAME=B.DB_NAME )>=2
 --(select ENV from RMAN_MNTR_USER.DBA_CATALOG_MAIN_VIEW_P1 where DB_NAME=B.DB_NAME)='PRIMARY'
 ) then 'Good'
 	---- below can used when any one backup is FAILED status and want to COMMENT it	(@ 18may2018)
 	    when ((select count(*) from RMAN_MNTR_USER.DAILYHEALTH_BACKUP_V1 SQ1 where SQ1.STATUS='FAILED'  and ODBNAME=B.DB_NAME and
	    DB_NAME='XXXX')>0)  --- > Here goes the failed database name
 	    then 'Good'
 	------------//
 when ((select count(*) from RMAN_MNTR_USER.DAILYHEALTH_BACKUP_V1 SQ1 where SQ1.STATUS='FAILED'  and ODBNAME=B.DB_NAME)>0)
 then '<strong><font color="red" face="Comic Sans MS" size=2>'||'FAILED'||'</font></strong>'
else '<strong><font color="olive" face="Comic Sans MS" size=2>'||'NO BACKUP'||'</font></strong>'  END)   BACKUP
--edited on 3rd feb 2018 to make color for NOBACKUP
--else 'NO BACKUP' END)   BACKUP
FROM RMAN_MNTR_USER.DBA_CATALOG_MAIN_VIEW_P1 B LEFT JOIN RMAN_MNTR_USER.DAILYHEALTH_BACKUP_V1 A   ON A.ODBNAME=B.DB_NAME
--and B.ENV='STANDBY'
order by 1
),
query_cpu as
(SELECT  B.DB_NAME,(
CASE
WHEN ((select min(Percentage_idle) from RMAN_MNTR_USER.DAILYHEALTH_CPU  WHERE ODBNAME = B.DB_NAME) > 50
)
THEN 'Good'
WHEN ((
select min(Percentage_idle) from RMAN_MNTR_USER.DAILYHEALTH_CPU WHERE ODBNAME = B.DB_NAME ) <= 50
)
THEN '<strong><font color="red" face="Comic Sans MS" size=2>'||'Idle CPU '||min(Percentage_idle)||'% '||'</font></strong>'
ELSE 'N/A'
END
)
CPU
FROM RMAN_MNTR_USER.DBA_CATALOG_MAIN_VIEW_P1 B
LEFT JOIN RMAN_MNTR_USER.DAILYHEALTH_CPU A ON A.ODBNAME = B.DB_NAME
group BY B.DB_NAME
ORDER BY 1
),
query_lfs as
(SELECT  B.DB_NAME,(
CASE
WHEN ((select max(LFS_MS) from RMAN_MNTR_USER.DAILYHEALTH_LFS  WHERE ODBNAME = B.DB_NAME) <15
)
THEN 'Good '||max(LFS_MS)||'ms '
WHEN ((
select max(LFS_MS) from RMAN_MNTR_USER.DAILYHEALTH_LFS WHERE ODBNAME = B.DB_NAME ) >15
)
THEN '<strong><font color="red" face="Comic Sans MS" size=2>'||'Chk '||max(LFS_MS)||'ms '||'</font></strong>'
ELSE 'N/A'
END
)
lfs
FROM RMAN_MNTR_USER.DBA_CATALOG_MAIN_VIEW_P1 B
LEFT JOIN RMAN_MNTR_USER.DAILYHEALTH_LFS A ON A.ODBNAME = B.DB_NAME
group BY B.DB_NAME
ORDER BY 1
),
query_blk as
(SELECT  B.DB_NAME,(
CASE
WHEN ((select count(*) from RMAN_MNTR_USER.DAILYHEALTH_BLK  WHERE ODBNAME = B.DB_NAME) =0
)
THEN 'Good '
WHEN ((
select count(*) from RMAN_MNTR_USER.DAILYHEALTH_BLK WHERE ODBNAME = B.DB_NAME ) >0
)
THEN '<strong><font color="red" face="Comic Sans MS" size=2>'||count(*)||' Bloking '||'</font></strong>'
ELSE 'N/A'
END
)
blk
FROM RMAN_MNTR_USER.DBA_CATALOG_MAIN_VIEW_P1 B
LEFT JOIN RMAN_MNTR_USER.DAILYHEALTH_BLK A ON A.ODBNAME = B.DB_NAME
group BY B.DB_NAME
ORDER BY 1
),
archive_fs as (
SELECT
B.DB_NAME,
(
CASE
WHEN ((select max(capacity) from RMAN_MNTR_USER.dailyhealth_ARCHIVEFS  WHERE ODBNAME = B.DB_NAME) <= 75
)
THEN 'Good '|| max(capacity)||'%'
WHEN ((
select max(capacity) from RMAN_MNTR_USER.dailyhealth_ARCHIVEFS WHERE ODBNAME = B.DB_NAME ) > 75
)
THEN '<strong><font color="red" face="Comic Sans MS" size=2>'||max(capacity)||'% '||'</font></strong>'
ELSE 'N/A'
END
)
archivefs
FROM RMAN_MNTR_USER.DBA_CATALOG_MAIN_VIEW_P1 B
LEFT JOIN RMAN_MNTR_USER.dailyhealth_ARCHIVEFS A ON A.ODBNAME = B.DB_NAME
group BY B.DB_NAME
),
query_session as
(
SELECT
B.DB_NAME,
(
CASE
WHEN ((select max(PS_PERCENT) from RMAN_MNTR_USER.dailyhealth_SESSION  WHERE ODBNAME = B.DB_NAME) <= 75
)
THEN 'Good '||max(PS_PERCENT)||'%'
WHEN ((
select max(PS_PERCENT) from RMAN_MNTR_USER.dailyhealth_SESSION WHERE ODBNAME = B.DB_NAME ) > 75
)
THEN '<strong><font color="red" face="Comic Sans MS" size=2>'||max(PS_PERCENT)||'% '||'</font></strong>'
ELSE 'N/A'
END
)
session_cnt
FROM RMAN_MNTR_USER.DBA_CATALOG_MAIN_VIEW_P1 B
LEFT JOIN RMAN_MNTR_USER.dailyhealth_SESSION A ON A.ODBNAME = B.DB_NAME
group BY B.DB_NAME
),
server_grouping as
(
select rtrim(db_name) db_name,
rtrim (xmlagg (xmlelement (e, SERVER_NAME || '/')).extract ('//text()'), '/') SERVER_NAME
from dba_catalog_main
where CATEGORY='P1'
AND MONITOR='Y'
AND UPPER(ENV) IN ('PROD','PRE-PROD','NEW-19C')
GROUP BY DB_NAME
)
select i.DB_NAME,
--,i.DBA,i.ENV,
b.backup,a.cpu AS "CPU_50%",c.lfs AS "logsyc_15ms",d.blk as "Bloking",e.archivefs as "ArchFS(75%)",f.session_cnt as "Ses/Pros%",upper(g.SERVER_NAME) SERVER_NAME
--select i.DB_NAME,i.ENV,b.backup,a.cpu AS "CPU_2Hr_50%",c.lfs AS "logsyc_15ms",d.blk as "Bloking"
--select i.DB_NAME,i.ENV,b.backup,a.cpu ,c.lfs,d.blk as "Bloking"
from
RMAN_MNTR_USER.DBA_CATALOG_MAIN_VIEW_P1 i
INNER JOIN QUERY_CPU a ON i.DB_NAME=a.DB_NAME
INNER JOIN query_backup b ON i.DB_NAME=b.DB_NAME
INNER JOIN query_lfs c ON i.DB_NAME=c.DB_NAME
INNER JOIN query_blk d ON i.DB_NAME=d.DB_NAME
INNER JOIN archive_fs e ON i.DB_NAME=e.DB_NAME
INNER JOIN query_session f ON i.DB_NAME=f.DB_NAME
INNER JOIN server_grouping g ON i.DB_NAME=g.DB_NAME
order by 2,6,7,5,1;


set heading off
SELECT '<strong><font color="black" face="Arial Black" size=3>'||'     ---------------- STANDBY REPORT --------------------'
||'</font></strong>'
 FROM DUAL;
set headin on

SELECT DISTINCT
      C.ODBID "DBID",
	--i.DBA,
     E.OINSTANCENAME "INSTANCE"
    ,E.OHOST_NAME  "HOSTNAME"
    --,E.CURRENT_SCN
    --,E.TODAYSYSDATE
    ,E.DIFFINHOUR||' Hrs '||E.DIFFINMIN||' Min '||E.DIFFINSEC||' Sec ' as "LAG DIFFERENCE"
	, (CASE WHEN (E.DIFFINHOUR=0 AND E.DIFFINMIN<=5) THEN '<strong><font color="green" face="Arial Black" size=2>'||'IN SYNC '||'</font></strong>'
	ELSE '<strong><font color="red" face="Arial Black" size=2>'||'NOT-IN-SYNC '||'</font></strong>'
	END) "STATUS(<5 Min)"
FROM SBY_SYNC_DBS_CATALOG_INFO C, RMAN_MNTR_USER.SBY_SYNC_EXT_TBL1 E ,RMAN_MNTR_USER.DBA_CATALOG_MAIN_VIEW_P1_SBY i
where
TRIM(C.OINSTANCENAME)=TRIM(E.OINSTANCENAME(+))
and upper(E.OINSTANCENAME)=upper(i.INSTANCE)
and i.ENV='STANDBY'
ORDER BY 5,2;



spool off;
 
exit;




