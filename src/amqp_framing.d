import amqp;
import amqp_base;

const uint AMQP_PROTOCOL_VERSION_MAJOR = 8;
const uint AMQP_PROTOCOL_VERSION_MINOR = 0;
const uint AMQP_PROTOCOL_PORT = 5672;
const uint AMQP_FRAME_OOB_HEADER = 5;
const uint AMQP_FRAME_TRACE = 7;
const uint AMQP_NOT_DELIVERED = 310;
const uint AMQP_FRAME_OOB_BODY = 6;
const uint AMQP_REPLY_SUCCESS = 200;
const uint AMQP_FRAME_MIN_SIZE = 4096;
const uint AMQP_FRAME_METHOD = 1;
const uint AMQP_RESOURCE_LOCKED = 405;
const uint AMQP_NO_ROUTE = 312;
const uint AMQP_FRAME_BODY = 3;
const uint AMQP_CONTENT_TOO_LARGE = 311;
const uint AMQP_FRAME_HEADER = 2;
const uint AMQP_FRAME_HEARTBEAT = 8;
const uint AMQP_ACCESS_REFUSED = 403;
const uint AMQP_INTERNAL_ERROR = 541;
const uint AMQP_NO_CONSUMERS = 313;
const uint AMQP_CONNECTION_FORCED = 320;
const uint AMQP_NOT_FOUND = 404;
const uint AMQP_NOT_IMPLEMENTED = 540;
const uint AMQP_COMMAND_INVALID = 503;
const uint AMQP_PRECONDITION_FAILED = 406;
const uint AMQP_CHANNEL_ERROR = 504;
const uint AMQP_FRAME_OOB_METHOD = 4;
const uint AMQP_RESOURCE_ERROR = 506;
const uint AMQP_FRAME_END = 206;
const uint AMQP_SYNTAX_ERROR = 502;
const uint AMQP_INVALID_PATH = 402;
const uint AMQP_FRAME_ERROR = 501;
const uint AMQP_NOT_ALLOWED = 530;

/* Method field records. */
const amqp_method_number_t AMQP_QUEUE_DECLARE_METHOD = 0x0032000A; /* 50, 10; 3276810 */
struct amqp_queue_declare_t {
  uint16_t ticket;
  amqp_bytes_t queue;
  amqp_boolean_t passive;
  amqp_boolean_t durable;
  amqp_boolean_t exclusive;
  amqp_boolean_t auto_delete;
  amqp_boolean_t nowait;
  amqp_table_t arguments;
};

const amqp_method_number_t AMQP_QUEUE_DECLARE_OK_METHOD = 0x0032000B; /* 50, 11; 3276811 */
struct amqp_queue_declare_ok_t_ {
  amqp_bytes_t queue;
  uint32_t message_count;
  uint32_t consumer_count;
};

const amqp_method_number_t AMQP_QUEUE_BIND_METHOD = 0x00320014;/* 50, 20; 3276820 */
struct amqp_queue_bind_t {
  uint16_t ticket;
  amqp_bytes_t queue;
  amqp_bytes_t exchange;
  amqp_bytes_t routing_key;
  amqp_boolean_t nowait;
  amqp_table_t arguments;
};

const amqp_method_number_t AMQP_QUEUE_BIND_OK_METHOD = 0x00320015; /* 50, 21; 3276821 */
struct amqp_queue_bind_ok_t {
};

const amqp_method_number_t AMQP_QUEUE_PURGE_METHOD = 0x0032001E; /* 50, 30; 3276830 */
struct amqp_queue_purge_t {
  uint16_t ticket;
  amqp_bytes_t queue;
  amqp_boolean_t nowait;
};

const amqp_method_number_t AMQP_QUEUE_PURGE_OK_METHOD = 0x0032001F; /* 50, 31; 3276831 */
struct amqp_queue_purge_ok_t {
  uint32_t message_count;
};

