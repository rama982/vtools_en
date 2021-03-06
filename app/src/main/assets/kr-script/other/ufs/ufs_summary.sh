if [[ -f /sys/devices/platform/soc/1d84000.ufshc/health_descriptor/life_time_estimation_a ]]; then
  #qcom
  bDeviceLifeTimeEstA=$(cat /sys/devices/platform/soc/1d84000.ufshc/health_descriptor/life_time_estimation_a)
elif [[ -f /sys/devices/platform/soc/1d84000.ufshc/health/lifetimeA ]]; then
  #pixel
  bDeviceLifeTimeEstA=$(cat /sys/devices/platform/soc/1d84000.ufshc/health/lifetimeA)
elif [[ -f  /sys/devices/platform/bootdevice/health_descriptor/life_time_estimation_a ]]; then
  #mtk
  bDeviceLifeTimeEstA=$(cat  /sys/devices/platform/bootdevice/health_descriptor/life_time_estimation_a)
elif [[ $(echo /sys/kernel/debug/*.ufshc/dump_health_desc) != "/sys/kernel/debug/*.ufshc/dump_health_desc" ]]; then
  bDeviceLifeTimeEstA=$(cat /sys/kernel/debug/*.ufshc/dump_health_desc 2>/dev/null | grep bDeviceLifeTimeEstA | cut -f2 -d '=' | cut -f2 -d ' ')
fi

# 0x00 No information about the service life of the device was found.
# 0x01 The estimated life of the device is 0% to 10%.
# 0x02 The estimated life of the device is 10% to 20%.
# 0x03 The estimated life of the device is 20% to 30%.
# 0x04 The estimated life of the device is 30% to 40%.
# 0x05 The estimated life of the device is 40% to 50%.
# 0x06 The estimated life of the device is 50% to 60%.
# 0x07 The estimated life of the device is 60% to 70%.
# 0x08 The estimated life of the device is 70% to 80%.
# 0x09 The estimated life of the device is 80% to 90%.
# 0x0A The estimated life of the device is 90% to 100%.
# 0x0B The device has exceeded its estimated useful life.

[[ -z "$bDeviceLifeTimeEstA" ]] && { echo "This device has not use ufs nor health info" ; exit 0; }

case $bDeviceLifeTimeEstA in
"0x00"|"0x00")
  echo 'Life span unknown'
;;
"0x01"|"0x1")
  echo 'Life span 0% ~ 10%'
;;
"0x02"|"0x2")
  echo 'Life span 10% ~ 20%'
;;
"0x03"|"0x3")
  echo 'Life span 20% ~ 30%'
;;
"0x04"|"0x4")
  echo 'Life span 30% ~ 40%'
;;
"0x05"|"0x5")
  echo 'Life span 40% ~ 50%'
;;
"0x06"|"0x6")
  echo 'Life span 50% ~ 60%'
;;
"0x07"|"0x7")
  echo 'Life span 60% ~ 70%'
;;
"0x08"|"0x8")
  echo 'Life span 70% ~ 80%'
;;
"0x09"|"0x9")
  echo 'Life span 80% ~ 90%'
;;
"0x0A"|"0xA")
  echo 'Life span 90% ~ 100%'
;;
"0x0B"|"0xB")
  echo 'Estimated life span has been exceeded'
;;
*)
  echo 'Life span unknown'
;;
esac