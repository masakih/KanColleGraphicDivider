//
//  SwfContent.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/20.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import "SwfContent.h"

#import "BitsLossless2Decoder.h"
#import "BitLossless2ColorTableDecoder.h"
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

@property (nullable, readwrite) SwfContent *next;

@property TagType tagType;
@property (readwrite) UInt32 charactorID;
@property (nullable) NSData *contentData;
//@property (nullable, readwrite) id<WritableObject> content;

@end

@implementation SwfContent

+ (nullable instancetype)contentWithData:(NSData *)data {
    
    return [[self alloc] initWithData:data];
    
}

- (nullable instancetype)initWithData:(NSData *)data {
    
    self = [super init];
    
    if( !data ) {
        
        return nil;
    }
    
    if( self ) {
        
        self.data = data;
        
        if( ![self parse] ) {
            
            return nil;
        }
    }
    
    return self;
}

- (id<WritableObject>)content {
    
    switch (self.tagType) {
            
        case tagBits:
            
            //
            break;
            
        case tagBitsJPEG3:
            
            
//            return [[BitsJPEG3Decoder decoderWithInformation:info data:p length:length] decode];
            //
            break;
            
        case tagBitsLossless2:
            
            //
            break;
            
        default:
            break;
    }
    
    
    return nil;
}

- (BOOL)parse {
    
    const unsigned char *p = self.data.bytes;
    
    HMSWFTag *tagP = (HMSWFTag *)p;
    NSUInteger tagLength = 2;
    p += 2;
    UInt32 tagType = tagP->tagAndLength >> 6;
    UInt32 contentLength = tagP->tagAndLength & 0x3F;
    if(contentLength == 0x3F) {
        contentLength = tagP->extraLength;
        p += 4;
        tagLength += 4;
    }
    
    if( tagType == 0 ) {
        
        self.next = nil;
        
        return YES;
    }
    
    if( contentLength == 0 ) {
        
        return NO;
    }
    
    self.contentData = [self.data subdataWithRange:NSMakeRange(tagLength, contentLength)];
    
    NSUInteger nextPos = tagLength + contentLength;
    NSUInteger length = self.data.length - nextPos;
    self.next = [SwfContent contentWithData:[self.data subdataWithRange:NSMakeRange(nextPos, length)]];
    
    return YES;
}

@end
