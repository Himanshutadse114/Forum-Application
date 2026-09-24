"""
APKiD Scanner Backend Server
Uses APKiD's Python API directly for fast, reliable APK fingerprinting.
"""

import os
import json
import tempfile
import subprocess
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# ── Risk classification ──────────────────────────────────────────────────────

PACKER_TAGS = {'packer', 'packed', 'protector'}
OBFUSCATOR_TAGS = {'obfuscator', 'obfuscated'}
ANTI_TAGS = {'anti_debug', 'anti_vm', 'anti_emulator', 'root_detection', 'frida', 'tamper'}

PACKER_KEYWORDS = [
    'bangcle', 'jiagu', 'ijiami', 'qihoo', 'baidu', 'tencent', 'ali',
    'apkprotect', 'dexprotector', 'appsealing', 'liapp', 'arxan',
    'dexguard', 'vdog', 'shield', 'packer', 'packed', 'protector',
]
OBFUSCATOR_KEYWORDS = [
    'proguard', 'dexguard', 'dasho', 'allatori', 'obfuscat',
    'zelix', 'yguard', 'enigma',
]
ANTI_KEYWORDS = [
    'anti_debug', 'anti_vm', 'anti_emulator', 'root_detection',
    'frida', 'tamper', 'integrity',
]
SUSPICIOUS_COMPILERS = ['dexlib', 'dexmerge', 'custom', 'unknown', 'hand-crafted']


def classify_findings(apkid_json: dict) -> dict:
    compilers = []
    packers = []
    obfuscators = []
    anti_features = []
    other = []

    files = apkid_json.get('files', [])
    for file_entry in files:
        filename = file_entry.get('filename', 'unknown')
        matches = file_entry.get('matches', {})

        if not isinstance(matches, dict):
            continue

        for category, detections in matches.items():
            if not isinstance(detections, list):
                detections = [str(detections)]

            cat_lower = category.lower()

            for detection in detections:
                det_lower = str(detection).lower()

                if cat_lower == 'compiler' or 'compiler' in cat_lower:
                    compilers.append({'file': filename, 'value': detection})

                elif (cat_lower in PACKER_TAGS or
                      'packer' in cat_lower or
                      any(kw in det_lower for kw in PACKER_KEYWORDS)):
                    packers.append({'file': filename, 'value': detection})

                elif (cat_lower in OBFUSCATOR_TAGS or
                      'obfuscat' in cat_lower or
                      any(kw in det_lower for kw in OBFUSCATOR_KEYWORDS)):
                    obfuscators.append({'file': filename, 'value': detection})

                elif (cat_lower in ANTI_TAGS or
                      'anti' in cat_lower or
                      any(kw in det_lower for kw in ANTI_KEYWORDS)):
                    anti_features.append({'file': filename, 'category': category, 'value': detection})

                else:
                    other.append({'file': filename, 'category': category, 'value': detection})

    # Calculate Balanced Risk Score
    risk_score = 0
    
    # 1. Obfuscation is standard industry practice (0 points)
    
    # 2. Suspicious Compiler (e.g. hand-crafted or unknown tool chains): +15 points
    has_suspicious_compiler = any(any(kw in c['value'].lower() for kw in SUSPICIOUS_COMPILERS) for c in compilers)
    if has_suspicious_compiler:
        risk_score += 15

    # 3. Packed Code: standard for financial/security apps. Presence adds +15 points (hardened)
    if packers:
        risk_score += 15

    # 4. Anti-Analysis: root beer, build checks, debugger checks. Presence adds +10 points (highly secure, not malware)
    if anti_features:
        risk_score += 10

    # 5. Combination of both packed and anti-analysis checks (common in hardened apps but increases surface): +10 points
    if packers and anti_features:
        risk_score += 10

    risk_score = min(risk_score, 100)

    # Classify Risk Label
    if risk_score >= 60:
        risk_label = 'HIGH RISK'
    elif risk_score >= 30:
        risk_label = 'SUSPICIOUS'
    else:
        risk_label = 'CLEAN'

    summary_parts = []
    if compilers:
        summary_parts.append(f"Built with: {', '.join(set(c['value'] for c in compilers))}")
    if packers:
        summary_parts.append(f"PACKED: {', '.join(set(p['value'] for p in packers))}")
    if obfuscators:
        summary_parts.append(f"Obfuscated: {', '.join(set(o['value'] for o in obfuscators))}")
    if anti_features:
        summary_parts.append(f"Anti-analysis: {', '.join(set(a['value'] for a in anti_features))}")

    return {
        'compilers': compilers,
        'packers': packers,
        'obfuscators': obfuscators,
        'anti_features': anti_features,
        'other': other,
        'risk_score': risk_score,
        'risk_label': risk_label,
        'summary': ' | '.join(summary_parts) if summary_parts else 'Standard build, no unusual patterns detected.',
        'is_packed': len(packers) > 0,
        'is_obfuscated': len(obfuscators) > 0,
        'has_anti_analysis': len(anti_features) > 0,
        'raw': apkid_json,
    }


