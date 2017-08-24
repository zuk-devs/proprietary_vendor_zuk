#!/system/bin/sh
# Copyright (c) 2012-2013, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

target=`getprop ro.board.platform`

function configure_memory_parameters() {
    # Set Memory paremeters.
    #
    # Set per_process_reclaim tuning parameters
    # 2GB 64-bit will have aggressive settings when compared to 1GB 32-bit
    # 1GB and less will use vmpressure range 50-70, 2GB will use 10-70
    # 1GB and less will use 512 pages swap size, 2GB will use 1024
    #
    # Set Low memory killer minfree parameters
    # 32 bit all memory configurations will use 15K series
    # 64 bit up to 2GB with use 14K, and above 2GB will use 18K
    #
    # Set ALMK parameters (usually above the highest minfree values)
    # 32 bit will have 53K & 64 bit will have 81K
    arch_type=`uname -m`
    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}
    echo 1 > /sys/module/process_reclaim/parameters/enable_process_reclaim
    echo 70 > /sys/module/process_reclaim/parameters/pressure_max
    echo 30 > /sys/module/process_reclaim/parameters/swap_opt_eff
    echo 1 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
    if [ "$arch_type" == "aarch64" ] && [ $MemTotal -gt 2097152 ]; then
        echo 10 > /sys/module/process_reclaim/parameters/pressure_min
        echo 1024 > /sys/module/process_reclaim/parameters/per_swap_size
        echo "18432,23040,27648,32256,55296,80640" > /sys/module/lowmemorykiller/parameters/minfree
        echo 81250 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
    elif [ "$arch_type" == "aarch64" ] && [ $MemTotal -gt 1048576 ]; then
        echo 10 > /sys/module/process_reclaim/parameters/pressure_min
        echo 1024 > /sys/module/process_reclaim/parameters/per_swap_size
        echo "14746,18432,22118,25805,40000,55000" > /sys/module/lowmemorykiller/parameters/minfree
        echo 81250 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
    elif [ "$arch_type" == "aarch64" ]; then
        echo 50 > /sys/module/process_reclaim/parameters/pressure_min
        echo 512 > /sys/module/process_reclaim/parameters/per_swap_size
        echo "14746,18432,22118,25805,40000,55000" > /sys/module/lowmemorykiller/parameters/minfree
        echo 81250 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
    else
        echo 50 > /sys/module/process_reclaim/parameters/pressure_min
        echo 512 > /sys/module/process_reclaim/parameters/per_swap_size
        echo "15360,19200,23040,26880,34415,43737" > /sys/module/lowmemorykiller/parameters/minfree
        echo 53059 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
    fi
}