const amqp_method_number_t AMQP_QUEUE_DELETE_METHOD = 0x00320028; /* 50, 40; 3276840 */
struct amqp_queue_delete_t {
  uint16_t ticket;
  amqp_bytes_t queue;
  amqp_boolean_t if_unused;
  amqp_boolean_t if_empty;
  amqp_boolean_t nowait;
};

const amqp_method_number_t AMQP_QUEUE_DELETE_OK_METHOD = 0x00320029; /* 50, 41; 3276841 */
struct amqp_queue_delete_ok_t {
  uint32_t message_count;
};

const amqp_method_number_t AMQP_QUEUE_UNBIND_METHOD = 0x00320032; /* 50, 50; 3276850 */
struct amqp_queue_unbind_t {
  uint16_t ticket;
  amqp_bytes_t queue;
  amqp_bytes_t exchange;
  amqp_bytes_t routing_key;
  amqp_table_t arguments;
};

const amqp_method_number_t AMQP_QUEUE_UNBIND_OK_METHOD = 0x00320033; /* 50, 51; 3276851 */
struct amqp_queue_unbind_ok_t {
};

const amqp_method_number_t AMQP_TX_SELECT_METHOD = 0x005A000A; /* 90, 10; 5898250 */
struct amqp_tx_select_t {
};

const amqp_method_number_t AMQP_TX_SELECT_OK_METHOD = 0x005A000B; /* 90, 11; 5898251 */
struct amqp_tx_select_ok_t {
};

const amqp_method_number_t AMQP_TX_COMMIT_METHOD = 0x005A0014; /* 90, 20; 5898260 */
struct amqp_tx_commit_t {
};

const amqp_method_number_t AMQP_TX_COMMIT_OK_METHOD = 0x005A0015; /* 90, 21; 5898261 */
struct amqp_tx_commit_ok_t {
};

const amqp_method_number_t AMQP_TX_ROLLBACK_METHOD = 0x005A001E; /* 90, 30; 5898270 */
struct amqp_tx_rollback_t {
};

const amqp_method_number_t AMQP_TX_ROLLBACK_OK_METHOD = 0x005A001F; /* 90, 31; 5898271 */
struct amqp_tx_rollback_ok_t {
};

const amqp_method_number_t AMQP_STREAM_QOS_METHOD = 0x0050000A; /* 80, 10; 5242890 */
struct amqp_stream_qos_t {
  uint32_t prefetch_size;
  uint16_t prefetch_count;
  uint32_t consume_rate;
  amqp_boolean_t global;
};

const amqp_method_number_t AMQP_STREAM_QOS_OK_METHOD = 0x0050000B; /* 80, 11; 5242891 */
struct amqp_stream_qos_ok_t {
};

const amqp_method_number_t AMQP_STREAM_CONSUME_METHOD = 0x00500014; /* 80, 20; 5242900 */
struct amqp_stream_consume_t {
  uint16_t ticket;
  amqp_bytes_t queue;
  amqp_bytes_t consumer_tag;
  amqp_boolean_t no_local;
  amqp_boolean_t exclusive;
  amqp_boolean_t nowait;
};

const amqp_method_number_t AMQP_STREAM_CONSUME_OK_METHOD = 0x00500015; /* 80, 21; 5242901 */
struct amqp_stream_consume_ok_t {
  amqp_bytes_t consumer_tag;
};

const amqp_method_number_t AMQP_STREAM_CANCEL_METHOD = 0x0050001E; /* 80, 30; 5242910 */
struct amqp_stream_cancel_t {
  amqp_bytes_t consumer_tag;
  amqp_boolean_t nowait;
};

const amqp_method_number_t AMQP_STREAM_CANCEL_OK_METHOD = 0x0050001F; /* 80, 31; 5242911 */
struct amqp_stream_cancel_ok_t {
  amqp_bytes_t consumer_tag;
};

const amqp_method_number_t AMQP_STREAM_PUBLISH_METHOD = 0x00500028; /* 80, 40; 5242920 */
struct amqp_stream_publish_t {
  uint16_t ticket;
  amqp_bytes_t exchange;
  amqp_bytes_t routing_key;
  amqp_boolean_t mandatory;
  amqp_boolean_t immediate;
};

