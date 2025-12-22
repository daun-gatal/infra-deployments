from flask_appbuilder.security.manager import AUTH_OAUTH

ENABLE_PROXY_FIX = True
PREFERRED_URL_SCHEME = "https"

AUTH_TYPE = AUTH_OAUTH

OAUTH_PROVIDERS = [
    {
        "name": "github",
        "icon": "fa-github",
        "token_key": "access_token",
        "remote_app": {
            "client_id": os.environ.get("GITHUB_CLIENT_ID"),
            "client_secret": os.environ.get("GITHUB_CLIENT_SECRET"),
            "api_base_url": "https://api.github.com/",
            "authorize_url": "https://github.com/login/oauth/authorize",
            "access_token_url": "https://github.com/login/oauth/access_token",
            "client_kwargs": {
                "scope": "user:email"
            }
        }
    }
]

AUTH_USER_REGISTRATION = True
AUTH_USER_REGISTRATION_ROLE = "Gamma"
