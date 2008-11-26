/*
 *  avencode.h
 *  VideoMonkey
 *
 *  Created by Chris Marrin on 11/19/08.
 *  Copyright 2008 Apple. All rights reserved.
 *
 */

typedef void* ffmpeg_Context;
typedef enum { FC_NONE } ffmpeg_CallbackType;
typedef void (*ffmpeg_Callback)(ffmpeg_Context, ffmpeg_CallbackType, void* userData);

ffmpeg_Context ffmpeg_createContext(ffmpeg_Callback, void* userData);
void ffmpeg_destroyContext(ffmpeg_Context);

int ffmpeg_addInputFile(ffmpeg_Context, const char*);
int ffmpeg_addOutputFile(ffmpeg_Context, const char*);

void ffmpeg_setParam(ffmpeg_Context, const char* name, const char* value);

void ffmpeg_startEncode(ffmpeg_Context);
void ffmpeg_pauseEncode(ffmpeg_Context);

float ffmpeg_getProgress(ffmpeg_Context);
float ffmpeg_getFloatParam(ffmpeg_Context, const char* name);
const char* ffmpeg_getStringParam(ffmpeg_Context, const char* name);
