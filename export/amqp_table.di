// D import file generated from 'src/amqp_table.d'
const INITIAL_TABLE_SIZE = 16;
import tango.io.Stdout;
import tango.stdc.stdlib;
import tango.stdc.string;
import amqp_base;
import amqp;
import amqp_private;
import amqp_mem;
int amqp_decode_table(amqp_bytes_t encoded, amqp_pool_t* pool, amqp_table_t* output, int* offsetptr);
int amqp_encode_table(amqp_bytes_t encoded, amqp_table_t* input, int* offsetptr);
int amqp_table_entry_cmp(void* entry1, void* entry2);
