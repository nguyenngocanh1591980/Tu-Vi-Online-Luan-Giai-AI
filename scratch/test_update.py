import urllib.request
import json
import sys
sys.stdout.reconfigure(encoding='utf-8')

def test_update_role():
    url = 'http://localhost:5000/api/v1/rbac/update-role'
    payload = {
        'userId': 12,
        'role': 'Sáng Lập'
    }
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'}, method='PUT')
    try:
        with urllib.request.urlopen(req) as res:
            print("Status:", res.status)
            print("Response:", res.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        print("HTTP Error:", e.code, e.read().decode('utf-8'))

def test_update_rank():
    url = 'http://localhost:5000/api/v1/rbac/update-rank'
    payload = {
        'userId': 12,
        'starLevel': 3,
        'rankTitle': 'Tam Đẳng'
    }
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'}, method='PUT')
    try:
        with urllib.request.urlopen(req) as res:
            print("Status:", res.status)
            print("Response:", res.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        print("HTTP Error:", e.code, e.read().decode('utf-8'))

if __name__ == '__main__':
    print("Testing Update Role to Sáng Lập...")
    test_update_role()
    print("\nTesting Update Rank to Tam Đẳng...")
    test_update_rank()