case "$target" in
    "msm8996")
        # disable thermal bcl hotplug to switch governor
        echo 0 > /sys/module/msm_thermal/core_control/enabled
        echo -n disable > /sys/devices/soc/soc:qcom,bcl/mode
        bcl_hotplug_mask=`cat /sys/devices/soc/soc:qcom,bcl/hotplug_mask`
        echo 0 > /sys/devices/soc/soc:qcom,bcl/hotplug_mask
        bcl_soc_hotplug_mask=`cat /sys/devices/soc/soc:qcom,bcl/hotplug_soc_mask`
        echo 0 > /sys/devices/soc/soc:qcom,bcl/hotplug_soc_mask
        echo -n enable > /sys/devices/soc/soc:qcom,bcl/mode

        # Enable Adaptive LMK
        echo 1 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
        echo 81250 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
        # configure governor settings for little cluster
        echo "interactive" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_migration_notif
        echo 19000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay
        echo 90 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load
        echo 20000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate
        echo 960000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
        echo 80 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
        echo 19000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time
        echo 79000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis
        echo 300000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/ignore_hispeed_on_notif
        # online CPU2
        echo 1 > /sys/devices/system/cpu/cpu2/online
        # configure governor settings for big cluster
        echo "interactive" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
        echo 1 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/use_sched_load
        echo 1 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/use_migration_notif
        echo "19000 1400000:39000 1700000:19000" > /sys/devices/system/cpu/cpu2/cpufreq/interactive/above_hispeed_delay
        echo 90 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/go_hispeed_load
        echo 20000 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/timer_rate
        echo 1248000 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/hispeed_freq
        echo 1 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/io_is_busy
        echo "85 1500000:90 1800000:70" > /sys/devices/system/cpu/cpu2/cpufreq/interactive/target_loads
        echo 19000 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/min_sample_time
        echo 79000 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/max_freq_hysteresis
        echo 300000 > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq
        echo 1 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/ignore_hispeed_on_notif

	# disable nightmode display
	echo 1 > /sys/devices/virtual/graphics/fb0/ct_onoff

	# for cpu freq scaling
        chown -h system /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq
        chmod -h 664    /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq

        # re-enable thermal and BCL hotplug
        echo 1 > /sys/module/msm_thermal/core_control/enabled
        echo -n disable > /sys/devices/soc/soc:qcom,bcl/mode
        echo $bcl_hotplug_mask > /sys/devices/soc/soc:qcom,bcl/hotplug_mask
        echo $bcl_soc_hotplug_mask > /sys/devices/soc/soc:qcom,bcl/hotplug_soc_mask
        echo -n enable > /sys/devices/soc/soc:qcom,bcl/mode
        # input boost configuration
        echo "0:1324800 2:1324800" > /sys/module/cpu_boost/parameters/input_boost_freq
        echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms
        # Setting b.L scheduler parameters
        echo 0 > /proc/sys/kernel/sched_boost
        echo 1 > /proc/sys/kernel/sched_migration_fixup
        echo 45 > /proc/sys/kernel/sched_downmigrate
        echo 45 > /proc/sys/kernel/sched_upmigrate
        echo 400000 > /proc/sys/kernel/sched_freq_inc_notify
        echo 400000 > /proc/sys/kernel/sched_freq_dec_notify
        echo 3 > /proc/sys/kernel/sched_spill_nr_run
        echo 100 > /proc/sys/kernel/sched_init_task_load
        # Enable bus-dcvs
        for cpubw in /sys/class/devfreq/*qcom,cpubw*
        do
            echo "bw_hwmon" > $cpubw/governor
            echo 50 > $cpubw/polling_interval
            echo 1525 > $cpubw/min_freq
            echo "1525 5195 11863 13763" > $cpubw/bw_hwmon/mbps_zones
            echo 4 > $cpubw/bw_hwmon/sample_ms
            echo 34 > $cpubw/bw_hwmon/io_percent
            echo 20 > $cpubw/bw_hwmon/hist_memory
            echo 10 > $cpubw/bw_hwmon/hyst_length
            echo 0 > $cpubw/bw_hwmon/low_power_ceil_mbps
            echo 34 > $cpubw/bw_hwmon/low_power_io_percent
            echo 20 > $cpubw/bw_hwmon/low_power_delay
            echo 0 > $cpubw/bw_hwmon/guard_band_mbps
            echo 250 > $cpubw/bw_hwmon/up_scale
            echo 1600 > $cpubw/bw_hwmon/idle_mbps
        done

        for memlat in /sys/class/devfreq/*qcom,memlat-cpu*
        do
            echo "mem_latency" > $memlat/governor
            echo 10 > $memlat/polling_interval
        done
        echo "cpufreq" > /sys/class/devfreq/soc:qcom,mincpubw/governor

	soc_revision=`cat /sys/devices/soc0/revision`
	if [ "$soc_revision" == "2.0" ]; then
		#Disable suspend for v1.0 and v2.0
		echo pwr_dbg > /sys/power/wake_lock
	elif [ "$soc_revision" == "2.1" ]; then
		# Enable C4.D4.E4.M3 LPM modes
		# Disable D3 state
		echo 0 > /sys/module/lpm_levels/system/pwr/pwr-l2-gdhs/idle_enabled
		echo 0 > /sys/module/lpm_levels/system/perf/perf-l2-gdhs/idle_enabled
		# Disable DEF-FPC mode
		echo N > /sys/module/lpm_levels/system/pwr/cpu0/fpc-def/idle_enabled
		echo N > /sys/module/lpm_levels/system/pwr/cpu1/fpc-def/idle_enabled
		echo N > /sys/module/lpm_levels/system/perf/cpu2/fpc-def/idle_enabled
		echo N > /sys/module/lpm_levels/system/perf/cpu3/fpc-def/idle_enabled
	else
		# Enable all LPMs by default
		# This will enable C4, D4, D3, E4 and M3 LPMs
		echo N > /sys/module/lpm_levels/parameters/sleep_disabled
	fi
	echo N > /sys/module/lpm_levels/parameters/sleep_disabled
        # Starting io prefetcher service
        start iop
    ;;
esac

chown -h system /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate
chown -h system /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor
chown -h system /sys/devices/system/cpu/cpufreq/ondemand/io_is_busy

emmc_boot=`getprop ro.boot.emmc`
case "$emmc_boot"
    in "true")
        chown -h system /sys/devices/platform/rs300000a7.65536/force_sync
        chown -h system /sys/devices/platform/rs300000a7.65536/sync_sts
        chown -h system /sys/devices/platform/rs300100a7.65536/force_sync
        chown -h system /sys/devices/platform/rs300100a7.65536/sync_sts
    ;;
esac

# Let kernel know our image version/variant/crm_version
if [ -f /sys/devices/soc0/select_image ]; then
    image_version="10:"
    image_version+=`getprop ro.build.id`
    image_version+=":"
    image_version+=`getprop ro.build.version.incremental`
    image_variant=`getprop ro.product.name`
    image_variant+="-"
    image_variant+=`getprop ro.build.type`
    oem_version=`getprop ro.build.version.codename`
    echo 10 > /sys/devices/soc0/select_image
    echo $image_version > /sys/devices/soc0/image_version
    echo $image_variant > /sys/devices/soc0/image_variant
    echo $oem_version > /sys/devices/soc0/image_crm_version
fi
