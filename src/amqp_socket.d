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
import tango.stdc.stdarg;
import tango.net.Socket;
import tango.net.InternetAddress;
import tango.stdc.string : strlenn = strlen, memcpy, memset;
import tango.stdc.stdlib;
import tango.io.Stdout;

import amqp_base;
import amqp;
import amqp_framing;
import amqp_private;
import amqp_mem;
import amqp_connection;


const AF_INET = 2;
const PF_INET = AF_INET;

alias ushort sa_family_t;
private import Log;

/*struct in_addr
  {
  in_addr_t   s_addr;
  }

  struct sockaddr_in
  {
  sa_family_t sin_family;
  in_port_t   sin_port;
  in_addr     sin_addr;
  char[8] sin_zero = 0;
  }*/

static void[] buf_array;

Socket amqp_open_socket(char[] hostname, int portnumber)
{
  
	Socket socket = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.IP, true);

	socket.connect(new InternetAddress (hostname, portnumber));
	buf_array = new void[INITIAL_INBOUND_SOCK_BUFFER_SIZE];
	return socket;

}

static char *header() {
	static char header[8];
	header[0] = 'A';
	header[1] = 'M';
	header[2] = 'Q';
	header[3] = 'P';
	header[4] = 1;
	header[5] = 1;
	header[6] = AMQP_PROTOCOL_VERSION_MAJOR;
	header[7] = AMQP_PROTOCOL_VERSION_MINOR;
	return header.ptr;
}

int amqp_send_header(amqp_connection_state_t *state) {
	return send_buffer_to_socket(state.socket, header(), 8);
}

int amqp_send_header_to(amqp_connection_state_t *state,
			int function(void *context, void *buffer, size_t count) fn,
			void *context)
{
	return fn(context, header(), 8);
}

static amqp_bytes_t sasl_method_name(amqp_sasl_method_enum method) {
	switch (method) {
	case (amqp_sasl_method_enum.AMQP_SASL_METHOD_PLAIN): 
		char *plain = "PLAIN";
		amqp_bytes_t r;
		r.len = 5;
		r.bytes = cast(void*)plain;
		return r;
	default:
		amqp_assert(0, "Invalid SASL method: %d", cast(int) method);
	}
	abort(); // unreachable
}

static amqp_bytes_t sasl_response(amqp_pool_t *pool,
				  amqp_sasl_method_enum method,
				  va_list args)
{
	amqp_bytes_t response;
	//Stdout.format("sasl_response #1").newline;
	switch (method) {
	case (amqp_sasl_method_enum.AMQP_SASL_METHOD_PLAIN): 
		{
			//Stdout.format("sasl_response #2").newline;
			char* username = va_arg!(char*)(args);
			//Stdout.format("username = [{}]", *username).newline;
			//Stdout.format("sasl_response #3").newline;
			size_t username_len = strlenn(username);

			char *password = va_arg!(char*)(args);
			size_t password_len = strlenn(password);

			amqp_pool_alloc_bytes(pool, strlenn(username) + strlenn(password) + 2, &response);
			//Stdout.format("sasl_response #3").newline;
			*BUF_AT(response, 0) = 0;
			memcpy((cast(char *) response.bytes) + 1, username, username_len);
			*BUF_AT(response, username_len + 1) = 0;
			memcpy((cast(char *) response.bytes) + username_len + 2, password, password_len);
			//Stdout.format("sasl_response #4").newline;
			break;
		}
	default:
		amqp_assert(0, "Invalid SASL method: %d", cast(int) method);
	}
	//Stdout.format("sasl_response #5").newline;
	return response;
}

amqp_boolean_t amqp_frames_enqueued(amqp_connection_state_t state) {
	return cast(amqp_boolean_t)(state.first_queued_frame !is null);
}

