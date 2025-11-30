//  main.m
//  chess
//
//  Created by Andrew Wang on 15/07/2013, Completed by MCN on 03/2022
//  Copyright (c) 2013 Andrew Wang. All rights reserved.

int main(int argc, const char * argv[])
{
   // NSLog pour le fun...
   NSLog(@"Welcome sur Objective-Chess\n");
   NSLog(@"La taille de stockage pour un 'int' est de %li bits\n", sizeof(int));
   NSLog(@"La valeur maxi pour un 'int' est de %d \n",INT_MAX);
   
   // Seule ligne véritablement nécessaire
   return NSApplicationMain(argc, argv);
}
