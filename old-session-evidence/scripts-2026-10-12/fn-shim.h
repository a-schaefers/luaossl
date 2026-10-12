#include <openssl/ocsp.h>
#undef PEM_write_bio_OCSP_RESPONSE
int PEM_write_bio_OCSP_RESPONSE(BIO *bp, const OCSP_RESPONSE *x);
