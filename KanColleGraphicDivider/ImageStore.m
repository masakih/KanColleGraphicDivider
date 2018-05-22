//
//  ImageStore.m
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/19.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#include "KanColleGraphicDivider.h"
#import "ImageStore.h"

void saveDataWithExtension(Information *info, NSData *data, NSString *extention, UInt16 charactorID) {
    
    NSString *path = [NSString stringWithFormat:@"%@-%d.%@", info.originalName, charactorID, extention];
    path = [info.outputDir stringByAppendingPathComponent:path];
    NSURL *url = [NSURL fileURLWithPath:path];
    [data writeToURL:url atomically:YES];
}
