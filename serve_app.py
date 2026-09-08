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

def load_env():
    """Load environment variables dynamically from .env file"""
    env_vars = {}
    env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env')
    if os.path.exists(env_path):
        with open(env_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    k, v = line.split('=', 1)
                    env_vars[k.strip()] = v.strip().strip("'").strip('"')
    return env_vars

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization, xi-api-key')
        self.end_headers()

    def do_GET(self):
        if self.path == '/api/config':
            env = load_env()
            config = {
                'twilioSid': os.environ.get('TWILIO_ACCOUNT_SID') or env.get('TWILIO_ACCOUNT_SID', ''),
                'twilioAuth': os.environ.get('TWILIO_AUTH_TOKEN') or env.get('TWILIO_AUTH_TOKEN', ''),
                'twilioFromNumber': os.environ.get('TWILIO_FROM_NUMBER') or env.get('TWILIO_FROM_NUMBER', ''),
                'elevenLabsKey': os.environ.get('ELEVENLABS_API_KEY') or env.get('ELEVENLABS_API_KEY', ''),
                'elevenLabsAgentId': os.environ.get('ELEVENLABS_AGENT_ID') or env.get('ELEVENLABS_AGENT_ID', ''),
                'elevenLabsVoiceId': os.environ.get('ELEVENLABS_VOICE_ID') or env.get('ELEVENLABS_VOICE_ID', 'Xb7hH8MSUJpSbSDYk0k2'),
                'studentPhone': os.environ.get('STUDENT_PHONE_NUMBER') or env.get('STUDENT_PHONE_NUMBER', ''),
            }
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(config).encode('utf-8'))
        else:
            super().do_GET()

    def do_POST(self):
        if self.path == '/api/call':
            self._handle_twilio_call()
        elif self.path == '/api/config':
            self._handle_save_config()
        else:
            self.send_response(404)
            self.end_headers()

    def _handle_save_config(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        try:
            payload = json.loads(post_data.decode('utf-8'))
            env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env')
            
            # Read existing env or create new
            lines = []
            if os.path.exists(env_path):
                with open(env_path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()

            def update_or_add(lines, key, val):
                found = False
                new_lines = []
                for line in lines:
                    if line.strip().startswith(f"{key}="):
                        new_lines.append(f"{key}={val}\n")
                        found = True
                    else:
                        new_lines.append(line)
                if not found:
                    new_lines.append(f"{key}={val}\n")
                return new_lines

            if 'twilioSid' in payload:
                lines = update_or_add(lines, 'TWILIO_ACCOUNT_SID', payload['twilioSid'])
            if 'twilioAuth' in payload:
                lines = update_or_add(lines, 'TWILIO_AUTH_TOKEN', payload['twilioAuth'])
            if 'twilioFromNumber' in payload:
                lines = update_or_add(lines, 'TWILIO_FROM_NUMBER', payload['twilioFromNumber'])
            if 'elevenLabsKey' in payload:
                lines = update_or_add(lines, 'ELEVENLABS_API_KEY', payload['elevenLabsKey'])
            if 'elevenLabsAgentId' in payload:
                lines = update_or_add(lines, 'ELEVENLABS_AGENT_ID', payload['elevenLabsAgentId'])
            if 'elevenLabsVoiceId' in payload:
                lines = update_or_add(lines, 'ELEVENLABS_VOICE_ID', payload['elevenLabsVoiceId'])
            if 'studentPhone' in payload:
                lines = update_or_add(lines, 'STUDENT_PHONE_NUMBER', payload['studentPhone'])

            with open(env_path, 'w', encoding='utf-8') as f:
                f.writelines(lines)

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({"success": True, "message": "Config saved to .env"}).encode('utf-8'))
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({"success": False, "message": str(e)}).encode('utf-8'))

    def _handle_twilio_call(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        
        try:
            env = load_env()
            payload = json.loads(post_data.decode('utf-8'))
            
            # Credentials are dynamically retrieved from payload, os.environ, or .env file
            sid = payload.get('sid') or os.environ.get('TWILIO_ACCOUNT_SID') or env.get('TWILIO_ACCOUNT_SID', '')
            auth = payload.get('auth') or os.environ.get('TWILIO_AUTH_TOKEN') or env.get('TWILIO_AUTH_TOKEN', '')
            from_number = payload.get('from') or os.environ.get('TWILIO_FROM_NUMBER') or env.get('TWILIO_FROM_NUMBER', '')
            to_number = payload.get('to') or os.environ.get('STUDENT_PHONE_NUMBER') or env.get('STUDENT_PHONE_NUMBER', '')
            topic = payload.get('topic', 'STEM Doubts')
            grade = payload.get('grade', 'Class 10')
            agent_id = payload.get('agentId') or os.environ.get('ELEVENLABS_AGENT_ID') or env.get('ELEVENLABS_AGENT_ID', '')

            if not sid or not auth or not from_number or not to_number:
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps({
                    "success": False,
                    "message": "Missing required credentials. Please configure Twilio and your phone number in .env or the Settings dialog."
                }).encode('utf-8'))
                return

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
