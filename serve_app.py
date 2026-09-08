import http.server
import socketserver
import json
import urllib.request
import urllib.parse
import base64
import os
import sys

PORT = 8085
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', 'web')

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization, xi-api-key')
        self.end_headers()

    def do_POST(self):
        if self.path == '/api/call':
            self._handle_twilio_call()
        else:
            self.send_response(404)
            self.end_headers()

    def _handle_twilio_call(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        
        try:
            payload = json.loads(post_data.decode('utf-8'))
            sid = payload.get('sid', 'AC86a315e8d751d9ab63d45bc379543378')
            auth = payload.get('auth', 'b15efb7ecedf832c0527098a300b2dd6')
            from_number = payload.get('from', '+19362336439')
            to_number = payload.get('to', '+918248059760')
            topic = payload.get('topic', 'STEM Doubts')
            grade = payload.get('grade', 'Class 10')
            agent_id = payload.get('agentId', '')

            # Query ElevenLabs live Twilio bridge to get the official streaming TwiML for this call
            # Generate a temporary unique call identifier for the initial handshake
            import time
            probe_sid = f"CA{int(time.time()*1000)}"
            el_data = urllib.parse.urlencode({
                'Called': from_number,
                'To': from_number,
                'From': to_number,
                'Direction': 'inbound',
                'CallSid': probe_sid,
                'CallGuid': probe_sid,
            }).encode('utf-8')

            el_req = urllib.request.Request('https://api.us.elevenlabs.io/twilio/inbound_call', data=el_data)
            with urllib.request.urlopen(el_req) as el_resp:
                twiml_content = el_resp.read().decode('utf-8')
                print(f"[ElevenLabs Bridge] Generated live TwiML: {twiml_content}")

            data_dict = {
                "To": to_number,
                "From": from_number,
                "Twiml": twiml_content,
            }
            data = urllib.parse.urlencode(data_dict).encode('utf-8')

            auth_header = "Basic " + base64.b64encode(f"{sid}:{auth}".encode('utf-8')).decode('utf-8')
            url = f"https://api.twilio.com/2010-04-01/Accounts/{sid}/Calls.json"

            req = urllib.request.Request(url, data=data, headers={
                "Authorization": auth_header,
                "Content-Type": "application/x-www-form-urlencoded"
            })

            with urllib.request.urlopen(req) as resp:
                resp_data = json.loads(resp.read().decode('utf-8'))
                call_sid = resp_data.get('sid', 'CA_unknown')
                
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps({
                    "success": True,
                    "callSid": call_sid,
                    "message": f"Twilio call dispatched to {to_number}! Ringing your phone now..."
                }).encode('utf-8'))

        except urllib.error.HTTPError as e:
            err_body = e.read().decode('utf-8')
            print(f"[Proxy Error] Twilio HTTP {e.code}: {err_body}")
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({
                "success": False,
                "message": f"Twilio error: {err_body}"
            }).encode('utf-8'))

        except Exception as e:
            print(f"[Proxy Error] {e}")
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({
                "success": False,
                "message": str(e)
            }).encode('utf-8'))

if __name__ == '__main__':
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), CustomHandler) as httpd:
        print(f"Serving Echo on http://localhost:{PORT} with Twilio Proxy...")
        httpd.serve_forever()
