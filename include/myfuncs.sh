#----- Fonctions de base
function Info()
{
    echo -e "${info}${1}${neutre}"
}

function Info2()
{
    echo -en "${info2}${1}${neutre} "
}

function Error()
{
    echo -e "${error}<ERREUR> : ${1}${neutre}"
}

function Question()
{
    echo -en "${question}$1${neutre} :"
}

function Check_Root ()
{  # doit être lancé en tant que root ou sudo
  Info2 "Verification droits utilisateur"
  if [ "$UID" -ne "0" ]; then
     Error "Vous devez lancer ce script en mode root ou en mode sudo sinon vous ne pourrez pas continuer."
     exit 999
  else
    Info "OK"
  fi
}


# Copyright (c) 2009, Scott Barr <gsbarr@gmail.com> All rights reserved.

function valid_input()
{
  local correct="no"
  Return_Val=""

  if [ -z "$2" ]
  then
	local opts=( oui non )
	local opt_list="oui/non"
  else
	local opts=( `echo $2 | tr "/" " "` )
	local opt_list=$2
  fi

  while [ "$correct" != "ok" ]
  do
    if [ -n "$3" ]; then
      line_prompt="$1 [default: $3] "
    else
      line_prompt="$1 [$opt_list] "
    fi
    echo -en "${question}$line_prompt${neutre}"
    read answer
    if [ -n "$3" ]; then
      answer=$3
    else
      ret=`echo "${opts[@]}" | grep -w "$answer"`
    fi
    if [ $? -eq 0 ]; then
      correct="ok"
      Return_Val=$answer
    fi
  done
}

function start_spinner()
{
  parent_pid=$$
  (SP_STRING="/-\\|"; while [ -d /proc/$1 ] && [ -d /proc/$parent_pid ]; do printf "\e[1;37m\e7[ %1.1s ]  \e8\e[0m" "$SP_STRING"; sleep .2; SP_STRING=${SP_STRING#"${SP_STRING%?}"}${SP_STRING%?}; done) &
  disown
  spinner_pid=$!
}

function stop_spinner()
{
   if [ $spinner_pid -gt 0 ]
   then
    kill -HUP $spinner_pid 2>/dev/null
   fi
}

function exec_command()
{
   printf "%-40s" "$2"

   (eval $1 >/dev/null 2>&1) &
   pid=$!

   start_spinner
   wait $pid
   status=$?
   stop_spinner

   if [ $status -eq 0 ];
   then
       echo -e "\e[1;37m[ \e[0m\e[1;32mok\e[0m\e[1;37m ]\e[0m"
   else
       echo -e "\e[1;37m[ \e[0m\e[1;31mfailed\e[0m\e[1;37m ]\e[0m"
	   echo -e "La commande suivante ne s'est pas effectuée correctement:"
	   echo -e "$1"
	   exit 1
   fi
}
