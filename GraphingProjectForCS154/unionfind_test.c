#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <assert.h>
#include "lib/unionfind.h"

int main() {
    printf("Testing Union Find\n");
    // Declare variables
    pixel pixels[ROWS][COLS];    
    unsigned int width;
    unsigned int height;
    int parentID[ROWS][COLS];
    graph G;
    
    // Read in png file. Look in the 'img' folder for more sample images
    provided_read_png("img/small.png", pixels, &width, &height);

    // Allocate strict pixel graph
    G = pixel_graph_new(width, height, pixels);

    // Initialize 2-D array parentID, 
    // i.e. create a forest of up trees in ParentID
    init_union_find(G, parentID);



    printf("Initialized Union Find%d\n", parentID[0][0]);

    // Apply your UNION-FIND implementation
    build(G, parentID);  // This may take a few seconds

    printf("Built Union-Find for graph G\n");

    /************************************
     * Test your resulting parentID here.
     ************************************/
    // Check if each pixel was mapped to its correct representative pixel
    // Note that this test relies on knowledge of the image small.png as well
    // as a tie-breaking scheme during merge that favors lower pixel IDs
    // IF you change the image, the 'correct' answers will change.
    unsigned int row, col;
    pixelID idx, target;




    for (row = 0; row < G->image_height; row++) {
        for (col = 0; col < G->image_width; col++) {
            idx = get_pixel_id(row, col, width);

            if (row < 10 && col < 10) {
                target = get_pixel_id(0, 0, width);
            } else if ((row >= 10 && row < 20) && (col >= 10 && col < 20)) {
                target = get_pixel_id(10, 10, width);
            } else if (row < 10 && col >= 10) {
                target = get_pixel_id(0, 10, width);
            } else if (row >= 10 && col < 10) {
                target = get_pixel_id(10, 0, width);
            }
            assert(find(parentID, width, idx) == target);
        }
    }
    

    // Free strict pixel graph
    pixel_graph_free(G);

    printf("Passed All Tests\n");

    return 0;
}
