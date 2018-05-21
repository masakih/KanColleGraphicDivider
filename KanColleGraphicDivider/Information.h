//
//  Information.h
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/19.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Information: NSObject
@property (copy) NSString *originalName;
@property (copy) NSString *outputDir;
@property (copy) NSString *filename;
@property (copy) NSArray *charctorIds;

- (bool)skipCharactorID:(UInt16) chractorid;

@end
