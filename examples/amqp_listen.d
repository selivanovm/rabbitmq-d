import tango.io.Stdout;
import tango.stdc.stdio;
import tango.stdc.stdlib;
import tango.net.Socket;
import tango.stdc.string : strlenn = strlen;

import amqp_base;
import amqp;
import amqp_framing;
import amqp_framing_;
import amqp_private;
import amqp_connection;
import amqp_socket;
import amqp_api;
import amqp_mem;

import example_utils;

/* Private: compiled out in NDEBUG mode */
//extern void amqp_dump(void const *buffer, size_t len);

int main(char[][] args) {
  char[] hostname;
  int port;
  char *exchange;
  char *bindingkey;

  Socket socket;
  amqp_connection_state_t *conn;

  amqp_bytes_t queuename;

  if (args.length < 5) {
    fprintf(stderr, "Usage: amqp_listen host port exchange bindingkey\n");
    return 1;
  }

  hostname = args[1];
  port = atoi(args[2].ptr);
  exchange = args[3].ptr;
  bindingkey = args[4].ptr;

  socket = amqp_open_socket(hostname, port);

  conn = amqp_new_connection(socket);

  die_on_amqp_error(amqp_login(conn, "test".ptr, 0, 131072, 0, amqp_sasl_method_enum.AMQP_SASL_METHOD_PLAIN, "user".ptr, "123".ptr),
		    "Logging in");
  amqp_channel_open(conn, 1);
  die_on_amqp_error(amqp_rpc_reply, "Opening channel");

  {
    amqp_queue_declare_ok_t *r = amqp_queue_declare(conn, 1, AMQP_EMPTY_BYTES, 0, 0, 0, 1,
						    AMQP_EMPTY_TABLE);
    die_on_amqp_error(amqp_rpc_reply, "Declaring queue");
    queuename = amqp_bytes_malloc_dup((*r).queue);
    if (queuename.bytes is null) {
      die_on_error(-ENOMEM, "Copying queue name");
    }
  }

  amqp_queue_bind(conn, 1, queuename, amqp_cstring_bytes(exchange), amqp_cstring_bytes(bindingkey),
		  AMQP_EMPTY_TABLE);
  die_on_amqp_error(amqp_rpc_reply, "Binding queue");

  amqp_basic_consume(conn, 1, queuename, AMQP_EMPTY_BYTES, 0, 1, 0);
  die_on_amqp_error(amqp_rpc_reply, "Consuming");

  {
    amqp_frame_t frame;
    int result;

    amqp_basic_deliver_t *d;
    amqp_basic_properties_t *p;
    size_t body_target;
    size_t body_received;

    while (1) {
      amqp_maybe_release_buffers(conn);
      result = amqp_simple_wait_frame(conn, &frame);
      printf("Result %d\n", result);
      if (result <= 0)
	break;

      printf("Frame type %d, channel %d\n", frame.frame_type, frame.channel);
      if (frame.frame_type != AMQP_FRAME_METHOD)
	continue;

      printf("Method %s\n", amqp_method_name(frame.payload.method.id));
      if (frame.payload.method.id != AMQP_BASIC_DELIVER_METHOD)
	continue;

      printf("main #1\n");

      d = cast(amqp_basic_deliver_t *) frame.payload.method.decoded;

      printf("main #2\n");

      Stdout.format("Delivery {}, exchange {} routingkey {}",
		    cast(uint64_t) (*d).delivery_tag, getString(cast(char *) (*d).exchange.bytes, cast(uint) (*d).exchange.len),
		    getString(cast(char *) (*d).routing_key.bytes, cast(uint) (*d).routing_key.len)).newline;

      printf("main #3\n");

      /*      printf("Delivery %u, exchange %.*s routingkey %.*s\n",
	     cast(uint64_t) (*d).delivery_tag,
	     cast(int) (*d).exchange.len, cast(char *) (*d).exchange.bytes,
	     cast(int) (*d).routing_key.len, cast(char *) (*d).routing_key.bytes);*/

      printf("main #4\n");

      result = amqp_simple_wait_frame(conn, &frame);
      if (result <= 0)
	break;

      if (frame.frame_type != AMQP_FRAME_HEADER) {
	fprintf(stderr, "Expected header!");
	abort();
      }
      p = cast(amqp_basic_properties_t *) frame.payload.properties.decoded;
      if ((*p)._flags & AMQP_BASIC_CONTENT_TYPE_FLAG) {
	printf("Content-type: %.*s\n",
	       cast(int) (*p).content_type.len, cast(char *) (*p).content_type.bytes);
      }
      printf("----\n");

      body_target = frame.payload.properties.body_size;
      body_received = 0;

      while (body_received < body_target) {
	result = amqp_simple_wait_frame(conn, &frame);
	if (result <= 0)
	  break;

	if (frame.frame_type != AMQP_FRAME_BODY) {
	  fprintf(stderr, "Expected body!");
	  abort();
	}	  

	body_received += frame.payload.body_fragment.len;
	assert(body_received <= body_target);

	/*	amqp_dump(frame.payload.body_fragment.bytes,
		frame.payload.body_fragment.len);*/

	Stdout.format("Content: \n{}", getString(cast(char *)frame.payload.body_fragment.bytes,
						 frame.payload.body_fragment.len)).newline;

      }

      if (body_received != body_target) {
	/* Can only happen when amqp_simple_wait_frame returns <= 0 */
	/* We break here to close the connection */
	break;
      }
    }
  }

  die_on_amqp_error(amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS), "Closing channel");
  die_on_amqp_error(amqp_connection_close(conn, AMQP_REPLY_SUCCESS), "Closing connection");
  amqp_destroy_connection(conn);

  return 0;
}