static int wait_frame_inner(amqp_connection_state_t *state,
			    amqp_frame_t *decoded_frame)
{
	//log.trace("#wait_frame_inner start");	
	while (1) {
		int result;
		
		//log.trace("#wait_frame_inner #1");
		
		while (state.sock_inbound_offset < state.sock_inbound_limit) {


			//log.trace("#wait_frame_inner #inner while start");

			amqp_bytes_t buffer;
			buffer.len = state.sock_inbound_limit - state.sock_inbound_offset;
			buffer.bytes = (cast(char *) state.sock_inbound_buffer.bytes) + state.sock_inbound_offset;
			
			//log.trace("wait_frame_inner handle input start");
			
			result = amqp_handle_input(state, buffer, decoded_frame);

			//log.trace("wait_frame_inner handle input end");

			if (result < 0)
			{
				//log.trace("wait_frame_inner result < 0");
				return result;		
			}

			//Stdout.format("wait_frame_inner #3").newline;

			state.sock_inbound_offset += result;

			if (decoded_frame.frame_type != 0) {
				//Stdout.format("wait_frame_inner #4").newline;
				/* Complete frame was read. Return it. */
				//log.trace("decoded_frame.frame_typ != 0");
				return 1;
			}

			/* Incomplete or ignored frame. Keep processing input. */
			assert(result != 0);
		}	

		//Stdout.format("wait_frame_inner #5").newline;

		//log.trace("wait_frame_inner receive_buffer_from_socket start");
		
		result = receive_buffer_from_socket(state.socket,
						    state.sock_inbound_buffer.bytes,
						    state.sock_inbound_buffer.len);

		//log.trace("wait_frame_inner receive_buffer_from_socket end");

		if (result < 0) {
			//log.trace("result < 0, errno = {}", -errno);
			return -errno;
		}
		if (result == 0) {
			/* EOF. */
			//log.trace("result == 0, returning", -errno);
			return 0;
		}

		state.sock_inbound_limit = result;
		state.sock_inbound_offset = 0;
		//log.trace("#wait_frame_inner loop end");
		
	}
}

int amqp_simple_wait_frame(amqp_connection_state_t *state,
			   amqp_frame_t *decoded_frame)
{

	//Stdout.format("amqp_simple_wait_frame #1").newline;

	if (state.first_queued_frame !is null) {
		amqp_frame_t *f = cast(amqp_frame_t *) state.first_queued_frame.data;
		state.first_queued_frame = state.first_queued_frame.next;
		if (state.first_queued_frame is null) {
			state.last_queued_frame = null;
		}
		*decoded_frame = *f;
		return 1;
	} else {
		//Stdout.format("amqp_simple_wait_frame #2").newline;
		return wait_frame_inner(state, decoded_frame);
	}
}

int amqp_simple_wait_method(amqp_connection_state_t *state,
			    amqp_channel_t expected_channel,
			    amqp_method_number_t expected_method,
			    amqp_method_t *output)
{
	amqp_frame_t frame;

	//Stdout.format("amqp_simple_wait_method #1").newline;

	int _result = amqp_simple_wait_frame(state, &frame);	
	if (_result <= 0) return _result;		


	//Stdout.format("amqp_simple_wait_method #2").newline;

	amqp_assert(frame.channel == expected_channel,
		    "Expected 0x%08X method frame on channel %d, got frame on channel %d",
		    expected_method,
		    expected_channel,
		    frame.channel);

	//Stdout.format("amqp_simple_wait_method #3").newline;

	amqp_assert(frame.frame_type == AMQP_FRAME_METHOD,
		    "Expected 0x%08X method frame on channel %d, got frame type %d",
		    expected_method,
		    expected_channel,
		    frame.frame_type);

	//Stdout.format("amqp_simple_wait_method #4").newline;

	amqp_assert(frame.payload.method.id == expected_method,
		    "Expected method ID 0x%08X on channel %d, got ID 0x%08X",
		    expected_method,
		    expected_channel,
		    frame.payload.method.id);

	//Stdout.format("amqp_simple_wait_method #5").newline;

	*output = frame.payload.method;

	//Stdout.format("amqp_simple_wait_method #6").newline;

	return 1;
}

int amqp_send_method(amqp_connection_state_t *state,
		     amqp_channel_t channel,
		     amqp_method_number_t id,
		     void *decoded)
{
	//Stdout.format("amqp_send_method #START").newline;
	amqp_frame_t frame;

	frame.frame_type = AMQP_FRAME_METHOD;
	frame.channel = channel;
	frame.payload.method.id = id;
	frame.payload.method.decoded = decoded;

	//Stdout.format("amqp_send_method #END").newline;

	return amqp_send_frame(state, &frame);
}

