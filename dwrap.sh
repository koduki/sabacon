#!/bin/bash

#
# Docker wraper for Rails development.
#

IMAGE=koduki/sabacon-app
IMAGE_JOBQ=koduki/sabacon-jobq
IMAGES="koduki/sabacon:./
        koduki/sabacon-app:./dockerfiles/web/
        koduki/sabacon-jobq:./dockerfiles/worker/"

REDIS_ID=`docker ps|awk '$2=="redis"{print $1}'`
POSTGRES_ID=`docker ps|awk '$2=="postgres"{print $1}'`
DATABASE_URL="postgres://postgres:mysecretpassword@postgres-host:5432/postgres"

# READ AWS AMI KEYS
`cat ~/.aws/credentials_sbacon-api.csv |grep 'sabacon-api'|awk -F',' '{print "export AWS_ACCESS_KEY="$2}'`
`cat ~/.aws/credentials_sbacon-api.csv |grep 'sabacon-api'|awk -F',' '{print "export AWS_SECRET_KEY="$3}'`

DOCKER="docker run -it \
	--link ${REDIS_ID}:redis \
        --link ${POSTGRES_ID}:postgres-host \
	-e "RACK_ENV=development" \
	-e "RAILS_ENV=development" \
	-e "REDIS_URL=redis://redis:6379" \
	-e "DATABASE_URL=${DATABASE_URL}" \
	-e "AWS_ACCESS_KEY=${AWS_ACCESS_KEY}" \
	-e "AWS_SECRET_KEY=${AWS_SECRET_KEY}" \
	-v `pwd`:/usr/src/app \
	-w /usr/src/app"

if [ $# -eq 0 ]; then
  cmd="$DOCKER -p 3000:3000 ${IMAGE}"
elif [ $1 = "rails" ]; then
  cmd="$DOCKER ${IMAGE} bundle exec $@"
elif [ $1 = "rake" ]; then
  cmd="$DOCKER ${IMAGE} bundle exec $@"
elif [ $1 = "worker" ]; then
  cmd="$DOCKER ${IMAGE_JOBQ}"
elif [ $1 = "build" ]; then
  echo "$IMAGES"|awk -F':' '{print  " echo \"\ndocker build -t "$1" "$2"\"; docker build -t "$1" "$2}'|sh
	exit
elif [ $1 = "deploy-web" ]; then
  echo "heroku container:push web"
  cd dockerfiles/web/
  heroku container:push web
 	exit
elif [ $1 = "deploy-worker" ]; then
  echo "heroku container:push worker"
  cd dockerfiles/worker/
  heroku container:push worker
 	exit
else
  cmd="$DOCKER ${IMAGE} $@"
fi

# run
echo $cmd
$cmd
