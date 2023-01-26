

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "lib/english.h"
#include "lib/decrypt.h"
#include "lib/hashtable.h"

void decipher_word(word_t *A, hashtable* ht, int wordcount,
                   word_t key, word_t cipher, word_t plain) {
    int index1 =  get(ht, cipher);

    int index2 = get(ht, key);
   
    int index3 = index1 - index2;
    if (index3 <= 0) {
        index3 = wordcount + index3;
    }

  
     strcpy(plain, A[index3]);
  

	return;
}

void decrypt_msg(word_t *A, hashtable* ht, int wordcount,
                 word_t *key_sentence, int key_len,
                 word_t *cipher_text, word_t *plain_text, int txt_len) {
         int k = 0;
     
        for (size_t i = 0; i < txt_len; i++)
        {  
            if (k >= key_len){
                k = 0;
            }
            decipher_word(A, ht, wordcount, key_sentence[k], cipher_text[i], plain_text[i]);

           k++;
        }
	return;
}

