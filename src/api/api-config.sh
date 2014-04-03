#!/bin/bash

# Get parameter
# $1 - Which parameter would you like to get
# $2 - Get parameter from this list (usually something like ${PROJECTS[$i]})
function get_param() {
	shift $1
	echo  $1
}

# Verify parameters
# $1 - How many parameters should be passed on, otherwise fail...
# $2 - Message to be displayed if verification failed
# $* - Parameters to be verified
function verify_params() {
	[ "$#" -lt $(($1 + 2)) ] && echo_red "$2" && exit 1
}

# Given a project, returns the root dir where sources are supposed to be
function get_src_base_dir() {
	project="$1"
	if [[ $project == $PORTAL_PROJECT_ID ]]; then
		result=$SRC_PORTAL_BASE;
	else
		result=$SRC_PLUGINS_BASE;
	fi;
	echo $result
}

function add_base_path() {
	project=$1
	base_src_dir=$2
	idx=-1;
	local j;
	for (( j=0; j<${#PATH_BASE_DIR[@]}; j++ ));
	do
		if [[ "${PATH_BASE_DIR[$j]}" == "$base_src_dir" ]]; then
			idx=$j;
		fi;
	done;
	if [[ $idx == -1 ]]; then
		idx=${#PATH_BASE_DIR[@]};
	fi;
	PATH_BASE_DIR[$idx]="$base_src_dir"
	PATH_PROJECTS[$idx]=" $project"${PATH_PROJECTS[$idx]}
}

function compute_working_paths() {
	local i;
	for (( i=0; i<${#PROJECT_NAMES[@]}; i++ ));
	do
		add_base_path "${PROJECT_NAMES[$i]}" "$(get_src_base_dir ${PROJECT_NAMES[$i]})"
	done
}

function get_project_language_path() {
	project="$1"
	local j;
	for (( j=0; j<${#PROJECT_NAMES[@]}; j++ ));
	do
		if [[ "${PROJECT_NAMES[$j]}" == "$project" ]]; then
			idx=$j;
		fi;
	done;
	if [[ $idx == -1 ]]; then
		result=""
	else
		result="${PROJECT_SRC[$idx]}";
	fi;
	echo "$result"
}

function add_project() {
	project_name="$1"
	source_path="$2"
	ant_path="$3"

	PROJECT_NAMES[${#PROJECT_NAMES[@]}]="$project_name"
	PROJECT_SRC[${#PROJECT_SRC[@]}]="$source_path"
	PROJECT_ANT[${#PROJECT_ANT[@]}]="$ant_path"
}

function add_projects() {
	plugins="$1"
	suffix="$2"
	prefix="$3"

	for plugin in $plugins;
	do
		pootle_project_id="$plugin$suffix"
		add_project "$pootle_project_id" "${prefix}${pootle_project_id}${SRC_PLUGINS_LANG_PATH}" "${prefix}${pootle_project_id}"
	done
}

function get_locales_from_source() {
	source_dir=$(get_project_language_path $1)
	echo $(ls -l $source_dir/Language_* | cut -f 1 -d . | cut -f 2- -d _)
}

# $1 - This parameter must contain $@ (parameters to resolve).
function resolve_params() {
	params="$@"
	[ "$params" = "" ] && export HELP=1
	for param in $1 ; do
		if [ "$param" = "--pootle2repo" ] || [ "$param" = "-r" ]; then
			export UPDATE_REPOSITORY=1
		elif [ "$param" = "--repo2pootle" ] || [ "$param" = "-p" ]; then
			export UPDATE_POOTLE_DB=1
		elif [ "$param" = "--rescanfile" ] || [ "$param" = "-s" ]; then
			export RESCAN_FILES=1
		elif [ "$param" = "--moveproject" ] || [ "$param" = "-m" ]; then
			export MOVE_PROJECT=1
		elif [ "$param" = "--backport" ] || [ "$param" = "-b" ]; then
			export BACKPORT=1
		elif [ "$param" = "--upload" ] || [ "$param" = "-u" ]; then
			export UPLOAD=1
		elif [ "$param" = "--uploadDerived" ] || [ "$param" = "-U" ]; then
			export UPLOAD_DERIVED=1
		elif [ "$param" = "--newproject" ] || [ "$param" = "-np" ]; then
			export NEW_PROJECT=1
		elif [ "$param" = "--qualityCheck" ] || [ "$param" = "-q" ]; then
			export QA_CHECK=1
		elif [ "$param" = "--help" ] && [ "$param" = "-h" ] && [ "$param" = "/?" ]; then
			export HELP=1
		else
			echo "Unknown parameter. Showing help..."
			export HELP=1
		fi
	done
	if [ $HELP ]; then
		print_help
	fi
}

function print_help() {
	echo -e "$WHITE.: $product :.$COLOROFF"
	echo

	echo "$product_name is a tool that syncrhonizes translations from Liferay source code repository from/to a Pootle installation"
	echo "Tool is invoked with one action at a time. Each action might have additional arguments."
	echo
	echo -e "${YELLOW}Environment variables$COLOROFF"
	echo "	LR_TRANS_MGR_PROFILE	configuration profile to load (see Configuration section)."
	echo "	LR_TRANS_MGR_TAIL_LOG	if defined, tool invocation will do tail on log file. This will allow you to track the execution"
	echo
	echo -e "${YELLOW}Configuration$COLOROFF"
	echo "	Tool reads conf/pootle-manager.\$LR_TRANS_MGR_PROFILE.conf file. Variables are documented in conf/pootle-manager.conf file"
	echo
	echo -e "${YELLOW}Logs$COLOROFF"
	echo "	Tool output is written into log file. Filename is shown in the console  "
	echo

	echo -e "${YELLOW}Actions$COLOROFF"

	print_action "-r, --pootle2repo"\
			"Exports pootle data into Language*.properties files, and commits them into a branch named \$EXPORT_BRANCH"

	print_action "-p, --repo2pootle"\
			"Updates the set of translatable keys in Pootle from Language.properties file in master branch. Updates all translations that have been committed to master since last invocation to this action"

	print_action "-s, --rescanfile"\
		"Instructs Pootle to rescan filesystem to update the filenames in the DB. This basically avoids doing the same using the UI (saving a lot of time).\
In addition, corrects any filename not matching Language_<locale>.properties naming convention"

	print_action "-m, --moveproject <currentCode> <newCode>"\
		"Changes the project code in Pootle. This operation is not supported by Pootle. Truly useful in case a plugin name changes"\
		"currentCode: project current code, such as 'knowledge-portlet'"\
		"newCode: project new code, such as 'knowledge-base-portlet'"

	print_action "-b, --backport"\
		"Backports translations from source to destination branches. This option works just with branches, there is no Pootle communication. Results are committed"

	print_action "-u, --upload <projectCode> <locale>"\
			"Uploads translations for a given project and language. Translations are read from Language_<locale>.properties file in the pwd. \
Automatic translations are not uploaded. If there is a Language.properties in the pwd, will be read as well so that \
translations which value equal to the english translation is skipped as well."\
			"projectCode: project code, such as 'knowledge-portlet'"\
			"locale: locale code denoting language where translations will be uploaded"

	print_action "-U, --uploadDerived <projectCode> <derivedLocale> <parentLocale>"\
			"Uploads translations for a given project and language which is derived from a parent language.\
Automatic translations are not uploaded. If a translation in derived language is found to be equal to its peer in parent locale, then it won't be uploaded. As a result,\
the translation in the parent locale will be used by Liferay when a page is requested in the derived locale, simplifying the administration.\
Both Language_<parentLocale>.properties and Language_<derivedLocale>.properties have to be in the pwd\
Future version are expected to read a Language.properties file as well to match the -u behavior"\
			"projectCode: project code, such as 'knowledge-portlet'"\
			"derivedLocale: locale code denoting language where translations will be uploaded"\
			"parentLocale: locale code denoting the parent language, which translations will be reused by the derived one "

	print_action "-np, --newproject <projectCode> \"<project name>\""\
			"Creates a new project in Pootle. In addition, creates all languages in the project, generating project files as expected by -r and -p options. This saves a lot of time"\
			"projectCode: new project code, such as 'knowledge-portlet'"\
			"projectName: new project name, such as 'Knowledge Portlet'. If contains spaces, please double quote it!"\

	print_action "-q, --qualityCheck"\
			"Run a set of checks over pootle exported files. Log files contain the results"

	print_action "-h, --help" "Prints this help and exits"

	UPDATE_REPOSITORY=
	UPDATE_POOTLE_DB=
}

function print_action() {
	echo -e "	${CYAN}$1$COLOROFF"
	shift 1
	echo "		$1"
	shift 1
	[[ ! -z $1 ]] && echo "		Arguments:"
	for arg in "$@";
	do
		echo "			$arg"
	done;
	echo
}

function load_config() {
	if [[ -n "$LR_TRANS_MGR_PROFILE" ]]; then
		pmp="pootle-manager.$LR_TRANS_MGR_PROFILE.conf.sh"
		msg="Loaded configuration profile '$pmp'"
	else
		pmp="pootle-manager.conf.sh"
		msg="Loaded default config profile '$pmp'"
	fi;

	. "conf/${pmp}"

	set_log_dir

	logt 1 "$msg"
}
