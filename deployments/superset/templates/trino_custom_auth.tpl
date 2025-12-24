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
    Trino Authentication using Keycloak Standard Token Exchange.
    
    Flow:
    1. Authenticate this client (Superset) using Client Credentials to get a Service Token.
    2. Perform Token Exchange using the Service Token as 'subject_token'.
    3. Specify the target user via 'requested_subject'.
    
    Ref: https://www.keycloak.org/securing-apps/token-exchange
    """
    
    _service_cache = {} 
    _user_cache = {}
    _cache_lock = threading.Lock()

    def __init__(self, token_endpoint=None, client_id=None, client_secret=None, 
                 scope=None, audience=None, requested_token_type=None, **kwargs):
        
        # Support both nested 'auth_params' and direct kwargs unpacking
        if 'auth_params' in kwargs:
            params = kwargs['auth_params']
            self.token_endpoint = params.get('token_endpoint')
            self.client_id = params.get('client_id')
            self.client_secret = params.get('client_secret')
            self.scope = params.get('scope', 'openid profile email')
            self.audience = params.get('audience')
            self.requested_token_type = params.get('requested_token_type')
        else:
            self.token_endpoint = token_endpoint
            self.client_id = client_id
            self.client_secret = client_secret
            self.scope = scope if scope else 'openid profile email'
            self.audience = audience
            self.requested_token_type = requested_token_type

        # Fallback to env var if secret is missing
        if not self.client_secret:
            import os
            self.client_secret = os.getenv('TRINO_AUTH_CLIENT_SECRET')

    def _get_superset_user(self):
        try:
            from flask import g
            if hasattr(g, 'user'):
                if hasattr(g.user, 'is_anonymous') and g.user.is_anonymous:
                    return None
                if hasattr(g.user, 'username'):
                    return g.user.username
        except Exception:
            pass
        return None

    def _get_service_token(self):
        """
        Get Service Account Token (Client Credentials).
        This token is used as the 'subject_token' in the exchange to identify the caller.
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

    def _exchange_token(self, username):
        """
        Perform Standard Token Exchange.
        
        subject_token = Service Token (Access Token of this client)
        subject_token_type = urn:ietf:params:oauth:token-type:access_token
        requested_subject = username (Target user to impersonate)
        """
        cache_key = (self.client_id, username)

        with self._cache_lock:
            cached = self._user_cache.get(cache_key)
            if cached and time.time() < (cached['expiry'] - 30):
                return cached['access_token']

        # 1. Get Service Token
        service_token = self._get_service_token()
        if not service_token:
            raise Exception("TrinoAuth: Could not obtain Service Token for Exchange.")

        # 2. Prepare Exchange Payload
        payload = {
            'grant_type': 'urn:ietf:params:oauth:grant-type:token-exchange',
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'subject_token': service_token,
            'subject_token_type': 'urn:ietf:params:oauth:token-type:access_token',
            'requested_subject': username,
            'scope': self.scope
        }
        
        if self.audience:
            payload['audience'] = self.audience
            
        if self.requested_token_type:
            payload['requested_token_type'] = self.requested_token_type

        try:
            response = requests.post(self.token_endpoint, data=payload, timeout=10)
            
            if response.status_code != 200:
                logger.warning(f"Token Exchange failed for {username}: {response.status_code} - {response.text}")
                # Check for "User not found" or "Impersonation forbidden" scenarios
                if response.status_code in [400, 404]:
                     raise Exception("User not found")
                
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
             if e.response.status_code in [400, 404]:
                 raise Exception("User not found")
             if e.response.status_code == 403:
                 raise Exception(f"Access Denied: Client '{self.client_id}' cannot exchange token for user '{username}'.")
             raise e
            
        except Exception as e:
            if str(e) == "User not found":
                raise e
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
                # Use Token Exchange
                token = self._exchange_token(superset_user)
            else:
                # Fallback to Service Account for background tasks
                token = self._get_service_token()
                
            request.headers['Authorization'] = f'Bearer {token}'
            return request
        http_session.auth = auth_header_hook

    def get_exceptions(self):
        return ()

    def authenticate(self, request):
        superset_user = self._get_superset_user()
        
        if superset_user:
            token = self._exchange_token(superset_user)
        else:
            token = self._get_service_token()
            
        request.headers['Authorization'] = f'Bearer {token}'
        return request
