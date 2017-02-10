//
//  DebugLog.h
//  AVAudioRecode
//
//  Created by Bear on 2016/11/23.
//  Copyright © 2016年 dragontrail. All rights reserved.
//

#ifndef DebugLog_h
#define DebugLog_h

typedef void(^isParpreRecoder)(BOOL granted);

//日志的打印
#ifdef DEBUG

#ifndef DebugLog
#define DebugLog(fmt, ...) NSLog((@"[%s Line %d] \n" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#endif

#else

#ifndef DebugLog
#define DebugLog(fmt, ...) // NSLog((@"[%s Line %d] \n" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#endif

#define NSLog // NSLog


#endif



#endif /* DebugLog_h */
