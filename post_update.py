import urllib.request
import json

url = 'https://cashbook-a3kn.onrender.com/api/updates/'
data = {
    "version": "1.0.4+5",
    "title": "SmartKhata v1.0.4",
    "description": "Premium Aesthetic Themes are here! Transform the entire app with Midnight Ocean, Sunset Glow, Forest Emerald, and Cherry Blossom vibes.",
    "size": "65.4MB",
    "downloadUrl": "https://github.com/Z-oss-tech/Cashbook-UI/releases/download/v1.0.4/app-release.apk",
    "isMandatory": False
}

req = urllib.request.Request(url, json.dumps(data).encode('utf-8'))
req.add_header('Content-Type', 'application/json')

try:
    response = urllib.request.urlopen(req)
    print("Success!", response.read().decode('utf-8'))
except Exception as e:
    print("Error:", e)
