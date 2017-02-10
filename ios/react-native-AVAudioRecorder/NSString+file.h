//
//  NSString+file.h
//  AVAudioRecode
//
//  Created by Bear on 2016/11/23.
//  Copyright © 2016年 dragontrail. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (file)

+ (NSString *)uuid;
+ (NSString *)documentPath;
+ (NSString* )cachePatch;
@end
