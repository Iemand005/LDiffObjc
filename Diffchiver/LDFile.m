//
//  File.m
//  larchiver
//
//  Created by Lasse Lauwerys on 30/03/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import "LDFile.h"

@implementation LDFile

- (id)initWithPath:(NSString *)path
{
    return path ? [self initWithURL:[NSURL fileURLWithPath:path]] : [self init];
}

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    self.url = url;
    return self;
}

- (void)setPath:(NSString*)path
{
    self.url = [NSURL fileURLWithPath:path];
}

- (void)setPathWithURL:(NSURL*)url
{
    self.url = url;
}

- (void)changeDirectory:(NSURL*)directory
{
    self.path = [directory.path stringByAppendingPathComponent:self.name];
}

- (NSString*)path
{
    return self.url.path;
}

- (NSString*)parentDirectory
{
    return [self.path stringByDeletingLastPathComponent];
}

- (NSString*)name
{
    return [[[self.url path] pathComponents] lastObject];
}

- (UInt64)size
{
    return [self getFileStats].st_size;
}

- (void)open
{
    self.handle = [NSFileHandle fileHandleForReadingFromURL:self.url error:nil];
}

- (void)open:(NSError * __autoreleasing *)error
{
    NSError *fileError;
    self.handle = [NSFileHandle fileHandleForReadingFromURL:self.url error:&fileError];
    if (fileError) *error = fileError;
}

- (void)openWrite
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.path])
        [fileManager createFileAtPath:self.path contents:nil attributes:nil];
    self.handle = [NSFileHandle fileHandleForWritingAtPath:self.path];
}

- (void)writeData:(NSData*)data
{
    [self.handle writeData:data];
}

- (void)writeBytes:(const void *)bytes length:(NSUInteger)length
{
    [self.handle writeData:[NSData dataWithBytes:bytes length:length]];
}

- (void)writeByte:(Byte)byte
{
    [self writeBytes:&byte length:1];
}

- (void)seekToFileOffset:(UInt64)offset
{
    [[self handle] seekToFileOffset:offset];
}

- (void)readByte:(const void *)byte
{
    byte = &[[self readDataOfLength:1] bytes][0];
}

- (const void *)readBytesOfLength:(NSUInteger)length
{
    return [[self.handle readDataOfLength:length] bytes];
}

- (Byte)readByte
{
    Byte byte;
    [[self readDataOfLength:1] getBytes:&byte length:1];
    return byte;
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    return [self.handle readDataOfLength:length];
}

- (void)close
{
    [self.handle closeFile];
}

- (BOOL)createAndOpen
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.path]) {
        [fileManager createFileAtPath:self.path contents:nil attributes:nil];
        [self openWrite];
        return true;
    } else return false;
}

- (BOOL)createAndOpenWithoutOverwriting
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *fileURL = [self url];
    for (NSInteger index = 1; [fileManager fileExistsAtPath:[self path]]; ++index) {
        NSString *fileExtension = [fileURL pathExtension];
        NSString *newFileName = [[[fileURL URLByDeletingPathExtension] lastPathComponent] stringByAppendingFormat:@" %ld", index];
        [self setUrl:[[[fileURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:newFileName] URLByAppendingPathExtension:fileExtension]];
        if (index > 10000) return false;
    }
    [fileManager createFileAtPath:[self path] contents:nil attributes:nil];
    [self openWrite];
    return true;
}

- (NSDictionary *)getFileAttributes
{
    return [[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil];
}

- (struct stat)getFileStats
{
    struct stat sb;
    stat(self.path.UTF8String, &sb);
    return sb;
}

+ (LDFile *)fileWithPath:(NSString *)path
{
    return [[LDFile alloc] initWithPath:path];
}

+ (LDFile *)fileWithName:(NSString *)name relativeTo:(NSString *)directory
{
    return [LDFile fileWithPath:[directory stringByAppendingPathComponent:name]];
}

+ (LDFile *)fileFromURL:(NSURL *)url
{
    return [[LDFile alloc] initWithURL:url];
}

- (NSURL *)previewItemURL
{
    return self.url;
}

- (NSImage *)image
{
    return [[NSWorkspace sharedWorkspace] iconForFile:self.path];
}

- (NSImage *)imageWithSize:(NSSize)size asIcon:(BOOL)asIcon
{
    if (cachedThumbnail) return cachedThumbnail;
    NSImage *image;
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:asIcon] forKey:(NSString *)kQLThumbnailOptionIconModeKey];
    
    CGImageRef imageRef = QLThumbnailCopyImage(QLThumbnailCreate(kCFAllocatorDefault, (__bridge CFURLRef)self.url, CGSizeMake(size.width, size.height), (__bridge CFDictionaryRef)dict));
    if (imageRef) {
        image = [[NSImage alloc] initWithCGImage:imageRef size:size];
        CFRelease(imageRef);
    }
    else image = [self image];
    return cachedThumbnail = image;
}

- (BOOL)isRegularFile
{
    return [self verifyURLKey:NSURLIsRegularFileKey];
}

- (BOOL)verifyURLKey:(NSString* const)key
{
    NSError *error;
    NSNumber *resourceValue;
    if ([self.url getResourceValue:&resourceValue forKey:key error:&error])
        return resourceValue == NULL || resourceValue.boolValue;
    else NSLog(@"An error occurred verifying the URL key: %@", error.localizedDescription);
    return NO;
}

- (BOOL)isEqual:(id)object
{
    return object && (LDFile*)object && [self.path isEqualToString:((LDFile*)object).path];
}

+ (LDFile *)file
{
    return [[LDFile alloc] init];
}

@end
