# Sync Docker VM's hardware clock which can drift when host machine sleeps
#   e.g. An error occurred (SignatureDoesNotMatch) when calling the AssumeRole operation: 
#        Signature expired: 20170103T233357Z is now earlier than 20170104T042623Z (20170104T044123Z - 15 min.)
hwclock -s 2>/dev/null
if [ $? -ne 0 ]; then
  echo "WARNING: unable to sync system time from hardware clock; you may encounter problems with signed requests as a result of time drift."
fi


