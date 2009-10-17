/*#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>

#include "amqp.h"
#include "amqp_framing.h"
#include "amqp_private.h"

#include <assert.h>*/

import amqp_base;
import amqp;
import amqp_framing;
import amqp_private;
import amqp_socket;
import amqp_connection;
import amqp_mem;

import tango.stdc.string;
import tango.stdc.stdio;
import tango.io.Stdout;

amqp_rpc_reply_t amqp_rpc_reply;

template RPC_REPLY(T)		
{
  T* resolve()
  {
    if (amqp_rpc_reply.reply_type == amqp_response_type_enum.AMQP_RESPONSE_NORMAL)
      return cast(T*) amqp_rpc_reply.reply.decoded;
    else 
      return null;
  }
}

amqp_channel_open_ok_t *amqp_channel_open(amqp_connection_state_t *state,
					  amqp_channel_t channel)
{
  Stdout.format("amqp_channel_open #START").newline;
  amqp_channel_open_t acot = { AMQP_EMPTY_BYTES };
  amqp_rpc_reply = amqp_simple_rpc(state, channel, AMQP_CHANNEL_OPEN_METHOD, AMQP_CHANNEL_OPEN_OK_METHOD,
				   cast(void*)&acot);
  Stdout.format("amqp_channel_open #RETURN").newline;
  return RPC_REPLY!(amqp_channel_open_ok_t).resolve();
}

int amqp_basic_publish(amqp_connection_state_t *state,
		       amqp_channel_t channel,
		       amqp_bytes_t exchange,
		       amqp_bytes_t routing_key,
		       amqp_boolean_t mandatory,
		       amqp_boolean_t immediate,
		       amqp_basic_properties_t *properties,
		       amqp_bytes_t bo_dy)
{

  Stdout.format("amqp_basic_publish #START").newline;

  amqp_frame_t f;
  size_t body_offset;
  size_t usable_body_payload_size = state.frame_max - (HEADER_SIZE + FOOTER_SIZE);

  amqp_basic_publish_t m;
  m.exchange = exchange;
  m.routing_key = routing_key;
  m.mandatory = mandatory;
  m.immediate = immediate;

  amqp_basic_properties_t default_properties;

  int result_ = amqp_send_method(state, channel, AMQP_BASIC_PUBLISH_METHOD, &m);
  if (result_ < 0)
    return result_;

  Stdout.format("amqp_basic_publish #1").newline;

  if (properties is null) {
    memset(&default_properties, 0, default_properties.sizeof);
    properties = &default_properties;
  }

  f.frame_type = AMQP_FRAME_HEADER;
  f.channel = channel;
  f.payload.properties.class_id = AMQP_BASIC_CLASS;
  f.payload.properties.body_size = bo_dy.len;
  f.payload.properties.decoded = cast(void*) properties;

  result_ = amqp_send_frame(state, &f);
  if (result_ < 0)
    return result_;

  Stdout.format("amqp_basic_publish #2").newline;

  body_offset = 0;
  while (1) {
    int remaining = bo_dy.len - body_offset;
    assert(remaining >= 0);

    if (remaining == 0)
      break;

    Stdout.format("amqp_basic_publish #3").newline;

    f.frame_type = AMQP_FRAME_BODY;
    f.channel = channel;
    f.payload.body_fragment.bytes = BUF_AT(bo_dy, body_offset);
    if (remaining >= usable_body_payload_size) {
      f.payload.body_fragment.len = usable_body_payload_size;
    } else {
      f.payload.body_fragment.len = remaining;
    }

    body_offset += f.payload.body_fragment.len;
    result_ = amqp_send_frame(state, &f);
    if(result_ < 0)
      return result_;

  }
  Stdout.format("amqp_basic_publish #RETURN").newline;
  return 0;
}

amqp_rpc_reply_t amqp_channel_close(amqp_connection_state_t *state,
				    amqp_channel_t channel,
				    int code)
{
  char codestr[13];
  snprintf(codestr.ptr, codestr.sizeof, "%d", code);

  amqp_channel_close_t acct;
  acct.reply_code = code;
  acct.reply_text = amqp_cstring_bytes(codestr.ptr);
  acct.class_id = 0;
  acct.method_id = 0;

  return amqp_simple_rpc(state, channel, AMQP_CHANNEL_CLOSE_METHOD, AMQP_CHANNEL_CLOSE_OK_METHOD,
				   cast(void*)&acct);

}

amqp_rpc_reply_t amqp_connection_close(amqp_connection_state_t *state,
				       int code)
{
  char codestr[13];
  snprintf(codestr.ptr, codestr.sizeof, "%d", code);

  amqp_connection_close_t acct;
  acct.reply_code = code;
  acct.reply_text = amqp_cstring_bytes(codestr.ptr);
  acct.class_id = 0;
  acct.method_id = 0;

  return amqp_simple_rpc(state, 0, AMQP_CONNECTION_CLOSE_METHOD, AMQP_CONNECTION_CLOSE_OK_METHOD,
				   cast(void*)&acct);

}

