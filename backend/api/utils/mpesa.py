import requests
import base64
from datetime import datetime
import os

def get_mpesa_access_token():
    """Get M-Pesa API access token from Daraja."""
    consumer_key = os.getenv('MPESA_CONSUMER_KEY')
    consumer_secret = os.getenv('MPESA_CONSUMER_SECRET')
    api_url = os.getenv('MPESA_AUTH_URL', 'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials')

    response = requests.get(api_url, auth=(consumer_key, consumer_secret))
    return response.json().get('access_token')


def generate_password(shortcode, passkey, timestamp):
    """Generate M-Pesa STK Push password."""
    data = f"{shortcode}{passkey}{timestamp}"
    encoded = base64.b64encode(data.encode('utf-8')).decode('utf-8')
    return encoded


def initiate_stk_push(phone_number, amount, account_reference):
    """Initiate M-Pesa STK Push payment."""
    shortcode = os.getenv('MPESA_SHORTCODE')
    passkey = os.getenv('MPESA_PASSKEY')
    callback_url = os.getenv('MPESA_CALLBACK_URL')
    stk_push_url = os.getenv(
        'MPESA_STK_PUSH_URL',
        'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest'
    )

    timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
    password = generate_password(shortcode, passkey, timestamp)

    # Normalize phone number — remove leading 0 or +, ensure it starts with 254
    phone = str(phone_number).strip()
    if phone.startswith('+'):
        phone = phone[1:]
    elif phone.startswith('0'):
        phone = '254' + phone[1:]

    try:
        access_token = get_mpesa_access_token()
        headers = {'Authorization': f'Bearer {access_token}', 'Content-Type': 'application/json'}

        payload = {
            'BusinessShortCode': shortcode,
            'Password': password,
            'Timestamp': timestamp,
            'TransactionType': 'CustomerPayBillOnline',
            'Amount': int(amount),
            'PartyA': phone,
            'PartyB': shortcode,
            'PhoneNumber': phone,
            'CallBackURL': callback_url,
            'AccountReference': account_reference,
            'TransactionDesc': f'Payment for booking {account_reference}',
        }

        response = requests.post(stk_push_url, json=payload, headers=headers)
        data = response.json()

        if data.get('ResponseCode') == '0':
            return data, None
        else:
            return None, data.get('ResponseDescription', 'STK Push failed')

    except Exception as e:
        return None, str(e)
