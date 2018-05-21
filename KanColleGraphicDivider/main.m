//
//  main.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2016/09/11.
//  Copyright © 2016年 Hori,Masaki. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include <getopt.h>

#include "KanColleGraphicDivider.h"

#import "Information.h"
#import "ImageStorer.h"

#import "SwfData.h"

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
    
    SwfData *swf = [SwfData dataWithData:data];
    SwfContent *content = swf.firstContent;
    
    while( content ) {
        
        SwfContent *aContent = content;
        content = aContent.next;
        
        NSData *data = aContent.content;
        if( !data ) {
            
            continue;
        }
        
        if( [info skipCharactorID:aContent.charactorID] ) {
            
            continue;
        }
        
        saveDataWithExtension(info, data, aContent.extension, aContent.charactorID);
    }
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

