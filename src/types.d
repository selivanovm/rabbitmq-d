alias ushort uint16_t;
alias uint uint32_t;
alias int int32_t;
alias amqp_bytes_t_ amqp_bytes_t;
alias amqp_table_t_ amqp_table_t;
alias ubyte uint8_t;
alias ulong uint64_t;
alias amqp_frame_t_ amqp_frame_t;
alias uint32_t amqp_method_number_t;

typedef int amqp_boolean_t;
typedef uint amqp_method_number_t;
typedef uint amqp_flags_t;
typedef short amqp_channel_t;

enum amqp_response_type_enum {
  AMQP_RESPONSE_NONE = 0,
  AMQP_RESPONSE_NORMAL,
  AMQP_RESPONSE_LIBRARY_EXCEPTION,
  AMQP_RESPONSE_SERVER_EXCEPTION
} 

struct amqp_method_t {
  amqp_method_number_t id;
  void *decoded;
}

struct amqp_basic_publish_t
{
  short ticket = 1;
  char[] exchange = "";
  char[] routing_key =  "";
  amqp_boolean_t mandatory = false;
  amqp_boolean_t immediate = false;
  char[] identifier = "";
}

struct amqp_basic_ack_t
{
  long delivery_tag = 0;
  amqp_boolean_t multiple = false;
}

struct amqp_rpc_reply_t {
  amqp_response_type_enum reply_type;
  amqp_method_t reply;
  int library_errno;
} 

