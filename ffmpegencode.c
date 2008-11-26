/*
 *  avencode.c
 *  VideoMonkey
 *
 *  Created by Chris Marrin on 11/19/08.
 *  Copyright 2008 Apple. All rights reserved.
 *
 */

#include "ffmpegencode.h"

#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <limits.h>
#include <unistd.h>
#include <assert.h>
#include "libavformat/avformat.h"
#include "libavcodec/audioconvert.h"
#include "libavutil/fifo.h"
#include "libswscale/swscale.h"
#include "libavcodec/opt.h"
#include "cmdutils.h"

/* select an input stream for an output stream */
typedef struct AVStreamMap {
    int file_index;
    int stream_index;
    int sync_file_index;
    int sync_stream_index;
} AVStreamMap;

typedef struct AVMetaDataMap {
    int out_file;
    int in_file;
} AVMetaDataMap;

#define MAX_FILES 20

// Context
typedef struct Context {
    ffmpeg_Callback myCB;
    void* myUserData;
    
    AVInputFormat *file_iformat;
    AVOutputFormat *file_oformat;
    int frame_width;
    int frame_height;
    AVRational frame_rate;
    float video_qscale;
    float frame_aspect_ratio;
    enum PixelFormat frame_pix_fmt;
    enum SampleFormat audio_sample_fmt;
    AVFormatContext* output_files[MAX_FILES];
    AVCodec* output_codecs[MAX_FILES*MAX_STREAMS];
    int nb_output_files;
    int nb_ocodecs;
    AVFormatContext *input_files[MAX_FILES];
    int64_t input_files_ts_offset[MAX_FILES];
    double input_files_ts_scale[MAX_FILES][MAX_STREAMS];
    AVCodec *input_codecs[MAX_FILES*MAX_STREAMS];
    int nb_input_files;
    int nb_icodecs;
    AVStreamMap stream_maps[MAX_FILES*MAX_STREAMS];
    int nb_stream_maps;
    AVMetaDataMap meta_data_maps[MAX_FILES];
    int nb_meta_data_maps;
    int force_fps;
    
    AVBitStreamFilterContext *video_bitstream_filters;
    AVBitStreamFilterContext *audio_bitstream_filters;
    AVBitStreamFilterContext *subtitle_bitstream_filters;
    AVBitStreamFilterContext *bitstream_filters[MAX_FILES][MAX_STREAMS];

    int opt_programid;
    int audio_volume;
    int audio_sync_method;
    int video_sync_method;
    int frame_topBand;
    int frame_bottomBand;
    int frame_leftBand;
    int frame_rightBand;
    int frame_padtop;
    int frame_padbottom;
    int frame_padleft;
    int frame_padright;
    int padcolor[3];
    unsigned int sws_flags;
    char* pass_logfilename;
    int bit_buffer_size;
    uint8_t* bit_buffer;
    int verbose;
    int64_t timer_start;
    int input_sync;
    int max_frames[4];
    int64_t recording_time;
    uint64_t limit_filesize;
    int opt_shortest;
    float dts_delta_threshold;
    int copy_ts;
    int64_t start_time;
    float audio_drift_threshold;
    int64_t video_size;
    int64_t audio_size;
    int64_t extra_size;
    int nb_frames_dup;
    int nb_frames_drop;
    
    char *vstats_filename;
    FILE *vstats_file;
    
    uint16_t *intra_matrix;
    uint16_t *inter_matrix;
    
    int audio_stream_copy;
    int video_stream_copy;
    int subtitle_stream_copy;
    char *video_standard;
    
    int video_global_header;
    const char *video_rc_override_string;
    int video_disable;
    int video_discard;
    char *video_codec_name;
    int video_codec_tag;
    int same_quality;
    int do_deinterlace;
    int top_field_first;
    int me_threshold;
    int intra_dc_precision;
    int loop_input;
    int loop_output;
    int qp_hist;

    int intra_only;
    int audio_sample_rate;
#define QSCALE_NONE -99999
    float audio_qscale;
    int audio_disable;
    int audio_channels;
    char  *audio_codec_name;
    int audio_codec_tag;
    char *audio_language;

    int subtitle_disable;
    char *subtitle_codec_name;
    char *subtitle_language;

    float mux_preload;
    float mux_max_delay;
    
    int thread_count;
} Context;

// Forward declarations
static int ffmpeg_encode(Context* ctx);
static void _finish(Context* ctx);
static int opt_output_file(Context* ctx, const char *filename);
                     
// Interface
ffmpeg_Context ffmpeg_createContext(ffmpeg_Callback cb, void* userData)
{
    Context* ctx = malloc(sizeof(Context));
    memset(ctx, 0, sizeof(Context));
    ctx->myCB = cb;
    ctx->myUserData = userData;
    
    // ints for ffmpeg vars
    ctx->audio_volume = 256;
    ctx->sws_flags = SWS_BICUBIC;
    ctx->bit_buffer_size = 1024*256;
    ctx->max_frames[0] = INT_MAX;
    ctx->max_frames[1] = INT_MAX;
    ctx->max_frames[2] = INT_MAX;
    ctx->max_frames[3] = INT_MAX;
    ctx->recording_time = INT64_MAX;
    ctx->dts_delta_threshold = 10;
    ctx->audio_drift_threshold = 0.1;
    ctx->video_sync_method = -1;
    ctx->padcolor[0] = 16;
    ctx->padcolor[1] = 128;
    ctx->padcolor[2] = 128;
    ctx->top_field_first = -1;
    ctx->intra_dc_precision = 8;
    ctx->loop_output = AVFMT_NOOUTPUTLOOP;
    ctx->audio_sample_rate = 44100;
    ctx->audio_qscale = QSCALE_NONE;
    ctx->audio_channels = 1;
    ctx->mux_preload = 0.5;
    ctx->mux_max_delay = 0.7;
    ctx->thread_count = 1;
    ctx->frame_pix_fmt = PIX_FMT_NONE;
    ctx->audio_sample_fmt = SAMPLE_FMT_NONE;
    return ctx;
}

void ffmpeg_destroyContext(ffmpeg_Context _ctx)
{
    _finish((Context*) _ctx);
    free(_ctx);
}

int ffmpeg_addInputFile(ffmpeg_Context _ctx, const char* filename)
{
    return -1;
}

int ffmpeg_addOutputFile(ffmpeg_Context _ctx, const char* filename)
{
    return opt_output_file((Context*) _ctx, filename);
}

void ffmpeg_setParam(ffmpeg_Context _ctx, const char* name, const char* value)
{
}

void ffmpeg_startEncode(ffmpeg_Context _ctx)
{
}

void ffmpeg_pauseEncode(ffmpeg_Context _ctx)
{
}

void ffmpeg_cancelEncode(ffmpeg_Context _ctx)
{
}

float ffmpeg_getProgress(ffmpeg_Context _ctx)
{
    return -1;
}

float ffmpeg_getFloatParam(ffmpeg_Context _ctx, const char* name)
{
    return -1;
}

const char* ffmpeg_getStringParam(ffmpeg_Context _ctx, const char* name)
{
    return "";
}

// internal structures
typedef struct AVOutputStream {
    int file_index;          /* file index */
    int index;               /* stream index in the output file */
    int source_index;        /* AVInputStream index */
    AVStream *st;            /* stream in the output file */
    int encoding_needed;     /* true if encoding needed for this stream */
    int frame_number;
    /* input pts and corresponding output pts
       for A/V sync */
    //double sync_ipts;        /* dts from the AVPacket of the demuxer in second units */
    struct AVInputStream *sync_ist; /* input stream to sync against */
    int64_t sync_opts;       /* output frame counter, could be changed to some true timestamp */ //FIXME look at frame_number
    /* video only */
    int video_resample;
    AVFrame pict_tmp;      /* temporary image for resampling */
    struct SwsContext *img_resample_ctx; /* for image resampling */
    int resample_height;

    int video_crop;
    int topBand;             /* cropping area sizes */
    int leftBand;

    int video_pad;
    int padtop;              /* padding area sizes */
    int padbottom;
    int padleft;
    int padright;

    /* audio only */
    int audio_resample;
    ReSampleContext *resample; /* for audio resampling */
    int reformat_pair;
    AVAudioConvert *reformat_ctx;
    AVFifoBuffer fifo;     /* for compression: one audio fifo per codec */
    FILE *logfile;
} AVOutputStream;

typedef struct AVInputStream {
    int file_index;
    int index;
    AVStream *st;
    int discard;             /* true if stream data should be discarded */
    int decoding_needed;     /* true if the packets must be decoded in 'raw_fifo' */
    int64_t sample_index;      /* current sample */

    int64_t       start;     /* time when read started */
    unsigned long frame;     /* current frame */
    int64_t       next_pts;  /* synthetic pts for cases where pkt.pts
                                is not defined */
    int64_t       pts;       /* current pts */
    int is_start;            /* is 1 at the start and after a discontinuity */
} AVInputStream;

typedef struct AVInputFile {
    int eof_reached;      /* true if eof reached */
    int ist_index;        /* index of first stream in ist_table */
    int buffer_size;      /* current total buffer size */
    int nb_streams;       /* nb streams we are aware of */
} AVInputFile;

#define MAKE_SFMT_PAIR(a,b) ((a)+SAMPLE_FMT_NB*(b))
#define DEFAULT_PASS_LOGFILENAME "ffmpeg2pass"
#define MAX_AUDIO_PACKET_SIZE (128 * 1024)

// Implementation
static int stream_index_from_inputs(AVFormatContext **input_files,
                                    int nb_input_files,
                                    AVInputFile *file_table,
                                    AVInputStream **ist_table,
                                    enum CodecType type,
                                    int programid)
{
    int p, q, z;
    for(z=0; z<nb_input_files; z++) {
        AVFormatContext *ic = input_files[z];
        for(p=0; p<ic->nb_programs; p++) {
            AVProgram *program = ic->programs[p];
            if(program->id != programid)
                continue;
            for(q=0; q<program->nb_stream_indexes; q++) {
                int sidx = program->stream_index[q];
                int ris = file_table[z].ist_index + sidx;
                if(ist_table[ris]->discard && ic->streams[sidx]->codec->codec_type == type)
                    return ris;
            }
        }
    }

    return -1;
}

static int decode_interrupt_cb(void)
{
    return 0; //q_pressed || (q_pressed = read_key() == 'q');
}

static void print_sdp(AVFormatContext **avc, int n)
{
    char sdp[2048];

    avf_sdp_create(avc, n, sdp, sizeof(sdp));
    printf("SDP:\n%s\n", sdp);
    fflush(stdout);
}

static int read_ffserver_streams(Context* ctx, AVFormatContext *s, const char *filename)
{
    int i, err;
    AVFormatContext *ic;
    int nopts = 0;

    err = av_open_input_file(&ic, filename, NULL, FFM_PACKET_SIZE, NULL);
    if (err < 0)
        return err;
    /* copy stream format */
    s->nb_streams = ic->nb_streams;
    for(i=0;i<ic->nb_streams;i++) {
        AVStream *st;

        // FIXME: a more elegant solution is needed
        st = av_mallocz(sizeof(AVStream));
        memcpy(st, ic->streams[i], sizeof(AVStream));
        st->codec = avcodec_alloc_context();
        memcpy(st->codec, ic->streams[i]->codec, sizeof(AVCodecContext));
        s->streams[i] = st;

        if (st->codec->codec_type == CODEC_TYPE_AUDIO && ctx->audio_stream_copy)
            st->stream_copy = 1;
        else if (st->codec->codec_type == CODEC_TYPE_VIDEO && ctx->video_stream_copy)
            st->stream_copy = 1;

        if(!st->codec->thread_count)
            st->codec->thread_count = 1;
        if(st->codec->thread_count>1)
            avcodec_thread_init(st->codec, st->codec->thread_count);

        if(st->codec->flags & CODEC_FLAG_BITEXACT)
            nopts = 1;
    }

    if (!nopts)
        s->timestamp = av_gettime();

    av_close_input_file(ic);
    return 0;
}

