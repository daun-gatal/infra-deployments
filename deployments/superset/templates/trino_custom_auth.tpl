import requests
from trino.auth import Authentication
from typing import Any, Dict

class TrinoKeycloakAuth(Authentication):
    def __init__(self, auth_params: Dict[str, Any]):
        self.token_endpoint = auth_params.get('token_endpoint')
        self.client_id = auth_params.get('client_id')
        self.client_secret = auth_params.get('client_secret')
        self.scope = auth_params.get('scope', 'openid')
        self.token = None

    def _get_token(self) -> str:
        # Simple token fetching logic - in production, you might want to cache this
        # and refresh only when expired.
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
        # This method is called by the Trino client to configure the session
        def auth_header_hook(request):
            token = self._get_token()
            request.headers['Authorization'] = f'Bearer {token}'
            return request

        http_session.auth = auth_header_hook

    def get_exceptions(self):
        return ()

    def authenticate(self, request):
        # Legacy method for older trino clients, delegates to the hook
        token = self._get_token()
        request.headers['Authorization'] = f'Bearer {token}'
        return request