def run_custom_yara_scan(apk_path: str) -> list:
    """Runs a custom YARA scan using signatures for known Android malware families."""
    import yara
    rules_path = os.path.join(os.path.dirname(__file__), 'android_malware_rules.yar')
    if not os.path.exists(rules_path):
        return []
    try:
        rules = yara.compile(filepath=rules_path)
        matches = rules.match(apk_path)
        findings = []
        for m in matches:
            findings.append({
                'rule': m.rule,
                'description': m.meta.get('description', 'Android Malware Match'),
                'category': m.meta.get('category', 'Malware')
            })
        return findings
    except Exception as e:
        print(f"Error running custom YARA scan: {e}")
        return []


def run_quark_scan(apk_path: str) -> list:
    """Runs Quark-Engine on the given APK path and returns high-confidence behavioral crimes."""
    import subprocess
    import tempfile
    import json
    
    quark_bin = "/home/platform/.local/bin/quark"
    if not os.path.exists(quark_bin):
        quark_bin = "quark"
        
    with tempfile.NamedTemporaryFile(suffix='.json', delete=False) as tmp:
        tmp_json = tmp.name
        
    try:
        # Run quark and output to JSON
        cmd = [quark_bin, "-a", apk_path, "-o", tmp_json]
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120)
        if res.returncode != 0:
            print(f"Quark run warning/error: {res.stderr.decode('utf-8', errors='ignore')}")
            
        if not os.path.exists(tmp_json) or os.path.getsize(tmp_json) == 0:
            return []
            
        with open(tmp_json, 'r') as f:
            data = json.load(f)
            
        crimes = data.get("crimes", [])
        findings = []
        for crime in crimes:
            confidence = crime.get("confidence", "0%")
            # Only include high-confidence behavioral matches (e.g. >= 80%)
            conf_val = 0
            try:
                conf_val = int(confidence.replace("%", "").strip())
            except ValueError:
                pass
            if conf_val >= 80:
                findings.append({
                    'behavior': crime.get('name', 'Suspicious Behavior'),
                    'label': crime.get('label', 'unknown'),
                    'weight': crime.get('weight', 0),
                    'confidence': confidence
                })
        return findings
    except Exception as e:
        print(f"Error running Quark-Engine scan: {e}")
        return []
    finally:
        try:
            os.unlink(tmp_json)
        except Exception:
            pass


