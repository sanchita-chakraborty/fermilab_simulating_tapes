#!/usr/bin/env bash
# vim: tabstop=4 shiftwidth=4 expandtab colorcolumn=80 foldmethod=marker :

# make sure we have the kernel directory defined
if [ -z "${KDIR}" ] ; then
    echo "error: you must supply environment variable KDIR" 1>&2
    echo "       or you do not have the kernel-devel installed" 1>&2
    exit 1
fi

#
# "syms" is an associative array, where the "key"
# is a symbol that we try to find (using grep) in
# the "value", i.e. we try to find the string
# "sysfs_emit" in the include file sysfs.h. Based
# on that, we create a cpp #define or #undef.
#
declare -A syms
syms[kmem_cache_create_usercopy]='slab.h'
syms[file_inode]='fs.h'
syms[sysfs_emit]='sysfs.h'

output='config.h'
kparent="${KDIR%/*}"

# use the "fs.h" to determine where the kernel headers are located
if [ -e "${KDIR}/include/linux/fs.h" ]
then
    hdrs="${KDIR}"
elif [ -e "${kparent}/source/include/linux/fs.h" ]
then
    hdrs="${kparent}/source"
else
    echo "Cannot infer kernel headers location" 1>&2
    exit 1
fi

rm -f "${output}"

cat <<EOF >"${output}"
/* Autogenerated by kernel/config.sh - do not edit
 */

#ifndef _MHVTL_KERNEL_CONFIG_H
#define _MHVTL_KERNEL_CONFIG_H


EOF

for sym in ${!syms[@]}
do
    grep -q "${sym}" "${hdrs}/include/linux/${syms[$sym]}"
    if [ $? -eq 0 ]
    then
        printf '#define HAVE_%s\n' "$( echo "${sym}" | tr [:lower:] [:upper:] )" >> "${output}"
    else
        printf '#undef HAVE_%s\n' "$( echo "${sym}" | tr [:lower:] [:upper:] )" >> "${output}"
    fi
done

# do we have a "genhd.h" present?
if [ -e "${hdrs}/include/linux/genhd.h" ]; then
    echo "#define HAVE_GENHD"
else
    echo "#undef HAVE_GENHD"
fi >> "${output}"

# see if "struct file_operations" has member "unlocked_ioctl"
# (otherwise, just "ioctl")
syms[file_operations]='fs.h'
if grep -q unlocked_ioctl "${hdrs}/include/linux/fs.h"; then
    echo "#ifndef HAVE_UNLOCKED_IOCTL"
    echo "#define HAVE_UNLOCKED_IOCTL"
    echo "#endif"
else
    echo "#undef HAVE_UNLOCKED_IOCTL"
fi >> "${output}"

# check for the scsi queue command taking one or two args
str=$( grep 'rc = func_name##_lck' ${hdrs}/include/scsi/scsi_host.h )
if [[ "$str" == *,* ]] ; then
    echo "#undef QUEUECOMMAND_LCK_ONE_ARG"
else
    echo "#ifndef QUEUECOMMAND_LCK_ONE_ARG"
    echo "#define QUEUECOMMAND_LCK_ONE_ARG"
    echo "#endif"
fi >> "${output}"

printf '\n\n#endif /* _MHVTL_KERNEL_CONFIG_H */\n' >> "${output}"