const amqp_method_number_t AMQP_STREAM_RETURN_METHOD = 0x00500032; /* 80, 50; 5242930 */
struct amqp_stream_return_t {
  uint16_t reply_code;
  amqp_bytes_t reply_text;
  amqp_bytes_t exchange;
  amqp_bytes_t routing_key;
};

const amqp_method_number_t AMQP_STREAM_DELIVER_METHOD = 0x0050003C; /* 80, 60; 5242940 */
struct amqp_stream_deliver_t {
  amqp_bytes_t consumer_tag;
  uint64_t delivery_tag;
  amqp_bytes_t exchange;
  amqp_bytes_t queue;
};

const amqp_method_number_t AMQP_EXCHANGE_DECLARE_METHOD = 0x0028000A; /* 40, 10; 2621450 */
struct amqp_exchange_declare_t {
  uint16_t ticket;
  amqp_bytes_t exchange;
  amqp_bytes_t type;
  amqp_boolean_t passive;
  amqp_boolean_t durable;
  amqp_boolean_t auto_delete;
  amqp_boolean_t internal;
  amqp_boolean_t nowait;
  amqp_table_t arguments;
};

const amqp_method_number_t AMQP_EXCHANGE_DECLARE_OK_METHOD = 0x0028000B; /* 40, 11; 2621451 */
struct amqp_exchange_declare_ok_t {
};

const amqp_method_number_t AMQP_EXCHANGE_DELETE_METHOD = 0x00280014; /* 40, 20; 2621460 */
struct amqp_exchange_delete_t {
  uint16_t ticket;
  amqp_bytes_t exchange;
  amqp_boolean_t if_unused;
  amqp_boolean_t nowait;
};

const amqp_method_number_t AMQP_EXCHANGE_DELETE_OK_METHOD = 0x00280015; /* 40, 21; 2621461 */
struct amqp_exchange_delete_ok_t {
};

const amqp_method_number_t AMQP_TUNNEL_REQUEST_METHOD = 0x006E000A; /* 110, 10; 7208970 */
struct amqp_tunnel_request_t {
  amqp_table_t meta_data;
};

const amqp_method_number_t AMQP_ACCESS_REQUEST_METHOD = 0x001E000A; /* 30, 10; 1966090 */
struct amqp_access_request_t {
  amqp_bytes_t realm;
  amqp_boolean_t exclusive;
  amqp_boolean_t passive;
  amqp_boolean_t active;
  amqp_boolean_t write;
  amqp_boolean_t read;
};

const amqp_method_number_t AMQP_ACCESS_REQUEST_OK_METHOD = 0x001E000B; /* 30, 11; 1966091 */
struct amqp_access_request_ok_t {
  uint16_t ticket;
};

const amqp_method_number_t AMQP_CONNECTION_START_METHOD = 0x000A000A; /* 10, 10; 655370 */
struct amqp_connection_start_t {
  uint8_t version_major;
  uint8_t version_minor;
  amqp_table_t server_properties;
  amqp_bytes_t mechanisms;
  amqp_bytes_t locales;
};

const amqp_method_number_t AMQP_CONNECTION_START_OK_METHOD = 0x000A000B; /* 10, 11; 655371 */
struct amqp_connection_start_ok_t {
  amqp_table_t client_properties;
  amqp_bytes_t mechanism;
  amqp_bytes_t response;
  amqp_bytes_t locale;
};

const amqp_method_number_t AMQP_CONNECTION_SECURE_METHOD = 0x000A0014; /* 10, 20; 655380 */
struct amqp_connection_secure_t {
  amqp_bytes_t challenge;
};

const amqp_method_number_t AMQP_CONNECTION_SECURE_OK_METHOD = 0x000A0015; /* 10, 21; 655381 */
struct amqp_connection_secure_ok_t {
  amqp_bytes_t response;
};