static double
get_sync_ipts(const AVOutputStream *ost, int64_t start_time)
{
    const AVInputStream *ist = ost->sync_ist;
    return (double)(ist->pts - start_time)/AV_TIME_BASE;
}

static void write_frame(AVFormatContext *s, AVPacket *pkt, AVCodecContext *avctx, AVBitStreamFilterContext *bsfc){
    int ret;

    while(bsfc){
        AVPacket new_pkt= *pkt;
        int a= av_bitstream_filter_filter(bsfc, avctx, NULL,
                                          &new_pkt.data, &new_pkt.size,
                                          pkt->data, pkt->size,
                                          pkt->flags & PKT_FLAG_KEY);
        if(a>0){
            av_free_packet(pkt);
            new_pkt.destruct= av_destruct_packet;
        } else if(a<0){
            fprintf(stderr, "%s failed for stream %d, codec %s",
                    bsfc->filter->name, pkt->stream_index,
                    avctx->codec ? avctx->codec->name : "copy");
            print_error("", a);
        }
        *pkt= new_pkt;

        bsfc= bsfc->next;
    }

    ret= av_interleaved_write_frame(s, pkt);
    if(ret < 0){
        print_error("av_interleaved_write_frame()", ret);
        //av_exit(1);
    }
}

static void check_audio_video_sub_inputs(Context* ctx, int *has_video_ptr, int *has_audio_ptr,
                                         int *has_subtitle_ptr)
{
    int has_video, has_audio, has_subtitle, i, j;
    AVFormatContext *ic;

    has_video = 0;
    has_audio = 0;
    has_subtitle = 0;
    for(j=0;j<ctx->nb_input_files;j++) {
        ic = ctx->input_files[j];
        for(i=0;i<ic->nb_streams;i++) {
            AVCodecContext *enc = ic->streams[i]->codec;
            switch(enc->codec_type) {
            case CODEC_TYPE_AUDIO:
                has_audio = 1;
                break;
            case CODEC_TYPE_VIDEO:
                has_video = 1;
                break;
            case CODEC_TYPE_SUBTITLE:
                has_subtitle = 1;
                break;
            case CODEC_TYPE_DATA:
            case CODEC_TYPE_ATTACHMENT:
            case CODEC_TYPE_UNKNOWN:
                break;
            default:
                abort();
            }
        }
    }
    *has_video_ptr = has_video;
    *has_audio_ptr = has_audio;
    *has_subtitle_ptr = has_subtitle;
}

static enum CodecID find_codec_or_die(const char *name, int type, int encoder)
{
    const char *codec_string = encoder ? "encoder" : "decoder";
    AVCodec *codec;

    if(!name)
        return CODEC_ID_NONE;
    codec = encoder ?
        avcodec_find_encoder_by_name(name) :
        avcodec_find_decoder_by_name(name);
    if(!codec) {
        av_log(NULL, AV_LOG_ERROR, "Unknown %s '%s'\n", codec_string, name);
        return CODEC_ID_NONE;
    }
    if(codec->type != type) {
        av_log(NULL, AV_LOG_ERROR, "Invalid %s type '%s'\n", codec_string, name);
        return CODEC_ID_NONE;
    }
    return codec->id;
}

static void new_video_stream(Context* ctx, AVFormatContext *oc)
{
    AVStream *st;
    AVCodecContext *video_enc;
    int codec_id;

    st = av_new_stream(oc, oc->nb_streams);
    if (!st) {
        fprintf(stderr, "Could not alloc stream\n");
        //av_exit(1);
    }
    avcodec_get_context_defaults2(st->codec, CODEC_TYPE_VIDEO);
    ctx->bitstream_filters[ctx->nb_output_files][oc->nb_streams - 1]= ctx->video_bitstream_filters;
    ctx->video_bitstream_filters= NULL;

    if(ctx->thread_count>1)
        avcodec_thread_init(st->codec, ctx->thread_count);

    video_enc = st->codec;

    if(ctx->video_codec_tag)
        video_enc->codec_tag= ctx->video_codec_tag;

    if(   (ctx->video_global_header&1)
       || (ctx->video_global_header==0 && (oc->oformat->flags & AVFMT_GLOBALHEADER))){
        video_enc->flags |= CODEC_FLAG_GLOBAL_HEADER;
        avctx_opts[CODEC_TYPE_VIDEO]->flags|= CODEC_FLAG_GLOBAL_HEADER;
    }
    if(ctx->video_global_header&2){
        video_enc->flags2 |= CODEC_FLAG2_LOCAL_HEADER;
        avctx_opts[CODEC_TYPE_VIDEO]->flags2|= CODEC_FLAG2_LOCAL_HEADER;
    }

    if (ctx->video_stream_copy) {
        st->stream_copy = 1;
        video_enc->codec_type = CODEC_TYPE_VIDEO;
        video_enc->sample_aspect_ratio =
        st->sample_aspect_ratio = av_d2q(ctx->frame_aspect_ratio*ctx->frame_height/ctx->frame_width, 255);
    } else {
        const char *p;
        int i;
        AVCodec *codec;
        AVRational fps= ctx->frame_rate.num ? ctx->frame_rate : (AVRational){25,1};

        if (ctx->video_codec_name) {
            codec_id = find_codec_or_die(ctx->video_codec_name, CODEC_TYPE_VIDEO, 1);
            codec = avcodec_find_encoder_by_name(ctx->video_codec_name);
            ctx->output_codecs[ctx->nb_ocodecs] = codec;
        } else {
            codec_id = av_guess_codec(oc->oformat, NULL, oc->filename, NULL, CODEC_TYPE_VIDEO);
            codec = avcodec_find_encoder(codec_id);
        }

        video_enc->codec_id = codec_id;

        set_context_opts(video_enc, avctx_opts[CODEC_TYPE_VIDEO], AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM);

        if (codec && codec->supported_framerates && !ctx->force_fps)
            fps = codec->supported_framerates[av_find_nearest_q_idx(fps, codec->supported_framerates)];
        video_enc->time_base.den = fps.num;
        video_enc->time_base.num = fps.den;

        video_enc->width = ctx->frame_width + ctx->frame_padright + ctx->frame_padleft;
        video_enc->height = ctx->frame_height + ctx->frame_padtop + ctx->frame_padbottom;
        video_enc->sample_aspect_ratio = av_d2q(ctx->frame_aspect_ratio*video_enc->height/video_enc->width, 255);
        video_enc->pix_fmt = ctx->frame_pix_fmt;
        st->sample_aspect_ratio = video_enc->sample_aspect_ratio;

        if(codec && codec->pix_fmts){
            const enum PixelFormat *p= codec->pix_fmts;
            for(; *p!=-1; p++){
                if(*p == video_enc->pix_fmt)
                    break;
            }
            if(*p == -1)
                video_enc->pix_fmt = codec->pix_fmts[0];
        }

        if (ctx->intra_only)
            video_enc->gop_size = 0;
        if (ctx->video_qscale || ctx->same_quality) {
            video_enc->flags |= CODEC_FLAG_QSCALE;
            video_enc->global_quality = st->quality = FF_QP2LAMBDA * ctx->video_qscale;
        }

        if(ctx->intra_matrix)
            video_enc->intra_matrix = ctx->intra_matrix;
        if(ctx->inter_matrix)
            video_enc->inter_matrix = ctx->inter_matrix;

        video_enc->thread_count = ctx->thread_count;
        p= ctx->video_rc_override_string;
        for(i=0; p; i++){
            int start, end, q;
            int e=sscanf(p, "%d,%d,%d", &start, &end, &q);
            if(e!=3){
                fprintf(stderr, "error parsing rc_override\n");
                return; //av_exit(1);
            }
            video_enc->rc_override=
                av_realloc(video_enc->rc_override,
                           sizeof(RcOverride)*(i+1));
            video_enc->rc_override[i].start_frame= start;
            video_enc->rc_override[i].end_frame  = end;
            if(q>0){
                video_enc->rc_override[i].qscale= q;
                video_enc->rc_override[i].quality_factor= 1.0;
            }
            else{
                video_enc->rc_override[i].qscale= 0;
                video_enc->rc_override[i].quality_factor= -q/100.0;
            }
            p= strchr(p, '/');
            if(p) p++;
        }
        video_enc->rc_override_count=i;
        if (!video_enc->rc_initial_buffer_occupancy)
            video_enc->rc_initial_buffer_occupancy = video_enc->rc_buffer_size*3/4;
        video_enc->me_threshold= me_threshold;
        video_enc->intra_dc_precision= intra_dc_precision - 8;

        if (do_psnr)
            video_enc->flags|= CODEC_FLAG_PSNR;

        /* two pass mode */
        if (do_pass) {
            if (do_pass == 1) {
                video_enc->flags |= CODEC_FLAG_PASS1;
            } else {
                video_enc->flags |= CODEC_FLAG_PASS2;
            }
        }
    }
    nb_ocodecs++;

    /* reset some key parameters */
    video_disable = 0;
    av_freep(&video_codec_name);
    video_stream_copy = 0;
}

static void new_audio_stream(Context* ctx, AVFormatContext *oc)
{
    AVStream *st;
    AVCodecContext *audio_enc;
    int codec_id;

    st = av_new_stream(oc, oc->nb_streams);
    if (!st) {
        fprintf(stderr, "Could not alloc stream\n");
        av_exit(1);
    }
    avcodec_get_context_defaults2(st->codec, CODEC_TYPE_AUDIO);

    bitstream_filters[nb_output_files][oc->nb_streams - 1]= audio_bitstream_filters;
    audio_bitstream_filters= NULL;

    if(thread_count>1)
        avcodec_thread_init(st->codec, thread_count);

    audio_enc = st->codec;
    audio_enc->codec_type = CODEC_TYPE_AUDIO;

    if(audio_codec_tag)
        audio_enc->codec_tag= audio_codec_tag;

    if (oc->oformat->flags & AVFMT_GLOBALHEADER) {
        audio_enc->flags |= CODEC_FLAG_GLOBAL_HEADER;
        avctx_opts[CODEC_TYPE_AUDIO]->flags|= CODEC_FLAG_GLOBAL_HEADER;
    }
    if (audio_stream_copy) {
        st->stream_copy = 1;
        audio_enc->channels = audio_channels;
    } else {
        AVCodec *codec;

        set_context_opts(audio_enc, avctx_opts[CODEC_TYPE_AUDIO], AV_OPT_FLAG_AUDIO_PARAM | AV_OPT_FLAG_ENCODING_PARAM);

        if (audio_codec_name) {
            codec_id = find_codec_or_die(audio_codec_name, CODEC_TYPE_AUDIO, 1);
            codec = avcodec_find_encoder_by_name(audio_codec_name);
            output_codecs[nb_ocodecs] = codec;
        } else {
            codec_id = av_guess_codec(oc->oformat, NULL, oc->filename, NULL, CODEC_TYPE_AUDIO);
            codec = avcodec_find_encoder(codec_id);
        }
        audio_enc->codec_id = codec_id;

        if (audio_qscale > QSCALE_NONE) {
            audio_enc->flags |= CODEC_FLAG_QSCALE;
            audio_enc->global_quality = st->quality = FF_QP2LAMBDA * audio_qscale;
        }
        audio_enc->thread_count = thread_count;
        audio_enc->channels = audio_channels;
        audio_enc->sample_fmt = audio_sample_fmt;

        if(codec && codec->sample_fmts){
            const enum SampleFormat *p= codec->sample_fmts;
            for(; *p!=-1; p++){
                if(*p == audio_enc->sample_fmt)
                    break;
            }
            if(*p == -1)
                audio_enc->sample_fmt = codec->sample_fmts[0];
        }
    }
    nb_ocodecs++;
    audio_enc->sample_rate = audio_sample_rate;
    audio_enc->time_base= (AVRational){1, audio_sample_rate};
    if (audio_language) {
        av_strlcpy(st->language, audio_language, sizeof(st->language));
        av_free(audio_language);
        audio_language = NULL;
    }

    /* reset some key parameters */
    audio_disable = 0;
    av_freep(&audio_codec_name);
    audio_stream_copy = 0;
}

