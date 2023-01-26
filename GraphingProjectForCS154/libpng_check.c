/* CMSC 16200 - Homework 4
 * File: libpng_check.c
 * A simple check if libpng was successful installed.
 */

#include <stdio.h>
#include <stdlib.h>
#include "lib/image_util.h"
#include "lib/pixel.h"

int main() {
    // declare variables
    pixel pixels[ROWS][COLS];
    unsigned int width;
    unsigned int height;

    // read in png file
    printf("Reading from img/uchicago.png: ");
    provided_read_png("img/uchicago.png", pixels, &width, &height);
    printf("Success!\n");
    // print to html
    printf("Generating img/uchicago.html: ");
    provided_print_image_to_html("img/uchicago.html", pixels, width, height);
    printf("Success!\n");
}

