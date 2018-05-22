//
//  SwfHeader.h
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/20.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SwfHeader : NSObject

+ (nullable instancetype)headerWithData:(NSData *)data;

@property (nullable, readonly) NSData *next;

@end
