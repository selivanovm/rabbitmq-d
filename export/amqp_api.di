// D import file generated from 'src/amqp_api.d'
import amqp_base;
import amqp;
import amqp_framing;
import amqp_private;
amqp_rpc_reply_t amqp_rpc_reply;
template RPC_REPLY(alias replytype)
{
typeof(replytype) what()
{
if (amqp_rpc_reply.reply_type == AMQP_RESPONSE_NORMAL)
return cast(typeof(replytype)*)amqp_rpc_reply.reply.decoded;
else
return null;
}
}
amqp_channel_open_ok_t* amqp_channel_open(amqp_connection_state_t state, amqp_channel_t channel)
{
amqp_channel_open_t acot = {AMQP_EMPTY_BYTES};
amqp_rpc_reply = amqp_simple_rpc(state,channel,AMQP_CHANNEL_OPEN_METHOD,AMQP_OPEN_OK_METHOD,amqp_channel_open_t,acot.out_of_band);
return RPC_REPLY(amqp_channel_open_ok_t);
}
int amqp_basic_publish(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t exchange, amqp_bytes_t routing_key, amqp_boolean_t mandatory, amqp_boolean_t immediate, amqp_basic_properties_t* properties, amqp_bytes_t bo_dy);
amqp_rpc_reply_t amqp_channel_close(amqp_connection_state_t state, amqp_channel_t channel, int code)
{
char[13] codestr;
snprintf(codestr,sizeof(codestr),"%d",code);
return AMQP_SIMPLE_RPC(state,channel,CHANNEL,CLOSE,CLOSE_OK,amqp_channel_close_t,code,amqp_cstring_bytes(codestr),0,0);
}
amqp_rpc_reply_t amqp_connection_close(amqp_connection_state_t state, int code)
{
char[13] codestr;
snprintf(codestr,sizeof(codestr),"%d",code);
return AMQP_SIMPLE_RPC(state,0,CONNECTION,CLOSE,CLOSE_OK,amqp_connection_close_t,code,amqp_cstring_bytes(codestr),0,0);
}
amqp_exchange_declare_ok_t* amqp_exchange_declare(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t exchange, amqp_bytes_t type, amqp_boolean_t passive, amqp_boolean_t durable, amqp_boolean_t auto_delete, amqp_table_t arguments)
{
amqp_rpc_reply = AMQP_SIMPLE_RPC(state,channel,EXCHANGE,DECLARE,DECLARE_OK,amqp_exchange_declare_t,0,exchange,type,passive,durable,auto_delete,0,0,arguments);
return RPC_REPLY(amqp_exchange_declare_ok_t);
}
amqp_queue_declare_ok_t* amqp_queue_declare(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t queue, amqp_boolean_t passive, amqp_boolean_t durable, amqp_boolean_t exclusive, amqp_boolean_t auto_delete, amqp_table_t arguments)
{
amqp_rpc_reply = AMQP_SIMPLE_RPC(state,channel,QUEUE,DECLARE,DECLARE_OK,amqp_queue_declare_t,0,queue,passive,durable,exclusive,auto_delete,0,arguments);
return RPC_REPLY(amqp_queue_declare_ok_t);
}
amqp_queue_bind_ok_t* amqp_queue_bind(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t queue, amqp_bytes_t exchange, amqp_bytes_t routing_key, amqp_table_t arguments)
{
amqp_rpc_reply = AMQP_SIMPLE_RPC(state,channel,QUEUE,BIND,BIND_OK,amqp_queue_bind_t,0,queue,exchange,routing_key,0,arguments);
return RPC_REPLY(amqp_queue_bind_ok_t);
}
amqp_queue_unbind_ok_t* amqp_queue_unbind(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t queue, amqp_bytes_t exchange, amqp_bytes_t binding_key, amqp_table_t arguments)
{
amqp_rpc_reply = AMQP_SIMPLE_RPC(state,channel,QUEUE,UNBIND,UNBIND_OK,amqp_queue_unbind_t,0,queue,exchange,binding_key,arguments);
return RPC_REPLY(amqp_queue_unbind_ok_t);
}
amqp_basic_consume_ok_t* amqp_basic_consume(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t queue, amqp_bytes_t consumer_tag, amqp_boolean_t no_local, amqp_boolean_t no_ack, amqp_boolean_t exclusive, amqp_table_t filter)
{
amqp_rpc_reply = AMQP_SIMPLE_RPC(state,channel,BASIC,CONSUME,CONSUME_OK,amqp_basic_consume_t,0,queue,consumer_tag,no_local,no_ack,exclusive,0,filter);
return RPC_REPLY(amqp_basic_consume_ok_t);
}
int amqp_basic_ack(amqp_connection_state_t state, amqp_channel_t channel, uint64_t delivery_tag, amqp_boolean_t multiple)
{
amqp_basic_ack_t m = {delivery_tag:delivery_tag,multiple:multiple};
AMQP_CHECK_RESULT(amqp_send_method(state,channel,AMQP_BASIC_ACK_METHOD,&m));
return 0;
}
