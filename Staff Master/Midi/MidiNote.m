#import "MidiFile.h"
#import "MidiNote.h"
//#import <Foundation/NSAutoreleasePool.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <assert.h>
#include <stdio.h>
#include <sys/stat.h>
#include <math.h>

@implementation MidiNote

@synthesize startTime;
@synthesize startTimeuS;
@synthesize channel;
@synthesize number;
@synthesize velocity;
@synthesize duration;
@synthesize durationuS;
@synthesize name;
@synthesize normalState;
@synthesize isAccidental;
@synthesize showAccidental;
@synthesize ledgerLines;
@synthesize clef;

int keySignature;

- (id)initWithKey:(int)key andClef:(NSString*)clefType{
    startTime = 0;
    startTimeuS = 0;
    channel = 0;
    duration = 0;
    durationuS = 0;
    number = 0;
    velocity = 0;
    name = @"";
    normalState = @"";
    showAccidental = NO;
    isAccidental = NO;
    keySignature = key;
    ledgerLines = 0;
    clef = clefType;
    
    
    return self;
} 



- (int)endTime
{
    return startTime + duration;
}

-(int)endTimeuS
{
    return startTimeuS + durationuS;
}

-(NSString *)name
{
    switch (number) {
        case 21:
            return @"A0";
            break;
        case 33:
            return @"A1";
            break;
        case 45:
            return @"A2";
            break;
        case 57:
            return @"A3";
            break;
        case 69:
            return @"A4";
            break;
        case 81:
            return @"A5";
            break;
        case 93:
            return @"A6";
            break;
        case 105:
            return @"A7";
            break;
         
        case 26:
            return @"D1";
            break;
        case 38:
            return @"D2";
            break;
        case 50:
            return @"D3";
            break;
        case 62:
            return @"D4";
            break;
        case 74:
            return @"D5";
            break;
        case 86:
            return @"D6";
            break;
        case 98:
            return @"D7";
            break;
        
        case 31:
            return @"G1";
            break;
        case 43:
            return @"G2";
            break;
        case 55:
            return @"G3";
            break;
        case 67:
            return @"G4";
            break;
        case 79:
            return @"G5";
            break;
        case 91:
            return @"G6";
            break;
        case 103:
            return @"G7";
            break;
            
        case 22:
            if (keySignature < 16) {
                return @"B0";
            }
            else{
                return @"A0";
            }
            break;
        case 34:
            if (keySignature < 16) {
                return @"B1";
            }
            else{
                return @"A1";
            }
            break;
        case 46:
            if (keySignature < 16) {
                return @"B2";
            }
            else{
                return @"A2";
            }
            break;
        case 58:
            if (keySignature < 16) {
                return @"B3";
            }
            else{
                return @"A3";
            }
            break;
        case 70:
            if (keySignature < 16) {
                return @"B4";
            }
            else{
                return @"A4";
            }
            break;
        case 82:
            if (keySignature < 16) {
                return @"B5";
            }
            else{
                return @"A5";
            }
            break;
        case 94:
            if (keySignature < 16) {
                return @"B6";
            }
            else{
                return @"A6";
            }
            break;
        case 106:
            if (keySignature < 16) {
                return @"B7";
            }
            else{
                return @"A7";
            }
            break;
          
        case 23:
            if (keySignature < 16) {
                return @"C1";
            }
            else{
                return @"B0";
            }
            break;
        case 35:
            if (keySignature < 16) {
                return @"C2";
            }
            else{
                return @"B1";
            }
            break;
        case 47:
            if (keySignature < 16) {
                return @"C3";
            }
            else{
                return @"B2";
            }
            break;
        case 59:
            if (keySignature < 16) {
                return @"C4";
            }
            else{
                return @"B3";
            }
            break;
        case 71:
            if (keySignature < 16) {
                return @"C5";
            }
            else{
                return @"B4";
            }
            break;
        case 83:
            if (keySignature < 16) {
                return @"C6";
            }
            else{
                return @"B5";
            }
            break;
        case 95:
            if (keySignature < 16) {
                return @"C7";
            }
            else{
                return @"B6";
            }
            break;
        case 107:
            if (keySignature < 16) {
                return @"C8";
            }
            else{
                return @"B7";
            }
            break;
            
        case 24:
            if (keySignature < 16) {
                return @"C1";
            }
            else{
                return @"B0";
            }
            break;
        case 36:
            if (keySignature < 16) {
                return @"C2";
            }
            else{
                return @"B1";
            }
            break;
        case 48:
            if (keySignature < 16) {
                return @"C3";
            }
            else{
                return @"B2";
            }
            break;
        case 60:
            if (keySignature < 16) {
                return @"C4";
            }
            else{
                return @"B3";
            }
            break;
        case 72:
            if (keySignature < 16) {
                return @"C5";
            }
            else{
                return @"B4";
            }
            break;
        case 84:
            if (keySignature < 16) {
                return @"C6";
            }
            else{
                return @"B5";
            }
            break;
        case 96:
            if (keySignature < 16) {
                return @"C7";
            }
            else{
                return @"B6";
            }
            break;
        case 108:
            if (keySignature < 16) {
                return @"C8";
            }
            else{
                return @"B7";
            }
            break;
            
        case 25:
            if (keySignature < 16) {
                return @"D1";
            }
            else{
                return @"C1";
            }
            break;
        case 37:
            if (keySignature < 16) {
                return @"D2";
            }
            else{
                return @"C2";
            }
            break;
        case 49:
            if (keySignature < 16) {
                return @"D3";
            }
            else{
                return @"C3";
            }
            break;
        case 61:
            if (keySignature < 16) {
                return @"D4";
            }
            else{
                return @"C4";
            }
            break;
        case 73:
            if (keySignature < 16) {
                return @"D5";
            }
            else{
                return @"C5";
            }
            break;
        case 85:
            if (keySignature < 16) {
                return @"D6";
            }
            else{
                return @"C6";
            }
            break;
        case 97:
            if (keySignature < 16) {
                return @"D7";
            }
            else{
                return @"C7";
            }
            break;
            
        case 27:
            if (keySignature < 16) {
                return @"E1";
            }
            else{
                return @"D1";
            }
            break;
        case 39:
            if (keySignature < 16) {
                return @"E2";
            }
            else{
                return @"D2";
            }
            break;
        case 51:
            if (keySignature < 16) {
                return @"E3";
            }
            else{
                return @"D3";
            }
            break;
        case 63:
            if (keySignature < 16) {
                return @"E4";
            }
            else{
                return @"D4";
            }
            break;
        case 75:
            if (keySignature < 16) {
                return @"E5";
            }
            else{
                return @"D5";
            }
            break;
        case 87:
            if (keySignature < 16) {
                return @"E6";
            }
            else{
                return @"D6";
            }
            break;
        case 99:
            if (keySignature < 16) {
                return @"E7";
            }
            else{
                return @"D7";
            }
            break;
            
        case 28:
            if (keySignature < 16) {
                return @"F1";
            }
            else{
                return @"E1";
            }
            break;
        case 40:
            if (keySignature < 16) {
                return @"F2";
            }
            else{
                return @"E2";
            }
            break;
        case 52:
            if (keySignature < 16) {
                return @"F3";
            }
            else{
                return @"E3";
            }
            break;
        case 64:
            if (keySignature < 16) {
                return @"F4";
            }
            else{
                return @"E4";
            }
            break;
        case 76:
            if (keySignature < 16) {
                return @"F5";
            }
            else{
                return @"E5";
            }
            break;
        case 88:
            if (keySignature < 16) {
                return @"F6";
            }
            else{
                return @"E6";
            }
            break;
        case 100:
            if (keySignature < 16) {
                return @"F7";
            }
            else{
                return @"E7";
            }
            break;
            
        case 29:
            if (keySignature < 16) {
                return @"F1";
            }
            else{
                return @"E1";
            }
            break;
        case 41:
            if (keySignature < 16) {
                return @"F2";
            }
            else{
                return @"E2";
            }
            break;
        case 53:
            if (keySignature < 16) {
                return @"F3";
            }
            else{
                return @"E3";
            }
            break;
        case 65:
            if (keySignature < 16) {
                return @"F4";
            }
            else{
                return @"E4";
            }
            break;
        case 77:
            if (keySignature < 16) {
                return @"F5";
            }
            else{
                return @"E5";
            }
            break;
        case 89:
            if (keySignature < 16) {
                return @"F6";
            }
            else{
                return @"E6";
            }
            break;
        case 101:
            if (keySignature < 16) {
                return @"F7";
            }
            else{
                return @"E7";
            }
            break;
            
        case 30:
            if (keySignature < 16) {
                return @"G1";
            }
            else{
                return @"F1";
            }
            break;
        case 42:
            if (keySignature < 16) {
                return @"G2";
            }
            else{
                return @"F2";
            }
            break;
        case 54:
            if (keySignature < 16) {
                return @"G3";
            }
            else{
                return @"F3";
            }
            break;
        case 66:
            if (keySignature < 16) {
                return @"G4";
            }
            else{
                return @"F4";
            }
            break;
        case 78:
            if (keySignature < 16) {
                return @"G5";
            }
            else{
                return @"F5";
            }
            break;
        case 90:
            if (keySignature < 16) {
                return @"G6";
            }
            else{
                return @"F6";
            }
            break;
        case 102:
            if (keySignature < 16) {
                return @"G7";
            }
            else{
                return @"F7";
            }
            break;
        
        case 32:
            if (keySignature < 16) {
                return @"A1";
            }
            else{
                return @"G1";
            }
            break;
        case 44:
            if (keySignature < 16) {
                return @"A2";
            }
            else{
                return @"G2";
            }
            break;
        case 56:
            if (keySignature < 16) {
                return @"A3";
            }
            else{
                return @"G3";
            }
            break;
        case 68:
            if (keySignature < 16) {
                return @"A4";
            }
            else{
                return @"G4";
            }
            break;
        case 80:
            if (keySignature < 16) {
                return @"A5";
            }
            else{
                return @"G5";
            }
            break;
        case 92:
            if (keySignature < 16) {
                return @"A6";
            }
            else{
                return @"G6";
            }
            break;
        case 104:
            if (keySignature < 16) {
                return @"A7";
            }
            else{
                return @"G7";
            }
            break;
            
      
        default:
            return @"";
            break;
    
    

    }
}

