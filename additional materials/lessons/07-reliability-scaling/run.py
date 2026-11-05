"""Four PostgreSQL exercises with step-by-step execution. Only Python's standard library is needed.

Run from any folder: python3 /path/to/live/run.py replica|restore|pool|partitions
The --auto flag is for an uninterrupted run and does not pause for Enter.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import queue
import re
import subprocess
import threading
import time
import uuid

ROOT=Path(__file__).resolve().parent
PROJECT=os.environ.get('LESSON07_PROJECT','postgres-live-students-07')
BASE=['docker','compose','-f',str(ROOT/'compose.yaml'),'-p',PROJECT,'exec','-T','lab']
DB='course_lesson07'
REPORT={}
AUTO=False


def run(args, timeout=50, check=True):
    p=subprocess.run(args,text=True,capture_output=True,timeout=timeout)
    if check and p.returncode:
        raise RuntimeError(p.stderr or p.stdout)
    return p.stdout.strip()


def sql(code,port=5540,pretty=False):
    return run(BASE+['psql','-X','-q','-h','127.0.0.1','-p',str(port),'-U','course',
        '-d','orders' if port==5543 else DB,'-v','ON_ERROR_STOP=1',
        '-P','pager=off',*([] if pretty else ['-A','-t']),'-c',code])


def shell(code):
    return run(BASE+['sh','-ec',code])


def source(name):
    return (ROOT/'show'/name).read_text().strip()


def pause(title,code=''):
    print('\n'+title,flush=True)
    if code:print(code,flush=True)
    if not AUTO:input('\nEnter — выполнить: ')


def wait(fn):
    deadline=time.monotonic()+15
    while time.monotonic()<deadline:
        if fn():return
        time.sleep(.08)
    raise RuntimeError('Условие готовности не выполнено за 15 секунд')


def catch_up():
    token=sql('SELECT pg_current_wal_lsn()')
    wait(lambda:sql(f"SELECT pg_last_wal_replay_lsn()>='{token}'::pg_lsn",5541)=='t')


class Session:
    def __init__(self):
        self.p=subprocess.Popen(BASE+['psql','-X','-qAt','-h','127.0.0.1','-p','5543',
            '-U','course','-d','orders'],stdin=subprocess.PIPE,stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,text=True,bufsize=1)
        self.lines=queue.Queue()
        def collect():
            for line in self.p.stdout:self.lines.put(line.rstrip())
        threading.Thread(target=collect,daemon=True).start()

    def execute(self,code):
        marker='END_'+uuid.uuid4().hex
        self.p.stdin.write(code.rstrip().rstrip(';')+';\n\\echo '+marker+'\n')
        self.p.stdin.flush();lines=[]
        while True:
            line=self.lines.get(timeout=15)
            if line==marker:break
            if line:lines.append(line)
        if any('ERROR:' in x for x in lines):raise RuntimeError('\n'.join(lines))
        return lines

    def close(self):
        self.p.stdin.write('\\q\n');self.p.stdin.flush()
        self.p.wait(timeout=5)


def replica():
    # Exercise reset is limited to this dedicated lesson database.
    sql('SELECT pg_wal_replay_resume()',5541)
    sql("TRUNCATE orders; INSERT INTO orders VALUES(1,42,'created'),(2,7,'paid')")
    catch_up()
    pause('1. Два заказа на primary и реплике. Задерживаем применение WAL.',
          'Replica: SELECT pg_wal_replay_pause();')
    sql('SELECT pg_wal_replay_pause()',5541)
    wait(lambda:sql('SELECT pg_get_wal_replay_pause_state()',5541)=='paused')
    print('Primary: 2 заказа. Replica: 2 заказа. Replay paused.',flush=True)
    try:
        pause('2. Создаём заказ на primary, читаем тот же id с двух серверов.',
              'Primary:\n'+source('01_insert_order.sql')+'\nОба сервера:\n'+source('02_read_order.sql'))
        sql(source('01_insert_order.sql'))
        primary=sql('SELECT count(*) FROM orders WHERE id=42')
        stale=sql('SELECT count(*) FROM orders WHERE id=42',5541)
        print('Primary, строк:',primary,'\nReplica, строк:',stale,flush=True)
        pause('3. Возобновляем replay и повторяем тот же SELECT.',
              'Replica: SELECT pg_wal_replay_resume();\n'+source('02_read_order.sql'))
    finally:
        sql('SELECT pg_wal_replay_resume()',5541)
    catch_up()
    fresh=sql('SELECT count(*) FROM orders WHERE id=42',5541)
    print(sql(source('02_read_order.sql'),5541,pretty=True),flush=True)
    assert (primary,stale,fresh)==('1','0','1')
    REPORT['replica']={'primary':int(primary),'paused_replica':int(stale),'caught_up_replica':int(fresh),'orders_after':3}


def restore():
    sql("INSERT INTO orders VALUES(1,42,'created'),(2,7,'paid'),(42,42,'created') ON CONFLICT(id) DO UPDATE SET status=excluded.status")
    catch_up()
    target='before_delete_'+uuid.uuid4().hex[:8]
    point=source('03_restore_point.sql').replace('before_delete',target)
    pause('1. Базовая копия уже готова. Отмечаем состояние трёх заказов до удаления.',point)
    sql(point)
    print(sql(source('05_restored_orders.sql'),pretty=True),flush=True)
    pause('2. Ошибочно удаляем заказы. Проверяем primary и реплику.',source('04_delete_orders.sql'))
    print(sql(source('04_delete_orders.sql'),pretty=True),flush=True)
    catch_up()
    replica_count=int(sql('SELECT count(*) FROM orders',5541))
    print('Заказов на replica:',replica_count,flush=True)
    wal=sql('SELECT pg_walfile_name(pg_current_wal_lsn())')
    sql('SELECT pg_switch_wal()')
    wait(lambda:shell(f'test -f /tmp/course07/archive/{wal} && echo yes || true')=='yes')
    pause('3. В отдельной копии восстанавливаем состояние до удаления.',
          'Base backup + WAL до выбранной точки\nRestored:\n'+source('05_restored_orders.sql'))
    # Pass the unique point as a positional argument; only this run's restore is selected.
    run(BASE+['sh','/work/restore.sh',target])
    wait(lambda:sql('SELECT pg_get_wal_replay_pause_state()',5542)=='paused')
    restored=sql('SELECT string_agg(id::text,\',\' ORDER BY id) FROM orders',5542)
    print(sql(source('05_restored_orders.sql'),5542,pretty=True),flush=True)
    assert restored=='1,2,42' and replica_count==0
    REPORT['restore']={'primary_after_delete':0,'replica_after_delete':replica_count,'restored_ids':[1,2,42],
                       'target':target,'in_recovery':sql('SELECT pg_is_in_recovery()',5542)=='t'}


def pool():
    a,b=Session(),Session()
    try:
        a.execute('BEGIN; RESET app.tenant_id; COMMIT')
        pause('1. Клиент A обслуживает магазин 42. PgBouncer: transaction, один backend.',source('06_session_context.sql'))
        out_a=a.execute(source('06_session_context.sql'));print('\n'.join(out_a),flush=True)
        pause('2. Клиент B обслуживает магазин 7, но ещё не задал контекст.',source('07_other_client.sql'))
        out_b=b.execute(source('07_other_client.sql'));print('\n'.join(out_b),flush=True)
        pause('3. Задаём контекст B внутри его транзакции.',source('08_local_context.sql'))
        out_fixed=b.execute(source('08_local_context.sql'));print('\n'.join(out_fixed),flush=True)
        pid_a,tenant_a=out_a[0].split('|');pid_b,tenant_b=out_b[0].split('|')
        _,tenant_fixed=out_fixed[0].split('|')
        assert pid_a==pid_b and tenant_a==tenant_b=='42' and tenant_fixed=='7'
        b.execute('BEGIN; RESET app.tenant_id; COMMIT')
        b.execute(source('08_local_context.sql'))
        reset=b.execute("SELECT coalesce(nullif(current_setting('app.tenant_id',true),''),'<empty>')")[0]
        assert reset=='<empty>'
        REPORT['pool']={'same_backend':True,'client_a_context':42,'client_b_inherited_context':42,'client_b_local_context':7,'local_context_after_commit':reset}
    finally:a.close();b.close()


def relations(node):
    found={node['Relation Name']} if 'Relation Name' in node else set()
    for child in node.get('Plans',[]):found.update(relations(child))
    return sorted(found)


def partitions():
    pause('1. История events разделена на три месяца UTC.',
          'SELECT tableoid::regclass, count(*)\nFROM events GROUP BY tableoid ORDER BY 1;')
    print(sql('SELECT tableoid::regclass,count(*) FROM events GROUP BY tableoid ORDER BY 1',pretty=True),flush=True)
    plans={}
    for i,(key,filename) in enumerate([('range','09_range.sql'),('wrapped','10_wrapped_key.sql')],2):
        query=source(filename)
        pause(f'{i}. '+('Диапазон непосредственно по occurred_at.' if key=='range' else 'Тот же месяц через функцию от occurred_at.'),query)
        print(sql(query,pretty=True),flush=True)
        json_query=query.replace('EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF)',
                                 'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)')
        plan=json.loads(sql(json_query))[0]['Plan'];plans[key]=plan
    direct=relations(plans['range']);wrapped=relations(plans['wrapped'])
    assert direct==['events_2026_10'] and len(wrapped)==3
    count=int(sql("SELECT count(*) FROM events WHERE occurred_at>='2026-10-01+00'::timestamptz AND occurred_at<'2026-11-01+00'::timestamptz"))
    REPORT['partitions']={'range_relations':direct,'wrapped_relations':wrapped,'october_rows':count,'plans':plans}


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('demo',choices=['replica','restore','pool','partitions','all'])
    parser.add_argument('--auto',action='store_true')
    parser.add_argument('--report',type=Path)
    args=parser.parse_args();AUTO=args.auto
    demos={'replica':replica,'restore':restore,'pool':pool,'partitions':partitions}
    for name in (demos if args.demo=='all' else [args.demo]):demos[name]()
    if args.report:
        args.report.parent.mkdir(parents=True,exist_ok=True)
        args.report.write_text(json.dumps({'passed':True,'version':sql('SELECT version()'),
            'pgbouncer':shell('pgbouncer --version'),'demonstrations':REPORT,
            'sql_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((ROOT/'show').glob('*.sql'))}},ensure_ascii=False,indent=2))
    print('\nДемонстрация завершена.',flush=True)
