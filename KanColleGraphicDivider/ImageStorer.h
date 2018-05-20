//
//  ImageStorer.h
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/19.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Information.h"

void saveDataWithExtension(Information *info, id data, NSString *extention, UInt16 charactorID);

void saveImageAsPNG(Information *info, id image, UInt16 charactorID);

void storeImage(Information *info, const unsigned char *p, UInt32 length, UInt16 charactorID);
