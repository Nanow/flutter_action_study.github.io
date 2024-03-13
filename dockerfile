# Environemnt to install flutter and build web
FROM public.ecr.aws/debian/debian:latest AS build-env

# install all needed stuff
RUN apt-get update
RUN apt-get install -y curl git unzip

# define variables
ARG FLUTTER_SDK=/usr/local/flutter
ARG APP=/app/
ARG VERSION=3.16.3

#clone flutter
RUN git clone https://github.com/flutter/flutter.git -b $VERSION $FLUTTER_SDK
# change dir to current flutter folder and make a checkout to the specific version
RUN cd $FLUTTER_SDK 

# setup the flutter path as an enviromental variable
ENV PATH="$FLUTTER_SDK/bin:$FLUTTER_SDK/bin/cache/dart-sdk/bin:${PATH}"

# Start to run Flutter commands
# doctor to see if all was installed ok
RUN flutter doctor -v

# create folder to copy source code
RUN mkdir /app/
# copy source code to folder
COPY . /app/
# setup new folder as the working directory
WORKDIR /app/

# Run build: 1 - clean, 2 - pub get, 3 - build web
# RUN flutter clean
RUN flutter pub get
RUN flutter pub run build_runner build --delete-conflicting-outputs
RUN flutter build web  --dart-define-from-file dev-config.json

# once here the app will be compiled and ready to deploy

# use nginx to deploy
FROM public.ecr.aws/nginx/nginx:1.25

# copy the info of the builded web app to nginx
COPY --from=build-env /app/build/web /usr/share/nginx/html
RUN pwd
COPY ./nginx/conf.d /usr/share/nginx/conf
# Expose and run nginx
EXPOSE 80
ENTRYPOINT ["nginx", "-g", "daemon off;"]