#!/bin/sh
set -eu
test -f /var/lib/postgresql/hw07/ready
for port in 5540 5541 5543 5544; do
  pg_isready -q -h 127.0.0.1 -p "$port" -U course -d course_hw07
done
