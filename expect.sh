#!/usr/bin/expect -f
set timeout 2
lassign $argv HOST PASS
 spawn ssh root@$HOST
 expect {
 "(yes/no)?*" {
 send "yes\r"
 }
} 
expect "word:"
send "OpenStack123\r"
expect "#*"
send "passwd root\r"
expect "#*"
send "exit\r"
expect eof
