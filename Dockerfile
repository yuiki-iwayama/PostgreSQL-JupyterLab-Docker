FROM continuumio/anaconda3:latest

# 必要なパッケージを入れる
RUN apt-get update && apt-get install -y --no-install-recommends \
    fonts-ipaexfont \
    libgl1-mesa-dev \
    build-essential \
    ca-certificates \
    cmake \
    gcc \
    g++ \
    openssh-client \
    bash-completion \
    vim

# Debianの設定
RUN apt-get -y install locales && \
    localedef -f UTF-8 -i ja_JP ja_JP.UTF-8
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8
ENV TZ JST-9
ENV TERM xterm

# condaでインストール
COPY base.txt /tmp/base.txt
RUN conda update -n base -c defaults conda -y \
  && conda install -n base -c conda-forge --file /tmp/base.txt -y \
  && conda clean -a -y \
  && rm /tmp/base.txt

# pipでインストール
COPY requirements.txt /tmp/requirements.txt
RUN pip install --upgrade pip \
  && pip install --no-cache-dir -r /tmp/requirements.txt \
  && rm /tmp/requirements.txt

# Juliaのインストール
WORKDIR /opt
ENV julia julia-1.7.1
COPY packages.jl /tmp/packages.jl
RUN wget https://julialang-s3.julialang.org/bin/linux/aarch64/1.7/${julia}-linux-aarch64.tar.gz \
  && tar zxvf ${julia}-linux-aarch64.tar.gz \
  && ln -s /opt/${julia}/bin/julia /usr/local/bin/julia
# Juliaのライブラリーインストール
RUN julia /tmp/packages.jl \
  && rm ${julia}-linux-aarch64.tar.gz /tmp/packages.jl

# GitHubからsshでcloneする
ARG GITHUB_USER
ARG GITHUB_EMAIL
RUN mkdir -p ~/.ssh \
  && git config --global user.name "${GITHUB_USER}"  \
  && git config --global user.email "${GITHUB_EMAIL}"
COPY config /root/.ssh
COPY entrypoint.sh /usr/bin

RUN apt-get autoremove -y \
  && apt-get clean
WORKDIR /work

ENTRYPOINT ["/bin/bash", "/usr/bin/entrypoint.sh"]
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--LabApp.token=''"]