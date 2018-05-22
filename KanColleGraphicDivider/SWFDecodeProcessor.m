//
//  SWFDecodeProcessor.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/22.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import "SWFDecodeProcessor.h"

#import "SwfData.h"
#import "ImageStore.h"

@interface SWFDecodeProcessor()

@property Information *information;

@end

@implementation SWFDecodeProcessor

+ (instancetype)swfDecodeProcessorWithInformation:(Information *)infotmation {
    
    return [[self alloc] initWithInformation:infotmation];
}

- (instancetype)initWithInformation:(Information *)information {
    
    self = [super init];
    if( self ) {
        
        self.information = information;
    }
    
    return self;
}

- (void)process {
    
    NSData *data = [NSData dataWithContentsOfURL:self.information.originalURL];
    if(!data) {
        fprintf(stderr, "Can not open %s.\n", self.information.filename.UTF8String);
        return;
    }
    
    SwfData *swf = [SwfData dataWithData:data];
    SwfContent *content = swf.firstContent;
    
    ImageStore *store = [ImageStore imageStoreWithInformation:self.information];
    
    while( content ) {
        
        SwfContent *aContent = content;
        content = aContent.next;
        
        [store store:content.decoder];
    }
}

@end
