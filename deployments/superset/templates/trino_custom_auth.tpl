import time
import requests
import threading
import logging
from requests.exceptions import HTTPError, Timeout, ConnectionError
from trino.auth import Authentication

# Configure logging
logger = logging.getLogger(__name__)

class TrinoKeycloakAuth(Authentication):
    """
    Trino Authentication using Keycloak 'Direct Naked Impersonation'.
    Workaround for 'requested_subject not supported in standard token exchange'.
    """
    
    _service_cache = {} 
    _user_cache = {}
    _cache_lock = threading.Lock()

    def __init__(self, token_endpoint=None, client_id=None, client_secret=None, 
                 scope=None, audience=None, **kwargs):
        
        if 'auth_params' in kwargs:
            params = kwargs['auth_params']
            self.token_endpoint = params.get('token_endpoint')
            self.client_id = params.get('client_id')
            self.client_secret = params.get('client_secret')
            self.scope = params.get('scope', 'openid profile email')
            self.audience = params.get('audience', self.client_id)
        else:
            self.token_endpoint = token_endpoint
            self.client_id = client_id
            self.client_secret = client_secret
            self.scope = scope if scope else 'openid profile email'
            self.audience = audience if audience else client_id

    def _get_superset_user(self):
        try:
            from flask import g
            if hasattr(g, 'user') and hasattr(g.user, 'username'):
                return g.user.username
        except Exception:
            pass
        return None

    def _get_service_token(self):
        """
        Get Service Account Token (Client Credentials).
        Used for background tasks where no user is logged in.
        """
        cache_key = self.client_id
        
        with self._cache_lock:
            cached = self._service_cache.get(cache_key)
            if cached and time.time() < (cached['expiry'] - 30):
                return cached['access_token']

        payload = {
            'grant_type': 'client_credentials',
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'scope': self.scope
        }
        
        try:
            response = requests.post(self.token_endpoint, data=payload, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            expiry = time.time() + data.get('expires_in', 60)
            with self._cache_lock:
                self._service_cache[cache_key] = {
                    'access_token': data['access_token'],
                    'expiry': expiry
                }
            return data['access_token']
        except Exception as e:
            logger.error(f"TrinoAuth: Service Login failed: {e}")
            self._handle_request_error(e)

    def _get_impersonated_user_token(self, username):
        """
        Direct Naked Impersonation (Legacy/Extension Mode).
        Does NOT send subject_token to avoid 'standard exchange' validation.
        """
        cache_key = (self.client_id, username)

        with self._cache_lock:
            cached = self._user_cache.get(cache_key)
            if cached and time.time() < (cached['expiry'] - 30):
                return cached['access_token']

        # DIRECT NAKED IMPERSONATION PAYLOAD
        # Removing subject_token tells Keycloak we are doing a "Naked" exchange
        payload = {
            'grant_type': 'urn:ietf:params:oauth:grant-type:token-exchange',
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'requested_subject': username,
            'scope': self.scope
        }
        
        if self.audience:
            payload['audience'] = self.audience

        try:
            response = requests.post(self.token_endpoint, data=payload, timeout=10)
            
            if response.status_code != 200:
                 try:
                     err = response.json()
                     logger.error(f"Impersonation Failed: {err}")
                 except:
                     logger.error(f"Impersonation Failed: {response.text}")
            
            response.raise_for_status()
            
            data = response.json()
            expiry = time.time() + data.get('expires_in', 60)
            with self._cache_lock:
                self._user_cache[cache_key] = {
                    'access_token': data['access_token'],
                    'expiry': expiry
                }
            return data['access_token']

        except HTTPError as e:
            code = e.response.status_code
            if code == 403:
                # This confirms we are hitting the Impersonation logic but lacking permission
                raise Exception(f"Access Denied: Client '{self.client_id}' is not allowed to impersonate users. Check 'Users -> Permissions -> Impersonate'.")
            if code == 400:
                raise Exception(f"Access Denied: Invalid request or user '{username}' not found.")
            raise e
            
        except Exception as e:
            logger.error(f"TrinoAuth: Error for {username}: {e}")
            raise e

    def _handle_request_error(self, error):
        if isinstance(error, Timeout): raise Exception("Auth Failed: Timeout.")
        if isinstance(error, ConnectionError): raise Exception("Auth Failed: Connection Error.")
        raise Exception(f"Auth Failed: {str(error)}")

    def set_http_session(self, http_session):
        def auth_header_hook(request):
            superset_user = self._get_superset_user()
            
            if superset_user:
                # Use Naked Impersonation
                token = self._get_impersonated_user_token(superset_user)
            else:
                # Fallback to Service Account
                token = self._get_service_token()
                
            request.headers['Authorization'] = f'Bearer {token}'
            return request
        http_session.auth = auth_header_hook

    def get_exceptions(self):
        return ()

    def authenticate(self, request):
        superset_user = self._get_superset_user()
        
        if superset_user:
            token = self._get_impersonated_user_token(superset_user)
        else:
            token = self._get_service_token()
            
        request.headers['Authorization'] = f'Bearer {token}'
        return request