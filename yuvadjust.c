/*
  *  yuvadjust.c
  * performs simple contrast brightness saturation adjustments
  *
  *  modified from yuvfps.c by
  *  Copyright (C) 2002 Alfonso Garcia-Patiño Barbolani
  *
  *
  *  This program is free software; you can redistribute it and/or modify
  *  it under the terms of the GNU General Public License as published by
  *  the Free Software Foundation; either version 2 of the License, or
  *  (at your option) any later version.
  *
  *  This program is distributed in the hope that it will be useful,
  *  but WITHOUT ANY WARRANTY; without even the implied warranty of
  *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  *  GNU General Public License for more details.
  *
  *  You should have received a copy of the GNU General Public License
  *  along with this program; if not, write to the Free Software
  *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
  *
  
gcc -O3 -L/usr/local/lib -I/usr/local/include/mjpegtools -lmjpegutils yuvadjust.c -o yuvadjust
	
  */

#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <string.h>
#include <math.h>

#include "yuv4mpeg.h"
#include "mpegconsts.h"

#define YUVRFPS_VERSION "0.3"

static void print_usage() 
{
  fprintf (stderr,
	   "usage: yuvadjust [-h <hue> -b <bri> [-c <con> [-C <cen>]] [-B <lev> -W <lev>]  -s <sat> -u <tra> -v <tra>]\n"
	   "yuvadjust performs simple luma and chroma adjustments\n"
           "\n"
	   "\t -V Verbosity degree : 0=quiet, 1=normal, 2=verbose/debug\n"
	   "\t -h <hue> hue rotation in degrees (0-359)\n"
	   "\t -b <bri> brightness increment (-255-255)\n"
	   "\t -c <con> contrast (-2.0-2.0)\n"
	   "\t -C <cen> contrast centre (16-240)\n"
		"\t -B <lev> Black level (16-240)\n"
		"\t -W <lev> White level (16-240)\n"
	   "\t -s <sat> saturation (-2.0-2.0)\n"
	   "\t -u <tra> shift Cr component (-255-255)\n"
		"\t -v <tra> shift Cb component (-255-255)\n"
         );
}

static void adjust(  int fdIn , y4m_stream_info_t  *inStrInfo,
	int fdOut, y4m_stream_info_t  *outStrInfo,
	float adj_bri, float adj_con, int adj_con_cen,
	float adj_sat, float adj_hue, float adj_u, float adj_v)
{
	y4m_frame_info_t   in_frame ;
	uint8_t            *yuv_data[3],*yuv_odata[3];	

	int                y_frame_data_size, uv_frame_data_size ;
	int                read_error_code ;
	int                write_error_code ;
	int                src_frame_counter ;
	float vy,vu,vv,nvu,nvv;
	float sin_hue, cos_hue;
	int x,y,w,h,cw,ch;

	w = y4m_si_get_plane_width(inStrInfo,0);
	h = y4m_si_get_plane_height(inStrInfo,0);
	cw = y4m_si_get_plane_width(inStrInfo,1);
	ch = y4m_si_get_plane_height(inStrInfo,1);

	
  // Allocate memory for the YUV channels

	y_frame_data_size = y4m_si_get_plane_length(inStrInfo,0);
	uv_frame_data_size = y4m_si_get_plane_length(inStrInfo,1);


		yuv_data[0] = (uint8_t *)malloc( y_frame_data_size);
		yuv_data[1] = (uint8_t *)malloc( uv_frame_data_size);
		yuv_data[2] = (uint8_t *)malloc( uv_frame_data_size);
		if( !yuv_data[0] || !yuv_data[1] || !yuv_data[2]) 
		    mjpeg_error_exit1 ("Could'nt allocate memory for the YUV4MPEG data!");  

	
  write_error_code = Y4M_OK ;

  src_frame_counter = 0 ;


	sin_hue = sin(adj_hue);
	cos_hue = cos(adj_hue);
	
	
// initialise and read the first number of frames
	y4m_init_frame_info( &in_frame );
	read_error_code = y4m_read_frame(fdIn,inStrInfo,&in_frame,yuv_data );
	
	while( Y4M_ERR_EOF != read_error_code && write_error_code == Y4M_OK ) {

		for (x=0; x<w; x++) {
			for (y=0; y<h; y++) {
			// perform magic
				vy = *(yuv_data[0]+x+(y*w)) - adj_con_cen;
				
				vy = vy * adj_con + adj_bri + adj_con_cen; // Brightness and contrast operation
			// clamping 
				if (vy > 240 ) vy = 240;
				if (vy < 16 ) vy = 16;
				
				*(yuv_data[0]+x+(y*w)) = vy;
				
				if ((x < cw) && (y<ch)) {
					vu = *(yuv_data[1]+x+(y*cw)) - 128 ;
					vv = *(yuv_data[2]+x+(y*cw)) - 128 ;

					// hue rotation, saturation and shift
					nvu = cos_hue * vu - sin_hue * vv * adj_sat + adj_v;
					nvv = sin_hue * vu + cos_hue * vv * adj_sat + adj_u;
					
					if (nvu > 112) nvu = 112;
					if (nvu < -112) nvu = -112;
					if (nvv > 112) nvv = 112;
					if (nvv < -112) nvv = -112;
					
					*(yuv_data[1]+x+(y*cw)) = nvu + 128;
					*(yuv_data[2]+x+(y*cw)) = nvv + 128;

				}
			}
		}
	write_error_code = y4m_write_frame( fdOut, outStrInfo, &in_frame, yuv_data );
		y4m_fini_frame_info( &in_frame );
		y4m_init_frame_info( &in_frame );
		read_error_code = y4m_read_frame(fdIn,inStrInfo,&in_frame,yuv_data );
		++src_frame_counter ;

	}

  // Clean-up regardless an error happened or not

y4m_fini_frame_info( &in_frame );

		free( yuv_data[0] );
		free( yuv_data[1] );
		free( yuv_data[2] );
	
  if( read_error_code != Y4M_ERR_EOF )
    mjpeg_error_exit1 ("Error reading from input stream!");
  if( write_error_code != Y4M_OK )
    mjpeg_error_exit1 ("Error writing output stream!");

}

