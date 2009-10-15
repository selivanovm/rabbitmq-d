// D import file generated from 'src/amqp.d'
import amqp_base;
import amqp_mem;
const 
{
    amqp_bytes_t AMQP_EMPTY_BYTES = {len:0,bytes:null};
}
struct amqp_decimal_t
{
    int decimals;
    uint32_t value;
}
public
{
    static 
{
    amqp_decimal_t AMQP_DECIMAL(int d, uint32_t v)
{
amqp_decimal_t decimal;
decimal.decimals = d;
decimal.value = v;
return decimal;
}
}
}
const 
{
    amqp_table_t AMQP_EMPTY_TABLE = {num_entries:0,entries:null};
}
union VVV
{
    amqp_bytes_t bytes;
    int32_t i32;
    amqp_decimal_t decimal;
    uint64_t u64;
    amqp_table_t table;
}
struct amqp_table_entry_t
{
    amqp_bytes_t key;
    char kind;
    VVV value;
}
struct amqp_table_t
{
    int num_entries;
    amqp_table_entry_t* entries;
}
public
{
    static 
{
    amqp_table_entry_t _AMQP_TE_INIT(amqp_bytes_t ke, char ki, VVV v)
{
amqp_table_entry_t entry;
entry.key = ke;
entry.kind = ki;
entry.value = v;
return entry;
}
}
}
public
{
    static 
{
    amqp_table_entry_t AMQP_TABLE_ENTRY_S(amqp_bytes_t k, VVV v)
{
VVV val;
val.bytes = v.bytes;
return _AMQP_TE_INIT(k,'S',val);
}
}
}
public
{
    static 
{
    amqp_table_entry_t AMQP_TABLE_ENTRY_I(amqp_bytes_t k, VVV v)
{
VVV val;
val.i32 = v.i32;
return _AMQP_TE_INIT(k,'I',val);
}
}
}
public
{
    static 
{
    amqp_table_entry_t AMQP_TABLE_ENTRY_D(amqp_bytes_t k, VVV v)
{
VVV val;
val.decimal = v.decimal;
return _AMQP_TE_INIT(k,'D',val);
}
}
}
public
{
    static 
{
    amqp_table_entry_t AMQP_TABLE_ENTRY_T(amqp_bytes_t k, VVV v)
{
VVV val;
val.u64 = v.u64;
return _AMQP_TE_INIT(k,'T',val);
}
}
}
public
{
    static 
{
    amqp_table_entry_t AMQP_TABLE_ENTRY_F(amqp_bytes_t k, VVV v)
{
VVV val;
val.table = v.table;
return _AMQP_TE_INIT(k,'F',val);
}
}
}
struct amqp_pool_blocklist_t
{
    int num_blocks;
    void** blocklist;
}
struct amqp_pool_t
{
    size_t pagesize;
    amqp_pool_blocklist_t pages;
    amqp_pool_blocklist_t large_blocks;
    int next_page;
    char* alloc_block;
    size_t alloc_used;
}
struct amqp_method_t
{
    amqp_method_number_t id;
    void* decoded;
}
struct properties_
{
    uint16_t class_id;
    uint64_t body_size;
    void* decoded;
}
struct protocol_header_
{
    uint8_t transport_high;
    uint8_t transport_low;
    uint8_t protocol_version_major;
    uint8_t protocol_version_minor;
}
union payload_
{
    amqp_method_t method;
    properties_ properties;
    protocol_header_ protocol_header;
    amqp_bytes_t body_fragment;
}
struct amqp_frame_t
{
    uint8_t frame_type;
    payload_ payload;
    amqp_channel_t channel;
}
enum amqp_response_type_enum 
{
AMQP_RESPONSE_NONE = 0,
AMQP_RESPONSE_NORMAL,
AMQP_RESPONSE_LIBRARY_EXCEPTION,
AMQP_RESPONSE_SERVER_EXCEPTION,
}
struct amqp_rpc_reply_t
{
    amqp_response_type_enum reply_type;
    amqp_method_t reply;
    int library_errno;
}
public
{
    enum amqp_sasl_method_enum 
{
AMQP_SASL_METHOD_PLAIN = 0,
}
}
const 
{
    uint8_t AMQP_PSEUDOFRAME_PROTOCOL_HEADER = 'A';
}
const 
{
    amqp_channel_t AMQP_PSEUDOFRAME_PROTOCOL_CHANNEL = cast(int)'M' << 8 | cast(int)'Q';
}
int function(void* context, void* buffer, size_t count) amqp_output_fn_t;
