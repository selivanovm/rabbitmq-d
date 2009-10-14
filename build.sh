rm export/*
dmd src/amqp_base.d src/amqp_private.d src/amqp_mem.d src/amqp.d src/amqp_framing.d  src/amqp_socket.d src/amqp_api.d -O -Hdexport -release -lib
