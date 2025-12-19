#include "main.hpp"

// #define mem 0
#define ENTITY_CNT  1024
#define BASE_ADDR   (0x100000)
#define MATCH_ADDR  (0x1000000)
#define BUFFER_ADDR (0x2000000)
#define ACTION_ADDR (0x3000000)

#define OFPAT_OUTPUT        0
#define OFPAT_SET_VLAN_VID  1
#define OFPAT_SET_VLAN_PCP  2
#define OFPAT_STRIP_VLAN    3
#define OFPAT_SET_ETH_SRC   4
#define OFPAT_SET_ETH_DST   5
#define OFPAT_SET_IP_SRC    6
#define OFPAT_SET_IP_DST    7
#define OFPAT_SET_IP_TOS    8
#define OFPAT_SET_TP_SRC    9
#define OFPAT_SET_TP_DST    10
#define OFPAT_EOF           0xcccc

/* Flow wildcards. */
enum ofp_flow_wildcards {
    OFPFW_IN_PORT = 1 << 0, /* Switch input port. */
    OFPFW_VLAN_ID = 1 << 1, /* VLAN id. */
    OFPFW_ETH_SRC = 1 << 2, /* Ethernet source address. */
    OFPFW_ETH_DST = 1 << 3, /* Ethernet destination address. */
    OFPFW_ETH_TYPE = 1 << 4, /* Ethernet frame type. */
    OFPFW_IP_PROTO = 1 << 5, /* IP protocol. */
    OFPFW_TP_SRC = 1 << 6, /* TCP/UDP source port. */
    OFPFW_TP_DST = 1 << 7, /* TCP/UDP destination port. */
    /* IP source address wildcard bit count. 0 is exact match, 1 ignores the
    * LSB, 2 ignores the 2 least-significant bits, ..., 32 and higher wildcard
    * the entire field. This is the *opposite* of the usual convention where
    * e.g. /24 indicates that 8 bits (not 24 bits) are wildcarded. */
    OFPFW_IPV4_SRC_SHIFT = 8,
    OFPFW_IPV4_SRC_BITS = 6,
    OFPFW_IPV4_SRC_MASK = ((1 << OFPFW_IPV4_SRC_BITS) - 1) << OFPFW_IPV4_SRC_SHIFT,
    OFPFW_IPV4_SRC_ALL = 32 << OFPFW_IPV4_SRC_SHIFT,
    /* IP destination address wildcard bit count. Same format as source. */
    OFPFW_IPV4_DST_SHIFT = 14,
    OFPFW_IPV4_DST_BITS = 6,
    OFPFW_IPV4_DST_MASK = ((1 << OFPFW_IPV4_DST_BITS) - 1) << OFPFW_IPV4_DST_SHIFT,
    OFPFW_IPV4_DST_ALL = 32 << OFPFW_IPV4_DST_SHIFT,
    OFPFW_VLAN_PCP = 1 << 20, /* VLAN priority. */
    OFPFW_IP_TOS = 1 << 21, /* IP ToS (DSCP field, 6 bits). */
    /* Wildcard all fields. */
    OFPFW_ALL = ((1 << 22) - 1)
};

typedef struct {
    uint32_t match_addr;
    uint32_t buffer_addr;
    uint32_t action_addr;
    uint32_t status;
    uint64_t tick;
    uint32_t uti_tick;
    uint32_t uti_fifo;
} __attribute__((packed)) device;

typedef struct {
    uint32_t wildcards;
    uint16_t in_port;
    uint8_t  eth_src[6];
    uint8_t  eth_dst[6];
    uint16_t vlan_id;
    uint8_t  vlan_pcp;
    uint8_t  status;
    uint16_t eth_type;
    uint8_t  ip_tos;
    uint8_t  ip_proto;
    uint16_t pad2;
    uint32_t ipv4_src;
    uint32_t ipv4_dst;
    uint16_t tp_src;
    uint16_t tp_dst;
    uint16_t idle_time;
    uint16_t hard_time;
    uint16_t prior;
    uint16_t flags;
    uint64_t cookie;
    uint64_t packet_count;
    uint64_t byte_count;
    uint64_t last_tick;
    uint64_t insert_tick;
} __attribute__((packed)) __attribute__((aligned(128))) of0_t;
    
