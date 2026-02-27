#!/usr/bin/env bash
# CrystalDiskMark-style sequential benchmark (Q32T1).
# io_uring = async I/O so iodepth=32 is used (psync caps at 1 and limits throughput).
# Run on a path on your NVMe (e.g. / or $HOME). Uses 2 GiB, direct I/O.
set -e
DEST="${1:-/tmp}"
FILE="$DEST/nvme_fio_benchmark"
SIZE="2G"
IODEPTH=32
BS="1M"
ENGINE="io_uring"

echo "Target: $FILE (${SIZE}, iodepth=$IODEPTH, bs=$BS, ioengine=$ENGINE)"
echo "--- Sequential WRITE (like CrystalDiskMark Seq Q32T1) ---"
fio --name=seqwrite --rw=write --bs="$BS" --size="$SIZE" --direct=1 \
    --filename="$FILE" --iodepth=$IODEPTH --numjobs=1 --ioengine=$ENGINE \
    --output-format=normal
echo ""
echo "--- Sequential READ ---"
fio --name=seqread --rw=read --bs="$BS" --size="$SIZE" --direct=1 \
    --filename="$FILE" --iodepth=$IODEPTH --numjobs=1 --ioengine=$ENGINE \
    --output-format=normal
rm -f "$FILE"
echo "Done. Compare WRITE/READ MB/s to CrystalDiskMark (Seq Q32T1)."
