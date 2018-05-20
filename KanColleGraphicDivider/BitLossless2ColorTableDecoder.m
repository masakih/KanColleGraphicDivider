//
//  BitLossless2ColorTableDecoder.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/19.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import "BitLossless2ColorTableDecoder.h"

#include "KanColleGraphicDivider.h"
#import "ImageStorer.h"

#import "HMZlibData.h"

@interface BitLossless2ColorTableDecoder()

@property Information *information;

@property const unsigned char *data;

@property UInt32 length;

@property UInt32 charactorID;

@end

@implementation BitLossless2ColorTableDecoder

+ (instancetype)decoderWithInformation:(Information *)information data:(const unsigned char *)data length:(UInt32)length {
    
    return [[self alloc] initWithInformation:information data:data length:length];
}

- (instancetype)initWithInformation:(Information *)information data:(const unsigned char *)data length:(UInt32)length {
    
    self = [super init];
    
    if( self ) {
        
        self.information = information;
        self.data = data;
        self.length = length;
    }
    
    return self;
}

- (void)decode {
    
    saveImageAsPNG(self.information, self.object, self.charactorID);
}

- (id<WritableObject>)object {
    
    return [self bitLossless2ColorTable];
}

- (id<WritableObject>)bitLossless2ColorTable {
    
    
    const HMSWFBitsLossless2 *data = (HMSWFBitsLossless2 *)self.data;
    
    self.charactorID = data->charctorID;
    if([self.information skipCharactorID:self.charactorID]) return nil;
    
    UInt8 mapSize = data->data.colorTable.colorTableSize + 1;
    
    NSData *zipedContentData = [NSData dataWithBytes:&data->data.colorTable.data length:self.length - HMSWFLossless2ColorTableHeaderSize];
    NSData *contentData = [zipedContentData inflate];
    
    const UInt32 *mapP = (UInt32 *)contentData.bytes;
    const UInt8 *colorIndexP = (UInt8 *)(mapP + mapSize);
    
    // rowサイズは4bytesアライメント
    UInt8 skipBytes = data->width % 4;
    
    // ARBGカラーマップからARBGビットマップを作成
    UInt32 *imageDataP = calloc(4, data->width * data->height);
    if(!imageDataP) {
        fprintf(stderr, "Can not allocate enough memory.\n");
        return nil;
    }
    
    UInt32 *imageDataPixel = imageDataP;
    for(UInt16 h = 0; h < data->height; h++) {
        for(UInt16 w = 0; w < data->width; w++) {
            *imageDataPixel++ = mapP[*colorIndexP++];
        }
        colorIndexP += skipBytes;
    }
    
    // ARGBビットマップからNSBitmapImageRepを作成
    NSData *imageData = [NSData dataWithBytes:imageDataP length:4 * data->width * data->height];
    unsigned char *pp = (unsigned char *)imageData.bytes;
    NSBitmapImageRep *imageRef = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pp
                                                                         pixelsWide:data->width
                                                                         pixelsHigh:data->height
                                                                      bitsPerSample:8
                                                                    samplesPerPixel:4
                                                                           hasAlpha:YES
                                                                           isPlanar:NO
                                                                     colorSpaceName:NSCalibratedRGBColorSpace
                                                                        bytesPerRow:data->width * 4
                                                                       bitsPerPixel:0];
    free(imageDataP);
    imageDataP = NULL;
    
    return imageRef;
}

@end
