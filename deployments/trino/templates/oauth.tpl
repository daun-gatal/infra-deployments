http-server.authentication.oauth2.issuer=https://keycloak-web-ext.kitty-barb.ts.net/realms/trino
http-server.authentication.oauth2.auth-url=https://keycloak-web-ext.kitty-barb.ts.net/realms/trino/protocol/openid-connect/auth
http-server.authentication.oauth2.token-url=https://keycloak-web-ext.kitty-barb.ts.net/realms/trino/protocol/openid-connect/token

http-server.authentication.oauth2.client-id=$${ENV:OAUTH_CLIENT_ID}
http-server.authentication.oauth2.client-secret=$${ENV:OAUTH_CLIENT_SECRET}

http-server.authentication.oauth2.scopes=openid,profile,email
http-server.authentication.oauth2.principal-field=preferred_username