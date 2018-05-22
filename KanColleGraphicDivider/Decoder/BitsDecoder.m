//
//  BitsDecoder.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/20.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import "BitsDecoder.h"

@interface BitsDecoder()

@property NSData *data;

@property (readonly) NSUInteger length;

@end

@implementation BitsDecoder

+ (instancetype)decoderWithData:(NSData *)data {
    
    return [[self alloc] initWithData:data];
}

- (instancetype)initWithData:(NSData *)data {
    
    self = [super init];
    
    if( self ) {
        
        self.data = data;
    }
    
    return self;
}

- (NSUInteger)length {
    
    return self.data.length;
}

- (UInt32) charactorID {
    
    return *(UInt16 *)self.data.bytes;
}

- (NSData *)decodedData {
    
    NSData *contentData = [self.data subdataWithRange:NSMakeRange(2, self.length - 2)];
    if(contentData.length == 0) return nil;
    
    NSImage *pict = [[NSImage alloc] initWithData:contentData];
    if(!pict) {
        
        fprintf(stderr, "Can not create image from data.\n");
        return nil;
    }
    
    return contentData;
}

- (NSString *)extension {
    
    return @"jpg";
}

@end
