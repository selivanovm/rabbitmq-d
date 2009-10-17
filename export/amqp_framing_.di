// D import file generated from 'src/amqp_framing_.d'
import tango.io.Stdout;
import amqp_base;
import amqp;
import amqp_private;
import amqp_framing;
import amqp_mem;
import amqp_table;
char* amqp_method_name(amqp_method_number_t methodNumber);
amqp_boolean_t amqp_method_has_content(amqp_method_number_t methodNumber);
int amqp_decode_method(amqp_method_number_t methodNumber, amqp_pool_t* pool, amqp_bytes_t encoded, void** decoded);
int amqp_decode_properties(uint16_t class_id, amqp_pool_t* pool, amqp_bytes_t encoded, void** decoded);
int amqp_encode_method(amqp_method_number_t methodNumber, void* decoded, amqp_bytes_t encoded);
int amqp_encode_properties(uint16_t class_id, void* decoded, amqp_bytes_t encoded);
