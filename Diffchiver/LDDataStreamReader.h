//
//  LDDataStreamReader.h
//  Diffchiver
//
//  Created by Lasse Lauwerys on 13/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LDDataStreamReader : NSObject
{
    NSRange range;
    NSData *streamData;
}

@property NSData *data;
@property (nonatomic) NSUInteger length;

- (id)initWithData:(NSData *)data;

- (void)nextByte:(void *)byte;
- (void)nextBytes:(void *)bytes;
- (void)nextBytes:(void *)bytes length:(NSUInteger)length;
- (void)nextWord:(void *)bytes;
- (void)nextDoubleWord:(void *)bytes;
- (void)nextQuadWord:(void *)bytes;
- (UInt16)nextWord;
- (UInt32)nextDoubleWord;
- (UInt64)nextQuadWord;
- (NSData *)nextData;
- (Boolean)reachedEnd;
//- (UInt64)setNextLenTo:(NSUInteger);

+ (LDDataStreamReader *)streamReader;
+ (LDDataStreamReader *)streamReaderWithData:(NSData *)data;

@end
