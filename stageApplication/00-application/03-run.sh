#!/bin/bash -e

. "${BASE_DIR}/config"
on_chroot << EOF
echo "Running commands as ${APP_USER} to test the build"
cd "${APP_INSTALL_DIR}"

# Run commands as APP_USER (without changing directory)
su "${APP_USER}" << 'USEREOF'
# activate venv
source "${APP_INSTALL_DIR}/venv/bin/activate"
echo "Confirming python & gunicorn are in the virtual environment"
which python
which gunicorn

echo "Running pytest to verify the build"
pytest --cov=src/shop-inventory --cov-config=pyproject.toml

USEREOF

EOF