const amqp_method_number_t AMQP_CONNECTION_TUNE_METHOD = 0x000A001E; /* 10, 30; 655390 */
struct amqp_connection_tune_t {
  uint16_t channel_max;
  uint32_t frame_max;
  uint16_t heartbeat;
};

const amqp_method_number_t AMQP_CONNECTION_TUNE_OK_METHOD = 0x000A001F; /* 10, 31; 655391 */
struct amqp_connection_tune_ok_t {
  uint16_t channel_max;
  uint32_t frame_max;
  uint16_t heartbeat;
};

const amqp_method_number_t AMQP_CONNECTION_OPEN_METHOD = 0x000A0028; /* 10, 40; 655400 */
struct amqp_connection_open_t {
  amqp_bytes_t virtual_host;
  amqp_bytes_t capabilities;
  amqp_boolean_t insist;
};

const amqp_method_number_t AMQP_CONNECTION_OPEN_OK_METHOD = 0x000A0029; /* 10, 41; 655401 */
struct amqp_connection_open_ok_t {
  amqp_bytes_t known_hosts;
};

const amqp_method_number_t AMQP_CONNECTION_REDIRECT_METHOD = 0x000A0032; /* 10, 50; 655410 */
struct amqp_connection_redirect_t {
  amqp_bytes_t host;
  amqp_bytes_t known_hosts;
};

const amqp_method_number_t AMQP_CONNECTION_CLOSE_METHOD = 0x000A003C; /* 10, 60; 655420 */
struct amqp_connection_close_t {
  uint16_t reply_code;
  amqp_bytes_t reply_text;
  uint16_t class_id;
  uint16_t method_id;
};

const amqp_method_number_t AMQP_CONNECTION_CLOSE_OK_METHOD = 0x000A003D; /* 10, 61; 655421 */
struct amqp_connection_close_ok_t {
};

const amqp_method_number_t AMQP_DTX_SELECT_METHOD = 0x0064000A; /* 100, 10; 6553610 */
struct amqp_dtx_select_t {
};

const amqp_method_number_t AMQP_DTX_SELECT_OK_METHOD = 0x0064000B; /* 100, 11; 6553611 */
struct amqp_dtx_select_ok_t {
};

const amqp_method_number_t AMQP_DTX_START_METHOD = 0x00640014; /* 100, 20; 6553620 */
struct amqp_dtx_start_t {
  amqp_bytes_t dtx_identifier;
};

const amqp_method_number_t AMQP_DTX_START_OK_METHOD = 0x00640015; /* 100, 21; 6553621 */
struct amqp_dtx_start_ok_t {
};

const amqp_method_number_t AMQP_FILE_QOS_METHOD = 0x0046000A; /* 70, 10; 4587530 */
struct amqp_file_qos_t {
  uint32_t prefetch_size;
  uint16_t prefetch_count;
  amqp_boolean_t global;
};

const amqp_method_number_t AMQP_FILE_QOS_OK_METHOD = 0x0046000B; /* 70, 11; 4587531 */
struct amqp_file_qos_ok_t {
};

const amqp_method_number_t AMQP_FILE_CONSUME_METHOD = 0x00460014; /* 70, 20; 4587540 */
struct amqp_file_consume_t {
  uint16_t ticket;
  amqp_bytes_t queue;
  amqp_bytes_t consumer_tag;
  amqp_boolean_t no_local;
  amqp_boolean_t no_ack;
  amqp_boolean_t exclusive;
  amqp_boolean_t nowait;
};

const amqp_method_number_t AMQP_FILE_CONSUME_OK_METHOD = 0x00460015; /* 70, 21; 4587541 */
struct amqp_file_consume_ok_t {
  amqp_bytes_t consumer_tag;
};

const amqp_method_number_t AMQP_FILE_CANCEL_METHOD = 0x0046001E; /* 70, 30; 4587550 */
struct amqp_file_cancel_t {
  amqp_bytes_t consumer_tag;
  amqp_boolean_t nowait;
};

