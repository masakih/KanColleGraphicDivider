//
//  SWFDecodeProcessor.h
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/22.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Information.h"

@interface SWFDecodeProcessor : NSObject

+ (instancetype)swfDecodeProcessorWithInformation:(Information *)infotmation;

- (void)process;

@end
