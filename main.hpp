#ifndef __MAIN_HPP__
#define __MAIN_HPP__

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#define ARRLEN(x) (sizeof(x) / sizeof((x)[0]))
#define forrange(i,r) for (size_t (i)=0; (i) < (r); (i)++)
#define forlen(i,r) forrange((i), ARRLEN(r))
#define foreach(p, arr, ...) do { \
    forlen(i, arr) { \
        typeof ((arr)[0]) *(p) = &((arr)[i]); \
        __VA_ARGS__ \
    } \
} while(0);

static inline void hexdump(void *buf, int len) {
    printf("hexdump %p 0x%x {\n", buf, len);
    forrange (i, len) {
        printf("%02x ", ((uint8_t*)buf)[i]);
        if (i % 16 == 15)
            printf("\n");
    }
    printf("}\n");
}

struct pkg_buf {
    uint8_t *buf;
    uint32_t cnt;
    uint8_t *alloc;
};

extern uint8_t *mem;
extern size_t pkg_cnt;
void host_init();
void host_deinit();
void fetch_pkg(uint8_t no, uint64_t sim_tick, struct pkg_buf *rx);
void raise_pkg(uint8_t no, uint64_t sim_tick, struct pkg_buf *tx);
void init_openflow();

#define MII_CNT 3
#define MTU 1500
#define USE_LIBPCAP 1

#endif