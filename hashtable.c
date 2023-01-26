

#include "lib/hashtable.h"
#include "lib/english.h"
#include <stdlib.h>
#include <stdio.h>


hashtable* allocate(int size){
     hashtable* S = malloc(sizeof(hashtable));
     S -> size = size;
    entry** larger = malloc(size*sizeof(entry));
     for(int i = 0; i<(size); i++){
         entry* temp = (entry*)malloc(sizeof(entry));
         temp->key = "empty";
         temp ->next = NULL;
         temp ->value = 0;
         larger[i] = temp;
     }
     S -> table = larger;
    return S;
    
}

int put(hashtable* ht, keyType key, valType value){
    int index = hash(key,2) % (ht->size);
  //printf("\n%s\n", key);
     entry* temp = ht->table[index];
   // printf("%d", ht->table[index]->value);
   //printf("\n heyo %d\n", temp -> value);
    if (temp -> key == "empty"){
   // printf("HHIII");
    temp->key = key;
   //printf("\n%s\n", temp->key);
    temp->value = value;
    temp->next = NULL;

    }
    else {
    while(temp->next != NULL) {
       temp = temp->next;
    }
    
    entry* temper = (entry*)malloc(sizeof(entry));
    temper->key = key;
  //  printf("\n%s\n", temper->key);
    temper->value = value;
    temper->next = NULL;
    temp->next = temper;
    }
    
}



valType get(hashtable* ht, keyType key){
    int index = hash(key, 2) % (ht->size);
     entry* temp = ht->table[index];
      if(strcmp(temp->key, "empty") == 0){
          //printf("\n get %s\n",temp->next->key);
            return -1;
    }

    if(strcmp(temp->key, key) == 0){
      valType store = temp->value;
          //printf("\n get %s\n",temp->next->key);
            return store;
    }

    while(temp->next != NULL) {
       
        if (strcmp(temp->next->key, key) == 0){
            valType store = temp->next->value;
          
            return store;
        }
      //  printf("\n get %s\n",temp->key);
       temp = temp->next;
    }
    if (strcmp(temp->next->key, key)==0){
    
         valType store = temp->next->value;
            return store;
    }

  return -1;
}

valType erase(hashtable* ht, keyType key){
     int index = hash(key, 2) % (ht->size);
     entry* temp = ht->table[index];

    if(strcmp(temp->key, key) == 0){
      valType store = temp->value;
        ht->table[index] -> key = "empty";
        ht->table[index] -> value = 0;
          //printf("\n get %s\n",temp->next->key);
            return store;
    }

    while(temp->next != NULL) {
        if (strcmp(temp->next->key, key) == 0){
            valType store = temp->next->value;
            if (temp->next->next == NULL){
                temp->next = NULL;
            }
            else{
            temp->next = temp->next->next;
            }
            free(temp->next);
            return store;
        }
       temp = temp->next;
    }
  return -1;
}

int deallocate(hashtable* ht){
     entry* tmp;
     for(int i = 0; i<(ht->size); i++){
     while (ht->table[i] != NULL)
    {
       tmp = ht->table[i];
       ht->table[i] = ht->table[i]->next;
       free(tmp);
    }
     }  
     free(ht->table);
     free(ht);
    return -1;
}

int hash(keyType key, int m){
  int hash = 7;
for (int i = 0; i < strlen(key)-1; i++) {
    hash = abs(hash + (m * (int) key[i]));
}

return hash;
}