const amqp_method_number_t AMQP_FILE_CANCEL_OK_METHOD = 0x0046001F; /* 70, 31; 4587551 */
struct amqp_file_cancel_ok_t {
  amqp_bytes_t consumer_tag;
};

const amqp_method_number_t AMQP_FILE_OPEN_METHOD = 0x00460028; /* 70, 40; 4587560 */
struct amqp_file_open_t {
  amqp_bytes_t identifier;
  uint64_t content_size;
};

const amqp_method_number_t AMQP_FILE_OPEN_OK_METHOD = 0x00460029; /* 70, 41; 4587561 */
struct amqp_file_open_ok_t {
  uint64_t staged_size;
};

const amqp_method_number_t AMQP_FILE_STAGE_METHOD = 0x00460032; /* 70, 50; 4587570 */
struct amqp_file_stage_t {
};

const amqp_method_number_t AMQP_FILE_PUBLISH_METHOD = 0x0046003C; /* 70, 60; 4587580 */
struct amqp_file_publish_t {
  uint16_t ticket;
  amqp_bytes_t exchange;
  amqp_bytes_t routing_key;
  amqp_boolean_t mandatory;
  amqp_boolean_t immediate;
  amqp_bytes_t identifier;
};

const amqp_method_number_t AMQP_FILE_RETURN_METHOD = 0x00460046; /* 70, 70; 4587590 */
struct amqp_file_return_t {
  uint16_t reply_code;
  amqp_bytes_t reply_text;
  amqp_bytes_t exchange;
  amqp_bytes_t routing_key;
};

const amqp_method_number_t AMQP_FILE_DELIVER_METHOD = 0x00460050; /* 70, 80; 4587600 */
struct amqp_file_deliver_t {
  amqp_bytes_t consumer_tag;
  uint64_t delivery_tag;
  amqp_boolean_t redelivered;
  amqp_bytes_t exchange;
  amqp_bytes_t routing_key;
  amqp_bytes_t identifier;
};

const amqp_method_number_t AMQP_FILE_ACK_METHOD = 0x0046005A; /* 70, 90; 4587610 */
struct amqp_file_ack_t {
  uint64_t delivery_tag;
  amqp_boolean_t multiple;
};

const amqp_method_number_t AMQP_FILE_REJECT_METHOD = 0x00460064; /* 70, 100; 4587620 */
struct amqp_file_reject_t {
  uint64_t delivery_tag;
  amqp_boolean_t requeue;
};

const amqp_method_number_t AMQP_BASIC_QOS_METHOD = 0x003C000A; /* 60, 10; 3932170 */
struct amqp_basic_qos_t {
  uint32_t prefetch_size;
  uint16_t prefetch_count;
  amqp_boolean_t global;
};

const amqp_method_number_t AMQP_BASIC_QOS_OK_METHOD = 0x003C000B; /* 60, 11; 3932171 */
struct amqp_basic_qos_ok_t {
};

const amqp_method_number_t AMQP_BASIC_CONSUME_METHOD = 0x003C0014; /* 60, 20; 3932180 */
struct amqp_basic_consume_t {
  uint16_t ticket;
  amqp_bytes_t queue;
  amqp_bytes_t consumer_tag;
  amqp_boolean_t no_local;
  amqp_boolean_t no_ack;
  amqp_boolean_t exclusive;
  amqp_boolean_t nowait;
};

const amqp_method_number_t AMQP_BASIC_CONSUME_OK_METHOD = 0x003C0015; /* 60, 21; 3932181 */
struct amqp_basic_consume_ok_t {
  amqp_bytes_t consumer_tag;
};

const amqp_method_number_t AMQP_BASIC_CANCEL_METHOD = 0x003C001E; /* 60, 30; 3932190 */
struct amqp_basic_cancel_t {
  amqp_bytes_t consumer_tag;
  amqp_boolean_t nowait;
};

const amqp_method_number_t AMQP_BASIC_CANCEL_OK_METHOD = 0x003C001F; /* 60, 31; 3932191 */
struct amqp_basic_cancel_ok_t {
  amqp_bytes_t consumer_tag;
};

