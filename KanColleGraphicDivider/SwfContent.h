//
//  SwfContent.h
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/20.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WritableObject.h"

@interface SwfContent : NSObject

+ (nullable instancetype)contentWithData:(NSData *)data;

@property (nullable, readonly) SwfContent *next;

@property (readonly) UInt32 charactorID;
@property (nullable, readonly) id<WritableObject> content;

@end
