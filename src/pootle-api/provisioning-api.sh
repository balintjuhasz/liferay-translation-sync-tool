#!/bin/sh

function create_pootle_project() {
	projectCode="$1"
	projectName="$2"

	logt 2 "Creating empty pootle project"
	start_pootle_session
	# this creates the pootle project
	logt 3 -n "Posting new project form"
	curl $CURL_OPTS -d "csrfmiddlewaretoken=`cat ${PO_COOKIES} | grep csrftoken | cut -f7`"\
        -d "form-TOTAL_FORMS=1" -d "form-INITIAL_FORMS=0" -d "form-MAX_NUM_FORMS=1000"\
        -d "form-0-id=" -d "form-0-code=$projectCode" -d "form-0-fullname=$projectName"\
        -d "form-0-checkstyle=standard" -d "form-0-localfiletype=properties" -d "form-0-treestyle=gnu" \
        -d "form-0-source_language=2" -d "form-0-ignoredfiles=" -d "changeprojects=Save Changes"\
        "$PO_SRV$path/admin/projects.html"
	check_command
	close_pootle_session
}

function notify_pootle() {
	projectCode="$1"
	logt 2 "Notifying pootle about the new project"
	call_manage "update_translation_projects" "--project=$projectCode"
}

function initialize_project_files() {
	projectCode="$1"
	projectName="$2"
	logt 2 "Initializing language files for $projectCode"

	locales=$(get_locales_from_source $PORTAL_PROJECT_ID)

	logt 3 -n "Creating template file"
	touch "$PODIR/$projectCode/$FILE.$PROP_EXT"
	check_command

	for locale in $locales; do
		filename="$FILE$LANG_SEP$locale.$PROP_EXT"
		logt 3 -n "Creating $filename"
		touch "$PODIR/$projectCode/$filename"
		check_command
	done;
}
#form-35-id:
#form-35-code:periquito-portlet
#form-35-fullname:Portlet de Periquito
#form-35-checkstyle:standard
#form-35-localfiletype:properties
#form-35-treestyle:gnu
#form-35-source_language:2
#form-35-ignoredfiles:
#changeprojects:Save Changes
#
#csrfmiddlewaretoken:6f182fe672be1094f318b13b55d7bd03
#form-TOTAL_FORMS:36
#form-INITIAL_FORMS:35
#form-MAX_NUM_FORMS: