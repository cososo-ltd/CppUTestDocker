/* Links against an installed wolfSSL and fails unless both the header and the
 * library report the release given on the command line. */
#include <stdio.h>
#include <string.h>
#include <wolfssl/options.h>
#include <wolfssl/ssl.h>
#include <wolfssl/version.h>

int main(int argc, char** argv)
{
    const char* library = wolfSSL_lib_version();
    int ok = (argc == 2) && (strcmp(argv[1], LIBWOLFSSL_VERSION_STRING) == 0) && (strcmp(argv[1], library) == 0);
    if (!ok)
    {
        fprintf(stderr, "expected %s, header %s, library %s\n", (argc == 2) ? argv[1] : "?", LIBWOLFSSL_VERSION_STRING, library);
    }
    return ok ? 0 : 1;
}
