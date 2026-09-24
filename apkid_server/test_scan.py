import requests

APK_PATH = r'C:\Users\Tadse\AndroidStudioProjects\MyApplication\app\build\intermediates\apk\debug\app-debug.apk'

with open(APK_PATH, 'rb') as f:
    resp = requests.post(
        'http://localhost:5000/scan',
        files={'file': ('app-debug.apk', f, 'application/octet-stream')},
        timeout=60
    )

data = resp.json()
print('=== APKiD Live Scan Result ===')
print('Risk Label   :', data.get('risk_label'))
print('Risk Score   :', data.get('risk_score'))
print('Is Packed    :', data.get('is_packed'))
print('Is Obfuscated:', data.get('is_obfuscated'))
print('Anti-Analysis:', data.get('has_anti_analysis'))
print('Compilers    :', [c['value'] for c in data.get('compilers', [])])
print('Packers      :', [p['value'] for p in data.get('packers', [])])
print('Obfuscators  :', [o['value'] for o in data.get('obfuscators', [])])
print('Anti-feats   :', [a['value'] for a in data.get('anti_features', [])])
print('Summary      :', data.get('summary'))
