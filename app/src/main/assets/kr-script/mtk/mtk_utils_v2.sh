perfmgr=/sys/module/mtk_fpsgo/parameters/perfmgr_enable
pandora_feas=/sys/module/perfmgr_mtk/parameters/perfmgr_enable
if [[ -f $pandora_feas ]]; then
  perfmgr=$pandora_feas
fi
fpsgo=/sys/kernel/fpsgo/common/fpsgo_enable
hybrid=/data/adb/modules/dimensity_hybrid_governor
if [[ -f /proc/gpufreqv2/stack_signed_opp_table ]]; then
    TABLE="/proc/gpufreqv2/stack_signed_opp_table"
elif [[ -f /proc/gpufreqv2/gpu_working_opp_table ]]; then
    TABLE="/proc/gpufreqv2/gpu_working_opp_table"
fi

lock_value () {
  chmod 644 "$2"
  echo "$1" > "$2"
  chmod 444 "$2"
}

gpu_freq(){
  # echo 'gpu_freq' $state
  if [[ "$state" == "-1" ]]; then
    echo -1 > /proc/gpufreqv2/fix_target_opp_index
    echo 0 0 > /proc/gpufreqv2/fix_custom_freq_volt
  else
    if [[ "$voltage" == "" || "$voltage" = "-1" ]]; then
      freq_row=$(grep "$state," "$TABLE")
      opp=${freq_row:1:2}
      echo 0 0 > /proc/gpufreqv2/fix_custom_freq_volt
      echo "$opp" > /proc/gpufreqv2/fix_target_opp_index
    else
      echo -1 > /proc/gpufreqv2/fix_target_opp_index
      echo "$state" "$voltage" > /proc/gpufreqv2/fix_custom_freq_volt
    fi
  fi
}

gpu_freq_cur_khz() {
 gpu_freq_cur KHz
}
gpu_freq_cur_khz2() {
 freq=$(gpu_freq_cur)
 volt=$(gpu_volt_cur)
 if [[ "$freq" != "" ]]; then
   if [[ "$volt" != "" ]]; then
     echo "${freq}KHz,${volt}mV"
   else
     echo "$freq"KHz
   fi
 fi
}
gpu_freq_cur() {
  fix_freq_volt=$(cat /proc/gpufreqv2/fix_custom_freq_volt | grep -v disabled)
  if [[ "$fix_freq_volt" == "" ]]; then
    opp=$(grep ':' /proc/gpufreqv2/fix_target_opp_index | cut -f2 -d ':')
    if [[ "$opp" == "" ]]; then
      echo ''
    else
      opp=$(printf "%02d" "$opp")
      freq_row=$(grep "\[$opp" "$TABLE")
      echo -n "${freq_row:11:6}""$1"
    fi
  else
     freq=$(echo -n "$fix_freq_volt" | awk '{ print $4}')
     echo "$freq""$1"
  fi
}
gpu_volt_cur(){
  fix_freq_volt=$(cat /proc/gpufreqv2/fix_custom_freq_volt | grep -v disabled)
  if [[ "$fix_freq_volt" != "" ]]; then
     echo "$fix_freq_volt" | awk '{ print $7}'
  fi
}

ddr_freq () {
  dvfsrc=/sys/class/devfreq/mtk-dvfsrc-devfreq
  chmod 664 $dvfsrc/min_freq
  echo "$state" > $dvfsrc/min_freq
  chmod 444 $dvfsrc/min_freq
}

ddr_freq_fixed () {
  dir='/sys/kernel/helio-dvfsrc'
  dvfsrc=${dir}/dvfsrc_force_vcore_dvfs_opp

  echo "$state" > $dvfsrc
}

# gpu_freq_max [oppIndex]
gpu_freq_max() {
  lock_value "$state" /sys/kernel/ged/hal/custom_upbound_gpu_freq
}
# gpu_freq_max_freq [freqKHZ]
gpu_freq_max_freq() {
  lock_value "$state" /sys/kernel/ged/hal/custom_upbound_gpu_freq

  state=-1
  gpu_freq
}
gpu_freq_max_freq_cur(){
  cur=$(cat /sys/kernel/ged/hal/custom_upbound_gpu_freq)
  cur=$(printf "%02d" "$cur")
  freq_row=$(grep "\[$cur" "$TABLE")
  echo -n "${freq_row:11:7}""$1"
}
gpu_freq_max_freq_cur_khz(){
  gpu_freq_max_freq_cur KHz
}

verify_sc(){
  sc=$(pgrep scene-scheduler)
  if [[ "$sc" != "" ]]; then
    echo "It is detected that SCENE's performance tuning policy is running. This modification may be overwritten soon or even fail!" 1>&2
    killall scene-scheduler 2>/dev/null
  fi
}
set_dcs_mode(){
  verify_sc
  dcs_mode=/sys/kernel/ged/hal/dcs_mode
  lock_value "$state" $dcs_mode
}
set_ged_kpi(){
  verify_sc
  ged_kpi=/sys/module/sspm_v3/holders/ged/parameters/is_GED_KPI_enabled
  lock_value "$state" $ged_kpi
}
set_fpsgo(){
  verify_sc
  lock_value "$state" $fpsgo
}

dimensity_hybrid_switch() {
  module=/data/adb/modules/dimensity_hybrid_governor
  disable=$module/disable
  if [[ $(pidof gpu-scheduler) != '' ]]; then
    echo "" > $disable
    killall gpu-scheduler 2>/dev/null
  else
    if [[ -d /sys/kernel/debug ]]; then
      umount /sys/kernel/debug 2>/dev/null
    fi
    mount -t debugfs none /sys/kernel/debug
    nohup $module/gpu-scheduler > /dev/null 2>&1 &
    rm -f $disable 2>/dev/null
  fi
}

set_perfmgr() {
  if [[ $(pidof uperf) != "" ]] || [[ $(pidof scene-scheduler) != "" ]]; then
    echo "Unable to enable Perfmgr when using [Uperf] and [SCENE-Classic]" 1>&2
    lock_value 0 $perfmgr
    return
  fi

  if [[ $(cat $fpsgo) != "1" ]]; then
    lock_value 1 $fpsgo
  fi

  if [[ $(cat "$ged_kpi") != "1" ]] && [[ ! -d $hybrid ]]; then
    lock_value 1 "$ged_kpi"
  fi

  lock_value "$state" $perfmgr

  echo "Please note:"
  echo "1. Perfmgr may cause daily fluency to decrease, and it is recommended to turn it off when not playing games."
  echo "2. [SCENE-Online] The configuration scheme will automatically manage the FEAS enablement status"
  echo "3. Manually modifying the CPU frequency will cause Perfmgr to become invalid (can be restored by restarting the phone)"
  echo "4. Disabling Joyose will still enable Perfmgr, but the behavior will be slightly different"
}