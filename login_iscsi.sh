#!/bin/bash
USAGE="Choose option: -l login to all targets, -u logout from all targets"
LOGIN="Client4"
PASS="Client4password"
NODES='10.10.119.91 10.10.119.92 10.10.119.93'
for H in $NODES; do
    T=`iscsiadm --mode discoverydb --type sendtargets --portal $H --discover`
    if [ $? -ne 0 ]; then continue; fi 
    TARGET=`echo $T | head -n1 | awk '{print $2}'`
    iscsiadm -m node -T $TARGET -p $H -o update -n node.session.auth.username -v $LOGIN
    iscsiadm -m node -T $TARGET -p $H -o update -n node.session.auth.password -v $PASS
done
iscsiadm -m node -P 1
case $1 in
    -l) iscsiadm -m node -L all;;
    -u) iscsiadm -m node -U all;;
    -r) iscsiadm -m node -R ;;
    *)  echo $USAGE ;;
esac
