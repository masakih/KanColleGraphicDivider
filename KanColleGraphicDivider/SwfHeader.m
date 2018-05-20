//
//  SwfHeader.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/20.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import "SwfHeader.h"

#import "HMZlibData.h"

typedef enum : NSUInteger {
    
    normalSWFType,
    zlibCompressedSWFType,
    LZMACompressedSWFType,
    
    unknownSWFType,
    
} SwfType;



@interface SwfHeader()

@property (nonnull) NSData *data;

@property (nullable, readwrite) NSData *next;

@end

@implementation SwfHeader

+ (nullable instancetype)headerWithData:(NSData *)data {
    
    return [[self alloc] initWithData:data];
}

- (nullable instancetype)initWithData:(NSData *)data {
    
    self = [super init];
    
    if( !data ) {
        
        return nil;
    }
    
    if( self ) {
        
        self.data = data;
    }
    
    return self;
}

- (BOOL)parse {
    
    SwfType type = typeOf(self.data);
    
    switch (type) {
            
        case normalSWFType:
        {
            NSData *subdata = [self.data subdataWithRange:NSMakeRange(8, self.data.length - 8)];
            self.data = subdata;
        }
            break;
            
        case zlibCompressedSWFType:
        {
            NSData *subdata = [self.data subdataWithRange:NSMakeRange(8, self.data.length - 8)];
            self.data = [subdata inflate];
        }
            break;
            
        case LZMACompressedSWFType:
        {
            NSData *subdata = [self.data subdataWithRange:NSMakeRange(8, self.data.length - 8)];
            self.data = [subdata inflate];
        }
            break;
            
        default:
            
            return NO;
    }
    
    const unsigned char *p = self.data.bytes;
    
    // RECT: 上位5bitsが各要素のサイズを表す 要素は4つ
    UInt8 size = *(UInt8 *)p;
    size >>= 3;
    int offset = size * 4;
    offset += 5; // 上位5bit分
    // bit -> byte
    int div = offset / 8;
    int mod = offset % 8;
    offset = div + (mod == 0 ? 0 : 1); // アライメント
    p += offset;
    
    // fps: 8.8 fixed number.
    p += 2;
    
    // frame count
    p += 2;
    
    UInt32 loc = offset + 2 + 2;
    
    self.next = [self.data subdataWithRange:NSMakeRange(loc, self.data.length - loc)];
    
    return YES;
}

SwfType typeOf(NSData *data) {
    
    NSString *signature = [[NSString alloc] initWithBytesNoCopy:data.bytes
                                                         length:3
                                                       encoding:NSUTF8StringEncoding
                                                freeWhenDone:YES];
    if( [signature isEqualToString:@"FWS"] ) {
        
        return normalSWFType;
    }
    if( [signature isEqualToString:@"CWS"] ) {
        
        return zlibCompressedSWFType;
    }
    if( [signature isEqualToString:@"ZWS"] ) {
        
        return LZMACompressedSWFType;
    }
    
    return kUnknownType;
}
@end
