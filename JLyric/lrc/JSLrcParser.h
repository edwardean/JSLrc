//
//  JSLrcParser.h
//  JLyric
//
//  Created by Jey on 8/8/12.
//  Copyright (c) 2012 Jey. All rights reserved.
//
//    http://www.apache.org/licenses/LICENSE-2.0

@class JSLrc;

@interface JSLrcParser : NSObject

+ (JSLrc *)lrcValue:(NSString *)file;

@end


//##################################### JSLrc ##################################
@interface JSLrc : NSObject

@property (readonly, nonatomic) NSMutableDictionary *lyric; // time:value
@property (readonly, nonatomic) NSArray *lyricKey; // time
@property (readonly, nonatomic) NSMutableArray *tags;
@property (strong, nonatomic) NSString *offset;

+ (JSLrc *)lrc;

@end