typedef struct {
    uint16_t type;
    uint16_t len;
    union {
        uint8_t  u8[12];
        uint16_t u16[6];
        uint32_t u32[3];
    };
} __attribute__((packed)) oneact0_t;

typedef struct {
    oneact0_t list[16];
} __attribute__((packed)) act0_t;


uint32_t freq;
volatile device *dev = NULL;
volatile of0_t  *of0 = NULL;
volatile act0_t *act0 = NULL;
uint64_t tick;

void of0_invalid(int i) {
    of0[i].status = 0;
}

void init_fpga_addr() {
    dev = (volatile device*)(mem + BASE_ADDR);
    dev->match_addr  = MATCH_ADDR;
    dev->buffer_addr = BUFFER_ADDR;
    dev->action_addr = ACTION_ADDR;
    freq = (dev->status >> 16) * 1000000;
    printf("freq: %d, tick %ld\n", freq, dev->tick);

    // init_match
    of0 = (volatile of0_t*)(mem + MATCH_ADDR);
    forrange(i, ENTITY_CNT) {
        of0_invalid(i);
    }

    // init_action
    act0 = (volatile act0_t*)(mem + ACTION_ADDR);
    forrange (i, ENTITY_CNT) {
        act0[i].list[0].type = OFPAT_EOF;
    }
}


typedef struct {
    of0_t match;
    act0_t act;
    int act_cnt;
} flowentry_t;

void flowentry_init(flowentry_t *ent) {
    memset(ent, 0, sizeof(flowentry_t));
    ent->match.wildcards = OFPFW_ALL;
}

void match_set_in_port(flowentry_t *ent, uint16_t in_port) {
    ent->match.wildcards &= ~OFPFW_IN_PORT;
    ent->match.in_port = in_port;
}

void match_set_ip_proto(flowentry_t *ent, uint8_t proto) {
    ent->match.wildcards &= ~OFPFW_IP_PROTO;
    ent->match.ip_proto = proto;
}

void match_set_eth_src(flowentry_t *ent, uint8_t *eth_src) {
    ent->match.wildcards &= ~OFPFW_ETH_SRC;
    memcpy(&(ent->match.eth_src), eth_src, 6);
}

void match_set_eth_dst(flowentry_t *ent, uint8_t *eth_dst) {
    ent->match.wildcards &= ~OFPFW_ETH_DST;
    memcpy(&(ent->match.eth_dst), eth_dst, 6);
}

void match_set_ipv4_src(flowentry_t *ent, uint8_t *ip_src, uint32_t ignore_bits) {
    ent->match.wildcards &= ~(OFPFW_IPV4_SRC_MASK);
    ent->match.wildcards |= (ignore_bits << OFPFW_IPV4_SRC_SHIFT);
    memcpy(&(ent->match.ipv4_src), ip_src, 4);
}

void match_set_ipv4_dst(flowentry_t *ent, uint8_t *ip_dst, uint32_t ignore_bits) {
    ent->match.wildcards &= ~(OFPFW_IPV4_DST_MASK);
    ent->match.wildcards |= (ignore_bits << OFPFW_IPV4_DST_SHIFT);
    memcpy(&(ent->match.ipv4_dst), ip_dst, 4);
}

void match_set_priority(flowentry_t *ent, uint16_t priority) {
    ent->match.prior = priority;
}

void match_set_timeout(flowentry_t *ent, uint16_t idle_time, uint16_t hard_time) {
    ent->match.idle_time = idle_time;
    ent->match.hard_time = hard_time;
}

void _match_active(flowentry_t *ent) {
    tick = dev->tick;
    ent->match.last_tick = tick;
    ent->match.insert_tick = tick;
    ent->match.status = 1;
}

