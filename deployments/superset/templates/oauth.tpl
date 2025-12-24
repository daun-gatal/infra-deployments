from flask_appbuilder.security.manager import AUTH_OAUTH
from trino_custom_auth import TrinoKeycloakAuth

from typing import Dict, Any, Callable

ENABLE_PROXY_FIX = True
PREFERRED_URL_SCHEME = "https"

AUTH_TYPE = AUTH_OAUTH

OAUTH_PROVIDERS = [
    {
        "name": "keycloak",
        "icon": "fa-key",
        "token_key": "access_token",
        "remote_app": {
            "client_id": "superset-sso",  # You'll need to create this client in Keycloak
            "client_secret": os.getenv("KEYCLOAK_CLIENT_SECRET"),
            "server_metadata_url": "https://keycloak-web-ext.kitty-barb.ts.net/realms/superset/.well-known/openid-configuration",
            "client_kwargs": {
                "scope": "email profile openid"
            },
            "api_base_url": "https://keycloak-web-ext.kitty-barb.ts.net/realms/superset/protocol/",
            "access_token_url": "https://keycloak-web-ext.kitty-barb.ts.net/realms/superset/protocol/openid-connect/token",
            "authorize_url": "https://keycloak-web-ext.kitty-barb.ts.net/realms/superset/protocol/openid-connect/auth",
            "request_token_url": None,
        },
    },
    # {
    #     "name": "github",
    #     "icon": "fa-github",
    #     "token_key": "access_token",
    #     "remote_app": {
    #         "client_id": os.environ.get("GITHUB_CLIENT_ID"),
    #         "client_secret": os.environ.get("GITHUB_CLIENT_SECRET"),
    #         "api_base_url": "https://api.github.com/",
    #         "authorize_url": "https://github.com/login/oauth/authorize",
    #         "access_token_url": "https://github.com/login/oauth/access_token",
    #         "client_kwargs": {
    #             "scope": "user:email"
    #         }
    #     }
    # }
]

AUTH_USER_REGISTRATION = True
AUTH_USER_REGISTRATION_ROLE = "Gamma"

ALLOWED_EXTRA_AUTHENTICATIONS: Dict[str, Dict[str, Callable[..., Any]]] = {
    "trino": {
        "custom_keycloak": TrinoKeycloakAuth,
    },
}