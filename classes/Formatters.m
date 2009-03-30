//
//  Formatters.m
//  VideoMonkey
//
//  Created by Chris Marrin on 1/20/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import "Formatters.h"

static NSString* stringForSizeValue(double size, NSString* units)
{
    if (size < 10000)
        return [NSString stringWithFormat:@"%d%@", (int) size, units];
    else if (size < 1000000)
        return [NSString stringWithFormat:@"%.1fK%@", size/1000.0, units];
    else if (size < 1000000000)
        return [NSString stringWithFormat:@"%.1fM%@", size/1000000.0, units];
    else
        return [NSString stringWithFormat:@"%.1fG%@", size/1000000000.0, units];
}

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

@implementation FileSizeFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    double size = [anObject doubleValue];
    return stringForSizeValue(size, @"B");
}

@end

@implementation BitrateFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    double bitrate = [anObject doubleValue];
    
    if (bitrate < 0 || bitrate > 4000000000)
        return @"unknown";

    return stringForSizeValue(bitrate, @"bps");
}

@end

@implementation SampleRateFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    double sampleRate = [anObject doubleValue];
    
    if (sampleRate < 0 || sampleRate > 4000000000)
        return @"unknown";
    
    return stringForSizeValue(sampleRate, @"Hz");
}

@end

@implementation BooleanFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    return [anObject boolValue] ? @"yes" : @"no";
}

@end

@implementation FramerateFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    double framerate = [anObject doubleValue];
    return [NSString stringWithFormat:@"%.2ffps", framerate];
}

@end

@implementation AspectRatioFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    double aspectRatio = [anObject doubleValue];
    
    // handle some standard ones
    if (16.0/9.0 - 0.05 <= aspectRatio && aspectRatio <= 16.0/9.0 + 0.05)
        return @"16:9";
        
    if (4.0/3.0 - 0.05 <= aspectRatio && aspectRatio <= 4.0/3.0 + 0.05)
        return @"4:3";
        
    if (3.0/2.0 - 0.05 <= aspectRatio && aspectRatio <= 3.0/2.0 + 0.05)
        return @"3:2";
        
    return [NSString stringWithFormat:@"%.2f:1", aspectRatio];
}

@end
