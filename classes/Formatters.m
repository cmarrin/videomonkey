//
//  Formatters.m
//  VideoMonkey
//
//  Created by Chris Marrin on 1/20/09.

/*
Copyright (c) 2009-2011 Chris Marrin (chris@marrin.com)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    - Redistributions of source code must retain the above copyright notice, this 
      list of conditions and the following disclaimer.

    - Redistributions in binary form must reproduce the above copyright notice, 
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

    - Neither the name of Video Monkey nor the names of its contributors may be 
      used to endorse or promote products derived from this software without 
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH 
DAMAGE.
*/

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
    else if (sampleRate == 0)
        return @"";
    
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
