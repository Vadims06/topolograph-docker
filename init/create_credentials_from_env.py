import time
import requests
import os
# using TOPOLOGRAPH_* env variable check if get request is ok
_login, _pass = os.getenv('TOPOLOGRAPH_WEB_API_USERNAME_EMAIL', ''), os.getenv('TOPOLOGRAPH_WEB_API_PASSWORD', '')
_host, _port = os.getenv('TOPOLOGRAPH_HOST', ''), os.getenv('TOPOLOGRAPH_PORT', '')

def run():
    for attempt in range(3):
        try:
            print(f"Attempt {attempt + 1}: contacting Flask app...")
            res = requests.post(f'http://{_host}:{_port}/create-default-credentials', auth=(_login, _pass), timeout=(5, 30))
            print("Status:", res.status_code)
            print("Response:", res.text)
            break
        except Exception as e:
            print(f"Flask not ready yet, waiting... {e}")
            time.sleep(2)
    else:
        print("Flask app did not become available in time.")

if __name__ == '__main__':
    run()