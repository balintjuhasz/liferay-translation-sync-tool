#!/bin/bash

####
## Pootle server communication
####

. common-functions.sh

# to Pootle

function update_pootle_db() {
	echo_cyan "[`date`] Updating pootle database..."
	for project in "${!PROJECTS[@]}";
	do
		echo_white "  $project: "
		echo_yellow "    Updating the set of translatable keys"
		echo -n "      Copying project files "
		cp "${PROJECTS[$project]}/${FILE}.$PROP_EXT" "$PODIR/$project"
		check_command
		# Update database as well as file system to reflect the latest version of translation templates
		echo -n "      Updating Pootle templates "
		$POOTLEDIR/manage.py update_from_templates --project="$project" -v 0 > /dev/null 2>&1
		check_command
	done
}

function prepare_input_dirs() {
	echo_cyan "[`date`] Preparing project input working dirs..."
	for project in "${!PROJECTS[@]}";
	do
		echo_white "  $project: cleaning input working dirs"
		clean_dir "$TMP_PROP_IN_DIR/$project"
	done
}

function create_working_branch() {
	path="$1"

	echo "      creating working branch '$WORKING_BRANCH'"
	cd $path
	if exists_branch $WORKING_BRANCH $path; then
		echo -n "      '$WORKING_BRANCH' branch already exists. There seems to be a previous, interrupted process. Deleting branch '$WORKING_BRANCH' "
		git branch -D $WORKING_BRANCH > /dev/null 2>&1
		check_command
	fi;
	echo -n "      git checkout -b $WORKING_BRANCH "
	git checkout -b $WORKING_BRANCH > /dev/null 2>&1
	check_command
}

function pull_changes() {
	path="$1"
	echo -n "      git checkout master "
	cd $path
	git checkout master > /dev/null 2>&1
	check_command
	echo -n "      git pull upstream master "
	git pull upstream master > /dev/null 2>&1
	check_command
}

function rotate_working_branch() {
	path="$1"
	# check if old branch exists
	if exists_branch $LAST_BRANCH $path; then
		echo -n "      git branch -D $LAST_BRANCH "
		git branch -D $LAST_BRANCH > /dev/null 2>&1
	else
		echo "      '$LAST_BRANCH' does not exist, will be created now"
	fi;

	echo -n "      git branch -m $WORKING_BRANCH $LAST_BRANCH "
	cd $path
	git branch -m $WORKING_BRANCH $LAST_BRANCH > /dev/null 2>&1
	check_command
	echo "      Contents in '$LAST_BRANCH' will be used as reference of last successful Pootle update"
}

function setup_working_branches() {
	echo_cyan "[`date`] Setting up git branches for project(s)"
	old_dir=$pwd;
	for path in "${!PATHS[@]}";
	do
		echo_white  "  $path"
		echo_yellow "    for projects:${PATHS[$path]}"
 		pull_changes $path;
 		create_working_branch $path
	done;
	cd $old_dir
}

function rotate_working_branches() {
	echo_cyan "[`date`] Rotating git branches for project(s)"
	old_dir=$pwd;
	for path in "${!PATHS[@]}";
	do
		echo_white  "  $path"
		echo_yellow "    for projects:${PATHS[$path]}"
 		rotate_working_branch $path
	done;
	cd $old_dir
}