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

@property NSData *data;

@property (readonly) NSUInteger length;

@end

@implementation BitsLossless2Decoder

+ (instancetype)decoderWithInformation:(Information *)information data:(NSData *)data {
    
    return [[self alloc] initWithInformation:information data:data];
}

- (instancetype)initWithInformation:(Information *)information data:(NSData *)data {
    
    self = [super init];
    
    if( self ) {
        
        self.information = information;
        self.data = data;
    }
    
    return self;
}

- (NSUInteger)length {
    
    return self.data.length;
}

- (void)decode {
    
    saveDataWithExtension(self.information, self.object, @"png", self.charactorID);
}

- (UInt32) charactorID {
    
    const HMSWFBitsLossless2 *data = (HMSWFBitsLossless2 *)self.data.bytes;
    
    return data->charctorID;
}

- (id<WritableObject>)object {
    
    return [self bitsLossless2];
}

- (id<WritableObject>)bitsLossless2 {
    
    const HMSWFBitsLossless2 *data = (HMSWFBitsLossless2 *)self.data.bytes;
        
    if(data->bitmapFormat == 3) {
        
        id decoder = [BitLossless2ColorTableDecoder decoderWithInformation:self.information
                                                                      data:self.data];
        return [decoder object];
    }
    
    NSUInteger cLength = self.length - HMSWFLossless2HeaderSize;
    
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
    
    return convertImagaData(imageRef);
}

@end
