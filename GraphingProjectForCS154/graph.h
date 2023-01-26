/* CMSC 16200 - Homework 4
 * File: graph.h
 * The strict pixel graph and its interface.
 */

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <inttypes.h>
#include "lib/image_util.h"
#include "lib/pixel.h"

#ifndef _GRAPH_H_
#define _GRAPH_H_



struct pixel_graph_header {
  
    unsigned int image_width;
    unsigned int image_height;
    pixel pixels[ROWS][COLS];
   
    // Define fields to hold graph data
};


typedef struct pixel_graph_header* graph;

// Allocate enough space for the graph, and intialize its required fields.
graph pixel_graph_new(unsigned int img_width,
                      unsigned int img_height,
                      pixel pixels[ROWS][COLS]);

// Free up the memory used by graph G.
void pixel_graph_free(graph G);

// Returns true if the given pixel ID refers to a valid vertex
bool is_vertex(graph G, pixelID idx);

// Return true if there is an edge between the given pixel IDs
bool are_neighbors(graph G, pixelID v, pixelID w);

#endif /* _GRAPH_H_ */
