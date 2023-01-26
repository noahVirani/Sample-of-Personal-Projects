
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "lib/english.h"
#include "lib/hashtable.h"
#include "lib/encrypt.h"

void encipher_word(word_t *A, hashtable* ht, int wordcount,
                   word_t key, word_t plain, word_t cipher) {
    int index1 =  get(ht, plain);
    int index2 = get(ht, key);
    int index3 = index1 + index2;
    if (index3 >= wordcount) {
        index3 = index3 - wordcount;
    }

    strcpy(cipher, A[index3]);


    return;
}

void encrypt_msg(word_t *A, hashtable* ht, int wordcount,
                 word_t *key_sentence, int key_len,
                 word_t *plain_text, word_t *cipher_text, int txt_len) {
        int k = 0;
     
        for (size_t i = 0; i < txt_len; i++)
        {  
            if (k >= key_len){
                k = 0;
            }
            encipher_word(A, ht, wordcount, key_sentence[k], plain_text[i], cipher_text[i]);
           k++;
        }
    return;
}

