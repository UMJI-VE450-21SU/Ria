#include "types.h"

#define CONV2D_FM_DIM     (*((volatile uint32_t*) 0x80000048))
#define CONV2D_WT_OFFSET  (*((volatile uint32_t*) 0x8000004c))
#define CONV2D_IFM_OFFSET (*((volatile uint32_t*) 0x80000050))
#define CONV2D_OFM_OFFSET (*((volatile uint32_t*) 0x80000054))
