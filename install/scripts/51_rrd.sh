#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

pkg_add -v -m -I rrdtool
template="/var/mailserv/install/templates"
install -m 644 ${template}/rrdmon.conf /etc

# Create rrd databases
rrd_dir="/var/spool/rrd"
mkdir -p ${rrd_dir}

# Accept data every 5 minutes
# Store 1 datapoint every 5 minute and keep 1 day
# Store 1 datapoint every 30 minutes and keep 1 week
# Store 1 datapoint every 2 hours and keep 1 month
# Store 1 datapoint every 1 day and keep 1 year
rrdtool create ${rrd_dir}/cpu.rrd --step 300 \
DS:user:GAUGE:400:0:100 \
DS:system:GAUGE:400:0:100 \
DS:idle:GAUGE:400:0:100 \
RRA:AVERAGE:0.5:1:288 \
RRA:AVERAGE:0.5:6:336 \
RRA:AVERAGE:0.5:24:372 \
RRA:AVERAGE:0.5:288:365

rrdtool create ${rrd_dir}/mem.rrd --step 300 \
DS:usage:GAUGE:400:0:U \
DS:free:GAUGE:400:0:U \
RRA:AVERAGE:0.5:1:288 \
RRA:AVERAGE:0.5:6:336 \
RRA:AVERAGE:0.5:24:372 \
RRA:AVERAGE:0.5:288:365

rrdtool create ${rrd_dir}/swap.rrd --step 300 \
DS:usage:GAUGE:400:0:U \
DS:free:GAUGE:400:0:U \
RRA:AVERAGE:0.5:1:288 \
RRA:AVERAGE:0.5:6:336 \
RRA:AVERAGE:0.5:24:372 \
RRA:AVERAGE:0.5:288:365

rrdtool create ${rrd_dir}/mail.rrd --step 300 \
DS:sent:GAUGE:400:0:U \
DS:received:GAUGE:400:0:U \
DS:bounced:GAUGE:400:0:U \
DS:rejected:GAUGE:400:0:U \
DS:virus:GAUGE:400:0:U \
DS:spam:GAUGE:400:0:U \
RRA:AVERAGE:0.5:1:288 \
RRA:AVERAGE:0.5:6:336 \
RRA:AVERAGE:0.5:24:372 \
RRA:AVERAGE:0.5:288:365

#rrdtool create ${rrd_dir}/pf.rrd --step 300 \
#DS:in_pass:COUNTER:400:0:U \ 
#DS:in_block:COUNTER:400:0:U \
#DS:out_pass:COUNTER:400:0:U \ 
#DS:out_block:COUNTER:400:0:U \
#RRA:AVERAGE:0.5:1:288 \
#RRA:AVERAGE:0.5:6:336 \
#RRA:AVERAGE:0.5:24:372 \
#RRA:AVERAGE:0.5:288:365


cat <<EOF >> /etc/crontab
# Collect System stats
*/5     *       *       *       *       root    /var/mailserv/scripts/rrdmon-poll >/dev/null 2>&1

EOF
