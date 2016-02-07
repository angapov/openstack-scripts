#!/bin/bash
trap 'echo "{}" > /var/www/html/static/perf.json; echo Terminated; exit 1' INT TERM
fio --output-format=json --status-interval=1  $1 | perl -we '$|=1; $a="" ; while(<>) { $a.=$_; if ($_=~/^}/) {open($fd,">","/var/www/html/static/perf.json"); print $fd $a ; $a=""; close $fd;}}'
echo "{}" > /var/www/html/static/perf.json
