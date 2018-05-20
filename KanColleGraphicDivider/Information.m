//
//  Information.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/19.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import "Information.h"

@implementation Information
- (bool)skipCharactorID:(UInt16) chractorid {
    if(self.charctorIds.count == 0) return false;
    
    for(NSString *charID in self.charctorIds) {
        if(charID.integerValue == chractorid) return false;
    }
    return true;
}
@end