const amqp_method_number_t AMQP_BASIC_PUBLISH_METHOD = 0x003C0028; /* 60, 40; 3932200 */
struct amqp_basic_publish_t {
  uint16_t ticket;
  amqp_bytes_t exchange;
  amqp_bytes_t routing_key;
  amqp_boolean_t mandatory;
  amqp_boolean_t immediate;
};

const amqp_method_number_t AMQP_BASIC_RETURN_METHOD = 0x003C0032; /* 60, 50; 3932210 */
struct amqp_basic_return_t {
  uint16_t reply_code;
  amqp_bytes_t reply_text;
  amqp_bytes_t exchange;
  amqp_bytes_t routing_key;
};

const amqp_method_number_t AMQP_BASIC_DELIVER_METHOD = 0x003C003C; /* 60, 60; 3932220 */
struct amqp_basic_deliver_t {
  amqp_bytes_t consumer_tag;
  uint64_t delivery_tag;
  amqp_boolean_t redelivered;
  amqp_bytes_t exchange;
  amqp_bytes_t routing_key;
};

const amqp_method_number_t AMQP_BASIC_GET_METHOD = 0x003C0046; /* 60, 70; 3932230 */
struct amqp_basic_get_t {
  uint16_t ticket;
  amqp_bytes_t queue;
  amqp_boolean_t no_ack;
};

const amqp_method_number_t AMQP_BASIC_GET_OK_METHOD = 0x003C0047; /* 60, 71; 3932231 */
struct amqp_basic_get_ok_t {
  uint64_t delivery_tag;
  amqp_boolean_t redelivered;
  amqp_bytes_t exchange;
  amqp_bytes_t routing_key;
  uint32_t message_count;
};

const amqp_method_number_t AMQP_BASIC_GET_EMPTY_METHOD = 0x003C0048; /* 60, 72; 3932232 */
struct amqp_basic_get_empty_t {
  amqp_bytes_t cluster_id;
};

const amqp_method_number_t AMQP_BASIC_ACK_METHOD = 0x003C0050; /* 60, 80; 3932240 */
struct amqp_basic_ack_t {
  uint64_t delivery_tag;
  amqp_boolean_t multiple;
};

const amqp_method_number_t AMQP_BASIC_REJECT_METHOD = 0x003C005A; /* 60, 90; 3932250 */
struct amqp_basic_reject_t {
  uint64_t delivery_tag;
  amqp_boolean_t requeue;
};

const amqp_method_number_t AMQP_BASIC_RECOVER_METHOD = 0x003C0064; /* 60, 100; 3932260 */
struct amqp_basic_recover_t {
  amqp_boolean_t requeue;
};

const amqp_method_number_t AMQP_TEST_INTEGER_METHOD = 0x0078000A; /* 120, 10; 7864330 */
struct amqp_test_integer_t {
  uint8_t integer_1;
  uint16_t integer_2;
  uint32_t integer_3;
  uint64_t integer_4;
  uint8_t operation;
};

const amqp_method_number_t AMQP_TEST_INTEGER_OK_METHOD = 0x0078000B; /* 120, 11; 7864331 */
struct amqp_test_integer_ok_t {
  uint64_t result;
};

const amqp_method_number_t AMQP_TEST_STRING_METHOD = 0x00780014; /* 120, 20; 7864340 */
struct amqp_test_string_t {
  amqp_bytes_t string_1;
  amqp_bytes_t string_2;
  uint8_t operation;
};

const amqp_method_number_t AMQP_TEST_STRING_OK_METHOD = 0x00780015; /* 120, 21; 7864341 */
struct amqp_test_string_ok_t {
  amqp_bytes_t result;
};

const amqp_method_number_t AMQP_TEST_TABLE_METHOD = 0x0078001E; /* 120, 30; 7864350 */
struct amqp_test_table_t {
  amqp_table_t table;
  uint8_t integer_op;
  uint8_t string_op;
};

