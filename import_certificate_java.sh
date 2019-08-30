#! /bin/bash
# Import certificate from site to Java keystore.
# Site URL is arg $1.

HOST=$1
PORT=443
KEYSTOREFILE=/awips2/java/jre/lib/security/cacerts
KEYSTOREPASS=changeit

# Get the SSL certificate.
openssl s_client -connect ${HOST}:${PORT} </dev/null \
    | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ${HOST}.cert

# Create a keystore and import certificate.
keytool -import -noprompt -trustcacerts \
    -alias ${HOST} -file ${HOST}.cert \
    -keystore ${KEYSTOREFILE} -storepass ${KEYSTOREPASS}

# Verify we've got it.
keytool -list -v -keystore ${KEYSTOREFILE} -storepass ${KEYSTOREPASS} -alias ${HOST}
