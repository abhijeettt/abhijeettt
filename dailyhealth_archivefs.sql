set serveroutput on   
set linesize 3000
set wrap off
set pagesize 50000
set timing on

--------------- ARCHIVE FILESYSTEM CHECK -----------------
DECLARE 
v_odbid number(20);
vr_instance_name VARCHAR2(100); 
vr_host_name  VARCHAR2(100);

BEGIN                  
select name,dbid,host_name into vr_instance_name,v_odbid,vr_host_name from sys.v_$database,sys.v_$instance;

-- checking all type of Objects
-- 

FOR v_arc_disk in (

with arc as
(select
REGEXP_SUBSTR(substr(value,10),'[^/]+',1,1) MOUNT
 from v$parameter
where
name like 'log_archive_dest_%' and
name not like 'log_archive_dest_state%' and
value is not null
and value not like 'SERVICE=%'
and value not like 'LOCATION=+%'
)
select 'DISK' as type,filesystem,blocks,used,available,capacity,mount from rman_mntr_user.DF
where mount in (select '/'||mount from arc);
)

LOOP 

dbms_output.put_line( 'XXARCHIVEXX' || '|' ||v_odbid ||'|'|| vr_instance_name ||'|'|| vr_host_name ||'|'||v_arc_disk.type||'|'|| v_arc_disk.filesystem ||'|'||v_arc_disk.blocks ||'|'||v_arc_disk.used||'|'||v_arc_disk.available||'|'||v_arc_disk.capacity||'|'||v_arc_disk.mount);	

END LOOP;
END ;     
/

FOR v_arc_asm in (

with arc_asm as
(select
REGEXP_SUBSTR(REGEXP_SUBSTR(substr(value,10),'[^/]+',1,1),'[^+]+',1,1) MOUNT
 from v$parameter
where
name like 'log_archive_dest_%' and
name not like 'log_archive_dest_state%' and
value is not null
and value not like 'SERVICE=%'
and value not like 'LOCATION=/%'
union
select
REGEXP_SUBSTR(substr(value,11),'[^ V]+',1,1) MOUNT
 from v$parameter
where
name like 'log_archive_dest_%' and
name not like 'log_archive_dest_state%' and
value is not null
and value not like 'SERVICE=%'
and value not like 'LOCATION=/%'
)
SELECT 'ASM' as type,name as filesystem,
round(total_mb/1024,1) as blocks,
round(cold_used_mb/1024,1) as used,
round( free_mb/1024,1) as available,
ROUND((TOTAL_MB-FREE_MB)/TOTAL_MB*100) as capacity,'+'||
name as mount
FROM V$ASM_DISKGROUP
where name in (select mount from arc_asm);


LOOP 

dbms_output.put_line( 'XXARCHIVEXX' || '|' ||v_odbid ||'|'|| vr_instance_name ||'|'|| vr_host_name ||'|'||arc_asm.type||'|'|| arc_asm.filesystem ||'|'||arc_asm.blocks ||'|'||arc_asm.used||'|'||arc_asm.available||'|'||arc_asm.capacity||'|'||arc_asm.mount);	

END LOOP;
END ;     
/

exit ; 