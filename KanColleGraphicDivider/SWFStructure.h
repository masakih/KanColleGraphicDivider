//
//  SWFStructure.h
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2016/09/11.
//  Copyright © 2016年 Hori,Masaki. All rights reserved.
//

#ifndef SWFStructure_h
#define SWFStructure_h


#pragma pack(1)

typedef struct _HMSWFHeader {
    char type[3];
    char version;
    union {
        char fileSize[4];
        int f;
    } f;
} HMSWFHeader;

typedef struct _HMSWFTag {
    UInt16 tagAndLength;
    UInt32 extraLength;
} HMSWFTag;

typedef struct _HMSWFBitsJPEG3 {
    UInt16 charctorID;
    UInt32 imageSize;
    unsigned char imageData;
} HMSWFBitsJPEG3;
#define HMSWFJPEG3HeaderSize 6

#pragma pack()


#endif /* SWFStructure_h */