static void new_subtitle_stream(Context* ctx, AVFormatContext *oc)
{
    AVStream *st;
    AVCodecContext *subtitle_enc;

    st = av_new_stream(oc, oc->nb_streams);
    if (!st) {
        fprintf(stderr, "Could not alloc stream\n");
        av_exit(1);
    }
    avcodec_get_context_defaults2(st->codec, CODEC_TYPE_SUBTITLE);

    bitstream_filters[nb_output_files][oc->nb_streams - 1]= subtitle_bitstream_filters;
    subtitle_bitstream_filters= NULL;

    subtitle_enc = st->codec;
    subtitle_enc->codec_type = CODEC_TYPE_SUBTITLE;
    if (subtitle_stream_copy) {
        st->stream_copy = 1;
    } else {
        set_context_opts(avctx_opts[CODEC_TYPE_SUBTITLE], subtitle_enc, AV_OPT_FLAG_SUBTITLE_PARAM | AV_OPT_FLAG_ENCODING_PARAM);
        subtitle_enc->codec_id = find_codec_or_die(subtitle_codec_name, CODEC_TYPE_SUBTITLE, 1);
        output_codecs[nb_ocodecs] = avcodec_find_encoder_by_name(subtitle_codec_name);
    }
    nb_ocodecs++;

    if (subtitle_language) {
        av_strlcpy(st->language, subtitle_language, sizeof(st->language));
        av_free(subtitle_language);
        subtitle_language = NULL;
    }

    subtitle_disable = 0;
    av_freep(&subtitle_codec_name);
    subtitle_stream_copy = 0;
}

static int do_audio_out(Context* ctx, AVFormatContext *s,
                         AVOutputStream *ost,
                         AVInputStream *ist,
                         unsigned char *buf, int size)
{
    uint8_t *buftmp;
    static uint8_t *audio_buf = NULL;
    static uint8_t *audio_out = NULL;
    static uint8_t *audio_out2 = NULL;
    const int audio_out_size= 4*MAX_AUDIO_PACKET_SIZE;

    int size_out, frame_bytes, ret;
    AVCodecContext *enc= ost->st->codec;
    AVCodecContext *dec= ist->st->codec;
    int osize= av_get_bits_per_sample_format(enc->sample_fmt)/8;
    int isize= av_get_bits_per_sample_format(dec->sample_fmt)/8;

    /* SC: dynamic allocation of buffers */
    if (!audio_buf)
        audio_buf = av_malloc(2*MAX_AUDIO_PACKET_SIZE);
    if (!audio_out)
        audio_out = av_malloc(audio_out_size);
    if (!audio_buf || !audio_out)
        return 1;               /* Should signal an error ! */

    if (enc->channels != dec->channels)
        ost->audio_resample = 1;

    if (ost->audio_resample && !ost->resample) {
        if (dec->sample_fmt != SAMPLE_FMT_S16) {
            fprintf(stderr, "Audio resampler only works with 16 bits per sample, patch welcome.\n");
            return -1;
        }
        ost->resample = audio_resample_init(enc->channels,    dec->channels,
                                            enc->sample_rate, dec->sample_rate);
        if (!ost->resample) {
            fprintf(stderr, "Can not resample %d channels @ %d Hz to %d channels @ %d Hz\n",
                    dec->channels, dec->sample_rate,
                    enc->channels, enc->sample_rate);
            return -1;
        }
    }

#define MAKE_SFMT_PAIR(a,b) ((a)+SAMPLE_FMT_NB*(b))
    if (dec->sample_fmt!=enc->sample_fmt &&
        MAKE_SFMT_PAIR(enc->sample_fmt,dec->sample_fmt)!=ost->reformat_pair) {
        if (!audio_out2)
            audio_out2 = av_malloc(audio_out_size);
        if (!audio_out2)
            return -1;
        if (ost->reformat_ctx)
            av_audio_convert_free(ost->reformat_ctx);
        ost->reformat_ctx = av_audio_convert_alloc(enc->sample_fmt, 1,
                                                   dec->sample_fmt, 1, NULL, 0);
        if (!ost->reformat_ctx) {
            fprintf(stderr, "Cannot convert %s sample format to %s sample format\n",
                avcodec_get_sample_fmt_name(dec->sample_fmt),
                avcodec_get_sample_fmt_name(enc->sample_fmt));
            return -1;
        }
        ost->reformat_pair=MAKE_SFMT_PAIR(enc->sample_fmt,dec->sample_fmt);
    }

    if(ctx->audio_sync_method){
        double delta = get_sync_ipts(ost, ctx->start_time) * enc->sample_rate - ost->sync_opts
                - av_fifo_size(&ost->fifo)/(ost->st->codec->channels * 2);
        double idelta= delta*ist->st->codec->sample_rate / enc->sample_rate;
        int byte_delta= ((int)idelta)*2*ist->st->codec->channels;

        //FIXME resample delay
        if(fabs(delta) > 50){
            if(ist->is_start || fabs(delta) > ctx->audio_drift_threshold*enc->sample_rate){
                if(byte_delta < 0){
                    byte_delta= FFMAX(byte_delta, -size);
                    size += byte_delta;
                    buf  -= byte_delta;
                    if(!size)
                        return 1;
                    ist->is_start=0;
                }else{
                    static uint8_t *input_tmp= NULL;
                    input_tmp= av_realloc(input_tmp, byte_delta + size);

                    if(byte_delta + size <= MAX_AUDIO_PACKET_SIZE)
                        ist->is_start=0;
                    else
                        byte_delta= MAX_AUDIO_PACKET_SIZE - size;

                    memset(input_tmp, 0, byte_delta);
                    memcpy(input_tmp + byte_delta, buf, size);
                    buf= input_tmp;
                    size += byte_delta;
                }
            } else if(ctx->audio_sync_method>1){
                int comp= av_clip(delta, -ctx->audio_sync_method, ctx->audio_sync_method);
                assert(ost->audio_resample);
                av_resample_compensate(*(struct AVResampleContext**)ost->resample, comp, enc->sample_rate);
            }
        }
    }else
        ost->sync_opts= lrintf(get_sync_ipts(ost, ctx->start_time) * enc->sample_rate)
                        - av_fifo_size(&ost->fifo)/(ost->st->codec->channels * 2); //FIXME wrong

    if (ost->audio_resample) {
        buftmp = audio_buf;
        size_out = audio_resample(ost->resample,
                                  (short *)buftmp, (short *)buf,
                                  size / (ist->st->codec->channels * isize));
        size_out = size_out * enc->channels * osize;
    } else {
        buftmp = buf;
        size_out = size;
    }

    if (dec->sample_fmt!=enc->sample_fmt) {
        const void *ibuf[6]= {buftmp};
        void *obuf[6]= {audio_out2};
        int istride[6]= {isize};
        int ostride[6]= {osize};
        int len= size_out/istride[0];
        if (av_audio_convert(ost->reformat_ctx, obuf, ostride, ibuf, istride, len)<0) {
            printf("av_audio_convert() failed\n");
            return 1;
        }
        buftmp = audio_out2;
        size_out = len*osize;
    }

    /* now encode as many frames as possible */
    if (enc->frame_size > 1) {
        /* output resampled raw samples */
        if (av_fifo_realloc2(&ost->fifo, av_fifo_size(&ost->fifo) + size_out) < 0) {
            fprintf(stderr, "av_fifo_realloc2() failed\n");
            return -1;
        }
        av_fifo_generic_write(&ost->fifo, buftmp, size_out, NULL);

        frame_bytes = enc->frame_size * osize * enc->channels;

        while (av_fifo_size(&ost->fifo) >= frame_bytes) {
            AVPacket pkt;
            av_init_packet(&pkt);

            av_fifo_read(&ost->fifo, audio_buf, frame_bytes);

            //FIXME pass ost->sync_opts as AVFrame.pts in avcodec_encode_audio()

            ret = avcodec_encode_audio(enc, audio_out, audio_out_size,
                                       (short *)audio_buf);
            ctx->audio_size += ret;
            pkt.stream_index= ost->index;
            pkt.data= audio_out;
            pkt.size= ret;
            if(enc->coded_frame && enc->coded_frame->pts != AV_NOPTS_VALUE)
                pkt.pts= av_rescale_q(enc->coded_frame->pts, enc->time_base, ost->st->time_base);
            pkt.flags |= PKT_FLAG_KEY;
            write_frame(s, &pkt, ost->st->codec, ctx->bitstream_filters[ost->file_index][pkt.stream_index]);

            ost->sync_opts += enc->frame_size;
        }
    } else {
        AVPacket pkt;
        int coded_bps = av_get_bits_per_sample(enc->codec->id)/8;
        av_init_packet(&pkt);

        ost->sync_opts += size_out / (osize * enc->channels);

        /* output a pcm frame */
        /* determine the size of the coded buffer */
        size_out /= osize;
        if (coded_bps)
            size_out *= coded_bps;

        //FIXME pass ost->sync_opts as AVFrame.pts in avcodec_encode_audio()
        ret = avcodec_encode_audio(enc, audio_out, size_out,
                                   (short *)buftmp);
        ctx->audio_size += ret;
        pkt.stream_index= ost->index;
        pkt.data= audio_out;
        pkt.size= ret;
        if(enc->coded_frame && enc->coded_frame->pts != AV_NOPTS_VALUE)
            pkt.pts= av_rescale_q(enc->coded_frame->pts, enc->time_base, ost->st->time_base);
        pkt.flags |= PKT_FLAG_KEY;
        write_frame(s, &pkt, ost->st->codec, ctx->bitstream_filters[ost->file_index][pkt.stream_index]);
    }
    
    return 1;
}

