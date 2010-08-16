#!/bin/sh

tango=/usr/include/d/dmd/tango

rm SendString Listen

dmd -version=Tango -Iexport src/Log.d $tango/net/InternetAddress $tango/net/device/Socket $tango/stdc/stdarg.d $tango/stdc/errno.d examples/example_utils.d examples/amqp_sendstring.d librabbitmq.a -O -release -ofSendString

dmd -version=Tango -Iexport src/Log.d $tango/net/InternetAddress $tango/net/device/Socket $tango/stdc/stdarg.d $tango/stdc/errno.d examples/example_utils.d examples/amqp_listen.d librabbitmq.a -O -release -ofListen

rm *.o