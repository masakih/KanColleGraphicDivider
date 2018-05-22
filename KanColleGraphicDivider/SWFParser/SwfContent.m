//
//  SwfContent.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/20.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import "SwfContent.h"

#import "BitsDecoder.h"
#import "BitsLossless2Decoder.h"
#import "BitsJPEG3Decoder.h"

#include "SWFStructure.h"

typedef enum : NSUInteger {
    tagBits = 6,
    tagJPEGTables = 8,  // not supported
    tagBitsJPEG2 = 21,  // not supported
    tagBitsJPEG3 = 35,
    tagBitsLossless = 20,  // not supported
    tagBitsLossless2 = 36,
    tagBitsJPEG4 = 90,  // not supported
} TagType;

@interface SwfContent()

@property (nonnull) NSData *data;

@property NSRange nextRange;

@property TagType tagType;
@property (nullable) NSData *contentData;
@property (nullable, readwrite) id<ImageDecoder> decoder;

@end

@implementation SwfContent

+ (nullable instancetype)contentWithData:(NSData *)data {
    
    return [[self alloc] initWithData:data];
    
}

- (nullable instancetype)initWithData:(NSData *)data {
    
    self = [super init];
    
    if( !data ) {
        
        NSLog(@"SwfContent: Data is nil");
        
        return nil;
    }
    
    if( self ) {
        
        self.data = data;
        self.nextRange = NSMakeRange(NSNotFound, 0);
        
        if( ![self parse] ) {
            
            NSLog(@"SwfContent: Parse Error");
            
            return nil;
        }
    }
    
    return self;
}

- (SwfContent *)next {
    
    if( self.nextRange.location == NSNotFound ) {
        
        return nil;
    }
    
    if( self.data.length < NSMaxRange(self.nextRange) ) {
        
        NSLog(@"Next size is Overflow");
        exit(-10);
    }
    
    return [SwfContent contentWithData:[self.data subdataWithRange:self.nextRange]];
}

- (BOOL)parse {
        
    HMSWFTag *tagP = (HMSWFTag *)self.data.bytes;
    NSUInteger tagLength = 2;
    self.tagType = tagP->tagAndLength >> 6;
    UInt32 contentLength = tagP->tagAndLength & 0x3F;
    if(contentLength == 0x3F) {
        contentLength = tagP->extraLength;
        tagLength += 4;
    }
    
    if( self.tagType == 0 ) {
        
        return YES;
    }
    
    if( self.data.length < (tagLength + contentLength) ) {
        
        NSLog(@"Content size is Overflow");
        exit(-10);
    }
    self.contentData = [self.data subdataWithRange:NSMakeRange(tagLength, contentLength)];
    
    NSUInteger nextPos = tagLength + contentLength;
    NSUInteger length = self.data.length - nextPos;
    self.nextRange = NSMakeRange(nextPos, length);
    
    switch (self.tagType) {
            
        case tagBits:
            
            self.decoder = [BitsDecoder decoderWithData:self.contentData];
            break;
            
        case tagBitsJPEG3:
            
            self.decoder = [BitsJPEG3Decoder decoderWithData:self.contentData];
            break;
            
        case tagBitsLossless2:
            
            self.decoder = [BitsLossless2Decoder decoderWithData:self.contentData];
            break;
            
        default:
            
            break;
    }
    
    return YES;
}

@end
