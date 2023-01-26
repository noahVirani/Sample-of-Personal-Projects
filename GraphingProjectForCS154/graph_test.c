#include <assert.h>
#include <stdio.h>

#include "graph.h"

#define TEST_ROWS 10
#define TEST_COLS 8


int main(void) {

    // Initialize the pixels array
    unsigned int row, col;
    pixel pixels[ROWS][COLS];

    for (row = 0; row < TEST_ROWS; row++) {
        for (col = 0; col < TEST_COLS; col++) {
            pixels[row][col] = make_pixel(row, row, row, row);
        }
    }

    graph G = pixel_graph_new(TEST_COLS, TEST_ROWS, pixels);

    // TASK 4.6 TESTS
    assert(is_vertex(G, 0));
    assert(is_vertex(G, 20));
    assert(is_vertex(G, 79));
    assert(!is_vertex(G, 80));
    assert(!is_vertex(G, 100));

    // TASK 4.7 TESTS
    assert(are_neighbors(G, 0, 1));
    assert(are_neighbors(G, 9, 8));
    assert(!are_neighbors(G, 0, 8));
    assert(!are_neighbors(G, 11, 3));

    pixel_graph_free(G);

    printf("Passed all tests.\n");
    return 0;
}
