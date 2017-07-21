//
//  Converter.h
//  App
//
//  Created by linus on 15/4/20.
//  Copyright (c) 2015年 linus. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Converter : NSObject


+(NSString*)toUTF8JSONString:(id)data;
+(NSString*)toJSONString:(id)data encoding:(NSStringEncoding)encoding;

+(NSString*)nsDataToNSString:(NSData*)data encoding:(NSStringEncoding)encoding;

+(NSDictionary*)jsonDataToNSDict:(NSData*)data encoding:(NSStringEncoding)encoding;
+(NSArray*)jsonDataToNSArray:(NSData*)data encoding:(NSStringEncoding)encoding;


+(NSData*)dictToNSData:(NSDictionary*)dict encoding:(NSStringEncoding)encoding;
+(NSString*)dictToNSString:(NSDictionary*)dict encoding:(NSStringEncoding)encoding;


+(NSDictionary*)nsStringToDict:(NSString*)string encoding:(NSStringEncoding)encoding;
+(NSData*)nsStringToNSData:(NSString*)string encoding:(NSStringEncoding)encoding;



+(NSString*)nsDataToNSStringWithUTF8:(NSData*)data;

+(NSDictionary*)jsonDataToNSDictWithUTF8:(NSData*)data;
+(NSArray*)jsonDataToNSArrayWithUTF8:(NSData*)data;


+(NSData*)dictToNSDataWithUTF8:(NSDictionary*)dict;
+(NSString*)dictToNSStringWithUTF8:(NSDictionary*)dict;

+(NSDictionary*)nsStringToDictWithUTF8:(NSString*)string;
+(NSData*)nsStringToNSDataWithUTF8:(NSString*)string;





+(NSString*)base64Decode:(NSString *)stringToDecode;
+(NSString *)base64Encode:(NSString *)b64StringToEncode;
+(NSString*)dataToBase64String:(NSData*)dataTobase64;

// 时间转换方法

+(NSString*)defaultTimeZone;
+(NSString*)defaultTimeFormat;
+(NSDateFormatter*)timeFormatterWithTimeZone:(NSString*)timeZoneString;
+(NSTimeInterval)strTime2UnixTimestamp:(NSString*)stringToFormat;
+(NSString*)unixTimestampToString:(NSTimeInterval)timestampToFormat;

@end
