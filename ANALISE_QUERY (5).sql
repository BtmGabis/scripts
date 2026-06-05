set lines 1000
set trimspool on
set pagesize 300
set long 2000
col plan_table_output for a200 heading operation 


spool c:\temp\analise_query_8tf1hnht7qjsx.txt

prompt --> Ultimo PLAN_HASH_VALUE na V$SQL:	   
select inst_id,SQL_ID,plan_hash_value,executions,end_of_fetch_count,first_load_time,disk_reads,buffer_gets,rows_processed,last_active_time 
from gv$sqlarea where sql_id = TRIM('8tf1hnht7qjsx');


>>>>> Planos em cache	

WITH
p AS (
SELECT plan_hash_value
  FROM gv$sql_plan
 WHERE sql_id = TRIM('8tf1hnht7qjsx')
   AND other_xml IS NOT NULL
 UNION
SELECT plan_hash_value
  FROM dba_hist_sql_plan
 WHERE sql_id = TRIM('8tf1hnht7qjsx')
   AND other_xml IS NOT NULL ),
m AS (
SELECT plan_hash_value,
       SUM(elapsed_time)/SUM(executions) avg_et_secs
  FROM gv$sql
 WHERE sql_id = TRIM('8tf1hnht7qjsx')
   AND executions > 0
 GROUP BY
       plan_hash_value ),
a AS (
SELECT plan_hash_value,
       SUM(elapsed_time_total)/SUM(executions_total) avg_et_secs
  FROM dba_hist_sqlstat
 WHERE sql_id = TRIM('8tf1hnht7qjsx')
   AND executions_total > 0
 GROUP BY
       plan_hash_value )
SELECT p.plan_hash_value,
       ROUND(NVL(m.avg_et_secs, a.avg_et_secs)/1e6, 3) avg_et_secs
  FROM p, m, a
 WHERE p.plan_hash_value = m.plan_hash_value(+)
   AND p.plan_hash_value = a.plan_hash_value(+)
 ORDER BY
       avg_et_secs NULLS LAST;

	   
>>>>HISTORICO DE EXECUÇÕES
select 
b.begin_interval_time         BEGIN, 
a.instance_number             INST,
a.sql_id                      SQL_ID,
a.plan_hash_value             PLAN_HASH,
a.executions_delta            EXEC,
a.rows_processed_delta        ROWS_PROC,
a.buffer_gets_delta           BUFFER_GETS,
a.disk_reads_delta            DISK_READS,
a.elapsed_time_delta/1000000     ELAPSED_TIME,
a.cpu_time_delta/1000000         CPU_TIME,
a.iowait_delta                  IO_WAIT,
a.apwait_delta                  APP_WAIT,
a.ccwait_delta                  CONCUR_WAIT,
a.direct_writes_delta           DIRECT_WRITES,
a.physical_read_requests_delta  PHI_READS_REQ,
a.physical_read_bytes_delta     PHI_READS_BYTES,
a.physical_write_requests_delta PHI_WRITES_REQ,
a.physical_write_bytes_delta    PHI_WRITES_BYTES
from 
dba_hist_sqlstat a,
dba_hist_snapshot b
where 
a.snap_id=b.snap_id and
a.sql_id='8tf1hnht7qjsx'
order by 1 desc; 


>>>Trazer sql _text
select a.instance_number inst_id,
a.snap_id,a.plan_hash_value,
s.sql_id,
to_char(begin_interval_time,'dd-mon-yy hh24:mi') btime,
abs(extract(minute from (end_interval_time-begin_interval_time)) + extract(hour from (end_interval_time-begin_interval_time))*60 + extract(day from (end_interval_time-begin_interval_time))*24*60) minutes,
executions_delta executions,
round(ELAPSED_TIME_delta/1000000/greatest(executions_delta,1),4) "avg duration (sec)" ,
s.sql_fulltext
from dba_hist_SQLSTAT a, dba_hist_snapshot b,Gv$sql s
where a.snap_id=b.snap_id
and a.instance_number=b.instance_number
and s.sql_id = a.sql_id
and a.module = 'Sinacor.APE.AlocacaoUnificada.Administracao.WSer'
order by snap_id desc, a.instance_number;

>>>>Encontrar plano de execução por período

SELECT DISTINCT sql_id, plan_hash_value
FROM dba_hist_sqlstat dhs,
    (
    SELECT /*+ NO_MERGE */ MIN(snap_id) min_snap, MAX(snap_id) max_snap
    FROM dba_hist_snapshot ss
    WHERE ss.begin_interval_time BETWEEN (SYSDATE - &No_Days) AND SYSDATE
    ) s
WHERE dhs.snap_id BETWEEN s.min_snap AND s.max_snap
  AND dhs.sql_id IN ( '&SQLID')


>>>>>Historico execução Query

select SESSION_ID,
       SESSION_SERIAL#,
       SAMPLE_TIME,
	   PROGRAM,
       SQL_ID,
	   pga_allocated/1024/1024,
	   top_level_sql_id,
       SQL_OPNAME,
       SQL_EXEC_START,
	   sql_plan_hash_value,
	   current_obj#,
	   blocking_session,
	   blocking_session_serial#,
	   event
  from 
gv$active_session_history 
--dba_hist_active_sess_history
where 
program='MovimentoDerivativos.WService.exe' 
and SAMPLE_TIME >= TO_DATE('27/06/2022 15:20', 'DD/MM/YYYY HH24:MI') 
--AND SAMPLE_TIME <= TO_DATE('23/06/2022 02:24', 'DD/MM/YYYY HH24:MI') 
order by SAMPLE_TIME

 SELECT H.SAMPLE_TIME,
         U.USERNAME,
         H.PROGRAM,
         H.MODULE,
         S.SQL_TEXT,
         H.SQL_ID,
         H.TOP_LEVEL_SQL_ID,
         H.BLOCKING_SESSION_STATUS
    FROM DBA_HIST_ACTIVE_SESS_HISTORY H, DBA_USERS U, DBA_HIST_SQLTEXT S
   WHERE     H.SAMPLE_TIME >= SYSDATE - 30
         AND H.SQL_ID = S.SQL_ID 
 AND U.USERNAME in ('CORRWIN','SINAWIN')
 AND SAMPLE_TIME >= TO_DATE('21/03/2025 17:25', 'DD/MM/YYYY HH24:MI') 
AND SAMPLE_TIME <= TO_DATE('21/03/2025 17:40', 'DD/MM/YYYY HH24:MI') 
ORDER BY H.SAMPLE_TIME DESC


select sql_fulltext from gv$sqlstats where sql_id='8tf1hnht7qjsx';

prompt --> EXPLAIN

SELECT * FROM TABLE(dbms_xplan.display_cursor('8tf1hnht7qjsx'));

SELECT * FROM TABLE (dbms_xplan.display_cursor ('8tf1hnht7qjsx',NULL,'LAST'));

SELECT RPAD('Inst: '||v.inst_id, 9)||' '||RPAD('Child: '||v.child_number, 11) inst_child, t.plan_table_output
FROM GV$SQL v,
TABLE(DBMS_XPLAN.DISPLAY('gv$sql_plan_statistics_all', NULL, 'ADVANCED ALLSTATS LAST', 'inst_id = '||v.inst_id||' AND sql_id = '''||v.sql_id||''' AND child_number = '||v.child_number)) t
WHERE v.sql_id = '8tf1hnht7qjsx';


SELECT DBMS_SQLTUNE.report_sql_monitor(
  sql_id       => '8tf1hnht7qjsx',
  type         => 'TEXT',
  report_level => 'ALL') AS report
FROM dual;


spool off



