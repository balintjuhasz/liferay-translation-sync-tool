#!/bin/bash

declare -g backported_postfix=".backported"

declare -Ag charc # colors
declare -Ag chart # text legend

charc["x"]=$BLUE; chart["x"]="No action, key doesn't exist in newer version"
charc["t"]=$LILA; chart["t"]="No action, key is automatic translated in older version and untranslated in newer one"
charc["c"]=$COLOROFF; chart["c"]="No action, key is automatic copied both in older and newer versions"
charc["b"]=$YELLOW; chart["b"]="Backport!, key is automatic copied in older and automatic translated in newer one."
charc["B"]=$WHITE; chart["B"]="Backport!, key untranslated in older and translated in newer one, same english meaning"
charc["r"]=$CYAN; chart["r"]="No action, key translated in newer, but different english meaning. Human review required (semantic change, echoed to $file_hrr_changes)"
charc["R"]=$GREEN; chart["R"]="No action, key translated in newer and older, translations are different but same english meaning. Human review required (refinement, echoed to $file_hrr_improvements)"
charc["·"]=$LILA; chart["·"]="No action, key translated in newer and older, same english meaning and translation"
charc["!"]=$RED; chart["!"]="No action, uncovered case"
charc["#"]=$COLOROFF; chart["#"]="No action, line is a comment"

function backport() {
	now="$(date +%s%N)"
	logt 2 "Backporting to '$1'"
	clear_translations
	read_lang_files $1
	file="${target_lang_path}${backported_postfix}"
	file_hrr_improvements="${target_lang_path}.review.improvements"
	file_hrr_changes="${target_lang_path}.review.changes"
	declare -A result
	backports=0
	improvements=0
	changes=0
	deprecations=0
    chart["r"]="No action, key translated in newer, but different english meaning. Human review required (semantic change, echoed to $file_hrr_changes)"
    chart["R"]="No action, key translated in newer and older, translations are different but same english meaning. Human review required (refinement, echoed to $file_hrr_improvements)"
    echo_legend
    logt 3 "Writing into $file "
	rm -f $file $file_hrr_improvements $file_hrr_changes
	done=false;
	until $done; do
	    read line || done=true
		result[$file]="$line"
		result[$file_hrr_improvements]="$line"
		result[$file_hrr_changes]="$line"
		char="!"
		if is_key_line "$line" ; then
			[[ "$line" =~ $kv_rexp ]] && key="${BASH_REMATCH[1]}"	# Let process the key....
			if exists_in_new $key; then							# key exists in newer version
				if is_translated $new_lang $key; then			#	key is translated in the newer version :)
					if is_translated $old_lang $key; then		#		key is also translated in the old version
						if english_value_changed $key; then		#			english original changed amongst versions 	> there is a semantic change, human review required
							result[$file_hrr_changes]="${key}=${T[$new_lang$key]}"
							char="r"
							(( changes++ ))
						else									#			english unchanged amongst versions
							if lang_value_changed $key; then	#				translation changed amongst version		> there is a refinement, human review requirement
								result[$file_hrr_improvements]="${key}=${T[$new_lang$key]}"
								char="R"
								(( improvements++ ))
							else								#				translation unchanged amongst version		> none to do
								char="·"
							fi
						fi
					else										#		key is not translated in the old version		> lets try to backport it
						if english_value_changed $key; then		#			english original changed amongst versions 	> there is a semantic change, human review required
							result[$file_hrr_changes]="${key}=${T[$new_lang$key]}"
							char="r"
							(( changes++ ))
						else									#			english unchanged amongst versions 			> backport it!
							result[$file]="${key}=${T[$new_lang$key]}"
							char="B"
							(( backports++ ))
						fi
					fi
				else											#	key is untranslated in the newer version			> almost none to do :(
					if is_automatic_copy $old_lang $key; then	#		old translation is a mere copy
						if is_automatic_translation $new_lang $key; then #	new translation is automatic				> lets backport
							result[$file]="${key}=${T[$new_lang$key]}"
							char="b"
							(( backports++ ))
						else
							char="c"							#			both newer and older translations are automatic copies
						fi
					else
						char="t"								#		untranslated in newer, automatic translated in older
					fi
				fi
			else												# key doesn't exist in newer version
				char="x"
				(( deprecations++ ))
			fi
		else
			char="#"
		fi
		printf "${result[$file]}" >> $file
		printf "${result[$file_hrr_improvements]}" >> $file_hrr_improvements
		printf "${result[$file_hrr_changes]}" >> $file_hrr_changes
		loglc 0 ${charc[$char]} -n "$char"
	done < $target_lang_path
	log

	if [[ $do_commit -eq 0 ]]; then
		logt 3 "Moving $file to $target_lang_path"
		mv $file $target_lang_path
		file=$target_lang_path
	fi
	logt 3 "Summary of '$1' backport process:"
	logt 4 "- $backports keys backported"
	logt 4 "- $deprecations keys are in $target_english_path but not in $source_english_path"
	if [[ $improvements -eq 0 ]]; then
		rm  -f $file_hrr_improvements;
		logt 4 "- No improvements over previous translations in $target_lang_path"
	else
		logt 4 "- $improvements improvements over previous translations. Please review $file_hrr_improvements. You can diff it with $file"
	fi
	if [[ $changes -eq 0 ]]; then
		rm  -f $file_hrr_changes;
		logt 4 "- No semantic changes in $target_lang_path"
	else
		logt 4 "- $changes semantic changes. Please review $file_hrr_changes. You can diff it with $file"
	fi
	now="$(($(date +%s%N)-now))"
	seconds="$((now/1000000000))"
	milliseconds="$((now/1000000))"
	printf -v stats "Backport took %02d.%03d seconds\n" "$((seconds))" "${milliseconds}"
	logt 4 "- $stats"
	unset result;
}

function clear_translations() {
    logt 3 -n "Garbage collection... "
    clear_keys $new_lang
    clear_keys $old_lang
    check_command
}

function echo_legend() {
    logt 3 "Legend:"
    for char in ${!charc[@]}; do
        loglc 8 ${charc[$char]} "'$char' ${chart[$char]}.  "
    done;
}

# as opposed to the entry-point, standalone function, a batch backport function does not cover all the functionality
# because it'll be invoked from another function that controls the process and is in charge of setting work dirs as
# well as committing results and changing branches
function backport_project() {
    prepare_dirs $1 $2
    read_english_files
    for locale in "${L[@]}"; do
    	    backport $locale
    done
    logt 3 "Garbage collection (project)"
    unset L;
    declare -ag L;
}