-(NSString*)normalState
{
    if (number == 21 || number == 33 || number == 45 || number == 57 || number == 69 || number == 81 || number == 93 || number == 105) {
        return @"natural";
    }
    else if (number == 26 || number == 38 || number == 50 || number == 62 || number == 74 || number == 86 || number == 98){
        return @"natural";
    }
    else if (number == 31 || number == 43 || number == 55 || number == 67 || number == 79 || number == 91 || number == 103){
        return @"natural";
    }
    else
    {
        if (keySignature < 16) {
            if (number == 22 || number == 34 || number == 46 || number == 58 || number == 70 || number == 82 || number == 94 || number == 106) {
                return @"flat";
            }
            else if (number == 23 || number == 35 || number == 47 || number == 59 || number == 71 || number == 83 || number == 95 || number == 107){
                return @"flat";
            }
            else if (number == 24 || number == 36 || number == 48 || number == 60 || number == 72 || number == 84 || number == 96 || number == 108){
                return @"natural";
            }
            else if (number == 25 || number == 37 || number == 49 || number == 61 || number == 73 || number == 85 || number == 97){
                return @"flat";
            }
            else if (number == 27 || number == 39 || number == 51 || number == 63 || number == 75 || number == 87 || number == 99){
                return @"flat";
            }
            else if (number == 28 || number == 40 || number == 52 || number == 64 || number == 76 || number == 88 || number == 100){
                return @"flat";
            }
            else if (number == 29 || number == 41 || number == 53 || number == 65 || number == 77 || number == 89 || number == 101){
                return @"nautral";
            }
            else if (number == 30 || number == 42 || number == 54 || number == 66 || number == 78 || number == 90 || number == 102){
                return @"flat";
            }
            else if (number == 32 || number == 44 || number == 56 || number == 68 || number == 80 || number == 92 || number == 104){
                return @"flat";
            }
            else
            {
                return @"";
            }
        }
        else {
            if (number == 22 || number == 34 || number == 46 || number == 58 || number == 70 || number == 82 || number == 94 || number == 106) {
                return @"sharp";
            }
            else if (number == 23 || number == 35 || number == 47 || number == 59 || number == 71 || number == 83 || number == 95 || number == 107){
                return @"natural";
            }
            else if (number == 24 || number == 36 || number == 48 || number == 60 || number == 72 || number == 84 || number == 96 || number == 108){
                return @"sharp";
            }
            else if (number == 25 || number == 37 || number == 49 || number == 61 || number == 73 || number == 85 || number == 97){
                return @"sharp";
            }
            else if (number == 27 || number == 39 || number == 51 || number == 63 || number == 75 || number == 87 || number == 99){
                return @"sharp";
            }
            else if (number == 28 || number == 40 || number == 52 || number == 64 || number == 76 || number == 88 || number == 100){
                return @"natural";
            }
            else if (number == 29 || number == 41 || number == 53 || number == 65 || number == 77 || number == 89 || number == 101){
                return @"sharp";
            }
            else if (number == 30 || number == 42 || number == 54 || number == 66 || number == 78 || number == 90 || number == 102){
                return @"sharp";
            }
            else if (number == 32 || number == 44 || number == 56 || number == 68 || number == 80 || number == 92 || number == 104){
                return @"sharp";
            }
            else
            {
                return @"";
            }
        }
    }
}

