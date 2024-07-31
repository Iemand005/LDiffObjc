//
//  File.h
//  larchiver
//
//  Created by Lasse Lauwerys on 30/03/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>

#import "LDCRC.h"
//#import "LDFileStreamReader.h"

#include <sys/stat.h>

@interface LDFile : NSObject <QLPreviewItem>
{
@private NSImage *cachedThumbnail;
}

@property NSURL *url;
@property (nonatomic, readonly) UInt64 size;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic) NSString *path;
@property (nonatomic, readonly) NSString *parentDirectory;
@property (strong) NSFileHandle *handle;
@property (nonatomic) BOOL isRegularFile;

- (id)initWithPath:(NSString *)path;
- (id)initWithURL:(NSURL *)path;
- (void)setPathWithURL:(NSURL *)url;
- (void)changeDirectory:(NSURL *)directory;

- (NSImage *)image;
- (NSImage *)imageWithSize:(NSSize)size asIcon:(BOOL)asIcon;

- (BOOL)verifyURLKey:(NSString * const)key;

- (BOOL)createAndOpen;
- (BOOL)createAndOpenWithoutOverwriting;
- (void)open;
- (void)open:(NSError **)error;
- (void)openWrite;
- (void)close;

- (void)seekToFileOffset:(UInt64)offset;

- (void)writeData:(NSData*)data;
- (void)writeBytes:(const void *)bytes length:(NSUInteger)length;
- (void) writeByte:(Byte)byte;
- (void)readByte:(const void *)byte;
- (Byte)readByte;
- (NSData *)readDataOfLength:(NSUInteger)length;
- (const void *)readBytesOfLength:(NSUInteger)length;

- (NSDictionary *)getFileAttributes;
- (struct stat)getFileStats;

+ (LDFile *)file;
+ (LDFile *)fileWithPath:(NSString *)path;
+ (LDFile *)fileFromURL:(NSURL *)url;//??\d
+ (LDFile *)fileWithName:(NSString *)name relativeTo:(NSString *)directory;

@end
