CCBIN=/usr/bin/gcc
CC=$(CCBIN) -Wall -Wextra -std=c99 -pedantic -g -fsanitize=address
C_LIBS=lib/image_util.c lib/colors.c
C_PNG_LIBS=-I/usr/local/include -L/usr/local/lib
#C_PNG_LIBS=
LINK_LIBS= -lpng

default: segment

checklib: $(C_LIBS) lib/*.h graph.h pixel.c libpng_check.c
	$(CC) -o checklib $(C_PNG_LIBS) $(C_LIBS) pixel.c libpng_check.c $(LINK_LIBS)

pixel: $(C_LIBS) lib/pixel.h pixel.c pixel_test.c
	 $(CC) -o pixel pixel.c pixel_test.c

graph: $(C_LIBS) lib/*.h graph.h pixel.c graph.c graph_test.c
	 $(CC) -o graph pixel.c graph.c graph_test.c

unionfind: $(C_LIBS) lib/*.h graph.h pixel.c graph.c unionfind.c unionfind_test.c
	$(CC) -o unionfind $(C_PNG_LIBS) $(C_LIBS) pixel.c graph.c unionfind.c unionfind_test.c $(LINK_LIBS)

segment: $(C_LIBS) lib/*.h graph.h pixel.c graph.c unionfind.c segment.c segment_test.c
	$(CC) -o segment $(C_PNG_LIBS) $(C_LIBS) pixel.c graph.c unionfind.c segment.c segment_test.c $(LINK_LIBS)

.PHONY: clean
clean:
	rm -Rf *.o lib/*.o img/*.html pixel graph checklib unionfind segment *.dSYM

.PHONY: package
package:
	tar -cvzf hw4-handin2.tgz *
