//
//  main.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2016/09/11.
//  Copyright © 2016年 Hori,Masaki. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "SWFStructure.h"
#import "HMZlibData.h"

static NSString *sCurrentDir = nil;
static NSString *originalName = nil;

void printLog(const char *fmt, ...) {
#if 0
    va_list ap;
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
#endif
}

void printHex(const unsigned char *p) {
    for(int i=0;i<1;i++) {
        for(int j=0;j<16;j++) {
            printLog("%02x ", *p++);
        }
        printLog("\n");
    }
}

void storeImage(const unsigned char *p, UInt32 length, int tagCount) {
    printLog("####  TYPE IS PICTURE ####\n\n");
    if(length == 0) return;
    
    NSData *pic = [NSData dataWithBytes:p length:length];
    NSImage *pict = [[NSImage alloc] initWithData:pic];
    if(!pict) {
        fprintf(stderr, "Can not create image from data.\n");
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"%@-%d.jpg", originalName, tagCount];
    path = [sCurrentDir stringByAppendingPathComponent:path];
    NSURL *url = [NSURL fileURLWithPath:path];
    [pic writeToURL:url atomically:YES];
}

void storeDefineBitsJPEG3(const unsigned char *p, UInt32 length, int tagCount) {
    printLog("####  TYPE IS PICTURE ####\n\n");
    if(length < HMSWFJPEG3HeaderSize) return;
    
    const HMSWFBitsJPEG3 *bitsJPEG3 = (HMSWFBitsJPEG3 *)p;
    
    UInt32 contentLength = length - HMSWFJPEG3HeaderSize;
    UInt32 imageSize = bitsJPEG3->imageSize;
    p = &bitsJPEG3->imageData;
    
    if(imageSize == contentLength) {
        storeImage(p, contentLength, tagCount);
        return;
    }
    
    // JPEGを取出し
    NSData *pic = [NSData dataWithBytes:p length:imageSize];
    NSImage *pict = [[NSImage alloc] initWithData:pic];
    if(!pict) {
        fprintf(stderr, "Can not create image from data.\n");
        return;
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
        return;
    }
    
    // 透過画像の作成
    NSImage *image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    {
        NSRect rect = NSMakeRect(0, 0, size.width, size.height);
        
        CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
        CGContextSaveGState(context);
        CGContextClipToMask(context, NSRectToCGRect(rect), alphaImageRef.CGImage);
        [pict drawAtPoint:NSZeroPoint
                 fromRect:rect
                operation:NSCompositeCopy
                 fraction:1.0];
        
        CGContextRestoreGState(context);
    }
    [image unlockFocus];
    
    // PNGで保存
    NSData *tiffData = image.TIFFRepresentation;
    if(!tiffData) {
        fprintf(stderr, "Can not create masked image.\n");
        return;
    }
    
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:tiffData];
    NSData *imageData = [rep representationUsingType:NSPNGFileType
                                  properties:@{}];
    NSString *path = [NSString stringWithFormat:@"%@-%d.png", originalName, tagCount];
    path = [sCurrentDir stringByAppendingPathComponent:path];
    NSURL *url = [NSURL fileURLWithPath:path];
    [imageData writeToURL:url atomically:YES];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSProcessInfo *pInfo = [NSProcessInfo processInfo];
        NSArray<NSString *> *args = pInfo.arguments;
        if(args.count < 2) {
            fprintf(stderr, "Few argument\n");
            exit(-1);
        }
        
        NSFileManager *fm = [NSFileManager defaultManager];
        sCurrentDir = fm.currentDirectoryPath;
        
        NSString *filePath = args[1];
        if(![filePath hasPrefix:@"/"]) {
            filePath = [sCurrentDir stringByAppendingPathComponent:filePath];
        }
        
        NSURL *url = [NSURL fileURLWithPath:filePath];
        NSData *data = [NSData dataWithContentsOfURL:url];
        if(!data) {
            fprintf(stderr, "Can not open %s.\n", args[1].UTF8String);
            exit(-1);
        }
        
        originalName = [filePath lastPathComponent];
        originalName = [originalName stringByDeletingPathExtension];
        
        printHex(data.bytes);
        
        // ヘッダの処理開始
        const HMSWFHeader *header = data.bytes;
        printLog("type\t%c%c%c\n", header->type[0], header->type[1], header->type[2]);
        printLog("version\t%d\n", header->version);
        printLog("file size\t0x%x (%d)\n", header->f.f, header->f.f);
        data = [data subdataWithRange:NSMakeRange(8, data.length - 8)];
        printHex(data.bytes);
        
        // シグニチャがCの時はコンテントはzlibで圧縮されている
        if(header->type[0] == 'C') {
            data = [data inflate];
            printHex(data.bytes);
        }
        
        const unsigned char *p = data.bytes;
        
        // RECT: 上位5bitsが各要素のサイズを表す 要素は4つ
        UInt8 size = *(UInt8 *)p;
        size >>= 3;
        printLog("size -> %u (%x)\n", size,  size);
        int offset = size * 4;
        offset += 5; // 上位5bit分
        int div = offset / 8;
        int mod = offset % 8;
        offset = div + (mod == 0 ? 0 : 1); // アライメント
        printLog("offset -> %d\n", offset);
        p += offset;
        
        // fps: 8.8 fixed number.
        UInt8 fpsE = *(UInt8 *)p;
        p += 1;
        UInt8 fps = *(UInt8 *)p;
        p += 1;
        printLog("fps -> %u.%u\n", fps, fpsE);
        
        // frame count
        UInt16 frameCount = *(UInt16 *)p;
        printLog("frame count -> %u\n", frameCount);
        p += 2;
        
        // タグの処理開始
        int tagCount = 0;
        while(1) {
            printHex(p);
            
            HMSWFTag *tagP = (HMSWFTag *)p;
            p += 2;
            printLog("tag and length -> 0x%04x\n", tagP->tagAndLength);
            UInt32 tag = tagP->tagAndLength >> 6;
            UInt32 length = tagP->tagAndLength & 0x3F;
            if(length == 0x3F) {
                length = tagP->extraLength;
                p += 4;
            }
            printLog("tag -> %u\nlength -> %u\n", tag, length);
            
            // tag == 0 終了タグ
            if(tag == 0) break;
            
            // 画像の時の処理
            switch(tag) {
                case 6:
                    @autoreleasepool {
                       storeImage(p + 2, length - 2, tagCount);
                    }
                    break;
                case 35:
                    @autoreleasepool {
                        storeDefineBitsJPEG3(p, length, tagCount);
                    }
                    break;
                case 8:
                case 21:
                case 20:
                case 36:
                case 90:
                    @autoreleasepool {
                        storeImage(p, length, tagCount);
                    }
                    break;
            }
            
            p += length;
            tagCount++;
            
            if(tagCount > 200) {
                exit(-1);
            }
        }
        
        printLog("tag Count -> %d\n", tagCount);
        
    }
    return 0;
}

