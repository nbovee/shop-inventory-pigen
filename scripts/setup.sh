#!/bin/bash

# Get the repository root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT" || exit

# Apply skipfiles and symlinks to
touch pi-gen/stage2/SKIP_IMAGES pi-gen/stage2/SKIP_NOOBS
touch pi-gen/stage4/SKIP_IMAGES pi-gen/stage4/SKIP_NOOBS
touch pi-gen/stage5/SKIP_IMAGES pi-gen/stage5/SKIP_NOOBS

# Create symlinks only if they don't exist
[ -e pi-gen/stageAccessPoint ] || ln -s ../stageAccessPoint pi-gen/
[ -e pi-gen/stageApplication ] || ln -s ../stageApplication pi-gen/
[ -e pi-gen/config ] || ln -s ../config pi-gen/

## link build directory
mkdir -p pi-gen/deploy
[ -e deploy ] || ln -s pi-gen/deploy deploy

cd - > /dev/null || exit

