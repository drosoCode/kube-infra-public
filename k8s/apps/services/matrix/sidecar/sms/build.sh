#!/bin/bash

/opt/android-sdk/tools/bin/sdkmanager "ndk;21.3.6528147" && \
    wget https://dl.google.com/go/go1.19.1.linux-amd64.tar.gz && tar -C /usr/local -xzf go1.19.1.linux-amd64.tar.gz && \
    export PATH=$PATH:/usr/local/go/bin && export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 && \
    git clone --recursive https://gitlab.com/beeper/android-sms && cd android-sms && git checkout 0.1.89 && \
    mkdir app/src/main/assets && cp ../config.yaml app/src/main/assets/config.yaml && \
    ./mautrix.sh && ./gradlew installDebug
