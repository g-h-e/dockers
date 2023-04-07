#!/usr/bin/env bash 
# server-cloner
# container installer
# ver - 1.06
# ghe - 2023
#######

init-docker() 
{
mkdir -p ./logs 2>&1
printf "\n===================================================\n"
printf "cloner installation - $(date)"  
printf "\n===================================================\n" 
sleep 1 
printf "\ncreating Dockerfile...\n" && sleep .5
cat <<EOF > ./Dockerfile
FROM $IMAGE
RUN echo cloner > /etc/hostname
RUN apk add --update $DEPS --no-cache
RUN rc-update add docker boot
RUN mkdir -p /home/toolkit/
COPY ./src home/toolkit
RUN mv /home/src/ssx /usr/local/bin 
RUN echo "alias ll='ls -lrt --color=auto'" >> ~/.bashrc
RUN echo "alias xsx='ssx connect'" >> ~/.bashrc
RUN echo "alias sxget='ssx get'" >> ~/.bashrc
RUN echo "alias sxput='ssx put'" >> ~/.bashrc
RUN echo "PS1=\"cloner \w % \"" >> ~/.bashrc 
RUN echo "cd /home/" >> ~/.bashrc
RUN echo "rc-update >> ~/.bashrc" 
RUN echo "clear ; printf '\nwelcome to cloner!\n\n' ; sleep .25" > ~/.welcome
RUN echo "echo \"container's /home/share directory is mounted on your local filesystem (cloner/share)\"" >> ~/.welcome
RUN echo "bash ~/.welcome" >> ~/.bashrc
RUN ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
EOF

cat Dockerfile 

printf "initializing container $name...\n" && sleep .125

docker pull $IMAGE
docker images -a 
docker build -t cloner ./ 
docker run -t -d -v $(pwd)/share:/home/share --privileged --name $(get-name init) cloner
rm Dockerfile 
} 

get-name()
{ 
count=$(docker ps -a | grep cloner | wc -l | awk '{ print $1}' )
[[ $1 == "init" ]] && : || (( count-- ))
echo "cloner-${count}"
}

run-cloner() 
{ 
read -p "run cloner container now? (y/n)" yn
while true ; do 
  case $yn in 
  [Yy]*) 
    printf "entering $name container...\n" 
    docker exec -it $(get-name) bash
    cloner-about | tee -a $LOGFILE 
    exit 
    ;;
  [Nn]*) 
    cloner-about | tee -a $LOGFILE
    exit 
    ;; 
  *) 
    printf "input not understood! exiting...\n"
    cloner-about | tee -a $LOGFILE
    exit
    ;; 
  esac
done 
}

cloner-about() 
{ 
printf "\cloner container installed!\n" 
printf "note: ./share directory is shared between your host and the container!\n" 
printf "\n\tto enter this cloner container, run:\n\t./cloner-ctl connect $(get-name)\n"  
printf "\n\tto destroy this cloner container, run:\n\t./cloner-ctl destroy $(get-name)\n" 
printf "\n\trun ./cloner-ctl for container help\n\n" 
}


LOGFILE=./logs/INSTALL-$(date +%Y%m%d_%H%M%S).log
IMAGE=docker:latest       
DEPS="bash coreutils vim curl openssh sshpass xz docker openrc tree sqlite ansible" 

[[ $(ps -ef | grep docker | grep -v grep | wc -l) -eq 0 ]] && {
  printf "\ndocker daemon not running! start docker before running...\n"
  exit 0 
} 

init-docker | tee $LOGFILE
run-cloner  
