//
//  BitsJPEG3Decoder.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/19.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import "BitsJPEG3Decoder.h"

#include "KanColleGraphicDivider.h"
#import "ImageStorer.h"

#import "BitsDecoder.h"

#import "HMZlibData.h"

@interface BitsJPEG3Decoder()

@property NSData *data;

@property (readonly) NSUInteger length;

@end

@implementation BitsJPEG3Decoder

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

- (void)decodeUsingInformationn:(Information *)information {
    
    saveDataWithExtension(information, self.object, @"png", self.charactorID);
}

- (UInt32) charactorID {
    
    const HMSWFBitsJPEG3 *data = (HMSWFBitsJPEG3 *)self.data.bytes;
    
    return data->charctorID;
}

- (id<WritableObject>)object {
    
    return [self bitsJPEG3];
}

- (id<WritableObject>)bitsJPEG3 {
    
    const unsigned char *p = self.data.bytes;
    
    if(self.length < HMSWFJPEG3HeaderSize) return nil;
    
    const HMSWFBitsJPEG3 *bitsJPEG3 = (HMSWFBitsJPEG3 *)p;
    
    NSUInteger contentLength = self.length - HMSWFJPEG3HeaderSize;
    NSUInteger imageSize = bitsJPEG3->imageSize;
    p = &bitsJPEG3->imageData;
    
    if(imageSize == contentLength) {
        
        return [[BitsDecoder decoderWithData:self.data] object];
    }
    
    // JPEGを取出し
    NSData *pic = [NSData dataWithBytes:p length:imageSize];
    NSImage *pict = [[NSImage alloc] initWithData:pic];
    if(!pict) {
        fprintf(stderr, "Can not create image from data.\n");
        return nil;
    }
    
    NSSize size = pict.size;
    
    // アルファチャンネルの取出し
    NSData *alpha = [NSData dataWithBytes:p + imageSize length:contentLength - imageSize];
    alpha = [alpha inflate];
    
    unsigned char *pp = (unsigned char *)alpha.bytes;
    NSBitmapImageRep *alphaImageRef = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pp
                                                                              pixelsWide:size.width
                                                                              pixelsHigh:size.height
                                                                           bitsPerSample:8
                                                                         samplesPerPixel:1
                                                                                hasAlpha:NO
                                                                                isPlanar:NO
                                                                          colorSpaceName:NSDeviceWhiteColorSpace
                                                                             bytesPerRow:size.width
                                                                            bitsPerPixel:0];
    if(!alphaImageRef) {
        fprintf(stderr, "Can not create alpha image from data.\n");
        return nil;
    }
    
    // 透過画像の作成
    NSImage *image = [NSImage imageWithSize:size
                                    flipped:NO
                             drawingHandler:
                      ^BOOL(NSRect dstRect) {
                          NSRect rect = NSMakeRect(0, 0, size.width, size.height);
                          
                          CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
                          CGContextSaveGState(context);
                          CGContextClipToMask(context, NSRectToCGRect(rect), alphaImageRef.CGImage);
                          [pict drawAtPoint:NSZeroPoint
                                   fromRect:rect
                                  operation:NSCompositeCopy
                                   fraction:1.0];
                          CGContextRestoreGState(context);
                          
                          return YES;
                      }];
    
    return convertImagaData(image);
}

@end
