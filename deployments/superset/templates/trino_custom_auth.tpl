import time
import requests
import threading
import logging
from requests.exceptions import HTTPError, Timeout, ConnectionError
from trino.auth import Authentication

# Configure logging
logger = logging.getLogger(__name__)

class TrinoKeycloakAuth(Authentication):
    _service_cache = {} 
    _user_cache = {}
    _cache_lock = threading.Lock()

    def __init__(self, token_endpoint=None, client_id=None, client_secret=None, 
                 scope='openid', **kwargs):
        
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
        try:
            from flask import g
            if hasattr(g, 'user') and hasattr(g.user, 'username'):
                return g.user.username
        except Exception:
            pass
        return None

    def _get_service_token(self):
        """Get Master Service Token"""
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

    def _get_impersonated_user_token(self, username, service_token):
        """
        Exchange Service Token for User Token.
        """
        cache_key = (self.client_id, username)

        with self._cache_lock:
            cached = self._user_cache.get(cache_key)
            if cached and time.time() < (cached['expiry'] - 30):
                return cached['access_token']

        # RFC 8693 Token Exchange Params
        payload = {
            'grant_type': 'urn:ietf:params:oauth:grant-type:token-exchange',
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'subject_token': service_token,
            # CRITICAL MISSING PARAM ADDED BELOW:
            'subject_token_type': 'urn:ietf:params:oauth:token-type:access_token',
            'requested_subject': username,
            'scope': self.scope
        }

        try:
            response = requests.post(self.token_endpoint, data=payload, timeout=10)
            
            # Raise error for 4xx/5xx to trigger the except block
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
            try:
                # Try to parse Keycloak's JSON error response
                # Example: {"error": "invalid_request", "error_description": "User not found"}
                err_body = e.response.json()
                kc_error = err_body.get('error', 'unknown')
                kc_desc = err_body.get('error_description', '')
                logger.error(f"Token Exchange Failed for user '{username}'. Code: {code}. Keycloak Error: {kc_error} - {kc_desc}")
            except Exception:
                # If response isn't JSON, log text
                logger.error(f"Token Exchange Failed for user '{username}'. Code: {code}. Response: {e.response.text}")

            if code == 400:
                raise Exception(f"Access Denied: Request invalid or user '{username}' not found/active.")
            if code == 404:
                raise Exception(f"Access Denied: User '{username}' not found.")
            if code == 403:
                raise Exception(f"Access Denied: System not authorized to impersonate '{username}'.")
            raise e
            
        except Exception as e:
            logger.error(f"TrinoAuth: Unexpected error for {username}: {e}")
            raise e

    def _handle_request_error(self, error):
        if isinstance(error, Timeout): raise Exception("Auth Failed: Timeout.")
        if isinstance(error, ConnectionError): raise Exception("Auth Failed: Connection Error.")
        raise Exception(f"Auth Failed: {str(error)}")

    def set_http_session(self, http_session):
        def auth_header_hook(request):
            service_token = self._get_service_token()
            superset_user = self._get_superset_user()
            
            final_token = service_token
            if superset_user:
                final_token = self._get_impersonated_user_token(superset_user, service_token)
                
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