from airflow.providers.fab.auth_manager.security_manager.override import FabAirflowSecurityManagerOverride
from flask_appbuilder.security.manager import AUTH_OAUTH
import os

AUTH_TYPE = AUTH_OAUTH
AUTH_USER_REGISTRATION_ROLE = "${auth_user_registration_role}"
AUTH_USER_REGISTRATION = True  # allow users who are not already in the FAB DB to register


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
]


class CustomSecurityManager(FabAirflowSecurityManagerOverride):
    pass


# Make sure to replace this with your own implementation of AirflowSecurityManager class
SECURITY_MANAGER_CLASS = CustomSecurityManager