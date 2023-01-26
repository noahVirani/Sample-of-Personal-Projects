/* CMSC 16200 - Homework 4
 * File: pixel.c
 * The pixel type and the implementation of library for pixel ops
 */

#include <stdio.h>
#include <stdlib.h>
#include "lib/pixel.h"

// Returns its index to 1-D pixel array, given the coords of input pixel.
pixelID get_pixel_id(unsigned int row, unsigned int col, unsigned int width) {

    return row*width+col;

}

// Returns the row of the pixel,
// given its index and the width of the image.
unsigned int get_row(pixelID idx, unsigned int width) {
    return (int) (idx)/width;

}

// Returns the column of the pixel
// given its index and the width of the image.
unsigned int get_col(pixelID idx, unsigned int width) {
             return (int) idx % width;
}

// Returns the red component of the pixel p, between 0 and 255, inclusive.
unsigned int get_red(pixel p) {
    return (p >> 16) & (0xFF);
}

// Returns the green component of the pixel p, between 0 and 255, inclusive.
unsigned int get_green(pixel p) {
    return (p >> 8) & (0xFF);
}

// Returns the blue component of the pixel p, between 0 and 255, inclusive.
unsigned int get_blue(pixel p) {
    return p & (0xFF);
}

// Returns the alpha component of the pixel p, between 0 and 255, inclusive.
unsigned int get_alpha(pixel p) {
    return (p >> 24) & (0xFF);
}

// Returns an int representing an RGB pixel consisting of the given
// alpha, red, green and blue intensity values.
// All intensity values must be between 0 and 255,
// inclusive.
pixel make_pixel(unsigned int alpha, unsigned int red, unsigned int green, unsigned int blue) {
  return ((alpha & 0xFF) << 24) | ((red & 0xFF) << 16) | ((green & 0xFF) << 8) | (blue & 0xFF);
}
