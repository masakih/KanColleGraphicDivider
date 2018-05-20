//
//  WritableObject.h
//  KanColleGraphicDivider
//
//  Created by Hori,Masaki on 2018/05/20.
//  Copyright © 2018年 Hori,Masaki. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol WritableObject

- (void)writeToURL:(NSURL *)url atomically:(BOOL)flag;

@end

@interface NSImage(WritableObject) <WritableObject>
@end

@interface NSBitmapImageRep(WritableObject) <WritableObject>
@end
