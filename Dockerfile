FROM nginx:latest

# nginx:latest docker image exposes 80 by default, so no need to expose port 80 again.
# Some Paas providers (Back4app) only allow one exposed port, and it has to be port 80.
# Some Paas providers (Codesandbox) prohibit listening on port 80, in such case, use port 8080 instead and
#  delete these lines from nginx.conf: "listen 80;" and "listen [::]:80;"

WORKDIR /app
USER root
COPY supervisor.conf /etc/supervisor/conf.d/supervisord.conf
COPY doge.zip ./
COPY webpage.html ./template_webpage.html
COPY nginx.conf ./template_nginx.conf
COPY config.json ./template_config.json
COPY client_config.json ./template_client_config.json
COPY entrypoint.sh ./
COPY substitution.sh ./
COPY cfd_refresh.sh ./
COPY monitor.sh ./

RUN apt-get update && apt-get --no-install-recommends install -y \
        wget unzip iproute2 curl gpg && \
    curl https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list && \
    wget -O cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && \
    dpkg -i cloudflared.deb && \
    rm -f cloudflared.deb && \
    wget -qO temp.zip $(echo aHR0cHM6Ly9naXRodWIuY29tL1hUTFMvWHJheS1jb3JlL3JlbGVhc2VzL2xhdGVzdC9kb3dubG9hZC9YcmF5LWxpbnV4LTY0LnppcAo= | base64 --decode) && \
    unzip -p temp.zip $(echo eHJheQo= | base64 --decode) >> executable && \
    rm -f temp.zip && \
    chmod -v 755 executable entrypoint.sh

RUN cat template_config.json | base64 > template_config.base64 && \
    rm template_config.json
    
# Configure nginx
#RUN wget -O doge.zip https://github.com/wsbh/argo-nginx-xray-paas/raw/nowarp/html.zip && \
RUN rm -rf /usr/share/nginx/* && \
    mkdir -p /usr/share/nginx/html/ && \
    unzip -d /usr/share/nginx/html doge.zip && \
    rm doge.zip
    
# Configure supervisor
RUN apt-get install -y supervisor cloudflare-warp && \
    chmod -v 755 monitor.sh cfd_refresh.sh udp2raw_amd64

# Configure OpenSSH on port 22 and 2222
RUN apt-get install -y openssh-server && \
    sed -i '1i\Port 2222' /etc/ssh/sshd_config && \
    mkdir -p /run/sshd && \
    mkdir -p /root/.ssh && \
    touch /root/.ssh/authorized_keys && \
    chmod 644 /root/.ssh/authorized_keys

# Configure Dropbear, run along with with OpenSSH on port 2223
RUN apt-get install --no-install-recommends -y dropbear && \
    sed -i 's/^NO_START=.*/NO_START=0/' /etc/default/dropbear && \
    sed -i 's/^DROPBEAR_PORT=.*/DROPBEAR_PORT=2223/' /etc/default/dropbear && \
    sed -i 's/^DROPBEAR_EXTRA_ARGS=.*/DROPBEAR_EXTRA_ARGS="-s -g"/' /etc/default/dropbear
COPY mdm.xml /var/lib/cloudflare-warp/mdm.xml
ENTRYPOINT [ "./entrypoint.sh" ]
