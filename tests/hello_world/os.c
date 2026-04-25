#include <stdio.h>


[[noreturn]]
[[gnu::used]]
void _exit (int status) {
    (void) status;
    while (1)
        ;
}

static int
debug_putc(char c, FILE *file)
{
	(void) file;		/* Not used in this function */
	return c;
}

static int
debug_flush(FILE *file)
{
	(void) file;		/* Not used in this function */

	return 0;
}

static FILE __stdio = FDEV_SETUP_STREAM(debug_putc,
					NULL,
					debug_flush,
					_FDEV_SETUP_WRITE);

FILE *const stdin = &__stdio;
__strong_reference(stdin, stdout);
__strong_reference(stdin, stderr);