static void pre_process_video_frame(Context* ctx, AVInputStream *ist, AVPicture *picture, void **bufp)
{
    AVCodecContext *dec;
    AVPicture *picture2;
    AVPicture picture_tmp;
    uint8_t *buf = 0;

    dec = ist->st->codec;

    /* deinterlace : must be done before any resize */
    if (ctx->do_deinterlace) {
        int size;

        /* create temporary picture */
        size = avpicture_get_size(dec->pix_fmt, dec->width, dec->height);
        buf = av_malloc(size);
        if (!buf)
            return;

        picture2 = &picture_tmp;
        avpicture_fill(picture2, buf, dec->pix_fmt, dec->width, dec->height);

        if (ctx->do_deinterlace){
            if(avpicture_deinterlace(picture2, picture,
                                     dec->pix_fmt, dec->width, dec->height) < 0) {
                /* if error, do not deinterlace */
                fprintf(stderr, "Deinterlacing failed\n");
                av_free(buf);
                buf = NULL;
                picture2 = picture;
            }
        } else {
            av_picture_copy(picture2, picture, dec->pix_fmt, dec->width, dec->height);
        }
    } else {
        picture2 = picture;
    }

    if (picture != picture2)
        *picture = *picture2;
    *bufp = buf;
}

static void do_video_out(Context* ctx, AVFormatContext *s,
                         AVOutputStream *ost,
                         AVInputStream *ist,
                         AVFrame *in_picture,
                         int *frame_size)
{
    int nb_frames, i, ret;
    AVFrame *final_picture, *formatted_picture, *resampling_dst, *padding_src;
    AVFrame picture_crop_temp, picture_pad_temp;
    AVCodecContext *enc, *dec;

    avcodec_get_frame_defaults(&picture_crop_temp);
    avcodec_get_frame_defaults(&picture_pad_temp);

    enc = ost->st->codec;
    dec = ist->st->codec;

    /* by default, we output a single frame */
    nb_frames = 1;

    *frame_size = 0;

    if(ctx->video_sync_method>0 || (ctx->video_sync_method && av_q2d(enc->time_base) > 0.001)){
        double vdelta;
        vdelta = get_sync_ipts(ost, ctx->start_time) / av_q2d(enc->time_base) - ost->sync_opts;
        //FIXME set to 0.5 after we fix some dts/pts bugs like in avidec.c
        if (vdelta < -1.1)
            nb_frames = 0;
        else if (ctx->video_sync_method == 2)
            ost->sync_opts= lrintf(get_sync_ipts(ost, ctx->start_time) / av_q2d(enc->time_base));
        else if (vdelta > 1.1)
            nb_frames = lrintf(vdelta);
//fprintf(stderr, "vdelta:%f, ost->sync_opts:%"PRId64", ost->sync_ipts:%f nb_frames:%d\n", vdelta, ost->sync_opts, ost->sync_ipts, nb_frames);
        if (nb_frames == 0){
            ++ctx->nb_frames_drop;
        }else if (nb_frames > 1) {
            ctx->nb_frames_dup += nb_frames;
        }
    }else
        ost->sync_opts= lrintf(get_sync_ipts(ost, ctx->start_time) / av_q2d(enc->time_base));

    nb_frames= FFMIN(nb_frames, ctx->max_frames[CODEC_TYPE_VIDEO] - ost->frame_number);
    if (nb_frames <= 0)
        return;

    if (ost->video_crop) {
        if (av_picture_crop((AVPicture *)&picture_crop_temp, (AVPicture *)in_picture, dec->pix_fmt, ost->topBand, ost->leftBand) < 0) {
            av_log(NULL, AV_LOG_ERROR, "error cropping picture\n");
            return;
        }
        formatted_picture = &picture_crop_temp;
    } else {
        formatted_picture = in_picture;
    }

    final_picture = formatted_picture;
    padding_src = formatted_picture;
    resampling_dst = &ost->pict_tmp;
    if (ost->video_pad) {
        final_picture = &ost->pict_tmp;
        if (ost->video_resample) {
            if (av_picture_crop((AVPicture *)&picture_pad_temp, (AVPicture *)final_picture, enc->pix_fmt, ost->padtop, ost->padleft) < 0) {
                av_log(NULL, AV_LOG_ERROR, "error padding picture\n");
                return;
            }
            resampling_dst = &picture_pad_temp;
        }
    }

    if (ost->video_resample) {
        padding_src = NULL;
        final_picture = &ost->pict_tmp;
        sws_scale(ost->img_resample_ctx, formatted_picture->data, formatted_picture->linesize,
              0, ost->resample_height, resampling_dst->data, resampling_dst->linesize);
    }

    if (ost->video_pad) {
        av_picture_pad((AVPicture*)final_picture, (AVPicture *)padding_src,
                enc->height, enc->width, enc->pix_fmt,
                ost->padtop, ost->padbottom, ost->padleft, ost->padright, ctx->padcolor);
    }

    /* duplicates frame if needed */
    for(i=0;i<nb_frames;i++) {
        AVPacket pkt;
        av_init_packet(&pkt);
        pkt.stream_index= ost->index;

        if (s->oformat->flags & AVFMT_RAWPICTURE) {
            /* raw pictures are written as AVPicture structure to
               avoid any copies. We support temorarily the older
               method. */
            AVFrame* old_frame = enc->coded_frame;
            enc->coded_frame = dec->coded_frame; //FIXME/XXX remove this hack
            pkt.data= (uint8_t *)final_picture;
            pkt.size=  sizeof(AVPicture);
            pkt.pts= av_rescale_q(ost->sync_opts, enc->time_base, ost->st->time_base);
            pkt.flags |= PKT_FLAG_KEY;

            write_frame(s, &pkt, ost->st->codec, ctx->bitstream_filters[ost->file_index][pkt.stream_index]);
            enc->coded_frame = old_frame;
        } else {
            AVFrame big_picture;

            big_picture= *final_picture;
            /* better than nothing: use input picture interlaced
               settings */
            big_picture.interlaced_frame = in_picture->interlaced_frame;
            if(avctx_opts[CODEC_TYPE_VIDEO]->flags & (CODEC_FLAG_INTERLACED_DCT|CODEC_FLAG_INTERLACED_ME)){
                if(ctx->top_field_first == -1)
                    big_picture.top_field_first = in_picture->top_field_first;
                else
                    big_picture.top_field_first = ctx->top_field_first;
            }

            /* handles sameq here. This is not correct because it may
               not be a global option */
            if (ctx->same_quality) {
                big_picture.quality = ist->st->quality;
            }else
                big_picture.quality = ost->st->quality;
            if(!ctx->me_threshold)
                big_picture.pict_type = 0;
//            big_picture.pts = AV_NOPTS_VALUE;
            big_picture.pts= ost->sync_opts;
//            big_picture.pts= av_rescale(ost->sync_opts, AV_TIME_BASE*(int64_t)enc->time_base.num, enc->time_base.den);
//av_log(NULL, AV_LOG_DEBUG, "%"PRId64" -> encoder\n", ost->sync_opts);
            ret = avcodec_encode_video(enc,
                                       ctx->bit_buffer, ctx->bit_buffer_size,
                                       &big_picture);
            if (ret == -1) {
                fprintf(stderr, "Video encoding failed\n");
                //av_exit(1);
            }
            //enc->frame_number = enc->real_pict_num;
            if(ret>0){
                pkt.data= ctx->bit_buffer;
                pkt.size= ret;
                if(enc->coded_frame->pts != AV_NOPTS_VALUE)
                    pkt.pts= av_rescale_q(enc->coded_frame->pts, enc->time_base, ost->st->time_base);
/*av_log(NULL, AV_LOG_DEBUG, "encoder -> %"PRId64"/%"PRId64"\n",
   pkt.pts != AV_NOPTS_VALUE ? av_rescale(pkt.pts, enc->time_base.den, AV_TIME_BASE*(int64_t)enc->time_base.num) : -1,
   pkt.dts != AV_NOPTS_VALUE ? av_rescale(pkt.dts, enc->time_base.den, AV_TIME_BASE*(int64_t)enc->time_base.num) : -1);*/

                if(enc->coded_frame->key_frame)
                    pkt.flags |= PKT_FLAG_KEY;
                write_frame(s, &pkt, ost->st->codec, ctx->bitstream_filters[ost->file_index][pkt.stream_index]);
                *frame_size = ret;
                ctx->video_size += ret;
                //fprintf(stderr,"\nFrame: %3d %3d size: %5d type: %d",
                //        enc->frame_number-1, enc->real_pict_num, ret,
                //        enc->pict_type);
                /* if two pass, output log */
                if (ost->logfile && enc->stats_out) {
                    fprintf(ost->logfile, "%s", enc->stats_out);
                }
            }
        }
        ost->sync_opts++;
        ost->frame_number++;
    }
}

static double psnr(double d){
    return -10.0*log(d)/log(10.0);
}

static void do_video_stats(Context* ctx, AVFormatContext *os, AVOutputStream *ost,
                           int frame_size)
{
    AVCodecContext *enc;
    int frame_number;
    double ti1, bitrate, avg_bitrate;

    /* this is executed just the first time do_video_stats is called */
    if (!ctx->vstats_file) {
        ctx->vstats_file = fopen(ctx->vstats_filename, "w");
        if (!ctx->vstats_file) {
            perror("fopen");
            //av_exit(1);
        }
    }

    enc = ost->st->codec;
    if (enc->codec_type == CODEC_TYPE_VIDEO) {
        frame_number = ost->frame_number;
        fprintf(ctx->vstats_file, "frame= %5d q= %2.1f ", frame_number, enc->coded_frame->quality/(float)FF_QP2LAMBDA);
        if (enc->flags&CODEC_FLAG_PSNR)
            fprintf(ctx->vstats_file, "PSNR= %6.2f ", psnr(enc->coded_frame->error[0]/(enc->width*enc->height*255.0*255.0)));

        fprintf(ctx->vstats_file,"f_size= %6d ", frame_size);
        /* compute pts value */
        ti1 = ost->sync_opts * av_q2d(enc->time_base);
        if (ti1 < 0.01)
            ti1 = 0.01;

        bitrate = (frame_size * 8) / av_q2d(enc->time_base) / 1000.0;
        avg_bitrate = (double)(ctx->video_size * 8) / ti1 / 1000.0;
        fprintf(ctx->vstats_file, "s_size= %8.0fkB time= %0.3f br= %7.1fkbits/s avg_br= %7.1fkbits/s ",
            (double) ctx->video_size / 1024, ti1, bitrate, avg_bitrate);
        fprintf(ctx->vstats_file,"type= %c\n", av_get_pict_type_char(enc->coded_frame->pict_type));
    }
}

