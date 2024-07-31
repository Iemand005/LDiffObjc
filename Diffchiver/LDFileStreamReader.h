//
//  LDFileStreamReader.h
//  Diffchiver
//
//  Created by Lasse Lauwerys on 13/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LDFile.h"

@interface LDFileStreamReader : NSObject
{
    NSRange range;
    NSMutableData *buffer;
}

@property LDFile *file;
@property (nonatomic) NSUInteger length;

- (id)initWithURL:(NSURL *)url;
//- (void)readBytes:(NSUInteger)length;
- (void)readDataOfLength:(NSUInteger)length;
- (void)nextByte:(void *)byte;
- (void)nextBytes:(void *)bytes;
- (void)nextBytes:(void *)bytes length:(NSUInteger)length;
- (void)flushBuffer;
- (void)flushBufferAndReadDataOfLength:(NSUInteger)length;
- (void)reset;
- (void)skipBytes;
- (void)skipBytes:(NSUInteger)amount;

+ (LDFileStreamReader *)streamReader;
+ (LDFileStreamReader *)streamReaderWithURL:(NSURL *)url;
+ (LDFileStreamReader *)streamReaderWithFile:(LDFile *)file;

@end
