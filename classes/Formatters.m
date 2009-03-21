//
//  Formatters.m
//  VideoMonkey
//
//  Created by Chris Marrin on 1/20/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import "Formatters.h"


@implementation FileSizeFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    double size = [anObject doubleValue];
    
    if (size < 10000)
        return [NSString stringWithFormat:@"%dB", (int) size];
    else if (size < 1000000)
        return [NSString stringWithFormat:@"%.1fKB", size/1000.0];
    else if (size < 1000000000)
        return [NSString stringWithFormat:@"%.1fMB", size/1000000.0];
    else
        return [NSString stringWithFormat:@"%.1fGB", size/1000000000.0];
}

@end

@implementation DurationFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    double duration = [anObject doubleValue];
    
    int ms = (int) round(fmod(duration, 1) * 1000);
    int hrs = (int) duration;
    int sec = hrs % 60;
    hrs /= 60;
    int min = hrs % 60;
    hrs /= 60;
    if (hrs == 0 && min == 0)
        return [NSString stringWithFormat:@"%.2fs", ((double) sec + ((double) ms / 1000.0))];
    else if (hrs == 0)
        return [NSString stringWithFormat:@"%dm %ds", min, sec];
    else
        return [NSString stringWithFormat:@"%dh %dm", hrs, min];
}

@end

@implementation FrameSizeFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    int frameSize = [anObject intValue];
    int width = frameSize >> 16;
    int height = frameSize & 0xffff;
    
    return [NSString stringWithFormat:@"%dx%d", width, height];
}

@end

@implementation BitrateFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    double bitrate = [anObject doubleValue];
    
    if (bitrate < 0 || bitrate > 4000000000)
        return @"unknown";
    
    if (bitrate < 10000)
        return [NSString stringWithFormat:@"%dbps", (int) bitrate];
    else if (bitrate < 10000000)
        return [NSString stringWithFormat:@"%dKbps", (int) (bitrate/1000.0)];
    else if (bitrate < 10000000000)
        return [NSString stringWithFormat:@"%dMbps", (int) (bitrate/1000000.0)];
    else
        return [NSString stringWithFormat:@"%dGbps", (int) (bitrate/1000000000.0)];
}

@end

