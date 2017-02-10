//
//  NSString+file.m
//  AVAudioRecode
//
//  Created by Bear on 2016/11/23.
//  Copyright © 2016年 dragontrail. All rights reserved.
//

#import "NSString+file.h"

@implementation NSString (file)
+ (NSString *)uuid{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef strUuid = CFUUIDCreateString(kCFAllocatorDefault,uuid);
    NSString * str = [NSString stringWithString:(__bridge NSString *)strUuid];
    CFRelease(strUuid);
    CFRelease(uuid);
    return  str;

}

+ (NSString *)documentPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

+ (NSString* )cachePatch
{
    NSArray *patchs = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *directory = [patchs objectAtIndex:0];
    NSString* cacheDirectory = [NSString stringWithFormat:@"%@/recoderCache",directory];
    NSFileManager* manager = [NSFileManager defaultManager];
    BOOL isDirectory;
    if (!([manager fileExistsAtPath:cacheDirectory isDirectory:&isDirectory]&&isDirectory)) {
        [manager createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return cacheDirectory;
}

@end
