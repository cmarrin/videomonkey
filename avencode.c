/*
 *  avencode.c
 *  VideoMonkey
 *
 *  Created by Chris Marrin on 11/19/08.
 *  Copyright 2008 Apple. All rights reserved.
 *
 */

#include "avencode.h"

// Forward declarations
static int ffmpeg_encode(AVFormatContext **output_files,
                     int nb_output_files,
                     AVFormatContext **input_files,
                     int nb_input_files,
                     AVStreamMap *stream_maps, int nb_stream_maps);
                     
// Context
struct {
    ffmpeg_Callback myCB;
    void* myUserData;
} Context;

// Interface
ffmpeg_Context ffmpeg_createContext(ffmpeg_Callback cb, void* userData)
{
    Context* ctx = malloc(sizeof(Context));
    ctx->myCB = cb;
    ctx->myUserData = userData;
    return ctx;
}

void ffmpeg_destroyContext(ffmpeg_Context _ctx;)
{
    ffmpeg_cancelEncode(_ctx);
    free(_ctx);
}

int ffmpeg_addInputFile(ffmpeg_Context, const char*)
{
    return -1;
}

int ffmpeg_addOutputFile(ffmpeg_Context, const char*)
{
    return -1;
}

bool ffmpeg_setParam(ffmpeg_Context, const char* name, const char* value)
{
    return false;
}

void ffmpeg_startEncode(ffmpeg_Context)
{
}

void ffmpeg_pauseEncode(ffmpeg_Context)
{
}

void ffmpeg_cancelEncode(ffmpeg_Context)
{
}

float ffmpeg_getProgress(ffmpeg_Context)
{
    return -1;
}

float ffmpeg_getFloatParam(ffmpeg_Context, const char* name)
{
    return -1;
}

const char* ffmpeg_getStringParam(ffmpeg_Context, const char* name)
{
    return "";
}

