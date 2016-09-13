//
//  HMZlibData.h
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2016/09/11.
//  Copyright © 2016年 Hori,Masaki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (HMZlibData)

- (NSData *)deflate:(int)compressionLevel;
- (NSData *)inflate;

@end
