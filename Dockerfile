FROM node:16.14.2

RUN apt-get update -y \
    && apt-get install -y nano less groff vim expect

# AWS CLIインストール
RUN cd /opt \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install

# shdotenvインストール
RUN wget https://github.com/ko1nksm/shdotenv/releases/latest/download/shdotenv -O /bin/shdotenv \
    && chmod +x /bin/shdotenv

# AWS CDKインストール
RUN npm install -g aws-cdk

# clean up unnecessary files
RUN rm -rf /opt/*

RUN mkdir aws
COPY . /aws

# Make command line prettier...
RUN echo "alias ls='ls --color=auto'" >> /root/.bashrc \
    && echo "PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@the-bears-field\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] $ '" >> /root/.bashrc

RUN mkdir -p /root/.ssh
WORKDIR /aws
CMD [ "/bin/bash" ]
