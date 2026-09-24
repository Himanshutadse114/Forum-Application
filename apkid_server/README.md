# APKiD Scanner Backend

Deep APK fingerprinting server using [APKiD](https://github.com/rednaga/APKiD).
Detects packers, obfuscators, compilers, and anti-analysis tricks in Android APKs.

## Quick Start

### 1. Start the Server (Windows)

Double-click `start_server.bat` or run:

```cmd
cd c:\sneakers_app\apkid_server
pip install -r requirements.txt
python server.py
```

Server runs on **http://0.0.0.0:5000**

---

### 2. Connect from Flutter App

| Device Type | URL to use |
|---|---|
| Android Emulator | `http://10.0.2.2:5000` |
| Real Device (USB/WiFi) | `http://YOUR_PC_IP:5000` |

To find your PC IP: run `ipconfig` in CMD and look for IPv4 address.

To change the URL in Flutter:
```dart
ApkidService.setServerUrl('http://192.168.1.X:5000');
```

---

### 3. API Endpoints

#### `GET /health`
Check if server and APKiD are running.

```json
{
  "status": "ok",
  "apkid_available": true,
  "apkid_version": "apkid 3.1.0"
}
```

#### `POST /scan`
Upload APK for fingerprinting.

```bash
curl -F "file=@myapp.apk" http://localhost:5000/scan
```

Response:
```json
{
  "compilers": [{"file": "classes.dex", "value": "r8"}],
  "packers": [],
  "obfuscators": [{"file": "classes.dex", "value": "proguard"}],
  "anti_features": [],
  "risk_score": 20,
  "risk_label": "CLEAN",
  "is_packed": false,
  "is_obfuscated": true,
  "has_anti_analysis": false,
  "summary": "Built with: r8 | Obfuscated: proguard"
}
```

#### `POST /scan-path`
Scan APK by server-local path.

```bash
curl -X POST http://localhost:5000/scan-path \
  -H "Content-Type: application/json" \
  -d '{"path": "/path/to/app.apk"}'
```

---

## What APKiD Detects

| Category | Examples |
|---|---|
| **Compilers** | dx, r8, dexlib, dexmerge |
| **Packers** | Bangcle, Jiagu, iJiaMi, DexGuard, AppSealing |
| **Obfuscators** | ProGuard, DashO, Allatori, Zelix KlassMaster |
| **Anti-analysis** | Anti-VM, Anti-debug, Root detection, Frida detection |

## Risk Labels

| Label | Meaning |
|---|---|
| `CLEAN` | Standard build, no red flags |
| `SUSPICIOUS` | Light obfuscation or unusual compiler |
| `HIGH RISK` | Packed, heavily obfuscated, or has anti-analysis |