static void do_subtitle_out(Context* ctx, AVFormatContext *s,
                            AVOutputStream *ost,
                            AVInputStream *ist,
                            AVSubtitle *sub,
                            int64_t pts)
{
    static uint8_t *subtitle_out = NULL;
    int subtitle_out_max_size = 65536;
    int subtitle_out_size, nb, i;
    AVCodecContext *enc;
    AVPacket pkt;

    if (pts == AV_NOPTS_VALUE) {
        fprintf(stderr, "Subtitle packets must have a pts\n");
        return;
    }

    enc = ost->st->codec;

    if (!subtitle_out) {
        subtitle_out = av_malloc(subtitle_out_max_size);
    }

    /* Note: DVB subtitle need one packet to draw them and one other
       packet to clear them */
    /* XXX: signal it in the codec context ? */
    if (enc->codec_id == CODEC_ID_DVB_SUBTITLE)
        nb = 2;
    else
        nb = 1;

    for(i = 0; i < nb; i++) {
        subtitle_out_size = avcodec_encode_subtitle(enc, subtitle_out,
                                                    subtitle_out_max_size, sub);

        av_init_packet(&pkt);
        pkt.stream_index = ost->index;
        pkt.data = subtitle_out;
        pkt.size = subtitle_out_size;
        pkt.pts = av_rescale_q(pts, ist->st->time_base, ost->st->time_base);
        if (enc->codec_id == CODEC_ID_DVB_SUBTITLE) {
            /* XXX: the pts correction is handled here. Maybe handling
               it in the codec would be better */
            if (i == 0)
                pkt.pts += 90 * sub->start_display_time;
            else
                pkt.pts += 90 * sub->end_display_time;
        }
        write_frame(s, &pkt, ost->st->codec, ctx->bitstream_filters[ost->file_index][pkt.stream_index]);
    }
}

/* pkt = NULL means EOF (needed to flush decoder buffers) */
static int output_packet(Context* ctx, AVInputStream *ist, int ist_index,
                         AVOutputStream **ost_table, int nb_ostreams,
                         const AVPacket *pkt)
{
    AVFormatContext *os;
    AVOutputStream *ost;
    uint8_t *ptr;
    int len, ret, i;
    uint8_t *data_buf;
    int data_size, got_picture;
    AVFrame picture;
    void *buffer_to_free;
    static unsigned int samples_size= 0;
    static short *samples= NULL;
    AVSubtitle subtitle, *subtitle_to_free;
    int got_subtitle;

    if(ist->next_pts == AV_NOPTS_VALUE)
        ist->next_pts= ist->pts;

    if (pkt == NULL) {
        /* EOF handling */
        ptr = NULL;
        len = 0;
        goto handle_eof;
    }

    if(pkt->dts != AV_NOPTS_VALUE)
        ist->next_pts = ist->pts = av_rescale_q(pkt->dts, ist->st->time_base, AV_TIME_BASE_Q);

    len = pkt->size;
    ptr = pkt->data;

    //while we have more to decode or while the decoder did output something on EOF
    while (len > 0 || (!pkt && ist->next_pts != ist->pts)) {
    handle_eof:
        ist->pts= ist->next_pts;

        /* decode the packet if needed */
        data_buf = NULL; /* fail safe */
        data_size = 0;
        subtitle_to_free = NULL;
        if (ist->decoding_needed) {
            switch(ist->st->codec->codec_type) {
            case CODEC_TYPE_AUDIO:{
                if(pkt && samples_size < FFMAX(pkt->size*sizeof(*samples), AVCODEC_MAX_AUDIO_FRAME_SIZE)) {
                    samples_size = FFMAX(pkt->size*sizeof(*samples), AVCODEC_MAX_AUDIO_FRAME_SIZE);
                    av_free(samples);
                    samples= av_malloc(samples_size);
                }
                data_size= samples_size;
                    /* XXX: could avoid copy if PCM 16 bits with same
                       endianness as CPU */
                ret = avcodec_decode_audio2(ist->st->codec, samples, &data_size,
                                           ptr, len);
                if (ret < 0)
                    goto fail_decode;
                ptr += ret;
                len -= ret;
                /* Some bug in mpeg audio decoder gives */
                /* data_size < 0, it seems they are overflows */
                if (data_size <= 0) {
                    /* no audio frame */
                    continue;
                }
                data_buf = (uint8_t *)samples;
                ist->next_pts += ((int64_t)AV_TIME_BASE/2 * data_size) /
                    (ist->st->codec->sample_rate * ist->st->codec->channels);
                break;}
            case CODEC_TYPE_VIDEO:
                    data_size = (ist->st->codec->width * ist->st->codec->height * 3) / 2;
                    /* XXX: allocate picture correctly */
                    avcodec_get_frame_defaults(&picture);

                    ret = avcodec_decode_video(ist->st->codec,
                                               &picture, &got_picture, ptr, len);
                    ist->st->quality= picture.quality;
                    if (ret < 0)
                        goto fail_decode;
                    if (!got_picture) {
                        /* no picture yet */
                        goto discard_packet;
                    }
                    if (ist->st->codec->time_base.num != 0) {
                        ist->next_pts += ((int64_t)AV_TIME_BASE *
                                          ist->st->codec->time_base.num) /
                            ist->st->codec->time_base.den;
                    }
                    len = 0;
                    break;
            case CODEC_TYPE_SUBTITLE:
                ret = avcodec_decode_subtitle(ist->st->codec,
                                              &subtitle, &got_subtitle, ptr, len);
                if (ret < 0)
                    goto fail_decode;
                if (!got_subtitle) {
                    goto discard_packet;
                }
                subtitle_to_free = &subtitle;
                len = 0;
                break;
            default:
                goto fail_decode;
            }
        } else {
            switch(ist->st->codec->codec_type) {
            case CODEC_TYPE_AUDIO:
                ist->next_pts += ((int64_t)AV_TIME_BASE * ist->st->codec->frame_size) /
                    ist->st->codec->sample_rate;
                break;
            case CODEC_TYPE_VIDEO:
                if (ist->st->codec->time_base.num != 0) {
                    ist->next_pts += ((int64_t)AV_TIME_BASE *
                                      ist->st->codec->time_base.num) /
                        ist->st->codec->time_base.den;
                }
                break;
            }
            data_buf = ptr;
            data_size = len;
            ret = len;
            len = 0;
        }

        buffer_to_free = NULL;
        if (ist->st->codec->codec_type == CODEC_TYPE_VIDEO) {
            pre_process_video_frame(ctx, ist, (AVPicture *)&picture,
                                    &buffer_to_free);
        }

        // preprocess audio (volume)
        if (ist->st->codec->codec_type == CODEC_TYPE_AUDIO) {
            if (ctx->audio_volume != 256) {
                short *volp;
                volp = samples;
                for(i=0;i<(data_size / sizeof(short));i++) {
                    int v = ((*volp) * ctx->audio_volume + 128) >> 8;
                    if (v < -32768) v = -32768;
                    if (v >  32767) v = 32767;
                    *volp++ = v;
                }
            }
        }

        /* frame rate emulation */
        if (ist->st->codec->rate_emu) {
            int64_t pts = av_rescale((int64_t) ist->frame * ist->st->codec->time_base.num, 1000000, ist->st->codec->time_base.den);
            int64_t now = av_gettime() - ist->start;
            if (pts > now)
                usleep(pts - now);

            ist->frame++;
        }

        /* if output time reached then transcode raw format,
           encode packets and output them */
        if (ctx->start_time == 0 || ist->pts >= ctx->start_time)
            for(i=0;i<nb_ostreams;i++) {
                int frame_size;

                ost = ost_table[i];
                if (ost->source_index == ist_index) {
                    os = ctx->output_files[ost->file_index];

#if 0
                    printf("%d: got pts=%0.3f %0.3f\n", i,
                           (double)pkt->pts / AV_TIME_BASE,
                           ((double)ist->pts / AV_TIME_BASE) -
                           ((double)ost->st->pts.val * ost->st->time_base.num / ost->st->time_base.den));
#endif
                    /* set the input output pts pairs */
                    //ost->sync_ipts = (double)(ist->pts + input_files_ts_offset[ist->file_index] - ctx->start_time)/ AV_TIME_BASE;

                    if (ost->encoding_needed) {
                        switch(ost->st->codec->codec_type) {
                        case CODEC_TYPE_AUDIO:
                            do_audio_out(ctx, os, ost, ist, data_buf, data_size);
                            break;
                        case CODEC_TYPE_VIDEO:
                            do_video_out(ctx, os, ost, ist, &picture, &frame_size);
                            if (ctx->vstats_filename && frame_size)
                                do_video_stats(ctx, os, ost, frame_size);
                            break;
                        case CODEC_TYPE_SUBTITLE:
                            do_subtitle_out(ctx, os, ost, ist, &subtitle,
                                            pkt->pts);
                            break;
                        default:
                            abort();
                        }
                    } else {
                        AVFrame avframe; //FIXME/XXX remove this
                        AVPacket opkt;
                        av_init_packet(&opkt);

                        if (!ost->frame_number && !(pkt->flags & PKT_FLAG_KEY))
                            continue;

                        /* no reencoding needed : output the packet directly */
                        /* force the input stream PTS */

                        avcodec_get_frame_defaults(&avframe);
                        ost->st->codec->coded_frame= &avframe;
                        avframe.key_frame = pkt->flags & PKT_FLAG_KEY;

                        if(ost->st->codec->codec_type == CODEC_TYPE_AUDIO)
                            ctx->audio_size += data_size;
                        else if (ost->st->codec->codec_type == CODEC_TYPE_VIDEO) {
                            ctx->video_size += data_size;
                            ost->sync_opts++;
                        }

                        opkt.stream_index= ost->index;
                        if(pkt->pts != AV_NOPTS_VALUE)
                            opkt.pts= av_rescale_q(pkt->pts, ist->st->time_base, ost->st->time_base);
                        else
                            opkt.pts= AV_NOPTS_VALUE;

                        if (pkt->dts == AV_NOPTS_VALUE)
                            opkt.dts = av_rescale_q(ist->pts, AV_TIME_BASE_Q, ost->st->time_base);
                        else
                            opkt.dts = av_rescale_q(pkt->dts, ist->st->time_base, ost->st->time_base);

                        opkt.duration = av_rescale_q(pkt->duration, ist->st->time_base, ost->st->time_base);
                        opkt.flags= pkt->flags;

                        //FIXME remove the following 2 lines they shall be replaced by the bitstream filters
                        if(av_parser_change(ist->st->parser, ost->st->codec, &opkt.data, &opkt.size, data_buf, data_size, pkt->flags & PKT_FLAG_KEY))
                            opkt.destruct= av_destruct_packet;

                        write_frame(os, &opkt, ost->st->codec, ctx->bitstream_filters[ost->file_index][opkt.stream_index]);
                        ost->st->codec->frame_number++;
                        ost->frame_number++;
                        av_free_packet(&opkt);
                    }
                }
            }
        av_free(buffer_to_free);
        /* XXX: allocate the subtitles in the codec ? */
        if (subtitle_to_free) {
            if (subtitle_to_free->rects != NULL) {
                for (i = 0; i < subtitle_to_free->num_rects; i++) {
                    av_free(subtitle_to_free->rects[i].bitmap);
                    av_free(subtitle_to_free->rects[i].rgba_palette);
                }
                av_freep(&subtitle_to_free->rects);
            }
            subtitle_to_free->num_rects = 0;
            subtitle_to_free = NULL;
        }
    }
 discard_packet:
    if (pkt == NULL) {
        /* EOF handling */

        for(i=0;i<nb_ostreams;i++) {
            ost = ost_table[i];
            if (ost->source_index == ist_index) {
                AVCodecContext *enc= ost->st->codec;
                os = ctx->output_files[ost->file_index];

                if(ost->st->codec->codec_type == CODEC_TYPE_AUDIO && enc->frame_size <=1)
                    continue;
                if(ost->st->codec->codec_type == CODEC_TYPE_VIDEO && (os->oformat->flags & AVFMT_RAWPICTURE))
                    continue;

                if (ost->encoding_needed) {
                    for(;;) {
                        AVPacket pkt;
                        int fifo_bytes;
                        av_init_packet(&pkt);
                        pkt.stream_index= ost->index;

                        switch(ost->st->codec->codec_type) {
                        case CODEC_TYPE_AUDIO:
                            fifo_bytes = av_fifo_size(&ost->fifo);
                            ret = 0;
                            /* encode any samples remaining in fifo */
                            if(fifo_bytes > 0 && enc->codec->capabilities & CODEC_CAP_SMALL_LAST_FRAME) {
                                int fs_tmp = enc->frame_size;
                                enc->frame_size = fifo_bytes / (2 * enc->channels);
                                av_fifo_read(&ost->fifo, (uint8_t *)samples, fifo_bytes);
                                    ret = avcodec_encode_audio(enc, ctx->bit_buffer, ctx->bit_buffer_size, samples);
                                enc->frame_size = fs_tmp;
                            }
                            if(ret <= 0) {
                                ret = avcodec_encode_audio(enc, ctx->bit_buffer, ctx->bit_buffer_size, NULL);
                            }
                            ctx->audio_size += ret;
                            pkt.flags |= PKT_FLAG_KEY;
                            break;
                        case CODEC_TYPE_VIDEO:
                            ret = avcodec_encode_video(enc, ctx->bit_buffer, ctx->bit_buffer_size, NULL);
                            ctx->video_size += ret;
                            if(enc->coded_frame && enc->coded_frame->key_frame)
                                pkt.flags |= PKT_FLAG_KEY;
                            if (ost->logfile && enc->stats_out) {
                                fprintf(ost->logfile, "%s", enc->stats_out);
                            }
                            break;
                        default:
                            ret=-1;
                        }

                        if(ret<=0)
                            break;
                        pkt.data= ctx->bit_buffer;
                        pkt.size= ret;
                        if(enc->coded_frame && enc->coded_frame->pts != AV_NOPTS_VALUE)
                            pkt.pts= av_rescale_q(enc->coded_frame->pts, enc->time_base, ost->st->time_base);
                        write_frame(os, &pkt, ost->st->codec, ctx->bitstream_filters[ost->file_index][pkt.stream_index]);
                    }
                }
            }
        }
    }

    return 0;
 fail_decode:
    return -1;
}

