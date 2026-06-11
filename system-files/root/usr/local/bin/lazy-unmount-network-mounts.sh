#!/bin/bash
# Lazily unmount all autofs managed mounts before stopping

echo "[$(date -Ins)] Unmounting network mounts..."

umount -l /mnt/nas/home
umount -l /mnt/nas/Videos

echo "[$(date -Ins)] Finished unmounting network mounts"
