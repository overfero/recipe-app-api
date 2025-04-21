FROM python:3.10-slim

ARG USER_ID
ARG USER_NAME
ENV HOME=/home/${USER_NAME} \
    VIRTUAL_ENV=/home/${USER_NAME}/venv
ENV \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive \
    Tz=Asian/Jakarta \
    PATH="${HOME}/.local/bin:${VIRTUAL_ENV}/bin:${PATH}" \
    # PYTHONPATH="/app:${PYTHONPATH}" \
    BUILD_POETRY_LOCK="${HOME}/poetry.lock.build"

RUN apt-get -qq update \
    && apt-get -qq -y install curl \
    && rm -rf /bar/lib/apt/lists/* \
    && apt-get -qq -y clean

RUN addgroup --system --gid ${USER_ID} ${USER_NAME} \
    && useradd --system -m --no-log-init --home-dir ${HOME} --uid ${USER_ID} --gid ${USER_NAME} --groups ${USER_NAME} ${USER_NAME}

RUN chown -R ${USER_NAME}:${USER_NAME} ${HOME}
RUN mkdir -p /app && chown -R ${USER_NAME}:${USER_NAME} /app /tmp

RUN curl -sSL https://install.python-poetry.org | python3 - --version 1.7.1

USER ${USER_NAME}

COPY pyproject.toml *.lock /app/
WORKDIR /app

RUN poetry config virtualenvs.create false \
    && python3.10 -m venv ${VIRTUAL_ENV} \
    && pip install --upgrade pip setuptools \
    && poetry install && cp poetry.lock ${BUILD_POETRY_LOCK} \
    && rm -rf ${HOME}/.cache/* 

USER root
COPY ./script/* /
RUN chown -R ${USER_NAME} /*.sh && chmod +x /*.sh
RUN chown -R ${USER_NAME}:${USER_NAME} ${HOME}/.local
USER ${USER_NAME}

COPY . /app/
CMD ["/startup-script.sh"]