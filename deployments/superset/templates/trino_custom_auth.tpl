import time
import requests
import threading
from requests.exceptions import HTTPError, Timeout, ConnectionError
from trino.auth import Authentication

class TrinoKeycloakAuth(Authentication):
    _token_cache = {}
    _cache_lock = threading.Lock()

    def __init__(self, token_endpoint=None, client_id=None, client_secret=None, 
                 username=None, password=None, scope='openid', **kwargs):
        
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

    @property
    def _cache_key(self):
        return (self.token_endpoint, self.client_id, self.username)

    def _get_cached_data(self):
        with self._cache_lock:
            return self._token_cache.get(self._cache_key)

    def _clear_cache(self):
        with self._cache_lock:
            if self._cache_key in self._token_cache:
                del self._token_cache[self._cache_key]

    def _update_cache(self, response_data):
        expires_in = response_data.get('expires_in', 0)
        expiry_time = time.time() + expires_in
        
        cache_entry = {
            'access_token': response_data.get('access_token'),
            'refresh_token': response_data.get('refresh_token'), 
            'expiry': expiry_time
        }
        
        with self._cache_lock:
            self._token_cache[self._cache_key] = cache_entry
            
        return cache_entry

    def _handle_request_error(self, error):
        if isinstance(error, Timeout):
            raise Exception("Authentication Failed: Connection to identity provider timed out.")
        if isinstance(error, ConnectionError):
            raise Exception("Authentication Failed: Unable to connect to identity provider.")
        if isinstance(error, HTTPError):
            code = error.response.status_code
            if code == 401:
                raise Exception("Authentication Failed: Invalid username or password.")
            elif code == 400:
                raise Exception("Authentication Failed: Invalid request (check client_id/secret).")
            elif code == 403:
                raise Exception("Authentication Failed: Access denied.")
            elif code == 404:
                raise Exception("Authentication Failed: Auth endpoint not found.")
            elif code >= 500:
                raise Exception("Authentication Failed: Identity provider server error.")
            else:
                raise Exception(f"Authentication Failed: Server returned status {code}.")
        raise Exception("Authentication Failed: An unexpected error occurred.")

    def _get_logout_url(self):
        # Infer logout URL from token URL
        # Keycloak Standard: .../openid-connect/token -> .../openid-connect/logout
        if self.token_endpoint.endswith('/token'):
            return self.token_endpoint[:-6] + '/logout'
        return self.token_endpoint.replace('/token', '/logout')

    def _perform_logout(self, refresh_token):
        """
        Calls Keycloak logout endpoint to delete the session on the server.
        """
        if not refresh_token:
            return

        logout_url = self._get_logout_url()
        payload = {
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'refresh_token': refresh_token
        }
        
        try:
            # We assume best-effort logout. If it fails, the session might 
            # already be dead or we have network issues, but we must proceed.
            requests.post(logout_url, data=payload, timeout=5)
        except Exception:
            # Swallow logout errors to prevent blocking the new login attempt
            pass

    def _get_token(self) -> str:
        cached = self._get_cached_data()

        if cached:
            # 1. Check if Access Token is valid
            if time.time() < (cached['expiry'] - 30):
                return cached['access_token']
            
            # --- TOKEN EXPIRED ---
            refresh_token = cached.get('refresh_token')
            
            # 2. Try to Refresh first (most efficient)
            if refresh_token:
                try:
                    return self._perform_refresh(refresh_token)
                except Exception:
                    # 3. If Refresh fails, cleanup Keycloak session
                    self._perform_logout(refresh_token)
                    self._clear_cache()
            else:
                # No refresh token? Just clear local
                self._clear_cache()

        # 4. Fallback: Full Login
        return self._perform_login()

    def _perform_login(self):
        if not self.username or not self.password:
             raise ValueError("Authentication Failed: Missing username or password.")

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
            data = self._update_cache(response.json())
            return data['access_token']
        except Exception as e:
            self._handle_request_error(e)

    def _perform_refresh(self, refresh_token):
        payload = {
            'grant_type': 'refresh_token',
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'refresh_token': refresh_token
        }
        
        # If this fails, it raises exception caught by _get_token
        response = requests.post(self.token_endpoint, data=payload, timeout=10)
        response.raise_for_status()
        
        data = self._update_cache(response.json())
        return data['access_token']

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