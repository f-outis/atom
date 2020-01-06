#!/bin/bash
###### PROMPT COLORS ######
NC=$'\e[0m'
RED=$'\e[31m'
YELLOW=$'\e[33m'
GREEN=$'\e[92m'
BLUE=$'\e[34m'
ORANGE=$'\e[38;5;202m'
BOLDUNDERLINE=$'\e[1;4m'
##########################
VALIDENTRIES="Valid arguments are "blue" or "green"."

usage() {
  USAGE="Usage : Enter keyword 'blue' or 'green'"
  echo "${YELLOW}$USAGE${NC}"
}

bluegradient () {
  for i in {18..21} {21..18} ; do echo -en "\e[48;5;${i}m \e[0m" ; done ; echo
  }

greengradient () {
  for i in {46..49} {49..46} ; do echo -en "\e[48;5;${i}m \e[0m" ; done ; echo
  }

check_input_entry() {
  case $ENV_TO_SWAP_TO in
  blue)
    echo "${BLUE}You are going to switch to blue environment${NC} $(bluegradient)"
    ;;
  green)
    echo "${GREEN}You are going to switch to green environment${NC} $(greengradient)"
    ;;
  *)
    usage
    exit 1
    ;;
esac
}

check_active_env() {
local CURRENT_ENV=`curl -s -u faramarz:f@rad@yM3tal https://supernova-dk.digikala.com/dev/healthcheck/env/`
if [[ "$CURRENT_ENV" == "$ENV_TO_SWAP_TO" ]]
 then
   echo "Environment to swap to : $ENV_TO_SWAP_TO"
   echo "Current Environment    : $CURRENT_ENV"
   echo "${RED}${BOLDUNDERLINE}INFO:${NC}${RED} Traffic is already routing to $CURRENT_ENV environment. Exiting...${NC}"
   exit 1
 else
   echo "Environment to swap to : $ENV_TO_SWAP_TO"
   echo "Current Environment    : $CURRENT_ENV"
   check_input_entry
   return 0
fi
}

get_env_instances() {
    case "$ENV_TO_SWAP_TO" in
        blue)
            HOSTS="192.168.78.2 192.168.78.3 192.168.78.4"
            ROOTPATH="/var/lib/machines/nginx-blue/var/www/html"
            PASSIVEROOTPATH="/var/lib/machines/nginx-green/var/www/html"
            ENV=blue
            ;;
        green)
            HOSTS="192.168.78.2 192.168.78.3 192.168.78.4"
            ROOTPATH="/var/lib/machines/nginx-green/var/www/html"
            PASSIVEROOTPATH="/var/lib/machines/nginx-blue/var/www/html"
            ENV=green
            ;;
        *)
            usage
            ;;
    esac
    export HOSTS ENV ROOTPATH PASSIVEROOTPATH
}

confirmation() {
while true; do
    read -p "${RED}Are you sure?${NC} " YESNO
    case $YESNO in
        [Yy]* ) return 0;;
        [Nn]* ) echo "${RED}Exiting...${NC}";exit 1;;
        * ) echo "Please answer yes or no.";;
    esac
done
}

create_host_file() {
  get_env_instances
  echo -e "\n${YELLOW}Summary :${NC}"
  echo "${YELLOW}Selected servers      : $HOSTS ${NC}"
  echo "${YELLOW}ROOT PATH of nginx    : $ROOTPATH ${NC}"
  echo -e "${YELLOW}Selected Environment  : $ENV_TO_SWAP_TO ${NC} \n"
  if [ -f .servers ]; then
    rm -f .servers
  fi
  for SRV in `echo $HOSTS | xargs`
  do
    echo "root@$SRV" >> .servers
  done
  export SERVERHOSTFILE=".servers"
}

swapper() {
  echo "${YELLOW}Swapping active environment to $ENV_TO_SWAP_TO...${NC}"
  parallel-ssh -i -v -P -h $SERVERHOSTFILE "echo $ENV_TO_SWAP_TO > $ROOTPATH/.production"
  echo "${GREEN}DONE!!!${NC}"
  parallel-ssh -i -v -P -h $SERVERHOSTFILE "rm -f $PASSIVEROOTPATH/.production"
  echo "${YELLOW}Old enviroment is deactivated.${NC}"
}

main() {
  echo -e "Environment swapping tool for \e[44mBlue\e[30;48;5;82mGreen\e[0m deployment..."
  echo -e "Valid arguments are "blue" or "green"."
  read -p "${ORANGE}Enter the name of the new environment(Environment contains new version of code) : ${NC}" ENV_TO_SWAP_TO
  export ENV_TO_SWAP_TO
  create_host_file
  check_active_env
  confirmation
  swapper
}
main
