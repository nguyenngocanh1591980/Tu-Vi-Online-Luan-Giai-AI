import requests
import json

payload = {
    "name": "Test",
    "birth_date": "1980-10-23",
    "birth_time": "21:05",
    "gender": 1,
    "kieu_an_sao": "An Đặc Biệt",
    "lat": 36.7014631,
    "lon": -118.1559819
}

print("Calling Python backend directly (8000)...")
try:
    resp = requests.post("http://localhost:8000/api/calculate-astrology-core", json=payload)
    print(resp.json())
except Exception as e:
    print(e)

print("\nCalling C# backend (5000)...")
try:
    payload_cs = {
        "name": "Test",
        "birthDate": "1980-10-23",
        "birthTime": "21:05",
        "gender": 1,
        "kieu_an_sao": "An Đặc Biệt",
        "lat": 36.7014631,
        "lon": -118.1559819
    }
    resp = requests.post("http://localhost:5000/api/TuVi/calculate-astrology-core", json=payload_cs)
    print(resp.json())
except Exception as e:
    print(e)
