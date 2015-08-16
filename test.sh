#!/bin/bash
#test.sh

#Ubaciti u folder gde se nalaze zadaci takmicara ("kodovi")
#Unutar foldera sa test primerima, testcases mora biti malim slovima i svaki test primer/resenje mora biti u formatu:
#ime_zadatka.redni_broj.<in/out/sol>
#Vreme izvrsavanja: 6-7h za timeout 10s, 4-5h za timeout 5s @ 1x3.2GHz

TIMEFORMAT='%3R=%3U+%3S' #Format ispisa vremena za bash time (NE /usr/bin/time)
#Imena zadataka
name1='apsolutno'
name2='izmena'
name3='anti'
name4='zamena'
name5='brojanje'
name6='kontra'
#Vremenska ogranicenja, po zadatku:
timelimit1='5s' #s obzirom da ne znam u brzinu u odnosu da brzinu gradera, preventivno stavljam na dosta visu vrednost
timelimit2='5s'
timelimit3='5s'
timelimit4='5s'
timelimit5='5s'
timelimit6='5s'
#Memorijska ogranicenja, po zadatku, u kilobajtima
memlimit1=$((1024*64))
memlimit2=$((1024*64))
memlimit3=$((1024*64))
memlimit4=$((1024*64))
memlimit5=$((1024*256))
memlimit6=$((1024*64))
tproot="../../TestPrimeri" #relativna putanja do foldera sa test primerima, iz foldera takmicara

#Kompajlira program odgovarajucim kompajlerom, preusmerava stdout u null, a stderr u fajl ime_zadatka.err
#Koristi iste opcije koje su date na papiru i dodaje -w, tj. -ve da spreci ispisivanje upozorenja
compile() {
	mkdir out
	if [[ $3 = 'c' ]]; then
		/usr/bin/gcc -w -DEVAL -static -O2 -o $2 $1 -lm >/dev/null 2>"${2}.err"
	elif [[ $3 = 'cpp' ]]; then
		/usr/bin/g++ -w -DEVAL -static -O2 -o $2 $1 >/dev/null 2>"${2}.err"
	elif [[ $3 = 'pas' ]]; then 
		err=$(/usr/bin/fpc -ve -dEVAL -XS -O2 $1) #fpc ispisuje greske na stdout
		if [[ $err == *"Fatal"* ]]; then
			echo $err >"${2}.err"
		fi
	fi
}

#Pokrece program i ispisuje rezultate i proteklo vreme u fajl u folderu out. Ime je istovetno kao i ime resenja, 
#dok se vreme upisuje u fajl sa ekstenzijom .time u formatu ukupno_vreme=userspace_vreme+kernelspace_vreme
#Ogranicenja se uzimaju iz promenljivih (vidi gore)
run() {
	case "$1" in
		"$name1") memlimit=$memlimit1 
				 timelimit=$timelimit1 ;;
		"$name2") memlimit=$memlimit2 
				 timelimit=$timelimit2 ;;
		"$name3") memlimit=$memlimit3 
				 timelimit=$timelimit3 ;;
		"$name4") memlimit=$memlimit4 
				 timelimit=$timelimit4 ;;
		"$name5") memlimit=$memlimit5 
				 timelimit=$timelimit5 ;;
		"$name6") memlimit=$memlimit6 
				 timelimit=$timelimit6 ;;
	esac
	for tp in ${2}*; do
		tpname="${tp##*/}"
		if [[ "${tpname##*.}" == "in" ]]; then
		#pokrece subshell sa datim memorijskim limitom
		#bash time, mora u viticastim zagradama, da ne bi posmatrao preusmeravanje kao komandu za merenje
		( ulimit -v $memlimit && { time timeout $timelimit ./$1 < $tp > "out/${tpname%.*}.out"; } 2>"out/${tpname%.*}.time" )
		elif [[ "${tpname##*.}" == "sol" ]]; then
			mv "out/${tpname%.*}.out" "out/${tpname%.*}.sol" #imena test primera su malo haoticna :/
		fi
	done
}

#Uporedjuje sve izlaze i vreme, i pise u fajl username.rez, koji se smesta u isti folder kao i ova skripta
#"Tacnost" se oznacava vrednostima od 0 do 1, u procentima (npr. 60% je 0.6)
#.rez fajl je u formatu: tacnost, vreme [+ sadrzaj stderr]
#Ako je doslo do greske pri kompajliranju, ispisuje "CE:" praceno porukom kompajlera, zavrsava sa EC
print() {
	rez="../${2}.rez"
	errfile="${4}.err"
	echo $3 >> $rez
	if [[ -s $errfile ]]; then
		echo "CE: " >> $rez
		cat $errfile >> $rez
		echo "EC" >> $rez
	fi
	for outfile in out/*; do
		if [[ "${outfile##*.}" = 'out' || "${outfile##*.}" = 'sol' ]]; then
			outfilename="${outfile##*/}"
			timefile="${outfile%.*}.time"
			time=$(<$timefile)
			head -c -1 $1$outfilename > "temp" #sve sem poslednjeg karaktera (newline)
			nums=($($(<$1$outfilename))
			outnums=($($(<$outfile))
			if cmp -s "$outfile" "$1$outfilename" || cmp -s "$outfile" "temp"; then
				echo "1, $time" >> $rez
			#dodati elif i odgovarajuci test ako su rezultati sem 0 i 1 moguci ili 
			#postoji vise razlicitih resenja koja nisu u .sol/.out fajlu
			else
				echo "0, $time" >> $rez
			fi
		fi
	done
	echo "" >> $rez
}

#Radi testiranje direktorijuma
#Razdvojeno da bi skripta mogla da radi sa i bez argumenata
#Brise sve fajlove sem .rez kada vise nisu potrebni
process() {
	>&2 echo $dir
    	rm "${dir}.rez" >/dev/null 2>/dev/null #Brisem prethodni rezultat ako postoji
        cd $dir

	    for file in *; do
			extension="${file##*.}"
			filename="${file%.*}"
			#Skinuti komentar ako za testiranje samo A kategorije
			#if [[ $filename = 'kodovi' || $filename = 'skrinja' || $filename = 'presto' ]]; then
			
			tpdir="${tproot}/${filename}/"
			if [[ $extension = 'c' || $extension = 'cpp' || $extension = 'pas' ]]; then
				compile $file $filename $extension
				echo "kompajlirao ${dir}/${file}"
				run $filename $tpdir
				rm $filename 2>/dev/null #iskomentarisati 2>/dev/null za prosledjivanje poruka o gresci pri brisanju na konzolu (ako je doslo do CE)
				if [[ $extension = 'pas' ]]; then
					rm "${filename}.o" 2>/dev/null
				fi
				echo "Uradio testiranje zadatka $filename ucenika $dir"
				print $tpdir $dir $file $filename
				rm -rf out
				rm "${filename}.err"
				echo "Ispisao rezultate zadatka $filename ucenika $dir"
				
				#else
					#echo "Preskacem ucenika $dir : B kategorija"
				#fi
			fi
        done
		rm temp 2>/dev/null #iskomentarisati 2>/dev/null za prosledjivanje poruka o gresci pri brisanju na konzolu
		
        cd ..
}

if [[ $# < 1 ]]; then #ako nije prosledjen nijedan argument
	for dir in *; do
    	if [ -d "${dir}" ]; then #posmatra se svaki poddirektorijum ovog direktorijuma
    		process $dir
    	fi
	done
else
	for dir in $@; do #testiraju se samo oni folderi iz argumenata
		process $dir
	done
fi
echo 'test done'
