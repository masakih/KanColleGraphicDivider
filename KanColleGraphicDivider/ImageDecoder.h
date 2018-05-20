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

+ (id)decoderWithInformation:(Information *)information data:(const unsigned char *)data length:(UInt32)length;

- (void)decode;

- (id<WritableObject>)object;

@end
