//
//  Information.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/19.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import "Information.h"


@interface Information()

@property (copy, readwrite) NSURL *originalURL;

@property (copy, readwrite) NSString *originalName;

@end

@implementation Information

@synthesize filename = _filename;

- (BOOL)skipCharactorID:(UInt16) chractorid {
    
    if(self.charctorIds.count == 0) return false;
    
    for(NSString *charID in self.charctorIds) {
        
        if(charID.integerValue == chractorid) return false;
    }
    return true;
}

- (void)setFilename:(NSString *)filename {
    
    _filename = [filename copy];
    
    NSString *filePath = [filename copy];
    
    if(![filePath hasPrefix:@"/"]) {
        
        NSFileManager *fm = [NSFileManager defaultManager];
        filePath = [fm.currentDirectoryPath stringByAppendingPathComponent:filePath];
    }
    
    self.originalURL = [NSURL fileURLWithPath:filePath];
    
    NSString *oName = [filename lastPathComponent];
    self.originalName = [oName stringByDeletingPathExtension];
}

- (NSString *)filename {
    
    return _filename;
}
@end
