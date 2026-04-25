/* SPDX-License-Identifier: Apache-2.0
 *
 */

#include <stdint.h>
#include <stdio.h>

int main(void) {
    uint32_t result;

    result = UINT32_C(42);
    printf("Hello, world %d\n", result);

    return 0;
}
