//
//  BitsLossless2Decoder.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/19.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import "BitsLossless2Decoder.h"

#include "KanColleGraphicDivider.h"
#import "ImageDataConverter.h"

#import "HMZlibData.h"

#import "BitLossless2ColorTableDecoder.h"

@interface BitsLossless2Decoder()

@property NSData *data;

@property (readonly) NSUInteger length;

@end

@implementation BitsLossless2Decoder

+ (instancetype)decoderWithData:(NSData *)data {
    
    return [[self alloc] initWithData:data];
}

- (instancetype)initWithData:(NSData *)data {
    
    self = [super init];
    
    if( self ) {
        
        self.data = data;
    }
    
    return self;
}

- (NSUInteger)length {
    
    return self.data.length;
}

- (UInt32) charactorID {
    
    const HMSWFBitsLossless2 *data = (HMSWFBitsLossless2 *)self.data.bytes;
    
    return data->charctorID;
}

- (NSData *)decodedData {
    
    const HMSWFBitsLossless2 *data = (HMSWFBitsLossless2 *)self.data.bytes;
    
    if(data->bitmapFormat == 3) {
        
        id decoder = [BitLossless2ColorTableDecoder decoderWithData:self.data];
        return [decoder decodedData];
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
    
    return convertToPNGImagaData(imageRef);
}

- (NSString *)extension {
    
    return @"png";
}

@end