amqp_rpc_reply_t amqp_simple_rpc(amqp_connection_state_t *state,
				 amqp_channel_t channel,
				 amqp_method_number_t request_id,
				 amqp_method_number_t expected_reply_id,
				 void *decoded_request_method)
{
	int status;
	amqp_rpc_reply_t result;

	memset(&result, 0, result.sizeof);

	status = amqp_send_method(state, channel, request_id, decoded_request_method);
	if (status < 0) {
		result.reply_type = amqp_response_type_enum.AMQP_RESPONSE_LIBRARY_EXCEPTION;
		result.library_errno = -status;
		return result;
	}

	{
		amqp_frame_t frame;

	retry:
		status = wait_frame_inner(state, &frame);
		if (status <= 0) {
			result.reply_type = amqp_response_type_enum.AMQP_RESPONSE_LIBRARY_EXCEPTION;
			result.library_errno = -status;
			return result;
		}

		/*
		 * We store the frame for later processing unless it's something
		 * that directly affects us here, namely a method frame that is
		 * either
		 *  - on the channel we want, and of the expected type, or
		 *  - on the channel we want, and a channel.close frame, or
		 *  - on channel zero, and a connection.close frame.
		 */
		if (!( (frame.frame_type == AMQP_FRAME_METHOD) &&
		       (   ((frame.channel == channel) &&
			    ((frame.payload.method.id == expected_reply_id) ||
			     (frame.payload.method.id == AMQP_CHANNEL_CLOSE_METHOD)))
			   ||
			   ((frame.channel == 0) &&
			    (frame.payload.method.id == AMQP_CONNECTION_CLOSE_METHOD))   ) ))
			{	     
				amqp_frame_t *frame_copy = cast(amqp_frame_t *)amqp_pool_alloc(&state.decoding_pool, amqp_frame_t.sizeof);
				amqp_link_t *link = cast(amqp_link_t *)amqp_pool_alloc(&state.decoding_pool, amqp_link_t.sizeof);

				*frame_copy = frame;

				link.next = null;
				link.data = frame_copy;

				if (state.last_queued_frame is null) {
					state.first_queued_frame = link;
				} else {
					state.last_queued_frame.next = link;
				}
				state.last_queued_frame = link;

				goto retry;
			}

		result.reply_type = (frame.payload.method.id == expected_reply_id)
			? amqp_response_type_enum.AMQP_RESPONSE_NORMAL
			: amqp_response_type_enum.AMQP_RESPONSE_SERVER_EXCEPTION;

		result.reply = frame.payload.method;
		return result;
	}
}

static int amqp_login_inner(amqp_connection_state_t *state,
			    int channel_max,
			    int frame_max,
			    int heartbeat,
			    amqp_sasl_method_enum sasl_method,
			    va_list vl)
{
	amqp_method_t method;
	uint32_t server_frame_max;
	uint16_t server_channel_max;
	uint16_t server_heartbeat;

	//Stdout.format("amqp_login_inner #START").newline;

	amqp_send_header(state);

	//Stdout.format("amqp_login_inner #22").newline;

	int result_ = amqp_simple_wait_method(state, 0, AMQP_CONNECTION_START_METHOD, &method);
	if (result_ < 0)
		return result_;
	//Stdout.format("amqp_login_inner #23").newline;
	{
		amqp_connection_start_t *s = cast(amqp_connection_start_t *) method.decoded;
		if ((s.version_major != AMQP_PROTOCOL_VERSION_MAJOR) ||
		    (s.version_minor != AMQP_PROTOCOL_VERSION_MINOR)) {
			return -EINVAL;
		}

		/* TODO: check that our chosen SASL mechanism is in the list of
		   acceptable mechanisms. Or even let the application choose from
		   the list! */
	}

	//Stdout.format("amqp_login_inner #24").newline;

	{
		amqp_bytes_t response_bytes = sasl_response(&state.decoding_pool, sasl_method, vl);
		//Stdout.format("amqp_login_inner #25").newline;
		amqp_connection_start_ok_t s;
		amqp_table_t cp;
		cp.num_entries = 0;
		cp.entries = null;
		char* us = "en_US";
		amqp_bytes_t l;
		l.len = 5;
		l.bytes = us;
		s.client_properties = cp;
		s.mechanism = sasl_method_name(sasl_method);
		s.response = response_bytes;
		s.locale = l;
		//Stdout.format("amqp_login_inner #26").newline;
		result_ = amqp_send_method(state, 0, AMQP_CONNECTION_START_OK_METHOD, &s);
		//Stdout.format("amqp_login_inner #27").newline;
		if (result_ < 0)
			return result_;
	}

	//Stdout.format("amqp_login_inner #28").newline;

	amqp_release_buffers(state);


	//Stdout.format("amqp_login_inner #29").newline;

	result_ = amqp_simple_wait_method(state, 0, AMQP_CONNECTION_TUNE_METHOD, &method);
	if (result_ < 0)
		return result_;
  
	{
		amqp_connection_tune_t *s = cast(amqp_connection_tune_t *) method.decoded;
		server_channel_max = s.channel_max;
		server_frame_max = s.frame_max;
		server_heartbeat = s.heartbeat;
	}

	if (server_channel_max != 0 && server_channel_max < channel_max) {
		channel_max = server_channel_max;
	}

	if (server_frame_max != 0 && server_frame_max < frame_max) {
		frame_max = server_frame_max;
	}

	if (server_heartbeat != 0 && server_heartbeat < heartbeat) {
		heartbeat = server_heartbeat;
	}

	result_ = amqp_tune_connection(state, channel_max, frame_max, heartbeat);
	if (result_ < 0)
		return result_;

	{
		amqp_connection_tune_ok_t s;
		s.channel_max = channel_max;
		s.frame_max = frame_max;
		s.heartbeat = heartbeat;
		result_ = amqp_send_method(state, 0, AMQP_CONNECTION_TUNE_OK_METHOD, &s);
		if (result_ < 0)
			return result_;

	}

	//Stdout.format("amqp_login_inner #30").newline;
	amqp_release_buffers(state);

	//Stdout.format("amqp_login_inner #END").newline;

	return 1;
}

