//
//  ImageStore.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/19.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#include "KanColleGraphicDivider.h"
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
    
    NSString *path = [NSString stringWithFormat:@"%@-%d.%@",
                      self.information.originalName, decoder.charactorID, decoder.extension];
    path = [self.information.outputDir stringByAppendingPathComponent:path];
    NSURL *url = [NSURL fileURLWithPath:path];
    
    [decoder.decodedData writeToURL:url atomically:YES];
}

@end
