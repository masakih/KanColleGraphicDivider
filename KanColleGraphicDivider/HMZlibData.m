//
//  HMZlibData.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2016/09/11.
//  Copyright © 2016年 Hori,Masaki. All rights reserved.
//

#import "HMZlibData.h"
#import <zlib.h>


@implementation NSData (HMZlibData)

- (z_stream)initialized_zStream {
    z_stream zStream;
    zStream.zalloc = Z_NULL;
    zStream.zfree = Z_NULL;
    zStream.opaque = Z_NULL;
    return zStream;
}

- (NSData *)deflate:(int)compressionLevel {
    z_stream zStream = [self initialized_zStream];
    Bytef buffer[131072];
    deflateInit(&zStream, compressionLevel);
    zStream.next_in = (Bytef *)self.bytes;
    zStream.avail_in = (UInt)self.length;
    int retval = Z_OK;
    NSMutableData *ret = [NSMutableData dataWithCapacity:0];
    do {
        zStream.next_out = buffer;
        zStream.avail_out = sizeof(buffer);
        retval = deflate(&zStream, Z_FINISH);
        size_t length = sizeof(buffer) - zStream.avail_out;
        if (length > 0)
            [ret appendBytes:buffer length:length];
    } while (zStream.avail_out != sizeof(buffer));
    deflateEnd(&zStream);
    return ret;
}

- (NSData *)inflate {
    z_stream zStream = [self initialized_zStream];
    Bytef buffer[131072];
    inflateInit(&zStream);
    zStream.next_in = (Bytef *)self.bytes;
    zStream.avail_in = (UInt)self.length;
    int retval = Z_OK;
    NSMutableData *ret = [NSMutableData dataWithCapacity:0];
    do {
        zStream.next_out = buffer;
        zStream.avail_out = sizeof(buffer);
        retval = inflate(&zStream, Z_FINISH);
        size_t length = sizeof(buffer) - zStream.avail_out;
        if (length > 0)
            [ret appendBytes:buffer length:length];
    } while (zStream.avail_out != sizeof(buffer));
    inflateEnd(&zStream);
    return ret;
}

@end
