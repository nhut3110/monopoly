import os, re, subprocess, sys
for args, marker in [(['--editor','--import','--quit'],None),(['--script','res://tests/smoke.gd'],'Smoke test:'),(['--script','res://tests/economy.gd'],'Economy:'),(['--script','res://tests/flow.gd'],'Flow:')]:
    # Initial import needs a real renderer for Godot 4.4's mesh thumbnails.
    display = [] if marker is None and os.environ.get('GODOT_IMPORT_DISPLAY') == '1' else ['--headless']
    result = subprocess.run([os.environ.get('GODOT_BIN','godot'),*display,'--audio-driver','Dummy','--rendering-method','gl_compatibility','--rendering-driver','opengl3','--path','.',*args],capture_output=True,text=True,timeout=180)
    output = result.stdout + result.stderr
    print(output,flush=True)
    if result.returncode or re.search(r'SCRIPT ERROR:|ERROR:|Assertion failed',output) or (marker and marker not in output):
        sys.exit(1)
