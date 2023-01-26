
#include "lib/hashtable.h"
#include <stdlib.h>
#include <stdio.h>


int main(void) {
 printf("\nUh oh1\n");
  hashtable* ht = allocate(20);

  keyType key = "Key1";
  valType value = 1;
 printf("\nUh oh2\n");
  put(ht, key, value);

  valType result = get(ht, key);
  printf("The value of %s is %d\n", key, result);

  
   printf("The value of %d\n", erase(ht, key));
  
  result = get(ht, key);
  printf("The value of %s is %d\n", key, result);


  deallocate(ht);
  printf("All tests have been successfully passed.\n");
  return 0;
}