def run_apkid_scan(apk_path: str) -> dict:
    """
    Runs APKiD on the given APK path using its Python API.
    Returns the classify_findings() dict merged with custom YARA and Quark-Engine matches.
    """
    from apkid.apkid import Scanner, Options
    from apkid.rules import RulesManager
    from apkid.output import OutputFormatter

    rm = RulesManager()
    rules = rm.load()
    opts = Options(
        timeout=300,
        verbose=False,
        json=True,
        scan_depth=2,
        typing='magic',
        entry_max_scan_size=0,
    )
    scanner = Scanner(rules, opts)
    formatter = OutputFormatter(
        json_output=True,
        output_dir=None,
        rules_manager=rm,
        include_types=False,
    )

    try:
        raw_matches = scanner.scan_file(apk_path)
        if raw_matches:
            json_output = formatter.build_json_output(raw_matches)
        else:
            json_output = {'apkid_version': '', 'rules_sha256': '', 'files': []}
    except Exception as e:
        json_output = {'apkid_version': '', 'rules_sha256': '', 'files': [], 'error': str(e)}

    # 1. Run standard APKiD classification
    findings = classify_findings(json_output)

    # 2. Run custom malware YARA rules scan
    custom_matches = run_custom_yara_scan(apk_path)
    findings['custom_malware_matches'] = custom_matches
    findings['is_malicious_malware'] = len(custom_matches) > 0

    # 3. Run Quark-Engine behavioral scan
    quark_crimes = run_quark_scan(apk_path)
    findings['behavioral_alerts'] = quark_crimes
    findings['has_behavioral_alerts'] = len(quark_crimes) > 0

    # Adjust risk score based on Quark crimes
    quark_score_addition = 0
    for crime in quark_crimes:
        weight = crime.get('weight', 0)
        if weight >= 8:
            quark_score_addition += 25
        else:
            quark_score_addition += 15

    if quark_score_addition > 0:
        findings['risk_score'] = min(findings['risk_score'] + quark_score_addition, 100)

    if custom_matches:
        # If actual known malware matches, immediately upgrade to HIGH RISK (100)
        findings['risk_score'] = 100
        findings['risk_label'] = 'HIGH RISK'
        matched_rules = [m['rule'] for m in custom_matches]
        findings['summary'] = f"MALWARE DETECTED: {', '.join(matched_rules)} | {findings['summary']}"
        findings['verdict'] = 'Malicious'
    else:
        # Determine verdict based on adjusted APKiD + Quark score
        score = findings['risk_score']
        if score >= 60:
            findings['risk_label'] = 'HIGH RISK'
            findings['verdict'] = 'Dangerous'
        elif score >= 35:
            findings['risk_label'] = 'SUSPICIOUS'
            findings['verdict'] = 'Suspicious'
        else:
            findings['risk_label'] = 'CLEAN'
            findings['verdict'] = 'Clean'

        # Build summary
        summary_prefix = ""
        if quark_crimes:
            summary_prefix = f"Behavioral Alerts: {len(quark_crimes)} detected | "
        
        if findings['summary'] and findings['summary'] != 'Standard build, no unusual patterns detected.':
            findings['summary'] = f"{summary_prefix}{findings['summary']}"
        elif summary_prefix:
            findings['summary'] = summary_prefix.rstrip(" | ")

    return findings


# ── Endpoints ────────────────────────────────────────────────────────────────

@app.route('/', methods=['GET'])
def index():
    return jsonify({
        'status': 'ok',
        'message': 'APKiD Scanner Backend Server is running. Use /health to check status, or POST to /scan to scan an APK.'
    })


@app.route('/health', methods=['GET'])
def health():
    try:
        from apkid.apkid import Scanner
        apkid_ok = True
        import apkid
        version_str = f'apkid {apkid.__version__}'
    except ImportError as e:
        apkid_ok = False
        version_str = str(e)
    return jsonify({
        'status': 'ok',
        'apkid_available': apkid_ok,
        'apkid_version': version_str,
        'message': 'APKiD Scanner Server is running',
    })


@app.route('/scan', methods=['POST'])
def scan():
    """Accepts APK file upload, runs APKiD, returns JSON findings."""
    if 'file' not in request.files:
        return jsonify({'error': "Send APK as 'file' in multipart form."}), 400

    uploaded_file = request.files['file']
    if not uploaded_file.filename:
        return jsonify({'error': 'Empty filename.'}), 400

    with tempfile.NamedTemporaryFile(suffix='.apk', delete=False) as tmp:
        tmp_path = tmp.name
        uploaded_file.save(tmp_path)

    try:
        findings = run_apkid_scan(tmp_path)
        findings['filename'] = uploaded_file.filename
        return jsonify(findings)
    except Exception as e:
        return jsonify({'error': f'Scan error: {str(e)}'}), 500
    finally:
        try:
            os.unlink(tmp_path)
        except Exception:
            pass


