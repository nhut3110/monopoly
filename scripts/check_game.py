import os, re, subprocess, sys
for args, marker in [(['--editor','--import','--quit'],None),(['--script','res://tests/smoke.gd'],'Smoke test:'),(['--script','res://tests/economy.gd'],'Economy:'),(['--script','res://tests/flow.gd'],'Flow:')]:
    result = subprocess.run([os.environ.get('GODOT_BIN','godot'),'--headless','--path','.',*args],capture_output=True,text=True,timeout=180)
    output = result.stdout + result.stderr
    print(output,flush=True)
    if result.returncode or re.search(r'SCRIPT ERROR:|ERROR:|Assertion failed',output) or (marker and marker not in output):
        sys.exit(1)
