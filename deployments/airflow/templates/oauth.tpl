from flask_appbuilder.security.manager import AUTH_OAUTH
import os

AUTH_TYPE = AUTH_OAUTH
ENABLE_PROXY_FIX = True
PREFERRED_URL_SCHEME = "https"

AUTH_USER_REGISTRATION = True  # allow users who are not already in the FAB DB to register
AUTH_USER_REGISTRATION_ROLE = "Public"
AUTH_ROLES_SYNC_AT_LOGIN = False  # Checks roles on every login

# If you wish, you can add multiple OAuth providers.
OAUTH_PROVIDERS = [
    {
        "name": "github",
        "icon": "fa-github",
        "token_key": "access_token",
        "remote_app": {
            "client_id": os.getenv("GITHUB_CLIENT_ID"),
            "client_secret": os.getenv("GITHUB_CLIENT_SECRET"),
            "api_base_url": "https://api.github.com",
            "client_kwargs": {"scope": "read:user, read:org"},
            "access_token_url": "https://github.com/login/oauth/access_token",
            "authorize_url": "https://github.com/login/oauth/authorize",
            "request_token_url": None,
        },
    },
    {
        "name": "keycloak",
        "icon": "fa-key",
        "token_key": "access_token",
        "remote_app": {
            "client_id": "airflow-sso",
            "client_secret": os.getenv("KEYCLOAK_CLIENT_SECRET"),
            "api_base_url": "https://keycloak-web-ext.kitty-barb.ts.net/realms/airflow/protocol/",
            "server_metadata_url": "https://keycloak-web-ext.kitty-barb.ts.net/realms/airflow/.well-known/openid-configuration",
            "client_kwargs": {"scope": "email profile"},
            "access_token_url": "https://keycloak-web-ext.kitty-barb.ts.net/realms/airflow/protocol/openid-connect/token",
            "authorize_url": "https://keycloak-web-ext.kitty-barb.ts.net/realms/airflow/protocol/openid-connect/auth",
            "request_token_url": None,
        },
    },
]