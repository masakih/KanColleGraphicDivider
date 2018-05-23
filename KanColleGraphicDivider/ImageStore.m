//
//  ImageStore.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/19.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import "ImageStore.h"

@interface ImageStore()

@property Information *information;

@end

@implementation ImageStore

+ (instancetype)imageStoreWithInformation:(Information *)information {
    
    return [[self alloc] initWithInformation:information];
}

- (instancetype)initWithInformation:(Information *)information {
    
    self = [super init];
    if( self ) {
        
        self.information = information;
    }
    
    return self;
}

- (void)store:(id<ImageDecoder>)decoder {
    
    if( [self.information skipCharactorID:decoder.charactorID] ) {
        
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"%@-%d.%@",
                      self.information.originalName, decoder.charactorID, decoder.extension];
    path = [self.information.outputDir stringByAppendingPathComponent:path];
    NSURL *url = [NSURL fileURLWithPath:path];
    
    if( !self.information.forceOverWrite && [url checkResourceIsReachableAndReturnError:nil] ) {
        
        fprintf(stderr, "%s is already exist.\n", url.path.UTF8String);
        
        return;
    }
    
    [decoder.decodedData writeToURL:url atomically:YES];
}

@end
