//
//  SwfContent.h
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/20.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SwfContent : NSObject

+ (nullable instancetype)contentWithData:(NSData *)data;

@property NSRange nextRange;

@property (nullable, readonly) SwfContent *next;

@property (readonly) UInt32 charactorID;
@property (nullable, readonly) NSData *content;
@property (readonly) NSString *extension;

@end