const amqp_method_number_t AMQP_TEST_TABLE_OK_METHOD = 0x0078001F; /* 120, 31; 7864351 */
struct amqp_test_table_ok_t {
  uint64_t integer_result;
  amqp_bytes_t string_result;
};

const amqp_method_number_t AMQP_TEST_CONTENT_METHOD = 0x00780028; /* 120, 40; 7864360 */
struct amqp_test_content_t {
};

const amqp_method_number_t AMQP_TEST_CONTENT_OK_METHOD = 0x00780029; /* 120, 41; 7864361 */
struct amqp_test_content_ok_t {
  uint32_t content_checksum;
};

const amqp_method_number_t AMQP_CHANNEL_OPEN_METHOD = 0x0014000A; /* 20, 10; 1310730 */
struct amqp_channel_open_t {
  amqp_bytes_t out_of_band;
};

const amqp_method_number_t AMQP_CHANNEL_OPEN_OK_METHOD = 0x0014000B; /* 20, 11; 1310731 */
struct amqp_channel_open_ok_t {
};

const amqp_method_number_t AMQP_CHANNEL_FLOW_METHOD = 0x00140014; /* 20, 20; 1310740 */
struct amqp_channel_flow_t {
  amqp_boolean_t active;
};

const amqp_method_number_t AMQP_CHANNEL_FLOW_OK_METHOD = 0x00140015; /* 20, 21; 1310741 */
struct amqp_channel_flow_ok_t {
  amqp_boolean_t active;
};

const amqp_method_number_t AMQP_CHANNEL_ALERT_METHOD = 0x0014001E; /* 20, 30; 1310750 */
struct amqp_channel_alert_t {
  uint16_t reply_code;
  amqp_bytes_t reply_text;
  amqp_table_t details;
};

const amqp_method_number_t AMQP_CHANNEL_CLOSE_METHOD = 0x00140028; /* 20, 40; 1310760 */
struct amqp_channel_close_t {
  uint16_t reply_code;
  amqp_bytes_t reply_text;
  uint16_t class_id;
  uint16_t method_id;
};

const amqp_method_number_t AMQP_CHANNEL_CLOSE_OK_METHOD = 0x00140029; /* 20, 41; 1310761 */
struct amqp_channel_close_ok_t {
};

/* Class property records. */
const AMQP_QUEUE_CLASS = 0x0032; /* 50 */
struct amqp_queue_properties_t {
  amqp_flags_t _flags;
};

const AMQP_TX_CLASS = 0x005A; /* 90 */
struct amqp_tx_properties_t {
  amqp_flags_t _flags;
};

const AMQP_STREAM_CLASS = 0x0050; /* 80 */
const AMQP_STREAM_CONTENT_TYPE_FLAG = 1 << 15;
const AMQP_STREAM_CONTENT_ENCODING_FLAG = 1 << 14;
const AMQP_STREAM_HEADERS_FLAG = 1 << 13;
const AMQP_STREAM_PRIORITY_FLAG = 1 << 12;
const AMQP_STREAM_TIMESTAMP_FLAG = 1 << 11;
struct amqp_stream_properties_t {
  amqp_flags_t _flags;
  amqp_bytes_t content_type;
  amqp_bytes_t content_encoding;
  amqp_table_t headers;
  uint8_t priority;
  uint64_t timestamp;
};

const AMQP_EXCHANGE_CLASS = 0x0028; /* 40 */
struct amqp_exchange_properties_t {
  amqp_flags_t _flags;
};

const AMQP_TUNNEL_CLASS = 0x006E; /* 110 */
const AMQP_TUNNEL_HEADERS_FLAG = 1 << 15;
const AMQP_TUNNEL_PROXY_NAME_FLAG = 1 << 14;
const AMQP_TUNNEL_DATA_NAME_FLAG = 1 << 13;
const AMQP_TUNNEL_DURABLE_FLAG = 1 << 12;
const AMQP_TUNNEL_BROADCAST_FLAG = 1 << 11;
struct amqp_tunnel_properties_t {
  amqp_flags_t _flags;
  amqp_table_t headers;
  amqp_bytes_t proxy_name;
  amqp_bytes_t data_name;
  uint8_t durable;
  uint8_t broadcast;
};

