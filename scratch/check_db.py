import subprocess

cmd = ['docker', 'exec', '-i', 'Tuvionlinemanager-db', 'psql', '-U', 'postgres', '-d', 'TuviAIManagerDB', '-c', 'SELECT "Id", "Username", "GroupLevel", "RankBadge", "RibbonAsset", "LogoAsset", "SortOrder" FROM "BoardMembers" ORDER BY "SortOrder" LIMIT 10;']
res = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', errors='replace')
import sys
sys.stdout.reconfigure(encoding='utf-8')
print(res.stdout)
if res.stderr:
    print("ERR:", res.stderr)
