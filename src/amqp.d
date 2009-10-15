import amqp_base;
import amqp_mem;

const amqp_bytes_t AMQP_EMPTY_BYTES  = { len : 0, bytes : null };
struct amqp_decimal_t {
  int decimals;
  uint32_t value;
};

public static amqp_decimal_t AMQP_DECIMAL(int d, uint32_t v) { 
  amqp_decimal_t decimal;
  decimal.decimals = d;
  decimal.value = v;
  return decimal;
}

const amqp_table_t AMQP_EMPTY_TABLE = { num_entries : 0, entries : null };

union VVV {
  amqp_bytes_t bytes;
  int32_t i32;
  amqp_decimal_t decimal;
  uint64_t u64;
  amqp_table_t table;
};

struct amqp_table_entry_t {
  amqp_bytes_t key;
  char kind;
  VVV value;
};

struct amqp_table_t {
  int num_entries;
  amqp_table_entry_t *entries;
};


public static amqp_table_entry_t _AMQP_TE_INIT(amqp_bytes_t ke, char ki, VVV v) 
{ 
  amqp_table_entry_t entry;
  entry.key = ke;
  entry.kind = ki;
  entry.value = v;
  return entry;
}

public static amqp_table_entry_t AMQP_TABLE_ENTRY_S(amqp_bytes_t k, VVV v) 
{
  VVV val;
  val.bytes = v.bytes;
  return _AMQP_TE_INIT(k, 'S', val);
}

public static amqp_table_entry_t AMQP_TABLE_ENTRY_I(amqp_bytes_t k, VVV v)
{
  VVV val;
  val.i32 = v.i32;
  return _AMQP_TE_INIT(k, 'I', val);
}

public static amqp_table_entry_t AMQP_TABLE_ENTRY_D(amqp_bytes_t k, VVV v)
{
  VVV val;
  val.decimal = v.decimal;
  return _AMQP_TE_INIT(k, 'D', val);
}

public static amqp_table_entry_t AMQP_TABLE_ENTRY_T(amqp_bytes_t k, VVV v)
{
  VVV val;
  val.u64 = v.u64;
  return _AMQP_TE_INIT(k, 'T', val);
}

public static amqp_table_entry_t AMQP_TABLE_ENTRY_F(amqp_bytes_t k, VVV v)
{
  VVV val;
  val.table = v.table;
  return _AMQP_TE_INIT(k, 'F', val);
}

struct amqp_pool_blocklist_t {
  int num_blocks;
  void **blocklist;
};

struct amqp_pool_t {
  size_t pagesize;

  amqp_pool_blocklist_t pages;
  amqp_pool_blocklist_t large_blocks;

  int next_page;
  char *alloc_block;
  size_t alloc_used;
};

struct amqp_method_t {
  amqp_method_number_t id;
  void *decoded;
};

struct properties_ {
  uint16_t class_id;
  uint64_t body_size;
  void *decoded;
};

struct protocol_header_ {
  uint8_t transport_high;
  uint8_t transport_low;
  uint8_t protocol_version_major;
  uint8_t protocol_version_minor;
};

union payload_ {
  amqp_method_t method;
  properties_ properties;
  protocol_header_ protocol_header;
  amqp_bytes_t body_fragment;
};

struct amqp_frame_t {
  uint8_t frame_type; /* 0 means no event */
  payload_ payload;
  amqp_channel_t channel;
};

enum amqp_response_type_enum {
  AMQP_RESPONSE_NONE = 0,
  AMQP_RESPONSE_NORMAL,
  AMQP_RESPONSE_LIBRARY_EXCEPTION,
  AMQP_RESPONSE_SERVER_EXCEPTION
};

struct amqp_rpc_reply_t {
  amqp_response_type_enum reply_type;
  amqp_method_t reply;
  int library_errno; /* if AMQP_RESPONSE_LIBRARY_EXCEPTION, then 0 here means socket EOF */
};

public enum amqp_sasl_method_enum {
  AMQP_SASL_METHOD_PLAIN = 0
};

const uint8_t AMQP_PSEUDOFRAME_PROTOCOL_HEADER = 'A';
const amqp_channel_t AMQP_PSEUDOFRAME_PROTOCOL_CHANNEL = (((cast(int) 'M') << 8) | (cast(int) 'Q'));

int function(void *context, void *buffer, size_t count) amqp_output_fn_t;

/* Opaque struct. */
///struct amqp_connection_state_t_ { *amqp_connection_state_t };