def run_mobsf_scan(apk_path: str, filename: str) -> dict:
    import requests
    import time
    from requests_toolbelt.multipart.encoder import MultipartEncoder

    mobsf_url = "http://172.22.0.2:8000"
    api_key = "mobsf_secret_api_key_2026"
    headers = {'Authorization': api_key}

    # 1. Upload APK to MobSF
    print(f"Uploading {filename} to MobSF...")
    try:
        multipart_data = MultipartEncoder(
            fields={'file': (filename, open(apk_path, 'rb'), 'application/octet-stream')}
        )
        upload_headers = {
            'Content-Type': multipart_data.content_type,
            'Authorization': api_key
        }
        
        upload_res = requests.post(f"{mobsf_url}/api/v1/upload", data=multipart_data, headers=upload_headers, timeout=120)
    except Exception as e:
        raise Exception(f"Failed to connect or upload to MobSF container: {e}")

    if upload_res.status_code != 200:
        raise Exception(f"MobSF upload failed with status {upload_res.status_code}: {upload_res.text}")
        
    upload_json = upload_res.json()
    apk_hash = upload_json.get("hash")
    scan_type = upload_json.get("scan_type", "apk")
    if not apk_hash:
        raise Exception(f"MobSF upload response missing hash: {upload_json}")

    # 2. Start Scan
    print(f"Initiating MobSF scan for hash {apk_hash}...")
    scan_res = requests.post(
        f"{mobsf_url}/api/v1/scan",
        data={'hash': apk_hash, 'scan_type': scan_type},
        headers=headers,
        timeout=300
    )
    if scan_res.status_code != 200:
        raise Exception(f"MobSF scan trigger failed: {scan_res.text}")

    # 3. Poll for JSON report
    print("Polling MobSF for scan completion...")
    max_retries = 30  # 30 * 5s = 150 seconds max
    report_data = None
    
    for i in range(max_retries):
        time.sleep(5)
        print(f"Polling check {i+1}/{max_retries}...")
        try:
            report_res = requests.post(
                f"{mobsf_url}/api/v1/report_json",
                data={'hash': apk_hash},
                headers=headers,
                timeout=10
            )
            if report_res.status_code == 200:
                res_json = report_res.json()
                if isinstance(res_json, dict) and ("security_score" in res_json or "appsec" in res_json):
                    report_data = res_json
                    break
            elif report_res.status_code == 404 or "not found" in report_res.text.lower():
                continue
        except Exception as e:
            print(f"Polling warning: {e}")
            continue
            
    if not report_data:
        raise Exception("MobSF detailed scan timed out or failed to generate report.")

    # 4. Extract and simplify metrics
    manifest_analysis = report_data.get("manifest_analysis", {})
    manifest_issues = []
    if isinstance(manifest_analysis, list):
        for item in manifest_analysis:
            manifest_issues.append({
                'title': item.get('title', item.get('name', 'Manifest Issue')),
                'severity': item.get('stat', 'medium').lower(),
                'description': item.get('desc', '')
            })
    elif isinstance(manifest_analysis, dict):
        findings = manifest_analysis.get("manifest_findings", [])
        if isinstance(findings, list):
            for item in findings:
                manifest_issues.append({
                    'title': item.get('title', item.get('name', 'Manifest Issue')),
                    'severity': item.get('severity', 'medium').lower(),
                    'description': item.get('desc', '')
                })

    code_analysis = report_data.get("code_analysis", {})
    code_issues = []
    if isinstance(code_analysis, dict):
        findings = code_analysis.get("findings", {})
        if isinstance(findings, dict):
            for key, val in findings.items():
                if isinstance(val, dict):
                    code_issues.append({
                        'title': val.get('metadata', {}).get('title', key),
                        'severity': val.get('metadata', {}).get('severity', 'medium').lower(),
                        'description': val.get('metadata', {}).get('description', '')
                    })

    trackers = report_data.get("trackers", {})
    tracker_list = []
    if isinstance(trackers, dict):
        detected = trackers.get("detected_trackers", [])
        if isinstance(detected, list):
            for t in detected:
                tracker_list.append({
                    'name': t.get('name', 'Unknown Tracker'),
                    'categories': t.get('categories', '')
                })

    secrets = report_data.get("secrets", [])
    secrets_list = []
    if isinstance(secrets, list):
        for s in secrets:
            if isinstance(s, dict):
                secrets_list.append(s.get('secret', ''))
            elif isinstance(s, str):
                secrets_list.append(s)

    score = report_data.get("security_score")
    if score is None and "appsec" in report_data:
        score = report_data["appsec"].get("security_score", 100)
    elif score is None:
        score = 100
    if score >= 90:
        grade = "A"
    elif score >= 70:
        grade = "B"
    elif score >= 50:
        grade = "C"
    elif score >= 30:
        grade = "D"
    else:
        grade = "F"

    high_vulns = []
    medium_vulns = []
    low_vulns = []

    for issue in (manifest_issues + code_issues):
        sev = issue.get('severity', 'low').lower()
        if 'high' in sev or 'critical' in sev:
            high_vulns.append(issue)
        elif 'medium' in sev or 'warn' in sev:
            medium_vulns.append(issue)
        else:
            low_vulns.append(issue)

    return {
        'status': 'success',
        'security_score': score,
        'security_grade': grade,
        'filename': filename,
        'hash': apk_hash,
        'trackers': tracker_list,
        'secrets': secrets_list,
        'vulnerabilities': {
            'high': high_vulns[:15],
            'medium': medium_vulns[:20],
            'low': low_vulns[:20]
        }
    }


