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

#import "HMZlibData.h"

@interface BitsJPEG3Decoder()

@property Information *information;

@property const unsigned char *data;

@property UInt32 length;

@property UInt32 charactorID;

@end

@implementation BitsJPEG3Decoder

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
    
    return [self bitsJPEG3];
}

- (id<WritableObject>)bitsJPEG3 {
    
    const unsigned char *p = self.data;
    
    if(self.length < HMSWFJPEG3HeaderSize) return nil;
    
    const HMSWFBitsJPEG3 *bitsJPEG3 = (HMSWFBitsJPEG3 *)p;
    
    self.charactorID = bitsJPEG3->charctorID;
    if([self.information skipCharactorID:self.charactorID]) return nil;
    
    UInt32 contentLength = self.length - HMSWFJPEG3HeaderSize;
    UInt32 imageSize = bitsJPEG3->imageSize;
    p = &bitsJPEG3->imageData;
    
    if(imageSize == contentLength) {
        
        storeImage(self.information, p, self.length, self.charactorID);
        
        return nil;
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
    
    return image;
}

@end
