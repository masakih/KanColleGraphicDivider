//
//  BitsLossless2Decoder.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/19.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import "BitsLossless2Decoder.h"

#include "KanColleGraphicDivider.h"
#import "ImageStorer.h"

#import "HMZlibData.h"

#import "BitLossless2ColorTableDecoder.h"

@interface BitsLossless2Decoder()

@property Information *information;

@property const unsigned char *data;

@property UInt32 length;

@property UInt32 charactorID;

@end

@implementation BitsLossless2Decoder

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
    
    return [self bitsLossless2];
}

- (id<WritableObject>)bitsLossless2 {
    
    const HMSWFBitsLossless2 *data = (HMSWFBitsLossless2 *)self.data;
    
    self.charactorID = data->charctorID;
    if([self.information skipCharactorID:self.charactorID]) return nil;
    
    if(data->bitmapFormat == 3) {
        
        id decoder = [BitLossless2ColorTableDecoder decoderWithInformation:self.information
                                                                      data:self.data
                                                                    length:self.length];
        return [decoder object];
    }
    
    UInt32 cLength = self.length - HMSWFLossless2HeaderSize;
    
    const unsigned char *p = &data->data.data;
    NSData *zipedImageData = [NSData dataWithBytes:p length:cLength];
    NSData *imageData = [zipedImageData inflate];
    unsigned char *pp = (unsigned char *)imageData.bytes;
    NSBitmapImageRep *imageRef = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pp
                                                                         pixelsWide:data->width
                                                                         pixelsHigh:data->height
                                                                      bitsPerSample:8 * 4
                                                                    samplesPerPixel:4
                                                                           hasAlpha:YES
                                                                           isPlanar:NO
                                                                     colorSpaceName:NSCalibratedRGBColorSpace
                                                                        bytesPerRow:data->width * 4
                                                                       bitsPerPixel:0];
    
    return imageRef;
}

@end