static int ffmpeg_encode(Context* ctx)
{
    int ret, i, j, k, n, nb_istreams = 0, nb_ostreams = 0;
    AVFormatContext *is, *os;
    AVCodecContext *codec, *icodec;
    AVOutputStream *ost, **ost_table = NULL;
    AVInputStream *ist, **ist_table = NULL;
    AVInputFile *file_table;
    int key;
    int want_sdp = 1;

    file_table= av_mallocz(ctx->nb_input_files * sizeof(AVInputFile));
    if (!file_table)
        goto fail;

    /* input stream init */
    j = 0;
    for(i=0;i<ctx->nb_input_files;i++) {
        is = ctx->input_files[i];
        file_table[i].ist_index = j;
        file_table[i].nb_streams = is->nb_streams;
        j += is->nb_streams;
    }
    nb_istreams = j;

    ist_table = av_mallocz(nb_istreams * sizeof(AVInputStream *));
    if (!ist_table)
        goto fail;

    for(i=0;i<nb_istreams;i++) {
        ist = av_mallocz(sizeof(AVInputStream));
        if (!ist)
            goto fail;
        ist_table[i] = ist;
    }
    j = 0;
    for(i=0;i<ctx->nb_input_files;i++) {
        is = ctx->input_files[i];
        for(k=0;k<is->nb_streams;k++) {
            ist = ist_table[j++];
            ist->st = is->streams[k];
            ist->file_index = i;
            ist->index = k;
            ist->discard = 1; /* the stream is discarded by default
                                 (changed later) */

            if (ist->st->codec->rate_emu) {
                ist->start = av_gettime();
                ist->frame = 0;
            }
        }
    }

    /* output stream init */
    nb_ostreams = 0;
    for(i=0;i<ctx->nb_output_files;i++) {
        os = ctx->output_files[i];
        if (!os->nb_streams) {
            dump_format(ctx->output_files[i], i, ctx->output_files[i]->filename, 1);
            fprintf(stderr, "Output file #%d does not contain any stream\n", i);
            return -1;
        }
        nb_ostreams += os->nb_streams;
    }
    if (ctx->nb_stream_maps > 0 && ctx->nb_stream_maps != nb_ostreams) {
        fprintf(stderr, "Number of stream maps must match number of output streams\n");
        return -1;
    }

    /* Sanity check the mapping args -- do the input files & streams exist? */
    for(i=0;i<ctx->nb_stream_maps;i++) {
        int fi = ctx->stream_maps[i].file_index;
        int si = ctx->stream_maps[i].stream_index;

        if (fi < 0 || fi > ctx->nb_input_files - 1 ||
            si < 0 || si > file_table[fi].nb_streams - 1) {
            fprintf(stderr,"Could not find input stream #%d.%d\n", fi, si);
            return -1;
        }
        fi = ctx->stream_maps[i].sync_file_index;
        si = ctx->stream_maps[i].sync_stream_index;
        if (fi < 0 || fi > ctx->nb_input_files - 1 ||
            si < 0 || si > file_table[fi].nb_streams - 1) {
            fprintf(stderr,"Could not find sync stream #%d.%d\n", fi, si);
            return -1;
        }
    }

    ost_table = av_mallocz(sizeof(AVOutputStream *) * nb_ostreams);
    if (!ost_table)
        goto fail;
    for(i=0;i<nb_ostreams;i++) {
        ost = av_mallocz(sizeof(AVOutputStream));
        if (!ost)
            goto fail;
        ost_table[i] = ost;
    }

    n = 0;
    for(k=0;k<ctx->nb_output_files;k++) {
        os = ctx->output_files[k];
        for(i=0;i<os->nb_streams;i++,n++) {
            int found;
            ost = ost_table[n];
            ost->file_index = k;
            ost->index = i;
            ost->st = os->streams[i];
            if (ctx->nb_stream_maps > 0) {
                ost->source_index = file_table[ctx->stream_maps[n].file_index].ist_index +
                    ctx->stream_maps[n].stream_index;

                /* Sanity check that the stream types match */
                if (ist_table[ost->source_index]->st->codec->codec_type != ost->st->codec->codec_type) {
                    int i= ost->file_index;
                    dump_format(ctx->output_files[i], i, ctx->output_files[i]->filename, 1);
                    fprintf(stderr, "Codec type mismatch for mapping #%d.%d -> #%d.%d\n",
                        ctx->stream_maps[n].file_index, ctx->stream_maps[n].stream_index,
                        ost->file_index, ost->index);
                    return -1;
                }

            } else {
                if(ctx->opt_programid) {
                    found = 0;
                    j = stream_index_from_inputs(ctx->input_files, ctx->nb_input_files, file_table, ist_table, ost->st->codec->codec_type, ctx->opt_programid);
                    if(j != -1) {
                        ost->source_index = j;
                        found = 1;
                    }
                } else {
                    /* get corresponding input stream index : we select the first one with the right type */
                    found = 0;
                    for(j=0;j<nb_istreams;j++) {
                        ist = ist_table[j];
                        if (ist->discard &&
                            ist->st->codec->codec_type == ost->st->codec->codec_type) {
                            ost->source_index = j;
                            found = 1;
                            break;
                        }
                    }
                }

                if (!found) {
                    if(!ctx->opt_programid) {
                        /* try again and reuse existing stream */
                        for(j=0;j<nb_istreams;j++) {
                            ist = ist_table[j];
                            if (ist->st->codec->codec_type == ost->st->codec->codec_type) {
                                ost->source_index = j;
                                found = 1;
                            }
                        }
                    }
                    if (!found) {
                        int i= ost->file_index;
                        dump_format(ctx->output_files[i], i, ctx->output_files[i]->filename, 1);
                        fprintf(stderr, "Could not find input stream matching output stream #%d.%d\n",
                                ost->file_index, ost->index);
                        return -1;
                    }
                }
            }
            ist = ist_table[ost->source_index];
            ist->discard = 0;
            ost->sync_ist = (ctx->nb_stream_maps > 0) ?
                ist_table[file_table[ctx->stream_maps[n].sync_file_index].ist_index +
                         ctx->stream_maps[n].sync_stream_index] : ist;
        }
    }

    /* for each output stream, we compute the right encoding parameters */
    for(i=0;i<nb_ostreams;i++) {
        ost = ost_table[i];
        os = ctx->output_files[ost->file_index];
        ist = ist_table[ost->source_index];

        codec = ost->st->codec;
        icodec = ist->st->codec;

        if (!ost->st->language[0])
            strlcpy(ost->st->language, ist->st->language, sizeof(ost->st->language));

        ost->st->disposition = ist->st->disposition;

        if (ost->st->stream_copy) {
            /* if stream_copy is selected, no need to decode or encode */
            codec->codec_id = icodec->codec_id;
            codec->codec_type = icodec->codec_type;

            if(!codec->codec_tag){
                if(   !os->oformat->codec_tag
                   || av_codec_get_id (os->oformat->codec_tag, icodec->codec_tag) > 0
                   || av_codec_get_tag(os->oformat->codec_tag, icodec->codec_id) <= 0)
                    codec->codec_tag = icodec->codec_tag;
            }

            codec->bit_rate = icodec->bit_rate;
            codec->extradata= icodec->extradata;
            codec->extradata_size= icodec->extradata_size;
            if(av_q2d(icodec->time_base) > av_q2d(ist->st->time_base) && av_q2d(ist->st->time_base) < 1.0/1000)
                codec->time_base = icodec->time_base;
            else
                codec->time_base = ist->st->time_base;
            switch(codec->codec_type) {
            case CODEC_TYPE_AUDIO:
                if(ctx->audio_volume != 256) {
                    fprintf(stderr,"-acodec copy and -vol are incompatible (frames are not decoded)\n");
                    return -1;
                }
                codec->sample_rate = icodec->sample_rate;
                codec->channels = icodec->channels;
                codec->frame_size = icodec->frame_size;
                codec->block_align= icodec->block_align;
                if(codec->block_align == 1 && codec->codec_id == CODEC_ID_MP3)
                    codec->block_align= 0;
                if(codec->codec_id == CODEC_ID_AC3)
                    codec->block_align= 0;
                break;
            case CODEC_TYPE_VIDEO:
                codec->pix_fmt = icodec->pix_fmt;
                codec->width = icodec->width;
                codec->height = icodec->height;
                codec->has_b_frames = icodec->has_b_frames;
                break;
            case CODEC_TYPE_SUBTITLE:
                break;
            default:
                abort();
            }
        } else {
            switch(codec->codec_type) {
            case CODEC_TYPE_AUDIO:
                if (av_fifo_init(&ost->fifo, 1024))
                    goto fail;
                ost->reformat_pair = MAKE_SFMT_PAIR(SAMPLE_FMT_NONE,SAMPLE_FMT_NONE);
                ost->audio_resample = codec->sample_rate != icodec->sample_rate || ctx->audio_sync_method > 1;
                icodec->request_channels = codec->channels;
                ist->decoding_needed = 1;
                ost->encoding_needed = 1;
                break;
            case CODEC_TYPE_VIDEO:
                ost->video_crop = ((ctx->frame_leftBand + ctx->frame_rightBand + ctx->frame_topBand + ctx->frame_bottomBand) != 0);
                ost->video_pad = ((ctx->frame_padleft + ctx->frame_padright + ctx->frame_padtop + ctx->frame_padbottom) != 0);
                ost->video_resample = ((codec->width != icodec->width -
                                (ctx->frame_leftBand + ctx->frame_rightBand) +
                                (ctx->frame_padleft + ctx->frame_padright)) ||
                        (codec->height != icodec->height -
                                (ctx->frame_topBand  + ctx->frame_bottomBand) +
                                (ctx->frame_padtop + ctx->frame_padbottom)) ||
                        (codec->pix_fmt != icodec->pix_fmt));
                if (ost->video_crop) {
                    ost->topBand = ctx->frame_topBand;
                    ost->leftBand = ctx->frame_leftBand;
                }
                if (ost->video_pad) {
                    ost->padtop = ctx->frame_padtop;
                    ost->padleft = ctx->frame_padleft;
                    ost->padbottom = ctx->frame_padbottom;
                    ost->padright = ctx->frame_padright;
                    if (!ost->video_resample) {
                        avcodec_get_frame_defaults(&ost->pict_tmp);
                        if(avpicture_alloc((AVPicture*)&ost->pict_tmp, codec->pix_fmt,
                                         codec->width, codec->height))
                            goto fail;
                    }
                }
                if (ost->video_resample) {
                    avcodec_get_frame_defaults(&ost->pict_tmp);
                    if(avpicture_alloc((AVPicture*)&ost->pict_tmp, codec->pix_fmt,
                                         codec->width, codec->height)) {
                        fprintf(stderr, "Cannot allocate temp picture, check pix fmt\n");
                        return -1;
                    }
                    ctx->sws_flags = av_get_int(sws_opts, "sws_flags", NULL);
                    ost->img_resample_ctx = sws_getContext(
                            icodec->width - (ctx->frame_leftBand + ctx->frame_rightBand),
                            icodec->height - (ctx->frame_topBand + ctx->frame_bottomBand),
                            icodec->pix_fmt,
                            codec->width - (ctx->frame_padleft + ctx->frame_padright),
                            codec->height - (ctx->frame_padtop + ctx->frame_padbottom),
                            codec->pix_fmt,
                            ctx->sws_flags, NULL, NULL, NULL);
                    if (ost->img_resample_ctx == NULL) {
                        fprintf(stderr, "Cannot get resampling context\n");
                        return -1;
                    }
                    ost->resample_height = icodec->height - (ctx->frame_topBand + ctx->frame_bottomBand);
                }
                ost->encoding_needed = 1;
                ist->decoding_needed = 1;
                break;
            case CODEC_TYPE_SUBTITLE:
                ost->encoding_needed = 1;
                ist->decoding_needed = 1;
                break;
            default:
                abort();
                break;
            }
            /* two pass mode */
            if (ost->encoding_needed &&
                (codec->flags & (CODEC_FLAG_PASS1 | CODEC_FLAG_PASS2))) {
                char logfilename[1024];
                FILE *f;
                int size;
                char *logbuffer;

                snprintf(logfilename, sizeof(logfilename), "%s-%d.log",
                         ctx->pass_logfilename ?
                         ctx->pass_logfilename : DEFAULT_PASS_LOGFILENAME, i);
                if (codec->flags & CODEC_FLAG_PASS1) {
                    f = fopen(logfilename, "w");
                    if (!f) {
                        perror(logfilename);
                        return -1;
                    }
                    ost->logfile = f;
                } else {
                    /* read the log file */
                    f = fopen(logfilename, "r");
                    if (!f) {
                        perror(logfilename);
                        return -1;
                    }
                    fseek(f, 0, SEEK_END);
                    size = ftell(f);
                    fseek(f, 0, SEEK_SET);
                    logbuffer = av_malloc(size + 1);
                    if (!logbuffer) {
                        fprintf(stderr, "Could not allocate log buffer\n");
                        return -1;
                    }
                    size = fread(logbuffer, 1, size, f);
                    fclose(f);
                    logbuffer[size] = '\0';
                    codec->stats_in = logbuffer;
                }
            }
        }
        if(codec->codec_type == CODEC_TYPE_VIDEO){
            int size= codec->width * codec->height;
            ctx->bit_buffer_size= FFMAX(ctx->bit_buffer_size, 4*size);
        }
    }

    if (!ctx->bit_buffer)
        ctx->bit_buffer = av_malloc(ctx->bit_buffer_size);
    if (!ctx->bit_buffer)
        goto fail;

    /* dump the file output parameters - cannot be done before in case
       of stream copy */
    for(i=0;i<ctx->nb_output_files;i++) {
        dump_format(ctx->output_files[i], i, ctx->output_files[i]->filename, 1);
    }

    /* dump the stream mapping */
    if (ctx->verbose >= 0) {
        fprintf(stderr, "Stream mapping:\n");
        for(i=0;i<nb_ostreams;i++) {
            ost = ost_table[i];
            fprintf(stderr, "  Stream #%d.%d -> #%d.%d",
                    ist_table[ost->source_index]->file_index,
                    ist_table[ost->source_index]->index,
                    ost->file_index,
                    ost->index);
            if (ost->sync_ist != ist_table[ost->source_index])
                fprintf(stderr, " [sync #%d.%d]",
                        ost->sync_ist->file_index,
                        ost->sync_ist->index);
            fprintf(stderr, "\n");
        }
    }

    /* open each encoder */
    for(i=0;i<nb_ostreams;i++) {
        ost = ost_table[i];
        if (ost->encoding_needed) {
            AVCodec *codec = ctx->output_codecs[i];
            if (!codec)
                codec = avcodec_find_encoder(ost->st->codec->codec_id);
            if (!codec) {
                fprintf(stderr, "Unsupported codec for output stream #%d.%d\n",
                        ost->file_index, ost->index);
                return -1;
            }
            if (avcodec_open(ost->st->codec, codec) < 0) {
                fprintf(stderr, "Error while opening codec for output stream #%d.%d - maybe incorrect parameters such as bit_rate, rate, width or height\n",
                        ost->file_index, ost->index);
                return -1;
            }
            ctx->extra_size += ost->st->codec->extradata_size;
        }
    }

    /* open each decoder */
    for(i=0;i<nb_istreams;i++) {
        ist = ist_table[i];
        if (ist->decoding_needed) {
            AVCodec *codec = ctx->input_codecs[i];
            if (!codec)
                codec = avcodec_find_decoder(ist->st->codec->codec_id);
            if (!codec) {
                fprintf(stderr, "Unsupported codec (id=%d) for input stream #%d.%d\n",
                        ist->st->codec->codec_id, ist->file_index, ist->index);
                return -1;
            }
            if (avcodec_open(ist->st->codec, codec) < 0) {
                fprintf(stderr, "Error while opening codec for input stream #%d.%d\n",
                        ist->file_index, ist->index);
                return -1;
            }
            //if (ist->st->codec->codec_type == CODEC_TYPE_VIDEO)
            //    ist->st->codec->flags |= CODEC_FLAG_REPEAT_FIELD;
        }
    }

    /* init pts */
    for(i=0;i<nb_istreams;i++) {
        ist = ist_table[i];
        is = ctx->input_files[ist->file_index];
        ist->pts = 0;
        ist->next_pts = AV_NOPTS_VALUE;
        ist->is_start = 1;
    }

    /* set meta data information from input file if required */
    for (i=0;i<ctx->nb_meta_data_maps;i++) {
        AVFormatContext *out_file;
        AVFormatContext *in_file;

        int out_file_index = ctx->meta_data_maps[i].out_file;
        int in_file_index = ctx->meta_data_maps[i].in_file;
        if (out_file_index < 0 || out_file_index >= ctx->nb_output_files) {
            fprintf(stderr, "Invalid output file index %d map_meta_data(%d,%d)\n", out_file_index, out_file_index, in_file_index);
            ret = AVERROR(EINVAL);
            goto fail;
        }
        if (in_file_index < 0 || in_file_index >= ctx->nb_input_files) {
            fprintf(stderr, "Invalid input file index %d map_meta_data(%d,%d)\n", in_file_index, out_file_index, in_file_index);
            ret = AVERROR(EINVAL);
            goto fail;
        }

        out_file = ctx->output_files[out_file_index];
        in_file = ctx->input_files[in_file_index];

        strcpy(out_file->title, in_file->title);
        strcpy(out_file->author, in_file->author);
        strcpy(out_file->copyright, in_file->copyright);
        strcpy(out_file->comment, in_file->comment);
        strcpy(out_file->album, in_file->album);
        out_file->year = in_file->year;
        out_file->track = in_file->track;
        strcpy(out_file->genre, in_file->genre);
    }

    /* open files and write file headers */
    for(i=0;i<ctx->nb_output_files;i++) {
        os = ctx->output_files[i];
        if (av_write_header(os) < 0) {
            fprintf(stderr, "Could not write header for output file #%d (incorrect codec parameters ?)\n", i);
            ret = AVERROR(EINVAL);
            goto fail;
        }
        if (strcmp(ctx->output_files[i]->oformat->name, "rtp")) {
            want_sdp = 0;
        }
    }
    if (want_sdp) {
        print_sdp(ctx->output_files, ctx->nb_output_files);
    }

    if (ctx->verbose >= 0) {
        fprintf(stderr, "Press [q] to stop encoding\n");
        url_set_interrupt_cb(decode_interrupt_cb);
    }
    //term_init();

    key = -1;
    ctx->timer_start = av_gettime();

    // CFM - for now we don't worry about sigterm
    for(; /*received_sigterm == 0*/;) {
        int file_index, ist_index;
        AVPacket pkt;
        double ipts_min;
        double opts_min;

    redo:
        ipts_min= 1e100;
        opts_min= 1e100;
        
        // CFM - lots of 
        /* if 'q' pressed, exits */
        //if (q_pressed)
        //    break;
        /* read_key() returns 0 on EOF */
        //key = read_key();
        //if (key == 'q')
        //    break;

        /* select the stream that we must read now by looking at the
           smallest output pts */
        file_index = -1;
        for(i=0;i<nb_ostreams;i++) {
            double ipts, opts;
            ost = ost_table[i];
            os = ctx->output_files[ost->file_index];
            ist = ist_table[ost->source_index];
            if(ost->st->codec->codec_type == CODEC_TYPE_VIDEO)
                opts = ost->sync_opts * av_q2d(ost->st->codec->time_base);
            else
                opts = ost->st->pts.val * av_q2d(ost->st->time_base);
            ipts = (double)ist->pts;
            if (!file_table[ist->file_index].eof_reached){
                if(ipts < ipts_min) {
                    ipts_min = ipts;
                    if(ctx->input_sync ) file_index = ist->file_index;
                }
                if(opts < opts_min) {
                    opts_min = opts;
                    if(!ctx->input_sync) file_index = ist->file_index;
                }
            }
            if(ost->frame_number >= ctx->max_frames[ost->st->codec->codec_type]){
                file_index= -1;
                break;
            }
        }
        /* if none, if is finished */
        if (file_index < 0) {
            break;
        }

        /* finish if recording time exhausted */
        if (opts_min >= (ctx->recording_time / 1000000.0))
            break;

        /* finish if limit size exhausted */
        if (ctx->limit_filesize != 0 && ctx->limit_filesize < url_ftell(ctx->output_files[0]->pb))
            break;

        /* read a frame from it and output it in the fifo */
        is = ctx->input_files[file_index];
        if (av_read_frame(is, &pkt) < 0) {
            file_table[file_index].eof_reached = 1;
            if (ctx->opt_shortest)
                break;
            else
                continue;
        }

        /* the following test is needed in case new streams appear
           dynamically in stream : we ignore them */
        if (pkt.stream_index >= file_table[file_index].nb_streams)
            goto discard_packet;
        ist_index = file_table[file_index].ist_index + pkt.stream_index;
        ist = ist_table[ist_index];
        if (ist->discard)
            goto discard_packet;

        if (pkt.dts != AV_NOPTS_VALUE)
            pkt.dts += av_rescale_q(ctx->input_files_ts_offset[ist->file_index], AV_TIME_BASE_Q, ist->st->time_base);
        if (pkt.pts != AV_NOPTS_VALUE)
            pkt.pts += av_rescale_q(ctx->input_files_ts_offset[ist->file_index], AV_TIME_BASE_Q, ist->st->time_base);

        if(ctx->input_files_ts_scale[file_index][pkt.stream_index]){
            if(pkt.pts != AV_NOPTS_VALUE)
                pkt.pts *= ctx->input_files_ts_scale[file_index][pkt.stream_index];
            if(pkt.dts != AV_NOPTS_VALUE)
                pkt.dts *= ctx->input_files_ts_scale[file_index][pkt.stream_index];
        }

//        fprintf(stderr, "next:%"PRId64" dts:%"PRId64" off:%"PRId64" %d\n", ist->next_pts, pkt.dts, ctx->input_files_ts_offset[ist->file_index], ist->st->codec->codec_type);
        if (pkt.dts != AV_NOPTS_VALUE && ist->next_pts != AV_NOPTS_VALUE
            && (is->iformat->flags & AVFMT_TS_DISCONT)) {
            int64_t pkt_dts= av_rescale_q(pkt.dts, ist->st->time_base, AV_TIME_BASE_Q);
            int64_t delta= pkt_dts - ist->next_pts;
            if((FFABS(delta) > 1LL*ctx->dts_delta_threshold*AV_TIME_BASE || pkt_dts+1<ist->pts)&& !ctx->copy_ts){
                ctx->input_files_ts_offset[ist->file_index]-= delta;
                if (ctx->verbose > 2)
                    fprintf(stderr, "timestamp discontinuity %"PRId64", new offset= %"PRId64"\n", delta, ctx->input_files_ts_offset[ist->file_index]);
                pkt.dts-= av_rescale_q(delta, AV_TIME_BASE_Q, ist->st->time_base);
                if(pkt.pts != AV_NOPTS_VALUE)
                    pkt.pts-= av_rescale_q(delta, AV_TIME_BASE_Q, ist->st->time_base);
            }
        }

        //fprintf(stderr,"read #%d.%d size=%d\n", ist->file_index, ist->index, pkt.size);
        if (output_packet(ctx, ist, ist_index, ost_table, nb_ostreams, &pkt) < 0) {

            if (ctx->verbose >= 0)
                fprintf(stderr, "Error while decoding stream #%d.%d\n",
                        ist->file_index, ist->index);
            av_free_packet(&pkt);
            goto redo;
        }

    discard_packet:
        av_free_packet(&pkt);
    }

    /* at the end of stream, we must flush the decoder buffers */
    for(i=0;i<nb_istreams;i++) {
        ist = ist_table[i];
        if (ist->decoding_needed) {
            output_packet(ctx, ist, i, ost_table, nb_ostreams, NULL);
        }
    }

    /* write the trailer if needed and close file */
    for(i=0;i<ctx->nb_output_files;i++) {
        os = ctx->output_files[i];
        av_write_trailer(os);
    }

    /* close each encoder */
    for(i=0;i<nb_ostreams;i++) {
        ost = ost_table[i];
        if (ost->encoding_needed) {
            av_freep(&ost->st->codec->stats_in);
            avcodec_close(ost->st->codec);
        }
    }

    /* close each decoder */
    for(i=0;i<nb_istreams;i++) {
        ist = ist_table[i];
        if (ist->decoding_needed) {
            avcodec_close(ist->st->codec);
        }
    }

    /* finished ! */

    ret = 0;
 fail1:
    av_freep(&ctx->bit_buffer);
    av_free(file_table);

    if (ist_table) {
        for(i=0;i<nb_istreams;i++) {
            ist = ist_table[i];
            av_free(ist);
        }
        av_free(ist_table);
    }
    if (ost_table) {
        for(i=0;i<nb_ostreams;i++) {
            ost = ost_table[i];
            if (ost) {
                if (ost->logfile) {
                    fclose(ost->logfile);
                    ost->logfile = NULL;
                }
                av_fifo_free(&ost->fifo); /* works even if fifo is not
                                             initialized but set to zero */
                av_free(ost->pict_tmp.data[0]);
                if (ost->video_resample)
                    sws_freeContext(ost->img_resample_ctx);
                if (ost->resample)
                    audio_resample_close(ost->resample);
                if (ost->reformat_ctx)
                    av_audio_convert_free(ost->reformat_ctx);
                av_free(ost);
            }
        }
        av_free(ost_table);
    }
    return ret;
 fail:
    ret = AVERROR(ENOMEM);
    goto fail1;
}

