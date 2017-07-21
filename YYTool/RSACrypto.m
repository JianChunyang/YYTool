//
//  RSACrypto.m
//  App
//
//  Created by linus on 15/5/6.
//  Copyright (c) 2015年 linus. All rights reserved.
//
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>


#import "RSACrypto.h"
#import "Converter.h"


#define kChosenCipherBlockSize	kCCBlockSizeAES128
#define kChosenCipherKeySize	kCCKeySizeAES128
#define kChosenDigestLength		CC_SHA1_DIGEST_LENGTH



NSString *header = @"-----BEGIN PUBLIC KEY-----";
NSString *footer = @"-----END PUBLIC KEY-----";

NSString *body = @"MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCXbiCN5y6mO/A22Ynk/H9sMZJ6qkP1pRoSfviUK4H3QapwnATmQW5CaM8SxY1AadTxqyfUw5gxedS1aDMLttqJ9XZ6fsxSDKMB23q9RWAYWXkLLjrpynRWgUUkUvqOvr2IhTlK5lPD+RqUOxfUsxbjza0QPR4+ID+6Io2MbX/+pwIDAQAB";

@implementation RSACrypto

static NSString *base64_encode_data(NSData *data){
    data = [data base64EncodedDataWithOptions:0];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return ret;
}

static NSData *base64_decode(NSString *str){
    NSData *data = [[NSData alloc] initWithBase64EncodedString:str options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return data;
}

+ (NSData *)stripPublicKeyHeader:(NSData *)d_key{
    // Skip ASN.1 public key header
    if (d_key == nil) return(nil);
    
    unsigned long len = [d_key length];
    if (!len) return(nil);
    
    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx    = 0;
    
    if (c_key[idx++] != 0x30) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    // PKCS #1 rsaEncryption szOID_RSA_RSA
    static unsigned char seqiod[] =
    { 0x30,   0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00 };
    if (memcmp(&c_key[idx], seqiod, 15)) return(nil);
    
    idx += 15;
    
    if (c_key[idx++] != 0x03) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    if (c_key[idx++] != '\0') return(nil);
    
    // Now make a new NSData from this buffer
    return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}

+ (SecKeyRef)addPublicKey
{
    NSString *key = [NSString stringWithFormat:@"%@\n%@\n%@",header,body,footer];
    NSRange spos = [key rangeOfString:@"-----BEGIN PUBLIC KEY-----"];
    NSRange epos = [key rangeOfString:@"-----END PUBLIC KEY-----"];
    if(spos.location != NSNotFound && epos.location != NSNotFound){
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e-s);
        key = [key substringWithRange:range];
    }
    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];
    
    // This will be base64 encoded, decode it.
    NSData *data = base64_decode(key);
    data = [RSACrypto stripPublicKeyHeader:data];
    if(!data){
        return nil;
    }
    
    NSString *tag = @"what_the_fuck_is_this";
    NSData *d_tag = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];
    
    // Delete any old lingering key with the same tag
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [publicKey setObject:d_tag forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)publicKey);
    
    // Add persistent version of the key to system keychain
    [publicKey setObject:data forKey:(__bridge id)kSecValueData];
    [publicKey setObject:(__bridge id) kSecAttrKeyClassPublic forKey:(__bridge id)
     kSecAttrKeyClass];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)
     kSecReturnPersistentRef];
    
    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)publicKey, &persistKey);
    if (persistKey != nil){
        CFRelease(persistKey);
    }
    if ((status != noErr) && (status != errSecDuplicateItem)) {
        return nil;
    }
    
    [publicKey removeObjectForKey:(__bridge id)kSecValueData];
    [publicKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    // Now fetch the SecKeyRef version of the key
    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)publicKey, (CFTypeRef *)&keyRef);
    if(status != noErr){
        return nil;
    }
    return keyRef;
}
+(NSArray *)formatStrToNSArrayData:(NSString*)str withMaxLength:(uint8_t)max_len
{
    NSMutableArray *array = [[NSMutableArray alloc]init];
    NSData* data = nil;
    NSUInteger step = max_len;
    long length = [str length];
    
    if (length < step) {
        data = [str dataUsingEncoding:NSUTF8StringEncoding];
        [array addObject: data];
    }
    else{
        NSUInteger from, to , len = [str length];
        
        for (int i =0; i < [str length]; ) {
            from = i;
            i += step;
            to = step;
            if (i >= len) {
                to = len - i + step;
            }
            NSRange range = NSMakeRange(from, to);
            data = [[str  substringWithRange: range] dataUsingEncoding:NSUTF8StringEncoding];
            [array addObject: data];
        }
        
    }
    
    return (NSArray*)array;
}


