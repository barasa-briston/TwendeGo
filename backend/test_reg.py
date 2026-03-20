import requests
import json

url = 'http://localhost:8080/api/auth/register/'
data = {
    'username': 'Test User',
    'phone_number': '0711111111',
    'email': 'test@example.com',
    'password': 'Password123!',
    'role': 'PASSENGER',
    'dob': '1990-01-01',
    'gender': 'Male'
}

response = requests.post(url, json=data)
print(f"Status Code: {response.status_code}")
print(f"Response Body: {response.text}")
