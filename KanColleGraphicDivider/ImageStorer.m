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

void saveDataWithExtension(Information *info, id<WritableObject> data, NSString *extention, UInt16 charactorID) {
    
    NSString *path = [NSString stringWithFormat:@"%@-%d.%@", info.originalName, charactorID, extention];
    path = [info.outputDir stringByAppendingPathComponent:path];
    NSURL *url = [NSURL fileURLWithPath:path];
    [data writeToURL:url atomically:YES];
}

id<WritableObject> convertImagaData(NSImage *image) {
    
    NSData *tiffData = [image TIFFRepresentation];
    if(!tiffData) {
        fprintf(stderr, "Can not create TIFF representation.\n");
        return nil;
    }
    
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:tiffData];
    return [rep representationUsingType:NSPNGFileType
                             properties:@{}];
}
