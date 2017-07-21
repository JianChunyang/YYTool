//
//  RSACrypto.h
//  App
//
//  Created by linus on 15/5/6.
//  Copyright (c) 2015年 linus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSACrypto : NSObject
+(NSString *)encryptDataToBase64:(NSData*)data;
+(NSArray *)encryptStringToNSArray:(NSString *)stringToEncrypt;
+(BOOL)rsaVerifyString:(NSString*)stringToVerify withSignature:(NSString*)signature;
@end
