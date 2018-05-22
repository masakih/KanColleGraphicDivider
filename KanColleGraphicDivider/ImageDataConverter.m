//
//  ImageDataConverter.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/22.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import "ImageDataConverter.h"

NSData *convertToPNGImagaData(id<ImageConvertible> image) {
    
    NSData *tiffData = [image TIFFRepresentation];
    if(!tiffData) {
        fprintf(stderr, "Can not create TIFF representation.\n");
        return nil;
    }
    
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:tiffData];
    return [rep representationUsingType:NSPNGFileType
                             properties:@{}];
}
