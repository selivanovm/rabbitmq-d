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
import tango.stdc.stdio;
import tango.stdc.string;
import tango.stdc.stdlib;
import tango.stdc.posix.sys.time;


import amqp_base;
import amqp;
import amqp_framing;

void die_on_error(int x, char *context) {
  if (x < 0) {
    fprintf(stderr, "%s: %s\n", context, strerror(-x));
    exit(1);
  }
}

void die_on_amqp_error(amqp_rpc_reply_t x, char *context) {
  switch (x.reply_type) {
    case amqp_response_type_enum.AMQP_RESPONSE_NORMAL:
      return;

    case amqp_response_type_enum.AMQP_RESPONSE_NONE:
      fprintf(stderr, "%s: missing RPC reply type!", context);
      break;

    case amqp_response_type_enum.AMQP_RESPONSE_LIBRARY_EXCEPTION:
      fprintf(stderr, "%s: %s\n", context,
	      x.library_errno ? strerror(x.library_errno) : "(end-of-stream)");
      break;

    case amqp_response_type_enum.AMQP_RESPONSE_SERVER_EXCEPTION:
      switch (x.reply.id) {
	case AMQP_CONNECTION_CLOSE_METHOD: {
	  amqp_connection_close_t *m = cast(amqp_connection_close_t *) x.reply.decoded;
	  fprintf(stderr, "%s: server connection error %d, message: %.*s",
		  context,
		  (*m).reply_code,
		  cast(int) (*m).reply_text.len, cast(char *) (*m).reply_text.bytes);
	  break;
	}
	case AMQP_CHANNEL_CLOSE_METHOD: {
	  amqp_channel_close_t *m = cast(amqp_channel_close_t *) x.reply.decoded;
	  fprintf(stderr, "%s: server channel error %d, message: %.*s",
		  context,
		  (*m).reply_code,
		  cast(int) (*m).reply_text.len, cast(char *) (*m).reply_text.bytes);
	  break;
	}
	default:
	  fprintf(stderr, "%s: unknown server error, method id 0x%08X", context, x.reply.id);
	  break;
      }
      break;
  }

  exit(1);
}

/*ulong now_microseconds() {
  timeval tv;
  gettimeofday(&tv, null);
  return cast(ulong) tv.tv_sec * 1000000 + cast(ulong) tv.tv_usec;
}*/

char[] getString(char* s, uint l) {
  char[] result = new char[l];
  for(uint i = 0; i < l; i++)
    result[i] = *(s + i);
  return result;
}