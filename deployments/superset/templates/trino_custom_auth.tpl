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

    def _get_token(self) -> str:
        if not self.token_endpoint or not self.client_id:
             raise ValueError("Missing required Auth params")

        # CASE 1: Specific User Login (Password Grant)
        if self.username and self.password:
            payload = {
                'grant_type': 'password',  # <--- Authenticates a specific user
                'client_id': self.client_id,
                'client_secret': self.client_secret,
                'username': self.username,
                'password': self.password,
                'scope': self.scope
            }
        # CASE 2: Service Account Login (Client Credentials)
        else:
            payload = {
                'grant_type': 'client_credentials',
                'client_id': self.client_id,
                'client_secret': self.client_secret,
                'scope': self.scope
            }
        
        try:
            response = requests.post(self.token_endpoint, data=payload, timeout=10)
            response.raise_for_status()
            return response.json().get('access_token')
        except Exception as e:
            raise Exception(f"Failed to authenticate with Keycloak: {str(e)}")

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