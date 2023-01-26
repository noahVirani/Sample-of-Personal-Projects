/* CMSC 16200 - Homework 4
 * File: unionfind.c
 * The Union Find implementation using up-trees.
 */

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include "lib/unionfind.h"


/* Initializes the Union-Find structure such that each pixel is in its own subset. */
void init_union_find(graph G, int parentID[ROWS][COLS]) {
    printf("\ninitRow %d\n", ROWS);
    for(int i = 0; i < ROWS; i++){
        for (int k = 0; k < COLS; k++){
           
            parentID[i][k] = -1;
      
        }
    }

    return;
}

/* Find and return the index of the root of the pixel with pixelID idx. */
pixelID find(int parentID[ROWS][COLS], unsigned int width, pixelID idx) {
   int col = get_col(idx, width);
    int row = get_row(idx,width);
    if (parentID[row][col] == -1){
        return idx; }
    else {
        return find(parentID, width, (parentID[row][col]));
    }
 
}

/* Merge the two groups to which pixel p1 and pixel p2 belong. */
void merge(int parentID[ROWS][COLS], unsigned int width, pixelID p1, pixelID p2) {
  
   pixelID idx1 = find(parentID, width, p1);
   pixelID idx2 = find(parentID, width, p2);
   if (p1 == p2) {
       return;
   }
    int col = get_col(idx1, width);
    int row = get_row(idx1,width);
     int col2 = get_col(idx2, width);
    int row2 = get_row(idx2,width);
   if (idx2 > idx1){
       parentID[row2][col2] = p1;
   }
   else if (idx2 < idx1){
       parentID[row][col] = p2;
   }
    return;
}

/*
 * Run UNION-FIND, and store the final sets in the array parentIDs.
 */
void build(graph G, int parentID[ROWS][COLS]) {
   for (int i = 0; i < (int) G->image_height; i++){
       for (int k = 0; k < (int) G->image_width-1; k++){
        int idx = get_pixel_id(i, k, G->image_width);
        int idx2 = get_pixel_id(i, k+1, G->image_width);
       if(are_neighbors(G, idx, idx2)){
           merge(parentID, G->image_width, idx,idx2);
       }
         int idx3 = get_pixel_id(i, k,  G->image_width);
        int idx4 = get_pixel_id(i+1, k,  G->image_width);
       if(are_neighbors(G, idx3, idx4)){
           merge(parentID,  G->image_width, idx3, idx4);
       }

       }
   }
    return;
}
