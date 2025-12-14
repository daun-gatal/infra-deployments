from airflow.providers.fab.auth_manager.security_manager.override import FabAirflowSecurityManagerOverride
from flask_appbuilder.security.manager import AUTH_OAUTH
import os

AUTH_TYPE = AUTH_OAUTH
AUTH_ROLE_PUBLIC = "Public"
AUTH_USER_REGISTRATION = True  # allow users who are not already in the FAB DB to register
AUTH_ROLES_SYNC_AT_LOGIN = True  # Checks roles on every login

AUTH_USER_ROLES_MAPPING = {
    "daun-gatal": ["Admin"]
}

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


def map_roles(user_id: str) -> list[str]:
    return AUTH_USER_ROLES_MAPPING.get(user_id, [AUTH_ROLE_PUBLIC])

class GithubUserAuthorizer(FabAirflowSecurityManagerOverride):
    # In this example, the oauth provider == 'github'.
    # If you ever want to support other providers, see how it is done here:
    # https://github.com/dpgaspar/Flask-AppBuilder/blob/master/flask_appbuilder/security/manager.py#L550
    def get_oauth_user_info(self, provider: str, resp: Any) -> dict[str, Union[str, list[str]]]:
        # Creates the user info payload from GitHub.
        # The user previously allowed your app to act on their behalf,
        #   so now we can query the user and teams endpoints for their data.
        # Username and team membership are added to the payload and returned to FAB.

        remote_app = self.appbuilder.sm.oauth_remotes[provider]
        me = remote_app.get("user")
        user_data = me.json()
        user_id = user_data.get("login")
        roles = map_roles(user_id)
        return {"username": "github_" + user_id, "role_keys": roles}


# Make sure to replace this with your own implementation of AirflowSecurityManager class
SECURITY_MANAGER_CLASS = GithubUserAuthorizer