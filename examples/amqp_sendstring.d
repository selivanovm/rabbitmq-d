// The contents of this file are subject to the Mozilla Public License
// Version 1.1 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS"
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
// License for the specific language governing rights and limitations
// under the License.
//
// The Original Code is RabbitMQ.
//
// The Initial Developers of the Original Code are LShift Ltd,
// Cohesive Financial Technologies LLC, and Rabbit Technologies Ltd.
//
// Portions created before 22-Nov-2008 00:00:00 GMT by LShift Ltd,
// Cohesive Financial Technologies LLC, or Rabbit Technologies Ltd
// are Copyright (C) 2007-2008 LShift Ltd, Cohesive Financial
// Technologies LLC, and Rabbit Technologies Ltd.
//
// Portions created by LShift Ltd are Copyright (C) 2007-2009 LShift
// Ltd. Portions created by Cohesive Financial Technologies LLC are
// Copyright (C) 2007-2009 Cohesive Financial Technologies
// LLC. Portions created by Rabbit Technologies Ltd are Copyright
// (C) 2007-2009 Rabbit Technologies Ltd.
//
// All Rights Reserved.
//
// Contributor(s): Mikhail Selivanov(Magnetosoft LLC).       
//
private import tango.core.Thread;
import tango.io.Stdout;
import tango.stdc.stdio;
import tango.stdc.stdlib;
import tango.net.device.Socket;
import tango.stdc.string : strlenn = strlen;
import tango.stdc.stringz;
import tango.stdc.stdio : stdErr = stderr;

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

  char[] hostname;
  int port;
  char[] exchange;
  char[] routingkey;
  char[] messagebody;
  int multiplier;
  int send_count;

  Socket socket;

  amqp_connection_state_t *conn;

  if (args.length < 8) {
    fprintf(stdErr, "Usage: amqp_sendstring host port exchange routingkey messagebody multiplier send_count\n");
    return;
  }

  //Stdout.format("{} {} {} {} {}", args[1], args[2], args[3], args[4], args[5], args[6]).newline;

  hostname = args[1];
  port = atoi(args[2].ptr);
  exchange = args[3];
  routingkey = args[4];
  messagebody = args[5];
  multiplier = atoi(args[6].ptr);
  send_count = atoi(args[7].ptr);

  char[] msg_arr = new char[multiplier * messagebody.length];

  int l = 0;
  for(int i = 0; i < multiplier; i++) {
	  for(int j = 0; j < messagebody.length; j++) {
		  msg_arr[l++] = messagebody[j];
	  }
  }

  socket = amqp_open_socket(hostname, port);
  conn = amqp_new_connection(socket);

  die_on_amqp_error(amqp_login(conn, toStringz("big-archive"), 0, 131072, 0, amqp_sasl_method_enum.AMQP_SASL_METHOD_PLAIN, toStringz("test"), toStringz("test")),
		    "Logging in");

  amqp_channel_open(conn, 1);

  die_on_amqp_error(amqp_rpc_reply, "Opening channel");

  amqp_exchange_declare(conn, 1, amqp_cstring_bytes(toStringz(exchange)), amqp_cstring_bytes("direct"),
			0, 0, 0, AMQP_EMPTY_TABLE);



  bool a = false;
  for(int i = 0; i < send_count; i++)
  {
    amqp_basic_properties_t props;
    props._flags = AMQP_BASIC_CONTENT_TYPE_FLAG | AMQP_BASIC_DELIVERY_MODE_FLAG;
    props.content_type = amqp_cstring_bytes("text/plain");
    props.delivery_mode = 2; // persistent delivery mode
    Stdout.format("amqp_sendstring : connection = {}", conn).newline;
    die_on_error(amqp_basic_publish(conn,
				    1,
				    amqp_cstring_bytes(toStringz(exchange)),
				    amqp_cstring_bytes(toStringz(routingkey)),
				    0,
				    0,
				    &props,
				    amqp_cstring_bytes(toStringz(msg_arr))),
		 "Publishing");

    Stdout.format("\n{} messages sent : socket = {}", i + 1, socket is null).newline;
	  
    if(i + 2 == send_count) {
	    Thread.sleep(1);
    }
  }

  die_on_amqp_error(amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS), "Closing channel");
  die_on_amqp_error(amqp_connection_close(conn, AMQP_REPLY_SUCCESS), "Closing connection");
  amqp_destroy_connection(conn);

  return;
}

public static char[] getString(char* s)
{
  return s ? s[0 .. strlenn(s)] : cast(char[]) null;
}
