//
//  BitsDecoder.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/20.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import "BitsDecoder.h"

#import "ImageStorer.h"

@interface BitsDecoder()

@property Information *information;

@property NSData *data;

@property (readonly) NSUInteger length;

@end

@implementation BitsDecoder

+ (instancetype)decoderWithInformation:(Information *)information data:(NSData *)data {
    
    return [[self alloc] initWithInformation:information data:data];
}

- (instancetype)initWithInformation:(Information *)information data:(NSData *)data {
    
    self = [super init];
    
    if( self ) {
        
        self.information = information;
        self.data = data;
    }
    
    return self;
}

- (NSUInteger)length {
    
    return self.data.length;
}

- (void)decode {
    
    saveDataWithExtension(self.information, self.object, @"jpg", self.charactorID);
}

- (UInt32) charactorID {
    
    return *(UInt16 *)self.data.bytes;
}

- (id<WritableObject>)object {
    
    NSData *contentData = [self.data subdataWithRange:NSMakeRange(2, self.length - 2)];
    if(contentData.length == 0) return nil;
    
    NSImage *pict = [[NSImage alloc] initWithData:contentData];
    if(!pict) {
        fprintf(stderr, "Can not create image from data.\n");
        return nil;
    }
    
    return contentData;
}

@end
