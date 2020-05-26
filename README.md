# HTTP Client

A generic HTTP client, which uses an OpenSSL certificate for authentication and authorisation when establishing a connection. Obviously, for this to work, client certificate should include `clientAuth` as part of its `extendedKeyUsage`.
