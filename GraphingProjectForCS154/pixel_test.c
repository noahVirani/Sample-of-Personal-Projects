#include <stdio.h>
#include <assert.h>
#include "lib/pixel.h"

#define TEST_ROWS 10
#define TEST_COLS 6

int main(void) {
    // TESTS FOR 4.1
    assert(0 == get_pixel_id(0, 0, 10));
    assert(1 == get_pixel_id(0, 1, 2));
    assert(5 == get_pixel_id(2, 1, 2)); 
    assert(3 == get_pixel_id(1, 0, 3));
    assert(8 == get_pixel_id(1, 3, 5));

    // TESTS FOR 4.2
    assert(0 == get_row(0, 10));
    assert(0 == get_row(1, 2));
    assert(2 == get_row(5, 2)); 
    assert(1 == get_row(3, 3));
    assert(1 == get_row(8, 5));

    // TESTS FOR 4.3
    assert(0 == get_col(0, 10));
    assert(1 == get_col(1, 2));
    assert(1 == get_col(5, 2)); 
    assert(0 == get_col(3, 3));
    assert(3 == get_col(8, 5));

    printf("Passed all tests.\n");

    return 0;
}
