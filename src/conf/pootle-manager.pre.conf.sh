#!/bin/bash
#
### BEGIN INIT INFO
# Provides:             pootle
# Required-Start:	$syslog $time
# Required-Stop:	$syslog $time
# Short-Description:	Manage pootle - conf file
# Description:		Configuration file for Pootle Management script
# 			that provides simplification for management of Pootle.
# Author:		Milan Jaroš, Daniel Sanz, Alberto Montero
# Version: 		1.0
# Dependences:
### END INIT INFO

## Configuration of directories
## base dirs
# pootle installation
declare -xgr POOTLEDIR="/var/www/Pootle"
# translation files for Pootle DB update/sync
declare -xgr PODIR="$POOTLEDIR/po"
# base working dir for the scripts
declare -xgr BASE_DIR="/opt/pootle"
# temporal working dirs
declare -xgr TMP_DIR="$BASE_DIR/po-lf"
declare -xgr TMP_PROP_IN_DIR="$TMP_DIR/prop_in"
declare -xgr TMP_PROP_OUT_DIR="$TMP_DIR/prop_out"
declare -xgr TMP_PO_DIR="$TMP_DIR/po"
declare -xgr TMP_DB_BACKUP_DIR="$BASE_DIR/db-backups"
# source dirs
declare -xgr SRC_BASE="$BASE_DIR/src/"
declare -xgr SRC_PORTAL_BASE="${SRC_BASE}liferay-portal/"
declare -xgr SRC_PORTAL_LANG_PATH="portal-impl/src/content/"
declare -xgr SRC_PLUGINS_BASE="${SRC_BASE}liferay-plugins/"
declare -xgr SRC_PLUGINS_LANG_PATH="/docroot/WEB-INF/src/content/"

## Configuration of credentials
declare -xgr PO_USER="manager"
declare -xgr PO_PASS="test"
# db credentials are not required for now

## Configuration of servers
declare -xgr PO_HOST="localhost"
declare -xgr PO_PORT="8080"
declare -xgr PO_SRV="http://$PO_HOST:$PO_PORT"
declare -xgr PO_COOKIES="$TMP_DIR/${PO_HOST}_${PO_PORT}_cookies.txt"

## Git branches management
declare -xgr WORKING_BRANCH="to-pootle-working"
declare -xgr LAST_BRANCH="to-pootle-current"

## List of projects we know about
declare -xgr PORTLET_LIST="akismet calendar chat contacts ddl-form digg events-display google-maps knowledge mail marketplace\
 microblogs opensocial plugins-security-manager polls private-messaging social-coding social-networking\
 so tasks twitter vimeo weather web-form wiki-navigation wsrp wysiwyg youtube"
declare -xgr PORTLET_SUFFIX="-portlet"
declare -xgr PORTLET_SRC_PATH_PREFIX="${SRC_PLUGINS_BASE}portlets/"

declare -xgr THEME_LIST="noir"
declare -xgr THEME_SUFFIX="-theme"
declare -xgr THEME_SRC_PATH_PREFIX="${SRC_PLUGINS_BASE}themes/"

declare -xgr HOOK_LIST="private-plugin-installer so-activities so"
declare -xgr HOOK_SUFFIX="-hook"
declare -xgr HOOK_SRC_PATH_PREFIX="${SRC_PLUGINS_BASE}hooks/"

# master project list
declare -xga PROJECT_NAMES
declare -xga PROJECT_SRC
# master path list
declare -xga PATH_PROJECTS
declare -xga PATH_BASE_DIR

# first project is the Liferay portal itself
PORTAL_PROJECT_ID=portal
add_project "$PORTAL_PROJECT_ID" "$SRC_PORTAL_BASE$SRC_PORTAL_LANG_PATH"

# now, some plugins
add_projects "$PORTLET_LIST" $PORTLET_SUFFIX $PORTLET_SRC_PATH_PREFIX
add_projects "$HOOK_LIST" $HOOK_SUFFIX $HOOK_SRC_PATH_PREFIX
#add_projects "$THEME_LIST" $THEME_SUFFIX $THEME_SRC_PATH_PREFIX    # no translatable themes so far...

# now that PROJECTS is filled, create the paths
compute_working_paths

# make master lists readonly from now on
declare -r PROJECT_NAMES
declare -r PROJECT_SRC
declare -r PATH_PROJECTS
declare -r PATH_BASE_DIR

# How does language file look like (e.g. Language.properties)
declare -xgr FILE="Language"
declare -xgr PROP_EXT="properties"
declare -xgr PO_EXT="po"
declare -xgr POT_EXT="pot"
declare -xgr LANG_SEP="_"

# How DB dump/restore commands look like (depends on pootle installation)
declare -xgr DB_NAME="pootle_2013_05_30"
declare -xgr DB_DUMP_COMMAND="mysqldump $DB_NAME "
