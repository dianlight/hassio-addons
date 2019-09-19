ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install requirements for add-on
RUN \
    # CONFIG PARSER
    apk add --no-cache jq sed \
#        curl \
    && \ 
    # WEBUI add-on
    apk add --no-cache python3 \
    && \
    # Build Requrement
    apk add --no-cache --virtual .build-dependencies \
        build-base=0.5-r1 \
        git=2.22.0-r0 \
        linux-headers=4.19.36-r0 \
#    && \
#    apk add --no-cache \
#        eudev=3.2.8-r0 \
    && \    
    #MySensors
    git clone https://github.com/mysensors/MySensors.git --depth 1 --branch master \ 
    # END    
    && true


# Copy data for add-on
COPY run.sh /
RUN chmod a+x /run.sh

# Copy support Files
COPY mysensors.conf /etc/

# Python 3 HTTP Server serves the current working dir
# So let's set it to our add-on persistent data directory.
WORKDIR /data

CMD [ "/run.sh" ]