+ (NSString *)encryptWithPublicKey:(SecKeyRef )keyRef andData:(NSData*)data
{
    
    
    size_t cipherBufferSize;
    uint8_t *cipherBuffer;
    
    
    const uint8_t *dataToEncrypt = (const uint8_t *)[data bytes];
    size_t dataLength = (size_t)data.length;
    
    cipherBufferSize = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
    
    if(dataLength > cipherBufferSize - 11){
        if (keyRef)CFRelease(keyRef);
        return nil;
    }
    
    cipherBuffer = malloc(cipherBufferSize);
    
    OSStatus status = noErr;
    status = SecKeyEncrypt(keyRef,kSecPaddingPKCS1,dataToEncrypt,dataLength,cipherBuffer,&cipherBufferSize);
    NSString *ret = nil;
    if (0 == status) {
        NSData *data = [NSData dataWithBytes:cipherBuffer length:cipherBufferSize];
        ret = base64_encode_data(data);
    }
    if(cipherBuffer)free(cipherBuffer);
    
    return ret;
}
- (NSString*)decryptWithPrivateKey:(SecKeyRef)keyRef andCryptedData:(NSData *)dataToDecrypt
{
    OSStatus status = noErr;;
    
    size_t cipherBufferSize = [dataToDecrypt length];
    uint8_t *cipherBuffer = (uint8_t *)[dataToDecrypt bytes];
    
    size_t plainBufferSize;
    uint8_t *plainBuffer;
    
    //  Allocate the buffer
    plainBufferSize = SecKeyGetBlockSize(keyRef);
    plainBuffer = malloc(plainBufferSize);
    
    if (plainBufferSize < cipherBufferSize) {
        if(plainBuffer)free(plainBuffer);
        return nil;
    }
    
    status = SecKeyDecrypt( keyRef,
                           kSecPaddingPKCS1,
                           cipherBuffer,
                           cipherBufferSize,
                           plainBuffer,
                           &plainBufferSize);
    
    NSString *ret = nil;
    if (noErr == status) {
        NSData *data = [NSData dataWithBytes:plainBuffer length:plainBufferSize] ;

        ret =  [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    }
    if(plainBuffer)free(plainBuffer);
    return ret;
    
}


+ (NSData *)getHashBytes:(NSData *)plainText
{
    CC_SHA1_CTX ctx;
    uint8_t * hashBytes = NULL;
    NSData * hash = nil;
    
    // Malloc a buffer to hold hash.
    hashBytes = malloc( kChosenDigestLength * sizeof(uint8_t) );
    memset((void *)hashBytes, 0x0, kChosenDigestLength);
    
    // Initialize the context.
    CC_SHA1_Init(&ctx);
    // Perform the hash.
    CC_SHA1_Update(&ctx, (void *)[plainText bytes], (CC_LONG)[plainText length]);
    // Finalize the output.
    CC_SHA1_Final(hashBytes, &ctx);
    // Build up the SHA1 blob.
    hash = [NSData dataWithBytes:(const void *)hashBytes length:(NSUInteger)kChosenDigestLength];
    if (hashBytes) free(hashBytes);
    return hash;
}

#pragma  ------------------- public methods -----------------------


+(BOOL)rsaVerifyString:(NSString*)stringToVerify withSignature:(NSString*)signature
{
    SecKeyRef keyRef = [RSACrypto addPublicKey];
    if(!keyRef){
        return NO;
    }
    
    NSData *plainTextData = [Converter nsStringToNSData:stringToVerify encoding:NSUTF8StringEncoding];
    NSData *sig = base64_decode(signature);
    size_t signedHashBytesSize = 0;
    OSStatus sanityCheck = noErr;
    // Get the size of the assymetric block.
    signedHashBytesSize = SecKeyGetBlockSize(keyRef);
    
    sanityCheck = SecKeyRawVerify(keyRef,
                                  kSecPaddingPKCS1SHA1,
                                  (const uint8_t *)[[self getHashBytes:plainTextData] bytes],
                                  kChosenDigestLength,
                                  (const uint8_t *)[sig bytes],
                                  signedHashBytesSize
                                  );
    
    return (sanityCheck == noErr) ? YES : NO;
}
+ (NSArray *)encryptStringToNSArray:(NSString *)stringToEncrypt
{
    
    SecKeyRef  keyRef= [RSACrypto addPublicKey];
    if(!keyRef){
        return nil;
    }
    
    uint8_t max_len = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t) - 11;
    NSMutableArray *array = [[NSMutableArray alloc]init];
    
    for (NSData *data in [self formatStrToNSArrayData:stringToEncrypt withMaxLength:max_len]) {
        [array addObject: [RSACrypto encryptWithPublicKey:keyRef andData:data]];
    }
    if (keyRef)CFRelease(keyRef);
    return (NSArray*)array;
    
}
+(NSString *)encryptDataToBase64:(NSData*)data
{
    SecKeyRef  keyRef= [RSACrypto addPublicKey];
    if(!keyRef){
        return nil;
    }
    return [self encryptWithPublicKey:keyRef andData:data];
    
}
@end







