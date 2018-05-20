//
//  ImageStorer.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/19.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#include "KanColleGraphicDivider.h"
#import "ImageStorer.h"

#import "HMZlibData.h"

void saveDataWithExtension(Information *info, id data, NSString *extention, UInt16 charactorID) {
    NSString *path = [NSString stringWithFormat:@"%@-%d.%@", info.originalName, charactorID, extention];
    path = [info.outputDir stringByAppendingPathComponent:path];
    NSURL *url = [NSURL fileURLWithPath:path];
    [data writeToURL:url atomically:YES];
}

void saveImageAsPNG(Information *info, id image, UInt16 charactorID) {
    NSData *tiffData = [image TIFFRepresentation];
    if(!tiffData) {
        fprintf(stderr, "Can not create TIFF representation.\n");
        return;
    }
    
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:tiffData];
    NSData *imageData = [rep representationUsingType:NSPNGFileType
                                          properties:@{}];
    saveDataWithExtension(info, imageData, @"png", charactorID);
}

void storeImage(Information *info, const unsigned char *p, UInt32 length, UInt16 charactorID) {
    printLog("####  TYPE IS PICTURE ####\n\n");
    
    printLog("CaractorID is %d\n", charactorID);
    if([info skipCharactorID:charactorID]) return;
    
    if(length == 0) return;
    
    NSData *pic = [NSData dataWithBytes:p length:length];
    NSImage *pict = [[NSImage alloc] initWithData:pic];
    if(!pict) {
        fprintf(stderr, "Can not create image from data.\n");
        return;
    }
    
    saveDataWithExtension(info, pic, @"jpg", charactorID);
}
