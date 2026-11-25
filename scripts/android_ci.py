"""CI-only signing configuration; restore source and remove key even on failure."""
import base64, hashlib, json, os, re, subprocess, sys
from pathlib import Path
e = os.environ
def run(args, **kw):
    return subprocess.run(args, check=True, **kw)
def configure():
    version = e['GITHUB_REF_NAME'][1:] if e['GITHUB_REF_TYPE']=='tag' else '0.1.'+e['GITHUB_RUN_NUMBER']
    if not re.fullmatch(r'\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?',version):
        raise ValueError('Invalid version tag')
    code = int(e['GITHUB_RUN_NUMBER'])
    if not 0 < code < 2100000000:
        raise ValueError('Invalid version code')
    settings = Path.home()/'.config/godot/editor_settings-4.tres'
    settings.parent.mkdir(parents=True,exist_ok=True)
    settings.write_text('[gd_resource type="EditorSettings" format=3]\n\n[resource]\nexport/android/java_sdk_path = '+json.dumps(e['JAVA_HOME'])+'\nexport/android/android_sdk_path = '+json.dumps(e['ANDROID_HOME'])+'\n')
    Path(e['RUNNER_TEMP'],'version.json').write_text(json.dumps({'name':version,'code':code}))
def build():
    for name in ('KEYSTORE_BASE64','KEYSTORE_ALIAS','KEYSTORE_PASSWORD'):
        if not e.get(name):
            raise ValueError('Missing required signing secret: '+name)
    key = Path(e['RUNNER_TEMP'],'monopoly-release.p12')
    original = Path('export_presets.cfg').read_text()
    try:
        fd = os.open(key,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
        with os.fdopen(fd,'wb') as f:
            f.write(base64.b64decode(e['KEYSTORE_BASE64'],validate=True))
        version = json.loads(Path(e['RUNNER_TEMP'],'version.json').read_text())
        prefix,android = original.split('[preset.1.options]',1)
        values = {'version/code':str(version['code']),'version/name':json.dumps(version['name']),'keystore/release':json.dumps(str(key)),'keystore/release_user':json.dumps(e['KEYSTORE_ALIAS']),'keystore/release_password':json.dumps(e['KEYSTORE_PASSWORD'])}
        for name,value in values.items():
            android,count = re.subn('^'+re.escape(name)+'=.*$',lambda _: name+'='+value,android,flags=re.M)
            if count!=1:
                raise ValueError('Missing/duplicate preset field: '+name)
        Path('export_presets.cfg').write_text(prefix+'[preset.1.options]'+android)
        Path('build').mkdir(exist_ok=True)
        apk = Path('build','CoTyPhu-v'+version['name']+'-arm64.apk')
        run([str(Path.home()/'.cache/godot-ci/godot'),'--headless','--path','.','--export-release','Android',str(apk)])
        sdk = Path(e['ANDROID_HOME'])/'build-tools/35.0.0'
        cert = run([str(sdk/'apksigner'),'verify','--verbose','--print-certs',str(apk)],capture_output=True,text=True).stdout
        expected = run(['keytool','-exportcert','-keystore',str(key),'-alias',e['KEYSTORE_ALIAS'],'-storepass:env','KEYSTORE_PASSWORD'],capture_output=True).stdout
        if hashlib.sha256(expected).hexdigest() not in cert.lower().replace(':',''):
            raise ValueError('APK signing certificate mismatch')
        info = run([str(sdk/'aapt'),'dump','badging',str(apk)],capture_output=True,text=True).stdout
        for field in ["name='vn.personal.cotyphu'","versionCode='"+str(version['code'])+"'","versionName='"+version['name']+"'","native-code: 'arm64-v8a'"]:
            if field not in info:
                raise ValueError('Unexpected APK metadata: '+field)
        Path('build/signing-certificate.txt').write_text(cert)
        Path('build/SHA256SUMS.txt').write_text(hashlib.sha256(apk.read_bytes()).hexdigest()+'  '+apk.name+'\n')
        print('Verified APK package, version, ABI and persistent signing certificate.')
    finally:
        Path('export_presets.cfg').write_text(original)
        key.unlink(missing_ok=True)
if __name__=='__main__':
    {'configure':configure,'build':build}[sys.argv[1]]()
