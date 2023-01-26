/* CMSC 16200 - Homework 4
 * File: segment.c
 * Implementations for operations on connected component.
 */

#include "lib/segment.h"

/* Counting the connected components in the image. */
int count_connected_components(graph G, int parentID[ROWS][COLS]) {
    int count = 0;
    for(int i=0; i< (int)G->image_height; i++){
        for(int k = 0; k< (int)G->image_width; k++){
            if(parentID[i][k] == -1)
            
                count++;
        }

    }
    return count;
}

/* Recolor the connected components in the image. */
void recolor_connected_components(graph G, int parentID[ROWS][COLS]) {
    int color[count_connected_components(G, parentID)];
    int count = 0;
    for (int i = 0; i< (int)G->image_height;i++){
        for(int k = 0; k< (int)G->image_width; k++){
            if(parentID[i][k] == -1){
                color[count] = get_pixel_id(i, k, G->image_width);
             
                count++;}
        }
    }

 for (int row = 0; row< (int)G->image_height;row++){
        for(int col = 0; col< (int)G->image_width; col++){
            int counter = 0;
            int idx = get_pixel_id(row, col, G->image_width);
            int idx2 = find(parentID, G->image_width, idx);
  
            while(idx2 != color[counter]){
                counter++;
            }
            int row = get_row(idx, G->image_width);
            int col = get_col(idx, G->image_width);
            G->pixels[row][col] = get_color(counter);

        }
    }


    return;
}
