import time
import requests
import threading
import logging
from requests.exceptions import HTTPError, Timeout, ConnectionError
from trino.auth import Authentication

# Configure logging to catch issues in Superset logs
logger = logging.getLogger(__name__)

class TrinoKeycloakAuth(Authentication):
    """
    Custom Trino Authentication for Superset with Keycloak.
    
    Mechanism:
    1. Authenticates as a Service Account (Client Credentials) to get a Master Token.
    2. Detects the logged-in Superset User.
    3. Exchanges the Master Token for a User-Specific Token (Token Exchange).
    4. Passes the User Token to Trino.
    """
    
    # -------------------------------------------------------------------------
    # GLOBAL CACHE
    # Shared across all instances to prevent opening too many Keycloak sessions.
    # -------------------------------------------------------------------------
    _service_cache = {} 
    _user_cache = {}
    _cache_lock = threading.Lock()

    def __init__(self, token_endpoint=None, client_id=None, client_secret=None, 
                 scope='openid', **kwargs):
        
        # Support initializing from Superset's 'auth_params' dictionary
        if 'auth_params' in kwargs:
            params = kwargs['auth_params']
            self.token_endpoint = params.get('token_endpoint')
            self.client_id = params.get('client_id')
            self.client_secret = params.get('client_secret')
            self.scope = params.get('scope', 'openid')
        else:
            self.token_endpoint = token_endpoint
            self.client_id = client_id
            self.client_secret = client_secret
            self.scope = scope

    def _get_superset_user(self):
        """
        Safely retrieve the current Superset user from the Flask context.
        Returns None if running in a background task (Celery).
        """
        try:
            from flask import g
            if hasattr(g, 'user') and hasattr(g.user, 'username'):
                return g.user.username
        except Exception:
            # Not in a web request context
            pass
        return None

    def _get_service_token(self):
        """
        Get the Master Token for the Service Account (Superset Client).
        Uses Client Credentials Flow.
        """
        cache_key = self.client_id
        
        # 1. Check Cache
        with self._cache_lock:
            cached = self._service_cache.get(cache_key)
            if cached and time.time() < (cached['expiry'] - 30):
                return cached['access_token']

        # 2. Request New Token
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
            
            # 3. Update Cache
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

    def _get_impersonated_user_token(self, username, service_token):
        """
        Exchange the Service Token for a User Token.
        STRICT: Raises exception if User does not exist or access is denied.
        """
        cache_key = (self.client_id, username)

        # 1. Check Cache
        with self._cache_lock:
            cached = self._user_cache.get(cache_key)
            if cached and time.time() < (cached['expiry'] - 30):
                return cached['access_token']

        # 2. Perform Token Exchange
        payload = {
            'grant_type': 'urn:ietf:params:oauth:grant-type:token-exchange',
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'subject_token': service_token,
            'requested_subject': username,
            'scope': self.scope
        }

        try:
            response = requests.post(self.token_endpoint, data=payload, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            # 3. Update Cache
            expiry = time.time() + data.get('expires_in', 60)
            with self._cache_lock:
                self._user_cache[cache_key] = {
                    'access_token': data['access_token'],
                    'expiry': expiry
                }
            return data['access_token']

        except HTTPError as e:
            code = e.response.status_code
            if code == 400:
                # Keycloak usually returns 400 if 'requested_subject' is invalid
                msg = f"Access Denied: User '{username}' does not exist in Identity Provider (Keycloak)."
                logger.error(msg)
                raise Exception(msg)
            if code == 404:
                raise Exception(f"Access Denied: User '{username}' not found.")
            if code == 403:
                msg = f"Access Denied: Superset Client is not authorized to impersonate '{username}'. Check Keycloak policies."
                logger.error(msg)
                raise Exception(msg)
            raise e
        except Exception as e:
            logger.error(f"TrinoAuth: Token Exchange failed for {username}: {e}")
            raise e

    def _handle_request_error(self, error):
        """Sanitize error messages to avoid leaking secrets"""
        if isinstance(error, Timeout): 
            raise Exception("Authentication Failed: Connection to identity provider timed out.")
        if isinstance(error, ConnectionError): 
            raise Exception("Authentication Failed: Unable to connect to identity provider.")
        if isinstance(error, HTTPError):
            code = error.response.status_code
            if code == 401:
                raise Exception("System Auth Failed: Invalid Client ID or Secret.")
        
        # Generic fallback
        raise Exception("Authentication Failed: An unexpected error occurred. Check logs.")

    def set_http_session(self, http_session):
        def auth_header_hook(request):
            # 1. Get Master Token (Always required)
            service_token = self._get_service_token()
            
            # 2. Identify Superset User
            superset_user = self._get_superset_user()
            
            final_token = service_token
            
            if superset_user:
                # 3. INTERACTIVE MODE: Impersonate the real user
                # This will RAISE AN EXCEPTION if the user is missing/invalid
                final_token = self._get_impersonated_user_token(superset_user, service_token)
            else:
                # 4. BACKGROUND MODE: Use Service Account
                # No user logged in (e.g., Scheduled Report), run as Service Account
                pass

            request.headers['Authorization'] = f'Bearer {final_token}'
            return request
            
        http_session.auth = auth_header_hook

    def get_exceptions(self):
        return ()

    def authenticate(self, request):
        service_token = self._get_service_token()
        superset_user = self._get_superset_user()
        
        final_token = service_token
        
        if superset_user:
            final_token = self._get_impersonated_user_token(superset_user, service_token)
            
        request.headers['Authorization'] = f'Bearer {final_token}'
        return request