amqp_rpc_reply_t amqp_login(amqp_connection_state_t *state,
			    char *vhost,
			    int channel_max,
			    int frame_max,
			    int heartbeat,
			    amqp_sasl_method_enum sasl_method,
			    ...)
{
	va_list vl;
	amqp_rpc_reply_t result;

	//Stdout.format("amqp_login #START").newline;

	va_start(vl, sasl_method);

	//Stdout.format("amqp_login #1").newline;

	amqp_login_inner(state, channel_max, frame_max, heartbeat, sasl_method, vl);

	//Stdout.format("amqp_login #2").newline;

	{
		amqp_connection_open_t s;
		amqp_bytes_t caps;
		caps.len = 0;
		caps.bytes = null;
		s.virtual_host = amqp_cstring_bytes(vhost);
		s.capabilities = caps;
		s.insist = 1;
		//Stdout.format("amqp_login #3").newline;
		result = amqp_simple_rpc(state,
					 0,
					 AMQP_CONNECTION_OPEN_METHOD,
					 AMQP_CONNECTION_OPEN_OK_METHOD,
					 &s);
		if (result.reply_type != amqp_response_type_enum.AMQP_RESPONSE_NORMAL) {
			return result;
		}
	}

	//Stdout.format("amqp_login #4").newline;

	amqp_maybe_release_buffers(state);

	va_end(vl);

	result.reply_type = amqp_response_type_enum.AMQP_RESPONSE_NORMAL;
	result.reply.id = 0;
	result.reply.decoded = null;
	result.library_errno = 0;

	//Stdout.format("amqp_login #END").newline;

	return result;
}

int send_buffer_to_socket(Socket socket, void* buffer, uint length) {
	//Stdout.format("send_buffer_to_socket #START . socket = {}", socket).newline;

	void[] buf_array = new void[length];
	memcpy(buf_array.ptr, buffer, length);
	//  for(uint i = 0; i < length; i++)
	//    buf_array[i] = *(buffer + i);

	return socket.send(buf_array, SocketFlags.NONE);
}


int receive_buffer_from_socket(Socket socket, void* buffer, uint length) {
	//log.trace("#receive_buffer_from_socket start. buffer length = {}", length);
	//Stdout.format("#receive_buffer_from_socket start. ").newline;
	//	void[] buf_array = new void[length];
	/*	if(buffer is null)
		buf_array = new void[100000];*/

	/*	if(buf_array.length < length)
	{
		buf_array = new void[length];
		}*/

	//log.trace("#receive_buffer_from_socket socket receive start");

	int result = socket.receive(buf_array, SocketFlags.NONE);

	//log.trace("#receive_buffer_from_socket socket receive end");

	if (result < 0) 
	{
		//log.trace("#receive_buffer_from_socket result < 0");
		return result;
	}

	//log.trace("#receive_buffer_from_socket memcpy start");

	memcpy(buffer, buf_array.ptr, buf_array.length);
	//	memcpy(buffer, buf_array.ptr, length);

	//log.trace("#receive_buffer_from_socket memcpy end");
	//log.trace("#receive_buffer_from_socket end");
	return result;
}
