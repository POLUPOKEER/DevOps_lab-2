FROM python:3.11-alpine

# переменные для упрощения
ENV PYTHONUNBUFFERED=1 \
    VENV_PATH=/opt/venv \
    VENV_IMAGE=/opt/venv_image \
    APP_HOME=/app

# Устанавливаем системные зависимости, объединяем их в группу .build-deps для последующего удаления
RUN apk add --no-cache --virtual .build-deps \
    build-base gcc musl-dev libffi-dev openssl-dev postgresql-dev \
    && apk add --no-cache postgresql-libs \ 
    # Создаём директории под приложение и окружения
    && mkdir -p ${APP_HOME} ${VENV_IMAGE} ${VENV_PATH}


WORKDIR ${APP_HOME}


# Копируем и устанавливаем зависимости Python
COPY requirements.txt .

# Создаём виртуальное окружение и устанавливаем зависимости в VENV_IMAGE
RUN python -m venv ${VENV_IMAGE} \
    && ${VENV_IMAGE}/bin/pip install --upgrade pip \
    && ${VENV_IMAGE}/bin/pip install --no-cache-dir -r requirements.txt \
    # Удаляем сборочные системные зависимости, чтобы уменьшить итоговый слой
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* 

# Cоздаём пользователя и назначаем права - Отдельный RUN, т.к Linux ругается
RUN adduser -D -u 1000 appuser \
    && chown -R appuser:appuser ${APP_HOME} ${VENV_IMAGE} ${VENV_PATH}

# Копируем код приложения
COPY app/ ${APP_HOME}/app
COPY docker-entrypoint.sh ${APP_HOME}/

# Даем права скрипту
RUN chmod +x ${APP_HOME}/docker-entrypoint.sh

# Переключаемся на непpивилегированного пользователя
USER appuser

ENV PATH="${VENV_PATH}/bin:${PATH}" \
    FLASK_APP=app

# Точка входа: скрипт, который:
# - если в volume с зависимостями пусто — копирует из VENV_IMAGE в VENV_PATH
# - активирует venv и запускает миграции, затем запускает сервер
ENTRYPOINT ["sh", "/app/docker-entrypoint.sh"]
CMD ["flask", "run", "--host=0.0.0.0", "--port=8080"]