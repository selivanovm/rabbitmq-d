// D import file generated from 'src/amqp_mem.d'
import amqp;
import amqp_base;
import tango.stdc.string;
amqp_bytes_t amqp_cstring_bytes(char* cstr)
{
amqp_bytes_t result;
result.len = strlen(cstr);
result.bytes = cast(void*)cstr;
return result;
}
