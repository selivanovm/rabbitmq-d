#!/bin/sh

sudo rabbitmqctl add_user user 123
sudo rabbitmqctl add_vhost test
sudo rabbitmqctl map_user_vhost user test