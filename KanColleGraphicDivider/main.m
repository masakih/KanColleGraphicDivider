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

#include <getopt.h>

static NSString *sOutputDir = nil;
static NSString *sOriginalName = nil;

static NSArray *sCharactorIds = nil;

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


enum {
    tagBits = 6,
    tagJPEGTables = 8,  // not supported
    tagBitsJPEG2 = 21,  // not supported
    tagBitsJPEG3 = 35,
    tagBitsLossless = 20,  // not supported
    tagBitsLossless2 = 36,
    tagBitsJPEG4 = 90,  // not supported
    
};

const char *toolName;
const char *versionString = "1.0";

const char *toolNameStr(const char *argv0)
{
    return [[[NSString stringWithFormat:@"%s", argv0] lastPathComponent] fileSystemRepresentation];
}

static void usage(int exitVal, FILE *fp)
{
    fprintf(fp, "Usage: %s [OPTIONS] input-swf-file\n", toolName);
    
    fprintf(fp, "\n");
    fprintf(fp, "  -c charactorIDs, --charactorid=charactorIDs\n");
    fprintf(fp, "\tcomma separated target image charactor ids. ex) 17,19 \n");
    fprintf(fp, "\textract all images if not set.\n");
    fprintf(fp, "  -o output-directory, --output=output-directory\n");
    fprintf(fp, "\textracted images output to output-directory.\n");
    fprintf(fp, "  -v, --version\n");
    fprintf(fp, "\toutput version information and exit.\n");
    fprintf(fp, "  -h, --help\n");
    fprintf(fp, "\tdisplay this help and text.\n");
    
    exit(exitVal);
}
static void version()
{
    printf("KanColleGraphicDivider %s\n", versionString);
    exit(EXIT_SUCCESS);
}

bool skipCharactorID(UInt16 chractorid) {
    if(sCharactorIds.count == 0) return false;
    
    for(NSString *charID in sCharactorIds) {
        if(charID.integerValue == chractorid) return false;
    }
    return true;
}

void saveDataWithExtension(id data, NSString *extention, UInt16 charactorID) {
    NSString *path = [NSString stringWithFormat:@"%@-%d.%@", sOriginalName, charactorID, extention];
    path = [sOutputDir stringByAppendingPathComponent:path];
    NSURL *url = [NSURL fileURLWithPath:path];
    [data writeToURL:url atomically:YES];
}

void saveImageAsPNG(id image, UInt16 charactorID) {
    NSData *tiffData = [image TIFFRepresentation];
    if(!tiffData) {
        fprintf(stderr, "Can not create TIFF representation.\n");
        return;
    }
    
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:tiffData];
    NSData *imageData = [rep representationUsingType:NSPNGFileType
                                          properties:@{}];
    saveDataWithExtension(imageData, @"png", charactorID);
}

void storeImage(const unsigned char *p, UInt32 length, UInt16 charactorID) {
    printLog("####  TYPE IS PICTURE ####\n\n");
    
    printLog("CaractorID is %d\n", charactorID);
    if(skipCharactorID(charactorID)) return;
    
    if(length == 0) return;
    
    NSData *pic = [NSData dataWithBytes:p length:length];
    NSImage *pict = [[NSImage alloc] initWithData:pic];
    if(!pict) {
        fprintf(stderr, "Can not create image from data.\n");
        return;
    }
    
    saveDataWithExtension(pic, @"jpg", charactorID);
}

