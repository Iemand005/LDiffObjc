//
//  LDCRC.h
//  larchiver
//
//  Created by Lasse Lauwerys on 6/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LDCRC : NSObject
{
    UInt32 crc;
    UInt32 divisor;
}

- (id)initWithDivisor:(UInt32)value;
- (void)writeBytes:(const unsigned char *)data length:(long)length;
- (void)writeByte:(char)byte;
- (void)writeData:(NSData *)data;
- (void)writeDataSliceBy16:(NSData *)data;
- (void)setDivisor:(int)value;
- (int)getChecksum;
- (UInt32)writeBytesSliceBy16:(const void *)data length:(Size)length;

+ (LDCRC *)crc;
+ (LDCRC *)crcWithDivisor:(UInt32)value;

@end

