#include "verilated.h"
#include "Vtop.h"
#include "svdpi.h"
#include "verilated_fst_c.h"
#include <signal.h>
#include "main.hpp"
using namespace std::chrono;


#define RST_TICK 40
#define SIM_TIME 100
#define SIM_TICK 10000
#define PKG_CNT -1

uint64_t sim_tick = 0;
Vtop *top = nullptr;
VerilatedFstC *tfp = nullptr;


char addr_buf[64];
char *parse_addr(uint32_t addr, uint32_t cnt) {
    uint32_t low = (addr + cnt*8) % 0x1000000;
    switch (addr / 0x1000000) {
        case 1: sprintf(addr_buf, "match[%d]",  low / 128); break;
        case 2: sprintf(addr_buf, "buffer[%d]", low / 2048); break;
        case 3: sprintf(addr_buf, "action[%d]", low / 256); break;
        default: strcpy(addr_buf, "unknown");
    }
    return addr_buf;
}

uint8_t *mem = nullptr;
struct pkg_buf rx[MII_CNT];
struct pkg_buf tx[MII_CNT];

extern "C" {
    uint32_t dev_read (uint32_t raddr) {
        uint32_t *dword = (uint32_t*)&mem[0x100000];
        // printf("dev_read %x = %x\n", raddr, dword[raddr/4]);
        return dword[raddr/4];
    }
    void     dev_write(uint32_t waddr, uint32_t wdata) {
        uint32_t *dword = (uint32_t*)&mem[0x100000];
        if (waddr == 0xc) { wdata |= (dword[3] & 0xff); }
        dword[waddr/4] = wdata;
        // printf("dev_write %x = %x\n", waddr, wdata);
    }
    uint64_t axif_read (uint32_t raddr, uint8_t rcnt,  uint8_t rsize) {
        uint64_t *qword = (uint64_t*)&(mem[raddr]);
        // if (qword[rcnt])
        // printf("read %s (%x, %d) = %lx\n", parse_addr(raddr, rcnt), raddr, rcnt, qword[rcnt]);
        return qword[rcnt];
    }
    void     axif_write(uint32_t waddr, uint64_t wdata, uint8_t wmask, uint8_t wcnt, uint8_t wsize) {
        // assert(0);
        uint64_t *qword = (uint64_t*)&mem[waddr];
        uint8_t  *dst   = (uint8_t*)&qword[wcnt];
        uint8_t  *src   = (uint8_t*)&wdata;
        forrange(i, 8) {
            if (wmask & (1<<i)) {
                dst[i] = src[i];
            }
        }
        // if (qword[wcnt])
        // printf("write %s (%x, %d) = %lx\n", parse_addr(waddr, wcnt), waddr, wcnt, qword[wcnt]);
    }
    void     axis_read (uint8_t no, uint8_t tready, uint8_t *tdata, uint8_t *tvalid, uint8_t *tlast) {
        assert(no < MII_CNT);
        if (rx[no].cnt == 0) {
            *tvalid = 0;
            *tlast  = 0;
            fetch_pkg(no, sim_tick, &rx[no]);
        } else {
            // printf("%ld: %d\n", sim_tick, rx[no].cnt);
            *tvalid = 1;
            *tdata  = rx[no].buf[0];
            *tlast  = rx[no].cnt == 1;
            if (tready) {
                rx[no].buf++;
                rx[no].cnt--;
            }
        }
    }
    void     axis_write(uint8_t no, uint8_t tdata,  uint8_t tlast) {
        // assert(0);
        assert(no < MII_CNT);
        uint32_t *cnt = &(tx[no].cnt);
        tx[no].buf[*cnt] = tdata;
        (*cnt)++;
        assert(*cnt < 2048);
        if (tlast) {
            raise_pkg(no, sim_tick, &tx[no]);
            *cnt = 0;
        }
    }
}

void on_close() {
    if (tfp) {
        tfp->close();
        delete tfp;
        tfp = nullptr;
    }
    host_deinit();
}
void signal_handler(int sig) {
    on_close();
    exit(1);
}

void init_vars() {
    mem = (uint8_t*)malloc(0x4000000);
    assert(mem);
    // memset(mem, 0, 0x4000000);
    memset(rx, 0, sizeof(rx));
    memset(tx, 0, sizeof(tx));
    forlen (i, tx) {
        tx[i].buf = (uint8_t*)malloc(4096);
        assert(tx[i].buf);
    }
    host_init();
}

void init() {
    Verilated::traceEverOn(true);
    init_vars();
    top = new Vtop;
    tfp = new VerilatedFstC;
    top->trace(tfp, 0);
    tfp->open("wave.fst");
    signal(SIGINT, signal_handler);
    signal(SIGABRT, signal_handler);
    atexit(on_close);
}

void reset() {
    top->clock = 0;
    top->reset = 1;
    forrange(i, RST_TICK) {
        top->clock = 1-top->clock;
        top->reset = i != RST_TICK-1;
        top->eval();
        tfp->dump(i);
    }
    init_openflow();
}


int main(int argc, char *argv[]) {
    Verilated::commandArgs(argc, argv);
    
    init();
    reset();

    auto start = steady_clock::now();
    uint64_t duration_ms = 0;

    while (
#if !USE_LIBPCAP
    (sim_tick <= SIM_TICK) && (duration_ms < SIM_TIME) && 
#endif
    (pkg_cnt < PKG_CNT)) {

        duration_ms = duration_cast<milliseconds>(steady_clock::now() - start).count();
        
        top->clock = 1-top->clock;
        top->eval();
        tfp->dump(RST_TICK+sim_tick);
        sim_tick++;
    };

    tfp->close();
    delete tfp;
    tfp = nullptr;
    
    if ((sim_tick >= SIM_TICK) || (duration_ms >= SIM_TIME) || (pkg_cnt >= PKG_CNT)) {
        printf("quit: out of condition\n");
    }
}