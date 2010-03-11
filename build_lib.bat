rem rm export/*
rem rm librabbitmq.a 
dmd src/Log.d src/amqp_base.d src/amqp_private.d src/amqp_mem.d src/amqp.d src/amqp_table.d src/amqp_framing.d  src/amqp_framing_.d src/amqp_connection.d src/amqp_socket.d src/amqp_api.d -O -Hdexport -release -lib -oflibrabbitmq


