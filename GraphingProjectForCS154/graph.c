/* CMSC 16200 - Homework 4
 * File: graph.c
 * The strict pixel graph and its implementation.
 */

#include <stdlib.h>
#include <stdio.h>
#include "graph.h"


// Allocate enough space for the graph, and initialize its required fields.
graph pixel_graph_new(unsigned int img_width,
                      unsigned int img_height,
                      pixel pixels[ROWS][COLS]) {

  graph S = (graph)malloc(3*sizeof(int)+sizeof(struct pixel_graph_header));
;
   for (int row = 0; row < (int) img_height; row++) {
        for (int col = 0; col < (int) img_width; col++) {
            S->pixels[row][col] = pixels[row][col];
         
        }
    }
  


      S->image_width = img_width;
    S -> image_height = img_height;
   
    return S;


}

// Free up the memory used by graph G.
void pixel_graph_free(graph G) {
    free(G);

    return;
}

// Returns whether the given pixel ID is a valid vertex
bool is_vertex(graph G, pixelID idx) {
    int col = get_col(idx, G->image_width);
    int row = get_row(idx,G->image_width);
    if ((col < (int) G->image_width) && (row < (int) G->image_height)){
        return true;
    }
    return false;
}

bool are_neighbors(graph G, pixelID v, pixelID w) {
    int col = get_col(w, G->image_width);
    int row = get_row(w,G->image_width);


    int col2 = get_col(v, G->image_width);
    int row2 = get_row(v,G->image_width);
 



    if (G->pixels[row][col] == G->pixels[row2][col2]){
    if (((col2 - col == 1) || (col2 - col == -1)) && (row == row2)) {
 
        return true;
    }
   else if (((row2 - row == 1) || (row2 - row == -1)) && (col == col2)) {
         
        return true;
    }}
    
    return false;
}


