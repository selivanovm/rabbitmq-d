/*#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <stdint.h>
#include <amqp.h>
#include <amqp_framing.h>

#include <unistd.h>*/

import tango.io.Stdout;
import tango.stdc.stdio;
import tango.stdc.stdlib;
import tango.net.Socket;
// : hostent, gethostbyname, htons, close, socket_t;
import tango.stdc.string : strlenn = strlen;

import amqp_base;
import amqp;
import amqp_framing;
import amqp_private;
import amqp_connection;
import amqp_socket;
import amqp_api;
import amqp_mem;

import example_utils;

public static void main(char[][] args) {

  char *hostname;
  int port;
  char *exchange;
  char *routingkey;
  char *messagebody;

  Socket socket;

  int sockfd;
  amqp_connection_state_t *conn;

  if (args.length < 6) {
    fprintf(stderr, "Usage: amqp_sendstring host port exchange routingkey messagebody\n");
    return 1;
  }

  Stdout.format("{} {} {} {} {}", args[1], args[2], args[3], args[4], args[5], args[6]).newline;

  hostname = args[1].ptr;
  port = atoi(args[2].ptr);
  exchange = args[3].ptr;
  routingkey = args[4].ptr;
  messagebody = args[5].ptr;

  conn = amqp_new_connection();

  Stdout.format("{} {} {}", getString(hostname), port, conn).newline;

  //  socket = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.IP, true);  

  //  sockfd = socket.sock;

  die_on_error(sockfd = amqp_open_socket(hostname, port), "Opening socket");

  Stdout.format("main #1 {}", sockfd).newline;

  amqp_set_sockfd(conn, sockfd);

  Stdout.format("main #2 {}", conn).newline;

  die_on_amqp_error(amqp_login(conn, "test\0".ptr, 0, 131072, 0, amqp_sasl_method_enum.AMQP_SASL_METHOD_PLAIN, "user".ptr, "123".ptr),
		    "Logging in");

  Stdout.format("main #3").newline;

  amqp_channel_open(conn, 1);

  Stdout.format("main #4").newline;

  die_on_amqp_error(amqp_rpc_reply, "Opening channel");

  Stdout.format("main #5").newline;

  amqp_exchange_declare(conn, 1, amqp_cstring_bytes(exchange), amqp_cstring_bytes("direct"),
			0, 0, 0, AMQP_EMPTY_TABLE);


  {
    amqp_basic_properties_t props;
    props._flags = AMQP_BASIC_CONTENT_TYPE_FLAG | AMQP_BASIC_DELIVERY_MODE_FLAG;
    props.content_type = amqp_cstring_bytes("text/plain");
    props.delivery_mode = 2; // persistent delivery mode
    Stdout.format("main #6").newline;
    die_on_error(amqp_basic_publish(conn,
				    1,
				    amqp_cstring_bytes(exchange),
				    amqp_cstring_bytes(routingkey),
				    0,
				    0,
				    &props,
				    amqp_cstring_bytes(messagebody)),
		 "Publishing");
  }

  Stdout.format("main #7").newline;

  die_on_amqp_error(amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS), "Closing channel");
  Stdout.format("main #8").newline;
  die_on_amqp_error(amqp_connection_close(conn, AMQP_REPLY_SUCCESS), "Closing connection");
  Stdout.format("main #9").newline;
  amqp_destroy_connection(conn);
  Stdout.format("main #10").newline;
  die_on_error(close(cast(socket_t)sockfd), "Closing socket");
  Stdout.format("main #RETURN").newline;
  return 0;
}

public static char[] getString(char* s)
{
  return s ? s[0 .. strlenn(s)] : cast(char[]) null;
}
