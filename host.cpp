#include "main.hpp"

uint8_t example[] = {
    0xb0, 0x25, 0xaa, 0x2e, 0xd1, 0xe7,     // ETH_DST
    0x1c, 0xb7, 0x2c, 0xd5, 0xdc, 0xe4,     // ETH_SRC
    0x08, 0x00, // ETH_TYPE: IPv4
    
    0x45, // 0100 Version 4, 0101 Header 20 byte
    0x00, // Not ECN-Capable
    0x00, 0x34,     // total length: 52
    0x1a, 0xf1,     // Identification: 6879
    0x40, 0x00,     // Flags 0x2, Don't fragment, offset: 0
    0x30,   // TTL: 48
    0x06,   // TCP: 6
    0x48, 0x40,     // checksum
    0x3a, 0xcd, 0xd7, 0x91,     // IP_SRC 58.205.215.145
    0xc0, 0xa8, 0x14, 0x8c,     // IP_DST 192.168.20.140
    
    0x01, 0xbb,     // TP_SRC: 443
    0xa8, 0xc2,     // TP_DST: 43202
    0x9a, 0x59, 0x70, 0x92, 0xc9, 0xae, 0xc0, 0x12, 0x80, 0x10,
    0x00, 0x36, 0xa5, 0xf5, 0x00, 0x00, 0x01, 0x01, 0x08, 0x0a, 
    0x4b, 0x9a, 0x28, 0x99, 0x0b, 0x59, 0x2a, 0x47,
};

bool tested = false;
void test_pkg_mem() {
    printf("%d\n", memcmp(example, &mem[0x2000000], sizeof(example)));
    hexdump(example, sizeof(example));
    hexdump(&mem[0x2000000], sizeof(example));
}


size_t pkg_cnt = 0;
#if USE_LIBPCAP
#include <pcap.h>
#include <thread>
#include <mutex>
#include <queue>
pcap_t *handle = nullptr;
std::mutex mtx;
std::queue<struct pkg_buf*> q;

#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/if.h>
#include <linux/if_tun.h>
int tap_fd[MII_CNT];
#endif

void fetch_pkg(uint8_t no, uint64_t sim_tick, struct pkg_buf *rx) {
#if !USE_LIBPCAP
    if (no == 1 & (sim_tick > 100) & (sim_tick < 150)) {
        rx->cnt = sizeof(example);
        rx->buf = example;
        pkg_cnt++;
        printf("send pkg[%d](%d) at %ld: \n", no, rx->cnt, sim_tick);
    }
    if (!tested && (sim_tick > 1000)) {
        test_pkg_mem();
        tested = true;
    }
    if (no == 0 & (sim_tick > 2000) & (sim_tick < 2050)) {
        rx->cnt = 1318;
        rx->buf = (uint8_t*)calloc(1, rx->cnt);
        pkg_cnt++;
        printf("send pkg[%d](%d) at %ld: \n", no, rx->cnt, sim_tick);
    }
#else
    assert(no < MII_CNT);
    if (rx->alloc) {
        free(rx->alloc);
        rx->alloc = nullptr;
    }
    struct pkg_buf *b = nullptr;
    if (no == 0) {
        // receive_from_monitor();
    } else {
        mtx.lock();
        if (q.size()) {
            b = q.front();
            q.pop();
            pkg_cnt++;
        }
        mtx.unlock();
    }
    if (b) {
        rx->cnt = b->cnt;
        rx->buf = b->buf;
        rx->alloc = b->buf;
        // printf("send pkg[%d](%d) at %ld: \n", no, rx->cnt, sim_tick);
        // hexdump(b->buf, b->cnt);
    }
#endif
}

void raise_pkg(uint8_t no, uint64_t sim_tick, struct pkg_buf *tx) {
    if (no == 0) {
        printf("talk to monitor (%d) at %ld: \n", tx->cnt, sim_tick);
    } else {
        printf("receive pkg[%d](%d) at %ld: \n", no, tx->cnt, sim_tick);
    }
#if !USE_LIBPCAP
    hexdump(tx->buf, tx->cnt);
#else
    int ret = write(tap_fd[no], tx->buf, tx->cnt);
    assert(ret == tx->cnt);
#endif
}

#if USE_LIBPCAP
void packet_handler(u_char *user, const struct pcap_pkthdr *header, const u_char *packet) {
    assert (header->len <= MTU);
    printf("got pkg(%d)\n", header->len);
    struct pkg_buf *b = (struct pkg_buf*)malloc(sizeof(struct pkg_buf));
    assert(b);
    b->cnt = header->len;
    b->buf = (uint8_t*)malloc(header->len);
    assert(b->buf);
    memcpy(b->buf, packet, header->len);
    mtx.lock();
    q.push(b);
    mtx.unlock();
}

void pcap_init() {
    int ret;
    char errbuf[PCAP_ERRBUF_SIZE];
    char *dev = pcap_lookupdev(errbuf);
    assert(dev);
    printf("using device %s\n", dev);

    handle = pcap_open_live(dev, 65535, 1, 100, errbuf);
    assert(handle);

    struct bpf_program fp;
    char filter_exp[] = "host 112.54.44.91 or icmp";
    ret = pcap_compile(handle, &fp, filter_exp, 0, PCAP_NETMASK_UNKNOWN);
    assert(ret != -1);
    ret = pcap_setfilter(handle, &fp);
    assert(ret != -1);

    std::thread t([&]() {
        pcap_loop(handle, -1, packet_handler, nullptr);
    });
    t.detach();
}

void pcap_deinit() {
    if (handle) {
        pcap_close(handle);
        handle = NULL;
    }
}

int safe_system(char *cmd) {
    int ret = system(cmd);
    assert(ret != -1);
    assert(WIFEXITED(ret));
    assert(WEXITSTATUS(ret) == 0);
    return ret;
}

void tap_init() {
    // sudo ethtool -K eth0 tso off gso off gro off lro off
    memset(tap_fd, -1, sizeof(tap_fd));
    forlen (i, tap_fd) {
        int ret;
        struct ifreq ifr;
        int fd = open("/dev/net/tun", O_RDWR);
        assert(fd >= 0);

        memset(&ifr, 0, sizeof(ifr));
        // TAP 设备, 不附加协议头
        ifr.ifr_flags = IFF_TAP | IFF_NO_PI;
        snprintf(ifr.ifr_name, IFNAMSIZ, "tap_%ld", i);

        ret = ioctl(fd, TUNSETIFF, &ifr);
        assert(ret != -1);
        printf("create device: %s\n", ifr.ifr_name);

        char cmd[256];
        snprintf(cmd, sizeof(cmd), "ip link set tap_%ld up", i);
        safe_system(cmd);
        tap_fd[i] = fd;
    }
}

void tap_deinit() {
    forlen (i, tap_fd) {
        if (tap_fd[i] != -1) {
            close(tap_fd[i]);
            tap_fd[i] = -1;
        }
    }
}

void host_init() {
    pcap_init();
    tap_init();
}
void host_deinit() {
    pcap_deinit();
    tap_deinit();
}
#else
void host_init() {}
void host_deinit() {}
#endif