/***extern char const *amqp_version(void);

extern void init_amqp_pool(amqp_pool_t *pool, size_t pagesize);
extern void recycle_amqp_pool(amqp_pool_t *pool);
extern void empty_amqp_pool(amqp_pool_t *pool);

extern void *amqp_pool_alloc(amqp_pool_t *pool, size_t amount);
extern void amqp_pool_alloc_bytes(amqp_pool_t *pool, size_t amount, amqp_bytes_t *output);

extern amqp_bytes_t amqp_cstring_bytes(char const *cstr);
extern amqp_bytes_t amqp_bytes_malloc_dup(amqp_bytes_t src);

#define AMQP_BYTES_FREE(b)			\
  ({						\
    if ((b).bytes != NULL) {			\
      free((b).bytes);				\
      (b).bytes = NULL;				\
    }						\
  })

extern amqp_connection_state_t amqp_new_connection(void);
extern int amqp_get_sockfd(amqp_connection_state_t state);
extern void amqp_set_sockfd(amqp_connection_state_t state,
			    int sockfd);
extern int amqp_tune_connection(amqp_connection_state_t state,
				int channel_max,
				int frame_max,
				int heartbeat);
int amqp_get_channel_max(amqp_connection_state_t state);
extern void amqp_destroy_connection(amqp_connection_state_t state);

extern int amqp_handle_input(amqp_connection_state_t state,
			     amqp_bytes_t received_data,
			     amqp_frame_t *decoded_frame);

extern amqp_boolean_t amqp_release_buffers_ok(amqp_connection_state_t state);

extern void amqp_release_buffers(amqp_connection_state_t state);

extern void amqp_maybe_release_buffers(amqp_connection_state_t state);

extern int amqp_send_frame(amqp_connection_state_t state,
			   amqp_frame_t const *frame);
extern int amqp_send_frame_to(amqp_connection_state_t state,
			      amqp_frame_t const *frame,
			      amqp_output_fn_t fn,
			      void *context);

extern int amqp_table_entry_cmp(void const *entry1, void const *entry2);

extern int amqp_open_socket(char const *hostname, int portnumber);

extern int amqp_send_header(amqp_connection_state_t state);
extern int amqp_send_header_to(amqp_connection_state_t state,
			       amqp_output_fn_t fn,
			       void *context);

extern amqp_boolean_t amqp_frames_enqueued(amqp_connection_state_t state);

extern int amqp_simple_wait_frame(amqp_connection_state_t state,
				  amqp_frame_t *decoded_frame);

extern int amqp_simple_wait_method(amqp_connection_state_t state,
				   amqp_channel_t expected_channel,
				   amqp_method_number_t expected_method,
				   amqp_method_t *output);

extern int amqp_send_method(amqp_connection_state_t state,
			    amqp_channel_t channel,
			    amqp_method_number_t id,
			    void *decoded);

extern amqp_rpc_reply_t amqp_simple_rpc(amqp_connection_state_t state,
					amqp_channel_t channel,
					amqp_method_number_t request_id,
					amqp_method_number_t expected_reply_id,
					void *decoded_request_method);


public static void AMQP_SIMPLE_RPC(state, channel, classname, requestname, replyname, structname, ...) 
{									
    structname _simple_rpc_request___ = (structname) { __VA_ARGS__ };	
    amqp_simple_rpc(state, channel,					
		    AMQP_ ## classname ## _ ## requestname ## _METHOD,	
		    AMQP_ ## classname ## _ ## replyname ## _METHOD,	
		    &_simple_rpc_request___);				
}


extern amqp_rpc_reply_t amqp_login(amqp_connection_state_t state,
				   char const *vhost,
				   int channel_max,
				   int frame_max,
				   int heartbeat,
				   amqp_sasl_method_enum sasl_method, ...);

extern amqp_rpc_reply_t amqp_rpc_reply;

extern struct amqp_channel_open_ok_t_ *amqp_channel_open(amqp_connection_state_t state,
							 amqp_channel_t channel);

struct amqp_basic_properties_t_;
extern int amqp_basic_publish(amqp_connection_state_t state,
			      amqp_channel_t channel,
			      amqp_bytes_t exchange,
			      amqp_bytes_t routing_key,
			      amqp_boolean_t mandatory,
			      amqp_boolean_t immediate,
			      struct amqp_basic_properties_t_ const *properties,
			      amqp_bytes_t body);

extern amqp_rpc_reply_t amqp_channel_close(amqp_connection_state_t state,
					   amqp_channel_t channel,
					   int code);
extern amqp_rpc_reply_t amqp_connection_close(amqp_connection_state_t state,
					      int code);

extern struct amqp_exchange_declare_ok_t_ *amqp_exchange_declare(amqp_connection_state_t state,
								 amqp_channel_t channel,
								 amqp_bytes_t exchange,
								 amqp_bytes_t type,
								 amqp_boolean_t passive,
								 amqp_boolean_t durable,
								 amqp_boolean_t auto_delete,
								 amqp_table_t arguments);

extern struct amqp_queue_declare_ok_t_ *amqp_queue_declare(amqp_connection_state_t state,
							   amqp_channel_t channel,
							   amqp_bytes_t queue,
							   amqp_boolean_t passive,
							   amqp_boolean_t durable,
							   amqp_boolean_t exclusive,
							   amqp_boolean_t auto_delete,
							   amqp_table_t arguments);

extern struct amqp_queue_bind_ok_t_ *amqp_queue_bind(amqp_connection_state_t state,
						     amqp_channel_t channel,
						     amqp_bytes_t queue,
						     amqp_bytes_t exchange,
						     amqp_bytes_t routing_key,
						     amqp_table_t arguments);

extern struct amqp_queue_unbind_ok_t_ *amqp_queue_unbind(amqp_connection_state_t state,
							 amqp_channel_t channel,
							 amqp_bytes_t queue,
							 amqp_bytes_t exchange,
							 amqp_bytes_t binding_key,
							 amqp_table_t arguments);

extern struct amqp_basic_consume_ok_t_ *amqp_basic_consume(amqp_connection_state_t state,
							   amqp_channel_t channel,
							   amqp_bytes_t queue,
							   amqp_bytes_t consumer_tag,
							   amqp_boolean_t no_local,
							   amqp_boolean_t no_ack,
							   amqp_boolean_t exclusive);

extern int amqp_basic_ack(amqp_connection_state_t state,
			  amqp_channel_t channel,
			  uint64_t delivery_tag,
			  amqp_boolean_t multiple);

***/
