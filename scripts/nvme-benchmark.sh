#!/usr/bin/env bash
# CrystalDiskMark-style sequential benchmark (Q32T1). Output: read/write MB/s only.
# io_uring = async I/O so iodepth=32 is used (psync caps at 1 and limits throughput).
# Run on a path on your NVMe (e.g. / or $HOME). Uses 2 GiB, direct I/O.
set -e
DEST="${1:-/tmp}"
FILE="$DEST/nvme_fio_benchmark"
SIZE="2G"
IODEPTH=32
BS="1M"
ENGINE="io_uring"

fio --name=seqwrite --rw=write --bs="$BS" --size="$SIZE" --direct=1 \
    --filename="$FILE" --iodepth=$IODEPTH --numjobs=1 --ioengine=$ENGINE \
    --output-format=json |
  jq -r '"Write: \(.jobs[0].write.bw / 1024 | floor) MB/s"'

fio --name=seqread --rw=read --bs="$BS" --size="$SIZE" --direct=1 \
    --filename="$FILE" --iodepth=$IODEPTH --numjobs=1 --ioengine=$ENGINE \
    --output-format=json |
  jq -r '"Read:  \(.jobs[0].read.bw / 1024 | floor) MB/s"'

rm -f "$FILE"
