//
//  MIDIUtility.m
//  MIDIExplore
//
//  Created by Taylor Moss on 11/8/14.
//  Copyright (c) 2014 MOSSTECH. All rights reserved.
//

#import "MIDIUtility.h"
#import <CoreMIDI/CoreMIDI.h>
#import "AudioUtility.h"

@implementation MIDIUtility

#define SYSEX_LENGTH 1024
BAudioController *audioController;


static void midiInputCallback (const MIDIPacketList *list,
                               void *procRef,
                               void *srcRef)
{
    processMessage(list);
    
}


+(void)setupDevice
{
    audioController = [[BAudioController alloc] init];
    
    MIDIClientRef midiClient;
    OSStatus result;
    
    result = MIDIClientCreate(CFSTR("MIDI client"), NULL, NULL, &midiClient);
    if (result != noErr) {
        NSLog(@"Error creating MIDI client.");
        return;
    }
    
    MIDIPortRef inputPort;
    
    result = MIDIInputPortCreate(midiClient, CFSTR("Input"), midiInputCallback, NULL, &inputPort);
    
    MIDIObjectRef endPoint;
    MIDIObjectType foundObj;
    
    result = MIDIObjectFindByUniqueID(-1679753259, &endPoint, &foundObj);
    
    result = MIDIPortConnectSource(inputPort, endPoint, NULL);
    
    
    
}

void processMessage(const MIDIPacketList *list)
{
    
    NSLog(@"midiInputCallback was called");
    
    
    bool continueSysEx = false;
    UInt16 nBytes;
    const MIDIPacket *packet = &list->packet[0];
    
    unsigned char sysExMessage[SYSEX_LENGTH];
    unsigned int sysExLength = 0;
    
    for (unsigned int i =0; i < list->numPackets; i++)
    {
        nBytes = packet->length;
        
        // Check if this is the end of a continued SysEx message
        if (continueSysEx) {
            unsigned int lengthToCopy = MIN (nBytes, SYSEX_LENGTH - sysExLength);
            // Copy the message into our SysEx message buffer,
            // making sure not to overrun the buffer
            memcpy(sysExMessage + sysExLength, packet->data, lengthToCopy);
            sysExLength += lengthToCopy;
        
            // Check if the last byte is SysEx End.
            continueSysEx = (packet->data[nBytes - 1] == 0xF7);
            
            if (!continueSysEx || sysExLength == 1024) {
                // We would process the SysEx message here, as it is we're just ignoring it
                
                sysExLength = 0;
            }
            
        }
        else {
            UInt16 iByte, size;
            
            iByte = 0;
            while (iByte < nBytes) {
                size = 0;
                
                // First byte should be status
                unsigned char status = packet->data[iByte];
                if (status < 0xC0) {
                    size = 3;
                } else if (status < 0xE0) {
                    size = 2;
                } else if (status < 0xF0) {
                    size = 3;
                } else if (status == 0xF0) {
                    // MIDI SysEx then we copy the rest of the message into the SysEx message buffer
                    unsigned int lengthLeftInMessage = nBytes - iByte;
                    unsigned int lengthToCopy = MIN (lengthLeftInMessage, SYSEX_LENGTH);
                    
                    memcpy(sysExMessage + sysExLength, packet->data, lengthToCopy);
                    sysExLength += lengthToCopy;
                    
                    size = 0;
                    iByte = nBytes;
                    
                    // Check whether the message at the end is the end of the SysEx
                    continueSysEx = (packet->data[nBytes - 1] != 0xF7);
                } else if (status < 0xF3) {
                    size = 3;
                } else if (status == 0xF3) {
                    size = 2;
                } else {
                    size = 1;
                }
                
                unsigned char messageType = status & 0xF0;
                //unsigned char messageChannel = status & 0xF;
                Byte note;
                UInt32 velocity;
                
                switch (messageType) {
                    case 0x80:
                        note = (Byte) packet->data[iByte + 1];
                        velocity = packet->data[iByte + 2];
                        [audioController noteOff:packet->data[iByte + 1]];
                        break;
                        
                    case 0x90:
                       
                        note = (Byte) packet->data[iByte + 1];
                        velocity = packet->data[iByte + 2];
                        [audioController noteOn:note withVelociy:velocity];
                        
                        break;
                        
                    case 0xA0:
                        NSLog(@"Aftertouch: %d, %d", packet->data[iByte + 1], packet->data[iByte + 2]);
                        break;
                        
                    case 0xB0:
                        NSLog(@"Control message: %d, %d", packet->data[iByte + 1], packet->data[iByte + 2]);
                        break;
                        
                    case 0xC0:
                        NSLog(@"Program change: %d", packet->data[iByte + 1]);
                        break;
                        
                    case 0xD0:
                        NSLog(@"Change aftertouch: %d", packet->data[iByte + 1]);
                        break;
                        
                    case 0xE0:
                        NSLog(@"Pitch wheel: %d, %d", packet->data[iByte + 1], packet->data[iByte + 2]);
                        break;
                        
                    default:
                        NSLog(@"Some other message");
                        break;
                }
                
                iByte += size;
            }
        }
                
                
    }
    
    packet = MIDIPacketNext(packet);
        
}
    



@end
