#!/bin/bash
#launch.sh
#pokrece vise test.sh skripti kao razlicite procese

parts=$(getconf _NPROCESSORS_ONLN) #broj procesa, default je broj jezgara
dirs=$(ls -d */)
dirarr=($dirs)
dirnum=${#dirarr[@]} #broj direktorijuma
i=0
res=$(expr $dirnum / $parts)
for dir in "${dirarr[@]}"; do
	for (( j=0; j<$parts; j++ )); do
		if [[ $i < $(( $(($j+1)) * res )) ]]; then
			part[$j]="${part[$j]} ${dir%?}"
			break
		fi
	done
	i=$(( $i+1 ))
done
for p in "${part[@]}"; do
	./test.sh $p &
done
echo "done exec"