void action_set_output(flowentry_t *ent, uint16_t port) {
    ent->act.list[ent->act_cnt].type = OFPAT_OUTPUT;
    ent->act.list[ent->act_cnt].len = 8;
    ent->act.list[ent->act_cnt].u16[0] = port;
    ent->act_cnt++;
}

void action_set_eth_src(flowentry_t *ent, uint8_t *eth_src) {
    ent->act.list[ent->act_cnt].type = OFPAT_SET_ETH_SRC;
    ent->act.list[ent->act_cnt].len  = 16;
    memcpy(ent->act.list[ent->act_cnt].u8, eth_src, 6);
    ent->act_cnt++;
}

void action_set_eth_dst(flowentry_t *ent, uint8_t *eth_dst) {
    ent->act.list[ent->act_cnt].type = OFPAT_SET_ETH_DST;
    ent->act.list[ent->act_cnt].len  = 16;
    memcpy(ent->act.list[ent->act_cnt].u8, eth_dst, 6);
    ent->act_cnt++;
}

void _action_active(flowentry_t *ent) {
    assert(ent->act_cnt < ARRLEN(ent->act.list)-1);
    ent->act.list[ent->act_cnt].type = OFPAT_EOF;
}

void flowentry_insert(flowentry_t *ent, int no) {
    _match_active(ent); 
    _action_active(ent);
    memcpy((void*)&of0[no],  &ent->match, sizeof(ent->match));
    memcpy((void*)&act0[no], &ent->act, sizeof(ent->act));
    printf("insert entry[%d] wildcard %x act %d\n", no, ent->match.wildcards, ent->act_cnt);
}

#define flowtable_new(no, prior, ...) do { \
    flowentry_t self; \
    flowentry_init(&self); \
    match_set_priority(&self, prior); \
    __VA_ARGS__; \
    flowentry_insert(&self, no); \
} while(0);


#include <pthread.h>
void *redirect(void*) {
    flowtable_new(0, 1, {})
    while (1) {
        int i = -1;
        scanf("%d", &i);
        if (i < 0) break;
        flowtable_new(0, 1, {
            match_set_ip_proto(&self, 1);
            // match_set_in_port(&self, 1);
            action_set_output(&self, i);
        })
        printf("all icmp to %d\n", i);
    }
    return NULL;
}
void test_bench() {
    forrange(i, ENTITY_CNT) {
        of0_invalid(i);
    }
    pthread_t t1;
    pthread_create(&t1, NULL, redirect, NULL);
}

uint8_t ip_range[] = {0x1, 0x14, 0xa8, 0xc0};
uint8_t fake_mac[6] = {0xBC, 0x9A, 0x78, 0x56, 0x34, 0x12};
uint8_t ip_1cn[] = {91, 44, 54, 112};
uint8_t ip_3cn[] = {153, 164, 39, 106};
void init_my_rule() {
    // flowtable_new(0, 5, {
    //     match_set_ipv4_dst(&self, ip_range, 8);
    //     action_set_output(&self, 0);
    //     action_set_eth_src(&self, fake_mac);
    //     flowentry_insert(&self, 0);
    // })
    flowtable_new(1, 10, {
        match_set_ipv4_dst(&self, ip_1cn, 0);
        action_set_output(&self, 1);
    })
    flowtable_new(2, 10, {
        match_set_ipv4_src(&self, ip_1cn, 0);
        action_set_output(&self, 1);
    })
    flowtable_new(3, 5, {
        match_set_ipv4_dst(&self, ip_3cn, 0);
        action_set_eth_dst(&self, fake_mac);
        action_set_output(&self, 2);
    })
    flowtable_new(4, 15, {
        match_set_ip_proto(&self, 1);
        action_set_output(&self, 2);
    })
    // test_bench();
}

void init_openflow() {
    init_fpga_addr();
    init_my_rule();
    dev->status = 1;
    printf("fpga status: %x\n", (uint16_t)dev->status);
}