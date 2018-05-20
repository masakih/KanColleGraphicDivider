//
//  ImageDecoder.h
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/19.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Information.h"

#import "WritableObject.h"


@protocol ImageDecoder <NSObject>

+ (id)decoderWithData:(NSData *)data;

- (void)decodeUsingInformationn:(Information *)information;

@property (readonly) UInt32 charactorID;

@property (nullable, readonly) id<WritableObject> object;

@end
