//
//  main.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2016/09/11.
//  Copyright © 2016年 Hori,Masaki. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include "KanColleGraphicDivider.h"
#include "SWFStructure.h"

#import "Information.h"

#import "HMZlibData.h"

#import "ImageStorer.h"

#include <getopt.h>

#import "ImageDecoder.h"
#import "BitsLossless2Decoder.h"
#import "BitLossless2ColorTableDecoder.h"
#import "BitsJPEG3Decoder.h"

void printLogF(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
}


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

void extractImagesFromSWFFile(Information *info) {
    NSString *filePath = info.filename;
    if(![filePath hasPrefix:@"/"]) {
        NSFileManager *fm = [NSFileManager defaultManager];
        filePath = [fm.currentDirectoryPath stringByAppendingPathComponent:filePath];
    }
    
    NSURL *url = [NSURL fileURLWithPath:filePath];
    NSData *data = [NSData dataWithContentsOfURL:url];
    if(!data) {
        fprintf(stderr, "Can not open %s.\n", info.filename.UTF8String);
        return;
    }
    
    info.originalName = [filePath lastPathComponent];
    info.originalName = [info.originalName stringByDeletingPathExtension];
    
    printHex(data.bytes);
    
    // ヘッダの処理開始
    const HMSWFHeader *header = data.bytes;
    printLog("type\t%c%c%c\n", header->type[0], header->type[1], header->type[2]);
    printLog("version\t%d\n", header->version);
    printLog("file size\t0x%x (%d)\n", header->f.f, header->f.f);
    data = [data subdataWithRange:NSMakeRange(8, data.length - 8)];
    printHex(data.bytes);
    
    if(header->type[0] != 'F' && header->type[0] != 'C') {
        fprintf(stderr, "File %s is not SWF.\n", info.filename.UTF8String);
        return;
    }
    if(header->type[1] != 'W' || header->type[2] != 'S') {
        fprintf(stderr, "File %s is not SWF.\n", info.filename.UTF8String);
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
                    storeImage(info, p + 2, length - 2, *(UInt16 *)p);
                }
                break;
            case tagBitsJPEG3:
                @autoreleasepool {
                     [[BitsJPEG3Decoder decoderWithInformation:info data:p length:length] decode];
                }
                break;
            case tagBitsLossless2:
                @autoreleasepool {
                    [[BitsLossless2Decoder decoderWithInformation:info data:p length:length] decode];
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
    
    NSString *outputDir = nil;
    NSArray *charactorIds = nil;
    
    @autoreleasepool {
        // 引数の処理
        int opt;
        char *oFilename = NULL;
        char *charactorid = NULL;
        
        toolName = toolNameStr(argv[0]);
        
#define SHORTOPTS "ho:vc:"
        static struct option longopts[] = {
            {"output",      required_argument,  NULL,   'o'},
            {"charactorid", required_argument,  NULL,   'c'},
            {"version",     no_argument,        NULL,   'v'},
            {"help",        no_argument,        NULL,   'h'},
            {NULL,          0,                  NULL,   0}
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
            outputDir = [[NSString alloc] initWithUTF8String:oFilename];
            if( outputDir.length == 0 ) {
                fprintf(stderr, "Output directory:%s can not convert file represendation.\n", oFilename);
                exit(EXIT_FAILURE);
            }
            NSFileManager *fm = [NSFileManager defaultManager];
            BOOL isDir = NO;
            if(![fm fileExistsAtPath:outputDir isDirectory:&isDir] || !isDir) {
                fprintf(stderr, "Output directory:%s is not found or not directory.\n", outputDir.UTF8String);
                exit(EXIT_FAILURE);
            }
        } else {
            NSFileManager *fm = [NSFileManager defaultManager];
            outputDir = fm.currentDirectoryPath;
        }
        
        if(charactorid) {
            NSString *charactoridsString = [[NSString alloc] initWithUTF8String:charactorid];
            NSArray *ids = [charactoridsString componentsSeparatedByString:@","];
            if(ids.count != 0) {
                charactorIds = ids;
                
                printLog("CaractorIDs is %s\n", [NSString stringWithFormat:@"%@", ids].fileSystemRepresentation);
            }
        }
                
        dispatch_group_t group = dispatch_group_create();
        dispatch_queue_t queue = dispatch_queue_create("Create image", DISPATCH_QUEUE_CONCURRENT);
        for(int filePos = optind; filePos < argc; filePos++) {
            const char *filename = argv[filePos];
            Information *info = [Information new];
            info.outputDir = outputDir;
            info.charctorIds = charactorIds;
            info.filename = [[NSString alloc] initWithUTF8String:filename];
            
            dispatch_group_async(group, queue, ^{
                extractImagesFromSWFFile(info);
            });
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    }
    return 0;
}