@app.route('/scan/detailed', methods=['POST'])
def scan_detailed():
    """Accepts APK file upload, uploads to MobSF, polls for report, returns simplified report."""
    if 'file' not in request.files:
        return jsonify({'error': "Send APK as 'file' in multipart form."}), 400

    uploaded_file = request.files['file']
    if not uploaded_file.filename:
        return jsonify({'error': 'Empty filename.'}), 400

    with tempfile.NamedTemporaryFile(suffix='.apk', delete=False) as tmp:
        tmp_path = tmp.name
        uploaded_file.save(tmp_path)

    try:
        report = run_mobsf_scan(tmp_path, uploaded_file.filename)
        return jsonify(report)
    except Exception as e:
        return jsonify({'error': f'Detailed scan error: {str(e)}'}), 500
    finally:
        try:
            os.unlink(tmp_path)
        except Exception:
            pass


@app.route('/scan-path', methods=['POST'])
def scan_by_path():
    """Scans an APK by server-local file path."""
    data = request.get_json()
    if not data or 'path' not in data:
        return jsonify({'error': 'Provide JSON: { "path": "/path/to/app.apk" }'}), 400
    apk_path = data['path']
    if not os.path.exists(apk_path):
        return jsonify({'error': f'File not found: {apk_path}'}), 404
    try:
        findings = run_apkid_scan(apk_path)
        findings['filename'] = os.path.basename(apk_path)
        return jsonify(findings)
    except Exception as e:
        return jsonify({'error': f'Scan error: {str(e)}'}), 500


if __name__ == '__main__':
    port = int(os.environ.get('APKID_PORT', 5000))
    print("=" * 60)
    print("  APKiD Scanner Backend Server v1.0")
    print(f"  Running on http://0.0.0.0:{port}")
    print()
    print("  Endpoints:")
    print("    GET  /health      - Health check")
    print("    POST /scan        - Scan APK (file upload)")
    print("    POST /scan-path   - Scan APK (server path)")
    print()
    print(f"  Android Emulator URL: http://10.0.2.2:{port}")
    print("  Real Device: use your PC IP (ipconfig)")
    print("=" * 60)
    app.run(host='0.0.0.0', port=port, debug=False)
