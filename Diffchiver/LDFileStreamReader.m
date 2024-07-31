//
//  LDFileStreamReader.m
//  Diffchiver
//
//  Created by Lasse Lauwerys on 13/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import "LDFileStreamReader.h"
//#include "pyobjc-api.h"
//#include "pyobjc-api.h"

@implementation LDFileStreamReader

- (id)init
{
    self = [super init];
    buffer = [NSMutableData data];
    return self;
}

- (id)initWithURL:(NSURL *)url
{
    return [self initWithFile:[LDFile fileFromURL:url]];
}

- (id)initWithFile:(LDFile *)file
{
    self = [self init];
    if (self) {
        [file open];
        [self setFile:file];
    }
    return self;
}

- (void)readDataOfLength:(NSUInteger)length
{
    [buffer appendData:[self.file readDataOfLength:length]];
}

- (void)nextBytes:(void *)bytes
{
    [buffer getBytes:bytes range:range];
    range.location += range.length;
}

- (void)nextByte:(void *)byte
{
    [buffer getBytes:byte range:NSMakeRange(range.location, 1)];
    range.location++;
}

- (void)nextBytes:(void *)bytes length:(NSUInteger)length
{
    [buffer getBytes:bytes range:NSMakeRange(range.location, length)];
    range.location += length;
}

- (void)flushBuffer
{
    range.location = 0;
    [buffer setLength:0];
}

- (void)flushBufferAndReadDataOfLength:(NSUInteger)length
{
    [self flushBuffer];
    [self readDataOfLength:length];
}

- (void)reset
{
    [self flushBuffer];
    [self.file.handle seekToFileOffset:0];
}

- (void)skipBytes
{
    range.location += range.length;
}

- (void)skipBytes:(NSUInteger)amount
{
    range.location += amount;
}

- (NSUInteger)length
{
    return range.length;
}

- (void)setLength:(NSUInteger)length
{
    range.length = length;
}

+ (LDFileStreamReader *)streamReader
{
    return [[LDFileStreamReader alloc] init];
}

+ (LDFileStreamReader *)streamReaderWithURL:(NSURL *)url
{
    return [[LDFileStreamReader alloc] initWithURL:url];
}

+ (LDFileStreamReader *)streamReaderWithFile:(LDFile *)file
{
    return [[LDFileStreamReader alloc] initWithFile:file];
}


@end
