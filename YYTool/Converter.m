//
//  Converter.m
//  App
//
//  Created by linus on 15/4/20.
//  Copyright (c) 2015年 linus. All rights reserved.
//

#import "Converter.h"

@implementation Converter


+(NSString*)toUTF8JSONString:(id)data
{
    return [self toJSONString:data encoding:NSUTF8StringEncoding];
}
+(NSString*)toJSONString:(id)data encoding:(NSStringEncoding)encoding
{
    if(nil == data) return nil;
    NSError *error;
    NSData *jsonData = nil;
    jsonData = [NSJSONSerialization dataWithJSONObject:data
                                               options:NSJSONWritingPrettyPrinted
                                                 error:&error];
    if (error) {
        return nil;
    }
    return  [[NSString alloc] initWithData:jsonData encoding: NSUTF8StringEncoding];
}

+(NSString*)nsDataToNSStringWithUTF8:(NSData*)data
{
    return [self nsDataToNSString:data encoding:NSUTF8StringEncoding];
}

+(NSDictionary*)jsonDataToNSDictWithUTF8:(NSData*)data{
    return  [self jsonDataToNSDict:data encoding:NSUTF8StringEncoding];
}

+(NSArray*)jsonDataToNSArrayWithUTF8:(NSData*)data{
    return [self jsonDataToNSArray:data encoding:NSUTF8StringEncoding];
}


+(NSData*)dictToNSDataWithUTF8:(NSDictionary*)dict{
    return [self dictToNSData:dict encoding:NSUTF8StringEncoding];
}
+(NSString*)dictToNSStringWithUTF8:(NSDictionary*)dict{
    return [self dictToNSString:dict encoding:NSUTF8StringEncoding];
}

+(NSDictionary*)nsStringToDictWithUTF8:(NSString*)string{
    return [self nsStringToDict:string encoding:NSUTF8StringEncoding];
}
+(NSData*)nsStringToNSDataWithUTF8:(NSString*)string{
    return [self nsStringToNSData:string encoding:NSUTF8StringEncoding];
}


+(NSData*)dictToNSData:(NSDictionary*)dict encoding:(NSStringEncoding)encoding
{
    if(nil == dict)return nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject: (id)dict
                                                       options:0
                                                         error:&error];
    if (error) {
        return nil;
    }
    return jsonData;
}

+(NSString*)dictToNSString:(NSDictionary*)dict encoding:(NSStringEncoding)encoding
{
    
    if(nil == dict) return nil;
    NSError *error;
    NSData *jsonData = nil;
    jsonData = [NSJSONSerialization dataWithJSONObject: (id)dict
                                               options:NSJSONWritingPrettyPrinted
                                                 error:&error];    
    if (error) {
        return nil;
    }
    return  [[NSString alloc] initWithData:jsonData encoding:encoding];
}

+(NSDictionary*)nsStringToDict:(NSString*)string encoding:(NSStringEncoding)encoding

{
    return [self nsDataToJson:[self nsStringToNSData:string encoding:encoding] encoding:encoding];
}

+(id)nsDataToJson:(NSData*)data encoding:(NSStringEncoding)encoding
{
    if (nil == data)return nil;
    
    id jsonData = nil;
    NSError *error;
    jsonData = [NSJSONSerialization JSONObjectWithData: data
                                               options:NSJSONReadingMutableLeaves error: &error];
    if (error) {
        return nil;
    }
    return jsonData;
}

+(NSDictionary*)jsonDataToNSDict:(NSData*)data encoding:(NSStringEncoding)encoding
{
    if (nil == data)return nil;
    id decode_data = [self nsDataToJson:data encoding:encoding];
    if (decode_data == nil){
        return nil;
    }
    if ([decode_data isKindOfClass: [NSMutableDictionary class]]) {
        return (NSDictionary*)decode_data;
    }
    if ([decode_data isKindOfClass: [NSDictionary class]]) {
        return (NSDictionary*)decode_data;
    }
    return nil;
}

+(NSArray*)jsonDataToNSArray:(NSData*)data encoding:(NSStringEncoding)encoding
{
    if (nil == data)return nil;
    id decode_data = [self nsDataToJson:data encoding:encoding];
    
    if (decode_data == nil){
        return nil;
    }
    if ([decode_data isKindOfClass:[NSDictionary class]]) {
        return (NSArray*)decode_data;
    }
    return nil;
}

+(NSData*)nsStringToNSData:(NSString*)string encoding:(NSStringEncoding)encoding
{
    return [string dataUsingEncoding:encoding];
}
+(NSString*)nsDataToNSString:(NSData*)data encoding:(NSStringEncoding)encoding
{
    return [[NSString alloc]initWithData:data encoding:encoding];
}

+(NSString*)dataToBase64String:(NSData*)dataTobase64
{
    dataTobase64 = [dataTobase64 base64EncodedDataWithOptions:0];
    NSString *ret = [[NSString alloc] initWithData:dataTobase64 encoding:NSUTF8StringEncoding];
    return ret;
}

+(NSString *)base64Encode:(NSString *)b64StringToEncode
{
    if (nil == b64StringToEncode) {
        return nil;
    }
    NSData *dataToEncode = [self nsStringToNSData:b64StringToEncode encoding:NSUTF8StringEncoding];
    dataToEncode = [dataToEncode base64EncodedDataWithOptions:0];
    NSString *ret = [[NSString alloc] initWithData:dataToEncode encoding:NSUTF8StringEncoding];
    return ret;
}

+(NSString*)base64Decode:(NSString *)stringToDecode
{
    if (nil == stringToDecode) {
        return nil;
    }
    NSData *data = [[NSData alloc] initWithBase64EncodedString:stringToDecode options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return [self nsDataToNSString:data encoding:NSUTF8StringEncoding];
}

#pragma ----------------- time formatter ---------------
+(NSDateFormatter*)timeFormatterWithTimeZone:(NSString*)timeZoneString
{
    if (nil == timeZoneString) {
        timeZoneString = [self defaultTimeZone];
    }
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:timeZoneString];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:[self defaultTimeFormat] ];
    [formatter setTimeZone:timeZone];
    return  formatter;
}
+(NSTimeInterval)strTime2UnixTimestamp:(NSString*)stringToFormat
{
    return [[[self timeFormatterWithTimeZone:nil] dateFromString:stringToFormat] timeIntervalSince1970];
}
+(NSString*)unixTimestampToString:(NSTimeInterval)timestampToFormat
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestampToFormat];
    return [[self timeFormatterWithTimeZone:nil] stringFromDate:date];
}

+(NSString*)defaultTimeZone
{
    return @"Asia/Shanghai";
}
+(NSString*)defaultTimeFormat
{
    return @"YYYY-MM-dd HH:mm:ss";
}
@end




