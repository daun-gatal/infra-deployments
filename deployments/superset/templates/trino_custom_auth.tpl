import time
import requests
from trino.auth import Authentication

class TrinoKeycloakAuth(Authentication):
    def __init__(self, token_endpoint=None, client_id=None, client_secret=None, 
                 username=None, password=None, scope='openid', **kwargs):
        
        # Handle unpacking from Superset's auth_params dict if present
        if 'auth_params' in kwargs:
            params = kwargs['auth_params']
            self.token_endpoint = params.get('token_endpoint')
            self.client_id = params.get('client_id')
            self.client_secret = params.get('client_secret')
            self.username = params.get('username')
            self.password = params.get('password')
            self.scope = params.get('scope', 'openid')
        else:
            self.token_endpoint = token_endpoint
            self.client_id = client_id
            self.client_secret = client_secret
            self.username = username
            self.password = password
            self.scope = scope

        # Token caching state
        self._access_token = None
        self._refresh_token = None
        self._token_expiry = 0

    def _handle_token_response(self, response_data):
        """Helper to update internal state from a successful token response"""
        self._access_token = response_data.get('access_token')
        self._refresh_token = response_data.get('refresh_token')
        
        # Calculate expiry time (current time + expires_in)
        # Default to 0 if not provided to force refresh next time
        expires_in = response_data.get('expires_in', 0)
        self._token_expiry = time.time() + expires_in

    def _get_token(self) -> str:
        # 1. Check if current access token is valid (with 30 second buffer)
        if self._access_token and time.time() < (self._token_expiry - 30):
            return self._access_token

        # 2. Try to refresh if we have a refresh token and it's expired
        if self._refresh_token:
            try:
                self._perform_refresh()
                return self._access_token
            except Exception:
                # If refresh fails (e.g., refresh token expired), fall through to full login
                pass

        # 3. Perform full authentication (Password Grant)
        self._perform_login()
        return self._access_token

    def _perform_login(self):
        if not self.token_endpoint or not self.client_id:
             raise ValueError("Missing required Auth params")

        if not self.username or not self.password:
             raise ValueError("Missing required Auth params: username and password")

        payload = {
            'grant_type': 'password',
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'username': self.username,
            'password': self.password,
            'scope': self.scope
        }
        
        try:
            response = requests.post(self.token_endpoint, data=payload, timeout=10)
            response.raise_for_status()
            self._handle_token_response(response.json())
        except Exception as e:
            raise Exception(f"Failed to authenticate with Keycloak: {str(e)}")

    def _perform_refresh(self):
        payload = {
            'grant_type': 'refresh_token',
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'refresh_token': self._refresh_token
        }
        
        response = requests.post(self.token_endpoint, data=payload, timeout=10)
        response.raise_for_status()
        self._handle_token_response(response.json())

    def set_http_session(self, http_session):
        def auth_header_hook(request):
            token = self._get_token()
            request.headers['Authorization'] = f'Bearer {token}'
            return request
        http_session.auth = auth_header_hook

    def get_exceptions(self):
        return ()

    def authenticate(self, request):
        token = self._get_token()
        request.headers['Authorization'] = f'Bearer {token}'
        return request