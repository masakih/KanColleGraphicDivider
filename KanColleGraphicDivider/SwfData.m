//
//  SwfData.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/20.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import "SwfData.h"

@interface SwfData()

@property (nullable, readwrite) SwfHeader *header;
@property (nullable, readwrite) SwfContent *firstContent;

@end

@implementation SwfData

+ (instancetype)dataWithData:(NSData *)data {
    
    return [[self alloc] initWithData:data];
}

- (instancetype)initWithData:(NSData *)data {
    
    self = [super init];
    if( self ) {
        
        self.header = [SwfHeader headerWithData:data];
        self.firstContent = [SwfContent contentWithData:self.header.next];
    }
    
    return self;
}

@end