-(bool)isAccidental
{
    if(keySignature == 9 || keySignature == - 7)
    {
        if (number == 22 || number == 34 || number == 46 || number == 58 || number == 70 || number == 82 || number == 94 || number == 106 ||
            number == 23 || number == 35 || number == 47 || number == 59 || number == 71 || number == 83 || number == 95 || number == 107 ||
            number == 25 || number == 37 || number == 49 || number == 61 || number == 73 || number == 85 || number == 97 ||
            number == 27 || number == 39 || number == 51 || number == 63 || number == 75 || number == 87 || number == 99 ||
            number == 28 || number == 40 || number == 52 || number == 64 || number == 76 || number == 88 || number == 100 ||
            number == 30 || number == 42 || number == 54 || number == 66 || number == 78 || number == 90 || number == 102 ||
            number == 32 || number == 44 || number == 56 || number == 68 || number == 80 || number == 92 || number == 104)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else if(keySignature == 10 || keySignature == - 6)
    {
        
        if(number == 22 || number == 34 || number == 46 || number == 58 || number == 70 || number == 82 || number == 94 || number == 106 ||
           number == 23 || number == 35 || number == 47 || number == 59 || number == 71 || number == 83 || number == 95 || number == 107 ||
           number == 25 || number == 37 || number == 49 || number == 61 || number == 73 || number == 85 || number == 97 ||
           number == 27 || number == 39 || number == 51 || number == 63 || number == 75 || number == 87 || number == 99 ||
           number == 29 || number == 41 || number == 53 || number == 65 || number == 77 || number == 89 || number == 101 ||
           number == 30 || number == 42 || number == 54 || number == 66 || number == 78 || number == 90 || number == 102 ||
           number == 32 || number == 44 || number == 56 || number == 68 || number == 80 || number == 92 || number == 104)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else if(keySignature == 11 || keySignature == - 5)
    {
        
        if(number == 22 || number == 34 || number == 46 || number == 58 || number == 70 || number == 82 || number == 94 || number == 106 ||
           number == 24 || number == 36 || number == 48 || number == 60 || number == 72 || number == 84 || number == 96 || number == 108 ||
           number == 25 || number == 37 || number == 49 || number == 61 || number == 73 || number == 85 || number == 97 ||
           number == 27 || number == 39 || number == 51 || number == 63 || number == 75 || number == 87 || number == 99 ||
           number == 29 || number == 41 || number == 53 || number == 65 || number == 77 || number == 89 || number == 101 ||
           number == 30 || number == 42 || number == 54 || number == 66 || number == 78 || number == 90 || number == 102 ||
           number == 32 || number == 44 || number == 56 || number == 68 || number == 80 || number == 92 || number == 104)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else if(keySignature == 12 || keySignature == - 4)
    {
        
        if(number == 22 || number == 34 || number == 46 || number == 58 || number == 70 || number == 82 || number == 94 || number == 106 ||
           number == 24 || number == 36 || number == 48 || number == 60 || number == 72 || number == 84 || number == 96 || number == 108 ||
           number == 25 || number == 37 || number == 49 || number == 61 || number == 73 || number == 85 || number == 97 ||
           number == 27 || number == 39 || number == 51 || number == 63 || number == 75 || number == 87 || number == 99 ||
           number == 29 || number == 41 || number == 53 || number == 65 || number == 77 || number == 89 || number == 101 ||
           number == 31 || number == 43 || number == 55 || number == 67 || number == 79 || number == 91 || number == 103 ||
           number == 32 || number == 44 || number == 56 || number == 68 || number == 80 || number == 92 || number == 104)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else if(keySignature == 13 || keySignature == - 3)
    {
        
        if(number == 22 || number == 34 || number == 46 || number == 58 || number == 70 || number == 82 || number == 94 || number == 106 ||
           number == 24 || number == 36 || number == 48 || number == 60 || number == 72 || number == 84 || number == 96 || number == 108 ||
           number == 26 || number == 38 || number == 50 || number == 62 || number == 74 || number == 86 || number == 98 ||
           number == 27 || number == 39 || number == 51 || number == 63 || number == 75 || number == 87 || number == 99 ||
           number == 29 || number == 41 || number == 53 || number == 65 || number == 77 || number == 89 || number == 101 ||
           number == 31 || number == 43 || number == 55 || number == 67 || number == 79 || number == 91 || number == 103 ||
           number == 32 || number == 44 || number == 56 || number == 68 || number == 80 || number == 92 || number == 104)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else if(keySignature == 14 || keySignature == - 2)
    {
        
        if(number == 21 || number == 33 || number == 45 || number == 57 || number == 69 || number == 81 || number == 93 || number == 105 ||
           number == 22 || number == 34 || number == 46 || number == 58 || number == 70 || number == 82 || number == 94 || number == 106 ||
           number == 24 || number == 36 || number == 48 || number == 60 || number == 72 || number == 84 || number == 96 || number == 108 ||
           number == 26 || number == 38 || number == 50 || number == 62 || number == 74 || number == 86 || number == 98 ||
           number == 27 || number == 39 || number == 51 || number == 63 || number == 75 || number == 87 || number == 99 ||
           number == 29 || number == 41 || number == 53 || number == 65 || number == 77 || number == 89 || number == 101 ||
           number == 31 || number == 43 || number == 55 || number == 67 || number == 79 || number == 91 || number == 103)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else if(keySignature == 15 || keySignature == - 1)
    {
        
        if(number == 21 || number == 33 || number == 45 || number == 57 || number == 69 || number == 81 || number == 93 || number == 105 ||
           number == 22 || number == 34 || number == 46 || number == 58 || number == 70 || number == 82 || number == 94 || number == 106 ||
           number == 24 || number == 36 || number == 48 || number == 60 || number == 72 || number == 84 || number == 96 || number == 108 ||
           number == 26 || number == 38 || number == 50 || number == 62 || number == 74 || number == 86 || number == 98 ||
           number == 28 || number == 40 || number == 52 || number == 64 || number == 76 || number == 88 || number == 100 ||
           number == 29 || number == 41 || number == 53 || number == 65 || number == 77 || number == 89 || number == 101 ||
           number == 31 || number == 43 || number == 55 || number == 67 || number == 79 || number == 91 || number == 103)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else if(keySignature == 16 || keySignature == 0)
    {
        
        if(number == 21 || number == 33 || number == 45 || number == 57 || number == 69 || number == 81 || number == 93 || number == 105 ||
           number == 23 || number == 35 || number == 47 || number == 59 || number == 71 || number == 83 || number == 95 || number == 107 ||
           number == 24 || number == 36 || number == 48 || number == 60 || number == 72 || number == 84 || number == 96 || number == 108 ||
           number == 26 || number == 38 || number == 50 || number == 62 || number == 74 || number == 86 || number == 98 ||
           number == 28 || number == 40 || number == 52 || number == 64 || number == 76 || number == 88 || number == 100 ||
           number == 29 || number == 41 || number == 53 || number == 65 || number == 77 || number == 89 || number == 101 ||
           number == 31 || number == 43 || number == 55 || number == 67 || number == 79 || number == 91 || number == 103)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else if(keySignature == 17 || keySignature == 1)
    {
        
        if(number == 21 || number == 33 || number == 45 || number == 57 || number == 69 || number == 81 || number == 93 || number == 105 ||
           number == 23 || number == 35 || number == 47 || number == 59 || number == 71 || number == 83 || number == 95 || number == 107 ||
           number == 24 || number == 36 || number == 48 || number == 60 || number == 72 || number == 84 || number == 96 || number == 108 ||
           number == 26 || number == 38 || number == 50 || number == 62 || number == 74 || number == 86 || number == 98 ||
           number == 28 || number == 40 || number == 52 || number == 64 || number == 76 || number == 88 || number == 100 ||
           number == 30 || number == 42 || number == 54 || number == 66 || number == 78 || number == 90 || number == 102 ||
           number == 31 || number == 43 || number == 55 || number == 67 || number == 79 || number == 91 || number == 103)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else if(keySignature == 18 || keySignature == 2)
    {
        
        if(number == 21 || number == 33 || number == 45 || number == 57 || number == 69 || number == 81 || number == 93 || number == 105 ||
           number == 23 || number == 35 || number == 47 || number == 59 || number == 71 || number == 83 || number == 95 || number == 107 ||
           number == 25 || number == 37 || number == 49 || number == 61 || number == 73 || number == 85 || number == 97 ||
           number == 26 || number == 38 || number == 50 || number == 62 || number == 74 || number == 86 || number == 98 ||
           number == 28 || number == 40 || number == 52 || number == 64 || number == 76 || number == 88 || number == 100 ||
           number == 30 || number == 42 || number == 54 || number == 66 || number == 78 || number == 90 || number == 102 ||
           number == 31 || number == 43 || number == 55 || number == 67 || number == 79 || number == 91 || number == 103)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else if(keySignature == 19 || keySignature == 3)
    {
        
        if(number == 21 || number == 33 || number == 45 || number == 57 || number == 69 || number == 81 || number == 93 || number == 105 ||
           number == 23 || number == 35 || number == 47 || number == 59 || number == 71 || number == 83 || number == 95 || number == 107 ||
           number == 25 || number == 37 || number == 49 || number == 61 || number == 73 || number == 85 || number == 97 ||
           number == 26 || number == 38 || number == 50 || number == 62 || number == 74 || number == 86 || number == 98 ||
           number == 28 || number == 40 || number == 52 || number == 64 || number == 76 || number == 88 || number == 100 ||
           number == 30 || number == 42 || number == 54 || number == 66 || number == 78 || number == 90 || number == 102 ||
           number == 32 || number == 44 || number == 56 || number == 68 || number == 80 || number == 92 || number == 104)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else if(keySignature == 20 || keySignature == 4)
    {
        
        if(number == 21 || number == 33 || number == 45 || number == 57 || number == 69 || number == 81 || number == 93 || number == 105 ||
           number == 23 || number == 35 || number == 47 || number == 59 || number == 71 || number == 83 || number == 95 || number == 107 ||
           number == 25 || number == 37 || number == 49 || number == 61 || number == 73 || number == 85 || number == 97 ||
           number == 27 || number == 39 || number == 51 || number == 63 || number == 75 || number == 87 || number == 99 ||
           number == 28 || number == 40 || number == 52 || number == 64 || number == 76 || number == 88 || number == 100 ||
           number == 30 || number == 42 || number == 54 || number == 66 || number == 78 || number == 90 || number == 102 ||
           number == 32 || number == 44 || number == 56 || number == 68 || number == 80 || number == 92 || number == 104)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else if(keySignature == 21 || keySignature == 5)
    {
        
        if(number == 22 || number == 34 || number == 46 || number == 58 || number == 70 || number == 82 || number == 94 || number == 106 ||
           number == 23 || number == 35 || number == 47 || number == 59 || number == 71 || number == 83 || number == 95 || number == 107 ||
           number == 25 || number == 37 || number == 49 || number == 61 || number == 73 || number == 85 || number == 97 ||
           number == 27 || number == 39 || number == 51 || number == 63 || number == 75 || number == 87 || number == 99 ||
           number == 28 || number == 40 || number == 52 || number == 64 || number == 76 || number == 88 || number == 100 ||
           number == 30 || number == 42 || number == 54 || number == 66 || number == 78 || number == 90 || number == 102 ||
           number == 32 || number == 44 || number == 56 || number == 68 || number == 80 || number == 92 || number == 104)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else if(keySignature == 22 || keySignature == 6)
    {
        
        if(number == 22 || number == 34 || number == 46 || number == 58 || number == 70 || number == 82 || number == 94 || number == 106 ||
           number == 23 || number == 35 || number == 47 || number == 59 || number == 71 || number == 83 || number == 95 || number == 107 ||
           number == 25 || number == 37 || number == 49 || number == 61 || number == 73 || number == 85 || number == 97 ||
           number == 27 || number == 39 || number == 51 || number == 63 || number == 75 || number == 87 || number == 99 ||
           number == 29 || number == 41 || number == 53 || number == 65 || number == 77 || number == 89 || number == 101 ||
           number == 30 || number == 42 || number == 54 || number == 66 || number == 78 || number == 90 || number == 102 ||
           number == 32 || number == 44 || number == 56 || number == 68 || number == 80 || number == 92 || number == 104)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else if(keySignature == 23 || keySignature == 7)
    {
        
        if(number == 22 || number == 34 || number == 46 || number == 58 || number == 70 || number == 82 || number == 94 || number == 106 ||
           number == 24 || number == 36 || number == 48 || number == 60 || number == 72 || number == 84 || number == 96 || number == 108 ||
           number == 25 || number == 37 || number == 49 || number == 61 || number == 73 || number == 85 || number == 97 ||
           number == 27 || number == 39 || number == 51 || number == 63 || number == 75 || number == 87 || number == 99 ||
           number == 29 || number == 41 || number == 53 || number == 65 || number == 77 || number == 89 || number == 101 ||
           number == 30 || number == 42 || number == 54 || number == 66 || number == 78 || number == 90 || number == 102 ||
           number == 32 || number == 44 || number == 56 || number == 68 || number == 80 || number == 92 || number == 104)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else
    {
        if(number == 21 || number == 33 || number == 45 || number == 57 || number == 69 || number == 81 || number == 93 || number == 105 ||
           number == 23 || number == 35 || number == 47 || number == 59 || number == 71 || number == 83 || number == 95 || number == 107 ||
           number == 24 || number == 36 || number == 48 || number == 60 || number == 72 || number == 84 || number == 96 || number == 108 ||
           number == 26 || number == 38 || number == 50 || number == 62 || number == 74 || number == 86 || number == 98 ||
           number == 28 || number == 40 || number == 52 || number == 64 || number == 76 || number == 88 || number == 100 ||
           number == 29 || number == 41 || number == 53 || number == 65 || number == 77 || number == 89 || number == 101 ||
           number == 31 || number == 43 || number == 55 || number == 67 || number == 79 || number == 91 || number == 103)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    
}

-(int)ledgerLinesFromNote:(NSString*)noteName andClef:(NSString*)clefType
{
    int lines = 0;
    
    if ([clefType isEqual:@"Bass"]) {
        if ([noteName  isEqual: @"A0"] || [noteName isEqual: @"B0"]) {
            lines = 6;
        }
        else if ([noteName  isEqual: @"C1"]|| [noteName isEqual: @"D1"]){
            lines = 5;
        }
        else if ([noteName  isEqual: @"E1"]|| [noteName isEqual: @"F1"]){
            lines = 4;
        }
        else if ([noteName  isEqual: @"G1"]|| [noteName isEqual: @"A1"]){
            lines = 3;
        }
        else if ([noteName  isEqual: @"B1"]|| [noteName isEqual: @"C2"]){
            lines = 2;
        }
        else if ([noteName  isEqual: @"D2"]|| [noteName isEqual: @"E2"]){
            lines = 1;
        }
        else if ([noteName  isEqual: @"C4"]|| [noteName isEqual: @"D4"]){
            lines = 1;
        }
        else if ([noteName  isEqual: @"E4"]|| [noteName isEqual: @"F4"]){
            lines = 2;
        }
        else if ([noteName  isEqual: @"G4"]|| [noteName isEqual: @"A4"]){
            lines = 3;
        }
    }
    else if ([clefType isEqual:@"Treble"])
    {
        if ([noteName  isEqual: @"C8"]) {
            lines = 9;
        }
        else if ([noteName  isEqual: @"B7"] || [noteName isEqual: @"A7"]) {
            lines = 8;
        }
        else if ([noteName  isEqual: @"G7"] || [noteName isEqual: @"F7"]) {
            lines = 7;
        }
        else if ([noteName  isEqual: @"E7"] || [noteName isEqual: @"D7"]) {
            lines = 6;
        }
        else if ([noteName  isEqual: @"C7"] || [noteName isEqual: @"B6"]) {
            lines = 5;
        }
        else if ([noteName  isEqual: @"A6"] || [noteName isEqual: @"G6"]) {
            lines = 4;
        }
        else if ([noteName  isEqual: @"F6"] || [noteName isEqual: @"E6"]) {
            lines = 3;
        }
        else if ([noteName  isEqual: @"D6"] || [noteName isEqual: @"C6"]) {
            lines = 2;
        }
        else if ([noteName  isEqual: @"B5"] || [noteName isEqual: @"A5"]) {
            lines = 1;
        }
        else if ([noteName  isEqual: @"C4"] || [noteName isEqual: @"B3"]) {
            lines = 1;
        }
        else if ([noteName  isEqual: @"A3"] || [noteName isEqual: @"G3"]) {
            lines = 2;
        }
        else if ([noteName  isEqual: @"F3"] || [noteName isEqual: @"E3"]) {
            lines = 3;
        }
    }
    
    return lines;
}
/* A NoteOff event occurs for this note at the given time.
 * Calculate the note duration based on the noteoff event.
 */
- (void)noteOff:(int)endtime {
    duration = endtime - startTime;
}

- (void)noteOffuS:(int)endtimeuS {
    durationuS = endtimeuS -startTimeuS;
}


- (NSString*)description {
    NSString *s = [NSString stringWithFormat:
                      @"MidiNote channel=%d number=%d start=%d duration=%d",
                      channel, number, startTime, duration ];
    return s;
}




@end


