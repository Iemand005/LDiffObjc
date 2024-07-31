//
//  LDDataStreamReader.m
//  Diffchiver
//
//  Created by Lasse Lauwerys on 13/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import "LDDataStreamReader.h"

@implementation LDDataStreamReader

- (id)init
{
    self = [super init];
    if (self) {
        range = NSMakeRange(0, 0);
    }
    return self;
}

- (id)initWithData:(NSData *)data
{
    self = [self init];
    if (self) {
        [self setData:data];
    }
    return self;
}

- (void)setData:(NSData *)data
{
    streamData = data;
    range.location = 0;
}

- (NSData *)data
{
    return streamData;
}

- (NSUInteger)length
{
    return range.length;
}

- (void)setLength:(NSUInteger)length
{
    range.length = length;
}

- (void)nextByte:(void *)byte
{
    [self.data getBytes:byte range:NSMakeRange(range.location, 1)];
    range.location++;
}

- (void)nextBytes:(void *)bytes
{
    [self.data getBytes:bytes range:range];
    range.location += range.length;
}

- (void)nextBytes:(void *)bytes length:(NSUInteger)length
{
    [self.data getBytes:bytes range:NSMakeRange(range.location, length)];
    range.location += length;
}

- (void)nextWord:(void *)bytes
{
    [self.data getBytes:bytes range:NSMakeRange(range.location, 2)];
    range.location += 2;
}

- (void)nextDoubleWord:(void *)bytes
{
    [self.data getBytes:bytes range:NSMakeRange(range.location, 4)];
    range.location += 4;
}

- (void)nextQuadWord:(void *)bytes
{
    [self.data getBytes:bytes range:NSMakeRange(range.location, 8)];
    range.location += 8;
}

- (UInt16)nextWord
{
    UInt16 word;
    [self nextWord:&word];
    return word;
}

- (UInt32)nextDoubleWord
{
    UInt32 word;
    [self nextDoubleWord:&word];
    return word;
}

- (UInt64)nextQuadWord
{
    UInt64 word;
    [self nextQuadWord:&word];
    return word;
}

- (NSData *)nextData
{
    char *bytes = malloc(range.length);
    [self.data getBytes:bytes range:range];
    range.location += range.length;
    return [NSData dataWithBytesNoCopy:bytes length:range.length];
}

- (void)seek:(NSUInteger)offset
{
    range.location = offset;
}

- (Boolean)reachedEnd
{
    return range.location == [[self data] length];
}

+ (LDDataStreamReader *)streamReader
{
    return [[LDDataStreamReader alloc] init];
}

+ (LDDataStreamReader *)streamReaderWithData:(NSData *)data
{
    return [[LDDataStreamReader alloc] initWithData:data];
}

@end
