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
static NSString *sOriginalName = nil;

#if 0
#define printLog(...) printLogF( __VA_ARGS__)
void printLogF(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
}
#else
#define printLog(...)
#endif

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
    
    NSString *path = [NSString stringWithFormat:@"%@-%d.jpg", sOriginalName, tagCount];
    path = [sCurrentDir stringByAppendingPathComponent:path];
    NSURL *url = [NSURL fileURLWithPath:path];
    [pic writeToURL:url atomically:YES];
}

void storeBitsJPEG3(const unsigned char *p, UInt32 length, int tagCount) {
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
    NSString *path = [NSString stringWithFormat:@"%@-%d.png", sOriginalName, tagCount];
    path = [sCurrentDir stringByAppendingPathComponent:path];
    NSURL *url = [NSURL fileURLWithPath:path];
    [imageData writeToURL:url atomically:YES];
}

void storeBitLossless2ColorTable(const unsigned char *p, UInt32 length, int tagCount) {
    const HMSWFBitsLossless2 *data = (HMSWFBitsLossless2 *)p;
    
    UInt8 mapSize = data->data.colorTable.colorTableSize + 1;
    printLog("color table size -> %d\n", mapSize);
    printLog("zipped image data size -> %d\n", length - HMSWFLossless2ColorTableHeaderSize);
    
    NSData *zipedContentData = [NSData dataWithBytes:&data->data.colorTable.data length:length - HMSWFLossless2ColorTableHeaderSize];
    NSData *contentData = [zipedContentData inflate];
    printLog("unzipped image data size -> %d\n", contentData.length);
    
    const UInt32 *mapP = (UInt32 *)contentData.bytes;
    const UInt8 *colorIndexP = (UInt8 *)(mapP + mapSize);
    
#if 0
    printLog("MAP TABLE\n");
    for(int i = 0; i < mapSize; i++) {
        printLog("0x%04x ", mapP[i]);
    }
    printLog("\n\n");
#endif
    
    // rowサイズは4bytesアライメント
    UInt8 skipBytes = data->width % 4;
    
    // ARBGカラーマップからARBGビットマップを作成
    UInt32 *imageDataP = calloc(8 * 4, data->width * data->height);
    if(!imageDataP) {
        fprintf(stderr, "Can not allocate enough memory.\n");
        return;
    }
    
    UInt32 *imageDataPixel = imageDataP;
    for(UInt16 h = 0; h < data->height; h++) {
        for(UInt16 w = 0; w < data->width; w++) {
            printLog("%d ", *colorIndexP);
            *imageDataPixel++ = mapP[*colorIndexP++];
        }
        colorIndexP += skipBytes;
        printLog("\n");
    }
    
    // ARGBビットマップからNSBitmapImageRepを作成
    NSData *imageData = [NSData dataWithBytes:imageDataP length:8 * 4 * data->width * data->height];
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
    
    // PNGで保存
    NSData *tiffData = imageRef.TIFFRepresentation;
    if(!tiffData) {
        fprintf(stderr, "Can not create tiff image.\n");
        return;
    }
    
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:tiffData];
    NSData *pndData = [rep representationUsingType:NSPNGFileType
                                        properties:@{}];
    NSString *path = [NSString stringWithFormat:@"%@-%d.png", sOriginalName, tagCount];
    path = [sCurrentDir stringByAppendingPathComponent:path];
    NSURL *url = [NSURL fileURLWithPath:path];
    [pndData writeToURL:url atomically:YES];
}
void storeBitsLossless2(const unsigned char *p, UInt32 length, int tagCount) {
    printLog("####  TYPE IS PICTURE ####\n\n");
    if(length < HMSWFLossless2HeaderSize) {
        fprintf(stderr, "length is too short.\n");
        return;
    }
    
    const HMSWFBitsLossless2 *data = (HMSWFBitsLossless2 *)p;
    
    if(data->bitmapFormat == 3) {
        storeBitLossless2ColorTable(p, length, tagCount);
        return;
    }
    
    length -= HMSWFLossless2HeaderSize;
    
    p = &data->data.data;
    NSData *zipedImageData = [NSData dataWithBytes:p length:length];
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
    // PNGで保存
    NSData *tiffData = imageRef.TIFFRepresentation;
    if(!tiffData) {
        fprintf(stderr, "Can not create tiff image.\n");
        return;
    }
    
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:tiffData];
    NSData *pndData = [rep representationUsingType:NSPNGFileType
                                        properties:@{}];
    NSString *path = [NSString stringWithFormat:@"%@-%d.png", sOriginalName, tagCount];
    path = [sCurrentDir stringByAppendingPathComponent:path];
    NSURL *url = [NSURL fileURLWithPath:path];
    [pndData writeToURL:url atomically:YES];
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
        
        sOriginalName = [filePath lastPathComponent];
        sOriginalName = [sOriginalName stringByDeletingPathExtension];
        
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
        // bit -> byte
        int div = offset / 8;
        int mod = offset % 8;
        offset = div + (mod == 0 ? 0 : 1); // アライメント
        printLog("offset -> %d\n", offset);
        p += offset;
        
        // fps: 8.8 fixed number.
        printLog("fps -> %u.%u\n", *(UInt8 *)(p + 1), *(UInt8 *)p);
        p += 2;
        
        // frame count
        printLog("frame count -> %u\n", *(UInt16 *)p);
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
                        storeBitsJPEG3(p, length, tagCount);
                    }
                    break;
                case 36:
                    @autoreleasepool {
                        storeBitsLossless2(p, length, tagCount);
                    }
                    break;
                case 8:
                case 21:
                case 20:
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