// *************************************************************************************
// MAIN
// *************************************************************************************
int main (int argc, char *argv[])
{

	int verbose = 1 ; // LOG_ERROR ?
	int drop_frames = 0;
	int fdIn = 0 ;
	int fdOut = 1 ;
	y4m_stream_info_t in_streaminfo,out_streaminfo;
	int src_interlacing = Y4M_UNKNOWN;
	y4m_ratio_t src_frame_rate;
	const static char *legal_flags = "h:c:C:B:W:b:s:u:v:V:";
	float adj_bri=0,adj_con=1,adj_sat=1,adj_hue=0,adj_u=0,adj_v=0;
	int c, adj_con_cen = 128;
	int adj_lev_blk = -1, adj_lev_wht = -1;
	

  while ((c = getopt (argc, argv, legal_flags)) != -1) {
    switch (c) {
      case 'V':
        verbose = atoi (optarg);
        if (verbose < 0 || verbose > 2)
          mjpeg_error_exit1 ("Verbose level must be [0..2]");
        break;
    case 'h':
	    adj_hue = atof(optarg);
		break;
	case 'c':
		adj_con = atof(optarg);
		break;
	case 'C':
		adj_con_cen = atoi(optarg);
		break;
	case 'B':
		adj_lev_blk = atoi(optarg);
		break;
	case 'W':
		adj_lev_wht = atoi(optarg);
		break;
	case 'b':
	    adj_bri = atof(optarg);
		break;
	case 's':
		adj_sat = atof(optarg);
		break;
	case 'u':
		adj_u = atof(optarg);
		break;
	case 'v':
		adj_v = atof(optarg);
		break;
	
	case '?':
          print_usage (argv);
          return 0 ;
          break;
    }
  }
  
  
  // mjpeg tools global initialisations
  mjpeg_default_handler_verbosity (verbose);

  // Initialize input streams
  y4m_init_stream_info (&in_streaminfo);
  y4m_init_stream_info (&out_streaminfo);

  // ***************************************************************
  // Get video stream informations (size, framerate, interlacing, aspect ratio).
  // The streaminfo structure is filled in
  // ***************************************************************
  // INPUT comes from stdin, we check for a correct file header
	if (y4m_read_stream_header (fdIn, &in_streaminfo) != Y4M_OK)
		mjpeg_error_exit1 ("Could'nt read YUV4MPEG header!");

	src_frame_rate = y4m_si_get_framerate( &in_streaminfo );
	y4m_copy_stream_info( &out_streaminfo, &in_streaminfo );
	

  // Information output
  mjpeg_info ("yuvadjust (version " YUVRFPS_VERSION ") is a simple luma and chroma adjustments for yuv streams");
  mjpeg_info ("yuvadjust -? for help");

  /* in that function we do all the important work */
	y4m_write_stream_header(fdOut,&out_streaminfo);

	/* convert hue into radians */
	
	adj_hue = adj_hue / 180 * M_PI;

	/* if black and white levels are set, calculate apropriate con and con_cen value */

	if (adj_lev_blk != -1 && adj_lev_wht != -1 ) {
	
	//	adj_con_cen = (16 - adj_lev_blk);
		adj_con = 224.0 / (adj_lev_wht - adj_lev_blk);  // rise over run
		if (adj_con == 1.0) {
			adj_con_cen = 128;
		} else {
			adj_con_cen = - (( ( adj_lev_blk - 16 ) * adj_con ) / ( 1 - adj_con) - 16 );
		}
	
	fprintf (stderr,"centre: %d contrast: %g\n",adj_con_cen, adj_con);
		
	
	}

// would like gamma, anyone for gamma?

	adjust( fdIn,&in_streaminfo,fdOut,&out_streaminfo,adj_bri,adj_con,adj_con_cen,adj_sat,adj_hue,adj_u,adj_v);

  y4m_fini_stream_info (&in_streaminfo);
  y4m_fini_stream_info (&out_streaminfo);

  return 0;
}
/*
 * Local variables:
 *  tab-width: 8
 *  indent-tabs-mode: nil
 * End:
 */