const AMQP_ACCESS_CLASS = 0x001E; /* 30 */
struct amqp_access_properties_t {
  amqp_flags_t _flags;
};

const AMQP_CONNECTION_CLASS = 0x000A; /* 10 */
struct amqp_connection_properties_t {
  amqp_flags_t _flags;
};

const AMQP_DTX_CLASS = 0x0064; /* 100 */
struct amqp_dtx_properties_t {
  amqp_flags_t _flags;
};

const AMQP_FILE_CLASS = 0x0046; /* 70 */
const AMQP_FILE_CONTENT_TYPE_FLAG = 1 << 15;
const AMQP_FILE_CONTENT_ENCODING_FLAG = 1 << 14;
const AMQP_FILE_HEADERS_FLAG = 1 << 13;
const AMQP_FILE_PRIORITY_FLAG = 1 << 12;
const AMQP_FILE_REPLY_TO_FLAG = 1 << 11;
const AMQP_FILE_MESSAGE_ID_FLAG = 1 << 10;
const AMQP_FILE_FILENAME_FLAG = 1 << 9;
const AMQP_FILE_TIMESTAMP_FLAG = 1 << 8;
const AMQP_FILE_CLUSTER_ID_FLAG = 1 << 7;
struct amqp_file_properties_t {
  amqp_flags_t _flags;
  amqp_bytes_t content_type;
  amqp_bytes_t content_encoding;
  amqp_table_t headers;
  uint8_t priority;
  amqp_bytes_t reply_to;
  amqp_bytes_t message_id;
  amqp_bytes_t filename;
  uint64_t timestamp;
  amqp_bytes_t cluster_id;
};

const AMQP_BASIC_CLASS = 0x003C; /* 60 */
const AMQP_BASIC_CONTENT_TYPE_FLAG = 1 << 15;
const AMQP_BASIC_CONTENT_ENCODING_FLAG = 1 << 14;
const AMQP_BASIC_HEADERS_FLAG = 1 << 13;
const AMQP_BASIC_DELIVERY_MODE_FLAG = 1 << 12;
const AMQP_BASIC_PRIORITY_FLAG = 1 << 11;
const AMQP_BASIC_CORRELATION_ID_FLAG = 1 << 10;
const AMQP_BASIC_REPLY_TO_FLAG = 1 << 9;
const AMQP_BASIC_EXPIRATION_FLAG = 1 << 8;
const AMQP_BASIC_MESSAGE_ID_FLAG = 1 << 7;
const AMQP_BASIC_TIMESTAMP_FLAG = 1 << 6;
const AMQP_BASIC_TYPE_FLAG = 1 << 5;
const AMQP_BASIC_USER_ID_FLAG = 1 << 4;
const AMQP_BASIC_APP_ID_FLAG = 1 << 3;
const AMQP_BASIC_CLUSTER_ID_FLAG = 1 << 2;
struct amqp_basic_properties_t {
  amqp_flags_t _flags;
  amqp_bytes_t content_type;
  amqp_bytes_t content_encoding;
  amqp_table_t headers;
  uint8_t delivery_mode;
  uint8_t priority;
  amqp_bytes_t correlation_id;
  amqp_bytes_t reply_to;
  amqp_bytes_t expiration;
  amqp_bytes_t message_id;
  uint64_t timestamp;
  amqp_bytes_t type;
  amqp_bytes_t user_id;
  amqp_bytes_t app_id;
  amqp_bytes_t cluster_id;
};

const AMQP_TEST_CLASS = 0x0078; /* 120 */
struct amqp_test_properties_t {
  amqp_flags_t _flags;
};

const AMQP_CHANNEL_CLASS = 0x0014; /* 20 */
struct amqp_channel_properties_t {
  amqp_flags_t _flags;
};