amqp_exchange_declare_ok_t *amqp_exchange_declare(amqp_connection_state_t *state,
						  amqp_channel_t channel,
						  amqp_bytes_t exchange,
						  amqp_bytes_t type,
						  amqp_boolean_t passive,
						  amqp_boolean_t durable,
						  amqp_boolean_t auto_delete,
						  amqp_table_t arguments)
{

  amqp_exchange_declare_t aedt;
  aedt.ticket = 0;
  aedt.exchange = exchange;
  aedt.type = type;
  aedt.passive = passive;
  aedt.durable = durable;
  aedt.auto_delete = auto_delete;
  aedt.internal = 0;
  aedt.nowait = 0;
  aedt.arguments = arguments;
  
  amqp_rpc_reply = amqp_simple_rpc(state, channel, AMQP_EXCHANGE_DECLARE_METHOD, AMQP_EXCHANGE_DECLARE_OK_METHOD,
				   cast(void*)&aedt);

  return RPC_REPLY!(amqp_exchange_declare_ok_t).resolve();

}

amqp_queue_declare_ok_t *amqp_queue_declare(amqp_connection_state_t *state,
					    amqp_channel_t channel,
					    amqp_bytes_t queue,
					    amqp_boolean_t passive,
					    amqp_boolean_t durable,
					    amqp_boolean_t exclusive,
					    amqp_boolean_t auto_delete,
					    amqp_table_t arguments)
{

  amqp_queue_declare_t aqdt;
  aqdt.ticket = 0;
  aqdt.queue = queue;
  aqdt.passive = passive;
  aqdt.durable = durable;
  aqdt.exclusive = exclusive;
  aqdt.auto_delete = auto_delete;
  aqdt.nowait = 0;
  aqdt.arguments = arguments;

  amqp_rpc_reply = amqp_simple_rpc(state, channel, AMQP_QUEUE_DECLARE_METHOD, AMQP_QUEUE_DECLARE_OK_METHOD,
				   cast(void*)&aqdt);

  return RPC_REPLY!(amqp_queue_declare_ok_t).resolve;
}

amqp_queue_bind_ok_t *amqp_queue_bind(amqp_connection_state_t *state,
				      amqp_channel_t channel,
				      amqp_bytes_t queue,
				      amqp_bytes_t exchange,
				      amqp_bytes_t routing_key,
				      amqp_table_t arguments)
{

  amqp_queue_bind_t aqbt;
  aqbt.ticket = 0;
  aqbt.queue = queue;
  aqbt.exchange = exchange;
  aqbt.routing_key = routing_key;
  aqbt.nowait = 0;
  aqbt.arguments = arguments;

  amqp_rpc_reply = amqp_simple_rpc(state, channel, AMQP_QUEUE_BIND_METHOD, AMQP_QUEUE_BIND_OK_METHOD,
				   cast(void*)&aqbt);

  return RPC_REPLY!(amqp_queue_bind_ok_t).resolve;
}

amqp_queue_unbind_ok_t *amqp_queue_unbind(amqp_connection_state_t *state,
					  amqp_channel_t channel,
					  amqp_bytes_t queue,
					  amqp_bytes_t exchange,
					  amqp_bytes_t binding_key,
					  amqp_table_t arguments)
{

  amqp_queue_unbind_t aqut;
  aqut.ticket = 0;
  aqut.queue = queue;
  aqut.exchange = exchange;
  aqut.routing_key = binding_key;
  aqut.arguments = arguments;

  amqp_rpc_reply = amqp_simple_rpc(state, channel, AMQP_QUEUE_UNBIND_METHOD, AMQP_QUEUE_UNBIND_OK_METHOD,
				   cast(void*)&aqut);

  return RPC_REPLY!(amqp_queue_unbind_ok_t).resolve;
}

amqp_basic_consume_ok_t *amqp_basic_consume(amqp_connection_state_t *state,
					    amqp_channel_t channel,
					    amqp_bytes_t queue,
					    amqp_bytes_t consumer_tag,
					    amqp_boolean_t no_local,
					    amqp_boolean_t no_ack,
					    amqp_boolean_t exclusive)
{

  amqp_basic_consume_t abct;
  abct.ticket = 0;
  abct.queue = queue;
  abct.consumer_tag = consumer_tag;
  abct.no_local = no_local;
  abct.no_ack = no_ack;
  abct.exclusive = exclusive;
  abct.nowait = 0;

  amqp_rpc_reply = amqp_simple_rpc(state, channel, AMQP_BASIC_CONSUME_METHOD, AMQP_BASIC_CONSUME_OK_METHOD,
				   cast(void*)&abct);

  return RPC_REPLY!(amqp_basic_consume_ok_t).resolve;
}

int amqp_basic_ack(amqp_connection_state_t *state,
		   amqp_channel_t channel,
		   uint64_t delivery_tag,
		   amqp_boolean_t multiple)
{
  amqp_basic_ack_t m;
  m.delivery_tag = delivery_tag;
  m.multiple = multiple;
  AMQP_CHECK_RESULT(amqp_send_method(state, channel, AMQP_BASIC_ACK_METHOD, &m));
  return 0;
}
