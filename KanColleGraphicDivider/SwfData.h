//
//  SwfData.h
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/20.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SwfHeader.h"
#import "SwfContent.h"

@interface SwfData : NSObject

+ (instancetype)dataWithData:(NSData *)data;

@property (nullable, readonly) SwfHeader *header;
@property (nullable, readonly) SwfContent *firstContent;

@end