void storeBitsJPEG3(const unsigned char *p, UInt32 length) {
    printLog("####  TYPE IS PICTURE ####\n\n");
    if(length < HMSWFJPEG3HeaderSize) return;
    
    const HMSWFBitsJPEG3 *bitsJPEG3 = (HMSWFBitsJPEG3 *)p;
    
    UInt16 charactorID = bitsJPEG3->charctorID;
    printLog("CaractorID is %d\n", charactorID);
    if(skipCharactorID(charactorID)) return;
    
    UInt32 contentLength = length - HMSWFJPEG3HeaderSize;
    UInt32 imageSize = bitsJPEG3->imageSize;
    p = &bitsJPEG3->imageData;
    
    if(imageSize == contentLength) {
        storeImage(p, contentLength, charactorID);
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
    
    saveImageAsPNG(image, charactorID);
}

void storeBitLossless2ColorTable(const unsigned char *p, UInt32 length) {
    const HMSWFBitsLossless2 *data = (HMSWFBitsLossless2 *)p;
    
    UInt16 charactorID = data->charctorID;
    printLog("CaractorID is %d\n", charactorID);
    if(skipCharactorID(charactorID)) return;
    
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
    UInt32 *imageDataP = calloc(4, data->width * data->height);
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
    
    if(!imageRef) {
        fprintf(stderr, "Can not create ImageRef from maked bitmap.");
        return;
    }
    
    saveImageAsPNG(imageRef, charactorID);
}
void storeBitsLossless2(const unsigned char *p, UInt32 length) {
    printLog("####  TYPE IS PICTURE ####\n\n");
    if(length < HMSWFLossless2HeaderSize) {
        fprintf(stderr, "length is too short.\n");
        return;
    }
    
    const HMSWFBitsLossless2 *data = (HMSWFBitsLossless2 *)p;
    
    UInt16 charactorID = data->charctorID;
    printLog("CaractorID is %d\n", charactorID);
    if(skipCharactorID(charactorID)) return;
    
    if(data->bitmapFormat == 3) {
        storeBitLossless2ColorTable(p, length);
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
    saveImageAsPNG(imageRef, charactorID);
}

void extractImagesFromSWFFile(const char *filename) {
    
    NSString *filePath = [NSString stringWithFormat:@"%s", filename];
    if(![filePath hasPrefix:@"/"]) {
        NSFileManager *fm = [NSFileManager defaultManager];
        filePath = [fm.currentDirectoryPath stringByAppendingPathComponent:filePath];
    }
    
    NSURL *url = [NSURL fileURLWithPath:filePath];
    NSData *data = [NSData dataWithContentsOfURL:url];
    if(!data) {
        fprintf(stderr, "Can not open %s.\n", filename);
        return;
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
    
    if(header->type[0] != 'F' && header->type[0] != 'C') {
        fprintf(stderr, "File %s is not SWF.\n", filename);
        return;
    }
    if(header->type[1] != 'W' || header->type[2] != 'S') {
        fprintf(stderr, "File %s is not SWF.\n", filename);
        return;
    }
    
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
            case tagBits:
                @autoreleasepool {
                    storeImage(p + 2, length - 2, *(UInt16 *)p);
                }
                break;
            case tagBitsJPEG3:
                @autoreleasepool {
                    storeBitsJPEG3(p, length);
                }
                break;
            case tagBitsLossless2:
                @autoreleasepool {
                    storeBitsLossless2(p, length);
                }
                break;
            case tagBitsJPEG2:
            case tagBitsLossless:
            case tagBitsJPEG4:
            case tagJPEGTables:
                if(length > 0) {
                    fprintf(stderr, "Not supported type. (tag=%d)\n", tag);
                }
                break;
        }
        
        p += length;
        tagCount++;
        
        if(tagCount > 200) {
            return;
        }
    }
    
    printLog("tag Count -> %d\n", tagCount);
}

int main(int argc, char * const *argv) {
    @autoreleasepool {
        
        // 引数の処理
        int opt;
        char *oFilename = NULL;
        char *charactorid = NULL;
        
        toolName = toolNameStr(argv[0]);
        
#define SHORTOPTS "ho:vc:"
        static struct option longopts[] = {
            {"output",		required_argument,	NULL,	'o'},
            {"charactorid",		required_argument,	NULL,	'c'},
            {"version",		no_argument,		NULL,	'v'},
            {"help",		no_argument,		NULL,	'h'},
            {NULL, 0, NULL, 0}
        };
        
        while((opt = getopt_long(argc, argv, SHORTOPTS, longopts, NULL)) != -1) {
            switch(opt) {
                case 'o':
                    oFilename = optarg;
                    break;
                case 'c':
                    charactorid = optarg;
                    break;
                case 'h':
                    usage(EXIT_SUCCESS, stdout);
                    break;
                case 'v':
                    version();
                    break;
                default:
                    usage(EXIT_FAILURE, stderr);
                    break;
            }
        }
        
        if(optind >= argc) {
            usage(EXIT_FAILURE, stderr);
        }
        
        if(oFilename) {
            sOutputDir = [NSString stringWithFormat:@"%s", oFilename];
            NSFileManager *fm = [NSFileManager defaultManager];
            BOOL isDir = NO;
            if(![fm fileExistsAtPath:sOutputDir isDirectory:&isDir] || !isDir) {
                fprintf(stderr, "Output directory:%s is not found or not directory.", sOutputDir.fileSystemRepresentation);
                exit(EXIT_FAILURE);
            }
        } else {
            NSFileManager *fm = [NSFileManager defaultManager];
            sOutputDir = fm.currentDirectoryPath;
        }
        
        if(charactorid) {
            NSString *charactoridsString = [NSString stringWithFormat:@"%s", charactorid];
            NSArray *ids = [charactoridsString componentsSeparatedByString:@","];
            if(ids.count != 0) {
                sCharactorIds = ids;
                
                
                printLog("CaractorIDs is %s\n", [NSString stringWithFormat:@"%@", ids].fileSystemRepresentation);
            }
        }
        
        for(int filePos = optind; filePos < argc; filePos++) {
            const char *filename = argv[filePos];
            
            extractImagesFromSWFFile(filename);
        }
    }
    return 0;
}

