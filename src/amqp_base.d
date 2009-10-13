alias uint uint32_t;
alias ushort uint16_t;
alias int int32_t;
alias ulong uint64_t;
alias ubyte uint8_t;

typedef int amqp_boolean_t;
typedef uint32_t amqp_method_number_t;
typedef uint32_t amqp_flags_t;
typedef uint16_t amqp_channel_t;

struct amqp_bytes_t {
  size_t len;
  void *bytes;
};
