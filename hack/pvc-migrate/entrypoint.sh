#!/bin/sh

ls -lah /src_vol /dst_vol
df -h
rsync -avPS --delete /src_vol/ /dst_vol/
ls -lah /dst_vol/
du -shxc /src_vol/ /dst_vol/
echo "Migration completed successfully from /src_vol/ /dst_vol/"