static void _finish(Context* ctx)
{
    int i;

    /* close files */
    for(i=0;i<ctx->nb_output_files;i++) {
        /* maybe av_close_output_file ??? */
        AVFormatContext *s = ctx->output_files[i];
        int j;
        if (!(s->oformat->flags & AVFMT_NOFILE) && s->pb)
            url_fclose(s->pb);
        for(j=0;j<s->nb_streams;j++) {
            av_free(s->streams[j]->codec);
            av_free(s->streams[j]);
        }
        av_free(s);
    }
    for(i=0;i<ctx->nb_input_files;i++)
        av_close_input_file(ctx->input_files[i]);

    av_free(ctx->intra_matrix);
    av_free(ctx->inter_matrix);

    if (ctx->vstats_file)
        fclose(ctx->vstats_file);
    av_free(ctx->vstats_filename);

    av_free(opt_names);

    av_free(ctx->video_codec_name);
    av_free(ctx->audio_codec_name);
    av_free(ctx->subtitle_codec_name);

    av_free(ctx->video_standard);
}

static int opt_output_file(Context* ctx, const char *filename)
{
    AVFormatContext *oc;
    int use_video, use_audio, use_subtitle;
    int input_has_video, input_has_audio, input_has_subtitle;
    AVFormatParameters params, *ap = &params;

    if (!strcmp(filename, "-"))
        filename = "pipe:";

    oc = av_alloc_format_context();

    if (!ctx->file_oformat) {
        ctx->file_oformat = guess_format(NULL, filename, NULL);
        if (!ctx->file_oformat) {
            fprintf(stderr, "Unable to find a suitable output format for '%s'\n",
                    filename);
            return -1;
        }
    }

    oc->oformat = ctx->file_oformat;
    strlcpy(oc->filename, filename, sizeof(oc->filename));

    if (!strcmp(ctx->file_oformat->name, "ffm") &&
        strncmp(filename, "http:", 5) == 0) {
        /* special case for files sent to ffserver: we get the stream
           parameters from ffserver */
        int err = read_ffserver_streams(ctx, oc, filename);
        if (err < 0) {
            print_error(filename, err);
            return -1;
        }
    } else {
        use_video = ctx->file_oformat->video_codec != CODEC_ID_NONE || ctx->video_stream_copy || ctx->video_codec_name;
        use_audio = ctx->file_oformat->audio_codec != CODEC_ID_NONE || ctx->audio_stream_copy || ctx->audio_codec_name;
        use_subtitle = ctx->file_oformat->subtitle_codec != CODEC_ID_NONE || ctx->subtitle_stream_copy || ctx->subtitle_codec_name;

        /* disable if no corresponding type found and at least one
           input file */
        if (ctx->nb_input_files > 0) {
            check_audio_video_sub_inputs(ctx, &input_has_video, &input_has_audio,
                                         &input_has_subtitle);
            if (!input_has_video)
                use_video = 0;
            if (!input_has_audio)
                use_audio = 0;
            if (!input_has_subtitle)
                use_subtitle = 0;
        }

        /* manual disable */
        if (ctx->audio_disable) {
            use_audio = 0;
        }
        if (ctx->video_disable) {
            use_video = 0;
        }
        if (ctx->subtitle_disable) {
            use_subtitle = 0;
        }

        if (use_video) {
            new_video_stream(ctx, oc);
        }

        if (use_audio) {
            new_audio_stream(ctx, oc);
        }

        if (use_subtitle) {
            new_subtitle_stream(ctx, oc);
        }

        oc->timestamp = rec_timestamp;

        if (str_title)
            av_strlcpy(oc->title, str_title, sizeof(oc->title));
        if (str_author)
            av_strlcpy(oc->author, str_author, sizeof(oc->author));
        if (str_copyright)
            av_strlcpy(oc->copyright, str_copyright, sizeof(oc->copyright));
        if (str_comment)
            av_strlcpy(oc->comment, str_comment, sizeof(oc->comment));
        if (str_album)
            av_strlcpy(oc->album, str_album, sizeof(oc->album));
        if (str_genre)
            av_strlcpy(oc->genre, str_genre, sizeof(oc->genre));
    }

    output_files[nb_output_files++] = oc;

    /* check filename in case of an image number is expected */
    if (oc->oformat->flags & AVFMT_NEEDNUMBER) {
        if (!av_filename_number_test(oc->filename)) {
            print_error(oc->filename, AVERROR_NUMEXPECTED);
            return -1;
        }
    }

    if (!(oc->oformat->flags & AVFMT_NOFILE)) {
        /* test if it already exists to avoid loosing precious files */
        if (!file_overwrite &&
            (strchr(filename, ':') == NULL ||
             filename[1] == ':' ||
             strncmp(filename, "file:", 5) == 0)) {
            if (url_exist(filename)) {
                int c;

                if (!using_stdin) {
                    fprintf(stderr,"File '%s' already exists. Overwrite ? [y/N] ", filename);
                    fflush(stderr);
                    c = getchar();
                    if (toupper(c) != 'Y') {
                        fprintf(stderr, "Not overwriting - exiting\n");
                        av_exit(1);
                    }
                }
                else {
                    fprintf(stderr,"File '%s' already exists. Exiting.\n", filename);
                    av_exit(1);
                }
            }
        }

        /* open the file */
        if (url_fopen(&oc->pb, filename, URL_WRONLY) < 0) {
            fprintf(stderr, "Could not open '%s'\n", filename);
            return -1;
        }
    }

    memset(ap, 0, sizeof(*ap));
    if (av_set_parameters(oc, ap) < 0) {
        fprintf(stderr, "%s: Invalid encoding parameters\n",
                oc->filename);
        return -1;
    }

    oc->preload= (int)(mux_preload*AV_TIME_BASE);
    oc->max_delay= (int)(mux_max_delay*AV_TIME_BASE);
    oc->loop_output = loop_output;

    set_context_opts(oc, avformat_opts, AV_OPT_FLAG_ENCODING_PARAM);

    /* reset some options */
    ctx->file_oformat = NULL;
    file_iformat = NULL;
    return 0;
}

