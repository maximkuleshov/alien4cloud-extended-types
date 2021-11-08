#!/bin/bash -e

partition_number=1
device_name=${DEVICE}

if [[ -L "$device_name" ]]; then
  device_name="`readlink -f $device_name`"
fi

echo "Checking existing partition for $device_name"
export LC_ALL=C

if [ -x "$(command -v parted)" ]; then
    sudo parted --script $device_name print 2>/dev/null | grep "Partition Table: unknown"
    PARTITION_UNKNOWN=$(echo $?)
    if [ $PARTITION_UNKNOWN -eq 0 ] ; then
        echo "Creating disk partition gpt on device ${device_name}"
        sudo parted --script $device_name \
            mklabel gpt \
            mkpart primary 0% 100%
    else
        echo "Not partitioning device since a partition already exist"
    fi
elif [ -x "$(command -v sgdisk)" ]; then
    sudo sgdisk -p $device_name 2>/dev/null | grep -q "Creating new GPT entries"
    PARTITION_EMPTY=$?
    if [ $PARTITION_EMPTY -eq 0 ]; then
        echo "Creating disk partition gpt on device ${device_name}"
        sudo sgdisk --largest-new=0 $device_name
    else
        echo "Not partitioning device since a partition already exist"
    fi 
else
    echo "No parted and no sgdisk - can not check/create parition" >&2
    exit 1
fi

# Set this runtime property on the source (the filesystem)
# its needed by subsequent scripts
# ctx source instance runtime-properties filesys ${device_name}${partition_number}
export PARTITION_NAME=${device_name}${partition_number}
