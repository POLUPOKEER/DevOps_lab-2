set -e

# папки (те же что в Dockerfile)
VENV_PATH="/opt/venv"
VENV_IMAGE="/opt/venv_image"
APP_HOME="/app"

# если venv volume пустой — скопируем туда предварительно установленное содержимое
if [ ! -f "${VENV_PATH}/.venv_populated" ]; then
    echo "Populating venv from image to volume..."
    # копируем содержимое (сохранит права)
    cp -r ${VENV_IMAGE}/. ${VENV_PATH}/
    # пометим что скопировано
    touch ${VENV_PATH}/.venv_populated
fi

# активируем виртуальное окружение
export PATH="${VENV_PATH}/bin:${PATH}"

# Ждём БД
echo "Waiting a bit for DB to be ready..."
sleep 3

# Автоматические миграции
echo "Checking migrations setup..."

if [ ! -d "migrations" ]; then
    echo "Initializing migrations for the first time..."
    flask db init
    flask db migrate -m "Initial migration"
fi

echo "Running migrations..."
flask db upgrade
echo "Migrations completed successfully!"

# Очистки кэша 
# Убедимся, что кеш pip не мешает
rm -rf /tmp/pip-* || true

# Запускаем основную команду контейнера
exec "$@"