import_utils="source $START_DIR/kr-script/mtk/mtk_utils.sh;"

function xml_start() {
    echo '<?xml version="1.0" encoding="UTF-8" ?>'
    echo "<root>"
}
function xml_end() {
    echo "</root>"
}
function resource() {
    echo "  <resource dir=\"$1\" />"
}
function group_start() {
    echo "  <group id=\"@$1\" title=\"$1\">"
}
function group_end() {
    echo "  </group>"
}
function switch() {
    echo "      <switch title=\"$1\">"
    echo "          <get>$2</get>"
    echo "          <set>$3</set>"
    echo "      </switch>"
}
function switch_hidden() {
    echo "      <switch title=\"$1\" shell=\"hidden\" >"
    echo "          <get>$2</get>"
    echo "          <set>$3</set>"
    echo "      </switch>"
}

function action() {
    echo "      <action confirm=\"true\" title=\"$1\">"
    echo "          <desc>$2</desc>"
    echo "          <set>$3</set>"
    echo "      </action>"
}

function get_row_id() {
  local row_id=`echo $1 | cut -f1 -d ']'`
  echo ${row_id/[/}
}
function get_row_title() {
    echo $1 | cut -f2 -d ' ' | cut -f1 -d ':'
}
function get_row_state() {
    echo $1 | cut -f2 -d ':'
}

function ppm_render() {
    switch_hidden "Enable PPM" "state=\`cat /proc/ppm/enabled | grep enabled\`; if [[ \$state != '' ]]; then echo 1; fi" "echo \$state > /proc/ppm/enabled"

    path="/proc/ppm/policy_status"
    cat $path | grep 'PPM_' | while read line
    do
      id=`get_row_id "$line"`
      title=`get_row_title "$line"`
      state=`get_row_state "$line"`
      # echo $id $title $state
      switch_hidden "$title" "cat $path | grep $title | grep enabled 1>&amp;2 > /dev/null &amp;&amp; echo 1" "echo $id \$state > $path"
    done
}

function ged_render() {
    local ged="/sys/module/ged/parameters"
    ls -1 $ged | grep -v "log" | grep -v "debug" | grep -E "enable|_on|mode" | while read line
    do
      # echo $line
      local title="$line"
      if [[ "$line" == "gpu_dvfs_enable" ]]; then
        title="Dynamic frequency and voltage regulation"
      elif [[ "$line" == "ged_force_mdp_enable" ]]; then
        title="Forced use of MDP"
      elif [[ "$line" == "gx_game_mode" ]]; then
        title="Game Mode"
      else
        continue # 有些效果不佳的选项，暂时隐藏掉
      fi
      switch_hidden "$title" "cat $ged/$line" "echo \$state > $ged/$line"
    done
}

function gpu_render() {
    cat /proc/gpufreq/gpufreq_opp_dump | awk '{printf $4 "\n"}' | cut -f1 -d "," > gpu_freqs
    local get_shell="cat /proc/gpufreq/gpufreq_opp_freq | grep freq | awk '{printf \$4 \"\\\\n\"}' | cut -f1 -d ','"

    echo "      <picker title=\"Fixed Frequency\" shell=\"hidden\" reload=\"@GPU\">"
    echo "          <options>"
    echo "            <option value=\"0\">Not fixed</option>"
    while read -r freq
    do
        local freq_mhz=$(($freq / 1000))
        echo "            <option value=\"${freq}\">${freq_mhz} MHz</option>"
    done < gpu_freqs
    echo "          </options>"
    echo "          <get>$get_shell</get>"
    echo "          <set>$import_utils gpu_freq</set>"
    echo "      </picker>"


    local dvfs=/proc/mali/dvfs_enable
    if [[ -f $dvfs ]]; then
      switch_hidden "Dynamic frequency and voltage regulation(DVFS)" "cat $dvfs | cut -f2 -d ' '" "echo \$state > $dvfs"
    fi
}

function cpu_render() {
    if [[ -f /sys/devices/system/cpu/sched/sched_boost ]]; then
      echo "      <picker title=\"Sched Boost\" shell=\"hidden\">"
      echo "          <options>"
      echo "            <option value=\"no boost\">no boost</option>"
      echo "            <option value=\"all boost\">all</option>"
      echo "            <option value=\"foreground boost\">foreground</option>"
      echo "          </options>"
      echo "          <get>$import_utils sched_boost_get</get>"
      echo "          <set>$import_utils sched_boost_set</set>"
      echo "      </picker>"
    fi

    if [[ -f /sys/devices/system/cpu/eas/enable ]]; then
      echo "      <picker title=\"Eas Enable\" shell=\"hidden\">"
      echo "          <options>"
      echo "            <option value=\"HMP\">HMP</option>"
      echo "            <option value=\"EAS\">EAS</option>"
      echo "            <option value=\"hybrid\">Hybrid</option>"
      echo "          </options>"
      echo "          <get>$import_utils eas_get</get>"
      echo "          <set>$import_utils eas_set</set>"
      echo "      </picker>"
    fi
}

# 显存占用 bytes
# cat /proc/mali/memory_usage | grep "Total" | cut -f2 -d "(" | cut -f1 -d " "

xml_start
    resource 'file:///android_asset/kr-script/common'
    resource 'file:///android_asset/kr-script/mtk'
    group_start 'PPM'
        ppm_render
    group_end

    #group_start 'GED'
    #     ged_render
    #group_end

if [[ -f /proc/gpufreq/gpufreq_opp_freq ]]
then
    group_start 'GPU'
      gpu_render
    group_end
fi


group_start 'CPU'
  cpu_render
group_end

group_start 'Battery Statistics'
    if [[ -f /sys/devices/platform/battery/reset_battery_cycle ]]
    then
      action "Emptying the battery cycle count" "Zero the number of battery cycles counted by the phone (this does not restore the battery capacity)" "echo 1 &gt; /sys/devices/platform/battery/reset_battery_cycle"
    fi

    if [[ -f /sys/devices/platform/battery/reset_aging_factor ]]
    then
      action "Empty battery aging rate" "Clear the battery aging will clear the phone statistics of the battery aging rate value (does not restore the battery life, reset this value may lead to a sudden shutdown when the battery is low!" "echo 1 &gt; /sys/devices/platform/battery/reset_aging_factor"
    fi
group_end
xml_end
