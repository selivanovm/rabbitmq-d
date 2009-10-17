// D import file generated from 'src/amqp_mem.d'
import amqp;
import amqp_base;
import tango.stdc.string;
import tango.stdc.stdlib;
import tango.io.Stdout;
import tango.stdc.errno;
void init_amqp_pool(amqp_pool_t* pool, size_t pagesize)
{
(*pool).pagesize = pagesize ? pagesize : 4096;
(*pool).pages.num_blocks = 0;
(*pool).pages.blocklist = null;
(*pool).large_blocks.num_blocks = 0;
(*pool).large_blocks.blocklist = null;
(*pool).next_page = 0;
(*pool).alloc_block = null;
(*pool).alloc_used = 0;
}
static 
{
    void empty_blocklist(amqp_pool_blocklist_t* x);
}
void recycle_amqp_pool(amqp_pool_t* pool)
{
empty_blocklist(&(*pool).large_blocks);
(*pool).next_page = 0;
(*pool).alloc_block = null;
(*pool).alloc_used = 0;
}
void empty_amqp_pool(amqp_pool_t* pool)
{
recycle_amqp_pool(pool);
empty_blocklist(&(*pool).pages);
}
static 
{
    int record_pool_block(amqp_pool_blocklist_t* x, void* block);
}
void* amqp_pool_alloc(amqp_pool_t* pool, size_t amount);
void amqp_pool_alloc_bytes(amqp_pool_t* pool, size_t amount, amqp_bytes_t* output)
{
Stdout.format("amqp_pool_alloc_bytes #1").newline;
(*output).len = amount;
(*output).bytes = amqp_pool_alloc(pool,amount);
Stdout.format("amqp_pool_alloc_bytes #2").newline;
}
amqp_bytes_t amqp_cstring_bytes(char* cstr)
{
amqp_bytes_t result;
result.len = strlen(cstr);
result.bytes = cast(void*)cstr;
return result;
}
