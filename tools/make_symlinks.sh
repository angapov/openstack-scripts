#!/bin/bash
GIT_DIR=$(realpath `pwd`/../OpenStack)
PYTHON_DIR="/usr/lib/python2.7/site-packages"
DASHBOARD_DIR="/usr/share/openstack-dashboard"
if [[ "$GIT_DIR" == "/root"* ]]; then chmod o+rx /root; fi
if [ ! -d $PYTHON_DIR ]; then exit 1; fi

cd $PYTHON_DIR
for SERVICE in  nova                    \
                python-novaclient       \
                cinder                  \
                python-cinderclient     \
                glance                  \
                python-glanceclient     \
                ceilometer              \
                python-ceilometerclient \
                keystone                \
                python-keystoneclient   \
                ; do
    SERVICE1=${SERVICE##python-}
	if [ -d $SERVICE1 -o -L $SERVICE1 ]; then
        rm -rf $SERVICE1
        ln -s $GIT_DIR/$SERVICE/$SERVICE1 .
    fi 
done

# Links for Dashboard
#if [ -d $DASHBOARD_DIR ]; then
#    ## Very dirty hack to resolve issue with apache wanting write permission to /root/
#    cd $DASHBOARD_DIR
#    rm -rf openstack_dashboard
#    cp -rf $GIT_DIR/horizon/openstack_dashboard .
#    rm -rf $GIT_DIR/horizon/openstack_dashboard
#    ln -sf $DASHBOARD_DIR/openstack_dashboard -t $GIT_DIR/horizon
#fi