// Implementation
static int av_encode(AVFormatContext **output_files,
                     int nb_output_files,
                     AVFormatContext **input_files,
                     int nb_input_files,
                     AVStreamMap *stream_maps, int nb_stream_maps)
{
    int ret, i, j, k, n, nb_istreams = 0, nb_ostreams = 0;
    AVFormatContext *is, *os;
    AVCodecContext *codec, *icodec;
    AVOutputStream *ost, **ost_table = NULL;
    AVInputStream *ist, **ist_table = NULL;
    AVInputFile *file_table;
    int key;
    int want_sdp = 1;

    file_table= av_mallocz(nb_input_files * sizeof(AVInputFile));
    if (!file_table)
        goto fail;

    /* input stream init */
    j = 0;
    for(i=0;i<nb_input_files;i++) {
        is = input_files[i];
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
    for(i=0;i<nb_input_files;i++) {
        is = input_files[i];
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
    for(i=0;i<nb_output_files;i++) {
        os = output_files[i];
        if (!os->nb_streams) {
            dump_format(output_files[i], i, output_files[i]->filename, 1);
            fprintf(stderr, "Output file #%d does not contain any stream\n", i);
            av_exit(1);
        }
        nb_ostreams += os->nb_streams;
    }
    if (nb_stream_maps > 0 && nb_stream_maps != nb_ostreams) {
        fprintf(stderr, "Number of stream maps must match number of output streams\n");
        av_exit(1);
    }

    /* Sanity check the mapping args -- do the input files & streams exist? */
    for(i=0;i<nb_stream_maps;i++) {
        int fi = stream_maps[i].file_index;
        int si = stream_maps[i].stream_index;

        if (fi < 0 || fi > nb_input_files - 1 ||
            si < 0 || si > file_table[fi].nb_streams - 1) {
            fprintf(stderr,"Could not find input stream #%d.%d\n", fi, si);
            av_exit(1);
        }
        fi = stream_maps[i].sync_file_index;
        si = stream_maps[i].sync_stream_index;
        if (fi < 0 || fi > nb_input_files - 1 ||
            si < 0 || si > file_table[fi].nb_streams - 1) {
            fprintf(stderr,"Could not find sync stream #%d.%d\n", fi, si);
            av_exit(1);
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
    for(k=0;k<nb_output_files;k++) {
        os = output_files[k];
        for(i=0;i<os->nb_streams;i++,n++) {
            int found;
            ost = ost_table[n];
            ost->file_index = k;
            ost->index = i;
            ost->st = os->streams[i];
            if (nb_stream_maps > 0) {
                ost->source_index = file_table[stream_maps[n].file_index].ist_index +
                    stream_maps[n].stream_index;

                /* Sanity check that the stream types match */
                if (ist_table[ost->source_index]->st->codec->codec_type != ost->st->codec->codec_type) {
                    int i= ost->file_index;
                    dump_format(output_files[i], i, output_files[i]->filename, 1);
                    fprintf(stderr, "Codec type mismatch for mapping #%d.%d -> #%d.%d\n",
                        stream_maps[n].file_index, stream_maps[n].stream_index,
                        ost->file_index, ost->index);
                    av_exit(1);
                }

            } else {
                if(opt_programid) {
                    found = 0;
                    j = stream_index_from_inputs(input_files, nb_input_files, file_table, ist_table, ost->st->codec->codec_type, opt_programid);
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
                    if(! opt_programid) {
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
                        dump_format(output_files[i], i, output_files[i]->filename, 1);
                        fprintf(stderr, "Could not find input stream matching output stream #%d.%d\n",
                                ost->file_index, ost->index);
                        av_exit(1);
                    }
                }
            }
            ist = ist_table[ost->source_index];
            ist->discard = 0;
            ost->sync_ist = (nb_stream_maps > 0) ?
                ist_table[file_table[stream_maps[n].sync_file_index].ist_index +
                         stream_maps[n].sync_stream_index] : ist;
        }
    }

    /* for each output stream, we compute the right encoding parameters */
    for(i=0;i<nb_ostreams;i++) {
        ost = ost_table[i];
        os = output_files[ost->file_index];
        ist = ist_table[ost->source_index];

        codec = ost->st->codec;
        icodec = ist->st->codec;

        if (!ost->st->language[0])
            av_strlcpy(ost->st->language, ist->st->language,
                       sizeof(ost->st->language));

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
                if(audio_volume != 256) {
                    fprintf(stderr,"-acodec copy and -vol are incompatible (frames are not decoded)\n");
                    av_exit(1);
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
                if(using_vhook) {
                    fprintf(stderr,"-vcodec copy and -vhook are incompatible (frames are not decoded)\n");
                    av_exit(1);
                }
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
                ost->audio_resample = codec->sample_rate != icodec->sample_rate || audio_sync_method > 1;
                icodec->request_channels = codec->channels;
                ist->decoding_needed = 1;
                ost->encoding_needed = 1;
                break;
            case CODEC_TYPE_VIDEO:
                ost->video_crop = ((frame_leftBand + frame_rightBand + frame_topBand + frame_bottomBand) != 0);
                ost->video_pad = ((frame_padleft + frame_padright + frame_padtop + frame_padbottom) != 0);
                ost->video_resample = ((codec->width != icodec->width -
                                (frame_leftBand + frame_rightBand) +
                                (frame_padleft + frame_padright)) ||
                        (codec->height != icodec->height -
                                (frame_topBand  + frame_bottomBand) +
                                (frame_padtop + frame_padbottom)) ||
                        (codec->pix_fmt != icodec->pix_fmt));
                if (ost->video_crop) {
                    ost->topBand = frame_topBand;
                    ost->leftBand = frame_leftBand;
                }
                if (ost->video_pad) {
                    ost->padtop = frame_padtop;
                    ost->padleft = frame_padleft;
                    ost->padbottom = frame_padbottom;
                    ost->padright = frame_padright;
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
                        av_exit(1);
                    }
                    sws_flags = av_get_int(sws_opts, "sws_flags", NULL);
                    ost->img_resample_ctx = sws_getContext(
                            icodec->width - (frame_leftBand + frame_rightBand),
                            icodec->height - (frame_topBand + frame_bottomBand),
                            icodec->pix_fmt,
                            codec->width - (frame_padleft + frame_padright),
                            codec->height - (frame_padtop + frame_padbottom),
                            codec->pix_fmt,
                            sws_flags, NULL, NULL, NULL);
                    if (ost->img_resample_ctx == NULL) {
                        fprintf(stderr, "Cannot get resampling context\n");
                        av_exit(1);
                    }
                    ost->resample_height = icodec->height - (frame_topBand + frame_bottomBand);
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
                         pass_logfilename ?
                         pass_logfilename : DEFAULT_PASS_LOGFILENAME, i);
                if (codec->flags & CODEC_FLAG_PASS1) {
                    f = fopen(logfilename, "w");
                    if (!f) {
                        perror(logfilename);
                        av_exit(1);
                    }
                    ost->logfile = f;
                } else {
                    /* read the log file */
                    f = fopen(logfilename, "r");
                    if (!f) {
                        perror(logfilename);
                        av_exit(1);
                    }
                    fseek(f, 0, SEEK_END);
                    size = ftell(f);
                    fseek(f, 0, SEEK_SET);
                    logbuffer = av_malloc(size + 1);
                    if (!logbuffer) {
                        fprintf(stderr, "Could not allocate log buffer\n");
                        av_exit(1);
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
            bit_buffer_size= FFMAX(bit_buffer_size, 4*size);
        }
    }

    if (!bit_buffer)
        bit_buffer = av_malloc(bit_buffer_size);
    if (!bit_buffer)
        goto fail;

    /* dump the file output parameters - cannot be done before in case
       of stream copy */
    for(i=0;i<nb_output_files;i++) {
        dump_format(output_files[i], i, output_files[i]->filename, 1);
    }

    /* dump the stream mapping */
    if (verbose >= 0) {
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
            AVCodec *codec = output_codecs[i];
            if (!codec)
                codec = avcodec_find_encoder(ost->st->codec->codec_id);
            if (!codec) {
                fprintf(stderr, "Unsupported codec for output stream #%d.%d\n",
                        ost->file_index, ost->index);
                av_exit(1);
            }
            if (avcodec_open(ost->st->codec, codec) < 0) {
                fprintf(stderr, "Error while opening codec for output stream #%d.%d - maybe incorrect parameters such as bit_rate, rate, width or height\n",
                        ost->file_index, ost->index);
                av_exit(1);
            }
            extra_size += ost->st->codec->extradata_size;
        }
    }

    /* open each decoder */
    for(i=0;i<nb_istreams;i++) {
        ist = ist_table[i];
        if (ist->decoding_needed) {
            AVCodec *codec = input_codecs[i];
            if (!codec)
                codec = avcodec_find_decoder(ist->st->codec->codec_id);
            if (!codec) {
                fprintf(stderr, "Unsupported codec (id=%d) for input stream #%d.%d\n",
                        ist->st->codec->codec_id, ist->file_index, ist->index);
                av_exit(1);
            }
            if (avcodec_open(ist->st->codec, codec) < 0) {
                fprintf(stderr, "Error while opening codec for input stream #%d.%d\n",
                        ist->file_index, ist->index);
                av_exit(1);
            }
            //if (ist->st->codec->codec_type == CODEC_TYPE_VIDEO)
            //    ist->st->codec->flags |= CODEC_FLAG_REPEAT_FIELD;
        }
    }

    /* init pts */
    for(i=0;i<nb_istreams;i++) {
        ist = ist_table[i];
        is = input_files[ist->file_index];
        ist->pts = 0;
        ist->next_pts = AV_NOPTS_VALUE;
        ist->is_start = 1;
    }

    /* set meta data information from input file if required */
    for (i=0;i<nb_meta_data_maps;i++) {
        AVFormatContext *out_file;
        AVFormatContext *in_file;

        int out_file_index = meta_data_maps[i].out_file;
        int in_file_index = meta_data_maps[i].in_file;
        if (out_file_index < 0 || out_file_index >= nb_output_files) {
            fprintf(stderr, "Invalid output file index %d map_meta_data(%d,%d)\n", out_file_index, out_file_index, in_file_index);
            ret = AVERROR(EINVAL);
            goto fail;
        }
        if (in_file_index < 0 || in_file_index >= nb_input_files) {
            fprintf(stderr, "Invalid input file index %d map_meta_data(%d,%d)\n", in_file_index, out_file_index, in_file_index);
            ret = AVERROR(EINVAL);
            goto fail;
        }

        out_file = output_files[out_file_index];
        in_file = input_files[in_file_index];

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
    for(i=0;i<nb_output_files;i++) {
        os = output_files[i];
        if (av_write_header(os) < 0) {
            fprintf(stderr, "Could not write header for output file #%d (incorrect codec parameters ?)\n", i);
            ret = AVERROR(EINVAL);
            goto fail;
        }
        if (strcmp(output_files[i]->oformat->name, "rtp")) {
            want_sdp = 0;
        }
    }
    if (want_sdp) {
        print_sdp(output_files, nb_output_files);
    }

    if (!using_stdin && verbose >= 0) {
        fprintf(stderr, "Press [q] to stop encoding\n");
        url_set_interrupt_cb(decode_interrupt_cb);
    }
    term_init();

    key = -1;
    timer_start = av_gettime();

    for(; received_sigterm == 0;) {
        int file_index, ist_index;
        AVPacket pkt;
        double ipts_min;
        double opts_min;

    redo:
        ipts_min= 1e100;
        opts_min= 1e100;
        /* if 'q' pressed, exits */
        if (!using_stdin) {
            if (q_pressed)
                break;
            /* read_key() returns 0 on EOF */
            key = read_key();
            if (key == 'q')
                break;
        }

        /* select the stream that we must read now by looking at the
           smallest output pts */
        file_index = -1;
        for(i=0;i<nb_ostreams;i++) {
            double ipts, opts;
            ost = ost_table[i];
            os = output_files[ost->file_index];
            ist = ist_table[ost->source_index];
            if(ost->st->codec->codec_type == CODEC_TYPE_VIDEO)
                opts = ost->sync_opts * av_q2d(ost->st->codec->time_base);
            else
                opts = ost->st->pts.val * av_q2d(ost->st->time_base);
            ipts = (double)ist->pts;
            if (!file_table[ist->file_index].eof_reached){
                if(ipts < ipts_min) {
                    ipts_min = ipts;
                    if(input_sync ) file_index = ist->file_index;
                }
                if(opts < opts_min) {
                    opts_min = opts;
                    if(!input_sync) file_index = ist->file_index;
                }
            }
            if(ost->frame_number >= max_frames[ost->st->codec->codec_type]){
                file_index= -1;
                break;
            }
        }
        /* if none, if is finished */
        if (file_index < 0) {
            break;
        }

        /* finish if recording time exhausted */
        if (opts_min >= (recording_time / 1000000.0))
            break;

        /* finish if limit size exhausted */
        if (limit_filesize != 0 && limit_filesize < url_ftell(output_files[0]->pb))
            break;

        /* read a frame from it and output it in the fifo */
        is = input_files[file_index];
        if (av_read_frame(is, &pkt) < 0) {
            file_table[file_index].eof_reached = 1;
            if (opt_shortest)
                break;
            else
                continue;
        }

        if (do_pkt_dump) {
            av_pkt_dump_log(NULL, AV_LOG_DEBUG, &pkt, do_hex_dump);
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
            pkt.dts += av_rescale_q(input_files_ts_offset[ist->file_index], AV_TIME_BASE_Q, ist->st->time_base);
        if (pkt.pts != AV_NOPTS_VALUE)
            pkt.pts += av_rescale_q(input_files_ts_offset[ist->file_index], AV_TIME_BASE_Q, ist->st->time_base);

        if(input_files_ts_scale[file_index][pkt.stream_index]){
            if(pkt.pts != AV_NOPTS_VALUE)
                pkt.pts *= input_files_ts_scale[file_index][pkt.stream_index];
            if(pkt.dts != AV_NOPTS_VALUE)
                pkt.dts *= input_files_ts_scale[file_index][pkt.stream_index];
        }

//        fprintf(stderr, "next:%"PRId64" dts:%"PRId64" off:%"PRId64" %d\n", ist->next_pts, pkt.dts, input_files_ts_offset[ist->file_index], ist->st->codec->codec_type);
        if (pkt.dts != AV_NOPTS_VALUE && ist->next_pts != AV_NOPTS_VALUE
            && (is->iformat->flags & AVFMT_TS_DISCONT)) {
            int64_t pkt_dts= av_rescale_q(pkt.dts, ist->st->time_base, AV_TIME_BASE_Q);
            int64_t delta= pkt_dts - ist->next_pts;
            if((FFABS(delta) > 1LL*dts_delta_threshold*AV_TIME_BASE || pkt_dts+1<ist->pts)&& !copy_ts){
                input_files_ts_offset[ist->file_index]-= delta;
                if (verbose > 2)
                    fprintf(stderr, "timestamp discontinuity %"PRId64", new offset= %"PRId64"\n", delta, input_files_ts_offset[ist->file_index]);
                pkt.dts-= av_rescale_q(delta, AV_TIME_BASE_Q, ist->st->time_base);
                if(pkt.pts != AV_NOPTS_VALUE)
                    pkt.pts-= av_rescale_q(delta, AV_TIME_BASE_Q, ist->st->time_base);
            }
        }

        //fprintf(stderr,"read #%d.%d size=%d\n", ist->file_index, ist->index, pkt.size);
        if (output_packet(ist, ist_index, ost_table, nb_ostreams, &pkt) < 0) {

            if (verbose >= 0)
                fprintf(stderr, "Error while decoding stream #%d.%d\n",
                        ist->file_index, ist->index);
            if (exit_on_error)
                av_exit(1);
            av_free_packet(&pkt);
            goto redo;
        }

    discard_packet:
        av_free_packet(&pkt);

        /* dump report by using the output first video and audio streams */
        print_report(output_files, ost_table, nb_ostreams, 0);
    }

    /* at the end of stream, we must flush the decoder buffers */
    for(i=0;i<nb_istreams;i++) {
        ist = ist_table[i];
        if (ist->decoding_needed) {
            output_packet(ist, i, ost_table, nb_ostreams, NULL);
        }
    }

    term_exit();

    /* write the trailer if needed and close file */
    for(i=0;i<nb_output_files;i++) {
        os = output_files[i];
        av_write_trailer(os);
    }

    /* dump report by using the first video and audio streams */
    print_report(output_files, ost_table, nb_ostreams, 1);

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
    av_freep(&bit_buffer);
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
