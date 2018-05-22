//
//  ImageDataConverter.h
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/22.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ImageConvertible

- (NSData *)TIFFRepresentation;

@end

@interface NSBitmapImageRep(ImageConvertible) <ImageConvertible>
@end

@interface NSImage(ImageConvertible) <ImageConvertible>
@end

NSData *convertToPNGImagaData(id<ImageConvertible> data);
