#!/bin/sh

php bin/console cache:warmup

exec "$@"
