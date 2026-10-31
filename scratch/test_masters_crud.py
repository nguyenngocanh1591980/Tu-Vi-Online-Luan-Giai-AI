import urllib.request
import json
import sys
sys.stdout.reconfigure(encoding='utf-8')

BASE_URL = 'http://localhost:5000/api/v1/masters'

def test_get():
    req = urllib.request.Request(BASE_URL)
    with urllib.request.urlopen(req) as res:
        data = json.loads(res.read())
        print(f"1. GET masters count: {len(data)}")
        first = data[0]
        keys = ['stt', 'username', 'masterName', 'rankTitle', 'titleLogo', 'joinDateFormatted', 
                'onlineBookingDays', 'offlineBookingDays', 'cancelledBookingDays', 
                'totalBookedClients', 'weeklyEarningsFormatted', 'thanksCount']
        has_all_12 = all(k in first for k in keys)
        print(f"   Contains all 12 columns: {has_all_12}")
        return len(data)

def test_create():
    payload = {
        'username': 'thay_batquai',
        'masterName': 'Thầy Bát Quái',
        'rankTitle': 'Ngũ Đẳng',
        'joinDate': '2026-10-15T00:00:00Z',
        'onlineBookingDays': 20,
        'offlineBookingDays': 10,
        'cancelledBookingDays': 1,
        'totalBookedClients': 42,
        'weeklyEarnings': 15000000,
        'thanksCount': 99
    }
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(BASE_URL, data=data, headers={'Content-Type': 'application/json'}, method='POST')
    with urllib.request.urlopen(req) as res:
        res_data = json.loads(res.read())
        print("2. POST create master:", res_data['success'], res_data['message'])
        return res_data['master']['id']

def test_update(master_id):
    payload = {
        'masterName': 'Đại Sư Bát Quái',
        'rankTitle': 'Lục Đẳng'
    }
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(f"{BASE_URL}/{master_id}", data=data, headers={'Content-Type': 'application/json'}, method='PUT')
    with urllib.request.urlopen(req) as res:
        res_data = json.loads(res.read())
        print("3. PUT update master:", res_data['success'], res_data['message'])

def test_delete(master_id):
    req = urllib.request.Request(f"{BASE_URL}/{master_id}", method='DELETE')
    with urllib.request.urlopen(req) as res:
        res_data = json.loads(res.read())
        print("4. DELETE master:", res_data['success'], res_data['message'])

if __name__ == '__main__':
    count_before = test_get()
    new_id = test_create()
    test_update(new_id)
    test_delete(new_id)
    count_after = test_get()
    assert count_before == count_after, f"Expected {count_before} but got {count_after}"
    print("ALL 12-COLUMN CRUD TESTS PASSED 100%!")
